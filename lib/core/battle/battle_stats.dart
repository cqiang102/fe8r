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

  /// `IsItemEffectiveAgainst(item, unit)`
  ///
  /// 三步：
  ///   1. 防御方没有职业数据 → false
  ///   2. 武器的特效列表里没有防御方职业 → false
  ///   3. 命中后还要过"飞行抵消"：**只有**列表本身是飞行/飞行+魔物时，
  ///      才检查防御方道具里有没有 `IA_NEGATE_FLYING`
  ///
  /// 第 3 步最容易被简化错：把"抵消"做成通用规则就会让对重甲/对龙的特效
  /// 也被抵消掉。原来的实现是拿**列表指针的身份**来判定的
  /// （`GetItemEffectiveness(item) != ItemEffectiveness_Flier`），
  /// 所以这里必须显式传入"这个列表是不是飞行类"，不能靠内容推断。
  static bool isItemEffectiveAgainst(
    int item,
    BattleUnitSide defender,
    ItemTable items,
  ) {
    final classId = defender.classId;
    if (classId == null) return false;

    final effList = items.effectivenessOf(item);
    if (effList == null || effList.isEmpty) return false;

    var hit = false;
    for (final c in effList) {
      if (c == 0) break; // 终止符
      if (c == classId) {
        hit = true;
        break;
      }
    }
    if (!hit) return false;

    // 非飞行类列表：直接生效
    if (!items.dataOf(item).effectivenessIsFlier) return true;

    // 飞行类列表：防御方所有道具的属性里只要有 IA_NEGATE_FLYING 就抵消
    var attributes = 0;
    for (final it in defender.items) {
      attributes |= items.attributesOf(it);
    }
    return attributes & iaNegateFlying == 0;
  }

  /// `IsUnitEffectiveAgainst(actor, target)`
  ///
  /// 只有攻击方职业是**主教**（0x2B/0x2C）时，才对一切魔物职业生效。
  /// 没有飞行抵消那一套。
  static bool isUnitEffectiveAgainst(
    BattleUnitSide actor,
    BattleUnitSide target,
    List<int> monsterClassList,
  ) {
    final actorClass = actor.classId;
    final targetClass = target.classId;
    if (actorClass == null || targetClass == null) return false;
    if (actorClass != classBishop && actorClass != classBishopF) return false;

    for (final c in monsterClassList) {
      if (c == 0) break;
      if (c == targetClass) return true;
    }
    return false;
  }

  /// `ComputeBattleUnitAttack`
  ///
  /// ⚠️ 两条特效分支**不是 else 关系**：`IsUnitEffectiveAgainst`（主教）先算，
  /// 然后 `IsItemEffectiveAgainst`（武器特效）如果也成立，会**覆盖**掉前者的结果
  /// ——因为两条分支里都写的是 `attack = attacker->battleAttack;` 重置。
  ///
  /// 倍率也不一样：武器特效默认 ×3，但八件"神器"（圣剑/圣枪等）是 ×2。
  /// 最后再加力量；魔石直接把结果清零。
  static void computeAttack(
    BattleUnit attacker,
    BattleUnit defender,
    ItemTable items, {
    required List<int> monsterClassList,
  }) {
    attacker.battleAttack =
        items.mightOf(attacker.weapon) + attacker.wTriangleDmgBonus;
    var attack = attacker.battleAttack;

    if (isUnitEffectiveAgainst(attacker.unit, defender.unit, monsterClassList)) {
      attack = attacker.battleAttack;
      attack = attack * 3;
    }

    if (isItemEffectiveAgainst(attacker.weapon, defender.unit, items)) {
      attack = attacker.battleAttack;
      attack *= sacredWeaponDoublesDamage(attacker.weapon) ? 2 : 3;
    }

    attacker.battleAttack = attack;
    attacker.battleAttack += attacker.unit.pow;

    if (ItemTable.itemIndex(attacker.weapon) == itemMonsterStone) {
      attacker.battleAttack = 0;
    }
  }

  /// 那八件特效倍率为 ×2 而不是 ×3 的"神器"。
  ///
  /// 对应 C 里 `ComputeBattleUnitAttack` 的 switch：
  ///   ITEM_SWORD_AUDHULMA / LANCE_VIDOFNIR / AXE_GARM / BOW_NIDHOGG /
  ///   ANIMA_EXCALIBUR / LIGHT_IVALDI / SWORD_SIEGLINDE / LANCE_SIEGMUND
  static const Set<int> _sacredWeapons = {
    0x3E, // ITEM_ANIMA_EXCALIBUR
    0x85, // ITEM_SWORD_SIEGLINDE
    0x87, // ITEM_LIGHT_IVALDI
    0x8E, // ITEM_LANCE_VIDOFNIR
    0x91, // ITEM_SWORD_AUDHULMA
    0x92, // ITEM_LANCE_SIEGMUND
    0x93, // ITEM_AXE_GARM
    0x94, // ITEM_BOW_NIDHOGG
  };

  static bool sacredWeaponDoublesDamage(int item) =>
      _sacredWeapons.contains(ItemTable.itemIndex(item));

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
