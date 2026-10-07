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
  });

  final String cmd;
  final int x;
  final int y;
  final int cmdId;
  final int doneFlag;
  final String? script;
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
