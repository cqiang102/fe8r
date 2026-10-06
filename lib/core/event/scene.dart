// arch-exempt: R4 「完全可序列化」这条约束已由用户明确取消（不需要随时存档），
//           所以场景脚本改用 async 函数直接表达"等玩家按键"，
//           不再用可序列化的状态机。见 tools/pipeline/extract/gen_scene_dart.py。
//
// 场景演出的运行时。
//
// ## 为什么可以生成 `async` 函数
//
// 之前保留"指令列表 + 程序计数器"的唯一理由是**随时存档**。
// 用户明确说不需要之后，那层数据模型就没有存在理由了 ——
// `SceneOp` 那些类型存在的唯一意义就是"被解释"。
//
// 现在生成的代码**直接调用本类的方法**：
//
//     Future<void> prologueBeginningScene(Scene s) async {
//       await s.call(prologueRenaisThroneCutscene);
//       s.setSlot(2, Sym('EventScr_Prologue_EirikaAttacked'));
//       await s.textShow(0x8CE);
//       ...
//     }
//
// `await` 天然表达"等玩家按键"，`CALL` 就是函数调用。
//
// ## 等多久由调用方决定
//
// [onEvent] 返回 `Future` —— 游戏里它等到按键，测试里它立即返回。
// 所以**同一份脚本既能演、也能测**，不用为测试准备假的输入。

import 'game_text.dart';

/// 演出中发生的一件事
sealed class SceneEvent {
  const SceneEvent();
}

/// 显示一段文字
class ShowText extends SceneEvent {
  const ShowText({
    required this.message,
    required this.scriptName,
    required this.step,
  });

  final GameMessage message;
  final String scriptName;
  final int step;

  @override
  String toString() => 'ShowText(0x${message.id.toRadixString(16)})';
}

/// 等玩家按键（文本里有 `[A]` 时自动产生）
class WaitForInput extends SceneEvent {
  const WaitForInput(this.scriptName, this.step);
  final String scriptName;
  final int step;

  @override
  String toString() => 'WaitForInput';
}

/// 加载单位表
class LoadUnits extends SceneEvent {
  const LoadUnits(this.table, this.group);
  final String table;
  final int group;

  @override
  String toString() => 'LoadUnits($table)';
}

/// 移动单位
class MoveUnitInScene extends SceneEvent {
  const MoveUnitInScene(this.op, this.args);
  final String op;
  final List<Object> args;

  @override
  String toString() => '$op(${args.join(', ')})';
}

/// 暂停若干帧
class Stall extends SceneEvent {
  const Stall(this.frames);
  final int frames;

  @override
  String toString() => 'Stall($frames)';
}

/// 符号引用（脚本名 / 单位表名 / 函数名），可带偏移
class Sym {
  const Sym(this.name, [this.offset = 0]);

  final String name;
  final int offset;

  @override
  bool operator ==(Object other) =>
      other is Sym && other.name == name && other.offset == offset;

  @override
  int get hashCode => Object.hash(name, offset);

  @override
  String toString() =>
      offset == 0 ? name : '$name+0x${offset.toRadixString(16)}';
}

/// 生成器没能归类的参数原文。
///
/// **它出现就代表生成器要补映射**，不是正常状态。
class RawArg {
  const RawArg(this.text);
  final String text;

  @override
  String toString() => '?$text';
}

/// 场景演出的运行时状态
class Scene {
  Scene({
    required this.texts,
    required this.onEvent,
    required this.scripts,
    Set<String>? defined,
  }) : defined = defined ?? const {};

  final GameTexts texts;

  /// 演出中发生一件事时调用。
  ///
  /// 返回的 Future 被 `await` —— **游戏里等到按键，测试里立即返回**。
  final Future<void> Function(SceneEvent) onEvent;

  /// 脚本名 → 入口函数（含缺失脚本的占位函数）
  final Map<String, Future<void> Function(Scene)> scripts;

  /// **真正被 carve 出来**的脚本名 —— 存在性检查用这个。
  ///
  /// ⚠️ 不能用 `scripts.keys`：它包含缺失脚本的**占位函数**，
  /// 那样"缺失"会看起来"存在"，检查就失效了（踩过）。
  final Set<String> defined;

  /// 当前正在执行的脚本名（事件定位用）
  String currentScript = '';

  /// 本次演出碰到的缺口
  final Set<String> missing = {};

  /// 走到的兜底调用（认得但不执行的）—— 列出来而不是藏起来
  final Map<String, int> placeholderCalls = {};

  /// 生成器未归类的参数
  final Set<String> unmappedArgs = {};

  /// 调用栈深度（`CALL` 嵌套）—— 防止脚本成环时无限递归
  int depth = 0;
  static const int maxDepth = 64;

  // ---- 生成的代码调用的方法 ----

  /// `CALL(x)` —— 运行另一个脚本
  Future<void> call(Sym target) async {
    if (depth >= maxDepth) {
      missing.add('?CALL 嵌套过深($maxDepth)：${target.name}');
      return;
    }
    final fn = scripts[target.name];
    if (fn == null) {
      // ⚠️ 不静默跳过 —— 否则"剧情少了一段"查不出来
      missing.add(target.name);
      return;
    }
    final prev = currentScript;
    currentScript = target.name;
    depth++;
    try {
      await fn(this);
    } finally {
      depth--;
      currentScript = prev;
    }
  }

  /// `CALL_SLOT(n)` —— 调用插槽里存的脚本
  Future<void> callSlot(int slot) async {
    final v = _slots[slot];
    if (v is Sym) {
      await call(v);
    } else if (v is String) {
      await call(Sym(v));
    }
  }

  final Map<int, Object> _slots = {};

  void setSlot(int slot, Object value) {
    _slots[slot] = value;
    // 插槽里存脚本引用时也检查存在性 —— 这类**间接引用**
    // 比直接 CALL 更隐蔽（序章缺的 3 个就是这么漏掉的）
    final String? name = value is Sym
        ? value.name
        : (value is String ? value : null);
    if (name != null &&
        name.startsWith('EventScr_') &&
        defined.isNotEmpty &&
        !defined.contains(name)) {
      missing.add(name);
    }
  }

  void setSlot2(int slot, int lo, int hi) {
    _slots[slot] = lo;
    _slots[slot + 1] = hi;
  }

  int slotInt(int i) => _slots[i] is int ? _slots[i] as int : 0;
  Object? slot(int i) => _slots[i];

  void slotArith(String op, int dst, Object src) {
    final a = slotInt(dst);
    final b = src is int ? src : slotInt(0);
    _slots[dst] = switch (op) {
      'SADD' => a + b,
      'SSUB' => a - b,
      'SMUL' => a * b,
      'SDIV' => b == 0 ? 0 : a ~/ b,
      'SAND' => a & b,
      'SORR' => a | b,
      _ => a,
    };
  }

  /// `TEXTSHOW(id)` —— 显示文字；文本里有 `[A]` 就等玩家按键
  Future<void> textShow(int textId) async {
    final m = texts.byId(textId);
    if (m == null) {
      missing.add('text:0x${textId.toRadixString(16)}');
      return;
    }
    await onEvent(ShowText(
      message: m,
      scriptName: currentScript,
      step: 0,
    ));
    if (m.segments.whereType<TextControl>().any((c) => c.isWaitForKey)) {
      await onEvent(WaitForInput(currentScript, 0));
    }
  }

  void loadUnits(int group, Sym table) {
    onEvent(LoadUnits(table.name, group));
  }

  void moveUnit(String op, List<Object> args) {
    onEvent(MoveUnitInScene(op, args));
  }

  Future<void> stall(int frames) => onEvent(Stall(frames));

  /// 认得但本阶段不执行的调用（`CURSOR_CHAR` / `MUSI` / `CHECK_TUTORIAL`…）
  void placeholder(String op) {
    placeholderCalls[op] = (placeholderCalls[op] ?? 0) + 1;
  }

  void noteUnmapped(RawArg a) => unmappedArgs.add(a.text);
}


