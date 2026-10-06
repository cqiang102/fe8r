// PORT OF: include/bmbattle.h, include/bmunit.h, include/bmitem.h
//
// 战斗单位与道具的数据模型。
//
// **只建模 Oracle 覆盖到的那部分字段**，不一次性把整个 struct 搬过来——
// 未使用的字段照搬只会增加出错面，等真正用到时再补。
//
// 数值宽度严格跟随 C：
//   battleSpeed / battleCritRate 等 = `short`（16 位有符号）
//   terrainAvoid / unit.def / unit.lck = `s8`（8 位有符号）
//   weapon / items[] = `u16`
//
// ⚠️ 宽度不是洁癖。`battleEffectiveCritRate = battleCritRate - battleDodgeRate`
// 在 C 里是 int 运算后再赋给 short；`ComputeBattleUnitAvoidRate` 里的
// `speed*2 + terrainAvoid + lck` 也一样。只要不溢出，用 Dart 的 int 算结果相同，
// 但**输入必须按 C 的宽度截断**，否则越界的测试值会算出 C 不可能产生的结果。

/// `UNIT_ITEM_COUNT`
const int unitItemCount = 5;

/// `ITEM_MONSTER_STONE`
const int itemMonsterStone = 0xB5;

/// `IsUnitEffectiveAgainst` 里写死 `case 0x2B: case 0x2C:` 的两个职业。
///
/// ⚠️ 它们是 **CLASS_BISHOP / CLASS_BISHOP_F**（主教的"斩魔"特性），
/// 不是名字看着像魔物的那些。反编译源码里用的是裸十六进制，
/// 按字面猜名字会猜错——我第一版就猜成了石像鬼蛋。
const int classBishop = 0x2B;
const int classBishopF = 0x2C;


/// `IA_NEGATE_CRIT`：免疫必杀的道具属性位（见 include/bmitem.h）
const int iaNegateCrit = 1 << 15;

/// `IA_BRAVE`：勇者武器，一次攻击打两下
const int iaBrave = 1 << 5;

/// `CA_*` 职业属性位 —— **全部取自 include/bmunit.h**。
///
/// 这些位号很反直觉（ASSASSIN 在 25 位而不是 20 位），
/// 凭印象写必然出错：我第一版把 CA_ASSASSIN 写成 1 << 20，
/// 那是 CA_UNSELECTABLE，于是"刺客瞬杀率"这条分支零覆盖。
const int caBoss = 1 << 15;
const int caUnselectable = 1 << 20;
const int caNegateLethality = 1 << 24;
const int caAssassin = 1 << 25;

/// `IA_NEGATE_FLYING`：免疫"特效对飞行"
const int iaNegateFlying = 1 << 14;

/// 把值按 C 的 `s8` 截断
int asS8(int v) {
  final x = v & 0xFF;
  return x >= 128 ? x - 256 : x;
}

/// 把值按 C 的 `u16` 截断
int asU16(int v) => v & 0xFFFF;

/// 把值按 C 的 `short` 截断
int asS16(int v) {
  final x = v & 0xFFFF;
  return x >= 32768 ? x - 65536 : x;
}

/// 单位（`struct Unit` 的子集）
class BattleUnitSide {
  BattleUnitSide({
    int def = 0,
    int lck = 0,
    int spd = 0,
    int conBonus = 0,
    int pow = 0,
    int skl = 0,
    this.classId,
    this.classAttributes = 0,
    this.level = 1,
    int res = 0,
    List<int>? items,
  })  : _pow = asS8(pow),
        _skl = asS8(skl),
        def = asS8(def),
        lck = asS8(lck),
        spd = asS8(spd),
        conBonus = asS8(conBonus),
        items = List<int>.generate(
          unitItemCount,
          (i) => asU16(i < (items?.length ?? 0) ? items![i] : 0),
        );

  final int def;
  final int lck;
  final int spd;

  /// 体格加成（`conBonus`）。`ComputeBattleUnitSpeed` 用它算有效重量。
  final int conBonus;

  /// 携带道具，`u16`
  final List<int> items;

  int _res = 0;

  /// `pClassData->number`；null 表示没有职业数据（C 里的 NULL 指针）
  int? classId;

  /// `UNIT_CATTRIBUTES(unit)` = 角色属性 | 职业属性
  final int classAttributes;

  /// 单位等级。`SureShot` / `GreatShield` / `Pierce` 用它当判定阈值
  /// （`src/bmbattle_0802B164.c:54/80/111`）。
  final int level;

  /// 魔防（`unit.res`），`s8`。魔法武器攻击时用它代替 `def`
  /// （`src/bmbattle_0802A914.c:51-59`）。
  int get res => _res;
  set res(int v) => _res = asS8(v);

  /// 力量（`pow`），`s8`
  int get pow => _pow;
  set pow(int v) => _pow = asS8(v);
  int _pow = 0;

  /// 技巧（`skl`），`s8` —— 命中率的输入
  int get skl => _skl;
  set skl(int v) => _skl = asS8(v);
  int _skl = 0;
}

/// 战斗单位（`struct BattleUnit` 的子集）。
///
/// ⚠️ **所有数值字段都按 C 的宽度截断**（`short` / `s8`）。
///
/// 这不是洁癖，是实测踩出来的：C Oracle 有一条用例
/// `critRate=32767, dodgeRate=-32768`，C 里
/// `battleEffectiveCritRate` 是 `short`，相减得 65535 再存回 short **回绕成 -1**，
/// 于是命中"负数钳位到 0"分支，结果是 **0**。
/// Dart 的 int 不会回绕，直接算出 65535——两边就不一致了。
///
/// 用 private 字段 + 截断 setter，而不是在每处赋值时手工 `asS16(...)`，
/// 是因为后者迟早会漏；宽度语义放在类型里才守得住。
class BattleUnit {
  BattleUnit({BattleUnitSide? unit}) : unit = unit ?? BattleUnitSide();

  BattleUnitSide unit;

  /// 当前武器（`u16`）
  int weapon = 0;

  /// 计算速度时用的"之前的武器"——原版用 `weaponBefore` 而不是 `weapon`，
  /// 这是为了处理"武器被打破后仍然用旧重量算速度"的行为
  int weaponBefore = 0;

  int _battleAttack = 0;
  int _battleDefense = 0;
  int _battleSpeed = 0;
  int _battleHitRate = 0;
  int _battleAvoidRate = 0;
  int _battleCritRate = 0;
  int _battleDodgeRate = 0;
  int _battleEffectiveCritRate = 0;
  int _battleEffectiveHitRate = 0;
  int _battleSilencerRate = 0;
  int _terrainAvoid = 0;
  int _terrainDefense = 0;
  int _terrainResistance = 0;

  /// `short` 字段：赋值即按 16 位截断
  int get battleAttack => _battleAttack;
  set battleAttack(int v) => _battleAttack = asS16(v);

  int get battleDefense => _battleDefense;
  set battleDefense(int v) => _battleDefense = asS16(v);

  int get battleSpeed => _battleSpeed;
  set battleSpeed(int v) => _battleSpeed = asS16(v);

  int get battleHitRate => _battleHitRate;
  set battleHitRate(int v) => _battleHitRate = asS16(v);

  int get battleAvoidRate => _battleAvoidRate;
  set battleAvoidRate(int v) => _battleAvoidRate = asS16(v);

  int get battleCritRate => _battleCritRate;
  set battleCritRate(int v) => _battleCritRate = asS16(v);

  int get battleDodgeRate => _battleDodgeRate;
  set battleDodgeRate(int v) => _battleDodgeRate = asS16(v);

  int get battleEffectiveCritRate => _battleEffectiveCritRate;
  set battleEffectiveCritRate(int v) => _battleEffectiveCritRate = asS16(v);

  int get battleEffectiveHitRate => _battleEffectiveHitRate;
  set battleEffectiveHitRate(int v) => _battleEffectiveHitRate = asS16(v);

  int get battleSilencerRate => _battleSilencerRate;
  set battleSilencerRate(int v) => _battleSilencerRate = asS16(v);

  /// 武器类型（`ITYPE_*`）
  int weaponType = 0;

  /// 武器属性位（`IA_*`）
  int weaponAttributes = 0;

  /// `GetItemWeaponEffect(weaponBefore)` —— 追击判定要用
  int followUpWeaponEffect = 0;

  int _triHit = 0;
  int _triDmg = 0;

  /// `s8`：武器三角命中加成
  int get wTriangleHitBonus => _triHit;
  set wTriangleHitBonus(int v) => _triHit = asS8(v);

  /// `s8`：武器三角伤害加成（叠加到攻击力上）
  int get wTriangleDmgBonus => _triDmg;
  set wTriangleDmgBonus(int v) => _triDmg = asS8(v);

  /// `s8` 字段
  int get terrainAvoid => _terrainAvoid;
  set terrainAvoid(int v) => _terrainAvoid = asS8(v);

  /// 地形魔防（`terrainResistance`）
  int get terrainResistance => _terrainResistance;
  set terrainResistance(int v) => _terrainResistance = asS8(v);

  int get terrainDefense => _terrainDefense;
  set terrainDefense(int v) => _terrainDefense = asS8(v);

  void setTerrain({int avoid = 0, int defense = 0}) {
    _terrainAvoid = asS8(avoid);
    _terrainDefense = asS8(defense);
  }
}

// ---------------------------------------------------------------- 道具表

/// `struct ItemStatBonuses` 的子集
/// `struct ItemStatBonuses`（`include/bmitem.h:6-15`）—— **每个字段都是 `s8`**。
///
/// ```c
/// struct ItemStatBonuses {
///     /* 00 */ s8 hpBonus;
///     /* 01 */ s8 powBonus;
///     /* 02 */ s8 sklBonus;
///     /* 03 */ s8 spdBonus;
///     /* 04 */ s8 defBonus;
///     /* 05 */ s8 resBonus;
///     /* 06 */ s8 lckBonus;
///     ...
/// };
/// ```
///
/// ⚠️ 我原来 `defBonus` 是普通 int、无截断。目前 `lib/` 里**没有任何地方
/// 构造** `ItemStatBonuses`（这条路还没接通），所以暂时没有实际影响 ——
/// 但一旦加载器把 ROM 里的 `0xFF`（= s8 的 -1）原样写进来，
/// `def + 255` 会差 **256**。
///
/// 现在按 `s8` 存 —— 与 `BattleUnitSide` 的 `asS8` 一致。
class ItemStatBonuses {
  ItemStatBonuses({
    int hpBonus = 0,
    int powBonus = 0,
    int sklBonus = 0,
    int spdBonus = 0,
    int defBonus = 0,
    int resBonus = 0,
    int lckBonus = 0,
  })  : hpBonus = asS8(hpBonus),
        powBonus = asS8(powBonus),
        sklBonus = asS8(sklBonus),
        spdBonus = asS8(spdBonus),
        defBonus = asS8(defBonus),
        resBonus = asS8(resBonus),
        lckBonus = asS8(lckBonus);

  final int hpBonus;
  final int powBonus;
  final int sklBonus;
  final int spdBonus;
  final int defBonus;
  final int resBonus;
  final int lckBonus;
}

/// `struct ItemData` 的子集
class ItemData {
  ItemData({
    this.attributes = 0,
    this.might = 0,
    this.weight = 0,
    this.hit = 0,
    this.crit = 0,
    this.statBonuses,
    this.effectiveness,
    this.effectivenessIsFlier = false,
  });

  /// 特效列表（`pEffectiveness`）：一串职业编号，0 是终止符。
  /// null 表示这件武器没有特效。
  List<int>? effectiveness;

  /// 这个特效列表**是不是** `ItemEffectiveness_Flier` 或
  /// `ItemEffectiveness_FlierAndMonsters`。
  ///
  /// C 里是拿**列表指针的身份**比对的：
  ///     if (GetItemEffectiveness(item) != ItemEffectiveness_Flier) ...
  /// 也就是说"是否走飞行抵消"取决于列表是不是那两个全局表之一，
  /// **不能靠内容里有没有飞行职业来推断**——`FlierAndMonsters` 里也有魔物职业。
  /// 所以这里把身份显式记成一个标记，由数据加载方设置。
  bool effectivenessIsFlier;

  /// 道具属性位（`IA_*`）
  int attributes;

  /// 威力
  int might;

  /// 重量
  int weight;

  /// 命中（`GetItemHit`）
  int hit;

  /// 必杀（`GetItemCrit`）
  int crit;

  /// 武器特殊效果（`GetItemWeaponEffect`）
  int weaponEffectId = 0;

  /// 编码射程（`encodedRange`）：**高 4 位是最小射程，低 4 位是最大射程**。
  ///
  /// 所以 1 格武器是 `0x11`、2 格是 `0x22`、1-2 格是 `0x12`。
  /// 不要写成"一个字节表示射程"。
  int encodedRange = 0;

  /// 属性加成表；null 表示没有
  ItemStatBonuses? statBonuses;
}

/// 道具表。对应 C 的全局 `gItemData`。
class ItemTable {
  ItemTable(int size)
      : _items = List<ItemData>.generate(size, (_) => ItemData());

  final List<ItemData> _items;

  int get length => _items.length;

  ItemData operator [](int index) {
    if (index < 0 || index >= _items.length) return ItemData();
    return _items[index];
  }

  /// 对应 C 的 `ITEM_INDEX(item)`：低 8 位是道具编号
  static int itemIndex(int item) => item & 0xFF;

  /// `GetItemData(item)`
  ItemData dataOf(int item) => this[itemIndex(item)];

  /// `GetItemAttributes(item)`
  int attributesOf(int item) => dataOf(item).attributes;

  /// `GetItemMight(item)`
  int mightOf(int item) => dataOf(item).might;

  /// `GetItemWeight(item)`
  int weightOf(int item) => dataOf(item).weight;

  /// `GetItemHit(item)`
  int hitOf(int item) => dataOf(item).hit;

  /// `GetItemCrit(item)`
  int critOf(int item) => dataOf(item).crit;

  /// `GetItemWeaponEffect(item)` —— 武器的特殊效果编号
  int weaponEffectOf(int item) => dataOf(item).weaponEffectId;

  /// `GetItemEncodedRange(item)`
  int encodedRangeOf(int item) => dataOf(item).encodedRange;

  /// `GetItemMinRange(item)` —— 编码射程的**高 4 位**
  int minRangeOf(int item) => encodedRangeOf(item) >> 4;

  /// `GetItemMaxRange(item)` —— 编码射程的**低 4 位**
  int maxRangeOf(int item) => encodedRangeOf(item) & 0xF;

  /// `GetItemStatBonuses(item)`
  ItemStatBonuses? statBonusesOf(int item) => dataOf(item).statBonuses;

  /// `GetItemEffectiveness(item)` —— 特效列表
  List<int>? effectivenessOf(int item) => dataOf(item).effectiveness;

  /// `GetItemDefBonus(item)`
  ///
  /// 空道具返回 0；没有加成表也返回 0。
  int defBonusOf(int item) {
    if (item == 0) return 0;
    final b = statBonusesOf(item);
    return b?.defBonus ?? 0;
  }
}
