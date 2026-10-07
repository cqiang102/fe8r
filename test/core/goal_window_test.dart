// 目标窗口（`GoalDisplay`）的规则层判据。
//
// 出处：`src/player_interface_0808F2C0.c:61-64`（可见性）、
//       `src/player_interface_0808F764.c:122-154`（滑入 6 帧 / 滑出 4 帧）。
import 'package:fe8r/core/core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('★ 两个条件都要满足才显示（`disableGoalDisplay` + 旗 102）', () {
    final off = GoalWindowState(wantVisible: false);
    off.onSideChange();
    expect(off.visible, isFalse, reason: '设置关掉了就不显示');
    for (var i = 0; i < 200; i++) {
      off.tick();
    }
    expect(off.visible, isFalse);
    expect(off.shownCount, 0);

    final on = GoalWindowState(wantVisible: true);
    on.onSideChange();
    expect(on.stage, GoalWindowStage.slidingIn);
    expect(on.visible, isTrue);
  });

  test('★ 帧数照源码：滑入 6 帧、滑出 4 帧', () {
    final s = GoalWindowState(wantVisible: true)..onSideChange();
    for (var i = 1; i < 6; i++) {
      s.tick(holdFrames: 1);
      expect(s.stage, GoalWindowStage.slidingIn, reason: '第 $i 帧还在滑入');
    }
    s.tick(holdFrames: 1); // 第 6 帧结束
    expect(s.stage, GoalWindowStage.shown);
    expect(s.shownCount, 1);
    s.tick(holdFrames: 1); // 保持 1 帧
    expect(s.stage, GoalWindowStage.slidingOut);
    for (var i = 1; i < 4; i++) {
      s.tick(holdFrames: 1);
      expect(s.stage, GoalWindowStage.slidingOut);
    }
    s.tick(holdFrames: 1);
    expect(s.stage, GoalWindowStage.hidden);
  });

  test('滑出之后会**再来一轮**（`gProcScr_GoalDisplay` 末尾 `PROC_GOTO(0)`）', () {
    final s = GoalWindowState(wantVisible: true)..onSideChange();
    for (var i = 0; i < 6 + 120 + 4 + 2; i++) {
      s.tick();
    }
    expect(s.shownCount, greaterThanOrEqualTo(1));
    expect(s.visible, isTrue, reason: '循环里它会再滑进来');
  });

  test('运行中把设置关掉 ⇒ 立刻不显示', () {
    final s = GoalWindowState(wantVisible: true)..onSideChange();
    s.tick();
    s.wantVisible = false;
    s.tick();
    expect(s.visible, isFalse);
  });
}
