// PORT OF: src/bmtarget_0802506C.c:81-114（`TryAddUnitToTradeTargetList` —— 交换对象的条件）
//          src/bmtarget_0802506C.c:118-138（`MakeTradeTargetList`）
//          src/bmtrade_0802D520.c:124-135（`TradeMenu_ApplyItemSwap` —— **两格对调**，
//            然后对**双方各自**调 `UnitRemoveInvalidItems`）
//          src/bmmenu_08022F50.c:50-66（`TradeCommandEffect` / `TradeSelection_OnSelect`）
//          include/bmunit.h:275（`UNIT_STATUS_BERSERK = 4`）
//
// # 交换的语义（照抄）
//
// ```c
// u8 TradeCommandEffect(...) { MakeTradeTargetList(gActiveUnit); NewTargetSelection(&gSelectInfo_Trade); }
// u8 TradeSelection_OnSelect(...) { StartTradeMenu(gActiveUnit, GetUnit(target->uid), 0); }
//
// void TradeMenu_ApplyItemSwap(struct TradeMenuProc* proc) {
//     u16* pItemA = &proc->units[proc->hoverColumn]->items[proc->hoverRow];
//     u16* pItemB = &proc->units[proc->selectedColumn]->items[proc->selectedRow];
//     u16 swp = *pItemA; *pItemA = *pItemB; *pItemB = swp;
//     proc->hasTraded = TRUE;
//     UnitRemoveInvalidItems(proc->units[0]);
//     UnitRemoveInvalidItems(proc->units[1]);
// }
// ```
//
// ⚠️ 注意"对调 + **两边都压缩**"合起来的效果：**拿一件道具和对方的空格交换 = 把道具挪过去**
// （压缩会把洞填上）。这不是巧合，是原作交易界面的基础操作。
//
// ⚠️ **未移植**（数据/模型没有，不编）：
//   * `CA_SUPPLY`（输送队属性）—— 我们的职业表没抽 `attributes` ⇒ 调用方传 `false`；
//   * `US_RESCUING`（救出中：可以把道具给"被救的人"）—— 我们还没做救出系统；
//   * `UNIT_STATUS_BERSERK` 的状态位在核心层是可传的，但我们还没做状态系统。

import 'item_use.dart';

/// 交换对象的条件（`TryAddUnitToTradeTargetList`，逐条照抄）
///
/// `subject*` 是发起方，`unit*` 是候选方。
bool isTradeTarget({
  required bool sameAllegiance,
  required bool subjectIsPhantom,
  required bool unitIsPhantom,
  required int unitStatus,
  required int subjectItem0,
  required int unitItem0,
  bool unitHasSupply = false,
}) {
  if (!sameAllegiance) return false;
  if (subjectIsPhantom || unitIsPhantom) return false;
  if (unitStatus == kUnitStatusBerserk) return false;
  // `if (gSubjectUnit->items[0] != 0 || unit->items[0] != 0)`
  if (subjectItem0 == 0 && unitItem0 == 0) return false;
  if (unitHasSupply) return false;
  return true;
}

/// `UNIT_STATUS_BERSERK`（`include/bmunit.h:275`）
const int kUnitStatusBerserk = 4;

/// 一次交换的结果（两边的背包都换过了，且各自**压缩**过）
class ItemSwapResult {
  const ItemSwapResult(this.a, this.b);

  /// 发起方的新背包
  final List<int> a;

  /// 对方的新背包
  final List<int> b;
}

/// `TradeMenu_ApplyItemSwap`：把 `a[slotA]` 与 `b[slotB]` **对调**，
/// 然后**双方各自** `UnitRemoveInvalidItems`（`src/exact_0801772c.c:40-62`）。
ItemSwapResult applyItemSwap(
  List<int> a,
  int slotA,
  List<int> b,
  int slotB,
) {
  // ⚠️ 原作是**两个指针** `pItemA` / `pItemB`，两者**可以指向同一份背包**
  //（`hoverColumn == selectedColumn` ⇒ 自己和自己交换 = **原地对调**，是"整理背包"）。
  // 我第一版无脑复制成两份，于是同一个背包会得到 `[13,12,13]` 这种结果 ✗
  // —— 测试当场抓到（`[13,12,11]` 才对）。
  final sameInventory = identical(a, b);
  final a2 = List<int>.from(a);
  final b2 = sameInventory ? a2 : List<int>.from(b);
  if (slotA >= 0 && slotA < a2.length && slotB >= 0 && slotB < b2.length) {
    final swp = a2[slotA];
    a2[slotA] = b2[slotB];
    b2[slotB] = swp;
  }
  final ra = unitRemoveInvalidItems(a2);
  final rb = sameInventory ? ra : unitRemoveInvalidItems(b2);
  return ItemSwapResult(ra, rb);
}
