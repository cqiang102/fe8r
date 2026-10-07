// PORT OF: src/GetUnitItemHealAmount.c:15-48（`GetItemIndex` / `GetItemAttributes` /
//            `GetUnitItemHealAmount`）
//          include/bmitem.h:148-149（`ITEM_INDEX(aItem) = aItem & 0xFF`、
//            `ITEM_USES(aItem) = aItem >> 8`）
//          include/bmitem.h:57（`IA_STAFF = (1 << 2)`）
//          include/bmitem.h:150+（`MakeNewItem`：`(uses << 8) + index`）
//
// # 用道具（回复类）的规则
//
// ```c
// int GetUnitItemHealAmount(struct Unit* unit, int item) {
//     int result = 0;
//     switch (GetItemIndex(item)) {
//     case ITEM_STAFF_HEAL: case ITEM_STAFF_PHYSIC: case ITEM_STAFF_FORTIFY:
//     case ITEM_VULNERARY:  case ITEM_VULNERARY_2:  result = 10; break;
//     case ITEM_STAFF_MEND:                          result = 20; break;
//     case ITEM_STAFF_RECOVER: case ITEM_ELIXIR:     result = 80; break;
//     }
//     if (GetItemAttributes(item) & IA_STAFF) {
//         result += GetUnitPower(unit);
//         if (result > 80) result = 80;
//     }
//     return result;
// }
// ```
//
// ⚠️ 上界 80 与 `+= 魔力` 两条**只对杖**生效（`IA_STAFF` 那一支），不在 switch 里。
// ⚠️ **未查证**：用道具的**可用性过滤**（满血时能不能用、杖要选目标等）——
//    原作在 `ItemSelectMenu_Usability`（`src/bmmenu_0802339C.c:64`）那一族里，
//    我没逐行核对；这里只做一条**保守**规则：回复量为 0 的道具不可用。

const int kItemIndexMask = 0xFF;
const int kItemStaffAttribute = 1 << 2; // IA_STAFF

/// `ITEM_INDEX(aItem)`（`include/bmitem.h:148`）
int itemIndex(int item) => item & kItemIndexMask;

/// `ITEM_USES(aItem)`（`include/bmitem.h:149`）—— **注意**：`0` 表示"不消耗"（`IA_UNBREAKABLE`）
int itemUses(int item) => item >> 8;

/// `GetUnitItemHealAmount`（`src/GetUnitItemHealAmount.c:24`）——按**道具编号**分支。
///
/// [itemNumber] 是 `ITEM_INDEX`（低 8 位）；调用方从道具表把编号查出来传进来，
/// 这样核心层不需要知道"伤药是 108"这种数据。
int unitItemHealAmount({
  required int itemNumber,
  required bool isStaff,
  int unitPower = 0,
  Map<int, String>? nameOf,
}) {
  final name = nameOf?[itemNumber];
  var result = 0;
  switch (name) {
    case 'ITEM_STAFF_HEAL':
    case 'ITEM_STAFF_PHYSIC':
    case 'ITEM_STAFF_FORTIFY':
    case 'ITEM_VULNERARY':
    case 'ITEM_VULNERARY_2':
      result = 10;
    case 'ITEM_STAFF_MEND':
      result = 20;
    case 'ITEM_STAFF_RECOVER':
    case 'ITEM_ELIXIR':
      result = 80;
  }
  if (isStaff) {
    result += unitPower;
    if (result > 80) result = 80;
  }
  return result;
}

/// 用一次回复道具的结果
class ItemUseResult {
  const ItemUseResult({
    required this.hp,
    required this.item,
    required this.consumed,
    required this.healed,
  });

  final int hp;

  /// 用完之后那个槽里的道具（`0` = 空了）
  final int item;

  /// 是不是**用完就没了**（耐久归零）
  final bool consumed;

  /// 实际回了多少血（受 `maxHp` 限制）
  final int healed;
}

/// 对一个单位使用回复道具。
///
/// 耐久规则照原作的打包表示：`ITEM_USES == 0` 表示**不消耗**（`IA_UNBREAKABLE`
/// 在 `MakeNewItem` 里就是写成 0 的，`include/bmitem.h:150+`）。
ItemUseResult useHealingItem({
  required int hp,
  required int maxHp,
  required int item,
  required int itemNumber,
  required bool isStaff,
  int unitPower = 0,
  Map<int, String>? nameOf,
}) {
  final amount = unitItemHealAmount(
      itemNumber: itemNumber, isStaff: isStaff, unitPower: unitPower, nameOf: nameOf);
  final newHp = (hp + amount) > maxHp ? maxHp : (hp + amount);
  final uses = itemUses(item);
  if (uses == 0) {
    // 不消耗：道具原样留在槽里
    return ItemUseResult(hp: newHp, item: item, consumed: false, healed: newHp - hp);
  }
  final left = uses - 1;
  if (left <= 0) {
    return ItemUseResult(hp: newHp, item: 0, consumed: true, healed: newHp - hp);
  }
  return ItemUseResult(
    hp: newHp,
    item: (left << 8) + (itemNumber & kItemIndexMask), // `MakeNewItem`
    consumed: false,
    healed: newHp - hp,
  );
}

// ---------------------------------------------------------------------------
// 装备（换武器）
// ---------------------------------------------------------------------------

/// `EquipUnitItemSlot`（`src/exact_08016968.c:14-23`）——**轮转**，不是交换：
///
/// ```c
/// item = unit->items[itemSlot];
/// for (i = itemSlot; i != 0; --i) unit->items[i] = unit->items[i - 1];
/// unit->items[0] = item;
/// ```
///
/// ⚠️ "交换"和"轮转"在 `itemSlot <= 1` 时**结果相同**，所以只有 2 把武器时
///    两种写法都对 —— 判据要用 **3 个及以上**才能分辨（`item_use_test` 就是这么写的）。
///
/// 为什么装备 = 挪到 0 号槽：原作**没有"当前武器"字段**，
/// `GetUnitEquippedWeapon`（`src/exact_080168d0.c:18-26`）就是"从 0 号槽起
/// 第一个能用的武器"。
List<int> equipUnitItemSlot(List<int> items, int slot) {
  if (slot <= 0 || slot >= items.length) return List<int>.from(items);
  final out = List<int>.from(items);
  final item = out[slot];
  for (var i = slot; i != 0; --i) {
    out[i] = out[i - 1];
  }
  out[0] = item;
  return out;
}

/// `GetUnitEquippedWeapon`（`src/exact_080168d0.c:18-26`）——
/// **从 0 号槽起第一个"能用"的武器**（不是单独的字段）。
///
/// [isUsableWeapon] 由调用方给（要看道具表属性 + 武器等级），核心层不持有道具表。
int equippedWeaponSlot(
  List<int> items, {
  required bool Function(int item) isUsableWeapon,
}) {
  for (var i = 0; i < items.length; i++) {
    if (isUsableWeapon(items[i])) return i;
  }
  return -1;
}
