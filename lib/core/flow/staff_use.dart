// PORT OF: src/DoUseHealStaff.c:33-46（`DoUseHealStaff` —— **先 `func(unit)`，再开目标选择**：
//            `StartSubtitleHelp(NewTargetSelection(&gSelectInfo_Heal), "Select a character
//             to restore HP to.")`）
//          src/GetUnitItemHealAmount.c:24+（治疗量；已在 `item_use.dart` 里移植）
//          src/bmtarget_0802506C.c:462-470（**同类判据**：`MakeTerrainHealTargetList` 用
//            `GetUnitCurrentHp(unit) != GetUnitMaxHp(unit)` 与状态过滤）
//
// # 杖的目标选择
//
// 原作流程（`DoUseHealStaff`，已核）：
//   1. 先执行 `func(unit)`（扣使用次数等）；
//   2. 再 `NewTargetSelection(&gSelectInfo_Heal)` —— 让玩家**选一个角色回复 HP**。
//
// ⚠️ **未查证**：`gSelectInfo_Heal` 的**定义不在反编译里**（`src/` 里只有引用，
// `DoUseHealStaff.c:44`），所以那张目标列表的**精确判据我读不到**。
// 下面用的是**同源码里同类函数**的判据（`MakeTerrainHealTargetList`：
// 同阵营、没死/没被救走/没隐藏、HP 不是满的）＋ 武器射程过滤，
// 这是**类比**，不是同一函数 —— 判据里把这一条写明了，别当成已核对。

import 'battle_field.dart';

/// 一个可被治疗的目标
class StaffTarget {
  const StaffTarget({
    required this.unitId,
    required this.x,
    required this.y,
    required this.healAmount,
  });

  final int unitId;
  final int x;
  final int y;

  /// 这一击会回复多少（已经过 `unitItemHealAmount`，含 80 上限）
  final int healAmount;

  Map<String, Object?> toJson() =>
      {'unitId': unitId, 'x': x, 'y': y, 'healAmount': healAmount};
}

/// `GetUnitMagBy2Range`（`src/GetUnitMagBy2Range.c:12-26`）：
/// `GetUnitPower(unit) / 2`，**最小 5**（`CHARACTER_FOMORTIIS` 用噩梦道具的射程，另论）。
///
/// ⚠️ 远程杖（Physic/Fortify）的射程**看的是这个**，**不是道具射程** ——
/// 我第 56 轮用的是道具的 `minRange/maxRange`，那是错的（好在当时只是"类比"口径）。
int magBy2Range(int unitPower) {
  final r = unitPower ~/ 2;
  return r < 5 ? 5 : r;
}

/// 杖的目标列表。
///
/// 条件照 `TryAddUnitToHealTargetList`（`src/bmtarget_08025BD8.c:127-141`，**逐条**）：
///   1. `AreUnitsAllied` ⇒ **同盟**；
///   2. `unit->state & US_RESCUED` ⇒ **被救走的不能治**；
///   3. `GetUnitCurrentHp(unit) == GetUnitMaxHp(unit)` ⇒ **满血不治**。
///
/// 射程照两个不同的函数：
///   * **相邻型** `MakeTargetListForAdjacentHeal`（`:152-160`）用 `ForEachAdjacentUnit`，
///     即 `InitTargets(x,y)` + `MapAddInRange(x,y,1,1)` + **`MapAddInRange(x,y,0,-1)`**
///     —— 最后那句把**中心格抹掉**（`MapAddInRange` 的 `value` 是写进射程图的值，
///     `-1` 即取消）⇒ **施术者自己不会被治**（我第 56 轮的排除是对的，这里补上出处）；
///   * **远程型** `MakeTargetListForRangedHeal`（`:165+`）用
///     `MapAddInRange(x, y, GetUnitMagBy2Range(unit), 1)` ⇒ 半价魔力的**菱形**。
///
/// ⚠️ **仍然未查证**：`gSelectInfo_Heal` 的**定义不在反编译里** ⇒
/// "哪一类杖走相邻型、哪一类走远程型"的**分派**我读不到；这里按道具
/// `maxRange > 1` 分（Heal/Mend/Recover 相邻、Physic/Fortify 远程）。
List<StaffTarget> staffTargets({
  required MapUnit user,
  required List<MapUnit> units,
  required int healAmount,
  required bool ranged,
  int unitPower = 0,
  bool Function(MapUnit u)? isSameFaction,
}) {
  final same = isSameFaction ?? (MapUnit u) => u.factionBit == user.factionBit;
  final radius = ranged ? magBy2Range(unitPower) : 1;
  final out = <StaffTarget>[];
  for (final u in units) {
    if (!u.isAlive) continue;
    if (!same(u)) continue;
    if (u.isRescued) continue; // 2
    if (u.hp >= u.maxHp) continue; // 3
    final d = (u.x - user.x).abs() + (u.y - user.y).abs();
    if (d < 1) continue; // 施术者自己不在列表里（中心格被 `-1` 抹掉）
    if (d > radius) continue;
    out.add(StaffTarget(
        unitId: u.id, x: u.x, y: u.y, healAmount: healAmount));
  }
  return out;
}

/// 应用治疗：**不超过上限**（`ExecHealStaff` 那一族的共同点）。
///
/// 返回实际回复量（可能小于 [amount]）。
int applyStaffHeal(MapUnit target, int amount) {
  final before = target.hp;
  target.hp = (target.hp + amount).clamp(0, target.maxHp);
  return target.hp - before;
}
