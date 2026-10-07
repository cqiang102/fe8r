// 敌方阶段**真的会动**吗？
//
// ## 为什么必须有这条
//
// 端到端跑"序章打到第 1 章"时发现：结束回合后回合数涨了，
// 但场上的敌人**一步没动**（奥尼尔还在 (14,8)）。
// 这种"阶段跑过了但 AI 没行动"的情况**不报错**，只表现为打不起来。
//
// 这里把三个前提分开验：
//   1. `phaseAbleCount(red)` 必须是敌人数量（否则阶段被自动跳过）
//   2. `EnemyAi.decide` 必须给出一个朝我方的落点
//   3. 用真实地图 + 真实移动力
import 'dart:io';

import 'package:fe8r/core/core.dart';
import 'package:flutter_test/flutter_test.dart';

MapGrid prologueMap() => MapGrid.parse(
    File('assets/maps/PrologueMap.json').readAsStringSync());

/// 与游戏里 `_demoCostTable()` 一致：只有 0 号地形不可通行，其余 1
MovementCostTable demoCost() {
  final c = List<int>.filled(65, 1);
  c[0] = 255;
  return MovementCostTable(c);
}

BattleField fieldWith({
  required int activeFaction,
  int sethX = 4,
  int sethY = 4,
}) =>
    BattleField(
      width: 15,
      height: 10,
      activeFaction: activeFaction,
      units: [
        // 赛特：圣骑士，`CLASS_PALADIN.baseMov = 8`
        //
        // ⚠️ 编号必须落在**阵营区块**里（`UNIT_FACTION(u) = u->index & 0xC0`，
        // `include/bmunit.h:477`）：我方 0x01..0x3F。`phaseAbleCount` 就是按
        // id 区间数的（`lib/core/battle/phase.dart:127`）—— 编号跑出区块，
        // 这个阶段会被当成"没人能动"直接跳过，AI 一步都不走。
        MapUnit(
            id: 1,
            faction: Faction.blue,
            x: sethX,
            y: sethY,
            charIndex: 2,
            classId: 7,
            movement: 8,
            name: 'SETH'),
        MapUnit(
            id: 2,
            faction: Faction.blue,
            x: 4,
            y: 5,
            charIndex: 1,
            classId: 2,
            movement: 5,
            name: 'EIRIKA'),
        // 奥尼尔：战士，`CLASS_FIGHTER.baseMov = 5`
        MapUnit(
            id: 0x81,
            faction: Faction.red,
            x: 14,
            y: 8,
            charIndex: 104,
            classId: 63,
            movement: 5,
            name: 'ONEILL'),
      ],
    );

/// 真实职业表（`classes.json` + `terrains.json`）
ClassTable realClasses() => ClassTable.parse(
      File('tools/pipeline/out/tables/classes.json').readAsStringSync(),
      File('tools/pipeline/out/tables/terrains.json').readAsStringSync(),
    );

void main() {
  test('地形表：平原可走、山峰不可走（真实 cost 表）', () {
    // `ClassData.pMovCostTable` 里，绝大多数职业 PEAK = 255（不可通行）。
    // 游戏里用的是 `_demoCostTable()`（全 1），所以山峰能爬 —— 这是**已知缺口**，
    // 见 `docs/还差什么.md`。这里只钉住"数据本身在"。
    final ct = ClassTable.parse(
      File('tools/pipeline/out/tables/classes.json').readAsStringSync(),
      File('tools/pipeline/out/tables/terrains.json').readAsStringSync(),
    );
    final paladin = ct.byNumber[7];
    expect(paladin, isNotNull);
    final cost = ct.movCost[paladin!.movCostTables![Weather.normal.tableIndex]];
    expect(cost, isNotNull, reason: '职业的移动消耗表必须能查到');
    expect(cost![TerrainType.plains.id], 1, reason: '平原消耗 1');
    expect(cost[TerrainType.peak.id], 255, reason: '山峰不可通行');
  });

  test('★ 敌方阶段有可行动单位（否则阶段会被自动跳过）', () {
    final f = fieldWith(activeFaction: Faction.red);
    expect(f.phaseAbleCount(Faction.red), 1);
    expect(f.phaseAbleCount(Faction.blue), 2);
  });

  test('★ AI 会朝我方移动（不是原地不动）', () {
    final f = fieldWith(activeFaction: Faction.red);
    final ai = EnemyAi(map: prologueMap(), costsOf: uniformCosts(demoCost()));
    final oneill = f.unitById(0x81)!;
    final a = ai.decide(f, oneill);
    expect(a.toX != oneill.x || a.toY != oneill.y, isTrue,
        reason: '奥尼尔在 (${oneill.x},${oneill.y})，AI 却让他留在原地：$a');
    // 朝赛特 (4,4) 走 → 两个坐标都不该变大
    expect(a.toX, lessThanOrEqualTo(oneill.x));
    expect(a.toY, lessThanOrEqualTo(oneill.y));
  });

  // ★ 接上真实移动消耗表（`GetUnitMovementCost`）之后的行为。
  //
  // 原来全场共用一张"除 0 号地形外全 1"的演示表 —— 于是**山峰也能走**。
  group('真实移动消耗表（按职业查 pMovCostTable）', () {
    test('★ 赛特（圣骑士）走不上山峰；演示表下能走', () {
      final grid = prologueMap();
      final ct = realClasses();
      final paladin = ct.movementCosts(7, Weather.normal)!;
      final real = MovementRangeComputer.compute(
        map: grid,
        costTable: MovementCostTable(paladin),
        x: 4,
        y: 4,
        movement: 8,
      );

      // 地图上每一格山峰都不该可达
      var peaks = 0;
      for (var y = 0; y < grid.height; y++) {
        for (var x = 0; x < grid.width; x++) {
          if (grid.terrainAt(x, y) != TerrainType.peak) continue;
          peaks++;
          expect(real.canReach(x, y), isFalse, reason: '山峰 ($x,$y) 不该可达');
        }
      }
      expect(peaks, greaterThan(0), reason: '这张图上确实有山峰');

      // 平原可达
      expect(real.canReach(4, 5), isTrue);

      // 对照：演示表（全 1）下 (11,4) 是山峰却可达 —— 这正是原来的 bug
      final demo = MovementRangeComputer.compute(
        map: grid,
        costTable: demoCost(),
        x: 4,
        y: 4,
        movement: 8,
      );
      expect(grid.terrainAt(11, 4), TerrainType.peak);
      expect(demo.canReach(11, 4), isTrue,
          reason: '演示表把山峰当成可通行，所以 (11,4) 可达');
    });

    test('★ AI 不会把落点选在山峰上', () {
      final grid = prologueMap();
      final ct = realClasses();
      var missing = 0;
      final ai = EnemyAi(
        map: grid,
        costsOf: costsByClass(
          costsOfClass: (cls) {
            final c = ct.movementCosts(cls, Weather.normal);
            if (c == null) missing++;
            return c;
          },
          fallback: demoCost(),
        ),
      );
      final f = fieldWith(activeFaction: Faction.red);
      final a = ai.decide(f, f.unitById(0x81)!);
      expect(missing, 0);
      expect(grid.terrainAt(a.toX, a.toY), isNot(TerrainType.peak),
          reason: 'AI 落点 $a 落在山峰上');
    });
  });

  test('相邻时 AI 会攻击', () {
    final f = fieldWith(activeFaction: Faction.red, sethX: 13, sethY: 8);
    final ai = EnemyAi(map: prologueMap(), costsOf: uniformCosts(demoCost()));
    final a = ai.decide(f, f.unitById(0x81)!);
    expect(a.attacked, isTrue, reason: '贴身了却不打：$a');
    expect(a.targetId, 1);
  });
}
