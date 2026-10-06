// PORT OF: src/bmbattle.c 的 BattleGenerate 编排 + src/bmbattle_0802A0C8.c
//
// M4（战斗数值）与 M5（战场流程）之间的桥。
//
// ## 这个文件为什么必须存在
//
// `lib/core/battle/` 里的东西全是**纯函数 + 显式输入**：给定
// BattleUnit / ItemTable / 乱数，算出结果，不碰任何全局状态。
// 那是为了能被 C Oracle 逐值锁定。
//
// 但战场流程需要的是"用地图上这两个单位打一架"。把这两件事混在一起，
// 战斗数值就会被战场状态污染，Oracle 也就没法再覆盖它了。
//
// 所以这里做**翻译**：MapUnit + 职业/道具数据 → BattleUnit 对 → 调数值层 → 写回 HP。
// 翻译层不含任何规则，只有字段搬运。
//
// ## 目前是"单次攻击"，不是完整战斗
//
// 原版一次交战是 `BattleGenerateRoundHits`：按攻速决定追击、
// 按顺序生成最多 7 次命中、每次都要重新判定。
// 那需要 `BattleGetFollowUpOrder` / `BattleUnwind` 那一套（M4 未覆盖的部分）。
// 这里先做**一次攻击判定**，够让 M5 的"打完一场遭遇战"成立。

import '../battle/battle_round.dart';
import '../battle/battle_rng.dart';
import '../battle/battle_stats.dart';
import '../battle/battle_unit.dart';
import '../battle/hit_effects.dart';
import '../battle/weapon_triangle.dart';
import '../rng/game_rng.dart';
import 'battle_field.dart';

/// `CA_CRITBONUS = 1 << 6`（`include/bmunit.h:317`）
const int caCritBonus = 1 << 6;

/// 一个单位参与战斗所需的静态数据（职业/武器）。
///
/// 这些数据来自章节配置与职业表——目前是调用方喂进来的，
/// 等 M12 的章节数据管线接通后会换成查表。
class CombatProfile {
  const CombatProfile({
    this.classId = 0,
    this.level = 1,
    this.classAttributes = 0,
    this.pow = 0,
    this.skl = 0,
    this.spd = 0,
    this.def = 0,
    this.lck = 0,
    this.conBonus = 0,
    this.weaponItem = 0,
    this.weaponType = WeaponType.sword,
    this.weaponAttributes = 0,
    this.weaponEffect = WeaponEffect.none,
    this.weaponUses = 0,
  });

  final int classId;
  final int level;

  /// 职业属性位（`CA_*`，`include/bmunit.h:311-338`）。
  /// 目前只用到 `CA_CRITBONUS`（1<<6）。
  final int classAttributes;
  final int pow;
  final int skl;
  final int spd;
  final int def;
  final int lck;
  final int conBonus;

  /// 武器在道具表里的编号（0 = 空手）
  final int weaponItem;

  final int weaponType;
  final int weaponAttributes;
  final int weaponEffect;

  /// 剩余耐久（0 = 会打坏；M5 先把耐久当纯展示，不做打坏流程）
  final int weaponUses;
}

/// 一次完整交战的结果
class CombatRound {
  CombatRound({required this.steps, required this.results});

  /// 实际执行的步骤序列（含反击与追击）
  final List<BattleStep> steps;

  /// 每一步的结果，与 [steps] 一一对应
  final List<AttackResult> results;

  int get totalDamage =>
      results.fold(0, (sum, r) => sum + r.damage);

  int get rnConsumed => results.fold(0, (sum, r) => sum + r.rnConsumed);

  bool get anyCrit => results.any((r) => r.crit);

  @override
  String toString() {
    final b = StringBuffer();
    for (var i = 0; i < steps.length; i++) {
      if (i > 0) b.write('  ');
      b.write('[${steps[i].toString()}] ${results[i]}');
    }
    return b.toString();
  }
}

/// 一次攻击的完整结果
class AttackResult {
  AttackResult({
    required this.hit,
    required this.crit,
    required this.damage,
    required this.hpBefore,
    required this.hpAfter,
    required this.rnConsumed,
    this.devilBackfire = false,
  });

  final bool hit;
  final bool crit;

  /// 实际造成的伤害（已钳到目标当前 HP）
  final int damage;

  final int hpBefore;
  final int hpAfter;

  /// 这次攻击消耗了几个乱数 —— 调试乱数错位时这个比结果更有用
  final int rnConsumed;

  final bool devilBackfire;

  @override
  String toString() => 'AttackResult(${hit ? '命中' : '未命中'}'
      '${crit ? ' 必杀' : ''} $hpBefore->$hpAfter (-$damage) '
      '消耗 $rnConsumed 个乱数)';
}

/// 战斗结算。
class CombatResolver {
  CombatResolver({
    required this.items,
    required this.triangle,
    this.monsterClassList = const [],
  });

  final ItemTable items;
  final WeaponTriangleTable triangle;

  /// 主教"斩魔"特效用的魔物职业列表
  final List<int> monsterClassList;

  /// 把模板套到一个地图单位上，造出战斗用的 `BattleUnit`。
  BattleUnit buildBattleUnit(MapUnit unit, CombatProfile p) {
    final bu = BattleUnit();
    bu.unit = BattleUnitSide(
      def: p.def,
      lck: p.lck,
      spd: p.spd,
      conBonus: p.conBonus,
      pow: p.pow,
      skl: p.skl,
      classId: p.classId,
      // 判定阈值要用真实等级 —— 见 `_toCombatant` 的说明
      level: p.level,
      classAttributes: p.classAttributes,
    );
    bu.weapon = p.weaponItem;
    bu.weaponBefore = p.weaponItem;
    bu.weaponType = p.weaponType;
    bu.weaponAttributes = p.weaponAttributes;
    return bu;
  }

  /// 结算**一次完整交战**：先手 → 反击 → 追击。
  ///
  /// 序列由规则层的 [battleUnwind] 决定（控制流与 C Oracle 锁定），
  /// 这里只负责"每一步怎么算"。
  ///
  /// ⚠️ 每一步都要**重新取双方的战斗单位与数值**：
  /// 前一步可能打死了人、可能改变了 HP（半血武器按当前 HP 算攻击力），
  /// 用循环外算好的一份数据会得到 C 不可能产生的结果。
  CombatRound resolveCombat({
    required BattleRngTracker tracker,
    required GameRng rng,
    required MapUnit actorUnit,
    required MapUnit targetUnit,
    required CombatProfile actorProfile,
    required CombatProfile targetProfile,
    required int actorTerrainDefense,
    required int actorTerrainAvoid,
    required int targetTerrainDefense,
    required int targetTerrainAvoid,
  }) {
    final results = <AttackResult>[];

    // 只建一次：追击判定要用 battleSpeed，而速度在一次交战中不变。
    // **每一步的攻防数值由 `attack` 重算** —— 半血武器按当前 HP 算攻击力，
    // 用循环外算好的一份数据会得到 C 不可能产生的结果。
    final actorBu = buildBattleUnit(actorUnit, actorProfile)
      ..followUpWeaponEffect = items.weaponEffectOf(actorProfile.weaponItem);
    final targetBu = buildBattleUnit(targetUnit, targetProfile)
      ..followUpWeaponEffect = items.weaponEffectOf(targetProfile.weaponItem);

    // battleUnwind 只需要速度；这里先把速度算出来
    BattleStats.computeSpeed(actorBu, items);
    BattleStats.computeSpeed(targetBu, items);

    final steps = battleUnwind(
      actor: actorBu,
      target: targetBu,
      perform: (step) {
        final attacker = step.attackerIsActor ? actorUnit : targetUnit;
        final defender = step.attackerIsActor ? targetUnit : actorUnit;
        final ap = step.attackerIsActor ? actorProfile : targetProfile;
        final dp = step.attackerIsActor ? targetProfile : actorProfile;
        final aTd =
            step.attackerIsActor ? actorTerrainDefense : targetTerrainDefense;
        final aTa =
            step.attackerIsActor ? actorTerrainAvoid : targetTerrainAvoid;
        final dTd =
            step.attackerIsActor ? targetTerrainDefense : actorTerrainDefense;
        final dTa =
            step.attackerIsActor ? targetTerrainAvoid : actorTerrainAvoid;

        results.add(attack(
          tracker: tracker,
          rng: rng,
          attackerUnit: attacker,
          defenderUnit: defender,
          attackerProfile: ap,
          defenderProfile: dp,
          terrainDefense: dTd,
          terrainAvoid: dTa,
          attackerTerrainDefense: aTd,
          attackerTerrainAvoid: aTa,
        ));

        // `BattleGenerateHit` 的结束条件：**任一方** HP 归零
        return BattleStepOutcome(
          finished: actorUnit.hp <= 0 || targetUnit.hp <= 0,
        );
      },
    );

    return CombatRound(steps: steps, results: results);
  }

  /// 结算一次攻击。
  ///
  /// 顺序严格跟随原版：
  ///   1. 算攻防命中必杀（`ComputeBattleUnit*`）
  ///   2. 武器三角
  ///   3. 命中判定（Roll2RN）→ 未命中就结束
  ///   4. 必杀判定（Roll1RN）
  ///   5. 扣血（含恶魔武器反噬，会再消耗 1 个乱数）
  AttackResult attack({
    required BattleRngTracker tracker,
    required GameRng rng,
    required MapUnit attackerUnit,
    required MapUnit defenderUnit,
    required CombatProfile attackerProfile,
    required CombatProfile defenderProfile,
    required int terrainDefense,
    required int terrainAvoid,
    int attackerTerrainDefense = 0,
    int attackerTerrainAvoid = 0,
  }) {
    final atk = buildBattleUnit(attackerUnit, attackerProfile);
    final def = buildBattleUnit(defenderUnit, defenderProfile);

    atk.setTerrain(
        defense: attackerTerrainDefense, avoid: attackerTerrainAvoid);
    def.setTerrain(defense: terrainDefense, avoid: terrainAvoid);

    // ---- 0. 武器三角必须**最先**应用 ----
    //
    // ⚠️ 我原来把它放在 `computeAttack` / `computeHitRate` **之后**，
    // 于是 `wTriangleDmgBonus` / `wTriangleHitBonus` 写进 BattleUnit 时，
    // 攻击力和命中率**已经算完了** —— 加成全部丢失。
    //
    // `src/bmbattle_0802A0C8.c:53,82`：`BattleApplyWeaponTriangleEffect`
    // 在 `SetBattleUnitTerrainBonusesAuto` / `BattleGenerate` /
    // `ComputeBattleUnitStats` **之前**调用；而
    // `ComputeBattleUnitAttack`（`src/ComputeBattleUnitAttack.c:11`）与
    // `ComputeBattleUnitHitRate`（`src/bmbattle_0802AB1C.c:29-30`）
    // 内部都要读这两个字段。
    //
    // 反例（审计给的）：剑 vs 斧 `{+15 hit, +1 atk}`，
    // skl=5 / 回避=10 / 武器命中 85 →
    //   C：  10+85+0+15 = 110 → 有效命中 **100**（上限钳位）
    //   原来：10+85+0+0  =  95 → 有效命中 **85**
    // 差 15 点命中 + 1 点伤害，而且 100 与 85 经 `Roll2RN` 的分布不同。
    triangle.apply(atk, def);

    // ---- 1. 数值 ----
    BattleStats.computeAttack(atk, def, items,
        monsterClassList: monsterClassList);
    // ⚠️ 主路径用 `ComputeBattleUnitDefense`（看武器是否带 IA_MAGIC*），
    // **不是** `ComputeBattleUnitBaseDefense` —— 后者只用于道具/杖效果路径。
    BattleStats.computeDefense(atk, def);
    BattleStats.computeDefense(def, atk);
    BattleStats.computeSpeed(atk, items);
    BattleStats.computeSpeed(def, items);
    computeHitRate(atk, items);
    computeHitRate(def, items);
    BattleStats.computeAvoidRate(atk);
    BattleStats.computeAvoidRate(def);
    BattleStats.computeDodgeRate(def);

    // ⚠️ 必须走规则层的 computeEffectiveHitRate，不能自己写减法 ——
    // 它带着**上限 100** 的钳位。我第一版就是自己写的减法，
    // 结果 120 的命中率一路传进 Roll2RN，分布和原版不同。
    BattleStats.computeEffectiveHitRate(atk, def);

    // 必杀率要在回避/幸运算完之后再算
    // ⚠️ 必杀率还要加 `CA_CRITBONUS`（+15）。
    //
    // `src/bmbattle_0802AB88.c:29-34`（`ComputeBattleUnitCritRate`）：
    //     if (UNIT_CATTRIBUTES(unit) & CA_CRITBONUS) battleCritRate += 15;
    // `CA_CRITBONUS = 1 << 6`（`include/bmunit.h:317`）。
    //
    // 我原来是内联 `items.critOf(...) + skl ~/ 2`，**整个 +15 没了**。
    atk.battleCritRate =
        items.critOf(attackerProfile.weaponItem) + (atk.unit.skl ~/ 2);
    if (atk.unit.classAttributes & caCritBonus != 0) {
      atk.battleCritRate += 15;
    }
    BattleStats.computeEffectiveCritRate(atk, def, items);
    BattleStats.computeSilencerRate(atk, def);

    final effectiveHit = atk.battleEffectiveHitRate;

    // ---- 3~5. 判定与扣血 ----
    final ctx = BattleHitContext(
      hitRate: effectiveHit,
      critRate: atk.battleEffectiveCritRate,
      silencerRate: atk.battleSilencerRate,
      attack: atk.battleAttack,
      // 原版 `gBattleStats.defense` 用的是 `battleDefense`（含地形）
      defense: def.battleDefense,
    );

    final hpBefore = defenderUnit.hp;
    // ⚠️ tracker.consumed 是**累计值**，这里要报的是本次攻击消耗了几个。
    // 直接拿累计值当"本次消耗"是最容易犯的错——调试图里会看到
    // 第二次攻击莫名消耗了几十个乱数。
    final rnBefore = tracker.consumed;
    battleGenerateHitAttributes(tracker, ctx, _toCombatant(atk),
            _toCombatant(def), weaponIndex: attackerProfile.weaponItem,
            weaponIsPoison:
                attackerProfile.weaponEffect == WeaponEffect.poison);

    final isMiss = ctx.attributes & BattleHitAttr.miss != 0;

    final eff = applyHitEffects(
      tracker: tracker,
      rng: rng,
      attacker: atk,
      defender: def,
      damage: ctx.damage,
      isMiss: isMiss,
      weaponEffect: attackerProfile.weaponEffect,
      attackerHp: attackerUnit.hp,
      attackerMaxHp: attackerUnit.maxHp,
      defenderHp: defenderUnit.hp,
    );

    // 写回
    attackerUnit.hp = eff.attackerHp;
    defenderUnit.hp = eff.defenderHp;

    return AttackResult(
      hit: !isMiss,
      crit: ctx.attributes & BattleHitAttr.crit != 0,
      damage: eff.damageDealt,
      hpBefore: hpBefore,
      hpAfter: defenderUnit.hp,
      rnConsumed: tracker.consumed - rnBefore,
      devilBackfire: eff.devilBackfire,
    );
  }

  /// ⚠️ `level` **必须取自单位**，不能硬编码。
  ///
  /// C 的 SureShot / GreatShield / Pierce 三次判定都用 `attacker->unit.level`
  /// 当阈值：`src/bmbattle_0802B164.c:54`（SureShot）、`:80`（Pierce）、
  /// `:111`（GreatShield）。而 `battle_rng.dart:181/235/246` 确实传了
  /// `attacker.level`（`CombatProfile` 也有 `level` 字段）——
  /// **但我这里永远给 1**，于是等级 20 的狙击手/翼骑士/将军
  /// 判定阈值恒为 1 → 这些职业特色几乎必定失败。
  ///
  /// （判定各消耗 1 个 RN，所以**乱数消耗次数不变**，但成功与否全错。）
  static BattleCombatant _toCombatant(BattleUnit bu) => BattleCombatant(
        classId: bu.unit.classId ?? 0,
        level: bu.unit.level,
        items: bu.unit.items,
      );
}
