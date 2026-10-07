// PORT OF: src/TalkCommandUsability.c:50-64（`TalkCommandUsability`）
//          src/bmtarget_0802506C.c:283-295（`TryAddUnitToTalkTargetList`）
//          src/bmtarget_0802506C.c:297-304（`MakeTalkTargetList`：`ForEachAdjacentUnit`）
//          src/CheckForCharacterEvents.c:25-41（`CheckForCharacterEvents`）
//          src/eventinfo_080851B8.c 的 `EvCheck03_CHAR`（`{unk0, script, u8 pidA, u8 pidB}`）
//
// # 話す（对话事件）
//
// ```c
// u8 TalkCommandUsability(...) {
//     if (gActiveUnit->state & US_HAS_MOVED) return MENU_NOTSHOWN;
//     MakeTalkTargetList(gActiveUnit);
//     if (GetSelectTargetCount() == 0) return MENU_NOTSHOWN;
//     if (gActiveUnit->statusIndex == UNIT_STATUS_SILENCED) return MENU_DISABLED;
//     return MENU_ENABLED;   // （尾部的 return 见源码）
// }
// void MakeTalkTargetList(struct Unit* unit) {
//     ForEachAdjacentUnit(unit->xPos, unit->yPos, TryAddUnitToTalkTargetList);
// }
// void TryAddUnitToTalkTargetList(struct Unit* unit) {
//     if (status == BERSERK || status == SLEEP) return;        // 状态：我们没建模
//     if (!CheckForCharacterEvents(gSubjectUnit->pid, unit->pid)) return;
//     AddTarget(...);
// }
// s8 CheckForCharacterEvents(u8 pidA, u8 pidB) {
//     info.listScript = 本章的 characterBasedEvents;
//     info.pidA = pidA; info.pidB = pidB;
//     return SearchAvailableEvent(&info) ? 1 : 0;   // ⇒ 还要过**条目自己的旗门**
// }
// ```
//
// ⚠️ **方向**：条目自己写着 `(pidA, pidB)` 的顺序 ⇒ 谁跟谁能说话**由数据决定**
//    （第 2 章里 `(1,7)` 与 `(7,1)` 是两条不同条目）。这里照数据比，不猜方向。
// ⚠️ **相邻**：`ForEachAdjacentUnit` 是四邻居且**不含自己那格**
//    （`MapAddInRange(x,y,0,-1)` 抹掉中心，见第 57 轮的考证）。
// ⚠️ 沉默/狂暴/睡眠这些**状态**我们还没建模 ⇒ 判据里不做，代码注释里标明。

import 'battle_field.dart';

/// 章节 `characterBasedEvents` 里的一条 `CHAR` 条目
class CharacterEvent {
  const CharacterEvent({
    required this.pidA,
    required this.pidB,
    required this.doneFlag,
    this.script,
  });

  /// `EvCheck03_CHAR` 里的两个角色编号（**顺序就是条目的顺序**）
  final int pidA;
  final int pidB;

  /// 演过之后置位（`SearchAvailableEvent` 会跳过已置位的条目）
  final int doneFlag;

  final String? script;

  Map<String, Object?> toJson() => {
        'pidA': pidA,
        'pidB': pidB,
        'doneFlag': doneFlag,
        'script': script,
      };
}

/// `CheckForCharacterEvents`：找 `(pidA, pidB)` 匹配、且 `doneFlag` 未置位的条目
CharacterEvent? checkForCharacterEvents(
  List<CharacterEvent> events,
  int pidA,
  int pidB,
  Set<int> flags,
) {
  for (final e in events) {
    if (e.pidA != pidA || e.pidB != pidB) continue;
    if (e.doneFlag != 0 && flags.contains(e.doneFlag)) continue;
    return e;
  }
  return null;
}

/// `MakeTalkTargetList`：**相邻**（四邻居、不含自己）里、与 `actor` 有 CHAR 条目的人
///
/// `eventFor` 由调用方给（它知道本章的 CHAR 表 + 旗）—— 核心层不持有章节数据。
List<MapUnit> talkTargets({
  required MapUnit actor,
  required List<MapUnit> units,
  required CharacterEvent? Function(MapUnit target) eventFor,
}) {
  final out = <MapUnit>[];
  for (final u in units) {
    if (u.id == actor.id || !u.isAlive || u.isHidden) continue;
    final d = (u.x - actor.x).abs() + (u.y - actor.y).abs();
    if (d != 1) continue; // 相邻（四邻居；不含自己那格）
    if (eventFor(u) == null) continue;
    out.add(u);
  }
  return out;
}

/// 「話す」这一项该不该出现（`TalkCommandUsability`）
///
/// ⚠️ 沉默状态那条 `MENU_DISABLED` **未做**（我们还没状态系统）—— 不是漏写，是没建模。
bool talkAvailable({required bool hasActed, required bool hasTarget}) {
  if (hasActed) return false;
  return hasTarget;
}
