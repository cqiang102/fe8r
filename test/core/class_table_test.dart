// 职业表（地形加成 / 移动消耗）的测试。
//
// 数据由 tools/pipeline/extract/parse_class_tables.py 从
// src/data/data_classes.c 提取，并校验所有引用的表名真实存在。
// 这里验证**语义**：
//   1. 地形加成是**按职业**查的，飞行职业走 `_Fly` 表
//   2. 移动消耗表是**按职业、按天气**的三张
//   3. 武器射程是编码射程的高/低 4 位
import 'dart:io';

import 'package:fe8r/core/core.dart';
import 'package:flutter_test/flutter_test.dart';

const _tables = 'tools/pipeline/out/tables';

void main() {
  group('职业表与地形加成', () {
    late ClassTable t;

    setUpAll(() {
      final cf = File('$_tables/classes.json');
      final tf = File('$_tables/terrains.json');
      if (!cf.existsSync() || !tf.existsSync()) {
        fail('缺少数据表，先跑 tools/pipeline/extract/parse_class_tables.py');
      }
      t = ClassTable.parse(cf.readAsStringSync(), tf.readAsStringSync());
    });

    test('职业表非空，且覆盖了步兵与飞行两类', () {
      expect(t.byNumber.length, greaterThan(100));
      final fly = t.byNumber.values
          .where((c) => c.terrainAvoidTable.endsWith('_Fly'))
          .length;
      final common = t.byNumber.values
          .where((c) => c.terrainAvoidTable.endsWith('_Common'))
          .length;
      expect(fly, greaterThan(0));
      expect(common, greaterThan(50));
    });

    test('森林对步兵加回避，对飞行不加', () {
      const forest = 0x05; // TERRAIN_FOREST
      final infantry = t.byNumber.values
          .firstWhere((c) => c.terrainAvoidTable == 'TerrainTable_Avo_Common');
      final flier = t.byNumber.values
          .firstWhere((c) => c.terrainAvoidTable == 'TerrainTable_Avo_Fly');

      final infAvo = t.terrainBonuses(infantry.number, forest).avoid;
      final flyAvo = t.terrainBonuses(flier.number, forest).avoid;

      expect(infAvo, greaterThan(0), reason: '步兵躲森林应当有回避加成');
      expect(flyAvo, 0, reason: '飞行职业用 _Fly 表，地形回避为 0');
      expect(infAvo, isNot(flyAvo),
          reason: '按职业查表的意义就在这里；全局一张表会让两者相等');
    });

    test('平原不给任何加成', () {
      const plains = 0x01;
      for (final c in t.byNumber.values.take(20)) {
        final tb = t.terrainBonuses(c.number, plains);
        final a = tb.avoid, d = tb.defense;
        expect(a, 0);
        expect(d, 0);
      }
    });

    test('未知职业 / 越界地形返回 (0,0)，而不是抛异常', () {
      expect(t.terrainBonuses(9999, 1), (avoid: 0, defense: 0));
      expect(t.terrainBonuses(1, 999), (avoid: 0, defense: 0));
      expect(t.terrainBonuses(1, -1), (avoid: 0, defense: 0));
    });

    test('移动消耗表是按职业按天气的三张', () {
      final c = t.byNumber.values
          .firstWhere((x) => x.movCostTables != null && x.movCostTables!.length == 3);
      final n = t.movementCosts(c.number, Weather.normal);
      final r = t.movementCosts(c.number, Weather.rain);
      final s = t.movementCosts(c.number, Weather.snow);
      expect(n, isNotNull);
      expect(r, isNotNull);
      expect(s, isNotNull);
      expect(n!.length, 65);
      // 三张表不应当完全一样（否则"按天气"就没意义了）
      expect([n, r, s].any((x) => x!.join() != n.join()), isTrue);
    });

    test('没有移动消耗表的职业返回 null（不是空表）', () {
      final noTable = t.byNumber.values.firstWhere(
        (x) => x.movCostTables == null,
        orElse: () => throw StateError('应当存在没有移动表的职业'),
      );
      expect(t.movementCosts(noTable.number, Weather.normal), isNull);
    });

    test('不可通行在地形消耗表里是 255（与移动范围的红线一致）', () {
      final c = t.byNumber.values.firstWhere((x) => x.movCostTables != null);
      final costs = t.movementCosts(c.number, Weather.normal)!;
      expect(costs[0], 255, reason: 'TERRAIN_NONE 必须不可通行');
    });
  });

  group('武器射程（编码射程的高/低 4 位）', () {
    test('1 格武器 = 0x11，2 格 = 0x22，1-2 格 = 0x12', () {
      final t = ItemTable(4);
      t[1].encodedRange = 0x11;
      t[2].encodedRange = 0x22;
      t[3].encodedRange = 0x12;

      expect(t.minRangeOf(1), 1);
      expect(t.maxRangeOf(1), 1);
      expect(t.minRangeOf(2), 2);
      expect(t.maxRangeOf(2), 2);
      expect(t.minRangeOf(3), 1);
      expect(t.maxRangeOf(3), 2);
    });

    test('直接把整字节当射程会算错', () {
      final t = ItemTable(2);
      t[1].encodedRange = 0x11;
      // 0x11 = 17，不是 1 —— 这是"忘了拆半字节"的典型症状
      expect(t.encodedRangeOf(1), 17);
      expect(t.maxRangeOf(1), 1);
    });
  });
}
