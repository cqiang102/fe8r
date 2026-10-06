// 场景剧情执行器 —— **基于 sealed class 的穷尽匹配**。
//
// ## 与第一版的区别
//
// 第一版是"字符串操作码 + 无类型参数"：
//
//     switch (ins.op) { case 'TEXTSHOW': ... default: 记进"未实现" }
//
// 现在是：
//
//     switch (op) {
//       case ShowTextOp(:final textId): ...
//       case CallScript(:final target): ...
//       // 少了任何一种，**编译器直接报错**
//     }
//
// 数据来自 `scene_data.g.dart`（由 C 源码**直接生成**，没有 JSON）。
//
// ## 仍然保留"指令列表 + 程序计数器"
//
// 项目要求随时存档（技术方案 §4.4）。`async` 函数的状态没法序列化，
// 而"指令列表 + PC"可以。

import 'game_text.dart';
import 'scene_data.g.dart';
import 'scene_op.dart';

/// 表现层要做的一件事
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

/// 等玩家按键（对应文本里的 `[A]`）
class WaitForInput extends SceneEvent {
  const WaitForInput(this.scriptName, this.step);
  final String scriptName;
  final int step;

  @override
  String toString() => 'WaitForInput';
}

/// 加载单位表
class LoadUnits extends SceneEvent {
  const LoadUnits(this.table, this.group, this.scriptName, this.step);
  final String table;
  final int group;
  final String scriptName;
  final int step;

  @override
  String toString() => 'LoadUnits($table)';
}

/// 移动单位
class MoveUnitInScene extends SceneEvent {
  const MoveUnitInScene(this.op, this.args, this.scriptName, this.step);
  final String op;
  final List<Object> args;
  final String scriptName;
  final int step;

  @override
  String toString() => '$op(${args.join(', ')})';
}

/// 暂停若干帧
class Stall extends SceneEvent {
  const Stall(this.frames, this.scriptName, this.step);
  final int frames;
  final String scriptName;
  final int step;

  @override
  String toString() => 'Stall($frames)';
}

/// 场景结束
class SceneFinished extends SceneEvent {
  const SceneFinished({required this.missing, required this.unmapped});
  final Set<String> missing;
  final Set<String> unmapped;

  @override
  String toString() =>
      'SceneFinished(缺 ${missing.length} / 未映射 ${unmapped.length})';
}

/// 执行结果
class SceneResult {
  SceneResult({
    required this.events,
    required this.missing,
    required this.unmapped,
  });

  final List<SceneEvent> events;

  /// 引用到但上游尚未 carve 的脚本
  final Set<String> missing;

  /// 生成器没能归类的参数原文（`RawArg`）—— 见到就该补映射
  final Set<String> unmapped;

  /// 走到的**兜底指令**（`MiscOp`）名字 → 出现次数。
  ///
  /// 这些是"认得但本阶段不执行"的指令。**列出来而不是藏起来** ——
  /// 否则"剧情少了一段动作"没人知道为什么。
  final Map<String, int> placeholderOps = {};

  List<ShowText> get texts => events.whereType<ShowText>().toList();

  String transcript({int limit = 20}) =>
      texts.take(limit).map((t) => t.message.plain).join('\n');
}

/// 走一遍场景脚本
class SceneRunner {
  SceneRunner({
    required this.texts,
    Map<String, SceneScript>? scripts,
    this.maxSteps = 20000,
  }) : scripts = scripts ?? allSceneScripts;

  final GameTexts texts;
  final Map<String, SceneScript> scripts;
  final int maxSteps;

  SceneResult run(String scriptName, {void Function(SceneEvent)? onEvent}) {
    final missing = <String>{};
    final unmapped = <String>{};
    final placeholderSink = <String, int>{};
    final events = <SceneEvent>[];

    void emit(SceneEvent e) {
      events.add(e);
      onEvent?.call(e);
    }

    for (final e in _walk(scriptName, missing, unmapped, placeholderSink)) {
      emit(e);
    }

    emit(SceneFinished(missing: missing, unmapped: unmapped));
    return SceneResult(
      events: events,
      missing: missing,
      unmapped: unmapped,
    )..placeholderOps.addAll(placeholderSink);
  }

  Iterable<SceneEvent> _walk(String entry, Set<String> missing,
      Set<String> unmapped, Map<String, int> placeholderSink) sync* {
    // 用**显式栈**而不是宿主递归：脚本之间可以有环，
    // 宿主递归会爆栈（而 `CALL` 成环在原版数据里是存在的）。
    final stack = <_Frame>[_Frame(entry, 0)];
    var steps = 0;

    while (stack.isNotEmpty) {
      if (++steps > maxSteps) {
        missing.add('?超出步数上限($maxSteps)');
        return;
      }
      final f = stack.last;
      final script = scripts[f.name];
      if (script == null) {
        // ⚠️ 不存在的脚本**不静默跳过** —— 否则"剧情少了一段"查不出来。
        missing.add(f.name);
        stack.removeLast();
        continue;
      }
      if (f.pc >= script.ops.length) {
        stack.removeLast();
        continue;
      }

      final op = script.ops[f.pc];
      final step = f.pc;
      f.pc++;

      for (final a in _argsOf(op)) {
        if (a is RawArg) unmapped.add(a.text);
      }

      // ★ 穷尽匹配：新增一种指令，这里不补就**编译不过**。
      switch (op) {
        case ShowTextOp(:final textId):
          final m = texts.byId(textId);
          if (m == null) {
            missing.add('text:0x${textId.toRadixString(16)}');
          } else {
            yield ShowText(message: m, scriptName: f.name, step: step);
            if (m.segments
                .whereType<TextControl>()
                .any((c) => c.isWaitForKey)) {
              yield WaitForInput(f.name, step);
            }
          }

        case CallScript(:final target):
          if (scripts.containsKey(target.name)) {
            stack.add(_Frame(target.name, 0));
          } else {
            missing.add(target.name);
          }

        case CallFromSlot(:final slot):
          final v = f.slots[slot];
          if (v is Sym) {
            if (scripts.containsKey(v.name)) {
              stack.add(_Frame(v.name, 0));
            } else {
              missing.add(v.name);
            }
          }

        case SetSlot(:final slot, :final value):
          f.slots[slot] = value;
          // 插槽里存脚本引用时也检查存在性 —— 这类**间接引用**
          // 比直接 CALL 更隐蔽（序章缺的 3 个就是这么漏掉的）
          if (value is Sym &&
              value.name.startsWith('EventScr_') &&
              !scripts.containsKey(value.name)) {
            missing.add(value.name);
          }

        case SetSlot2(:final slot, :final lo, :final hi):
          f.slots[slot] = lo;
          f.slots[slot + 1] = hi;

        case SlotArith(:final op, :final dst, :final src):
          final a = f.slots[dst];
          final b = src is int ? src : 0;
          if (a is int) {
            f.slots[dst] = switch (op) {
              'SADD' => a + b,
              'SSUB' => a - b,
              'SMUL' => a * b,
              'SDIV' => b == 0 ? 0 : a ~/ b,
              'SAND' => a & b,
              'SORR' => a | b,
              _ => a,
            };
          }

        case LoadUnitsOp(:final group, :final table):
          yield LoadUnits(table.name, group, f.name, step);

        case MoveUnitOp(:final op, :final args):
          yield MoveUnitInScene(op, args, f.name, step);

        case StallOp(:final frames):
          yield Stall(frames, f.name, step);

        case BranchIf(:final equal, :final slot, :final opCount):
          final v = f.slots[slot];
          final taken = (v == 0) == equal;
          if (taken) f.pc += opCount;

        case GoTo(:final label):
          final t = _findLabel(script, label);
          if (t >= 0) f.pc = t;

        // ⚠️ `MiscOp` **必须单独一个 case** —— 它带变量绑定，
        // 而 Dart 不允许"部分 case 绑定了变量"的共享分支体。
        case MiscOp(:final op):
          placeholderSink[op] = (placeholderSink[op] ?? 0) + 1;

        case Label():
        case TextBoxOp():
        case ClearTextOp():
        case SetTextTypeOp():
        case FaceOp():
        case BackgroundOp():
        case CameraOp():
        case CursorOp():
        case EndUnitOp():
        case MusicOp():
        case FadeOp():
        case EventBitOp():
        case AsmCallOp():
        case EnqueueOps():
        case EndScript():
          // 认得它们（**不算"未映射"**），只是本阶段不产出表现事件：
          // 要么归渲染层、要么归 `lib/game` 的状态处理。
          break;
      }
    }
  }

  static int _findLabel(SceneScript s, int label) {
    for (var i = 0; i < s.ops.length; i++) {
      final o = s.ops[i];
      if (o is Label && o.index == label) return i + 1;
    }
    return -1;
  }

  /// 取出指令里可能含 `RawArg` 的参数（用于统计"生成器还没映射什么"）
  static List<Object> _argsOf(SceneOp op) => switch (op) {
        SetSlot(:final value) => [value],
        SlotArith(:final src) => [src],
        FaceOp(:final args) => args,
        BackgroundOp(:final args) => args,
        CameraOp(:final args) => args,
        CursorOp(:final args) => args,
        MusicOp(:final args) => args,
        FadeOp(:final args) => args,
        MoveUnitOp(:final args) => args,
        MiscOp(:final args) => args,
        _ => const [],
      };
}

class _Frame {
  _Frame(this.name, this.pc);
  final String name;
  int pc;

  /// 插槽：`SVAL` 写、`CALL_SLOT` 读。**每个调用帧独立** ——
  /// 原版也是每个脚本有自己的插槽，不是全局共享。
  final Map<int, Object> slots = {};
}
