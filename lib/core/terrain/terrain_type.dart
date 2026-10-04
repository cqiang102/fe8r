// PORT OF: include/constants/terrains.h
//
// 地形类型。**这是规则层数据，不是美术。**
//
// 地形类型决定：
//   * 移动消耗（每种移动类型对每种地形的 cost）
//   * 回避 / 防御加成
//   * 回复效果（城池、王座）
//   * 能否放置单位、能否作为出击点
//
// 所以它必须与反编译逐值一致，且绝不能因为"重做 UI"而改动。
// 视觉表现可以任意替换（技术方案 §4.9.5 红线）。
//
// 数值全部来自 include/constants/terrains.h，命名保持一致，便于对照。

/// 地形类型。
enum TerrainType {
  none(0x00, 'TERRAIN_NONE'),
  plains(0x01, 'TERRAIN_PLAINS'),
  road(0x02, 'TERRAIN_ROAD'),
  villageRegular(0x03, 'TERRAIN_VILLAGE_REGULAR'),
  villageClosed(0x04, 'TERRAIN_VILLAGE_CLOSED'),
  house(0x05, 'TERRAIN_HOUSE'),
  armory(0x06, 'TERRAIN_ARMORY'),
  vendor(0x07, 'TERRAIN_VENDOR'),
  arenaRegular(0x08, 'TERRAIN_ARENA_REGULAR'),
  cRoom09(0x09, 'TERRAIN_C_ROOM_09'),
  fort(0x0A, 'TERRAIN_FORT'),
  gateCastle(0x0B, 'TERRAIN_GATE_CASTLE'),
  forest(0x0C, 'TERRAIN_FOREST'),
  thicket(0x0D, 'TERRAIN_THICKET'),
  sand(0x0E, 'TERRAIN_SAND'),
  desert(0x0F, 'TERRAIN_DESERT'),
  river(0x10, 'TERRAIN_RIVER'),
  mountain(0x11, 'TERRAIN_MOUNTAIN'),
  peak(0x12, 'TERRAIN_PEAK'),
  bridgeRegular(0x13, 'TERRAIN_BRIDGE_REGULAR'),
  bridge14(0x14, 'TERRAIN_BRIDGE_14'),
  sea(0x15, 'TERRAIN_SEA'),
  lake(0x16, 'TERRAIN_LAKE'),
  floorRegular(0x17, 'TERRAIN_FLOOR_REGULAR'),
  /// FE8 未使用，FE6 遗留
  floorMagic(0x18, 'TERRAIN_FLOOR_MAGIC'),
  fenceRegular(0x19, 'TERRAIN_FENCE_REGULAR'),
  wallRegular(0x1A, 'TERRAIN_WALL_REGULAR'),
  wallDamaged(0x1B, 'TERRAIN_WALL_DAMAGED'),
  rubble(0x1C, 'TERRAIN_RUBBLE'),
  pillar(0x1D, 'TERRAIN_PILLAR'),
  door(0x1E, 'TERRAIN_DOOR'),
  throne(0x1F, 'TERRAIN_THRONE'),
  chestEmpty(0x20, 'TERRAIN_CHEST_EMPTY'),
  chestFull(0x21, 'TERRAIN_CHEST_FULL'),
  roof(0x22, 'TERRAIN_ROOF'),
  gateRegular(0x23, 'TERRAIN_GATE_REGULAR'),
  church(0x24, 'TERRAIN_CHURCH'),
  ruinsRegular(0x25, 'TERRAIN_RUINS_REGULAR'),
  cliff(0x26, 'TERRAIN_CLIFF'),
  ballistaRegular(0x27, 'TERRAIN_BALLISTA_REGULAR'),
  ballistaLong(0x28, 'TERRAIN_BALLISTA_LONG'),
  ballistaKiller(0x29, 'TERRAIN_BALLISTA_KILLER'),
  shipFlat(0x2A, 'TERRAIN_SHIP_FLAT'),
  shipWreck(0x2B, 'TERRAIN_SHIP_WRECK'),
  tile2C(0x2C, 'TERRAIN_TILE_2C'),
  stairs(0x2D, 'TERRAIN_STAIRS'),
  tile2E(0x2E, 'TERRAIN_TILE_2E'),
  glacier(0x2F, 'TERRAIN_GLACIER'),
  arena30(0x30, 'TERRAIN_ARENA_30'),
  valley(0x31, 'TERRAIN_VALLEY'),
  fence32(0x32, 'TERRAIN_FENCE_32'),
  snag(0x33, 'TERRAIN_SNAG'),
  bridgeSnag(0x34, 'TERRAIN_BRIDGE_SNAG'),
  sky(0x35, 'TERRAIN_SKY'),
  deeps(0x36, 'TERRAIN_DEEPS'),
  /// FE8 未使用，FE7 遗留
  ruinsVillage(0x37, 'TERRAIN_RUINS_VILLAGE'),
  inn(0x38, 'TERRAIN_INN'),
  barrel(0x39, 'TERRAIN_BARREL'),
  bone(0x3A, 'TERRAIN_BONE'),
  dark(0x3B, 'TERRAIN_DARK'),
  water(0x3C, 'TERRAIN_WATER'),
  gunnels(0x3D, 'TERRAIN_GUNNELS'),
  deck(0x3E, 'TERRAIN_DECK'),
  brace(0x3F, 'TERRAIN_BRACE'),
  mast(0x40, 'TERRAIN_MAST');

  const TerrainType(this.id, this.symbolName);

  /// 与 C 枚举一致的数值
  final int id;

  /// 与 C 枚举一致的名字，便于与反编译源码对照
  final String symbolName;

  /// `TERRAIN_COUNT`：有效地形的个数
  static const int count = 0x41;

  static final Map<int, TerrainType> _byId = {
    for (final t in TerrainType.values) t.id: t,
  };

  /// 按数值查地形。未知值返回 [none] 并在名字里标出原值。
  static TerrainType fromId(int id) => _byId[id] ?? TerrainType.none;

  /// 按数值给出名字。
  ///
  /// 少数地图的查表里有超出命名范围的裸值（例如 `TileConfiguration10.S:1066`
  /// 的 `0x54`），这里不隐藏它们——直接以十六进制显示，方便发现异常。
  static String nameOf(int id) =>
      _byId[id]?.symbolName ?? 'TERRAIN_UNKNOWN_0x${id.toRadixString(16).padLeft(2, '0').toUpperCase()}';
}
