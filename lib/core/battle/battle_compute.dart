// PORT OF: src/ComputeBattleUnitAttack.c + ComputeBattleUnitBaseDefense.c
//          + ComputeBattleUnitSpeed.c + ComputeBattleUnitAvoidRate.c
//          + ComputeBattleUnitDodgeRate.c
//
// 战斗属性**逐条按源码算**，不再用硬编码的演示值。
//
// ## 为什么单独一个文件
//
// 原来是 `Fe8Game._profileFor()` 里手写的：
//
//     if (u.factionBit == Faction.red) {
//       final isArcher = u.id == 0x82;           // 演示单位的 id
//       return CombatProfile(classId: isArcher ? 0x1B : 0x2A, ...);
//     }
//
// **后果：奥尼尔打不掉**（`C63:20` 一直满血），伤害全落在艾莉丝身上。
//
// ## 源码里的公式（逐条对照）
//
// ```c
// // ComputeBattleUnitBaseDefense.c
// bu->battleDefense = bu->terrainDefense + bu->unit.def;
//
// // ComputeBattleUnitSpeed.c
// int effWt = GetItemWeight(bu->weaponBefore) - bu->unit.conBonus;
// if (effWt < 0) effWt = 0;
// bu->battleSpeed = bu->unit.spd - effWt;
// if (bu->battleSpeed < 0) bu->battleSpeed = 0;
//
// // ComputeBattleUnitAvoidRate.c
// bu->battleAvoidRate = (bu->battleSpeed * 2) + bu->terrainAvoid + bu->unit.lck;
// if (bu->battleAvoidRate < 0) bu->battleAvoidRate = 0;
//
// // ComputeBattleUnitDodgeRate.c
// bu->battleDodgeRate = bu->unit.lck;
//
// // ComputeBattleUnitAttack.c（简化：不含特效武器）
// attacker->battleAttack = GetItemMight(attacker->weapon) + attacker->wTriangleDmgBonus;
// ```
//
// ## `unit.def` / `unit.spd` / `unit.lck` 从哪来
//
// **职业基础值 + 角色基础值**（`InitUnit` 里相加）。实测印证了 GBA FE 的模型：
//
//     CLASS_EIRIKA_LORD: baseHP=16 basePow=4 baseSkl=8 baseSpd=9 baseDef=3 baseRes=1 baseCon=5
//     CHARACTER_EIRIKA:  baseLevel=1 baseLck=5（角色**只有**等级和幸运）
//
// 三张表都由数据管线从源码抽出：
//     `classes.json` / `characters.json` / `items.json`

import 'dart:math' as math;

/// 职业数据（`struct ClassData`，`include/bmunit.h:61`）
class ClassStats {
  const ClassStats({
    required this.number,
    this.baseHP = 0,
    this.basePow = 0,
    this.baseSkl = 0,
    this.baseSpd = 0,
    this.baseDef = 0,
    this.baseRes = 0,
    this.baseCon = 0,
    this.baseMov = 0,
    // ★ 等级成长用的**成长值**（`UnitAutolevelCore` 逐项要用）。
    // 第 59 轮之前这里没有它们 ⇒ 数值无法随等级增长（欠账 55）。
    this.growthHP = 0,
    this.growthPow = 0,
    this.growthSkl = 0,
    this.growthSpd = 0,
    this.growthDef = 0,
    this.growthRes = 0,
    this.growthLck = 0,
  });

  factory ClassStats.fromJson(Map<String, dynamic> j) => ClassStats(
        number: (j['number'] as num?)?.toInt() ?? 0,
        baseHP: (j['baseHP'] as num?)?.toInt() ?? 0,
        basePow: (j['basePow'] as num?)?.toInt() ?? 0,
        baseSkl: (j['baseSkl'] as num?)?.toInt() ?? 0,
        baseSpd: (j['baseSpd'] as num?)?.toInt() ?? 0,
        baseDef: (j['baseDef'] as num?)?.toInt() ?? 0,
        baseRes: (j['baseRes'] as num?)?.toInt() ?? 0,
        baseCon: (j['baseCon'] as num?)?.toInt() ?? 0,
        baseMov: (j['baseMov'] as num?)?.toInt() ?? 0,
        growthHP: (j['growthHP'] as num?)?.toInt() ?? 0,
        growthPow: (j['growthPow'] as num?)?.toInt() ?? 0,
        growthSkl: (j['growthSkl'] as num?)?.toInt() ?? 0,
        growthSpd: (j['growthSpd'] as num?)?.toInt() ?? 0,
        growthDef: (j['growthDef'] as num?)?.toInt() ?? 0,
        growthRes: (j['growthRes'] as num?)?.toInt() ?? 0,
        growthLck: (j['growthLck'] as num?)?.toInt() ?? 0,
      );

  final int number;
  final int baseHP, basePow, baseSkl, baseSpd, baseDef, baseRes, baseCon, baseMov;

  /// 成长值（百分数；`src/data/data_classes.c` 的 `growthHP` 等）。
  /// `UnitAutolevelCore` 用的是**职业自己的**成长值（不是职业+角色）。
  final int growthHP, growthPow, growthSkl, growthSpd, growthDef, growthRes,
      growthLck;
}

/// 角色数据（`struct CharacterData`）
///
/// ⚠️ **角色只有 `baseLevel` / `baseLck`** —— 其余属性全在职业上。
class CharStats {
  const CharStats({required this.number, this.baseLevel = 1, this.baseLck = 0});

  factory CharStats.fromJson(Map<String, dynamic> j) => CharStats(
        number: (j['number'] as num?)?.toInt() ?? 0,
        baseLevel: (j['baseLevel'] as num?)?.toInt() ?? 1,
        baseLck: (j['baseLck'] as num?)?.toInt() ?? 0,
      );

  final int number;
  final int baseLevel;
  final int baseLck;
}

/// 道具数据（`struct ItemData`，`include/bmitem.h:28`）
class ItemStats {
  const ItemStats({
    required this.number,
    this.might = 0,
    this.hit = 0,
    this.crit = 0,
    this.weight = 0,
    this.encodedRange = 0,
    this.weaponType = 0,
    this.maxUses = 0,
    this.attributes = 0,
  });

  factory ItemStats.fromJson(Map<String, dynamic> j) => ItemStats(
        number: (j['number'] as num?)?.toInt() ?? 0,
        might: (j['might'] as num?)?.toInt() ?? 0,
        hit: (j['hit'] as num?)?.toInt() ?? 0,
        crit: (j['crit'] as num?)?.toInt() ?? 0,
        weight: (j['weight'] as num?)?.toInt() ?? 0,
        encodedRange: (j['encodedRange'] as num?)?.toInt() ?? 0,
        weaponType: (j['weaponType'] as num?)?.toInt() ?? 0,
        maxUses: (j['maxUses'] as num?)?.toInt() ?? 0,
        attributes: (j['attributes'] as num?)?.toInt() ?? 0,
      );

  final int number;
  final int might, hit, crit, weight, encodedRange;

  /// `ITYPE_*` 的**数值**（`include/bmitem.h:84-96`）：
  ///
  /// ```c
  /// ITYPE_SWORD = 0, ITYPE_LANCE = 1, ITYPE_AXE = 2, ITYPE_BOW = 3,
  /// ITYPE_STAFF = 4, ITYPE_ANIMA = 5, ITYPE_LIGHT = 6, ITYPE_DARK = 7, ...
  /// ```
  ///
  /// 与 `WeaponType.sword/lance/axe/bow/staff/anima/light/dark`
  /// （`lib/core/battle/weapon_triangle.dart:26-34`）**逐个数相同** ——
  /// 所以映射是恒等的，不需要 switch。
  ///
  /// ⚠️ 提取器原来把它当**字符串**留下（`'ITYPE_LANCE'`），
  /// 属性位（`IA_*`）也当字符串 —— 两头都没接上。
  final int weaponType;

  /// `IA_WEAPON = (1 << 0)`（`include/bmitem.h:56`）—— 判断"这是不是武器"。
  ///
  /// ⚠️ 不能靠 `weaponType` 判断：`ITYPE_SWORD = 0`，
  /// 而"没有武器类型"的条目也是 0 —— 两者分不开。
  bool get isWeapon => attributes & iaWeapon != 0;

  /// `IA_WEAPON = (1 << 0)`
  static const int iaWeapon = 1 << 0;

  /// `GetItemMaxUses` —— `MakeNewItem` 用它算耐久
  final int maxUses;

  /// `IA_*` 位掩码（`include/bmitem.h:52-`）。
  ///
  /// ⚠️ 提取器原来把它当成**字符串**留下（`'IA_WEAPON'`），
  /// 于是：
  ///   * `MakeNewItem` 的 `IA_UNBREAKABLE` 分支永远不成立
  ///   * `_realItems()` 也就没往上拷（`attributesOf` 恒为 0）
  ///     → `IA_NEGATE_CRIT` / `IA_NEGATE_FLYING` 的判定永远为假
  ///
  /// 现在由提取器按位或求值（`IA_WEAPON | IA_UNSELLABLE | IA_LOCK_4` → 262161）。
  final int attributes;

  /// `IA_UNBREAKABLE`（`include/bmitem.h:58` `(1 << 3)`）
  bool get unbreakable => attributes & iaUnbreakable != 0;

  /// `IA_UNBREAKABLE = (1 << 3)`
  static const int iaUnbreakable = 1 << 3;

  /// `GetItemMinRange` —— `encodedRange >> 4`
  int get minRange => encodedRange >> 4;

  /// `GetItemMaxRange` —— `encodedRange & 0xF`
  int get maxRange => encodedRange & 0xF;
}

/// 一个单位参与战斗的**全部输入**。
///
/// 刻意做得扁平：它对应 `struct BattleUnit` 里被那些 `Compute*` 用到的字段，
/// **便于和源码逐条对照**。
class BattleUnitInput {
  const BattleUnitInput({
    required this.level,
    required this.cls,
    required this.chr,
    required this.item,
    required this.terrainDefense,
    required this.terrainAvoid,
    this.triangleDmgBonus = 0,
    this.hpBonus = 0,
  });

  final int level;
  final ClassStats cls;
  final CharStats chr;
  final ItemStats item;
  final int terrainDefense;
  final int terrainAvoid;

  /// `wTriangleDmgBonus`（武器三角的伤害加成）—— 已由 `weapon_triangle.json` 提供
  final int triangleDmgBonus;

  /// 角色的 hp 基础修正（本作暂未用到，留口子）
  final int hpBonus;

  /// `unit.def` —— **职业基础值**（本作角色不提供 def）
  int get def => cls.baseDef;

  /// `unit.spd`
  int get spd => cls.baseSpd;

  /// `unit.lck` —— **只有角色提供**
  int get lck => chr.baseLck;

  /// `UNIT_CON(unit)` —— `unit.conBonus`
  int get conBonus => cls.baseCon;

  int get maxHp => cls.baseHP + hpBonus;
}

/// `ComputeBattleUnitBaseDefense` —— `terrainDefense + unit.def`
int computeBattleUnitBaseDefense(BattleUnitInput u) =>
    u.terrainDefense + u.def;

/// `ComputeBattleUnitSpeed`
/// `effWt = GetItemWeight(weapon) - conBonus; clamp>=0; spd - effWt; clamp>=0`
int computeBattleUnitSpeed(BattleUnitInput u) {
  var effWt = u.item.weight - u.conBonus;
  if (effWt < 0) effWt = 0;
  final spd = u.spd - effWt;
  return spd < 0 ? 0 : spd;
}

/// `ComputeBattleUnitAvoidRate` —— `speed*2 + terrainAvoid + lck`，clamp >= 0
int computeBattleUnitAvoidRate(BattleUnitInput u) {
  final r = computeBattleUnitSpeed(u) * 2 + u.terrainAvoid + u.lck;
  return r < 0 ? 0 : r;
}

/// `ComputeBattleUnitDodgeRate` —— `unit.lck`
int computeBattleUnitDodgeRate(BattleUnitInput u) => u.lck;

/// `ComputeBattleUnitAttack`（不含特效武器那条分支）
/// `GetItemMight(weapon) + wTriangleDmgBonus`
int computeBattleUnitAttack(BattleUnitInput u) =>
    u.item.might + u.triangleDmgBonus;

/// 命中率 —— `battleHitRate` 由武器命中 + 技巧/幸运 决定。
///
/// 出处：`ComputeBattleUnitEffectiveHitRate` /
/// `GetBattleUnitHitRate`（`(skl*2 + lck/2)` 那一套）。
int computeBattleUnitHitRate(BattleUnitInput u) =>
    u.item.hit + u.cls.baseSkl * 2 + (u.lck ~/ 2);

/// `BattleGenerateHitAttributes` 里的一步：`damage = attack - defense`
int computeDamage(BattleUnitInput atk, BattleUnitInput def) =>
    math.max(0, computeBattleUnitAttack(atk) - computeBattleUnitBaseDefense(def));
