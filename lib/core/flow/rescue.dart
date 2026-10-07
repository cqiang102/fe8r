// PORT OF: src/exact_08018030.c:40-45（`CanUnitRescue`）
//          src/exact_080186cc.c:37-44（`GetUnitAid`）
//          src/exact_08018060.c:37-46（`UnitRescue`）
//          src/UnitDrop.c:31-45（`UnitDrop`）
//          src/DropUsability.c:50-66（`DropUsability`）
//          include/bmunit.h（`US_RESCUING` / `US_RESCUED` / `US_HIDDEN` / `US_UNSELECTABLE`）
//
// # 救出 / 降下
//
// ```c
// s8 CanUnitRescue(struct Unit* actor, struct Unit* target) {
//     int actorAid  = GetUnitAid(actor);
//     int targetCon = UNIT_CON(target);
//     return (actorAid >= targetCon) ? TRUE : FALSE;
// }
//
// int GetUnitAid(struct Unit* unit) {
//     if (!(UNIT_CATTRIBUTES(unit) & CA_MOUNTEDAID)) return UNIT_CON(unit) - 1;
//     if (UNIT_CATTRIBUTES(unit) & CA_FEMALE)        return 20 - UNIT_CON(unit);
//     else                                           return 25 - UNIT_CON(unit);
// }
//
// void UnitRescue(struct Unit* actor, struct Unit* target) {
//     actor->state  |= US_RESCUING;
//     target->state |= US_RESCUED | US_HIDDEN;
//     actor->rescue = target->index;
//     target->rescue = actor->index;
//     target->xPos = actor->xPos;
//     target->yPos = actor->yPos;
// }
//
// void UnitDrop(struct Unit* actor, int xTarget, int yTarget) {
//     struct Unit* target = GetUnit(actor->rescue);
//     actor->state  &= ~(US_RESCUING | US_RESCUED);
//     target->state &= ~(US_RESCUING | US_RESCUED | US_HIDDEN);
//     if (UNIT_FACTION(target) == gPlaySt.faction) target->state |= US_UNSELECTABLE;
//     actor->rescue = 0; target->rescue = 0;
//     target->xPos = xTarget; target->yPos = yTarget;
// }
// ```
//
// ⚠️ 两个容易搞反的地方（都写进判据）：
//   1. **降下后目标当回合不能再动**（`US_UNSELECTABLE`，只对我方 faction 置位）；
//   2. `UnitRescue` 会把目标**挪到发起者的坐标**（两个人叠在同一格）；
//      `UnitDrop` 才把它放到落点。

import 'battle_field.dart';

/// `GetUnitAid`：`include/bmunit.h` 的 `CA_MOUNTEDAID` / `CA_FEMALE`
int unitAid({
  required int con,
  required bool mountedAid,
  required bool female,
}) {
  if (!mountedAid) return con - 1;
  return female ? 20 - con : 25 - con;
}

/// `CanUnitRescue`
bool canUnitRescue({required int actorAid, required int targetCon}) =>
    actorAid >= targetCon;

/// `UnitRescue`：**双方互记 rescue 索引** + 目标挪到发起者坐标
void unitRescue(MapUnit actor, MapUnit target) {
  actor.isRescuing = true;
  target.isRescued = true;
  target.isHidden = true;
  actor.rescueIndex = target.id;
  target.rescueIndex = actor.id;
  target.x = actor.x;
  target.y = actor.y;
}

/// `UnitDrop`：清状态位、断链接、把人放到 (xTarget, yTarget)。
///
/// `targetIsPlayerFaction` 对应 `UNIT_FACTION(target) == gPlaySt.faction`
/// ⇒ 置 `US_UNSELECTABLE`（**当回合不能再动**）。
void unitDrop(
  MapUnit actor,
  MapUnit target, {
  required int xTarget,
  required int yTarget,
  required bool targetIsPlayerFaction,
}) {
  actor.isRescuing = false;
  actor.isRescued = false;
  target.isRescuing = false;
  target.isRescued = false;
  target.isHidden = false;
  if (targetIsPlayerFaction) target.unselectable = true;
  actor.rescueIndex = 0;
  target.rescueIndex = 0;
  target.x = xTarget;
  target.y = yTarget;
}

/// 「降ろす」这一项该不该出现（`DropUsability`）
bool dropAvailable({
  required bool hasActed,
  required bool isRescuing,
  required bool hasTarget,
}) {
  if (hasActed) return false;
  if (!isRescuing) return false;
  return hasTarget;
}

/// `MakeDropTargetList`：**相邻的空格**（有单位/不可通行格不算）
List<(int, int)> dropTargets({
  required int x,
  required int y,
  required bool Function(int x, int y) isFree,
}) {
  final out = <(int, int)>[];
  for (final (dx, dy) in const [(0, -1), (0, 1), (-1, 0), (1, 0)]) {
    if (isFree(x + dx, y + dy)) out.add((x + dx, y + dy));
  }
  return out;
}
