// 序章单位坐标 —— **与源码逐条对照**。
//
// 出处：`src/data/worldmap_gmapunit/dat_worldmap_gmapunit_p1311.c`
// （王座厅）与 `src/data/data_prologue_event_udefs.c`（可玩地图）。
//
// 为什么要钉这个：用户报过「地图上的角色好像不太对，位置也不太对」。
// 根因有两个（都修了）：
//   ① 画面上一直是 `_makeDemoField` 里手写的演示单位
//   ② `parse_unit_defs.py` 只扫三个目录模式，漏了 2/3 的单位表
//
// 这个测试把「坐标来自源码」这件事**钉死**，将来数据覆盖变化会立刻报警。
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late Map<String, dynamic> tables;

  setUpAll(() {
    final f = File('tools/pipeline/out/tables/unit_defs.json');
    if (!f.existsSync()) {
      fail('缺 unit_defs.json —— 先跑 tools/pipeline/extract/parse_unit_defs.py');
    }
    tables = (jsonDecode(f.readAsStringSync()) as Map<String, dynamic>)['tables'] as Map<String, dynamic>;
  });

  List<Map<String, dynamic>> entries(String name) => [
        for (final e in (tables[name] as List<dynamic>))
          (e as Map<String, dynamic>),
      ];

  /// `{0}` 终止项不计
  bool isTerm(Map<String, dynamic> e) =>
      (e['charIndex'] ?? 0) == 0 && (e['classIndex'] ?? 0) == 0;

  test('★ 序章王座厅：8 个单位，坐标与源码逐条一致', () {
    final src = entries('UnitDef_Event_PrologueThroneRoomUnits')
        .where((e) => !isTerm(e))
        .toList();
    expect(src.length, 8, reason: '源码里有 8 条');

    // 逐条对照 `src/data/worldmap_gmapunit/dat_worldmap_gmapunit_p1311.c:10-17`
    const expected = [
      (197, 115, 13, 3),
      (1, 2, 14, 4),
      (2, 7, 15, 4),
      (5, 11, 11, 7),
      (6, 11, 15, 7),
      (3, 9, 7, 14),
      (192, 9, 10, 14),
      (4, 5, 11, 4),
    ];
    for (var i = 0; i < expected.length; i++) {
      final (ch, cls, x, y) = expected[i];
      expect(src[i]['charIndex'], ch, reason: '第 $i 条 charIndex');
      expect(src[i]['classIndex'], cls, reason: '第 $i 条 classIndex');
      expect(src[i]['x'], x, reason: '第 $i 条 x');
      expect(src[i]['y'], y, reason: '第 $i 条 y');
    }
  });

  test('★ 序章可玩地图：艾莉卡 (13,9)、赛特 (8,5)', () {
    final src =
        entries('UnitDef_Event_PrologueAlly').where((e) => !isTerm(e)).toList();
    expect(src.length, 2);
    expect(src[0]['charIndex'], 2); // 艾莉卡
    expect(src[0]['x'], 13);
    expect(src[0]['y'], 9);
    expect(src[1]['charIndex'], 1); // 赛特
    expect(src[1]['x'], 8);
    expect(src[1]['y'], 5);
  });

  test('★ 汇编解出的表：传令兵在第 15 行（y 是 6 位位域）', () {
    final m = entries('UnitDef_Event_PrologueMessager');
    expect(m, isNotEmpty, reason: '这张表只在 .s 里，靠 parse_unit_defs_asm.py 解');
    // 日版：x=9 y=15（美版同坐标，但 GradoRoyals 的 reda 坐标不同）
    expect(m[0]['x'], 9);
    expect(m[0]['y'], 15);
    expect(m[0]['allegiance'], 0, reason: '蓝色方');
  });

  test('★ 坐标全部落在 6 位位域内（0..63）', () {
    // `xPosition`/`yPosition` 是 6 位 —— 解错位会得到 >63 的值
    for (final e in tables.entries) {
      for (final u in (e.value as List<dynamic>)) {
        final m = u as Map<String, dynamic>;
        if (isTerm(m)) continue;
        expect(m['x'], inInclusiveRange(0, 63), reason: '${e.key} 的 x');
        expect(m['y'], inInclusiveRange(0, 63), reason: '${e.key} 的 y');
      }
    }
  });
}
