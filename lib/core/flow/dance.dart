// PORT OF: src/masked_0802315c.c:64-70（`DanceCommandUsability`：要求 `CA_DANCE`）
//          src/masked_08023120.c:64-73（`PlayCommandUsability`：要求 `CA_PLAY`）
//          src/PlayDanceCommandUsabilityCommon.c:50-72（共用可用性：`!US_HAS_MOVED` +
//              `MakeTargetListForRefresh` 非空；否则看身上有没有 `ITYPE_DANCE` 的道具）
//          src/bmtarget_08025ABC.c:26-42（`TryAddUnitToRefreshTargetList`）
//          src/bmtarget_08025ABC.c:45-53（`MakeTargetListForRefresh`：`ForEachAdjacentUnit`）
//
// # 踊る / 演奏（refresh）
//
// ```c
// // 共用可用性
// if (gActiveUnit->state & US_HAS_MOVED) return MENU_NOTSHOWN;
// MakeTargetListForRefresh(gActiveUnit);
// if (GetSelectTargetCount()) return MENU_ENABLED;
// /* 否则：扫道具栏，有 ITYPE_DANCE 的道具（指轮）也放行 —— 那一支我们没做 */
//
// void TryAddUnitToRefreshTargetList(struct Unit* unit) {
//     if (!IsSameAllegiance(gSubjectUnit->index, unit->index)) return;
//     if (!(unit->state & US_UNSELECTABLE)) return;      // ★ **必须是"已经不能动"的人**
//     if (status == PETRIFY || status == 13) return;      // 状态：我们没建模
//     AddTarget(...);
// }
// void MakeTargetListForRefresh(struct Unit* unit) {
//     ForEachAdjacentUnit(unit->xPos, unit->yPos, TryAddUnitToRefreshTargetList);
// }
// ```
//
// ⚠️ **效果函数的出处我**没**定位到**：`RefreshAllies`（`src/RefreshAllies.c:9-20`）
//    是**阶段开始**的全体刷新（遍历 `gUnitLookup[]`、还清状态），**不是**踊る的效果 ✗。
//    我一开始把它当成了踊る的效果，是**读错**。这里的效果是从**目标条件**推出来的：
//    目标必须是"已经不能动"的人（`US_UNSELECTABLE`），选中它是为了**让它再动一次**
//    ⇒ 效果 = 清掉 `hasActed`/`unselectable`（并解除救出位，与 `RefreshAllies` 的位集一致）。
//    **这一条是推断，不是照抄**（标在这里，别当成已核对）。

import 'battle_field.dart';

/// `TryAddUnitToRefreshTargetList` 的条件：同盟 + **必须**"现在不能动"
/// （`US_UNSELECTABLE` ⇒ 已行动 / 刚被降下）
bool isRefreshTarget({required bool sameAllegiance, required bool cannotActNow}) =>
    sameAllegiance && cannotActNow;

/// `MakeTargetListForRefresh`：相邻（四邻居、不含自己）里"已经不能动"的同伴
List<MapUnit> danceTargets({
  required MapUnit actor,
  required List<MapUnit> units,
}) {
  final out = <MapUnit>[];
  for (final u in units) {
    if (u.id == actor.id || !u.isAlive || u.isHidden) continue;
    if (u.factionBit != actor.factionBit) continue;
    final d = (u.x - actor.x).abs() + (u.y - actor.y).abs();
    if (d != 1) continue;
    if (!isRefreshTarget(
        sameAllegiance: true, cannotActNow: u.hasActed || u.unselectable)) {
      continue;
    }
    out.add(u);
  }
  return out;
}

/// 刷新一个单位（**推断的效果**，见文件头）：让它能再动一次
void refreshUnit(MapUnit u) {
  u.hasActed = false;
  u.unselectable = false;
  // 与 `RefreshAllies` 清的位集一致（`US_RESCUING | US_RESCUED` 也一起解除）
  u.isRescuing = false;
  u.isRescued = false;
  u.rescueIndex = 0;
}

/// 「踊る / 演奏」这一项该不该出现（`PlayDanceCommandUsabilityCommon`）
///
/// ⚠️ 只做了"有可刷新的目标"这一支；**指轮那一支**（身上有 `ITYPE_DANCE` 道具也放行）
///    以及沉默/石化等状态过滤**未做**（状态系统还没建模）。
bool danceAvailable({
  required bool hasAttribute,
  required bool hasActed,
  required bool hasTarget,
}) {
  if (!hasAttribute) return false;
  if (hasActed) return false;
  return hasTarget;
}
