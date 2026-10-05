// 战斗结算（M4 数值层 → M5 战场流程的桥）。
//
// 数值本身的正确性由 M4 的 655 条 C Oracle 向量保证；
// 这里验证的是**桥接**没有引入错误：
//   1. 伤害真的落到 HP 上，且钳位规则与 BattleGenerateHitEffects 一致
//   2. 乱数消耗是"本次攻击"的量，不是累计量
//   3. 相同输入产生相同结果（确定性）
import 'dart:convert';
import 'dart:io';

import 'package:fe8r/core/core.dart';
import 'package:flutter_test/flutter_test.dart';

ItemTable _items() {
  final t = ItemTable(8);
  t[1]..might = 5..hit = 90..weight = 3;
  t[2]..might = 7..hit = 85..weight = 8;
  return t;
}

WeaponTriangleTable _triangle() {
  final f = File('tools/pipeline/out/tables/weapon_triangle.json');
  if (!f.existsSync()) return WeaponTriangleTable(const []);
  return WeaponTriangleTable.fromJson(
    jsonDecode(f.readAsStringSync()) as Map<String, dynamic>,
  );
}

CombatResolver _resolver() =>
    CombatResolver(items: _items(), triangle: _triangle());

const _attacker = CombatProfile(
  classId: 0x01, level: 5, pow: 8, skl: 8, spd: 8, def: 5, lck: 5,
  weaponItem: 1, weaponType: WeaponType.sword,
);
const _defender = CombatProfile(
  classId: 0x2A, level: 3, pow: 6, skl: 5, spd: 5, def: 3, lck: 2,
  weaponItem: 2, weaponType: WeaponType.lance,
);

void main() {
  late CombatResolver r;
  late GameRng rng;
  late BattleRngTracker tracker;

  setUp(() {
    r = _resolver();
    rng = GameRng()..initRn(1);
    tracker = BattleRngTracker(rng);
  });

  MapUnit mk(int id, int faction, {int hp = 30, int maxHp = 30}) => MapUnit(
      id: id, faction: faction, x: 0, y: 0, hp: hp, maxHp: maxHp);

  test('命中会扣血，且伤害不超过目标当前 HP（钳位）', () {
    final a = mk(1, Faction.blue);
    // 目标只剩 2 HP，攻击力远大于 2
    final d = mk(0x81, Faction.red, hp: 2, maxHp: 30);

    // 找一个必中的乱数种子
    final res = r.attack(
      tracker: tracker, rng: rng,
      attackerUnit: a, defenderUnit: d,
      attackerProfile: _attacker, defenderProfile: _defender,
      terrainDefense: 0, terrainAvoid: 0,
    );

    expect(d.hp, greaterThanOrEqualTo(0));
    if (res.hit) {
      expect(res.damage, lessThanOrEqualTo(2),
          reason: '伤害必须钳到当前 HP —— 否则显示的数字会大于实际掉血');
      expect(d.hp, 0);
      expect(res.damage, res.hpBefore - res.hpAfter);
    }
  });

  test('HP 不会被扣成负数', () {
    final a = mk(1, Faction.blue);
    final d = mk(0x81, Faction.red, hp: 1, maxHp: 30);
    for (var i = 0; i < 30; i++) {
      r.attack(
        tracker: tracker, rng: rng,
        attackerUnit: a, defenderUnit: d,
        attackerProfile: _attacker, defenderProfile: _defender,
        terrainDefense: 0, terrainAvoid: 0,
      );
      expect(d.hp, greaterThanOrEqualTo(0));
    }
  });

  test('rnConsumed 是本次攻击的消耗量，不是累计量', () {
    final a = mk(1, Faction.blue);
    final d = mk(0x81, Faction.red, hp: 999, maxHp: 999);

    final first = r.attack(
      tracker: tracker, rng: rng,
      attackerUnit: a, defenderUnit: d,
      attackerProfile: _attacker, defenderProfile: _defender,
      terrainDefense: 0, terrainAvoid: 0,
    );
    expect(first.rnConsumed, greaterThan(0));
    expect(first.rnConsumed, lessThanOrEqualTo(6),
        reason: '一次攻击最多几次判定，不可能是累计的几十次');

    final second = r.attack(
      tracker: tracker, rng: rng,
      attackerUnit: a, defenderUnit: d,
      attackerProfile: _attacker, defenderProfile: _defender,
      terrainDefense: 0, terrainAvoid: 0,
    );
    // 两次单独报的消耗量应当同量级（都在个位数），而不是 6、12
    expect(second.rnConsumed, lessThanOrEqualTo(6),
        reason: '第二次也应报本次消耗，而不是累计的 12');
  });

  test('相同种子 + 相同输入 → 相同结果（确定性）', () {
    List<Object> run() {
      final rr = _resolver();
      final g = GameRng()..initRn(42);
      final t = BattleRngTracker(g);
      final a = mk(1, Faction.blue);
      final d = mk(0x81, Faction.red, hp: 999, maxHp: 999);
      final out = <Object>[];
      for (var i = 0; i < 10; i++) {
        final res = rr.attack(
          tracker: t, rng: g,
          attackerUnit: a, defenderUnit: d,
          attackerProfile: _attacker, defenderProfile: _defender,
          terrainDefense: 0, terrainAvoid: 0,
        );
        out.add('${res.hit},${res.crit},${res.damage},${d.hp},${res.rnConsumed}');
      }
      return out;
    }

    final x = run();
    final y = run();
    expect(x, y);
    // 而且不能是"全都没命中"这种平凡结果
    expect(x.any((e) => !(e as String).startsWith('false')), isTrue);
  });

  test('地形回避会降低命中率 → 长期命中数不增加', () {
    int hits(int terrainAvoid) {
      final rr = _resolver();
      final g = GameRng()..initRn(7);
      final t = BattleRngTracker(g);
      var n = 0;
      for (var i = 0; i < 200; i++) {
        final a = mk(1, Faction.blue);
        final d = mk(0x81, Faction.red, hp: 999, maxHp: 999);
        final res = rr.attack(
          tracker: t, rng: g,
          attackerUnit: a, defenderUnit: d,
          attackerProfile: _attacker, defenderProfile: _defender,
          terrainDefense: 0, terrainAvoid: terrainAvoid,
        );
        if (res.hit) n++;
      }
      return n;
    }

    final flat = hits(0);
    final forest = hits(30);
    expect(forest, lessThan(flat),
        reason: '地形回避 30 应当让命中数明显下降');
  });
}
