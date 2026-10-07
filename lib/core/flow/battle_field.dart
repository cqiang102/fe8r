// PORT OF: include/bmunit.h（struct Unit / UNIT_ITEM_COUNT / UnitDefinition）
//          src/UnitInitFromDefinition.c（道具装载循环）
//          src/exact_08017714.c（UnitClearInventory）
//          src/exact_080176f0.c（UnitAddItem）
//          src/MakeNewItem.c
//          src/bm.c（战场状态）
//          ⚠️ 刻意不复用 lib/core/battle/battle_unit.dart 的 BattleUnit
//
// 战场单位与场地的**语义模型**（纯 Dart，可序列化）。
//
// 这里刻意不复用 `lib/core/battle/battle_unit.dart` 里的 `BattleUnit`：
// 那是**一次战斗结算**期间的临时单位（含 battleAttack / wTriangleBonus 等
// 只在结算中有效的字段），而这里是**地图上长期存在的单位**。
// 两者的生命周期与字段完全不同，混成一个类会让"哪些字段该存档"变得含糊。
//
// 与技术方案 §4.2 的"完全可序列化"要求对应：这个对象能原样进存档。

import 'dart:convert';

import '../battle/battle_unit.dart' show unitItemCount;
import '../battle/phase.dart';

/// `UNIT_DEFINITION_ITEM_COUNT` —— `include/bmunit.h:12`
///
/// 单位定义表里每行只有 **4** 个道具槽（`struct UnitDefinition.items[4]`），
/// 而单位自己的道具栏是 **5** 槽（`unitItemCount`，见 `battle_unit.dart`）。
/// **两者不是同一个数**，混用就会少装一件或越界。
const int unitDefinitionItemCount = 4;

/// `UnitClearInventory` —— `src/exact_08017714.c:37`
///
/// ```c
/// for (i = 0; i < UNIT_ITEM_COUNT; ++i)
///     unit->items[i] = 0;
/// ```
List<int> unitClearInventory() => List<int>.filled(unitItemCount, 0);

/// `UnitAddItem` —— `src/exact_080176f0.c:37`
///
/// ```c
/// s8 UnitAddItem(struct Unit* unit, int item) {
///     for (i = 0; i < UNIT_ITEM_COUNT; ++i)
///         if (unit->items[i] == 0) { unit->items[i] = item; return TRUE; }
///     return FALSE;   // 满了
/// }
/// ```
///
/// 返回写进的下标；道具栏满了返回 `-1`（对应 C 的 `FALSE`）。
/// **满了不是"随便找个地方塞"，是真的放不进去** —— 调用方必须区分。
int unitAddItem(List<int> inventory, int item) {
  for (var i = 0; i < inventory.length; ++i) {
    if (inventory[i] == 0) {
      inventory[i] = item;
      return i;
    }
  }
  return -1;
}

/// `MakeNewItem` —— `src/MakeNewItem.c:27`
///
/// ```c
/// int MakeNewItem(int item) {
///     int uses = GetItemMaxUses(item);
///     if (GetItemAttributes(item) & IA_UNBREAKABLE) uses = 0;
///     return (uses << 8) + GetItemIndex(item);
/// }
/// ```
///
/// 注意 `GetItemMaxUses` 对不磨损道具返回 `0xFF`，而 `MakeNewItem` 又把它
/// 归零 —— 两个分支合起来就是"不磨损 ⇒ 耐久字段为 0"。
int makeNewItem(int itemIndex, int maxUses, {bool unbreakable = false}) =>
    ((unbreakable ? 0 : maxUses) << 8) + (itemIndex & 0xFF);

/// `UnitInitFromDefinition` 的道具装载部分 —— `src/UnitInitFromDefinition.c:62`
///
/// ```c
/// UnitClearInventory(unit);                       // 5 槽清零
/// for (i = 0; (i < UNIT_DEFINITION_ITEM_COUNT) && (uDef->items[i]); ++i)
///     UnitAddItem(unit, MakeNewItem(uDef->items[i]));
/// ```
///
/// [defItems] 是 `UnitDefinition.items[0..3]`（**原始道具编号**，不是编码后的），
/// [makeItem] 由调用方给出（它需要道具表才能算耐久）。
///
/// **`0` 是终止符**：遇到就停，后面的槽不再看 —— 这是源码的循环条件，
/// 不是"跳过这一件继续"。
List<int> inventoryFromDefinition(
  List<int> defItems,
  int Function(int itemIndex) makeItem,
) {
  final inv = unitClearInventory();
  for (var i = 0; i < unitDefinitionItemCount && i < defItems.length; ++i) {
    if (defItems[i] == 0) break;
    unitAddItem(inv, makeItem(defItems[i]));
  }
  return inv;
}

/// 地图上的一个单位。
class MapUnit {
  MapUnit({
    required this.id,
    required this.faction,
    required this.x,
    required this.y,
    this.charIndex = 0,
    this.item0 = 0,
    List<int>? items,
    this.classId = 0,
    this.level = 1,
    this.movement = 5,
    this.hp = 20,
    this.maxHp = 20,
    this.hasActed = false,
    this.name = '',
    this.con = 0,
    this.rescueIndex = 0,
    this.isRescuing = false,
    this.isRescued = false,
    this.isHidden = false,
    this.unselectable = false,
  }) : _initItems = items;

  /// 单位编号（对应原版的 `gUnitLut` 下标）
  final int id;

  /// `FACTION_BLUE` / `FACTION_GREEN` / `FACTION_RED` + 编号
  final int faction;

  int x;
  int y;

  /// 角色编号（`UnitDefinition.charIndex`）—— 胜负判定用它认首领
  final int charIndex;

  /// `UnitDefinition.items[0]` —— 初始的第一件道具（兼容旧调用）
  final int item0;

  /// **道具栏**（`struct Unit.items[UNIT_ITEM_COUNT]`）。
  ///
  /// 每项是 `MakeNewItem` 的编码：`耐久 << 8 | 编号`。
  /// `GIVEITEMTO` 往这里塞东西。
  ///
  /// ## ⚠️ 必须是 **5 槽**，不是"有几件就多长"
  ///
  /// 出处：`include/bmunit.h:11` `enum { UNIT_ITEM_COUNT = 5 };`
  ///
  /// 我原来写的是 `[if (item0 != 0) item0]` —— 一个**只有 1 个元素的表**。
  /// 后果有两个，**都不报错**：
  ///
  /// 1. `UnitAddItem`（第一个空槽）永远找不到空槽
  ///    → `GIVEITEMTO` 永远失败 → **序章里艾莉卡拿不到细剑**，没有武器
  /// 2. `UnitDefinition.items[1..3]` 被丢掉
  ///    → 赛特本该带 3 件（`{0x03, 0x17, 0x6C}`），实际只剩 1 件
  ///
  /// 装载规则（`src/UnitInitFromDefinition.c:62`）：
  ///
  /// ```c
  /// for (i = 0; (i < UNIT_DEFINITION_ITEM_COUNT) && (uDef->items[i]); ++i)
  ///     UnitAddItem(unit, MakeNewItem(uDef->items[i]));
  /// ```
  late final List<int> items = _buildInventory(_initItems, item0);
  final List<int>? _initItems;

  final int classId;
  final int level;

  /// 移动力
  final int movement;

  int hp;
  int maxHp;

  /// 本回合是否已行动
  bool hasActed;

  /// 体格（`UNIT_CON`；原作从职业的 `baseCon` 来，加道具加成）
  int con;

  /// 救出关系（对应 `actor->rescue` / `target->rescue`；0 = 无）
  int rescueIndex;

  /// `US_RESCUING` / `US_RESCUED` / `US_HIDDEN` / `US_UNSELECTABLE`
  bool isRescuing;
  bool isRescued;
  bool isHidden;
  bool unselectable;

  final String name;

  /// 阵营位
  int get factionBit => faction & 0x80;

  bool get isAlive => hp > 0;

  /// `UnitAddItem` —— 放进第一个空槽。满了返回 `-1`（调用方必须处理）。
  int addItem(int item) => unitAddItem(items, item);

  /// 道具栏**非空**项（`0` 是空槽）
  List<int> get heldItems => items.where((i) => i != 0).toList();

  /// 构造时的道具栏：显式给了就用它，否则从 `item0` 起。
  ///
  /// 两条路都**补齐到 `UNIT_ITEM_COUNT` 槽** —— 见 [items] 的说明。
  static List<int> _buildInventory(List<int>? given, int item0) {
    final inv = unitClearInventory();
    if (given != null) {
      for (var i = 0; i < given.length && i < unitItemCount; ++i) {
        inv[i] = given[i];
      }
    } else if (item0 != 0) {
      inv[0] = item0;
    }
    return inv;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'faction': faction,
        'x': x,
        'y': y,
        'classId': classId,
        'level': level,
        'movement': movement,
        'hp': hp,
        'maxHp': maxHp,
        'hasActed': hasActed,
        'name': name,
        // 道具栏也要进存档 —— 它是 `struct Unit.items[UNIT_ITEM_COUNT]`，
        // 漏了它「存档后武器不见了」是必然的（现在至少不会被静默丢掉）
        'items': items,
        'charIndex': charIndex,
      };

  factory MapUnit.fromJson(Map<String, dynamic> j) => MapUnit(
        id: j['id'] as int,
        faction: j['faction'] as int,
        x: j['x'] as int,
        y: j['y'] as int,
        classId: j['classId'] as int? ?? 0,
        level: j['level'] as int? ?? 1,
        movement: j['movement'] as int? ?? 5,
        hp: j['hp'] as int? ?? 20,
        maxHp: j['maxHp'] as int? ?? 20,
        hasActed: j['hasActed'] as bool? ?? false,
        name: j['name'] as String? ?? '',
        charIndex: j['charIndex'] as int? ?? 0,
        items: (j['items'] as List?)?.cast<int>(),
      );
}

/// 战场：一组单位 + 当前回合信息。
///
/// **完全可序列化**——这是"任意时刻存档"的基础。
class BattleField {
  BattleField({
    required this.width,
    required this.height,
    List<MapUnit>? units,
    this.turn = 1,
    this.activeFaction = Faction.blue,
  }) : units = units ?? [];

  final int width;
  final int height;
  final List<MapUnit> units;

  int turn;

  /// 当前行动阵营（`Faction.*`）
  int activeFaction;

  MapUnit? unitAt(int x, int y) {
    for (final u in units) {
      if (u.isAlive && u.x == x && u.y == y) return u;
    }
    return null;
  }

  MapUnit? unitById(int? id) {
    if (id == null) return null;
    for (final u in units) {
      if (u.id == id) return u;
    }
    return null;
  }

  /// 这个单位是否属于当前行动阵营、且可被玩家操控。
  ///
  /// 用 [PhaseRules.isSameAllegiance] 而不是 [PhaseRules.areUnitsAllied]：
  /// "同盟"包含友军 NPC，而友军 NPC 不由玩家操控。
  bool isControllable(MapUnit u) =>
      PhaseRules.isSameAllegiance(u.faction, activeFaction);

  /// 换掉某个单位（阵营变了之类 —— `MapUnit.faction` 是 final）。
  ///
  /// `UnitChangeFaction`（`src/eventscr_0800F8D4.c:62`）的等价物。
  BattleField withUnitReplaced(int id, MapUnit replacement) => BattleField(
        width: width,
        height: height,
        turn: turn,
        activeFaction: activeFaction,
        units: [
          for (final u in units)
            if (u.id == id) replacement else u,
        ],
      );

  /// 把单位移动到新位置
  void moveUnit(MapUnit u, int x, int y) {
    u.x = x;
    u.y = y;
  }

  /// 结束当前单位行动
  void finishUnit(MapUnit u) => u.hasActed = true;

  /// 把地图单位转成 `PhaseRules` 需要的最小视图。
  ///
  /// ⚠️ **`hasActed` 对应 `US_UNSELECTABLE`**，不是 `US_HAS_MOVED`。
  /// 原版里这两个是不同的位：
  ///   * `US_UNSELECTABLE` —— 灰掉、本回合不能再动（`GetPhaseAbleUnitCount` 的 notAble 掩码里有它）
  ///   * `US_HAS_MOVED`    —— 已经移动过（用于再移动 / Canto），**不在**掩码里，
  ///                          所以"移动过但还能再动"的单位仍然会被计入
  /// 把两者当成一个，会让再移动类单位在移动后立刻被判定为"已行动"。
  List<PhaseUnit?> toPhaseUnits() {
    final arr = List<PhaseUnit?>.filled(0x100, null);
    for (final u in units) {
      if (u.id < 0 || u.id >= 0x100) continue;
      arr[u.id] = PhaseUnit(
        faction: u.faction,
        state: u.isAlive ? (u.hasActed ? UnitState.unselectable : 0)
                         : UnitState.dead,
        statusIndex: UnitStatus.none,
        classAttributes: 0,
        hasCharacterData: true,
      );
    }
    return arr;
  }

  /// `GetPhaseAbleUnitCount(faction)`
  ///
  /// 直接用规则层的实现，不在表现层另写一套。
  int phaseAbleCount(int faction) =>
      PhaseRules.getPhaseAbleUnitCount(toPhaseUnits(), faction);

  /// 本回合还能行动的**我方**单位数
  int get actionableCount =>
      units.where((u) => u.isAlive && !u.hasActed && isControllable(u)).length;

  /// `ClearActiveFactionGrayedStates` 的核心：清掉当前阵营的灰化标记。
  ///
  /// 原版在阶段开始时调用它，把 `US_UNSELECTABLE | US_HAS_MOVED | US_HAS_MOVED_AI`
  /// 一起清掉——这正是"新回合所有单位又能动了"的机制。
  void clearActiveFactionGrayedStates() {
    for (final u in units) {
      if (PhaseRules.isSameAllegiance(u.faction, activeFaction)) {
        u.hasActed = false;
      }
    }
  }

  /// 是否所有我方单位都行动完了 —— 可以结束回合
  bool get allActed => actionableCount == 0;

  Map<String, dynamic> toJson() => {
        'width': width,
        'height': height,
        'turn': turn,
        'activeFaction': activeFaction,
        'units': units.map((u) => u.toJson()).toList(),
      };

  factory BattleField.fromJson(Map<String, dynamic> j) => BattleField(
        width: j['width'] as int,
        height: j['height'] as int,
        turn: j['turn'] as int? ?? 1,
        activeFaction: j['activeFaction'] as int? ?? Faction.blue,
        units: (j['units'] as List<dynamic>)
            .map((e) => MapUnit.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  String encode() => jsonEncode(toJson());

  static BattleField decode(String source) =>
      BattleField.fromJson(jsonDecode(source) as Map<String, dynamic>);
}

/// 该出现在地图上的单位：**活着且没被隐藏**。
///
/// `UnitRescue`（`src/exact_08018060.c:37-46`）会给被救者置 `US_HIDDEN`
/// —— 被扛在肩上的人**不该画在地图上**。渲染层与转储自检**都用这一个定义**，
/// 免得"画出来的"和"判据说该有的"各算各的（这个仓库为此吃过亏）。
List<MapUnit> visibleUnits(BattleField f) =>
    [for (final u in f.units) if (u.isAlive && !u.isHidden) u];
