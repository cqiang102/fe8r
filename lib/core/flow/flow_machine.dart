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

  /// 正在选择要用的道具（`ActionOption.item` 之后）
  itemMenu,

  /// 已完成本回合行动，等待下一个单位
  unitDone,
}

/// 行动菜单里的选项。
///
/// 只放**已经实现**的项：原版还有 道具 / 交换 / 救出 / 再移动 等，
/// 属于后续里程碑。这里放一个做不了的选项只会让玩家点了没反应。
/// GBA 键位（`include/gba/io_reg.h:663-672`）—— `IGNORE_KEYS` 的掩码用这些位
const int kKeyA = 0x0001;
const int kKeyB = 0x0002;
const int kKeySelect = 0x0004;
const int kKeyStart = 0x0008;
const int kKeyRight = 0x0010;
const int kKeyLeft = 0x0020;
const int kKeyUp = 0x0040;
const int kKeyDown = 0x0080;
const int kKeyR = 0x0100;
const int kKeyL = 0x0200;

/// `ActionOption` → `menuOverrideKeys` 里的语义键
///
/// 用于 `DISABLEOPTIONS`（`EvtOverrideUnitMenu`，
/// `src/Event3D_MenuOverride.c:74-118` 的 `UnitMenuOverrideConf`）——
/// 那张表按 msgId 列出可隐藏的菜单项，我们按语义键对到自己这边。
String menuKeyOfAction(ActionOption o) => switch (o) {
      ActionOption.wait => 'wait',
      ActionOption.attack => 'attack',
      ActionOption.item => 'item',
      ActionOption.visit => 'visit',
      ActionOption.seize => 'seize',
      ActionOption.chest => 'chest',
      ActionOption.door => 'door',
      ActionOption.rescue => 'rescue',
      ActionOption.drop => 'drop',
      ActionOption.supply => 'supply',
      ActionOption.talk => 'talk',
      ActionOption.dance => 'dance',
      ActionOption.steal => 'steal',
    };

/// `FlowInput` → GBA 键位（`include/gba/io_reg.h:663-672`）
///
/// `IGNORE_KEYS`（`EvtSetKeyIgnore` ⇒ `SetKeyStatus_IgnoreMask`，
/// `src/SetKeyStatus_IgnoreMask.c:7-10`）的掩码就是这些位；
/// 游戏在输入入口按它吞键。放在这里是因为 `FlowInput` 定义在本文件。
int keyBitOf(FlowInput i) => switch (i) {
      FlowInput.confirm => kKeyA,
      FlowInput.cancel => kKeyB,
      FlowInput.up => kKeyUp,
      FlowInput.down => kKeyDown,
      FlowInput.left => kKeyLeft,
      FlowInput.right => kKeyRight,
      // `endTurn`（地图上的"结束回合"）对应 START 键
      FlowInput.endTurn => kKeyStart,
      // 其余（`startDialogue` / `start` 等）不是实体键或暂不参与屏蔽 ⇒ 0
      _ => 0,
    };

enum ActionOption {
  wait('待机'),
  attack('攻击'),

  /// 道具（回复类）。**顺序**：原作行动菜单的完整表在
  /// `src/menu_def.c` 的 `gUnitActionMenuItems`，它的**逐项顺序与可用性**我没核对
  /// ⇒ 这里与原有两项并列，顺序按"待机/攻击/道具"，**未与源码对齐**。
  item('道具'),

  /// 訪問（村/家）。可用性照 `VisitCommandUsability`（`src/bmmenu_08022F50.c:89-118`），
  /// 由 [FlowMachine.visitAvailableAt] 注入判定。
  visit('訪問'),

  /// 制圧（章节结束的正规入口）。可用性照 `UnitActionMenu_CanSeize`
  /// （`src/bmmenu_08022F50.c:68-80`），由 [FlowMachine.seizeAvailableAt] 注入判定。
  seize('制圧'),

  /// 宝箱（`ChestCommandUsability`，`src/bmmenu_08023D5C.c:85-97`）
  chest('宝箱'),

  /// 扉（`DoorCommandUsability`，`src/bmmenu_08023D5C.c:58-72`）
  door('扉'),

  /// 救出 / 降下（`CanUnitRescue` / `UnitRescue` / `DropUsability`）
  rescue('救出'),
  drop('降ろす'),

  /// 輸送（`SupplyUsability`，`src/SupplyUsability.c:51-80`）
  supply('輸送'),

  /// 話す（`TalkCommandUsability`，`src/TalkCommandUsability.c:50-64`）
  talk('話す'),

  /// 踊る / 演奏（`PlayDanceCommandUsabilityCommon`）
  dance('踊る'),

  /// 盗む（`StealCommandUsability`，`src/StealCommandUsability.c:50-64`）
  steal('盗む');

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
    this.itemIndex = 0,
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

  /// 道具菜单里当前高亮的槽位（`UNIT_ITEM_COUNT` = 5 槽之一）
  final int itemIndex;

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
    int? itemIndex,
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
      itemIndex: itemIndex ?? this.itemIndex,
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
        'itemIndex': itemIndex,
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
        itemIndex: json['itemIndex'] as int? ?? 0,
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
    this.itemUseIndex,
    this.visitAt,
    this.seizeAt,
    this.chestAt,
    this.doorAt,
    this.rescueAt,
    this.dropAt,
    this.supplyAt,
    this.talkAt,
    this.danceAt,
    this.stealAt,
  });

  final FlowState state;

  /// 本次输入是否让某个单位真的移动了
  final bool movedUnit;

  /// 本次输入是否提交了一次完整的"移动 + 待机"
  final bool committedMove;

  /// 本次输入是否请求结束回合
  final bool endTurn;

  /// 本次输入是否请求**訪問**（值是"x,y"，调用方据此在那格上跑 VILL 事件）。
  final String? visitAt;

  /// 本次输入是否请求**制圧**（值是"x,y"）。
  final String? seizeAt;

  /// 本次输入是否请求**开宝箱**（值是"x,y"）。
  final String? chestAt;

  /// 本次输入是否请求**开门/吊桥**（值是"x,y"，调用方据此找相邻目标）。
  final String? doorAt;

  /// 本次输入是否请求**救出** / **降下** / **輸送** / **話す**（值是"x,y"）
  final String? rescueAt;
  final String? dropAt;
  final String? supplyAt;
  final String? talkAt;
  final String? danceAt;
  final String? stealAt;

  /// 本次输入是否请求**使用某个槽位的道具**。
  ///
  /// 和 [attack] 一样：状态机不结算，只发意图（用哪个槽），
  /// 由调用方拿着道具表去算回复量与耐久。
  final int? itemUseIndex;

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

      case FlowPhase.itemMenu:
        return _itemMenu(state, field, input, itemSlotCount);   // 注入的"可用槽数"

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
        // 只有**当前阵营**的、还能行动的单位才能选中。
        // `US_HIDDEN`（被救出扛在肩上）不在场上 ⇒ 选不中；
        // `US_UNSELECTABLE`（刚被降下的我方，`src/UnitDrop.c:37-38`）本回合也选不中。
        if (unit == null || unit.hasActed) return FlowResult(s);
        if (unit.isHidden || unit.unselectable) return FlowResult(s);
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

    final options = availableActions(s, field, hasUsableItem: hasUsableItem);
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

        if (picked == ActionOption.visit) {
          return FlowResult(s, visitAt: '$at,$atY');
        }

        if (picked == ActionOption.seize) {
          return FlowResult(s, seizeAt: '$at,$atY');
        }

        if (picked == ActionOption.chest) {
          return FlowResult(s, chestAt: '$at,$atY');
        }

        if (picked == ActionOption.door) {
          return FlowResult(s, doorAt: '$at,$atY');
        }

        if (picked == ActionOption.rescue) {
          return FlowResult(s, rescueAt: '$at,$atY');
        }

        if (picked == ActionOption.drop) {
          return FlowResult(s, dropAt: '$at,$atY');
        }

        if (picked == ActionOption.supply) {
          return FlowResult(s, supplyAt: '$at,$atY');
        }

        if (picked == ActionOption.talk) {
          return FlowResult(s, talkAt: '$at,$atY');
        }

        if (picked == ActionOption.dance) {
          return FlowResult(s, danceAt: '$at,$atY');
        }

        if (picked == ActionOption.steal) {
          return FlowResult(s, stealAt: '$at,$atY');
        }

        if (picked == ActionOption.item) {
          return FlowResult(s.copyWith(
            phase: FlowPhase.itemMenu,
            itemIndex: 0,
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

  // ------------------------------------------------------------ 道具菜单

  /// 道具菜单：上下选槽，确认 = 发"用这个槽"的意图，取消 = 退回行动菜单。
  ///
  /// ⚠️ 原作这一步走的是 `ItemSelectMenu`（`src/bmmenu_0802339C.c`
  /// `ItemSelectMenu_Usability` 一族）—— **可用性过滤我未逐行核对**；
  /// 这里只按"调用方说这个单位有可用道具"来开菜单，槽位过滤交给调用方（游戏层）。
  /// 子菜单（装備/使う/捨てる/交換）决定之后，**提交**这次行动。
  ///
  /// 与"待机"走同一条路径（`_toFreeCursor` + movedUnit/committedMove）——
  /// 原作里用完道具/装完备，单位就结束行动了。
  FlowResult commitItemAction(FlowState s) => FlowResult(
        _toFreeCursor(s),
        movedUnit: true,
        committedMove: true,
      );

  FlowResult _itemMenu(FlowState s, BattleField field, FlowInput input,
      int slotCount) {
    final unit = field.unitById(s.selectedUnitId);
    if (unit == null) return FlowResult(_toFreeCursor(s));
    if (slotCount <= 0) {
      return FlowResult(s.copyWith(phase: FlowPhase.actionMenu));
    }
    switch (input) {
      case FlowInput.up:
      case FlowInput.left:
        return FlowResult(s.copyWith(
          itemIndex: (s.itemIndex - 1 + slotCount) % slotCount,
        ));
      case FlowInput.down:
      case FlowInput.right:
        return FlowResult(s.copyWith(
          itemIndex: (s.itemIndex + 1) % slotCount,
        ));
      case FlowInput.confirm:
        // ★ 只发"**选了哪个槽**"的意图，**不提交**这次行动 ——
        // 接着要弹 `ItemSubMenu`（装備/使う/捨てる/交換，`src/ItemSubMenu_*.c`），
        // 由子菜单决定做什么；决定之后调 [commitItemAction] 提交。
        //
        // ⚠️ 路径改过一次：第 28 轮这里是"确认即提交"（那时还没有子菜单）。
        // 现在拆成"选槽 → 子菜单 → 提交"。
        return FlowResult(s, itemUseIndex: s.itemIndex.clamp(0, slotCount - 1));
      case FlowInput.cancel:
        return FlowResult(s.copyWith(phase: FlowPhase.actionMenu));
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
    bool hasUsableItem = false,
  }) {
    final unit = field.unitById(s.selectedUnitId);
    if (unit == null) return const [ActionOption.wait];
    final x = atX ?? s.pendingX ?? unit.x;
    final y = atY ?? s.pendingY ?? unit.y;
    final out = <ActionOption>[ActionOption.wait];
    if (validTargets(field, unit, x, y).isNotEmpty) {
      out.add(ActionOption.attack);
    }
    if (hasUsableItem) {
      out.add(ActionOption.item);
    }
    final canVisit = visitAvailableAt?.call(x, y) ?? false;
    if (canVisit) {
      out.add(ActionOption.visit);
    }
    final canSeize = seizeAvailableAt?.call(x, y) ?? false;
    if (canSeize) {
      out.add(ActionOption.seize);
    }
    final canChest = chestAvailableAt?.call(x, y) ?? false;
    if (canChest) {
      out.add(ActionOption.chest);
    }
    final canDoor = doorAvailableAt?.call(x, y) ?? false;
    if (canDoor) {
      out.add(ActionOption.door);
    }
    if (rescueAvailableAt?.call(x, y) ?? false) {
      out.add(ActionOption.rescue);
    }
    if (dropAvailableAt?.call(x, y) ?? false) {
      out.add(ActionOption.drop);
    }
    if (supplyAvailableAt?.call(x, y) ?? false) {
      out.add(ActionOption.supply);
    }
    if (talkAvailableAt?.call(x, y) ?? false) {
      out.add(ActionOption.talk);
    }
    if (danceAvailableAt?.call(x, y) ?? false) {
      out.add(ActionOption.dance);
    }
    if (stealAvailableAt?.call(x, y) ?? false) {
      out.add(ActionOption.steal);
    }
    return out;
  }

  /// 这个单位**有没有可用道具**（决定行动菜单里出不出现「道具」）——
  /// 同样由调用方注入（要道具表 + 当前 HP）。
  bool hasUsableItem = false;

  /// "站在 (x,y) 上能不能「訪問」" —— 由调用方注入（要地形表 + 本章 Location 事件
  /// + 事件旗）。规则层的判据在 `tile_events.dart`（`visitAvailable`）。
  bool Function(int x, int y)? visitAvailableAt;

  /// "站在 (x,y) 上能不能「制圧」" —— 同样由调用方注入
  bool Function(int x, int y)? seizeAvailableAt;

  /// "站在 (x,y) 上能不能开「宝箱」" —— 同样由调用方注入
  bool Function(int x, int y)? chestAvailableAt;

  /// "站在 (x,y) 上能不能开「扉」" —— 由调用方注入（要地图 + 钥匙 + 目标列表）
  bool Function(int x, int y)? doorAvailableAt;

  /// "这个单位能不能「救出」"（要相邻同伴 + `CanUnitRescue`）
  bool Function(int x, int y)? rescueAvailableAt;

  /// "这个单位能不能「降ろす」"（要 `US_RESCUING` + 相邻空落点）
  bool Function(int x, int y)? dropAvailableAt;

  /// "这个单位能不能「輸送」"（`HasConvoyAccess` + 非幻影 + 领袖）
  bool Function(int x, int y)? supplyAvailableAt;

  /// "这个单位能不能「話す」"（相邻且有本章 CHAR 条目）
  bool Function(int x, int y)? talkAvailableAt;

  /// "这个单位能不能「踊る」"（`CA_DANCE`/`CA_PLAY` + 相邻有已行动的同伴）
  bool Function(int x, int y)? danceAvailableAt;

  /// "这个单位能不能「盗む」"（`CA_STEAL` + 相邻有能偷的红方）
  bool Function(int x, int y)? stealAvailableAt;

  /// 道具菜单里的**可用槽数** —— 由调用方注入（游戏层拿道具表算出"哪些槽能用"）。
  ///
  /// ⚠️ `FlowState.itemIndex` 是**可用列表里的下标**（不是 5 槽里的绝对下标）：
  /// 过滤规则要用道具表，状态机不该持有它 —— 所以映射由调用方负责。
  int itemSlotCount = 0;

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
