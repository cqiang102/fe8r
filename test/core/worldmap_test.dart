// 大地图的两张数据表 —— 正向抽查真值，不是"文件存在"。
//
// 出处：`tools/pipeline/extract/parse_worldmap.py` 的头注释
//   * 节点 `gWMNodeData`（`struct GMapNodeData`，`include/worldmap.h:334-352`，每条 0x20 字节）
//   * 路径 `gWorldmapPath_0..19`（`struct GMapMovementPathData`，`include/worldmap.h:303-308`）
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late Map<String, dynamic> d;
  setUpAll(() {
    final f = File('tools/pipeline/out/tables/worldmap.json');
    if (!f.existsSync()) {
      fail('缺少 ${f.path}（先跑 tools/pipeline/extract/parse_worldmap.py）');
    }
    d = jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
  });

  test('★ 节点表就是 29 条（`gWMNodeData` = 29 × 0x20 字节）', () {
    final nodes = (d['nodes'] as List).cast<Map<String, dynamic>>();
    expect(nodes.length, 29);
    // 正向抽查：节点 0 是序章（`chapteridx_eirika == 0`）
    expect(nodes[0]['chapteridx_eirika'], 0);
    // 坐标必须是**非负**且在世界图范围内（解错位会立刻露出来）
    for (final n in nodes) {
      expect(n['x'], isA<int>());
      expect(n['y'], isA<int>());
      expect(n['x'] as int, greaterThanOrEqualTo(0));
      expect(n['y'] as int, greaterThanOrEqualTo(0));
    }
  });

  test('★ 路径 20 条，且 `gWorldmapPath_0` 逐点吻合', () {
    final paths = d['paths'] as Map<String, dynamic>;
    expect(paths.length, 20);
    final p0 = (paths['gWorldmapPath_0'] as List).cast<Map<String, dynamic>>();
    expect([for (final p in p0) '${p['t']},${p['x']},${p['y']}'],
        ['1351,128,88', '2703,112,72']);
  });

  test('每条路径都以 keyframe 组成、时间递增（不是空表）', () {
    final paths = d['paths'] as Map<String, dynamic>;
    for (final e in paths.entries) {
      final pts = (e.value as List).cast<Map<String, dynamic>>();
      expect(pts, isNotEmpty, reason: '${e.key} 是空的');
      var last = -1;
      for (final p in pts) {
        expect(p['t'] as int, greaterThan(last), reason: '${e.key} 时间没递增');
        last = p['t'] as int;
      }
    }
  });
}
