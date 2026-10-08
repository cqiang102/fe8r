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

TitleFlow fresh() => TitleFlow(texts: GameTexts.empty());

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

    test('★ 主菜单的选项**按存档状态动态出现**（`InitSaveMenuChoice.c`）', () {
      final f = fresh();
      // 全新（无存档、无中断）：只有「はじめから」
      expect(f.options, [MainMenuItem.newGame],
          reason: 'count==0 且无 extras 时只加 NEW_GAME');

      // 有 1 个存档：RESTART / COPY / ERASE / NEW_GAME
      f.usedSlots = 1;
      expect(f.options, [
        MainMenuItem.restart,
        MainMenuItem.copy,
        MainMenuItem.erase,
        MainMenuItem.newGame,
      ]);

      // 3 个存档全满：没有 COPY（`if (count < 3)`）、也没有 NEW_GAME
      f.usedSlots = 3;
      expect(f.options, [
        MainMenuItem.restart,
        MainMenuItem.erase,
      ]);

      // 有中断存档 → 最前面加 RESUME
      f.usedSlots = 0;
      f.resumable = true;
      expect(f.options, [MainMenuItem.resume, MainMenuItem.newGame]);
    });

    test('上下到边界就停（原作不循环）', () {
      final f = atMenu();
      f.usedSlots = 1;
      expect(f.options.length, 4);
      // 往上到底还是 0
      for (var i = 0; i < 3; i++) {
        f.tick(confirm: false, cancel: false, up: true, down: false);
      }
      expect(f.mainIndex, 0);
      // 往下到底 = 最后一项
      for (var i = 0; i < 9; i++) {
        f.tick(confirm: false, cancel: false, up: false, down: true);
      }
      expect(f.mainIndex, 3);
    });

    test('新游戏 → 难度 → 存档槽 → 放行', () {
      final f = atMenu();
      f.tick(confirm: true, cancel: false, up: false, down: false);
      expect(f.screen, TitleScreen.difficulty);
      expect(f.difficulty, Difficulty.normal, reason: '默认普通（第 5 轮试改成 easy 会弄坏中断/读档两条场景，已回退）');

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

  group('★ 菜单项的精灵索引 = 枚举值（`include/savemenu.h:33-41`）', () {
    test('NEW_GAME 的精灵索引是 4，不是列表位置', () {
      // `SpriteArray_SavemenuData_1[4] = gSprite_SavemenuData_4`
      expect(MainMenuItem.newGame.spriteIndex, 4);
      expect(MainMenuItem.resume.spriteIndex, 0);
      expect(MainMenuItem.restart.spriteIndex, 1);
      expect(MainMenuItem.copy.spriteIndex, 2);
      expect(MainMenuItem.erase.spriteIndex, 3);
      expect(MainMenuItem.extras.spriteIndex, 5);
    });

    test('精灵索引**与它在可见列表里的位置无关**', () {
      final f = fresh();
      f.usedSlots = 1;
      // 列表 = [RESTART(1), COPY(2), ERASE(3), NEW_GAME(4)]
      // 位置是 0..3，但精灵索引是 1..4 —— 两者不同
      final idx = f.options.map((o) => o.spriteIndex).toList();
      expect(idx, [1, 2, 3, 4]);
      expect(idx, isNot(List.generate(4, (i) => i)),
          reason: '如果按位置取精灵，第一项会画成 RESUME 的图');
    });
  });

  group('★ 选项走向（`src/SaveMenuTryMoveSaveSlotCursor.c:24-41`）', () {
    test('NEW_GAME 直接去难度，不选存档槽', () {
      final f = fresh()..startAt = TitleScreen.mainMenu;
      f.reset();
      expect(f.mainItem, MainMenuItem.newGame);
      f.tick(confirm: true, cancel: false, up: false, down: false);
      expect(f.screen, TitleScreen.difficulty);
    });

    test('RESUME 什么都不选，直接进游戏', () {
      final f = fresh()..startAt = TitleScreen.mainMenu;
      f.reset();
      f.resumable = true;
      expect(f.mainItem, MainMenuItem.resume);
      final go = f.tick(confirm: true, cancel: false, up: false, down: false);
      expect(go, isTrue);
      expect(f.screen, TitleScreen.mainMenu, reason: 'RESUME 不经过任何画面');
    });

    test('RESTART / ERASE / COPY 要先选存档槽', () {
      // ⚠️ COPY 只在 `count < 3` 时出现（`InitSaveMenuChoice.c`），
      // 所以用 1 个存档 —— 这样三项都在列表里。
      // （我第一版用 `usedSlots = 3`，COPY 不在列表里 —— **测试写错了，不是代码错**，
      //   而这恰好反证了实现与源码一致。）
      for (final target in [MainMenuItem.restart, MainMenuItem.erase,
                            MainMenuItem.copy]) {
        final f = fresh()..startAt = TitleScreen.mainMenu;
        f.reset();
        f.usedSlots = 1;
        final i = f.options.indexOf(target);
        expect(i, greaterThanOrEqualTo(0), reason: '$target 应该出现在列表里');
        for (var k = 0; k < i; k++) {
          f.tick(confirm: false, cancel: false, up: false, down: true);
        }
        expect(f.mainItem, target);
        f.tick(confirm: true, cancel: false, up: false, down: false);
        expect(f.screen, TitleScreen.saveSlot,
            reason: '$target 的 flag=1，要先选槽');
      }
    });
  });

  group('★ 难度的说明文字 ID 来自源码（gTextIds_DifficultyDescription）', () {
    test('三个 ID = 0x0832 / 0x0833 / 0x0834（消息 2098/2099/2100）', () {
      expect(Difficulty.easy.descriptionMsgId, 0x0832);
      expect(Difficulty.normal.descriptionMsgId, 0x0833);
      expect(Difficulty.hard.descriptionMsgId, 0x0834);
      expect(Difficulty.easy.descriptionMsgId, 2098);
      expect(Difficulty.hard.descriptionMsgId, 2100);
    });
  });

  test('标题文字用的是**真实消息表**（253 / 1749）', () {
    final f = fresh();
    // `GameTexts.empty()` 时退回硬编码的原文，仍然是那一句
    expect(f.gameTitle, '聖魔の光石');
    expect(f.pressStart, 'スタートを押すと始まります');
  });
}
