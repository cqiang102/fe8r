// 交战序列（BattleUnwind）的测试。
//
// 序列本身的**判据由 C Oracle 锁定**（vectors/effective_hit.cases.tsv，
// 覆盖有效命中率的 100 上限、追击的 >= 4 阈值、250 短路、瞬杀率、勇气武器）。
// 这里验证的是"把这些判据拼成一次交战"时的控制流：
//
//   1. 先手打完没结束 → 防御方反击
//   2. 反击完还没结束 → 速度快的一方追击（只追一次）
//   3. **先手打死人就不再挨打** —— 这条是原版短路的自然结果，
//      也是最容易被"简化"掉的一条
import 'dart:io';

import 'package:fe8r/core/core.dart';
import 'package:flutter_test/flutter_test.dart';

BattleUnit mkBu({
  int weapon = 1,
  int weaponAttributes = 0,
  int speed = 10,
  int followUpEffect = 0,
}) {
  final bu = BattleUnit()
    ..weapon = weapon
    ..weaponBefore = weapon
    ..weaponAttributes = weaponAttributes
    ..followUpWeaponEffect = followUpEffect;
  bu.battleSpeed = speed;
  return bu;
}

/// 记录每一"步"的执行，并按 [killOn] 决定哪一步把目标打死
List<String> runPlan(
  BattleUnit actor,
  BattleUnit target, {
  int? killOnStepIndex,
}) {
  var i = 0;
  final log = <String>[];
  battleUnwind(
    actor: actor,
    target: target,
    perform: (step) {
      log.add('${step.kind.name}${step.attackerIsActor ? 'A' : 'D'}');
      final kills = killOnStepIndex != null && i == killOnStepIndex;
      i++;
      return BattleStepOutcome(finished: kills);
    },
  );
  return log;
}

void main() {
  group('攻击次数', () {
    test('普通武器 1 下，勇气武器 2 下', () {
      expect(battleUnitHitCount(0), 1);
      expect(battleUnitHitCount(iaBrave), 2);
      // 是 1 << flag，不是 flag 本身
      expect(battleUnitHitCount(iaBrave | 0xFF), 2);
    });
  });

  group('追击判定（阈值是 >= 4，不是 > 4）', () {
    FollowUpSide fu(int a, int d) => followUpOrder(
          actorSpeed: a,
          defenderSpeed: d,
          followUpWeapon: 1,
          followUpWeaponBefore: 1,
          followUpWeaponEffect: 0,
        );

    test('差 4 能追击，差 3 不能', () {
      expect(fu(10, 6), FollowUpSide.actor);
      expect(fu(10, 7), FollowUpSide.none, reason: '差 3 —— 写成 > 4 会漏掉差 4');
      expect(fu(6, 10), FollowUpSide.defender);
    });

    test('等速不追击', () {
      expect(fu(10, 10), FollowUpSide.none);
    });

    test('防御方速度 > 250 直接短路', () {
      expect(fu(300, 251), FollowUpSide.none);
    });

    test('半血武器与魔石不追击', () {
      expect(
        followUpOrder(
          actorSpeed: 20,
          defenderSpeed: 1,
          followUpWeapon: 1,
          followUpWeaponBefore: 1,
          followUpWeaponEffect: wpnEffectHpHalve,
        ),
        FollowUpSide.none,
      );
      expect(
        followUpOrder(
          actorSpeed: 20,
          defenderSpeed: 1,
          followUpWeapon: monsterStoneItem,
          followUpWeaponBefore: monsterStoneItem,
          followUpWeaponEffect: 0,
        ),
        FollowUpSide.none,
      );
    });
  });

  group('交战序列', () {
    test('没打死 → 反击 → 追击', () {
      final a = mkBu(speed: 20);
      final d = mkBu(speed: 1); // 差 19，攻击方追击
      expect(runPlan(a, d), ['attackA', 'retaliateD', 'followUpA']);
    });

    test('先手打死 → 不再挨打（原版短路的自然结果）', () {
      final a = mkBu(speed: 20);
      final d = mkBu(speed: 1);
      expect(runPlan(a, d, killOnStepIndex: 0), ['attackA']);
    });

    test('先手打完没死、反击打死先手 → 不追击', () {
      final a = mkBu(speed: 20);
      final d = mkBu(speed: 1);
      expect(runPlan(a, d, killOnStepIndex: 1), ['attackA', 'retaliateD']);
    });

    test('速度慢的一方先手时，由对方追击', () {
      final a = mkBu(speed: 1);
      final d = mkBu(speed: 20);
      expect(runPlan(a, d), ['attackA', 'retaliateD', 'followUpD']);
    });

    test('速度差不足 → 只有先手和反击', () {
      final a = mkBu(speed: 10);
      final d = mkBu(speed: 8); // 差 2
      expect(runPlan(a, d), ['attackA', 'retaliateD']);
    });

    test('勇气武器一次 round 打两下', () {
      final a = mkBu(speed: 20, weaponAttributes: iaBrave);
      final d = mkBu(speed: 1);
      // 先手两下、反击一下、追击两下
      expect(runPlan(a, d),
          ['attackA', 'attackA', 'retaliateD', 'followUpA', 'followUpA']);
    });

    test('防御方空手 → 跳过反击，但攻击方仍可追击', () {
      final a = mkBu(speed: 20);
      final d = mkBu(weapon: 0, speed: 1);
      expect(runPlan(a, d), ['attackA', 'followUpA'],
          reason: '空手不能反击，但这不算"战斗结束"');
    });

    test('攻击方空手 → 第一轮直接跳过，防御方反击', () {
      final a = mkBu(weapon: 0, speed: 20);
      final d = mkBu(speed: 1);
      expect(runPlan(a, d), ['retaliateD'],
          reason: '空手跳过第一轮，但防御方仍会反击');
    });
  });

  group('有效命中率与 C Oracle 逐值一致', () {
    test('effective_hit：钳位 / 追击 / 瞬杀 / 攻击次数', () {
      final cases = <String, Map<String, String>>{};
      for (final line
          in File('tools/oracle/vectors/effective_hit.cases.tsv').readAsLinesSync()) {
        if (line.startsWith('#') || line.trim().isEmpty) continue;
        final parts = line.split('\t');
        final f = <String, String>{};
        for (final p in parts.skip(1)) {
          final eq = p.indexOf('=');
          if (eq > 0) f[p.substring(0, eq)] = p.substring(eq + 1);
        }
        cases[parts.first] = f;
      }
      final expected = <String, String>{};
      for (final line in File('tools/oracle/vectors/effective_hit.expected.tsv')
          .readAsLinesSync()) {
        if (line.startsWith('#') || line.trim().isEmpty) continue;
        final p = line.split('\t');
        if (p.length >= 2) expected[p.first] = p[1];
      }
      expect(cases, isNotEmpty);

      int v(Map<String, String> c, String k, [int d = 0]) =>
          c.containsKey(k) ? int.parse(c[k]!) : d;

      final failures = <String>[];
      for (final id in cases.keys.toList()..sort()) {
        final c = cases[id]!;
        final want = expected[id];
        if (want == null) {
          failures.add('$id: 缺少期望值');
          continue;
        }

        final atk = BattleUnit();
        atk.unit = BattleUnitSide(classAttributes: v(c, 'atkCA'));
        atk.battleHitRate = v(c, 'hitRate');
        atk.battleSpeed = v(c, 'atkSpd');
        atk.weapon = v(c, 'weapon', 1);
        atk.weaponBefore = atk.weapon;
        atk.weaponAttributes = v(c, 'wepAttr');

        final def = BattleUnit();
        def.unit = BattleUnitSide(classAttributes: v(c, 'defCA'));
        def.battleAvoidRate = v(c, 'avoidRate');
        def.battleSpeed = v(c, 'defSpd');

        final fn = c['fn'] ?? 'effhit';
        final int got;
        switch (fn) {
          case 'silencer':
            BattleStats.computeSilencerRate(atk, def);
            got = atk.battleSilencerRate;
          case 'hitcount':
            got = battleUnitHitCount(atk.weaponAttributes);
          case 'followup':
            final aSpd = atk.battleSpeed;
            final dSpd = def.battleSpeed;
            final fasterIsActor = aSpd > dSpd;
            final side = followUpOrder(
              actorSpeed: aSpd,
              defenderSpeed: dSpd,
              followUpWeapon: 1,
              followUpWeaponBefore: 1,
              followUpWeaponEffect: v(c, 'wepEffect'),
            );
            got = side == FollowUpSide.none
                ? 0
                : (side == FollowUpSide.actor ? 1 : 2);
            // 防止"谁先手"写反
            expect(fasterIsActor || side != FollowUpSide.actor, isTrue);
          default:
            BattleStats.computeEffectiveHitRate(atk, def);
            got = atk.battleEffectiveHitRate;
        }

        if ('$got' != want) failures.add('$id ($fn): 期望 $want，实际 $got');
      }
      expect(failures, isEmpty, reason: failures.take(6).join('\n'));
      expect(cases.length, 84);
    });
  });
}
