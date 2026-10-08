// arch-exempt: R4 「完全可序列化」这条约束已由用户明确取消（不需要随时存档），
//            所以场景脚本用 async 函数直接表达「等玩家按键」，不再用可序列化的状态机。
//
// ignore_for_file: type=lint, dead_code
//
// PORT OF: src/event.c + src/TalkInterpret.c（场景脚本）
// ^ 只压 lint 噪音；**类型错误照样报** —— 见 analysis_options.yaml 的说明。
//
// GENERATED —— 由 tools/pipeline/extract/gen_scene_dart.py 生成。
// **请勿手改**：改 C 源码或生成器，然后重新生成。
//
// 每个脚本编译成一个 `async` 函数 —— **没有指令列表，没有解释器**。
// 脚本 468 个（直线 347 个 / 有分支 121 个）
//
// 直线脚本是顺序的 async 代码；有分支的用 `while(true){switch(pc)}`，
// `pc` 是**局部变量**（因为不需要存档）。

// ignore_for_file: lines_longer_than_80_chars

import 'scene.dart';

/// `EventScrWM_CastleFrelia_Beginning`
Future<void> EventScrWM_CastleFrelia_Beginning(Scene s) async {
}

/// `EventScrWM_Ch10a_Beginning`
Future<void> EventScrWM_Ch10a_Beginning(Scene s) async {
}

/// `EventScrWM_Ch10b_Beginning`
Future<void> EventScrWM_Ch10b_Beginning(Scene s) async {
}

/// `EventScrWM_Ch11a_Beginning`
Future<void> EventScrWM_Ch11a_Beginning(Scene s) async {
}

/// `EventScrWM_Ch11b_Beginning`
Future<void> EventScrWM_Ch11b_Beginning(Scene s) async {
}

/// `EventScrWM_Ch12a_Beginning`
Future<void> EventScrWM_Ch12a_Beginning(Scene s) async {
}

/// `EventScrWM_Ch12b_Beginning`
Future<void> EventScrWM_Ch12b_Beginning(Scene s) async {
}

/// `EventScrWM_Ch13a_Beginning`
Future<void> EventScrWM_Ch13a_Beginning(Scene s) async {
}

/// `EventScrWM_Ch13b_Beginning`
Future<void> EventScrWM_Ch13b_Beginning(Scene s) async {
}

/// `EventScrWM_Ch14a_Beginning`
Future<void> EventScrWM_Ch14a_Beginning(Scene s) async {
}

/// `EventScrWM_Ch14b_Beginning`
Future<void> EventScrWM_Ch14b_Beginning(Scene s) async {
}

/// `EventScrWM_Ch15a_Beginning`
Future<void> EventScrWM_Ch15a_Beginning(Scene s) async {
}

/// `EventScrWM_Ch15b_Beginning`
Future<void> EventScrWM_Ch15b_Beginning(Scene s) async {
}

/// `EventScrWM_Ch16a_Beginning`
Future<void> EventScrWM_Ch16a_Beginning(Scene s) async {
}

/// `EventScrWM_Ch16b_Beginning`
Future<void> EventScrWM_Ch16b_Beginning(Scene s) async {
}

/// `EventScrWM_Ch17a_Beginning`
Future<void> EventScrWM_Ch17a_Beginning(Scene s) async {
}

/// `EventScrWM_Ch17b_Beginning`
Future<void> EventScrWM_Ch17b_Beginning(Scene s) async {
}

/// `EventScrWM_Ch18a_Beginning`
Future<void> EventScrWM_Ch18a_Beginning(Scene s) async {
}

/// `EventScrWM_Ch18b_Beginning`
Future<void> EventScrWM_Ch18b_Beginning(Scene s) async {
}

/// `EventScrWM_Ch19a_Beginning`
Future<void> EventScrWM_Ch19a_Beginning(Scene s) async {
}

/// `EventScrWM_Ch19b_Beginning`
Future<void> EventScrWM_Ch19b_Beginning(Scene s) async {
}

/// `EventScrWM_Ch1_Beginning`
Future<void> EventScrWM_Ch1_Beginning(Scene s) async {
}

/// `EventScrWM_Ch1_ChapterIntro`
Future<void> EventScrWM_Ch1_ChapterIntro(Scene s) async {
}

/// `EventScrWM_Ch20a_Beginning`
Future<void> EventScrWM_Ch20a_Beginning(Scene s) async {
}

/// `EventScrWM_Ch20b_Beginning`
Future<void> EventScrWM_Ch20b_Beginning(Scene s) async {
}

/// `EventScrWM_Ch21a_Beginning`
Future<void> EventScrWM_Ch21a_Beginning(Scene s) async {
}

/// `EventScrWM_Ch21ax_Beginning`
Future<void> EventScrWM_Ch21ax_Beginning(Scene s) async {
}

/// `EventScrWM_Ch21b_Beginning`
Future<void> EventScrWM_Ch21b_Beginning(Scene s) async {
}

/// `EventScrWM_Ch21bx_Beginning`
Future<void> EventScrWM_Ch21bx_Beginning(Scene s) async {
}

/// `EventScrWM_Ch2_Beginning`
Future<void> EventScrWM_Ch2_Beginning(Scene s) async {
}

/// `EventScrWM_Ch2_BeginningTutorial`
Future<void> EventScrWM_Ch2_BeginningTutorial(Scene s) async {
}

/// `EventScrWM_Ch2_ChapterIntro`
Future<void> EventScrWM_Ch2_ChapterIntro(Scene s) async {
}

/// `EventScrWM_Ch3_Beginning`
Future<void> EventScrWM_Ch3_Beginning(Scene s) async {
}

/// `EventScrWM_Ch3_BeginningTutorial`
Future<void> EventScrWM_Ch3_BeginningTutorial(Scene s) async {
}

/// `EventScrWM_Ch3_ChapterIntro`
Future<void> EventScrWM_Ch3_ChapterIntro(Scene s) async {
}

/// `EventScrWM_Ch4_Beginning`
Future<void> EventScrWM_Ch4_Beginning(Scene s) async {
}

/// `EventScrWM_Ch4_ChapterIntro`
Future<void> EventScrWM_Ch4_ChapterIntro(Scene s) async {
}

/// `EventScrWM_Ch5_0`
Future<void> EventScrWM_Ch5_0(Scene s) async {
}

/// `EventScrWM_Ch5_1`
Future<void> EventScrWM_Ch5_1(Scene s) async {
}

/// `EventScrWM_Ch5_Beginning`
Future<void> EventScrWM_Ch5_Beginning(Scene s) async {
}

/// `EventScrWM_Ch5_ChapterIntro`
Future<void> EventScrWM_Ch5_ChapterIntro(Scene s) async {
}

/// `EventScrWM_Ch5x_Beginning`
Future<void> EventScrWM_Ch5x_Beginning(Scene s) async {
}

/// `EventScrWM_Ch5x_ChapterIntro`
Future<void> EventScrWM_Ch5x_ChapterIntro(Scene s) async {
}

/// `EventScrWM_Ch6_Beginning`
Future<void> EventScrWM_Ch6_Beginning(Scene s) async {
}

/// `EventScrWM_Ch6_ChapterIntro`
Future<void> EventScrWM_Ch6_ChapterIntro(Scene s) async {
}

/// `EventScrWM_Ch7_Beginning`
Future<void> EventScrWM_Ch7_Beginning(Scene s) async {
}

/// `EventScrWM_Ch7_ChapterIntro`
Future<void> EventScrWM_Ch7_ChapterIntro(Scene s) async {
}

/// `EventScrWM_Ch8_Beginning`
Future<void> EventScrWM_Ch8_Beginning(Scene s) async {
}

/// `EventScrWM_Ch8_ChapterIntro`
Future<void> EventScrWM_Ch8_ChapterIntro(Scene s) async {
}

/// `EventScrWM_Ch9a_Beginning`
Future<void> EventScrWM_Ch9a_Beginning(Scene s) async {
}

/// `EventScrWM_Ch9a_ChapterIntro`
Future<void> EventScrWM_Ch9a_ChapterIntro(Scene s) async {
}

/// `EventScrWM_Ch9b_Beginning`
Future<void> EventScrWM_Ch9b_Beginning(Scene s) async {
}

/// `EventScrWM_LagdouRuins10_Beginning`
Future<void> EventScrWM_LagdouRuins10_Beginning(Scene s) async {
}

/// `EventScrWM_LagdouRuins1_Beginning`
Future<void> EventScrWM_LagdouRuins1_Beginning(Scene s) async {
}

/// `EventScrWM_LagdouRuins2_Beginning`
Future<void> EventScrWM_LagdouRuins2_Beginning(Scene s) async {
}

/// `EventScrWM_LagdouRuins3_Beginning`
Future<void> EventScrWM_LagdouRuins3_Beginning(Scene s) async {
}

/// `EventScrWM_LagdouRuins4_Beginning`
Future<void> EventScrWM_LagdouRuins4_Beginning(Scene s) async {
}

/// `EventScrWM_LagdouRuins5_Beginning`
Future<void> EventScrWM_LagdouRuins5_Beginning(Scene s) async {
}

/// `EventScrWM_LagdouRuins6_Beginning`
Future<void> EventScrWM_LagdouRuins6_Beginning(Scene s) async {
}

/// `EventScrWM_LagdouRuins7_Beginning`
Future<void> EventScrWM_LagdouRuins7_Beginning(Scene s) async {
}

/// `EventScrWM_LagdouRuins8_Beginning`
Future<void> EventScrWM_LagdouRuins8_Beginning(Scene s) async {
}

/// `EventScrWM_LagdouRuins9_Beginning`
Future<void> EventScrWM_LagdouRuins9_Beginning(Scene s) async {
}

/// `EventScrWM_MelkaenCoast_Beginning`
Future<void> EventScrWM_MelkaenCoast_Beginning(Scene s) async {
}

/// `EventScrWM_MessedEventscr_0`
Future<void> EventScrWM_MessedEventscr_0(Scene s) async {
}

/// `EventScrWM_MessedEventscr_1`
Future<void> EventScrWM_MessedEventscr_1(Scene s) async {
}

/// `EventScrWM_MessedEventscr_10`
Future<void> EventScrWM_MessedEventscr_10(Scene s) async {
}

/// `EventScrWM_MessedEventscr_11`
Future<void> EventScrWM_MessedEventscr_11(Scene s) async {
}

/// `EventScrWM_MessedEventscr_12`
Future<void> EventScrWM_MessedEventscr_12(Scene s) async {
}

/// `EventScrWM_MessedEventscr_13`
Future<void> EventScrWM_MessedEventscr_13(Scene s) async {
}

/// `EventScrWM_MessedEventscr_14`
Future<void> EventScrWM_MessedEventscr_14(Scene s) async {
}

/// `EventScrWM_MessedEventscr_15`
Future<void> EventScrWM_MessedEventscr_15(Scene s) async {
}

/// `EventScrWM_MessedEventscr_16`
Future<void> EventScrWM_MessedEventscr_16(Scene s) async {
}

/// `EventScrWM_MessedEventscr_17`
Future<void> EventScrWM_MessedEventscr_17(Scene s) async {
}

/// `EventScrWM_MessedEventscr_18`
Future<void> EventScrWM_MessedEventscr_18(Scene s) async {
}

/// `EventScrWM_MessedEventscr_19`
Future<void> EventScrWM_MessedEventscr_19(Scene s) async {
}

/// `EventScrWM_MessedEventscr_2`
Future<void> EventScrWM_MessedEventscr_2(Scene s) async {
}

/// `EventScrWM_MessedEventscr_20`
Future<void> EventScrWM_MessedEventscr_20(Scene s) async {
}

/// `EventScrWM_MessedEventscr_21`
Future<void> EventScrWM_MessedEventscr_21(Scene s) async {
}

/// `EventScrWM_MessedEventscr_22`
Future<void> EventScrWM_MessedEventscr_22(Scene s) async {
}

/// `EventScrWM_MessedEventscr_23`
Future<void> EventScrWM_MessedEventscr_23(Scene s) async {
}

/// `EventScrWM_MessedEventscr_24`
Future<void> EventScrWM_MessedEventscr_24(Scene s) async {
}

/// `EventScrWM_MessedEventscr_25`
Future<void> EventScrWM_MessedEventscr_25(Scene s) async {
}

/// `EventScrWM_MessedEventscr_26`
Future<void> EventScrWM_MessedEventscr_26(Scene s) async {
}

/// `EventScrWM_MessedEventscr_27`
Future<void> EventScrWM_MessedEventscr_27(Scene s) async {
}

/// `EventScrWM_MessedEventscr_28`
Future<void> EventScrWM_MessedEventscr_28(Scene s) async {
}

/// `EventScrWM_MessedEventscr_29`
Future<void> EventScrWM_MessedEventscr_29(Scene s) async {
}

/// `EventScrWM_MessedEventscr_3`
Future<void> EventScrWM_MessedEventscr_3(Scene s) async {
}

/// `EventScrWM_MessedEventscr_30`
Future<void> EventScrWM_MessedEventscr_30(Scene s) async {
}

/// `EventScrWM_MessedEventscr_31`
Future<void> EventScrWM_MessedEventscr_31(Scene s) async {
}

/// `EventScrWM_MessedEventscr_32`
Future<void> EventScrWM_MessedEventscr_32(Scene s) async {
}

/// `EventScrWM_MessedEventscr_33`
Future<void> EventScrWM_MessedEventscr_33(Scene s) async {
}

/// `EventScrWM_MessedEventscr_34`
Future<void> EventScrWM_MessedEventscr_34(Scene s) async {
}

/// `EventScrWM_MessedEventscr_35`
Future<void> EventScrWM_MessedEventscr_35(Scene s) async {
}

/// `EventScrWM_MessedEventscr_36`
Future<void> EventScrWM_MessedEventscr_36(Scene s) async {
}

/// `EventScrWM_MessedEventscr_37`
Future<void> EventScrWM_MessedEventscr_37(Scene s) async {
}

/// `EventScrWM_MessedEventscr_38`
Future<void> EventScrWM_MessedEventscr_38(Scene s) async {
}

/// `EventScrWM_MessedEventscr_39`
Future<void> EventScrWM_MessedEventscr_39(Scene s) async {
}

/// `EventScrWM_MessedEventscr_4`
Future<void> EventScrWM_MessedEventscr_4(Scene s) async {
}

/// `EventScrWM_MessedEventscr_40`
Future<void> EventScrWM_MessedEventscr_40(Scene s) async {
}

/// `EventScrWM_MessedEventscr_41`
Future<void> EventScrWM_MessedEventscr_41(Scene s) async {
}

/// `EventScrWM_MessedEventscr_42`
Future<void> EventScrWM_MessedEventscr_42(Scene s) async {
}

/// `EventScrWM_MessedEventscr_43`
Future<void> EventScrWM_MessedEventscr_43(Scene s) async {
}

/// `EventScrWM_MessedEventscr_44`
Future<void> EventScrWM_MessedEventscr_44(Scene s) async {
}

/// `EventScrWM_MessedEventscr_45`
Future<void> EventScrWM_MessedEventscr_45(Scene s) async {
}

/// `EventScrWM_MessedEventscr_46`
Future<void> EventScrWM_MessedEventscr_46(Scene s) async {
}

/// `EventScrWM_MessedEventscr_47`
Future<void> EventScrWM_MessedEventscr_47(Scene s) async {
}

/// `EventScrWM_MessedEventscr_48`
Future<void> EventScrWM_MessedEventscr_48(Scene s) async {
}

/// `EventScrWM_MessedEventscr_49`
Future<void> EventScrWM_MessedEventscr_49(Scene s) async {
}

/// `EventScrWM_MessedEventscr_5`
Future<void> EventScrWM_MessedEventscr_5(Scene s) async {
}

/// `EventScrWM_MessedEventscr_50`
Future<void> EventScrWM_MessedEventscr_50(Scene s) async {
}

/// `EventScrWM_MessedEventscr_51`
Future<void> EventScrWM_MessedEventscr_51(Scene s) async {
}

/// `EventScrWM_MessedEventscr_52`
Future<void> EventScrWM_MessedEventscr_52(Scene s) async {
}

/// `EventScrWM_MessedEventscr_53`
Future<void> EventScrWM_MessedEventscr_53(Scene s) async {
}

/// `EventScrWM_MessedEventscr_54`
Future<void> EventScrWM_MessedEventscr_54(Scene s) async {
}

/// `EventScrWM_MessedEventscr_55`
Future<void> EventScrWM_MessedEventscr_55(Scene s) async {
}

/// `EventScrWM_MessedEventscr_56`
Future<void> EventScrWM_MessedEventscr_56(Scene s) async {
}

/// `EventScrWM_MessedEventscr_57`
Future<void> EventScrWM_MessedEventscr_57(Scene s) async {
}

/// `EventScrWM_MessedEventscr_58`
Future<void> EventScrWM_MessedEventscr_58(Scene s) async {
}

/// `EventScrWM_MessedEventscr_6`
Future<void> EventScrWM_MessedEventscr_6(Scene s) async {
}

/// `EventScrWM_MessedEventscr_7`
Future<void> EventScrWM_MessedEventscr_7(Scene s) async {
}

/// `EventScrWM_MessedEventscr_8`
Future<void> EventScrWM_MessedEventscr_8(Scene s) async {
}

/// `EventScrWM_MessedEventscr_9`
Future<void> EventScrWM_MessedEventscr_9(Scene s) async {
}

/// `EventScrWM_Prologue_Beginning`
Future<void> EventScrWM_Prologue_Beginning(Scene s) async {
}

/// `EventScrWM_Prologue_ChapterIntro`
Future<void> EventScrWM_Prologue_ChapterIntro(Scene s) async {
}

/// `EventScrWM_ValniTower1_Beginning`
Future<void> EventScrWM_ValniTower1_Beginning(Scene s) async {
}

/// `EventScrWM_ValniTower2_Beginning`
Future<void> EventScrWM_ValniTower2_Beginning(Scene s) async {
}

/// `EventScrWM_ValniTower3_Beginning`
Future<void> EventScrWM_ValniTower3_Beginning(Scene s) async {
}

/// `EventScrWM_ValniTower4_Beginning`
Future<void> EventScrWM_ValniTower4_Beginning(Scene s) async {
}

/// `EventScrWM_ValniTower5_Beginning`
Future<void> EventScrWM_ValniTower5_Beginning(Scene s) async {
}

/// `EventScrWM_ValniTower6_Beginning`
Future<void> EventScrWM_ValniTower6_Beginning(Scene s) async {
}

/// `EventScrWM_ValniTower7_Beginning`
Future<void> EventScrWM_ValniTower7_Beginning(Scene s) async {
}

/// `EventScrWM_ValniTower8_Beginning`
Future<void> EventScrWM_ValniTower8_Beginning(Scene s) async {
}

/// `EventScr_9EE6A0`
Future<void> scr_9EE6A0(Scene s) async {
    var pc = 0;
    while (true) {
      switch (pc) {
        case 0:
          if (s.slotInt(12) != s.slotInt(3)) { pc = 3; } else { pc = 1; }
          continue;
        case 1:
          await s.call(Sym('EventScr_ChangeAIinQueue'));
          pc = 2;
          continue;
        case 2:
          pc = 6;
          continue;
        case 3:
          pc = 4;
          continue;
        case 4:
          s.slotArith('SADD', 66, 4294902305);
          pc = 5;
          continue;
        case 5:
          s.evBitMod('flag', false, 65535);
          pc = 6;
          continue;
        case 6:
          pc = 7;
          continue;
        case 7:
          return;
        default:
          return;
      }
    }
}

/// `EventScr_9EE6C8`
Future<void> scr_9EE6C8(Scene s) async {
    var pc = 0;
    while (true) {
      switch (pc) {
        case 0:
          s.checkSlotValue('activePid');
          pc = 1;
          continue;
        case 1:
          if (s.slotInt(12) != s.slotInt(3)) { pc = 4; } else { pc = 2; }
          continue;
        case 2:
          await s.call(Sym('EventScr_ChangeAIinQueue'));
          pc = 3;
          continue;
        case 3:
          pc = 7;
          continue;
        case 4:
          pc = 5;
          continue;
        case 5:
          s.slotArith('SADD', 66, 4294902305);
          pc = 6;
          continue;
        case 6:
          s.evBitMod('flag', false, 65535);
          pc = 7;
          continue;
        case 7:
          pc = 8;
          continue;
        case 8:
          return;
        default:
          return;
      }
    }
}

/// `EventScr_9EE84C`
Future<void> scr_9EE84C(Scene s) async {
    var pc = 0;
    while (true) {
      switch (pc) {
        case 0:
          s.placeholder('RANDOMNUMBER');
          pc = 1;
          continue;
        case 1:
          s.setSlot(7, -1);
          pc = 2;
          continue;
        case 2:
          s.setSlot(8, 0);
          pc = 3;
          continue;
        case 3:
          pc = 4;
          continue;
        case 4:
          s.slotQueuePopToSlot(9);
          pc = 5;
          continue;
        case 5:
          s.setSlot(1, 1);
          pc = 6;
          continue;
        case 6:
          s.slotArith('SADD', 7, 7);
          pc = 7;
          continue;
        case 7:
          s.slotArith('SADD', 8, 8);
          pc = 8;
          continue;
        case 8:
          if (s.slotInt(8) <= s.slotInt(12)) { pc = 3; } else { pc = 9; }
          continue;
        case 9:
          s.setSlot(13, 0);
          pc = 10;
          continue;
        case 10:
          s.setSlot(1, 0);
          pc = 11;
          continue;
        case 11:
          s.placeholder('SAVETOQUEUE');
          pc = 12;
          continue;
        case 12:
          s.setSlot(1, 40);
          pc = 13;
          continue;
        case 13:
          s.placeholder('SAVETOQUEUE');
          pc = 14;
          continue;
        case 14:
          s.setSlot(1, 60);
          pc = 15;
          continue;
        case 15:
          s.placeholder('SAVETOQUEUE');
          pc = 16;
          continue;
        case 16:
          s.setSlot(1, 80);
          pc = 17;
          continue;
        case 17:
          s.placeholder('SAVETOQUEUE');
          pc = 18;
          continue;
        case 18:
          s.setSlot(1, 100);
          pc = 19;
          continue;
        case 19:
          s.placeholder('SAVETOQUEUE');
          pc = 20;
          continue;
        case 20:
          pc = 21;
          continue;
        case 21:
          s.setSlot(1, 1);
          pc = 22;
          continue;
        case 22:
          s.slotArith('SSUB', 7, 7);
          pc = 23;
          continue;
        case 23:
          s.slotQueuePopToSlot(2);
          pc = 24;
          continue;
        case 24:
          if (s.slotInt(0) <= s.slotInt(7)) { pc = 20; } else { pc = 25; }
          continue;
        case 25:
          s.placeholder('EvtSetLoadUnitChance');
          pc = 26;
          continue;
        case 26:
          s.setSlot(13, 0);
          pc = 27;
          continue;
        case 27:
          return;
        default:
          return;
      }
    }
}

/// `EventScr_9EE8F0`
Future<void> scr_9EE8F0(Scene s) async {
    var pc = 0;
    while (true) {
      switch (pc) {
        case 0:
          s.checkSlot('flag', 65535);
          pc = 1;
          continue;
        case 1:
          if (s.slotInt(12) != s.slotInt(0)) { pc = 7; } else { pc = 2; }
          continue;
        case 2:
          s.placeholder('ASMC');
          pc = 3;
          continue;
        case 3:
          s.slotArith('SADD', 50, 4294912545);
          pc = 4;
          continue;
        case 4:
          await s.changeChapter(65535, subcmd: 1);
          pc = 5;
          continue;
        case 5:
          s.placeholder('ASMC');
          pc = 6;
          continue;
        case 6:
          s.placeholder('ENDB');
          pc = 7;
          continue;
        case 7:
          pc = 8;
          continue;
        case 8:
          return;
        default:
          return;
      }
    }
}

/// `EventScr_9EEA58`
Future<void> scr_9EEA58(Scene s) async {
    var pc = 0;
    while (true) {
      switch (pc) {
        case 0:
          s.checkSlot('evbit', 8);
          pc = 1;
          continue;
        case 1:
          if (s.slotInt(12) != s.slotInt(0)) { pc = 3; } else { pc = 2; }
          continue;
        case 2:
          await s.fade(FadeDirection.toBlack, 16);
          pc = 3;
          continue;
        case 3:
          pc = 4;
          continue;
        case 4:
          s.hideFaction('blue');
          pc = 5;
          continue;
        case 5:
          s.hideFaction('red');
          pc = 6;
          continue;
        case 6:
          s.hideFaction('green');
          pc = 7;
          continue;
        case 7:
          s.setSlot(11, 0);
          pc = 8;
          continue;
        case 8:
          await s.loadMap(63);
          pc = 9;
          continue;
        case 9:
          await s.fade(FadeDirection.fromBlack, 16);
          pc = 10;
          continue;
        case 10:
          await s.popupText(1524, 8, 8);
          pc = 11;
          continue;
        case 11:
          s.showCursorAt(10, 4);
          pc = 12;
          continue;
        case 12:
          await s.stall(60);
          pc = 13;
          continue;
        case 13:
          await s.endCursor();
          pc = 14;
          continue;
        case 14:
          await s.fade(FadeDirection.toBlack, 16);
          pc = 15;
          continue;
        case 15:
          s.slotArith('SADD', 11, 2);
          pc = 16;
          continue;
        case 16:
          await s.loadMap(27);
          pc = 17;
          continue;
        case 17:
          return;
        default:
          return;
      }
    }
}

/// `EventScr_9EEAAC`
Future<void> scr_9EEAAC(Scene s) async {
    var pc = 0;
    while (true) {
      switch (pc) {
        case 0:
          s.modifyEvBit(3);
          pc = 1;
          continue;
        case 1:
          s.volumeDown(true);
          pc = 2;
          continue;
        case 2:
          s.setTextType(0);
          pc = 3;
          continue;
        case 3:
          s.checkSlot('flag', 65535);
          pc = 4;
          continue;
        case 4:
          if (s.slotInt(12) != s.slotInt(0)) { pc = 11; } else { pc = 5; }
          continue;
        case 5:
          s.evBitMod('flag', true, 65535);
          pc = 6;
          continue;
        case 6:
          s.slotQueuePopToSlot(2);
          pc = 7;
          continue;
        case 7:
          await s.textShow(65535);
          pc = 8;
          continue;
        case 8:
          await s.textEnd();
          pc = 9;
          continue;
        case 9:
          s.slotQueuePopToSlot(2);
          pc = 10;
          continue;
        case 10:
          pc = 16;
          continue;
        case 11:
          pc = 12;
          continue;
        case 12:
          s.slotQueuePopToSlot(2);
          pc = 13;
          continue;
        case 13:
          s.slotQueuePopToSlot(2);
          pc = 14;
          continue;
        case 14:
          await s.textShow(65535);
          pc = 15;
          continue;
        case 15:
          await s.textEnd();
          pc = 16;
          continue;
        case 16:
          pc = 17;
          continue;
        case 17:
          await s.call(Sym('EventScr_9EEB00'));
          pc = 18;
          continue;
        case 18:
          return;
        default:
          return;
      }
    }
}

/// `EventScr_9EEB00`
Future<void> scr_9EEB00(Scene s) async {
    var pc = 0;
    while (true) {
      switch (pc) {
        case 0:
          s.placeholder('CHECK_MONEY');
          pc = 1;
          continue;
        case 1:
          if (s.slotInt(12) < s.slotInt(4)) { pc = 20; } else { pc = 2; }
          continue;
        case 2:
          s.evBitMod('evbit', false, 3);
          pc = 3;
          continue;
        case 3:
          s.slotQueuePopToSlot(2);
          pc = 4;
          continue;
        case 4:
          s.placeholder('EvtTextShow2');
          pc = 5;
          continue;
        case 5:
          await s.textEnd();
          pc = 6;
          continue;
        case 6:
          s.setSlot(7, 1);
          pc = 7;
          continue;
        case 7:
          if (s.slotInt(12) != s.slotInt(7)) { pc = 30; } else { pc = 8; }
          continue;
        case 8:
          s.slotQueuePopToSlot(2);
          pc = 9;
          continue;
        case 9:
          s.sound('override', 48);
          pc = 10;
          continue;
        case 10:
          await s.stall(33);
          pc = 11;
          continue;
        case 11:
          s.placeholder('EvtTextShow2');
          pc = 12;
          continue;
        case 12:
          await s.textEnd();
          pc = 13;
          continue;
        case 13:
          s.textRemoveAll();
          pc = 14;
          continue;
        case 14:
          s.slotArith('SADD', 50, 4294784034);
          pc = 15;
          continue;
        case 15:
          s.placeholder('CHANGESTATE');
          pc = 16;
          continue;
        case 16:
          s.slotArith('SADD', 67, 14114);
          pc = 17;
          continue;
        case 17:
          s.placeholder('EvtGiveMoneymAtSlot3NoPopup');
          pc = 18;
          continue;
        case 18:
          s.restoreBgm(2);
          pc = 19;
          continue;
        case 19:
          pc = 38;
          continue;
        case 20:
          pc = 21;
          continue;
        case 21:
          s.slotQueuePopToSlot(2);
          pc = 22;
          continue;
        case 22:
          s.slotQueuePopToSlot(2);
          pc = 23;
          continue;
        case 23:
          s.slotQueuePopToSlot(2);
          pc = 24;
          continue;
        case 24:
          s.slotQueuePopToSlot(2);
          pc = 25;
          continue;
        case 25:
          s.placeholder('EvtTextShow2');
          pc = 26;
          continue;
        case 26:
          await s.textEnd();
          pc = 27;
          continue;
        case 27:
          s.textRemoveAll();
          pc = 28;
          continue;
        case 28:
          s.volumeDown(false);
          pc = 29;
          continue;
        case 29:
          await s.call(Sym('UnitDef_Ch14BAlly_7', 28));
          pc = 30;
          continue;
        case 30:
          pc = 31;
          continue;
        case 31:
          s.slotQueuePopToSlot(2);
          pc = 32;
          continue;
        case 32:
          s.slotQueuePopToSlot(2);
          pc = 33;
          continue;
        case 33:
          s.placeholder('EvtTextShow2');
          pc = 34;
          continue;
        case 34:
          await s.textEnd();
          pc = 35;
          continue;
        case 35:
          s.textRemoveAll();
          pc = 36;
          continue;
        case 36:
          s.volumeDown(false);
          pc = 37;
          continue;
        case 37:
          await s.call(Sym('UnitDef_Ch14BAlly_7', 28));
          pc = 38;
          continue;
        case 38:
          pc = 39;
          continue;
        case 39:
          s.evBitMod('evbit', true, 7);
          pc = 40;
          continue;
        case 40:
          return;
        default:
          return;
      }
    }
}

/// `EventScr_ApplyActiveUnitTileChange`
Future<void> ApplyActiveUnitTileChange(Scene s) async {
    s.modifyEvBit(1);
    await s.tileChange(65534);
    s.evBitMod('evbit', true, 7);
    return;
}

/// `EventScr_ApplyTileChangeForFaction`
Future<void> ApplyTileChangeForFaction(Scene s) async {
    var pc = 0;
    while (true) {
      switch (pc) {
        case 0:
          s.modifyEvBit(1);
          pc = 1;
          continue;
        case 1:
          s.checkSlot('allegiance', -1);
          pc = 2;
          continue;
        case 2:
          if (s.slotInt(12) != s.slotInt(2)) { pc = 4; } else { pc = 3; }
          continue;
        case 3:
          await s.tileChange(-2);
          pc = 4;
          continue;
        case 4:
          pc = 5;
          continue;
        case 5:
          s.placeholder('NoFade');
          pc = 6;
          continue;
        case 6:
          return;
        default:
          return;
      }
    }
}

/// `EventScr_ApplyTileChangeForFactionIfAlly`
Future<void> ApplyTileChangeForFactionIfAlly(Scene s) async {
    s.setSlot(2, 0);
    await s.call(Sym('EventScr_ApplyTileChangeForFaction'));
    return;
}

/// `EventScr_ApplyTileChangeForFactionIfEnemy`
Future<void> ApplyTileChangeForFactionIfEnemy(Scene s) async {
    s.setSlot(2, 2);
    await s.call(Sym('EventScr_ApplyTileChangeForFaction'));
    return;
}

/// `EventScr_ApplyTileChangeForFactionIfNPC`
Future<void> ApplyTileChangeForFactionIfNPC(Scene s) async {
    s.setSlot(2, 1);
    await s.call(Sym('EventScr_ApplyTileChangeForFaction'));
    return;
}

/// `EventScr_CallBreakStone`
Future<void> CallBreakStone(Scene s) async {
    s.placeholder('STARTFADE');
    s.placeholder('EvtColorFadeSetup');
    await s.stall(30);
    s.placeholder('GLOWINGCROSS');
    s.placeholder('EvtColorFadeSetup');
    return;
}

/// `EventScr_CallIfCommonMode`
Future<void> CallIfCommonMode(Scene s) async {
    var pc = 0;
    while (true) {
      switch (pc) {
        case 0:
          s.checkSlotValue('mode');
          pc = 1;
          continue;
        case 1:
          if (s.slotInt(12) != s.slotInt(2)) { pc = 4; } else { pc = 2; }
          continue;
        case 2:
          s.slotArith('SADD', 2, 3);
          pc = 3;
          continue;
        case 3:
          await s.callSlot(2);
          pc = 4;
          continue;
        case 4:
          pc = 5;
          continue;
        case 5:
          return;
        default:
          return;
      }
    }
}

/// `EventScr_CallOnChapterNumber`
Future<void> CallOnChapterNumber(Scene s) async {
    var pc = 0;
    while (true) {
      switch (pc) {
        case 0:
          s.checkSlotValue('chapter');
          pc = 1;
          continue;
        case 1:
          if (s.slotInt(12) != s.slotInt(3)) { pc = 3; } else { pc = 2; }
          continue;
        case 2:
          await s.callSlot(2);
          pc = 3;
          continue;
        case 3:
          pc = 4;
          continue;
        case 4:
          return;
        default:
          return;
      }
    }
}

/// `EventScr_CallOnHardMode`
Future<void> CallOnHardMode(Scene s) async {
    var pc = 0;
    while (true) {
      switch (pc) {
        case 0:
          s.checkSlotValue('tutorial');
          pc = 1;
          continue;
        case 1:
          if (s.slotInt(12) != s.slotInt(0)) { pc = 5; } else { pc = 2; }
          continue;
        case 2:
          s.checkSlotValue('hard');
          pc = 3;
          continue;
        case 3:
          if (s.slotInt(12) == s.slotInt(0)) { pc = 5; } else { pc = 4; }
          continue;
        case 4:
          await s.callSlot(2);
          pc = 5;
          continue;
        case 5:
          pc = 6;
          continue;
        case 6:
          return;
        default:
          return;
      }
    }
}

/// `EventScr_CallOnTutorialMode`
Future<void> CallOnTutorialMode(Scene s) async {
    var pc = 0;
    while (true) {
      switch (pc) {
        case 0:
          s.checkSlotValue('tutorial');
          pc = 1;
          continue;
        case 1:
          if (s.slotInt(12) == s.slotInt(0)) { pc = 3; } else { pc = 2; }
          continue;
        case 2:
          await s.callSlot(2);
          pc = 3;
          continue;
        case 3:
          pc = 4;
          continue;
        case 4:
          return;
        default:
          return;
      }
    }
}

/// `EventScr_CallWithModeCheck`
Future<void> CallWithModeCheck(Scene s) async {
    var pc = 0;
    while (true) {
      switch (pc) {
        case 0:
          s.checkSlotValue('mode');
          pc = 1;
          continue;
        case 1:
          s.setSlot(7, 1);
          pc = 2;
          continue;
        case 2:
          if (s.slotInt(12) == s.slotInt(7)) { pc = 9; } else { pc = 3; }
          continue;
        case 3:
          s.setSlot(7, 2);
          pc = 4;
          continue;
        case 4:
          if (s.slotInt(12) != s.slotInt(7)) { pc = 7; } else { pc = 5; }
          continue;
        case 5:
          s.slotArith('SADD', 2, 3);
          pc = 6;
          continue;
        case 6:
          pc = 9;
          continue;
        case 7:
          pc = 8;
          continue;
        case 8:
          s.slotArith('SADD', 2, 4);
          pc = 9;
          continue;
        case 9:
          pc = 10;
          continue;
        case 10:
          await s.callSlot(2);
          pc = 11;
          continue;
        case 11:
          return;
        default:
          return;
      }
    }
}

/// `EventScr_Ch10A_0`
Future<void> Ch10A_0(Scene s) async {
    s.cameraToChar(79);
    s.showCursorAtUnit(79);
    await s.stall(60);
    await s.endCursor();
    s.sound('bgm', 20);
    s.setTextType(0);
    await s.textShow(2545);
    await s.textEnd();
    s.textRemoveAll();
    s.showCursorAt(16, 1);
    await s.stall(60);
    await s.endCursor();
    s.volumeDown(true);
    s.setSlot(2, 19);
    s.setSlot(3, 2546);
    await s.call(Sym('Event_TextWithBG'));
    s.volumeDown(false);
    s.evBitMod('evbit', true, 7);
    return;
}

/// `EventScr_Ch10A_10`
Future<void> Ch10A_10(Scene s) async {
    s.volumeDown(true);
    s.setSlot(2, 0);
    s.setSlot(3, 2565);
    await s.call(Sym('Event_TextWithBG'));
    s.volumeDown(false);
    s.evBitMod('evbit', true, 7);
    return;
}

/// `EventScr_Ch10A_11`
Future<void> Ch10A_11(Scene s) async {
    s.volumeDown(true);
    s.setSlot(2, 0);
    s.setSlot(3, 2566);
    await s.call(Sym('Event_TextWithBG'));
    s.volumeDown(false);
    s.evBitMod('evbit', true, 7);
    return;
}

/// `EventScr_Ch10A_12`
Future<void> Ch10A_12(Scene s) async {
    s.setSlot(2, Sym('UnitDef_Ch10AEnemy_2'));
    await s.call(Sym('EventScr_LoadReinforce'));
    s.evBitMod('evbit', true, 7);
    return;
}

/// `EventScr_Ch10A_13`
Future<void> Ch10A_13(Scene s) async {
    s.setSlot(2, 0);
    await s.call(Sym('UnitDef_Ch14BAlly_7'));
    s.evBitMod('flag', false, 14);
    s.setSlot(13, 0);
    s.setSlot(1, 1900557);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 1835022);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 1900559);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 1835024);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 1900561);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 1966094);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 1966096);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 1966098);
    s.slotQueuePushSlot(0x1);
    s.setSlot(2, 65536);
    await s.call(Sym('EventScr_ChangeAIinQueue'));
    s.evBitMod('evbit', true, 7);
    return;
}

/// `EventScr_Ch10A_8`
Future<void> Ch10A_8(Scene s) async {
    var pc = 0;
    while (true) {
      switch (pc) {
        case 0:
          s.checkSlotValue('tutorial');
          pc = 1;
          continue;
        case 1:
          if (s.slotInt(12) != s.slotInt(0)) { pc = 7; } else { pc = 2; }
          continue;
        case 2:
          s.checkSlotValue('hard');
          pc = 3;
          continue;
        case 3:
          if (s.slotInt(12) == s.slotInt(0)) { pc = 7; } else { pc = 4; }
          continue;
        case 4:
          await s.cameraTo(0, 10, centered: false);
          pc = 5;
          continue;
        case 5:
          s.setSlot(2, Sym('UnitDef_Ch10AEnemy_5'));
          pc = 6;
          continue;
        case 6:
          await s.call(Sym('EventScr_LoadReinforceHardMode'));
          pc = 7;
          continue;
        case 7:
          pc = 8;
          continue;
        case 8:
          s.setSlot(2, Sym('UnitDef_Ch10AEnemy_3'));
          pc = 9;
          continue;
        case 9:
          await s.call(Sym('EventScr_LoadReinforce'));
          pc = 10;
          continue;
        case 10:
          s.setSlot(2, Sym('UnitDef_Ch10AEnemy_4'));
          pc = 11;
          continue;
        case 11:
          await s.call(Sym('EventScr_LoadReinforce'));
          pc = 12;
          continue;
        case 12:
          s.evBitMod('evbit', true, 7);
          pc = 13;
          continue;
        case 13:
          return;
        default:
          return;
      }
    }
}

/// `EventScr_Ch10A_9`
Future<void> Ch10A_9(Scene s) async {
    s.volumeDown(true);
    s.setSlot(2, 0);
    s.setSlot(3, 2564);
    await s.call(Sym('Event_TextWithBG'));
    s.volumeDown(false);
    s.evBitMod('evbit', true, 7);
    return;
}

/// `EventScr_Ch10B_0`
Future<void> Ch10B_0(Scene s) async {
    s.sound('bgm', 20);
    await s.cameraTo(15, 11, centered: true);
    await s.stall(15);
    s.loadUnits(1, Sym('frontier_df3_unitdef_b_027_917600', 520));
    await s.waitUnitMoving();
    await s.removeUnit(67);
    s.showCursorAt(19, 11);
    await s.stall(60);
    await s.endCursor();
    s.volumeDown(true);
    s.setSlot(2, 23);
    await s.call(Sym('EventScr_SetBackground'));
    await s.textShow(2682);
    await s.textEnd();
    s.textRemoveAll();
    await s.fade(FadeDirection.toBlack, 16);
    await s.clearScreen();
    await s.removeUnit(68);
    await s.fade(FadeDirection.fromBlack, 16);
    s.loadUnits(1, Sym('frontier_df3_unitdef_b_027_917600', 560));
    await s.waitUnitMoving();
    await s.removeUnit(68);
    s.loadUnits(1, Sym('frontier_df3_unitdef_b_027_917600', 600));
    await s.waitUnitMoving();
    s.loadUnits(1, Sym('frontier_df3_unitdef_b_026_916D14', 1464));
    await s.waitUnitMoving();
    s.showCursorAtUnit(67);
    await s.stall(60);
    await s.endCursor();
    s.setTextType(0);
    await s.textShow(2683);
    await s.textEnd();
    s.textRemoveAll();
    s.volumeDown(false);
    s.moveUnit('MOVE', [16, 67, 23, 14]);
    await s.waitUnitMoving();
    await s.removeUnit(67);
    s.evBitMod('evbit', true, 7);
    return;
}

/// `EventScr_Ch10B_1`
Future<void> Ch10B_1(Scene s) async {
    var pc = 0;
    while (true) {
      switch (pc) {
        case 0:
          s.checkSlot('exists', 14);
          pc = 1;
          continue;
        case 1:
          if (s.slotInt(12) == s.slotInt(0)) { pc = 15; } else { pc = 2; }
          continue;
        case 2:
          s.checkSlot('allegiance', 14);
          pc = 3;
          continue;
        case 3:
          s.setSlot(1, 0);
          pc = 4;
          continue;
        case 4:
          if (s.slotInt(12) == s.slotInt(1)) { pc = 15; } else { pc = 5; }
          continue;
        case 5:
          s.sound('bgm', 20);
          pc = 6;
          continue;
        case 6:
          s.cameraToChar(14);
          pc = 7;
          continue;
        case 7:
          await s.stall(15);
          pc = 8;
          continue;
        case 8:
          s.showCursorAtUnit(14);
          pc = 9;
          continue;
        case 9:
          await s.stall(60);
          pc = 10;
          continue;
        case 10:
          await s.endCursor();
          pc = 11;
          continue;
        case 11:
          s.setTextType(0);
          pc = 12;
          continue;
        case 12:
          await s.textShow(2684);
          pc = 13;
          continue;
        case 13:
          await s.textEnd();
          pc = 14;
          continue;
        case 14:
          s.textRemoveAll();
          pc = 15;
          continue;
        case 15:
          pc = 16;
          continue;
        case 16:
          s.evBitMod('evbit', true, 7);
          pc = 17;
          continue;
        case 17:
          return;
        default:
          return;
      }
    }
}

/// `EventScr_Ch10B_2`
Future<void> Ch10B_2(Scene s) async {
    var pc = 0;
    while (true) {
      switch (pc) {
        case 0:
          s.checkSlot('exists', 14);
          pc = 1;
          continue;
        case 1:
          if (s.slotInt(12) == s.slotInt(0)) { pc = 15; } else { pc = 2; }
          continue;
        case 2:
          s.checkSlot('allegiance', 14);
          pc = 3;
          continue;
        case 3:
          s.setSlot(1, 0);
          pc = 4;
          continue;
        case 4:
          if (s.slotInt(12) == s.slotInt(1)) { pc = 15; } else { pc = 5; }
          continue;
        case 5:
          s.sound('bgm', 20);
          pc = 6;
          continue;
        case 6:
          s.cameraToChar(14);
          pc = 7;
          continue;
        case 7:
          await s.stall(15);
          pc = 8;
          continue;
        case 8:
          s.showCursorAtUnit(14);
          pc = 9;
          continue;
        case 9:
          await s.stall(60);
          pc = 10;
          continue;
        case 10:
          await s.endCursor();
          pc = 11;
          continue;
        case 11:
          s.setTextType(0);
          pc = 12;
          continue;
        case 12:
          await s.textShow(2685);
          pc = 13;
          continue;
        case 13:
          await s.textEnd();
          pc = 14;
          continue;
        case 14:
          s.textRemoveAll();
          pc = 15;
          continue;
        case 15:
          pc = 16;
          continue;
        case 16:
          return;
        default:
          return;
      }
    }
}

/// `EventScr_Ch10a_BeginningScene`
Future<void> Ch10a_BeginningScene(Scene s) async {
    s.sound('bgm', 46);
    s.setSlot(2, 131087);
    await s.call(Sym('EventScr_9EEA58'));
    s.loadUnits(1, Sym('frontier_df4_banim_b_077_90DB94', 52));
    await s.waitUnitMoving();
    await s.fade(FadeDirection.fromBlack, 16);
    s.moveUnit('MOVE_1STEP', [16, 105, 3]);
    await s.waitUnitMoving();
    s.showCursorAtUnit(107);
    await s.stall(60);
    await s.endCursor();
    s.setTextType(0);
    await s.textShow(2540);
    await s.textEnd();
    s.textRemoveAll();
    await s.fade(FadeDirection.toBlack, 16);
    s.hideFaction('blue');
    s.hideFaction('red');
    s.hideFaction('green');
    await s.cameraTo(9, 11, centered: true);
    s.placeholder('UNIT_COLORS');
    s.placeholder('EvtSetLoadUnitNoREDA');
    s.loadUnits(2, Sym('frontier_df4_banim_b_077_90DB94', 212));
    await s.waitUnitMoving();
    s.setSlot(11, 851975);
    await s.tileChange(65535);
    await s.fade(FadeDirection.fromBlack, 16);
    await s.tileChange(0);
    s.loadUnits(2, Sym('frontier_df4_banim_b_077_90DB94', 212));
    await s.waitUnitMoving();
    await s.tileRevert(0);
    s.loadUnits(2, Sym('frontier_df4_banim_b_077_90DB94', 272));
    await s.waitUnitMoving();
    s.showCursorAtUnit(105);
    await s.stall(60);
    await s.endCursor();
    s.setSlot(2, 17);
    s.setSlot(3, 2541);
    await s.call(Sym('Event_TextWithBG'));
    s.loadUnits(2, Sym('frontier_df4_banim_b_077_90DB94', 312));
    await s.waitUnitMoving();
    s.volumeDown(true);
    s.showCursorAtUnit(67);
    await s.stall(60);
    await s.endCursor();
    s.setSlot(2, 17);
    await s.call(Sym('EventScr_SetBackground'));
    await s.textShow(2542);
    await s.textEnd();
    s.textRemoveAll();
    await s.fade(FadeDirection.toBlack, 16);
    s.hideFaction('blue');
    s.hideFaction('red');
    s.hideFaction('green');
    s.placeholder('UNIT_COLORS');
    s.setSlot(11, 1048583);
    await s.loadMap(11);
    s.loadUnits(1, Sym('UnitDef_Ch10ANPC'));
    await s.waitUnitMoving();
    s.loadUnits(1, Sym('UnitDef_Ch10AEnemy_0'));
    await s.waitUnitMoving();
    s.setSlot(2, Sym('UnitDef_Ch10AEnemy_1'));
    s.setSlot(3, 1);
    await s.call(Sym('EventScr_LoadUnitForTutorial'));
    await s.fade(FadeDirection.fromBlack, 16);
    s.showCursorAtUnit(11);
    await s.stall(60);
    await s.endCursor();
    s.sound('bgm', 38);
    s.setSlot(2, 57);
    s.setSlot(3, 2543);
    await s.call(Sym('Event_TextWithBG'));
    await s.cameraTo(0, 0, centered: false);
    s.loadUnits(2, Sym('UnitDef_Ch10AAlly_0'));
    await s.stall(32, cancellable: false);
    s.setSlot(1, 0);
    s.unitStateOp('setState', 1);
    s.setSlot(1, 0);
    s.unitStateOp('setState', 2);
    s.loadUnits(3, Sym('UnitDef_Ch10AAlly_1'));
    await s.waitUnitMoving();
    s.setSlot(1, 4294967295);
    s.unitStateOp('setState', 1);
    s.setSlot(1, 4294967295);
    s.unitStateOp('setState', 2);
    s.showCursorAtUnit(1);
    await s.stall(60);
    await s.endCursor();
    s.setSlot(2, 37);
    await s.call(Sym('EventScr_SetBackground'));
    await s.textShow(2544);
    await s.textEnd();
    s.textRemoveAll();
    await s.call(Sym('data_085B9BBC', 512));
    s.evBitMod('flag', true, 13);
    s.evBitMod('flag', true, 14);
    return;
}

/// `EventScr_Ch10a_EndingScene`
Future<void> Ch10a_EndingScene(Scene s) async {
    var pc = 0;
    while (true) {
      switch (pc) {
        case 0:
          await s.fade(FadeDirection.toBlack, 16);
          pc = 1;
          continue;
        case 1:
          s.setSlot(2, 11);
          pc = 2;
          continue;
        case 2:
          await s.call(Sym('EventScr_LoadUniqueAlly'));
          pc = 3;
          continue;
        case 3:
          s.setSlot(7, 2);
          pc = 4;
          continue;
        case 4:
          s.checkSlot('exists', 20);
          pc = 5;
          continue;
        case 5:
          if (s.slotInt(12) == s.slotInt(0)) { pc = 10; } else { pc = 6; }
          continue;
        case 6:
          s.checkSlot('alive', 20);
          pc = 7;
          continue;
        case 7:
          if (s.slotInt(12) == s.slotInt(0)) { pc = 10; } else { pc = 8; }
          continue;
        case 8:
          s.setSlot(1, 1);
          pc = 9;
          continue;
        case 9:
          s.slotArith('SSUB', 7, 7);
          pc = 10;
          continue;
        case 10:
          pc = 11;
          continue;
        case 11:
          s.checkSlot('exists', 21);
          pc = 12;
          continue;
        case 12:
          if (s.slotInt(12) == s.slotInt(0)) { pc = 17; } else { pc = 13; }
          continue;
        case 13:
          s.checkSlot('alive', 21);
          pc = 14;
          continue;
        case 14:
          if (s.slotInt(12) == s.slotInt(0)) { pc = 17; } else { pc = 15; }
          continue;
        case 15:
          s.setSlot(1, 1);
          pc = 16;
          continue;
        case 16:
          s.slotArith('SSUB', 7, 7);
          pc = 17;
          continue;
        case 17:
          pc = 18;
          continue;
        case 18:
          s.setSlot(2, 20);
          pc = 19;
          continue;
        case 19:
          await s.call(Sym('EventScr_LoadUniqueAlly'));
          pc = 20;
          continue;
        case 20:
          s.setSlot(2, 21);
          pc = 21;
          continue;
        case 21:
          await s.call(Sym('EventScr_LoadUniqueAlly'));
          pc = 22;
          continue;
        case 22:
          if (s.slotInt(7) == s.slotInt(0)) { pc = 33; } else { pc = 23; }
          continue;
        case 23:
          s.setSlot(1, 0);
          pc = 24;
          continue;
        case 24:
          await s.setUnitHpFromSlot(20);
          pc = 25;
          continue;
        case 25:
          s.setSlot(1, 0);
          pc = 26;
          continue;
        case 26:
          await s.setUnitHpFromSlot(21);
          pc = 27;
          continue;
        case 27:
          s.setSlot(1, 0);
          pc = 28;
          continue;
        case 28:
          s.unitStateOp('setState', 20);
          pc = 29;
          continue;
        case 29:
          s.setSlot(1, 0);
          pc = 30;
          continue;
        case 30:
          s.unitStateOp('setState', 21);
          pc = 31;
          continue;
        case 31:
          s.unitStateOp('remu', 20);
          pc = 32;
          continue;
        case 32:
          s.unitStateOp('remu', 21);
          pc = 33;
          continue;
        case 33:
          pc = 34;
          continue;
        case 34:
          s.setSlot(2, 22);
          pc = 35;
          continue;
        case 35:
          await s.call(Sym('EventScr_StrictLoadUniqueAlly'));
          pc = 36;
          continue;
        case 36:
          s.hideFaction('blue');
          pc = 37;
          continue;
        case 37:
          s.hideFaction('red');
          pc = 38;
          continue;
        case 38:
          s.hideFaction('green');
          pc = 39;
          continue;
        case 39:
          s.sound('bgm', 46);
          pc = 40;
          continue;
        case 40:
          await s.cameraTo(0, 30, centered: false);
          pc = 41;
          continue;
        case 41:
          await s.fade(FadeDirection.fromBlack, 16);
          pc = 42;
          continue;
        case 42:
          s.loadUnits(1, Sym('UnitDef_Ch10AEnemy_6'));
          pc = 43;
          continue;
        case 43:
          await s.waitUnitMoving();
          pc = 44;
          continue;
        case 44:
          s.showCursorAtUnit(67);
          pc = 45;
          continue;
        case 45:
          await s.stall(60);
          pc = 46;
          continue;
        case 46:
          await s.endCursor();
          pc = 47;
          continue;
        case 47:
          s.setSlot(2, 37);
          pc = 48;
          continue;
        case 48:
          s.setSlot(3, 2551);
          pc = 49;
          continue;
        case 49:
          await s.call(Sym('Event_TextWithBG'));
          pc = 50;
          continue;
        case 50:
          s.moveUnit('MOVE', [16, 67, 3, 30]);
          pc = 51;
          continue;
        case 51:
          s.setSlot(11, 1769474);
          pc = 52;
          continue;
        case 52:
          await s.stall(32, cancellable: false);
          pc = 53;
          continue;
        case 53:
          s.moveUnit('MOVE', [16, 65534, 2, 30]);
          pc = 54;
          continue;
        case 54:
          s.setSlot(11, 1769476);
          pc = 55;
          continue;
        case 55:
          s.moveUnit('MOVE', [16, 65534, 4, 30]);
          pc = 56;
          continue;
        case 56:
          await s.fade(FadeDirection.toBlack, 16);
          pc = 57;
          continue;
        case 57:
          s.placeholder('EvtBgmFadeIn');
          pc = 58;
          continue;
        case 58:
          await s.waitUnitMoving();
          pc = 59;
          continue;
        case 59:
          s.hideFaction('blue');
          pc = 60;
          continue;
        case 60:
          s.hideFaction('red');
          pc = 61;
          continue;
        case 61:
          s.hideFaction('green');
          pc = 62;
          continue;
        case 62:
          await s.cameraTo(19, 0, centered: false);
          pc = 63;
          continue;
        case 63:
          await s.fade(FadeDirection.fromBlack, 16);
          pc = 64;
          continue;
        case 64:
          s.showCursorAt(15, 1);
          pc = 65;
          continue;
        case 65:
          await s.stall(60);
          pc = 66;
          continue;
        case 66:
          await s.endCursor();
          pc = 67;
          continue;
        case 67:
          s.setSlot(2, 19);
          pc = 68;
          continue;
        case 68:
          await s.call(Sym('EventScr_SetBackground'));
          pc = 69;
          continue;
        case 69:
          s.sound('bgm', 49);
          pc = 70;
          continue;
        case 70:
          await s.textShow(2552);
          pc = 71;
          continue;
        case 71:
          await s.textEnd();
          pc = 72;
          continue;
        case 72:
          s.textRemoveAll();
          pc = 73;
          continue;
        case 73:
          if (s.slotInt(7) != s.slotInt(0)) { pc = 79; } else { pc = 74; }
          continue;
        case 74:
          s.setSlot(2, 21);
          pc = 75;
          continue;
        case 75:
          await s.call(Sym('EventScr_SetBackground'));
          pc = 76;
          continue;
        case 76:
          await s.textShow(2553);
          pc = 77;
          continue;
        case 77:
          await s.textEnd();
          pc = 78;
          continue;
        case 78:
          s.textRemoveAll();
          pc = 79;
          continue;
        case 79:
          pc = 80;
          continue;
        case 80:
          s.setSlot(2, 2);
          pc = 81;
          continue;
        case 81:
          await s.call(Sym('EventScr_SetBackground'));
          pc = 82;
          continue;
        case 82:
          s.checkSlot('alive', 21);
          pc = 83;
          continue;
        case 83:
          if (s.slotInt(12) == s.slotInt(0)) { pc = 95; } else { pc = 84; }
          continue;
        case 84:
          s.volumeDown(true);
          pc = 85;
          continue;
        case 85:
          await s.textShow(2554);
          pc = 86;
          continue;
        case 86:
          await s.textEnd();
          pc = 87;
          continue;
        case 87:
          s.textRemoveAll();
          pc = 88;
          continue;
        case 88:
          s.setSlot(2, 37);
          pc = 89;
          continue;
        case 89:
          await s.call(Sym('EventScr_SetBackground'));
          pc = 90;
          continue;
        case 90:
          await s.textShow(2555);
          pc = 91;
          continue;
        case 91:
          await s.textEnd();
          pc = 92;
          continue;
        case 92:
          s.textRemoveAll();
          pc = 93;
          continue;
        case 93:
          s.volumeDown(false);
          pc = 94;
          continue;
        case 94:
          pc = 99;
          continue;
        case 95:
          pc = 96;
          continue;
        case 96:
          await s.textShow(2556);
          pc = 97;
          continue;
        case 97:
          await s.textEnd();
          pc = 98;
          continue;
        case 98:
          s.textRemoveAll();
          pc = 99;
          continue;
        case 99:
          pc = 100;
          continue;
        case 100:
          await s.fade(FadeDirection.toBlack, 16);
          pc = 101;
          continue;
        case 101:
          s.evBitMod('flag', true, 114);
          pc = 102;
          continue;
        case 102:
          await s.changeChapter(61, subcmd: 1);
          pc = 103;
          continue;
        case 103:
          return;
        default:
          return;
      }
    }
}

/// `EventScr_Ch11B_0`
Future<void> Ch11B_0(Scene s) async {
    s.sound('bgm', 17);
    s.cameraToChar(15);
    s.showCursorAtUnit(15);
    await s.stall(60);
    await s.endCursor();
    s.setSlot(2, 13);
    await s.call(Sym('EventScr_SetBackground'));
    await s.textShow(2707);
    await s.textEnd();
    s.textRemoveAll();
    await s.fade(FadeDirection.toBlack, 16);
    await s.tileRevert(0);
    await s.tileChange(1);
    await s.clearScreen();
    await s.cameraTo(9, 9, centered: true);
    s.setTextType(0);
    s.loadUnits(1, Sym('UnitDef_Ch11BEnemy_1'));
    await s.waitUnitMoving();
    s.loadUnits(1, Sym('UnitDef_Ch11BEnemy_2'));
    await s.waitUnitMoving();
    await s.fade(FadeDirection.fromBlack, 16);
    s.evBitMod('evbit', true, 7);
    return;
}

/// `EventScr_Ch11B_1`
Future<void> Ch11B_1(Scene s) async {
    s.sound('bgm', 17);
    await s.cameraTo(9, 9, centered: true);
    s.placeholder('EARTHQUAKE_START');
    await s.stall(30);
    await s.tileChange(2);
    await s.stall(30);
    s.placeholder('EARTHQUAKE_END');
    s.cameraToChar(15);
    s.showCursorAtUnit(15);
    await s.stall(60);
    await s.endCursor();
    s.setTextType(0);
    await s.textShow(2708);
    await s.textEnd();
    s.textRemoveAll();
    s.evBitMod('evbit', true, 7);
    return;
}

/// `EventScr_Ch11B_2`
Future<void> Ch11B_2(Scene s) async {
    s.sound('bgm', 17);
    s.cameraToChar(15);
    s.showCursorAtUnit(15);
    await s.stall(60);
    await s.endCursor();
    s.setSlot(2, 13);
    await s.call(Sym('EventScr_SetBackground'));
    await s.textShow(2709);
    await s.textEnd();
    s.textRemoveAll();
    await s.fade(FadeDirection.toBlack, 16);
    await s.tileChange(3);
    await s.clearScreen();
    await s.cameraTo(12, 10, centered: true);
    s.setTextType(0);
    s.placeholder('EARTHQUAKE_START');
    await s.fade(FadeDirection.fromBlack, 16);
    await s.stall(32);
    s.placeholder('EARTHQUAKE_END');
    s.loadUnits(1, Sym('frontier_df3_unitdef_b_029_9184F0'));
    await s.waitUnitMoving();
    s.showCursorAtUnit(25);
    await s.stall(60);
    await s.endCursor();
    s.setTextType(0);
    await s.textShow(2710);
    await s.textEnd();
    s.textRemoveAll();
    s.evBitMod('evbit', true, 7);
    return;
}

/// `EventScr_Ch11B_6`
Future<void> Ch11B_6(Scene s) async {
    s.setSlot(2, Sym('UnitDef_Ch11BEnemy_4'));
    await s.call(Sym('EventScr_LoadReinforce'));
    s.setSlot(2, Sym('frontier_df3_unitdef_b_030_918784', 120));
    await s.call(Sym('EventScr_LoadReinforceHardMode'));
    s.setSlot(2, Sym('frontier_df3_unitdef_b_030_918784', 180));
    await s.call(Sym('EventScr_LoadReinforceHardMode'));
    s.setSlot(2, Sym('frontier_df3_unitdef_b_030_918784', 240));
    await s.call(Sym('EventScr_LoadReinforceHardMode'));
    s.evBitMod('evbit', true, 7);
    return;
}

/// `EventScr_Ch11a_BeginningScene`
Future<void> Ch11a_BeginningScene(Scene s) async {
    var pc = 0;
    while (true) {
      switch (pc) {
        case 0:
          s.sound('bgm', 77);
          pc = 1;
          continue;
        case 1:
          s.loadUnits(2, Sym('UnitDef_Ch11AAlly_0'));
          pc = 2;
          continue;
        case 2:
          await s.waitUnitMoving();
          pc = 3;
          continue;
        case 3:
          s.displayCursorAtUnit(24);
          pc = 4;
          continue;
        case 4:
          await s.stall(60);
          pc = 5;
          continue;
        case 5:
          await s.endCursor();
          pc = 6;
          continue;
        case 6:
          s.setSlot(2, 39);
          pc = 7;
          continue;
        case 7:
          await s.call(Sym('EventScr_SetBackground'));
          pc = 8;
          continue;
        case 8:
          await s.textShow(2567);
          pc = 9;
          continue;
        case 9:
          await s.textEnd();
          pc = 10;
          continue;
        case 10:
          s.placeholder('BGMCHANGE_13');
          pc = 11;
          continue;
        case 11:
          await s.continueText();
          pc = 12;
          continue;
        case 12:
          await s.textEnd();
          pc = 13;
          continue;
        case 13:
          s.sound('bgm', 37);
          pc = 14;
          continue;
        case 14:
          await s.continueText();
          pc = 15;
          continue;
        case 15:
          await s.textEnd();
          pc = 16;
          continue;
        case 16:
          s.textRemoveAll();
          pc = 17;
          continue;
        case 17:
          await s.call(Sym('EventScr_TextShowWithFadeIn'));
          pc = 18;
          continue;
        case 18:
          s.checkSlot('alive', 21);
          pc = 19;
          continue;
        case 19:
          if (s.slotInt(12) == s.slotInt(0)) { pc = 27; } else { pc = 20; }
          continue;
        case 20:
          s.displayCursorAtUnit(21);
          pc = 21;
          continue;
        case 21:
          await s.stall(60);
          pc = 22;
          continue;
        case 22:
          await s.endCursor();
          pc = 23;
          continue;
        case 23:
          s.setSlot(2, 39);
          pc = 24;
          continue;
        case 24:
          s.setSlot(3, 2568);
          pc = 25;
          continue;
        case 25:
          await s.call(Sym('Event_TextWithBG'));
          pc = 26;
          continue;
        case 26:
          pc = 36;
          continue;
        case 27:
          pc = 28;
          continue;
        case 28:
          s.moveUnit('MOVEUNIT', [0]);
          pc = 29;
          continue;
        case 29:
          await s.waitUnitMoving();
          pc = 30;
          continue;
        case 30:
          s.displayCursorAtUnit(11);
          pc = 31;
          continue;
        case 31:
          await s.stall(60);
          pc = 32;
          continue;
        case 32:
          await s.endCursor();
          pc = 33;
          continue;
        case 33:
          s.setSlot(2, 39);
          pc = 34;
          continue;
        case 34:
          s.setSlot(3, 2569);
          pc = 35;
          continue;
        case 35:
          await s.call(Sym('Event_TextWithBG'));
          pc = 36;
          continue;
        case 36:
          pc = 37;
          continue;
        case 37:
          s.setSlot(13, 0);
          pc = 38;
          continue;
        case 38:
          s.setSlot(1, 134);
          pc = 39;
          continue;
        case 39:
          s.slotQueuePushSlot(0x1);
          pc = 40;
          continue;
        case 40:
          s.setSlot(1, 0);
          pc = 41;
          continue;
        case 41:
          s.slotQueuePushSlot(0x1);
          pc = 42;
          continue;
        case 42:
          s.setSlot(1, 133);
          pc = 43;
          continue;
        case 43:
          s.slotQueuePushSlot(0x1);
          pc = 44;
          continue;
        case 44:
          s.setSlot(1, 0);
          pc = 45;
          continue;
        case 45:
          s.slotQueuePushSlot(0x1);
          pc = 46;
          continue;
        case 46:
          s.setSlot(1, 5);
          pc = 47;
          continue;
        case 47:
          s.slotQueuePushSlot(0x1);
          pc = 48;
          continue;
        case 48:
          s.setSlot(1, 0);
          pc = 49;
          continue;
        case 49:
          s.slotQueuePushSlot(0x1);
          pc = 50;
          continue;
        case 50:
          s.moveUnit('MOVEUNIT', [0]);
          pc = 51;
          continue;
        case 51:
          await s.waitUnitMoving();
          pc = 52;
          continue;
        case 52:
          await s.removeUnit(24);
          pc = 53;
          continue;
        case 53:
          await s.fade(FadeDirection.toBlack, 16);
          pc = 54;
          continue;
        case 54:
          s.hideFaction('blue');
          pc = 55;
          continue;
        case 55:
          await s.cameraTo(12, 13, centered: true);
          pc = 56;
          continue;
        case 56:
          await s.fade(FadeDirection.fromBlack, 16);
          pc = 57;
          continue;
        case 57:
          s.loadUnits(1, Sym('frontier_df4_banim_b_077_90DB94', 1708));
          pc = 58;
          continue;
        case 58:
          await s.waitUnitMoving();
          pc = 59;
          continue;
        case 59:
          s.displayCursorAtUnit(25);
          pc = 60;
          continue;
        case 60:
          await s.stall(60);
          pc = 61;
          continue;
        case 61:
          await s.endCursor();
          pc = 62;
          continue;
        case 62:
          s.setSlot(2, 59);
          pc = 63;
          continue;
        case 63:
          await s.call(Sym('EventScr_SetBackground'));
          pc = 64;
          continue;
        case 64:
          await s.textShow(2570);
          pc = 65;
          continue;
        case 65:
          await s.textEnd();
          pc = 66;
          continue;
        case 66:
          s.textRemoveAll();
          pc = 67;
          continue;
        case 67:
          await s.fade(FadeDirection.toBlack, 16);
          pc = 68;
          continue;
        case 68:
          s.loadUnits(1, Sym('frontier_df4_banim_b_077_90DB94', 868));
          pc = 69;
          continue;
        case 69:
          await s.waitUnitMoving();
          pc = 70;
          continue;
        case 70:
          await s.call(Sym('data_085B9BBC', 512));
          pc = 71;
          continue;
        case 71:
          return;
        default:
          return;
      }
    }
}

/// `EventScr_Ch11a_EndingScene`
Future<void> Ch11a_EndingScene(Scene s) async {
    var pc = 0;
    while (true) {
      switch (pc) {
        case 0:
          s.sound('bgm', 49);
          pc = 1;
          continue;
        case 1:
          s.setSlot(2, 59);
          pc = 2;
          continue;
        case 2:
          await s.call(Sym('EventScr_SetBackground'));
          pc = 3;
          continue;
        case 3:
          s.checkSlot('alive', 25);
          pc = 4;
          continue;
        case 4:
          if (s.slotInt(12) == s.slotInt(0)) { pc = 8; } else { pc = 5; }
          continue;
        case 5:
          await s.textShow(2571);
          pc = 6;
          continue;
        case 6:
          await s.textEnd();
          pc = 7;
          continue;
        case 7:
          pc = 11;
          continue;
        case 8:
          pc = 9;
          continue;
        case 9:
          await s.textShow(2572);
          pc = 10;
          continue;
        case 10:
          await s.textEnd();
          pc = 11;
          continue;
        case 11:
          pc = 12;
          continue;
        case 12:
          await s.fade(FadeDirection.toBlack, 4);
          pc = 13;
          continue;
        case 13:
          s.textRemoveAll();
          pc = 14;
          continue;
        case 14:
          await s.fade(FadeDirection.fromBlack, 4);
          pc = 15;
          continue;
        case 15:
          await s.textShow(2573);
          pc = 16;
          continue;
        case 16:
          await s.textEnd();
          pc = 17;
          continue;
        case 17:
          s.checkSlot('alive', 26);
          pc = 18;
          continue;
        case 18:
          if (s.slotInt(12) == s.slotInt(0)) { pc = 21; } else { pc = 19; }
          continue;
        case 19:
          s.placeholder('EvtTextShow2');
          pc = 20;
          continue;
        case 20:
          await s.textEnd();
          pc = 21;
          continue;
        case 21:
          pc = 22;
          continue;
        case 22:
          s.textRemoveAll();
          pc = 23;
          continue;
        case 23:
          s.placeholder('EvtBgmFadeIn');
          pc = 24;
          continue;
        case 24:
          await s.fade(FadeDirection.toBlack, 16);
          pc = 25;
          continue;
        case 25:
          s.setSlot(2, 25);
          pc = 26;
          continue;
        case 26:
          await s.call(Sym('EventScr_LoadUniqueAlly'));
          pc = 27;
          continue;
        case 27:
          s.setSlot(2, 26);
          pc = 28;
          continue;
        case 28:
          await s.call(Sym('EventScr_LoadUniqueAlly'));
          pc = 29;
          continue;
        case 29:
          s.hideFaction('blue');
          pc = 30;
          continue;
        case 30:
          s.hideFaction('red');
          pc = 31;
          continue;
        case 31:
          s.hideFaction('green');
          pc = 32;
          continue;
        case 32:
          s.setSlot(11, 655360);
          pc = 33;
          continue;
        case 33:
          await s.loadMap(65);
          pc = 34;
          continue;
        case 34:
          s.placeholder('EvtChangeFogVision');
          pc = 35;
          continue;
        case 35:
          s.sound('bgm', 74);
          pc = 36;
          continue;
        case 36:
          await s.fade(FadeDirection.fromBlack, 16);
          pc = 37;
          continue;
        case 37:
          s.loadUnits(2, Sym('frontier_df4_banim_b_078_90E58C'));
          pc = 38;
          continue;
        case 38:
          await s.waitUnitMoving();
          pc = 39;
          continue;
        case 39:
          await s.removeUnit(24);
          pc = 40;
          continue;
        case 40:
          await s.stall(30);
          pc = 41;
          continue;
        case 41:
          s.showCursorAt(2, 6);
          pc = 42;
          continue;
        case 42:
          await s.stall(60);
          pc = 43;
          continue;
        case 43:
          await s.endCursor();
          pc = 44;
          continue;
        case 44:
          s.setSlot(2, 1);
          pc = 45;
          continue;
        case 45:
          await s.call(Sym('EventScr_SetBackground'));
          pc = 46;
          continue;
        case 46:
          s.volumeDown(true);
          pc = 47;
          continue;
        case 47:
          await s.textShow(2575);
          pc = 48;
          continue;
        case 48:
          await s.textEnd();
          pc = 49;
          continue;
        case 49:
          s.textRemoveAll();
          pc = 50;
          continue;
        case 50:
          s.placeholder('EvtBgmFadeIn');
          pc = 51;
          continue;
        case 51:
          await s.fade(FadeDirection.toBlack, 2);
          pc = 52;
          continue;
        case 52:
          await s.clearScreen();
          pc = 53;
          continue;
        case 53:
          s.placeholder('EvtSetLoadUnitNoREDA');
          pc = 54;
          continue;
        case 54:
          s.loadUnits(2, Sym('UnitDef_Ch11AMixed'));
          pc = 55;
          continue;
        case 55:
          await s.waitUnitMoving();
          pc = 56;
          continue;
        case 56:
          await s.removeUnit(105);
          pc = 57;
          continue;
        case 57:
          await s.removeUnit(128);
          pc = 58;
          continue;
        case 58:
          await s.removeUnit(129);
          pc = 59;
          continue;
        case 59:
          await s.fade(FadeDirection.fromBlack, 2);
          pc = 60;
          continue;
        case 60:
          s.loadUnits(2, Sym('UnitDef_Ch11AMixed'));
          pc = 61;
          continue;
        case 61:
          await s.waitUnitMoving();
          pc = 62;
          continue;
        case 62:
          s.showCursorAtUnit(105);
          pc = 63;
          continue;
        case 63:
          await s.stall(60);
          pc = 64;
          continue;
        case 64:
          await s.endCursor();
          pc = 65;
          continue;
        case 65:
          s.sound('bgm', 46);
          pc = 66;
          continue;
        case 66:
          s.setSlot(2, 37);
          pc = 67;
          continue;
        case 67:
          await s.call(Sym('EventScr_SetBackground'));
          pc = 68;
          continue;
        case 68:
          await s.textShow(2576);
          pc = 69;
          continue;
        case 69:
          await s.textEnd();
          pc = 70;
          continue;
        case 70:
          s.sound('bgm', 40);
          pc = 71;
          continue;
        case 71:
          await s.continueText();
          pc = 72;
          continue;
        case 72:
          await s.textEnd();
          pc = 73;
          continue;
        case 73:
          s.textRemoveAll();
          pc = 74;
          continue;
        case 74:
          await s.call(Sym('EventScr_TextShowWithFadeIn'));
          pc = 75;
          continue;
        case 75:
          s.moveUnit('MOVE', [0, 23, 13, 0]);
          pc = 76;
          continue;
        case 76:
          await s.waitUnitMoving();
          pc = 77;
          continue;
        case 77:
          s.moveUnit('MOVE', [16, 11, 13, 0]);
          pc = 78;
          continue;
        case 78:
          s.moveUnit('MOVE', [16, 25, 13, 0]);
          pc = 79;
          continue;
        case 79:
          s.moveUnit('MOVE', [16, 2, 13, 0]);
          pc = 80;
          continue;
        case 80:
          s.moveUnit('MOVE', [16, 1, 13, 0]);
          pc = 81;
          continue;
        case 81:
          await s.waitUnitMoving();
          pc = 82;
          continue;
        case 82:
          s.moveUnit('MOVE', [16, 105, 8, 5]);
          pc = 83;
          continue;
        case 83:
          s.moveUnit('MOVE', [16, 128, 7, 4]);
          pc = 84;
          continue;
        case 84:
          s.moveUnit('MOVE', [16, 129, 9, 4]);
          pc = 85;
          continue;
        case 85:
          s.loadUnits(1, Sym('UnitDef_Ch11AEnemy_5'));
          pc = 86;
          continue;
        case 86:
          await s.waitUnitMoving();
          pc = 87;
          continue;
        case 87:
          await s.waitUnitMoving();
          pc = 88;
          continue;
        case 88:
          s.showCursorAtUnit(67);
          pc = 89;
          continue;
        case 89:
          await s.stall(60);
          pc = 90;
          continue;
        case 90:
          await s.endCursor();
          pc = 91;
          continue;
        case 91:
          s.sound('bgm', 46);
          pc = 92;
          continue;
        case 92:
          s.setSlot(2, 37);
          pc = 93;
          continue;
        case 93:
          await s.call(Sym('EventScr_SetBackground'));
          pc = 94;
          continue;
        case 94:
          await s.textShow(2577);
          pc = 95;
          continue;
        case 95:
          await s.textEnd();
          pc = 96;
          continue;
        case 96:
          s.sound('bgm', 38);
          pc = 97;
          continue;
        case 97:
          await s.continueText();
          pc = 98;
          continue;
        case 98:
          await s.textEnd();
          pc = 99;
          continue;
        case 99:
          s.textRemoveAll();
          pc = 100;
          continue;
        case 100:
          await s.call(Sym('EventScr_TextShowWithFadeIn'));
          pc = 101;
          continue;
        case 101:
          s.moveUnit('MOVE_1STEP', [0, 67, 3]);
          pc = 102;
          continue;
        case 102:
          await s.waitUnitMoving();
          pc = 103;
          continue;
        case 103:
          s.setSlot(13, 0);
          pc = 104;
          continue;
        case 104:
          s.setSlot(1, 1);
          pc = 105;
          continue;
        case 105:
          s.slotQueuePushSlot(0x1);
          pc = 106;
          continue;
        case 106:
          s.setSlot(1, 131072);
          pc = 107;
          continue;
        case 107:
          s.slotQueuePushSlot(0x1);
          pc = 108;
          continue;
        case 108:
          s.setSlot(1, 91137);
          pc = 109;
          continue;
        case 109:
          s.slotQueuePushSlot(0x1);
          pc = 110;
          continue;
        case 110:
          s.setSlot(1, 4294967295);
          pc = 111;
          continue;
        case 111:
          s.slotQueuePushSlot(0x1);
          pc = 112;
          continue;
        case 112:
          s.placeholder('FIGHT');
          pc = 113;
          continue;
        case 113:
          s.placeholder('KILL');
          pc = 114;
          continue;
        case 114:
          await s.removeUnit(105, onlyIfDead: true);
          pc = 115;
          continue;
        case 115:
          s.showCursorAtUnit(67);
          pc = 116;
          continue;
        case 116:
          await s.stall(60);
          pc = 117;
          continue;
        case 117:
          await s.endCursor();
          pc = 118;
          continue;
        case 118:
          s.setTextType(0);
          pc = 119;
          continue;
        case 119:
          await s.textShow(2579);
          pc = 120;
          continue;
        case 120:
          await s.textEnd();
          pc = 121;
          continue;
        case 121:
          s.textRemoveAll();
          pc = 122;
          continue;
        case 122:
          s.setSlot(13, 0);
          pc = 123;
          continue;
        case 123:
          s.setSlot(1, 131207);
          pc = 124;
          continue;
        case 124:
          s.slotQueuePushSlot(0x1);
          pc = 125;
          continue;
        case 125:
          s.setSlot(1, 0);
          pc = 126;
          continue;
        case 126:
          s.slotQueuePushSlot(0x1);
          pc = 127;
          continue;
        case 127:
          s.setSlot(1, 131203);
          pc = 128;
          continue;
        case 128:
          s.slotQueuePushSlot(0x1);
          pc = 129;
          continue;
        case 129:
          s.setSlot(1, 0);
          pc = 130;
          continue;
        case 130:
          s.slotQueuePushSlot(0x1);
          pc = 131;
          continue;
        case 131:
          s.setSlot(1, 131075);
          pc = 132;
          continue;
        case 132:
          s.slotQueuePushSlot(0x1);
          pc = 133;
          continue;
        case 133:
          s.setSlot(1, 0);
          pc = 134;
          continue;
        case 134:
          s.slotQueuePushSlot(0x1);
          pc = 135;
          continue;
        case 135:
          s.moveUnit('MOVE_DEFINED', [128]);
          pc = 136;
          continue;
        case 136:
          s.setSlot(13, 0);
          pc = 137;
          continue;
        case 137:
          s.setSlot(1, 131329);
          pc = 138;
          continue;
        case 138:
          s.slotQueuePushSlot(0x1);
          pc = 139;
          continue;
        case 139:
          s.setSlot(1, 0);
          pc = 140;
          continue;
        case 140:
          s.slotQueuePushSlot(0x1);
          pc = 141;
          continue;
        case 141:
          s.setSlot(1, 131073);
          pc = 142;
          continue;
        case 142:
          s.slotQueuePushSlot(0x1);
          pc = 143;
          continue;
        case 143:
          s.setSlot(1, 0);
          pc = 144;
          continue;
        case 144:
          s.slotQueuePushSlot(0x1);
          pc = 145;
          continue;
        case 145:
          s.moveUnit('MOVE_DEFINED', [129]);
          pc = 146;
          continue;
        case 146:
          await s.stall(15, cancellable: false);
          pc = 147;
          continue;
        case 147:
          s.setSlot(13, 0);
          pc = 148;
          continue;
        case 148:
          s.setSlot(1, 131206);
          pc = 149;
          continue;
        case 149:
          s.slotQueuePushSlot(0x1);
          pc = 150;
          continue;
        case 150:
          s.setSlot(1, 0);
          pc = 151;
          continue;
        case 151:
          s.slotQueuePushSlot(0x1);
          pc = 152;
          continue;
        case 152:
          s.setSlot(1, 131203);
          pc = 153;
          continue;
        case 153:
          s.slotQueuePushSlot(0x1);
          pc = 154;
          continue;
        case 154:
          s.setSlot(1, 0);
          pc = 155;
          continue;
        case 155:
          s.slotQueuePushSlot(0x1);
          pc = 156;
          continue;
        case 156:
          s.setSlot(1, 131075);
          pc = 157;
          continue;
        case 157:
          s.slotQueuePushSlot(0x1);
          pc = 158;
          continue;
        case 158:
          s.setSlot(1, 0);
          pc = 159;
          continue;
        case 159:
          s.slotQueuePushSlot(0x1);
          pc = 160;
          continue;
        case 160:
          s.moveUnit('MOVE_DEFINED', [102]);
          pc = 161;
          continue;
        case 161:
          s.setSlot(13, 0);
          pc = 162;
          continue;
        case 162:
          s.setSlot(1, 131329);
          pc = 163;
          continue;
        case 163:
          s.slotQueuePushSlot(0x1);
          pc = 164;
          continue;
        case 164:
          s.setSlot(1, 0);
          pc = 165;
          continue;
        case 165:
          s.slotQueuePushSlot(0x1);
          pc = 166;
          continue;
        case 166:
          s.setSlot(1, 131073);
          pc = 167;
          continue;
        case 167:
          s.slotQueuePushSlot(0x1);
          pc = 168;
          continue;
        case 168:
          s.setSlot(1, 0);
          pc = 169;
          continue;
        case 169:
          s.slotQueuePushSlot(0x1);
          pc = 170;
          continue;
        case 170:
          s.moveUnit('MOVE_DEFINED', [103]);
          pc = 171;
          continue;
        case 171:
          await s.waitUnitMoving();
          pc = 172;
          continue;
        case 172:
          s.showCursorAtUnit(67);
          pc = 173;
          continue;
        case 173:
          await s.stall(60);
          pc = 174;
          continue;
        case 174:
          await s.endCursor();
          pc = 175;
          continue;
        case 175:
          s.setTextType(0);
          pc = 176;
          continue;
        case 176:
          await s.textShow(2580);
          pc = 177;
          continue;
        case 177:
          await s.textEnd();
          pc = 178;
          continue;
        case 178:
          s.textRemoveAll();
          pc = 179;
          continue;
        case 179:
          s.evBitMod('flag', true, 115);
          pc = 180;
          continue;
        case 180:
          await s.changeChapter(12, subcmd: 2);
          pc = 181;
          continue;
        case 181:
          return;
        default:
          return;
      }
    }
}

/// `EventScr_Ch12A_0`
Future<void> Ch12A_0(Scene s) async {
    s.volumeDown(true);
    s.setSlot(2, 1);
    s.setSlot(3, 2596);
    await s.call(Sym('Event_TextWithBG'));
    s.volumeDown(false);
    await s.call(Sym('data_085B9BBC', 360));
    s.setSlot(3, 89);
    await s.giveItem(65535, 3);
    await s.tileChange(2);
    s.evBitMod('evbit', true, 7);
    return;
}

/// `EventScr_Ch12A_1`
Future<void> Ch12A_1(Scene s) async {
    var pc = 0;
    while (true) {
      switch (pc) {
        case 0:
          s.sound('override', 48);
          pc = 1;
          continue;
        case 1:
          await s.stall(33);
          pc = 2;
          continue;
        case 2:
          pc = 3;
          continue;
        case 3:
          s.checkSlotValue('activePid');
          pc = 4;
          continue;
        case 4:
          s.setSlot(7, 1);
          pc = 5;
          continue;
        case 5:
          if (s.slotInt(12) == s.slotInt(7)) { pc = 14; } else { pc = 6; }
          continue;
        case 6:
          s.setSlot(7, 23);
          pc = 7;
          continue;
        case 7:
          if (s.slotInt(12) == s.slotInt(7)) { pc = 19; } else { pc = 8; }
          continue;
        case 8:
          s.setSlot(7, 21);
          pc = 9;
          continue;
        case 9:
          if (s.slotInt(12) == s.slotInt(7)) { pc = 24; } else { pc = 10; }
          continue;
        case 10:
          s.setSlot(2, 1);
          pc = 11;
          continue;
        case 11:
          s.setSlot(3, 2600);
          pc = 12;
          continue;
        case 12:
          await s.call(Sym('Event_TextWithBG'));
          pc = 13;
          continue;
        case 13:
          pc = 28;
          continue;
        case 14:
          pc = 15;
          continue;
        case 15:
          s.setSlot(2, 1);
          pc = 16;
          continue;
        case 16:
          s.setSlot(3, 2597);
          pc = 17;
          continue;
        case 17:
          await s.call(Sym('Event_TextWithBG'));
          pc = 18;
          continue;
        case 18:
          pc = 28;
          continue;
        case 19:
          pc = 20;
          continue;
        case 20:
          s.setSlot(2, 1);
          pc = 21;
          continue;
        case 21:
          s.setSlot(3, 2598);
          pc = 22;
          continue;
        case 22:
          await s.call(Sym('Event_TextWithBG'));
          pc = 23;
          continue;
        case 23:
          pc = 28;
          continue;
        case 24:
          pc = 25;
          continue;
        case 25:
          s.setSlot(2, 1);
          pc = 26;
          continue;
        case 26:
          s.setSlot(3, 2599);
          pc = 27;
          continue;
        case 27:
          await s.call(Sym('Event_TextWithBG'));
          pc = 28;
          continue;
        case 28:
          pc = 29;
          continue;
        case 29:
          s.loadUnits(1, Sym('UnitDef_Ch12AAlly_0'));
          pc = 30;
          continue;
        case 30:
          await s.waitUnitMoving();
          pc = 31;
          continue;
        case 31:
          await s.tileChange(3);
          pc = 32;
          continue;
        case 32:
          s.restoreBgm(2);
          pc = 33;
          continue;
        case 33:
          s.evBitMod('evbit', true, 7);
          pc = 34;
          continue;
        case 34:
          return;
        default:
          return;
      }
    }
}

/// `EventScr_Ch12A_2`
Future<void> Ch12A_2(Scene s) async {
    s.setSlot(2, 0);
    await s.call(Sym('UnitDef_Ch14BAlly_7'));
    s.evBitMod('flag', false, 7);
    s.evBitMod('evbit', true, 7);
    return;
}

/// `EventScr_Ch12A_3`
Future<void> Ch12A_3(Scene s) async {
    s.setSlot(2, Sym('UnitDef_Ch12AEnemy_2'));
    await s.call(Sym('EventScr_LoadReinforce'));
    s.setSlot(2, Sym('UnitDef_Ch12AEnemy_7'));
    await s.call(Sym('EventScr_LoadReinforceHardMode'));
    s.evBitMod('evbit', true, 7);
    return;
}

/// `EventScr_Ch12A_4`
Future<void> Ch12A_4(Scene s) async {
    s.setSlot(2, 0);
    await s.call(Sym('UnitDef_Ch14BAlly_7'));
    s.evBitMod('flag', false, 8);
    s.evBitMod('evbit', true, 7);
    return;
}

/// `EventScr_Ch12A_5`
Future<void> Ch12A_5(Scene s) async {
    s.setSlot(2, Sym('UnitDef_Ch12AEnemy_5'));
    await s.call(Sym('EventScr_LoadReinforce'));
    s.setSlot(2, Sym('UnitDef_Ch12AEnemy_8'));
    await s.call(Sym('EventScr_LoadReinforceHardMode'));
    s.setSlot(2, Sym('UnitDef_Ch12AEnemy_6'));
    await s.call(Sym('EventScr_LoadReinforce'));
    s.setSlot(2, Sym('UnitDef_Ch12AEnemy_3'));
    await s.call(Sym('EventScr_LoadReinforce'));
    s.evBitMod('evbit', true, 7);
    return;
}

/// `EventScr_Ch12B_1`
Future<void> Ch12B_1(Scene s) async {
    s.cameraToChar(83);
    s.placeholder('SPAWN_ENEMY');
    s.setSlot(2, 87);
    s.moveUnit('MOVE_CLOSEST', [65535, 65533, 17, 1]);
    await s.call(Sym('EventScr_UnitWarpIN'));
    s.showCursorAtUnit(83);
    await s.stall(60);
    await s.endCursor();
    s.setTextType(0);
    await s.textShow(2722);
    await s.textEnd();
    s.textRemoveAll();
    s.setSlot(2, 87);
    await s.call(Sym('EventScr_UnitWarpOUT'));
    await s.removeUnit(87);
    s.moveUnit('MOVE', [24, 83, 17, 0]);
    await s.waitUnitMoving();
    await s.removeUnit(83);
    s.moveUnit('MOVE', [24, 129, 16, 0]);
    s.moveUnit('MOVE', [24, 130, 18, 0]);
    await s.waitUnitMoving();
    await s.removeUnit(129);
    await s.removeUnit(130);
    s.setSlot(2, Sym('UnitDef_Ch12BEnemy_1'));
    await s.call(Sym('EventScr_LoadReinforce'));
    await s.stall(30, cancellable: false);
    s.setSlot(2, Sym('UnitDef_Ch12BEnemy_2'));
    await s.call(Sym('EventScr_LoadReinforce'));
    await s.stall(30, cancellable: false);
    s.setSlot(2, Sym('frontier_df3_unitdef_b_032_91908C'));
    await s.call(Sym('EventScr_LoadReinforce'));
    await s.stall(30, cancellable: false);
    s.setSlot(2, Sym('UnitDef_Ch12BEnemy_4'));
    await s.call(Sym('EventScr_LoadReinforce'));
    await s.stall(30, cancellable: false);
    s.cameraToChar(15);
    s.showCursorAtUnit(15);
    await s.stall(60);
    await s.endCursor();
    s.setTextType(0);
    await s.textShow(2723);
    await s.textEnd();
    s.textRemoveAll();
    s.evBitMod('evbit', true, 7);
    return;
}

/// `EventScr_Ch13A_3`
Future<void> Ch13A_3(Scene s) async {
    s.sound('bgm', 20);
    s.setSlot(2, Sym('UnitDef_Ch13AEnemy_3'));
    await s.call(Sym('EventScr_LoadReinforce'));
    s.setSlot(2, Sym('UnitDef_Ch13AEnemy_4'));
    await s.call(Sym('EventScr_LoadReinforceHardMode'));
    s.showCursorAtUnit(79);
    await s.stall(60);
    await s.endCursor();
    s.setTextType(0);
    await s.textShow(2607);
    await s.textEnd();
    s.textRemoveAll();
    s.evBitMod('evbit', true, 7);
    return;
}

/// `EventScr_Ch13A_4`
Future<void> Ch13A_4(Scene s) async {
    var pc = 0;
    while (true) {
      switch (pc) {
        case 0:
          s.checkSlotValue('turn');
          pc = 1;
          continue;
        case 1:
          s.setSlot(1, 1);
          pc = 2;
          continue;
        case 2:
          s.slotArith('SAND', 12, 12);
          pc = 3;
          continue;
        case 3:
          if (s.slotInt(12) == s.slotInt(0)) { pc = 8; } else { pc = 4; }
          continue;
        case 4:
          s.setSlot(2, Sym('UnitDef_Ch13AEnemy_5'));
          pc = 5;
          continue;
        case 5:
          await s.call(Sym('EventScr_LoadReinforce'));
          pc = 6;
          continue;
        case 6:
          s.setSlot(2, Sym('UnitDef_Ch13AEnemy_6'));
          pc = 7;
          continue;
        case 7:
          await s.call(Sym('EventScr_LoadReinforce'));
          pc = 8;
          continue;
        case 8:
          pc = 9;
          continue;
        case 9:
          s.evBitMod('evbit', true, 7);
          pc = 10;
          continue;
        case 10:
          return;
        default:
          return;
      }
    }
}

/// `EventScr_Ch13A_5`
Future<void> Ch13A_5(Scene s) async {
    s.setSlot(2, Sym('UnitDef_Ch13AEnemy_7'));
    await s.call(Sym('EventScr_LoadReinforce'));
    s.evBitMod('evbit', true, 7);
    return;
}

/// `EventScr_Ch13A_6`
Future<void> Ch13A_6(Scene s) async {
    s.setSlot(2, Sym('UnitDef_Ch13AEnemy_8'));
    await s.call(Sym('EventScr_LoadReinforce'));
    s.evBitMod('evbit', true, 7);
    return;
}

/// `EventScr_Ch13A_7`
Future<void> Ch13A_7(Scene s) async {
    s.sound('bgm', 20);
    s.setSlot(2, Sym('UnitDef_Ch13AEnemy_9'));
    await s.call(Sym('EventScr_LoadReinforce'));
    s.displayCursorAtUnit(14);
    await s.stall(60);
    await s.endCursor();
    s.setTextType(0);
    await s.textShow(2608);
    await s.textEnd();
    s.textRemoveAll();
    s.evBitMod('evbit', true, 7);
    return;
}

/// `EventScr_Ch13B_0`
Future<void> Ch13B_0(Scene s) async {
    var pc = 0;
    while (true) {
      switch (pc) {
        case 0:
          s.checkSlot('flag', 2);
          pc = 1;
          continue;
        case 1:
          if (s.slotInt(12) != s.slotInt(0)) { pc = 12; } else { pc = 2; }
          continue;
        case 2:
          s.setSlot(2, 0);
          pc = 3;
          continue;
        case 3:
          await s.call(Sym('UnitDef_Ch14BAlly_7'));
          pc = 4;
          continue;
        case 4:
          s.setSlot(2, 15);
          pc = 5;
          continue;
        case 5:
          await s.call(Sym('EventScr_UnTriggerIfNotUnit'));
          pc = 6;
          continue;
        case 6:
          s.volumeDown(true);
          pc = 7;
          continue;
        case 7:
          s.setTextType(0);
          pc = 8;
          continue;
        case 8:
          await s.textShow(2740);
          pc = 9;
          continue;
        case 9:
          await s.textEnd();
          pc = 10;
          continue;
        case 10:
          s.textRemoveAll();
          pc = 11;
          continue;
        case 11:
          s.volumeDown(false);
          pc = 12;
          continue;
        case 12:
          pc = 13;
          continue;
        case 13:
          s.evBitMod('evbit', true, 7);
          pc = 14;
          continue;
        case 14:
          return;
        default:
          return;
      }
    }
}

/// `EventScr_Ch13B_1`
Future<void> Ch13B_1(Scene s) async {
    var pc = 0;
    while (true) {
      switch (pc) {
        case 0:
          s.checkSlot('flag', 2);
          pc = 1;
          continue;
        case 1:
          if (s.slotInt(12) != s.slotInt(0)) { pc = 12; } else { pc = 2; }
          continue;
        case 2:
          s.setSlot(2, 0);
          pc = 3;
          continue;
        case 3:
          await s.call(Sym('UnitDef_Ch14BAlly_7'));
          pc = 4;
          continue;
        case 4:
          s.setSlot(2, 29);
          pc = 5;
          continue;
        case 5:
          await s.call(Sym('EventScr_UnTriggerIfNotUnit'));
          pc = 6;
          continue;
        case 6:
          s.volumeDown(true);
          pc = 7;
          continue;
        case 7:
          s.setTextType(0);
          pc = 8;
          continue;
        case 8:
          await s.textShow(2741);
          pc = 9;
          continue;
        case 9:
          await s.textEnd();
          pc = 10;
          continue;
        case 10:
          s.textRemoveAll();
          pc = 11;
          continue;
        case 11:
          s.volumeDown(false);
          pc = 12;
          continue;
        case 12:
          pc = 13;
          continue;
        case 13:
          s.evBitMod('evbit', true, 7);
          pc = 14;
          continue;
        case 14:
          return;
        default:
          return;
      }
    }
}

/// `EventScr_Ch13a_EndingScene`
Future<void> Ch13a_EndingScene(Scene s) async {
    var pc = 0;
    while (true) {
      switch (pc) {
        case 0:
          s.checkSlot('flag', 2);
          pc = 1;
          continue;
        case 1:
          if (s.slotInt(12) != s.slotInt(0)) { pc = 11; } else { pc = 2; }
          continue;
        case 2:
          s.cameraToChar(81);
          pc = 3;
          continue;
        case 3:
          s.showCursorAtUnit(81);
          pc = 4;
          continue;
        case 4:
          await s.stall(60);
          pc = 5;
          continue;
        case 5:
          await s.endCursor();
          pc = 6;
          continue;
        case 6:
          s.setSlot(2, 35);
          pc = 7;
          continue;
        case 7:
          await s.call(Sym('EventScr_SetBackground'));
          pc = 8;
          continue;
        case 8:
          await s.textShow(2614);
          pc = 9;
          continue;
        case 9:
          await s.textEnd();
          pc = 10;
          continue;
        case 10:
          pc = 16;
          continue;
        case 11:
          pc = 12;
          continue;
        case 12:
          s.setSlot(2, 35);
          pc = 13;
          continue;
        case 13:
          await s.call(Sym('EventScr_SetBackground'));
          pc = 14;
          continue;
        case 14:
          await s.textShow(2615);
          pc = 15;
          continue;
        case 15:
          await s.textEnd();
          pc = 16;
          continue;
        case 16:
          pc = 17;
          continue;
        case 17:
          s.textRemoveAll();
          pc = 18;
          continue;
        case 18:
          await s.fade(FadeDirection.toBlack, 16);
          pc = 19;
          continue;
        case 19:
          s.hideFaction('red');
          pc = 20;
          continue;
        case 20:
          await s.clearScreen();
          pc = 21;
          continue;
        case 21:
          await s.cameraTo(23, 0, centered: false);
          pc = 22;
          continue;
        case 22:
          await s.fade(FadeDirection.fromBlack, 16);
          pc = 23;
          continue;
        case 23:
          s.loadUnits(1, Sym('UnitDef_Ch13ANPC'));
          pc = 24;
          continue;
        case 24:
          await s.waitUnitMoving();
          pc = 25;
          continue;
        case 25:
          s.showCursorAtUnit(200);
          pc = 26;
          continue;
        case 26:
          await s.stall(60);
          pc = 27;
          continue;
        case 27:
          await s.endCursor();
          pc = 28;
          continue;
        case 28:
          s.sound('bgm', 15);
          pc = 29;
          continue;
        case 29:
          s.setTextType(0);
          pc = 30;
          continue;
        case 30:
          await s.textShow(2616);
          pc = 31;
          continue;
        case 31:
          await s.textEnd();
          pc = 32;
          continue;
        case 32:
          s.textRemoveAll();
          pc = 33;
          continue;
        case 33:
          s.cameraToChar(1);
          pc = 34;
          continue;
        case 34:
          s.showCursorAtUnit(1);
          pc = 35;
          continue;
        case 35:
          await s.stall(60);
          pc = 36;
          continue;
        case 36:
          await s.endCursor();
          pc = 37;
          continue;
        case 37:
          s.setSlot(2, 35);
          pc = 38;
          continue;
        case 38:
          await s.call(Sym('EventScr_SetBackground'));
          pc = 39;
          continue;
        case 39:
          await s.textShow(2617);
          pc = 40;
          continue;
        case 40:
          await s.textEnd();
          pc = 41;
          continue;
        case 41:
          s.textRemoveAll();
          pc = 42;
          continue;
        case 42:
          await s.fade(FadeDirection.toBlack, 16);
          pc = 43;
          continue;
        case 43:
          s.setSlot(2, 35);
          pc = 44;
          continue;
        case 44:
          await s.call(Sym('EventScr_SetBackground'));
          pc = 45;
          continue;
        case 45:
          s.sound('override', 49);
          pc = 46;
          continue;
        case 46:
          await s.stall(33);
          pc = 47;
          continue;
        case 47:
          s.checkSlot('alive', 26);
          pc = 48;
          continue;
        case 48:
          if (s.slotInt(12) == s.slotInt(0)) { pc = 64; } else { pc = 49; }
          continue;
        case 49:
          await s.textShow(2618);
          pc = 50;
          continue;
        case 50:
          await s.textEnd();
          pc = 51;
          continue;
        case 51:
          s.textRemoveAll();
          pc = 52;
          continue;
        case 52:
          await s.call(Sym('data_085B9BBC', 360));
          pc = 53;
          continue;
        case 53:
          s.setSlot(3, 5000);
          pc = 54;
          continue;
        case 54:
          await s.giveItem(0, 3);
          pc = 55;
          continue;
        case 55:
          await s.textShow(2619);
          pc = 56;
          continue;
        case 56:
          await s.textEnd();
          pc = 57;
          continue;
        case 57:
          s.placeholder('EvtBgmFadeIn');
          pc = 58;
          continue;
        case 58:
          await s.continueText();
          pc = 59;
          continue;
        case 59:
          await s.textEnd();
          pc = 60;
          continue;
        case 60:
          s.sound('bgm', 38);
          pc = 61;
          continue;
        case 61:
          await s.continueText();
          pc = 62;
          continue;
        case 62:
          await s.textEnd();
          pc = 63;
          continue;
        case 63:
          pc = 79;
          continue;
        case 64:
          pc = 65;
          continue;
        case 65:
          await s.textShow(2620);
          pc = 66;
          continue;
        case 66:
          await s.textEnd();
          pc = 67;
          continue;
        case 67:
          s.textRemoveAll();
          pc = 68;
          continue;
        case 68:
          await s.call(Sym('data_085B9BBC', 360));
          pc = 69;
          continue;
        case 69:
          s.setSlot(3, 5000);
          pc = 70;
          continue;
        case 70:
          await s.giveItem(0, 3);
          pc = 71;
          continue;
        case 71:
          await s.textShow(2621);
          pc = 72;
          continue;
        case 72:
          await s.textEnd();
          pc = 73;
          continue;
        case 73:
          s.placeholder('EvtBgmFadeIn');
          pc = 74;
          continue;
        case 74:
          await s.continueText();
          pc = 75;
          continue;
        case 75:
          await s.textEnd();
          pc = 76;
          continue;
        case 76:
          s.sound('bgm', 38);
          pc = 77;
          continue;
        case 77:
          await s.continueText();
          pc = 78;
          continue;
        case 78:
          await s.textEnd();
          pc = 79;
          continue;
        case 79:
          pc = 80;
          continue;
        case 80:
          s.textRemoveAll();
          pc = 81;
          continue;
        case 81:
          await s.fade(FadeDirection.toBlack, 4);
          pc = 82;
          continue;
        case 82:
          s.hideFaction('blue');
          pc = 83;
          continue;
        case 83:
          s.hideFaction('red');
          pc = 84;
          continue;
        case 84:
          s.hideFaction('green');
          pc = 85;
          continue;
        case 85:
          s.checkSlot('flag', 2);
          pc = 86;
          continue;
        case 86:
          if (s.slotInt(12) != s.slotInt(0)) { pc = 111; } else { pc = 87; }
          continue;
        case 87:
          s.setSlot(11, 0);
          pc = 88;
          continue;
        case 88:
          await s.loadMap(15);
          pc = 89;
          continue;
        case 89:
          s.loadUnits(1, Sym('frontier_df3_unitdef_b_000_90F678', 2368));
          pc = 90;
          continue;
        case 90:
          await s.waitUnitMoving();
          pc = 91;
          continue;
        case 91:
          await s.fade(FadeDirection.fromBlack, 4);
          pc = 92;
          continue;
        case 92:
          s.loadUnits(1, Sym('frontier_df3_unitdef_b_000_90F678', 2408));
          pc = 93;
          continue;
        case 93:
          await s.waitUnitMoving();
          pc = 94;
          continue;
        case 94:
          s.setSlot(1, 5);
          pc = 95;
          continue;
        case 95:
          await s.setUnitHpFromSlot(81);
          pc = 96;
          continue;
        case 96:
          s.showCursorAtUnit(83);
          pc = 97;
          continue;
        case 97:
          await s.stall(60);
          pc = 98;
          continue;
        case 98:
          await s.endCursor();
          pc = 99;
          continue;
        case 99:
          s.setSlot(2, 73);
          pc = 100;
          continue;
        case 100:
          await s.call(Sym('EventScr_SetBackground'));
          pc = 101;
          continue;
        case 101:
          s.sound('bgm', 46);
          pc = 102;
          continue;
        case 102:
          await s.textShow(2622);
          pc = 103;
          continue;
        case 103:
          await s.textEnd();
          pc = 104;
          continue;
        case 104:
          s.textRemoveAll();
          pc = 105;
          continue;
        case 105:
          await s.call(Sym('EventScr_TextShowWithFadeIn'));
          pc = 106;
          continue;
        case 106:
          s.setSlot(13, 0);
          pc = 107;
          continue;
        case 107:
          s.setSlot(1, 65536);
          pc = 108;
          continue;
        case 108:
          s.slotQueuePushSlot(0x1);
          pc = 109;
          continue;
        case 109:
          s.placeholder('FIGHT_MAP');
          pc = 110;
          continue;
        case 110:
          await s.fade(FadeDirection.toBlack, 4);
          pc = 111;
          continue;
        case 111:
          pc = 112;
          continue;
        case 112:
          s.evBitMod('flag', true, 117);
          pc = 113;
          continue;
        case 113:
          await s.changeChapter(14, subcmd: 1);
          pc = 114;
          continue;
        case 114:
          return;
        default:
          return;
      }
    }
}

/// `EventScr_Ch13b_EndingScene`
Future<void> Ch13b_EndingScene(Scene s) async {
    s.placeholder('EvtBgmFadeIn');
    await s.fade(FadeDirection.toBlack, 16);
    s.hideFaction('blue');
    s.hideFaction('red');
    s.hideFaction('green');
    await s.cameraTo(14, 13, centered: true);
    s.placeholder('EvtSetLoadUnitNoREDA');
    s.loadUnits(2, Sym('frontier_df3_unitdef_b_033_9191E0', 1964));
    await s.waitUnitMoving();
    await s.fade(FadeDirection.fromBlack, 16);
    s.loadUnits(2, Sym('frontier_df3_unitdef_b_033_9191E0', 1964));
    await s.waitUnitMoving();
    s.showCursorAtUnit(30);
    await s.stall(60);
    await s.endCursor();
    s.sound('bgm', 50);
    s.setSlot(2, 44);
    await s.call(Sym('EventScr_SetBackground'));
    await s.textShow(2739);
    await s.textEnd();
    s.textRemoveAll();
    await s.fade(FadeDirection.toBlack, 16);
    s.hideFaction('blue');
    s.hideFaction('red');
    s.hideFaction('green');
    s.evBitMod('flag', true, 117);
    await s.changeChapter(27, subcmd: 1);
    return;
}

/// `EventScr_Ch14A_0`
Future<void> Ch14A_0(Scene s) async {
    await s.cameraTo(9, 7, centered: true);
    s.loadUnits(1, Sym('frontier_df3_unitdef_b_003_91066C_residue'));
    await s.waitUnitMoving();
    s.showCursorAtUnit(83);
    await s.stall(60);
    await s.endCursor();
    s.sound('bgm', 38);
    s.setTextType(0);
    await s.textShow(2630);
    await s.textEnd();
    s.textRemoveAll();
    s.moveUnit('MOVEONTO', [0, 83, 203]);
    await s.waitUnitMoving();
    s.moveUnit('MOVE_1STEP', [8, 203, 2]);
    s.moveUnit('MOVE_1STEP', [0, 82, 1]);
    await s.waitUnitMoving();
    s.showCursorAtUnit(83);
    await s.stall(60);
    await s.endCursor();
    s.setTextType(0);
    await s.textShow(2631);
    await s.textEnd();
    s.textRemoveAll();
    s.moveUnit('MOVE_1STEP', [0, 82, 0]);
    await s.waitUnitMoving();
    s.moveUnit('MOVEONTO', [0, 83, 203]);
    await s.waitUnitMoving();
    await s.removeUnit(203);
    await s.stall(16);
    s.moveUnit('MOVE', [0, 83, 9, 8]);
    await s.waitUnitMoving();
    s.showCursorAtUnit(83);
    await s.stall(60);
    await s.endCursor();
    s.setTextType(0);
    await s.textShow(2632);
    await s.textEnd();
    s.textRemoveAll();
    s.moveUnit('MOVEONTO', [0, 83, 64]);
    await s.waitUnitMoving();
    await s.removeUnit(64);
    s.moveUnit('MOVE', [0, 83, 17, 11]);
    await s.waitUnitMoving();
    await s.removeUnit(83);
    await s.cameraTo(9, 6, centered: true);
    s.moveUnit('MOVE', [0, 82, 9, 5]);
    s.loadUnits(1, Sym('UnitDef_Ch14AEnemy_6'));
    await s.waitUnitMoving();
    s.evBitMod('evbit', true, 7);
    return;
}

/// `EventScr_Ch14A_1`
Future<void> Ch14A_1(Scene s) async {
    s.setSlot(2, 9);
    s.setSlot(3, 28);
    s.setSlot(4, 9980);
    s.setSlot(13, 0);
    s.setSlot(1, 2649);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 2650);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 2652);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 2653);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 2654);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 2651);
    s.slotQueuePushSlot(0x1);
    await s.call(Sym('EventScr_9EEAAC'));
    return;
}

/// `EventScr_Ch14A_2`
Future<void> Ch14A_2(Scene s) async {
    s.setSlot(2, Sym('frontier_df3_unitdef_b_001_91020C', 860));
    await s.call(Sym('EventScr_LoadReinforce'));
    s.evBitMod('evbit', true, 7);
    return;
}

/// `EventScr_Ch14A_3`
Future<void> Ch14A_3(Scene s) async {
    s.setSlot(2, Sym('UnitDef_Ch14AEnemy_4'));
    await s.call(Sym('EventScr_LoadReinforce'));
    s.evBitMod('evbit', true, 7);
    return;
}

/// `EventScr_Ch14A_4`
Future<void> Ch14A_4(Scene s) async {
    s.setSlot(2, 0);
    await s.call(Sym('UnitDef_Ch14BAlly_7'));
    s.evBitMod('flag', false, 12);
    s.evBitMod('evbit', true, 7);
    return;
}

/// `EventScr_Ch14A_5`
Future<void> Ch14A_5(Scene s) async {
    s.setSlot(2, Sym('UnitDef_Ch14AEnemy_2'));
    await s.call(Sym('EventScr_LoadReinforce'));
    s.evBitMod('evbit', true, 7);
    return;
}

/// `EventScr_Ch14A_6`
Future<void> Ch14A_6(Scene s) async {
    s.setSlot(2, 0);
    await s.call(Sym('UnitDef_Ch14BAlly_7'));
    s.counterSet(0, 0);
    s.evBitMod('flag', false, 14);
    s.evBitMod('evbit', true, 7);
    return;
}

/// `EventScr_Ch14A_7`
Future<void> Ch14A_7(Scene s) async {
    var pc = 0;
    while (true) {
      switch (pc) {
        case 0:
          s.setSlot(2, Sym('frontier_df3_unitdef_b_002_9105E0'));
          pc = 1;
          continue;
        case 1:
          await s.call(Sym('EventScr_LoadReinforce'));
          pc = 2;
          continue;
        case 2:
          s.counterDec(0);
          pc = 3;
          continue;
        case 3:
          s.evBitMod('flag', false, 14);
          pc = 4;
          continue;
        case 4:
          s.counterCheck(0);
          pc = 5;
          continue;
        case 5:
          if (s.slotInt(12) != s.slotInt(0)) { pc = 7; } else { pc = 6; }
          continue;
        case 6:
          s.evBitMod('flag', true, 14);
          pc = 7;
          continue;
        case 7:
          pc = 8;
          continue;
        case 8:
          s.evBitMod('evbit', true, 7);
          pc = 9;
          continue;
        case 9:
          return;
        default:
          return;
      }
    }
}

/// `EventScr_Ch14A_8`
Future<void> Ch14A_8(Scene s) async {
    s.setSlot(2, 0);
    await s.call(Sym('UnitDef_Ch14BAlly_7'));
    s.setSlot(13, 0);
    s.setSlot(1, 458760);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 458761);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 458762);
    s.slotQueuePushSlot(0x1);
    s.setSlot(2, 65536);
    await s.call(Sym('EventScr_ChangeAIinQueue'));
    s.evBitMod('evbit', true, 7);
    return;
}

/// `EventScr_Ch14B_12`
Future<void> Ch14B_12(Scene s) async {
    var pc = 0;
    while (true) {
      switch (pc) {
        case 0:
          s.setSlot(2, Sym('UnitDef_Ch14BEnemy_8'));
          pc = 1;
          continue;
        case 1:
          await s.call(Sym('EventScr_LoadReinforceHardMode'));
          pc = 2;
          continue;
        case 2:
          s.setSlot(2, Sym('UnitDef_Ch14BEnemy_9'));
          pc = 3;
          continue;
        case 3:
          await s.call(Sym('EventScr_LoadReinforceHardMode'));
          pc = 4;
          continue;
        case 4:
          s.counterDec(1);
          pc = 5;
          continue;
        case 5:
          s.evBitMod('flag', false, 16);
          pc = 6;
          continue;
        case 6:
          s.counterCheck(1);
          pc = 7;
          continue;
        case 7:
          if (s.slotInt(12) != s.slotInt(0)) { pc = 9; } else { pc = 8; }
          continue;
        case 8:
          s.evBitMod('flag', true, 16);
          pc = 9;
          continue;
        case 9:
          pc = 10;
          continue;
        case 10:
          s.evBitMod('evbit', true, 7);
          pc = 11;
          continue;
        case 11:
          return;
        default:
          return;
      }
    }
}

/// `EventScr_Ch14B_2`
Future<void> Ch14B_2(Scene s) async {
    s.setSlot(2, 10);
    s.setSlot(3, 28);
    s.setSlot(4, 9980);
    s.setSlot(13, 0);
    s.setSlot(1, 2770);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 2771);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 2773);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 2774);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 2775);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 2772);
    s.slotQueuePushSlot(0x1);
    await s.call(Sym('EventScr_9EEAAC'));
    return;
}

/// `EventScr_Ch14a_BeginningScene`
Future<void> Ch14a_BeginningScene(Scene s) async {
    s.setTextType(1);
    s.showTextBg(79);
    await s.fade(FadeDirection.fromBlack, 128);
    await s.fade(FadeDirection.toWhite, 2);
    s.showTextBg(26);
    s.placeholder('BGMCHANGE_13');
    await s.fade(FadeDirection.fromWhite, 2);
    await s.popupText(407, 8, 8);
    await s.textShow(2626);
    await s.textEnd();
    s.placeholder('BGMCHANGE_13');
    await s.fade(FadeDirection.toWhite, 2);
    s.textRemoveAll();
    s.setSlot(11, 262158);
    await s.loadMap(15);
    s.sound('bgm', 78);
    await s.fade(FadeDirection.fromWhite, 2);
    s.loadUnits(2, Sym('frontier_df3_unitdef_b_004_91075C_p5'));
    await s.waitUnitMoving();
    s.displayCursorAtUnit(2);
    await s.stall(60);
    await s.endCursor();
    s.setSlot(2, 73);
    await s.call(Sym('EventScr_SetBackground'));
    await s.textShow(2627);
    await s.textEnd();
    s.sound('bgm', 37);
    await s.continueText();
    await s.textEnd();
    s.textRemoveAll();
    await s.call(Sym('EventScr_TextShowWithFadeIn'));
    s.moveUnit('MOVE_CLOSEST', [16, 1, 1033]);
    s.moveUnit('MOVE_CLOSEST', [16, 2, 1033]);
    s.moveUnit('MOVE_CLOSEST', [16, 11, 1033]);
    s.moveUnit('MOVE_CLOSEST', [16, 25, 1033]);
    await s.stall(20, cancellable: false);
    await s.fade(FadeDirection.toBlack, 16);
    await s.waitUnitMoving();
    s.hideFaction('blue');
    s.hideFaction('red');
    s.hideFaction('green');
    s.setSlot(11, 458762);
    await s.loadMap(14);
    s.loadUnits(1, Sym('frontier_df3_unitdef_b_001_91020C'));
    await s.waitUnitMoving();
    s.moveUnit('MOVE_CLOSEST', [65535, 82, 1801]);
    s.loadUnits(1, Sym('frontier_df3_unitdef_b_003_91066C'));
    await s.waitUnitMoving();
    await s.fade(FadeDirection.fromBlack, 16);
    s.moveUnit('MOVEUNIT', [16]);
    await s.waitUnitMoving();
    s.displayCursorAtUnit(82);
    await s.stall(60);
    await s.endCursor();
    s.sound('bgm', 38);
    s.setTextType(0);
    await s.textShow(2628);
    await s.textEnd();
    s.textRemoveAll();
    await s.fade(FadeDirection.toBlack, 16);
    s.moveUnit('MOVE_CLOSEST', [65535, 82, 1800]);
    await s.call(Sym('data_085B9BBC', 512));
    s.sound('bgm', 20);
    s.cameraToChar(28);
    await s.fade(FadeDirection.fromBlack, 16);
    s.displayCursorAtUnit(28);
    await s.stall(60);
    await s.endCursor();
    s.volumeDown(true);
    s.setSlot(2, 63);
    s.setSlot(3, 2629);
    await s.call(Sym('Event_TextWithBG'));
    s.evBitMod('flag', true, 12);
    s.evBitMod('flag', true, 14);
    s.evBitMod('evbit', true, 7);
    return;
}

/// `EventScr_Ch14b_BeginningScene`
Future<void> Ch14b_BeginningScene(Scene s) async {
    s.loadUnits(1, Sym('frontier_df3_unitdef_b_037_91AC38_tail_p1', 240));
    await s.waitUnitMoving();
    s.unitStateOp('remu', 83);
    s.loadUnits(1, Sym('frontier_df3_unitdef_b_038_91B948_residue', 240));
    await s.waitUnitMoving();
    await s.cameraTo(0, 21, centered: false);
    await s.clearScreen();
    s.sound('bgm', 37);
    await s.fade(FadeDirection.fromBlack, 16);
    s.loadUnits(2, Sym('frontier_df3_unitdef_b_038_91B948_residue'));
    s.setSlot(1, 0);
    s.unitStateOp('setState', 15);
    s.setSlot(1, 0);
    s.unitStateOp('setState', 2);
    s.loadUnits(3, Sym('frontier_df3_unitdef_b_038_91B948_residue', 60));
    await s.waitUnitMoving();
    s.setSlot(1, 4294967295);
    s.unitStateOp('setState', 15);
    s.setSlot(1, 4294967295);
    s.unitStateOp('setState', 2);
    s.showCursorAtUnit(15);
    await s.stall(60);
    await s.endCursor();
    s.setSlot(2, 73);
    await s.call(Sym('EventScr_SetBackground'));
    await s.textShow(2778);
    await s.textEnd();
    s.textRemoveAll();
    s.placeholder('EvtBgmFadeIn');
    await s.fade(FadeDirection.toBlack, 16);
    await s.clearScreen();
    await s.cameraTo(0, 0, centered: false);
    await s.fade(FadeDirection.fromBlack, 16);
    s.placeholder('SPAWN_ENEMY');
    s.setSlot(2, 64);
    s.moveUnit('MOVE_CLOSEST', [65535, 65533, 5, 2]);
    await s.call(Sym('EventScr_UnitWarpIN'));
    s.showCursorAtUnit(64);
    await s.stall(60);
    await s.endCursor();
    s.sound('bgm', 46);
    s.setSlot(2, 73);
    s.setSlot(3, 2779);
    await s.call(Sym('Event_TextWithBG'));
    s.setSlot(2, 64);
    await s.call(Sym('EventScr_UnitWarpOUT'));
    await s.removeUnit(64);
    s.moveUnit('MOVE_1STEP', [0, 102, 3]);
    await s.waitUnitMoving();
    s.moveUnit('MOVEONTO', [0, 102, 83]);
    await s.waitUnitMoving();
    s.loadUnits(1, Sym('frontier_df3_unitdef_b_037_91AC38_tail_p1', 1100));
    await s.waitUnitMoving();
    await s.waitUnitMoving();
    s.unitStateOp('reveal', 83);
    await s.removeUnit(102);
    await s.fade(FadeDirection.toBlack, 16);
    await s.call(Sym('data_085B9BBC', 512));
    await s.cameraTo(12, 7, centered: true);
    await s.fade(FadeDirection.fromBlack, 16);
    s.sound('bgm', 38);
    s.loadUnits(1, Sym('frontier_df3_unitdef_b_037_91AC38_tail_p1', 1180));
    await s.waitUnitMoving();
    s.unitStateOp('reveal', 1);
    s.showCursorAtUnit(1);
    await s.stall(60);
    await s.endCursor();
    s.setSlot(2, 73);
    s.setSlot(3, 2781);
    await s.call(Sym('Event_TextWithBG'));
    s.evBitMod('evbit', true, 7);
    return;
}

/// `EventScr_Ch14b_EndingScene`
Future<void> Ch14b_EndingScene(Scene s) async {
    await s.call(Sym('EventScr_Ch15A_26'));
    s.evBitMod('flag', true, 119);
    await s.changeChapter(29, subcmd: 1);
    return;
    s.volumeDown(true);
    s.setSlot(2, 0);
    s.setSlot(3, 2806);
    await s.call(Sym('Event_TextWithBG'));
    s.volumeDown(false);
    await s.call(Sym('data_085B9BBC', 360));
    s.setSlot(3, 136);
    await s.giveItem(65535, 3);
    s.evBitMod('evbit', true, 7);
    return;
    s.volumeDown(true);
    s.setSlot(2, 0);
    s.setSlot(3, 2807);
    await s.call(Sym('Event_TextWithBG'));
    s.volumeDown(false);
    s.evBitMod('evbit', true, 7);
    return;
    s.volumeDown(true);
    s.setSlot(2, 0);
    s.setSlot(3, 2808);
    await s.call(Sym('Event_TextWithBG'));
    s.volumeDown(false);
    s.evBitMod('evbit', true, 7);
    return;
    s.sound('override', 39);
    await s.stall(33);
    s.setTextType(0);
    await s.textShow(2796);
    await s.textEnd();
    s.textRemoveAll();
    s.restoreBgm(2);
    s.evBitMod('evbit', true, 7);
    return;
    s.volumeDown(true);
    s.setTextType(0);
    await s.textShow(2802);
    await s.textEnd();
    s.textRemoveAll();
    s.volumeDown(false);
    s.evBitMod('evbit', true, 7);
    return;
    s.volumeDown(true);
    s.setTextType(0);
    await s.textShow(2803);
    await s.textEnd();
    s.textRemoveAll();
    s.volumeDown(false);
    s.evBitMod('evbit', true, 7);
    return;
    s.volumeDown(true);
    s.setTextType(0);
    await s.textShow(2804);
    await s.textEnd();
    s.textRemoveAll();
    s.volumeDown(false);
    s.evBitMod('evbit', true, 7);
    return;
    s.volumeDown(true);
    s.setTextType(0);
    await s.textShow(2805);
    await s.textEnd();
    s.textRemoveAll();
    s.volumeDown(false);
    s.evBitMod('evbit', true, 7);
    return;
    s.setSlot(2, Sym('frontier_df3_unitdef_b_037_91AC38_tail_p1', 1260));
    await s.call(Sym('EventScr_LoadReinforce'));
    s.evBitMod('evbit', true, 7);
    return;
    s.setSlot(2, Sym('frontier_df3_unitdef_b_037_91AC38_tail_p1', 1320));
    await s.call(Sym('EventScr_LoadReinforce'));
    s.evBitMod('evbit', true, 7);
    return;
    s.setSlot(2, Sym('UnitDef_Ch15BEnemy_4'));
    await s.call(Sym('EventScr_LoadReinforce'));
    s.evBitMod('evbit', true, 7);
    return;
    s.setSlot(2, Sym('UnitDef_Ch15BEnemy_5'));
    await s.call(Sym('EventScr_LoadReinforce'));
    s.evBitMod('evbit', true, 7);
    return;
    s.setSlot(2, Sym('frontier_df3_unitdef_b_038_91B948'));
    await s.call(Sym('EventScr_LoadReinforce'));
    s.evBitMod('evbit', true, 7);
    return;
    s.setSlot(2, 0);
    await s.call(Sym('UnitDef_Ch14BAlly_7'));
    s.setSlot(1, 65536);
    s.placeholder('CHAI');
    s.setSlot(1, 70144);
    s.placeholder('CHAI');
    s.evBitMod('evbit', true, 7);
    return;
}

/// `EventScr_Ch15A_0`
Future<void> Ch15A_0(Scene s) async {
    s.sound('bgm', 37);
    s.evBitMod('evbit', true, 9);
    s.loadUnits(1, Sym('UnitDef_Ch15AAlly_1'));
    await s.waitUnitMoving();
    s.evBitMod('evbit', false, 9);
    s.showCursorAtUnit(15);
    await s.stall(60);
    await s.endCursor();
    s.setSlot(2, 73);
    s.setSlot(3, 2780);
    await s.call(Sym('Event_TextWithBG'));
    s.unitStateOp('reveal', 15);
    s.evBitMod('evbit', true, 7);
    return;
}

/// `EventScr_Ch15A_1`
Future<void> Ch15A_1(Scene s) async {
    await s.call(Sym('EventScr_Ch15A_26'));
    s.evBitMod('flag', true, 119);
    await s.changeChapter(16, subcmd: 1);
    return;
}

/// `EventScr_Ch15A_17`
Future<void> Ch15A_17(Scene s) async {
    var pc = 0;
    while (true) {
      switch (pc) {
        case 0:
          s.setSlot(2, 0);
          pc = 1;
          continue;
        case 1:
          await s.call(Sym('UnitDef_Ch14BAlly_7'));
          pc = 2;
          continue;
        case 2:
          s.checkLuck(65535);
          pc = 3;
          continue;
        case 3:
          s.slotArith('SADD', 2, 12);
          pc = 4;
          continue;
        case 4:
          s.setSlot(3, 15);
          pc = 5;
          continue;
        case 5:
          await s.call(Sym('EventScr_GiveTreasureToLuckyDog'));
          pc = 6;
          continue;
        case 6:
          if (s.slotInt(12) != s.slotInt(0)) { pc = 8; } else { pc = 7; }
          continue;
        case 7:
          await s.call(Sym('UnitDef_Ch14BAlly_7', 28));
          pc = 8;
          continue;
        case 8:
          pc = 9;
          continue;
        case 9:
          s.evBitMod('evbit', true, 7);
          pc = 10;
          continue;
        case 10:
          return;
        default:
          return;
      }
    }
}

/// `EventScr_Ch15A_18`
Future<void> Ch15A_18(Scene s) async {
    var pc = 0;
    while (true) {
      switch (pc) {
        case 0:
          s.setSlot(2, 0);
          pc = 1;
          continue;
        case 1:
          await s.call(Sym('UnitDef_Ch14BAlly_7'));
          pc = 2;
          continue;
        case 2:
          s.checkLuck(65535);
          pc = 3;
          continue;
        case 3:
          s.slotArith('SADD', 2, 12);
          pc = 4;
          continue;
        case 4:
          s.setSlot(3, 98);
          pc = 5;
          continue;
        case 5:
          await s.call(Sym('EventScr_GiveTreasureToLuckyDog'));
          pc = 6;
          continue;
        case 6:
          if (s.slotInt(12) != s.slotInt(0)) { pc = 8; } else { pc = 7; }
          continue;
        case 7:
          await s.call(Sym('UnitDef_Ch14BAlly_7', 28));
          pc = 8;
          continue;
        case 8:
          pc = 9;
          continue;
        case 9:
          s.evBitMod('evbit', true, 7);
          pc = 10;
          continue;
        case 10:
          return;
        default:
          return;
      }
    }
}

/// `EventScr_Ch15A_19`
Future<void> Ch15A_19(Scene s) async {
    var pc = 0;
    while (true) {
      switch (pc) {
        case 0:
          s.setSlot(2, 0);
          pc = 1;
          continue;
        case 1:
          await s.call(Sym('UnitDef_Ch14BAlly_7'));
          pc = 2;
          continue;
        case 2:
          s.checkLuck(65535);
          pc = 3;
          continue;
        case 3:
          s.slotArith('SADD', 2, 12);
          pc = 4;
          continue;
        case 4:
          s.setSlot(3, 137);
          pc = 5;
          continue;
        case 5:
          await s.call(Sym('EventScr_GiveTreasureToLuckyDog'));
          pc = 6;
          continue;
        case 6:
          if (s.slotInt(12) != s.slotInt(0)) { pc = 8; } else { pc = 7; }
          continue;
        case 7:
          await s.call(Sym('UnitDef_Ch14BAlly_7', 28));
          pc = 8;
          continue;
        case 8:
          pc = 9;
          continue;
        case 9:
          s.evBitMod('evbit', true, 7);
          pc = 10;
          continue;
        case 10:
          return;
        default:
          return;
      }
    }
}

/// `EventScr_Ch15A_2`
Future<void> Ch15A_2(Scene s) async {
    s.placeholder('EvtNop');
    s.setSlot(3, 2806);
    await s.call(Sym('Event_TextWithBG'));
    s.volumeDown(false);
    await s.call(Sym('data_085B9BBC', 360));
    s.setSlot(3, 136);
    await s.giveItem(65535, 3);
    s.evBitMod('evbit', true, 7);
    return;
    s.volumeDown(true);
    s.setSlot(2, 0);
    s.setSlot(3, 2807);
    await s.call(Sym('Event_TextWithBG'));
    s.volumeDown(false);
    s.evBitMod('evbit', true, 7);
    return;
    s.volumeDown(true);
    s.setSlot(2, 0);
    s.setSlot(3, 2808);
    await s.call(Sym('Event_TextWithBG'));
    s.volumeDown(false);
    s.evBitMod('evbit', true, 7);
    return;
    s.sound('override', 39);
    await s.stall(33);
    s.setTextType(0);
    await s.textShow(2796);
    await s.textEnd();
    s.textRemoveAll();
    s.restoreBgm(2);
    s.evBitMod('evbit', true, 7);
    return;
    s.volumeDown(true);
    s.setTextType(0);
    await s.textShow(2797);
    await s.textEnd();
    s.textRemoveAll();
    s.volumeDown(false);
    s.evBitMod('evbit', true, 7);
    return;
    s.volumeDown(true);
    s.setTextType(0);
    await s.textShow(2798);
    await s.textEnd();
    s.textRemoveAll();
    s.volumeDown(false);
    s.evBitMod('evbit', true, 7);
    return;
    s.volumeDown(true);
    s.setTextType(0);
    await s.textShow(2799);
    await s.textEnd();
    s.textRemoveAll();
    s.volumeDown(false);
    s.evBitMod('evbit', true, 7);
    return;
    s.volumeDown(true);
    s.setTextType(0);
    await s.textShow(2800);
    await s.textEnd();
    s.textRemoveAll();
    s.volumeDown(false);
    s.evBitMod('evbit', true, 7);
    return;
    s.volumeDown(true);
    s.setTextType(0);
    await s.textShow(2801);
    await s.textEnd();
    s.textRemoveAll();
    s.volumeDown(false);
    s.evBitMod('evbit', true, 7);
    return;
    s.setSlot(2, Sym('frontier_df3_unitdef_b_006_911070'));
    await s.call(Sym('EventScr_LoadReinforce'));
    s.evBitMod('evbit', true, 7);
    return;
    s.setSlot(2, 143724716);
    await s.call(Sym('EventScr_LoadReinforce'));
    s.evBitMod('evbit', true, 7);
    return;
    s.setSlot(2, 143724776);
    await s.call(Sym('EventScr_LoadReinforce'));
    s.evBitMod('evbit', true, 7);
    return;
    s.setSlot(2, Sym('UnitDef_Ch15AEnemy_6'));
    await s.call(Sym('EventScr_LoadReinforce'));
    s.evBitMod('evbit', true, 7);
    return;
    s.setSlot(2, Sym('frontier_df3_unitdef_b_007_911200', 60));
    await s.call(Sym('EventScr_LoadReinforce'));
    s.evBitMod('evbit', true, 7);
    return;
    s.setSlot(2, 0);
    await s.call(Sym('UnitDef_Ch14BAlly_7'));
    s.setSlot(1, 65536);
    s.placeholder('CHAI');
    s.setSlot(1, 70144);
    s.placeholder('CHAI');
    s.evBitMod('evbit', true, 7);
    return;
}

/// `EventScr_Ch15A_20`
Future<void> Ch15A_20(Scene s) async {
    var pc = 0;
    while (true) {
      switch (pc) {
        case 0:
          s.setSlot(2, 0);
          pc = 1;
          continue;
        case 1:
          await s.call(Sym('UnitDef_Ch14BAlly_7'));
          pc = 2;
          continue;
        case 2:
          s.checkLuck(65535);
          pc = 3;
          continue;
        case 3:
          s.slotArith('SADD', 2, 12);
          pc = 4;
          continue;
        case 4:
          s.setSlot(3, 84);
          pc = 5;
          continue;
        case 5:
          await s.call(Sym('EventScr_GiveTreasureToLuckyDog'));
          pc = 6;
          continue;
        case 6:
          if (s.slotInt(12) != s.slotInt(0)) { pc = 8; } else { pc = 7; }
          continue;
        case 7:
          await s.call(Sym('UnitDef_Ch14BAlly_7', 28));
          pc = 8;
          continue;
        case 8:
          pc = 9;
          continue;
        case 9:
          s.evBitMod('evbit', true, 7);
          pc = 10;
          continue;
        case 10:
          return;
        default:
          return;
      }
    }
}

/// `EventScr_Ch15A_21`
Future<void> Ch15A_21(Scene s) async {
    var pc = 0;
    while (true) {
      switch (pc) {
        case 0:
          s.setSlot(2, 0);
          pc = 1;
          continue;
        case 1:
          await s.call(Sym('UnitDef_Ch14BAlly_7'));
          pc = 2;
          continue;
        case 2:
          s.checkLuck(65535);
          pc = 3;
          continue;
        case 3:
          s.slotArith('SADD', 2, 12);
          pc = 4;
          continue;
        case 4:
          s.setSlot(3, 72);
          pc = 5;
          continue;
        case 5:
          await s.call(Sym('EventScr_GiveTreasureToLuckyDog'));
          pc = 6;
          continue;
        case 6:
          if (s.slotInt(12) != s.slotInt(0)) { pc = 8; } else { pc = 7; }
          continue;
        case 7:
          await s.call(Sym('UnitDef_Ch14BAlly_7', 28));
          pc = 8;
          continue;
        case 8:
          pc = 9;
          continue;
        case 9:
          s.evBitMod('evbit', true, 7);
          pc = 10;
          continue;
        case 10:
          return;
        default:
          return;
      }
    }
}

/// `EventScr_Ch15A_22`
Future<void> Ch15A_22(Scene s) async {
    var pc = 0;
    while (true) {
      switch (pc) {
        case 0:
          s.setSlot(2, 0);
          pc = 1;
          continue;
        case 1:
          await s.call(Sym('UnitDef_Ch14BAlly_7'));
          pc = 2;
          continue;
        case 2:
          s.checkLuck(65535);
          pc = 3;
          continue;
        case 3:
          s.slotArith('SADD', 2, 12);
          pc = 4;
          continue;
        case 4:
          s.setSlot(3, 99);
          pc = 5;
          continue;
        case 5:
          await s.call(Sym('EventScr_GiveTreasureToLuckyDog'));
          pc = 6;
          continue;
        case 6:
          if (s.slotInt(12) != s.slotInt(0)) { pc = 8; } else { pc = 7; }
          continue;
        case 7:
          await s.call(Sym('UnitDef_Ch14BAlly_7', 28));
          pc = 8;
          continue;
        case 8:
          pc = 9;
          continue;
        case 9:
          s.evBitMod('evbit', true, 7);
          pc = 10;
          continue;
        case 10:
          return;
        default:
          return;
      }
    }
}

/// `EventScr_Ch15A_23`
Future<void> Ch15A_23(Scene s) async {
    var pc = 0;
    while (true) {
      switch (pc) {
        case 0:
          s.setSlot(2, 0);
          pc = 1;
          continue;
        case 1:
          await s.call(Sym('UnitDef_Ch14BAlly_7'));
          pc = 2;
          continue;
        case 2:
          s.checkLuck(65535);
          pc = 3;
          continue;
        case 3:
          s.slotArith('SADD', 2, 12);
          pc = 4;
          continue;
        case 4:
          s.setSlot(3, 115);
          pc = 5;
          continue;
        case 5:
          await s.call(Sym('EventScr_GiveTreasureToLuckyDog'));
          pc = 6;
          continue;
        case 6:
          if (s.slotInt(12) != s.slotInt(0)) { pc = 8; } else { pc = 7; }
          continue;
        case 7:
          await s.call(Sym('UnitDef_Ch14BAlly_7', 28));
          pc = 8;
          continue;
        case 8:
          pc = 9;
          continue;
        case 9:
          s.evBitMod('evbit', true, 7);
          pc = 10;
          continue;
        case 10:
          return;
        default:
          return;
      }
    }
}

/// `EventScr_Ch15A_24`
Future<void> Ch15A_24(Scene s) async {
    var pc = 0;
    while (true) {
      switch (pc) {
        case 0:
          s.setSlot(2, 0);
          pc = 1;
          continue;
        case 1:
          await s.call(Sym('UnitDef_Ch14BAlly_7'));
          pc = 2;
          continue;
        case 2:
          s.checkLuck(65535);
          pc = 3;
          continue;
        case 3:
          s.slotArith('SADD', 2, 12);
          pc = 4;
          continue;
        case 4:
          s.setSlot(3, 49);
          pc = 5;
          continue;
        case 5:
          await s.call(Sym('EventScr_GiveTreasureToLuckyDog'));
          pc = 6;
          continue;
        case 6:
          if (s.slotInt(12) != s.slotInt(0)) { pc = 8; } else { pc = 7; }
          continue;
        case 7:
          await s.call(Sym('UnitDef_Ch14BAlly_7', 28));
          pc = 8;
          continue;
        case 8:
          pc = 9;
          continue;
        case 9:
          s.evBitMod('evbit', true, 7);
          pc = 10;
          continue;
        case 10:
          return;
        default:
          return;
      }
    }
}

/// `EventScr_Ch15A_25`
Future<void> Ch15A_25(Scene s) async {
    var pc = 0;
    while (true) {
      switch (pc) {
        case 0:
          s.setSlot(2, 0);
          pc = 1;
          continue;
        case 1:
          await s.call(Sym('UnitDef_Ch14BAlly_7'));
          pc = 2;
          continue;
        case 2:
          s.checkLuck(65535);
          pc = 3;
          continue;
        case 3:
          s.slotArith('SADD', 2, 12);
          pc = 4;
          continue;
        case 4:
          s.setSlot(3, 81);
          pc = 5;
          continue;
        case 5:
          await s.call(Sym('EventScr_GiveTreasureToLuckyDog'));
          pc = 6;
          continue;
        case 6:
          if (s.slotInt(12) != s.slotInt(0)) { pc = 8; } else { pc = 7; }
          continue;
        case 7:
          await s.call(Sym('UnitDef_Ch14BAlly_7', 28));
          pc = 8;
          continue;
        case 8:
          pc = 9;
          continue;
        case 9:
          s.evBitMod('evbit', true, 7);
          pc = 10;
          continue;
        case 10:
          return;
        default:
          return;
      }
    }
}

/// `EventScr_Ch15A_26`
Future<void> Ch15A_26(Scene s) async {
    var pc = 0;
    while (true) {
      switch (pc) {
        case 0:
          s.sound('bgm', 49);
          pc = 1;
          continue;
        case 1:
          s.setSlot(2, 73);
          pc = 2;
          continue;
        case 2:
          await s.call(Sym('EventScr_SetBackground'));
          pc = 3;
          continue;
        case 3:
          s.checkSlotValue('mode');
          pc = 4;
          continue;
        case 4:
          s.setSlot(1, 2);
          pc = 5;
          continue;
        case 5:
          if (s.slotInt(12) != s.slotInt(1)) { pc = 16; } else { pc = 6; }
          continue;
        case 6:
          await s.textShow(2792);
          pc = 7;
          continue;
        case 7:
          await s.textEnd();
          pc = 8;
          continue;
        case 8:
          s.textRemoveAll();
          pc = 9;
          continue;
        case 9:
          await s.call(Sym('data_085B9BBC', 360));
          pc = 10;
          continue;
        case 10:
          s.setSlot(3, 74);
          pc = 11;
          continue;
        case 11:
          await s.giveItem(1, 3);
          pc = 12;
          continue;
        case 12:
          await s.call(Sym('data_085B9BBC', 360));
          pc = 13;
          continue;
        case 13:
          s.setSlot(3, 147);
          pc = 14;
          continue;
        case 14:
          await s.giveItem(1, 3);
          pc = 15;
          continue;
        case 15:
          pc = 26;
          continue;
        case 16:
          pc = 17;
          continue;
        case 17:
          await s.textShow(2793);
          pc = 18;
          continue;
        case 18:
          await s.textEnd();
          pc = 19;
          continue;
        case 19:
          s.textRemoveAll();
          pc = 20;
          continue;
        case 20:
          await s.call(Sym('data_085B9BBC', 360));
          pc = 21;
          continue;
        case 21:
          s.setSlot(3, 145);
          pc = 22;
          continue;
        case 22:
          await s.giveItem(15, 3);
          pc = 23;
          continue;
        case 23:
          await s.call(Sym('data_085B9BBC', 360));
          pc = 24;
          continue;
        case 24:
          s.setSlot(3, 62);
          pc = 25;
          continue;
        case 25:
          await s.giveItem(15, 3);
          pc = 26;
          continue;
        case 26:
          pc = 27;
          continue;
        case 27:
          await s.fade(FadeDirection.toBlack, 16);
          pc = 28;
          continue;
        case 28:
          s.hideFaction('blue');
          pc = 29;
          continue;
        case 29:
          s.hideFaction('red');
          pc = 30;
          continue;
        case 30:
          s.hideFaction('green');
          pc = 31;
          continue;
        case 31:
          await s.cameraTo(12, 5, centered: true);
          pc = 32;
          continue;
        case 32:
          await s.clearScreen();
          pc = 33;
          continue;
        case 33:
          await s.fade(FadeDirection.fromBlack, 16);
          pc = 34;
          continue;
        case 34:
          s.showCursorAt(8, 8);
          pc = 35;
          continue;
        case 35:
          await s.stall(60);
          pc = 36;
          continue;
        case 36:
          await s.endCursor();
          pc = 37;
          continue;
        case 37:
          s.setSlot(2, 59);
          pc = 38;
          continue;
        case 38:
          await s.call(Sym('EventScr_SetBackground'));
          pc = 39;
          continue;
        case 39:
          await s.textShow(2794);
          pc = 40;
          continue;
        case 40:
          await s.textEnd();
          pc = 41;
          continue;
        case 41:
          s.sound('override', 45);
          pc = 42;
          continue;
        case 42:
          await s.stall(33);
          pc = 43;
          continue;
        case 43:
          await s.continueText();
          pc = 44;
          continue;
        case 44:
          await s.textEnd();
          pc = 45;
          continue;
        case 45:
          s.restoreBgm(4);
          pc = 46;
          continue;
        case 46:
          await s.continueText();
          pc = 47;
          continue;
        case 47:
          await s.textEnd();
          pc = 48;
          continue;
        case 48:
          s.textRemoveAll();
          pc = 49;
          continue;
        case 49:
          s.placeholder('EvtBgmFadeIn');
          pc = 50;
          continue;
        case 50:
          await s.fade(FadeDirection.toBlack, 16);
          pc = 51;
          continue;
        case 51:
          s.checkSlot('alive', 23);
          pc = 52;
          continue;
        case 52:
          if (s.slotInt(12) == s.slotInt(0)) { pc = 60; } else { pc = 53; }
          continue;
        case 53:
          s.setSlot(2, 59);
          pc = 54;
          continue;
        case 54:
          await s.call(Sym('EventScr_SetBackground'));
          pc = 55;
          continue;
        case 55:
          s.sound('bgm', 43);
          pc = 56;
          continue;
        case 56:
          await s.textShow(2795);
          pc = 57;
          continue;
        case 57:
          await s.textEnd();
          pc = 58;
          continue;
        case 58:
          s.textRemoveAll();
          pc = 59;
          continue;
        case 59:
          await s.fade(FadeDirection.toBlack, 16);
          pc = 60;
          continue;
        case 60:
          pc = 61;
          continue;
        case 61:
          return;
        case 62:
          s.volumeDown(true);
          pc = 63;
          continue;
        case 63:
          s.placeholder('EVENT_WORD');
          pc = 64;
          continue;
        default:
          return;
      }
    }
}

/// `EventScr_Ch15B_14`
Future<void> Ch15B_14(Scene s) async {
    var pc = 0;
    while (true) {
      switch (pc) {
        case 0:
          s.setSlot(2, 0);
          pc = 1;
          continue;
        case 1:
          await s.call(Sym('UnitDef_Ch14BAlly_7'));
          pc = 2;
          continue;
        case 2:
          s.checkLuck(65535);
          pc = 3;
          continue;
        case 3:
          s.slotArith('SADD', 2, 12);
          pc = 4;
          continue;
        case 4:
          s.setSlot(3, 15);
          pc = 5;
          continue;
        case 5:
          await s.call(Sym('EventScr_GiveTreasureToLuckyDog'));
          pc = 6;
          continue;
        case 6:
          if (s.slotInt(12) != s.slotInt(0)) { pc = 8; } else { pc = 7; }
          continue;
        case 7:
          await s.call(Sym('UnitDef_Ch14BAlly_7', 28));
          pc = 8;
          continue;
        case 8:
          pc = 9;
          continue;
        case 9:
          s.evBitMod('evbit', true, 7);
          pc = 10;
          continue;
        case 10:
          return;
        default:
          return;
      }
    }
}

/// `EventScr_Ch15B_15`
Future<void> Ch15B_15(Scene s) async {
    var pc = 0;
    while (true) {
      switch (pc) {
        case 0:
          s.setSlot(2, 0);
          pc = 1;
          continue;
        case 1:
          await s.call(Sym('UnitDef_Ch14BAlly_7'));
          pc = 2;
          continue;
        case 2:
          s.checkLuck(65535);
          pc = 3;
          continue;
        case 3:
          s.slotArith('SADD', 2, 12);
          pc = 4;
          continue;
        case 4:
          s.setSlot(3, 98);
          pc = 5;
          continue;
        case 5:
          await s.call(Sym('EventScr_GiveTreasureToLuckyDog'));
          pc = 6;
          continue;
        case 6:
          if (s.slotInt(12) != s.slotInt(0)) { pc = 8; } else { pc = 7; }
          continue;
        case 7:
          await s.call(Sym('UnitDef_Ch14BAlly_7', 28));
          pc = 8;
          continue;
        case 8:
          pc = 9;
          continue;
        case 9:
          s.evBitMod('evbit', true, 7);
          pc = 10;
          continue;
        case 10:
          return;
        default:
          return;
      }
    }
}

/// `EventScr_Ch15B_16`
Future<void> Ch15B_16(Scene s) async {
    var pc = 0;
    while (true) {
      switch (pc) {
        case 0:
          s.setSlot(2, 0);
          pc = 1;
          continue;
        case 1:
          await s.call(Sym('UnitDef_Ch14BAlly_7'));
          pc = 2;
          continue;
        case 2:
          s.checkLuck(65535);
          pc = 3;
          continue;
        case 3:
          s.slotArith('SADD', 2, 12);
          pc = 4;
          continue;
        case 4:
          s.setSlot(3, 137);
          pc = 5;
          continue;
        case 5:
          await s.call(Sym('EventScr_GiveTreasureToLuckyDog'));
          pc = 6;
          continue;
        case 6:
          if (s.slotInt(12) != s.slotInt(0)) { pc = 8; } else { pc = 7; }
          continue;
        case 7:
          await s.call(Sym('UnitDef_Ch14BAlly_7', 28));
          pc = 8;
          continue;
        case 8:
          pc = 9;
          continue;
        case 9:
          s.evBitMod('evbit', true, 7);
          pc = 10;
          continue;
        case 10:
          return;
        default:
          return;
      }
    }
}

/// `EventScr_Ch15B_17`
Future<void> Ch15B_17(Scene s) async {
    var pc = 0;
    while (true) {
      switch (pc) {
        case 0:
          s.setSlot(2, 0);
          pc = 1;
          continue;
        case 1:
          await s.call(Sym('UnitDef_Ch14BAlly_7'));
          pc = 2;
          continue;
        case 2:
          s.checkLuck(65535);
          pc = 3;
          continue;
        case 3:
          s.slotArith('SADD', 2, 12);
          pc = 4;
          continue;
        case 4:
          s.setSlot(3, 84);
          pc = 5;
          continue;
        case 5:
          await s.call(Sym('EventScr_GiveTreasureToLuckyDog'));
          pc = 6;
          continue;
        case 6:
          if (s.slotInt(12) != s.slotInt(0)) { pc = 8; } else { pc = 7; }
          continue;
        case 7:
          await s.call(Sym('UnitDef_Ch14BAlly_7', 28));
          pc = 8;
          continue;
        case 8:
          pc = 9;
          continue;
        case 9:
          s.evBitMod('evbit', true, 7);
          pc = 10;
          continue;
        case 10:
          return;
        default:
          return;
      }
    }
}

/// `EventScr_Ch15B_18`
Future<void> Ch15B_18(Scene s) async {
    var pc = 0;
    while (true) {
      switch (pc) {
        case 0:
          s.setSlot(2, 0);
          pc = 1;
          continue;
        case 1:
          await s.call(Sym('UnitDef_Ch14BAlly_7'));
          pc = 2;
          continue;
        case 2:
          s.checkLuck(65535);
          pc = 3;
          continue;
        case 3:
          s.slotArith('SADD', 2, 12);
          pc = 4;
          continue;
        case 4:
          s.setSlot(3, 72);
          pc = 5;
          continue;
        case 5:
          await s.call(Sym('EventScr_GiveTreasureToLuckyDog'));
          pc = 6;
          continue;
        case 6:
          if (s.slotInt(12) != s.slotInt(0)) { pc = 8; } else { pc = 7; }
          continue;
        case 7:
          await s.call(Sym('UnitDef_Ch14BAlly_7', 28));
          pc = 8;
          continue;
        case 8:
          pc = 9;
          continue;
        case 9:
          s.evBitMod('evbit', true, 7);
          pc = 10;
          continue;
        case 10:
          return;
        default:
          return;
      }
    }
}

/// `EventScr_Ch15B_19`
Future<void> Ch15B_19(Scene s) async {
    var pc = 0;
    while (true) {
      switch (pc) {
        case 0:
          s.setSlot(2, 0);
          pc = 1;
          continue;
        case 1:
          await s.call(Sym('UnitDef_Ch14BAlly_7'));
          pc = 2;
          continue;
        case 2:
          s.checkLuck(65535);
          pc = 3;
          continue;
        case 3:
          s.slotArith('SADD', 2, 12);
          pc = 4;
          continue;
        case 4:
          s.setSlot(3, 99);
          pc = 5;
          continue;
        case 5:
          await s.call(Sym('EventScr_GiveTreasureToLuckyDog'));
          pc = 6;
          continue;
        case 6:
          if (s.slotInt(12) != s.slotInt(0)) { pc = 8; } else { pc = 7; }
          continue;
        case 7:
          await s.call(Sym('UnitDef_Ch14BAlly_7', 28));
          pc = 8;
          continue;
        case 8:
          pc = 9;
          continue;
        case 9:
          s.evBitMod('evbit', true, 7);
          pc = 10;
          continue;
        case 10:
          return;
        default:
          return;
      }
    }
}

/// `EventScr_Ch15B_20`
Future<void> Ch15B_20(Scene s) async {
    var pc = 0;
    while (true) {
      switch (pc) {
        case 0:
          s.setSlot(2, 0);
          pc = 1;
          continue;
        case 1:
          await s.call(Sym('UnitDef_Ch14BAlly_7'));
          pc = 2;
          continue;
        case 2:
          s.checkLuck(65535);
          pc = 3;
          continue;
        case 3:
          s.slotArith('SADD', 2, 12);
          pc = 4;
          continue;
        case 4:
          s.setSlot(3, 115);
          pc = 5;
          continue;
        case 5:
          await s.call(Sym('EventScr_GiveTreasureToLuckyDog'));
          pc = 6;
          continue;
        case 6:
          if (s.slotInt(12) != s.slotInt(0)) { pc = 8; } else { pc = 7; }
          continue;
        case 7:
          await s.call(Sym('UnitDef_Ch14BAlly_7', 28));
          pc = 8;
          continue;
        case 8:
          pc = 9;
          continue;
        case 9:
          s.evBitMod('evbit', true, 7);
          pc = 10;
          continue;
        case 10:
          return;
        default:
          return;
      }
    }
}

/// `EventScr_Ch15B_21`
Future<void> Ch15B_21(Scene s) async {
    var pc = 0;
    while (true) {
      switch (pc) {
        case 0:
          s.setSlot(2, 0);
          pc = 1;
          continue;
        case 1:
          await s.call(Sym('UnitDef_Ch14BAlly_7'));
          pc = 2;
          continue;
        case 2:
          s.checkLuck(65535);
          pc = 3;
          continue;
        case 3:
          s.slotArith('SADD', 2, 12);
          pc = 4;
          continue;
        case 4:
          s.setSlot(3, 49);
          pc = 5;
          continue;
        case 5:
          await s.call(Sym('EventScr_GiveTreasureToLuckyDog'));
          pc = 6;
          continue;
        case 6:
          if (s.slotInt(12) != s.slotInt(0)) { pc = 8; } else { pc = 7; }
          continue;
        case 7:
          await s.call(Sym('UnitDef_Ch14BAlly_7', 28));
          pc = 8;
          continue;
        case 8:
          pc = 9;
          continue;
        case 9:
          s.evBitMod('evbit', true, 7);
          pc = 10;
          continue;
        case 10:
          return;
        default:
          return;
      }
    }
}

/// `EventScr_Ch15B_22`
Future<void> Ch15B_22(Scene s) async {
    var pc = 0;
    while (true) {
      switch (pc) {
        case 0:
          s.setSlot(2, 0);
          pc = 1;
          continue;
        case 1:
          await s.call(Sym('UnitDef_Ch14BAlly_7'));
          pc = 2;
          continue;
        case 2:
          s.checkLuck(65535);
          pc = 3;
          continue;
        case 3:
          s.slotArith('SADD', 2, 12);
          pc = 4;
          continue;
        case 4:
          s.setSlot(3, 81);
          pc = 5;
          continue;
        case 5:
          await s.call(Sym('EventScr_GiveTreasureToLuckyDog'));
          pc = 6;
          continue;
        case 6:
          if (s.slotInt(12) != s.slotInt(0)) { pc = 8; } else { pc = 7; }
          continue;
        case 7:
          await s.call(Sym('UnitDef_Ch14BAlly_7', 28));
          pc = 8;
          continue;
        case 8:
          pc = 9;
          continue;
        case 9:
          s.evBitMod('evbit', true, 7);
          pc = 10;
          continue;
        case 10:
          return;
        default:
          return;
      }
    }
}

/// `EventScr_Ch15a_BeginningScene`
Future<void> Ch15a_BeginningScene(Scene s) async {
    s.sound('bgm', 38);
    s.loadUnits(2, Sym('frontier_df3_unitdef_b_005_9109A8_residue_p5'));
    await s.waitUnitMoving();
    await s.fade(FadeDirection.fromBlack, 16);
    s.displayCursorAtUnit(2);
    await s.stall(60);
    await s.endCursor();
    s.setSlot(2, 73);
    await s.call(Sym('EventScr_SetBackground'));
    await s.textShow(2776);
    await s.textEnd();
    await s.fade(FadeDirection.toBlack, 4);
    s.textRemoveAll();
    await s.cameraTo(23, 21, centered: false);
    await s.clearScreen();
    s.loadUnits(1, Sym('frontier_df3_unitdef_b_005_9109A8', 696));
    await s.waitUnitMoving();
    await s.fade(FadeDirection.fromBlack, 16);
    s.placeholder('LOADSINGLEUNIT');
    s.setSlot(2, 87);
    s.moveUnit('MOVEUNIT', [65535]);
    await s.call(Sym('EventScr_UnitWarpIN'));
    s.displayCursorAtUnit(87);
    await s.stall(60);
    await s.endCursor();
    s.setSlot(2, 73);
    await s.call(Sym('EventScr_SetBackground'));
    await s.textShow(2777);
    await s.textEnd();
    await s.fade(FadeDirection.toBlack, 16);
    s.textRemoveAll();
    await s.removeUnit(87);
    s.loadUnits(1, Sym('frontier_df3_unitdef_b_005_9109A8', 1516));
    await s.waitUnitMoving();
    await s.call(Sym('data_085B9BBC', 512));
    return;
}

/// `EventScr_Ch16A_0`
Future<void> Ch16A_0(Scene s) async {
    await s.call(Sym('EventScr_Ch16A_12'));
    await s.changeChapter(17, subcmd: 1);
    return;
}

/// `EventScr_Ch16A_1`
Future<void> Ch16A_1(Scene s) async {
    s.slotArith('SADD', 10, 2);
    s.placeholder('STARTFADE');
    s.placeholder('EvtColorFadeSetup');
    await s.fade(FadeDirection.fromWhite, 128);
    await s.call(Sym('data_085B9BBC', 360));
    s.modifyEvBit(4);
    await s.call(Sym('EventScr_Ch16A_1', 84));
    s.placeholder('EvtBgmFadeIn');
    s.setTextType(1);
    s.slotArith('SADD', 2, 10);
    s.showTextBg(65535);
    await s.fade(FadeDirection.fromWhite, 4);
    s.modifyEvBit(0);
    return;
    s.checkSlotValue('mode');
    s.placeholder('EVENT_WORD');
}

/// `EventScr_Ch16A_11`
Future<void> Ch16A_11(Scene s) async {
    var pc = 0;
    while (true) {
      switch (pc) {
        case 0:
          s.sound('bgm', 71);
          pc = 1;
          continue;
        case 1:
          s.setSlot(11, 0);
          pc = 2;
          continue;
        case 2:
          await s.loadMap(64);
          pc = 3;
          continue;
        case 3:
          await s.fade(FadeDirection.fromBlack, 16);
          pc = 4;
          continue;
        case 4:
          s.loadUnits(2, Sym('UnitDef_Ch16AAlly_5'));
          pc = 5;
          continue;
        case 5:
          await s.waitUnitMoving();
          pc = 6;
          continue;
        case 6:
          s.showCursorAtUnit(15);
          pc = 7;
          continue;
        case 7:
          await s.stall(60);
          pc = 8;
          continue;
        case 8:
          await s.endCursor();
          pc = 9;
          continue;
        case 9:
          s.setSlot(2, 37);
          pc = 10;
          continue;
        case 10:
          await s.call(Sym('EventScr_SetBackground'));
          pc = 11;
          continue;
        case 11:
          await s.textShow(2809);
          pc = 12;
          continue;
        case 12:
          await s.textEnd();
          pc = 13;
          continue;
        case 13:
          s.sound('bgm', 37);
          pc = 14;
          continue;
        case 14:
          await s.continueText();
          pc = 15;
          continue;
        case 15:
          await s.textEnd();
          pc = 16;
          continue;
        case 16:
          s.textRemoveAll();
          pc = 17;
          continue;
        case 17:
          await s.fade(FadeDirection.toBlack, 16);
          pc = 18;
          continue;
        case 18:
          await s.clearScreen();
          pc = 19;
          continue;
        case 19:
          await s.fade(FadeDirection.fromBlack, 16);
          pc = 20;
          continue;
        case 20:
          s.moveUnit('MOVE_1STEP', [16, 30, 3]);
          pc = 21;
          continue;
        case 21:
          await s.waitUnitMoving();
          pc = 22;
          continue;
        case 22:
          s.setSlot(2, 37);
          pc = 23;
          continue;
        case 23:
          await s.call(Sym('EventScr_SetBackground'));
          pc = 24;
          continue;
        case 24:
          await s.textShow(2810);
          pc = 25;
          continue;
        case 25:
          await s.textEnd();
          pc = 26;
          continue;
        case 26:
          s.textRemoveAll();
          pc = 27;
          continue;
        case 27:
          s.placeholder('EvtBgmFadeIn');
          pc = 28;
          continue;
        case 28:
          await s.fade(FadeDirection.toBlack, 16);
          pc = 29;
          continue;
        case 29:
          s.hideFaction('blue');
          pc = 30;
          continue;
        case 30:
          s.hideFaction('red');
          pc = 31;
          continue;
        case 31:
          s.hideFaction('green');
          pc = 32;
          continue;
        case 32:
          s.setSlot(11, 786432);
          pc = 33;
          continue;
        case 33:
          await s.loadMap(66);
          pc = 34;
          continue;
        case 34:
          s.placeholder('UNIT_COLORS');
          pc = 35;
          continue;
        case 35:
          s.loadUnits(2, Sym('frontier_df3_unitdef_b_012_911C34', 256));
          pc = 36;
          continue;
        case 36:
          await s.waitUnitMoving();
          pc = 37;
          continue;
        case 37:
          await s.fade(FadeDirection.fromBlack, 16);
          pc = 38;
          continue;
        case 38:
          s.loadUnits(2, Sym('frontier_df3_unitdef_b_012_911C34', 316));
          pc = 39;
          continue;
        case 39:
          await s.waitUnitMoving();
          pc = 40;
          continue;
        case 40:
          s.sound('se', 177);
          pc = 41;
          continue;
        case 41:
          await s.tileChange(0);
          pc = 42;
          continue;
        case 42:
          s.moveUnit('MOVE', [0, 109, 7, 6]);
          pc = 43;
          continue;
        case 43:
          await s.waitUnitMoving();
          pc = 44;
          continue;
        case 44:
          await s.tileRevert(0);
          pc = 45;
          continue;
        case 45:
          s.loadUnits(2, Sym('frontier_df3_unitdef_b_012_911C34', 356));
          pc = 46;
          continue;
        case 46:
          await s.waitUnitMoving();
          pc = 47;
          continue;
        case 47:
          await s.fade(FadeDirection.toBlack, 16);
          pc = 48;
          continue;
        case 48:
          s.hideFaction('blue');
          pc = 49;
          continue;
        case 49:
          s.hideFaction('red');
          pc = 50;
          continue;
        case 50:
          s.hideFaction('green');
          pc = 51;
          continue;
        case 51:
          s.checkSlotValue('mode');
          pc = 52;
          continue;
        case 52:
          s.setSlot(1, 2);
          pc = 53;
          continue;
        case 53:
          if (s.slotInt(12) != s.slotInt(1)) { pc = 61; } else { pc = 54; }
          continue;
        case 54:
          s.setSlot(2, 19);
          pc = 55;
          continue;
        case 55:
          await s.call(Sym('EventScr_SetBackground'));
          pc = 56;
          continue;
        case 56:
          await s.textShow(2811);
          pc = 57;
          continue;
        case 57:
          await s.textEnd();
          pc = 58;
          continue;
        case 58:
          s.textRemoveAll();
          pc = 59;
          continue;
        case 59:
          await s.fade(FadeDirection.toBlack, 16);
          pc = 60;
          continue;
        case 60:
          await s.clearScreen();
          pc = 61;
          continue;
        case 61:
          pc = 62;
          continue;
        case 62:
          s.checkSlotValue('mode');
          pc = 63;
          continue;
        case 63:
          s.setSlot(1, 2);
          pc = 64;
          continue;
        case 64:
          if (s.slotInt(12) == s.slotInt(1)) { pc = 89; } else { pc = 65; }
          continue;
        case 65:
          s.sound('bgm', 46);
          pc = 66;
          continue;
        case 66:
          s.placeholder('EvtSetLoadUnitNoREDA');
          pc = 67;
          continue;
        case 67:
          s.loadUnits(2, Sym('UnitDef_Ch16AAlly_8'));
          pc = 68;
          continue;
        case 68:
          await s.waitUnitMoving();
          pc = 69;
          continue;
        case 69:
          s.unitStateOp('remu', 64);
          pc = 70;
          continue;
        case 70:
          s.unitStateOp('remu', 87);
          pc = 71;
          continue;
        case 71:
          await s.fade(FadeDirection.fromBlack, 16);
          pc = 72;
          continue;
        case 72:
          s.setSlot(2, 64);
          pc = 73;
          continue;
        case 73:
          s.moveUnit('MOVE_CLOSEST', [65535, 65533, 7, 11]);
          pc = 74;
          continue;
        case 74:
          await s.call(Sym('EventScr_UnitWarpIN'));
          pc = 75;
          continue;
        case 75:
          s.setSlot(2, 87);
          pc = 76;
          continue;
        case 76:
          s.moveUnit('MOVE_CLOSEST', [65535, 65533, 8, 11]);
          pc = 77;
          continue;
        case 77:
          await s.call(Sym('EventScr_UnitWarpIN'));
          pc = 78;
          continue;
        case 78:
          s.loadUnits(2, Sym('UnitDef_Ch16AAlly_8'));
          pc = 79;
          continue;
        case 79:
          await s.waitUnitMoving();
          pc = 80;
          continue;
        case 80:
          s.showCursorAtUnit(128);
          pc = 81;
          continue;
        case 81:
          await s.stall(60);
          pc = 82;
          continue;
        case 82:
          await s.endCursor();
          pc = 83;
          continue;
        case 83:
          s.setSlot(2, 21);
          pc = 84;
          continue;
        case 84:
          s.setSlot(3, 2812);
          pc = 85;
          continue;
        case 85:
          await s.call(Sym('Event_TextWithBG'));
          pc = 86;
          continue;
        case 86:
          s.moveUnit('MOVE_1STEP', [16, 128, 0]);
          pc = 87;
          continue;
        case 87:
          s.moveUnit('MOVE_1STEP', [16, 129, 1]);
          pc = 88;
          continue;
        case 88:
          await s.waitUnitMoving();
          pc = 89;
          continue;
        case 89:
          pc = 90;
          continue;
        case 90:
          s.checkSlotValue('mode');
          pc = 91;
          continue;
        case 91:
          s.setSlot(1, 2);
          pc = 92;
          continue;
        case 92:
          if (s.slotInt(12) != s.slotInt(1)) { pc = 98; } else { pc = 93; }
          continue;
        case 93:
          s.loadUnits(2, Sym('UnitDef_Ch16AAlly_8'));
          pc = 94;
          continue;
        case 94:
          await s.waitUnitMoving();
          pc = 95;
          continue;
        case 95:
          s.moveUnit('MOVE_1STEP', [65535, 128, 0]);
          pc = 96;
          continue;
        case 96:
          s.moveUnit('MOVE_1STEP', [65535, 129, 1]);
          pc = 97;
          continue;
        case 97:
          await s.fade(FadeDirection.fromBlack, 16);
          pc = 98;
          continue;
        case 98:
          pc = 99;
          continue;
        case 99:
          s.loadUnits(2, Sym('frontier_df3_unitdef_b_013_911E38'));
          pc = 100;
          continue;
        case 100:
          await s.waitUnitMoving();
          pc = 101;
          continue;
        case 101:
          s.sound('se', 177);
          pc = 102;
          continue;
        case 102:
          await s.tileChange(0);
          pc = 103;
          continue;
        case 103:
          s.moveUnit('MOVE', [16, 64, 7, 5]);
          pc = 104;
          continue;
        case 104:
          await s.waitUnitMoving();
          pc = 105;
          continue;
        case 105:
          s.moveUnit('MOVE', [16, 87, 8, 6]);
          pc = 106;
          continue;
        case 106:
          await s.waitUnitMoving();
          pc = 107;
          continue;
        case 107:
          await s.tileRevert(0);
          pc = 108;
          continue;
        case 108:
          s.loadUnits(2, Sym('frontier_df3_unitdef_b_013_911E38', 60));
          pc = 109;
          continue;
        case 109:
          await s.waitUnitMoving();
          pc = 110;
          continue;
        case 110:
          s.moveUnit('MOVE_1STEP', [16, 128, 1]);
          pc = 111;
          continue;
        case 111:
          await s.waitUnitMoving();
          pc = 112;
          continue;
        case 112:
          s.moveUnit('MOVE_1STEP', [16, 129, 0]);
          pc = 113;
          continue;
        case 113:
          await s.waitUnitMoving();
          pc = 114;
          continue;
        case 114:
          s.sound('bgm', 46);
          pc = 115;
          continue;
        case 115:
          s.showCursorAtUnit(128);
          pc = 116;
          continue;
        case 116:
          await s.stall(60);
          pc = 117;
          continue;
        case 117:
          await s.endCursor();
          pc = 118;
          continue;
        case 118:
          s.setSlot(2, 21);
          pc = 119;
          continue;
        case 119:
          await s.call(Sym('EventScr_SetBackground'));
          pc = 120;
          continue;
        case 120:
          s.checkSlotValue('mode');
          pc = 121;
          continue;
        case 121:
          s.setSlot(1, 2);
          pc = 122;
          continue;
        case 122:
          if (s.slotInt(12) != s.slotInt(1)) { pc = 126; } else { pc = 123; }
          continue;
        case 123:
          await s.textShow(2813);
          pc = 124;
          continue;
        case 124:
          await s.textEnd();
          pc = 125;
          continue;
        case 125:
          pc = 130;
          continue;
        case 126:
          pc = 127;
          continue;
        case 127:
          await s.textShow(2814);
          pc = 128;
          continue;
        case 128:
          await s.textEnd();
          pc = 129;
          continue;
        case 129:
          s.placeholder('EvtBgmFadeIn');
          pc = 130;
          continue;
        case 130:
          pc = 131;
          continue;
        case 131:
          s.textRemoveAll();
          pc = 132;
          continue;
        case 132:
          await s.fade(FadeDirection.toBlack, 16);
          pc = 133;
          continue;
        case 133:
          s.hideFaction('blue');
          pc = 134;
          continue;
        case 134:
          s.hideFaction('red');
          pc = 135;
          continue;
        case 135:
          s.hideFaction('green');
          pc = 136;
          continue;
        case 136:
          s.setSlot(2, 19);
          pc = 137;
          continue;
        case 137:
          await s.call(Sym('EventScr_SetBackground'));
          pc = 138;
          continue;
        case 138:
          s.checkSlotValue('mode');
          pc = 139;
          continue;
        case 139:
          s.setSlot(1, 2);
          pc = 140;
          continue;
        case 140:
          if (s.slotInt(12) != s.slotInt(1)) { pc = 144; } else { pc = 141; }
          continue;
        case 141:
          await s.textShow(2815);
          pc = 142;
          continue;
        case 142:
          await s.textEnd();
          pc = 143;
          continue;
        case 143:
          pc = 148;
          continue;
        case 144:
          pc = 145;
          continue;
        case 145:
          s.sound('bgm', 45);
          pc = 146;
          continue;
        case 146:
          await s.textShow(2816);
          pc = 147;
          continue;
        case 147:
          await s.textEnd();
          pc = 148;
          continue;
        case 148:
          pc = 149;
          continue;
        case 149:
          s.textRemoveAll();
          pc = 150;
          continue;
        case 150:
          await s.fade(FadeDirection.toBlack, 16);
          pc = 151;
          continue;
        case 151:
          s.checkSlotValue('mode');
          pc = 152;
          continue;
        case 152:
          s.setSlot(1, 2);
          pc = 153;
          continue;
        case 153:
          if (s.slotInt(12) != s.slotInt(1)) { pc = 174; } else { pc = 154; }
          continue;
        case 154:
          await s.clearScreen();
          pc = 155;
          continue;
        case 155:
          await s.cameraTo(0, 0, centered: false);
          pc = 156;
          continue;
        case 156:
          s.sound('bgm', 45);
          pc = 157;
          continue;
        case 157:
          await s.fade(FadeDirection.fromBlack, 16);
          pc = 158;
          continue;
        case 158:
          s.loadUnits(2, Sym('frontier_df3_unitdef_b_013_911E38', 120));
          pc = 159;
          continue;
        case 159:
          await s.waitUnitMoving();
          pc = 160;
          continue;
        case 160:
          s.showCursorAtUnit(87);
          pc = 161;
          continue;
        case 161:
          await s.stall(60);
          pc = 162;
          continue;
        case 162:
          await s.endCursor();
          pc = 163;
          continue;
        case 163:
          s.setSlot(2, 19);
          pc = 164;
          continue;
        case 164:
          s.setSlot(3, 2817);
          pc = 165;
          continue;
        case 165:
          await s.call(Sym('Event_TextWithBG'));
          pc = 166;
          continue;
        case 166:
          s.setSlot(2, 64);
          pc = 167;
          continue;
        case 167:
          await s.call(Sym('EventScr_UnitWarpOUT'));
          pc = 168;
          continue;
        case 168:
          s.setSlot(2, 87);
          pc = 169;
          continue;
        case 169:
          await s.call(Sym('EventScr_UnitWarpOUT'));
          pc = 170;
          continue;
        case 170:
          await s.fade(FadeDirection.toBlack, 16);
          pc = 171;
          continue;
        case 171:
          s.hideFaction('blue');
          pc = 172;
          continue;
        case 172:
          s.hideFaction('red');
          pc = 173;
          continue;
        case 173:
          s.hideFaction('green');
          pc = 174;
          continue;
        case 174:
          pc = 175;
          continue;
        case 175:
          s.placeholder('UNIT_COLORS');
          pc = 176;
          continue;
        case 176:
          return;
        default:
          return;
      }
    }
}

/// `EventScr_Ch16A_12`
Future<void> Ch16A_12(Scene s) async {
    var pc = 0;
    while (true) {
      switch (pc) {
        case 0:
          await s.fade(FadeDirection.toBlack, 16);
          pc = 1;
          continue;
        case 1:
          s.hideFaction('blue');
          pc = 2;
          continue;
        case 2:
          s.hideFaction('red');
          pc = 3;
          continue;
        case 3:
          s.hideFaction('green');
          pc = 4;
          continue;
        case 4:
          s.sound('bgm', 50);
          pc = 5;
          continue;
        case 5:
          s.setSlot(2, 15);
          pc = 6;
          continue;
        case 6:
          await s.call(Sym('EventScr_SetBackground'));
          pc = 7;
          continue;
        case 7:
          await s.textShow(2825);
          pc = 8;
          continue;
        case 8:
          await s.textEnd();
          pc = 9;
          continue;
        case 9:
          s.textRemoveAll();
          pc = 10;
          continue;
        case 10:
          await s.fade(FadeDirection.toBlack, 16);
          pc = 11;
          continue;
        case 11:
          s.setSlot(11, 0);
          pc = 12;
          continue;
        case 12:
          await s.loadMap(66);
          pc = 13;
          continue;
        case 13:
          await s.fade(FadeDirection.fromBlack, 16);
          pc = 14;
          continue;
        case 14:
          s.loadUnits(2, Sym('frontier_df3_unitdef_b_013_911E38_tail'));
          pc = 15;
          continue;
        case 15:
          await s.waitUnitMoving();
          pc = 16;
          continue;
        case 16:
          s.sound('se', 177);
          pc = 17;
          continue;
        case 17:
          await s.tileChange(0);
          pc = 18;
          continue;
        case 18:
          s.loadUnits(2, Sym('UnitDef_Ch16AMixed_1'));
          pc = 19;
          continue;
        case 19:
          await s.waitUnitMoving();
          pc = 20;
          continue;
        case 20:
          s.showCursorAtUnit(251);
          pc = 21;
          continue;
        case 21:
          await s.stall(60);
          pc = 22;
          continue;
        case 22:
          await s.endCursor();
          pc = 23;
          continue;
        case 23:
          s.placeholder('EvtBgmFadeIn');
          pc = 24;
          continue;
        case 24:
          s.setSlot(2, 19);
          pc = 25;
          continue;
        case 25:
          await s.call(Sym('EventScr_SetBackground'));
          pc = 26;
          continue;
        case 26:
          await s.textShow(2826);
          pc = 27;
          continue;
        case 27:
          await s.textEnd();
          pc = 28;
          continue;
        case 28:
          await s.fade(FadeDirection.toBlack, 4);
          pc = 29;
          continue;
        case 29:
          s.textRemoveAll();
          pc = 30;
          continue;
        case 30:
          s.hideFaction('blue');
          pc = 31;
          continue;
        case 31:
          s.hideFaction('red');
          pc = 32;
          continue;
        case 32:
          s.hideFaction('green');
          pc = 33;
          continue;
        case 33:
          s.setSlot(11, 262158);
          pc = 34;
          continue;
        case 34:
          await s.loadMap(16);
          pc = 35;
          continue;
        case 35:
          s.placeholder('EvtSetLoadUnitNoREDA');
          pc = 36;
          continue;
        case 36:
          s.loadUnits(2, Sym('UnitDef_Ch16AAlly_0'));
          pc = 37;
          continue;
        case 37:
          await s.waitUnitMoving();
          pc = 38;
          continue;
        case 38:
          await s.fade(FadeDirection.fromBlack, 4);
          pc = 39;
          continue;
        case 39:
          s.showCursorAtUnit(15);
          pc = 40;
          continue;
        case 40:
          await s.stall(60);
          pc = 41;
          continue;
        case 41:
          await s.endCursor();
          pc = 42;
          continue;
        case 42:
          s.sound('bgm', 49);
          pc = 43;
          continue;
        case 43:
          s.setTextType(0);
          pc = 44;
          continue;
        case 44:
          await s.textShow(2827);
          pc = 45;
          continue;
        case 45:
          await s.textEnd();
          pc = 46;
          continue;
        case 46:
          s.textRemoveAll();
          pc = 47;
          continue;
        case 47:
          s.loadUnits(2, Sym('UnitDef_Ch16AAlly_0'));
          pc = 48;
          continue;
        case 48:
          await s.waitUnitMoving();
          pc = 49;
          continue;
        case 49:
          s.showCursorAtUnit(2);
          pc = 50;
          continue;
        case 50:
          await s.stall(60);
          pc = 51;
          continue;
        case 51:
          await s.endCursor();
          pc = 52;
          continue;
        case 52:
          s.setTextType(0);
          pc = 53;
          continue;
        case 53:
          await s.textShow(2828);
          pc = 54;
          continue;
        case 54:
          await s.textEnd();
          pc = 55;
          continue;
        case 55:
          s.textRemoveAll();
          pc = 56;
          continue;
        case 56:
          s.moveUnit('MOVE', [0, 1, 12, 11]);
          pc = 57;
          continue;
        case 57:
          s.moveUnit('MOVE', [0, 15, 14, 11]);
          pc = 58;
          continue;
        case 58:
          s.moveUnit('MOVE', [0, 2, 13, 11]);
          pc = 59;
          continue;
        case 59:
          await s.stall(20, cancellable: false);
          pc = 60;
          continue;
        case 60:
          s.placeholder('EvtBgmFadeIn');
          pc = 61;
          continue;
        case 61:
          await s.fade(FadeDirection.toBlack, 16);
          pc = 62;
          continue;
        case 62:
          await s.waitUnitMoving();
          pc = 63;
          continue;
        case 63:
          s.hideFaction('blue');
          pc = 64;
          continue;
        case 64:
          s.setSlot(11, 0);
          pc = 65;
          continue;
        case 65:
          await s.loadMap(67);
          pc = 66;
          continue;
        case 66:
          s.loadUnits(2, Sym('frontier_df3_unitdef_b_015_91206C', 20));
          pc = 67;
          continue;
        case 67:
          await s.waitUnitMoving();
          pc = 68;
          continue;
        case 68:
          s.sound('bgm', 149);
          pc = 69;
          continue;
        case 69:
          await s.fade(FadeDirection.fromBlack, 16);
          pc = 70;
          continue;
        case 70:
          s.loadUnits(2, Sym('UnitDef_Ch16AAlly_13'));
          pc = 71;
          continue;
        case 71:
          s.setTextType(4);
          pc = 72;
          continue;
        case 72:
          s.setSlot(11, 4194312);
          pc = 73;
          continue;
        case 73:
          await s.textShow(2829);
          pc = 74;
          continue;
        case 74:
          await s.textEnd();
          pc = 75;
          continue;
        case 75:
          s.textRemoveAll();
          pc = 76;
          continue;
        case 76:
          s.setSlot(11, 5767216);
          pc = 77;
          continue;
        case 77:
          await s.textShow(2830);
          pc = 78;
          continue;
        case 78:
          await s.textEnd();
          pc = 79;
          continue;
        case 79:
          s.textRemoveAll();
          pc = 80;
          continue;
        case 80:
          s.setSlot(11, 4718720);
          pc = 81;
          continue;
        case 81:
          await s.textShow(2831);
          pc = 82;
          continue;
        case 82:
          await s.textEnd();
          pc = 83;
          continue;
        case 83:
          s.textRemoveAll();
          pc = 84;
          continue;
        case 84:
          await s.waitUnitMoving();
          pc = 85;
          continue;
        case 85:
          s.showCursorAtUnit(15);
          pc = 86;
          continue;
        case 86:
          await s.stall(60);
          pc = 87;
          continue;
        case 87:
          await s.endCursor();
          pc = 88;
          continue;
        case 88:
          s.setSlot(2, 15);
          pc = 89;
          continue;
        case 89:
          await s.call(Sym('EventScr_SetBackground'));
          pc = 90;
          continue;
        case 90:
          await s.textShow(2832);
          pc = 91;
          continue;
        case 91:
          await s.textEnd();
          pc = 92;
          continue;
        case 92:
          s.textRemoveAll();
          pc = 93;
          continue;
        case 93:
          s.placeholder('EvtBgmFadeIn');
          pc = 94;
          continue;
        case 94:
          await s.fade(FadeDirection.toBlack, 16);
          pc = 95;
          continue;
        case 95:
          s.hideFaction('blue');
          pc = 96;
          continue;
        case 96:
          s.hideFaction('red');
          pc = 97;
          continue;
        case 97:
          s.hideFaction('green');
          pc = 98;
          continue;
        case 98:
          await s.stall(60);
          pc = 99;
          continue;
        case 99:
          s.setSlot(11, 262158);
          pc = 100;
          continue;
        case 100:
          await s.loadMap(16);
          pc = 101;
          continue;
        case 101:
          s.placeholder('EvtSetLoadUnitNoREDA');
          pc = 102;
          continue;
        case 102:
          s.loadUnits(2, Sym('UnitDef_Ch16AAlly_1'));
          pc = 103;
          continue;
        case 103:
          await s.waitUnitMoving();
          pc = 104;
          continue;
        case 104:
          await s.fade(FadeDirection.fromBlack, 16);
          pc = 105;
          continue;
        case 105:
          s.showCursorAtUnit(2);
          pc = 106;
          continue;
        case 106:
          await s.stall(60);
          pc = 107;
          continue;
        case 107:
          await s.endCursor();
          pc = 108;
          continue;
        case 108:
          s.setTextType(0);
          pc = 109;
          continue;
        case 109:
          await s.textShow(2833);
          pc = 110;
          continue;
        case 110:
          await s.textEnd();
          pc = 111;
          continue;
        case 111:
          s.textRemoveAll();
          pc = 112;
          continue;
        case 112:
          s.placeholder('STARTFADE');
          pc = 113;
          continue;
        case 113:
          s.placeholder('EvtColorFadeSetup');
          pc = 114;
          continue;
        case 114:
          s.placeholder('ASMC2');
          pc = 115;
          continue;
        case 115:
          s.setSlot(11, 196621);
          pc = 116;
          continue;
        case 116:
          await s.tileChange(65535);
          pc = 117;
          continue;
        case 117:
          s.setSlot(11, 196622);
          pc = 118;
          continue;
        case 118:
          await s.tileChange(65535);
          pc = 119;
          continue;
        case 119:
          s.placeholder('EvtColorFadeSetup');
          pc = 120;
          continue;
        case 120:
          s.evBitMod('evbit', true, 6);
          pc = 121;
          continue;
        case 121:
          s.loadUnits(2, Sym('UnitDef_Ch16AAlly_1'));
          pc = 122;
          continue;
        case 122:
          await s.stall(20);
          pc = 123;
          continue;
        case 123:
          await s.fade(FadeDirection.toBlack, 4);
          pc = 124;
          continue;
        case 124:
          await s.waitUnitMoving();
          pc = 125;
          continue;
        case 125:
          s.evBitMod('evbit', false, 6);
          pc = 126;
          continue;
        case 126:
          s.hideFaction('blue');
          pc = 127;
          continue;
        case 127:
          s.setSlot(11, 0);
          pc = 128;
          continue;
        case 128:
          await s.loadMap(71);
          pc = 129;
          continue;
        case 129:
          await s.fade(FadeDirection.fromBlack, 16);
          pc = 130;
          continue;
        case 130:
          s.loadUnits(2, Sym('UnitDef_Ch16AAlly_15'));
          pc = 131;
          continue;
        case 131:
          await s.waitUnitMoving();
          pc = 132;
          continue;
        case 132:
          s.showCursorAtUnit(15);
          pc = 133;
          continue;
        case 133:
          await s.stall(60);
          pc = 134;
          continue;
        case 134:
          await s.endCursor();
          pc = 135;
          continue;
        case 135:
          s.setSlot(2, 69);
          pc = 136;
          continue;
        case 136:
          await s.call(Sym('EventScr_SetBackground'));
          pc = 137;
          continue;
        case 137:
          s.placeholder('EvtBgmFadeIn');
          pc = 138;
          continue;
        case 138:
          await s.textShow(2834);
          pc = 139;
          continue;
        case 139:
          await s.textEnd();
          pc = 140;
          continue;
        case 140:
          s.placeholder('EvtBgmFadeIn');
          pc = 141;
          continue;
        case 141:
          await s.fade(FadeDirection.toBlack, 4);
          pc = 142;
          continue;
        case 142:
          s.textRemoveAll();
          pc = 143;
          continue;
        case 143:
          await s.clearScreen();
          pc = 144;
          continue;
        case 144:
          await s.fade(FadeDirection.fromBlack, 4);
          pc = 145;
          continue;
        case 145:
          s.showCursorAtUnit(15);
          pc = 146;
          continue;
        case 146:
          await s.stall(60);
          pc = 147;
          continue;
        case 147:
          await s.endCursor();
          pc = 148;
          continue;
        case 148:
          s.setSlot(2, 69);
          pc = 149;
          continue;
        case 149:
          await s.call(Sym('EventScr_SetBackground'));
          pc = 150;
          continue;
        case 150:
          await s.textShow(2835);
          pc = 151;
          continue;
        case 151:
          await s.textEnd();
          pc = 152;
          continue;
        case 152:
          s.sound('se', 747);
          pc = 153;
          continue;
        case 153:
          await s.fade(FadeDirection.toWhite, 4);
          pc = 154;
          continue;
        case 154:
          s.textRemoveAll();
          pc = 155;
          continue;
        case 155:
          s.setSlot(2, 69);
          pc = 156;
          continue;
        case 156:
          await s.call(Sym('EventScr_Ch16A_1'));
          pc = 157;
          continue;
        case 157:
          s.placeholder('EvtBgmFadeIn');
          pc = 158;
          continue;
        case 158:
          s.setTextType(1);
          pc = 159;
          continue;
        case 159:
          await s.textShow(2836);
          pc = 160;
          continue;
        case 160:
          await s.textEnd();
          pc = 161;
          continue;
        case 161:
          s.textRemoveAll();
          pc = 162;
          continue;
        case 162:
          await s.fade(FadeDirection.toBlack, 16);
          pc = 163;
          continue;
        case 163:
          await s.clearScreen();
          pc = 164;
          continue;
        case 164:
          await s.fade(FadeDirection.fromBlack, 4);
          pc = 165;
          continue;
        case 165:
          s.loadUnits(2, Sym('frontier_df3_unitdef_b_016_912198_residue'));
          pc = 166;
          continue;
        case 166:
          await s.waitUnitMoving();
          pc = 167;
          continue;
        case 167:
          s.sound('se', 177);
          pc = 168;
          continue;
        case 168:
          await s.tileChange(0);
          pc = 169;
          continue;
        case 169:
          s.loadUnits(2, Sym('frontier_df3_unitdef_b_016_912198', 60));
          pc = 170;
          continue;
        case 170:
          await s.waitUnitMoving();
          pc = 171;
          continue;
        case 171:
          s.sound('se', 177);
          pc = 172;
          continue;
        case 172:
          await s.tileChange(1);
          pc = 173;
          continue;
        case 173:
          s.loadUnits(2, Sym('frontier_df3_unitdef_b_016_912198', 100));
          pc = 174;
          continue;
        case 174:
          await s.waitUnitMoving();
          pc = 175;
          continue;
        case 175:
          s.showCursorAtUnit(2);
          pc = 176;
          continue;
        case 176:
          await s.stall(60);
          pc = 177;
          continue;
        case 177:
          await s.endCursor();
          pc = 178;
          continue;
        case 178:
          s.setSlot(2, 69);
          pc = 179;
          continue;
        case 179:
          await s.call(Sym('EventScr_SetBackground'));
          pc = 180;
          continue;
        case 180:
          await s.textShow(2837);
          pc = 181;
          continue;
        case 181:
          await s.textEnd();
          pc = 182;
          continue;
        case 182:
          s.textRemoveAll();
          pc = 183;
          continue;
        case 183:
          await s.call(Sym('data_085B9BBC', 360));
          pc = 184;
          continue;
        case 184:
          s.setSlot(3, 146);
          pc = 185;
          continue;
        case 185:
          await s.giveItem(15, 3);
          pc = 186;
          continue;
        case 186:
          await s.textShow(2838);
          pc = 187;
          continue;
        case 187:
          await s.textEnd();
          pc = 188;
          continue;
        case 188:
          s.textRemoveAll();
          pc = 189;
          continue;
        case 189:
          await s.call(Sym('data_085B9BBC', 360));
          pc = 190;
          continue;
        case 190:
          s.setSlot(3, 133);
          pc = 191;
          continue;
        case 191:
          await s.giveItem(1, 3);
          pc = 192;
          continue;
        case 192:
          s.checkSlotValue('mode');
          pc = 193;
          continue;
        case 193:
          s.setSlot(1, 2);
          pc = 194;
          continue;
        case 194:
          if (s.slotInt(12) != s.slotInt(1)) { pc = 198; } else { pc = 195; }
          continue;
        case 195:
          await s.textShow(2839);
          pc = 196;
          continue;
        case 196:
          await s.textEnd();
          pc = 197;
          continue;
        case 197:
          pc = 201;
          continue;
        case 198:
          pc = 199;
          continue;
        case 199:
          await s.textShow(2840);
          pc = 200;
          continue;
        case 200:
          await s.textEnd();
          pc = 201;
          continue;
        case 201:
          pc = 202;
          continue;
        case 202:
          await s.fade(FadeDirection.toBlack, 16);
          pc = 203;
          continue;
        case 203:
          s.textRemoveAll();
          pc = 204;
          continue;
        case 204:
          s.hideFaction('blue');
          pc = 205;
          continue;
        case 205:
          s.hideFaction('red');
          pc = 206;
          continue;
        case 206:
          s.hideFaction('green');
          pc = 207;
          continue;
        case 207:
          s.setSlot(11, 262158);
          pc = 208;
          continue;
        case 208:
          await s.loadMap(16);
          pc = 209;
          continue;
        case 209:
          s.setSlot(11, 196621);
          pc = 210;
          continue;
        case 210:
          await s.tileChange(65535);
          pc = 211;
          continue;
        case 211:
          s.setSlot(11, 196622);
          pc = 212;
          continue;
        case 212:
          await s.tileChange(65535);
          pc = 213;
          continue;
        case 213:
          s.loadUnits(2, Sym('frontier_df3_unitdef_b_010_9119D0'));
          pc = 214;
          continue;
        case 214:
          await s.waitUnitMoving();
          pc = 215;
          continue;
        case 215:
          await s.fade(FadeDirection.fromBlack, 16);
          pc = 216;
          continue;
        case 216:
          s.loadUnits(2, Sym('UnitDef_Ch16AAlly_3'));
          pc = 217;
          continue;
        case 217:
          await s.waitUnitMoving();
          pc = 218;
          continue;
        case 218:
          s.setSlot(11, 196621);
          pc = 219;
          continue;
        case 219:
          await s.tileRevert(65535);
          pc = 220;
          continue;
        case 220:
          s.setSlot(11, 196622);
          pc = 221;
          continue;
        case 221:
          await s.tileRevert(65535);
          pc = 222;
          continue;
        case 222:
          s.showCursorAtUnit(25);
          pc = 223;
          continue;
        case 223:
          await s.stall(60);
          pc = 224;
          continue;
        case 224:
          await s.endCursor();
          pc = 225;
          continue;
        case 225:
          s.sound('bgm', 49);
          pc = 226;
          continue;
        case 226:
          s.checkSlotValue('mode');
          pc = 227;
          continue;
        case 227:
          s.setSlot(1, 2);
          pc = 228;
          continue;
        case 228:
          if (s.slotInt(12) != s.slotInt(1)) { pc = 234; } else { pc = 229; }
          continue;
        case 229:
          s.setTextType(0);
          pc = 230;
          continue;
        case 230:
          await s.textShow(2841);
          pc = 231;
          continue;
        case 231:
          await s.textEnd();
          pc = 232;
          continue;
        case 232:
          s.textRemoveAll();
          pc = 233;
          continue;
        case 233:
          pc = 239;
          continue;
        case 234:
          pc = 235;
          continue;
        case 235:
          s.setTextType(0);
          pc = 236;
          continue;
        case 236:
          await s.textShow(2842);
          pc = 237;
          continue;
        case 237:
          await s.textEnd();
          pc = 238;
          continue;
        case 238:
          s.textRemoveAll();
          pc = 239;
          continue;
        case 239:
          pc = 240;
          continue;
        case 240:
          s.loadUnits(2, Sym('UnitDef_Ch16AAlly_4'));
          pc = 241;
          continue;
        case 241:
          await s.waitUnitMoving();
          pc = 242;
          continue;
        case 242:
          await s.fade(FadeDirection.toBlack, 16);
          pc = 243;
          continue;
        case 243:
          await s.waitUnitMoving();
          pc = 244;
          continue;
        case 244:
          return;
        default:
          return;
      }
    }
}

/// `EventScr_Ch16A_9`
Future<void> Ch16A_9(Scene s) async {
    s.setSlot(2, Sym('UnitDef_Ch16AEnemy_2'));
    await s.call(Sym('EventScr_LoadReinforce'));
    s.setSlot(2, Sym('UnitDef_Ch16AEnemy_3'));
    await s.call(Sym('EventScr_LoadReinforce'));
    await s.cameraTo(19, 27, centered: false);
    s.setSlot(2, Sym('UnitDef_Ch16AEnemy_4'));
    await s.call(Sym('EventScr_LoadReinforce'));
    s.setSlot(2, Sym('frontier_df3_unitdef_b_009_91187C'));
    await s.call(Sym('EventScr_LoadReinforce'));
    s.evBitMod('evbit', true, 7);
    return;
}

/// `EventScr_Ch16B_3`
Future<void> Ch16B_3(Scene s) async {
    var pc = 0;
    while (true) {
      switch (pc) {
        case 0:
          s.setSlot(2, Sym('UnitDef_Ch16BEnemy_2'));
          pc = 1;
          continue;
        case 1:
          await s.call(Sym('EventScr_LoadReinforce'));
          pc = 2;
          continue;
        case 2:
          s.setSlot(2, Sym('frontier_df3_unitdef_b_039_91BED4'));
          pc = 3;
          continue;
        case 3:
          await s.call(Sym('EventScr_LoadReinforce'));
          pc = 4;
          continue;
        case 4:
          s.counterDec(0);
          pc = 5;
          continue;
        case 5:
          s.evBitMod('flag', false, 14);
          pc = 6;
          continue;
        case 6:
          s.counterCheck(0);
          pc = 7;
          continue;
        case 7:
          if (s.slotInt(12) != s.slotInt(0)) { pc = 9; } else { pc = 8; }
          continue;
        case 8:
          s.evBitMod('flag', true, 14);
          pc = 9;
          continue;
        case 9:
          pc = 10;
          continue;
        case 10:
          s.evBitMod('evbit', true, 7);
          pc = 11;
          continue;
        case 11:
          return;
        default:
          return;
      }
    }
}

/// `EventScr_Ch16B_5`
Future<void> Ch16B_5(Scene s) async {
    var pc = 0;
    while (true) {
      switch (pc) {
        case 0:
          s.setSlot(2, Sym('frontier_df3_unitdef_b_040_91BF9C'));
          pc = 1;
          continue;
        case 1:
          await s.call(Sym('EventScr_LoadReinforce'));
          pc = 2;
          continue;
        case 2:
          s.setSlot(2, Sym('UnitDef_Ch16BEnemy_4'));
          pc = 3;
          continue;
        case 3:
          await s.call(Sym('EventScr_LoadReinforce'));
          pc = 4;
          continue;
        case 4:
          s.counterDec(1);
          pc = 5;
          continue;
        case 5:
          s.evBitMod('flag', false, 13);
          pc = 6;
          continue;
        case 6:
          s.counterCheck(1);
          pc = 7;
          continue;
        case 7:
          if (s.slotInt(12) != s.slotInt(0)) { pc = 9; } else { pc = 8; }
          continue;
        case 8:
          s.evBitMod('flag', true, 13);
          pc = 9;
          continue;
        case 9:
          pc = 10;
          continue;
        case 10:
          s.evBitMod('evbit', true, 7);
          pc = 11;
          continue;
        case 11:
          return;
        default:
          return;
      }
    }
}

/// `EventScr_Ch16a_BeginningScene`
Future<void> Ch16a_BeginningScene(Scene s) async {
    await s.call(Sym('EventScr_Ch16A_11'));
    s.setSlot(11, 0);
    await s.loadMap(16);
    s.loadUnits(1, Sym('frontier_df3_unitdef_b_007_911200_tail'));
    await s.waitUnitMoving();
    s.loadUnits(1, Sym('UnitDef_Ch16AEnemy_0'));
    await s.waitUnitMoving();
    s.setSlot(2, Sym('UnitDef_Ch16AEnemy_1'));
    s.setSlot(3, 1);
    await s.call(Sym('EventScr_LoadUnitForTutorial'));
    s.hideFaction('blue');
    await s.call(Sym('data_085B9BBC', 512));
    s.evBitMod('flag', true, 12);
    return;
}

/// `EventScr_Ch16b_BeginningScene`
Future<void> Ch16b_BeginningScene(Scene s) async {
    s.setSlot(2, Sym('frontier_df3_unitdef_b_042_91C230'));
    await s.call(Sym('frontier_df3_eventscr_ch_001_A696D4', 48));
    s.evBitMod('flag', true, 14);
    return;
    await s.call(Sym('frontier_df3_eventscr_ch_001_A696D4', 996));
    await s.changeChapter(31, subcmd: 1);
    return;
    await s.call(Sym('frontier_df3_eventscr_ch_001_A696D4', 1724));
    return;
    await s.call(Sym('frontier_df3_eventscr_ch_001_A696D4', 1764));
    return;
    await s.call(Sym('frontier_df3_eventscr_ch_001_A696D4', 1804));
    return;
    s.setSlot(2, Sym('frontier_df3_unitdef_b_042_91C230_residue'));
    s.placeholder('EVENT_WORD');
}

/// `EventScr_Ch18A_11`
Future<void> Ch18A_11(Scene s) async {
    var pc = 0;
    while (true) {
      switch (pc) {
        case 0:
          s.sound('bgm', 73);
          pc = 1;
          continue;
        case 1:
          s.setSlot(2, 76);
          pc = 2;
          continue;
        case 2:
          await s.call(Sym('EventScr_SetBackground'));
          pc = 3;
          continue;
        case 3:
          s.checkSlotValue('mode');
          pc = 4;
          continue;
        case 4:
          s.setSlot(1, 2);
          pc = 5;
          continue;
        case 5:
          if (s.slotInt(12) != s.slotInt(1)) { pc = 15; } else { pc = 6; }
          continue;
        case 6:
          await s.textShow(2874);
          pc = 7;
          continue;
        case 7:
          await s.textEnd();
          pc = 8;
          continue;
        case 8:
          s.placeholder('EvtBgmFadeIn');
          pc = 9;
          continue;
        case 9:
          await s.continueText();
          pc = 10;
          continue;
        case 10:
          await s.textEnd();
          pc = 11;
          continue;
        case 11:
          s.sound('bgm', 44);
          pc = 12;
          continue;
        case 12:
          await s.continueText();
          pc = 13;
          continue;
        case 13:
          await s.textEnd();
          pc = 14;
          continue;
        case 14:
          pc = 24;
          continue;
        case 15:
          pc = 16;
          continue;
        case 16:
          await s.textShow(2875);
          pc = 17;
          continue;
        case 17:
          await s.textEnd();
          pc = 18;
          continue;
        case 18:
          s.placeholder('EvtBgmFadeIn');
          pc = 19;
          continue;
        case 19:
          await s.continueText();
          pc = 20;
          continue;
        case 20:
          await s.textEnd();
          pc = 21;
          continue;
        case 21:
          s.sound('bgm', 44);
          pc = 22;
          continue;
        case 22:
          await s.continueText();
          pc = 23;
          continue;
        case 23:
          await s.textEnd();
          pc = 24;
          continue;
        case 24:
          pc = 25;
          continue;
        case 25:
          s.textRemoveAll();
          pc = 26;
          continue;
        case 26:
          s.placeholder('EvtBgmFadeIn');
          pc = 27;
          continue;
        case 27:
          await s.fade(FadeDirection.toBlack, 16);
          pc = 28;
          continue;
        case 28:
          await s.clearScreen();
          pc = 29;
          continue;
        case 29:
          await s.fade(FadeDirection.fromBlack, 16);
          pc = 30;
          continue;
        case 30:
          s.loadUnits(2, Sym('UnitDef_Ch18AMixed'));
          pc = 31;
          continue;
        case 31:
          await s.waitUnitMoving();
          pc = 32;
          continue;
        case 32:
          s.sound('bgm', 73);
          pc = 33;
          continue;
        case 33:
          s.showCursorAtUnit(192);
          pc = 34;
          continue;
        case 34:
          await s.stall(60);
          pc = 35;
          continue;
        case 35:
          await s.endCursor();
          pc = 36;
          continue;
        case 36:
          s.setSlot(2, 76);
          pc = 37;
          continue;
        case 37:
          s.setSlot(3, 2876);
          pc = 38;
          continue;
        case 38:
          await s.call(Sym('Event_TextWithBG'));
          pc = 39;
          continue;
        case 39:
          await s.cameraTo(12, 15, centered: true);
          pc = 40;
          continue;
        case 40:
          await s.stall(60);
          pc = 41;
          continue;
        case 41:
          await s.cameraTo(0, 27, centered: false);
          pc = 42;
          continue;
        case 42:
          s.showCursorAtUnit(15);
          pc = 43;
          continue;
        case 43:
          await s.stall(60);
          pc = 44;
          continue;
        case 44:
          await s.endCursor();
          pc = 45;
          continue;
        case 45:
          s.sound('bgm', 37);
          pc = 46;
          continue;
        case 46:
          s.setSlot(2, 76);
          pc = 47;
          continue;
        case 47:
          await s.call(Sym('EventScr_SetBackground'));
          pc = 48;
          continue;
        case 48:
          await s.textShow(2877);
          pc = 49;
          continue;
        case 49:
          await s.textEnd();
          pc = 50;
          continue;
        case 50:
          s.textRemoveAll();
          pc = 51;
          continue;
        case 51:
          await s.fade(FadeDirection.toBlack, 16);
          pc = 52;
          continue;
        case 52:
          s.hideFaction('green');
          pc = 53;
          continue;
        case 53:
          await s.call(Sym('data_085B9BBC', 512));
          pc = 54;
          continue;
        case 54:
          s.evBitMod('flag', true, 8);
          pc = 55;
          continue;
        case 55:
          s.evBitMod('flag', true, 10);
          pc = 56;
          continue;
        case 56:
          s.evBitMod('flag', true, 12);
          pc = 57;
          continue;
        case 57:
          s.evBitMod('flag', true, 14);
          pc = 58;
          continue;
        case 58:
          s.evBitMod('evbit', true, 7);
          pc = 59;
          continue;
        case 59:
          return;
        default:
          return;
      }
    }
}

/// `EventScr_Ch18b_BeginningScene`
Future<void> Ch18b_BeginningScene(Scene s) async {
    s.setSlot(2, Sym('frontier_df3_unitdef_b_047_91E280', 1000));
    s.setSlot(3, Sym('UnitDef_Ch19BNPC_1'));
    s.setSlot(4, Sym('frontier_df3_unitdef_b_047_91E280'));
    await s.call(Sym('frontier_df3_eventscr_ch_002_A6A06C', 884));
    s.evBitMod('evbit', true, 7);
    return;
    s.cameraToChar(15);
    s.showCursorAtUnit(15);
    await s.stall(60);
    await s.endCursor();
    s.sound('bgm', 17);
    s.placeholder('EVENT_WORD');
}

/// `EventScr_Ch19A_11`
Future<void> Ch19A_11(Scene s) async {
    var pc = 0;
    while (true) {
      switch (pc) {
        case 0:
          s.checkSlotValue('greenCount');
          pc = 1;
          continue;
        case 1:
          s.slotArith('SADD', 7, 12);
          pc = 2;
          continue;
        case 2:
          s.sound('bgm', 49);
          pc = 3;
          continue;
        case 3:
          s.setSlot(2, 15);
          pc = 4;
          continue;
        case 4:
          await s.call(Sym('EventScr_SetBackground'));
          pc = 5;
          continue;
        case 5:
          s.checkSlotValue('mode');
          pc = 6;
          continue;
        case 6:
          s.setSlot(1, 2);
          pc = 7;
          continue;
        case 7:
          if (s.slotInt(12) != s.slotInt(1)) { pc = 11; } else { pc = 8; }
          continue;
        case 8:
          await s.textShow(2908);
          pc = 9;
          continue;
        case 9:
          await s.textEnd();
          pc = 10;
          continue;
        case 10:
          pc = 26;
          continue;
        case 11:
          pc = 12;
          continue;
        case 12:
          s.checkSlot('flag', 7);
          pc = 13;
          continue;
        case 13:
          if (s.slotInt(12) != s.slotInt(0)) { pc = 23; } else { pc = 14; }
          continue;
        case 14:
          s.checkSlot('alive', 34);
          pc = 15;
          continue;
        case 15:
          if (s.slotInt(12) == s.slotInt(0)) { pc = 19; } else { pc = 16; }
          continue;
        case 16:
          await s.textShow(2909);
          pc = 17;
          continue;
        case 17:
          await s.textEnd();
          pc = 18;
          continue;
        case 18:
          pc = 26;
          continue;
        case 19:
          pc = 20;
          continue;
        case 20:
          await s.textShow(2910);
          pc = 21;
          continue;
        case 21:
          await s.textEnd();
          pc = 22;
          continue;
        case 22:
          pc = 26;
          continue;
        case 23:
          pc = 24;
          continue;
        case 24:
          await s.textShow(2911);
          pc = 25;
          continue;
        case 25:
          await s.textEnd();
          pc = 26;
          continue;
        case 26:
          pc = 27;
          continue;
        case 27:
          s.textRemoveAll();
          pc = 28;
          continue;
        case 28:
          s.placeholder('EvtBgmFadeIn');
          pc = 29;
          continue;
        case 29:
          await s.fade(FadeDirection.toBlack, 16);
          pc = 30;
          continue;
        case 30:
          s.hideFaction('blue');
          pc = 31;
          continue;
        case 31:
          s.hideFaction('red');
          pc = 32;
          continue;
        case 32:
          s.hideFaction('green');
          pc = 33;
          continue;
        case 33:
          s.placeholder('EvtChangeFogVision');
          pc = 34;
          continue;
        case 34:
          s.setSlot(11, 0);
          pc = 35;
          continue;
        case 35:
          await s.loadMap(72);
          pc = 36;
          continue;
        case 36:
          await s.fade(FadeDirection.fromBlack, 4);
          pc = 37;
          continue;
        case 37:
          s.loadUnits(2, Sym('frontier_df3_unitdef_b_022_915038_tail_p1'));
          pc = 38;
          continue;
        case 38:
          await s.waitUnitMoving();
          pc = 39;
          continue;
        case 39:
          s.sound('se', 177);
          pc = 40;
          continue;
        case 40:
          await s.tileChange(0);
          pc = 41;
          continue;
        case 41:
          s.loadUnits(2, Sym('UnitDef_Ch19AAlly_5'));
          pc = 42;
          continue;
        case 42:
          await s.waitUnitMoving();
          pc = 43;
          continue;
        case 43:
          s.loadUnits(2, Sym('frontier_df3_unitdef_b_023_91512C'));
          pc = 44;
          continue;
        case 44:
          await s.waitUnitMoving();
          pc = 45;
          continue;
        case 45:
          s.showCursorAtUnit(25);
          pc = 46;
          continue;
        case 46:
          await s.stall(60);
          pc = 47;
          continue;
        case 47:
          await s.endCursor();
          pc = 48;
          continue;
        case 48:
          s.setSlot(2, 70);
          pc = 49;
          continue;
        case 49:
          await s.call(Sym('EventScr_SetBackground'));
          pc = 50;
          continue;
        case 50:
          s.sound('bgm', 43);
          pc = 51;
          continue;
        case 51:
          await s.textShow(2912);
          pc = 52;
          continue;
        case 52:
          await s.textEnd();
          pc = 53;
          continue;
        case 53:
          s.textRemoveAll();
          pc = 54;
          continue;
        case 54:
          s.placeholder('EvtBgmFadeIn');
          pc = 55;
          continue;
        case 55:
          await s.fade(FadeDirection.toBlack, 16);
          pc = 56;
          continue;
        case 56:
          s.hideFaction('blue');
          pc = 57;
          continue;
        case 57:
          s.hideFaction('red');
          pc = 58;
          continue;
        case 58:
          s.hideFaction('green');
          pc = 59;
          continue;
        case 59:
          s.checkSlotValue('mode');
          pc = 60;
          continue;
        case 60:
          s.setSlot(1, 2);
          pc = 61;
          continue;
        case 61:
          if (s.slotInt(12) != s.slotInt(1)) { pc = 65; } else { pc = 62; }
          continue;
        case 62:
          s.setSlot(11, 1572864);
          pc = 63;
          continue;
        case 63:
          await s.loadMap(19);
          pc = 64;
          continue;
        case 64:
          pc = 68;
          continue;
        case 65:
          pc = 66;
          continue;
        case 66:
          s.setSlot(11, 1572864);
          pc = 67;
          continue;
        case 67:
          await s.loadMap(32);
          pc = 68;
          continue;
        case 68:
          pc = 69;
          continue;
        case 69:
          s.loadUnits(2, Sym('frontier_df3_unitdef_b_021_914BD8', 860));
          pc = 70;
          continue;
        case 70:
          await s.waitUnitMoving();
          pc = 71;
          continue;
        case 71:
          await s.fade(FadeDirection.fromBlack, 16);
          pc = 72;
          continue;
        case 72:
          s.loadUnits(2, Sym('UnitDef_Ch19ANPC_3'));
          pc = 73;
          continue;
        case 73:
          await s.waitUnitMoving();
          pc = 74;
          continue;
        case 74:
          s.showCursorAtUnit(200);
          pc = 75;
          continue;
        case 75:
          await s.stall(60);
          pc = 76;
          continue;
        case 76:
          await s.endCursor();
          pc = 77;
          continue;
        case 77:
          s.setSlot(2, 23);
          pc = 78;
          continue;
        case 78:
          await s.call(Sym('EventScr_SetBackground'));
          pc = 79;
          continue;
        case 79:
          s.sound('bgm', 49);
          pc = 80;
          continue;
        case 80:
          await s.textShow(2913);
          pc = 81;
          continue;
        case 81:
          await s.textEnd();
          pc = 82;
          continue;
        case 82:
          s.checkSlotValue('mode');
          pc = 83;
          continue;
        case 83:
          s.setSlot(1, 2);
          pc = 84;
          continue;
        case 84:
          if (s.slotInt(12) != s.slotInt(1)) { pc = 88; } else { pc = 85; }
          continue;
        case 85:
          s.placeholder('EvtTextShow2');
          pc = 86;
          continue;
        case 86:
          await s.textEnd();
          pc = 87;
          continue;
        case 87:
          pc = 91;
          continue;
        case 88:
          pc = 89;
          continue;
        case 89:
          s.placeholder('EvtTextShow2');
          pc = 90;
          continue;
        case 90:
          await s.textEnd();
          pc = 91;
          continue;
        case 91:
          pc = 92;
          continue;
        case 92:
          s.placeholder('EvtTextShow2');
          pc = 93;
          continue;
        case 93:
          await s.textEnd();
          pc = 94;
          continue;
        case 94:
          s.textRemoveAll();
          pc = 95;
          continue;
        case 95:
          await s.call(Sym('data_085B9BBC', 360));
          pc = 96;
          continue;
        case 96:
          s.setSlot(3, 135);
          pc = 97;
          continue;
        case 97:
          await s.giveItem(0, 3);
          pc = 98;
          continue;
        case 98:
          await s.call(Sym('data_085B9BBC', 360));
          pc = 99;
          continue;
        case 99:
          s.setSlot(3, 140);
          pc = 100;
          continue;
        case 100:
          await s.giveItem(0, 3);
          pc = 101;
          continue;
        case 101:
          await s.call(Sym('data_085B9BBC', 360));
          pc = 102;
          continue;
        case 102:
          s.setSlot(3, 10000);
          pc = 103;
          continue;
        case 103:
          await s.giveItem(0, 3);
          pc = 104;
          continue;
        case 104:
          s.checkSlotValue('mode');
          pc = 105;
          continue;
        case 105:
          s.setSlot(1, 2);
          pc = 106;
          continue;
        case 106:
          if (s.slotInt(12) != s.slotInt(1)) { pc = 110; } else { pc = 107; }
          continue;
        case 107:
          await s.textShow(2917);
          pc = 108;
          continue;
        case 108:
          await s.textEnd();
          pc = 109;
          continue;
        case 109:
          pc = 113;
          continue;
        case 110:
          pc = 111;
          continue;
        case 111:
          await s.textShow(2918);
          pc = 112;
          continue;
        case 112:
          await s.textEnd();
          pc = 113;
          continue;
        case 113:
          pc = 114;
          continue;
        case 114:
          s.textRemoveAll();
          pc = 115;
          continue;
        case 115:
          s.setSlot(8, 6);
          pc = 116;
          continue;
        case 116:
          if (s.slotInt(7) < s.slotInt(8)) { pc = 133; } else { pc = 117; }
          continue;
        case 117:
          s.setSlot(2, 23);
          pc = 118;
          continue;
        case 118:
          await s.call(Sym('EventScr_SetBackground'));
          pc = 119;
          continue;
        case 119:
          s.checkSlotValue('mode');
          pc = 120;
          continue;
        case 120:
          s.setSlot(1, 2);
          pc = 121;
          continue;
        case 121:
          if (s.slotInt(12) != s.slotInt(1)) { pc = 125; } else { pc = 122; }
          continue;
        case 122:
          await s.textShow(2919);
          pc = 123;
          continue;
        case 123:
          await s.textEnd();
          pc = 124;
          continue;
        case 124:
          pc = 128;
          continue;
        case 125:
          pc = 126;
          continue;
        case 126:
          await s.textShow(2920);
          pc = 127;
          continue;
        case 127:
          await s.textEnd();
          pc = 128;
          continue;
        case 128:
          pc = 129;
          continue;
        case 129:
          s.textRemoveAll();
          pc = 130;
          continue;
        case 130:
          await s.call(Sym('data_085B9BBC', 360));
          pc = 131;
          continue;
        case 131:
          s.setSlot(3, 16);
          pc = 132;
          continue;
        case 132:
          await s.giveItem(0, 3);
          pc = 133;
          continue;
        case 133:
          pc = 134;
          continue;
        case 134:
          return;
        default:
          return;
      }
    }
}

/// `EventScr_Ch1Tut_AfterSethBattleEirikaVisit`
Future<void> Ch1Tut_AfterSethBattleEirikaVisit(Scene s) async {
    s.evBitMod('evbit', true, 7);
    s.setKeyIgnore(0);
    s.placeholder('EvtEnqueueCallDirectly');
    return;
}

/// `EventScr_Ch1Tut_AfterSethMoveToEnemy`
Future<void> Ch1Tut_AfterSethMoveToEnemy(Scene s) async {
    s.evBitMod('evbit', true, 7);
    s.setKeyIgnore(0);
    s.setTextType(3);
    s.setSlot(11, 3670088);
    await s.textShow(2322);
    await s.textEnd();
    s.textRemoveAll();
    s.setKeyIgnore(266);
    s.placeholder('DISABLEWEAPONS');
    s.enqueueTutCall(5, Sym('EventScr_Ch1Tut_GuideOnBKSEL'));
    return;
}

/// `EventScr_Ch1Tut_AfterTrade`
Future<void> Ch1Tut_AfterTrade(Scene s) async {
    s.evBitMod('evbit', true, 7);
    s.setTextType(3);
    s.setSlot(11, 3670088);
    await s.textShow(2317);
    await s.textEnd();
    s.textRemoveAll();
    s.evBitMod('flag', true, 199);
    s.evBitMod('flag', true, 200);
    s.enqueueTutCall(1, Sym('EventScr_Ch1Tut_PostTradeAndItemUseAction'));
    return;
}

/// `EventScr_Ch1Tut_BeforeSethMoveToEnemy`
Future<void> Ch1Tut_BeforeSethMoveToEnemy(Scene s) async {
    s.evBitMod('evbit', true, 7);
    s.setKeyIgnore(0);
    s.setSlot(13, 0);
    s.setSlot(1, 393225);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 2320);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 524296);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, Sym('EventScr_Ch1Tut_AfterSethMoveToEnemy'));
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, Sym('EventScr_Ch1Tut_BeforeSethMoveToEnemy'));
    s.slotQueuePushSlot(0x1);
    await s.call(Sym('EventScr_Tutorial_Exec1'));
    s.overrideUnitMenu(65534);
    s.setKeyIgnore(266);
    return;
}

/// `EventScr_Ch1Tut_ChooseSethTurn1`
Future<void> Ch1Tut_ChooseSethTurn1(Scene s) async {
    s.setTextType(3);
    s.setSlot(11, 4294967295);
    await s.textShow(2318);
    await s.textEnd();
    s.textRemoveAll();
    s.showCursorAtUnit(2, flashing: true);
    await s.stall(60);
    await s.endCursor();
    s.setSlot(13, 0);
    s.setSlot(1, 0);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 1);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 65536);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 4294967295);
    s.slotQueuePushSlot(0x1);
    s.placeholder('FIGHT_SCRIPT');
    s.placeholder('EvtEnqueueConditionalTutCall');
    s.overrideUnitMenu(24576);
    return;
}

/// `EventScr_Ch1Tut_EirikaVisitHouseEnd`
Future<void> Ch1Tut_EirikaVisitHouseEnd(Scene s) async {
    s.evBitMod('evbit', true, 7);
    s.setKeyIgnore(0);
    s.setTextType(3);
    s.setSlot(11, 3670088);
    await s.textShow(2305);
    await s.textEnd();
    s.textRemoveAll();
    s.evBitMod('flag', true, 207);
    s.setKeyIgnore(266);
    s.enqueueTutCall(1, Sym('EventScr_Ch1Tut_GuideTerrainHeal'));
    return;
}

/// `EventScr_Ch1Tut_EirikaVisitHouseIdle1`
Future<void> Ch1Tut_EirikaVisitHouseIdle1(Scene s) async {
    s.evBitMod('evbit', true, 7);
    s.setSlot(13, 0);
    s.setSlot(1, 1);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 393229);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 2304);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 524296);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 2303);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 524296);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, Sym('EventScr_Ch1Tut_EirikaVisitHouseIdle2'));
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, Sym('EventScr_Ch1Tut_EirikaVisitHouseIdle1'));
    s.slotQueuePushSlot(0x1);
    await s.call(Sym('EventScr_Tutorial_Exec0'));
    return;
}

/// `EventScr_Ch1Tut_EirikaVisitHouseIdle2`
Future<void> Ch1Tut_EirikaVisitHouseIdle2(Scene s) async {
    s.evBitMod('evbit', true, 7);
    s.setKeyIgnore(0);
    s.setSlot(13, 0);
    s.setSlot(1, 393229);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 0);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 0);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, Sym('EventScr_Ch1Tut_EirikaVisitHouseEnd'));
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, Sym('EventScr_Ch1Tut_EirikaVisitHouseIdle2'));
    s.slotQueuePushSlot(0x1);
    await s.call(Sym('EventScr_Tutorial_Exec1'));
    s.overrideUnitMenu(65503);
    s.setKeyIgnore(266);
    return;
}

/// `EventScr_Ch1Tut_EirikaVisitHouseInit`
Future<void> Ch1Tut_EirikaVisitHouseInit(Scene s) async {
    s.sound('bgm', 9);
    s.setTextType(0);
    await s.textShow(2286);
    await s.textEnd();
    s.textRemoveAll();
    s.showCursorAt(13, 6, flashing: true);
    await s.stall(60);
    await s.endCursor();
    s.setTextType(3);
    s.setSlot(11, 4294967295);
    s.placeholder('EVENT_WORD_SYM');
    await s.textEnd();
    s.textRemoveAll();
    s.showCursorAtUnit(1, flashing: true);
    await s.stall(60);
    await s.endCursor();
    s.placeholder('EvtEnqueueConditionalTutCall');
    s.overrideUnitMenu(16384);
    s.evBitMod('evbit', true, 7);
    return;
}

/// `EventScr_Ch1Tut_GilliamBattle`
Future<void> Ch1Tut_GilliamBattle(Scene s) async {
    s.setSlot(1, 19);
    await s.setUnitHpFromSlot(3);
    await s.stall(60);
    s.moveUnit('MOVE_CLOSEST', [0, 3, 520]);
    await s.waitUnitMoving();
    s.setSlot(13, 0);
    s.setSlot(1, 0);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 131073);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 513);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 4294967295);
    s.slotQueuePushSlot(0x1);
    s.setSlot(11, 196616);
    s.placeholder('FIGHT');
    s.setSlot(2, Sym('EventScr_Ch1Tut_GuideMsg944'));
    await s.call(Sym('EventScr_CallOnTutorialMode'));
    s.moveUnit('MOVE_CLOSEST', [0, 4, 264]);
    await s.waitUnitMoving();
    s.displayCursorAtUnit(4);
    await s.stall(60);
    await s.endCursor();
    s.volumeDown(true);
    s.setTextType(0);
    await s.textShow(2291);
    await s.textEnd();
    s.textRemoveAll();
    s.volumeDown(false);
    s.setTextType(3);
    s.setSlot(11, 4294967295);
    await s.textShow(2310);
    await s.textEnd();
    s.textRemoveAll();
    s.showCursorAtUnit(3, flashing: true);
    await s.stall(60);
    await s.endCursor();
    s.enqueueTutCall(2, Sym('EventScr_Ch1Tut_TradeSelectGalliamIdle1'));
    s.overrideUnitMenu(16384);
    return;
}

/// `EventScr_Ch1Tut_GuideOnBKSEL`
Future<void> Ch1Tut_GuideOnBKSEL(Scene s) async {
    s.evBitMod('evbit', true, 7);
    s.setKeyIgnore(256);
    s.setTextType(3);
    s.setSlot(11, 1048660);
    await s.textShow(2321);
    await s.textEnd();
    s.textRemoveAll();
    s.setKeyIgnore(266);
    s.enqueueTutCall(1, Sym('EventScr_Ch1Tut_AfterSethBattleEirikaVisit'));
    s.evBitMod('evbit', true, 7);
    return;
}

/// `EventScr_Ch1Tut_GuideTerrainHeal`
Future<void> Ch1Tut_GuideTerrainHeal(Scene s) async {
    s.setKeyIgnore(0);
    s.showCursorAt(7, 7, flashing: true);
    s.showCursorAt(7, 2, flashing: true);
    s.showCursorAt(2, 2, flashing: true);
    await s.stall(60);
    await s.endCursor();
    s.setTextType(3);
    s.setSlot(11, 4294967295);
    await s.textShow(2306);
    await s.textEnd();
    s.textRemoveAll();
    s.evBitMod('flag', true, 206);
    s.overrideUnitMenu(512);
    s.evBitMod('evbit', true, 7);
    return;
}

/// `EventScr_Ch1Tut_MsgOnGuideOption`
Future<void> Ch1Tut_MsgOnGuideOption(Scene s) async {
    s.setTextType(3);
    s.setSlot(11, 4294967295);
    await s.textShow(2323);
    await s.textEnd();
    s.textRemoveAll();
    return;
}

/// `EventScr_Ch1Tut_OnBeginning`
Future<void> Ch1Tut_OnBeginning(Scene s) async {
    s.showCursorAtUnit(2);
    await s.stall(60);
    await s.endCursor();
    s.setTextType(3);
    s.setSlot(11, 4294967295);
    await s.textShow(2307);
    await s.textEnd();
    s.textRemoveAll();
    s.evBitMod('flag', true, 182);
    s.evBitMod('flag', true, 215);
    s.setTextType(0);
    s.placeholder('EVENT_WORD_SYM');
    await s.textEnd();
    s.textRemoveAll();
    return;
}

/// `EventScr_Ch1Tut_PostTradeAndItemUseAction`
Future<void> Ch1Tut_PostTradeAndItemUseAction(Scene s) async {
    s.displayCursorAtUnit(4);
    await s.stall(60);
    await s.endCursor();
    s.setTextType(0);
    await s.textShow(2290);
    await s.textEnd();
    s.textRemoveAll();
    s.overrideUnitMenu(0);
    await s.call(Sym('EventScr_Ch1Tut_MsgOnGuideOption'));
    s.evBitMod('evbit', true, 7);
    return;
}

/// `EventScr_Ch1Tut_SethMoveToEnemy`
Future<void> Ch1Tut_SethMoveToEnemy(Scene s) async {
    s.evBitMod('evbit', true, 7);
    s.setSlot(13, 0);
    s.setSlot(1, 2);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 393225);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 2320);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 524296);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 2319);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 524296);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, Sym('EventScr_Ch1Tut_BeforeSethMoveToEnemy'));
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, Sym('EventScr_Ch1Tut_SethMoveToEnemy'));
    s.slotQueuePushSlot(0x1);
    await s.call(Sym('EventScr_Tutorial_Exec0'));
    return;
}

/// `EventScr_Ch1Tut_TradeSelectGalliamEnd`
Future<void> Ch1Tut_TradeSelectGalliamEnd(Scene s) async {
    s.evBitMod('evbit', true, 7);
    s.setKeyIgnore(0);
    s.setTextType(3);
    s.setSlot(11, 3670088);
    await s.textShow(2312);
    await s.textEnd();
    s.textRemoveAll();
    s.setKeyIgnore(266);
    s.evBitMod('flag', true, 135);
    s.enqueueTutCall(4, Sym('EventScr_Ch1Tut_AfterTrade'));
    return;
}

/// `EventScr_Ch1Tut_TradeSelectGalliamIdle1`
Future<void> Ch1Tut_TradeSelectGalliamIdle1(Scene s) async {
    s.evBitMod('evbit', true, 7);
    s.setSlot(13, 0);
    s.setSlot(1, 3);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 131080);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 2311);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 4194344);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 2310);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 4194344);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, Sym('EventScr_Ch1Tut_TradeSelectGalliamIdle2'));
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, Sym('EventScr_Ch1Tut_TradeSelectGalliamIdle1'));
    s.slotQueuePushSlot(0x1);
    await s.call(Sym('EventScr_Tutorial_Exec0'));
    s.setKeyIgnore(1022);
    return;
}

/// `EventScr_Ch1Tut_TradeSelectGalliamIdle2`
Future<void> Ch1Tut_TradeSelectGalliamIdle2(Scene s) async {
    s.evBitMod('evbit', true, 7);
    s.setKeyIgnore(0);
    s.setSlot(13, 0);
    s.setSlot(1, 131080);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 0);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 0);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, Sym('EventScr_Ch1Tut_TradeSelectGalliamEnd'));
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, Sym('EventScr_Ch1Tut_TradeSelectGalliamIdle2'));
    s.slotQueuePushSlot(0x1);
    await s.call(Sym('EventScr_Tutorial_Exec1'));
    s.overrideUnitMenu(65023);
    s.setKeyIgnore(266);
    return;
}

/// `EventScr_Ch1_BeginningScene`
Future<void> Ch1_BeginningScene(Scene s) async {
    s.sound('bgm', 37);
    s.loadUnits(1, Sym('UnitDef_Event_Ch1Enemy'));
    await s.waitUnitMoving();
    await s.stall(60, cancellable: false);
    s.showCursorAt(2, 2);
    await s.stall(60);
    await s.endCursor();
    s.setSlot(2, 57);
    s.setSlot(3, 2281);
    await s.call(Sym('Event_TextWithBG'));
    s.loadUnits(1, Sym('UnitDef_Event_Ch1NPC'));
    await s.waitUnitMoving();
    s.setSlot(11, 0);
    await s.removeUnit(65534);
    s.showCursorAtUnit(70);
    await s.stall(60);
    await s.endCursor();
    s.setSlot(2, 36);
    s.setSlot(3, 2282);
    await s.call(Sym('Event_TextWithBG'));
    s.moveUnit('MOVE', [0, 70, 2, 3]);
    await s.waitUnitMoving();
    s.evBitMod('flag', true, 1);
    s.setSlot(13, 0);
    s.setSlot(1, 70656);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 1);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 4294967295);
    s.slotQueuePushSlot(0x1);
    s.placeholder('FIGHT');
    s.evBitMod('flag', false, 1);
    s.setSlot(11, 131074);
    s.placeholder('KILL');
    await s.removeUnit(65534, onlyIfDead: true);
    s.showCursorAtUnit(70);
    await s.stall(60);
    await s.endCursor();
    await s.textShow(2283);
    await s.textEnd();
    s.textRemoveAll();
    s.setSlot(2, Sym('EventScr_Ch1Tut_GuideWTA'));
    await s.call(Sym('EventScr_CallOnTutorialMode'));
    s.moveUnit('MOVE', [0, 70, 2, 2]);
    s.setSlot(11, 393217);
    s.moveUnit('MOVE', [24, 65534, 1, 3]);
    s.setSlot(11, 393219);
    s.moveUnit('MOVE', [24, 65534, 3, 3]);
    s.setSlot(11, 524289);
    s.moveUnit('MOVE', [24, 65534, 9, 5]);
    s.setSlot(11, 458754);
    s.moveUnit('MOVE', [24, 65534, 8, 3]);
    s.setSlot(11, 524291);
    s.moveUnit('MOVE', [24, 65534, 4, 7]);
    s.setSlot(11, 589826);
    s.moveUnit('MOVE', [24, 65534, 2, 8]);
    await s.waitUnitMoving();
    await s.stall(60, cancellable: false);
    s.showCursorAt(2, 2);
    await s.stall(60);
    await s.endCursor();
    s.setSlot(2, 57);
    s.setSlot(3, 2284);
    await s.call(Sym('Event_TextWithBG'));
    s.textRemoveAll();
    s.loadUnits(2, Sym('UnitDef_Event_Ch1Ally'));
    await s.waitUnitMoving();
    s.showCursorAtUnit(1);
    await s.stall(60);
    await s.endCursor();
    s.setTextType(0);
    await s.textShow(2285);
    await s.textEnd();
    s.textRemoveAll();
    s.setSlot(2, 2);
    await s.call(Sym('EventScr_MoveUnitS2ToLeader'));
    s.setSlot(2, Sym('EventScr_Ch1Tut_OnBeginning'));
    await s.call(Sym('EventScr_CallOnTutorialMode'));
    s.evBitMod('flag', true, 11);
    s.evBitMod('evbit', true, 7);
    return;
}

/// `EventScr_Ch1_EndingScene`
Future<void> Ch1_EndingScene(Scene s) async {
    var pc = 0;
    while (true) {
      switch (pc) {
        case 0:
          s.sound('bgm', 49);
          pc = 1;
          continue;
        case 1:
          s.setSlot(2, 57);
          pc = 2;
          continue;
        case 2:
          await s.call(Sym('EventScr_SetBackground'));
          pc = 3;
          continue;
        case 3:
          s.checkSlot('alive', 3);
          pc = 4;
          continue;
        case 4:
          if (s.slotInt(12) == s.slotInt(0)) { pc = 8; } else { pc = 5; }
          continue;
        case 5:
          await s.textShow(2295);
          pc = 6;
          continue;
        case 6:
          await s.textEnd();
          pc = 7;
          continue;
        case 7:
          pc = 11;
          continue;
        case 8:
          pc = 9;
          continue;
        case 9:
          await s.textShow(2296);
          pc = 10;
          continue;
        case 10:
          await s.textEnd();
          pc = 11;
          continue;
        case 11:
          pc = 12;
          continue;
        case 12:
          s.textRemoveAll();
          pc = 13;
          continue;
        case 13:
          await s.fade(FadeDirection.toBlack, 16);
          pc = 14;
          continue;
        case 14:
          s.evBitMod('flag', true, 186);
          pc = 15;
          continue;
        case 15:
          s.evBitMod('flag', true, 207);
          pc = 16;
          continue;
        case 16:
          s.evBitMod('flag', true, 206);
          pc = 17;
          continue;
        case 17:
          s.evBitMod('flag', true, 182);
          pc = 18;
          continue;
        case 18:
          s.evBitMod('flag', true, 215);
          pc = 19;
          continue;
        case 19:
          s.evBitMod('flag', true, 214);
          pc = 20;
          continue;
        case 20:
          s.evBitMod('flag', true, 199);
          pc = 21;
          continue;
        case 21:
          s.evBitMod('flag', true, 200);
          pc = 22;
          continue;
        case 22:
          s.evBitMod('flag', true, 221);
          pc = 23;
          continue;
        case 23:
          s.unitStateOp('reveal', 2);
          pc = 24;
          continue;
        case 24:
          await s.changeChapter(56, subcmd: 1);
          pc = 25;
          continue;
        case 25:
          return;
        default:
          return;
      }
    }
}

/// `EventScr_Ch1_Loca_Visit1`
Future<void> Ch1_Loca_Visit1(Scene s) async {
    s.setKeyIgnore(0);
    s.volumeDown(true);
    s.setSlot(2, 0);
    s.setSlot(3, 2299);
    await s.call(Sym('Event_TextWithBG'));
    s.volumeDown(false);
    s.evBitMod('evbit', true, 7);
    return;
}

/// `EventScr_Ch1_Loca_Visit2`
Future<void> Ch1_Loca_Visit2(Scene s) async {
    s.volumeDown(true);
    s.setSlot(2, 0);
    s.setSlot(3, 2300);
    await s.call(Sym('Event_TextWithBG'));
    s.volumeDown(false);
    s.evBitMod('evbit', true, 7);
    return;
}

/// `EventScr_Ch1_Misc_Area`
Future<void> Ch1_Misc_Area(Scene s) async {
    s.setSlot(2, 1);
    await s.call(Sym('EventScr_UnTriggerIfNotUnit'));
    s.evBitMod('flag', false, 11);
    s.evBitMod('evbit', true, 7);
    return;
}

/// `EventScr_Ch1_Misc_DefeatBoss`
Future<void> Ch1_Misc_DefeatBoss(Scene s) async {
    s.setSlot(2, Sym('EventScr_Ch1Tut_GuideMsgSeize'));
    await s.call(Sym('EventScr_CallOnTutorialMode'));
    s.evBitMod('evbit', true, 7);
    return;
}

/// `EventScr_Ch1_Turn1Player`
Future<void> Ch1_Turn1Player(Scene s) async {
    s.setSlot(2, Sym('EventScr_Ch1Tut_ChooseSethTurn1'));
    await s.call(Sym('EventScr_CallOnTutorialMode'));
    s.evBitMod('evbit', true, 7);
    return;
}

/// `EventScr_Ch1_Turn_AllyReinforceArrive`
Future<void> Ch1_Turn_AllyReinforceArrive(Scene s) async {
    s.sound('bgm', 84);
    s.loadUnits(1, Sym('UnitDef_Event_Ch1AllyReinforce'));
    await s.waitUnitMoving();
    s.showCursorAtUnit(4);
    await s.stall(60);
    await s.endCursor();
    s.setTextType(0);
    await s.textShow(2289);
    await s.textEnd();
    s.textRemoveAll();
    s.setSlot(2, Sym('EventScr_Ch1Tut_GilliamBattle'));
    await s.call(Sym('EventScr_CallOnTutorialMode'));
    s.evBitMod('evbit', true, 7);
    return;
}

/// `EventScr_Ch1_Turn_EnemyReinforceArrive`
Future<void> Ch1_Turn_EnemyReinforceArrive(Scene s) async {
    s.volumeDown(true);
    s.setSlot(2, Sym('UnitDef_Event_Ch1EnemyReinforce'));
    await s.call(Sym('EventScr_LoadReinforce'));
    s.displayCursorAtUnit(131);
    await s.stall(60);
    await s.endCursor();
    s.setTextType(0);
    await s.textShow(2292);
    await s.textEnd();
    s.textRemoveAll();
    s.volumeDown(false);
    s.evBitMod('evbit', true, 7);
    return;
}

/// `EventScr_Ch20B_1`
Future<void> Ch20B_1(Scene s) async {
    var pc = 0;
    while (true) {
      switch (pc) {
        case 0:
          s.setSlot(2, Sym('frontier_df3_unitdef_b_052_91F89C'));
          pc = 1;
          continue;
        case 1:
          await s.call(Sym('EventScr_LoadReinforce'));
          pc = 2;
          continue;
        case 2:
          s.counterDec(0);
          pc = 3;
          continue;
        case 3:
          s.evBitMod('flag', false, 11);
          pc = 4;
          continue;
        case 4:
          s.counterCheck(0);
          pc = 5;
          continue;
        case 5:
          if (s.slotInt(12) != s.slotInt(0)) { pc = 7; } else { pc = 6; }
          continue;
        case 6:
          s.evBitMod('flag', true, 11);
          pc = 7;
          continue;
        case 7:
          pc = 8;
          continue;
        case 8:
          s.evBitMod('evbit', true, 7);
          pc = 9;
          continue;
        case 9:
          return;
        case 10:
          s.setSlot(2, 0);
          pc = 11;
          continue;
        case 11:
          await s.call(Sym('UnitDef_Ch14BAlly_7'));
          pc = 12;
          continue;
        default:
          return;
      }
    }
}

/// `EventScr_Ch20B_2`
Future<void> Ch20B_2(Scene s) async {
    var pc = 0;
    while (true) {
      switch (pc) {
        case 0:
          s.setSlot(2, Sym('frontier_df3_unitdef_b_052_91F89C', 120));
          pc = 1;
          continue;
        case 1:
          await s.call(Sym('EventScr_LoadReinforce'));
          pc = 2;
          continue;
        case 2:
          s.counterDec(1);
          pc = 3;
          continue;
        case 3:
          s.evBitMod('flag', false, 12);
          pc = 4;
          continue;
        case 4:
          s.counterCheck(1);
          pc = 5;
          continue;
        case 5:
          if (s.slotInt(12) != s.slotInt(0)) { pc = 7; } else { pc = 6; }
          continue;
        case 6:
          s.evBitMod('flag', true, 12);
          pc = 7;
          continue;
        case 7:
          pc = 8;
          continue;
        case 8:
          s.evBitMod('evbit', true, 7);
          pc = 9;
          continue;
        case 9:
          return;
        case 10:
          s.setSlot(2, 0);
          pc = 11;
          continue;
        case 11:
          await s.call(Sym('UnitDef_Ch14BAlly_7'));
          pc = 12;
          continue;
        default:
          return;
      }
    }
}

/// `EventScr_Ch20b_BeginningScene`
Future<void> Ch20b_BeginningScene(Scene s) async {
    await s.call(Sym('EventScr_Ch21A_8'));
    s.setSlot(2, 108);
    await s.call(Sym('EventScr_UnitWarpOUT'));
    await s.removeUnit(108);
    await s.fade(FadeDirection.toBlack, 16);
    s.loadUnits(1, Sym('UnitDef_Ch21BEnemy_0'));
    await s.waitUnitMoving();
    await s.call(Sym('data_085B9BBC', 512));
    s.evBitMod('flag', true, 11);
    s.evBitMod('flag', true, 12);
    s.evBitMod('flag', true, 13);
    return;
}

/// `EventScr_Ch21A_0`
Future<void> Ch21A_0(Scene s) async {
    s.placeholder('EvtBgmFadeIn');
    await s.fade(FadeDirection.toBlack, 4);
    s.hideFaction('blue');
    s.hideFaction('red');
    s.hideFaction('green');
    await s.cameraTo(11, 4, centered: true);
    s.placeholder('EvtSetLoadUnitNoREDA');
    s.loadUnits(2, Sym('UnitDef_Ch21AMixed'));
    await s.waitUnitMoving();
    await s.fade(FadeDirection.fromBlack, 4);
    s.loadUnits(2, Sym('UnitDef_Ch21AMixed'));
    await s.waitUnitMoving();
    s.showCursorAtUnit(64);
    await s.stall(60);
    await s.endCursor();
    s.setTextType(0);
    await s.textShow(2949);
    await s.textEnd();
    s.placeholder('EvtBgmFadeIn');
    await s.continueText();
    await s.textEnd();
    s.textRemoveAll();
    s.placeholder('EvtBgmFadeIn');
    await s.call(Sym('EventScr_Ch21A_9'));
    await s.changeChapter(22, subcmd: 3);
    return;
}

/// `EventScr_Ch21A_8`
Future<void> Ch21A_8(Scene s) async {
    var pc = 0;
    while (true) {
      switch (pc) {
        case 0:
          s.setTextType(1);
          pc = 1;
          continue;
        case 1:
          s.showTextBg(79);
          pc = 2;
          continue;
        case 2:
          await s.fade(FadeDirection.toWhite, 2);
          pc = 3;
          continue;
        case 3:
          s.showTextBg(26);
          pc = 4;
          continue;
        case 4:
          await s.fade(FadeDirection.fromWhite, 2);
          pc = 5;
          continue;
        case 5:
          s.placeholder('EvtBgmFadeIn');
          pc = 6;
          continue;
        case 6:
          await s.popupText(406, 8, 8);
          pc = 7;
          continue;
        case 7:
          s.checkSlotValue('mode');
          pc = 8;
          continue;
        case 8:
          s.setSlot(1, 2);
          pc = 9;
          continue;
        case 9:
          if (s.slotInt(12) != s.slotInt(1)) { pc = 13; } else { pc = 10; }
          continue;
        case 10:
          await s.textShow(2938);
          pc = 11;
          continue;
        case 11:
          await s.textEnd();
          pc = 12;
          continue;
        case 12:
          pc = 16;
          continue;
        case 13:
          pc = 14;
          continue;
        case 14:
          await s.textShow(2939);
          pc = 15;
          continue;
        case 15:
          await s.textEnd();
          pc = 16;
          continue;
        case 16:
          pc = 17;
          continue;
        case 17:
          s.textRemoveAll();
          pc = 18;
          continue;
        case 18:
          s.placeholder('EvtBgmFadeIn');
          pc = 19;
          continue;
        case 19:
          await s.fade(FadeDirection.toWhite, 2);
          pc = 20;
          continue;
        case 20:
          await s.clearScreen();
          pc = 21;
          continue;
        case 21:
          s.loadUnits(1, Sym('frontier_df3_unitdef_b_023_91512C', 2792));
          pc = 22;
          continue;
        case 22:
          await s.waitUnitMoving();
          pc = 23;
          continue;
        case 23:
          await s.fade(FadeDirection.fromWhite, 2);
          pc = 24;
          continue;
        case 24:
          s.loadUnits(2, Sym('UnitDef_Ch21AAlly_1'));
          pc = 25;
          continue;
        case 25:
          await s.waitUnitMoving();
          pc = 26;
          continue;
        case 26:
          s.moveUnit('MOVE', [16, 0, 11, 20]);
          pc = 27;
          continue;
        case 27:
          await s.waitUnitMoving();
          pc = 28;
          continue;
        case 28:
          s.showCursorAtUnit(0);
          pc = 29;
          continue;
        case 29:
          await s.stall(60);
          pc = 30;
          continue;
        case 30:
          await s.endCursor();
          pc = 31;
          continue;
        case 31:
          s.checkSlotValue('mode');
          pc = 32;
          continue;
        case 32:
          s.setSlot(1, 2);
          pc = 33;
          continue;
        case 33:
          if (s.slotInt(12) != s.slotInt(1)) { pc = 40; } else { pc = 34; }
          continue;
        case 34:
          s.sound('bgm', 68);
          pc = 35;
          continue;
        case 35:
          s.setTextType(0);
          pc = 36;
          continue;
        case 36:
          await s.textShow(2940);
          pc = 37;
          continue;
        case 37:
          await s.textEnd();
          pc = 38;
          continue;
        case 38:
          s.textRemoveAll();
          pc = 39;
          continue;
        case 39:
          pc = 45;
          continue;
        case 40:
          pc = 41;
          continue;
        case 41:
          s.setTextType(0);
          pc = 42;
          continue;
        case 42:
          await s.textShow(2942);
          pc = 43;
          continue;
        case 43:
          await s.textEnd();
          pc = 44;
          continue;
        case 44:
          s.textRemoveAll();
          pc = 45;
          continue;
        case 45:
          pc = 46;
          continue;
        case 46:
          s.placeholder('STARTFADE');
          pc = 47;
          continue;
        case 47:
          s.placeholder('EvtBgmFadeIn');
          pc = 48;
          continue;
        case 48:
          s.placeholder('EvtColorFadeSetup');
          pc = 49;
          continue;
        case 49:
          s.placeholder('EvtColorFadeSetup');
          pc = 50;
          continue;
        case 50:
          s.setSlot(2, 64);
          pc = 51;
          continue;
        case 51:
          await s.call(Sym('EventScr_UnitFlushingOUT'));
          pc = 52;
          continue;
        case 52:
          await s.removeUnit(64);
          pc = 53;
          continue;
        case 53:
          await s.stall(30);
          pc = 54;
          continue;
        case 54:
          s.placeholder('SPAWN_ENEMY');
          pc = 55;
          continue;
        case 55:
          s.placeholder('EvtColorFadeSetup');
          pc = 56;
          continue;
        case 56:
          s.setSlot(2, 108);
          pc = 57;
          continue;
        case 57:
          s.moveUnit('MOVE_CLOSEST', [65535, 65533, 11, 18]);
          pc = 58;
          continue;
        case 58:
          await s.call(Sym('EventScr_UnitFlushingIN'));
          pc = 59;
          continue;
        case 59:
          s.placeholder('EvtColorFadeSetup');
          pc = 60;
          continue;
        case 60:
          return;
        default:
          return;
      }
    }
}

/// `EventScr_Ch21A_9`
Future<void> Ch21A_9(Scene s) async {
    s.placeholder('STARTFADE');
    s.placeholder('EvtColorFadeSetup');
    await s.stall(30);
    s.moveUnit('MOVE_1STEP', [2, 64, 3]);
    await s.waitUnitMoving();
    await s.stall(30, cancellable: false);
    s.setSlot(2, 64);
    await s.call(Sym('EventScr_UnitWarpOUT'));
    await s.removeUnit(64);
    s.setTextType(0);
    await s.textShow(2951);
    await s.textEnd();
    s.textRemoveAll();
    s.setTextType(4);
    s.setSlot(11, 8388632);
    await s.textShow(2952);
    await s.textEnd();
    s.textRemoveAll();
    return;
}

/// `EventScr_Ch21b_BeginningScene`
Future<void> Ch21b_BeginningScene(Scene s) async {
    await s.call(Sym('frontier_df3_eventscr_ch_005_A6B460', 300));
    return;
    await s.call(Sym('UnitDef_Ch21BEnemy_1'));
    await s.changeChapter(0, subcmd: 4);
    return;
    s.placeholder('ASMC');
    s.setSlot(2, 0);
    await s.call(Sym('EventScr_ConfigHardModeLoadUnitHard'));
    s.setSlot(13, 0);
    s.setSlot(1, 50);
}

/// `EventScr_Ch21b_EndingScene`
Future<void> Ch21b_EndingScene(Scene s) async {
    s.placeholder('EvtBgmFadeIn');
    await s.fade(FadeDirection.toBlack, 4);
    s.hideFaction('blue');
    s.hideFaction('red');
    s.hideFaction('green');
    await s.cameraTo(11, 4, centered: true);
    s.placeholder('EvtSetLoadUnitNoREDA');
    s.loadUnits(2, Sym('UnitDef_Ch21BMixed'));
    await s.waitUnitMoving();
    await s.fade(FadeDirection.fromBlack, 4);
    s.loadUnits(2, Sym('UnitDef_Ch21BMixed'));
    await s.waitUnitMoving();
    s.showCursorAtUnit(64);
    await s.stall(60);
    await s.endCursor();
    s.setTextType(0);
    await s.textShow(2950);
    await s.textEnd();
    s.placeholder('EvtBgmFadeIn');
    await s.continueText();
    await s.textEnd();
    s.textRemoveAll();
    s.placeholder('EvtBgmFadeIn');
    await s.call(Sym('EventScr_Ch21A_9'));
    await s.changeChapter(35, subcmd: 3);
    return;
}

/// `EventScr_Ch2Tutorial10`
Future<void> Ch2Tutorial10(Scene s) async {
    s.enqueueTutCall(1, Sym('EventScr_Ch2Tutorial22'));
    s.evBitMod('evbit', true, 7);
    return;
}

/// `EventScr_Ch2Tutorial11`
Future<void> Ch2Tutorial11(Scene s) async {
    s.evBitMod('evbit', true, 7);
    s.setSlot(13, 0);
    s.setSlot(1, 6);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 262152);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 2358);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 5767200);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 2356);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 5767200);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, Sym('EventScr_Ch2Tutorial12'));
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, Sym('EventScr_Ch2Tutorial11'));
    s.slotQueuePushSlot(0x1);
    await s.call(Sym('EventScr_Tutorial_Exec0'));
    s.setKeyIgnore(1022);
    return;
}

/// `EventScr_Ch2Tutorial12`
Future<void> Ch2Tutorial12(Scene s) async {
    s.evBitMod('evbit', true, 7);
    s.setKeyIgnore(0);
    s.setSlot(13, 0);
    s.setSlot(1, 262152);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 0);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 0);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, Sym('EventScr_Ch2Tutorial13'));
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, Sym('EventScr_Ch2Tutorial12'));
    s.slotQueuePushSlot(0x1);
    await s.call(Sym('EventScr_Tutorial_Exec1'));
    s.overrideUnitMenu(65519);
    s.setKeyIgnore(266);
    return;
}

/// `EventScr_Ch2Tutorial13`
Future<void> Ch2Tutorial13(Scene s) async {
    s.evBitMod('evbit', true, 7);
    s.enqueueTutCall(2, Sym('EventScr_Ch2Tutorial14'));
    return;
}

/// `EventScr_Ch2Tutorial14`
Future<void> Ch2Tutorial14(Scene s) async {
    s.evBitMod('evbit', true, 7);
    s.setKeyIgnore(0);
    s.sound('bgm', 9);
    s.setTextType(0);
    await s.textShow(2334);
    await s.textEnd();
    s.textRemoveAll();
    s.evBitMod('flag', true, 197);
    s.overrideUnitMenu(0);
    s.placeholder('SHOW_ATTACK_RANGE');
    s.showCursorAt(9, 4, flashing: true);
    await s.stall(60);
    s.setTextType(3);
    s.setSlot(11, 5767184);
    await s.textShow(2359);
    await s.textEnd();
    s.textRemoveAll();
    await s.endCursor();
    s.setKeyIgnore(266);
    s.placeholder('EvtEnqueueConditionalTutCall');
    return;
}

/// `EventScr_Ch2Tutorial15`
Future<void> Ch2Tutorial15(Scene s) async {
    s.evBitMod('evbit', true, 7);
    s.setKeyIgnore(0);
    s.setSlot(13, 0);
    s.setSlot(1, 262153);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 0);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 0);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, Sym('EventScr_Ch2Tutorial16'));
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, Sym('EventScr_Ch2Tutorial15'));
    s.slotQueuePushSlot(0x1);
    await s.call(Sym('EventScr_Tutorial_Exec1'));
    s.setKeyIgnore(266);
    return;
}

/// `EventScr_Ch2Tutorial16`
Future<void> Ch2Tutorial16(Scene s) async {
    s.enqueueTutCall(1, Sym('EventScr_Ch2Tutorial17'));
    s.evBitMod('evbit', true, 7);
    return;
}

/// `EventScr_Ch2Tutorial17`
Future<void> Ch2Tutorial17(Scene s) async {
    s.setKeyIgnore(0);
    s.placeholder('EvtEnqueueCallDirectly');
    s.evBitMod('flag', true, 184);
    s.evBitMod('evbit', true, 7);
    return;
}

/// `EventScr_Ch2Tutorial18`
Future<void> Ch2Tutorial18(Scene s) async {
    s.evBitMod('evbit', true, 7);
    s.cameraToChar(5);
    s.setSlot(13, 0);
    s.setSlot(1, 5);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 196615);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 2361);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 5767200);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 2360);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 5767200);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, Sym('EventScr_Ch2Tutorial19'));
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, Sym('EventScr_Ch2Tutorial18'));
    s.slotQueuePushSlot(0x1);
    await s.call(Sym('EventScr_Tutorial_Exec0'));
    s.setKeyIgnore(1022);
    return;
}

/// `EventScr_Ch2Tutorial19`
Future<void> Ch2Tutorial19(Scene s) async {
    s.evBitMod('evbit', true, 7);
    s.placeholder('ASMC');
    s.overrideUnitMenu(65533);
    s.setKeyIgnore(0);
    s.enqueueTutCall(4, Sym('EventScr_Ch2Tutorial20'));
    return;
}

/// `EventScr_Ch2Tutorial2`
Future<void> Ch2Tutorial2(Scene s) async {
    s.evBitMod('evbit', true, 7);
    s.setKeyIgnore(0);
    s.setSlot(13, 0);
    s.setSlot(1, 327689);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 0);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 0);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, Sym('EventScr_Ch2Tutorial3'));
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, Sym('EventScr_Ch2Tutorial2'));
    s.slotQueuePushSlot(0x1);
    await s.call(Sym('EventScr_Tutorial_Exec1'));
    s.overrideUnitMenu(65527);
    s.setKeyIgnore(266);
    return;
}

/// `EventScr_Ch2Tutorial20`
Future<void> Ch2Tutorial20(Scene s) async {
    s.evBitMod('evbit', true, 7);
    s.setKeyIgnore(0);
    s.setTextType(3);
    s.setSlot(11, 3670032);
    await s.textShow(2362);
    await s.textEnd();
    s.textRemoveAll();
    s.setKeyIgnore(266);
    s.enqueueTutCall(1, Sym('EventScr_Ch2Tutorial21'));
    return;
}

/// `EventScr_Ch2Tutorial21`
Future<void> Ch2Tutorial21(Scene s) async {
    s.setKeyIgnore(0);
    s.setTextType(0);
    await s.textShow(2335);
    await s.textEnd();
    s.textRemoveAll();
    s.evBitMod('flag', true, 192);
    s.setTextType(3);
    s.setSlot(11, 4294967295);
    await s.textShow(2365);
    await s.textEnd();
    s.textRemoveAll();
    s.evBitMod('flag', true, 196);
    s.overrideUnitMenu(0);
    await s.call(Sym('EventScr_Ch2_7'));
    s.evBitMod('evbit', true, 7);
    return;
}

/// `EventScr_Ch2Tutorial22`
Future<void> Ch2Tutorial22(Scene s) async {
    s.setKeyIgnore(0);
    s.showCursorAtUnit(1);
    await s.stall(60);
    await s.endCursor();
    s.setTextType(0);
    await s.textShow(2332);
    await s.textEnd();
    s.textRemoveAll();
    s.setTextType(3);
    s.setSlot(11, 4294967295);
    await s.textShow(2368);
    await s.textEnd();
    s.textRemoveAll();
    s.showCursorAtUnit(1, flashing: true);
    await s.stall(60);
    await s.endCursor();
    s.placeholder('EvtEnqueueConditionalTutCall');
    s.overrideUnitMenu(16384);
    s.evBitMod('evbit', true, 7);
    return;
}

/// `EventScr_Ch2Tutorial23`
Future<void> Ch2Tutorial23(Scene s) async {
    s.evBitMod('evbit', true, 7);
    s.setSlot(13, 0);
    s.setSlot(1, 1);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 131076);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 2370);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 5767200);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 2369);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 5767200);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, Sym('EventScr_Ch2Tutorial24'));
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, Sym('EventScr_Ch2Tutorial23'));
    s.slotQueuePushSlot(0x1);
    await s.call(Sym('EventScr_Tutorial_Exec0'));
    return;
}

/// `EventScr_Ch2Tutorial24`
Future<void> Ch2Tutorial24(Scene s) async {
    s.evBitMod('evbit', true, 7);
    s.setKeyIgnore(0);
    s.setSlot(13, 0);
    s.setSlot(1, 131076);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 0);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 0);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, Sym('EventScr_Ch2Tutorial25'));
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, Sym('EventScr_Ch2Tutorial24'));
    s.slotQueuePushSlot(0x1);
    await s.call(Sym('EventScr_Tutorial_Exec1'));
    s.overrideUnitMenu(65503);
    s.setKeyIgnore(266);
    return;
}

/// `EventScr_Ch2Tutorial25`
Future<void> Ch2Tutorial25(Scene s) async {
    s.evBitMod('evbit', true, 7);
    s.setKeyIgnore(0);
    s.setTextType(3);
    s.setSlot(11, 3670032);
    await s.textShow(2371);
    await s.textEnd();
    s.textRemoveAll();
    s.setKeyIgnore(266);
    s.enqueueTutCall(1, Sym('EventScr_Ch2Tutorial26'));
    return;
}

/// `EventScr_Ch2Tutorial26`
Future<void> Ch2Tutorial26(Scene s) async {
    s.setKeyIgnore(0);
    s.setSlot(2, Sym('EventScr_Ch2_Village2', 160));
    await s.call(Sym('EventScr_CallOnTutorialMode'));
    s.overrideUnitMenu(0);
    s.placeholder('EvtEnqueueCallDirectly');
    s.evBitMod('evbit', true, 7);
    return;
}

/// `EventScr_Ch2Tutorial27`
Future<void> Ch2Tutorial27(Scene s) async {
    s.evBitMod('evbit', true, 7);
    s.cameraToChar(1);
    s.setSlot(13, 0);
    s.setSlot(1, 1);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 262150);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 2374);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 5767200);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 2373);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 5767200);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, Sym('EventScr_Ch2Tutorial28'));
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, Sym('EventScr_Ch2Tutorial27'));
    s.slotQueuePushSlot(0x1);
    await s.call(Sym('EventScr_Tutorial_Exec0'));
    return;
}

/// `EventScr_Ch2Tutorial28`
Future<void> Ch2Tutorial28(Scene s) async {
    s.evBitMod('evbit', true, 7);
    s.setKeyIgnore(0);
    s.setSlot(13, 0);
    s.setSlot(1, 262150);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 0);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 0);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, Sym('EventScr_Ch2Tutorial29'));
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, Sym('EventScr_Ch2Tutorial28'));
    s.slotQueuePushSlot(0x1);
    await s.call(Sym('EventScr_Tutorial_Exec1'));
    s.overrideUnitMenu(65471);
    s.setKeyIgnore(266);
    return;
}

/// `EventScr_Ch2Tutorial29`
Future<void> Ch2Tutorial29(Scene s) async {
    s.evBitMod('evbit', true, 7);
    s.setKeyIgnore(0);
    s.setTextType(3);
    s.setSlot(11, 3670032);
    await s.textShow(2375);
    await s.textEnd();
    s.textRemoveAll();
    s.setKeyIgnore(266);
    s.enqueueTutCall(1, Sym('EventScr_Ch2Tutorial30'));
    return;
}

/// `EventScr_Ch2Tutorial3`
Future<void> Ch2Tutorial3(Scene s) async {
    s.evBitMod('evbit', true, 7);
    s.setKeyIgnore(0);
    s.setTextType(3);
    s.setSlot(11, 3670088);
    await s.textShow(2354);
    await s.textEnd();
    s.textRemoveAll();
    s.setKeyIgnore(266);
    s.enqueueTutCall(2, Sym('EventScr_Ch2Tutorial4'));
    return;
}

/// `EventScr_Ch2Tutorial30`
Future<void> Ch2Tutorial30(Scene s) async {
    s.setKeyIgnore(0);
    s.setSlot(2, Sym('EventScr_Ch2_9'));
    await s.call(Sym('EventScr_CallOnTutorialMode'));
    s.overrideUnitMenu(0);
    s.evBitMod('evbit', true, 7);
    return;
}

/// `EventScr_Ch2Tutorial4`
Future<void> Ch2Tutorial4(Scene s) async {
    s.evBitMod('evbit', true, 7);
    s.setKeyIgnore(0);
    s.volumeDown(true);
    s.setTextType(0);
    await s.textShow(2333);
    await s.textEnd();
    s.textRemoveAll();
    s.volumeDown(false);
    s.overrideUnitMenu(0);
    s.placeholder('SHOW_ATTACK_RANGE');
    s.showCursorAt(8, 4, flashing: true);
    await s.stall(60);
    s.setTextType(3);
    s.setSlot(11, 5767184);
    await s.textShow(2355);
    await s.textEnd();
    s.textRemoveAll();
    await s.endCursor();
    s.setKeyIgnore(266);
    s.placeholder('EvtEnqueueConditionalTutCall');
    return;
}

/// `EventScr_Ch2Tutorial5`
Future<void> Ch2Tutorial5(Scene s) async {
    s.evBitMod('evbit', true, 7);
    s.setKeyIgnore(0);
    s.setSlot(13, 0);
    s.setSlot(1, 262152);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 0);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 0);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, Sym('EventScr_Ch2Tutorial6'));
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, Sym('EventScr_Ch2Tutorial5'));
    s.slotQueuePushSlot(0x1);
    await s.call(Sym('EventScr_Tutorial_Exec1'));
    s.setKeyIgnore(266);
    return;
}

/// `EventScr_Ch2Tutorial6`
Future<void> Ch2Tutorial6(Scene s) async {
    s.enqueueTutCall(1, Sym('EventScr_Ch2Tutorial7'));
    s.evBitMod('evbit', true, 7);
    return;
}

/// `EventScr_Ch2Tutorial7`
Future<void> Ch2Tutorial7(Scene s) async {
    s.setKeyIgnore(0);
    s.placeholder('EvtEnqueueCallDirectly');
    s.evBitMod('flag', true, 184);
    s.evBitMod('evbit', true, 7);
    return;
}

/// `EventScr_Ch2Tutorial8`
Future<void> Ch2Tutorial8(Scene s) async {
    s.evBitMod('evbit', true, 7);
    s.setSlot(13, 0);
    s.setSlot(1, 5);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 196615);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 2364);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 5767200);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 2363);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 5767200);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, Sym('EventScr_Ch2Tutorial9'));
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, Sym('EventScr_Ch2Tutorial8'));
    s.slotQueuePushSlot(0x1);
    await s.call(Sym('EventScr_Tutorial_Exec0'));
    return;
}

/// `EventScr_Ch2Tutorial9`
Future<void> Ch2Tutorial9(Scene s) async {
    s.evBitMod('evbit', true, 7);
    s.setKeyIgnore(0);
    s.setSlot(13, 0);
    s.setSlot(1, 196615);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 0);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 0);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, Sym('EventScr_Ch2Tutorial10'));
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, Sym('EventScr_Ch2Tutorial9'));
    s.slotQueuePushSlot(0x1);
    await s.call(Sym('EventScr_Tutorial_Exec1'));
    s.overrideUnitMenu(65531);
    s.setKeyIgnore(266);
    return;
}

/// `EventScr_Ch2_10`
Future<void> Ch2_10(Scene s) async {
    s.setTextType(3);
    s.setSlot(11, 4294967295);
    await s.textShow(2376);
    await s.textEnd();
    s.textRemoveAll();
    s.showCursorAt(5, 7);
    await s.stall(60);
    await s.endCursor();
    s.setTextType(3);
    s.setSlot(11, 4294967295);
    await s.textShow(2377);
    await s.textEnd();
    s.textRemoveAll();
    s.evBitMod('flag', true, 203);
    s.evBitMod('evbit', true, 7);
    return;
}

/// `EventScr_Ch2_4`
Future<void> Ch2_4(Scene s) async {
    s.setTextType(3);
    s.setSlot(11, 4294967295);
    await s.textShow(2363);
    await s.textEnd();
    s.textRemoveAll();
    s.showCursorAtUnit(5, flashing: true);
    await s.stall(60);
    await s.endCursor();
    s.enqueueTutCall(2, Sym('EventScr_Ch2Tutorial8'));
    s.overrideUnitMenu(16384);
    s.evBitMod('evbit', true, 7);
    return;
}

/// `EventScr_Ch2_5`
Future<void> Ch2_5(Scene s) async {
    s.setTextType(3);
    s.setSlot(11, 4294967295);
    await s.textShow(2357);
    await s.textEnd();
    s.textRemoveAll();
    s.showCursorAtUnit(6, flashing: true);
    await s.stall(60);
    await s.endCursor();
    s.enqueueTutCall(2, Sym('EventScr_Ch2Tutorial11'));
    s.overrideUnitMenu(16384);
    return;
}

/// `EventScr_Ch2_6`
Future<void> Ch2_6(Scene s) async {
    s.cameraToChar(5);
    s.setTextType(3);
    s.setSlot(11, 4294967295);
    await s.textShow(2360);
    await s.textEnd();
    s.textRemoveAll();
    s.showCursorAtUnit(5, flashing: true);
    await s.stall(60);
    await s.endCursor();
    s.enqueueTutCall(2, Sym('EventScr_Ch2Tutorial18'));
    s.overrideUnitMenu(16384);
    s.evBitMod('evbit', true, 7);
    return;
}

/// `EventScr_Ch2_7`
Future<void> Ch2_7(Scene s) async {
    s.cameraToChar(1);
    s.setTextType(3);
    s.setSlot(11, 4294967295);
    await s.textShow(2372);
    await s.textEnd();
    s.textRemoveAll();
    s.showCursorAtUnit(1, flashing: true);
    await s.stall(60);
    await s.endCursor();
    s.enqueueTutCall(2, Sym('EventScr_Ch2Tutorial27'));
    s.overrideUnitMenu(16384);
    s.evBitMod('evbit', true, 7);
    return;
}

/// `EventScr_Ch2_8`
Future<void> Ch2_8(Scene s) async {
    s.setTextType(3);
    s.setSlot(11, 4294967295);
    await s.textShow(2366);
    await s.textEnd();
    s.textRemoveAll();
    s.setTextType(3);
    s.setSlot(11, 4294967295);
    await s.textShow(2378);
    await s.textEnd();
    s.textRemoveAll();
    s.evBitMod('flag', true, 202);
    s.evBitMod('flag', true, 222);
    s.evBitMod('evbit', true, 7);
    return;
}

/// `EventScr_Ch2_BeginningScene`
Future<void> Ch2_BeginningScene(Scene s) async {
    s.sound('bgm', 36);
    s.setSlot(2, 30);
    await s.call(Sym('EventScr_SetBackground'));
    await s.textShow(2324);
    await s.textEnd();
    s.textRemoveAll();
    await s.fade(FadeDirection.toBlack, 16);
    await s.clearScreen();
    await s.fade(FadeDirection.fromBlack, 16);
    s.loadUnits(1, Sym('UnitDef_Ch2Ally'));
    await s.waitUnitMoving();
    s.placeholder('EvtBgmFadeIn');
    s.loadUnits(1, Sym('UnitDef_Ch2Enemy_0'));
    await s.waitUnitMoving();
    s.loadUnits(1, Sym('UnitDef_Ch2Enemy_2'));
    await s.waitUnitMoving();
    await s.stall(60, cancellable: false);
    s.sound('bgm', 26);
    s.showCursorAtUnit(71);
    await s.stall(60);
    await s.endCursor();
    s.setTextType(0);
    await s.textShow(2325);
    await s.textEnd();
    s.textRemoveAll();
    s.moveUnit('MOVE', [24, 72, 14, 9]);
    await s.waitUnitMoving();
    await s.removeUnit(72);
    s.showCursorAt(12, 3);
    await s.stall(60);
    await s.endCursor();
    s.sound('bgm', 37);
    s.setSlot(2, 2);
    s.setSlot(3, 2326);
    await s.call(Sym('Event_TextWithBG'));
    s.showCursorAtUnit(71);
    await s.stall(60);
    await s.endCursor();
    s.setTextType(0);
    await s.textShow(2327);
    await s.textEnd();
    s.textRemoveAll();
    s.moveUnit('MOVE', [24, 71, 9, 14]);
    await s.waitUnitMoving();
    s.setSlot(11, 327692);
    s.moveUnit('MOVE', [0, 65534, 12, 3]);
    await s.waitUnitMoving();
    s.sound('se', 171);
    s.setSlot(11, 131084);
    await s.tileChange(65535);
    s.sound('se', 92);
    s.placeholder('NOTIFY');
    s.loadUnits(1, Sym('UnitDef_Ch2NPC'));
    await s.waitUnitMoving();
    s.setSlot(1, 5);
    await s.setUnitHpFromSlot(7);
    s.showCursorAtUnit(7);
    await s.stall(60);
    await s.endCursor();
    s.setSlot(2, 37);
    s.setSlot(3, 2328);
    await s.call(Sym('Event_TextWithBG'));
    s.setSlot(2, Sym('EventScr_Ch2_Village2', 192));
    await s.call(Sym('EventScr_CallOnTutorialMode'));
    s.loadUnits(1, Sym('UnitDef_Event_Ch2Ally'));
    await s.waitUnitMoving();
    s.showCursorAtUnit(6);
    await s.stall(60);
    await s.endCursor();
    s.setTextType(0);
    await s.textShow(2329);
    await s.textEnd();
    s.textRemoveAll();
    s.moveUnit('MOVE', [24, 6, 2, 3]);
    await s.waitUnitMoving();
    s.showCursorAtUnit(6);
    await s.stall(60);
    await s.endCursor();
    s.setTextType(0);
    await s.textShow(2330);
    await s.textEnd();
    s.textRemoveAll();
    s.setSlot(2, Sym('EventScr_Ch2_Village2', 224));
    await s.call(Sym('EventScr_CallOnTutorialMode'));
    s.showCursorAtUnit(5);
    await s.stall(60);
    await s.endCursor();
    s.setTextType(0);
    await s.textShow(2331);
    await s.textEnd();
    s.textRemoveAll();
    s.moveUnit('MOVE', [24, 6, 6, 3]);
    await s.waitUnitMoving();
    s.evBitMod('evbit', true, 7);
    return;
}

/// `EventScr_Ch2_EndingScene`
Future<void> Ch2_EndingScene(Scene s) async {
    var pc = 0;
    while (true) {
      switch (pc) {
        case 0:
          s.sound('bgm', 49);
          pc = 1;
          continue;
        case 1:
          s.checkSlot('alive', 10);
          pc = 2;
          continue;
        case 2:
          if (s.slotInt(12) == s.slotInt(0)) { pc = 15; } else { pc = 3; }
          continue;
        case 3:
          s.checkSlot('alive', 7);
          pc = 4;
          continue;
        case 4:
          if (s.slotInt(12) == s.slotInt(0)) { pc = 15; } else { pc = 5; }
          continue;
        case 5:
          s.setSlot(2, 37);
          pc = 6;
          continue;
        case 6:
          await s.call(Sym('EventScr_SetBackground'));
          pc = 7;
          continue;
        case 7:
          await s.textShow(2338);
          pc = 8;
          continue;
        case 8:
          await s.textEnd();
          pc = 9;
          continue;
        case 9:
          s.textRemoveAll();
          pc = 10;
          continue;
        case 10:
          await s.fade(FadeDirection.toBlack, 16);
          pc = 11;
          continue;
        case 11:
          s.setSlot(2, 10);
          pc = 12;
          continue;
        case 12:
          await s.call(Sym('EventScr_LoadUniqueAlly'));
          pc = 13;
          continue;
        case 13:
          s.setSlot(2, 7);
          pc = 14;
          continue;
        case 14:
          await s.call(Sym('EventScr_LoadUniqueAlly'));
          pc = 15;
          continue;
        case 15:
          pc = 16;
          continue;
        case 16:
          s.setSlot(2, 6);
          pc = 17;
          continue;
        case 17:
          await s.call(Sym('EventScr_SetBackground'));
          pc = 18;
          continue;
        case 18:
          await s.textShow(2339);
          pc = 19;
          continue;
        case 19:
          await s.textEnd();
          pc = 20;
          continue;
        case 20:
          await s.fade(FadeDirection.toBlack, 4);
          pc = 21;
          continue;
        case 21:
          s.placeholder('EvtBgmFadeIn');
          pc = 22;
          continue;
        case 22:
          s.textRemoveAll();
          pc = 23;
          continue;
        case 23:
          s.setTextType(1);
          pc = 24;
          continue;
        case 24:
          s.showTextBg(41);
          pc = 25;
          continue;
        case 25:
          await s.fade(FadeDirection.fromBlack, 2);
          pc = 26;
          continue;
        case 26:
          await s.textShow(2340);
          pc = 27;
          continue;
        case 27:
          await s.textEnd();
          pc = 28;
          continue;
        case 28:
          await s.fade(FadeDirection.toWhite, 2);
          pc = 29;
          continue;
        case 29:
          s.textRemoveAll();
          pc = 30;
          continue;
        case 30:
          s.showTextBg(28);
          pc = 31;
          continue;
        case 31:
          await s.fade(FadeDirection.fromWhite, 2);
          pc = 32;
          continue;
        case 32:
          s.sound('bgm', 82);
          pc = 33;
          continue;
        case 33:
          await s.popupText(408, 8, 8);
          pc = 34;
          continue;
        case 34:
          await s.textShow(2341);
          pc = 35;
          continue;
        case 35:
          await s.textEnd();
          pc = 36;
          continue;
        case 36:
          await s.fade(FadeDirection.toWhite, 2);
          pc = 37;
          continue;
        case 37:
          s.placeholder('EvtBgmFadeIn');
          pc = 38;
          continue;
        case 38:
          s.textRemoveAll();
          pc = 39;
          continue;
        case 39:
          s.showTextBg(41);
          pc = 40;
          continue;
        case 40:
          await s.fade(FadeDirection.fromWhite, 2);
          pc = 41;
          continue;
        case 41:
          s.placeholder('EvtBgmFadeIn');
          pc = 42;
          continue;
        case 42:
          await s.textShow(2342);
          pc = 43;
          continue;
        case 43:
          await s.textEnd();
          pc = 44;
          continue;
        case 44:
          s.textRemoveAll();
          pc = 45;
          continue;
        case 45:
          await s.fade(FadeDirection.toBlack, 16);
          pc = 46;
          continue;
        case 46:
          s.evBitMod('flag', true, 208);
          pc = 47;
          continue;
        case 47:
          s.evBitMod('flag', true, 232);
          pc = 48;
          continue;
        case 48:
          s.evBitMod('flag', true, 188);
          pc = 49;
          continue;
        case 49:
          s.evBitMod('flag', true, 184);
          pc = 50;
          continue;
        case 50:
          s.evBitMod('flag', true, 197);
          pc = 51;
          continue;
        case 51:
          s.evBitMod('flag', true, 184);
          pc = 52;
          continue;
        case 52:
          s.evBitMod('flag', true, 192);
          pc = 53;
          continue;
        case 53:
          s.evBitMod('flag', true, 196);
          pc = 54;
          continue;
        case 54:
          s.evBitMod('flag', true, 202);
          pc = 55;
          continue;
        case 55:
          s.evBitMod('flag', true, 222);
          pc = 56;
          continue;
        case 56:
          s.evBitMod('flag', true, 218);
          pc = 57;
          continue;
        case 57:
          s.evBitMod('flag', true, 203);
          pc = 58;
          continue;
        case 58:
          await s.changeChapter(3, subcmd: 1);
          pc = 59;
          continue;
        case 59:
          s.setSlot(2, 7);
          pc = 60;
          continue;
        case 60:
          await s.call(Sym('EventScr_StrictLoadUniqueAlly'));
          pc = 61;
          continue;
        case 61:
          s.setSlot(2, 10);
          pc = 62;
          continue;
        case 62:
          await s.call(Sym('EventScr_StrictLoadUniqueAlly'));
          pc = 63;
          continue;
        case 63:
          return;
        default:
          return;
      }
    }
}

/// `EventScr_Ch2_Turn1Player`
Future<void> Ch2_Turn1Player(Scene s) async {
    s.setSlot(2, Sym('EventScr_Ch2_Village2', 256));
    await s.call(Sym('EventScr_CallOnTutorialMode'));
    s.evBitMod('evbit', true, 7);
    return;
}

/// `EventScr_Ch2_Turn2Player`
Future<void> Ch2_Turn2Player(Scene s) async {
    s.setSlot(2, Sym('EventScr_Ch2_5'));
    await s.call(Sym('EventScr_CallOnTutorialMode'));
    s.evBitMod('evbit', true, 7);
    return;
}

/// `EventScr_Ch2_Village1`
Future<void> Ch2_Village1(Scene s) async {
    var pc = 0;
    while (true) {
      switch (pc) {
        case 0:
          s.setKeyIgnore(0);
          pc = 1;
          continue;
        case 1:
          s.checkSlotValue('activePid');
          pc = 2;
          continue;
        case 2:
          s.setSlot(1, 1);
          pc = 3;
          continue;
        case 3:
          if (s.slotInt(12) != s.slotInt(1)) { pc = 10; } else { pc = 4; }
          continue;
        case 4:
          s.volumeDown(true);
          pc = 5;
          continue;
        case 5:
          s.setSlot(2, 2);
          pc = 6;
          continue;
        case 6:
          s.setSlot(3, 2345);
          pc = 7;
          continue;
        case 7:
          await s.call(Sym('Event_TextWithBG'));
          pc = 8;
          continue;
        case 8:
          s.volumeDown(false);
          pc = 9;
          continue;
        case 9:
          pc = 16;
          continue;
        case 10:
          pc = 11;
          continue;
        case 11:
          s.volumeDown(true);
          pc = 12;
          continue;
        case 12:
          s.setSlot(2, 2);
          pc = 13;
          continue;
        case 13:
          s.setSlot(3, 2346);
          pc = 14;
          continue;
        case 14:
          await s.call(Sym('Event_TextWithBG'));
          pc = 15;
          continue;
        case 15:
          s.volumeDown(false);
          pc = 16;
          continue;
        case 16:
          pc = 17;
          continue;
        case 17:
          await s.call(Sym('data_085B9BBC', 360));
          pc = 18;
          continue;
        case 18:
          s.setSlot(3, 118);
          pc = 19;
          continue;
        case 19:
          await s.giveItem(65535, 3);
          pc = 20;
          continue;
        case 20:
          s.evBitMod('evbit', true, 7);
          pc = 21;
          continue;
        case 21:
          return;
        default:
          return;
      }
    }
}

/// `EventScr_Ch2_Village2`
Future<void> Ch2_Village2(Scene s) async {
    s.volumeDown(true);
    s.setSlot(2, 2);
    s.setSlot(3, 2347);
    await s.call(Sym('Event_TextWithBG'));
    s.volumeDown(false);
    await s.call(Sym('data_085B9BBC', 360));
    s.setSlot(3, 109);
    await s.giveItem(65535, 3);
    s.evBitMod('evbit', true, 7);
    return;
    s.volumeDown(true);
    s.setSlot(2, 2);
    s.setSlot(3, 2348);
    await s.call(Sym('Event_TextWithBG'));
    s.volumeDown(false);
    await s.call(Sym('data_085B9BBC', 360));
    s.setSlot(3, 110);
    await s.giveItem(65535, 3);
    s.evBitMod('evbit', true, 7);
    return;
    s.setSlot(2, Sym('UnitDef_Ch2Enemy_1'));
    await s.call(Sym('EventScr_LoadReinforce'));
    s.setSlot(2, Sym('EventScr_Ch2_8'));
    await s.call(Sym('EventScr_CallOnTutorialMode'));
    s.evBitMod('evbit', true, 7);
    return;
    s.setTextType(3);
    s.setSlot(11, 4294967295);
    await s.textShow(2349);
    await s.textEnd();
    s.textRemoveAll();
    s.evBitMod('flag', true, 208);
    return;
    s.setTextType(3);
    s.setSlot(11, 4294967295);
    await s.textShow(2350);
    await s.textEnd();
    s.textRemoveAll();
    s.evBitMod('flag', true, 232);
    return;
    s.setTextType(3);
    s.setSlot(11, 4294967295);
    await s.textShow(2351);
    await s.textEnd();
    s.textRemoveAll();
    s.evBitMod('flag', true, 188);
    return;
    s.setTextType(3);
    s.setSlot(11, 4294967295);
    await s.textShow(2352);
    await s.textEnd();
    s.textRemoveAll();
    s.showCursorAtUnit(6, flashing: true);
    await s.stall(60);
    await s.endCursor();
    s.enqueueTutCall(2, Sym('EventScr_Ch2_Village2', 308));
    s.overrideUnitMenu(16384);
    return;
    s.evBitMod('evbit', true, 7);
    s.setSlot(13, 0);
    s.setSlot(1, 6);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 327689);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 2353);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 5767200);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 2356);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 5767200);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, Sym('EventScr_Ch2Tutorial2'));
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, Sym('EventScr_Ch2_Village2', 308));
    s.slotQueuePushSlot(0x1);
    await s.call(Sym('EventScr_Tutorial_Exec0'));
    return;
}

/// `EventScr_Ch3_0`
Future<void> Ch3_0(Scene s) async {
    await s.cameraTo(7, 7, centered: true);
    await s.stall(15);
    s.setSlot(13, 0);
    s.setSlot(1, 196610);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 655366);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 327690);
    s.slotQueuePushSlot(0x1);
    await s.call(Sym('EventScr_FormatFlashingCursor'));
    await s.stall(60);
    await s.endCursor();
    s.setTextType(0);
    await s.textShow(2381);
    await s.textEnd();
    s.textRemoveAll();
    await s.cameraTo(7, 10, centered: true);
    await s.stall(15);
    s.setSlot(13, 0);
    s.setSlot(1, 589828);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 786436);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 524296);
    s.slotQueuePushSlot(0x1);
    await s.call(Sym('EventScr_FormatFlashingCursor'));
    await s.stall(60);
    await s.endCursor();
    s.setTextType(3);
    s.setSlot(11, 4294967295);
    await s.textShow(2395);
    await s.textEnd();
    s.textRemoveAll();
    s.evBitMod('flag', true, 211);
    return;
}

/// `EventScr_Ch3_5`
Future<void> Ch3_5(Scene s) async {
    s.showCursorAtUnit(8);
    await s.stall(60);
    await s.endCursor();
    s.setTextType(0);
    await s.textShow(2383);
    await s.textEnd();
    s.textRemoveAll();
    s.moveUnit('MOVE', [0, 8, 3, 9]);
    await s.waitUnitMoving();
    s.setSlot(13, 0);
    s.setSlot(1, 0);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 4294967295);
    s.slotQueuePushSlot(0x1);
    s.setSlot(11, 589829);
    s.placeholder('FIGHT');
    s.setTextType(3);
    s.setSlot(11, 4294967295);
    await s.textShow(2399);
    await s.textEnd();
    s.textRemoveAll();
    return;
}

/// `EventScr_Ch3_BeginningScene`
Future<void> Ch3_BeginningScene(Scene s) async {
    var pc = 0;
    while (true) {
      switch (pc) {
        case 0:
          s.sound('bgm', 37);
          pc = 1;
          continue;
        case 1:
          s.setSlot(2, 30);
          pc = 2;
          continue;
        case 2:
          await s.call(Sym('EventScr_SetBackground'));
          pc = 3;
          continue;
        case 3:
          await s.textShow(2379);
          pc = 4;
          continue;
        case 4:
          await s.textEnd();
          pc = 5;
          continue;
        case 5:
          s.textRemoveAll();
          pc = 6;
          continue;
        case 6:
          s.setSlot(2, 37);
          pc = 7;
          continue;
        case 7:
          await s.call(Sym('EventScr_SetBackground'));
          pc = 8;
          continue;
        case 8:
          await s.textShow(2380);
          pc = 9;
          continue;
        case 9:
          await s.textEnd();
          pc = 10;
          continue;
        case 10:
          s.textRemoveAll();
          pc = 11;
          continue;
        case 11:
          await s.fade(FadeDirection.toBlack, 16);
          pc = 12;
          continue;
        case 12:
          await s.clearScreen();
          pc = 13;
          continue;
        case 13:
          s.loadUnits(1, Sym('UnitDef_Ch3Enemy_0'));
          pc = 14;
          continue;
        case 14:
          await s.waitUnitMoving();
          pc = 15;
          continue;
        case 15:
          await s.fade(FadeDirection.fromBlack, 16);
          pc = 16;
          continue;
        case 16:
          s.loadUnits(2, Sym('UnitDef_Event_Ch3Ally'));
          pc = 17;
          continue;
        case 17:
          await s.waitUnitMoving();
          pc = 18;
          continue;
        case 18:
          s.setSlot(2, Sym('EventScr_Ch3_0'));
          pc = 19;
          continue;
        case 19:
          await s.call(Sym('EventScr_CallOnTutorialMode'));
          pc = 20;
          continue;
        case 20:
          s.checkSlotValue('tutorial');
          pc = 21;
          continue;
        case 21:
          if (s.slotInt(12) != s.slotInt(0)) { pc = 29; } else { pc = 22; }
          continue;
        case 22:
          s.showCursorAtUnit(8);
          pc = 23;
          continue;
        case 23:
          await s.stall(60);
          pc = 24;
          continue;
        case 24:
          await s.endCursor();
          pc = 25;
          continue;
        case 25:
          s.setTextType(0);
          pc = 26;
          continue;
        case 26:
          await s.textShow(2382);
          pc = 27;
          continue;
        case 27:
          await s.textEnd();
          pc = 28;
          continue;
        case 28:
          s.textRemoveAll();
          pc = 29;
          continue;
        case 29:
          pc = 30;
          continue;
        case 30:
          s.setSlot(2, Sym('EventScr_Ch3_5'));
          pc = 31;
          continue;
        case 31:
          await s.call(Sym('EventScr_CallOnTutorialMode'));
          pc = 32;
          continue;
        case 32:
          s.setSlot(2, 2);
          pc = 33;
          continue;
        case 33:
          await s.call(Sym('EventScr_MoveUnitS2ToLeader'));
          pc = 34;
          continue;
        case 34:
          await s.fade(FadeDirection.toBlack, 16);
          pc = 35;
          continue;
        case 35:
          s.loadUnits(1, Sym('UnitDef_Event_Ch3Ally'));
          pc = 36;
          continue;
        case 36:
          await s.waitUnitMoving();
          pc = 37;
          continue;
        case 37:
          s.checkSlotValue('tutorial');
          pc = 38;
          continue;
        case 38:
          if (s.slotInt(12) != s.slotInt(0)) { pc = 40; } else { pc = 39; }
          continue;
        case 39:
          pc = 42;
          continue;
        case 40:
          pc = 41;
          continue;
        case 41:
          s.moveUnit('MOVE', [65535, 8, 3, 9]);
          pc = 42;
          continue;
        case 42:
          pc = 43;
          continue;
        case 43:
          s.cameraToChar(72);
          pc = 44;
          continue;
        case 44:
          await s.fade(FadeDirection.fromBlack, 16);
          pc = 45;
          continue;
        case 45:
          s.checkSlotValue('tutorial');
          pc = 46;
          continue;
        case 46:
          if (s.slotInt(12) != s.slotInt(0)) { pc = 55; } else { pc = 47; }
          continue;
        case 47:
          s.sound('bgm', 19);
          pc = 48;
          continue;
        case 48:
          s.showCursorAtUnit(72);
          pc = 49;
          continue;
        case 49:
          await s.stall(60);
          pc = 50;
          continue;
        case 50:
          await s.endCursor();
          pc = 51;
          continue;
        case 51:
          s.setTextType(0);
          pc = 52;
          continue;
        case 52:
          await s.textShow(2384);
          pc = 53;
          continue;
        case 53:
          await s.textEnd();
          pc = 54;
          continue;
        case 54:
          s.textRemoveAll();
          pc = 55;
          continue;
        case 55:
          pc = 56;
          continue;
        case 56:
          s.setSlot(2, Sym('EventScr_Ch3_1'));
          pc = 57;
          continue;
        case 57:
          await s.call(Sym('EventScr_CallOnTutorialMode'));
          pc = 58;
          continue;
        case 58:
          s.setSlot(2, Sym('EventScr_Ch3_4'));
          pc = 59;
          continue;
        case 59:
          await s.call(Sym('EventScr_CallOnTutorialMode'));
          pc = 60;
          continue;
        case 60:
          s.evBitMod('evbit', true, 7);
          pc = 61;
          continue;
        case 61:
          return;
        default:
          return;
      }
    }
}

/// `EventScr_Ch3_EndingScene`
Future<void> Ch3_EndingScene(Scene s) async {
    var pc = 0;
    while (true) {
      switch (pc) {
        case 0:
          s.sound('bgm', 49);
          pc = 1;
          continue;
        case 1:
          s.checkSlot('alive', 9);
          pc = 2;
          continue;
        case 2:
          if (s.slotInt(12) == s.slotInt(0)) { pc = 14; } else { pc = 3; }
          continue;
        case 3:
          s.checkSlot('alive', 8);
          pc = 4;
          continue;
        case 4:
          if (s.slotInt(12) == s.slotInt(0)) { pc = 14; } else { pc = 5; }
          continue;
        case 5:
          s.setSlot(2, 60);
          pc = 6;
          continue;
        case 6:
          await s.call(Sym('EventScr_SetBackground'));
          pc = 7;
          continue;
        case 7:
          await s.textShow(2389);
          pc = 8;
          continue;
        case 8:
          await s.textEnd();
          pc = 9;
          continue;
        case 9:
          s.textRemoveAll();
          pc = 10;
          continue;
        case 10:
          await s.fade(FadeDirection.toBlack, 16);
          pc = 11;
          continue;
        case 11:
          s.setSlot(2, 9);
          pc = 12;
          continue;
        case 12:
          await s.call(Sym('EventScr_LoadUniqueAlly'));
          pc = 13;
          continue;
        case 13:
          pc = 17;
          continue;
        case 14:
          pc = 15;
          continue;
        case 15:
          s.setSlot(2, 9);
          pc = 16;
          continue;
        case 16:
          await s.call(Sym('EventScr_StrictLoadUniqueAlly'));
          pc = 17;
          continue;
        case 17:
          pc = 18;
          continue;
        case 18:
          s.setSlot(2, 62);
          pc = 19;
          continue;
        case 19:
          await s.call(Sym('EventScr_SetBackground'));
          pc = 20;
          continue;
        case 20:
          await s.textShow(2390);
          pc = 21;
          continue;
        case 21:
          await s.textEnd();
          pc = 22;
          continue;
        case 22:
          s.textRemoveAll();
          pc = 23;
          continue;
        case 23:
          s.placeholder('EvtBgmFadeIn');
          pc = 24;
          continue;
        case 24:
          await s.fade(FadeDirection.toBlack, 4);
          pc = 25;
          continue;
        case 25:
          s.setSlot(2, 131087);
          pc = 26;
          continue;
        case 26:
          await s.call(Sym('EventScr_9EEA58'));
          pc = 27;
          continue;
        case 27:
          s.setSlot(2, 17);
          pc = 28;
          continue;
        case 28:
          await s.call(Sym('EventScr_SetBackground'));
          pc = 29;
          continue;
        case 29:
          await s.textShow(2391);
          pc = 30;
          continue;
        case 30:
          await s.textEnd();
          pc = 31;
          continue;
        case 31:
          s.textRemoveAll();
          pc = 32;
          continue;
        case 32:
          await s.fade(FadeDirection.toBlack, 16);
          pc = 33;
          continue;
        case 33:
          await s.clearScreen();
          pc = 34;
          continue;
        case 34:
          s.loadUnits(1, Sym('UnitDef_Ch3Enemy_1'));
          pc = 35;
          continue;
        case 35:
          await s.waitUnitMoving();
          pc = 36;
          continue;
        case 36:
          await s.fade(FadeDirection.fromBlack, 16);
          pc = 37;
          continue;
        case 37:
          s.sound('bgm', 46);
          pc = 38;
          continue;
        case 38:
          s.showCursorAtUnit(107);
          pc = 39;
          continue;
        case 39:
          await s.stall(60);
          pc = 40;
          continue;
        case 40:
          await s.endCursor();
          pc = 41;
          continue;
        case 41:
          s.setTextType(0);
          pc = 42;
          continue;
        case 42:
          await s.textShow(2392);
          pc = 43;
          continue;
        case 43:
          await s.textEnd();
          pc = 44;
          continue;
        case 44:
          s.textRemoveAll();
          pc = 45;
          continue;
        case 45:
          s.sound('se', 177);
          pc = 46;
          continue;
        case 46:
          await s.tileChange(0);
          pc = 47;
          continue;
        case 47:
          s.setSlot(13, 0);
          pc = 48;
          continue;
        case 48:
          s.setSlot(1, 65806);
          pc = 49;
          continue;
        case 49:
          s.slotQueuePushSlot(0x1);
          pc = 50;
          continue;
        case 50:
          s.setSlot(1, 0);
          pc = 51;
          continue;
        case 51:
          s.slotQueuePushSlot(0x1);
          pc = 52;
          continue;
        case 52:
          s.setSlot(1, 65804);
          pc = 53;
          continue;
        case 53:
          s.slotQueuePushSlot(0x1);
          pc = 54;
          continue;
        case 54:
          s.setSlot(1, 0);
          pc = 55;
          continue;
        case 55:
          s.slotQueuePushSlot(0x1);
          pc = 56;
          continue;
        case 56:
          s.moveUnit('MOVE_DEFINED', [29]);
          pc = 57;
          continue;
        case 57:
          s.moveUnit('MOVE_1STEP', [16, 105, 0]);
          pc = 58;
          continue;
        case 58:
          s.moveUnit('MOVE_1STEP', [16, 68, 1]);
          pc = 59;
          continue;
        case 59:
          await s.waitUnitMoving();
          pc = 60;
          continue;
        case 60:
          s.loadUnits(1, Sym('UnitDef_Ch3Enemy_2'));
          pc = 61;
          continue;
        case 61:
          await s.waitUnitMoving();
          pc = 62;
          continue;
        case 62:
          s.showCursorAtUnit(107);
          pc = 63;
          continue;
        case 63:
          await s.stall(60);
          pc = 64;
          continue;
        case 64:
          await s.endCursor();
          pc = 65;
          continue;
        case 65:
          s.setTextType(0);
          pc = 66;
          continue;
        case 66:
          await s.textShow(2393);
          pc = 67;
          continue;
        case 67:
          await s.textEnd();
          pc = 68;
          continue;
        case 68:
          s.textRemoveAll();
          pc = 69;
          continue;
        case 69:
          await s.fade(FadeDirection.toBlack, 16);
          pc = 70;
          continue;
        case 70:
          s.evBitMod('flag', true, 211);
          pc = 71;
          continue;
        case 71:
          s.evBitMod('flag', true, 209);
          pc = 72;
          continue;
        case 72:
          s.evBitMod('flag', true, 233);
          pc = 73;
          continue;
        case 73:
          s.evBitMod('flag', true, 216);
          pc = 74;
          continue;
        case 74:
          s.evBitMod('flag', true, 217);
          pc = 75;
          continue;
        case 75:
          s.evBitMod('flag', true, 198);
          pc = 76;
          continue;
        case 76:
          s.unitStateOp('reveal', 2);
          pc = 77;
          continue;
        case 77:
          await s.changeChapter(4, subcmd: 1);
          pc = 78;
          continue;
        case 78:
          return;
        default:
          return;
      }
    }
}

/// `EventScr_Ch3_Talk_NeimiColm`
Future<void> Ch3_Talk_NeimiColm(Scene s) async {
    s.sound('override', 48);
    await s.stall(33);
    s.setTextType(0);
    await s.textShow(2394);
    await s.textEnd();
    s.textRemoveAll();
    s.restoreBgm(2);
    s.placeholder('CHANGESTATE');
    s.setSlot(2, Sym('EventScr_Ch3_6'));
    await s.call(Sym('EventScr_CallOnTutorialMode'));
    s.evBitMod('evbit', true, 7);
    return;
}

/// `EventScr_Ch3_Turn1Npc`
Future<void> Ch3_Turn1Npc(Scene s) async {
    await s.cameraTo(0, 0, centered: false);
    await s.stall(15);
    s.loadUnits(1, Sym('UnitDef_Ch3NPC'));
    await s.waitUnitMoving();
    s.sound('bgm', 15);
    s.showCursorAtUnit(9);
    await s.stall(60);
    await s.endCursor();
    s.setTextType(0);
    await s.textShow(2386);
    await s.textEnd();
    s.textRemoveAll();
    s.setSlot(2, Sym('EventScr_Ch3_2'));
    await s.call(Sym('EventScr_CallOnTutorialMode'));
    s.moveUnit('MOVE_CLOSEST', [0, 9, 2, 4]);
    await s.waitUnitMoving();
    s.setSlot(2, Sym('EventScr_Ch3_3'));
    await s.call(Sym('EventScr_CallOnTutorialMode'));
    s.evBitMod('evbit', true, 7);
    return;
}

/// `EventScr_Ch3_Turn2Player`
Future<void> Ch3_Turn2Player(Scene s) async {
    s.setSlot(2, Sym('EventScr_Ch3_7'));
    await s.call(Sym('EventScr_CallOnTutorialMode'));
    s.evBitMod('evbit', true, 7);
    return;
}

/// `EventScr_Ch4_0`
Future<void> Ch4_0(Scene s) async {
    await s.cameraTo(7, 0, centered: true);
    await s.stall(15);
    s.loadUnits(1, Sym('UnitDef_Ch4NPC_0'));
    await s.waitUnitMoving();
    s.sound('bgm', 42);
    s.showCursorAtUnit(25);
    await s.stall(60);
    await s.endCursor();
    s.setTextType(0);
    await s.textShow(2412);
    await s.textEnd();
    s.textRemoveAll();
    s.moveUnit('MOVE', [24, 25, 15, 2]);
    s.moveUnit('MOVE', [24, 26, 15, 1]);
    s.moveUnit('MOVE', [24, 28, 15, 1]);
    await s.waitUnitMoving();
    s.hideFaction('green');
    s.evBitMod('evbit', true, 7);
    return;
}

/// `EventScr_Ch4_1`
Future<void> Ch4_1(Scene s) async {
    var pc = 0;
    while (true) {
      switch (pc) {
        case 0:
          s.sound('bgm', 49);
          pc = 1;
          continue;
        case 1:
          s.checkSlot('exists', 12);
          pc = 2;
          continue;
        case 2:
          if (s.slotInt(12) != s.slotInt(0)) { pc = 18; } else { pc = 3; }
          continue;
        case 3:
          s.setSlot(2, 2);
          pc = 4;
          continue;
        case 4:
          await s.call(Sym('EventScr_SetBackground'));
          pc = 5;
          continue;
        case 5:
          s.checkSlot('alive', 19);
          pc = 6;
          continue;
        case 6:
          if (s.slotInt(12) == s.slotInt(0)) { pc = 9; } else { pc = 7; }
          continue;
        case 7:
          s.setSlot(2, 2413);
          pc = 8;
          continue;
        case 8:
          pc = 11;
          continue;
        case 9:
          pc = 10;
          continue;
        case 10:
          s.setSlot(2, 2414);
          pc = 11;
          continue;
        case 11:
          pc = 12;
          continue;
        case 12:
          await s.textShow(65535);
          pc = 13;
          continue;
        case 13:
          await s.textEnd();
          pc = 14;
          continue;
        case 14:
          s.textRemoveAll();
          pc = 15;
          continue;
        case 15:
          await s.fade(FadeDirection.toBlack, 16);
          pc = 16;
          continue;
        case 16:
          s.loadUnits(1, Sym('UnitDef_Ch4Ally_2'));
          pc = 17;
          continue;
        case 17:
          await s.waitUnitMoving();
          pc = 18;
          continue;
        case 18:
          pc = 19;
          continue;
        case 19:
          s.sound('bgm', 50);
          pc = 20;
          continue;
        case 20:
          s.setSlot(2, 30);
          pc = 21;
          continue;
        case 21:
          await s.call(Sym('EventScr_SetBackground'));
          pc = 22;
          continue;
        case 22:
          s.checkSlot('alive', 19);
          pc = 23;
          continue;
        case 23:
          if (s.slotInt(12) == s.slotInt(0)) { pc = 28; } else { pc = 24; }
          continue;
        case 24:
          s.checkSlot('alive', 12);
          pc = 25;
          continue;
        case 25:
          if (s.slotInt(12) == s.slotInt(0)) { pc = 28; } else { pc = 26; }
          continue;
        case 26:
          s.setSlot(2, 2415);
          pc = 27;
          continue;
        case 27:
          pc = 30;
          continue;
        case 28:
          pc = 29;
          continue;
        case 29:
          s.setSlot(2, 2416);
          pc = 30;
          continue;
        case 30:
          pc = 31;
          continue;
        case 31:
          await s.textShow(65535);
          pc = 32;
          continue;
        case 32:
          await s.textEnd();
          pc = 33;
          continue;
        case 33:
          s.textRemoveAll();
          pc = 34;
          continue;
        case 34:
          await s.fade(FadeDirection.toBlack, 16);
          pc = 35;
          continue;
        case 35:
          s.placeholder('EvtBgmFadeIn');
          pc = 36;
          continue;
        case 36:
          await s.clearScreen();
          pc = 37;
          continue;
        case 37:
          await s.cameraTo(7, 7, centered: true);
          pc = 38;
          continue;
        case 38:
          s.hideFaction('blue');
          pc = 39;
          continue;
        case 39:
          s.hideFaction('red');
          pc = 40;
          continue;
        case 40:
          s.hideFaction('green');
          pc = 41;
          continue;
        case 41:
          s.loadUnits(2, Sym('UnitDef_Ch4Ally_3'));
          pc = 42;
          continue;
        case 42:
          await s.waitUnitMoving();
          pc = 43;
          continue;
        case 43:
          await s.fade(FadeDirection.fromBlack, 16);
          pc = 44;
          continue;
        case 44:
          s.loadUnits(1, Sym('UnitDef_Ch4NPC_1'));
          pc = 45;
          continue;
        case 45:
          await s.waitUnitMoving();
          pc = 46;
          continue;
        case 46:
          s.sound('bgm', 42);
          pc = 47;
          continue;
        case 47:
          s.showCursorAtUnit(25);
          pc = 48;
          continue;
        case 48:
          await s.stall(60);
          pc = 49;
          continue;
        case 49:
          await s.endCursor();
          pc = 50;
          continue;
        case 50:
          s.setSlot(2, 30);
          pc = 51;
          continue;
        case 51:
          await s.call(Sym('EventScr_SetBackground'));
          pc = 52;
          continue;
        case 52:
          await s.textShow(2417);
          pc = 53;
          continue;
        case 53:
          await s.textEnd();
          pc = 54;
          continue;
        case 54:
          s.textRemoveAll();
          pc = 55;
          continue;
        case 55:
          s.evBitMod('flag', true, 210);
          pc = 56;
          continue;
        case 56:
          s.evBitMod('flag', true, 187);
          pc = 57;
          continue;
        case 57:
          s.evBitMod('flag', true, 190);
          pc = 58;
          continue;
        case 58:
          s.evBitMod('flag', true, 191);
          pc = 59;
          continue;
        case 59:
          s.evBitMod('flag', true, 230);
          pc = 60;
          continue;
        case 60:
          s.evBitMod('flag', true, 205);
          pc = 61;
          continue;
        case 61:
          await s.changeChapter(6, subcmd: 1);
          pc = 62;
          continue;
        case 62:
          return;
        default:
          return;
      }
    }
}

/// `EventScr_Ch4_10`
Future<void> Ch4_10(Scene s) async {
    s.moveUnit('MOVE', [0, 19, 6, 3]);
    await s.waitUnitMoving();
    s.showCursorAtUnit(19);
    await s.stall(60);
    await s.endCursor();
    s.setTextType(0);
    await s.textShow(2410);
    await s.textEnd();
    s.textRemoveAll();
    s.showCursorAtUnit(1);
    await s.stall(60);
    await s.endCursor();
    s.setTextType(0);
    await s.textShow(2411);
    await s.textEnd();
    s.textRemoveAll();
    s.setTextType(3);
    s.setSlot(11, 4294967295);
    await s.textShow(2425);
    await s.textEnd();
    s.textRemoveAll();
    s.evBitMod('flag', true, 205);
    return;
}

/// `EventScr_Ch4_2`
Future<void> Ch4_2(Scene s) async {
    var pc = 0;
    while (true) {
      switch (pc) {
        case 0:
          s.sound('override', 48);
          pc = 1;
          continue;
        case 1:
          await s.stall(33);
          pc = 2;
          continue;
        case 2:
          s.checkSlotValue('activePid');
          pc = 3;
          continue;
        case 3:
          s.setSlot(7, 19);
          pc = 4;
          continue;
        case 4:
          if (s.slotInt(12) == s.slotInt(7)) { pc = 11; } else { pc = 5; }
          continue;
        case 5:
          s.setSlot(7, 1);
          pc = 6;
          continue;
        case 6:
          if (s.slotInt(12) == s.slotInt(7)) { pc = 16; } else { pc = 7; }
          continue;
        case 7:
          s.setSlot(2, 2);
          pc = 8;
          continue;
        case 8:
          s.setSlot(3, 2420);
          pc = 9;
          continue;
        case 9:
          await s.call(Sym('Event_TextWithBG'));
          pc = 10;
          continue;
        case 10:
          pc = 20;
          continue;
        case 11:
          pc = 12;
          continue;
        case 12:
          s.setSlot(2, 2);
          pc = 13;
          continue;
        case 13:
          s.setSlot(3, 2418);
          pc = 14;
          continue;
        case 14:
          await s.call(Sym('Event_TextWithBG'));
          pc = 15;
          continue;
        case 15:
          pc = 20;
          continue;
        case 16:
          pc = 17;
          continue;
        case 17:
          s.setSlot(2, 2);
          pc = 18;
          continue;
        case 18:
          s.setSlot(3, 2419);
          pc = 19;
          continue;
        case 19:
          await s.call(Sym('Event_TextWithBG'));
          pc = 20;
          continue;
        case 20:
          pc = 21;
          continue;
        case 21:
          s.restoreBgm(4);
          pc = 22;
          continue;
        case 22:
          s.loadUnits(1, Sym('UnitDef_Ch4Ally_2'));
          pc = 23;
          continue;
        case 23:
          await s.waitUnitMoving();
          pc = 24;
          continue;
        case 24:
          s.evBitMod('evbit', true, 7);
          pc = 25;
          continue;
        case 25:
          return;
        default:
          return;
      }
    }
}

/// `EventScr_Ch4_3`
Future<void> Ch4_3(Scene s) async {
    s.volumeDown(true);
    s.setSlot(2, 2);
    s.setSlot(3, 2421);
    await s.call(Sym('Event_TextWithBG'));
    s.volumeDown(false);
    await s.call(Sym('data_085B9BBC', 360));
    s.setSlot(3, 31);
    await s.giveItem(65535, 3);
    s.evBitMod('evbit', true, 7);
    return;
}

/// `EventScr_Ch4_4`
Future<void> Ch4_4(Scene s) async {
    s.setSlot(2, Sym('UnitDef_Ch4Enemy_2'));
    await s.call(Sym('EventScr_LoadReinforce'));
    s.evBitMod('evbit', true, 7);
    return;
}

/// `EventScr_Ch4_5`
Future<void> Ch4_5(Scene s) async {
    s.setSlot(2, 0);
    await s.call(Sym('UnitDef_Ch14BAlly_7'));
    s.evBitMod('flag', false, 8);
    s.evBitMod('evbit', true, 7);
    return;
}

/// `EventScr_Ch4_6`
Future<void> Ch4_6(Scene s) async {
    s.setSlot(2, Sym('UnitDef_Ch4Enemy_1'));
    await s.call(Sym('EventScr_LoadReinforce'));
    s.evBitMod('evbit', true, 7);
    return;
}

/// `EventScr_Ch4_BeginningScene`
Future<void> Ch4_BeginningScene(Scene s) async {
    s.loadUnits(2, Sym('UnitDef_Ch4Ally_0'));
    await s.waitUnitMoving();
    s.sound('bgm', 82);
    s.showCursorAtUnit(1);
    await s.stall(60);
    await s.endCursor();
    s.setSlot(2, 46);
    await s.call(Sym('EventScr_SetBackground'));
    await s.textShow(2403);
    await s.textEnd();
    s.textRemoveAll();
    await s.fade(FadeDirection.toBlack, 16);
    await s.clearScreen();
    s.loadUnits(1, Sym('UnitDef_Ch4Enemy_0'));
    await s.waitUnitMoving();
    await s.fade(FadeDirection.fromBlack, 16);
    s.sound('bgm', 37);
    s.showCursorAtUnit(1);
    await s.stall(60);
    await s.endCursor();
    s.setTextType(0);
    await s.textShow(2404);
    await s.textEnd();
    s.textRemoveAll();
    await s.fade(FadeDirection.toBlack, 16);
    await s.cameraTo(0, 14, centered: false);
    await s.fade(FadeDirection.fromBlack, 16);
    s.volumeDown(true);
    s.showCursorAt(1, 11);
    await s.stall(60);
    await s.endCursor();
    s.setSlot(2, 2);
    await s.call(Sym('EventScr_SetBackground'));
    await s.textShow(2405);
    await s.textEnd();
    s.textRemoveAll();
    s.volumeDown(false);
    s.setSlot(2, Sym('EventScr_Ch4_7'));
    await s.call(Sym('EventScr_CallOnTutorialMode'));
    await s.fade(FadeDirection.toBlack, 16);
    await s.clearScreen();
    await s.cameraTo(0, 0, centered: false);
    await s.fade(FadeDirection.fromBlack, 16);
    s.loadUnits(1, Sym('UnitDef_Ch4Ally_1'));
    await s.waitUnitMoving();
    s.showCursorAtUnit(19);
    await s.stall(60);
    await s.endCursor();
    s.setTextType(0);
    await s.textShow(2406);
    await s.textEnd();
    s.textRemoveAll();
    s.setSlot(11, 393227);
    s.moveUnit('MOVE', [0, 65534, 9, 3]);
    await s.waitUnitMoving();
    s.showCursorAtUnit(19);
    await s.stall(60);
    await s.endCursor();
    s.setTextType(0);
    await s.textShow(2407);
    await s.textEnd();
    s.textRemoveAll();
    s.setSlot(13, 0);
    s.setSlot(1, 0);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 65536);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 4294967295);
    s.slotQueuePushSlot(0x1);
    s.setSlot(11, 196617);
    s.placeholder('FIGHT');
    s.setSlot(11, 196617);
    s.placeholder('KILL');
    await s.removeUnit(65534, onlyIfDead: true);
    s.setSlot(2, Sym('EventScr_Ch4_8'));
    await s.call(Sym('EventScr_CallOnTutorialMode'));
    s.showCursorAtUnit(1);
    await s.stall(60);
    await s.endCursor();
    s.setTextType(0);
    await s.textShow(2408);
    await s.textEnd();
    s.textRemoveAll();
    s.setSlot(2, Sym('EventScr_Ch4_9'));
    await s.call(Sym('EventScr_CallOnTutorialMode'));
    await s.call(Sym('data_085B9BBC', 512));
    await s.cameraTo(0, 0, centered: false);
    await s.fade(FadeDirection.fromBlack, 16);
    s.sound('bgm', 9);
    s.showCursorAtUnit(19);
    await s.stall(60);
    await s.endCursor();
    s.setTextType(0);
    await s.textShow(2409);
    await s.textEnd();
    s.textRemoveAll();
    s.setSlot(2, Sym('EventScr_Ch4_10'));
    await s.call(Sym('EventScr_CallOnTutorialMode'));
    s.evBitMod('flag', true, 8);
    s.evBitMod('evbit', true, 7);
    return;
}

/// `EventScr_Ch5_0`
Future<void> Ch5_0(Scene s) async {
    s.volumeDown(true);
    s.setSlot(2, 0);
    s.setSlot(3, 2445);
    await s.call(Sym('Event_TextWithBG'));
    s.volumeDown(false);
    await s.call(Sym('data_085B9BBC', 360));
    s.setSlot(3, 14);
    await s.giveItem(65535, 3);
    s.setSlot(2, Sym('EventScr_Ch5_9'));
    await s.call(Sym('EventScr_CallOnTutorialMode'));
    s.evBitMod('evbit', true, 7);
    return;
}

/// `EventScr_Ch5_1`
Future<void> Ch5_1(Scene s) async {
    s.volumeDown(true);
    s.setSlot(2, 0);
    s.setSlot(3, 2446);
    await s.call(Sym('Event_TextWithBG'));
    s.volumeDown(false);
    await s.call(Sym('data_085B9BBC', 360));
    s.setSlot(3, 96);
    await s.giveItem(65535, 3);
    s.evBitMod('evbit', true, 7);
    return;
}

/// `EventScr_Ch5_10`
Future<void> Ch5_10(Scene s) async {
    s.setTextType(3);
    s.setSlot(11, 4294967295);
    await s.textShow(2451);
    await s.textEnd();
    s.textRemoveAll();
    await s.cameraTo(2, 1, centered: false);
    s.showCursorAt(2, 1, flashing: true);
    await s.stall(60);
    await s.cameraTo(6, 10, centered: false);
    s.showCursorAt(6, 10, flashing: true);
    await s.stall(60);
    s.setTextType(3);
    s.setSlot(11, 4294967295);
    await s.textShow(2452);
    await s.textEnd();
    s.textRemoveAll();
    s.evBitMod('flag', true, 204);
    await s.endCursor();
    return;
}

/// `EventScr_Ch5_11`
Future<void> Ch5_11(Scene s) async {
    s.setTextType(3);
    s.setSlot(11, 4294967295);
    await s.textShow(2453);
    await s.textEnd();
    s.textRemoveAll();
    await s.cameraTo(12, 6, centered: false);
    s.showCursorAt(12, 6, flashing: true);
    await s.stall(60);
    s.setTextType(3);
    s.setSlot(11, 4294967295);
    await s.textShow(2454);
    await s.textEnd();
    s.textRemoveAll();
    s.evBitMod('flag', true, 234);
    await s.endCursor();
    return;
}

/// `EventScr_Ch5_2`
Future<void> Ch5_2(Scene s) async {
    s.volumeDown(true);
    s.setSlot(2, 0);
    s.setSlot(3, 2447);
    await s.call(Sym('Event_TextWithBG'));
    s.volumeDown(false);
    await s.call(Sym('data_085B9BBC', 360));
    s.setSlot(3, 93);
    await s.giveItem(65535, 3);
    s.evBitMod('evbit', true, 7);
    return;
}

/// `EventScr_Ch5_3`
Future<void> Ch5_3(Scene s) async {
    s.volumeDown(true);
    s.setSlot(2, 0);
    s.setSlot(3, 2448);
    await s.call(Sym('Event_TextWithBG'));
    await s.call(Sym('data_085B9BBC', 360));
    s.setSlot(3, 112);
    await s.giveItem(65535, 3);
    s.volumeDown(false);
    s.evBitMod('evbit', true, 7);
    return;
}

/// `EventScr_Ch5_5`
Future<void> Ch5_5(Scene s) async {
    s.setSlot(2, Sym('EventScr_Ch5_10'));
    await s.call(Sym('EventScr_CallOnTutorialMode'));
    s.sound('bgm', 19);
    s.setSlot(2, Sym('frontier_df4_banim_b_074_909DE8'));
    await s.call(Sym('EventScr_LoadReinforce'));
    s.showCursorAt(14, 16);
    await s.stall(60);
    await s.endCursor();
    s.setTextType(0);
    await s.textShow(2437);
    await s.textEnd();
    s.textRemoveAll();
    s.evBitMod('evbit', true, 7);
    return;
}

/// `EventScr_Ch5_6`
Future<void> Ch5_6(Scene s) async {
    s.setSlot(2, Sym('frontier_df4_banim_b_074_909DE8', 60));
    await s.call(Sym('EventScr_LoadReinforce'));
    s.evBitMod('evbit', true, 7);
    return;
}

/// `EventScr_Ch5_7`
Future<void> Ch5_7(Scene s) async {
    s.setSlot(2, Sym('frontier_df4_banim_b_074_909DE8', 120));
    await s.call(Sym('EventScr_LoadReinforce'));
    s.evBitMod('evbit', true, 7);
    return;
}

/// `EventScr_Ch5_BeginningScene`
Future<void> Ch5_BeginningScene(Scene s) async {
    var pc = 0;
    while (true) {
      switch (pc) {
        case 0:
          s.checkSlot('flag', 136);
          pc = 1;
          continue;
        case 1:
          if (s.slotInt(12) == s.slotInt(0)) { pc = 3; } else { pc = 2; }
          continue;
        case 2:
          await s.call(Sym('EventScr_Ch8_10'));
          pc = 3;
          continue;
        case 3:
          pc = 4;
          continue;
        case 4:
          s.sound('bgm', 37);
          pc = 5;
          continue;
        case 5:
          s.placeholder('EvtSetLoadUnitNoREDA');
          pc = 6;
          continue;
        case 6:
          s.loadUnits(2, Sym('frontier_df4_banim_b_074_909DE8', 220));
          pc = 7;
          continue;
        case 7:
          await s.waitUnitMoving();
          pc = 8;
          continue;
        case 8:
          s.setSlot(2, 10);
          pc = 9;
          continue;
        case 9:
          s.setSlot(3, 2426);
          pc = 10;
          continue;
        case 10:
          await s.call(Sym('Event_TextWithBG'));
          pc = 11;
          continue;
        case 11:
          await s.removeUnit(32);
          pc = 12;
          continue;
        case 12:
          s.loadUnits(2, Sym('frontier_df4_banim_b_074_909DE8', 220));
          pc = 13;
          continue;
        case 13:
          await s.waitUnitMoving();
          pc = 14;
          continue;
        case 14:
          s.showCursorAtUnit(32);
          pc = 15;
          continue;
        case 15:
          await s.stall(60);
          pc = 16;
          continue;
        case 16:
          await s.endCursor();
          pc = 17;
          continue;
        case 17:
          s.setSlot(2, 10);
          pc = 18;
          continue;
        case 18:
          await s.call(Sym('EventScr_SetBackground'));
          pc = 19;
          continue;
        case 19:
          await s.textShow(2427);
          pc = 20;
          continue;
        case 20:
          await s.textEnd();
          pc = 21;
          continue;
        case 21:
          s.textRemoveAll();
          pc = 22;
          continue;
        case 22:
          await s.fade(FadeDirection.toBlack, 16);
          pc = 23;
          continue;
        case 23:
          s.hideFaction('blue');
          pc = 24;
          continue;
        case 24:
          s.hideFaction('red');
          pc = 25;
          continue;
        case 25:
          s.hideFaction('green');
          pc = 26;
          continue;
        case 26:
          await s.clearScreen();
          pc = 27;
          continue;
        case 27:
          s.sound('bgm', 46);
          pc = 28;
          continue;
        case 28:
          s.loadUnits(1, Sym('frontier_df4_banim_b_074_909DE8', 280));
          pc = 29;
          continue;
        case 29:
          await s.waitUnitMoving();
          pc = 30;
          continue;
        case 30:
          await s.fade(FadeDirection.fromBlack, 16);
          pc = 31;
          continue;
        case 31:
          s.showCursorAtUnit(105);
          pc = 32;
          continue;
        case 32:
          await s.stall(60);
          pc = 33;
          continue;
        case 33:
          await s.endCursor();
          pc = 34;
          continue;
        case 34:
          s.setSlot(2, 10);
          pc = 35;
          continue;
        case 35:
          s.setSlot(3, 2428);
          pc = 36;
          continue;
        case 36:
          await s.call(Sym('Event_TextWithBG'));
          pc = 37;
          continue;
        case 37:
          s.moveUnit('MOVE', [0, 74, 9, 4]);
          pc = 38;
          continue;
        case 38:
          await s.waitUnitMoving();
          pc = 39;
          continue;
        case 39:
          s.moveUnit('MOVE_1STEP', [16, 14, 3]);
          pc = 40;
          continue;
        case 40:
          await s.waitUnitMoving();
          pc = 41;
          continue;
        case 41:
          s.showCursorAtUnit(105);
          pc = 42;
          continue;
        case 42:
          await s.stall(60);
          pc = 43;
          continue;
        case 43:
          await s.endCursor();
          pc = 44;
          continue;
        case 44:
          s.setSlot(2, 10);
          pc = 45;
          continue;
        case 45:
          s.setSlot(3, 2429);
          pc = 46;
          continue;
        case 46:
          await s.call(Sym('Event_TextWithBG'));
          pc = 47;
          continue;
        case 47:
          s.setSlot(13, 0);
          pc = 48;
          continue;
        case 48:
          s.setSlot(1, 457);
          pc = 49;
          continue;
        case 49:
          s.slotQueuePushSlot(0x1);
          pc = 50;
          continue;
        case 50:
          s.setSlot(1, 0);
          pc = 51;
          continue;
        case 51:
          s.slotQueuePushSlot(0x1);
          pc = 52;
          continue;
        case 52:
          s.setSlot(1, 459);
          pc = 53;
          continue;
        case 53:
          s.slotQueuePushSlot(0x1);
          pc = 54;
          continue;
        case 54:
          s.setSlot(1, 0);
          pc = 55;
          continue;
        case 55:
          s.slotQueuePushSlot(0x1);
          pc = 56;
          continue;
        case 56:
          s.setSlot(1, 267);
          pc = 57;
          continue;
        case 57:
          s.slotQueuePushSlot(0x1);
          pc = 58;
          continue;
        case 58:
          s.setSlot(1, 0);
          pc = 59;
          continue;
        case 59:
          s.slotQueuePushSlot(0x1);
          pc = 60;
          continue;
        case 60:
          s.moveUnit('MOVE_DEFINED', [105]);
          pc = 61;
          continue;
        case 61:
          s.setSlot(13, 0);
          pc = 62;
          continue;
        case 62:
          s.setSlot(1, 456);
          pc = 63;
          continue;
        case 63:
          s.slotQueuePushSlot(0x1);
          pc = 64;
          continue;
        case 64:
          s.setSlot(1, 0);
          pc = 65;
          continue;
        case 65:
          s.slotQueuePushSlot(0x1);
          pc = 66;
          continue;
        case 66:
          s.setSlot(1, 459);
          pc = 67;
          continue;
        case 67:
          s.slotQueuePushSlot(0x1);
          pc = 68;
          continue;
        case 68:
          s.setSlot(1, 0);
          pc = 69;
          continue;
        case 69:
          s.slotQueuePushSlot(0x1);
          pc = 70;
          continue;
        case 70:
          s.setSlot(1, 267);
          pc = 71;
          continue;
        case 71:
          s.slotQueuePushSlot(0x1);
          pc = 72;
          continue;
        case 72:
          s.setSlot(1, 0);
          pc = 73;
          continue;
        case 73:
          s.slotQueuePushSlot(0x1);
          pc = 74;
          continue;
        case 74:
          s.moveUnit('MOVE_DEFINED', [14]);
          pc = 75;
          continue;
        case 75:
          await s.stall(30, cancellable: false);
          pc = 76;
          continue;
        case 76:
          await s.fade(FadeDirection.toBlack, 16);
          pc = 77;
          continue;
        case 77:
          s.placeholder('EvtBgmFadeIn');
          pc = 78;
          continue;
        case 78:
          await s.waitUnitMoving();
          pc = 79;
          continue;
        case 79:
          s.hideFaction('blue');
          pc = 80;
          continue;
        case 80:
          s.hideFaction('red');
          pc = 81;
          continue;
        case 81:
          s.hideFaction('green');
          pc = 82;
          continue;
        case 82:
          s.setSlot(2, 47);
          pc = 83;
          continue;
        case 83:
          await s.call(Sym('EventScr_SetBackground'));
          pc = 84;
          continue;
        case 84:
          s.sound('bgm', 36);
          pc = 85;
          continue;
        case 85:
          await s.textShow(2430);
          pc = 86;
          continue;
        case 86:
          await s.textEnd();
          pc = 87;
          continue;
        case 87:
          s.volumeDown(true);
          pc = 88;
          continue;
        case 88:
          await s.continueText();
          pc = 89;
          continue;
        case 89:
          await s.textEnd();
          pc = 90;
          continue;
        case 90:
          s.textRemoveAll();
          pc = 91;
          continue;
        case 91:
          s.volumeDown(false);
          pc = 92;
          continue;
        case 92:
          await s.textShow(2431);
          pc = 93;
          continue;
        case 93:
          await s.textEnd();
          pc = 94;
          continue;
        case 94:
          s.placeholder('EvtBgmFadeIn');
          pc = 95;
          continue;
        case 95:
          s.placeholder('STAL3');
          pc = 96;
          continue;
        case 96:
          await s.continueText();
          pc = 97;
          continue;
        case 97:
          await s.textEnd();
          pc = 98;
          continue;
        case 98:
          s.textRemoveAll();
          pc = 99;
          continue;
        case 99:
          await s.call(Sym('EventScr_TextShowWithFadeIn'));
          pc = 100;
          continue;
        case 100:
          s.loadUnits(1, Sym('frontier_df4_banim_b_074_909DE8', 360));
          pc = 101;
          continue;
        case 101:
          await s.waitUnitMoving();
          pc = 102;
          continue;
        case 102:
          s.loadUnits(1, Sym('UnitDef_Ch5Enemy_0'));
          pc = 103;
          continue;
        case 103:
          await s.waitUnitMoving();
          pc = 104;
          continue;
        case 104:
          s.sound('bgm', 38);
          pc = 105;
          continue;
        case 105:
          s.setTextType(0);
          pc = 106;
          continue;
        case 106:
          await s.textShow(2432);
          pc = 107;
          continue;
        case 107:
          await s.textEnd();
          pc = 108;
          continue;
        case 108:
          s.textRemoveAll();
          pc = 109;
          continue;
        case 109:
          s.loadUnits(1, Sym('UnitDef_Ch5Enemy_1'));
          pc = 110;
          continue;
        case 110:
          await s.waitUnitMoving();
          pc = 111;
          continue;
        case 111:
          await s.waitUnitMoving();
          pc = 112;
          continue;
        case 112:
          await s.cameraTo(7, 14, centered: true);
          pc = 113;
          continue;
        case 113:
          s.loadUnits(2, Sym('frontier_df4_banim_b_074_909DE8', 400));
          pc = 114;
          continue;
        case 114:
          await s.waitUnitMoving();
          pc = 115;
          continue;
        case 115:
          s.showCursorAtUnit(2);
          pc = 116;
          continue;
        case 116:
          await s.stall(60);
          pc = 117;
          continue;
        case 117:
          await s.endCursor();
          pc = 118;
          continue;
        case 118:
          s.setTextType(0);
          pc = 119;
          continue;
        case 119:
          await s.textShow(2433);
          pc = 120;
          continue;
        case 120:
          await s.textEnd();
          pc = 121;
          continue;
        case 121:
          s.textRemoveAll();
          pc = 122;
          continue;
        case 122:
          s.moveUnit('MOVE', [0, 13, 6, 15]);
          pc = 123;
          continue;
        case 123:
          await s.waitUnitMoving();
          pc = 124;
          continue;
        case 124:
          s.showCursorAtUnit(1);
          pc = 125;
          continue;
        case 125:
          await s.stall(60);
          pc = 126;
          continue;
        case 126:
          await s.endCursor();
          pc = 127;
          continue;
        case 127:
          s.setTextType(0);
          pc = 128;
          continue;
        case 128:
          await s.textShow(2434);
          pc = 129;
          continue;
        case 129:
          await s.textEnd();
          pc = 130;
          continue;
        case 130:
          s.textRemoveAll();
          pc = 131;
          continue;
        case 131:
          await s.fade(FadeDirection.toBlack, 16);
          pc = 132;
          continue;
        case 132:
          s.placeholder('EvtBgmFadeIn');
          pc = 133;
          continue;
        case 133:
          s.loadUnits(1, Sym('UnitDef_Event_Ch4Ally'));
          pc = 134;
          continue;
        case 134:
          await s.waitUnitMoving();
          pc = 135;
          continue;
        case 135:
          await s.call(Sym('data_085B9BBC', 512));
          pc = 136;
          continue;
        case 136:
          await s.fade(FadeDirection.fromBlack, 16);
          pc = 137;
          continue;
        case 137:
          await s.cameraTo(0, 0, centered: false);
          pc = 138;
          continue;
        case 138:
          s.sound('bgm', 19);
          pc = 139;
          continue;
        case 139:
          s.showCursorAt(12, 6);
          pc = 140;
          continue;
        case 140:
          await s.stall(60);
          pc = 141;
          continue;
        case 141:
          await s.endCursor();
          pc = 142;
          continue;
        case 142:
          s.loadUnits(1, Sym('frontier_df4_banim_b_074_909DE8', 180));
          pc = 143;
          continue;
        case 143:
          await s.waitUnitMoving();
          pc = 144;
          continue;
        case 144:
          s.moveUnit('MOVE', [0, 32, 9, 7]);
          pc = 145;
          continue;
        case 145:
          await s.waitUnitMoving();
          pc = 146;
          continue;
        case 146:
          s.showCursorAtUnit(32);
          pc = 147;
          continue;
        case 147:
          await s.stall(60);
          pc = 148;
          continue;
        case 148:
          await s.endCursor();
          pc = 149;
          continue;
        case 149:
          s.setTextType(0);
          pc = 150;
          continue;
        case 150:
          await s.textShow(2435);
          pc = 151;
          continue;
        case 151:
          await s.textEnd();
          pc = 152;
          continue;
        case 152:
          s.textRemoveAll();
          pc = 153;
          continue;
        case 153:
          s.setSlot(2, Sym('EventScr_Ch5_11'));
          pc = 154;
          continue;
        case 154:
          await s.call(Sym('EventScr_CallOnTutorialMode'));
          pc = 155;
          continue;
        case 155:
          await s.cameraTo(5, 18, centered: false);
          pc = 156;
          continue;
        case 156:
          s.sound('bgm', 9);
          pc = 157;
          continue;
        case 157:
          s.showCursorAtUnit(13);
          pc = 158;
          continue;
        case 158:
          await s.stall(60);
          pc = 159;
          continue;
        case 159:
          await s.endCursor();
          pc = 160;
          continue;
        case 160:
          s.setTextType(0);
          pc = 161;
          continue;
        case 161:
          await s.textShow(2436);
          pc = 162;
          continue;
        case 162:
          await s.textEnd();
          pc = 163;
          continue;
        case 163:
          s.textRemoveAll();
          pc = 164;
          continue;
        case 164:
          s.setSlot(2, Sym('EventScr_Ch5_8'));
          pc = 165;
          continue;
        case 165:
          await s.call(Sym('EventScr_CallOnTutorialMode'));
          pc = 166;
          continue;
        case 166:
          s.evBitMod('evbit', true, 7);
          pc = 167;
          continue;
        case 167:
          return;
        default:
          return;
      }
    }
}

/// `EventScr_Ch5_EndingScene`
Future<void> Ch5_EndingScene(Scene s) async {
    var pc = 0;
    while (true) {
      switch (pc) {
        case 0:
          await s.fade(FadeDirection.toBlack, 16);
          pc = 1;
          continue;
        case 1:
          s.setSlot(2, 32);
          pc = 2;
          continue;
        case 2:
          await s.call(Sym('EventScr_StrictLoadUniqueAlly'));
          pc = 3;
          continue;
        case 3:
          s.setSlot(2, 10);
          pc = 4;
          continue;
        case 4:
          await s.call(Sym('EventScr_SetBackground'));
          pc = 5;
          continue;
        case 5:
          s.checkSlot('alive', 13);
          pc = 6;
          continue;
        case 6:
          if (s.slotInt(12) == s.slotInt(0)) { pc = 11; } else { pc = 7; }
          continue;
        case 7:
          s.sound('bgm', 49);
          pc = 8;
          continue;
        case 8:
          await s.textShow(2441);
          pc = 9;
          continue;
        case 9:
          await s.textEnd();
          pc = 10;
          continue;
        case 10:
          pc = 15;
          continue;
        case 11:
          pc = 12;
          continue;
        case 12:
          s.sound('bgm', 50);
          pc = 13;
          continue;
        case 13:
          await s.textShow(2442);
          pc = 14;
          continue;
        case 14:
          await s.textEnd();
          pc = 15;
          continue;
        case 15:
          pc = 16;
          continue;
        case 16:
          s.textRemoveAll();
          pc = 17;
          continue;
        case 17:
          s.checkSlot('flag', 8);
          pc = 18;
          continue;
        case 18:
          if (s.slotInt(12) == s.slotInt(0)) { pc = 33; } else { pc = 19; }
          continue;
        case 19:
          s.checkSlot('flag', 9);
          pc = 20;
          continue;
        case 20:
          if (s.slotInt(12) == s.slotInt(0)) { pc = 33; } else { pc = 21; }
          continue;
        case 21:
          s.checkSlot('flag', 10);
          pc = 22;
          continue;
        case 22:
          if (s.slotInt(12) == s.slotInt(0)) { pc = 33; } else { pc = 23; }
          continue;
        case 23:
          s.checkSlot('flag', 11);
          pc = 24;
          continue;
        case 24:
          if (s.slotInt(12) == s.slotInt(0)) { pc = 33; } else { pc = 25; }
          continue;
        case 25:
          s.setSlot(2, 10);
          pc = 26;
          continue;
        case 26:
          await s.call(Sym('EventScr_SetBackground'));
          pc = 27;
          continue;
        case 27:
          await s.textShow(2443);
          pc = 28;
          continue;
        case 28:
          await s.textEnd();
          pc = 29;
          continue;
        case 29:
          s.textRemoveAll();
          pc = 30;
          continue;
        case 30:
          await s.call(Sym('data_085B9BBC', 360));
          pc = 31;
          continue;
        case 31:
          s.setSlot(3, 104);
          pc = 32;
          continue;
        case 32:
          await s.giveItem(0, 3);
          pc = 33;
          continue;
        case 33:
          pc = 34;
          continue;
        case 34:
          s.evBitMod('flag', true, 219);
          pc = 35;
          continue;
        case 35:
          s.evBitMod('flag', true, 189);
          pc = 36;
          continue;
        case 36:
          s.evBitMod('flag', true, 187);
          pc = 37;
          continue;
        case 37:
          s.evBitMod('flag', true, 204);
          pc = 38;
          continue;
        case 38:
          s.evBitMod('flag', true, 234);
          pc = 39;
          continue;
        case 39:
          await s.changeChapter(5, subcmd: 2);
          pc = 40;
          continue;
        case 40:
          s.placeholder('EVENT_WORD');
          pc = 41;
          continue;
        case 41:
          s.placeholder('EVENT_WORD');
          pc = 42;
          continue;
        case 42:
          return;
        default:
          return;
      }
    }
}

/// `EventScr_Ch5x_BeginningScene`
Future<void> Ch5x_BeginningScene(Scene s) async {
    s.placeholder('ASMC');
    s.sound('bgm', 46);
    s.setSlot(11, 262154);
    await s.loadMap(8);
    await s.fade(FadeDirection.fromBlack, 16);
    await s.popupText(1513, 8, 8);
    s.showCursorAt(9, 4);
    await s.stall(60);
    await s.endCursor();
    await s.fade(FadeDirection.toBlack, 16);
    s.setSlot(11, 262155);
    await s.loadMap(9);
    s.loadUnits(1, Sym('UnitDef_Ch5xEnemy_1'));
    await s.waitUnitMoving();
    await s.fade(FadeDirection.fromBlack, 16);
    s.placeholder('SPAWN_ENEMY');
    s.moveUnit('MOVE', [16, 67, 10, 4]);
    await s.waitUnitMoving();
    s.moveUnit('MOVE', [16, 77, 9, 3]);
    await s.waitUnitMoving();
    s.moveUnit('MOVE', [16, 67, 10, 2]);
    await s.waitUnitMoving();
    s.moveUnit('MOVE', [16, 77, 10, 3]);
    await s.waitUnitMoving();
    s.showCursorAtUnit(77);
    await s.stall(60);
    await s.endCursor();
    s.setTextType(0);
    await s.textShow(2455);
    await s.textEnd();
    s.textRemoveAll();
    await s.fade(FadeDirection.toBlack, 16);
    s.placeholder('EvtBgmFadeIn');
    s.hideFaction('blue');
    s.hideFaction('red');
    s.hideFaction('green');
    s.setSlot(11, 786452);
    await s.loadMap(7);
    s.loadUnits(2, Sym('UnitDef_Ch5xAlly_1'));
    await s.waitUnitMoving();
    await s.fade(FadeDirection.fromBlack, 16);
    s.showCursorAtUnit(15);
    await s.stall(60);
    await s.endCursor();
    s.setSlot(2, 45);
    await s.call(Sym('EventScr_SetBackground'));
    s.sound('bgm', 37);
    await s.textShow(2456);
    await s.textEnd();
    s.textRemoveAll();
    await s.fade(FadeDirection.toBlack, 16);
    s.hideFaction('blue');
    s.hideFaction('red');
    s.hideFaction('green');
    s.setSlot(11, 458761);
    await s.loadMap(8);
    await s.fade(FadeDirection.fromBlack, 16);
    s.loadUnits(2, Sym('UnitDef_Ch5xAlly_2'));
    await s.waitUnitMoving();
    s.showCursorAtUnit(15);
    await s.stall(60);
    await s.endCursor();
    s.setSlot(2, 44);
    s.setSlot(3, 2457);
    await s.call(Sym('Event_TextWithBG'));
    s.moveUnit('MOVE', [0, 15, 9, 4]);
    await s.stall(8, cancellable: false);
    s.moveUnit('MOVE', [0, 16, 9, 5]);
    s.moveUnit('MOVE', [0, 17, 8, 5]);
    s.moveUnit('MOVE', [0, 66, 8, 6]);
    await s.stall(8, cancellable: false);
    await s.fade(FadeDirection.toBlack, 16);
    await s.waitUnitMoving();
    s.hideFaction('blue');
    s.hideFaction('red');
    s.hideFaction('green');
    s.setSlot(11, 458766);
    await s.loadMap(5);
    s.loadUnits(1, Sym('frontier_df4_banim_b_075_90A050'));
    await s.waitUnitMoving();
    await s.fade(FadeDirection.fromBlack, 16);
    s.showCursorAtUnit(106);
    await s.stall(60);
    await s.endCursor();
    await s.textShow(2458);
    await s.textEnd();
    s.textRemoveAll();
    await s.cameraTo(0, 18, centered: false);
    s.loadUnits(1, Sym('UnitDef_Event_Ch5xAlly'));
    await s.waitUnitMoving();
    s.showCursorAtUnit(15);
    await s.stall(60);
    await s.endCursor();
    s.setSlot(2, 21);
    await s.call(Sym('EventScr_SetBackground'));
    await s.textShow(2459);
    await s.textEnd();
    s.textRemoveAll();
    s.placeholder('EvtBgmFadeIn');
    return;
}

/// `EventScr_Ch5x_EndingScene`
Future<void> Ch5x_EndingScene(Scene s) async {
    s.placeholder('ASMC');
    s.sound('bgm', 49);
    s.setSlot(2, 21);
    await s.call(Sym('EventScr_SetBackground'));
    await s.textShow(2465);
    await s.textEnd();
    s.textRemoveAll();
    await s.fade(FadeDirection.toBlack, 16);
    s.placeholder('EvtBgmFadeIn');
    s.hideFaction('blue');
    s.hideFaction('red');
    s.hideFaction('green');
    await s.clearScreen();
    await s.cameraTo(13, 9, centered: true);
    s.placeholder('EvtSetLoadUnitNoREDA');
    s.loadUnits(2, Sym('UnitDef_Ch5xAlly_0'));
    await s.waitUnitMoving();
    await s.fade(FadeDirection.fromBlack, 16);
    s.loadUnits(1, Sym('UnitDef_Ch5xAlly_0'));
    await s.waitUnitMoving();
    s.showCursorAtUnit(16);
    await s.stall(60);
    await s.endCursor();
    s.setTextType(0);
    await s.textShow(2466);
    await s.textEnd();
    s.textRemoveAll();
    await s.fade(FadeDirection.toBlack, 16);
    s.hideFaction('blue');
    s.hideFaction('red');
    s.hideFaction('green');
    s.setSlot(11, 262154);
    await s.loadMap(8);
    s.loadUnits(1, Sym('UnitDef_Ch5xEnemy_2'));
    await s.waitUnitMoving();
    await s.fade(FadeDirection.fromBlack, 16);
    s.evBitMod('evbit', true, 9);
    s.loadUnits(2, Sym('UnitDef_Ch5xAlly_3'));
    await s.waitUnitMoving();
    s.evBitMod('evbit', false, 9);
    s.sound('bgm', 38);
    s.loadUnits(1, Sym('UnitDef_Ch5xEnemy_3'));
    await s.waitUnitMoving();
    s.loadUnits(1, Sym('UnitDef_Ch5xEnemy_4'));
    await s.waitUnitMoving();
    s.showCursorAtUnit(67);
    await s.stall(60);
    await s.endCursor();
    s.setSlot(2, 44);
    await s.call(Sym('EventScr_SetBackground'));
    await s.textShow(2467);
    await s.textEnd();
    s.textRemoveAll();
    await s.fade(FadeDirection.toBlack, 16);
    s.placeholder('EvtBgmFadeIn');
    s.placeholder('EVENT_WORD');
    s.placeholder('EVENT_WORD');
    await s.changeChapter(7, subcmd: 1);
    return;
}

/// `EventScr_Ch6_0`
Future<void> Ch6_0(Scene s) async {
    var pc = 0;
    while (true) {
      switch (pc) {
        case 0:
          s.checkSlot('alive', 249);
          pc = 1;
          continue;
        case 1:
          if (s.slotInt(12) == s.slotInt(0)) { pc = 31; } else { pc = 2; }
          continue;
        case 2:
          s.placeholder('CHECK_INAREA');
          pc = 3;
          continue;
        case 3:
          if (s.slotInt(12) == s.slotInt(0)) { pc = 29; } else { pc = 4; }
          continue;
        case 4:
          s.setSlot(2, 176);
          pc = 5;
          continue;
        case 5:
          await s.call(Sym('EventScr_UnTriggerIfNotUnit'));
          pc = 6;
          continue;
        case 6:
          s.sound('bgm', 24);
          pc = 7;
          continue;
        case 7:
          s.cameraToChar(249);
          pc = 8;
          continue;
        case 8:
          s.showCursorAtUnit(249);
          pc = 9;
          continue;
        case 9:
          await s.stall(60);
          pc = 10;
          continue;
        case 10:
          await s.endCursor();
          pc = 11;
          continue;
        case 11:
          s.placeholder('RANDOMNUMBER');
          pc = 12;
          continue;
        case 12:
          s.setSlot(7, 1);
          pc = 13;
          continue;
        case 13:
          if (s.slotInt(12) == s.slotInt(7)) { pc = 19; } else { pc = 14; }
          continue;
        case 14:
          s.setSlot(7, 2);
          pc = 15;
          continue;
        case 15:
          if (s.slotInt(12) == s.slotInt(7)) { pc = 22; } else { pc = 16; }
          continue;
        case 16:
          pc = 17;
          continue;
        case 17:
          s.setSlot(2, 2476);
          pc = 18;
          continue;
        case 18:
          pc = 24;
          continue;
        case 19:
          pc = 20;
          continue;
        case 20:
          s.setSlot(2, 2477);
          pc = 21;
          continue;
        case 21:
          pc = 24;
          continue;
        case 22:
          pc = 23;
          continue;
        case 23:
          s.setSlot(2, 2478);
          pc = 24;
          continue;
        case 24:
          pc = 25;
          continue;
        case 25:
          s.setTextType(0);
          pc = 26;
          continue;
        case 26:
          await s.textShow(65535);
          pc = 27;
          continue;
        case 27:
          await s.textEnd();
          pc = 28;
          continue;
        case 28:
          s.textRemoveAll();
          pc = 29;
          continue;
        case 29:
          pc = 30;
          continue;
        case 30:
          await s.call(Sym('UnitDef_Ch14BAlly_7', 28));
          pc = 31;
          continue;
        case 31:
          pc = 32;
          continue;
        case 32:
          s.evBitMod('evbit', true, 7);
          pc = 33;
          continue;
        case 33:
          return;
        default:
          return;
      }
    }
}

/// `EventScr_Ch6_1`
Future<void> Ch6_1(Scene s) async {
    s.volumeDown(true);
    s.setSlot(2, 0);
    s.setSlot(3, 2484);
    await s.call(Sym('Event_TextWithBG'));
    s.volumeDown(false);
    await s.call(Sym('data_085B9BBC', 360));
    s.setSlot(3, 111);
    await s.giveItem(65535, 3);
    s.setSlot(2, Sym('EventScr_Ch6_3'));
    await s.call(Sym('EventScr_CallOnTutorialMode'));
    s.evBitMod('evbit', true, 7);
    return;
}

/// `EventScr_Ch6_2`
Future<void> Ch6_2(Scene s) async {
    var pc = 0;
    while (true) {
      switch (pc) {
        case 0:
          await s.clearScreen();
          pc = 1;
          continue;
        case 1:
          await s.cameraTo(7, 8, centered: true);
          pc = 2;
          continue;
        case 2:
          await s.fade(FadeDirection.fromBlack, 16);
          pc = 3;
          continue;
        case 3:
          s.sound('bgm', 17);
          pc = 4;
          continue;
        case 4:
          s.showCursorAtUnit(1);
          pc = 5;
          continue;
        case 5:
          await s.stall(60);
          pc = 6;
          continue;
        case 6:
          await s.endCursor();
          pc = 7;
          continue;
        case 7:
          s.setSlot(2, 34);
          pc = 8;
          continue;
        case 8:
          await s.call(Sym('EventScr_SetBackground'));
          pc = 9;
          continue;
        case 9:
          await s.textShow(2474);
          pc = 10;
          continue;
        case 10:
          await s.textEnd();
          pc = 11;
          continue;
        case 11:
          s.checkSlot('alive', 9);
          pc = 12;
          continue;
        case 12:
          if (s.slotInt(12) == s.slotInt(0)) { pc = 15; } else { pc = 13; }
          continue;
        case 13:
          s.placeholder('EvtTextShow2');
          pc = 14;
          continue;
        case 14:
          await s.textEnd();
          pc = 15;
          continue;
        case 15:
          pc = 16;
          continue;
        case 16:
          s.textRemoveAll();
          pc = 17;
          continue;
        case 17:
          s.setTextType(3);
          pc = 18;
          continue;
        case 18:
          s.setSlot(11, 4294967295);
          pc = 19;
          continue;
        case 19:
          await s.textShow(2485);
          pc = 20;
          continue;
        case 20:
          await s.textEnd();
          pc = 21;
          continue;
        case 21:
          s.textRemoveAll();
          pc = 22;
          continue;
        case 22:
          s.evBitMod('flag', true, 212);
          pc = 23;
          continue;
        case 23:
          return;
        default:
          return;
      }
    }
}

/// `EventScr_Ch6_3`
Future<void> Ch6_3(Scene s) async {
    s.setTextType(3);
    s.setSlot(11, 4294967295);
    await s.textShow(2486);
    await s.textEnd();
    s.textRemoveAll();
    s.evBitMod('flag', true, 193);
    return;
}

/// `EventScr_Ch6_4`
Future<void> Ch6_4(Scene s) async {
    s.setSlot(2, Sym('UnitDef_Ch6Enemy_0'));
    await s.call(Sym('EventScr_LoadReinforceHardMode'));
    s.evBitMod('evbit', true, 7);
    return;
}

/// `EventScr_Ch6_BeginningScene`
Future<void> Ch6_BeginningScene(Scene s) async {
    s.sound('bgm', 46);
    s.setSlot(2, 34);
    await s.call(Sym('EventScr_SetBackground'));
    await s.textShow(2468);
    await s.textEnd();
    s.textRemoveAll();
    s.placeholder('EvtBgmFadeIn');
    await s.call(Sym('EventScr_TextShowWithFadeIn'));
    s.evBitMod('evbit', true, 9);
    s.loadUnits(2, Sym('UnitDef_Ch6Ally_0'));
    await s.waitUnitMoving();
    s.evBitMod('evbit', false, 9);
    await s.cameraTo(7, 7, centered: true);
    s.loadUnits(1, Sym('UnitDef_Ch6Mixed'));
    await s.waitUnitMoving();
    s.setSlot(2, 75);
    s.moveUnit('MOVE_CLOSEST', [65535, 65533, 5, 8]);
    await s.call(Sym('EventScr_UnitWarpIN'));
    s.setSlot(2, 249);
    s.moveUnit('MOVE_CLOSEST', [65535, 65533, 6, 8]);
    await s.call(Sym('EventScr_UnitWarpIN'));
    s.moveUnit('MOVE_1STEP', [0, 1, 0]);
    s.moveUnit('MOVE_1STEP', [0, 2, 0]);
    await s.waitUnitMoving();
    s.showCursorAtUnit(75);
    await s.stall(60);
    await s.endCursor();
    s.setSlot(2, 34);
    await s.call(Sym('EventScr_SetBackground'));
    await s.textShow(2469);
    await s.textEnd();
    s.sound('bgm', 38);
    await s.continueText();
    await s.textEnd();
    s.textRemoveAll();
    s.setSlot(2, 34);
    await s.call(Sym('EventScr_SetBackground'));
    await s.textShow(2470);
    await s.textEnd();
    s.textRemoveAll();
    s.setSlot(2, 34);
    await s.call(Sym('EventScr_SetBackground'));
    await s.textShow(2471);
    await s.textEnd();
    s.textRemoveAll();
    await s.call(Sym('EventScr_TextShowWithFadeIn'));
    s.moveUnit('MOVE', [65535, 251, 20, 5]);
    s.setSlot(2, 75);
    await s.call(Sym('EventScr_UnitWarpOUT'));
    s.setSlot(2, 249);
    await s.call(Sym('EventScr_UnitWarpOUT'));
    await s.cameraTo(19, 5, centered: true);
    s.setSlot(2, 75);
    s.moveUnit('MOVE_CLOSEST', [65535, 65533, 19, 6]);
    await s.call(Sym('EventScr_UnitWarpIN'));
    s.setSlot(2, 249);
    s.moveUnit('MOVE_CLOSEST', [65535, 65533, 20, 6]);
    await s.call(Sym('EventScr_UnitWarpIN'));
    s.showCursorAtUnit(75);
    await s.stall(60);
    await s.endCursor();
    s.setSlot(2, 39);
    s.setSlot(3, 2472);
    await s.call(Sym('Event_TextWithBG'));
    await s.stall(60);
    s.setSlot(2, 249);
    await s.call(Sym('EventScr_UnitWarpOUT'));
    s.setSlot(2, 251);
    await s.call(Sym('EventScr_UnitWarpOUT'));
    await s.cameraTo(21, 11, centered: true);
    s.setSlot(2, 249);
    s.moveUnit('MOVE_CLOSEST', [65535, 65533, 26, 12]);
    await s.call(Sym('EventScr_UnitWarpIN'));
    s.setSlot(2, 251);
    s.moveUnit('MOVE_CLOSEST', [65535, 65533, 25, 12]);
    await s.call(Sym('EventScr_UnitWarpIN'));
    s.showCursorAtUnit(249);
    await s.stall(60);
    await s.endCursor();
    s.setSlot(2, 39);
    await s.call(Sym('EventScr_SetBackground'));
    await s.textShow(2473);
    await s.textEnd();
    s.textRemoveAll();
    await s.fade(FadeDirection.toBlack, 16);
    s.setSlot(2, Sym('EventScr_Ch6_2'));
    await s.call(Sym('EventScr_CallOnTutorialMode'));
    await s.call(Sym('data_085B9BBC', 512));
    return;
}

/// `EventScr_Ch6_EndingScene`
Future<void> Ch6_EndingScene(Scene s) async {
    var pc = 0;
    while (true) {
      switch (pc) {
        case 0:
          s.placeholder('EvtBgmFadeIn');
          pc = 1;
          continue;
        case 1:
          s.setSlot(2, 34);
          pc = 2;
          continue;
        case 2:
          await s.call(Sym('EventScr_SetBackground'));
          pc = 3;
          continue;
        case 3:
          s.checkSlot('alive', 250);
          pc = 4;
          continue;
        case 4:
          if (s.slotInt(12) == s.slotInt(0)) { pc = 17; } else { pc = 5; }
          continue;
        case 5:
          s.checkSlot('alive', 251);
          pc = 6;
          continue;
        case 6:
          if (s.slotInt(12) == s.slotInt(0)) { pc = 17; } else { pc = 7; }
          continue;
        case 7:
          s.checkSlot('alive', 249);
          pc = 8;
          continue;
        case 8:
          if (s.slotInt(12) == s.slotInt(0)) { pc = 17; } else { pc = 9; }
          continue;
        case 9:
          s.sound('bgm', 49);
          pc = 10;
          continue;
        case 10:
          await s.textShow(2482);
          pc = 11;
          continue;
        case 11:
          await s.textEnd();
          pc = 12;
          continue;
        case 12:
          s.textRemoveAll();
          pc = 13;
          continue;
        case 13:
          s.placeholder('EvtBgmFadeIn');
          pc = 14;
          continue;
        case 14:
          await s.call(Sym('data_085B9BBC', 360));
          pc = 15;
          continue;
        case 15:
          s.setSlot(3, 102);
          pc = 16;
          continue;
        case 16:
          await s.giveItem(1, 3);
          pc = 17;
          continue;
        case 17:
          pc = 18;
          continue;
        case 18:
          s.textRemoveAll();
          pc = 19;
          continue;
        case 19:
          s.sound('bgm', 43);
          pc = 20;
          continue;
        case 20:
          await s.textShow(2483);
          pc = 21;
          continue;
        case 21:
          await s.textEnd();
          pc = 22;
          continue;
        case 22:
          s.placeholder('EvtBgmFadeIn');
          pc = 23;
          continue;
        case 23:
          await s.stall(60);
          pc = 24;
          continue;
        case 24:
          s.placeholder('EvtBgmFadeIn');
          pc = 25;
          continue;
        case 25:
          await s.continueText();
          pc = 26;
          continue;
        case 26:
          await s.textEnd();
          pc = 27;
          continue;
        case 27:
          s.textRemoveAll();
          pc = 28;
          continue;
        case 28:
          s.evBitMod('flag', true, 212);
          pc = 29;
          continue;
        case 29:
          s.evBitMod('flag', true, 193);
          pc = 30;
          continue;
        case 30:
          await s.changeChapter(8, subcmd: 1);
          pc = 31;
          continue;
        case 31:
          return;
        default:
          return;
      }
    }
}

/// `EventScr_Ch7_1`
Future<void> Ch7_1(Scene s) async {
    s.volumeDown(true);
    s.setSlot(2, 0);
    s.setSlot(3, 2503);
    await s.call(Sym('Event_TextWithBG'));
    s.volumeDown(false);
    s.evBitMod('evbit', true, 7);
    return;
}

/// `EventScr_Ch7_2`
Future<void> Ch7_2(Scene s) async {
    s.volumeDown(true);
    s.setSlot(2, 0);
    s.setSlot(3, 2504);
    await s.call(Sym('Event_TextWithBG'));
    s.volumeDown(false);
    s.evBitMod('evbit', true, 7);
    return;
}

/// `EventScr_Ch7_BeginningScene`
Future<void> Ch7_BeginningScene(Scene s) async {
    var pc = 0;
    while (true) {
      switch (pc) {
        case 0:
          s.sound('bgm', 37);
          pc = 1;
          continue;
        case 1:
          s.loadUnits(1, Sym('frontier_df4_banim_b_076_90B4DC'));
          pc = 2;
          continue;
        case 2:
          await s.waitUnitMoving();
          pc = 3;
          continue;
        case 3:
          await s.fade(FadeDirection.fromBlack, 16);
          pc = 4;
          continue;
        case 4:
          s.loadUnits(3, Sym('UnitDef_Event_Ch7Ally'));
          pc = 5;
          continue;
        case 5:
          await s.waitUnitMoving();
          pc = 6;
          continue;
        case 6:
          await s.stall(15);
          pc = 7;
          continue;
        case 7:
          await s.cameraTo(9, 4, centered: true);
          pc = 8;
          continue;
        case 8:
          s.showCursorAt(9, 4);
          pc = 9;
          continue;
        case 9:
          await s.stall(60);
          pc = 10;
          continue;
        case 10:
          await s.endCursor();
          pc = 11;
          continue;
        case 11:
          await s.cameraTo(0, 21, centered: false);
          pc = 12;
          continue;
        case 12:
          s.showCursorAtUnit(1);
          pc = 13;
          continue;
        case 13:
          await s.stall(60);
          pc = 14;
          continue;
        case 14:
          await s.endCursor();
          pc = 15;
          continue;
        case 15:
          s.setSlot(2, 44);
          pc = 16;
          continue;
        case 16:
          await s.call(Sym('EventScr_SetBackground'));
          pc = 17;
          continue;
        case 17:
          await s.textShow(2487);
          pc = 18;
          continue;
        case 18:
          await s.textEnd();
          pc = 19;
          continue;
        case 19:
          s.checkSlot('alive', 4);
          pc = 20;
          continue;
        case 20:
          if (s.slotInt(12) == s.slotInt(0)) { pc = 23; } else { pc = 21; }
          continue;
        case 21:
          s.placeholder('EvtTextShow2');
          pc = 22;
          continue;
        case 22:
          await s.textEnd();
          pc = 23;
          continue;
        case 23:
          pc = 24;
          continue;
        case 24:
          s.checkSlot('alive', 3);
          pc = 25;
          continue;
        case 25:
          if (s.slotInt(12) == s.slotInt(0)) { pc = 32; } else { pc = 26; }
          continue;
        case 26:
          s.checkSlot('alive', 5);
          pc = 27;
          continue;
        case 27:
          if (s.slotInt(12) == s.slotInt(0)) { pc = 32; } else { pc = 28; }
          continue;
        case 28:
          s.checkSlot('alive', 6);
          pc = 29;
          continue;
        case 29:
          if (s.slotInt(12) == s.slotInt(0)) { pc = 32; } else { pc = 30; }
          continue;
        case 30:
          s.placeholder('EvtTextShow2');
          pc = 31;
          continue;
        case 31:
          await s.textEnd();
          pc = 32;
          continue;
        case 32:
          pc = 33;
          continue;
        case 33:
          s.checkSlot('alive', 7);
          pc = 34;
          continue;
        case 34:
          if (s.slotInt(12) == s.slotInt(0)) { pc = 39; } else { pc = 35; }
          continue;
        case 35:
          s.checkSlot('alive', 10);
          pc = 36;
          continue;
        case 36:
          if (s.slotInt(12) == s.slotInt(0)) { pc = 39; } else { pc = 37; }
          continue;
        case 37:
          s.placeholder('EvtTextShow2');
          pc = 38;
          continue;
        case 38:
          await s.textEnd();
          pc = 39;
          continue;
        case 39:
          pc = 40;
          continue;
        case 40:
          s.checkSlot('alive', 9);
          pc = 41;
          continue;
        case 41:
          if (s.slotInt(12) == s.slotInt(0)) { pc = 46; } else { pc = 42; }
          continue;
        case 42:
          s.checkSlot('alive', 8);
          pc = 43;
          continue;
        case 43:
          if (s.slotInt(12) == s.slotInt(0)) { pc = 46; } else { pc = 44; }
          continue;
        case 44:
          s.placeholder('EvtTextShow2');
          pc = 45;
          continue;
        case 45:
          await s.textEnd();
          pc = 46;
          continue;
        case 46:
          pc = 47;
          continue;
        case 47:
          s.checkSlot('alive', 12);
          pc = 48;
          continue;
        case 48:
          if (s.slotInt(12) == s.slotInt(0)) { pc = 53; } else { pc = 49; }
          continue;
        case 49:
          s.checkSlot('alive', 19);
          pc = 50;
          continue;
        case 50:
          if (s.slotInt(12) == s.slotInt(0)) { pc = 53; } else { pc = 51; }
          continue;
        case 51:
          s.placeholder('EvtTextShow2');
          pc = 52;
          continue;
        case 52:
          await s.textEnd();
          pc = 53;
          continue;
        case 53:
          pc = 54;
          continue;
        case 54:
          s.checkSlot('alive', 32);
          pc = 55;
          continue;
        case 55:
          if (s.slotInt(12) == s.slotInt(0)) { pc = 58; } else { pc = 56; }
          continue;
        case 56:
          s.placeholder('EvtTextShow2');
          pc = 57;
          continue;
        case 57:
          await s.textEnd();
          pc = 58;
          continue;
        case 58:
          pc = 59;
          continue;
        case 59:
          s.checkSlot('alive', 13);
          pc = 60;
          continue;
        case 60:
          if (s.slotInt(12) == s.slotInt(0)) { pc = 63; } else { pc = 61; }
          continue;
        case 61:
          s.placeholder('EvtTextShow2');
          pc = 62;
          continue;
        case 62:
          await s.textEnd();
          pc = 63;
          continue;
        case 63:
          pc = 64;
          continue;
        case 64:
          s.placeholder('EvtTextShow2');
          pc = 65;
          continue;
        case 65:
          await s.textEnd();
          pc = 66;
          continue;
        case 66:
          await s.call(Sym('data_085B9BBC', 512));
          pc = 67;
          continue;
        case 67:
          s.sound('bgm', 9);
          pc = 68;
          continue;
        case 68:
          await s.fade(FadeDirection.fromBlack, 16);
          pc = 69;
          continue;
        case 69:
          s.setSlot(2, Sym('EventScr_Ch7_3'));
          pc = 70;
          continue;
        case 70:
          await s.call(Sym('EventScr_CallOnTutorialMode'));
          pc = 71;
          continue;
        case 71:
          s.evBitMod('evbit', true, 7);
          pc = 72;
          continue;
        case 72:
          return;
        default:
          return;
      }
    }
}

/// `EventScr_Ch7_EndingScene`
Future<void> Ch7_EndingScene(Scene s) async {
    await s.fade(FadeDirection.toBlack, 16);
    s.setSlot(11, 0);
    await s.loadMap(68);
    s.hideFaction('blue');
    s.hideFaction('red');
    s.hideFaction('green');
    await s.fade(FadeDirection.fromBlack, 16);
    s.sound('bgm', 83);
    s.loadUnits(2, Sym('frontier_df4_banim_b_076_90B4DC', 440));
    await s.waitUnitMoving();
    s.showCursorAtUnit(1);
    await s.stall(60);
    await s.endCursor();
    s.setTextType(0);
    await s.textShow(2501);
    await s.textEnd();
    s.textRemoveAll();
    s.moveUnit('MOVE_1STEP', [0, 2, 1]);
    s.moveUnit('MOVE_1STEP', [0, 1, 0]);
    s.loadUnits(2, Sym('frontier_df4_banim_b_076_90B4DC', 500));
    await s.waitUnitMoving();
    await s.waitUnitMoving();
    s.showCursorAtUnit(66);
    await s.stall(60);
    await s.endCursor();
    s.volumeDown(true);
    s.setSlot(2, 21);
    s.setSlot(3, 2502);
    await s.call(Sym('Event_TextWithBG'));
    s.volumeDown(false);
    s.moveUnit('MOVE_1STEP', [0, 66, 0]);
    await s.waitUnitMoving();
    s.moveUnit('MOVE', [0, 66, 9, 0]);
    s.setSlot(13, 0);
    s.setSlot(1, 265);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 0);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 9);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 0);
    s.slotQueuePushSlot(0x1);
    s.moveUnit('MOVE_DEFINED', [1]);
    s.setSlot(13, 0);
    s.setSlot(1, 266);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 0);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 10);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 0);
    s.slotQueuePushSlot(0x1);
    s.moveUnit('MOVE_DEFINED', [2]);
    await s.stall(8, cancellable: false);
    await s.fade(FadeDirection.toBlack, 16);
    await s.waitUnitMoving();
    s.evBitMod('flag', true, 213);
    await s.changeChapter(9, subcmd: 1);
    return;
}

/// `EventScr_Ch8_0`
Future<void> Ch8_0(Scene s) async {
    await s.cameraTo(0, 23, centered: false);
    s.loadUnits(1, Sym('UnitDef_Ch8Ally_0'));
    await s.waitUnitMoving();
    s.unitStateOp('reveal', 15);
    s.unitStateOp('reveal', 16);
    s.unitStateOp('reveal', 17);
    s.setSlot(1, 1);
    s.unitStateOp('setState', 15);
    s.setSlot(1, 1);
    s.unitStateOp('setState', 16);
    s.setSlot(1, 1);
    s.unitStateOp('setState', 17);
    s.showCursorAtUnit(15);
    await s.stall(60);
    await s.endCursor();
    s.sound('bgm', 37);
    s.setTextType(0);
    await s.textShow(2510);
    await s.textEnd();
    s.textRemoveAll();
    s.evBitMod('evbit', true, 7);
    return;
}

/// `EventScr_Ch8_10`
Future<void> Ch8_10(Scene s) async {
    await s.cameraTo(14, 20, centered: false);
    s.loadUnits(2, Sym('UnitDef_Ch8Ally_2'));
    await s.waitUnitMoving();
    s.sound('bgm', 76);
    await s.fade(FadeDirection.fromBlack, 16);
    s.showCursorAtUnit(1);
    await s.stall(60);
    await s.endCursor();
    s.setSlot(2, 10);
    await s.call(Sym('EventScr_SetBackground'));
    await s.textShow(3010);
    await s.textEnd();
    s.placeholder('EvtBgmFadeIn');
    await s.fade(FadeDirection.toWhite, 2);
    s.textRemoveAll();
    s.hideFaction('blue');
    s.hideFaction('red');
    s.hideFaction('green');
    s.setSlot(11, 1310734);
    await s.loadMap(78);
    s.placeholder('UNIT_COLORS');
    s.loadUnits(2, Sym('UnitDef_Ch8Ally_3'));
    await s.waitUnitMoving();
    s.placeholder('EvtBgmFadeIn');
    await s.fade(FadeDirection.fromWhite, 2);
    await s.popupText(406, 8, 8);
    s.showCursorAtUnit(1);
    await s.stall(60);
    await s.endCursor();
    s.setTextType(1);
    await s.fade(FadeDirection.toWhite, 16);
    s.showTextBg(11);
    await s.fade(FadeDirection.fromWhite, 16);
    await s.textShow(3011);
    await s.textEnd();
    s.textRemoveAll();
    await s.fade(FadeDirection.toWhite, 16);
    await s.clearScreen();
    await s.fade(FadeDirection.fromWhite, 16);
    s.moveUnit('MOVE', [0, 1, 0, 16]);
    await s.stall(32, cancellable: false);
    await s.fade(FadeDirection.toWhite, 16);
    await s.waitUnitMoving();
    s.hideFaction('blue');
    s.hideFaction('red');
    s.hideFaction('green');
    s.setTextType(1);
    s.showTextBg(11);
    await s.fade(FadeDirection.fromWhite, 16);
    await s.textShow(3012);
    await s.textEnd();
    s.placeholder('EvtBgmFadeIn');
    await s.fade(FadeDirection.toWhite, 2);
    s.textRemoveAll();
    s.setSlot(11, 1310734);
    await s.loadMap(6);
    s.placeholder('UNIT_COLORS');
    s.loadUnits(2, Sym('UnitDef_Ch8Ally_2'));
    await s.waitUnitMoving();
    s.sound('bgm', 76);
    await s.fade(FadeDirection.fromWhite, 2);
    s.showCursorAtUnit(1);
    await s.stall(60);
    await s.endCursor();
    s.setSlot(2, 10);
    await s.call(Sym('EventScr_SetBackground'));
    await s.textShow(3013);
    await s.textEnd();
    s.textRemoveAll();
    await s.changeChapter(56, subcmd: 1);
    s.placeholder('ENDB');
}

/// `EventScr_Ch8_11`
Future<void> Ch8_11(Scene s) async {
    s.slotArith('SADD', 7, 2);
    s.slotArith('SADD', 8, 3);
    s.slotArith('SADD', 9, 4);
    s.setSlot(2, 131087);
    await s.call(Sym('EventScr_9EEA58'));
    await s.tileChange(0);
    s.loadUnits(1, Sym('UnitDef_Ch9AEnemy_11'));
    await s.waitUnitMoving();
    await s.fade(FadeDirection.fromBlack, 16);
    s.showCursorAtUnit(107);
    await s.stall(60);
    await s.endCursor();
    s.slotArith('SADD', 2, 7);
    s.setTextType(0);
    await s.textShow(65535);
    await s.textEnd();
    s.textRemoveAll();
    s.moveUnit('MOVE', [16, 105, 13, 10]);
    s.moveUnit('MOVE', [16, 67, 15, 10]);
    s.moveUnit('MOVE', [16, 83, 13, 5]);
    s.setSlot(13, 0);
    s.setSlot(1, 65873);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 0);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 65871);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 0);
    s.slotQueuePushSlot(0x1);
    s.moveUnit('MOVE_DEFINED', [87]);
    await s.waitUnitMoving();
    await s.removeUnit(105);
    await s.removeUnit(67);
    s.showCursorAtUnit(107);
    await s.stall(60);
    await s.endCursor();
    s.slotArith('SADD', 2, 8);
    s.setTextType(0);
    await s.textShow(65535);
    await s.textEnd();
    s.textRemoveAll();
    s.moveUnit('MOVE', [16, 83, 13, 10]);
    s.moveUnit('MOVE', [16, 87, 15, 10]);
    s.moveUnit('MOVE', [16, 68, 15, 5]);
    s.setSlot(13, 0);
    s.setSlot(1, 65867);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 0);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 65869);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 0);
    s.slotQueuePushSlot(0x1);
    s.moveUnit('MOVE_DEFINED', [29]);
    await s.waitUnitMoving();
    await s.removeUnit(83);
    await s.removeUnit(87);
    s.showCursorAtUnit(107);
    await s.stall(60);
    await s.endCursor();
    s.slotArith('SADD', 2, 9);
    s.setTextType(0);
    await s.textShow(65535);
    await s.textEnd();
    s.textRemoveAll();
    s.moveUnit('MOVE', [16, 29, 13, 10]);
    s.moveUnit('MOVE', [16, 68, 15, 10]);
    await s.stall(15, cancellable: false);
    await s.fade(FadeDirection.toBlack, 16);
    await s.waitUnitMoving();
    s.hideFaction('blue');
    s.hideFaction('red');
    s.hideFaction('green');
    return;
}

/// `EventScr_Ch8_BeginningScene`
Future<void> Ch8_BeginningScene(Scene s) async {
    s.sound('bgm', 37);
    s.loadUnits(2, Sym('UnitDef_Ch8Ally_1'));
    await s.waitUnitMoving();
    s.showCursorAtUnit(66);
    await s.stall(60);
    await s.endCursor();
    s.setSlot(2, 21);
    await s.call(Sym('EventScr_SetBackground'));
    await s.textShow(2505);
    await s.textEnd();
    s.placeholder('EvtBgmFadeIn');
    await s.continueText();
    await s.textEnd();
    await s.call(Sym('EventScr_TextShowWithFadeIn'));
    s.loadUnits(1, Sym('UnitDef_Ch8Enemy_3'));
    await s.waitUnitMoving();
    s.showCursorAtUnit(77);
    await s.stall(60);
    await s.endCursor();
    s.sound('bgm', 38);
    s.setTextType(0);
    await s.textShow(2506);
    await s.textEnd();
    s.textRemoveAll();
    await s.stall(30);
    s.placeholder('CUSE');
    s.showCursorAtUnit(66);
    await s.stall(60);
    await s.endCursor();
    s.moveUnit('MOVE', [0, 66, 20, 19]);
    s.setSlot(11, 1048596);
    s.moveUnit('MOVE_1STEP', [0, 65534, 1]);
    await s.waitUnitMoving();
    s.moveUnit('MOVE', [0, 66, 20, 15]);
    await s.waitUnitMoving();
    s.setSlot(11, 1048597);
    s.moveUnit('MOVE_1STEP', [0, 65534, 0]);
    s.moveUnit('MOVE', [0, 66, 19, 10]);
    await s.waitUnitMoving();
    await s.removeUnit(66);
    s.showCursorAtUnit(77);
    await s.stall(60);
    await s.endCursor();
    s.setSlot(2, 21);
    s.setSlot(3, 2507);
    await s.call(Sym('Event_TextWithBG'));
    s.setSlot(11, 1048595);
    s.moveUnit('MOVE_1STEP', [0, 65534, 0]);
    await s.waitUnitMoving();
    s.moveUnit('MOVE', [0, 77, 19, 14]);
    await s.waitUnitMoving();
    s.setSlot(11, 1048594);
    s.moveUnit('MOVE_1STEP', [0, 65534, 1]);
    await s.waitUnitMoving();
    s.moveUnit('MOVE', [0, 77, 19, 14]);
    await s.waitUnitMoving();
    s.showCursorAtUnit(77);
    await s.stall(60);
    await s.endCursor();
    s.setTextType(0);
    await s.textShow(2508);
    await s.textEnd();
    s.textRemoveAll();
    s.setSlot(11, 1376276);
    s.sound('se', 171);
    await s.tileChange(65535);
    s.moveUnit('MOVE', [0, 77, 19, 10]);
    s.setSlot(11, 1048595);
    s.moveUnit('MOVE', [16, 65534, 19, 11]);
    s.setSlot(11, 1048596);
    s.moveUnit('MOVE', [16, 65534, 20, 11]);
    await s.waitUnitMoving();
    s.hideFaction('red');
    s.loadUnits(1, Sym('UnitDef_Ch8Enemy_0'));
    await s.waitUnitMoving();
    s.setSlot(2, Sym('UnitDef_Ch8Enemy_4'));
    s.setSlot(3, 1);
    await s.call(Sym('EventScr_LoadUnitForTutorial'));
    s.showCursorAtUnit(1);
    await s.stall(60);
    await s.endCursor();
    s.setSlot(2, 21);
    await s.call(Sym('EventScr_SetBackground'));
    await s.textShow(2509);
    await s.textEnd();
    s.textRemoveAll();
    await s.call(Sym('data_085B9BBC', 512));
    s.evBitMod('flag', true, 12);
    return;
}

/// `EventScr_Ch8_EndingScene`
Future<void> Ch8_EndingScene(Scene s) async {
    s.sound('bgm', 49);
    s.setSlot(2, 21);
    await s.call(Sym('EventScr_SetBackground'));
    await s.textShow(2513);
    await s.textEnd();
    s.textRemoveAll();
    s.evBitMod('flag', true, 223);
    await s.changeChapter(6, subcmd: 1);
    return;
    s.sound('bgm', 39);
    s.setTextType(0);
    await s.textShow(2514);
    await s.textEnd();
    s.textRemoveAll();
    s.evBitMod('evbit', true, 7);
    return;
    s.volumeDown(true);
    s.setTextType(0);
    await s.textShow(2515);
    await s.textEnd();
    s.textRemoveAll();
    s.volumeDown(false);
    s.evBitMod('evbit', true, 7);
    return;
    s.volumeDown(true);
    s.setTextType(0);
    await s.textShow(2516);
    await s.textEnd();
    s.textRemoveAll();
    s.volumeDown(false);
    s.evBitMod('evbit', true, 7);
    return;
    s.volumeDown(true);
    s.setTextType(0);
    await s.textShow(2517);
    await s.textEnd();
    s.textRemoveAll();
    s.volumeDown(false);
    s.evBitMod('evbit', true, 7);
    return;
    s.setSlot(2, 0);
    await s.call(Sym('UnitDef_Ch14BAlly_7'));
    s.evBitMod('flag', false, 12);
    s.evBitMod('evbit', true, 7);
    return;
    s.setSlot(2, Sym('UnitDef_Ch8Enemy_1'));
    await s.call(Sym('EventScr_LoadReinforce'));
    s.evBitMod('evbit', true, 7);
    return;
    s.setSlot(2, Sym('UnitDef_Ch8Enemy_2'));
    await s.call(Sym('EventScr_LoadReinforce'));
    s.evBitMod('evbit', true, 7);
    return;
}

/// `EventScr_Ch9A_2`
Future<void> Ch9A_2(Scene s) async {
    s.sound('override', 42);
    await s.stall(33);
    s.setSlot(2, 0);
    s.setSlot(3, 2538);
    await s.call(Sym('Event_TextWithBG'));
    s.restoreBgm(2);
    await s.call(Sym('data_085B9BBC', 360));
    s.setSlot(3, 96);
    await s.giveItem(65535, 3);
    s.evBitMod('evbit', true, 7);
    return;
}

/// `EventScr_Ch9A_3`
Future<void> Ch9A_3(Scene s) async {
    s.volumeDown(true);
    s.setSlot(2, 0);
    s.setSlot(3, 2539);
    await s.call(Sym('Event_TextWithBG'));
    s.volumeDown(false);
    await s.call(Sym('data_085B9BBC', 360));
    s.setSlot(3, 9);
    await s.giveItem(65535, 3);
    s.evBitMod('evbit', true, 7);
    return;
}

/// `EventScr_Ch9A_4`
Future<void> Ch9A_4(Scene s) async {
    var pc = 0;
    while (true) {
      switch (pc) {
        case 0:
          s.checkSlot('alive', 18);
          pc = 1;
          continue;
        case 1:
          if (s.slotInt(12) == s.slotInt(0)) { pc = 2; } else { pc = 2; }
          continue;
        case 2:
          s.checkSlot('allegiance', 18);
          pc = 3;
          continue;
        case 3:
          s.setSlot(1, 0);
          pc = 4;
          continue;
        case 4:
          if (s.slotInt(12) == s.slotInt(1)) { pc = 5; } else { pc = 5; }
          continue;
        case 5:
          s.cameraToChar(18);
          pc = 6;
          continue;
        case 6:
          s.showCursorAtUnit(18);
          pc = 7;
          continue;
        case 7:
          await s.stall(60);
          pc = 8;
          continue;
        case 8:
          await s.endCursor();
          pc = 9;
          continue;
        case 9:
          s.sound('override', 20);
          pc = 10;
          continue;
        case 10:
          await s.stall(33);
          pc = 11;
          continue;
        case 11:
          s.setTextType(0);
          pc = 12;
          continue;
        case 12:
          await s.textShow(2528);
          pc = 13;
          continue;
        case 13:
          await s.textEnd();
          pc = 14;
          continue;
        case 14:
          s.textRemoveAll();
          pc = 15;
          continue;
        case 15:
          s.moveUnit('MOVE', [24, 18, 2, 23]);
          pc = 16;
          continue;
        case 16:
          s.moveUnit('MOVE', [24, 131, 2, 23]);
          pc = 17;
          continue;
        case 17:
          s.moveUnit('MOVE', [24, 132, 2, 23]);
          pc = 18;
          continue;
        case 18:
          s.moveUnit('MOVE', [24, 133, 2, 23]);
          pc = 19;
          continue;
        case 19:
          await s.waitUnitMoving();
          pc = 20;
          continue;
        case 20:
          await s.removeUnit(18);
          pc = 21;
          continue;
        case 21:
          await s.removeUnit(131);
          pc = 22;
          continue;
        case 22:
          await s.removeUnit(132);
          pc = 23;
          continue;
        case 23:
          await s.removeUnit(133);
          pc = 24;
          continue;
        case 24:
          s.checkSlotValue('redCount');
          pc = 25;
          continue;
        case 25:
          if (s.slotInt(12) != s.slotInt(0)) { pc = 26; } else { pc = 26; }
          continue;
        case 26:
          await s.call(Sym('EventScr_Ch9a_EndingScene'));
          pc = 27;
          continue;
        case 27:
          s.placeholder('ENDB');
          pc = 28;
          continue;
        default:
          return;
      }
    }
}

/// `EventScr_Ch9A_5`
Future<void> Ch9A_5(Scene s) async {
    var pc = 0;
    while (true) {
      switch (pc) {
        case 0:
          pc = 1;
          continue;
        case 1:
          s.evBitMod('evbit', true, 7);
          pc = 2;
          continue;
        case 2:
          return;
        case 3:
          s.setSlot(2, Sym('UnitDef_Ch9AEnemy_2'));
          pc = 4;
          continue;
        case 4:
          await s.call(Sym('EventScr_LoadReinforce'));
          pc = 5;
          continue;
        case 5:
          s.evBitMod('evbit', true, 7);
          pc = 6;
          continue;
        case 6:
          return;
        case 7:
          s.setSlot(2, Sym('UnitDef_Ch9AEnemy_3'));
          pc = 8;
          continue;
        case 8:
          await s.call(Sym('EventScr_LoadReinforce'));
          pc = 9;
          continue;
        case 9:
          s.evBitMod('evbit', true, 7);
          pc = 10;
          continue;
        case 10:
          return;
        case 11:
          s.setSlot(2, Sym('UnitDef_Ch9AEnemy_4'));
          pc = 12;
          continue;
        case 12:
          await s.call(Sym('EventScr_LoadReinforce'));
          pc = 13;
          continue;
        case 13:
          s.evBitMod('evbit', true, 7);
          pc = 14;
          continue;
        case 14:
          return;
        case 15:
          s.setSlot(2, Sym('UnitDef_Ch9AEnemy_5'));
          pc = 16;
          continue;
        case 16:
          await s.call(Sym('EventScr_LoadReinforce'));
          pc = 17;
          continue;
        case 17:
          s.evBitMod('evbit', true, 7);
          pc = 18;
          continue;
        case 18:
          return;
        case 19:
          s.setSlot(2, Sym('UnitDef_Ch9AEnemy_6'));
          pc = 20;
          continue;
        case 20:
          await s.call(Sym('EventScr_LoadReinforce'));
          pc = 21;
          continue;
        case 21:
          s.evBitMod('evbit', true, 7);
          pc = 22;
          continue;
        case 22:
          return;
        case 23:
          s.setSlot(2, Sym('UnitDef_Ch9AEnemy_7'));
          pc = 24;
          continue;
        case 24:
          await s.call(Sym('EventScr_LoadReinforce'));
          pc = 25;
          continue;
        case 25:
          s.evBitMod('evbit', true, 7);
          pc = 26;
          continue;
        case 26:
          return;
        case 27:
          s.setSlot(2, Sym('UnitDef_Ch9AEnemy_8'));
          pc = 28;
          continue;
        case 28:
          await s.call(Sym('EventScr_LoadReinforce'));
          pc = 29;
          continue;
        case 29:
          s.displayCursorAtUnit(18);
          pc = 30;
          continue;
        case 30:
          await s.stall(60);
          pc = 31;
          continue;
        case 31:
          await s.endCursor();
          pc = 32;
          continue;
        case 32:
          s.sound('override', 20);
          pc = 33;
          continue;
        case 33:
          await s.stall(33);
          pc = 34;
          continue;
        case 34:
          s.setTextType(0);
          pc = 35;
          continue;
        case 35:
          await s.textShow(2527);
          pc = 36;
          continue;
        case 36:
          await s.textEnd();
          pc = 37;
          continue;
        case 37:
          s.textRemoveAll();
          pc = 38;
          continue;
        case 38:
          s.evBitMod('evbit', true, 7);
          pc = 39;
          continue;
        case 39:
          return;
        case 40:
          s.setSlot(2, Sym('UnitDef_Ch9AEnemy_9'));
          pc = 41;
          continue;
        case 41:
          await s.call(Sym('EventScr_LoadReinforceHardMode'));
          pc = 42;
          continue;
        case 42:
          s.evBitMod('evbit', true, 7);
          pc = 43;
          continue;
        case 43:
          return;
        default:
          return;
      }
    }
}

/// `EventScr_Ch9B_9`
Future<void> Ch9B_9(Scene s) async {
    var pc = 0;
    while (true) {
      switch (pc) {
        case 0:
          s.setSlot(2, 0);
          pc = 1;
          continue;
        case 1:
          await s.call(Sym('UnitDef_Ch14BAlly_7'));
          pc = 2;
          continue;
        case 2:
          s.counterSet(3, 0);
          pc = 3;
          continue;
        case 3:
          s.checkSlotValue('tutorial');
          pc = 4;
          continue;
        case 4:
          if (s.slotInt(12) != s.slotInt(0)) { pc = 8; } else { pc = 5; }
          continue;
        case 5:
          s.checkSlotValue('hard');
          pc = 6;
          continue;
        case 6:
          if (s.slotInt(12) == s.slotInt(0)) { pc = 8; } else { pc = 7; }
          continue;
        case 7:
          s.counterSet(3, 0);
          pc = 8;
          continue;
        case 8:
          pc = 9;
          continue;
        case 9:
          s.evBitMod('flag', false, 14);
          pc = 10;
          continue;
        case 10:
          s.evBitMod('evbit', true, 7);
          pc = 11;
          continue;
        case 11:
          return;
        default:
          return;
      }
    }
}

/// `EventScr_Ch9a_BeginningScene`
Future<void> Ch9a_BeginningScene(Scene s) async {
    var pc = 0;
    while (true) {
      switch (pc) {
        case 0:
          s.sound('bgm', 46);
          pc = 1;
          continue;
        case 1:
          s.setSlot(2, 2519);
          pc = 2;
          continue;
        case 2:
          s.setSlot(3, 2520);
          pc = 3;
          continue;
        case 3:
          s.setSlot(4, 2521);
          pc = 4;
          continue;
        case 4:
          await s.call(Sym('EventScr_Ch8_11'));
          pc = 5;
          continue;
        case 5:
          s.placeholder('EvtBgmFadeIn');
          pc = 6;
          continue;
        case 6:
          s.setSlot(11, 0);
          pc = 7;
          continue;
        case 7:
          await s.loadMap(69);
          pc = 8;
          continue;
        case 8:
          s.checkSlot('exists', 34);
          pc = 9;
          continue;
        case 9:
          if (s.slotInt(12) == s.slotInt(0)) { pc = 12; } else { pc = 10; }
          continue;
        case 10:
          s.setSlot(1, 0);
          pc = 11;
          continue;
        case 11:
          s.unitStateOp('setState', 34);
          pc = 12;
          continue;
        case 12:
          pc = 13;
          continue;
        case 13:
          s.setSlot(1, 1);
          pc = 14;
          continue;
        case 14:
          s.unitStateOp('setState', 1);
          pc = 15;
          continue;
        case 15:
          s.loadUnits(3, Sym('UnitDef_Ch9AAlly_2'));
          pc = 16;
          continue;
        case 16:
          await s.waitUnitMoving();
          pc = 17;
          continue;
        case 17:
          await s.fade(FadeDirection.fromBlack, 16);
          pc = 18;
          continue;
        case 18:
          s.loadUnits(2, Sym('UnitDef_Ch9AAlly_3'));
          pc = 19;
          continue;
        case 19:
          await s.waitUnitMoving();
          pc = 20;
          continue;
        case 20:
          s.moveUnit('MOVE_1STEP', [0, 1, 0]);
          pc = 21;
          continue;
        case 21:
          await s.waitUnitMoving();
          pc = 22;
          continue;
        case 22:
          s.showCursorAtUnit(34);
          pc = 23;
          continue;
        case 23:
          await s.stall(60);
          pc = 24;
          continue;
        case 24:
          await s.endCursor();
          pc = 25;
          continue;
        case 25:
          s.sound('bgm', 36);
          pc = 26;
          continue;
        case 26:
          s.setSlot(2, 36);
          pc = 27;
          continue;
        case 27:
          await s.call(Sym('EventScr_SetBackground'));
          pc = 28;
          continue;
        case 28:
          await s.textShow(2522);
          pc = 29;
          continue;
        case 29:
          await s.textEnd();
          pc = 30;
          continue;
        case 30:
          s.textRemoveAll();
          pc = 31;
          continue;
        case 31:
          await s.fade(FadeDirection.toBlack, 16);
          pc = 32;
          continue;
        case 32:
          s.hideFaction('blue');
          pc = 33;
          continue;
        case 33:
          s.hideFaction('red');
          pc = 34;
          continue;
        case 34:
          s.hideFaction('green');
          pc = 35;
          continue;
        case 35:
          s.setSlot(11, 262162);
          pc = 36;
          continue;
        case 36:
          await s.loadMap(10);
          pc = 37;
          continue;
        case 37:
          await s.fade(FadeDirection.fromBlack, 16);
          pc = 38;
          continue;
        case 38:
          s.loadUnits(2, Sym('UnitDef_Ch9AAlly_0'));
          pc = 39;
          continue;
        case 39:
          await s.waitUnitMoving();
          pc = 40;
          continue;
        case 40:
          s.showCursorAtUnit(2);
          pc = 41;
          continue;
        case 41:
          await s.stall(60);
          pc = 42;
          continue;
        case 42:
          await s.endCursor();
          pc = 43;
          continue;
        case 43:
          s.setSlot(2, 12);
          pc = 44;
          continue;
        case 44:
          await s.call(Sym('EventScr_SetBackground'));
          pc = 45;
          continue;
        case 45:
          await s.textShow(2523);
          pc = 46;
          continue;
        case 46:
          await s.textEnd();
          pc = 47;
          continue;
        case 47:
          s.volumeDown(true);
          pc = 48;
          continue;
        case 48:
          await s.continueText();
          pc = 49;
          continue;
        case 49:
          await s.textEnd();
          pc = 50;
          continue;
        case 50:
          s.textRemoveAll();
          pc = 51;
          continue;
        case 51:
          await s.fade(FadeDirection.toBlack, 16);
          pc = 52;
          continue;
        case 52:
          await s.clearScreen();
          pc = 53;
          continue;
        case 53:
          await s.fade(FadeDirection.fromBlack, 16);
          pc = 54;
          continue;
        case 54:
          s.loadUnits(2, Sym('UnitDef_Ch9AMixed_0'));
          pc = 55;
          continue;
        case 55:
          await s.waitUnitMoving();
          pc = 56;
          continue;
        case 56:
          s.showCursorAtUnit(25);
          pc = 57;
          continue;
        case 57:
          await s.stall(60);
          pc = 58;
          continue;
        case 58:
          await s.endCursor();
          pc = 59;
          continue;
        case 59:
          s.sound('override', 42);
          pc = 60;
          continue;
        case 60:
          await s.stall(33);
          pc = 61;
          continue;
        case 61:
          s.setSlot(2, 12);
          pc = 62;
          continue;
        case 62:
          await s.call(Sym('EventScr_SetBackground'));
          pc = 63;
          continue;
        case 63:
          await s.textShow(2524);
          pc = 64;
          continue;
        case 64:
          await s.textEnd();
          pc = 65;
          continue;
        case 65:
          s.restoreBgm(4);
          pc = 66;
          continue;
        case 66:
          await s.continueText();
          pc = 67;
          continue;
        case 67:
          await s.textEnd();
          pc = 68;
          continue;
        case 68:
          s.textRemoveAll();
          pc = 69;
          continue;
        case 69:
          await s.fade(FadeDirection.toBlack, 16);
          pc = 70;
          continue;
        case 70:
          await s.clearScreen();
          pc = 71;
          continue;
        case 71:
          await s.fade(FadeDirection.fromBlack, 16);
          pc = 72;
          continue;
        case 72:
          s.moveUnit('MOVE', [0, 25, 9, 2]);
          pc = 73;
          continue;
        case 73:
          await s.stall(16, cancellable: false);
          pc = 74;
          continue;
        case 74:
          s.setSlot(13, 0);
          pc = 75;
          continue;
        case 75:
          s.setSlot(1, 145);
          pc = 76;
          continue;
        case 76:
          s.slotQueuePushSlot(0x1);
          pc = 77;
          continue;
        case 77:
          s.setSlot(1, 0);
          pc = 78;
          continue;
        case 78:
          s.slotQueuePushSlot(0x1);
          pc = 79;
          continue;
        case 79:
          s.setSlot(1, 137);
          pc = 80;
          continue;
        case 80:
          s.slotQueuePushSlot(0x1);
          pc = 81;
          continue;
        case 81:
          s.setSlot(1, 0);
          pc = 82;
          continue;
        case 82:
          s.slotQueuePushSlot(0x1);
          pc = 83;
          continue;
        case 83:
          s.moveUnit('MOVE_DEFINED', [26]);
          pc = 84;
          continue;
        case 84:
          s.setSlot(13, 0);
          pc = 85;
          continue;
        case 85:
          s.setSlot(1, 147);
          pc = 86;
          continue;
        case 86:
          s.slotQueuePushSlot(0x1);
          pc = 87;
          continue;
        case 87:
          s.setSlot(1, 0);
          pc = 88;
          continue;
        case 88:
          s.slotQueuePushSlot(0x1);
          pc = 89;
          continue;
        case 89:
          s.setSlot(1, 137);
          pc = 90;
          continue;
        case 90:
          s.slotQueuePushSlot(0x1);
          pc = 91;
          continue;
        case 91:
          s.setSlot(1, 0);
          pc = 92;
          continue;
        case 92:
          s.slotQueuePushSlot(0x1);
          pc = 93;
          continue;
        case 93:
          s.moveUnit('MOVE_DEFINED', [28]);
          pc = 94;
          continue;
        case 94:
          await s.waitUnitMoving();
          pc = 95;
          continue;
        case 95:
          s.hideFaction('green');
          pc = 96;
          continue;
        case 96:
          s.moveUnit('MOVE_1STEP', [16, 1, 0]);
          pc = 97;
          continue;
        case 97:
          await s.waitUnitMoving();
          pc = 98;
          continue;
        case 98:
          s.showCursorAtUnit(1);
          pc = 99;
          continue;
        case 99:
          await s.stall(60);
          pc = 100;
          continue;
        case 100:
          await s.endCursor();
          pc = 101;
          continue;
        case 101:
          s.setTextType(0);
          pc = 102;
          continue;
        case 102:
          await s.textShow(2525);
          pc = 103;
          continue;
        case 103:
          await s.textEnd();
          pc = 104;
          continue;
        case 104:
          s.textRemoveAll();
          pc = 105;
          continue;
        case 105:
          s.placeholder('EvtBgmFadeIn');
          pc = 106;
          continue;
        case 106:
          await s.cameraTo(14, 4, centered: true);
          pc = 107;
          continue;
        case 107:
          s.loadUnits(1, Sym('UnitDef_Ch9AEnemy_10'));
          pc = 108;
          continue;
        case 108:
          await s.waitUnitMoving();
          pc = 109;
          continue;
        case 109:
          s.moveUnit('MOVE_1STEP', [0, 2, 0]);
          pc = 110;
          continue;
        case 110:
          await s.waitUnitMoving();
          pc = 111;
          continue;
        case 111:
          s.showCursorAtUnit(197);
          pc = 112;
          continue;
        case 112:
          await s.stall(60);
          pc = 113;
          continue;
        case 113:
          await s.endCursor();
          pc = 114;
          continue;
        case 114:
          s.sound('bgm', 38);
          pc = 115;
          continue;
        case 115:
          s.setSlot(2, 12);
          pc = 116;
          continue;
        case 116:
          s.setSlot(3, 2526);
          pc = 117;
          continue;
        case 117:
          await s.call(Sym('Event_TextWithBG'));
          pc = 118;
          continue;
        case 118:
          s.loadUnits(1, Sym('UnitDef_Ch9AEnemy_0'));
          pc = 119;
          continue;
        case 119:
          await s.waitUnitMoving();
          pc = 120;
          continue;
        case 120:
          s.setSlot(2, Sym('UnitDef_Ch9AEnemy_1'));
          pc = 121;
          continue;
        case 121:
          s.setSlot(3, 1);
          pc = 122;
          continue;
        case 122:
          await s.call(Sym('EventScr_LoadUnitForTutorial'));
          pc = 123;
          continue;
        case 123:
          await s.fade(FadeDirection.toBlack, 16);
          pc = 124;
          continue;
        case 124:
          await s.removeUnit(197);
          pc = 125;
          continue;
        case 125:
          s.hideFaction('blue');
          pc = 126;
          continue;
        case 126:
          s.loadUnits(1, Sym('UnitDef_Event_Ch9aAlly'));
          pc = 127;
          continue;
        case 127:
          await s.waitUnitMoving();
          pc = 128;
          continue;
        case 128:
          s.setSlot(1, 1);
          pc = 129;
          continue;
        case 129:
          s.unitStateOp('setState', 34);
          pc = 130;
          continue;
        case 130:
          await s.call(Sym('data_085B9BBC', 512));
          pc = 131;
          continue;
        case 131:
          return;
        default:
          return;
      }
    }
}

/// `EventScr_Ch9a_EndingScene`
Future<void> Ch9a_EndingScene(Scene s) async {
    var pc = 0;
    while (true) {
      switch (pc) {
        case 0:
          s.sound('bgm', 50);
          pc = 1;
          continue;
        case 1:
          s.setSlot(2, 12);
          pc = 2;
          continue;
        case 2:
          await s.call(Sym('EventScr_SetBackground'));
          pc = 3;
          continue;
        case 3:
          await s.textShow(2531);
          pc = 4;
          continue;
        case 4:
          await s.textEnd();
          pc = 5;
          continue;
        case 5:
          s.textRemoveAll();
          pc = 6;
          continue;
        case 6:
          await s.fade(FadeDirection.toBlack, 16);
          pc = 7;
          continue;
        case 7:
          s.hideFaction('blue');
          pc = 8;
          continue;
        case 8:
          s.hideFaction('red');
          pc = 9;
          continue;
        case 9:
          s.hideFaction('green');
          pc = 10;
          continue;
        case 10:
          await s.clearScreen();
          pc = 11;
          continue;
        case 11:
          await s.cameraTo(20, 7, centered: true);
          pc = 12;
          continue;
        case 12:
          s.placeholder('EvtSetLoadUnitNoREDA');
          pc = 13;
          continue;
        case 13:
          s.loadUnits(2, Sym('UnitDef_Ch9AMixed_1'));
          pc = 14;
          continue;
        case 14:
          await s.waitUnitMoving();
          pc = 15;
          continue;
        case 15:
          await s.fade(FadeDirection.fromBlack, 16);
          pc = 16;
          continue;
        case 16:
          s.loadUnits(2, Sym('UnitDef_Ch9AMixed_1'));
          pc = 17;
          continue;
        case 17:
          await s.waitUnitMoving();
          pc = 18;
          continue;
        case 18:
          s.moveUnit('MOVE_1STEP', [0, 167, 2]);
          pc = 19;
          continue;
        case 19:
          await s.waitUnitMoving();
          pc = 20;
          continue;
        case 20:
          s.showCursorAtUnit(2);
          pc = 21;
          continue;
        case 21:
          await s.stall(60);
          pc = 22;
          continue;
        case 22:
          await s.endCursor();
          pc = 23;
          continue;
        case 23:
          s.setSlot(2, 12);
          pc = 24;
          continue;
        case 24:
          s.setSlot(3, 2532);
          pc = 25;
          continue;
        case 25:
          await s.call(Sym('Event_TextWithBG'));
          pc = 26;
          continue;
        case 26:
          s.placeholder('EvtBgmFadeIn');
          pc = 27;
          continue;
        case 27:
          s.moveUnit('MOVE_1STEP', [16, 2, 3]);
          pc = 28;
          continue;
        case 28:
          await s.waitUnitMoving();
          pc = 29;
          continue;
        case 29:
          s.setSlot(13, 0);
          pc = 30;
          continue;
        case 30:
          s.setSlot(1, 197076);
          pc = 31;
          continue;
        case 31:
          s.slotQueuePushSlot(0x1);
          pc = 32;
          continue;
        case 32:
          s.setSlot(1, 0);
          pc = 33;
          continue;
        case 33:
          s.slotQueuePushSlot(0x1);
          pc = 34;
          continue;
        case 34:
          s.setSlot(1, 196628);
          pc = 35;
          continue;
        case 35:
          s.slotQueuePushSlot(0x1);
          pc = 36;
          continue;
        case 36:
          s.setSlot(1, 0);
          pc = 37;
          continue;
        case 37:
          s.slotQueuePushSlot(0x1);
          pc = 38;
          continue;
        case 38:
          s.moveUnit('MOVE_DEFINED', [167]);
          pc = 39;
          continue;
        case 39:
          await s.waitUnitMoving();
          pc = 40;
          continue;
        case 40:
          s.showCursorAtUnit(2);
          pc = 41;
          continue;
        case 41:
          await s.stall(60);
          pc = 42;
          continue;
        case 42:
          await s.endCursor();
          pc = 43;
          continue;
        case 43:
          s.sound('bgm', 40);
          pc = 44;
          continue;
        case 44:
          s.setSlot(2, 12);
          pc = 45;
          continue;
        case 45:
          s.setSlot(3, 2533);
          pc = 46;
          continue;
        case 46:
          await s.call(Sym('Event_TextWithBG'));
          pc = 47;
          continue;
        case 47:
          s.loadUnits(2, Sym('UnitDef_Ch9AAlly_1'));
          pc = 48;
          continue;
        case 48:
          await s.waitUnitMoving();
          pc = 49;
          continue;
        case 49:
          s.showCursorAtUnit(204);
          pc = 50;
          continue;
        case 50:
          await s.stall(60);
          pc = 51;
          continue;
        case 51:
          await s.endCursor();
          pc = 52;
          continue;
        case 52:
          s.setSlot(2, 12);
          pc = 53;
          continue;
        case 53:
          await s.call(Sym('EventScr_SetBackground'));
          pc = 54;
          continue;
        case 54:
          s.sound('bgm', 38);
          pc = 55;
          continue;
        case 55:
          await s.textShow(2534);
          pc = 56;
          continue;
        case 56:
          await s.textEnd();
          pc = 57;
          continue;
        case 57:
          s.textRemoveAll();
          pc = 58;
          continue;
        case 58:
          s.checkSlot('flag', 8);
          pc = 59;
          continue;
        case 59:
          if (s.slotInt(12) == s.slotInt(0)) { pc = 70; } else { pc = 60; }
          continue;
        case 60:
          s.checkSlot('flag', 9);
          pc = 61;
          continue;
        case 61:
          if (s.slotInt(12) == s.slotInt(0)) { pc = 70; } else { pc = 62; }
          continue;
        case 62:
          s.setSlot(2, 12);
          pc = 63;
          continue;
        case 63:
          await s.call(Sym('EventScr_SetBackground'));
          pc = 64;
          continue;
        case 64:
          await s.textShow(2535);
          pc = 65;
          continue;
        case 65:
          await s.textEnd();
          pc = 66;
          continue;
        case 66:
          s.textRemoveAll();
          pc = 67;
          continue;
        case 67:
          await s.call(Sym('data_085B9BBC', 360));
          pc = 68;
          continue;
        case 68:
          s.setSlot(3, 91);
          pc = 69;
          continue;
        case 69:
          await s.giveItem(0, 3);
          pc = 70;
          continue;
        case 70:
          pc = 71;
          continue;
        case 71:
          s.evBitMod('flag', true, 113);
          pc = 72;
          continue;
        case 72:
          await s.changeChapter(11, subcmd: 1);
          pc = 73;
          continue;
        case 73:
          return;
        default:
          return;
      }
    }
}

/// `EventScr_ChangeAIinQueue`
Future<void> ChangeAIinQueue(Scene s) async {
    var pc = 0;
    while (true) {
      switch (pc) {
        case 0:
          pc = 1;
          continue;
        case 1:
          if (s.slotInt(13) <= s.slotInt(0)) { pc = 6; } else { pc = 2; }
          continue;
        case 2:
          s.slotArith('SADD', 33, 722722);
          pc = 3;
          continue;
        case 3:
          s.slotQueuePopToSlot(11);
          pc = 4;
          continue;
        case 4:
          s.placeholder('CHAI_AT');
          pc = 5;
          continue;
        case 5:
          pc = 0;
          continue;
        case 6:
          pc = 7;
          continue;
        case 7:
          return;
        default:
          return;
      }
    }
}

/// `EventScr_ConfigHardModeLoadUnitHard`
Future<void> ConfigHardModeLoadUnitHard(Scene s) async {
    var pc = 0;
    while (true) {
      switch (pc) {
        case 0:
          s.checkSlotValue('hard');
          pc = 1;
          continue;
        case 1:
          if (s.slotInt(12) != s.slotInt(0)) { pc = 4; } else { pc = 2; }
          continue;
        case 2:
          s.placeholder('EvtSetLoadUnitCount');
          pc = 3;
          continue;
        case 3:
          pc = 6;
          continue;
        case 4:
          pc = 5;
          continue;
        case 5:
          s.placeholder('EvtSetLoadUnitCount');
          pc = 6;
          continue;
        case 6:
          pc = 7;
          continue;
        case 7:
          return;
        default:
          return;
      }
    }
}

/// `EventScr_CutsceneExecEnd_Sub0`
Future<void> CutsceneExecEnd_Sub0(Scene s) async {
    var pc = 0;
    while (true) {
      switch (pc) {
        case 0:
          s.checkSlot('evbit', 8);
          pc = 1;
          continue;
        case 1:
          if (s.slotInt(12) != s.slotInt(0)) { pc = 5; } else { pc = 2; }
          continue;
        case 2:
          s.checkSlot('evbit', 7);
          pc = 3;
          continue;
        case 3:
          if (s.slotInt(12) != s.slotInt(0)) { pc = 8; } else { pc = 4; }
          continue;
        case 4:
          await s.fade(FadeDirection.toBlack, 16);
          pc = 5;
          continue;
        case 5:
          pc = 6;
          continue;
        case 6:
          await s.clearScreen();
          pc = 7;
          continue;
        case 7:
          await s.fade(FadeDirection.fromBlack, 16);
          pc = 8;
          continue;
        case 8:
          pc = 9;
          continue;
        case 9:
          return;
        default:
          return;
      }
    }
}

/// `EventScr_CutsceneExecEnd_Sub1`
Future<void> CutsceneExecEnd_Sub1(Scene s) async {
    var pc = 0;
    while (true) {
      switch (pc) {
        case 0:
          s.checkSlot('evbit', 8);
          pc = 1;
          continue;
        case 1:
          if (s.slotInt(12) != s.slotInt(0)) { pc = 3; } else { pc = 2; }
          continue;
        case 2:
          await s.fade(FadeDirection.toBlack, 16);
          pc = 3;
          continue;
        case 3:
          pc = 4;
          continue;
        case 4:
          s.checkSlot('evbit', 11);
          pc = 5;
          continue;
        case 5:
          if (s.slotInt(12) == s.slotInt(0)) { pc = 10; } else { pc = 6; }
          continue;
        case 6:
          s.checkSlotValue('chapter');
          pc = 7;
          continue;
        case 7:
          s.slotArith('SADD', 2, 12);
          pc = 8;
          continue;
        case 8:
          s.setSlot(11, 0);
          pc = 9;
          continue;
        case 9:
          await s.loadMap(65535);
          pc = 10;
          continue;
        case 10:
          pc = 11;
          continue;
        case 11:
          return;
        default:
          return;
      }
    }
}

/// `EventScr_FloorClearInTower`
Future<void> FloorClearInTower(Scene s) async {
    var pc = 0;
    while (true) {
      switch (pc) {
        case 0:
          s.modifyEvBit(4);
          pc = 1;
          continue;
        case 1:
          s.placeholder('ASMC');
          pc = 2;
          continue;
        case 2:
          s.setTextType(3);
          pc = 3;
          continue;
        case 3:
          s.setSlot(11, 4294967295);
          pc = 4;
          continue;
        case 4:
          await s.textShow(2239);
          pc = 5;
          continue;
        case 5:
          await s.textEnd();
          pc = 6;
          continue;
        case 6:
          s.setSlot(7, 1);
          pc = 7;
          continue;
        case 7:
          if (s.slotInt(12) == s.slotInt(7)) { pc = 11; } else { pc = 8; }
          continue;
        case 8:
          await s.changeChapter(65535, subcmd: 1);
          pc = 9;
          continue;
        case 9:
          s.placeholder('ASMC');
          pc = 10;
          continue;
        case 10:
          pc = 15;
          continue;
        case 11:
          pc = 12;
          continue;
        case 12:
          s.slotArith('SADD', 2, 3);
          pc = 13;
          continue;
        case 13:
          await s.changeChapter(65535, subcmd: 3);
          pc = 14;
          continue;
        case 14:
          s.placeholder('ASMC');
          pc = 15;
          continue;
        case 15:
          pc = 16;
          continue;
        case 16:
          return;
        default:
          return;
      }
    }
}

/// `EventScr_FormatFlashingCursor`
Future<void> FormatFlashingCursor(Scene s) async {
    var pc = 0;
    while (true) {
      switch (pc) {
        case 0:
          pc = 1;
          continue;
        case 1:
          if (s.slotInt(13) <= s.slotInt(0)) { pc = 5; } else { pc = 2; }
          continue;
        case 2:
          s.slotQueuePopToSlot(11);
          pc = 3;
          continue;
        case 3:
          s.showCursorAt(-1, -1, flashing: true);
          pc = 4;
          continue;
        case 4:
          pc = 0;
          continue;
        case 5:
          pc = 6;
          continue;
        case 6:
          return;
        default:
          return;
      }
    }
}

/// `EventScr_FormatMoveUnit`
Future<void> FormatMoveUnit(Scene s) async {
    var pc = 0;
    while (true) {
      switch (pc) {
        case 0:
          s.checkSlot('alive', -3);
          pc = 1;
          continue;
        case 1:
          if (s.slotInt(12) == s.slotInt(0)) { pc = 6; } else { pc = 2; }
          continue;
        case 2:
          s.placeholder('CHECK_DEPLOYED');
          pc = 3;
          continue;
        case 3:
          if (s.slotInt(12) == s.slotInt(0)) { pc = 6; } else { pc = 4; }
          continue;
        case 4:
          s.moveUnit('MOVE_NEXTTO', [0, -3, 0]);
          pc = 5;
          continue;
        case 5:
          pc = 26;
          continue;
        case 6:
          pc = 7;
          continue;
        case 7:
          s.placeholder('CHECK_COORDS');
          pc = 8;
          continue;
        case 8:
          s.slotArith('SADD', 11, 12);
          pc = 9;
          continue;
        case 9:
          s.placeholder('SPAWN_CUTSCENE_ALLY');
          pc = 10;
          continue;
        case 10:
          s.setSlot(7, RawArg('FACING_UP'));
          pc = 11;
          continue;
        case 11:
          if (s.slotInt(7) != s.slotInt(3)) { pc = 14; } else { pc = 12; }
          continue;
        case 12:
          s.moveUnit('MOVE_1STEP', [0, -3, RawArg('FACING_UP')]);
          pc = 13;
          continue;
        case 13:
          pc = 26;
          continue;
        case 14:
          pc = 15;
          continue;
        case 15:
          s.setSlot(7, RawArg('FACING_DOWN'));
          pc = 16;
          continue;
        case 16:
          if (s.slotInt(7) != s.slotInt(3)) { pc = 19; } else { pc = 17; }
          continue;
        case 17:
          s.moveUnit('MOVE_1STEP', [0, -3, RawArg('FACING_DOWN')]);
          pc = 18;
          continue;
        case 18:
          pc = 26;
          continue;
        case 19:
          pc = 20;
          continue;
        case 20:
          s.setSlot(7, RawArg('FACING_LEFT'));
          pc = 21;
          continue;
        case 21:
          if (s.slotInt(7) != s.slotInt(3)) { pc = 24; } else { pc = 22; }
          continue;
        case 22:
          s.moveUnit('MOVE_1STEP', [0, -3, RawArg('FACING_LEFT')]);
          pc = 23;
          continue;
        case 23:
          pc = 26;
          continue;
        case 24:
          pc = 25;
          continue;
        case 25:
          s.moveUnit('MOVE_1STEP', [0, -3, RawArg('FACING_RIGHT')]);
          pc = 26;
          continue;
        case 26:
          pc = 27;
          continue;
        case 27:
          await s.waitUnitMoving();
          pc = 28;
          continue;
        case 28:
          return;
        default:
          return;
      }
    }
}

/// `EventScr_GiveTreasureToLuckyDog`
Future<void> GiveTreasureToLuckyDog(Scene s) async {
    var pc = 0;
    while (true) {
      switch (pc) {
        case 0:
          s.placeholder('CHECK_CLASS');
          pc = 1;
          continue;
        case 1:
          s.setSlot(7, 13);
          pc = 2;
          continue;
        case 2:
          if (s.slotInt(12) == s.slotInt(7)) { pc = 7; } else { pc = 3; }
          continue;
        case 3:
          s.setSlot(7, 51);
          pc = 4;
          continue;
        case 4:
          if (s.slotInt(12) == s.slotInt(7)) { pc = 7; } else { pc = 5; }
          continue;
        case 5:
          s.placeholder('RANDOMNUMBER');
          pc = 6;
          continue;
        case 6:
          if (s.slotInt(2) < s.slotInt(12)) { pc = 12; } else { pc = 7; }
          continue;
        case 7:
          pc = 8;
          continue;
        case 8:
          await s.call(Sym('data_085B9BBC', 360));
          pc = 9;
          continue;
        case 9:
          await s.giveItem(65535, 3);
          pc = 10;
          continue;
        case 10:
          s.setSlot(12, 1);
          pc = 11;
          continue;
        case 11:
          pc = 14;
          continue;
        case 12:
          pc = 13;
          continue;
        case 13:
          s.setSlot(12, 0);
          pc = 14;
          continue;
        case 14:
          pc = 15;
          continue;
        case 15:
          return;
        default:
          return;
      }
    }
}

/// `EventScr_LoadReinforce`
Future<void> LoadReinforce(Scene s) async {
    s.modifyEvBit(4);
    await s.call(Sym('data_085B9BBC', 360));
    s.evBitMod('evbit', true, 9);
    s.placeholder('LOAD1');
    await s.waitUnitMoving();
    s.evBitMod('evbit', false, 9);
    s.modifyEvBit(0);
    return;
}

/// `EventScr_LoadReinforceHardMode`
Future<void> LoadReinforceHardMode(Scene s) async {
    var pc = 0;
    while (true) {
      switch (pc) {
        case 0:
          s.checkSlotValue('tutorial');
          pc = 1;
          continue;
        case 1:
          if (s.slotInt(12) != s.slotInt(0)) { pc = 5; } else { pc = 2; }
          continue;
        case 2:
          s.checkSlotValue('hard');
          pc = 3;
          continue;
        case 3:
          if (s.slotInt(12) == s.slotInt(0)) { pc = 5; } else { pc = 4; }
          continue;
        case 4:
          await s.call(Sym('EventScr_LoadReinforce'));
          pc = 5;
          continue;
        case 5:
          pc = 6;
          continue;
        case 6:
          return;
        default:
          return;
      }
    }
}

/// `EventScr_LoadUniqueAlly`
Future<void> LoadUniqueAlly(Scene s) async {
    var pc = 0;
    while (true) {
      switch (pc) {
        case 0:
          s.placeholder('CHECK_EXISTS');
          pc = 1;
          continue;
        case 1:
          if (s.slotInt(12) == s.slotInt(0)) { pc = 7; } else { pc = 2; }
          continue;
        case 2:
          s.placeholder('CHECK_ALLEGIANCE');
          pc = 3;
          continue;
        case 3:
          s.setSlot(1, RawArg('FACTION_ID_BLUE'));
          pc = 4;
          continue;
        case 4:
          if (s.slotInt(12) == s.slotInt(1)) { pc = 14; } else { pc = 5; }
          continue;
        case 5:
          s.placeholder('CUSA');
          pc = 6;
          continue;
        case 6:
          pc = 14;
          continue;
        case 7:
          pc = 8;
          continue;
        case 8:
          s.placeholder('SPAWN_ALLY');
          pc = 9;
          continue;
        case 9:
          s.setSlot(1, 0);
          pc = 10;
          continue;
        case 10:
          await s.setUnitHpFromSlot(0);
          pc = 11;
          continue;
        case 11:
          s.placeholder('REMU');
          pc = 12;
          continue;
        case 12:
          s.setSlot(1, 0);
          pc = 13;
          continue;
        case 13:
          s.placeholder('SET_STATE');
          pc = 14;
          continue;
        case 14:
          pc = 15;
          continue;
        case 15:
          return;
        default:
          return;
      }
    }
}

/// `EventScr_LoadUnitForDifferentMode`
Future<void> LoadUnitForDifferentMode(Scene s) async {
    var pc = 0;
    while (true) {
      switch (pc) {
        case 0:
          if (s.slotInt(12) != s.slotInt(0)) { pc = 4; } else { pc = 1; }
          continue;
        case 1:
          s.checkSlotValue('hard');
          pc = 2;
          continue;
        case 2:
          if (s.slotInt(12) == s.slotInt(0)) { pc = 4; } else { pc = 3; }
          continue;
        case 3:
          s.slotArith('SADD', 50, 2080);
          pc = 4;
          continue;
        case 4:
          pc = 5;
          continue;
        case 5:
          s.slotArith('SADD', 76, 2624);
          pc = 6;
          continue;
        case 6:
          await s.call(Sym('UnitDef_Ch14BAlly_7', 48));
          pc = 7;
          continue;
        case 7:
          return;
        default:
          return;
      }
    }
}

/// `EventScr_LoadUnitForTutorial`
Future<void> LoadUnitForTutorial(Scene s) async {
    var pc = 0;
    while (true) {
      switch (pc) {
        case 0:
          s.checkSlotValue('tutorial');
          pc = 1;
          continue;
        case 1:
          if (s.slotInt(12) != s.slotInt(0)) { pc = 6; } else { pc = 2; }
          continue;
        case 2:
          s.checkSlotValue('hard');
          pc = 3;
          continue;
        case 3:
          if (s.slotInt(12) == s.slotInt(0)) { pc = 6; } else { pc = 4; }
          continue;
        case 4:
          s.slotArith('SADD', 60, 2624);
          pc = 5;
          continue;
        case 5:
          await s.call(Sym('UnitDef_Ch14BAlly_7', 48));
          pc = 6;
          continue;
        case 6:
          pc = 7;
          continue;
        case 7:
          return;
        default:
          return;
      }
    }
}

/// `EventScr_MapSupportConversation`
Future<void> MapSupportConversation(Scene s) async {
    var pc = 0;
    while (true) {
      switch (pc) {
        case 0:
          s.modifyEvBit(3);
          pc = 1;
          continue;
        case 1:
          if (s.slotInt(2) == s.slotInt(0)) { pc = 4; } else { pc = 2; }
          continue;
        case 2:
          s.sound('bgm', 65535);
          pc = 3;
          continue;
        case 3:
          pc = 6;
          continue;
        case 4:
          pc = 5;
          continue;
        case 5:
          s.volumeDown(true);
          pc = 6;
          continue;
        case 6:
          pc = 7;
          continue;
        case 7:
          s.slotArith('SADD', 2, 3);
          pc = 8;
          continue;
        case 8:
          await s.textShow(65535);
          pc = 9;
          continue;
        case 9:
          await s.textEnd();
          pc = 10;
          continue;
        case 10:
          s.textRemoveAll();
          pc = 11;
          continue;
        case 11:
          s.placeholder('NOTIFY');
          pc = 12;
          continue;
        case 12:
          s.evBitMod('evbit', true, 7);
          pc = 13;
          continue;
        case 13:
          return;
        default:
          return;
      }
    }
}

/// `EventScr_MoveUnitS2ToLeader`
Future<void> MoveUnitS2ToLeader(Scene s) async {
    var pc = 0;
    while (true) {
      switch (pc) {
        case 0:
          s.checkSlot('alive', -3);
          pc = 1;
          continue;
        case 1:
          if (s.slotInt(12) == s.slotInt(0)) { pc = 5; } else { pc = 2; }
          continue;
        case 2:
          s.placeholder('CHECK_DEPLOYED');
          pc = 3;
          continue;
        case 3:
          if (s.slotInt(12) == s.slotInt(0)) { pc = 5; } else { pc = 4; }
          continue;
        case 4:
          pc = 9;
          continue;
        case 5:
          pc = 6;
          continue;
        case 6:
          s.moveUnit('MOVEONTO', [0, -3, 0]);
          pc = 7;
          continue;
        case 7:
          await s.waitUnitMoving();
          pc = 8;
          continue;
        case 8:
          s.unitStateOp('remu', -3);
          pc = 9;
          continue;
        case 9:
          pc = 10;
          continue;
        case 10:
          return;
        default:
          return;
      }
    }
}

/// `EventScr_Prologue_9EF828`
Future<void> Prologue_9EF828(Scene s) async {
    s.setTextType(3);
    s.setSlot(11, 4294967295);
    await s.textShow(2280);
    await s.textEnd();
    s.textRemoveAll();
    s.evBitMod('flag', true, 201);
    return;
}

/// `EventScr_Prologue_BeginningScene`
Future<void> Prologue_BeginningScene(Scene s) async {
    var pc = 0;
    while (true) {
      switch (pc) {
        case 0:
          await s.call(Sym('EventScr_Prologue_RenaisThroneCutscene'));
          pc = 1;
          continue;
        case 1:
          s.setSlot(2, Sym('EventScr_Prologue_EirikaAttacked'));
          pc = 2;
          continue;
        case 2:
          await s.call(Sym('EventScr_CallOnTutorialMode'));
          pc = 3;
          continue;
        case 3:
          s.checkSlotValue('tutorial');
          pc = 4;
          continue;
        case 4:
          if (s.slotInt(12) != s.slotInt(0)) { pc = 6; } else { pc = 5; }
          continue;
        case 5:
          s.placeholder('ASMC');
          pc = 6;
          continue;
        case 6:
          pc = 7;
          continue;
        case 7:
          s.evBitMod('flag', true, 8);
          pc = 8;
          continue;
        case 8:
          s.loadUnits(1, Sym('UnitDef_Event_PrologueAlly'));
          pc = 9;
          continue;
        case 9:
          await s.waitUnitMoving();
          pc = 10;
          continue;
        case 10:
          s.setSlot(1, 13);
          pc = 11;
          continue;
        case 11:
          await s.setUnitHpFromSlot(2);
          pc = 12;
          continue;
        case 12:
          s.showCursorAtUnit(1);
          pc = 13;
          continue;
        case 13:
          await s.stall(60);
          pc = 14;
          continue;
        case 14:
          await s.endCursor();
          pc = 15;
          continue;
        case 15:
          s.volumeDown(true);
          pc = 16;
          continue;
        case 16:
          s.setSlot(2, 37);
          pc = 17;
          continue;
        case 17:
          s.setSlot(3, 2253);
          pc = 18;
          continue;
        case 18:
          await s.call(Sym('Event_TextWithBG'));
          pc = 19;
          continue;
        case 19:
          s.volumeDown(false);
          pc = 20;
          continue;
        case 20:
          s.moveUnit('MOVE', [24, 2, 4, 4]);
          pc = 21;
          continue;
        case 21:
          await s.waitUnitMoving();
          pc = 22;
          continue;
        case 22:
          s.showCursorAtUnit(2);
          pc = 23;
          continue;
        case 23:
          await s.stall(60);
          pc = 24;
          continue;
        case 24:
          await s.endCursor();
          pc = 25;
          continue;
        case 25:
          s.setTextType(0);
          pc = 26;
          continue;
        case 26:
          await s.textShow(2254);
          pc = 27;
          continue;
        case 27:
          await s.textEnd();
          pc = 28;
          continue;
        case 28:
          s.textRemoveAll();
          pc = 29;
          continue;
        case 29:
          s.setSlot(2, Sym('EventScr_Prologue_ExecTut'));
          pc = 30;
          continue;
        case 30:
          await s.call(Sym('EventScr_CallOnTutorialMode'));
          pc = 31;
          continue;
        case 31:
          s.moveUnit('MOVE_CLOSEST', [0, 1, 4, 5]);
          pc = 32;
          continue;
        case 32:
          await s.waitUnitMoving();
          pc = 33;
          continue;
        case 33:
          await s.call(Sym('EventScr_Prologue_GiveRapier'));
          pc = 34;
          continue;
        case 34:
          await s.call(Sym('EventScr_Prologue_ONeillSpawn'));
          pc = 35;
          continue;
        case 35:
          s.evBitMod('evbit', true, 7);
          pc = 36;
          continue;
        case 36:
          return;
        default:
          return;
      }
    }
}

/// `EventScr_Prologue_EirikaAttacked`
Future<void> Prologue_EirikaAttacked(Scene s) async {
    s.overrideUnitMenu(24576);
    s.evBitMod('flag', true, 102);
    s.evBitMod('flag', true, 224);
    s.evBitMod('flag', true, 225);
    s.evBitMod('flag', true, 4);
    s.setSlot(13, 0);
    s.setSlot(1, 131072);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 1);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 1);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 4294967295);
    s.slotQueuePushSlot(0x1);
    s.placeholder('FIGHT_SCRIPT');
    return;
}

/// `EventScr_Prologue_EndingScene`
Future<void> Prologue_EndingScene(Scene s) async {
    s.sound('bgm', 49);
    s.setSlot(2, 37);
    await s.call(Sym('EventScr_SetBackground'));
    await s.textShow(2264);
    await s.textEnd();
    await s.fade(FadeDirection.toBlack, 16);
    s.textRemoveAll();
    s.evBitMod('flag', true, 224);
    s.evBitMod('flag', true, 225);
    s.evBitMod('flag', true, 183);
    s.evBitMod('flag', true, 180);
    s.evBitMod('flag', true, 181);
    s.evBitMod('flag', true, 220);
    s.evBitMod('flag', true, 185);
    s.evBitMod('flag', true, 194);
    s.evBitMod('flag', true, 195);
    s.evBitMod('flag', true, 231);
    s.evBitMod('flag', true, 201);
    await s.changeChapter(1, subcmd: 2);
    return;
}

/// `EventScr_Prologue_ExecTut`
Future<void> Prologue_ExecTut(Scene s) async {
    s.setTextType(3);
    s.setSlot(11, 4294967295);
    await s.textShow(2265);
    await s.textEnd();
    s.textRemoveAll();
    s.showCursorAtUnit(1, flashing: true);
    await s.stall(60);
    await s.endCursor();
    s.enqueueTutCall(2, Sym('EventScr_Prologue_Tutorial0'));
    s.evBitMod('evbit', true, 7);
    s.placeholder('ENDB');
}

/// `EventScr_Prologue_GiveRapier`
Future<void> Prologue_GiveRapier(Scene s) async {
    s.showCursorAtUnit(2);
    await s.stall(60);
    await s.endCursor();
    s.setTextType(0);
    await s.textShow(2255);
    await s.textEnd();
    s.textRemoveAll();
    await s.call(Sym('data_085B9BBC', 360));
    s.setSlot(3, 9);
    await s.giveItem(1, 3);
    s.setSlot(2, Sym('EventScr_Prologue_9EF828'));
    await s.call(Sym('EventScr_CallOnTutorialMode'));
    return;
}

/// `EventScr_Prologue_ONeillSpawn`
Future<void> Prologue_ONeillSpawn(Scene s) async {
    s.loadUnits(1, Sym('UnitDef_Event_PrologueEnemy'));
    await s.waitUnitMoving();
    s.displayCursorAtUnit(104);
    await s.stall(60);
    await s.endCursor();
    s.sound('bgm', 19);
    s.setTextType(0);
    await s.textShow(2256);
    await s.textEnd();
    s.textRemoveAll();
    s.evBitMod('flag', false, 4);
    return;
}

/// `EventScr_Prologue_OneEnemyLeft`
Future<void> Prologue_OneEnemyLeft(Scene s) async {
    var pc = 0;
    while (true) {
      switch (pc) {
        case 0:
          s.checkSlotValue('redCount');
          pc = 1;
          continue;
        case 1:
          s.setSlot(7, 1);
          pc = 2;
          continue;
        case 2:
          if (s.slotInt(12) != s.slotInt(7)) { pc = 12; } else { pc = 3; }
          continue;
        case 3:
          s.showCursorAtUnit(2);
          pc = 4;
          continue;
        case 4:
          await s.stall(60);
          pc = 5;
          continue;
        case 5:
          await s.endCursor();
          pc = 6;
          continue;
        case 6:
          s.setTextType(0);
          pc = 7;
          continue;
        case 7:
          s.placeholder('EVENT_WORD_SYM');
          pc = 8;
          continue;
        case 8:
          await s.textEnd();
          pc = 9;
          continue;
        case 9:
          s.textRemoveAll();
          pc = 10;
          continue;
        case 10:
          s.evBitMod('flag', false, 8);
          pc = 11;
          continue;
        case 11:
          pc = 16;
          continue;
        case 12:
          pc = 13;
          continue;
        case 13:
          s.placeholder('CHECK_TRIG_EVENTID');
          pc = 14;
          continue;
        case 14:
          s.slotArith('SADD', 2, 12);
          pc = 15;
          continue;
        case 15:
          s.evBitMod('flag', false, 65535);
          pc = 16;
          continue;
        case 16:
          pc = 17;
          continue;
        case 17:
          s.evBitMod('evbit', true, 7);
          pc = 18;
          continue;
        case 18:
          return;
        default:
          return;
      }
    }
}

/// `EventScr_Prologue_OneillSethBattle`
Future<void> Prologue_OneillSethBattle(Scene s) async {
    s.moveUnit('MOVE_CLOSEST', [0, 104, 1545]);
    await s.waitUnitMoving();
    s.setSlot(13, 0);
    s.setSlot(1, 0);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 131073);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 4294967295);
    s.slotQueuePushSlot(0x1);
    s.placeholder('FIGHT');
    s.displayCursorAtUnit(2);
    await s.stall(60);
    await s.endCursor();
    s.setTextType(0);
    await s.textShow(2261);
    await s.textEnd();
    s.textRemoveAll();
    return;
}

/// `EventScr_Prologue_RenaisThroneCutscene`
Future<void> Prologue_RenaisThroneCutscene(Scene s) async {
    s.setSlot(11, 655374);
    await s.loadMap(16);
    s.loadUnits(2, Sym('UnitDef_Event_PrologueThroneRoomUnits'));
    await s.waitUnitMoving();
    await s.fade(FadeDirection.fromBlack, 16);
    s.sound('bgm', 38);
    await s.popupText(1526, 8, 8);
    s.loadUnits(1, Sym('UnitDef_Event_PrologueMessager'));
    await s.waitUnitMoving();
    await s.cameraTo(14, 0, centered: false);
    s.showCursorAtUnit(15);
    await s.stall(60);
    await s.endCursor();
    s.setTextType(0);
    await s.textShow(2243);
    await s.textEnd();
    s.textRemoveAll();
    s.moveUnit('MOVE', [0, 15, 13, 11]);
    await s.waitUnitMoving();
    await s.removeUnit(15);
    s.moveUnit('MOVE_1STEP', [0, 1, 0]);
    await s.waitUnitMoving();
    s.showCursorAtUnit(1);
    await s.stall(60);
    await s.endCursor();
    s.setTextType(0);
    await s.textShow(2244);
    await s.textEnd();
    s.textRemoveAll();
    s.moveUnit('MOVEONTO', [0, 2, 1]);
    await s.waitUnitMoving();
    await s.removeUnit(1);
    s.showCursorAtUnit(2);
    await s.stall(60);
    await s.endCursor();
    s.setTextType(0);
    await s.textShow(2245);
    await s.textEnd();
    s.textRemoveAll();
    s.moveUnit('MOVE', [0, 2, 13, 11]);
    s.setSlot(13, 0);
    s.setSlot(1, 268);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 0);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 716);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 0);
    s.slotQueuePushSlot(0x1);
    s.moveUnit('MOVE_DEFINED', [4]);
    await s.waitUnitMoving();
    await s.removeUnit(2);
    await s.removeUnit(4);
    s.moveUnit('MOVE', [0, 5, 11, 4]);
    s.moveUnit('MOVE', [0, 6, 15, 4]);
    await s.waitUnitMoving();
    s.moveUnit('MOVE_1STEP', [0, 5, 1]);
    s.moveUnit('MOVE_1STEP', [0, 6, 0]);
    await s.waitUnitMoving();
    s.loadUnits(1, Sym('UnitDef_Event_PrologueGradoShamans'));
    await s.waitUnitMoving();
    s.loadUnits(1, Sym('UnitDef_Event_PrologueGradoCavalry'));
    await s.waitUnitMoving();
    s.loadUnits(1, Sym('UnitDef_Event_PrologueGradoRoyals'));
    await s.waitUnitMoving();
    s.showCursorAtUnit(197);
    await s.stall(60);
    await s.endCursor();
    s.setTextType(0);
    await s.textShow(2246);
    await s.textEnd();
    await s.fade(FadeDirection.toBlack, 2);
    s.textRemoveAll();
    s.evBitMod('evbit', false, 2);
    s.hideFaction('blue');
    s.hideFaction('red');
    s.hideFaction('green');
    s.setSlot(11, 0);
    await s.loadMap(64);
    await s.fade(FadeDirection.fromBlack, 16);
    s.loadUnits(2, Sym('UnitDef_Event_PrologueEscapees'));
    await s.waitUnitMoving();
    s.showCursorAtUnit(2);
    await s.stall(60);
    await s.endCursor();
    s.setSlot(2, 37);
    s.setSlot(3, 2247);
    await s.call(Sym('Event_TextWithBG'));
    s.setSlot(13, 0);
    s.setSlot(1, 260);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 0);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 132);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 0);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 128);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 0);
    s.slotQueuePushSlot(0x1);
    s.moveUnit('MOVE_DEFINED', [4]);
    await s.waitUnitMoving();
    await s.removeUnit(4);
    s.showCursorAtUnit(2);
    await s.stall(60);
    await s.endCursor();
    s.setSlot(2, 37);
    s.setSlot(3, 2248);
    await s.call(Sym('Event_TextWithBG'));
    s.loadUnits(1, Sym('UnitDef_Event_PrologueValterGroup'));
    await s.waitUnitMoving();
    s.moveUnit('MOVE_1STEP', [0, 2, 1]);
    await s.waitUnitMoving();
    s.moveUnit('MOVE_1STEP', [0, 1, 0]);
    await s.waitUnitMoving();
    s.showCursorAtUnit(69);
    await s.stall(60);
    await s.endCursor();
    s.setSlot(2, 37);
    s.setSlot(3, 2249);
    await s.call(Sym('Event_TextWithBG'));
    s.moveUnit('MOVE_1STEP', [0, 69, 0]);
    await s.waitUnitMoving();
    s.setSlot(13, 0);
    s.setSlot(1, 131072);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 1);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 4294967295);
    s.slotQueuePushSlot(0x1);
    s.placeholder('FIGHT');
    s.showCursorAtUnit(2);
    await s.stall(60);
    await s.endCursor();
    s.setTextType(0);
    await s.textShow(2251);
    await s.textEnd();
    s.textRemoveAll();
    s.moveUnit('MOVE_1STEP', [8, 2, 0]);
    await s.waitUnitMoving();
    await s.removeUnit(1);
    s.setSlot(13, 0);
    s.setSlot(1, 98564);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 0);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 98436);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 0);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 98432);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 0);
    s.slotQueuePushSlot(0x1);
    s.moveUnit('MOVE_DEFINED', [2]);
    await s.waitUnitMoving();
    await s.removeUnit(2);
    s.showCursorAtUnit(69);
    await s.stall(60);
    await s.endCursor();
    s.setTextType(0);
    await s.textShow(2252);
    await s.textEnd();
    s.textRemoveAll();
    await s.fade(FadeDirection.toBlack, 16);
    s.evBitMod('evbit', false, 2);
    s.hideFaction('blue');
    s.hideFaction('red');
    s.hideFaction('green');
    s.setSlot(11, 0);
    await s.loadMap(0);
    await s.fade(FadeDirection.fromBlack, 16);
    return;
}

/// `EventScr_Prologue_Turn1`
Future<void> Prologue_Turn1(Scene s) async {
    s.setSlot(2, Sym('EventScr_Prologue_ONeillSpawn'));
    await s.call(Sym('EventScr_CallOnTutorialMode'));
    s.setSlot(2, Sym('EventScr_Prologue_TutMessageTurn1'));
    await s.call(Sym('EventScr_CallOnTutorialMode'));
    s.evBitMod('evbit', true, 7);
    return;
}

/// `EventScr_Prologue_Turn2`
Future<void> Prologue_Turn2(Scene s) async {
    s.setSlot(2, Sym('EventScr_Prologue_TutMessageTurn2'));
    await s.call(Sym('EventScr_CallOnTutorialMode'));
    s.evBitMod('evbit', true, 7);
    return;
}

/// `EventScr_Prologue_Turn3`
Future<void> Prologue_Turn3(Scene s) async {
    s.setSlot(2, Sym('EventScr_Prologue_OneillSethBattle'));
    await s.call(Sym('EventScr_CallOnTutorialMode'));
    s.setSlot(2, Sym('EventScr_Prologue_TutEirikaAttack'));
    await s.call(Sym('EventScr_CallOnTutorialMode'));
    s.evBitMod('evbit', true, 7);
    return;
}

/// `EventScr_Prologue_TutEirikaAttack`
Future<void> Prologue_TutEirikaAttack(Scene s) async {
    s.setTextType(3);
    s.setSlot(11, 4294967295);
    await s.textShow(2275);
    await s.textEnd();
    s.textRemoveAll();
    s.showCursorAtUnit(1, flashing: true);
    await s.stall(60);
    await s.endCursor();
    s.setSlot(13, 0);
    s.setSlot(1, 0);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 1);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 65536);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 4294967295);
    s.slotQueuePushSlot(0x1);
    s.placeholder('FIGHT_SCRIPT');
    s.placeholder('EvtEnqueueConditionalTutCall');
    return;
}

/// `EventScr_Prologue_TutMessageTurn1`
Future<void> Prologue_TutMessageTurn1(Scene s) async {
    s.setTextType(3);
    s.setSlot(11, 4294967295);
    await s.textShow(2269);
    await s.textEnd();
    s.textRemoveAll();
    s.evBitMod('flag', true, 180);
    s.evBitMod('flag', true, 181);
    return;
}

/// `EventScr_Prologue_TutMessageTurn2`
Future<void> Prologue_TutMessageTurn2(Scene s) async {
    s.showCursorAtUnit(2);
    await s.stall(60);
    await s.endCursor();
    s.setTextType(0);
    await s.textShow(2257);
    await s.textEnd();
    s.textRemoveAll();
    s.setSlot(13, 0);
    s.setSlot(1, 0);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 131073);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 0);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 4294967295);
    s.slotQueuePushSlot(0x1);
    s.placeholder('FIGHT_SCRIPT');
    s.setTextType(3);
    s.setSlot(11, 4294967295);
    await s.textShow(2274);
    await s.textEnd();
    s.textRemoveAll();
    s.evBitMod('flag', false, 102);
    s.evBitMod('flag', true, 220);
    s.showCursorAtUnit(1, flashing: true);
    await s.stall(60);
    await s.endCursor();
    s.placeholder('EvtEnqueueConditionalTutCall');
    return;
}

/// `EventScr_Prologue_Tutorial0`
Future<void> Prologue_Tutorial0(Scene s) async {
    s.evBitMod('evbit', true, 7);
    s.setSlot(13, 0);
    s.setSlot(1, 1);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 327684);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 2267);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 524376);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 2266);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 524376);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, Sym('EventScr_Prologue_Tutorial1'));
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, Sym('EventScr_Prologue_Tutorial0'));
    s.slotQueuePushSlot(0x1);
    await s.call(Sym('EventScr_Tutorial_Exec0'));
    return;
}

/// `EventScr_Prologue_Tutorial1`
Future<void> Prologue_Tutorial1(Scene s) async {
    s.evBitMod('evbit', true, 7);
    s.setKeyIgnore(0);
    s.setSlot(13, 0);
    s.setSlot(1, 327684);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 2268);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 524376);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, Sym('EventScr_Prologue_Tutorial2'));
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, Sym('EventScr_Prologue_Tutorial1'));
    s.slotQueuePushSlot(0x1);
    await s.call(Sym('EventScr_Tutorial_Exec1'));
    s.overrideUnitMenu(65531);
    s.setKeyIgnore(266);
    return;
}

/// `EventScr_Prologue_Tutorial2`
Future<void> Prologue_Tutorial2(Scene s) async {
    s.evBitMod('evbit', true, 7);
    s.enqueueTutCall(1, Sym('EventScr_Prologue_Tutorial3'));
    return;
}

/// `EventScr_Prologue_Tutorial3`
Future<void> Prologue_Tutorial3(Scene s) async {
    s.evBitMod('evbit', true, 7);
    s.setKeyIgnore(0);
    await s.call(Sym('EventScr_Prologue_GiveRapier'));
    s.placeholder('SET_ENDTURN');
    s.evBitMod('flag', true, 183);
    return;
}

/// `EventScr_Prologue_Tutorial4`
Future<void> Prologue_Tutorial4(Scene s) async {
    s.evBitMod('evbit', true, 7);
    s.setKeyIgnore(0);
    s.setSlot(13, 0);
    s.setSlot(1, 1);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 327684);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 2270);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 524376);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 2271);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 524376);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, Sym('EventScr_Prologue_Tutorial5'));
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, Sym('EventScr_Prologue_Tutorial4'));
    s.slotQueuePushSlot(0x1);
    await s.call(Sym('EventScr_Tutorial_Exec0'));
    s.setKeyIgnore(1022);
    return;
}

/// `EventScr_Prologue_Tutorial5`
Future<void> Prologue_Tutorial5(Scene s) async {
    s.evBitMod('evbit', true, 7);
    s.placeholder('ASMC');
    s.overrideUnitMenu(65534);
    s.setKeyIgnore(266);
    s.enqueueTutCall(4, Sym('EventScr_Prologue_Tutorial6'));
    return;
}

/// `EventScr_Prologue_Tutorial6`
Future<void> Prologue_Tutorial6(Scene s) async {
    s.evBitMod('evbit', true, 7);
    s.setKeyIgnore(0);
    s.setTextType(3);
    s.setSlot(11, 3670040);
    await s.textShow(2272);
    await s.textEnd();
    s.textRemoveAll();
    s.setKeyIgnore(266);
    s.enqueueTutCall(5, Sym('EventScr_Prologue_Tutorial7'));
    return;
}

/// `EventScr_Prologue_Tutorial7`
Future<void> Prologue_Tutorial7(Scene s) async {
    s.evBitMod('evbit', true, 7);
    s.setKeyIgnore(256);
    s.setTextType(3);
    s.setSlot(11, 2097164);
    await s.textShow(2273);
    await s.textEnd();
    s.textRemoveAll();
    s.setKeyIgnore(266);
    s.enqueueTutCall(1, Sym('EventScr_Prologue_Tutorial8'));
    return;
}

/// `EventScr_Prologue_Tutorial8`
Future<void> Prologue_Tutorial8(Scene s) async {
    s.setKeyIgnore(0);
    s.displayCursorAtUnit(1);
    await s.stall(60);
    await s.endCursor();
    s.setTextType(0);
    await s.textShow(2258);
    await s.textEnd();
    s.textRemoveAll();
    s.enqueueTutCall(6, Sym('EventScr_Prologue_Tutorial9'));
    s.evBitMod('flag', true, 185);
    s.evBitMod('flag', true, 194);
    s.evBitMod('flag', true, 195);
    s.evBitMod('evbit', true, 7);
    return;
}

/// `EventScr_Prologue_Tutorial9`
Future<void> Prologue_Tutorial9(Scene s) async {
    s.moveUnit('MOVE_CLOSEST', [0, 2, 1289]);
    await s.waitUnitMoving();
    s.setSlot(13, 0);
    s.setSlot(1, 5120);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 4294967295);
    s.slotQueuePushSlot(0x1);
    s.setSlot(11, 393225);
    s.placeholder('FIGHT');
    s.placeholder('_3427');
    s.setSlot(11, 393225);
    s.placeholder('KILL');
    await s.removeUnit(65534, onlyIfDead: true);
    s.evBitMod('flag', true, 7);
    await s.call(Sym('EventScr_Prologue_OneEnemyLeft'));
    s.placeholder('SET_ENDTURN');
    s.evBitMod('evbit', true, 7);
    return;
}

/// `EventScr_Prologue_TutorialA`
Future<void> Prologue_TutorialA(Scene s) async {
    s.evBitMod('evbit', true, 7);
    s.setSlot(13, 0);
    s.setSlot(1, 1);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 393224);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 2277);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 524376);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 2276);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 524376);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, Sym('EventScr_Prologue_TutorialB'));
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, Sym('EventScr_Prologue_TutorialA'));
    s.slotQueuePushSlot(0x1);
    await s.call(Sym('EventScr_Tutorial_Exec0'));
    return;
}

/// `EventScr_Prologue_TutorialB`
Future<void> Prologue_TutorialB(Scene s) async {
    s.evBitMod('evbit', true, 7);
    s.setKeyIgnore(0);
    s.setSlot(13, 0);
    s.setSlot(1, 393224);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 2277);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 524376);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, Sym('EventScr_Prologue_TutorialC'));
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, Sym('EventScr_Prologue_TutorialB'));
    s.slotQueuePushSlot(0x1);
    await s.call(Sym('EventScr_Tutorial_Exec1'));
    s.overrideUnitMenu(65534);
    s.setKeyIgnore(266);
    return;
}

/// `EventScr_Prologue_TutorialC`
Future<void> Prologue_TutorialC(Scene s) async {
    s.evBitMod('evbit', true, 7);
    s.enqueueTutCall(5, Sym('EventScr_Prologue_TutorialD'));
    return;
}

/// `EventScr_Prologue_TutorialD`
Future<void> Prologue_TutorialD(Scene s) async {
    s.evBitMod('evbit', true, 7);
    s.setKeyIgnore(256);
    s.setTextType(3);
    s.setSlot(11, 2097232);
    await s.textShow(2278);
    await s.textEnd();
    s.textRemoveAll();
    s.setKeyIgnore(266);
    s.enqueueTutCall(1, Sym('EventScr_Prologue_TutorialE'));
    s.evBitMod('evbit', true, 7);
    return;
}

/// `EventScr_Prologue_TutorialE`
Future<void> Prologue_TutorialE(Scene s) async {
    s.evBitMod('evbit', true, 7);
    s.setKeyIgnore(0);
    s.setTextType(3);
    s.setSlot(11, 4294967295);
    await s.textShow(2279);
    await s.textEnd();
    s.textRemoveAll();
    s.evBitMod('flag', true, 231);
    s.overrideUnitMenu(0);
    return;
}

/// `EventScr_Ruin_37`
Future<void> Ruin_37(Scene s) async {
    var pc = 0;
    while (true) {
      switch (pc) {
        case 0:
          s.checkSlotValue('turn');
          pc = 1;
          continue;
        case 1:
          s.setSlot(1, 1);
          pc = 2;
          continue;
        case 2:
          if (s.slotInt(12) == s.slotInt(1)) { pc = 10; } else { pc = 3; }
          continue;
        case 3:
          s.checkSlotValue('turn');
          pc = 4;
          continue;
        case 4:
          s.setSlot(1, 10);
          pc = 5;
          continue;
        case 5:
          if (s.slotInt(12) == s.slotInt(1)) { pc = 10; } else { pc = 6; }
          continue;
        case 6:
          s.checkSlotValue('turn');
          pc = 7;
          continue;
        case 7:
          s.setSlot(1, 20);
          pc = 8;
          continue;
        case 8:
          if (s.slotInt(12) == s.slotInt(1)) { pc = 10; } else { pc = 9; }
          continue;
        case 9:
          pc = 19;
          continue;
        case 10:
          pc = 11;
          continue;
        case 11:
          await s.cameraTo(0, 20, centered: false);
          pc = 12;
          continue;
        case 12:
          await s.stall(15);
          pc = 13;
          continue;
        case 13:
          s.sound('se', 190);
          pc = 14;
          continue;
        case 14:
          await s.tileChange(0);
          pc = 15;
          continue;
        case 15:
          await s.cameraTo(12, 12, centered: true);
          pc = 16;
          continue;
        case 16:
          await s.stall(15);
          pc = 17;
          continue;
        case 17:
          s.sound('se', 190);
          pc = 18;
          continue;
        case 18:
          await s.tileChange(7);
          pc = 19;
          continue;
        case 19:
          pc = 20;
          continue;
        case 20:
          s.evBitMod('evbit', true, 7);
          pc = 21;
          continue;
        case 21:
          return;
        default:
          return;
      }
    }
}

/// `EventScr_Ruin_38`
Future<void> Ruin_38(Scene s) async {
    var pc = 0;
    while (true) {
      switch (pc) {
        case 0:
          s.checkSlotValue('turn');
          pc = 1;
          continue;
        case 1:
          s.setSlot(1, 6);
          pc = 2;
          continue;
        case 2:
          if (s.slotInt(12) == s.slotInt(1)) { pc = 7; } else { pc = 3; }
          continue;
        case 3:
          s.checkSlotValue('turn');
          pc = 4;
          continue;
        case 4:
          s.setSlot(1, 15);
          pc = 5;
          continue;
        case 5:
          if (s.slotInt(12) == s.slotInt(1)) { pc = 7; } else { pc = 6; }
          continue;
        case 6:
          pc = 16;
          continue;
        case 7:
          pc = 8;
          continue;
        case 8:
          await s.cameraTo(0, 20, centered: false);
          pc = 9;
          continue;
        case 9:
          await s.stall(15);
          pc = 10;
          continue;
        case 10:
          s.sound('se', 189);
          pc = 11;
          continue;
        case 11:
          await s.tileRevert(0);
          pc = 12;
          continue;
        case 12:
          await s.cameraTo(12, 12, centered: true);
          pc = 13;
          continue;
        case 13:
          await s.stall(15);
          pc = 14;
          continue;
        case 14:
          s.sound('se', 189);
          pc = 15;
          continue;
        case 15:
          await s.tileRevert(7);
          pc = 16;
          continue;
        case 16:
          pc = 17;
          continue;
        case 17:
          s.evBitMod('evbit', true, 7);
          pc = 18;
          continue;
        case 18:
          return;
        default:
          return;
      }
    }
}

/// `EventScr_Ruin_39`
Future<void> Ruin_39(Scene s) async {
    var pc = 0;
    while (true) {
      switch (pc) {
        case 0:
          s.checkSlotValue('turn');
          pc = 1;
          continue;
        case 1:
          s.setSlot(1, 2);
          pc = 2;
          continue;
        case 2:
          if (s.slotInt(12) == s.slotInt(1)) { pc = 13; } else { pc = 3; }
          continue;
        case 3:
          s.checkSlotValue('turn');
          pc = 4;
          continue;
        case 4:
          s.setSlot(1, 8);
          pc = 5;
          continue;
        case 5:
          if (s.slotInt(12) == s.slotInt(1)) { pc = 13; } else { pc = 6; }
          continue;
        case 6:
          s.checkSlotValue('turn');
          pc = 7;
          continue;
        case 7:
          s.setSlot(1, 14);
          pc = 8;
          continue;
        case 8:
          if (s.slotInt(12) == s.slotInt(1)) { pc = 13; } else { pc = 9; }
          continue;
        case 9:
          s.checkSlotValue('turn');
          pc = 10;
          continue;
        case 10:
          s.setSlot(1, 20);
          pc = 11;
          continue;
        case 11:
          if (s.slotInt(12) == s.slotInt(1)) { pc = 13; } else { pc = 12; }
          continue;
        case 12:
          pc = 26;
          continue;
        case 13:
          pc = 14;
          continue;
        case 14:
          await s.cameraTo(7, 10, centered: true);
          pc = 15;
          continue;
        case 15:
          await s.stall(15);
          pc = 16;
          continue;
        case 16:
          s.sound('se', 190);
          pc = 17;
          continue;
        case 17:
          await s.tileChange(1);
          pc = 18;
          continue;
        case 18:
          await s.cameraTo(10, 10, centered: true);
          pc = 19;
          continue;
        case 19:
          await s.stall(15);
          pc = 20;
          continue;
        case 20:
          s.sound('se', 190);
          pc = 21;
          continue;
        case 21:
          await s.tileChange(5);
          pc = 22;
          continue;
        case 22:
          await s.cameraTo(19, 20, centered: false);
          pc = 23;
          continue;
        case 23:
          await s.stall(15);
          pc = 24;
          continue;
        case 24:
          s.sound('se', 190);
          pc = 25;
          continue;
        case 25:
          await s.tileChange(8);
          pc = 26;
          continue;
        case 26:
          pc = 27;
          continue;
        case 27:
          s.evBitMod('evbit', true, 7);
          pc = 28;
          continue;
        case 28:
          return;
        default:
          return;
      }
    }
}

/// `EventScr_Ruin_40`
Future<void> Ruin_40(Scene s) async {
    var pc = 0;
    while (true) {
      switch (pc) {
        case 0:
          s.checkSlotValue('turn');
          pc = 1;
          continue;
        case 1:
          s.setSlot(1, 5);
          pc = 2;
          continue;
        case 2:
          if (s.slotInt(12) == s.slotInt(1)) { pc = 10; } else { pc = 3; }
          continue;
        case 3:
          s.checkSlotValue('turn');
          pc = 4;
          continue;
        case 4:
          s.setSlot(1, 11);
          pc = 5;
          continue;
        case 5:
          if (s.slotInt(12) == s.slotInt(1)) { pc = 10; } else { pc = 6; }
          continue;
        case 6:
          s.checkSlotValue('turn');
          pc = 7;
          continue;
        case 7:
          s.setSlot(1, 17);
          pc = 8;
          continue;
        case 8:
          if (s.slotInt(12) == s.slotInt(1)) { pc = 10; } else { pc = 9; }
          continue;
        case 9:
          pc = 23;
          continue;
        case 10:
          pc = 11;
          continue;
        case 11:
          await s.cameraTo(7, 10, centered: true);
          pc = 12;
          continue;
        case 12:
          await s.stall(15);
          pc = 13;
          continue;
        case 13:
          s.sound('se', 189);
          pc = 14;
          continue;
        case 14:
          await s.tileRevert(1);
          pc = 15;
          continue;
        case 15:
          await s.cameraTo(10, 10, centered: true);
          pc = 16;
          continue;
        case 16:
          await s.stall(15);
          pc = 17;
          continue;
        case 17:
          s.sound('se', 189);
          pc = 18;
          continue;
        case 18:
          await s.tileRevert(5);
          pc = 19;
          continue;
        case 19:
          await s.cameraTo(19, 20, centered: false);
          pc = 20;
          continue;
        case 20:
          await s.stall(15);
          pc = 21;
          continue;
        case 21:
          s.sound('se', 189);
          pc = 22;
          continue;
        case 22:
          await s.tileRevert(8);
          pc = 23;
          continue;
        case 23:
          pc = 24;
          continue;
        case 24:
          s.evBitMod('evbit', true, 7);
          pc = 25;
          continue;
        case 25:
          return;
        default:
          return;
      }
    }
}

/// `EventScr_Ruin_41`
Future<void> Ruin_41(Scene s) async {
    var pc = 0;
    while (true) {
      switch (pc) {
        case 0:
          s.checkSlotValue('turn');
          pc = 1;
          continue;
        case 1:
          s.setSlot(1, 5);
          pc = 2;
          continue;
        case 2:
          if (s.slotInt(12) == s.slotInt(1)) { pc = 10; } else { pc = 3; }
          continue;
        case 3:
          s.checkSlotValue('turn');
          pc = 4;
          continue;
        case 4:
          s.setSlot(1, 13);
          pc = 5;
          continue;
        case 5:
          if (s.slotInt(12) == s.slotInt(1)) { pc = 10; } else { pc = 6; }
          continue;
        case 6:
          s.checkSlotValue('turn');
          pc = 7;
          continue;
        case 7:
          s.setSlot(1, 20);
          pc = 8;
          continue;
        case 8:
          if (s.slotInt(12) == s.slotInt(1)) { pc = 10; } else { pc = 9; }
          continue;
        case 9:
          pc = 19;
          continue;
        case 10:
          pc = 11;
          continue;
        case 11:
          await s.cameraTo(0, 0, centered: false);
          pc = 12;
          continue;
        case 12:
          await s.stall(15);
          pc = 13;
          continue;
        case 13:
          s.sound('se', 190);
          pc = 14;
          continue;
        case 14:
          await s.tileChange(2);
          pc = 15;
          continue;
        case 15:
          await s.cameraTo(19, 20, centered: false);
          pc = 16;
          continue;
        case 16:
          await s.stall(15);
          pc = 17;
          continue;
        case 17:
          s.sound('se', 190);
          pc = 18;
          continue;
        case 18:
          await s.tileChange(9);
          pc = 19;
          continue;
        case 19:
          pc = 20;
          continue;
        case 20:
          s.evBitMod('evbit', true, 7);
          pc = 21;
          continue;
        case 21:
          return;
        default:
          return;
      }
    }
}

/// `EventScr_Ruin_42`
Future<void> Ruin_42(Scene s) async {
    var pc = 0;
    while (true) {
      switch (pc) {
        case 0:
          s.checkSlotValue('turn');
          pc = 1;
          continue;
        case 1:
          s.setSlot(1, 9);
          pc = 2;
          continue;
        case 2:
          if (s.slotInt(12) == s.slotInt(1)) { pc = 7; } else { pc = 3; }
          continue;
        case 3:
          s.checkSlotValue('turn');
          pc = 4;
          continue;
        case 4:
          s.setSlot(1, 17);
          pc = 5;
          continue;
        case 5:
          if (s.slotInt(12) == s.slotInt(1)) { pc = 7; } else { pc = 6; }
          continue;
        case 6:
          pc = 16;
          continue;
        case 7:
          pc = 8;
          continue;
        case 8:
          await s.cameraTo(0, 0, centered: false);
          pc = 9;
          continue;
        case 9:
          await s.stall(15);
          pc = 10;
          continue;
        case 10:
          s.sound('se', 189);
          pc = 11;
          continue;
        case 11:
          await s.tileRevert(2);
          pc = 12;
          continue;
        case 12:
          await s.cameraTo(19, 20, centered: false);
          pc = 13;
          continue;
        case 13:
          await s.stall(15);
          pc = 14;
          continue;
        case 14:
          s.sound('se', 189);
          pc = 15;
          continue;
        case 15:
          await s.tileRevert(9);
          pc = 16;
          continue;
        case 16:
          pc = 17;
          continue;
        case 17:
          s.evBitMod('evbit', true, 7);
          pc = 18;
          continue;
        case 18:
          return;
        default:
          return;
      }
    }
}

/// `EventScr_Ruin_45`
Future<void> Ruin_45(Scene s) async {
    var pc = 0;
    while (true) {
      switch (pc) {
        case 0:
          s.checkSlotValue('turn');
          pc = 1;
          continue;
        case 1:
          s.setSlot(1, 1);
          pc = 2;
          continue;
        case 2:
          if (s.slotInt(12) == s.slotInt(1)) { pc = 19; } else { pc = 3; }
          continue;
        case 3:
          s.checkSlotValue('turn');
          pc = 4;
          continue;
        case 4:
          s.setSlot(1, 5);
          pc = 5;
          continue;
        case 5:
          if (s.slotInt(12) == s.slotInt(1)) { pc = 19; } else { pc = 6; }
          continue;
        case 6:
          s.checkSlotValue('turn');
          pc = 7;
          continue;
        case 7:
          s.setSlot(1, 9);
          pc = 8;
          continue;
        case 8:
          if (s.slotInt(12) == s.slotInt(1)) { pc = 19; } else { pc = 9; }
          continue;
        case 9:
          s.checkSlotValue('turn');
          pc = 10;
          continue;
        case 10:
          s.setSlot(1, 13);
          pc = 11;
          continue;
        case 11:
          if (s.slotInt(12) == s.slotInt(1)) { pc = 19; } else { pc = 12; }
          continue;
        case 12:
          s.checkSlotValue('turn');
          pc = 13;
          continue;
        case 13:
          s.setSlot(1, 17);
          pc = 14;
          continue;
        case 14:
          if (s.slotInt(12) == s.slotInt(1)) { pc = 19; } else { pc = 15; }
          continue;
        case 15:
          s.checkSlotValue('turn');
          pc = 16;
          continue;
        case 16:
          s.setSlot(1, 20);
          pc = 17;
          continue;
        case 17:
          if (s.slotInt(12) == s.slotInt(1)) { pc = 19; } else { pc = 18; }
          continue;
        case 18:
          pc = 28;
          continue;
        case 19:
          pc = 20;
          continue;
        case 20:
          await s.cameraTo(10, 15, centered: true);
          pc = 21;
          continue;
        case 21:
          await s.stall(15);
          pc = 22;
          continue;
        case 22:
          s.sound('se', 190);
          pc = 23;
          continue;
        case 23:
          await s.tileChange(4);
          pc = 24;
          continue;
        case 24:
          await s.cameraTo(12, 6, centered: true);
          pc = 25;
          continue;
        case 25:
          await s.stall(15);
          pc = 26;
          continue;
        case 26:
          s.sound('se', 190);
          pc = 27;
          continue;
        case 27:
          await s.tileChange(10);
          pc = 28;
          continue;
        case 28:
          pc = 29;
          continue;
        case 29:
          s.evBitMod('evbit', true, 7);
          pc = 30;
          continue;
        case 30:
          return;
        default:
          return;
      }
    }
}

/// `EventScr_Ruin_47`
Future<void> Ruin_47(Scene s) async {
    var pc = 0;
    while (true) {
      switch (pc) {
        case 0:
          s.checkSlotValue('turn');
          pc = 1;
          continue;
        case 1:
          s.setSlot(1, 6);
          pc = 2;
          continue;
        case 2:
          if (s.slotInt(12) == s.slotInt(1)) { pc = 13; } else { pc = 3; }
          continue;
        case 3:
          s.checkSlotValue('turn');
          pc = 4;
          continue;
        case 4:
          s.setSlot(1, 12);
          pc = 5;
          continue;
        case 5:
          if (s.slotInt(12) == s.slotInt(1)) { pc = 13; } else { pc = 6; }
          continue;
        case 6:
          s.checkSlotValue('turn');
          pc = 7;
          continue;
        case 7:
          s.setSlot(1, 18);
          pc = 8;
          continue;
        case 8:
          if (s.slotInt(12) == s.slotInt(1)) { pc = 13; } else { pc = 9; }
          continue;
        case 9:
          s.checkSlotValue('turn');
          pc = 10;
          continue;
        case 10:
          s.setSlot(1, 20);
          pc = 11;
          continue;
        case 11:
          if (s.slotInt(12) == s.slotInt(1)) { pc = 13; } else { pc = 12; }
          continue;
        case 12:
          pc = 18;
          continue;
        case 13:
          pc = 14;
          continue;
        case 14:
          await s.cameraTo(0, 20, centered: false);
          pc = 15;
          continue;
        case 15:
          await s.stall(15);
          pc = 16;
          continue;
        case 16:
          s.sound('se', 190);
          pc = 17;
          continue;
        case 17:
          await s.tileChange(11);
          pc = 18;
          continue;
        case 18:
          pc = 19;
          continue;
        case 19:
          s.evBitMod('evbit', true, 7);
          pc = 20;
          continue;
        case 20:
          return;
        default:
          return;
      }
    }
}

/// `EventScr_Ruin_48`
Future<void> Ruin_48(Scene s) async {
    var pc = 0;
    while (true) {
      switch (pc) {
        case 0:
          s.checkSlotValue('turn');
          pc = 1;
          continue;
        case 1:
          s.setSlot(1, 7);
          pc = 2;
          continue;
        case 2:
          if (s.slotInt(12) == s.slotInt(1)) { pc = 10; } else { pc = 3; }
          continue;
        case 3:
          s.checkSlotValue('turn');
          pc = 4;
          continue;
        case 4:
          s.setSlot(1, 13);
          pc = 5;
          continue;
        case 5:
          if (s.slotInt(12) == s.slotInt(1)) { pc = 10; } else { pc = 6; }
          continue;
        case 6:
          s.checkSlotValue('turn');
          pc = 7;
          continue;
        case 7:
          s.setSlot(1, 19);
          pc = 8;
          continue;
        case 8:
          if (s.slotInt(12) == s.slotInt(1)) { pc = 10; } else { pc = 9; }
          continue;
        case 9:
          pc = 15;
          continue;
        case 10:
          pc = 11;
          continue;
        case 11:
          await s.cameraTo(0, 20, centered: false);
          pc = 12;
          continue;
        case 12:
          await s.stall(15);
          pc = 13;
          continue;
        case 13:
          s.sound('se', 189);
          pc = 14;
          continue;
        case 14:
          await s.tileRevert(11);
          pc = 15;
          continue;
        case 15:
          pc = 16;
          continue;
        case 16:
          s.evBitMod('evbit', true, 7);
          pc = 17;
          continue;
        case 17:
          return;
        default:
          return;
      }
    }
}

/// `EventScr_Ruin_54`
Future<void> Ruin_54(Scene s) async {
    var pc = 0;
    while (true) {
      switch (pc) {
        case 0:
          await s.fade(FadeDirection.toBlack, 64);
          pc = 1;
          continue;
        case 1:
          s.checkSlot('evbit', 2);
          pc = 2;
          continue;
        case 2:
          if (s.slotInt(12) != s.slotInt(0)) { pc = 9; } else { pc = 3; }
          continue;
        case 3:
          s.setSlot(11, 0);
          pc = 4;
          continue;
        case 4:
          await s.loadMap(0);
          pc = 5;
          continue;
        case 5:
          await s.fade(FadeDirection.fromBlack, 64);
          pc = 6;
          continue;
        case 6:
          await s.popupText(232, 8, 8);
          pc = 7;
          continue;
        case 7:
          await s.stall(65535, cancellable: true);
          pc = 8;
          continue;
        case 8:
          await s.fade(FadeDirection.toBlack, 64);
          pc = 9;
          continue;
        case 9:
          pc = 10;
          continue;
        case 10:
          s.checkSlot('evbit', 2);
          pc = 11;
          continue;
        case 11:
          if (s.slotInt(12) != s.slotInt(0)) { pc = 18; } else { pc = 12; }
          continue;
        case 12:
          s.setSlot(11, 0);
          pc = 13;
          continue;
        case 13:
          await s.loadMap(1);
          pc = 14;
          continue;
        case 14:
          await s.fade(FadeDirection.fromBlack, 64);
          pc = 15;
          continue;
        case 15:
          await s.popupText(233, 8, 8);
          pc = 16;
          continue;
        case 16:
          await s.stall(65535, cancellable: true);
          pc = 17;
          continue;
        case 17:
          await s.fade(FadeDirection.toBlack, 64);
          pc = 18;
          continue;
        case 18:
          pc = 19;
          continue;
        case 19:
          s.checkSlot('evbit', 2);
          pc = 20;
          continue;
        case 20:
          if (s.slotInt(12) != s.slotInt(0)) { pc = 27; } else { pc = 21; }
          continue;
        case 21:
          s.setSlot(11, 0);
          pc = 22;
          continue;
        case 22:
          await s.loadMap(2);
          pc = 23;
          continue;
        case 23:
          await s.fade(FadeDirection.fromBlack, 64);
          pc = 24;
          continue;
        case 24:
          await s.popupText(234, 8, 8);
          pc = 25;
          continue;
        case 25:
          await s.stall(65535, cancellable: true);
          pc = 26;
          continue;
        case 26:
          await s.fade(FadeDirection.toBlack, 64);
          pc = 27;
          continue;
        case 27:
          pc = 28;
          continue;
        case 28:
          s.checkSlot('evbit', 2);
          pc = 29;
          continue;
        case 29:
          if (s.slotInt(12) != s.slotInt(0)) { pc = 36; } else { pc = 30; }
          continue;
        case 30:
          s.setSlot(11, 0);
          pc = 31;
          continue;
        case 31:
          await s.loadMap(3);
          pc = 32;
          continue;
        case 32:
          await s.fade(FadeDirection.fromBlack, 64);
          pc = 33;
          continue;
        case 33:
          await s.popupText(235, 8, 8);
          pc = 34;
          continue;
        case 34:
          await s.stall(65535, cancellable: true);
          pc = 35;
          continue;
        case 35:
          await s.fade(FadeDirection.toBlack, 64);
          pc = 36;
          continue;
        case 36:
          pc = 37;
          continue;
        case 37:
          s.checkSlot('evbit', 2);
          pc = 38;
          continue;
        case 38:
          if (s.slotInt(12) != s.slotInt(0)) { pc = 45; } else { pc = 39; }
          continue;
        case 39:
          s.setSlot(11, 0);
          pc = 40;
          continue;
        case 40:
          await s.loadMap(4);
          pc = 41;
          continue;
        case 41:
          await s.fade(FadeDirection.fromBlack, 64);
          pc = 42;
          continue;
        case 42:
          await s.popupText(236, 8, 8);
          pc = 43;
          continue;
        case 43:
          await s.stall(65535, cancellable: true);
          pc = 44;
          continue;
        case 44:
          await s.fade(FadeDirection.toBlack, 64);
          pc = 45;
          continue;
        case 45:
          pc = 46;
          continue;
        case 46:
          s.checkSlot('evbit', 2);
          pc = 47;
          continue;
        case 47:
          if (s.slotInt(12) != s.slotInt(0)) { pc = 54; } else { pc = 48; }
          continue;
        case 48:
          s.setSlot(11, 0);
          pc = 49;
          continue;
        case 49:
          await s.loadMap(6);
          pc = 50;
          continue;
        case 50:
          await s.fade(FadeDirection.fromBlack, 64);
          pc = 51;
          continue;
        case 51:
          await s.popupText(238, 8, 8);
          pc = 52;
          continue;
        case 52:
          await s.stall(65535, cancellable: true);
          pc = 53;
          continue;
        case 53:
          await s.fade(FadeDirection.toBlack, 64);
          pc = 54;
          continue;
        case 54:
          pc = 55;
          continue;
        case 55:
          s.checkSlot('evbit', 2);
          pc = 56;
          continue;
        case 56:
          if (s.slotInt(12) != s.slotInt(0)) { pc = 63; } else { pc = 57; }
          continue;
        case 57:
          s.setSlot(11, 0);
          pc = 58;
          continue;
        case 58:
          await s.loadMap(7);
          pc = 59;
          continue;
        case 59:
          await s.fade(FadeDirection.fromBlack, 64);
          pc = 60;
          continue;
        case 60:
          await s.popupText(239, 8, 8);
          pc = 61;
          continue;
        case 61:
          await s.stall(65535, cancellable: true);
          pc = 62;
          continue;
        case 62:
          await s.fade(FadeDirection.toBlack, 64);
          pc = 63;
          continue;
        case 63:
          pc = 64;
          continue;
        case 64:
          s.checkSlot('evbit', 2);
          pc = 65;
          continue;
        case 65:
          if (s.slotInt(12) != s.slotInt(0)) { pc = 72; } else { pc = 66; }
          continue;
        case 66:
          s.setSlot(11, 0);
          pc = 67;
          continue;
        case 67:
          await s.loadMap(8);
          pc = 68;
          continue;
        case 68:
          await s.fade(FadeDirection.fromBlack, 64);
          pc = 69;
          continue;
        case 69:
          await s.popupText(240, 8, 8);
          pc = 70;
          continue;
        case 70:
          await s.stall(65535, cancellable: true);
          pc = 71;
          continue;
        case 71:
          await s.fade(FadeDirection.toBlack, 64);
          pc = 72;
          continue;
        case 72:
          pc = 73;
          continue;
        case 73:
          s.checkSlot('evbit', 2);
          pc = 74;
          continue;
        case 74:
          if (s.slotInt(12) != s.slotInt(0)) { pc = 81; } else { pc = 75; }
          continue;
        case 75:
          s.setSlot(11, 0);
          pc = 76;
          continue;
        case 76:
          await s.loadMap(9);
          pc = 77;
          continue;
        case 77:
          await s.fade(FadeDirection.fromBlack, 64);
          pc = 78;
          continue;
        case 78:
          await s.popupText(241, 8, 8);
          pc = 79;
          continue;
        case 79:
          await s.stall(65535, cancellable: true);
          pc = 80;
          continue;
        case 80:
          await s.fade(FadeDirection.toBlack, 64);
          pc = 81;
          continue;
        case 81:
          pc = 82;
          continue;
        case 82:
          s.checkSlot('evbit', 2);
          pc = 83;
          continue;
        case 83:
          if (s.slotInt(12) != s.slotInt(0)) { pc = 90; } else { pc = 84; }
          continue;
        case 84:
          s.setSlot(11, 0);
          pc = 85;
          continue;
        case 85:
          await s.loadMap(10);
          pc = 86;
          continue;
        case 86:
          await s.fade(FadeDirection.fromBlack, 64);
          pc = 87;
          continue;
        case 87:
          await s.popupText(242, 8, 8);
          pc = 88;
          continue;
        case 88:
          await s.stall(65535, cancellable: true);
          pc = 89;
          continue;
        case 89:
          await s.fade(FadeDirection.toBlack, 64);
          pc = 90;
          continue;
        case 90:
          pc = 91;
          continue;
        case 91:
          s.checkSlot('evbit', 2);
          pc = 92;
          continue;
        case 92:
          if (s.slotInt(12) != s.slotInt(0)) { pc = 99; } else { pc = 93; }
          continue;
        case 93:
          s.setSlot(11, 0);
          pc = 94;
          continue;
        case 94:
          await s.loadMap(11);
          pc = 95;
          continue;
        case 95:
          await s.fade(FadeDirection.fromBlack, 64);
          pc = 96;
          continue;
        case 96:
          await s.popupText(243, 8, 8);
          pc = 97;
          continue;
        case 97:
          await s.stall(65535, cancellable: true);
          pc = 98;
          continue;
        case 98:
          await s.fade(FadeDirection.toBlack, 64);
          pc = 99;
          continue;
        case 99:
          pc = 100;
          continue;
        case 100:
          s.checkSlot('evbit', 2);
          pc = 101;
          continue;
        case 101:
          if (s.slotInt(12) != s.slotInt(0)) { pc = 108; } else { pc = 102; }
          continue;
        case 102:
          s.setSlot(11, 0);
          pc = 103;
          continue;
        case 103:
          await s.loadMap(12);
          pc = 104;
          continue;
        case 104:
          await s.fade(FadeDirection.fromBlack, 64);
          pc = 105;
          continue;
        case 105:
          await s.popupText(244, 8, 8);
          pc = 106;
          continue;
        case 106:
          await s.stall(65535, cancellable: true);
          pc = 107;
          continue;
        case 107:
          await s.fade(FadeDirection.toBlack, 64);
          pc = 108;
          continue;
        case 108:
          pc = 109;
          continue;
        case 109:
          s.checkSlot('evbit', 2);
          pc = 110;
          continue;
        case 110:
          if (s.slotInt(12) != s.slotInt(0)) { pc = 117; } else { pc = 111; }
          continue;
        case 111:
          s.setSlot(11, 0);
          pc = 112;
          continue;
        case 112:
          await s.loadMap(13);
          pc = 113;
          continue;
        case 113:
          await s.fade(FadeDirection.fromBlack, 64);
          pc = 114;
          continue;
        case 114:
          await s.popupText(245, 8, 8);
          pc = 115;
          continue;
        case 115:
          await s.stall(65535, cancellable: true);
          pc = 116;
          continue;
        case 116:
          await s.fade(FadeDirection.toBlack, 64);
          pc = 117;
          continue;
        case 117:
          pc = 118;
          continue;
        case 118:
          s.checkSlot('evbit', 2);
          pc = 119;
          continue;
        case 119:
          if (s.slotInt(12) != s.slotInt(0)) { pc = 126; } else { pc = 120; }
          continue;
        case 120:
          s.setSlot(11, 0);
          pc = 121;
          continue;
        case 121:
          await s.loadMap(14);
          pc = 122;
          continue;
        case 122:
          await s.fade(FadeDirection.fromBlack, 64);
          pc = 123;
          continue;
        case 123:
          await s.popupText(246, 8, 8);
          pc = 124;
          continue;
        case 124:
          await s.stall(65535, cancellable: true);
          pc = 125;
          continue;
        case 125:
          await s.fade(FadeDirection.toBlack, 64);
          pc = 126;
          continue;
        case 126:
          pc = 127;
          continue;
        case 127:
          s.checkSlot('evbit', 2);
          pc = 128;
          continue;
        case 128:
          if (s.slotInt(12) != s.slotInt(0)) { pc = 135; } else { pc = 129; }
          continue;
        case 129:
          s.setSlot(11, 0);
          pc = 130;
          continue;
        case 130:
          await s.loadMap(15);
          pc = 131;
          continue;
        case 131:
          await s.fade(FadeDirection.fromBlack, 64);
          pc = 132;
          continue;
        case 132:
          await s.popupText(247, 8, 8);
          pc = 133;
          continue;
        case 133:
          await s.stall(65535, cancellable: true);
          pc = 134;
          continue;
        case 134:
          await s.fade(FadeDirection.toBlack, 64);
          pc = 135;
          continue;
        case 135:
          pc = 136;
          continue;
        case 136:
          s.checkSlot('evbit', 2);
          pc = 137;
          continue;
        case 137:
          if (s.slotInt(12) != s.slotInt(0)) { pc = 144; } else { pc = 138; }
          continue;
        case 138:
          s.setSlot(11, 0);
          pc = 139;
          continue;
        case 139:
          await s.loadMap(16);
          pc = 140;
          continue;
        case 140:
          await s.fade(FadeDirection.fromBlack, 64);
          pc = 141;
          continue;
        case 141:
          await s.popupText(248, 8, 8);
          pc = 142;
          continue;
        case 142:
          await s.stall(65535, cancellable: true);
          pc = 143;
          continue;
        case 143:
          await s.fade(FadeDirection.toBlack, 64);
          pc = 144;
          continue;
        case 144:
          pc = 145;
          continue;
        case 145:
          s.checkSlot('evbit', 2);
          pc = 146;
          continue;
        case 146:
          if (s.slotInt(12) != s.slotInt(0)) { pc = 153; } else { pc = 147; }
          continue;
        case 147:
          s.setSlot(11, 0);
          pc = 148;
          continue;
        case 148:
          await s.loadMap(17);
          pc = 149;
          continue;
        case 149:
          await s.fade(FadeDirection.fromBlack, 64);
          pc = 150;
          continue;
        case 150:
          await s.popupText(249, 8, 8);
          pc = 151;
          continue;
        case 151:
          await s.stall(65535, cancellable: true);
          pc = 152;
          continue;
        case 152:
          await s.fade(FadeDirection.toBlack, 64);
          pc = 153;
          continue;
        case 153:
          pc = 154;
          continue;
        case 154:
          s.checkSlot('evbit', 2);
          pc = 155;
          continue;
        case 155:
          if (s.slotInt(12) != s.slotInt(0)) { pc = 162; } else { pc = 156; }
          continue;
        case 156:
          s.setSlot(11, 0);
          pc = 157;
          continue;
        case 157:
          await s.loadMap(18);
          pc = 158;
          continue;
        case 158:
          await s.fade(FadeDirection.fromBlack, 64);
          pc = 159;
          continue;
        case 159:
          await s.popupText(250, 8, 8);
          pc = 160;
          continue;
        case 160:
          await s.stall(65535, cancellable: true);
          pc = 161;
          continue;
        case 161:
          await s.fade(FadeDirection.toBlack, 64);
          pc = 162;
          continue;
        case 162:
          pc = 163;
          continue;
        case 163:
          s.checkSlot('evbit', 2);
          pc = 164;
          continue;
        case 164:
          if (s.slotInt(12) != s.slotInt(0)) { pc = 171; } else { pc = 165; }
          continue;
        case 165:
          s.setSlot(11, 0);
          pc = 166;
          continue;
        case 166:
          await s.loadMap(19);
          pc = 167;
          continue;
        case 167:
          await s.fade(FadeDirection.fromBlack, 64);
          pc = 168;
          continue;
        case 168:
          await s.popupText(251, 8, 8);
          pc = 169;
          continue;
        case 169:
          await s.stall(65535, cancellable: true);
          pc = 170;
          continue;
        case 170:
          await s.fade(FadeDirection.toBlack, 64);
          pc = 171;
          continue;
        case 171:
          pc = 172;
          continue;
        case 172:
          s.checkSlot('evbit', 2);
          pc = 173;
          continue;
        case 173:
          if (s.slotInt(12) != s.slotInt(0)) { pc = 180; } else { pc = 174; }
          continue;
        case 174:
          s.setSlot(11, 0);
          pc = 175;
          continue;
        case 175:
          await s.loadMap(20);
          pc = 176;
          continue;
        case 176:
          await s.fade(FadeDirection.fromBlack, 64);
          pc = 177;
          continue;
        case 177:
          await s.popupText(252, 8, 8);
          pc = 178;
          continue;
        case 178:
          await s.stall(65535, cancellable: true);
          pc = 179;
          continue;
        case 179:
          await s.fade(FadeDirection.toBlack, 64);
          pc = 180;
          continue;
        case 180:
          pc = 181;
          continue;
        case 181:
          s.checkSlot('evbit', 2);
          pc = 182;
          continue;
        case 182:
          if (s.slotInt(12) != s.slotInt(0)) { pc = 189; } else { pc = 183; }
          continue;
        case 183:
          s.setSlot(11, 0);
          pc = 184;
          continue;
        case 184:
          await s.loadMap(21);
          pc = 185;
          continue;
        case 185:
          await s.fade(FadeDirection.fromBlack, 64);
          pc = 186;
          continue;
        case 186:
          await s.popupText(253, 8, 8);
          pc = 187;
          continue;
        case 187:
          await s.stall(65535, cancellable: true);
          pc = 188;
          continue;
        case 188:
          await s.fade(FadeDirection.toBlack, 64);
          pc = 189;
          continue;
        case 189:
          pc = 190;
          continue;
        case 190:
          s.checkSlot('evbit', 2);
          pc = 191;
          continue;
        case 191:
          if (s.slotInt(12) != s.slotInt(0)) { pc = 198; } else { pc = 192; }
          continue;
        case 192:
          s.setSlot(11, 0);
          pc = 193;
          continue;
        case 193:
          await s.loadMap(23);
          pc = 194;
          continue;
        case 194:
          await s.fade(FadeDirection.fromBlack, 64);
          pc = 195;
          continue;
        case 195:
          await s.popupText(255, 8, 8);
          pc = 196;
          continue;
        case 196:
          await s.stall(65535, cancellable: true);
          pc = 197;
          continue;
        case 197:
          await s.fade(FadeDirection.toBlack, 64);
          pc = 198;
          continue;
        case 198:
          pc = 199;
          continue;
        case 199:
          s.checkSlot('evbit', 2);
          pc = 200;
          continue;
        case 200:
          if (s.slotInt(12) != s.slotInt(0)) { pc = 207; } else { pc = 201; }
          continue;
        case 201:
          s.setSlot(11, 0);
          pc = 202;
          continue;
        case 202:
          await s.loadMap(24);
          pc = 203;
          continue;
        case 203:
          await s.fade(FadeDirection.fromBlack, 64);
          pc = 204;
          continue;
        case 204:
          await s.popupText(256, 8, 8);
          pc = 205;
          continue;
        case 205:
          await s.stall(65535, cancellable: true);
          pc = 206;
          continue;
        case 206:
          await s.fade(FadeDirection.toBlack, 64);
          pc = 207;
          continue;
        case 207:
          pc = 208;
          continue;
        case 208:
          s.checkSlot('evbit', 2);
          pc = 209;
          continue;
        case 209:
          if (s.slotInt(12) != s.slotInt(0)) { pc = 216; } else { pc = 210; }
          continue;
        case 210:
          s.setSlot(11, 0);
          pc = 211;
          continue;
        case 211:
          await s.loadMap(25);
          pc = 212;
          continue;
        case 212:
          await s.fade(FadeDirection.fromBlack, 64);
          pc = 213;
          continue;
        case 213:
          await s.popupText(257, 8, 8);
          pc = 214;
          continue;
        case 214:
          await s.stall(65535, cancellable: true);
          pc = 215;
          continue;
        case 215:
          await s.fade(FadeDirection.toBlack, 64);
          pc = 216;
          continue;
        case 216:
          pc = 217;
          continue;
        case 217:
          s.checkSlot('evbit', 2);
          pc = 218;
          continue;
        case 218:
          if (s.slotInt(12) != s.slotInt(0)) { pc = 225; } else { pc = 219; }
          continue;
        case 219:
          s.setSlot(11, 0);
          pc = 220;
          continue;
        case 220:
          await s.loadMap(26);
          pc = 221;
          continue;
        case 221:
          await s.fade(FadeDirection.fromBlack, 64);
          pc = 222;
          continue;
        case 222:
          await s.popupText(258, 8, 8);
          pc = 223;
          continue;
        case 223:
          await s.stall(65535, cancellable: true);
          pc = 224;
          continue;
        case 224:
          await s.fade(FadeDirection.toBlack, 64);
          pc = 225;
          continue;
        case 225:
          pc = 226;
          continue;
        case 226:
          s.checkSlot('evbit', 2);
          pc = 227;
          continue;
        case 227:
          if (s.slotInt(12) != s.slotInt(0)) { pc = 234; } else { pc = 228; }
          continue;
        case 228:
          s.setSlot(11, 0);
          pc = 229;
          continue;
        case 229:
          await s.loadMap(27);
          pc = 230;
          continue;
        case 230:
          await s.fade(FadeDirection.fromBlack, 64);
          pc = 231;
          continue;
        case 231:
          await s.popupText(259, 8, 8);
          pc = 232;
          continue;
        case 232:
          await s.stall(65535, cancellable: true);
          pc = 233;
          continue;
        case 233:
          await s.fade(FadeDirection.toBlack, 64);
          pc = 234;
          continue;
        case 234:
          pc = 235;
          continue;
        case 235:
          s.checkSlot('evbit', 2);
          pc = 236;
          continue;
        case 236:
          if (s.slotInt(12) != s.slotInt(0)) { pc = 243; } else { pc = 237; }
          continue;
        case 237:
          s.setSlot(11, 0);
          pc = 238;
          continue;
        case 238:
          await s.loadMap(28);
          pc = 239;
          continue;
        case 239:
          await s.fade(FadeDirection.fromBlack, 64);
          pc = 240;
          continue;
        case 240:
          await s.popupText(260, 8, 8);
          pc = 241;
          continue;
        case 241:
          await s.stall(65535, cancellable: true);
          pc = 242;
          continue;
        case 242:
          await s.fade(FadeDirection.toBlack, 64);
          pc = 243;
          continue;
        case 243:
          pc = 244;
          continue;
        case 244:
          s.checkSlot('evbit', 2);
          pc = 245;
          continue;
        case 245:
          if (s.slotInt(12) != s.slotInt(0)) { pc = 252; } else { pc = 246; }
          continue;
        case 246:
          s.setSlot(11, 0);
          pc = 247;
          continue;
        case 247:
          await s.loadMap(29);
          pc = 248;
          continue;
        case 248:
          await s.fade(FadeDirection.fromBlack, 64);
          pc = 249;
          continue;
        case 249:
          await s.popupText(261, 8, 8);
          pc = 250;
          continue;
        case 250:
          await s.stall(65535, cancellable: true);
          pc = 251;
          continue;
        case 251:
          await s.fade(FadeDirection.toBlack, 64);
          pc = 252;
          continue;
        case 252:
          pc = 253;
          continue;
        case 253:
          s.checkSlot('evbit', 2);
          pc = 254;
          continue;
        case 254:
          if (s.slotInt(12) != s.slotInt(0)) { pc = 261; } else { pc = 255; }
          continue;
        case 255:
          s.setSlot(11, 0);
          pc = 256;
          continue;
        case 256:
          await s.loadMap(30);
          pc = 257;
          continue;
        case 257:
          await s.fade(FadeDirection.fromBlack, 64);
          pc = 258;
          continue;
        case 258:
          await s.popupText(262, 8, 8);
          pc = 259;
          continue;
        case 259:
          await s.stall(65535, cancellable: true);
          pc = 260;
          continue;
        case 260:
          await s.fade(FadeDirection.toBlack, 64);
          pc = 261;
          continue;
        case 261:
          pc = 262;
          continue;
        case 262:
          s.checkSlot('evbit', 2);
          pc = 263;
          continue;
        case 263:
          if (s.slotInt(12) != s.slotInt(0)) { pc = 270; } else { pc = 264; }
          continue;
        case 264:
          s.setSlot(11, 0);
          pc = 265;
          continue;
        case 265:
          await s.loadMap(31);
          pc = 266;
          continue;
        case 266:
          await s.fade(FadeDirection.fromBlack, 64);
          pc = 267;
          continue;
        case 267:
          await s.popupText(263, 8, 8);
          pc = 268;
          continue;
        case 268:
          await s.stall(65535, cancellable: true);
          pc = 269;
          continue;
        case 269:
          await s.fade(FadeDirection.toBlack, 64);
          pc = 270;
          continue;
        case 270:
          pc = 271;
          continue;
        case 271:
          s.checkSlot('evbit', 2);
          pc = 272;
          continue;
        case 272:
          if (s.slotInt(12) != s.slotInt(0)) { pc = 279; } else { pc = 273; }
          continue;
        case 273:
          s.setSlot(11, 0);
          pc = 274;
          continue;
        case 274:
          await s.loadMap(32);
          pc = 275;
          continue;
        case 275:
          await s.fade(FadeDirection.fromBlack, 64);
          pc = 276;
          continue;
        case 276:
          await s.popupText(264, 8, 8);
          pc = 277;
          continue;
        case 277:
          await s.stall(65535, cancellable: true);
          pc = 278;
          continue;
        case 278:
          await s.fade(FadeDirection.toBlack, 64);
          pc = 279;
          continue;
        case 279:
          pc = 280;
          continue;
        case 280:
          s.checkSlot('evbit', 2);
          pc = 281;
          continue;
        case 281:
          if (s.slotInt(12) != s.slotInt(0)) { pc = 288; } else { pc = 282; }
          continue;
        case 282:
          s.setSlot(11, 0);
          pc = 283;
          continue;
        case 283:
          await s.loadMap(33);
          pc = 284;
          continue;
        case 284:
          await s.fade(FadeDirection.fromBlack, 64);
          pc = 285;
          continue;
        case 285:
          await s.popupText(265, 8, 8);
          pc = 286;
          continue;
        case 286:
          await s.stall(65535, cancellable: true);
          pc = 287;
          continue;
        case 287:
          await s.fade(FadeDirection.toBlack, 64);
          pc = 288;
          continue;
        case 288:
          pc = 289;
          continue;
        case 289:
          s.checkSlot('evbit', 2);
          pc = 290;
          continue;
        case 290:
          if (s.slotInt(12) != s.slotInt(0)) { pc = 297; } else { pc = 291; }
          continue;
        case 291:
          s.setSlot(11, 0);
          pc = 292;
          continue;
        case 292:
          await s.loadMap(34);
          pc = 293;
          continue;
        case 293:
          await s.fade(FadeDirection.fromBlack, 64);
          pc = 294;
          continue;
        case 294:
          await s.popupText(266, 8, 8);
          pc = 295;
          continue;
        case 295:
          await s.stall(65535, cancellable: true);
          pc = 296;
          continue;
        case 296:
          await s.fade(FadeDirection.toBlack, 64);
          pc = 297;
          continue;
        case 297:
          pc = 298;
          continue;
        case 298:
          s.setSlot(11, 0);
          pc = 299;
          continue;
        case 299:
          await s.loadMap(60);
          pc = 300;
          continue;
        case 300:
          return;
        default:
          return;
      }
    }
}

/// `EventScr_Ruin_56`
Future<void> Ruin_56(Scene s) async {
    var pc = 0;
    while (true) {
      switch (pc) {
        case 0:
          await s.fade(FadeDirection.toBlack, 16);
          pc = 1;
          continue;
        case 1:
          s.setSlot(2, 1);
          pc = 2;
          continue;
        case 2:
          s.setSlot(3, 115);
          pc = 3;
          continue;
        case 3:
          s.setTextType(1);
          pc = 4;
          continue;
        case 4:
          pc = 5;
          continue;
        case 5:
          s.showTextBg(81);
          pc = 6;
          continue;
        case 6:
          await s.fade(FadeDirection.fromBlack, 16);
          pc = 7;
          continue;
        case 7:
          s.placeholder('FACE_SHOW');
          pc = 8;
          continue;
        case 8:
          await s.textEnd();
          pc = 9;
          continue;
        case 9:
          await s.stall(65535, cancellable: true);
          pc = 10;
          continue;
        case 10:
          s.textRemoveAll();
          pc = 11;
          continue;
        case 11:
          await s.fade(FadeDirection.toBlack, 16);
          pc = 12;
          continue;
        case 12:
          s.setSlot(1, 1);
          pc = 13;
          continue;
        case 13:
          s.slotArith('SADD', 2, 2);
          pc = 14;
          continue;
        case 14:
          if (s.slotInt(2) < s.slotInt(3)) { pc = 4; } else { pc = 15; }
          continue;
        case 15:
          await s.clearScreen();
          pc = 16;
          continue;
        case 16:
          await s.fade(FadeDirection.fromBlack, 16);
          pc = 17;
          continue;
        case 17:
          s.evBitMod('evbit', true, 7);
          pc = 18;
          continue;
        case 18:
          return;
        default:
          return;
      }
    }
}

/// `EventScr_Ruin_58`
Future<void> Ruin_58(Scene s) async {
    var pc = 0;
    while (true) {
      switch (pc) {
        case 0:
          await s.fade(FadeDirection.toBlack, 16);
          pc = 1;
          continue;
        case 1:
          s.setSlot(2, 0);
          pc = 2;
          continue;
        case 2:
          s.setSlot(3, 79);
          pc = 3;
          continue;
        case 3:
          s.setTextType(1);
          pc = 4;
          continue;
        case 4:
          pc = 5;
          continue;
        case 5:
          s.showTextBg(65535);
          pc = 6;
          continue;
        case 6:
          await s.fade(FadeDirection.fromBlack, 16);
          pc = 7;
          continue;
        case 7:
          await s.stall(65535, cancellable: true);
          pc = 8;
          continue;
        case 8:
          await s.fade(FadeDirection.toBlack, 16);
          pc = 9;
          continue;
        case 9:
          s.setSlot(1, 1);
          pc = 10;
          continue;
        case 10:
          s.slotArith('SADD', 2, 2);
          pc = 11;
          continue;
        case 11:
          if (s.slotInt(2) < s.slotInt(3)) { pc = 4; } else { pc = 12; }
          continue;
        case 12:
          await s.clearScreen();
          pc = 13;
          continue;
        case 13:
          await s.fade(FadeDirection.fromBlack, 16);
          pc = 14;
          continue;
        case 14:
          s.evBitMod('evbit', true, 7);
          pc = 15;
          continue;
        case 15:
          return;
        default:
          return;
      }
    }
}

/// `EventScr_Ruin_60`
Future<void> Ruin_60(Scene s) async {
    s.setSlot(2, 0);
    await s.call(Sym('EventScr_ConfigHardModeLoadUnitHard'));
    s.setSlot(13, 0);
    s.setSlot(1, 50);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 25);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 15);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 5);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 5);
    s.slotQueuePushSlot(0x1);
    await s.call(Sym('EventScr_9EE84C'));
    s.setSlot(1, 0);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 1);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 2);
    s.slotQueuePushSlot(0x1);
    return;
}

/// `EventScr_Ruin_62`
Future<void> Ruin_62(Scene s) async {
    s.setSlot(2, 0);
    await s.call(Sym('EventScr_ConfigHardModeLoadUnitHard'));
    s.setSlot(13, 0);
    s.setSlot(1, 50);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 25);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 15);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 5);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 5);
    s.slotQueuePushSlot(0x1);
    await s.call(Sym('EventScr_9EE84C'));
    s.setSlot(1, 0);
    s.slotQueuePushSlot(0x1);
    return;
}

/// `EventScr_Ruin_64`
Future<void> Ruin_64(Scene s) async {
    s.setSlot(2, 0);
    await s.call(Sym('EventScr_ConfigHardModeLoadUnitHard'));
    s.setSlot(13, 0);
    s.setSlot(1, 50);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 25);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 15);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 5);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 5);
    s.slotQueuePushSlot(0x1);
    await s.call(Sym('EventScr_9EE84C'));
    s.setSlot(1, 0);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 1);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 2);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 3);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 4);
    s.slotQueuePushSlot(0x1);
    return;
}

/// `EventScr_Ruin_66`
Future<void> Ruin_66(Scene s) async {
    s.setSlot(2, 0);
    await s.call(Sym('EventScr_ConfigHardModeLoadUnitHard'));
    s.setSlot(13, 0);
    s.setSlot(1, 50);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 25);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 15);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 5);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 5);
    s.slotQueuePushSlot(0x1);
    await s.call(Sym('EventScr_9EE84C'));
    return;
}

/// `EventScr_Ruin_68`
Future<void> Ruin_68(Scene s) async {
    s.setSlot(2, 0);
    await s.call(Sym('EventScr_ConfigHardModeLoadUnitHard'));
    s.setSlot(13, 0);
    s.setSlot(1, 50);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 25);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 15);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 5);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 5);
    s.slotQueuePushSlot(0x1);
    await s.call(Sym('EventScr_9EE84C'));
    s.setSlot(1, 0);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 1);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 2);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 3);
    s.slotQueuePushSlot(0x1);
    return;
}

/// `EventScr_Ruin_70`
Future<void> Ruin_70(Scene s) async {
    s.setSlot(2, 0);
    await s.call(Sym('EventScr_ConfigHardModeLoadUnitHard'));
    s.setSlot(13, 0);
    s.setSlot(1, 50);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 25);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 15);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 5);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 5);
    s.slotQueuePushSlot(0x1);
    await s.call(Sym('EventScr_9EE84C'));
    s.placeholder('EvtChangeFogVision');
    return;
}

/// `EventScr_Ruin_72`
Future<void> Ruin_72(Scene s) async {
    s.setSlot(2, 0);
    await s.call(Sym('EventScr_ConfigHardModeLoadUnitHard'));
    s.setSlot(13, 0);
    s.setSlot(1, 50);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 25);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 15);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 5);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 5);
    s.slotQueuePushSlot(0x1);
    await s.call(Sym('EventScr_9EE84C'));
    s.setSlot(1, 0);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 1);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 2);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 3);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 6);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 7);
    s.slotQueuePushSlot(0x1);
    return;
}

/// `EventScr_Ruin_74`
Future<void> Ruin_74(Scene s) async {
    s.setSlot(2, 0);
    await s.call(Sym('EventScr_ConfigHardModeLoadUnitHard'));
    s.setSlot(13, 0);
    s.setSlot(1, 50);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 25);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 15);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 5);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 5);
    s.slotQueuePushSlot(0x1);
    await s.call(Sym('EventScr_9EE84C'));
    s.setSlot(1, 0);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 1);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 4);
    s.slotQueuePushSlot(0x1);
    return;
}

/// `EventScr_Ruin_76`
Future<void> Ruin_76(Scene s) async {
    s.setSlot(2, 0);
    await s.call(Sym('EventScr_ConfigHardModeLoadUnitHard'));
    s.setSlot(13, 0);
    s.setSlot(1, 50);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 25);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 15);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 5);
    s.slotQueuePushSlot(0x1);
    s.setSlot(1, 5);
    s.slotQueuePushSlot(0x1);
    await s.call(Sym('EventScr_9EE84C'));
    return;
}

/// `EventScr_SetBackground`
Future<void> SetBackground(Scene s) async {
    var pc = 0;
    while (true) {
      switch (pc) {
        case 0:
          s.checkSlot('evbit', 8);
          pc = 1;
          continue;
        case 1:
          if (s.slotInt(12) != s.slotInt(0)) { pc = 3; } else { pc = 2; }
          continue;
        case 2:
          await s.fade(FadeDirection.toBlack, 16);
          pc = 3;
          continue;
        case 3:
          pc = 4;
          continue;
        case 4:
          s.setTextType(1);
          pc = 5;
          continue;
        case 5:
          s.showTextBg(65535);
          pc = 6;
          continue;
        case 6:
          await s.fade(FadeDirection.fromBlack, 16);
          pc = 7;
          continue;
        case 7:
          return;
        default:
          return;
      }
    }
}

/// `EventScr_SetFlagIfPlayedThrough`
Future<void> SetFlagIfPlayedThrough(Scene s) async {
    var pc = 0;
    while (true) {
      switch (pc) {
        case 0:
          s.placeholder('CHECK_POSTGAME');
          pc = 1;
          continue;
        case 1:
          if (s.slotInt(12) == s.slotInt(0)) { pc = 3; } else { pc = 2; }
          continue;
        case 2:
          s.evBitMod('flag', true, -1);
          pc = 3;
          continue;
        case 3:
          pc = 4;
          continue;
        case 4:
          return;
        default:
          return;
      }
    }
}

/// `EventScr_SkirmishRetreat`
Future<void> SkirmishRetreat(Scene s) async {
    var pc = 0;
    while (true) {
      switch (pc) {
        case 0:
          s.modifyEvBit(4);
          pc = 1;
          continue;
        case 1:
          s.setTextType(3);
          pc = 2;
          continue;
        case 2:
          s.setSlot(11, 4294967295);
          pc = 3;
          continue;
        case 3:
          await s.textShow(2238);
          pc = 4;
          continue;
        case 4:
          await s.textEnd();
          pc = 5;
          continue;
        case 5:
          s.setSlot(7, 1);
          pc = 6;
          continue;
        case 6:
          if (s.slotInt(12) != s.slotInt(7)) { pc = 14; } else { pc = 7; }
          continue;
        case 7:
          s.placeholder('EvtBgmFadeIn');
          pc = 8;
          continue;
        case 8:
          await s.fade(FadeDirection.toBlack, 4);
          pc = 9;
          continue;
        case 9:
          await s.changeChapter(65535, subcmd: 1);
          pc = 10;
          continue;
        case 10:
          s.placeholder('CHECK_SKIRMISH');
          pc = 11;
          continue;
        case 11:
          s.setSlot(1, 1);
          pc = 12;
          continue;
        case 12:
          if (s.slotInt(12) != s.slotInt(1)) { pc = 14; } else { pc = 13; }
          continue;
        case 13:
          s.placeholder('ASMC');
          pc = 14;
          continue;
        case 14:
          pc = 15;
          continue;
        case 15:
          s.textRemoveAll();
          pc = 16;
          continue;
        case 16:
          s.evBitMod('evbit', true, 7);
          pc = 17;
          continue;
        case 17:
          return;
        default:
          return;
      }
    }
}

/// `EventScr_StrictLoadUniqueAlly`
Future<void> StrictLoadUniqueAlly(Scene s) async {
    var pc = 0;
    while (true) {
      switch (pc) {
        case 0:
          s.placeholder('CHECK_EXISTS');
          pc = 1;
          continue;
        case 1:
          if (s.slotInt(12) != s.slotInt(0)) { pc = 5; } else { pc = 2; }
          continue;
        case 2:
          s.placeholder('SPAWN_ALLY');
          pc = 3;
          continue;
        case 3:
          s.placeholder('REMU');
          pc = 4;
          continue;
        case 4:
          pc = 10;
          continue;
        case 5:
          pc = 6;
          continue;
        case 6:
          s.placeholder('CHECK_ALLEGIANCE');
          pc = 7;
          continue;
        case 7:
          s.setSlot(1, RawArg('FACTION_ID_BLUE'));
          pc = 8;
          continue;
        case 8:
          if (s.slotInt(12) == s.slotInt(1)) { pc = 16; } else { pc = 9; }
          continue;
        case 9:
          s.placeholder('CUSA');
          pc = 10;
          continue;
        case 10:
          pc = 11;
          continue;
        case 11:
          s.setSlot(1, 0);
          pc = 12;
          continue;
        case 12:
          await s.setUnitHpFromSlot(0);
          pc = 13;
          continue;
        case 13:
          s.placeholder('REMU');
          pc = 14;
          continue;
        case 14:
          s.setSlot(1, 0);
          pc = 15;
          continue;
        case 15:
          s.placeholder('SET_STATE');
          pc = 16;
          continue;
        case 16:
          pc = 17;
          continue;
        case 17:
          return;
        default:
          return;
      }
    }
}

/// `EventScr_SuspendPrompt`
Future<void> SuspendPrompt(Scene s) async {
    var pc = 0;
    while (true) {
      switch (pc) {
        case 0:
          s.modifyEvBit(4);
          pc = 1;
          continue;
        case 1:
          s.setTextType(0);
          pc = 2;
          continue;
        case 2:
          await s.textShow(2079);
          pc = 3;
          continue;
        case 3:
          await s.textEnd();
          pc = 4;
          continue;
        case 4:
          s.setSlot(7, 1);
          pc = 5;
          continue;
        case 5:
          if (s.slotInt(12) != s.slotInt(7)) { pc = 12; } else { pc = 6; }
          continue;
        case 6:
          s.placeholder('ASMC');
          pc = 7;
          continue;
        case 7:
          s.placeholder('EVENT_WORD_SYM');
          pc = 8;
          continue;
        case 8:
          await s.textEnd();
          pc = 9;
          continue;
        case 9:
          s.placeholder('EvtBgmFadeIn');
          pc = 10;
          continue;
        case 10:
          await s.fade(FadeDirection.toBlack, 4);
          pc = 11;
          continue;
        case 11:
          await s.changeChapter(0, subcmd: 0);
          pc = 12;
          continue;
        case 12:
          pc = 13;
          continue;
        case 13:
          s.textRemoveAll();
          pc = 14;
          continue;
        case 14:
          s.evBitMod('evbit', true, 7);
          pc = 15;
          continue;
        case 15:
          return;
        default:
          return;
      }
    }
}

/// `EventScr_TextShowWithFadeIn`
Future<void> TextShowWithFadeIn(Scene s) async {
    var pc = 0;
    while (true) {
      switch (pc) {
        case 0:
          s.checkSlot('evbit', 8);
          pc = 1;
          continue;
        case 1:
          if (s.slotInt(12) != s.slotInt(0)) { pc = 3; } else { pc = 2; }
          continue;
        case 2:
          await s.fade(FadeDirection.toBlack, 16);
          pc = 3;
          continue;
        case 3:
          pc = 4;
          continue;
        case 4:
          s.setTextType(0);
          pc = 5;
          continue;
        case 5:
          await s.clearScreen();
          pc = 6;
          continue;
        case 6:
          await s.fade(FadeDirection.fromBlack, 16);
          pc = 7;
          continue;
        case 7:
          return;
        default:
          return;
      }
    }
}

/// `EventScr_Tutorial_Exec0`
Future<void> Tutorial_Exec0(Scene s) async {
    var pc = 0;
    while (true) {
      switch (pc) {
        case 0:
          s.setTextType(3);
          pc = 1;
          continue;
        case 1:
          s.checkSlotValue('activePid');
          pc = 2;
          continue;
        case 2:
          s.slotQueuePopToSlot(2);
          pc = 3;
          continue;
        case 3:
          if (s.slotInt(12) != s.slotInt(2)) { pc = 18; } else { pc = 4; }
          continue;
        case 4:
          s.placeholder('SHOW_ATTACK_RANGE');
          pc = 5;
          continue;
        case 5:
          s.slotQueuePopToSlot(11);
          pc = 6;
          continue;
        case 6:
          s.showCursorAt(-1, -1, flashing: true);
          pc = 7;
          continue;
        case 7:
          await s.stall(18);
          pc = 8;
          continue;
        case 8:
          s.slotQueuePopToSlot(2);
          pc = 9;
          continue;
        case 9:
          s.slotQueuePopToSlot(11);
          pc = 10;
          continue;
        case 10:
          await s.textShow(-1);
          pc = 11;
          continue;
        case 11:
          await s.textEnd();
          pc = 12;
          continue;
        case 12:
          await s.endCursor();
          pc = 13;
          continue;
        case 13:
          s.placeholder('IGNORE_KEYS');
          pc = 14;
          continue;
        case 14:
          s.slotQueuePopToSlot(12);
          pc = 15;
          continue;
        case 15:
          s.slotQueuePopToSlot(12);
          pc = 16;
          continue;
        case 16:
          s.slotQueuePopToSlot(2);
          pc = 17;
          continue;
        case 17:
          pc = 32;
          continue;
        case 18:
          pc = 19;
          continue;
        case 19:
          s.slotQueuePopToSlot(12);
          pc = 20;
          continue;
        case 20:
          s.slotQueuePopToSlot(12);
          pc = 21;
          continue;
        case 21:
          s.slotQueuePopToSlot(12);
          pc = 22;
          continue;
        case 22:
          s.showCursorAtUnit(0, flashing: true);
          pc = 23;
          continue;
        case 23:
          await s.stall(8);
          pc = 24;
          continue;
        case 24:
          s.placeholder('SET_ACTIVE');
          pc = 25;
          continue;
        case 25:
          s.slotQueuePopToSlot(2);
          pc = 26;
          continue;
        case 26:
          s.slotQueuePopToSlot(11);
          pc = 27;
          continue;
        case 27:
          await s.textShow(-1);
          pc = 28;
          continue;
        case 28:
          await s.textEnd();
          pc = 29;
          continue;
        case 29:
          await s.endCursor();
          pc = 30;
          continue;
        case 30:
          s.slotQueuePopToSlot(12);
          pc = 31;
          continue;
        case 31:
          s.slotQueuePopToSlot(2);
          pc = 32;
          continue;
        case 32:
          pc = 33;
          continue;
        case 33:
          s.textRemoveAll();
          pc = 34;
          continue;
        case 34:
          return;
        default:
          return;
      }
    }
}

/// `EventScr_Tutorial_Exec1`
Future<void> Tutorial_Exec1(Scene s) async {
    var pc = 0;
    while (true) {
      switch (pc) {
        case 0:
          s.placeholder('CHECK_CURSOR');
          pc = 1;
          continue;
        case 1:
          s.slotQueuePopToSlot(11);
          pc = 2;
          continue;
        case 2:
          if (s.slotInt(12) != s.slotInt(11)) { pc = 10; } else { pc = 3; }
          continue;
        case 3:
          s.placeholder('ASMC');
          pc = 4;
          continue;
        case 4:
          s.slotQueuePopToSlot(12);
          pc = 5;
          continue;
        case 5:
          s.slotQueuePopToSlot(12);
          pc = 6;
          continue;
        case 6:
          s.slotQueuePopToSlot(2);
          pc = 7;
          continue;
        case 7:
          s.placeholder('EvtEnqueueConditionalTutCall');
          pc = 8;
          continue;
        case 8:
          s.setSlot(12, 1);
          pc = 9;
          continue;
        case 9:
          pc = 28;
          continue;
        case 10:
          pc = 11;
          continue;
        case 11:
          s.placeholder('SET_CURSOR');
          pc = 12;
          continue;
        case 12:
          await s.cameraTo(255, 255, centered: false);
          pc = 13;
          continue;
        case 13:
          s.showCursorAt(255, 255, flashing: true);
          pc = 14;
          continue;
        case 14:
          s.placeholder('STAL3');
          pc = 15;
          continue;
        case 15:
          s.setTextType(3);
          pc = 16;
          continue;
        case 16:
          s.slotQueuePopToSlot(2);
          pc = 17;
          continue;
        case 17:
          s.slotQueuePopToSlot(11);
          pc = 18;
          continue;
        case 18:
          if (s.slotInt(2) == s.slotInt(0)) { pc = 22; } else { pc = 19; }
          continue;
        case 19:
          await s.textShow(65535);
          pc = 20;
          continue;
        case 20:
          await s.textEnd();
          pc = 21;
          continue;
        case 21:
          s.textRemoveAll();
          pc = 22;
          continue;
        case 22:
          pc = 23;
          continue;
        case 23:
          await s.endCursor();
          pc = 24;
          continue;
        case 24:
          s.slotQueuePopToSlot(12);
          pc = 25;
          continue;
        case 25:
          s.slotQueuePopToSlot(2);
          pc = 26;
          continue;
        case 26:
          s.placeholder('EvtEnqueueConditionalTutCall');
          pc = 27;
          continue;
        case 27:
          s.setSlot(12, 0);
          pc = 28;
          continue;
        case 28:
          pc = 29;
          continue;
        case 29:
          return;
        default:
          return;
      }
    }
}

/// `EventScr_UnTriggerIfNotUnit`
Future<void> UnTriggerIfNotUnit(Scene s) async {
    var pc = 0;
    while (true) {
      switch (pc) {
        case 0:
          s.checkSlotValue('activePid');
          pc = 1;
          continue;
        case 1:
          if (s.slotInt(12) == s.slotInt(2)) { pc = 3; } else { pc = 2; }
          continue;
        case 2:
          await s.call(Sym('UnitDef_Ch14BAlly_7', 28));
          pc = 3;
          continue;
        case 3:
          pc = 4;
          continue;
        case 4:
          return;
        default:
          return;
      }
    }
}

/// `EventScr_UnitFlushingIN`
Future<void> UnitFlushingIN(Scene s) async {
    s.placeholder('CAMERA_CAHR');
    s.placeholder('REVEAL');
    await s.stall(2, cancellable: false);
    s.placeholder('REMU');
    await s.stall(4, cancellable: false);
    s.placeholder('REVEAL');
    await s.stall(2, cancellable: false);
    s.placeholder('REMU');
    await s.stall(4, cancellable: false);
    s.placeholder('REVEAL');
    await s.stall(2, cancellable: false);
    s.placeholder('REMU');
    await s.stall(2, cancellable: false);
    s.placeholder('REVEAL');
    return;
}

/// `EventScr_UnitFlushingOUT`
Future<void> UnitFlushingOUT(Scene s) async {
    s.placeholder('CAMERA_CAHR');
    s.placeholder('REVEAL');
    await s.stall(2, cancellable: false);
    s.placeholder('REMU');
    await s.stall(2, cancellable: false);
    s.placeholder('REVEAL');
    await s.stall(2, cancellable: false);
    s.placeholder('REMU');
    await s.stall(4, cancellable: false);
    s.placeholder('REVEAL');
    await s.stall(2, cancellable: false);
    s.placeholder('REMU');
    await s.stall(6, cancellable: false);
    s.placeholder('REVEAL');
    await s.stall(2, cancellable: false);
    s.placeholder('REMU');
    return;
}

/// `EventScr_UnitWarpIN`
Future<void> UnitWarpIN(Scene s) async {
    s.placeholder('REMU');
    s.placeholder('CAMERA_CAHR');
    s.placeholder('CHECK_COORDS');
    s.slotArith('SADD', 11, 12);
    s.placeholder('WARP_IN');
    await s.stall(10, cancellable: false);
    s.placeholder('REVEAL');
    s.placeholder('ENDWARP');
    return;
}

/// `EventScr_UnitWarpOUT`
Future<void> UnitWarpOUT(Scene s) async {
    s.placeholder('CAMERA_CAHR');
    s.placeholder('CHECK_COORDS');
    s.slotArith('SADD', 11, 12);
    s.placeholder('WARP_OUT');
    await s.stall(20, cancellable: false);
    s.placeholder('REMU');
    s.placeholder('ENDWARP');
    return;
}

/// `EventScr_WM_FadeCommon`
Future<void> WM_FadeCommon(Scene s) async {
}

/// `EventScr_WholeTowerClear`
Future<void> WholeTowerClear(Scene s) async {
    s.placeholder('ASMC');
    s.placeholder('ASMC');
    s.placeholder('ASMC');
    await s.changeChapter(65535, subcmd: 1);
    return;
}

/// `frontier_df3_eventscr_ch_014_A6EDFC + 0x98`
Future<void> frontier_df3_eventscr_ch_014_A6EDFC_0x98(Scene s) async {
    s.setSlot(2, 0);
    await s.call(Sym('UnitDef_Ch14BAlly_7'));
    s.setSlot(1, 65536);
    s.placeholder('CHAI');
    s.counterSet(0, 0);
    s.evBitMod('flag', false, 14);
    s.evBitMod('evbit', true, 7);
    return;
}

/// `frontier_df3_eventscr_ch_015_A6EF04`
Future<void> frontier_df3_eventscr_ch_015_A6EF04(Scene s) async {
    s.setSlot(2, 0);
    await s.call(Sym('UnitDef_Ch14BAlly_7'));
    s.setSlot(1, 65536);
    s.placeholder('CHAI');
    s.setSlot(1, 66307);
    s.placeholder('CHAI');
    s.counterSet(1, 0);
    s.evBitMod('flag', false, 13);
    s.evBitMod('evbit', true, 7);
    return;
}

/// `frontier_df3_eventscr_ch_016_A6EFD8 + 0x24`
Future<void> frontier_df3_eventscr_ch_016_A6EFD8_0x24(Scene s) async {
    var pc = 0;
    while (true) {
      switch (pc) {
        case 0:
          await s.call(Sym('frontier_df3_eventscr_ch_000_A69464', 112));
          pc = 1;
          continue;
        case 1:
          await s.call(Sym('frontier_df3_eventscr_ch_000_A69464', 240));
          pc = 2;
          continue;
        case 2:
          pc = 3;
          continue;
        case 3:
          pc = 4;
          continue;
        default:
          return;
      }
    }
}

/// `frontier_df3_eventscr_ch_016_A6EFD8 + 0x3C`
Future<void> frontier_df3_eventscr_ch_016_A6EFD8_0x3C(Scene s) async {
    var pc = 0;
    while (true) {
      switch (pc) {
        case 0:
          s.setTextType(3);
          pc = 1;
          continue;
        case 1:
          s.setSlot(11, 4294967295);
          pc = 2;
          continue;
        case 2:
          await s.textShow(2844);
          pc = 3;
          continue;
        case 3:
          await s.textEnd();
          pc = 4;
          continue;
        case 4:
          s.textRemoveAll();
          pc = 5;
          continue;
        case 5:
          await s.call(Sym('frontier_df3_eventscr_ch_000_A69464', 240));
          pc = 6;
          continue;
        case 6:
          await s.call(Sym('frontier_df3_eventscr_ch_000_A69464', 112));
          pc = 7;
          continue;
        case 7:
          pc = 8;
          continue;
        case 8:
          await s.fade(FadeDirection.toWhite, 16);
          pc = 9;
          continue;
        case 9:
          return;
        case 10:
          s.setTextType(3);
          pc = 11;
          continue;
        default:
          return;
      }
    }
}

/// `frontier_df3_eventscr_ch_016_A6EFD8 + 0xC`
Future<void> frontier_df3_eventscr_ch_016_A6EFD8_0xC(Scene s) async {
    s.setTextType(3);
    s.setSlot(11, 4294967295);
    await s.textShow(2843);
    await s.textEnd();
    s.textRemoveAll();
}

/// `frontier_df3_eventscr_ch_017_A6F47C + 0x1B8`
Future<void> frontier_df3_eventscr_ch_017_A6F47C_0x1B8(Scene s) async {
    await s.call(Sym('frontier_df3_eventscr_ch_003_A6AA20', 804));
    return;
    await s.call(Sym('UnitDef_Ch18BAlly_2'));
    await s.stall(30);
    s.showCursorAtUnit(64);
    await s.stall(60);
    await s.endCursor();
    await s.fade(FadeDirection.toWhite, 2);
    s.placeholder('EvtBgmFadeIn');
    s.setTextType(1);
    s.showTextBg(20);
    await s.fade(FadeDirection.fromWhite, 2);
    await s.popupText(405, 8, 8);
    await s.textShow(2935);
    await s.textEnd();
    s.textRemoveAll();
    await s.fade(FadeDirection.toWhite, 16);
    s.setTextType(1);
    s.showTextBg(18);
    await s.fade(FadeDirection.fromWhite, 16);
    await s.textShow(2936);
    await s.textEnd();
    s.textRemoveAll();
    s.placeholder('EvtBgmFadeIn');
    await s.fade(FadeDirection.toWhite, 2);
    await s.clearScreen();
    await s.fade(FadeDirection.fromWhite, 2);
    s.sound('bgm', 45);
    s.showCursorAtUnit(64);
    await s.stall(60);
    await s.endCursor();
    s.setSlot(2, 78);
    await s.call(Sym('EventScr_SetBackground'));
    await s.textShow(2937);
    await s.textEnd();
    await s.fade(FadeDirection.toBlack, 16);
    s.textRemoveAll();
    await s.changeChapter(34, subcmd: 2);
    return;
}

/// `frontier_df3_eventscr_ch_017_A6F47C + 0x1C`
Future<void> frontier_df3_eventscr_ch_017_A6F47C_0x1C(Scene s) async {
    await s.call(Sym('EventScr_Ch19A_11'));
    await s.changeChapter(33, subcmd: 1);
    return;
}

/// `frontier_df3_eventscr_ch_017_A6F47C + 0x270`
Future<void> frontier_df3_eventscr_ch_017_A6F47C_0x270(Scene s) async {
    var pc = 0;
    while (true) {
      switch (pc) {
        case 0:
          s.checkSlotValue('turn');
          pc = 1;
          continue;
        case 1:
          s.setSlot(1, 1);
          pc = 2;
          continue;
        case 2:
          s.slotArith('SAND', 12, 12);
          pc = 3;
          continue;
        case 3:
          if (s.slotInt(12) != s.slotInt(0)) { pc = 8; } else { pc = 4; }
          continue;
        case 4:
          s.setSlot(2, Sym('frontier_df3_unitdef_b_050_91EE14_residue'));
          pc = 5;
          continue;
        case 5:
          await s.call(Sym('EventScr_LoadReinforce'));
          pc = 6;
          continue;
        case 6:
          s.setSlot(2, Sym('frontier_df3_unitdef_b_050_91EE14_residue', 60));
          pc = 7;
          continue;
        case 7:
          await s.call(Sym('EventScr_LoadReinforceHardMode'));
          pc = 8;
          continue;
        case 8:
          pc = 9;
          continue;
        case 9:
          s.evBitMod('evbit', true, 7);
          pc = 10;
          continue;
        case 10:
          return;
        default:
          return;
      }
    }
}

/// `frontier_df3_eventscr_ch_017_A6F47C + 0x2B4`
Future<void> frontier_df3_eventscr_ch_017_A6F47C_0x2B4(Scene s) async {
    var pc = 0;
    while (true) {
      switch (pc) {
        case 0:
          s.checkSlotValue('turn');
          pc = 1;
          continue;
        case 1:
          s.setSlot(1, 1);
          pc = 2;
          continue;
        case 2:
          s.slotArith('SAND', 12, 12);
          pc = 3;
          continue;
        case 3:
          if (s.slotInt(12) == s.slotInt(0)) { pc = 8; } else { pc = 4; }
          continue;
        case 4:
          s.setSlot(2, Sym('frontier_df3_unitdef_b_050_91EE14_residue', 100));
          pc = 5;
          continue;
        case 5:
          await s.call(Sym('EventScr_LoadReinforce'));
          pc = 6;
          continue;
        case 6:
          s.setSlot(2, Sym('frontier_df3_unitdef_b_050_91EE14_residue', 160));
          pc = 7;
          continue;
        case 7:
          await s.call(Sym('EventScr_LoadReinforceHardMode'));
          pc = 8;
          continue;
        case 8:
          pc = 9;
          continue;
        case 9:
          s.evBitMod('evbit', true, 7);
          pc = 10;
          continue;
        case 10:
          return;
        default:
          return;
      }
    }
}

/// `frontier_df3_eventscr_ch_017_A6F47C + 0x2C`
Future<void> frontier_df3_eventscr_ch_017_A6F47C_0x2C(Scene s) async {
    s.setSlot(2, Sym('frontier_df3_unitdef_b_047_91E280', 500));
    await s.call(Sym('EventScr_LoadReinforce'));
    s.evBitMod('evbit', true, 7);
    return;
}

/// `frontier_df3_eventscr_ch_017_A6F47C + 0x2F8`
Future<void> frontier_df3_eventscr_ch_017_A6F47C_0x2F8(Scene s) async {
    s.setSlot(2, 0);
    await s.call(Sym('UnitDef_Ch14BAlly_7'));
    s.counterSet(0, 0);
    s.evBitMod('flag', false, 10);
    s.evBitMod('evbit', true, 7);
    return;
}

/// `frontier_df3_eventscr_ch_017_A6F47C + 0x318`
Future<void> frontier_df3_eventscr_ch_017_A6F47C_0x318(Scene s) async {
    var pc = 0;
    while (true) {
      switch (pc) {
        case 0:
          s.setSlot(2, Sym('frontier_df3_unitdef_b_050_91EE14_residue', 200));
          pc = 1;
          continue;
        case 1:
          await s.call(Sym('EventScr_LoadReinforce'));
          pc = 2;
          continue;
        case 2:
          s.counterDec(0);
          pc = 3;
          continue;
        case 3:
          s.evBitMod('flag', false, 10);
          pc = 4;
          continue;
        case 4:
          s.counterCheck(0);
          pc = 5;
          continue;
        case 5:
          if (s.slotInt(12) != s.slotInt(0)) { pc = 7; } else { pc = 6; }
          continue;
        case 6:
          s.evBitMod('flag', true, 10);
          pc = 7;
          continue;
        case 7:
          pc = 8;
          continue;
        case 8:
          s.evBitMod('evbit', true, 7);
          pc = 9;
          continue;
        case 9:
          return;
        default:
          return;
      }
    }
}

/// `frontier_df3_eventscr_ch_017_A6F47C + 0x34C`
Future<void> frontier_df3_eventscr_ch_017_A6F47C_0x34C(Scene s) async {
    s.setSlot(2, 0);
    await s.call(Sym('UnitDef_Ch14BAlly_7'));
    s.evBitMod('flag', false, 12);
    s.counterSet(1, 0);
    s.evBitMod('evbit', true, 7);
    return;
}

/// `frontier_df3_eventscr_ch_017_A6F47C + 0x36C`
Future<void> frontier_df3_eventscr_ch_017_A6F47C_0x36C(Scene s) async {
    var pc = 0;
    while (true) {
      switch (pc) {
        case 0:
          s.evBitMod('flag', false, 12);
          pc = 1;
          continue;
        case 1:
          s.counterCheck(1);
          pc = 2;
          continue;
        case 2:
          s.setSlot(7, 5);
          pc = 3;
          continue;
        case 3:
          if (s.slotInt(12) == s.slotInt(7)) { pc = 13; } else { pc = 4; }
          continue;
        case 4:
          s.setSlot(7, 3);
          pc = 5;
          continue;
        case 5:
          if (s.slotInt(12) == s.slotInt(7)) { pc = 13; } else { pc = 6; }
          continue;
        case 6:
          s.setSlot(7, 1);
          pc = 7;
          continue;
        case 7:
          if (s.slotInt(12) == s.slotInt(7)) { pc = 13; } else { pc = 8; }
          continue;
        case 8:
          s.setSlot(2, Sym('frontier_df3_unitdef_b_050_91EE14_residue', 260));
          pc = 9;
          continue;
        case 9:
          await s.call(Sym('EventScr_LoadReinforce'));
          pc = 10;
          continue;
        case 10:
          s.counterCheck(1);
          pc = 11;
          continue;
        case 11:
          if (s.slotInt(12) != s.slotInt(0)) { pc = 13; } else { pc = 12; }
          continue;
        case 12:
          s.evBitMod('flag', true, 12);
          pc = 13;
          continue;
        case 13:
          pc = 14;
          continue;
        case 14:
          s.counterDec(1);
          pc = 15;
          continue;
        case 15:
          s.evBitMod('evbit', true, 7);
          pc = 16;
          continue;
        case 16:
          return;
        default:
          return;
      }
    }
}

/// `frontier_df3_eventscr_ch_017_A6F47C + 0x3D4`
Future<void> frontier_df3_eventscr_ch_017_A6F47C_0x3D4(Scene s) async {
    s.setSlot(2, 0);
    await s.call(Sym('UnitDef_Ch14BAlly_7'));
    s.evBitMod('flag', false, 14);
    s.counterSet(2, 0);
    s.evBitMod('evbit', true, 7);
    return;
}

/// `frontier_df3_eventscr_ch_017_A6F47C + 0x3F4`
Future<void> frontier_df3_eventscr_ch_017_A6F47C_0x3F4(Scene s) async {
    var pc = 0;
    while (true) {
      switch (pc) {
        case 0:
          s.evBitMod('flag', false, 14);
          pc = 1;
          continue;
        case 1:
          s.counterCheck(2);
          pc = 2;
          continue;
        case 2:
          s.setSlot(7, 5);
          pc = 3;
          continue;
        case 3:
          if (s.slotInt(12) == s.slotInt(7)) { pc = 13; } else { pc = 4; }
          continue;
        case 4:
          s.setSlot(7, 3);
          pc = 5;
          continue;
        case 5:
          if (s.slotInt(12) == s.slotInt(7)) { pc = 13; } else { pc = 6; }
          continue;
        case 6:
          s.setSlot(7, 1);
          pc = 7;
          continue;
        case 7:
          if (s.slotInt(12) == s.slotInt(7)) { pc = 13; } else { pc = 8; }
          continue;
        case 8:
          s.setSlot(2, Sym('frontier_df3_unitdef_b_050_91EE14_residue', 340));
          pc = 9;
          continue;
        case 9:
          await s.call(Sym('EventScr_LoadReinforce'));
          pc = 10;
          continue;
        case 10:
          s.counterCheck(2);
          pc = 11;
          continue;
        case 11:
          if (s.slotInt(12) != s.slotInt(0)) { pc = 13; } else { pc = 12; }
          continue;
        case 12:
          s.evBitMod('flag', true, 14);
          pc = 13;
          continue;
        case 13:
          pc = 14;
          continue;
        case 14:
          s.counterDec(2);
          pc = 15;
          continue;
        case 15:
          s.evBitMod('evbit', true, 7);
          pc = 16;
          continue;
        case 16:
          return;
        default:
          return;
      }
    }
}

/// `frontier_df3_eventscr_ch_017_A6F47C + 0x44`
Future<void> frontier_df3_eventscr_ch_017_A6F47C_0x44(Scene s) async {
    s.setSlot(2, Sym('frontier_df3_unitdef_b_047_91E280', 540));
    await s.call(Sym('EventScr_LoadReinforce'));
    s.evBitMod('evbit', true, 7);
    return;
}

/// `frontier_df3_eventscr_ch_017_A6F47C + 0x45C`
Future<void> frontier_df3_eventscr_ch_017_A6F47C_0x45C(Scene s) async {
    s.setSlot(2, 0);
    await s.call(Sym('UnitDef_Ch14BAlly_7'));
    s.evBitMod('flag', false, 16);
    s.counterSet(3, 0);
    s.evBitMod('evbit', true, 7);
    return;
}

/// `frontier_df3_eventscr_ch_017_A6F47C + 0x47C`
Future<void> frontier_df3_eventscr_ch_017_A6F47C_0x47C(Scene s) async {
    var pc = 0;
    while (true) {
      switch (pc) {
        case 0:
          s.evBitMod('flag', false, 16);
          pc = 1;
          continue;
        case 1:
          s.counterCheck(3);
          pc = 2;
          continue;
        case 2:
          s.setSlot(7, 11);
          pc = 3;
          continue;
        case 3:
          if (s.slotInt(12) == s.slotInt(7)) { pc = 23; } else { pc = 4; }
          continue;
        case 4:
          s.setSlot(7, 10);
          pc = 5;
          continue;
        case 5:
          if (s.slotInt(12) == s.slotInt(7)) { pc = 23; } else { pc = 6; }
          continue;
        case 6:
          s.setSlot(7, 8);
          pc = 7;
          continue;
        case 7:
          if (s.slotInt(12) == s.slotInt(7)) { pc = 23; } else { pc = 8; }
          continue;
        case 8:
          s.setSlot(7, 7);
          pc = 9;
          continue;
        case 9:
          if (s.slotInt(12) == s.slotInt(7)) { pc = 23; } else { pc = 10; }
          continue;
        case 10:
          s.setSlot(7, 5);
          pc = 11;
          continue;
        case 11:
          if (s.slotInt(12) == s.slotInt(7)) { pc = 23; } else { pc = 12; }
          continue;
        case 12:
          s.setSlot(7, 4);
          pc = 13;
          continue;
        case 13:
          if (s.slotInt(12) == s.slotInt(7)) { pc = 23; } else { pc = 14; }
          continue;
        case 14:
          s.setSlot(7, 2);
          pc = 15;
          continue;
        case 15:
          if (s.slotInt(12) == s.slotInt(7)) { pc = 23; } else { pc = 16; }
          continue;
        case 16:
          s.setSlot(7, 1);
          pc = 17;
          continue;
        case 17:
          if (s.slotInt(12) == s.slotInt(7)) { pc = 23; } else { pc = 18; }
          continue;
        case 18:
          s.setSlot(2, Sym('frontier_df3_unitdef_b_050_91EE14_residue', 420));
          pc = 19;
          continue;
        case 19:
          await s.call(Sym('EventScr_LoadReinforce'));
          pc = 20;
          continue;
        case 20:
          s.counterCheck(3);
          pc = 21;
          continue;
        case 21:
          if (s.slotInt(12) != s.slotInt(0)) { pc = 23; } else { pc = 22; }
          continue;
        case 22:
          s.evBitMod('flag', true, 16);
          pc = 23;
          continue;
        case 23:
          pc = 24;
          continue;
        case 24:
          s.counterDec(3);
          pc = 25;
          continue;
        case 25:
          s.evBitMod('evbit', true, 7);
          pc = 26;
          continue;
        case 26:
          return;
        default:
          return;
      }
    }
}

/// `frontier_df3_eventscr_ch_017_A6F47C + 0x534`
Future<void> frontier_df3_eventscr_ch_017_A6F47C_0x534(Scene s) async {
    var pc = 0;
    while (true) {
      switch (pc) {
        case 0:
          s.checkSlotValue('turn');
          pc = 1;
          continue;
        case 1:
          s.setSlot(1, 1);
          pc = 2;
          continue;
        case 2:
          s.slotArith('SAND', 12, 12);
          pc = 3;
          continue;
        case 3:
          if (s.slotInt(12) != s.slotInt(0)) { pc = 12; } else { pc = 4; }
          continue;
        case 4:
          s.setSlot(2, Sym('frontier_df3_unitdef_b_050_91EE14_residue', 500));
          pc = 5;
          continue;
        case 5:
          await s.call(Sym('EventScr_LoadReinforce'));
          pc = 6;
          continue;
        case 6:
          s.setSlot(2, Sym('frontier_df3_unitdef_b_050_91EE14_residue', 580));
          pc = 7;
          continue;
        case 7:
          await s.call(Sym('EventScr_LoadReinforceHardMode'));
          pc = 8;
          continue;
        case 8:
          s.setSlot(2, Sym('frontier_df3_unitdef_b_050_91EE14_residue', 640));
          pc = 9;
          continue;
        case 9:
          await s.call(Sym('EventScr_LoadReinforceHardMode'));
          pc = 10;
          continue;
        case 10:
          s.setSlot(2, Sym('frontier_df3_unitdef_b_050_91EE14_residue', 680));
          pc = 11;
          continue;
        case 11:
          await s.call(Sym('EventScr_LoadReinforceHardMode'));
          pc = 12;
          continue;
        case 12:
          pc = 13;
          continue;
        case 13:
          s.evBitMod('evbit', true, 7);
          pc = 14;
          continue;
        case 14:
          return;
        default:
          return;
      }
    }
}

/// `frontier_df3_eventscr_ch_017_A6F47C + 0x598`
Future<void> frontier_df3_eventscr_ch_017_A6F47C_0x598(Scene s) async {
    s.setSlot(2, Sym('UnitDef_Ch19BEnemy_8'));
    await s.call(Sym('EventScr_LoadReinforceHardMode'));
    s.evBitMod('evbit', true, 7);
    return;
}

/// `frontier_df3_eventscr_ch_017_A6F47C + 0x5C`
Future<void> frontier_df3_eventscr_ch_017_A6F47C_0x5C(Scene s) async {
    var pc = 0;
    while (true) {
      switch (pc) {
        case 0:
          s.checkSlotValue('turn');
          pc = 1;
          continue;
        case 1:
          s.setSlot(1, 1);
          pc = 2;
          continue;
        case 2:
          s.slotArith('SAND', 12, 12);
          pc = 3;
          continue;
        case 3:
          if (s.slotInt(12) == s.slotInt(0)) { pc = 6; } else { pc = 4; }
          continue;
        case 4:
          s.setSlot(2, Sym('frontier_df3_unitdef_b_047_91E280_residue'));
          pc = 5;
          continue;
        case 5:
          await s.call(Sym('EventScr_LoadReinforce'));
          pc = 6;
          continue;
        case 6:
          pc = 7;
          continue;
        case 7:
          s.evBitMod('evbit', true, 7);
          pc = 8;
          continue;
        case 8:
          return;
        default:
          return;
      }
    }
}

/// `frontier_df3_eventscr_ch_017_A6F47C + 0x90`
Future<void> frontier_df3_eventscr_ch_017_A6F47C_0x90(Scene s) async {
    var pc = 0;
    while (true) {
      switch (pc) {
        case 0:
          s.checkSlotValue('turn');
          pc = 1;
          continue;
        case 1:
          s.setSlot(1, 1);
          pc = 2;
          continue;
        case 2:
          s.slotArith('SAND', 12, 12);
          pc = 3;
          continue;
        case 3:
          if (s.slotInt(12) != s.slotInt(0)) { pc = 24; } else { pc = 4; }
          continue;
        case 4:
          s.setSlot(2, Sym('frontier_df3_unitdef_b_047_91E280_residue', 60));
          pc = 5;
          continue;
        case 5:
          await s.call(Sym('EventScr_LoadReinforce'));
          pc = 6;
          continue;
        case 6:
          pc = 7;
          continue;
        case 7:
          s.evBitMod('evbit', true, 7);
          pc = 8;
          continue;
        case 8:
          return;
        case 9:
          s.checkSlotValue('turn');
          pc = 10;
          continue;
        case 10:
          s.setSlot(1, 1);
          pc = 11;
          continue;
        case 11:
          s.slotArith('SAND', 12, 12);
          pc = 12;
          continue;
        case 12:
          if (s.slotInt(12) == s.slotInt(0)) { pc = 24; } else { pc = 13; }
          continue;
        case 13:
          s.setSlot(2, Sym('frontier_df3_unitdef_b_047_91E280_residue', 120));
          pc = 14;
          continue;
        case 14:
          await s.call(Sym('EventScr_LoadReinforce'));
          pc = 15;
          continue;
        case 15:
          pc = 16;
          continue;
        case 16:
          s.evBitMod('evbit', true, 7);
          pc = 17;
          continue;
        case 17:
          return;
        case 18:
          s.checkSlotValue('turn');
          pc = 19;
          continue;
        case 19:
          s.setSlot(1, 1);
          pc = 20;
          continue;
        case 20:
          s.slotArith('SAND', 12, 12);
          pc = 21;
          continue;
        case 21:
          if (s.slotInt(12) != s.slotInt(0)) { pc = 24; } else { pc = 22; }
          continue;
        case 22:
          s.setSlot(2, Sym('frontier_df3_unitdef_b_047_91E280_residue', 180));
          pc = 23;
          continue;
        case 23:
          await s.call(Sym('EventScr_LoadReinforce'));
          pc = 24;
          continue;
        case 24:
          pc = 25;
          continue;
        case 25:
          s.evBitMod('evbit', true, 7);
          pc = 26;
          continue;
        case 26:
          return;
        case 27:
          s.setSlot(2, Sym('frontier_df3_unitdef_b_047_91E280_residue', 240));
          pc = 28;
          continue;
        case 28:
          await s.call(Sym('EventScr_LoadReinforce'));
          pc = 29;
          continue;
        case 29:
          s.evBitMod('evbit', true, 7);
          pc = 30;
          continue;
        case 30:
          return;
        case 31:
          s.setSlot(2, Sym('frontier_df3_unitdef_b_047_91E280_residue', 340));
          pc = 32;
          continue;
        case 32:
          await s.call(Sym('EventScr_LoadReinforce'));
          pc = 33;
          continue;
        case 33:
          s.evBitMod('evbit', true, 7);
          pc = 34;
          continue;
        case 34:
          return;
        case 35:
          s.setSlot(2, Sym('UnitDef_Ch19BEnemy_0'));
          pc = 36;
          continue;
        case 36:
          await s.call(Sym('frontier_df3_eventscr_ch_003_A6AA20', 396));
          pc = 37;
          continue;
        case 37:
          s.loadUnits(1, Sym('UnitDef_Ch19BEnemy_0'));
          pc = 38;
          continue;
        case 38:
          await s.waitUnitMoving();
          pc = 39;
          continue;
        case 39:
          s.loadUnits(1, Sym('frontier_df3_unitdef_b_050_91EE14', 420));
          pc = 40;
          continue;
        case 40:
          await s.waitUnitMoving();
          pc = 41;
          continue;
        case 41:
          s.setSlot(2, Sym('frontier_df3_unitdef_b_051_91F300_residue', 180));
          pc = 42;
          continue;
        case 42:
          s.setSlot(3, 1);
          pc = 43;
          continue;
        case 43:
          await s.call(Sym('EventScr_LoadUnitForTutorial'));
          pc = 44;
          continue;
        case 44:
          await s.call(Sym('data_085B9BBC', 512));
          pc = 45;
          continue;
        case 45:
          s.evBitMod('flag', true, 10);
          pc = 46;
          continue;
        case 46:
          s.evBitMod('flag', true, 12);
          pc = 47;
          continue;
        case 47:
          s.evBitMod('flag', true, 14);
          pc = 48;
          continue;
        case 48:
          s.evBitMod('flag', true, 16);
          pc = 49;
          continue;
        case 49:
          return;
        default:
          return;
      }
    }
}

/// `frontier_df3_eventscr_ch_020_A6FB9C + 0x10`
Future<void> frontier_df3_eventscr_ch_020_A6FB9C_0x10(Scene s) async {
    var pc = 0;
    while (true) {
      switch (pc) {
        case 0:
          s.setSlot(2, Sym('frontier_df3_unitdef_b_052_91F89C', 220));
          pc = 1;
          continue;
        case 1:
          await s.call(Sym('EventScr_LoadReinforce'));
          pc = 2;
          continue;
        case 2:
          s.counterDec(2);
          pc = 3;
          continue;
        case 3:
          s.evBitMod('flag', false, 13);
          pc = 4;
          continue;
        case 4:
          s.counterCheck(2);
          pc = 5;
          continue;
        case 5:
          if (s.slotInt(12) != s.slotInt(0)) { pc = 7; } else { pc = 6; }
          continue;
        case 6:
          s.evBitMod('flag', true, 13);
          pc = 7;
          continue;
        case 7:
          pc = 8;
          continue;
        case 8:
          s.evBitMod('evbit', true, 7);
          pc = 9;
          continue;
        case 9:
          return;
        case 10:
          s.setSlot(2, 0);
          pc = 11;
          continue;
        case 11:
          await s.call(Sym('UnitDef_Ch14BAlly_7'));
          pc = 12;
          continue;
        case 12:
          s.setSlot(1, 65536);
          pc = 13;
          continue;
        case 13:
          s.placeholder('CHAI');
          pc = 14;
          continue;
        case 14:
          s.evBitMod('evbit', true, 7);
          pc = 15;
          continue;
        case 15:
          return;
        default:
          return;
      }
    }
}

/// ⚠️ `EventScr_Ch1Tut_GuideMsg944` —— 上游尚未 carve，生成的是**记录缺失**的占位
Future<void> missing_EventScr_Ch1Tut_GuideMsg944(Scene s) async {
  s.missing.add('EventScr_Ch1Tut_GuideMsg944');
}

/// ⚠️ `EventScr_Ch1Tut_GuideMsgSeize` —— 上游尚未 carve，生成的是**记录缺失**的占位
Future<void> missing_EventScr_Ch1Tut_GuideMsgSeize(Scene s) async {
  s.missing.add('EventScr_Ch1Tut_GuideMsgSeize');
}

/// ⚠️ `EventScr_Ch1Tut_GuideWTA` —— 上游尚未 carve，生成的是**记录缺失**的占位
Future<void> missing_EventScr_Ch1Tut_GuideWTA(Scene s) async {
  s.missing.add('EventScr_Ch1Tut_GuideWTA');
}

/// ⚠️ `EventScr_Ch2_9` —— 上游尚未 carve，生成的是**记录缺失**的占位
Future<void> missing_EventScr_Ch2_9(Scene s) async {
  s.missing.add('EventScr_Ch2_9');
}

/// ⚠️ `EventScr_Ch3_1` —— 上游尚未 carve，生成的是**记录缺失**的占位
Future<void> missing_EventScr_Ch3_1(Scene s) async {
  s.missing.add('EventScr_Ch3_1');
}

/// ⚠️ `EventScr_Ch3_2` —— 上游尚未 carve，生成的是**记录缺失**的占位
Future<void> missing_EventScr_Ch3_2(Scene s) async {
  s.missing.add('EventScr_Ch3_2');
}

/// ⚠️ `EventScr_Ch3_3` —— 上游尚未 carve，生成的是**记录缺失**的占位
Future<void> missing_EventScr_Ch3_3(Scene s) async {
  s.missing.add('EventScr_Ch3_3');
}

/// ⚠️ `EventScr_Ch3_4` —— 上游尚未 carve，生成的是**记录缺失**的占位
Future<void> missing_EventScr_Ch3_4(Scene s) async {
  s.missing.add('EventScr_Ch3_4');
}

/// ⚠️ `EventScr_Ch3_6` —— 上游尚未 carve，生成的是**记录缺失**的占位
Future<void> missing_EventScr_Ch3_6(Scene s) async {
  s.missing.add('EventScr_Ch3_6');
}

/// ⚠️ `EventScr_Ch3_7` —— 上游尚未 carve，生成的是**记录缺失**的占位
Future<void> missing_EventScr_Ch3_7(Scene s) async {
  s.missing.add('EventScr_Ch3_7');
}

/// ⚠️ `EventScr_Ch4_7` —— 上游尚未 carve，生成的是**记录缺失**的占位
Future<void> missing_EventScr_Ch4_7(Scene s) async {
  s.missing.add('EventScr_Ch4_7');
}

/// ⚠️ `EventScr_Ch4_8` —— 上游尚未 carve，生成的是**记录缺失**的占位
Future<void> missing_EventScr_Ch4_8(Scene s) async {
  s.missing.add('EventScr_Ch4_8');
}

/// ⚠️ `EventScr_Ch4_9` —— 上游尚未 carve，生成的是**记录缺失**的占位
Future<void> missing_EventScr_Ch4_9(Scene s) async {
  s.missing.add('EventScr_Ch4_9');
}

/// ⚠️ `EventScr_Ch5_8` —— 上游尚未 carve，生成的是**记录缺失**的占位
Future<void> missing_EventScr_Ch5_8(Scene s) async {
  s.missing.add('EventScr_Ch5_8');
}

/// ⚠️ `EventScr_Ch5_9` —— 上游尚未 carve，生成的是**记录缺失**的占位
Future<void> missing_EventScr_Ch5_9(Scene s) async {
  s.missing.add('EventScr_Ch5_9');
}

/// ⚠️ `EventScr_Ch7_3` —— 上游尚未 carve，生成的是**记录缺失**的占位
Future<void> missing_EventScr_Ch7_3(Scene s) async {
  s.missing.add('EventScr_Ch7_3');
}

/// **真正被 carve 出来**的脚本名。
///
/// ⚠️ 与 `allSceneFns` 的键**不一样**：后者还包含下面那些
/// 占位函数。存在性检查必须用本集合 —— 用 `allSceneFns` 的话
/// 占位让「缺失」看起来「存在」，检查就失效了（踩过）。
final Set<String> definedSceneScripts = {
  'EventScrWM_CastleFrelia_Beginning',
  'EventScrWM_Ch10a_Beginning',
  'EventScrWM_Ch10b_Beginning',
  'EventScrWM_Ch11a_Beginning',
  'EventScrWM_Ch11b_Beginning',
  'EventScrWM_Ch12a_Beginning',
  'EventScrWM_Ch12b_Beginning',
  'EventScrWM_Ch13a_Beginning',
  'EventScrWM_Ch13b_Beginning',
  'EventScrWM_Ch14a_Beginning',
  'EventScrWM_Ch14b_Beginning',
  'EventScrWM_Ch15a_Beginning',
  'EventScrWM_Ch15b_Beginning',
  'EventScrWM_Ch16a_Beginning',
  'EventScrWM_Ch16b_Beginning',
  'EventScrWM_Ch17a_Beginning',
  'EventScrWM_Ch17b_Beginning',
  'EventScrWM_Ch18a_Beginning',
  'EventScrWM_Ch18b_Beginning',
  'EventScrWM_Ch19a_Beginning',
  'EventScrWM_Ch19b_Beginning',
  'EventScrWM_Ch1_Beginning',
  'EventScrWM_Ch1_ChapterIntro',
  'EventScrWM_Ch20a_Beginning',
  'EventScrWM_Ch20b_Beginning',
  'EventScrWM_Ch21a_Beginning',
  'EventScrWM_Ch21ax_Beginning',
  'EventScrWM_Ch21b_Beginning',
  'EventScrWM_Ch21bx_Beginning',
  'EventScrWM_Ch2_Beginning',
  'EventScrWM_Ch2_BeginningTutorial',
  'EventScrWM_Ch2_ChapterIntro',
  'EventScrWM_Ch3_Beginning',
  'EventScrWM_Ch3_BeginningTutorial',
  'EventScrWM_Ch3_ChapterIntro',
  'EventScrWM_Ch4_Beginning',
  'EventScrWM_Ch4_ChapterIntro',
  'EventScrWM_Ch5_0',
  'EventScrWM_Ch5_1',
  'EventScrWM_Ch5_Beginning',
  'EventScrWM_Ch5_ChapterIntro',
  'EventScrWM_Ch5x_Beginning',
  'EventScrWM_Ch5x_ChapterIntro',
  'EventScrWM_Ch6_Beginning',
  'EventScrWM_Ch6_ChapterIntro',
  'EventScrWM_Ch7_Beginning',
  'EventScrWM_Ch7_ChapterIntro',
  'EventScrWM_Ch8_Beginning',
  'EventScrWM_Ch8_ChapterIntro',
  'EventScrWM_Ch9a_Beginning',
  'EventScrWM_Ch9a_ChapterIntro',
  'EventScrWM_Ch9b_Beginning',
  'EventScrWM_LagdouRuins10_Beginning',
  'EventScrWM_LagdouRuins1_Beginning',
  'EventScrWM_LagdouRuins2_Beginning',
  'EventScrWM_LagdouRuins3_Beginning',
  'EventScrWM_LagdouRuins4_Beginning',
  'EventScrWM_LagdouRuins5_Beginning',
  'EventScrWM_LagdouRuins6_Beginning',
  'EventScrWM_LagdouRuins7_Beginning',
  'EventScrWM_LagdouRuins8_Beginning',
  'EventScrWM_LagdouRuins9_Beginning',
  'EventScrWM_MelkaenCoast_Beginning',
  'EventScrWM_MessedEventscr_0',
  'EventScrWM_MessedEventscr_1',
  'EventScrWM_MessedEventscr_10',
  'EventScrWM_MessedEventscr_11',
  'EventScrWM_MessedEventscr_12',
  'EventScrWM_MessedEventscr_13',
  'EventScrWM_MessedEventscr_14',
  'EventScrWM_MessedEventscr_15',
  'EventScrWM_MessedEventscr_16',
  'EventScrWM_MessedEventscr_17',
  'EventScrWM_MessedEventscr_18',
  'EventScrWM_MessedEventscr_19',
  'EventScrWM_MessedEventscr_2',
  'EventScrWM_MessedEventscr_20',
  'EventScrWM_MessedEventscr_21',
  'EventScrWM_MessedEventscr_22',
  'EventScrWM_MessedEventscr_23',
  'EventScrWM_MessedEventscr_24',
  'EventScrWM_MessedEventscr_25',
  'EventScrWM_MessedEventscr_26',
  'EventScrWM_MessedEventscr_27',
  'EventScrWM_MessedEventscr_28',
  'EventScrWM_MessedEventscr_29',
  'EventScrWM_MessedEventscr_3',
  'EventScrWM_MessedEventscr_30',
  'EventScrWM_MessedEventscr_31',
  'EventScrWM_MessedEventscr_32',
  'EventScrWM_MessedEventscr_33',
  'EventScrWM_MessedEventscr_34',
  'EventScrWM_MessedEventscr_35',
  'EventScrWM_MessedEventscr_36',
  'EventScrWM_MessedEventscr_37',
  'EventScrWM_MessedEventscr_38',
  'EventScrWM_MessedEventscr_39',
  'EventScrWM_MessedEventscr_4',
  'EventScrWM_MessedEventscr_40',
  'EventScrWM_MessedEventscr_41',
  'EventScrWM_MessedEventscr_42',
  'EventScrWM_MessedEventscr_43',
  'EventScrWM_MessedEventscr_44',
  'EventScrWM_MessedEventscr_45',
  'EventScrWM_MessedEventscr_46',
  'EventScrWM_MessedEventscr_47',
  'EventScrWM_MessedEventscr_48',
  'EventScrWM_MessedEventscr_49',
  'EventScrWM_MessedEventscr_5',
  'EventScrWM_MessedEventscr_50',
  'EventScrWM_MessedEventscr_51',
  'EventScrWM_MessedEventscr_52',
  'EventScrWM_MessedEventscr_53',
  'EventScrWM_MessedEventscr_54',
  'EventScrWM_MessedEventscr_55',
  'EventScrWM_MessedEventscr_56',
  'EventScrWM_MessedEventscr_57',
  'EventScrWM_MessedEventscr_58',
  'EventScrWM_MessedEventscr_6',
  'EventScrWM_MessedEventscr_7',
  'EventScrWM_MessedEventscr_8',
  'EventScrWM_MessedEventscr_9',
  'EventScrWM_Prologue_Beginning',
  'EventScrWM_Prologue_ChapterIntro',
  'EventScrWM_ValniTower1_Beginning',
  'EventScrWM_ValniTower2_Beginning',
  'EventScrWM_ValniTower3_Beginning',
  'EventScrWM_ValniTower4_Beginning',
  'EventScrWM_ValniTower5_Beginning',
  'EventScrWM_ValniTower6_Beginning',
  'EventScrWM_ValniTower7_Beginning',
  'EventScrWM_ValniTower8_Beginning',
  'EventScr_9EE6A0',
  'EventScr_9EE6C8',
  'EventScr_9EE84C',
  'EventScr_9EE8F0',
  'EventScr_9EEA58',
  'EventScr_9EEAAC',
  'EventScr_9EEB00',
  'EventScr_ApplyActiveUnitTileChange',
  'EventScr_ApplyTileChangeForFaction',
  'EventScr_ApplyTileChangeForFactionIfAlly',
  'EventScr_ApplyTileChangeForFactionIfEnemy',
  'EventScr_ApplyTileChangeForFactionIfNPC',
  'EventScr_CallBreakStone',
  'EventScr_CallIfCommonMode',
  'EventScr_CallOnChapterNumber',
  'EventScr_CallOnHardMode',
  'EventScr_CallOnTutorialMode',
  'EventScr_CallWithModeCheck',
  'EventScr_Ch10A_0',
  'EventScr_Ch10A_10',
  'EventScr_Ch10A_11',
  'EventScr_Ch10A_12',
  'EventScr_Ch10A_13',
  'EventScr_Ch10A_8',
  'EventScr_Ch10A_9',
  'EventScr_Ch10B_0',
  'EventScr_Ch10B_1',
  'EventScr_Ch10B_2',
  'EventScr_Ch10a_BeginningScene',
  'EventScr_Ch10a_EndingScene',
  'EventScr_Ch11B_0',
  'EventScr_Ch11B_1',
  'EventScr_Ch11B_2',
  'EventScr_Ch11B_6',
  'EventScr_Ch11a_BeginningScene',
  'EventScr_Ch11a_EndingScene',
  'EventScr_Ch12A_0',
  'EventScr_Ch12A_1',
  'EventScr_Ch12A_2',
  'EventScr_Ch12A_3',
  'EventScr_Ch12A_4',
  'EventScr_Ch12A_5',
  'EventScr_Ch12B_1',
  'EventScr_Ch13A_3',
  'EventScr_Ch13A_4',
  'EventScr_Ch13A_5',
  'EventScr_Ch13A_6',
  'EventScr_Ch13A_7',
  'EventScr_Ch13B_0',
  'EventScr_Ch13B_1',
  'EventScr_Ch13a_EndingScene',
  'EventScr_Ch13b_EndingScene',
  'EventScr_Ch14A_0',
  'EventScr_Ch14A_1',
  'EventScr_Ch14A_2',
  'EventScr_Ch14A_3',
  'EventScr_Ch14A_4',
  'EventScr_Ch14A_5',
  'EventScr_Ch14A_6',
  'EventScr_Ch14A_7',
  'EventScr_Ch14A_8',
  'EventScr_Ch14B_12',
  'EventScr_Ch14B_2',
  'EventScr_Ch14a_BeginningScene',
  'EventScr_Ch14b_BeginningScene',
  'EventScr_Ch14b_EndingScene',
  'EventScr_Ch15A_0',
  'EventScr_Ch15A_1',
  'EventScr_Ch15A_17',
  'EventScr_Ch15A_18',
  'EventScr_Ch15A_19',
  'EventScr_Ch15A_2',
  'EventScr_Ch15A_20',
  'EventScr_Ch15A_21',
  'EventScr_Ch15A_22',
  'EventScr_Ch15A_23',
  'EventScr_Ch15A_24',
  'EventScr_Ch15A_25',
  'EventScr_Ch15A_26',
  'EventScr_Ch15B_14',
  'EventScr_Ch15B_15',
  'EventScr_Ch15B_16',
  'EventScr_Ch15B_17',
  'EventScr_Ch15B_18',
  'EventScr_Ch15B_19',
  'EventScr_Ch15B_20',
  'EventScr_Ch15B_21',
  'EventScr_Ch15B_22',
  'EventScr_Ch15a_BeginningScene',
  'EventScr_Ch16A_0',
  'EventScr_Ch16A_1',
  'EventScr_Ch16A_11',
  'EventScr_Ch16A_12',
  'EventScr_Ch16A_9',
  'EventScr_Ch16B_3',
  'EventScr_Ch16B_5',
  'EventScr_Ch16a_BeginningScene',
  'EventScr_Ch16b_BeginningScene',
  'EventScr_Ch18A_11',
  'EventScr_Ch18b_BeginningScene',
  'EventScr_Ch19A_11',
  'EventScr_Ch1Tut_AfterSethBattleEirikaVisit',
  'EventScr_Ch1Tut_AfterSethMoveToEnemy',
  'EventScr_Ch1Tut_AfterTrade',
  'EventScr_Ch1Tut_BeforeSethMoveToEnemy',
  'EventScr_Ch1Tut_ChooseSethTurn1',
  'EventScr_Ch1Tut_EirikaVisitHouseEnd',
  'EventScr_Ch1Tut_EirikaVisitHouseIdle1',
  'EventScr_Ch1Tut_EirikaVisitHouseIdle2',
  'EventScr_Ch1Tut_EirikaVisitHouseInit',
  'EventScr_Ch1Tut_GilliamBattle',
  'EventScr_Ch1Tut_GuideOnBKSEL',
  'EventScr_Ch1Tut_GuideTerrainHeal',
  'EventScr_Ch1Tut_MsgOnGuideOption',
  'EventScr_Ch1Tut_OnBeginning',
  'EventScr_Ch1Tut_PostTradeAndItemUseAction',
  'EventScr_Ch1Tut_SethMoveToEnemy',
  'EventScr_Ch1Tut_TradeSelectGalliamEnd',
  'EventScr_Ch1Tut_TradeSelectGalliamIdle1',
  'EventScr_Ch1Tut_TradeSelectGalliamIdle2',
  'EventScr_Ch1_BeginningScene',
  'EventScr_Ch1_EndingScene',
  'EventScr_Ch1_Loca_Visit1',
  'EventScr_Ch1_Loca_Visit2',
  'EventScr_Ch1_Misc_Area',
  'EventScr_Ch1_Misc_DefeatBoss',
  'EventScr_Ch1_Turn1Player',
  'EventScr_Ch1_Turn_AllyReinforceArrive',
  'EventScr_Ch1_Turn_EnemyReinforceArrive',
  'EventScr_Ch20B_1',
  'EventScr_Ch20B_2',
  'EventScr_Ch20b_BeginningScene',
  'EventScr_Ch21A_0',
  'EventScr_Ch21A_8',
  'EventScr_Ch21A_9',
  'EventScr_Ch21b_BeginningScene',
  'EventScr_Ch21b_EndingScene',
  'EventScr_Ch2Tutorial10',
  'EventScr_Ch2Tutorial11',
  'EventScr_Ch2Tutorial12',
  'EventScr_Ch2Tutorial13',
  'EventScr_Ch2Tutorial14',
  'EventScr_Ch2Tutorial15',
  'EventScr_Ch2Tutorial16',
  'EventScr_Ch2Tutorial17',
  'EventScr_Ch2Tutorial18',
  'EventScr_Ch2Tutorial19',
  'EventScr_Ch2Tutorial2',
  'EventScr_Ch2Tutorial20',
  'EventScr_Ch2Tutorial21',
  'EventScr_Ch2Tutorial22',
  'EventScr_Ch2Tutorial23',
  'EventScr_Ch2Tutorial24',
  'EventScr_Ch2Tutorial25',
  'EventScr_Ch2Tutorial26',
  'EventScr_Ch2Tutorial27',
  'EventScr_Ch2Tutorial28',
  'EventScr_Ch2Tutorial29',
  'EventScr_Ch2Tutorial3',
  'EventScr_Ch2Tutorial30',
  'EventScr_Ch2Tutorial4',
  'EventScr_Ch2Tutorial5',
  'EventScr_Ch2Tutorial6',
  'EventScr_Ch2Tutorial7',
  'EventScr_Ch2Tutorial8',
  'EventScr_Ch2Tutorial9',
  'EventScr_Ch2_10',
  'EventScr_Ch2_4',
  'EventScr_Ch2_5',
  'EventScr_Ch2_6',
  'EventScr_Ch2_7',
  'EventScr_Ch2_8',
  'EventScr_Ch2_BeginningScene',
  'EventScr_Ch2_EndingScene',
  'EventScr_Ch2_Turn1Player',
  'EventScr_Ch2_Turn2Player',
  'EventScr_Ch2_Village1',
  'EventScr_Ch2_Village2',
  'EventScr_Ch3_0',
  'EventScr_Ch3_5',
  'EventScr_Ch3_BeginningScene',
  'EventScr_Ch3_EndingScene',
  'EventScr_Ch3_Talk_NeimiColm',
  'EventScr_Ch3_Turn1Npc',
  'EventScr_Ch3_Turn2Player',
  'EventScr_Ch4_0',
  'EventScr_Ch4_1',
  'EventScr_Ch4_10',
  'EventScr_Ch4_2',
  'EventScr_Ch4_3',
  'EventScr_Ch4_4',
  'EventScr_Ch4_5',
  'EventScr_Ch4_6',
  'EventScr_Ch4_BeginningScene',
  'EventScr_Ch5_0',
  'EventScr_Ch5_1',
  'EventScr_Ch5_10',
  'EventScr_Ch5_11',
  'EventScr_Ch5_2',
  'EventScr_Ch5_3',
  'EventScr_Ch5_5',
  'EventScr_Ch5_6',
  'EventScr_Ch5_7',
  'EventScr_Ch5_BeginningScene',
  'EventScr_Ch5_EndingScene',
  'EventScr_Ch5x_BeginningScene',
  'EventScr_Ch5x_EndingScene',
  'EventScr_Ch6_0',
  'EventScr_Ch6_1',
  'EventScr_Ch6_2',
  'EventScr_Ch6_3',
  'EventScr_Ch6_4',
  'EventScr_Ch6_BeginningScene',
  'EventScr_Ch6_EndingScene',
  'EventScr_Ch7_1',
  'EventScr_Ch7_2',
  'EventScr_Ch7_BeginningScene',
  'EventScr_Ch7_EndingScene',
  'EventScr_Ch8_0',
  'EventScr_Ch8_10',
  'EventScr_Ch8_11',
  'EventScr_Ch8_BeginningScene',
  'EventScr_Ch8_EndingScene',
  'EventScr_Ch9A_2',
  'EventScr_Ch9A_3',
  'EventScr_Ch9A_4',
  'EventScr_Ch9A_5',
  'EventScr_Ch9B_9',
  'EventScr_Ch9a_BeginningScene',
  'EventScr_Ch9a_EndingScene',
  'EventScr_ChangeAIinQueue',
  'EventScr_ConfigHardModeLoadUnitHard',
  'EventScr_CutsceneExecEnd_Sub0',
  'EventScr_CutsceneExecEnd_Sub1',
  'EventScr_FloorClearInTower',
  'EventScr_FormatFlashingCursor',
  'EventScr_FormatMoveUnit',
  'EventScr_GiveTreasureToLuckyDog',
  'EventScr_LoadReinforce',
  'EventScr_LoadReinforceHardMode',
  'EventScr_LoadUniqueAlly',
  'EventScr_LoadUnitForDifferentMode',
  'EventScr_LoadUnitForTutorial',
  'EventScr_MapSupportConversation',
  'EventScr_MoveUnitS2ToLeader',
  'EventScr_Prologue_9EF828',
  'EventScr_Prologue_BeginningScene',
  'EventScr_Prologue_EirikaAttacked',
  'EventScr_Prologue_EndingScene',
  'EventScr_Prologue_ExecTut',
  'EventScr_Prologue_GiveRapier',
  'EventScr_Prologue_ONeillSpawn',
  'EventScr_Prologue_OneEnemyLeft',
  'EventScr_Prologue_OneillSethBattle',
  'EventScr_Prologue_RenaisThroneCutscene',
  'EventScr_Prologue_Turn1',
  'EventScr_Prologue_Turn2',
  'EventScr_Prologue_Turn3',
  'EventScr_Prologue_TutEirikaAttack',
  'EventScr_Prologue_TutMessageTurn1',
  'EventScr_Prologue_TutMessageTurn2',
  'EventScr_Prologue_Tutorial0',
  'EventScr_Prologue_Tutorial1',
  'EventScr_Prologue_Tutorial2',
  'EventScr_Prologue_Tutorial3',
  'EventScr_Prologue_Tutorial4',
  'EventScr_Prologue_Tutorial5',
  'EventScr_Prologue_Tutorial6',
  'EventScr_Prologue_Tutorial7',
  'EventScr_Prologue_Tutorial8',
  'EventScr_Prologue_Tutorial9',
  'EventScr_Prologue_TutorialA',
  'EventScr_Prologue_TutorialB',
  'EventScr_Prologue_TutorialC',
  'EventScr_Prologue_TutorialD',
  'EventScr_Prologue_TutorialE',
  'EventScr_Ruin_37',
  'EventScr_Ruin_38',
  'EventScr_Ruin_39',
  'EventScr_Ruin_40',
  'EventScr_Ruin_41',
  'EventScr_Ruin_42',
  'EventScr_Ruin_45',
  'EventScr_Ruin_47',
  'EventScr_Ruin_48',
  'EventScr_Ruin_54',
  'EventScr_Ruin_56',
  'EventScr_Ruin_58',
  'EventScr_Ruin_60',
  'EventScr_Ruin_62',
  'EventScr_Ruin_64',
  'EventScr_Ruin_66',
  'EventScr_Ruin_68',
  'EventScr_Ruin_70',
  'EventScr_Ruin_72',
  'EventScr_Ruin_74',
  'EventScr_Ruin_76',
  'EventScr_SetBackground',
  'EventScr_SetFlagIfPlayedThrough',
  'EventScr_SkirmishRetreat',
  'EventScr_StrictLoadUniqueAlly',
  'EventScr_SuspendPrompt',
  'EventScr_TextShowWithFadeIn',
  'EventScr_Tutorial_Exec0',
  'EventScr_Tutorial_Exec1',
  'EventScr_UnTriggerIfNotUnit',
  'EventScr_UnitFlushingIN',
  'EventScr_UnitFlushingOUT',
  'EventScr_UnitWarpIN',
  'EventScr_UnitWarpOUT',
  'EventScr_WM_FadeCommon',
  'EventScr_WholeTowerClear',
  'frontier_df3_eventscr_ch_014_A6EDFC + 0x98',
  'frontier_df3_eventscr_ch_015_A6EF04',
  'frontier_df3_eventscr_ch_016_A6EFD8 + 0x24',
  'frontier_df3_eventscr_ch_016_A6EFD8 + 0x3C',
  'frontier_df3_eventscr_ch_016_A6EFD8 + 0xC',
  'frontier_df3_eventscr_ch_017_A6F47C + 0x1B8',
  'frontier_df3_eventscr_ch_017_A6F47C + 0x1C',
  'frontier_df3_eventscr_ch_017_A6F47C + 0x270',
  'frontier_df3_eventscr_ch_017_A6F47C + 0x2B4',
  'frontier_df3_eventscr_ch_017_A6F47C + 0x2C',
  'frontier_df3_eventscr_ch_017_A6F47C + 0x2F8',
  'frontier_df3_eventscr_ch_017_A6F47C + 0x318',
  'frontier_df3_eventscr_ch_017_A6F47C + 0x34C',
  'frontier_df3_eventscr_ch_017_A6F47C + 0x36C',
  'frontier_df3_eventscr_ch_017_A6F47C + 0x3D4',
  'frontier_df3_eventscr_ch_017_A6F47C + 0x3F4',
  'frontier_df3_eventscr_ch_017_A6F47C + 0x44',
  'frontier_df3_eventscr_ch_017_A6F47C + 0x45C',
  'frontier_df3_eventscr_ch_017_A6F47C + 0x47C',
  'frontier_df3_eventscr_ch_017_A6F47C + 0x534',
  'frontier_df3_eventscr_ch_017_A6F47C + 0x598',
  'frontier_df3_eventscr_ch_017_A6F47C + 0x5C',
  'frontier_df3_eventscr_ch_017_A6F47C + 0x90',
  'frontier_df3_eventscr_ch_020_A6FB9C + 0x10',
};

/// 脚本名 → 入口函数
final Map<String, Future<void> Function(Scene)> allSceneFns = {
  'EventScrWM_CastleFrelia_Beginning': EventScrWM_CastleFrelia_Beginning,
  'EventScrWM_Ch10a_Beginning': EventScrWM_Ch10a_Beginning,
  'EventScrWM_Ch10b_Beginning': EventScrWM_Ch10b_Beginning,
  'EventScrWM_Ch11a_Beginning': EventScrWM_Ch11a_Beginning,
  'EventScrWM_Ch11b_Beginning': EventScrWM_Ch11b_Beginning,
  'EventScrWM_Ch12a_Beginning': EventScrWM_Ch12a_Beginning,
  'EventScrWM_Ch12b_Beginning': EventScrWM_Ch12b_Beginning,
  'EventScrWM_Ch13a_Beginning': EventScrWM_Ch13a_Beginning,
  'EventScrWM_Ch13b_Beginning': EventScrWM_Ch13b_Beginning,
  'EventScrWM_Ch14a_Beginning': EventScrWM_Ch14a_Beginning,
  'EventScrWM_Ch14b_Beginning': EventScrWM_Ch14b_Beginning,
  'EventScrWM_Ch15a_Beginning': EventScrWM_Ch15a_Beginning,
  'EventScrWM_Ch15b_Beginning': EventScrWM_Ch15b_Beginning,
  'EventScrWM_Ch16a_Beginning': EventScrWM_Ch16a_Beginning,
  'EventScrWM_Ch16b_Beginning': EventScrWM_Ch16b_Beginning,
  'EventScrWM_Ch17a_Beginning': EventScrWM_Ch17a_Beginning,
  'EventScrWM_Ch17b_Beginning': EventScrWM_Ch17b_Beginning,
  'EventScrWM_Ch18a_Beginning': EventScrWM_Ch18a_Beginning,
  'EventScrWM_Ch18b_Beginning': EventScrWM_Ch18b_Beginning,
  'EventScrWM_Ch19a_Beginning': EventScrWM_Ch19a_Beginning,
  'EventScrWM_Ch19b_Beginning': EventScrWM_Ch19b_Beginning,
  'EventScrWM_Ch1_Beginning': EventScrWM_Ch1_Beginning,
  'EventScrWM_Ch1_ChapterIntro': EventScrWM_Ch1_ChapterIntro,
  'EventScrWM_Ch20a_Beginning': EventScrWM_Ch20a_Beginning,
  'EventScrWM_Ch20b_Beginning': EventScrWM_Ch20b_Beginning,
  'EventScrWM_Ch21a_Beginning': EventScrWM_Ch21a_Beginning,
  'EventScrWM_Ch21ax_Beginning': EventScrWM_Ch21ax_Beginning,
  'EventScrWM_Ch21b_Beginning': EventScrWM_Ch21b_Beginning,
  'EventScrWM_Ch21bx_Beginning': EventScrWM_Ch21bx_Beginning,
  'EventScrWM_Ch2_Beginning': EventScrWM_Ch2_Beginning,
  'EventScrWM_Ch2_BeginningTutorial': EventScrWM_Ch2_BeginningTutorial,
  'EventScrWM_Ch2_ChapterIntro': EventScrWM_Ch2_ChapterIntro,
  'EventScrWM_Ch3_Beginning': EventScrWM_Ch3_Beginning,
  'EventScrWM_Ch3_BeginningTutorial': EventScrWM_Ch3_BeginningTutorial,
  'EventScrWM_Ch3_ChapterIntro': EventScrWM_Ch3_ChapterIntro,
  'EventScrWM_Ch4_Beginning': EventScrWM_Ch4_Beginning,
  'EventScrWM_Ch4_ChapterIntro': EventScrWM_Ch4_ChapterIntro,
  'EventScrWM_Ch5_0': EventScrWM_Ch5_0,
  'EventScrWM_Ch5_1': EventScrWM_Ch5_1,
  'EventScrWM_Ch5_Beginning': EventScrWM_Ch5_Beginning,
  'EventScrWM_Ch5_ChapterIntro': EventScrWM_Ch5_ChapterIntro,
  'EventScrWM_Ch5x_Beginning': EventScrWM_Ch5x_Beginning,
  'EventScrWM_Ch5x_ChapterIntro': EventScrWM_Ch5x_ChapterIntro,
  'EventScrWM_Ch6_Beginning': EventScrWM_Ch6_Beginning,
  'EventScrWM_Ch6_ChapterIntro': EventScrWM_Ch6_ChapterIntro,
  'EventScrWM_Ch7_Beginning': EventScrWM_Ch7_Beginning,
  'EventScrWM_Ch7_ChapterIntro': EventScrWM_Ch7_ChapterIntro,
  'EventScrWM_Ch8_Beginning': EventScrWM_Ch8_Beginning,
  'EventScrWM_Ch8_ChapterIntro': EventScrWM_Ch8_ChapterIntro,
  'EventScrWM_Ch9a_Beginning': EventScrWM_Ch9a_Beginning,
  'EventScrWM_Ch9a_ChapterIntro': EventScrWM_Ch9a_ChapterIntro,
  'EventScrWM_Ch9b_Beginning': EventScrWM_Ch9b_Beginning,
  'EventScrWM_LagdouRuins10_Beginning': EventScrWM_LagdouRuins10_Beginning,
  'EventScrWM_LagdouRuins1_Beginning': EventScrWM_LagdouRuins1_Beginning,
  'EventScrWM_LagdouRuins2_Beginning': EventScrWM_LagdouRuins2_Beginning,
  'EventScrWM_LagdouRuins3_Beginning': EventScrWM_LagdouRuins3_Beginning,
  'EventScrWM_LagdouRuins4_Beginning': EventScrWM_LagdouRuins4_Beginning,
  'EventScrWM_LagdouRuins5_Beginning': EventScrWM_LagdouRuins5_Beginning,
  'EventScrWM_LagdouRuins6_Beginning': EventScrWM_LagdouRuins6_Beginning,
  'EventScrWM_LagdouRuins7_Beginning': EventScrWM_LagdouRuins7_Beginning,
  'EventScrWM_LagdouRuins8_Beginning': EventScrWM_LagdouRuins8_Beginning,
  'EventScrWM_LagdouRuins9_Beginning': EventScrWM_LagdouRuins9_Beginning,
  'EventScrWM_MelkaenCoast_Beginning': EventScrWM_MelkaenCoast_Beginning,
  'EventScrWM_MessedEventscr_0': EventScrWM_MessedEventscr_0,
  'EventScrWM_MessedEventscr_1': EventScrWM_MessedEventscr_1,
  'EventScrWM_MessedEventscr_10': EventScrWM_MessedEventscr_10,
  'EventScrWM_MessedEventscr_11': EventScrWM_MessedEventscr_11,
  'EventScrWM_MessedEventscr_12': EventScrWM_MessedEventscr_12,
  'EventScrWM_MessedEventscr_13': EventScrWM_MessedEventscr_13,
  'EventScrWM_MessedEventscr_14': EventScrWM_MessedEventscr_14,
  'EventScrWM_MessedEventscr_15': EventScrWM_MessedEventscr_15,
  'EventScrWM_MessedEventscr_16': EventScrWM_MessedEventscr_16,
  'EventScrWM_MessedEventscr_17': EventScrWM_MessedEventscr_17,
  'EventScrWM_MessedEventscr_18': EventScrWM_MessedEventscr_18,
  'EventScrWM_MessedEventscr_19': EventScrWM_MessedEventscr_19,
  'EventScrWM_MessedEventscr_2': EventScrWM_MessedEventscr_2,
  'EventScrWM_MessedEventscr_20': EventScrWM_MessedEventscr_20,
  'EventScrWM_MessedEventscr_21': EventScrWM_MessedEventscr_21,
  'EventScrWM_MessedEventscr_22': EventScrWM_MessedEventscr_22,
  'EventScrWM_MessedEventscr_23': EventScrWM_MessedEventscr_23,
  'EventScrWM_MessedEventscr_24': EventScrWM_MessedEventscr_24,
  'EventScrWM_MessedEventscr_25': EventScrWM_MessedEventscr_25,
  'EventScrWM_MessedEventscr_26': EventScrWM_MessedEventscr_26,
  'EventScrWM_MessedEventscr_27': EventScrWM_MessedEventscr_27,
  'EventScrWM_MessedEventscr_28': EventScrWM_MessedEventscr_28,
  'EventScrWM_MessedEventscr_29': EventScrWM_MessedEventscr_29,
  'EventScrWM_MessedEventscr_3': EventScrWM_MessedEventscr_3,
  'EventScrWM_MessedEventscr_30': EventScrWM_MessedEventscr_30,
  'EventScrWM_MessedEventscr_31': EventScrWM_MessedEventscr_31,
  'EventScrWM_MessedEventscr_32': EventScrWM_MessedEventscr_32,
  'EventScrWM_MessedEventscr_33': EventScrWM_MessedEventscr_33,
  'EventScrWM_MessedEventscr_34': EventScrWM_MessedEventscr_34,
  'EventScrWM_MessedEventscr_35': EventScrWM_MessedEventscr_35,
  'EventScrWM_MessedEventscr_36': EventScrWM_MessedEventscr_36,
  'EventScrWM_MessedEventscr_37': EventScrWM_MessedEventscr_37,
  'EventScrWM_MessedEventscr_38': EventScrWM_MessedEventscr_38,
  'EventScrWM_MessedEventscr_39': EventScrWM_MessedEventscr_39,
  'EventScrWM_MessedEventscr_4': EventScrWM_MessedEventscr_4,
  'EventScrWM_MessedEventscr_40': EventScrWM_MessedEventscr_40,
  'EventScrWM_MessedEventscr_41': EventScrWM_MessedEventscr_41,
  'EventScrWM_MessedEventscr_42': EventScrWM_MessedEventscr_42,
  'EventScrWM_MessedEventscr_43': EventScrWM_MessedEventscr_43,
  'EventScrWM_MessedEventscr_44': EventScrWM_MessedEventscr_44,
  'EventScrWM_MessedEventscr_45': EventScrWM_MessedEventscr_45,
  'EventScrWM_MessedEventscr_46': EventScrWM_MessedEventscr_46,
  'EventScrWM_MessedEventscr_47': EventScrWM_MessedEventscr_47,
  'EventScrWM_MessedEventscr_48': EventScrWM_MessedEventscr_48,
  'EventScrWM_MessedEventscr_49': EventScrWM_MessedEventscr_49,
  'EventScrWM_MessedEventscr_5': EventScrWM_MessedEventscr_5,
  'EventScrWM_MessedEventscr_50': EventScrWM_MessedEventscr_50,
  'EventScrWM_MessedEventscr_51': EventScrWM_MessedEventscr_51,
  'EventScrWM_MessedEventscr_52': EventScrWM_MessedEventscr_52,
  'EventScrWM_MessedEventscr_53': EventScrWM_MessedEventscr_53,
  'EventScrWM_MessedEventscr_54': EventScrWM_MessedEventscr_54,
  'EventScrWM_MessedEventscr_55': EventScrWM_MessedEventscr_55,
  'EventScrWM_MessedEventscr_56': EventScrWM_MessedEventscr_56,
  'EventScrWM_MessedEventscr_57': EventScrWM_MessedEventscr_57,
  'EventScrWM_MessedEventscr_58': EventScrWM_MessedEventscr_58,
  'EventScrWM_MessedEventscr_6': EventScrWM_MessedEventscr_6,
  'EventScrWM_MessedEventscr_7': EventScrWM_MessedEventscr_7,
  'EventScrWM_MessedEventscr_8': EventScrWM_MessedEventscr_8,
  'EventScrWM_MessedEventscr_9': EventScrWM_MessedEventscr_9,
  'EventScrWM_Prologue_Beginning': EventScrWM_Prologue_Beginning,
  'EventScrWM_Prologue_ChapterIntro': EventScrWM_Prologue_ChapterIntro,
  'EventScrWM_ValniTower1_Beginning': EventScrWM_ValniTower1_Beginning,
  'EventScrWM_ValniTower2_Beginning': EventScrWM_ValniTower2_Beginning,
  'EventScrWM_ValniTower3_Beginning': EventScrWM_ValniTower3_Beginning,
  'EventScrWM_ValniTower4_Beginning': EventScrWM_ValniTower4_Beginning,
  'EventScrWM_ValniTower5_Beginning': EventScrWM_ValniTower5_Beginning,
  'EventScrWM_ValniTower6_Beginning': EventScrWM_ValniTower6_Beginning,
  'EventScrWM_ValniTower7_Beginning': EventScrWM_ValniTower7_Beginning,
  'EventScrWM_ValniTower8_Beginning': EventScrWM_ValniTower8_Beginning,
  'EventScr_9EE6A0': scr_9EE6A0,
  'EventScr_9EE6C8': scr_9EE6C8,
  'EventScr_9EE84C': scr_9EE84C,
  'EventScr_9EE8F0': scr_9EE8F0,
  'EventScr_9EEA58': scr_9EEA58,
  'EventScr_9EEAAC': scr_9EEAAC,
  'EventScr_9EEB00': scr_9EEB00,
  'EventScr_ApplyActiveUnitTileChange': ApplyActiveUnitTileChange,
  'EventScr_ApplyTileChangeForFaction': ApplyTileChangeForFaction,
  'EventScr_ApplyTileChangeForFactionIfAlly': ApplyTileChangeForFactionIfAlly,
  'EventScr_ApplyTileChangeForFactionIfEnemy': ApplyTileChangeForFactionIfEnemy,
  'EventScr_ApplyTileChangeForFactionIfNPC': ApplyTileChangeForFactionIfNPC,
  'EventScr_CallBreakStone': CallBreakStone,
  'EventScr_CallIfCommonMode': CallIfCommonMode,
  'EventScr_CallOnChapterNumber': CallOnChapterNumber,
  'EventScr_CallOnHardMode': CallOnHardMode,
  'EventScr_CallOnTutorialMode': CallOnTutorialMode,
  'EventScr_CallWithModeCheck': CallWithModeCheck,
  'EventScr_Ch10A_0': Ch10A_0,
  'EventScr_Ch10A_10': Ch10A_10,
  'EventScr_Ch10A_11': Ch10A_11,
  'EventScr_Ch10A_12': Ch10A_12,
  'EventScr_Ch10A_13': Ch10A_13,
  'EventScr_Ch10A_8': Ch10A_8,
  'EventScr_Ch10A_9': Ch10A_9,
  'EventScr_Ch10B_0': Ch10B_0,
  'EventScr_Ch10B_1': Ch10B_1,
  'EventScr_Ch10B_2': Ch10B_2,
  'EventScr_Ch10a_BeginningScene': Ch10a_BeginningScene,
  'EventScr_Ch10a_EndingScene': Ch10a_EndingScene,
  'EventScr_Ch11B_0': Ch11B_0,
  'EventScr_Ch11B_1': Ch11B_1,
  'EventScr_Ch11B_2': Ch11B_2,
  'EventScr_Ch11B_6': Ch11B_6,
  'EventScr_Ch11a_BeginningScene': Ch11a_BeginningScene,
  'EventScr_Ch11a_EndingScene': Ch11a_EndingScene,
  'EventScr_Ch12A_0': Ch12A_0,
  'EventScr_Ch12A_1': Ch12A_1,
  'EventScr_Ch12A_2': Ch12A_2,
  'EventScr_Ch12A_3': Ch12A_3,
  'EventScr_Ch12A_4': Ch12A_4,
  'EventScr_Ch12A_5': Ch12A_5,
  'EventScr_Ch12B_1': Ch12B_1,
  'EventScr_Ch13A_3': Ch13A_3,
  'EventScr_Ch13A_4': Ch13A_4,
  'EventScr_Ch13A_5': Ch13A_5,
  'EventScr_Ch13A_6': Ch13A_6,
  'EventScr_Ch13A_7': Ch13A_7,
  'EventScr_Ch13B_0': Ch13B_0,
  'EventScr_Ch13B_1': Ch13B_1,
  'EventScr_Ch13a_EndingScene': Ch13a_EndingScene,
  'EventScr_Ch13b_EndingScene': Ch13b_EndingScene,
  'EventScr_Ch14A_0': Ch14A_0,
  'EventScr_Ch14A_1': Ch14A_1,
  'EventScr_Ch14A_2': Ch14A_2,
  'EventScr_Ch14A_3': Ch14A_3,
  'EventScr_Ch14A_4': Ch14A_4,
  'EventScr_Ch14A_5': Ch14A_5,
  'EventScr_Ch14A_6': Ch14A_6,
  'EventScr_Ch14A_7': Ch14A_7,
  'EventScr_Ch14A_8': Ch14A_8,
  'EventScr_Ch14B_12': Ch14B_12,
  'EventScr_Ch14B_2': Ch14B_2,
  'EventScr_Ch14a_BeginningScene': Ch14a_BeginningScene,
  'EventScr_Ch14b_BeginningScene': Ch14b_BeginningScene,
  'EventScr_Ch14b_EndingScene': Ch14b_EndingScene,
  'EventScr_Ch15A_0': Ch15A_0,
  'EventScr_Ch15A_1': Ch15A_1,
  'EventScr_Ch15A_17': Ch15A_17,
  'EventScr_Ch15A_18': Ch15A_18,
  'EventScr_Ch15A_19': Ch15A_19,
  'EventScr_Ch15A_2': Ch15A_2,
  'EventScr_Ch15A_20': Ch15A_20,
  'EventScr_Ch15A_21': Ch15A_21,
  'EventScr_Ch15A_22': Ch15A_22,
  'EventScr_Ch15A_23': Ch15A_23,
  'EventScr_Ch15A_24': Ch15A_24,
  'EventScr_Ch15A_25': Ch15A_25,
  'EventScr_Ch15A_26': Ch15A_26,
  'EventScr_Ch15B_14': Ch15B_14,
  'EventScr_Ch15B_15': Ch15B_15,
  'EventScr_Ch15B_16': Ch15B_16,
  'EventScr_Ch15B_17': Ch15B_17,
  'EventScr_Ch15B_18': Ch15B_18,
  'EventScr_Ch15B_19': Ch15B_19,
  'EventScr_Ch15B_20': Ch15B_20,
  'EventScr_Ch15B_21': Ch15B_21,
  'EventScr_Ch15B_22': Ch15B_22,
  'EventScr_Ch15a_BeginningScene': Ch15a_BeginningScene,
  'EventScr_Ch16A_0': Ch16A_0,
  'EventScr_Ch16A_1': Ch16A_1,
  'EventScr_Ch16A_11': Ch16A_11,
  'EventScr_Ch16A_12': Ch16A_12,
  'EventScr_Ch16A_9': Ch16A_9,
  'EventScr_Ch16B_3': Ch16B_3,
  'EventScr_Ch16B_5': Ch16B_5,
  'EventScr_Ch16a_BeginningScene': Ch16a_BeginningScene,
  'EventScr_Ch16b_BeginningScene': Ch16b_BeginningScene,
  'EventScr_Ch18A_11': Ch18A_11,
  'EventScr_Ch18b_BeginningScene': Ch18b_BeginningScene,
  'EventScr_Ch19A_11': Ch19A_11,
  'EventScr_Ch1Tut_AfterSethBattleEirikaVisit': Ch1Tut_AfterSethBattleEirikaVisit,
  'EventScr_Ch1Tut_AfterSethMoveToEnemy': Ch1Tut_AfterSethMoveToEnemy,
  'EventScr_Ch1Tut_AfterTrade': Ch1Tut_AfterTrade,
  'EventScr_Ch1Tut_BeforeSethMoveToEnemy': Ch1Tut_BeforeSethMoveToEnemy,
  'EventScr_Ch1Tut_ChooseSethTurn1': Ch1Tut_ChooseSethTurn1,
  'EventScr_Ch1Tut_EirikaVisitHouseEnd': Ch1Tut_EirikaVisitHouseEnd,
  'EventScr_Ch1Tut_EirikaVisitHouseIdle1': Ch1Tut_EirikaVisitHouseIdle1,
  'EventScr_Ch1Tut_EirikaVisitHouseIdle2': Ch1Tut_EirikaVisitHouseIdle2,
  'EventScr_Ch1Tut_EirikaVisitHouseInit': Ch1Tut_EirikaVisitHouseInit,
  'EventScr_Ch1Tut_GilliamBattle': Ch1Tut_GilliamBattle,
  'EventScr_Ch1Tut_GuideOnBKSEL': Ch1Tut_GuideOnBKSEL,
  'EventScr_Ch1Tut_GuideTerrainHeal': Ch1Tut_GuideTerrainHeal,
  'EventScr_Ch1Tut_MsgOnGuideOption': Ch1Tut_MsgOnGuideOption,
  'EventScr_Ch1Tut_OnBeginning': Ch1Tut_OnBeginning,
  'EventScr_Ch1Tut_PostTradeAndItemUseAction': Ch1Tut_PostTradeAndItemUseAction,
  'EventScr_Ch1Tut_SethMoveToEnemy': Ch1Tut_SethMoveToEnemy,
  'EventScr_Ch1Tut_TradeSelectGalliamEnd': Ch1Tut_TradeSelectGalliamEnd,
  'EventScr_Ch1Tut_TradeSelectGalliamIdle1': Ch1Tut_TradeSelectGalliamIdle1,
  'EventScr_Ch1Tut_TradeSelectGalliamIdle2': Ch1Tut_TradeSelectGalliamIdle2,
  'EventScr_Ch1_BeginningScene': Ch1_BeginningScene,
  'EventScr_Ch1_EndingScene': Ch1_EndingScene,
  'EventScr_Ch1_Loca_Visit1': Ch1_Loca_Visit1,
  'EventScr_Ch1_Loca_Visit2': Ch1_Loca_Visit2,
  'EventScr_Ch1_Misc_Area': Ch1_Misc_Area,
  'EventScr_Ch1_Misc_DefeatBoss': Ch1_Misc_DefeatBoss,
  'EventScr_Ch1_Turn1Player': Ch1_Turn1Player,
  'EventScr_Ch1_Turn_AllyReinforceArrive': Ch1_Turn_AllyReinforceArrive,
  'EventScr_Ch1_Turn_EnemyReinforceArrive': Ch1_Turn_EnemyReinforceArrive,
  'EventScr_Ch20B_1': Ch20B_1,
  'EventScr_Ch20B_2': Ch20B_2,
  'EventScr_Ch20b_BeginningScene': Ch20b_BeginningScene,
  'EventScr_Ch21A_0': Ch21A_0,
  'EventScr_Ch21A_8': Ch21A_8,
  'EventScr_Ch21A_9': Ch21A_9,
  'EventScr_Ch21b_BeginningScene': Ch21b_BeginningScene,
  'EventScr_Ch21b_EndingScene': Ch21b_EndingScene,
  'EventScr_Ch2Tutorial10': Ch2Tutorial10,
  'EventScr_Ch2Tutorial11': Ch2Tutorial11,
  'EventScr_Ch2Tutorial12': Ch2Tutorial12,
  'EventScr_Ch2Tutorial13': Ch2Tutorial13,
  'EventScr_Ch2Tutorial14': Ch2Tutorial14,
  'EventScr_Ch2Tutorial15': Ch2Tutorial15,
  'EventScr_Ch2Tutorial16': Ch2Tutorial16,
  'EventScr_Ch2Tutorial17': Ch2Tutorial17,
  'EventScr_Ch2Tutorial18': Ch2Tutorial18,
  'EventScr_Ch2Tutorial19': Ch2Tutorial19,
  'EventScr_Ch2Tutorial2': Ch2Tutorial2,
  'EventScr_Ch2Tutorial20': Ch2Tutorial20,
  'EventScr_Ch2Tutorial21': Ch2Tutorial21,
  'EventScr_Ch2Tutorial22': Ch2Tutorial22,
  'EventScr_Ch2Tutorial23': Ch2Tutorial23,
  'EventScr_Ch2Tutorial24': Ch2Tutorial24,
  'EventScr_Ch2Tutorial25': Ch2Tutorial25,
  'EventScr_Ch2Tutorial26': Ch2Tutorial26,
  'EventScr_Ch2Tutorial27': Ch2Tutorial27,
  'EventScr_Ch2Tutorial28': Ch2Tutorial28,
  'EventScr_Ch2Tutorial29': Ch2Tutorial29,
  'EventScr_Ch2Tutorial3': Ch2Tutorial3,
  'EventScr_Ch2Tutorial30': Ch2Tutorial30,
  'EventScr_Ch2Tutorial4': Ch2Tutorial4,
  'EventScr_Ch2Tutorial5': Ch2Tutorial5,
  'EventScr_Ch2Tutorial6': Ch2Tutorial6,
  'EventScr_Ch2Tutorial7': Ch2Tutorial7,
  'EventScr_Ch2Tutorial8': Ch2Tutorial8,
  'EventScr_Ch2Tutorial9': Ch2Tutorial9,
  'EventScr_Ch2_10': Ch2_10,
  'EventScr_Ch2_4': Ch2_4,
  'EventScr_Ch2_5': Ch2_5,
  'EventScr_Ch2_6': Ch2_6,
  'EventScr_Ch2_7': Ch2_7,
  'EventScr_Ch2_8': Ch2_8,
  'EventScr_Ch2_BeginningScene': Ch2_BeginningScene,
  'EventScr_Ch2_EndingScene': Ch2_EndingScene,
  'EventScr_Ch2_Turn1Player': Ch2_Turn1Player,
  'EventScr_Ch2_Turn2Player': Ch2_Turn2Player,
  'EventScr_Ch2_Village1': Ch2_Village1,
  'EventScr_Ch2_Village2': Ch2_Village2,
  'EventScr_Ch3_0': Ch3_0,
  'EventScr_Ch3_5': Ch3_5,
  'EventScr_Ch3_BeginningScene': Ch3_BeginningScene,
  'EventScr_Ch3_EndingScene': Ch3_EndingScene,
  'EventScr_Ch3_Talk_NeimiColm': Ch3_Talk_NeimiColm,
  'EventScr_Ch3_Turn1Npc': Ch3_Turn1Npc,
  'EventScr_Ch3_Turn2Player': Ch3_Turn2Player,
  'EventScr_Ch4_0': Ch4_0,
  'EventScr_Ch4_1': Ch4_1,
  'EventScr_Ch4_10': Ch4_10,
  'EventScr_Ch4_2': Ch4_2,
  'EventScr_Ch4_3': Ch4_3,
  'EventScr_Ch4_4': Ch4_4,
  'EventScr_Ch4_5': Ch4_5,
  'EventScr_Ch4_6': Ch4_6,
  'EventScr_Ch4_BeginningScene': Ch4_BeginningScene,
  'EventScr_Ch5_0': Ch5_0,
  'EventScr_Ch5_1': Ch5_1,
  'EventScr_Ch5_10': Ch5_10,
  'EventScr_Ch5_11': Ch5_11,
  'EventScr_Ch5_2': Ch5_2,
  'EventScr_Ch5_3': Ch5_3,
  'EventScr_Ch5_5': Ch5_5,
  'EventScr_Ch5_6': Ch5_6,
  'EventScr_Ch5_7': Ch5_7,
  'EventScr_Ch5_BeginningScene': Ch5_BeginningScene,
  'EventScr_Ch5_EndingScene': Ch5_EndingScene,
  'EventScr_Ch5x_BeginningScene': Ch5x_BeginningScene,
  'EventScr_Ch5x_EndingScene': Ch5x_EndingScene,
  'EventScr_Ch6_0': Ch6_0,
  'EventScr_Ch6_1': Ch6_1,
  'EventScr_Ch6_2': Ch6_2,
  'EventScr_Ch6_3': Ch6_3,
  'EventScr_Ch6_4': Ch6_4,
  'EventScr_Ch6_BeginningScene': Ch6_BeginningScene,
  'EventScr_Ch6_EndingScene': Ch6_EndingScene,
  'EventScr_Ch7_1': Ch7_1,
  'EventScr_Ch7_2': Ch7_2,
  'EventScr_Ch7_BeginningScene': Ch7_BeginningScene,
  'EventScr_Ch7_EndingScene': Ch7_EndingScene,
  'EventScr_Ch8_0': Ch8_0,
  'EventScr_Ch8_10': Ch8_10,
  'EventScr_Ch8_11': Ch8_11,
  'EventScr_Ch8_BeginningScene': Ch8_BeginningScene,
  'EventScr_Ch8_EndingScene': Ch8_EndingScene,
  'EventScr_Ch9A_2': Ch9A_2,
  'EventScr_Ch9A_3': Ch9A_3,
  'EventScr_Ch9A_4': Ch9A_4,
  'EventScr_Ch9A_5': Ch9A_5,
  'EventScr_Ch9B_9': Ch9B_9,
  'EventScr_Ch9a_BeginningScene': Ch9a_BeginningScene,
  'EventScr_Ch9a_EndingScene': Ch9a_EndingScene,
  'EventScr_ChangeAIinQueue': ChangeAIinQueue,
  'EventScr_ConfigHardModeLoadUnitHard': ConfigHardModeLoadUnitHard,
  'EventScr_CutsceneExecEnd_Sub0': CutsceneExecEnd_Sub0,
  'EventScr_CutsceneExecEnd_Sub1': CutsceneExecEnd_Sub1,
  'EventScr_FloorClearInTower': FloorClearInTower,
  'EventScr_FormatFlashingCursor': FormatFlashingCursor,
  'EventScr_FormatMoveUnit': FormatMoveUnit,
  'EventScr_GiveTreasureToLuckyDog': GiveTreasureToLuckyDog,
  'EventScr_LoadReinforce': LoadReinforce,
  'EventScr_LoadReinforceHardMode': LoadReinforceHardMode,
  'EventScr_LoadUniqueAlly': LoadUniqueAlly,
  'EventScr_LoadUnitForDifferentMode': LoadUnitForDifferentMode,
  'EventScr_LoadUnitForTutorial': LoadUnitForTutorial,
  'EventScr_MapSupportConversation': MapSupportConversation,
  'EventScr_MoveUnitS2ToLeader': MoveUnitS2ToLeader,
  'EventScr_Prologue_9EF828': Prologue_9EF828,
  'EventScr_Prologue_BeginningScene': Prologue_BeginningScene,
  'EventScr_Prologue_EirikaAttacked': Prologue_EirikaAttacked,
  'EventScr_Prologue_EndingScene': Prologue_EndingScene,
  'EventScr_Prologue_ExecTut': Prologue_ExecTut,
  'EventScr_Prologue_GiveRapier': Prologue_GiveRapier,
  'EventScr_Prologue_ONeillSpawn': Prologue_ONeillSpawn,
  'EventScr_Prologue_OneEnemyLeft': Prologue_OneEnemyLeft,
  'EventScr_Prologue_OneillSethBattle': Prologue_OneillSethBattle,
  'EventScr_Prologue_RenaisThroneCutscene': Prologue_RenaisThroneCutscene,
  'EventScr_Prologue_Turn1': Prologue_Turn1,
  'EventScr_Prologue_Turn2': Prologue_Turn2,
  'EventScr_Prologue_Turn3': Prologue_Turn3,
  'EventScr_Prologue_TutEirikaAttack': Prologue_TutEirikaAttack,
  'EventScr_Prologue_TutMessageTurn1': Prologue_TutMessageTurn1,
  'EventScr_Prologue_TutMessageTurn2': Prologue_TutMessageTurn2,
  'EventScr_Prologue_Tutorial0': Prologue_Tutorial0,
  'EventScr_Prologue_Tutorial1': Prologue_Tutorial1,
  'EventScr_Prologue_Tutorial2': Prologue_Tutorial2,
  'EventScr_Prologue_Tutorial3': Prologue_Tutorial3,
  'EventScr_Prologue_Tutorial4': Prologue_Tutorial4,
  'EventScr_Prologue_Tutorial5': Prologue_Tutorial5,
  'EventScr_Prologue_Tutorial6': Prologue_Tutorial6,
  'EventScr_Prologue_Tutorial7': Prologue_Tutorial7,
  'EventScr_Prologue_Tutorial8': Prologue_Tutorial8,
  'EventScr_Prologue_Tutorial9': Prologue_Tutorial9,
  'EventScr_Prologue_TutorialA': Prologue_TutorialA,
  'EventScr_Prologue_TutorialB': Prologue_TutorialB,
  'EventScr_Prologue_TutorialC': Prologue_TutorialC,
  'EventScr_Prologue_TutorialD': Prologue_TutorialD,
  'EventScr_Prologue_TutorialE': Prologue_TutorialE,
  'EventScr_Ruin_37': Ruin_37,
  'EventScr_Ruin_38': Ruin_38,
  'EventScr_Ruin_39': Ruin_39,
  'EventScr_Ruin_40': Ruin_40,
  'EventScr_Ruin_41': Ruin_41,
  'EventScr_Ruin_42': Ruin_42,
  'EventScr_Ruin_45': Ruin_45,
  'EventScr_Ruin_47': Ruin_47,
  'EventScr_Ruin_48': Ruin_48,
  'EventScr_Ruin_54': Ruin_54,
  'EventScr_Ruin_56': Ruin_56,
  'EventScr_Ruin_58': Ruin_58,
  'EventScr_Ruin_60': Ruin_60,
  'EventScr_Ruin_62': Ruin_62,
  'EventScr_Ruin_64': Ruin_64,
  'EventScr_Ruin_66': Ruin_66,
  'EventScr_Ruin_68': Ruin_68,
  'EventScr_Ruin_70': Ruin_70,
  'EventScr_Ruin_72': Ruin_72,
  'EventScr_Ruin_74': Ruin_74,
  'EventScr_Ruin_76': Ruin_76,
  'EventScr_SetBackground': SetBackground,
  'EventScr_SetFlagIfPlayedThrough': SetFlagIfPlayedThrough,
  'EventScr_SkirmishRetreat': SkirmishRetreat,
  'EventScr_StrictLoadUniqueAlly': StrictLoadUniqueAlly,
  'EventScr_SuspendPrompt': SuspendPrompt,
  'EventScr_TextShowWithFadeIn': TextShowWithFadeIn,
  'EventScr_Tutorial_Exec0': Tutorial_Exec0,
  'EventScr_Tutorial_Exec1': Tutorial_Exec1,
  'EventScr_UnTriggerIfNotUnit': UnTriggerIfNotUnit,
  'EventScr_UnitFlushingIN': UnitFlushingIN,
  'EventScr_UnitFlushingOUT': UnitFlushingOUT,
  'EventScr_UnitWarpIN': UnitWarpIN,
  'EventScr_UnitWarpOUT': UnitWarpOUT,
  'EventScr_WM_FadeCommon': WM_FadeCommon,
  'EventScr_WholeTowerClear': WholeTowerClear,
  'frontier_df3_eventscr_ch_014_A6EDFC + 0x98': frontier_df3_eventscr_ch_014_A6EDFC_0x98,
  'frontier_df3_eventscr_ch_015_A6EF04': frontier_df3_eventscr_ch_015_A6EF04,
  'frontier_df3_eventscr_ch_016_A6EFD8 + 0x24': frontier_df3_eventscr_ch_016_A6EFD8_0x24,
  'frontier_df3_eventscr_ch_016_A6EFD8 + 0x3C': frontier_df3_eventscr_ch_016_A6EFD8_0x3C,
  'frontier_df3_eventscr_ch_016_A6EFD8 + 0xC': frontier_df3_eventscr_ch_016_A6EFD8_0xC,
  'frontier_df3_eventscr_ch_017_A6F47C + 0x1B8': frontier_df3_eventscr_ch_017_A6F47C_0x1B8,
  'frontier_df3_eventscr_ch_017_A6F47C + 0x1C': frontier_df3_eventscr_ch_017_A6F47C_0x1C,
  'frontier_df3_eventscr_ch_017_A6F47C + 0x270': frontier_df3_eventscr_ch_017_A6F47C_0x270,
  'frontier_df3_eventscr_ch_017_A6F47C + 0x2B4': frontier_df3_eventscr_ch_017_A6F47C_0x2B4,
  'frontier_df3_eventscr_ch_017_A6F47C + 0x2C': frontier_df3_eventscr_ch_017_A6F47C_0x2C,
  'frontier_df3_eventscr_ch_017_A6F47C + 0x2F8': frontier_df3_eventscr_ch_017_A6F47C_0x2F8,
  'frontier_df3_eventscr_ch_017_A6F47C + 0x318': frontier_df3_eventscr_ch_017_A6F47C_0x318,
  'frontier_df3_eventscr_ch_017_A6F47C + 0x34C': frontier_df3_eventscr_ch_017_A6F47C_0x34C,
  'frontier_df3_eventscr_ch_017_A6F47C + 0x36C': frontier_df3_eventscr_ch_017_A6F47C_0x36C,
  'frontier_df3_eventscr_ch_017_A6F47C + 0x3D4': frontier_df3_eventscr_ch_017_A6F47C_0x3D4,
  'frontier_df3_eventscr_ch_017_A6F47C + 0x3F4': frontier_df3_eventscr_ch_017_A6F47C_0x3F4,
  'frontier_df3_eventscr_ch_017_A6F47C + 0x44': frontier_df3_eventscr_ch_017_A6F47C_0x44,
  'frontier_df3_eventscr_ch_017_A6F47C + 0x45C': frontier_df3_eventscr_ch_017_A6F47C_0x45C,
  'frontier_df3_eventscr_ch_017_A6F47C + 0x47C': frontier_df3_eventscr_ch_017_A6F47C_0x47C,
  'frontier_df3_eventscr_ch_017_A6F47C + 0x534': frontier_df3_eventscr_ch_017_A6F47C_0x534,
  'frontier_df3_eventscr_ch_017_A6F47C + 0x598': frontier_df3_eventscr_ch_017_A6F47C_0x598,
  'frontier_df3_eventscr_ch_017_A6F47C + 0x5C': frontier_df3_eventscr_ch_017_A6F47C_0x5C,
  'frontier_df3_eventscr_ch_017_A6F47C + 0x90': frontier_df3_eventscr_ch_017_A6F47C_0x90,
  'frontier_df3_eventscr_ch_020_A6FB9C + 0x10': frontier_df3_eventscr_ch_020_A6FB9C_0x10,
  'EventScr_Ch1Tut_GuideMsg944': missing_EventScr_Ch1Tut_GuideMsg944,
  'EventScr_Ch1Tut_GuideMsgSeize': missing_EventScr_Ch1Tut_GuideMsgSeize,
  'EventScr_Ch1Tut_GuideWTA': missing_EventScr_Ch1Tut_GuideWTA,
  'EventScr_Ch2_9': missing_EventScr_Ch2_9,
  'EventScr_Ch3_1': missing_EventScr_Ch3_1,
  'EventScr_Ch3_2': missing_EventScr_Ch3_2,
  'EventScr_Ch3_3': missing_EventScr_Ch3_3,
  'EventScr_Ch3_4': missing_EventScr_Ch3_4,
  'EventScr_Ch3_6': missing_EventScr_Ch3_6,
  'EventScr_Ch3_7': missing_EventScr_Ch3_7,
  'EventScr_Ch4_7': missing_EventScr_Ch4_7,
  'EventScr_Ch4_8': missing_EventScr_Ch4_8,
  'EventScr_Ch4_9': missing_EventScr_Ch4_9,
  'EventScr_Ch5_8': missing_EventScr_Ch5_8,
  'EventScr_Ch5_9': missing_EventScr_Ch5_9,
  'EventScr_Ch7_3': missing_EventScr_Ch7_3,
};
