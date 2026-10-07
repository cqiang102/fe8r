// ★ 等级成长与晋升补正，在**游戏层**（profile 这条链）验证。
//
// 出处：`UnitAutolevel`（`src/UnitAutolevel.c:27-32`）、
//       `GetCurrentPromotedLevelBonus`（`src/masked_08037bdc.c:50-56`：困难 19 / 普通 9）、
//       `UnitAutolevelCore`（`src/bmunit.c:78-87`）。
import 'dart:convert';
import 'dart:io';

import 'package:fe8r/core/core.dart';
import 'package:fe8r/game/fe8_game.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> classes() =>
    ((jsonDecode(File('tools/pipeline/out/tables/classes.json')
                .readAsStringSync()) as Map<String, dynamic>)['classes'] as Map)
        .cast<String, dynamic>();

({int number, int baseDef, int growthDef}) pick(
    {required bool promoted}) {
  for (final e in classes().entries) {
    final v = (e.value as Map).cast<String, dynamic>();
    final names = (v['attributeNames'] as List? ?? const []).cast<String>();
    if (names.contains('CA_PROMOTED') == promoted) {
      return (
        number: (v['number'] as num).toInt(),
        baseDef: (v['baseDef'] as num).toInt(),
        growthDef: (v['growthDef'] as num).toInt(),
      );
    }
  }
  fail('classes.json 里找不到 promoted=$promoted 的职业');
}

void main() {
  test('★ 未晋升 1 级 = 职业基础值；晋升 1 级 = 基础 + **晋升补正**（普通 9 轮）', () {
    final g = Fe8Game();
    g.loadRuleData();
    final plain = pick(promoted: false);
    final prom = pick(promoted: true);

    // ⚠️ 每次调用用**不同的 id**：成长结果按单位 id 缓存（这是设计如此），
    // 全用 `id: 1` 会让第二次调用**复用**第一次的缓存 —— 我第一版就是这么写的，
    // 于是"晋升单位消耗 14 次乱数"测出来是 0。
    var nextId = 1;
    CombatProfile profileOf(int classId, int level) => g.profileForTest(MapUnit(
        id: nextId++, faction: 0, x: 0, y: 0, classId: classId, level: level));

    // 未晋升、1 级 ⇒ 就是职业基础值（`level - 1 == 0` ⇒ 不成长）
    expect(profileOf(plain.number, 1).def, plain.baseDef,
        reason: '1 级不发成长（`UnitAutolevelCore` 里 `if (levelCount)` 挡住）');

    // ★ 晋升补正是**确定性**可观测的：晋升单位补两轮（7 项 × 2 次 × 2）、
    // 未晋升只补一轮 ⇒ 乱数消耗 28 vs 14。
    // （不做"晋升一定更强"的概率断言：那个职业 growthDef 只有 ${prom.growthDef}%，
    //   9 轮的期望才 +1.35，乱数判定完全可能给 0 —— 我第一版就是这么写错的。）
    var d = g.dumpState();
    expect(d['autolevelRngConsumed'], 0,
        reason: '★ 1 级 ⇒ `level - 1 == 0` ⇒ **一轮都不抽**'
            '（`UnitAutolevelCore` 的 `if (levelCount)` 挡住）');
    final p1 = profileOf(prom.number, 1);
    d = g.dumpState();
    expect(d['autolevelRngConsumed'], 14,
        reason: '★ 晋升单位 1 级：只有**晋升补正**那一轮（7 项 × 2 次 = 14）；'
            '等级轮因为 `level - 1 == 0` 不抽');
    expect(p1.def, greaterThanOrEqualTo(prom.baseDef),
        reason: '晋升 1 级不低于职业基础值');
    // 3 级（非晋升）⇒ 等级轮要抽满 7 项 × 2 次
    final before = d['autolevelRngConsumed'] as int;
    profileOf(plain.number, 3);
    d = g.dumpState();
    expect(d['autolevelRngConsumed'], before + 14,
        reason: '★ 3 级 ⇒ `level - 1 = 2` 那一轮抽满 14 次');
    expect(d['autolevelMisses'], 0, reason: '成长查表不该有查不到的时候');
  });
}
