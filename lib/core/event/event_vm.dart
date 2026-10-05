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

/// 移动目标怎么解析
enum MoveTargetMode {
  /// 坐标就是绝对格子坐标
  absolute,

  /// 走到某个单位所在的位置
  ontoUnit,

  /// 从当前位置朝某方向走一格
  oneStep,

  /// 按事件队列里预先登记的路径走
  queuedPath,
}

/// 一次"让某个单位走到某处"的请求。
///
/// VM 只描述**意图**（谁、去哪儿、多快、是否瞬移），
/// 具体怎么走由渲染层决定 —— 寻路与动画都属于表现层。
class UnitMoveRequest {
  const UnitMoveRequest({
    required this.unitId,
    required this.toX,
    required this.toY,
    required this.speed,
    required this.instant,
    this.targetMode = MoveTargetMode.absolute,
    this.targetUnitId,
    this.direction,
  });

  /// `pid`（角色编号）
  final int unitId;
  final int toX;
  final int toY;

  /// 速度；**负数表示直接瞬移**（原版 `if (speed < 0) MoveUnit_(...)`）
  final int speed;

  /// 是否瞬移过去
  final bool instant;

  /// 目标怎么解析
  final MoveTargetMode targetMode;

  /// [MoveTargetMode.ontoUnit] 时的目标单位
  final int? targetUnitId;

  /// [MoveTargetMode.oneStep] 时的方向
  final int? direction;

  Map<String, dynamic> toJson() => {
        'unitId': unitId,
        'toX': toX,
        'toY': toY,
        'speed': speed,
        'instant': instant,
        'targetMode': targetMode.name,
        'targetUnitId': targetUnitId,
        'direction': direction,
      };

  static UnitMoveRequest fromJson(Map<String, dynamic> j) => UnitMoveRequest(
        unitId: j['unitId'] as int,
        toX: j['toX'] as int,
        toY: j['toY'] as int,
        speed: j['speed'] as int,
        instant: j['instant'] as bool,
        targetMode: MoveTargetMode.values.firstWhere(
          (m) => m.name == j['targetMode'],
          orElse: () => MoveTargetMode.absolute,
        ),
        targetUnitId: j['targetUnitId'] as int?,
        direction: j['direction'] as int?,
      );

  @override
  String toString() => 'MoveUnit($unitId → $toX,$toY speed=$speed'
      '${instant ? ' 瞬移' : ''})';
}

/// 剧情的**表现状态** —— VM 记录"脚本想要什么"，渲染层决定怎么画。
///
/// 为什么不把 GBA 的渲染细节搬进来：原版这些指令直接调
/// `EventText_StartTalkMsg` / 背景图层 / 立绘 OAM，那是表现层的活。
/// 搬进来会让 VM 依赖一套用不上的图形系统，而且换成 Flutter 之后
/// 那些细节全部要重写。这里只留**语义**：显示哪段文字、谁的脸、
/// 什么背景、要不要等玩家。
class EventPresentation {
  EventPresentation({
    this.textId,
    this.textType = TextTypeSubCommand.talk,
    this.backgroundId,
    Map<int, int>? faces,
    this.textBoxVisible = false,
  }) : faces = faces ?? {};

  /// 当前文字编号（null = 没在显示文字）
  int? textId;

  /// 对话框样式
  int textType;

  /// 当前背景编号
  int? backgroundId;

  /// 立绘槽位 → 角色脸编号。
  /// `DISPLAYFACE` 把**子命令当作槽位**、参数 0 当作脸编号 —— 这个编码
  /// 不太寻常（通常子命令是"做什么"，这里是"放哪儿"）。
  final Map<int, int> faces;

  bool textBoxVisible;

  Map<String, dynamic> toJson() => {
        'textId': textId,
        'textType': textType,
        'backgroundId': backgroundId,
        'faces': faces.map((k, v) => MapEntry('$k', v)),
        'textBoxVisible': textBoxVisible,
      };

  static EventPresentation fromJson(Map<String, dynamic> j) {
    final f = <int, int>{};
    (j['faces'] as Map<String, dynamic>? ?? {}).forEach((k, v) {
      f[int.parse(k)] = v as int;
    });
    return EventPresentation(
      textId: j['textId'] as int?,
      textType: j['textType'] as int? ?? TextTypeSubCommand.talk,
      backgroundId: j['backgroundId'] as int?,
      faces: f,
      textBoxVisible: j['textBoxVisible'] as bool? ?? false,
    );
  }
}

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
    this.waitingForPlayer = false,
    this.waitingForMove = false,
    List<UnitMoveRequest>? pendingMoves,
    this.cameraX,
    this.cameraY,
    EventPresentation? presentation,
  })  : callStack = callStack ?? [],
        slots = slots ?? List<int>.filled(eventSlotCount, 0),
        eventBits = eventBits ?? {},
        pendingMoves = pendingMoves ?? [],
        presentation = presentation ?? EventPresentation();

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

  /// 是否在等玩家按键继续。
  ///
  /// 这是**引擎状态**而不是表现层的动画状态：它决定 VM 会不会推进，
  /// 所以必须入档 —— 存档时正好停在"等玩家按键"的一帧是完全正常的。
  bool waitingForPlayer;

  /// 当前的表现状态（文字 / 立绘 / 背景）
  final EventPresentation presentation;

  /// 待执行的单位移动请求。渲染层取走后调用 [EventVm.notifyMoveFinished]。
  final List<UnitMoveRequest> pendingMoves;

  /// 是否在等单位走完。
  ///
  /// ⚠️ **这是对原版的一处刻意偏离。**
  /// 原版的 `Event2F_MoveUnit` 返回 `EVC_ADVANCE_CONTINUE`，也就是
  /// "开始走，脚本继续往下跑"；同步靠 Proc 系统在事件引擎层面完成
  /// （`TryPrepareEventUnitMovement` 失败时返回 `EVC_STOP_YIELD`，
  /// 下一帧重试同一条指令）。
  ///
  /// 我们没有 Proc 调度器。若照抄"不等待"，下一句对白会在角色走到位之前
  /// 就弹出来 —— 画面上明显是坏的。
  /// 所以这里用显式的 `waitingForMove` 代替 Proc 层面的同步：
  /// **语义等价（脚本在单位到位前不继续），实现不同。**
  bool waitingForMove;

  /// 镜头目标（null = 不控制镜头）
  int? cameraX;
  int? cameraY;

  Map<String, dynamic> toJson() => {
        'pc': pc,
        'callStack': callStack,
        'slots': slots,
        // JSON 的 key 只能是字符串，这里统一转成字符串再用时转回来
        'eventBits': eventBits.map((k, v) => MapEntry('$k', v)),
        'stallTimer': stallTimer,
        'done': done,
        'lastText': lastText,
        'waitingForPlayer': waitingForPlayer,
        'waitingForMove': waitingForMove,
        'pendingMoves': pendingMoves.map((m) => m.toJson()).toList(),
        'cameraX': cameraX,
        'cameraY': cameraY,
        'presentation': presentation.toJson(),
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
      waitingForPlayer: j['waitingForPlayer'] as bool? ?? false,
      waitingForMove: j['waitingForMove'] as bool? ?? false,
      pendingMoves: (j['pendingMoves'] as List<dynamic>? ?? [])
          .map((e) => UnitMoveRequest.fromJson(e as Map<String, dynamic>))
          .toList(),
      cameraX: j['cameraX'] as int?,
      cameraY: j['cameraY'] as int?,
      presentation: EventPresentation.fromJson(
        j['presentation'] as Map<String, dynamic>? ?? {},
      ),
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

  /// 玩家按键继续。
  ///
  /// 对应原版文本系统的"按键推进"。返回是否真的解除了等待 ——
  /// 不在等待时调用它是无害的（返回 false），这样调用方不必先查状态。
  bool advanceFromPlayerInput(EventVmState state) {
    if (!state.waitingForPlayer) return false;
    state.waitingForPlayer = false;
    return true;
  }

  /// 渲染层报告"移动已完成"。
  ///
  /// 会清空待执行队列并解除等待。返回是否真的解除了等待 ——
  /// 不在等待时调用是无害的。
  bool notifyMoveFinished(EventVmState state) {
    if (!state.waitingForMove) return false;
    state.pendingMoves.clear();
    state.waitingForMove = false;
    return true;
  }

  /// 推进一条指令。
  ///
  /// 返回 null 表示"不推进"（等待中或已结束），调用方应当停帧。
  EventStep? step(EventVmState state) {
    if (state.done) return null;

    // 等玩家按键：整条流程卡在这里，直到 advanceFromPlayerInput。
    // 注意这与 stallTimer 不同：那是按帧等待，这是按输入等待。
    if (state.waitingForPlayer) {
      return EventStep(
        instruction: null,
        advanced: false,
        note: '等玩家按键',
      );
    }

    // 等单位走完（渲染层调用 notifyMoveFinished 解除）
    if (state.waitingForMove) {
      return EventStep(
        instruction: null,
        advanced: false,
        note: '等 ${state.pendingMoves.length} 个单位走完',
      );
    }

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

      // ---------------------------------------------------- 表现类

      case EventOpcodes.setTextType:
        state.presentation.textType = inst.subCommand;
        if (inst.subCommand == TextTypeSubCommand.removePortraits) {
          state.presentation.faces.clear();
        }
        state.pc = _nextOffset(state, idx);
        return EventStep(instruction: inst, advanced: true,
            note: '对话框样式 ${inst.subCommand}');

      case EventOpcodes.displayText:
        _displayText(state, inst, idx);
        return EventStep(instruction: inst, advanced: true,
            text: state.lastText,
            note: state.waitingForPlayer ? '等玩家按键' : '继续');

      case EventOpcodes.continueText:
        state.pc = _nextOffset(state, idx);
        state.waitingForPlayer = true;
        return EventStep(instruction: inst, advanced: true, note: '等玩家按键');

      case EventOpcodes.endText:
        state.presentation.textBoxVisible = false;
        state.presentation.textId = null;
        state.pc = _nextOffset(state, idx);
        return EventStep(instruction: inst, advanced: true, note: '关闭文字框');

      case EventOpcodes.displayFace:
        _requireArgs(inst, 1);
        // ⚠️ 子命令是**槽位**，参数 0 才是脸编号
        state.presentation.faces[inst.subCommand] = inst.args[0];
        state.pc = _nextOffset(state, idx);
        return EventStep(instruction: inst, advanced: true,
            note: '立绘槽 ${inst.subCommand} = 脸 ${inst.args[0]}');

      case EventOpcodes.moveFace:
        state.pc = _nextOffset(state, idx);
        return EventStep(instruction: inst, advanced: true, note: '移动立绘');

      case EventOpcodes.clearTextBox:
        state.presentation.textBoxVisible = false;
        state.presentation.textId = null;
        state.lastText = '';
        state.pc = _nextOffset(state, idx);
        return EventStep(instruction: inst, advanced: true, note: '清空文字框');

      case EventOpcodes.showBg:
        _requireArgs(inst, 1);
        state.presentation.backgroundId = inst.args[0];
        state.pc = _nextOffset(state, idx);
        return EventStep(instruction: inst, advanced: true,
            note: '背景 ${inst.args[0]}');

      case EventOpcodes.clearScreen:
        state.presentation.backgroundId = null;
        state.presentation.faces.clear();
        state.presentation.textBoxVisible = false;
        state.presentation.textId = null;
        state.lastText = '';
        state.pc = _nextOffset(state, idx);
        return EventStep(instruction: inst, advanced: true, note: '清屏');

      // ---------------------------------------------------- 单位与镜头

      case EventOpcodes.moveUnit:
        _moveUnit(state, inst, idx);
        return EventStep(instruction: inst, advanced: true,
            note: '移动 ${state.pendingMoves.last}');

      case EventOpcodes.cameraControl:
        _cameraControl(state, inst, idx);
        return EventStep(instruction: inst, advanced: true,
            note: '镜头 → ${state.cameraX},${state.cameraY}');

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

  /// `EV_CMD_MOVEUNIT`
  ///
  /// 参数：`args[0] = speed`、`args[1] = pid`、`args[2]` 随子命令变化。
  ///
  /// ⚠️ 子命令要用**低 3 位**（`subCommandLow`）。原版把它打包成
  /// `EVSUBCMD_MOVE | (modify << 3)`，直接用 4 位的值会得到 8 而不是 0。
  void _moveUnit(EventVmState state, EventInstruction inst, int idx) {
    _requireArgs(inst, 3);
    final speed = inst.args[0];
    final pid = inst.args[1];
    final arg2 = inst.args[2];
    final sub = inst.subCommandLow;

    // 原版 `if (speed < 0) MoveUnit_(...)` —— 负数速度是"直接瞬移"
    final instant = speed < 0;

    state.pendingMoves.add(_resolveMoveTarget(sub, pid, arg2, speed, instant));
    state.waitingForMove = true;
    state.pc = _nextOffset(state, idx);
  }

  /// 把指令参数翻译成"要走到哪"。
  ///
  /// 三种子命令的目标**依赖单位表**（目标单位在哪、自己现在在哪），
  /// 而 VM 刻意不持有单位表 —— 所以用 [UnitMoveRequest.targetMode] 标记出来，
  /// 让渲染层去解析。
  ///
  /// 用显式的 mode 而不是"给个 (0,0) 让渲染层猜"：后者会把
  /// "目标未解析"和"目标真的在 (0,0)"混成一种情况。
  UnitMoveRequest _resolveMoveTarget(
    int sub,
    int pid,
    int arg2,
    int speed,
    bool instant,
  ) {
    switch (sub) {
      case MoveUnitSubCommand.move:
        // (x, y) 打包成一个字：低 8 位是 x，高 8 位是 y
        return UnitMoveRequest(
          unitId: pid,
          toX: arg2 & 0xFF,
          toY: (arg2 >> 8) & 0xFF,
          speed: speed,
          instant: instant,
        );
      case MoveUnitSubCommand.moveOnto:
        // arg2 是**目标单位的 pid**
        return UnitMoveRequest(
          unitId: pid,
          toX: 0,
          toY: 0,
          speed: speed,
          instant: instant,
          targetMode: MoveTargetMode.ontoUnit,
          targetUnitId: arg2,
        );
      case MoveUnitSubCommand.moveOneStep:
        // arg2 是方向；起点是单位当前位置
        return UnitMoveRequest(
          unitId: pid,
          toX: 0,
          toY: 0,
          speed: speed,
          instant: instant,
          targetMode: MoveTargetMode.oneStep,
          direction: arg2,
        );
      case MoveUnitSubCommand.moveDefined:
        return UnitMoveRequest(
          unitId: pid,
          toX: 0,
          toY: 0,
          speed: speed,
          instant: instant,
          targetMode: MoveTargetMode.queuedPath,
        );
      default:
        throw UnimplementedError('MOVEUNIT 子命令 $sub 未实现');
    }
  }

  /// `EV_CMD_CAMERACONTROL`
  ///
  /// 参数：`args[0]`。子命令用低 3 位。
  ///   * `at` —— `args[0]` 是打包的 `(x, y)`
  ///   * `character` —— `args[0]` 是单位 pid，坐标由渲染层查
  void _cameraControl(EventVmState state, EventInstruction inst, int idx) {
    _requireArgs(inst, 1);
    final sub = inst.subCommandLow;

    switch (sub) {
      case CameraSubCommand.at:
        final packed = inst.args[0];
        state.cameraX = packed & 0xFF;
        state.cameraY = (packed >> 8) & 0xFF;
      case CameraSubCommand.character:
        // 坐标依赖单位表；用特殊值标记"跟随某单位"
        state.cameraX = -1;
        state.cameraY = inst.args[0];
      default:
        throw UnimplementedError('CAMERACONTROL 子命令 $sub 未实现');
    }
    state.pc = _nextOffset(state, idx);
  }

  /// `EV_CMD_DISPLAYTEXT`
  ///
  /// 子命令：
  ///   * `show` / `show2` —— 显示文字并**等玩家按键**（原版是等文字框结束）
  ///   * `removeAll`      —— 关掉所有文字框，不等玩家
  ///
  /// ⚠️ 原文里有个容易漏的分支：`if (evArgument == 0) return CONTINUE;`
  /// 也就是**文字编号为 0 时什么都不做**。0 在原版是"没有文字"的哨兵值。
  /// 漏掉它会让编号 0 去查表，得到空字符串，表现为"这里莫名卡一下"。
  void _displayText(EventVmState state, EventInstruction inst, int idx) {
    if (inst.subCommand == TextShowSubCommand.removeAll) {
      state.presentation.textBoxVisible = false;
      state.presentation.textId = null;
      state.lastText = '';
      state.pc = _nextOffset(state, idx);
      return;
    }

    _requireArgs(inst, 1);
    final msgId = inst.args[0];

    // 负数表示"取插槽 2 的值"（原版 `if (evArgument < 0) evArgument = gEventSlots[2]`）
    final resolved = msgId < 0 ? state.slots[2] : msgId;

    if (resolved == 0) {
      // 哨兵值：不显示，也不等待
      state.pc = _nextOffset(state, idx);
      return;
    }

    state.presentation.textBoxVisible = true;
    state.presentation.textId = resolved;
    state.lastText = textTable[resolved] ?? '';
    state.waitingForPlayer = true;
    state.pc = _nextOffset(state, idx);
  }

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
