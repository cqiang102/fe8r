// 序章地图上的**移动范围** —— 用真地图 + 真职业消耗表算一遍。
//
// ## 为什么需要这条
//
// 用户报过「行动力好像也不对」。移动这条链已经有两层保障：
//   * `movement_oracle_test.dart` —— 54 条**逐格** C oracle 向量（算法对）
//   * `move_costs.dart` 的头注释 —— 记着"演示表导致山峰可走"那个已修的 bug
// 缺的是**序章这张真地图 + 真职业表**上的端到端抽查：这里补上，并且和
// 真机转储（`scenario.sh range` 的 `range.count`）互相印证 ——
// 两条独立路径给出同一个数，才算"接线也对"。
//
// 出处：
//   * 算法 `GenerateMovementMap`（`src/movement_08018C74.c:42`）
//   * 消耗表 `pMovCostTable[0..2]`（`src/masked_08018a60.c:44-51`）
//   * 数据 `assets/maps/PrologueMap.json` + `classes.json` + `terrains.json`
import 'dart:convert';
import 'dart:io';

import 'package:fe8r/core/core.dart';
import 'package:flutter_test/flutter_test.dart';

MapGrid _prologueGrid() {
  final m = jsonDecode(File('assets/maps/PrologueMap.json').readAsStringSync())
      as Map<String, dynamic>;
  final legend = (m['terrainLegend'] as List).cast<String>();
  return MapGrid(
    id: m['id'] as String,
    chapter: m['chapter'] as String? ?? '',
    width: m['width'] as int,
    height: m['height'] as int,
    tileSize: m['tileSize'] as int,
    metatiles: (m['grid'] as List).cast<int>(),
    terrainIndices: (m['terrainIndex'] as List).cast<int>(),
    terrainLegend: legend,
  );
}

void main() {
  test('★ 帕拉丁（赛特）在序章地图 (4,4) 的可达格数 = 20，与真机转储一致', () {
    final table = ClassTable.parse(
      File('tools/pipeline/out/tables/classes.json').readAsStringSync(),
      File('tools/pipeline/out/tables/terrains.json').readAsStringSync(),
    );
    // CLASS_PALADIN = 7（`classes.json` 的 classEnum）
    final costs = table.movementCosts(7, Weather.normal);
    expect(costs, isNotNull, reason: '帕拉丁必须有消耗表');
    expect(costs!.length, greaterThan(0x12), reason: '至少覆盖到 TERRAIN_PEAK(0x12)');

    final grid = _prologueGrid();
    expect(grid.width, 15);
    expect(grid.height, 10);

    final range = MovementRangeComputer.compute(
      map: grid,
      costTable: MovementCostTable(costs),
      x: 4,
      y: 4,
      movement: 8, // CLASS_PALADIN.baseMov（`classes.json`）
    );
    // ★ 真机 `scenario.sh range` 的转储里 `range.count` 也是 20 —— 两条独立路径
    expect(range.reachableCount, 20);
  });

  test('★ 山峰（`TERRAIN_PEAK`）不可通行：101 格山峰一格都进不去', () {
    final grid = _prologueGrid();
    final terrains0 = jsonDecode(
        File('tools/pipeline/out/tables/terrains.json').readAsStringSync())
        as Map<String, dynamic>;
    final enums0 = (terrains0['enum'] ?? terrains0['enums']) as Map<String, dynamic>;
    // ⚠️ `MapGrid.terrainAt` 返回的是 **`TerrainType` 对象**（取 id 要 `.id`）——
    // 不是 legend 下标、也不是裸 int。我连错两次（`.id` 前比了一次 int、又比了一次下标）。
    // legend 是"这张图用到了哪几种地形"的压缩表，而消耗表按**地形 id** 索引。
    // 我第一版拿 legend 下标去比，于是"山峰格数 = 0"（假红）。
    final peakId = enums0['TERRAIN_PEAK'] as int;
    final peaks = <String>[
      for (var y = 0; y < grid.height; y++)
        for (var x = 0; x < grid.width; x++)
          if (grid.terrainAt(x, y).id == peakId) '$x,$y',
    ];
    // 地形直方图（真机日志）：PEAK×101
    expect(peaks.length, 101, reason: '序章地图的山峰格数');

    final table = ClassTable.parse(
      File('tools/pipeline/out/tables/classes.json').readAsStringSync(),
      File('tools/pipeline/out/tables/terrains.json').readAsStringSync(),
    );
    final costs = table.movementCosts(7, Weather.normal)!;
    final range = MovementRangeComputer.compute(
      map: grid,
      costTable: MovementCostTable(costs),
      x: 4,
      y: 4,
      movement: 8,
    );
    final bad = peaks.where((t) {
      final p = t.split(',');
      return range.canReach(int.parse(p[0]), int.parse(p[1]));
    }).toList();
    expect(bad, isEmpty, reason: '这些山峰被当成了可通行：${bad.take(5)}');
  });

  test('★ 消耗表的真值抽查（源码 `TerrainTable_MovCost_HorseT2Normal`）', () {
    final terrains = jsonDecode(
        File('tools/pipeline/out/tables/terrains.json').readAsStringSync())
        as Map<String, dynamic>;
    final enums = (terrains['enum'] ?? terrains['enums']) as Map<String, dynamic>;
    int id(String name) => enums[name] as int;

    final table = ClassTable.parse(
      File('tools/pipeline/out/tables/classes.json').readAsStringSync(),
      File('tools/pipeline/out/tables/terrains.json').readAsStringSync(),
    );
    final costs = table.movementCosts(7, Weather.normal)!;
    // 源码里那三行（`src/data/data_terrains.c` 的指定初始化）：
    //   [TERRAIN_PLAINS] = 1 / [TERRAIN_FORT] = 2 / [TERRAIN_PEAK] = -1（s8）
    // 我们这层按 s8 → u8 转过，所以 -1 读作 255。
    expect(costs[id('TERRAIN_PLAINS')], 1);
    expect(costs[id('TERRAIN_FORT')], 2);
    expect(costs[id('TERRAIN_PEAK')], 255, reason: '-1（不可通行）转成 u8 是 255');
    // 帕拉丁是**上级**骑兵 ⇒ 用的是 T2 那三张表，不是 T1
    final classes = jsonDecode(
        File('tools/pipeline/out/tables/classes.json').readAsStringSync())
        as Map<String, dynamic>;
    final pal = (classes['classes'] as Map<String, dynamic>)['CLASS_PALADIN']
        as Map<String, dynamic>;
    expect((pal['pMovCostTable'] as List).first, contains('HorseT2'));
  });
}
