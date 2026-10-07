// PORT OF: 无直接 C 对应 —— 这是技术方案 §4.4「事件引擎设计」要求的
//          **可序列化显式状态机**，替代原版的 Proc 协程驱动的交互流程。
//
// 地图上的交互流程：光标移动 → 选中单位 → 显示移动范围 → 移动 → 待机。
//
// ## 为什么用显式状态机而不是 async/await
//
// 原版用 Proc 协程表达"等待玩家输入"这类流程。Flutter 里最自然的写法是
// `await` 一个 Future，但**协程的调用栈无法序列化**——
// 一旦玩家在"移动范围已显示、还没确认"的瞬间存档，读档就回不到那个状态。
//
// 所以这里把流程写成"状态 + 输入 → 新状态"的纯函数式推进：
// 每个状态都是可枚举的值，整个对象可以完整序列化成 JSON。
//
// 这也是 `lib/core` 禁止 `async`/`await` 的原因（见 check_architecture.dart 的 R4）。

import 'dart:convert';

import '../battle/phase.dart';
import '../map/map_grid.dart';
import '../map/movement_range.dart';
import 'move_costs.dart';
import 'battle_field.dart';

/// 交互阶段
enum FlowPhase {
  /// 自由移动光标（玩家回合的默认态）
  freeCursor,

  /// 已选中一个我方单位，正在显示移动范围
  unitSelected,

  /// 已确认落点，正在选择"移动后做什么"
  actionMenu,

  /// 正在选择攻击目标
  selectTarget,

  /// 已完成本回合行动，等待下一个单位
  unitDone,
}

/// 行动菜单里的选项。
///
/// 只放**已经实现**的项：原版还有 道具 / 交换 / 救出 / 再移动 等，
/// 属于后续里程碑。这里放一个做不了的选项只会让玩家点了没反应。
enum ActionOption {
  wait('待机'),
  attack('攻击');

  const ActionOption(this.label);
  final String label;
}

/// 一次输入
enum FlowInput {
  up,
  down,
  left,
  right,

  /// 确认（键盘 Z / 回车 / 鼠标左键）
  confirm,

  /// 取消（键盘 X / ESC / 鼠标右键）
  cancel,

  /// 结束回合（键盘 E）
  endTurn,

  /// 开始剧情演出（键盘 D）—— 只在外壳层处理，流程状态机忽略它
  startDialogue,

  /// **START 键**（键盘回车）。
  ///
  /// 出处：`src/event_0800D110.c:25-28`
  ///
  /// ```c
  /// if (EventEngine_CanStartSkip(proc) && (gKeyStatusPtr->newKeys & START_BUTTON)) {
  ///     EventEngine_StartSkip(proc);   // 置 EV_STATE_SKIPPING
  ///     return;
  /// }
  /// ```
  ///
  /// 演出期间按下它会**快进整段剧情**（`EVENT_IS_SKIPPING` 在
  /// 淡入淡出 / 等按键 / 移动 / 死亡淡出里都被检查）。
  /// 流程状态机本身忽略它。
  start,
}

/// 流程状态机的状态快照。**完全可序列化。**
class FlowState {
  FlowState({
    required this.phase,
    required this.cursorX,
    required this.cursorY,
    this.selectedUnitId,
    this.moveOriginX,
    this.moveOriginY,
    this.pendingX,
    this.pendingY,
    this.turn = 1,
    this.faction = 0,
    this.actionIndex = 0,
    this.targetIndex = 0,
  });

  final FlowPhase phase;
  final int cursorX;
  final int cursorY;

  /// 当前选中的单位（`null` 表示没选中）
  final int? selectedUnitId;

  /// 选中单位的原始位置（取消时要回退到这里）
  final int? moveOriginX;
  final int? moveOriginY;

  /// 光标停在的落点（行动菜单阶段用）
  final int? pendingX;
  final int? pendingY;

  final int turn;
  final int faction;

  /// 行动菜单里当前高亮的项（[ActionOption] 的序号）
  final int actionIndex;

  /// 选目标阶段当前高亮的目标序号（对应 `validTargets()` 的结果）
  final int targetIndex;

  FlowState copyWith({
    FlowPhase? phase,
    int? cursorX,
    int? cursorY,
    Object? selectedUnitId = _unset,
    Object? moveOriginX = _unset,
    Object? moveOriginY = _unset,
    Object? pendingX = _unset,
    Object? pendingY = _unset,
    int? turn,
    int? faction,
    int? actionIndex,
    int? targetIndex,
  }) {
    return FlowState(
      phase: phase ?? this.phase,
      cursorX: cursorX ?? this.cursorX,
      cursorY: cursorY ?? this.cursorY,
      selectedUnitId: selectedUnitId == _unset
          ? this.selectedUnitId
          : selectedUnitId as int?,
      moveOriginX:
          moveOriginX == _unset ? this.moveOriginX : moveOriginX as int?,
      moveOriginY:
          moveOriginY == _unset ? this.moveOriginY : moveOriginY as int?,
      pendingX: pendingX == _unset ? this.pendingX : pendingX as int?,
      pendingY: pendingY == _unset ? this.pendingY : pendingY as int?,
      turn: turn ?? this.turn,
      faction: faction ?? this.faction,
      actionIndex: actionIndex ?? this.actionIndex,
      targetIndex: targetIndex ?? this.targetIndex,
    );
  }

  static const Object _unset = Object();

  Map<String, dynamic> toJson() => {
        'phase': phase.name,
        'cursorX': cursorX,
        'cursorY': cursorY,
        'selectedUnitId': selectedUnitId,
        'moveOriginX': moveOriginX,
        'moveOriginY': moveOriginY,
        'pendingX': pendingX,
        'pendingY': pendingY,
        'turn': turn,
        'faction': faction,
        'actionIndex': actionIndex,
        'targetIndex': targetIndex,
      };

  factory FlowState.fromJson(Map<String, dynamic> json) => FlowState(
        phase: FlowPhase.values.firstWhere(
          (p) => p.name == json['phase'],
          orElse: () => FlowPhase.freeCursor,
        ),
        cursorX: json['cursorX'] as int,
        cursorY: json['cursorY'] as int,
        selectedUnitId: json['selectedUnitId'] as int?,
        moveOriginX: json['moveOriginX'] as int?,
        moveOriginY: json['moveOriginY'] as int?,
        pendingX: json['pendingX'] as int?,
        pendingY: json['pendingY'] as int?,
        turn: json['turn'] as int? ?? 1,
        faction: json['faction'] as int? ?? 0,
        actionIndex: json['actionIndex'] as int? ?? 0,
        targetIndex: json['targetIndex'] as int? ?? 0,
      );

  String encode() => jsonEncode(toJson());

  static FlowState decode(String source) =>
      FlowState.fromJson(jsonDecode(source) as Map<String, dynamic>);

  @override
  String toString() => 'FlowState(${phase.name} @$cursorX,$cursorY '
      'unit=$selectedUnitId turn=$turn)';
}

/// 推进结果
class FlowResult {
  FlowResult(
    this.state, {
    this.movedUnit = false,
    this.committedMove = false,
    this.endTurn = false,
    this.attack,
  });

  final FlowState state;

  /// 本次输入是否让某个单位真的移动了
  final bool movedUnit;

  /// 本次输入是否提交了一次完整的"移动 + 待机"
  final bool committedMove;

  /// 本次输入是否请求结束回合
  final bool endTurn;

  /// 本次输入是否请求执行一次攻击。
  ///
  /// **状态机不自己结算伤害** —— 它只决定"谁打谁"，把结算交给调用方。
  /// 理由：结算需要道具表 / 职业数据 / 乱数，这些都不是流程状态的一部分；
  /// 把它们塞进状态机，存档就会连带存下整张道具表。
  /// 保持"流程只管流程"，也是 FlowState 能保持可序列化的原因。
  final ({int attackerId, int targetId})? attack;
}

/// 交互流程状态机。
///
/// **纯函数式**：给定 (状态, 单位列表, 地图, 输入) 一定得到同一个新状态。
/// 没有隐藏状态、没有计时器、没有随机数——所以它可测试、可存档、可回放。
class FlowMachine {
  FlowMachine({
    required this.map,
    required this.costsOf,
  });

  final MapGrid map;

  /// 每个单位**自己的**移动消耗表。
  ///
  /// 出处：`src/masked_08018a60.c` 的 `GetUnitMovementCost` ——
  /// 按**职业**（× 天气）选 `pClassData->pMovCostTable[i]`。
  /// 曾经这里是一个"全场一张"的演示表（除 0 号地形外全 1），
  /// 于是**山峰也能走**（真实表里是 255 = 不可通行）。
  final MoveCostsOf costsOf;

  /// 当前光标所在格的移动范围（选中单位时才有）
  MovementRange? _range;

  MovementRange? get currentRange => _range;

  /// 推进一次。
  FlowResult advance(
    FlowState state,
    BattleField field,
    FlowInput input,
  ) {
    switch (state.phase) {
      case FlowPhase.freeCursor:
      case FlowPhase.unitDone:
        return _freeCursor(state, field, input);

      case FlowPhase.unitSelected:
        return _unitSelected(state, field, input);

      case FlowPhase.actionMenu:
        return _actionMenu(state, field, input);

      case FlowPhase.selectTarget:
        return _selectTarget(state, field, input);
    }
  }

  // ------------------------------------------------------------ 自由光标

  FlowResult _freeCursor(FlowState s, BattleField field, FlowInput input) {
    switch (input) {
      case FlowInput.up:
      case FlowInput.down:
      case FlowInput.left:
      case FlowInput.right:
        final (nx, ny) = _moveCursor(s.cursorX, s.cursorY, input);
        return FlowResult(s.copyWith(
          phase: FlowPhase.freeCursor,
          cursorX: nx,
          cursorY: ny,
        ));

      case FlowInput.confirm:
        final unit = field.unitAt(s.cursorX, s.cursorY);
        // 只有**当前阵营**的、还能行动的单位才能选中
        if (unit == null || unit.hasActed) return FlowResult(s);
        if (!field.isControllable(unit)) return FlowResult(s);

        _range = MovementRangeComputer.compute(
          map: map,
          costTable: costsOf(unit),
          x: s.cursorX,
          y: s.cursorY,
          movement: unit.movement,
        );
        return FlowResult(s.copyWith(
          phase: FlowPhase.unitSelected,
          selectedUnitId: unit.id,
          moveOriginX: s.cursorX,
          moveOriginY: s.cursorY,
        ));

      case FlowInput.cancel:
        return FlowResult(s);

      case FlowInput.endTurn:
        return FlowResult(s, endTurn: true);

      // START 在外壳层处理（快进剧情），流程状态机忽略
      case FlowInput.start:
        return FlowResult(s);

      case FlowInput.startDialogue:
        return FlowResult(s);
    }
  }

  // ------------------------------------------------------------ 已选中单位

  FlowResult _unitSelected(FlowState s, BattleField field, FlowInput input) {
    switch (input) {
      case FlowInput.up:
      case FlowInput.down:
      case FlowInput.left:
      case FlowInput.right:
        final (nx, ny) = _moveCursor(s.cursorX, s.cursorY, input);
        // 光标只能在移动范围内走——这是原版的行为，
        // 也是"能不能走到"与"能不能选"共用同一份数据的体现。
        //
        // ⚠️ **这里不能检查"格子上有没有人"。**
        //
        // 出处：`src/UpdatePathArrowWithCursor.c:31-33`
        //
        // ```c
        // SetWorkingBmMap(gBmMapMovement);
        // if (GetBmMapPointAtCursor() == -1) return;   // -1 = 不在移动范围内
        // ```
        //
        // 原作的路径箭头只看**在不在移动范围内**，友军格子照走（穿过友军）。
        // "不能停在别人身上"是**确认时**的规则，不是光标移动时的规则。
        //
        // 我原来把两者写在了一起 —— 后果不是"多按一下方向键"：
        // **友军会把路堵死**。序章开局艾莉卡站在 (4,5)，而那是赛特通往
        // 东侧战场的唯一一格（其余三面是山峰），于是赛特**一步都走不出去**。
        if (_range != null && !_range!.canReach(nx, ny)) {
          return FlowResult(s);
        }
        return FlowResult(s.copyWith(cursorX: nx, cursorY: ny));

      case FlowInput.confirm:
        // 不能停在**别人**的格子上 —— 确认时才判（同上，原作如此）。
        //
        // ⚠️ 自己的那一格是**合法落点**（"原地待机"就是这么按的）。
        // 我第一版写成 `unitAt(...) != null`，把自己也挡了 ——
        // 于是**站在原地待机这个操作根本做不出来**（不是"多按一下"）。
        final occupant = field.unitAt(s.cursorX, s.cursorY);
        if (occupant != null && occupant.id != s.selectedUnitId) {
          return FlowResult(s);
        }
        return FlowResult(s.copyWith(
          phase: FlowPhase.actionMenu,
          pendingX: s.cursorX,
          pendingY: s.cursorY,
          actionIndex: 0,
        ));

      case FlowInput.endTurn:
      case FlowInput.startDialogue:
      case FlowInput.start:
        return FlowResult(s);

      case FlowInput.cancel:
        // 回到选中前的光标位置
        _range = null;
        return FlowResult(s.copyWith(
          phase: FlowPhase.freeCursor,
          cursorX: s.moveOriginX ?? s.cursorX,
          cursorY: s.moveOriginY ?? s.cursorY,
          selectedUnitId: null,
          moveOriginX: null,
          moveOriginY: null,
        ));
    }
  }

  // ------------------------------------------------------------ 行动菜单

  FlowResult _actionMenu(FlowState s, BattleField field, FlowInput input) {
    final unit = field.unitById(s.selectedUnitId);
    if (unit == null) {
      // 选中的单位没了（比如被打死）—— 回到自由光标，不要卡在这个阶段
      return FlowResult(_toFreeCursor(s));
    }

    final options = availableActions(s, field);
    final at = s.pendingX ?? unit.x;
    final atY = s.pendingY ?? unit.y;

    switch (input) {
      case FlowInput.up:
      case FlowInput.left:
        if (options.length <= 1) return FlowResult(s);
        return FlowResult(s.copyWith(
          actionIndex: (s.actionIndex - 1 + options.length) % options.length,
        ));

      case FlowInput.down:
      case FlowInput.right:
        if (options.length <= 1) return FlowResult(s);
        return FlowResult(s.copyWith(
          actionIndex: (s.actionIndex + 1) % options.length,
        ));

      case FlowInput.confirm:
        final picked = options[s.actionIndex.clamp(0, options.length - 1)];

        if (picked == ActionOption.attack) {
          final targets = validTargets(field, unit, at, atY);
          if (targets.isEmpty) {
            // 理论上到不了这里（availableActions 会先滤掉），
            // 但真的到了也不能卡死：退回菜单并归零高亮。
            return FlowResult(s.copyWith(actionIndex: 0));
          }
          return FlowResult(s.copyWith(
            phase: FlowPhase.selectTarget,
            targetIndex: 0,
          ));
        }

        // 待机
        return FlowResult(
          _toFreeCursor(s),
          movedUnit: true,
          committedMove: true,
        );

      case FlowInput.cancel:
        // 退回移动范围选择
        return FlowResult(s.copyWith(
          phase: FlowPhase.unitSelected,
          pendingX: null,
          pendingY: null,
          actionIndex: 0,
        ));

      case FlowInput.endTurn:
      case FlowInput.startDialogue:
      case FlowInput.start:
        return FlowResult(s);
    }
  }

  // ------------------------------------------------------------ 选择目标

  FlowResult _selectTarget(FlowState s, BattleField field, FlowInput input) {
    final unit = field.unitById(s.selectedUnitId);
    if (unit == null) return FlowResult(_toFreeCursor(s));

    final at = s.pendingX ?? unit.x;
    final atY = s.pendingY ?? unit.y;
    final targets = validTargets(field, unit, at, atY);
    if (targets.isEmpty) {
      return FlowResult(s.copyWith(phase: FlowPhase.actionMenu, targetIndex: 0));
    }

    switch (input) {
      case FlowInput.up:
      case FlowInput.left:
        return FlowResult(s.copyWith(
          targetIndex: (s.targetIndex - 1 + targets.length) % targets.length,
        ));

      case FlowInput.down:
      case FlowInput.right:
        return FlowResult(s.copyWith(
          targetIndex: (s.targetIndex + 1) % targets.length,
        ));

      case FlowInput.confirm:
        final t = targets[s.targetIndex.clamp(0, targets.length - 1)];
        // 攻击也要算作"这个单位行动完了"
        return FlowResult(
          _toFreeCursor(s),
          movedUnit: true,
          committedMove: true,
          attack: (attackerId: unit.id, targetId: t.id),
        );

      case FlowInput.cancel:
        return FlowResult(s.copyWith(
          phase: FlowPhase.actionMenu,
          targetIndex: 0,
        ));

      case FlowInput.endTurn:
      case FlowInput.startDialogue:
      case FlowInput.start:
        return FlowResult(s);
    }
  }

  FlowState _toFreeCursor(FlowState s) => s.copyWith(
        phase: FlowPhase.freeCursor,
        selectedUnitId: null,
        moveOriginX: null,
        moveOriginY: null,
        pendingX: null,
        pendingY: null,
        actionIndex: 0,
        targetIndex: 0,
      );

  /// 当前单位在 [atX],[atY] 位置上能做的事。
  ///
  /// 位置是**参数**而不是读 `unit.x`：行动菜单是在"已确认落点但还没真的
  /// 移动"的时候弹出的，此时单位还在原位。用 `unit.x` 会算出移动前的射程。
  List<ActionOption> availableActions(
    FlowState s,
    BattleField field, {
    int? atX,
    int? atY,
  }) {
    final unit = field.unitById(s.selectedUnitId);
    if (unit == null) return const [ActionOption.wait];
    final x = atX ?? s.pendingX ?? unit.x;
    final y = atY ?? s.pendingY ?? unit.y;
    final out = <ActionOption>[ActionOption.wait];
    if (validTargets(field, unit, x, y).isNotEmpty) {
      out.add(ActionOption.attack);
    }
    return out;
  }

  /// 攻击范围（由武器决定）。
  ///
  /// 值来自 `GetItemMinRange` / `GetItemMaxRange`（编码射程的高/低 4 位）。
  /// **FlowMachine 不持有道具表** —— 射程由调用方算好传进来。
  /// 理由同"状态机不结算伤害"：道具表不属于流程状态，
  /// 放进来会让存档连带存下整张表。
  int attackMinRange = 1;
  int attackMaxRange = 1;

  /// 站在 [x],[y] 时能打到的敌人。
  ///
  /// 顺序：**先按 id 升序**，保证同一局面下目标顺序稳定 ——
  /// 否则玩家看到的"第一个目标"会随哈希顺序变化，回放/存档对不上。
  List<MapUnit> validTargets(
    BattleField field,
    MapUnit attacker,
    int x,
    int y,
  ) {
    final out = field.units
        .where((u) {
          if (!u.isAlive) return false;
          if (PhaseRules.areUnitsAllied(u.faction, attacker.faction)) {
            return false;
          }
          final d = _dist(x, y, u.x, u.y);
          return d >= attackMinRange && d <= attackMaxRange;
        })
        .toList()
      ..sort((a, b) => a.id.compareTo(b.id));
    return out;
  }

  static int _dist(int ax, int ay, int bx, int by) =>
      (ax - bx).abs() + (ay - by).abs();

  // ------------------------------------------------------------ 工具

  (int, int) _moveCursor(int x, int y, FlowInput input) {
    var nx = x;
    var ny = y;
    switch (input) {
      case FlowInput.up:
        ny -= 1;
      case FlowInput.down:
        ny += 1;
      case FlowInput.left:
        nx -= 1;
      case FlowInput.right:
        nx += 1;
      default:
        break;
    }
    // 夹在地图内。原版光标不会跑出地图。
    if (nx < 0) nx = 0;
    if (ny < 0) ny = 0;
    if (nx >= map.width) nx = map.width - 1;
    if (ny >= map.height) ny = map.height - 1;
    return (nx, ny);
  }
}
