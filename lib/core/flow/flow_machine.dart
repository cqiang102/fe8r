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

import '../map/map_grid.dart';
import '../map/movement_range.dart';
import 'battle_field.dart';

/// 交互阶段
enum FlowPhase {
  /// 自由移动光标（玩家回合的默认态）
  freeCursor,

  /// 已选中一个我方单位，正在显示移动范围
  unitSelected,

  /// 已确认落点，正在选择"移动后做什么"
  actionMenu,

  /// 已完成本回合行动，等待下一个单位
  unitDone,
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
  FlowResult(this.state, {this.movedUnit = false, this.committedMove = false});

  final FlowState state;

  /// 本次输入是否让某个单位真的移动了
  final bool movedUnit;

  /// 本次输入是否提交了一次完整的"移动 + 待机"
  final bool committedMove;
}

/// 交互流程状态机。
///
/// **纯函数式**：给定 (状态, 单位列表, 地图, 输入) 一定得到同一个新状态。
/// 没有隐藏状态、没有计时器、没有随机数——所以它可测试、可存档、可回放。
class FlowMachine {
  FlowMachine({
    required this.map,
    required this.costTable,
  });

  final MapGrid map;
  final MovementCostTable costTable;

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
          costTable: costTable,
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
        // 也是"能不能走到"与"能不能选"共用同一份数据的体现
        if (_range != null && !_range!.canReach(nx, ny)) {
          return FlowResult(s);
        }
        // 不能停在已被占据的格子上
        if (field.unitAt(nx, ny) != null) return FlowResult(s);
        return FlowResult(s.copyWith(cursorX: nx, cursorY: ny));

      case FlowInput.confirm:
        return FlowResult(s.copyWith(
          phase: FlowPhase.actionMenu,
          pendingX: s.cursorX,
          pendingY: s.cursorY,
        ));

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
    switch (input) {
      case FlowInput.confirm:
        // M5 只实现"待机"这一个选项。攻击/道具/救出等留到后续里程碑。
        return FlowResult(
          s.copyWith(
            phase: FlowPhase.freeCursor,
            selectedUnitId: null,
            moveOriginX: null,
            moveOriginY: null,
            pendingX: null,
            pendingY: null,
          ),
          movedUnit: true,
          committedMove: true,
        );

      case FlowInput.cancel:
        // 退回移动范围选择
        return FlowResult(s.copyWith(
          phase: FlowPhase.unitSelected,
          pendingX: null,
          pendingY: null,
        ));

      case FlowInput.up:
      case FlowInput.down:
      case FlowInput.left:
      case FlowInput.right:
        return FlowResult(s);
    }
  }

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
