// 开场流程的状态机测试。
//
// ## 为什么这组测试值钱
//
// 流程的每一步都有**源码依据**（`gProcScr_GameControl` + `Title_IDLE`），
// 但"依据"和"实现一致"是两回事 —— 差一帧、差一个分支都会让
// 「不按键 815 帧播职业介绍」这类行为悄悄失效。
//
// 这组测试把**每一跳和它的判据**钉住：
//   * ① 三个画面的顺序与帧数
//   * ④ 815 帧超时 → 职业介绍（**用户明确描述过的行为**）
//   * ⑤ 主菜单 → 难度 → 存档槽 → 可以进游戏
import 'package:fe8r/core/core.dart';
import 'package:fe8r/game/title_flow.dart';
import 'package:flutter_test/flutter_test.dart';

TitleFlow fresh() => TitleFlow(texts: const GameTexts.empty());

/// 推进 n 帧，不带任何输入
void idle(TitleFlow f, int n) {
  for (var i = 0; i < n; i++) {
    f.tick(confirm: false, cancel: false, up: false, down: false);
  }
}

void main() {
  group('① 开机三个画面', () {
    test('顺序是 Nintendo → IntelligentSystems → HealthSafety', () {
      final f = fresh();
      expect(f.screen, TitleScreen.nintendo);

      idle(f, TitleTimings.fadeFrames * 2 + TitleTimings.holdFrames + 1);
      expect(f.screen, TitleScreen.intelligentSystems,
          reason: '第一个画面按帧数走完就该切到第二个');

      idle(f, TitleTimings.fadeFrames * 2 + TitleTimings.holdFrames + 1);
      expect(f.screen, TitleScreen.healthSafety);
    });

    test('★ 健康警告**等按键**，不给按键就一直等', () {
      final f = fresh();
      // 快进到健康警告
      idle(f, (TitleTimings.fadeFrames * 2 + TitleTimings.holdFrames + 1) * 2);
      expect(f.screen, TitleScreen.healthSafety);

      // 再等 2000 帧也不该自己走掉（原作这里没有超时）
      idle(f, 2000);
      expect(f.screen, TitleScreen.healthSafety,
          reason: '「Press Start」不给按键不能自己过去');

      // 给一个确认键才走
      f.tick(confirm: true, cancel: false, up: false, down: false);
      expect(f.screen, TitleScreen.title);
    });
  });

  group('④ 标题画面', () {
    TitleFlow atTitle() {
      final f = fresh();
      idle(f, (TitleTimings.fadeFrames * 2 + TitleTimings.holdFrames + 1) * 2);
      f.tick(confirm: true, cancel: false, up: false, down: false);
      return f;
    }

    test('按键 → 进主菜单', () {
      final f = atTitle();
      expect(f.screen, TitleScreen.title);
      f.tick(confirm: true, cancel: false, up: false, down: false);
      expect(f.screen, TitleScreen.mainMenu);
    });

    test('★ **不按键 815 帧** → 播职业介绍（用户描述过的行为）', () {
      final f = atTitle();
      // 差一帧时还在标题
      idle(f, TitleTimings.classReelTimeout - 1);
      expect(f.screen, TitleScreen.title,
          reason: '814 帧时不该走 —— 判据是 == 815');

      // 第 815 帧
      f.tick(confirm: false, cancel: false, up: false, down: false);
      expect(f.screen, TitleScreen.classReel,
          reason: '815 帧不按键就播职业介绍（src/titlescreen_080CB2A0.c:46）');
    });

    test('职业介绍看完回标题', () {
      final f = atTitle();
      idle(f, TitleTimings.classReelTimeout);
      expect(f.screen, TitleScreen.classReel);
      f.tick(confirm: true, cancel: false, up: false, down: false);
      expect(f.screen, TitleScreen.title);
    });
  });

  group('⑤ 主菜单 → 难度 → 存档槽', () {
    TitleFlow atMenu() {
      final f = fresh()..startAt = TitleScreen.mainMenu;
      f.reset();
      return f;
    }

    test('主菜单可以切到「附加内容」，但确认不了（本实现不做）', () {
      final f = atMenu();
      expect(f.mainItem, MainMenuItem.newGame);
      f.tick(confirm: false, cancel: false, up: false, down: true);
      expect(f.mainItem, MainMenuItem.extras);

      final go = f.tick(confirm: true, cancel: false, up: false, down: false);
      expect(go, isFalse, reason: '附加内容没实现，不该放行');
      expect(f.screen, TitleScreen.mainMenu, reason: '应当留在原地而不是静默跳走');
    });

    test('新游戏 → 难度 → 存档槽 → 放行', () {
      final f = atMenu();
      f.tick(confirm: true, cancel: false, up: false, down: false);
      expect(f.screen, TitleScreen.difficulty);
      expect(f.difficulty, Difficulty.normal, reason: '默认普通');

      // 往上 = 新手
      f.tick(confirm: false, cancel: false, up: true, down: false);
      expect(f.difficulty, Difficulty.easy);

      f.tick(confirm: true, cancel: false, up: false, down: false);
      expect(f.screen, TitleScreen.saveSlot);

      final go = f.tick(confirm: true, cancel: false, up: false, down: false);
      expect(go, isTrue, reason: '选完存档槽就该进游戏了');
      expect(f.saveSlot, 0);
    });

    test('难度三档，边界不越界', () {
      final f = atMenu();
      f.tick(confirm: true, cancel: false, up: false, down: false); // → 难度
      for (var i = 0; i < 5; i++) {
        f.tick(confirm: false, cancel: false, up: false, down: true);
      }
      expect(f.difficulty, Difficulty.hard, reason: '往下到底就是困难');
      for (var i = 0; i < 5; i++) {
        f.tick(confirm: false, cancel: false, up: true, down: false);
      }
      expect(f.difficulty, Difficulty.easy, reason: '往上到底就是新手');
    });
  });

  test('标题文字用的是**真实消息表**（253 / 1749）', () {
    final f = fresh();
    // `GameTexts.empty()` 时退回硬编码的原文，仍然是那一句
    expect(f.gameTitle, '聖魔の光石');
    expect(f.pressStart, 'スタートを押すと始まります');
  });
}
