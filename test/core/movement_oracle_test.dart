// 移动范围与 C Oracle 逐格一致。
//
// 期望值由 tools/oracle/ 里**真实的 C 代码**产出：
//   MapFloodCoreStep  = src/MapFloodCoreStepThumb.c
//   MapFloodCore      = src/arm.s 的重构源码（见 scenarios/movement.c 的说明）
//
// 单位格与地形格由用例的 terrain / unit 字段构造，两端必须完全对称，
// 否则比的就是"两套不同的输入"而不是"两套实现"。
import 'dart:io';

import 'package:fe8r/core/core.dart';
import 'package:flutter_test/flutter_test.dart';

const String _vecDir = 'tools/oracle/vectors';

Map<String, Map<String, String>> _readCases(String path) {
  final out = <String, Map<String, String>>{};
  for (final line in File(path).readAsLinesSync()) {
    if (line.startsWith('#') || line.trim().isEmpty) continue;
    final parts = line.split('\t');
    final f = <String, String>{};
    for (final p in parts.skip(1)) {
      final eq = p.indexOf('=');
      if (eq > 0) f[p.substring(0, eq)] = p.substring(eq + 1);
    }
    out[parts.first] = f;
  }
  return out;
}

Map<String, String> _readExpected(String path) {
  final out = <String, String>{};
  for (final line in File(path).readAsLinesSync()) {
    if (line.startsWith('#') || line.trim().isEmpty) continue;
    final p = line.split('\t');
    if (p.length >= 2) out[p.first] = p[1];
  }
  return out;
}

List<int> _ints(String s) =>
    s.isEmpty ? const [] : s.split(',').map((x) => int.parse(x.trim())).toList();

/// 用用例里的地形网格构造一个 MapGrid。
///
/// 移动范围只用到 `terrainAt`，metatile 网格填 0 即可。
MapGrid _gridFrom(List<int> terrain, int w, int h) {
  final legend = <String>[];
  final index = <int, int>{};
  for (final t in terrain) {
    index.putIfAbsent(t, () {
      legend.add(TerrainType.fromId(t).symbolName);
      return legend.length - 1;
    });
  }
  return MapGrid(
    id: 'oracle',
    chapter: 'oracle',
    width: w,
    height: h,
    tileSize: 16,
    metatiles: List<int>.filled(w * h, 0),
    terrainIndices: terrain.map((t) => index[t]!).toList(),
    terrainLegend: legend,
  );
}

void main() {
  group('移动范围与 C Oracle 逐格一致', () {
    late Map<String, Map<String, String>> cases;
    late Map<String, String> expected;

    setUpAll(() {
      final f = File('$_vecDir/movement.cases.tsv');
      if (!f.existsSync()) {
        fail('找不到 ${f.path}。先在 tools/oracle/ 下跑 ./run_all.sh。');
      }
      cases = _readCases(f.path);
      expected = _readExpected('$_vecDir/movement.expected.tsv');
    });

    test('向量文件非空', () {
      expect(cases, isNotEmpty);
      expect(expected, isNotEmpty);
    });

    test('全部 54 条用例', () {
      final failures = <String>[];
      var checked = 0;

      for (final id in cases.keys.toList()..sort()) {
        final c = cases[id]!;
        final want = expected[id];
        if (want == null) {
          failures.add('$id: 缺少期望值');
          continue;
        }

        final w = int.parse(c['w']!);
        final h = int.parse(c['h']!);
        final terrain = _ints(c['terrain'] ?? '');
        final costs = _ints(c['costs'] ?? '');

        final grid = _gridFrom(terrain, w, h);
        final table = MovementCostTable(costs);
        final range = MovementRangeComputer.compute(
          map: grid,
          costTable: table,
          x: int.parse(c['x']!),
          y: int.parse(c['y']!),
          movement: int.parse(c['move']!),
          unitId: int.parse(c['unit'] ?? '0'),
        );

        final got = List<String>.generate(
          w * h,
          (i) => '${range.costs[i]}',
        ).join(',');

        if (got != want) {
          // 找出第一处差异，打印成网格便于定位
          final g = got.split(',').map(int.parse).toList();
          final e = want.split(',').map(int.parse).toList();
          var firstBad = -1;
          for (var i = 0; i < g.length && i < e.length; i++) {
            if (g[i] != e[i]) {
              firstBad = i;
              break;
            }
          }
          final rows = StringBuffer();
          for (var y = 0; y < h; y++) {
            final a = <String>[];
            final b = <String>[];
            for (var x = 0; x < w; x++) {
              a.add(g[y * w + x] == 255 ? '  .' : g[y * w + x].toString().padLeft(3));
              b.add(e[y * w + x] == 255 ? '  .' : e[y * w + x].toString().padLeft(3));
            }
            rows.write('      ${a.join(' ')}   |${b.join(' ')}\n');
          }
          failures.add('$id  首处不同 @${firstBad ~/ w},${firstBad % w}\n'
              '      实际        |期望\n$rows');
        }
        checked++;
      }

      expect(failures, isEmpty,
          reason: '${failures.length} 条不一致：\n${failures.take(2).join('\n')}');
      expect(checked, 54);
    });
  });
}
