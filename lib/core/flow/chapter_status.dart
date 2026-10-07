// PORT OF: src/uichapterstatus_080908DC.c:30-86（`ChapterStatus_LoopKeyHandler`）
//          src/MapMenu_StatusCommand.c:50-54（`MapMenu_StatusCommand`）
//          src/uichapterstatus_08090A38.c:28-44（`StartChapterStatusScreen`）
//          src/uichapterstatus_08090710.c:25-58（`DrawChapterStatusStatValues`）
//          src/data/frontier_df4_menu/frontier_df4_menu.c（`gProcScr_ChapterStatusScreen`）
//
// # 「状況」屏（`StartChapterStatusScreen`）的**规则层**
//
// 这个屏是**单位导向**的：它拿一份我方单位列表，用 `unitIndex` 选一个来显示，
// 退出时可以把镜头聚焦到那个单位（A 键）。
//
// ## 按键（`ChapterStatus_LoopKeyHandler`，逐条照抄）
//
// ```c
// if (newKeys & R_BUTTON)      { helpTextActive = true; StartChapterStatusHelpBox(proc); return; }
// else if (newKeys & A_BUTTON) { … focusUnitOnExit = true; Proc_Goto(proc, 1); return; }
// else if (newKeys & B_BUTTON) { Proc_Goto(proc, 1); return; }
//
// if ((repeatedKeys & DPAD_LEFT)  && (proc->unitIndex != 0))  proc->unitIndex--;
// if ((repeatedKeys & DPAD_RIGHT) && (proc->unitIndex == 0))  proc->unitIndex++;
// ```
//
// ⚠️ **最后两行是不对称的**：往左只在 `unitIndex != 0` 时生效，
// 往右**只在 `unitIndex == 0` 时**生效。看起来像原作的写法如此（不是笔误能改的地方），
// 照抄并且**用测试钉住** —— 这种"怪但确定"的规则最容易被后来的人顺手'修正'。

/// 「状況」屏的运行时状态
class ChapterStatusState {
  ChapterStatusState({required this.unitCount, this.unitIndex = 0});

  /// `proc->units[]` 里有几个可显示的单位
  final int unitCount;

  /// `proc->unitIndex`
  int unitIndex;

  /// `proc->focusUnitOnExit`（按 A 退出时要不要把镜头对到该单位）
  bool focusUnitOnExit = false;

  /// `proc->helpTextActive`（R 键）
  bool helpTextActive = false;

  /// 屏已经关掉了吗（`Proc_Goto(proc, 1)`）
  bool closed = false;

  /// 屏上**当前显示**的单位下标；没有单位时 -1
  int get shownIndex =>
      (unitCount <= 0 || unitIndex < 0 || unitIndex >= unitCount) ? -1 : unitIndex;
}

/// `ChapterStatus_LoopKeyHandler` 的一条输入
enum ChapterStatusKey { right, left, a, b, r }

/// 应用一次输入。**逐条照抄源码**（包括那处不对称），不要"顺手修正"。
void chapterStatusKey(ChapterStatusState s, ChapterStatusKey k) {
  if (s.closed) return;
  switch (k) {
    case ChapterStatusKey.r:
      s.helpTextActive = true;
      return; // 源码里 R 之后**直接 return**，不处理左右
    case ChapterStatusKey.a:
      // `(units[unitIndex] != NULL) && !(state & (US_UNDER_A_ROOF | US_BIT9))`
      // —— 能否聚焦由单位状态决定；这里只记"要聚焦"，具体判定留给表现层
      if (s.shownIndex >= 0) s.focusUnitOnExit = true;
      s.closed = true;
      return;
    case ChapterStatusKey.b:
      s.closed = true;
      return;
    case ChapterStatusKey.left:
      if (s.unitIndex != 0) s.unitIndex--;
      return;
    case ChapterStatusKey.right:
      // ⚠️ **只在 index == 0 时**能往右（源码如此）
      if (s.unitIndex == 0) s.unitIndex++;
      return;
  }
}
