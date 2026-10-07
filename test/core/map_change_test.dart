// 地形变化（`ApplyMapChangesById`）的判据。
//
// 出处：`src/masked_0802e4c4.c`（稀疏语义）、`src/sub_800BDE8.c`（`TriggerMapChanges`）、
//       `include/types.h:395-402`（`struct MapChange`）。
import 'package:fe8r/core/core.dart';
import 'package:flutter_test/flutter_test.dart';

MapGrid grid() => MapGrid(
      id: 't',
      chapter: '',
      width: 4,
      height: 4,
      tileSize: 16,
      metatiles: List<int>.generate(16, (i) => 100 + i),
      terrainIndices: List<int>.filled(16, 1),
      terrainLegend: const ['TERRAIN_PLAINS', 'TERRAIN_DOOR'],
    );

MapChangeRecord rec({List<int> tiles = const [7, 0, 8, 0]}) => MapChangeRecord(
      id: 3, xOrigin: 1, yOrigin: 1, xSize: 2, ySize: 2, tiles: tiles);

void main() {
  test('★ `0` 是"这格不动"，不是"写成 0"（写反了地图会出空洞）', () {
    final g = grid();
    final before = [for (var i = 0; i < 16; i++) g.metatileAt(i % 4, i ~/ 4)];
    expect(g.applyMapChange(rec()), isTrue);
    // (1,1) 写成 7；(2,1) 保持原值（因为数据里是 0）；(1,2) 写成 8；(2,2) 不动
    expect(g.metatileAt(1, 1), 7);
    expect(g.metatileAt(2, 1), before[1 * 4 + 2], reason: '0 ⇒ 不动');
    expect(g.metatileAt(1, 2), 8);
    expect(g.metatileAt(2, 2), before[2 * 4 + 2], reason: '0 ⇒ 不动');
    // 范围外的一格没被碰
    expect(g.metatileAt(0, 0), before[0]);
  });

  test('★ 同一条变更**只应用一次**（`IsMapChangeEnabled` ⇒ `return`）', () {
    final g = grid();
    expect(g.applyMapChange(rec()), isTrue);
    expect(g.appliedMapChanges.contains(3), isTrue);
    expect(g.applyMapChange(rec(tiles: const [99, 99, 99, 99])), isFalse,
        reason: '已经应用过 ⇒ 第二次直接返回 false，不再改地图');
    expect(g.metatileAt(1, 1), 7, reason: '第二次的那份数据不该生效');
  });

  test('越界与数据过短都不崩', () {
    final g = grid();
    // 原点在右下角、尺寸超出地图
    expect(
        g.applyMapChange(const MapChangeRecord(
            id: 9, xOrigin: 3, yOrigin: 3, xSize: 3, ySize: 3,
            tiles: [1, 2, 3, 4, 5, 6, 7, 8, 9])),
        isTrue);
    expect(g.metatileAt(3, 3), 1);
    // 数据比 xSize*ySize 短 ⇒ 读多少算多少，不越界
    final g2 = grid();
    g2.applyMapChange(const MapChangeRecord(
        id: 10, xOrigin: 0, yOrigin: 0, xSize: 4, ySize: 4, tiles: [5]));
    expect(g2.metatileAt(0, 0), 5);
  });

  test('换地形（门开了变地板）：`terrainAt` 跟着走', () {
    final g = grid();
    expect(g.terrainNameAt(1, 1), 'TERRAIN_DOOR');
    g.applyTerrainOverride(1, 1, 0);
    expect(g.terrainNameAt(1, 1), 'TERRAIN_PLAINS');
    // ⚠️ **不要**用 `terrainAt(x,y).id` 判图例下标 —— `TerrainType.id` 是地形类型
    // 自己的编号，**不是** `terrainIndices` 里的图例下标（第 33 轮就踩过，
    // 这次又踩了一回 ✗）。判据一律走 `terrainNameAt`（它按 `terrainLegend` 取）。
    expect(g.terrainNameAt(2, 1), 'TERRAIN_DOOR', reason: '别的格子不受影响');
  });

  test('纯函数版与网格版语义一致（稀疏 0）', () {
    final out = applyMapChangeToTiles(
        metatiles: List<int>.generate(16, (i) => 100 + i),
        width: 4, height: 4, r: rec());
    expect(out[1 * 4 + 1], 7);
    expect(out[1 * 4 + 2], 100 + 1 * 4 + 2, reason: '0 ⇒ 不动');
    expect(out[2 * 4 + 1], 8);
  });
}
