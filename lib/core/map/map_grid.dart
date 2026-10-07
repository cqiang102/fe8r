// PORT OF: src/bmmap.c（gBmMapBaseTiles / gBmMapTerrain 的语义）
//
// 地图的**语义形式**：格子网格 + 地形网格。
//
// 这是技术方案 §4.3「语义形式原则」的核心产物。GBA 原版把地图信息散在五处：
//   1. `.mar` 文件（metatile 索引）
//   2. `TileConfiguration*.S`（metatile → 4 个瓦片 + 翻转 + 调色板）
//   3. 图集 PNG + `.pal`（视觉）
//   4. 地形查表（规则）
//   5. 章节配置（尺寸、雾、章节资产）
//
// 这里把它们收敛成"格子 + 地形"两个网格。至于**怎么画**是表现层的事，
// 规则层一个字都不需要知道。
//
// 纯 Dart：只用 dart:convert，不碰 dart:io / Flutter / Flame
// （由 tools/verify/check_architecture.dart 的 R1/R2 强制）。
//
// 数据文件由 tools/pipeline/extract/map_tmx.py 导出：
//   .tmx  → lib/game（Flame 渲染）
//   .json → 本文件（规则计算）
// 两者同源，因此不可能不一致。

import 'dart:convert';

import 'map_change.dart';

import '../terrain/terrain_type.dart';

/// 一张地图的语义数据。不可变。
class MapGrid {
  MapGrid({
    required this.id,
    required this.chapter,
    required this.width,
    required this.height,
    required this.tileSize,
    required List<int> metatiles,
    required List<int> terrainIndices,
    required this.terrainLegend,
  })  : metatiles = List.unmodifiable(metatiles),
        terrainIndices = List.unmodifiable(terrainIndices) {
    final expected = width * height;
    if (metatiles.length != expected) {
      throw ArgumentError('地图 $id：metatile 网格 ${metatiles.length} 格，'
          '期望 $expected（$width×$height）');
    }
    if (terrainIndices.length != expected) {
      throw ArgumentError('地图 $id：地形网格 ${terrainIndices.length} 格，'
          '期望 $expected（$width×$height）');
    }

    // 预先解析地形名 → TerrainType，避免每次查询都做字符串比较。
    // 未识别的名字保留为 none，但原字符串仍可通过 terrainNameAt 取到。
    _types = List<TerrainType>.unmodifiable(
      terrainLegend.map(_resolveType).toList(),
    );
  }

  /// 地图标识，如 `PrologueMap`
  final String id;

  /// 章节内部名，如 `L00`
  final String chapter;

  /// 宽（格）
  final int width;

  /// 高（格）
  final int height;

  /// 每格边长（像素）。原版是 16（2×2 个 8×8 瓦片）
  final int tileSize;

  /// metatile 索引网格，行优先
  final List<int> metatiles;

  /// 地形类型下标网格（指向 [terrainLegend]），行优先
  final List<int> terrainIndices;

  /// 地形名表，下标即 [terrainIndices] 里的值
  final List<String> terrainLegend;

  /// 预先解析好的地形类型，下标与 [terrainLegend] 对齐
  late final List<TerrainType> _types;

  int get cellCount => width * height;

  static TerrainType _resolveType(String name) {
    for (final t in TerrainType.values) {
      if (t.symbolName == name) return t;
    }
    return TerrainType.none;
  }

  /// 边界检查。地图外一律返回 null，让调用方显式处理越界。
  bool contains(int x, int y) => x >= 0 && y >= 0 && x < width && y < height;

  int _index(int x, int y) {
    if (!contains(x, y)) {
      throw RangeError('($x, $y) 超出地图 $id 的范围 $width×$height');
    }
    return y * width + x;
  }

  /// 该格的 metatile 索引（视觉用）
  /// 查瓦片：**先看覆盖层**（地形变化写进覆盖，底层网格不动）。
  ///
  /// ⚠️ 越界仍然**抛 `RangeError`**（沿用既有契约，`map_grid_test` 钉着它）——
  /// 我第一版照搬了游戏层那份的"越界返回 0"，把契约改掉了，测试当场红 ✗。
  int metatileAt(int x, int y) {
    final i = _index(x, y);
    return _metatileOverrides[i] ?? metatiles[i];
  }

  /// 该格的地形类型（**规则用**：移动消耗 / 回避 / 防御加成）
  /// ★ **地形变化的覆盖层**（第 51 轮）。
  ///
  /// 瓦片/地形网格本身是 `List.unmodifiable`（很多调用方依赖它不变），所以换地形
  /// 走**覆盖层** —— 等价于原作的 `gBmMapBaseTiles[y][x] = tile`
  /// （`ApplyMapChangesById`，`src/masked_0802e4c4.c`）：底层数据不动，查询先看覆盖。
  final Map<int, int> _metatileOverrides = {};
  final Map<int, int> _terrainOverrides = {};

  /// 已应用过的变更 id（对应 `EnableMapChange` / `IsMapChangeEnabled`）
  final Set<int> appliedMapChanges = {};

  /// 应用一条地形变化。返回 false = **这条已经应用过**
  /// （对应 `TriggerMapChanges` 开头的 `if (IsMapChangeEnabled(id)) return;`）。
  bool applyMapChange(MapChangeRecord r) {
    if (appliedMapChanges.contains(r.id)) return false;
    var i = 0;
    for (var iy = 0; iy < r.ySize; iy++) {
      for (var ix = 0; ix < r.xSize; ix++) {
        if (i >= r.tiles.length) {
          appliedMapChanges.add(r.id);
          return true;
        }
        final v = r.tiles[i++];
        if (v == 0) continue; // ★ `0` = 这格不动（稀疏语义）
        final gx = r.xOrigin + ix;
        final gy = r.yOrigin + iy;
        if (gx < 0 || gy < 0 || gx >= width || gy >= height) continue;
        _metatileOverrides[gy * width + gx] = v;
      }
    }
    appliedMapChanges.add(r.id);
    return true;
  }

  /// 换某一格的地形（门/桥开了会变成地板这类）
  void applyTerrainOverride(int x, int y, int terrainIndex) {
    if (x < 0 || y < 0 || x >= width || y >= height) return;
    _terrainOverrides[y * width + x] = terrainIndex;
  }

  TerrainType terrainAt(int x, int y) =>
      _types[_terrainOverrides[_index(x, y)] ?? terrainIndices[_index(x, y)]];

  /// 该格的地形名原文。未知值也能原样取到，方便发现数据异常。
  String terrainNameAt(int x, int y) => terrainLegend[
      _terrainOverrides[_index(x, y)] ?? terrainIndices[_index(x, y)]];

  /// 各地形出现次数，键是地形名
  Map<String, int> terrainHistogram() {
    final out = <String, int>{};
    for (final i in terrainIndices) {
      final n = terrainLegend[i];
      out[n] = (out[n] ?? 0) + 1;
    }
    return out;
  }

  // ------------------------------------------------------------ 序列化

  factory MapGrid.fromJson(Map<String, dynamic> json) {
    List<int> ints(String key) =>
        (json[key] as List<dynamic>).map((e) => e as int).toList();

    return MapGrid(
      id: json['id'] as String,
      chapter: json['chapter'] as String,
      width: json['width'] as int,
      height: json['height'] as int,
      tileSize: json['tileSize'] as int? ?? 16,
      metatiles: ints('grid'),
      terrainIndices: ints('terrainIndex'),
      terrainLegend: (json['terrainLegend'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
    );
  }

  /// 从 JSON 文本解析
  factory MapGrid.parse(String source) =>
      MapGrid.fromJson(jsonDecode(source) as Map<String, dynamic>);

  Map<String, dynamic> toJson() => {
        'id': id,
        'chapter': chapter,
        'width': width,
        'height': height,
        'tileSize': tileSize,
        'grid': metatiles,
        'terrainIndex': terrainIndices,
        'terrainLegend': terrainLegend,
      };

  /// 存档用。地图是静态数据，存 id 就够了，不必把网格塞进存档。
  String toSaveToken() => '$id@$chapter';

  @override
  String toString() =>
      'MapGrid($id, ${width}x$height, ${terrainLegend.length} 种地形)';
}
