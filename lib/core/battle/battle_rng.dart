// PORT OF: src/BattleGenerateHitAttributes.c + src/bmbattle_0802B164.c
//          + src/BattleCheckSilencer.c + src/BattleRoll2RN.c + src/sub_802A490.c
//
// 一次攻击判定的完整乱数消耗流程。
//
// ## 为什么这个文件单独存在
//
// M4 的验收是"乱数序列与**消耗次数**逐位一致"。乱数错位的代价极高：
// 战斗中少消耗或多消耗一个 RN，之后所有命中/必杀/成长全部错位，
// 而且**表现上完全看不出来**——只是"感觉暴击变多了"。
//
// 所以这里把消耗顺序显式建模出来，并由 C Oracle 用**调用后的 LFSR 状态**
// 做判据：状态是 3 个 u16，任何数量或顺序的偏差都会让它完全不同。
// 这比"数一数调用了几次"更强，而且不需要动被测代码。
//
// ## 消耗顺序（原版的真实顺序，改动这个顺序等于改变游戏行为）
//
//   1. SureShot 判定        —— 纯职业判定，**不消耗**
//   2. 命中判定 BattleRoll2RN —— **2 个**（SURESHOT 时跳过；MISS 则立即返回）
//   3. GreatShield 判定      —— 视职业，可能 **1 个**
//   4. Pierce 判定           —— 翼骑士职业时 **1 个**
//   5. 必杀判定 BattleRoll1RN —— **1 个**
//   6. 瞬杀判定              —— **只在必杀命中之后**，且非魔王时 **1 个**
//
// 第 6 条最容易搞错：瞬杀判定嵌在必杀判定内部，不是并列的。

import '../rng/game_rng.dart';

/// 命中判定产生的标记位（与 `BATTLE_HIT_ATTR_*` 一致）
class BattleHitAttr {
  static const int crit = 1 << 0;
  static const int miss = 1 << 1;

  /// `BATTLE_HIT_ATTR_BRAVE = (1 << 4)`（`include/bmbattle.h:117`）。
  ///
  /// ⚠️ **本实现只把它当"武器属性"，没有建模跨次命中的累积。**
  ///
  /// C（`src/bmbattle.c:218-236`）：
  /// ```c
  /// attrs = gBattleHitIterator->attributes;
  /// count = GetBattleUnitHitCount(attacker);   // 内部会 |BATTLE_HIT_ATTR_BRAVE
  /// for (i = 0; i < count; ++i) { gBattleHitIterator->attributes |= attrs; ... }
  /// ```
  /// `src/BattleCheckBraveEffect.c` 会往 attributes 里置 brave，
  /// 并被 `attrs` 快照带到**第二次**命中。
  ///
  /// 而 Dart 的 `battleUnitHitCount(weaponAttributes)` 直接看武器属性，
  /// `BattleHitAttr` 里也没有跨 step 的 hit-iterator 状态。
  ///
  /// **影响面：只影响动画标志位，不影响伤害与乱数** —— 所以列为
  /// "结构性简化"而不是数值错误（审计的判定，我认同）。
  static const int brave = 1 << 4;
  static const int silencer = 1 << 11;
  static const int sureshot = 1 << 14;
  static const int greatShield = 1 << 15;
  static const int pierce = 1 << 16;
}

/// `gBattleStats.config`
class BattleConfig {
  static const int real = 1 << 0;
  static const int simulate = 1 << 1;
}

/// `BATTLE_MAX_DAMAGE`
const int battleMaxDamage = 127;

/// 带消耗计数的乱数。
///
/// 包一层而不是直接用 [GameRng]，是为了能回答"这次判定消耗了几个"——
/// 调试乱数错位时这个问题比结果本身更有用。
class BattleRngTracker {
  BattleRngTracker(this.rng);

  final GameRng rng;

  /// 累计消耗的乱数个数
  int consumed = 0;

  /// `NextRN` —— 唯一真正推进 LFSR 的地方，也就在这一处计数
  int nextRn() {
    consumed++;
    return rng.nextRn();
  }

  /// `NextRN_100`
  int nextRn100() => nextRn() * 100 ~/ 0x10000;

  /// `Roll1RN` —— 消耗 1 个
  bool roll1Rn(int threshold) => threshold > nextRn100();

  /// `Roll2RN` —— 消耗 2 个（取平均）
  bool roll2Rn(int threshold) {
    final average = (nextRn100() + nextRn100()) ~/ 2;
    return threshold > average;
  }
}

/// 战斗判定的上下文（对应 `gBattleStats` + `gBattleHitIterator`）
class BattleHitContext {
  BattleHitContext({
    this.config = BattleConfig.real,
    this.hitRate = 100,
    this.critRate = 0,
    this.silencerRate = 0,
    this.attack = 0,
    this.defense = 0,
    this.attributes = 0,
  });

  int config;
  int hitRate;
  int critRate;
  int silencerRate;
  int attack;
  int defense;

  /// `gBattleHitIterator->attributes`
  int attributes = 0;

  /// `gBattleStats.damage`
  int damage = 0;
}

/// `BattleRoll1RN` / `BattleRoll2RN`
///
/// 两者在 SIMULATE 配置下**直接返回模拟值，不消耗乱数**——
/// 这是战斗预测界面不会扰动乱数序列的原因，也是乱数回归里很容易漏的一条。
bool _battleRoll1Rn(BattleRngTracker t, BattleCtx c, int threshold, bool sim) {
  if (c.config & BattleConfig.simulate != 0) return sim;
  return t.roll1Rn(threshold);
}

bool _battleRoll2Rn(BattleRngTracker t, BattleCtx c, int threshold, bool sim) {
  if (c.config & BattleConfig.simulate != 0) return sim;
  return t.roll2Rn(threshold);
}

/// 内部：把 `gBattleStats` 的字段打包传给判定函数
class BattleCtx {
  BattleCtx(this.stats);
  final BattleHitContext stats;
  int get config => stats.config;
}

/// 攻击方/防御方的职业编号（`pClassData->number`）
class BattleCombatant {
  BattleCombatant({required this.classId, this.level = 1, this.items = const []});
  final int classId;
  final int level;
  final List<int> items;
}

/// 下面这些常量全部**直接取自反编译头文件**，不要凭印象写。
///
/// 我第一版凭记忆写成了 `CLASS_SNIPER = 0x1C` / `CLASS_WYVERN_KNIGHT = 0x23`
/// 之类的"看起来合理"的值——其中 SNIPER 差了 1，GreatShield 的职业列表
/// 也凭空多编了两个。这类错误不会崩，只会让判定**悄悄走错分支**。
const int classSniper = 0x1B; // CLASS_SNIPER
const int classSniperF = 0x1C; // CLASS_SNIPER_F
const int classGeneral = 0x0B; // CLASS_GENERAL —— GreatShield
const int classGeneralF = 0x0C; // CLASS_GENERAL_F —— GreatShield
const int classWyvernKnight = 0x23; // CLASS_WYVERN_KNIGHT —— Pierce
const int classWyvernKnightF = 0x24; // CLASS_WYVERN_KNIGHT_F —— Pierce
const int classDemonKing = 0x66; // CLASS_DEMON_KING —— 免疫瞬杀

const int itemBallistaRegular = 0x35;
const int itemBallistaLong = 0x36;
const int itemBallistaKiller = 0x37;

/// `WPN_EFFECT_POISON` —— 毒武器会让 GreatShield 直接返回（不消耗乱数）
const int wpnEffectPoison = 1;

/// `BattleCheckSureShot`
///
/// ⚠️ 两种情况的消耗**不一样**，这是最容易写错的地方：
///   * 狙击手 + 弩车      → 直接必中，**不消耗乱数**
///   * 狙击手 + 非弩车    → `BattleRoll1RN(level)`，**消耗 1 个**
///   * 其它职业          → 什么都不做，**不消耗**
///
/// 我第一版把它写成"要么不消耗、要么直接返回 bool"，漏掉了非弩车那条 roll。
void battleCheckSureShot(
  BattleRngTracker tracker,
  BattleCtx ctx,
  BattleCombatant attacker,
  int weaponIndex,
) {
  if (ctx.stats.attributes & BattleHitAttr.sureshot != 0) return;
  if (ctx.stats.attributes & BattleHitAttr.pierce != 0) return;
  if (ctx.stats.attributes & BattleHitAttr.greatShield != 0) return;

  if (attacker.classId != classSniper && attacker.classId != classSniperF) {
    return;
  }

  final isBallista = weaponIndex == itemBallistaRegular ||
      weaponIndex == itemBallistaLong ||
      weaponIndex == itemBallistaKiller;
  if (isBallista) return; // 弩车：必中，且不消耗乱数

  if (_battleRoll1Rn(tracker, ctx, attacker.level, false)) {
    ctx.stats.attributes |= BattleHitAttr.sureshot;
  }
}

/// `BattleCheckSilencer`
///
/// 魔王免疫。其余情况消耗 1 个乱数（SIMULATE 下不消耗）。
bool battleCheckSilencer(
  BattleRngTracker tracker,
  BattleCtx ctx,
  BattleCombatant defender,
) {
  if (defender.classId == classDemonKing) return false;
  return _battleRoll1Rn(tracker, ctx, ctx.stats.silencerRate, false);
}

/// `BattleGenerateHitAttributes` 的乱数消耗与判定流程。
///
/// 返回消耗掉的乱数个数（同时把结果写进 [ctx]）。
int battleGenerateHitAttributes(
  BattleRngTracker tracker,
  BattleHitContext ctx,
  BattleCombatant attacker,
  BattleCombatant defender, {
  int weaponIndex = 1,
  bool weaponIsPoison = false,
}) {
  final start = tracker.consumed;
  final c = BattleCtx(ctx);

  ctx.damage = 0;

  // ---- 1. SureShot（狙击手非弩车时会消耗 1 个乱数）----
  battleCheckSureShot(tracker, c, attacker, weaponIndex);

  // ---- 2. 命中判定 ----
  if (ctx.attributes & BattleHitAttr.sureshot == 0) {
    if (!_battleRoll2Rn(tracker, c, ctx.hitRate, true)) {
      ctx.attributes |= BattleHitAttr.miss;
      return tracker.consumed - start;
    }
  }

  final attack = ctx.attack;
  var defense = ctx.defense;

  // ---- 3. GreatShield（只有 CLASS_GENERAL / CLASS_GENERAL_F）----
  if (ctx.attributes & BattleHitAttr.miss == 0 &&
      ctx.attributes & BattleHitAttr.sureshot == 0 &&
      ctx.attributes & BattleHitAttr.pierce == 0 &&
      ctx.attributes & BattleHitAttr.greatShield == 0 &&
      !weaponIsPoison &&
      (defender.classId == classGeneral || defender.classId == classGeneralF)) {
    if (_battleRoll1Rn(tracker, c, attacker.level, false)) {
      ctx.attributes |= BattleHitAttr.greatShield;
    }
  }

  // ---- 4. Pierce ----
  if (ctx.attributes & BattleHitAttr.sureshot == 0 &&
      ctx.attributes & BattleHitAttr.pierce == 0 &&
      ctx.attributes & BattleHitAttr.greatShield == 0 &&
      (attacker.classId == classWyvernKnight ||
          attacker.classId == classWyvernKnightF)) {
    if (_battleRoll1Rn(tracker, c, attacker.level, false)) {
      ctx.attributes |= BattleHitAttr.pierce;
    }
  }

  if (ctx.attributes & BattleHitAttr.pierce != 0) defense = 0;

  ctx.damage = attack - defense;
  if (ctx.attributes & BattleHitAttr.greatShield != 0) ctx.damage = 0;

  // ---- 5. 必杀判定，---- 6. 瞬杀判定嵌在里面 ----
  if (_battleRoll1Rn(tracker, c, ctx.critRate, false)) {
    if (battleCheckSilencer(tracker, c, defender)) {
      ctx.attributes |= BattleHitAttr.silencer;
      ctx.damage = battleMaxDamage;
      ctx.attributes &= ~BattleHitAttr.greatShield;
    } else {
      ctx.attributes |= BattleHitAttr.crit;
      ctx.damage = ctx.damage * 3;
    }
  }

  if (ctx.damage > battleMaxDamage) ctx.damage = battleMaxDamage;
  if (ctx.damage < 0) ctx.damage = 0;

  return tracker.consumed - start;
}
