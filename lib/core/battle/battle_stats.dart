// PORT OF: src/ComputeBattleUnitAvoidRate.c, src/ComputeBattleUnitBaseDefense.c,
//          src/ComputeBattleUnitDodgeRate.c, src/ComputeBattleUnitEffectiveCritRate.c,
//          src/ComputeBattleUnitSpeed.c, src/GetUnitDefense.c, src/GetItemDefBonus.c
//
// 战斗数值计算。**这是规则层，必须与 C 逐位一致。**
//
// 这几个函数看起来简单（加减法），但每一处"负数钳位"都是手写移植最容易漏的分支，
// 而且漏了之后只有在特定数值下才表现不同——所以它们全部由 C Oracle 逐值锁定，
// 见 test/core/battle_oracle_test.dart。

import 'battle_unit.dart';

/// 战斗数值计算。
class BattleStats {
  const BattleStats._();

  /// `ComputeBattleUnitBaseDefense`
  ///
  /// C 里没有钳位：`terrainDefense + unit.def` 直接相加。
  static void computeBaseDefense(BattleUnit bu) {
    bu.battleDefense = bu.terrainDefense + bu.unit.def;
  }

  /// `ComputeBattleUnitDodgeRate` —— 就是幸运值
  static void computeDodgeRate(BattleUnit bu) {
    bu.battleDodgeRate = bu.unit.lck;
  }

  /// `ComputeBattleUnitAvoidRate`
  ///
  /// `speed*2 + terrainAvoid + lck`，**负数钳位到 0**。
  /// 那个钳位不是防御性代码，它是实际会触发的分支（负地形回避）。
  static void computeAvoidRate(BattleUnit bu) {
    var v = bu.battleSpeed * 2 + bu.terrainAvoid + bu.unit.lck;
    if (v < 0) v = 0;
    bu.battleAvoidRate = v;
  }

  /// `ComputeBattleUnitSpeed`
  ///
  /// 有效重量 = 武器重量 - 体格加成，**钳位到 0**；
  /// 速度 = spd - 有效重量，再**钳位到 0**。
  ///
  /// 注意用的是 `weaponBefore` 而不是 `weapon`（原版刻意如此）。
  static void computeSpeed(BattleUnit bu, ItemTable items) {
    var effWt = items.weightOf(bu.weaponBefore) - bu.unit.conBonus;
    if (effWt < 0) effWt = 0;

    var spd = bu.unit.spd - effWt;
    if (spd < 0) spd = 0;
    bu.battleSpeed = spd;
  }

  /// `ComputeBattleUnitEffectiveCritRate`
  ///
  /// 三条**互相独立**的归零分支，顺序也有讲究：
  ///   1. `crit - dodge`，然后负数钳位到 0
  ///   2. 攻击方拿的是魔石 → 0
  ///   3. 防御方身上**任意**一件道具带 `IA_NEGATE_CRIT` → 0
  ///
  /// 第 3 条的循环会在遇到空道具时提前终止——这个短路在 C 里是
  /// `(item = defender->unit.items[i])` 赋值表达式的一部分，
  /// 移植时很容易顺手写成遍历整个数组，于是"空道具之后的道具"被错误地看到了。
  static void computeEffectiveCritRate(
    BattleUnit attacker,
    BattleUnit defender,
    ItemTable items,
  ) {
    attacker.battleEffectiveCritRate =
        attacker.battleCritRate - defender.battleDodgeRate;

    if (ItemTable.itemIndex(attacker.weapon) == itemMonsterStone) {
      attacker.battleEffectiveCritRate = 0;
    }

    if (attacker.battleEffectiveCritRate < 0) {
      attacker.battleEffectiveCritRate = 0;
    }

    for (var i = 0; i < unitItemCount; i++) {
      final item = defender.unit.items[i];
      if (item == 0) break; // ★ 短路：空道具处终止
      if (items.attributesOf(item) & iaNegateCrit != 0) {
        attacker.battleEffectiveCritRate = 0;
        break;
      }
    }
  }

  /// `GetUnitDefense`
  ///
  /// `unit->def + GetItemDefBonus(GetUnitEquippedWeapon(unit))`
  ///
  /// 原版内部调 `GetUnitEquippedWeapon`，那条依赖链会一路扯到武器等级判定。
  /// Oracle 把它 stub 成 `items[0] & 0xFF`，所以这里把"装备了什么"作为
  /// 显式参数传进来——**依赖显式化**本身就是技术方案 §4.8.2 要求的方向。
  static int unitDefense(BattleUnitSide unit, int equippedWeapon, ItemTable items) =>
      unit.def + items.defBonusOf(equippedWeapon);

  /// `GetItemDefBonus`
  ///
  /// 空道具 → 0；有道具但没有加成表 → 0。
  static int itemDefBonus(int item, ItemTable items) => items.defBonusOf(item);
}
