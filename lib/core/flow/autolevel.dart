// PORT OF: src/GetAutoleveledStatIncrease.c:22-24（`GetAutoleveledStatIncrease`）
//          src/bmbattle_0802B784.c:82-90（`GetStatIncrease`）
//          src/bmunit.c:78-87（`UnitAutolevelCore` —— 逐项用**职业自己的**成长值）
//          src/UnitAutolevel.c:27-32（`UnitAutolevel`：晋升补正 + `level - 1` 次）
//          src/rng.c:80-83（`NextRN_N(max) = NextRN() * max / 0x10000`）
//
// # 单位在 N 级的数值从哪来
//
// ```c
// int GetStatIncrease(int growth) {
//     int result = 0;
//     while (growth > 100) { result++; growth -= 100; }
//     if (Roll1RN(growth)) result++;       // Roll1RN(t) = t > NextRN_100()
//     return result;
// }
// int GetAutoleveledStatIncrease(int growth, int levelCount) {
//     return GetStatIncrease((growth * levelCount)
//         + (NextRN_N((growth * levelCount) / 4) - (growth * levelCount) / 8));
// }
// void UnitAutolevelCore(struct Unit* unit, u8 classId, int levelCount) {
//     if (levelCount) {
//         unit->pow += GetAutoleveledStatIncrease(unit->pClassData->growthPow, levelCount);
//         ... 其余各项同理（**用的是职业的成长，不是职业+角色**）
//     }
// }
// void UnitAutolevel(struct Unit* unit) {
//     if (UNIT_CATTRIBUTES(unit) & CA_PROMOTED)
//         UnitAutolevelCore(unit, unit->pClassData->promotion, GetCurrentPromotedLevelBonus());
//     UnitAutolevelCore(unit, unit->pClassData->number, unit->level - 1);
// }
// ```
//
// ⚠️ 每项要抽 **2 次乱数**（一次 `NextRN_N`、一次 `Roll1RN`），且**顺序固定**
//    —— 顺序错了数值就全错，而且不会报错。判据里钉住"每项恰好消耗 2 次"。
//
// 晋升补正（第 61 轮补上）：
// ```c
// int GetCurrentPromotedLevelBonus() {                 // src/masked_08037bdc.c:50-56
//     if (gPlaySt.chapterStateBits & PLAY_FLAG_HARD) return 19;
//     return 9;
// }
// void UnitAutolevel(struct Unit* unit) {              // src/UnitAutolevel.c:27-32
//     if (UNIT_CATTRIBUTES(unit) & CA_PROMOTED)
//         UnitAutolevelCore(unit, unit->pClassData->promotion, GetCurrentPromotedLevelBonus());
//     UnitAutolevelCore(unit, unit->pClassData->number, unit->level - 1);
// }
// ```
// ⚠️ `UnitAutolevelCore` 的 `classId` 形参**在函数体里没被用到**
//（它读的是 `unit->pClassData->growthX`）⇒ 两轮补正用的是**同一份成长值**
//（当前职业的），这不是我偷懒，是源码如此。判据里按**顺序**核对（先晋升轮、再等级轮）。

import '../battle/battle_rng.dart';

/// `NextRN_N(max)`（`src/rng.c:80-83`）：`NextRN() * max / 0x10000`
int nextRnN(BattleRngTracker rng, int max) => rng.nextRn() * max ~/ 0x10000;

/// `GetStatIncrease(growth)`（`src/bmbattle_0802B784.c:82-90`）
int getStatIncrease(int growth, BattleRngTracker rng) {
  var result = 0;
  var g = growth;
  while (g > 100) {
    result++;
    g -= 100;
  }
  if (rng.roll1Rn(g)) result++;
  return result;
}

/// `GetAutoleveledStatIncrease(growth, levelCount)`（`src/GetAutoleveledStatIncrease.c:22-24`）
int getAutoleveledStatIncrease(
    int growth, int levelCount, BattleRngTracker rng) {
  final base = growth * levelCount;
  // C 的整数除法（正数时 `~/` 与之一致）
  final noise = nextRnN(rng, base ~/ 4) - base ~/ 8;
  return getStatIncrease(base + noise, rng);
}

/// 一个职业的成长值（就是 `classes.json` 里那几项）
class ClassGrowths {
  const ClassGrowths({
    this.hp = 0,
    this.pow = 0,
    this.skl = 0,
    this.spd = 0,
    this.def = 0,
    this.res = 0,
    this.lck = 0,
  });

  final int hp, pow, skl, spd, def, res, lck;

  List<int> get all => [hp, pow, skl, spd, def, res, lck];
}

/// `level - 1` 次成长的累加结果（`UnitAutolevelCore` 的 7 项，顺序照源码）
class AutolevelGains {
  const AutolevelGains(this.hp, this.pow, this.skl, this.spd, this.def, this.res,
      this.lck);

  final int hp, pow, skl, spd, def, res, lck;
}

/// 按 `UnitAutolevelCore` 的**顺序**逐项抽（顺序错 ⇒ 数值错，但不报错）
AutolevelGains autolevelGains(
    ClassGrowths g, int levelCount, BattleRngTracker rng) {
  if (levelCount <= 0) return const AutolevelGains(0, 0, 0, 0, 0, 0, 0);
  return AutolevelGains(
    getAutoleveledStatIncrease(g.hp, levelCount, rng),
    getAutoleveledStatIncrease(g.pow, levelCount, rng),
    getAutoleveledStatIncrease(g.skl, levelCount, rng),
    getAutoleveledStatIncrease(g.spd, levelCount, rng),
    getAutoleveledStatIncrease(g.def, levelCount, rng),
    getAutoleveledStatIncrease(g.res, levelCount, rng),
    getAutoleveledStatIncrease(g.lck, levelCount, rng),
  );
}

/// `GetCurrentPromotedLevelBonus`（`src/masked_08037bdc.c:50-56`）：
/// **困难 19、否则 9**（与路线无关）。
int currentPromotedLevelBonus({required bool hardMode}) => hardMode ? 19 : 9;

/// `UnitAutolevel`（`src/UnitAutolevel.c:27-32`）：
/// 晋升单位**先**按晋升补正补一轮（困难 19 / 普通 9），**再**按 `level - 1` 补一轮。
///
/// ⚠️ 顺序不能反（乱数消耗顺序固定）：先 7 项晋升轮、后 7 项等级轮。
AutolevelGains unitAutolevelGains({
  required ClassGrowths g,
  required int level,
  required bool promoted,
  required bool hardMode,
  required BattleRngTracker rng,
}) {
  var hp = 0, pow = 0, skl = 0, spd = 0, def = 0, res = 0, lck = 0;
  if (promoted) {
    final b = autolevelGains(g, currentPromotedLevelBonus(hardMode: hardMode), rng);
    hp += b.hp;
    pow += b.pow;
    skl += b.skl;
    spd += b.spd;
    def += b.def;
    res += b.res;
    lck += b.lck;
  }
  final l = autolevelGains(g, level - 1, rng);
  return AutolevelGains(
      hp + l.hp, pow + l.pow, skl + l.skl, spd + l.spd, def + l.def, res + l.res,
      lck + l.lck);
}
