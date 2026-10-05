// PORT OF: src/bmbattle.c 的 BattleUnwind / BattleGenerateRoundHits /
//          BattleGetFollowUpOrder / BattleGetBattleUnitOrder
//          + src/GetBattleUnitHitCount.c / src/BattleCheckBraveEffect.c
//
// 一次交战的**完整序列**：先手 → 反击 → 追击。
//
// ## 原版的控制流（照抄，不要"简化"）
//
//     BattleGetBattleUnitOrder(&attacker, &defender);   // 攻击方 = 发起者
//     if (!BattleGenerateRoundHits(attacker, defender)) {
//         attributes |= RETALIATE;
//         if (!BattleGenerateRoundHits(defender, attacker) &&
//             BattleGetFollowUpOrder(&attacker, &defender)) {
//             attributes = FOLLOWUP;
//             BattleGenerateRoundHits(attacker, defender);
//         }
//     }
//
// 两个关键点：
//
// 1. **反击的条件是"先手那一轮没有结束战斗"**，不是"防御方还活着且能打"。
//    `BattleGenerateRoundHits` 返回 TRUE 表示战斗**已经结束**
//    （有人 HP 归零，或防御方被石化）。所以"打死人就不再挨打"是这条
//    短路自然得到的结果 —— 不需要额外判 HP。
//
// 2. **追击只发生一次**，而且是在双方都没打死对方之后。
//    原版用的是 `attributes = FOLLOWUP`（**赋值**不是 `|=`），
//    会把 RETALIATE 标志覆盖掉。这个细节影响战斗动画的标志位。
//
// ## 勇气武器打两下
//
// `GetBattleUnitHitCount` = `1 << BattleCheckBraveEffect(attacker)`，
// 也就是带 `IA_BRAVE` 就打 2 次。注意是**左移**，所以返回值只可能是 1 或 2。

import 'battle_unit.dart';

/// `BATTLE_FOLLOWUP_SPEED_THRESHOLD`
const int battleFollowUpSpeedThreshold = 4;

/// `WPN_EFFECT_HPHALVE`
const int wpnEffectHpHalve = 3;

/// `ITEM_MONSTER_STONE`
const int monsterStoneItem = 0xB5;

/// 追击归属
enum FollowUpSide {
  none,

  /// 攻击方（发起者）追击
  actor,

  /// 防御方追击
  defender,
}

/// `BattleGetFollowUpOrder`
///
/// ⚠️ 三个判据，顺序也有意义：
///   1. **防御方速度 > 250 → 直接不追击**（防止速度异常时的计算溢出）
///   2. 速度差 **< 4** 不追击（也就是 `>= 4` 才追击，不是 `> 4`）
///   3. 速度快的一方追击；但若其武器是"半血"effect 或魔石，则不追击
///
/// 第 2 条是最容易写成 `> 4` 的地方 —— 差 4 是**能**追击的。
FollowUpSide followUpOrder({
  required int actorSpeed,
  required int defenderSpeed,
  required int followUpWeapon,          // 追击方的 weapon
  required int followUpWeaponBefore,    // 追击方的 weaponBefore
  required int followUpWeaponEffect,    // GetItemWeaponEffect(weaponBefore)
}) {
  if (defenderSpeed > 250) return FollowUpSide.none;

  final diff = (actorSpeed - defenderSpeed).abs();
  if (diff < battleFollowUpSpeedThreshold) return FollowUpSide.none;

  final side =
      actorSpeed > defenderSpeed ? FollowUpSide.actor : FollowUpSide.defender;

  if (followUpWeaponEffect == wpnEffectHpHalve) return FollowUpSide.none;
  if (ItemTable.itemIndex(followUpWeapon) == monsterStoneItem) {
    return FollowUpSide.none;
  }

  return side;
}

/// `GetBattleUnitHitCount` —— 带 `IA_BRAVE` 打两下
int battleUnitHitCount(int weaponAttributes) =>
    1 << ((weaponAttributes & iaBrave) != 0 ? 1 : 0);

/// 一次交战的步骤类型
enum BattleStepKind {
  /// 发起者的普通攻击
  attack,

  /// 防御方的反击
  retaliate,

  /// 追击（可能是任一方）
  followUp,
}

/// 交战序列里的一步
class BattleStep {
  BattleStep({
    required this.kind,
    required this.attackerIsActor,
    required this.hitIndex,
    required this.hitCount,
  });

  final BattleStepKind kind;

  /// 这一步是谁打的（true = 发起者）
  final bool attackerIsActor;

  /// 本次 round 里的第几下（0 起）
  final int hitIndex;

  /// 本次 round 一共几下（勇气武器是 2）
  final int hitCount;

  @override
  String toString() => '${kind.name}${attackerIsActor ? '(发起者)' : '(防御者)'} '
      '${hitIndex + 1}/$hitCount';
}

/// 一次交战的完整计划。
///
/// **只生成"该打谁、打几下"，不结算伤害。** 伤害要在执行时逐次算，
/// 因为每次命中的输入（HP、地形、是否已死）都在变。
class BattlePlan {
  BattlePlan(this.steps);

  final List<BattleStep> steps;

  @override
  String toString() => 'BattlePlan(${steps.map((s) => s.toString()).join(' → ')})';
}

/// 执行一步的结果，供 [battleUnwind] 决定要不要继续。
class BattleStepOutcome {
  const BattleStepOutcome({required this.finished});

  /// 战斗是否已经结束（有人 HP 归零 / 被石化）。
  ///
  /// 对应 `BattleGenerateRoundHits` 的返回值 —— 注意它表示
  /// "**结束**"而不是"成功"。
  final bool finished;

  static const bool done = true;
  static const bool alive = false;
}

/// `BattleUnwind` 的序列生成。
///
/// [perform] 负责真正执行一步（结算伤害、扣血），并返回战斗是否结束。
/// 把执行交给调用方是为了让这个文件保持纯逻辑、可单独测试；
/// 真伪判定（谁死了）依赖 HP，而 HP 属于战场状态。
///
/// 返回实际执行的步骤列表，便于调试与表现层回放。
List<BattleStep> battleUnwind({
  required BattleUnit actor,
  required BattleUnit target,
  required BattleStepOutcome Function(BattleStep step) perform,
}) {
  final executed = <BattleStep>[];

  bool runRound({
    required bool attackerIsActor,
    required BattleStepKind kind,
  }) {
    final a = attackerIsActor ? actor : target;

    // `if (!attacker->weapon) return FALSE;`
    // 没武器就打不了 —— 注意这**不算**"战斗结束"，
    // 所以对方仍然可以反击。原版也是这样：
    // 空手的防御方会被打，然后反击轮直接跳过（它没武器），
    // 然后可能被追击。
    if (a.weapon == 0) return false;

    final count = battleUnitHitCount(a.weaponAttributes);
    for (var i = 0; i < count; i++) {
      final step = BattleStep(
        kind: kind,
        attackerIsActor: attackerIsActor,
        hitIndex: i,
        hitCount: count,
      );
      executed.add(step);

      final outcome = perform(step);
      // `if (BattleGenerateHit(...)) return TRUE;` —— 结束就立刻退出
      if (outcome.finished) return true;
    }
    return false;
  }

  // 1) 发起者攻击
  final firstFinished = runRound(
    attackerIsActor: true,
    kind: BattleStepKind.attack,
  );
  if (firstFinished) return executed;

  // 2) 防御方反击
  final retaliateFinished = runRound(
    attackerIsActor: false,
    kind: BattleStepKind.retaliate,
  );
  if (retaliateFinished) return executed;

  // 3) 追击
  final followUp = followUpOrder(
    actorSpeed: actor.battleSpeed,
    defenderSpeed: target.battleSpeed,
    followUpWeapon:
        actor.battleSpeed > target.battleSpeed ? actor.weapon : target.weapon,
    followUpWeaponBefore: actor.battleSpeed > target.battleSpeed
        ? actor.weaponBefore
        : target.weaponBefore,
    followUpWeaponEffect: actor.battleSpeed > target.battleSpeed
        ? actor.followUpWeaponEffect
        : target.followUpWeaponEffect,
  );

  if (followUp == FollowUpSide.none) return executed;

  runRound(
    attackerIsActor: followUp == FollowUpSide.actor,
    kind: BattleStepKind.followUp,
  );

  return executed;
}
