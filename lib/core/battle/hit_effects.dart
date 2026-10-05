// PORT OF: src/BattleGenerateHitEffects.c
//
// 把一次判定的结果**落到实际 HP 上**。
//
// ## 一个非常容易被忽略的细节
//
// 扣血前原版会先把伤害**钳到防御方的当前 HP**：
//
//     if (gBattleStats.damage > defender->unit.curHP)
//         gBattleStats.damage = defender->unit.curHP;
//     defender->unit.curHP -= gBattleStats.damage;
//
// 而且 `gBattleHitIterator->hpChange = gBattleStats.damage` 记的是
// **钳位之后**的值。也就是说：一个只剩 5 HP 的单位被 24 点伤害打中，
// 战斗动画上跳的是 **5**，不是 24。
//
// 不钳位的话数值结果碰巧也对（HP 会被下面那句 floor 到 0 兜住），
// 但**显示的数字会错**，而且 `hpChange` 这个字段会被下游拿去算别的东西。
// 这类"结果对、中间值错"的 bug 最难发现——所以这里严格照抄顺序。
//
// ## 恶魔武器：打自己
//
// `WPN_EFFECT_DEVIL` 的武器有概率**把伤害打在自己身上**，
// 而且**消耗 1 个乱数**（`BattleRoll1RN(31 - luck)`）。
// 这是战斗流程里少数几个"消耗乱数但和命中/必杀无关"的地方，
// M4 的乱数消耗追踪里没有覆盖到它——因为那条路径需要武器带 DEVIL 属性。

import '../rng/game_rng.dart';
import 'battle_rng.dart';
import 'battle_unit.dart';

/// `WPN_EFFECT_*`
class WeaponEffect {
  static const int none = 0;
  static const int poison = 1;
  static const int hpDrain = 2;
  static const int hpHalve = 3;
  static const int devil = 4;
  static const int petrify = 5;
}

/// 一次命中效果的结果
class HitEffectResult {
  HitEffectResult({
    required this.damageDealt,
    required this.attackerHp,
    required this.defenderHp,
    this.devilBackfire = false,
    this.drained = 0,
  });

  /// 实际造成的伤害（**钳位后**，与 `hpChange` 一致）
  final int damageDealt;

  final int attackerHp;
  final int defenderHp;

  /// 恶魔武器是否反噬了攻击方
  final bool devilBackfire;

  /// 吸血回复量
  final int drained;
}

/// `BattleGenerateHitEffects` 中与 HP 相关的部分。
///
/// 道具特效（中毒/石化/半血）属于状态系统（M6），这里先不做，
/// 但**乱数消耗**必须照做——否则之后的乱数序列会整体错位。
HitEffectResult applyHitEffects({
  required BattleRngTracker tracker,
  required GameRng rng,
  required BattleUnit attacker,
  required BattleUnit defender,
  required int damage,
  required bool isMiss,
  int weaponEffect = WeaponEffect.none,
  int attackerHp = 0,
  int attackerMaxHp = 0,
  int defenderHp = 0,
  int config = BattleConfig.real,
}) {
  // 未命中：什么都不发生（但注意武器耐久仍会消耗，那部分不在本函数）
  if (isMiss) {
    return HitEffectResult(
      damageDealt: 0,
      attackerHp: attackerHp,
      defenderHp: defenderHp,
    );
  }

  var aHp = attackerHp;
  var dHp = defenderHp;
  var dealt = damage;
  var devil = false;
  var drained = 0;

  if (damage != 0) {
    // 魔石（魔物专用的"石化"武器）不参与这里的伤害流程
    final isDemonKing = defender.unit.classId == classDemonKing;

    if (weaponEffect == WeaponEffect.devil && !isDemonKing) {
      // ⚠️ 恶魔武器判定会消耗 1 个乱数，且**与是否命中/必杀无关**
      final threshold = 31 - attacker.unit.lck;
      final backfire = _battleRoll1Rn(tracker, config, threshold, false);

      if (backfire) {
        devil = true;
        aHp -= dealt;
        if (aHp < 0) aHp = 0;
      } else {
        if (dealt > dHp) dealt = dHp; // ★ 先钳位
        dHp -= dealt;
        if (dHp < 0) dHp = 0;
      }
    } else {
      if (dealt > dHp) dealt = dHp; // ★ 先钳位
      dHp -= dealt;
      if (dHp < 0) dHp = 0;
    }

    // 吸血：回复量用的是**钳位后**的 dealt
    if (weaponEffect == WeaponEffect.hpDrain) {
      aHp += dealt;
      if (aHp > attackerMaxHp) aHp = attackerMaxHp;
      drained = dealt;
    }
  }

  return HitEffectResult(
    damageDealt: dealt,
    attackerHp: aHp,
    defenderHp: dHp,
    devilBackfire: devil,
    drained: drained,
  );
}

bool _battleRoll1Rn(
  BattleRngTracker tracker,
  int config,
  int threshold,
  bool sim,
) {
  if (config & BattleConfig.simulate != 0) return sim;
  return tracker.roll1Rn(threshold);
}
