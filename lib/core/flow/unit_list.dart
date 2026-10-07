// PORT OF: src/unitlistscreen_08093744.c:64-190（`UnitList_LoopKeyHandler` 一族：
//            A / R / 上下键 / 边界翻页）
//          src/unitlistscreen_08093DE4.c:54（B 键退出）
//          src/unitlistscreen_08093AD0.c:51-80（`UnitList_HandleSortInput`：排序输入）
//          src/MapMenu_UnitListCommand.c（地图菜单「部隊」入口）
//
// # 「部隊」（单位一览）的**规则层**
//
// ## A 键的语义（`UNITLIST_MODE_FIELD`，`unitlistscreen_08093744.c:83-90`）
//
// ```c
// case UNITLIST_MODE_FIELD:
//     SetLastStatScreenUid(gSortedUnits[proc->unk_30]->unit->index);
//     PlaySoundEffect(SONG_SE_SYS_WINDOW_SELECT1);
//     Proc_Break(proc);
// ```
// ⇒ **记住选中的单位、然后跳出列表** —— 之后打开的就是**那个单位**的「状況」屏。
// 这两屏在原作里就是这么串起来的。
//
// ## 上下键的边界（`:144-158`）
//
// 在顶端（`unk_30 == 0`）**再按上**不是循环到末尾，而是**翻页**（`proc->unk_29 = 3`），
// 且只在**新按下**时触发（`newKeys & DPAD_UP`，按住重复不算）。
//
// ⚠️ 未实现/未查证（不假装做了）：
//   * **排序**（`R`/`UnitList_HandleSortInput`）—— 原作的排序键与六项比较规则没移植；
//   * **每行显示的战斗数值**（`gSortedUnitsBuf` 里的 battleAttack/HitRate/…，
//     `unitlistscreen_08092E20.c:36-63`）—— 那一层要 `gBattleActor` 的预测结果。

/// 「部隊」列表的运行时状态
class UnitListState {
  UnitListState({required this.unitIds, this.index = 0});

  /// 列表里的单位（**顺序**就是显示顺序）
  final List<int> unitIds;

  /// `proc->unk_30`：光标所在行
  int index;

  /// 边界再按时请求翻页（`proc->unk_29 = 3`）—— 分页**渲染**还没做
  bool pageUpRequested = false;
  bool pageDownRequested = false;

  /// 按 A 选中的那个单位（`SetLastStatScreenUid`）；没选就是 null
  int? chosenUnitId;

  /// `R` 请求进排序模式（**未实现**，只记下来）
  bool sortRequested = false;

  bool closed = false;

  int get entryCount => unitIds.length;

  int? get shownUnitId =>
      (index >= 0 && index < unitIds.length) ? unitIds[index] : null;
}

/// `UnitList_LoopKeyHandler` 的一条输入
enum UnitListKey { up, down, a, b, r }

/// 应用一次输入。边界行为照源码（顶端再按上是**翻页**，不是循环）。
void unitListKey(UnitListState s, UnitListKey k) {
  if (s.closed) return;
  switch (k) {
    case UnitListKey.up:
      if (s.index > 0) {
        s.index--;
      } else {
        // 顶端：请求上一页（源码只在"新按下"时翻页；`repeatedKeys` 的重复不算）
        s.pageUpRequested = true;
      }
      return;
    case UnitListKey.down:
      if (s.index < s.entryCount - 1) {
        s.index++;
      } else {
        s.pageDownRequested = true;
      }
      return;
    case UnitListKey.a:
      // `SetLastStatScreenUid(...)` + `Proc_Break`
      s.chosenUnitId = s.shownUnitId;
      s.closed = true;
      return;
    case UnitListKey.b:
      s.closed = true;
      return;
    case UnitListKey.r:
      s.sortRequested = true; // 未实现，只记账
      return;
  }
}
