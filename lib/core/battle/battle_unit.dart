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

/// `IA_NEGATE_CRIT`：免疫必杀的道具属性位
const int iaNegateCrit = 0x80;

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
    List<int>? items,
  })  : def = asS8(def),
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
  int _terrainAvoid = 0;
  int _terrainDefense = 0;

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

  /// `s8` 字段
  int get terrainAvoid => _terrainAvoid;
  set terrainAvoid(int v) => _terrainAvoid = asS8(v);

  int get terrainDefense => _terrainDefense;
  set terrainDefense(int v) => _terrainDefense = asS8(v);

  void setTerrain({int avoid = 0, int defense = 0}) {
    _terrainAvoid = asS8(avoid);
    _terrainDefense = asS8(defense);
  }
}

// ---------------------------------------------------------------- 道具表

/// `struct ItemStatBonuses` 的子集
class ItemStatBonuses {
  ItemStatBonuses({this.defBonus = 0});
  final int defBonus;
}

/// `struct ItemData` 的子集
class ItemData {
  ItemData({
    this.attributes = 0,
    this.might = 0,
    this.weight = 0,
    this.statBonuses,
  });

  /// 道具属性位（`IA_*`）
  int attributes;

  /// 威力
  int might;

  /// 重量
  int weight;

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

  /// `GetItemStatBonuses(item)`
  ItemStatBonuses? statBonusesOf(int item) => dataOf(item).statBonuses;

  /// `GetItemDefBonus(item)`
  ///
  /// 空道具返回 0；没有加成表也返回 0。
  int defBonusOf(int item) {
    if (item == 0) return 0;
    final b = statBonusesOf(item);
    return b?.defBonus ?? 0;
  }
}
