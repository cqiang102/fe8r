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

/// 杖的目标列表。
///
/// * 只对自己阵营（`UNIT_FACTION` 同侧）；
/// * 排除死 / 隐藏（被扛走）/ 不可选；
/// * **HP 不是满的**（满血不给治 —— 类比 `MakeTerrainHealTargetList` 的判据）；
/// * 射程：曼哈顿距离落在 `[minRange, maxRange]`（武器射程，`encodedRange` 已拆好）。
List<StaffTarget> staffTargets({
  required MapUnit user,
  required List<MapUnit> units,
  required int healAmount,
  required int minRange,
  required int maxRange,
  bool Function(MapUnit u)? isSameFaction,
}) {
  final same = isSameFaction ?? (MapUnit u) => u.factionBit == user.factionBit;
  final out = <StaffTarget>[];
  for (final u in units) {
    if (u.id == user.id) continue;
    if (!u.isAlive || u.isHidden) continue;
    if (!same(u)) continue;
    if (u.hp >= u.maxHp) continue; // 满血不给治
    final d = (u.x - user.x).abs() + (u.y - user.y).abs();
    if (d < minRange || d > maxRange) continue;
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
