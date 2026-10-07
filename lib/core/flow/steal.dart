// PORT OF: src/StealCommandUsability.c:50-64（`StealCommandUsability`）
//          src/MakeTargetListForSteal.c（`MakeTargetListForSteal`：`ForEachAdjacentUnit`）
//          src/AddAsTarget_IfCanStealFrom.c（目标条件）
//          src/IsItemStealable.c（`IsItemStealable`：`GetItemType(item) == ITYPE_ITEM`）
//          include/bmitem.h:84-96（`ITYPE_*`）、`include/bmunit.h`（`CA_STEAL`）
//
// # 盗む（steal）
//
// ```c
// u8 StealCommandUsability(...) {
//     if (!(UNIT_CATTRIBUTES(gActiveUnit) & CA_STEAL)) return MENU_NOTSHOWN;
//     if (gActiveUnit->state & US_HAS_MOVED)            return MENU_NOTSHOWN;
//     MakeTargetListForSteal(gActiveUnit);
//     if (GetSelectTargetCount() == 0)                  return MENU_NOTSHOWN;
//     if (GetUnitItemCount(gActiveUnit) == UNIT_ITEM_COUNT) return MENU_DISABLED;  // 背包满
//     return MENU_ENABLED;
// }
// void AddAsTarget_IfCanStealFrom(struct Unit* unit) {
//     if (UNIT_FACTION(unit) != FACTION_RED) return;        // 只能偷**红方**
//     if (gActiveUnit->spd < unit->spd)      return;        // 速度不能低于对方
//     for (i = 0; i < UNIT_ITEM_COUNT; i++) {
//         u16 item = unit->items[i];
//         if (item == 0) return;                            // ★ 扫到**第一个空格就 return**
//         if (!IsItemStealable(item)) continue;             // 只偷 ITYPE_ITEM 那一类
//         AddTarget(...); return;
//     }
// }
// s8 IsItemStealable(int item) { return (GetItemType(item) == ITYPE_ITEM); }
// // `GetItemType(item)` 就是 `GetItemData(ITEM_INDEX(item))->weaponType`
// // ⇒ 我们 `items.json` 里的 `weaponType` 正是它（实测：伤药 9、铁剑 0、Mend 4）
// ```
//
// ⚠️ **效果函数没读到**（`gSelectInfo_Steal` 的处理不在反编译里）⇒ 下面的
//    [stealItemFrom] 是用**已移植的两个原语**组合出来的（`UnitRemoveItem` + `UnitAddItem`），
//    语义由"选中目标 → 选中一件道具"这条流程确定，但**不是照抄某个函数**（标注在此）。

import 'battle_field.dart';
import 'item_use.dart';

/// `UNIT_ITEM_COUNT`（每人的道具槽数）
const int kUnitItemCount = 5;

/// `ITYPE_ITEM`（`include/bmitem.h:93`）—— `IsItemStealable` 只认这一类
const int kItypeItem = 9;

/// `IsItemStealable`：`GetItemType(item) == ITYPE_ITEM`
bool isItemStealable({required int itemType, int itypeItem = kItypeItem}) =>
    itemType == itypeItem;

/// 目标身上**可偷的槽**（照 `AddAsTarget_IfCanStealFrom` 的循环：
/// **扫到第一个空格就停**，不是 continue）
List<int> stealableSlots(
  List<int> items, {
  required int Function(int item) itemTypeOf,
  int itypeItem = kItypeItem,
}) {
  final out = <int>[];
  for (var i = 0; i < items.length; i++) {
    final item = items[i];
    if (item == 0) break; // ★ 源码在这里 `return`
    if (!isItemStealable(itemType: itemTypeOf(item), itypeItem: itypeItem)) {
      continue;
    }
    out.add(i);
  }
  return out;
}

/// `AddAsTarget_IfCanStealFrom`：能不能偷这个人
bool canStealFrom({
  required bool targetIsRed,
  required int actorSpd,
  required int targetSpd,
  required List<int> targetItems,
  required int Function(int item) itemTypeOf,
}) {
  if (!targetIsRed) return false;
  if (actorSpd < targetSpd) return false;
  return stealableSlots(targetItems, itemTypeOf: itemTypeOf).isNotEmpty;
}

/// `MakeTargetListForSteal`：相邻（四邻居、不含自己）里能偷的人
List<MapUnit> stealTargets({
  required MapUnit actor,
  required List<MapUnit> units,
  required int Function(MapUnit u) spdOf,
  required bool Function(MapUnit u) isRed,
  required int Function(int item) itemTypeOf,
}) {
  final out = <MapUnit>[];
  for (final u in units) {
    if (u.id == actor.id || !u.isAlive || u.isHidden) continue;
    final d = (u.x - actor.x).abs() + (u.y - actor.y).abs();
    if (d != 1) continue;
    if (!canStealFrom(
      targetIsRed: isRed(u),
      actorSpd: spdOf(actor),
      targetSpd: spdOf(u),
      targetItems: u.items,
      itemTypeOf: itemTypeOf,
    )) {
      continue;
    }
    out.add(u);
  }
  return out;
}

/// 「盗む」这一项该不该出现（`StealCommandUsability`；`inventoryFull` ⇒ 禁用而不是隐藏）
bool stealAvailable({
  required bool hasStealAttribute,
  required bool hasActed,
  required bool hasTarget,
  required bool inventoryFull,
}) {
  if (!hasStealAttribute) return false;
  if (hasActed) return false;
  if (!hasTarget) return false;
  if (inventoryFull) return false; // 原作是 MENU_DISABLED（有提示），我们这里等同"不可用"
  return true;
}

/// **推导**的效果（见文件头）：把 `target.items[slot]` 取走并放进 `actor` 的空槽
///
/// 返回 `(ok, item)`；`ok == false` 表示发起者背包满或槽位无效（**道具不动**）。
({bool ok, int item}) stealItemFrom(MapUnit actor, MapUnit target, int slot) {
  if (slot < 0 || slot >= target.items.length) return (ok: false, item: 0);
  final word = target.items[slot];
  if (word == 0) return (ok: false, item: 0);
  final put = unitAddItem(actor.items, word);
  if (put < 0) return (ok: false, item: word); // 背包满 ⇒ 不偷（也不丢）
  final removed = unitRemoveItem(target.items, slot);
  for (var i = 0; i < target.items.length; i++) {
    target.items[i] = removed[i];
  }
  return (ok: true, item: word);
}
