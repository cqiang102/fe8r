// 地图语义形式（MapGrid）的测试。
//
// 这里最有价值的一条是「与 GBA 原始 .mar 对照」：直接从反编译仓库读
// `PrologueMap.mar`，按 `metatileIndex = u16_le >> 5` 解出来，跟数据管线导出的
// JSON 逐格比对。也就是说，**Dart 侧的规则层数据被直接钉在了 ROM 数据上**，
// 中间任何一环（Python 管线、JSON 序列化、MapGrid 解析）出错都会被抓到。
import 'dart:io';
import 'dart:typed_data';

import 'package:fe8r/core/core.dart';
import 'package:flutter_test/flutter_test.dart';

const String _jsonPath = 'assets/maps/prologue.json';
const String _marPath =
    'third_party/fireemblem8j/graphics/map/layout/PrologueMap.mar';

void main() {
  group('MapGrid', () {
    late MapGrid grid;

    setUpAll(() {
      grid = MapGrid.parse(File(_jsonPath).readAsStringSync());
    });

    test('基本字段', () {
      expect(grid.id, 'PrologueMap');
      expect(grid.width, 15);
      expect(grid.height, 10);
      expect(grid.tileSize, 16);
      expect(grid.cellCount, 150);
      expect(grid.metatiles.length, 150);
      expect(grid.terrainIndices.length, 150);
      expect(grid.terrainLegend, isNotEmpty);
    });

    test('尺寸不符会拒绝构造', () {
      expect(
        () => MapGrid(
          id: 'bad',
          chapter: 'X',
          width: 3,
          height: 3,
          tileSize: 16,
          metatiles: [1, 2, 3], // 应为 9
          terrainIndices: List.filled(9, 0),
          terrainLegend: const ['TERRAIN_PLAINS'],
        ),
        throwsArgumentError,
      );
    });

    test('越界访问抛 RangeError', () {
      expect(() => grid.metatileAt(-1, 0), throwsRangeError);
      expect(() => grid.terrainAt(grid.width, 0), throwsRangeError);
      expect(grid.contains(0, 0), isTrue);
      expect(grid.contains(grid.width, 0), isFalse);
    });

    test('地形类型能正确解析（不是全 none）', () {
      final hist = grid.terrainHistogram();
      expect(hist.values.reduce((a, b) => a + b), grid.cellCount);
      // 序章应当有平原和山峰，且都不是 none
      expect(hist.keys, contains('TERRAIN_PLAINS'));
      final types = <TerrainType>{};
      for (var y = 0; y < grid.height; y++) {
        for (var x = 0; x < grid.width; x++) {
          types.add(grid.terrainAt(x, y));
        }
      }
      expect(types, isNot(contains(TerrainType.none)),
          reason: '所有地形名都应能映射到 TerrainType，出现 none 说明名字对不上');
    });

    test('JSON 往返无损', () {
      final again = MapGrid.fromJson(grid.toJson());
      expect(again.metatiles, grid.metatiles);
      expect(again.terrainIndices, grid.terrainIndices);
      expect(again.terrainLegend, grid.terrainLegend);
    });

    test('与 GBA 原始 .mar 逐格一致', () {
      final mar = File(_marPath);
      if (!mar.existsSync()) {
        // ⚠️ 这里原本是 `markTestSkipped` + `return` —— 而
        // `flutter test` 对 skip 返回 **0**，于是"唯一的 ROM 字节对照测试"
        // 被跳过时，整步仍记 `✓ 通过`（审计实测：`+180 ~1: All tests passed!`）。
        // 缺数据是**失败**，不是跳过。
        fail('缺少 ${mar.path}（需要 clone fireemblem8j 到 third_party/）');
      }

      // GBA 格式：每格 2 字节小端 u16，metatileIndex = 值 >> 5
      final bytes = mar.readAsBytesSync();
      expect(bytes.length, grid.cellCount * 2,
          reason: '.mar 大小应为 宽×高×2');

      final view = ByteData.sublistView(Uint8List.fromList(bytes));
      final fromRom = <int>[
        for (var i = 0; i < grid.cellCount; i++) view.getUint16(i * 2, Endian.little) >> 5,
      ];

      expect(fromRom, grid.metatiles,
          reason: 'Dart 侧解析出的 metatile 网格与 ROM 数据不一致——'
              '说明数据管线或 JSON 序列化有问题');
    });
  });
}
