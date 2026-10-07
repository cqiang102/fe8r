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
