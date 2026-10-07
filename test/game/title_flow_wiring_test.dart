// 开场流程**接入游戏之后**是不是按帧走。
//
// ## 为什么单独一条
//
// `TitleFlow` 自己的状态机测试（`title_flow_test.dart`）一直是绿的 ——
// 它每一跳都按帧数算得清清楚楚。**问题出在调用点**：
//
//     bool _titleInput(FlowInput i) { ... f.tick(confirm: i == confirm, ...) }
//     void routeInput(FlowInput i) { if (inTitleFlow && _titleInput(i)) return; ... }
//
// `tick()` **只在按键时被调用**，于是 `framesOnScreen` 其实是"按了几次键"：
//
//   * Nintendo / IS 的淡入淡出（30 帧淡入 + 40 帧停 + 30 帧淡出）
//     **不给按键就永远停在第一屏**
//   * 815 帧"等太久 → 播职业介绍"永远不会发生
//   * 按住键连打会把 100 帧的过场"按"过去
//
// 出处：`src/titlescreen_080CB2A0.c:33-52`（每个画面有自己的 `timer`，
// 每帧 +1；按键只是每帧读一次 `newKeys`）。
import 'package:fe8r/core/core.dart';
import 'package:fe8r/game/fe8_game.dart';
import 'package:fe8r/game/title_flow.dart';
import 'package:flutter_test/flutter_test.dart';

/// 一个只装了开场流程的游戏（不碰 Flame 的加载）。
Fe8Game gameAtTitle() {
  final g = Fe8Game();
  g.titleFlow = TitleFlow(texts: GameTexts.empty());
  return g;
}

/// 推进 n 帧（走游戏的 `update`，即真实主循环那条路）
void frames(Fe8Game g, int n) {
  for (var i = 0; i < n; i++) {
    g.update(1 / 60);
  }
}

const int oneIntroScreen =
    TitleTimings.fadeFrames * 2 + TitleTimings.holdFrames + 1;

void main() {
  test('★ 不给按键，Nintendo / IS 两屏也会按帧走完', () {
    final g = gameAtTitle();
    expect(g.titleFlow!.screen, TitleScreen.nintendo);

    // ⚠️ 这一条在修之前会红：`update` 里根本没人调 `tick`
    frames(g, oneIntroScreen);
    expect(g.titleFlow!.screen, TitleScreen.intelligentSystems,
        reason: '时间驱动的画面不该等按键');

    frames(g, oneIntroScreen);
    expect(g.titleFlow!.screen, TitleScreen.healthSafety);
  });

  test('按键不再冒充"帧"：按 100 次键不会推过 Nintendo 屏', () {
    final g = gameAtTitle();
    for (var i = 0; i < 100; i++) {
      g.routeInput(FlowInput.confirm);
    }
    // 一帧都没推进 —— 按键只是排队
    expect(g.titleFlow!.screen, TitleScreen.nintendo,
        reason: '按键次数不该等于帧数（这正是修之前的 bug）');

    // 帧推进之后才走：100 次按键正好被 100 帧消费掉
    frames(g, oneIntroScreen);
    expect(g.titleFlow!.screen, TitleScreen.intelligentSystems);

    frames(g, oneIntroScreen);
    expect(g.titleFlow!.screen, TitleScreen.healthSafety);
  });

  test('健康警告等按键：给一次确认就进标题', () {
    final g = gameAtTitle();
    frames(g, oneIntroScreen * 2);
    expect(g.titleFlow!.screen, TitleScreen.healthSafety);

    g.routeInput(FlowInput.confirm);
    frames(g, 1);
    expect(g.titleFlow!.screen, TitleScreen.title);
  });

  test('不按键等到 815 帧 → 播职业介绍（原作行为）', () {
    final g = gameAtTitle();
    frames(g, oneIntroScreen * 2); // 到健康警告
    g.routeInput(FlowInput.confirm); // → 标题
    frames(g, 1);
    expect(g.titleFlow!.screen, TitleScreen.title);

    frames(g, TitleTimings.classReelTimeout);
    expect(g.titleFlow!.screen, TitleScreen.classReel,
        reason: '等太久自动播职业介绍 —— 按键驱动的实现永远走不到这里');
  });

  test('一路按键能走到"可以进游戏"（存档槽确认）', () {
    final g = gameAtTitle();
    frames(g, oneIntroScreen * 2); // 到健康警告
    for (var i = 0; i < 6; i++) {
      g.routeInput(FlowInput.confirm);
      frames(g, 1);
      if (g.titleFlow == null) break;
    }
    expect(g.titleFlow, isNull,
        reason: '流程跑完会把 titleFlow 置空并开始演序章');
  });
}
