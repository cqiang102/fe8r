// PORT OF: src/eventscr.c / src/eventscr_*.c / src/Event0*.c 的控制流部分
//
// 事件脚本的**执行引擎**。
//
// ## 为什么是显式状态机
//
// 原版用 Proc 协程：`EventEngineProc` 保存 `pEventCurrent`，每条指令函数
// 返回一个状态码（`EV_CMD_*` 的返回约定），引擎据此决定下一步。
//
// 我们在 M5 已经踩过这个选择：**协程的调用栈无法序列化**。
// 事件引擎比交互流程更需要这一点 —— 剧情演出可以随时被打断（关游戏、
// 断点续玩），而"演到一半的剧情"必须能从存档里恢复。
//
// 所以这里把引擎写成"状态 + 一条指令 → 新状态"：
// 程序计数器、调用栈、插槽、事件位、等待计数全在 [EventVmState] 里，
// 整体可 encode 成 JSON。
//
// ## 与原版的对应关系
//
//   proc->pEventCurrent   → [EventVmState.pc]（**字偏移**，不是指令下标）
//   proc->evStateBits     → [EventVmState.stateBits]
//   proc->evStallTimer    → [EventVmState.stallTimer]
//   调用栈（Event0A_Call）→ [EventVmState.callStack]
//   插槽（SVAL/SLOT_OPS） → [EventVmState.slots]
//
// 用**字偏移**而不是指令下标做 PC，是因为原版的 GOTO/LABEL 都是绝对字地址；
// 用下标会额外引入一层"下标 ↔ 偏移"的双向映射，跳转时就容易对不上。

import 'dart:convert';

import 'event_script.dart';

/// 插槽数量（`EV_SLOT_IDX_*`）
const int eventSlotCount = 0x10;

/// 引擎状态。
///
/// **完全可序列化** —— 这是"剧情演出中途存档"的基础。
class EventVmState {
  EventVmState({
    required this.script,
    this.pc = 0,
    List<int>? callStack,
    List<int>? slots,
    Map<int, bool>? eventBits,
    this.stallTimer = 0,
    this.done = false,
    this.lastText = '',
  })  : callStack = callStack ?? [],
        slots = slots ?? List<int>.filled(eventSlotCount, 0),
        eventBits = eventBits ?? {};

  /// 当前脚本
  final EventScript script;

  /// 程序计数器：**字偏移**
  int pc;

  /// 调用栈（存返回地址，单位同样是字偏移）
  final List<int> callStack;

  /// 通用插槽
  final List<int> slots;

  /// 事件位（`EVBIT_*`）
  final Map<int, bool> eventBits;

  /// 等待计数：> 0 时引擎不推进
  int stallTimer;

  /// 脚本是否已结束
  bool done;

  /// 最近一次显示的文字（供表现层取用）
  String lastText;

  Map<String, dynamic> toJson() => {
        'pc': pc,
        'callStack': callStack,
        'slots': slots,
        // JSON 的 key 只能是字符串，这里统一转成字符串再用时转回来
        'eventBits': eventBits.map((k, v) => MapEntry('$k', v)),
        'stallTimer': stallTimer,
        'done': done,
        'lastText': lastText,
      };

  /// 从 JSON 恢复。**脚本本身不入档** —— 它是静态数据，
  /// 存档只存"演到哪儿了"。把脚本也塞进去会让存档膨胀几百倍，
  /// 而且换版本后旧脚本的偏移可能已经无意义。
  static EventVmState fromJson(Map<String, dynamic> j, EventScript script) {
    final bits = <int, bool>{};
    (j['eventBits'] as Map<String, dynamic>? ?? {}).forEach((k, v) {
      bits[int.parse(k)] = v as bool;
    });
    return EventVmState(
      script: script,
      pc: j['pc'] as int? ?? 0,
      callStack:
          (j['callStack'] as List<dynamic>? ?? []).map((e) => e as int).toList(),
      slots: (j['slots'] as List<dynamic>? ?? [])
          .map((e) => e as int)
          .toList(),
      eventBits: bits,
      stallTimer: j['stallTimer'] as int? ?? 0,
      done: j['done'] as bool? ?? false,
      lastText: j['lastText'] as String? ?? '',
    );
  }

  String encode() => jsonEncode(toJson());

  static EventVmState decode(String source, EventScript script) =>
      EventVmState.fromJson(jsonDecode(source) as Map<String, dynamic>, script);
}

/// 执行一条指令的结果
class EventStep {
  const EventStep({
    required this.instruction,
    required this.advanced,
    this.text,
    this.note = '',
  });

  final EventInstruction? instruction;

  /// 是否推进了 PC
  final bool advanced;

  /// 本条指令产生的文字（`EV_CMD_DISPLAYTEXT`）
  final String? text;

  final String note;

  @override
  String toString() => '${instruction?.toString() ?? '(空)'}'
      '${text == null ? '' : '  → "$text"'}'
      '${note.isEmpty ? '' : '  # $note'}';
}

/// 事件虚拟机。
///
/// **没有隐藏状态**：所有可变数据都在 [EventVmState] 里。同一份状态
/// 推进两次一定得到同样的结果 —— 可测试、可存档、可回放。
class EventVm {
  EventVm({Map<int, String>? textTable}) : textTable = textTable ?? const {};

  /// 文字编号 → 文本。
  ///
  /// 真实文本来自反编译项目里的对话数据（属于 M10 的翻译管线）。
  /// 这里允许注入，让引擎本身能独立测试。
  final Map<int, String> textTable;

  /// 推进一条指令。
  ///
  /// 返回 null 表示"不推进"（等待中或已结束），调用方应当停帧。
  EventStep? step(EventVmState state) {
    if (state.done) return null;

    // 等待中：只减计数，不执行指令。
    // 原版对应 `if (proc->evStallTimer) { proc->evStallTimer--; return; }`
    if (state.stallTimer > 0) {
      state.stallTimer -= 1;
      return EventStep(
        instruction: null,
        advanced: false,
        note: '等待中（剩 ${state.stallTimer}）',
      );
    }

    final idx = state.script.indexAtOffset(state.pc);
    if (idx == null) {
      // PC 落不到任何指令上 —— 说明脚本有问题（跳转目标算错）。
      // 不静默结束：静默结束会让"剧情突然没了"变成偶发难查的问题。
      throw StateError(
        'PC=${state.pc} 不是任何指令的起始偏移（脚本共 '
        '${state.script.instructions.length} 条指令）',
      );
    }
    final inst = state.script.instructions[idx];

    switch (inst.opcode) {
      case EventOpcodes.nop:
        state.pc = _nextOffset(state, idx);
        return EventStep(instruction: inst, advanced: true);

      case EventOpcodes.label:
        // 标签是纯粹的跳转目标，执行时直接越过
        state.pc = _nextOffset(state, idx);
        return EventStep(instruction: inst, advanced: true, note: '标签');

      case EventOpcodes.goTo:
        _requireArgs(inst, 1);
        state.pc = inst.args[0];
        return EventStep(instruction: inst, advanced: true,
            note: '跳到 ${inst.args[0]}');

      case EventOpcodes.call:
        _requireArgs(inst, 1);
        state.callStack.add(_nextOffset(state, idx));
        state.pc = inst.args[0];
        return EventStep(instruction: inst, advanced: true,
            note: '调用 ${inst.args[0]}（栈深 ${state.callStack.length}）');

      case EventOpcodes.end:
        if (inst.subCommand == EndSubCommand.endAll) {
          state.done = true;
          return EventStep(instruction: inst, advanced: false, note: '结束全部');
        }
        // EVSUBCMD_ENDA：从调用返回；栈空则结束整个脚本
        if (state.callStack.isEmpty) {
          state.done = true;
          return EventStep(instruction: inst, advanced: false, note: '结束');
        }
        state.pc = state.callStack.removeLast();
        return EventStep(instruction: inst, advanced: true,
            note: '返回 ${state.pc}（栈深 ${state.callStack.length}）');

      case EventOpcodes.stall:
        // 原版 EV_CMD_STALL：等待若干帧
        state.stallTimer = inst.args.isEmpty ? 1 : inst.args[0];
        state.pc = _nextOffset(state, idx);
        return EventStep(instruction: inst, advanced: true,
            note: '等待 ${state.stallTimer} 帧');

      case EventOpcodes.evSet:
        _requireArgs(inst, 1);
        // 子命令 0 = 清位，8 = 置位（EVSUBCMD_EVBIT_F / _T）
        final on = inst.subCommand == EvSetSubCommand.setEventBit;
        state.eventBits[inst.args[0]] = on;
        state.pc = _nextOffset(state, idx);
        return EventStep(instruction: inst, advanced: true,
            note: '事件位 ${inst.args[0]} = $on');

      case EventOpcodes.evCheck:
        _requireArgs(inst, 1);
        // 检查事件位或事件 id；把结果写进插槽 0
        final on = state.eventBits[inst.args[0]] ?? false;
        state.slots[0] = on ? 1 : 0;
        state.pc = _nextOffset(state, idx);
        return EventStep(instruction: inst, advanced: true,
            note: '检查 ${inst.args[0]} → ${state.slots[0]}');

      case EventOpcodes.sVal:
        _requireArgs(inst, 2);
        state.slots[inst.args[0] % eventSlotCount] = inst.args[1];
        state.pc = _nextOffset(state, idx);
        return EventStep(instruction: inst, advanced: true);

      case EventOpcodes.slotOps:
        _slotOp(state, inst);
        state.pc = _nextOffset(state, idx);
        return EventStep(instruction: inst, advanced: true);

      case EventOpcodes.branch:
        _branch(state, inst, idx);
        return EventStep(instruction: inst, advanced: true);

      default:
        // **不静默跳过**。未实现的指令如果悄悄越过，
        // 剧情会"看起来能跑但内容缺失"，那是最难发现的一类问题。
        throw UnimplementedError(
          '事件指令 ${EventOpcodes.nameOf(inst.opcode)}'
          '（0x${inst.opcode.toRadixString(16)}）尚未实现。'
          '偏移 ${inst.offset}，参数 ${inst.args}。',
        );
    }
  }

  /// 一直推进到"需要等待"或结束。
  ///
  /// [maxSteps] 防止脚本里的死循环把调用方挂死 ——
  /// 原版靠每帧一条指令自然限速，我们的批量推进需要显式上限。
  List<EventStep> run(EventVmState state, {int maxSteps = 1000}) {
    final out = <EventStep>[];
    for (var i = 0; i < maxSteps; i++) {
      if (state.done) break;
      final s = step(state);
      if (s == null) break;
      out.add(s);
      if (!s.advanced && s.instruction == null) break; // 进入等待
    }
    return out;
  }

  // ------------------------------------------------------------ 内部

  int _nextOffset(EventVmState state, int idx) {
    final inst = state.script.instructions[idx];
    return inst.offset + inst.length;
  }

  static void _requireArgs(EventInstruction inst, int n) {
    if (inst.args.length < n) {
      throw FormatException(
        '指令 ${EventOpcodes.nameOf(inst.opcode)}（偏移 ${inst.offset}）'
        '需要 $n 个参数，实际只有 ${inst.args.length} 个',
      );
    }
  }

  void _slotOp(EventVmState state, EventInstruction inst) {
    _requireArgs(inst, 2);
    final dst = inst.args[0] % eventSlotCount;
    final src = inst.args[1] % eventSlotCount;
    final a = state.slots[dst];
    final b = state.slots[src];
    // ⚠️ 除零：原版会崩；这里明确报错而不是给个"看起来合理"的 0，
    // 因为除零一定是脚本有问题。
    if ((inst.subCommand == SlotOpSubCommand.div ||
            inst.subCommand == SlotOpSubCommand.mod) &&
        b == 0) {
      throw StateError('插槽运算除零：指令偏移 ${inst.offset}');
    }
    state.slots[dst] = switch (inst.subCommand) {
      SlotOpSubCommand.add => a + b,
      SlotOpSubCommand.sub => a - b,
      SlotOpSubCommand.mul => a * b,
      SlotOpSubCommand.div => a ~/ b,
      SlotOpSubCommand.mod => a % b,
      SlotOpSubCommand.and => a & b,
      SlotOpSubCommand.or => a | b,
      SlotOpSubCommand.xor => a ^ b,
      SlotOpSubCommand.lsl => a << b,
      SlotOpSubCommand.lsr => a >> b,
      _ => throw UnimplementedError(
          '插槽运算子命令 ${inst.subCommand} 未实现'),
    };
  }

  void _branch(EventVmState state, EventInstruction inst, int idx) {
    // 参数：slotA, value, target
    _requireArgs(inst, 3);
    final a = state.slots[inst.args[0] % eventSlotCount];
    final b = inst.args[1];
    final target = inst.args[2];

    final take = switch (inst.subCommand) {
      BranchSubCommand.eq => a == b,
      BranchSubCommand.ne => a != b,
      BranchSubCommand.ge => a >= b,
      BranchSubCommand.gt => a > b,
      BranchSubCommand.le => a <= b,
      BranchSubCommand.lt => a < b,
      _ => throw UnimplementedError('跳转子命令 ${inst.subCommand} 未实现'),
    };

    state.pc = take ? target : _nextOffset(state, idx);
  }
}
