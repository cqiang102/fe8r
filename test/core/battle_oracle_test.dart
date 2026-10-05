// 战斗数值与 C Oracle 逐值一致。
//
// 期望值由 tools/oracle/ 里**真实的 C 代码**产出（451+54 条向量中的战斗部分）：
//   battle_unit  — ComputeBattleUnitAvoidRate / BaseDefense / DodgeRate
//   crit_rate    — ComputeBattleUnitEffectiveCritRate（含道具表）
//   unit_defense — GetUnitDefense / GetItemDefBonus
//
// 用例里的字段名与 C 场景的输入字段一一对应，两端构造的输入必须完全一致。
import 'dart:convert';
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

int _v(Map<String, String> c, String k, [int dflt = 0]) =>
    c.containsKey(k) ? int.parse(c[k]!) : dflt;

void main() {
  group('战斗数值与 C Oracle 逐值一致', () {
    /// battle_unit：三个函数共用一个用例文件，靠 `fn` 字段分派
    test('battle_unit（回避 / 基础防御 / 回避率 / 速度）', () {
      final cases = _readCases('$_vecDir/battle_unit.cases.tsv');
      final expected = _readExpected('$_vecDir/battle_unit.expected.tsv');
      expect(cases, isNotEmpty);

      // 与 scenarios/battle_unit.c 完全一致的可控重量表
      final items = ItemTable(8);
      const weights = [0, 1, 5, 12, 20];
      for (var i = 0; i < weights.length; i++) {
        items[i].weight = weights[i];
      }

      final failures = <String>[];
      for (final id in cases.keys.toList()..sort()) {
        final c = cases[id]!;
        final want = expected[id];
        if (want == null) {
          failures.add('$id: 缺少期望值');
          continue;
        }

        final bu = BattleUnit()
          ..battleSpeed = asS16(_v(c, 'battleSpeed'))
          ..setTerrain(avoid: _v(c, 'terrainAvoid'), defense: _v(c, 'terrainDefense'));
        bu.weaponBefore = asU16(_v(c, 'weaponBefore'));
        bu.unit = BattleUnitSide(
          def: _v(c, 'def'),
          lck: _v(c, 'lck'),
          spd: _v(c, 'spd'),
          conBonus: _v(c, 'conBonus'),
        );

        final fn = c['fn'] ?? 'avoid';
        final int got;
        switch (fn) {
          case 'speed':
            BattleStats.computeSpeed(bu, items);
            got = bu.battleSpeed;
          case 'defense':
            BattleStats.computeBaseDefense(bu);
            got = bu.battleDefense;
          case 'dodge':
            BattleStats.computeDodgeRate(bu);
            got = bu.battleDodgeRate;
          default:
            BattleStats.computeAvoidRate(bu);
            got = bu.battleAvoidRate;
        }

        if ('$got' != want) failures.add('$id ($fn): 期望 $want，实际 $got');
      }
      expect(failures, isEmpty, reason: failures.take(6).join('\n'));
    });

    test('crit_rate（必杀率，含 IA_NEGATE_CRIT 与魔石）', () {
      final cases = _readCases('$_vecDir/crit_rate.cases.tsv');
      final expected = _readExpected('$_vecDir/crit_rate.expected.tsv');
      expect(cases, isNotEmpty);

      final failures = <String>[];
      for (final id in cases.keys.toList()..sort()) {
        final c = cases[id]!;
        final want = expected[id];
        if (want == null) {
          failures.add('$id: 缺少期望值');
          continue;
        }

        // 与 scenarios/crit_rate.c 完全一致的固定道具表
        final items = ItemTable(itemMonsterStone + 1);
        items[1].attributes = 0;
        items[2].attributes = iaNegateCrit;

        final atk = BattleUnit()..battleCritRate = asS16(_v(c, 'critRate'));
        atk.weapon = asU16(_v(c, 'weapon'));
        final def = BattleUnit()..battleDodgeRate = asS16(_v(c, 'dodgeRate'));
        def.unit.items[0] = asU16(_v(c, 'di0'));
        def.unit.items[1] = asU16(_v(c, 'di1'));

        BattleStats.computeEffectiveCritRate(atk, def, items);

        if ('${atk.battleEffectiveCritRate}' != want) {
          failures.add('$id: 期望 $want，实际 ${atk.battleEffectiveCritRate}');
        }
      }
      expect(failures, isEmpty, reason: failures.take(6).join('\n'));
    });

    test('unit_defense（含道具加成链）', () {
      final cases = _readCases('$_vecDir/unit_defense.cases.tsv');
      final expected = _readExpected('$_vecDir/unit_defense.expected.tsv');
      expect(cases, isNotEmpty);

      final failures = <String>[];
      for (final id in cases.keys.toList()..sort()) {
        final c = cases[id]!;
        final want = expected[id];
        if (want == null) {
          failures.add('$id: 缺少期望值');
          continue;
        }

        // 与 scenarios/unit_defense.c 一致：道具 1 带 defBonus，道具 0 无
        final items = ItemTable(2);
        items[0].statBonuses = null;
        final bonus = ItemStatBonuses(defBonus: asS8(_v(c, 'defBonus')));
        items[1].statBonuses = bonus;

        // Oracle 把 GetUnitEquippedWeapon stub 成 items[0] & 0xFF，
        // 这里显式传入同样的值
        final unit = BattleUnitSide(def: _v(c, 'def'));
        final got = BattleStats.unitDefense(unit, asU16(_v(c, 'item')), items);

        if ('$got' != want) failures.add('$id: 期望 $want，实际 $got');
      }
      expect(failures, isEmpty, reason: failures.take(6).join('\n'));
    });

    test('battle_attack（攻击力 / 武器特效 / 主教斩魔）', () {
      final cases = _readCases('$_vecDir/battle_attack.cases.tsv');
      final expected = _readExpected('$_vecDir/battle_attack.expected.tsv');
      expect(cases, isNotEmpty);

      // 与 scenarios/battle_attack.c 的 pick_list 一一对应。
      // 职业编号直接取自真实有效性表（tools/pipeline/out/tables/itemuse.json），
      // 保证与生成向量时用的是同一份数据。
      final tables = jsonDecode(
        File('tools/pipeline/out/tables/itemuse.json').readAsStringSync(),
      ) as Map<String, dynamic>;
      final tbl = tables['tables'] as Map<String, dynamic>;
      List<int> members(String name) => ((tbl[name] as Map<String, dynamic>)['values']
              as List<dynamic>)
          .map((e) => e as int)
          .where((v) => v != 0)
          .toList();

      final lists = <String, List<int>?>{
        'none': null,
        'armor': members('ItemEffectiveness_Armor'),
        'armorAndHorse': members('ItemEffectiveness_ArmorAndHorse'),
        'horse': members('ItemEffectiveness_Horse'),
        'flier': members('ItemEffectiveness_Flier'),
        'flierAndMonsters': members('ItemEffectiveness_FlierAndMonsters'),
        'dragon': members('ItemEffectiveness_Dragon'),
        'monsters': members('ItemEffectiveness_Monsters'),
      };
      const flierLists = {'flier', 'flierAndMonsters'};

      final failures = <String>[];
      for (final id in cases.keys.toList()..sort()) {
        final c = cases[id]!;
        final want = expected[id];
        if (want == null) {
          failures.add('$id: 缺少期望值');
          continue;
        }

        // 场景里道具 1 承载被测武器，道具 2 承载 IA_NEGATE_FLYING
        final items = ItemTable(4);
        final effName = c['effList'] ?? 'none';
        items[1]
          ..might = _v(c, 'might')
          ..effectiveness = lists[effName]
          ..effectivenessIsFlier = flierLists.contains(effName);
        final negFly = _v(c, 'negFly');
        items[2].attributes = negFly;

        final atk = BattleUnit()
          ..wTriangleDmgBonus = _v(c, 'triBonus');
        atk.weapon = asU16(_v(c, 'weapon'));
        atk.unit = BattleUnitSide(
          pow: _v(c, 'pow'),
          classId: _v(c, 'actorCls'),
        );

        final def = BattleUnit();
        def.unit = BattleUnitSide(
          classId: _v(c, 'targetCls'),
          items: [negFly != 0 ? 2 : 0],
        );

        final fn = c['fn'] ?? 'attack';
        final int got;
        switch (fn) {
          case 'item_eff':
            got = BattleStats.isItemEffectiveAgainst(
                    atk.weapon, def.unit, items)
                ? 1
                : 0;
          case 'unit_eff':
            got = BattleStats.isUnitEffectiveAgainst(
              atk.unit,
              def.unit,
              lists['monsters']!,
            )
                ? 1
                : 0;
          default:
            BattleStats.computeAttack(
              atk,
              def,
              items,
              monsterClassList: lists['monsters']!,
            );
            got = atk.battleAttack;
        }

        if ('$got' != want) failures.add('$id ($fn): 期望 $want，实际 $got');
      }
      expect(failures, isEmpty, reason: failures.take(8).join('\n'));
    });

    test('battle_rng（乱数消耗顺序，用 LFSR 状态做指纹）', () {
      final cases = _readCases('$_vecDir/battle_rng.cases.tsv');
      final expected = _readExpected('$_vecDir/battle_rng.expected.tsv');
      expect(cases, isNotEmpty);

      final failures = <String>[];
      var totalConsumed = 0;

      for (final id in cases.keys.toList()..sort()) {
        final c = cases[id]!;
        final want = expected[id];
        if (want == null) {
          failures.add('$id: 缺少期望值');
          continue;
        }

        final rng = GameRng()..initRn(_v(c, 'seed'));
        final tracker = BattleRngTracker(rng);
        final ctx = BattleHitContext(
          config: _v(c, 'config', BattleConfig.real),
          hitRate: _v(c, 'hitRate', 100),
          critRate: _v(c, 'critRate'),
          silencerRate: _v(c, 'silencerRate'),
          attack: _v(c, 'attack'),
          defense: _v(c, 'defense'),
          attributes: _v(c, 'attrs'),
        );

        final n = battleGenerateHitAttributes(
          tracker,
          ctx,
          BattleCombatant(
            classId: _v(c, 'actorCls', 1),
            level: _v(c, 'actorLevel', 1),
          ),
          BattleCombatant(classId: _v(c, 'targetCls', 1)),
        );
        totalConsumed += n;

        final (s0, s1, s2) = rng.storeRnState();
        final got = '${ctx.damage},${ctx.attributes},$s0,$s1,$s2';

        if (got != want) {
          failures.add('\$id\n    期望 \$want\n    实际 \$got  (消耗 \$n 个乱数)');
        }
      }

      expect(failures, isEmpty, reason: failures.take(5).join('\n'));
      // 状态指纹只有在"确实消耗了乱数"时才有区分度
      expect(totalConsumed, greaterThan(100));
    });

    test('三个场景的用例总数（防止向量文件被误删）', () {
      final n1 = _readCases('$_vecDir/battle_unit.cases.tsv').length;
      final n2 = _readCases('$_vecDir/crit_rate.cases.tsv').length;
      final n3 = _readCases('$_vecDir/unit_defense.cases.tsv').length;
      expect(n1 + n2 + n3, 171 + 90 + 69);
      expect(_readCases('$_vecDir/battle_attack.cases.tsv').length, 107);
    });
  });
}
