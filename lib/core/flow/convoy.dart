// PORT OF: src/bmcontainer.c:54-70（`AddItemToConvoy`）
//          src/bmcontainer.c:72-77（`RemoveItemFromConvoy`：置 0 后 `ShrinkConvoyItemList()`）
//          include/bmcontainer.h:7（`CONVOY_ITEM_COUNT = 100`）
//          src/SendToConvoyMenu_NormalEffect.c:24-27（送到输送队 + 换入）
//          src/SupplyUsability.c:51-80（谁能用输送：`HasConvoyAccess` + 非幻影 + **领袖**）
//
// # 输送队（convoy）
//
// ```c
// int AddItemToConvoy(int item) {
//     gBmSt.itemUnk2E = 0;
//     for (i = 0; i < CONVOY_ITEM_COUNT; ++i)
//         if (gConvoyItemArray[i] == 0) { gConvoyItemArray[i] = item; return i; }
//     gBmSt.itemUnk2E = item;      // 满了：道具留在暂存格，返回 -1
//     return -1;
// }
// void RemoveItemFromConvoy(int index) {
//     gConvoyItemArray[index] = 0;
//     ShrinkConvoyItemList();      // ⇒ **压缩**（和背包 `UnitRemoveInvalidItems` 同一套）
// }
// ```
//
// ⚠️ 满的时候原作**不是丢弃**，而是把道具放到 `gBmSt.itemUnk2E`（暂存格）再返回 -1，
// 由调用方决定怎么办 ⇒ 我们的 [addItemToConvoy] 也**不丢**，返回 -1 表示"没进去"，
// 调用方持有道具。判据里专门钉"满了以后数组**没变**"。

import 'tile_events.dart'; // kCharacterEirika / kCharacterEphraim（`include/constants/characters.h`）

/// `CONVOY_ITEM_COUNT = 100`（`include/bmcontainer.h:7`）
const int convoyItemCount = 100;

/// `AddItemToConvoy`：放进**第一个空槽**，返回下标；满 ⇒ 返回 -1（**不丢道具**）。
int addItemToConvoy(List<int> convoy, int item) {
  for (var i = 0; i < convoy.length; i++) {
    if (convoy[i] == 0) {
      convoy[i] = item;
      return i;
    }
  }
  return -1; // 原文把 item 存进 `gBmSt.itemUnk2E`，调用方自己留住它
}

/// `RemoveItemFromConvoy`：置 0 后**压缩**（`ShrinkConvoyItemList`）
void removeItemFromConvoy(List<int> convoy, int index) {
  if (index < 0 || index >= convoy.length) return;
  convoy[index] = 0;
  final kept = [for (final w in convoy) if (w != 0) w];
  for (var i = 0; i < convoy.length; i++) {
    convoy[i] = i < kept.length ? kept[i] : 0;
  }
}

/// `GetConvoyItemCount` —— 数**非零**（压缩不变式下与"扫到第一个 0"等价）
int convoyCount(List<int> convoy) => convoy.where((w) => w != 0).length;

/// `SupplyUsability` 的领袖判定（`src/SupplyUsability.c:63-80`）
///
/// ```c
/// switch (gPlaySt.chapterModeIndex) {
///     case CHAPTER_MODE_EIRIKA:  pid = CHARACTER_EIRIKA;  break;
///     case CHAPTER_MODE_EPHRAIM: pid = CHARACTER_EPHRAIM; break;
///     default:                   pid = CHARACTER_EIRIKA;  break;
/// }
/// ```
int convoyLeaderId({required int chapterModeIndex}) =>
    chapterModeIndex == 2 ? kCharacterEphraim : kCharacterEirika;

/// 「輸送」这一项该不该出现（`SupplyUsability`）
///
/// ⚠️ `HasConvoyAccess()` 的**实现没读到**（`src/` 里只有调用点）
/// ⇒ 由调用方作为参数给（**不猜**）。
bool supplyAvailable({
  required bool hasConvoyAccess,
  required bool isPhantom,
  required bool isLeader,
}) {
  if (!hasConvoyAccess) return false;
  if (isPhantom) return false;
  return isLeader;
}
