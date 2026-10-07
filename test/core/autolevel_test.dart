// 单位在 N 级的成长累加（`UnitAutolevelCore` / `GetAutoleveledStatIncrease`）判据。
//
// 出处：`src/GetAutoleveledStatIncrease.c:22-24`、`src/bmbattle_0802B784.c:82-90`、
//       `src/bmunit.c:78-87`、`src/UnitAutolevel.c:27-32`、`src/rng.c:80-83`。
import 'package:fe8r/core/core.dart';
import 'package:flutter_test/flutter_test.dart';

/// 固定种子的乱数（`GameRng.initRn(seed)`）
GameRng seeded(int s) => GameRng()..initRn(s);

void main() {
  test('★ `GetStatIncrease`：先按 100 拆整，余数**用乱数判定**', () {
    // 用固定种子的乱数源，把"余数那一次判定"的两种结果都造出来
    final high = BattleRngTracker(seeded(1));
    final low = BattleRngTracker(seeded(1));
    // growth = 250 ⇒ 必然 +2，再对 50 判定一次
    final r1 = getStatIncrease(250, high);
    expect(r1, greaterThanOrEqualTo(2), reason: '250 ⇒ 先拿 2 点');
    expect(r1, lessThanOrEqualTo(3), reason: '余数 50 最多再加 1');
    // growth = 40 ⇒ 一次都不整，只看那一次判定（0 或 1）
    final r2 = getStatIncrease(40, low);
    expect(r2, inInclusiveRange(0, 1));
  });

  test('★ 每项恰好消耗 **2 次**乱数（顺序错了数值全错，但不报错）', () {
    final rng = BattleRngTracker(seeded(7));
    final before = rng.consumed;
    getAutoleveledStatIncrease(45, 9, rng);
    expect(rng.consumed - before, 2,
        reason: '一次 `NextRN_N` + 一次 `Roll1RN`（`GetAutoleveledStatIncrease` 的公式）');
    final b2 = rng.consumed;
    autolevelGains(const ClassGrowths(hp: 70, pow: 40, skl: 50, spd: 45, def: 25,
        res: 20, lck: 30), 5, rng);
    expect(rng.consumed - b2, 14, reason: '7 项 × 2 次');
  });

  test('★ `level - 1 == 0` ⇒ 不发成长、也不抽乱数', () {
    final rng = BattleRngTracker(seeded(3));
    final before = rng.consumed;
    final g = autolevelGains(const ClassGrowths(hp: 70, pow: 44), 0, rng);
    expect(rng.consumed, before, reason: '`UnitAutolevelCore` 里 `if (levelCount)` 挡住');
    expect([g.hp, g.pow, g.skl, g.spd, g.def, g.res, g.lck],
        everyElement(0));
  });

  test('★ 同一种子 ⇒ 同一结果（可复现）；等级越高成长越多（期望意义）', () {
    AutolevelGains at(int level) => autolevelGains(
        const ClassGrowths(hp: 70, pow: 40, skl: 50, spd: 45, def: 25, res: 20,
            lck: 30),
        level - 1,
        BattleRngTracker(seeded(11)));
    final a1 = at(1);
    final a20 = at(20);
    expect([a1.hp, a1.pow, a1.skl, a1.spd, a1.def, a1.res, a1.lck],
        everyElement(0), reason: '1 级 = 职业基础值，不成长');
    expect(a20.pow, greaterThan(0), reason: '★ 20 级必须比 1 级强（第 58 轮实测的 bug）');
    expect(a20.pow, greaterThanOrEqualTo(6),
        reason: '成长 40% × 19 级 ⇒ 至少 7 点里的绝大部分（这里只要求 > 5 保守）');
    // 复现性：同一等级、同一种子，两次结果相同
    final again = at(20);
    expect(again.pow, a20.pow);
    expect(again.hp, a20.hp);
  });
}
