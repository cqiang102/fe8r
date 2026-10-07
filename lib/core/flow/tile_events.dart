// PORT OF: src/bmmenu_08022F50.c:89-118（`VisitCommandUsability`）
//          src/VisitCommandEffect.c:50-59（`VisitCommandEffect`）
//          src/StartAvailableTileEvent.c:24-60（`StartAvailableTileEvent`）
//          src/eventinfo_080851B8.c:88-94（`struct EvCheck05 { unk0; script; u8 x; u8 y; u16 cmdId; }`）
//          `layout`/`constants`：`TILE_COMMAND_VISIT`（数据里是 `cmdId = 0x10`）
//
// # 「訪問（村/家）」的规则层
//
// 可用性（`VisitCommandUsability`）：
//   1. 幻影职业 ⇒ `MENU_NOTSHOWN`；
//   2. `gActiveUnit->state & US_HAS_MOVED` ⇒ `MENU_NOTSHOWN`；
//   3. 地形必须是 `TERRAIN_HOUSE / INN / RUINS_VILLAGE / VILLAGE_REGULAR`；
//   4. `GetAvailableTileEventCommand(x, y) == TILE_COMMAND_VISIT`
//      —— 即在章节的 **`locationBasedEvents`** 列表里，有一条 (x,y) 对得上、
//      `cmdId == 0x10`、且 `doneFlag` **未置位**的条目；
//   5. 沉默状态 ⇒ `MENU_DISABLED`（我们还没做状态系统）。
//
// ⚠️ **`US_HAS_MOVED` 的映射**：它在源码里只在**晋升**与
// `ClearActiveFactionGrayedStates`（阶段结束）里被置/清，移动流程里没有它
// ⇒ 行动菜单出现时它是**清零**的（所以原作允许"走到村口再訪問"）。
// 我们对应成"这个单位还没行动过"（`!hasActed`），并在这里写明这层映射。

/// `cmdId == 0x10` ⇒ `TILE_COMMAND_VISIT`（数据里 `Ch14b_Location` 那条 VILL 就是 0x10）
const int kTileCommandVisit = 0x10;

/// 可以「訪問」的地形（`VisitCommandUsability` 的 switch）
const Set<int> kVisitTerrains = {
  3, // TERRAIN_VILLAGE_REGULAR
  5, // TERRAIN_HOUSE
  55, // TERRAIN_RUINS_VILLAGE
  56, // TERRAIN_INN
};

/// 章节的 `locationBasedEvents` 里的一条（只留我们判据要用的字段）
class LocationEvent {
  const LocationEvent({
    required this.cmd,
    required this.x,
    required this.y,
    required this.cmdId,
    required this.doneFlag,
    this.script,
    this.givenItem = 0,
    this.givenMoney = 0,
  });

  final String cmd;
  final int x;
  final int y;
  final int cmdId;
  final int doneFlag;
  final String? script;

  /// `CHES` 条目里的宝箱内容（`struct EvCheck07 { u32 unk0; u16 givenItem;
  /// u16 givenMoney; u8 x; u8 y; u16 cmdId; }`，`src/exact_08085cc4.c:95-102`）。
  /// ⚠️ 数据里 12 条 CHES **全是具体道具**；`givenItem == 0` 的"按概率表抽"
  /// 在数据里不出现，且那是 `StartAvailableTileEvent` 读了 `info.script` 当表指针
  /// —— 而 `EvCheck07_CHES` 的实现**不在反编译里** ⇒ 不实现（不编）。
  final int givenItem;
  final int givenMoney;
}

/// `SearchAvailableEvent` 对这一族条目的匹配：坐标 + `cmdId` + **`doneFlag` 未置位**。
///
/// 返回命中的那条（没有就 null）。调用方拿 `script` 去跑事件、拿 `doneFlag` 去置位。
LocationEvent? availableTileEvent(
  List<LocationEvent> events,
  int x,
  int y,
  Set<int> flags,
) {
  for (final e in events) {
    if (e.x != x || e.y != y) continue;
    if (e.doneFlag != 0 && flags.contains(e.doneFlag)) continue;
    return e;
  }
  return null;
}

/// 「訪問」这一项该不该出现（完整判据；`TERRAIN_*` 的编号来自 `terrains.json` 的枚举）
bool visitAvailable({
  required int terrainId,
  required bool isPhantom,
  required bool hasActed,
  required bool hasAvailableVill,
}) {
  if (isPhantom) return false;
  if (hasActed) return false; // 对应 `US_HAS_MOVED`（见文件头）
  if (!kVisitTerrains.contains(terrainId)) return false;
  return hasAvailableVill;
}

// ---------------------------------------------------------------------------
// 制圧（`TILE_COMMAND_SEIZE`）
// ---------------------------------------------------------------------------

/// `TILE_COMMAND_SEIZE = 0x11`（`include/eventinfo.h:15`）
const int kTileCommandSeize = 0x11;

/// `CanUnitSeize`（`src/masked_08037bfc.c:50-70`）：
///
/// ```c
/// switch (gPlaySt.chapterModeIndex) {
///     case 2: leaderId = CHARACTER_EIRIKA;  break;   // Eirika 路线
///     case 1: leaderId = CHARACTER_EIRIKA;  break;   // 教学（第 0–8 章）
///     case 3: leaderId = CHARACTER_EPHRAIM; break;   // Ephraim 路线
/// }
/// if (gPlaySt.chapterIndex == 5) leaderId = CHARACTER_EPHRAIM;   // 第 5 章特例
/// return unit->pCharacterData->number == leaderId;
/// ```
///
/// ⚠️ 原作里 `chapterModeIndex` 不在 {1,2,3} 时 `leaderId` **未初始化**（C 的坑）
/// ⇒ 我们**不照抄这个未定义行为**：返回 [kSeizeLeaderUnknown] 并让调用方判假 + 留痕。
const int kSeizeLeaderUnknown = -1;

/// 领袖角色编号（`CHARACTER_EIRIKA = 1` / `CHARACTER_EPHRAIM = 2`，见下）
int seizeLeaderId({required int chapterModeIndex, required int chapterIndex}) {
  int leader;
  switch (chapterModeIndex) {
    case 2:
    case 1:
      leader = kCharacterEirika;
    case 3:
      leader = kCharacterEphraim;
    default:
      return kSeizeLeaderUnknown;
  }
  if (chapterIndex == 5) leader = kCharacterEphraim;
  return leader;
}

/// `CHARACTER_EIRIKA` / `CHARACTER_EPHRAIM`（`include/constants/characters.h`）
const int kCharacterEirika = 1;
const int kCharacterEphraim = 2;

/// 「制圧」这一项该不该出现
///
/// 出处：`UnitActionMenu_CanSeize`（`src/bmmenu_08022F50.c:68-80`）——
/// `!US_HAS_MOVED`（我们映射成 `!hasActed`，同 `visitAvailable`）+ `CanUnitSeize`
/// + 该格 `cmdId == 0x11`。
bool seizeAvailable({
  required bool hasActed,
  required bool canSeize,
  required bool hasSeizeTile,
}) {
  if (hasActed) return false;
  if (!canSeize) return false;
  return hasSeizeTile;
}

// ---------------------------------------------------------------------------
// 宝箱（`TILE_COMMAND_CHEST`）
// ---------------------------------------------------------------------------

/// `TILE_COMMAND_CHEST = 0x14`（`include/eventinfo.h:19`）
const int kTileCommandChest = 0x14;

/// `TERRAIN_CHEST_FULL`（编号见 `tools/pipeline/out/tables/terrains.json` 的枚举）
const int kTerrainChestFull = 33;

/// `GetUnitKeyItemSlotForTerrain`（`src/bmunit_080187B0.c:39-58`）：
///
/// ```c
/// if (UNIT_CATTRIBUTES(unit) & CA_THIEF) {
///     int slot = GetUnitItemSlot(unit, ITEM_LOCKPICK);
///     if (slot >= 0) return slot;
/// }
/// switch (terrain) {
/// case TERRAIN_CHEST_FULL:
///     slot = GetUnitItemSlot(unit, ITEM_CHESTKEY);
///     if (slot < 0) slot = GetUnitItemSlot(unit, ITEM_CHESTKEY_BUNDLE);
///     return slot;
/// case TERRAIN_DOOR:
///     item = ITEM_DOORKEY; break;
/// }
/// return GetUnitItemSlot(unit, item);
/// ```
///
/// 返回**槽位下标**（-1 = 没有能开它的道具）。
int unitKeyItemSlotForTerrain({
  required bool isThief,
  required List<int> items,
  required int terrainId,
  required int lockpickItem,
  required int chestKeyItem,
  required int chestKeyBundleItem,
}) {
  int slotOf(int item) => items.indexOf(item);
  if (isThief) {
    final s = slotOf(lockpickItem);
    if (s >= 0) return s;
  }
  if (terrainId == kTerrainChestFull) {
    final s = slotOf(chestKeyItem);
    return s >= 0 ? s : slotOf(chestKeyBundleItem);
  }
  return -1; // 门/吊桥另论（见路线图欠账 50）
}

/// `CanUnitUseChestKeyItem`（`src/CanUnitUseChestKeyItem.c:34-43`）：
/// **只看地形 + 那格有没有关着的宝箱**（不看道具）。
bool canUnitUseChestKeyItem({
  required int terrainId,
  required bool hasClosedChestTile,
}) =>
    terrainId == kTerrainChestFull && hasClosedChestTile;

/// 「宝箱」这一项该不该出现
///
/// 出处：`ChestCommandUsability`（`src/bmmenu_08023D5C.c:85-97`）——
/// `!US_HAS_MOVED`（映射 `!hasActed`）+ 有能开的道具（钥匙/盗贼的撬锁器）
/// + `CanUnitUseChestKeyItem`。
bool chestAvailable({
  required bool hasActed,
  required bool hasClosedChestTile,
  required bool hasKeyOrLockpick,
  required int terrainId,
}) {
  if (hasActed) return false;
  if (!hasKeyOrLockpick) return false;
  return canUnitUseChestKeyItem(
      terrainId: terrainId, hasClosedChestTile: hasClosedChestTile);
}

// ---------------------------------------------------------------------------
// 门 / 吊桥（`TILE_COMMAND_DOOR` / `TILE_COMMAND_BRIDGE`）
// ---------------------------------------------------------------------------

/// `TILE_COMMAND_DOOR = 0x12`、`TILE_COMMAND_BRIDGE = 0x13`（`include/eventinfo.h:17-18`）
const int kTileCommandDoor = 0x12;
const int kTileCommandBridge = 0x13;

/// 门的钥匙槽（`GetUnitKeyItemSlotForTerrain`，`src/bmunit_080187B0.c:39-58` 的
/// `case TERRAIN_DOOR: item = ITEM_DOORKEY;` 那一支）
int unitDoorKeySlot({
  required bool isThief,
  required List<int> items,
  required int lockpickItem,
  required int doorKeyItem,
}) {
  int slotOf(int item) => items.indexOf(item);
  if (isThief) {
    final s = slotOf(lockpickItem);
    if (s >= 0) return s;
  }
  return slotOf(doorKeyItem);
}

/// `IsThereClosedDoorAt`（`src/eventinfo_08085528.c:141-147`）：
/// ```c
/// if (GetAvailableTileEventCommand(x, y) == TILE_COMMAND_DOOR) return true;
/// ```
/// ⇒ 与宝箱那条完全对称：**就是"该格有可用的门事件"**。
bool isThereClosedDoorAt({required bool hasAvailableDoorEvent}) =>
    hasAvailableDoorEvent;

/// 门/吊桥的候选目标（`MakeTargetListForDoorAndBridges`，`src/bmtarget_0802506C.c:414-432`）：
/// **上下左右相邻格**里、地形是 `TERRAIN_DOOR`/`TERRAIN_BRIDGE_14`、且 `IsThereClosedDoorAt` 的。
///
/// 谓词由调用方给（核心层不持有地图）。
List<(int, int)> doorAndBridgeTargets({
  required int x,
  required int y,
  required bool Function(int x, int y) isTargetTerrain,
  required bool Function(int x, int y) isClosedDoor,
}) {
  final out = <(int, int)>[];
  for (final (dx, dy) in const [(0, -1), (0, 1), (-1, 0), (1, 0)]) {
    final nx = x + dx;
    final ny = y + dy;
    if (isTargetTerrain(nx, ny) && isClosedDoor(nx, ny)) out.add((nx, ny));
  }
  return out;
}

/// 「扉」这一项该不该出现
///
/// 出处：`DoorCommandUsability`（`src/bmmenu_08023D5C.c:58-72`）——
/// `!US_HAS_MOVED` + 钥匙槽 `>= 0` + 目标列表非空。
bool doorAvailable({
  required bool hasActed,
  required bool hasKeyOrLockpick,
  required bool hasTarget,
}) {
  if (hasActed) return false;
  if (!hasKeyOrLockpick) return false;
  return hasTarget;
}
