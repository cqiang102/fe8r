// PORT OF: src/player_interface_0808F2C0.c:61-64（可见性：`disableGoalDisplay` +
//            `EVFLAG_OBJWINDOW_DISABLE` 两个条件）
//          src/player_interface_0808F584.c（`GoalDisplay_Init`：读
//            `goalWindowTextId` 作为窗口里的字）
//          src/player_interface_0808F764.c:122-133 / :142-154
//            （`GoalDisplay_Loop_SlideIn` 到 `showHideClock == 5` 结束、
//             `GoalDisplay_Loop_SlideOut` 到 `== 3` 结束 ⇒ 滑入 6 帧、滑出 4 帧）
//          src/data/frontier_df4_menu/frontier_df4_menu.c（`gProcScr_GoalDisplay`：
//            `Init → LABEL(0) → 等相机停下 → OnSideChange → SlideIn → Display → SlideOut → GOTO(0)`
//             ⇒ **每次阵营切换**都会滑入再滑出）
//          include/constants/event-flags.h:16（`EVFLAG_OBJWINDOW_DISABLE = 102`）
//
// ⚠️ **未查证**：`sGoalSlideInWidthLut[5]` / `sGoalSlideOutWidthLut` 的**每帧宽度**
//（那几个数值只在 `src/player_interface_0808F764.c` 里被 extern 声明，定义没在 carve 里找到）
// ⇒ 帧数（6/4）是源码的，**逐帧像素位移不是**。
// ⚠️ 窗口第二行（按 `goalWindowDataType` 拼的"剩余回合"等）**未实现**。

const int kEvFlagObjWindowDisable = 102;

enum GoalWindowStage { slidingIn, shown, slidingOut, hidden }

class GoalWindowState {
  GoalWindowState({required this.wantVisible});

  /// `gPlaySt.config.disableGoalDisplay == 0 && CheckFlag(EVFLAG_OBJWINDOW_DISABLE) == 0`
  bool wantVisible;

  GoalWindowStage stage = GoalWindowStage.hidden;
  int clock = 0;

  /// 累计"滑入过"多少次（判据用）
  int shownCount = 0;

  bool get visible => stage != GoalWindowStage.hidden;

  /// 阵营切换时调：滑入
  void onSideChange() {
    if (!wantVisible) {
      stage = GoalWindowStage.hidden;
      clock = 0;
      return;
    }
    stage = GoalWindowStage.slidingIn;
    clock = 0;
  }

  /// 每帧推进。滑入 6 帧、显示保持 [holdFrames]、滑出 4 帧、然后**从头再来**
  ///（`gProcScr_GoalDisplay` 末尾是 `PROC_GOTO(0)`）。
  void tick({int holdFrames = 120}) {
    if (!wantVisible) {
      stage = GoalWindowStage.hidden;
      clock = 0;
      return;
    }
    clock++;
    switch (stage) {
      case GoalWindowStage.hidden:
        stage = GoalWindowStage.slidingIn;
        clock = 0;
      case GoalWindowStage.slidingIn:
        if (clock >= 6) {
          stage = GoalWindowStage.shown;
          clock = 0;
          shownCount++;
        }
      case GoalWindowStage.shown:
        if (clock >= holdFrames) {
          stage = GoalWindowStage.slidingOut;
          clock = 0;
        }
      case GoalWindowStage.slidingOut:
        if (clock >= 4) {
          stage = GoalWindowStage.hidden;
          clock = 0;
        }
    }
  }
}
