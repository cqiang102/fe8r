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

import '../battle/battle_rng.dart';
import '../battle/battle_stats.dart';
import '../battle/battle_unit.dart';
import '../battle/hit_effects.dart';
import '../battle/weapon_triangle.dart';
import '../rng/game_rng.dart';
import 'battle_field.dart';

/// 一个单位参与战斗所需的静态数据（职业/武器）。
///
/// 这些数据来自章节配置与职业表——目前是调用方喂进来的，
/// 等 M12 的章节数据管线接通后会换成查表。
class CombatProfile {
  const CombatProfile({
    this.classId = 0,
    this.level = 1,
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
    );
    bu.weapon = p.weaponItem;
    bu.weaponBefore = p.weaponItem;
    bu.weaponType = p.weaponType;
    bu.weaponAttributes = p.weaponAttributes;
    return bu;
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
  }) {
    final atk = buildBattleUnit(attackerUnit, attackerProfile);
    final def = buildBattleUnit(defenderUnit, defenderProfile);

    // ---- 1. 数值 ----
    BattleStats.computeAttack(atk, def, items,
        monsterClassList: monsterClassList);
    BattleStats.computeBaseDefense(def);
    def.setTerrain(defense: terrainDefense, avoid: terrainAvoid);
    BattleStats.computeBaseDefense(def);
    BattleStats.computeSpeed(atk, items);
    BattleStats.computeSpeed(def, items);
    computeHitRate(atk, items);
    computeHitRate(def, items);
    BattleStats.computeAvoidRate(atk);
    BattleStats.computeAvoidRate(def);
    BattleStats.computeDodgeRate(def);

    // ---- 2. 武器三角 ----
    triangle.apply(atk, def);

    // 有效命中 = 命中 - 回避（原版还有武器相克等修正，这里覆盖主要项）
    final effectiveHit = atk.battleHitRate - def.battleAvoidRate;

    // 必杀率要在回避/幸运算完之后再算
    atk.battleCritRate = items.critOf(attackerProfile.weaponItem) +
        (atk.unit.skl ~/ 2);
    BattleStats.computeEffectiveCritRate(atk, def, items);

    // ---- 3~5. 判定与扣血 ----
    final ctx = BattleHitContext(
      hitRate: effectiveHit,
      critRate: atk.battleEffectiveCritRate,
      silencerRate: 0,
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

  static BattleCombatant _toCombatant(BattleUnit bu) => BattleCombatant(
        classId: bu.unit.classId ?? 0,
        level: 1,
        items: bu.unit.items,
      );
}
