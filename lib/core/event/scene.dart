// PORT OF: src/event.c + src/TalkInterpret.c（场景演出的运行时）
//          ⚠️ 不是 1:1 移植：脚本改成了 async 函数，不是可序列化的指令流
//
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
/// 淡入/淡出方向。取值对应 `EVSUBCMD_FAD*`。
enum FadeDirection {
  /// subcode 0：从黑淡出（画面出现）
  fromBlack,

  /// subcode 1：淡到黑（画面消失）
  toBlack,

  /// subcode 2：从白淡出
  fromWhite,

  /// subcode 3：淡到白
  toWhite,
}

sealed class SceneEvent {
  const SceneEvent();
}

/// 显示一段文字
class ShowText extends SceneEvent {
  const ShowText({
    required this.message,
    required this.scriptName,
    required this.step,
    this.page,
    this.upto,
    this.pageIndex = 0,
    this.pageCount = 1,
  });

  final GameMessage message;
  final String scriptName;
  final int step;

  /// **这一页**的文字（一条消息可能有好几页，见 `GameMessage.pageSpans`）
  final String? page;

  /// 这一页在 `message.segments` 里的结束下标。
  ///
  /// ⚠️ 有它就不必"拿文字去反查页界" —— 那个做法在含 `[LF]` 的页上
  /// 永远匹配不到，退了会退化成"用整条消息的脸状态"。
  final int? upto;
  final int pageIndex;
  final int pageCount;

  /// 实际要显示的文字
  String get text => page ?? message.plain;

  bool get hasMorePages => pageIndex + 1 < pageCount;

  @override
  String toString() => 'ShowText(0x${message.id.toRadixString(16)}'
      '${pageCount > 1 ? ' 第${pageIndex + 1}/$pageCount页' : ''})';
}

/// 淡入/淡出（`FADU` / `FADI` / `FAWU` / `FAWI`）
class Fade extends SceneEvent {
  const Fade({
    required this.dir,
    required this.speed,
    required this.scriptName,
  });

  final FadeDirection dir;

  /// 速度参数：值越大越慢（原作语义）
  final int speed;
  final String scriptName;

  @override
  String toString() => 'Fade(${dir.name}, speed=$speed)';
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
    // ⚠️ **一页一页地演**，不是整条消息一口气画出来。
    //
    // 一条消息里 `[A]` / `[CR]` 把正文切成多页（序章开场那条就有好几页）。
    // 第一版不分页，结果只显示前两行、后面全被裁掉。
    final pages = m.pageSpans;
    if (pages.isEmpty) {
      await onEvent(ShowText(
        message: m,
        scriptName: currentScript,
        step: 0,
      ));
      return;
    }
    for (var i = 0; i < pages.length; i++) {
      await onEvent(ShowText(
        message: m,
        scriptName: currentScript,
        step: 0,
        page: pages[i].$1,
        // ⚠️ 页界**按 token 序号**给，下游不再"拿文字反查" —— 见 pageSpans 的说明
        upto: pages[i].$2,
        pageIndex: i,
        pageCount: pages.length,
      ));
      // ⚠️ **只有 `[A]` 才等按键，`[CR]` 不等。**
      //
      // 原作：
      //   * `[A]`(3)  → `StartTalkWaitForInput`（`src/TalkInterpret.c:99-108`）**等**
      //   * `[CR]`(2) → `Proc_StartBlocking(gProcScr_TalkShiftClearAll)`
      //     （`:86-97`），滚动清屏完就继续 —— **不等按键**
      //     （`src/TalkShiftClearAll_OnIdle.c:21-33`）
      //
      // 我原来对**每一页**都 `await WaitForInput` —— 每个非空 `[CR]` 页
      // 都会多要一次按键（全量 395 处；播放集 53 条消息含 `[CR]`）。
      //
      // 另外：2127/3339 条消息**没有 `[A]`**，它们也不该在最后等按键。
      if (m.isWaitForKeyAt(pages[i].$2)) {
        await onEvent(WaitForInput(currentScript, 0));
      }
    }
  }

  void loadUnits(int group, Sym table) {
    onEvent(LoadUnits(table.name, group));
  }

  void moveUnit(String op, List<Object> args) {
    onEvent(MoveUnitInScene(op, args));
  }

  Future<void> stall(int frames) => onEvent(Stall(frames));

  /// 淡入/淡出。
  ///
  /// ⚠️ **缩写名是反的** —— 看 `src/Event17_Fade.c`：
  ///
  ///     case 0: // FADU
  ///         StartLockingFadeFromBlack(...);   // 从黑淡出 → 画面出现
  ///     case 1: // FADI
  ///         StartLockingFadeToBlack(...);     // 淡到黑 → 画面消失
  ///
  /// 按缩写猜会**正好做反**。生成器里也是显式映射，不靠名字。
  ///
  /// 四个分支都返回 `EVC_ADVANCE_YIELD` —— **脚本阻塞到淡完为止**。
  Future<void> fade(FadeDirection dir, int speed) =>
      onEvent(Fade(dir: dir, speed: speed, scriptName: currentScript));

  /// 认得但本阶段不执行的调用（`CURSOR_CHAR` / `MUSI` / `CHECK_TUTORIAL`…）
  void placeholder(String op) {
    placeholderCalls[op] = (placeholderCalls[op] ?? 0) + 1;
  }

  void noteUnmapped(RawArg a) => unmappedArgs.add(a.text);
}


