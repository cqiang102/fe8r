// 场景剧情执行器。
//
// 把一个 [SceneScript] 走一遍，产出**表现层要做的事**（显示哪句话、
// 加载哪个立绘、镜头怎么动）。它**不做像素决定**，也不改游戏规则 ——
// 那是 `lib/game` 的事。
//
// ## 为什么先做这一层
//
// 这样"序章能不能跑"就**先可验证了**：走一遍脚本，检查头几句话
// 是否按预期吐出来。不用等到渲染接好才知道对不对。
//
// ## 与 `EventVm` 的关系
//
// `EventVm` 执行的是**打包成字的**章节事件表（`EventListScr`）。
// 本执行器执行的是**从源码解析出来的**场景脚本（`SceneScript`）。
// 两者输入格式不同，是因为来源不同：
//
//   * 章节事件表：源码里元素之间**没有逗号**（宏展开带的），
//     只能编译后按字节读 —— 那条路要处理指针，很重
//   * 场景脚本：源码里**每行一条指令**，直接读就行 —— 没有指针问题
//
// 后续会统一到一种输入格式上（场景脚本这种），但那是后面的事。

import 'scene_script.dart';

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

  /// 这句话出自哪个脚本（`CALL` 会切脚本，所以需要它来定位）
  final String scriptName;
  final int step;

  @override
  String toString() => 'ShowText(${message.id.toString()})';
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
  const LoadUnits(this.symbol, this.scriptName, this.step);

  final String symbol;
  final String scriptName;
  final int step;

  @override
  String toString() => 'LoadUnits($symbol)';
}

/// 移动一个单位
class MoveUnitInScene extends SceneEvent {
  const MoveUnitInScene(this.args, this.scriptName, this.step);

  final List<Object> args;
  final String scriptName;
  final int step;

  @override
  String toString() => 'MoveUnit(${args.join(',')})';
}

/// 暂停若干帧（`STAL`）
class Stall extends SceneEvent {
  const Stall(this.frames, this.scriptName, this.step);

  final int frames;
  final String scriptName;
  final int step;

  @override
  String toString() => 'Stall($frames)';
}

/// 执行走完了
class SceneFinished extends SceneEvent {
  const SceneFinished({required this.missingSymbols, required this.skipped});

  /// 引用到但不存在的脚本 / 符号 —— **如实带出来**，不静默吞掉
  final Set<String> missingSymbols;

  /// 不认识的指令名（执行器跳过了它们）
  final Map<String, int> skipped;

  @override
  String toString() => 'SceneFinished(缺 ${missingSymbols.length} / '
      '跳过 ${skipped.length} 种)';
}

/// 走一遍场景脚本
class SceneRunner {
  SceneRunner({required this.scenes, required this.texts, this.maxSteps = 4000});

  final SceneScripts scenes;
  final GameTexts texts;

  /// 上限，防止脚本里的循环把执行器卡死
  final int maxSteps;

  /// 执行一条脚本，产出表现事件。
  ///
  /// [onEvent] 每产出一件事就被调用一次，所以调用方可以边跑边渲染；
  /// 返回值是执行完后的汇总（缺了什么、跳过了什么）。
  SceneResult run(String scriptName, {void Function(SceneEvent)? onEvent}) {
    final missing = <String>{};
    final skipped = <String, int>{};
    final events = <SceneEvent>[];
    var steps = 0;

    void emit(SceneEvent e) {
      events.add(e);
      onEvent?.call(e);
    }

    /// 递归执行（`CALL` 会切脚本，所以用显式的栈而不是宿主递归 ——
    /// 脚本里可以有环，宿主递归会爆栈）
    final stack = <_Frame>[_Frame(scriptName, 0)];
    while (stack.isNotEmpty) {
      if (++steps > maxSteps) {
        missing.add('?超出步数上限($maxSteps)');
        break;
      }
      final f = stack.last;
      final script = scenes.scripts[f.name];
      if (script == null) {
        // ⚠️ 不存在的脚本**不静默跳过** —— 记进 missing，
        // 否则"剧情少了一段"会变成一个查不出的谜。
        missing.add(f.name);
        stack.removeLast();
        continue;
      }
      if (f.pc >= script.instructions.length) {
        stack.removeLast();
        continue;
      }

      final ins = script.instructions[f.pc];
      f.pc++;

      switch (ins.op) {
        case 'TEXTSHOW':
          final id = ins.args.isNotEmpty ? ins.args[0] : null;
          if (id is int) {
            final m = texts.byId(id);
            if (m == null) {
              missing.add('text:$id');
            } else {
              emit(ShowText(message: m, scriptName: f.name, step: f.pc - 1));
            }
          }
          break;

        case 'SVAL':
        case 'SVAL2':
          // `SVAL(槽位, 值)` —— 值可能是**另一个脚本的引用**
          //（如 `SVAL(EVT_SLOT_2, EventScr_Prologue_EirikaAttacked)`），
          // 之后通过 `CALL_SLOT` 之类间接调用。
          //
          // ⚠️ 这类引用**必须也检查存在性** —— 第一版只查了 `CALL`/`LOAD`，
          // 结果序章缺的 3 个脚本一个都没报出来，测试才发现的。
          // 间接引用比直接引用更隐蔽。
          for (final sym in ins.syms) {
            if (sym.name.startsWith('EventScr_') &&
                !scenes.scripts.containsKey(sym.name)) {
              missing.add(sym.name);
            }
          }
          break;

        case 'CALL':
          // `CALL(X)` / `CALL((u8 *)X + 0xNN)` —— 目标是另一个脚本
          final sym = ins.syms.isNotEmpty ? ins.syms.first : null;
          if (sym == null) {
            skipped['CALL(无符号参数)'] = (skipped['CALL(无符号参数)'] ?? 0) + 1;
          } else if (!scenes.scripts.containsKey(sym.name)) {
            missing.add(sym.name);
          } else {
            stack.add(_Frame(sym.name, 0));
          }
          break;

        case 'LOAD1':
        case 'LOAD2':
          final sym = ins.syms.isNotEmpty ? ins.syms.first : null;
          if (sym != null) {
            emit(LoadUnits(sym.name, f.name, f.pc - 1));
            if (!scenes.scripts.containsKey(sym.name) &&
                sym.name.startsWith('EventScr_')) {
              missing.add(sym.name);
            }
          }
          break;

        case 'MOVE':
        case 'MOVE_CLOSEST':
        case 'MOVEONTO':
        case 'MOVE_1STEP':
          emit(MoveUnitInScene(ins.args, f.name, f.pc - 1));
          break;

        case 'STAL':
          final n = ins.args.isNotEmpty ? ins.args[0] : null;
          emit(Stall(n is int ? n : 0, f.name, f.pc - 1));
          break;

        case 'REMA':
        case 'CURE':
        case 'MUNO':
        case 'ENUN':
        case 'ENUT':
        case 'ENDA':
        case 'TEXTSTART':
        case 'TEXTEND':
        case 'LABEL':
        case 'MUSI':
        case 'MUSC':
        case 'FADI':
        case 'FADU':
        case 'CURSOR_CHAR':
        case 'SET_HP':
        case 'EVBIT_T':
          // 这些要么是纯状态、要么归渲染层，
          // 执行器**认得它们**（不算跳过），只是不产出表现事件。
          break;

        default:
          skipped[ins.op] = (skipped[ins.op] ?? 0) + 1;
      }
    }

    // 文本里的 `[A]` 是"等玩家按键" —— 把它变成显式事件，
    // 渲染层才知道什么时候该停下来等输入。
    for (var i = 0; i < events.length; i++) {
      final e = events[i];
      if (e is! ShowText) continue;
      if (e.message.segments.whereType<TextControl>().any((c) => c.isWaitForKey)) {
        events.insert(i + 1, WaitForInput(e.scriptName, e.step));
        i++;
      }
    }

    final fin = SceneFinished(missingSymbols: missing, skipped: skipped);
    emit(fin);
    return SceneResult(events: events, missing: missing, skipped: skipped);
  }
}

class _Frame {
  _Frame(this.name, this.pc);
  final String name;
  int pc;
}

/// 执行结果
class SceneResult {
  const SceneResult({
    required this.events,
    required this.missing,
    required this.skipped,
  });

  final List<SceneEvent> events;

  /// 引用到但找不到的符号 / 文本 —— **跑不通的原因**
  final Set<String> missing;

  /// 执行器不认识的指令名
  final Map<String, int> skipped;

  List<ShowText> get texts => events.whereType<ShowText>().toList();

  /// 头几句话连起来（用于"读一遍剧情"）
  String transcript({int limit = 20}) =>
      texts.take(limit).map((t) => t.message.plain).join('\n');
}
