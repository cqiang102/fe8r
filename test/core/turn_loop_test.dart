// 回合循环与敌方 AI 的测试。
//
// 这一层是重写（不是移植），判据是：
//   1. 阶段/回合的推进符合 SwitchPhases 的语义（这条由 C Oracle 锁定，见 turn_switch）
//   2. 阶段开始时灰化标记被正确清除（否则第二回合起游戏卡死）
//   3. AI 是**确定性**的：同一局面必须给出同一结果
//   4. 回合循环能终止（不会出现"永远轮到下一方"的死循环）
import 'dart:io';

import 'package:fe8r/core/core.dart';
import 'package:flutter_test/flutter_test.dart';

MapGrid _map() =>
    MapGrid.parse(File('assets/maps/PrologueMap.json').readAsStringSync());

MovementCostTable _flat() {
  final c = List<int>.filled(65, 1);
  c[0] = 255;
  return MovementCostTable(c);
}

BattleField _field() => BattleField(
      width: 15,
      height: 10,
      activeFaction: Faction.blue,
      units: [
        MapUnit(id: 1, faction: Faction.blue, x: 2, y: 2, movement: 4),
        MapUnit(id: 2, faction: Faction.blue, x: 3, y: 2, movement: 4),
        MapUnit(id: 0x81, faction: Faction.red, x: 8, y: 2, movement: 4),
        MapUnit(id: 0x82, faction: Faction.red, x: 10, y: 8, movement: 4),
      ],
    );

void main() {
  group('回合推进（SwitchPhases 语义）', () {
    test('阶段顺序是 蓝 → 红 → 绿 → 蓝', () {
      final f = _field();
      expect(f.activeFaction, Faction.blue);
      switchPhases(f);
      expect(f.activeFaction, Faction.red);
      switchPhases(f);
      expect(f.activeFaction, Faction.green);
      switchPhases(f);
      expect(f.activeFaction, Faction.blue);
    });

    test('回合数只在 GREEN 绕回 BLUE 时递增', () {
      final f = _field();
      f.turn = 1;
      switchPhases(f); // 蓝→红
      expect(f.turn, 1);
      switchPhases(f); // 红→绿
      expect(f.turn, 1);
      switchPhases(f); // 绿→蓝
      expect(f.turn, 2, reason: '只有这一跳才加回合');
    });

    test('回合数封顶 999', () {
      final f = _field();
      f.activeFaction = Faction.green;
      f.turn = 999;
      switchPhases(f);
      expect(f.turn, 999);
      expect(f.activeFaction, Faction.blue);

      f.activeFaction = Faction.green;
      f.turn = 998;
      switchPhases(f);
      expect(f.turn, 999);
    });
  });

  group('阶段开始时的灰化清除', () {
    test('新阶段单位重新变为可行动', () {
      final f = _field();
      f.unitById(1)!.hasActed = true;
      f.unitById(2)!.hasActed = true;
      expect(f.actionableCount, 0);

      // 走到敌方阶段再绕回我方
      switchPhases(f); // 红
      beginPhase(f);
      // 我方单位此时仍应是灰的（还没轮到我方）
      expect(f.unitById(1)!.hasActed, isTrue, reason: '敌方阶段不该清我方的灰');

      switchPhases(f); // 绿
      beginPhase(f);
      switchPhases(f); // 蓝
      beginPhase(f);
      expect(f.unitById(1)!.hasActed, isFalse, reason: '新回合我方应恢复');
      expect(f.actionableCount, 2);
    });

    test('clearActiveFactionGrayedStates 只清当前阵营', () {
      final f = _field();
      f.unitById(1)!.hasActed = true;
      f.unitById(0x81)!.hasActed = true;
      f.activeFaction = Faction.red;
      f.clearActiveFactionGrayedStates();
      expect(f.unitById(0x81)!.hasActed, isFalse, reason: '敌方应被清');
      expect(f.unitById(1)!.hasActed, isTrue, reason: '我方不该被清');
    });
  });

  group('phaseAbleCount 用的是规则层实现', () {
    test('已行动的单位不计入', () {
      final f = _field();
      expect(f.phaseAbleCount(Faction.blue), 2);
      f.unitById(1)!.hasActed = true;
      expect(f.phaseAbleCount(Faction.blue), 1);
    });

    test('阵亡的单位不计入（走的是 US_DEAD 分支）', () {
      final f = _field();
      expect(f.phaseAbleCount(Faction.red), 2);
      f.unitById(0x81)!.hp = 0;
      expect(f.phaseAbleCount(Faction.red), 1);
    });

    test('阵营编号范围正确：不会把别的阵营算进来', () {
      final f = _field();
      // 我方 2 个、敌方 2 个，互不串台
      expect(f.phaseAbleCount(Faction.blue), 2);
      expect(f.phaseAbleCount(Faction.red), 2);
      expect(f.phaseAbleCount(Faction.green), 0);
    });
  });

  group('敌方 AI 的确定性', () {
    late EnemyAi ai;

    setUp(() {
      ai = EnemyAi(map: _map(), costsOf: uniformCosts(_flat()));
    });

    test('同一局面重复决策结果完全相同', () {
      final f = _field();
      final unit = f.unitById(0x81)!;
      final first = ai.decide(f, unit);
      for (var i = 0; i < 20; i++) {
        final again = ai.decide(f, unit);
        expect(again.toX, first.toX);
        expect(again.toY, first.toY);
        expect(again.targetId, first.targetId);
      }
    });

    test('朝最近的我方单位靠近', () {
      final f = _field();
      final unit = f.unitById(0x81)!; // (8,2)
      final a = ai.decide(f, unit);
      // 最近的我方是 (3,2) 或 (2,2)，都远在左边，应当往左走
      expect(a.toX, lessThan(8));
      expect(a.toY, 2);
    });

    test('够得着就攻击', () {
      final f = BattleField(
        width: 15,
        height: 10,
        activeFaction: Faction.red,
        units: [
          MapUnit(id: 1, faction: Faction.blue, x: 5, y: 5, movement: 4),
          // 敌方紧邻我方
          MapUnit(id: 0x81, faction: Faction.red, x: 6, y: 5, movement: 4),
        ],
      );
      final a = ai.decide(f, f.unitById(0x81)!);
      expect(a.attacked, isTrue);
      expect(a.targetId, 1);
    });

    test('没有敌人时原地待机（不是返回 null）', () {
      final f = BattleField(
        width: 15,
        height: 10,
        units: [MapUnit(id: 0x81, faction: Faction.red, x: 6, y: 5)],
      );
      final a = ai.decide(f, f.unitById(0x81)!);
      expect(a.toX, 6);
      expect(a.toY, 5);
      expect(a.attacked, isFalse);
    });

    test('等距时不会来回走（原地也是候选）', () {
      // 我方在 (0,0) 和 (10,0)，敌方在 (5,0)：两个方向等距
      final f = BattleField(
        width: 15,
        height: 10,
        units: [
          MapUnit(id: 1, faction: Faction.blue, x: 0, y: 0, movement: 4),
          MapUnit(id: 2, faction: Faction.blue, x: 10, y: 0, movement: 4),
          MapUnit(id: 0x81, faction: Faction.red, x: 5, y: 0, movement: 2),
        ],
      );
      final unit = f.unitById(0x81)!;
      final a = ai.decide(f, unit);
      // 目标取 id 小的（单位 1，在 (0,0)），应当往左走
      expect(a.targetId, isNull);
      expect(a.toX, lessThan(5));
    });
  });

  group('回合循环能终止', () {
    test('advanceToNextActivePhase 最多探测 3 跳', () {
      final f = _field();
      final hops = advanceToNextActivePhase(f);
      expect(hops, lessThanOrEqualTo(3));
      expect(f.activeFaction, isNot(Faction.green), reason: '绿色没有单位，应跳过');
    });

    test('所有阶段都空时不会死循环', () {
      final f = BattleField(width: 5, height: 5);
      final hops = advanceToNextActivePhase(f);
      expect(hops, 3, reason: '三跳都空就放弃，不能无限转');
    });
  });

  _secondEnemyPhaseTests();
}

void _secondEnemyPhaseTests() {
  test('★ 连续两个敌方阶段都能动（灰化在阶段结束时清）', () {
    final f = BattleField(
      width: 10,
      height: 10,
      activeFaction: Faction.blue,
      units: [
        MapUnit(id: 1, faction: Faction.blue, x: 1, y: 1, movement: 5),
        MapUnit(id: 0x81, faction: Faction.red, x: 8, y: 8, movement: 5),
        MapUnit(id: 0x82, faction: Faction.red, x: 9, y: 9, movement: 5),
      ],
    );

    // 第 1 回合：我方行动完 → 结束回合
    f.unitById(1)!.hasActed = true;
    advanceToNextActivePhase(f);
    expect(f.activeFaction, Faction.red);
    expect(f.phaseAbleCount(Faction.red), 2, reason: '第 1 个敌方阶段有人能动');

    // 敌方全部行动完 → 结束回合
    for (final u in f.units.where((u) => u.faction == Faction.red)) {
      u.hasActed = true;
    }
    advanceToNextActivePhase(f);
    expect(f.activeFaction, Faction.blue);
    expect(f.unitById(1)!.hasActed, isFalse, reason: '新回合我方恢复');

    // 我方再行动完 → **第 2 个敌方阶段**
    f.unitById(1)!.hasActed = true;
    final hops = advanceToNextActivePhase(f);
    expect(hops, lessThanOrEqualTo(3));
    expect(f.activeFaction, Faction.red,
        reason: '第 2 个回合也应该轮到敌方（不是被跳过）');
    expect(f.phaseAbleCount(Faction.red), 2,
        reason: '★ 第 2 个敌方阶段敌人必须还能动 —— 这条曾经红过');
  });

  group('★ `stepPhase` = 一次 `BmMain_ChangePhase`（纯逻辑部分）', () {
    test('清的是**即将结束**的阵营，切完才轮到新阵营', () {
      final f = _field();
      f.finishUnit(f.unitById(1)!); // 蓝 1 号已行动
      f.finishUnit(f.unitById(0x81)!); // 红 81 号已行动
      expect(f.phaseAbleCount(Faction.blue), 1);

      // 蓝→红：清的是**蓝**（它的阶段结束了）
      final autoEnd = stepPhase(f);
      expect(f.activeFaction, Faction.red);
      expect(f.phaseAbleCount(Faction.blue), 2,
          reason: '蓝的灰化在**自己阶段结束时**清掉（ClearActiveFactionGrayedStates）');
      expect(f.phaseAbleCount(Faction.red), 1,
          reason: '红的灰化要等**红的阶段**结束才清 —— 现在还是"已行动"');
      expect(autoEnd, isFalse, reason: '红方还有 1 个能动的');
    });

    test('回合数只在离开 GREEN 时 +1（跨 stepPhase 也一样）', () {
      final f = _field();
      f.turn = 1;
      stepPhase(f); // 蓝→红
      expect(f.turn, 1);
      stepPhase(f); // 红→绿
      expect(f.turn, 1);
      stepPhase(f); // 绿→蓝
      expect(f.turn, 2);
      expect(f.activeFaction, Faction.blue);
    });

    test('★ `disableAutoEndTurns` **只**管我方阶段（敌方/NPC 照旧自己结束）', () {
      final f = _field();

      // 我方阶段：关掉自动结束后，即使一个能动的都没有也不结束
      f.finishUnit(f.unitById(1)!);
      f.finishUnit(f.unitById(2)!);
      expect(f.phaseAbleCount(Faction.blue), 0);
      expect(shouldAutoEndPhase(f, disableAutoEndTurns: true), isFalse,
          reason: '`PlayerPhase_HandleAutoEnd` 的 `!disableAutoEndTurns` 那一半');
      expect(shouldAutoEndPhase(f, disableAutoEndTurns: false), isTrue);

      // 敌方阶段：同一个开关**不该**影响它
      // （敌方阶段跑 `gProcScr_CpPhase`，AI 跑完就 Proc_End；全作只有
      //  `PlayerPhase_HandleAutoEnd` 读这个开关）
      final g = BattleField(
        width: 15,
        height: 10,
        activeFaction: Faction.green,
        units: [MapUnit(id: 1, faction: Faction.blue, x: 2, y: 2)],
      );
      expect(g.phaseAbleCount(Faction.green), 0);
      expect(shouldAutoEndPhase(g, disableAutoEndTurns: true), isTrue,
          reason: '没有友军 NPC 的阶段必须照旧被跳过，否则整局卡住');
    });
  });
}
