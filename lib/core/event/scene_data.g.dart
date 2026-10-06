// GENERATED —— 由 tools/pipeline/extract/gen_scene_dart.py 生成。
// **请勿手改**：改 C 源码或生成器，然后重新生成。
//
// 每个脚本编译成一个 `async` 函数 —— **没有指令列表，没有解释器**。
// 脚本 196 个（直线 103 个 / 有分支 93 个）
//
// 直线脚本是顺序的 async 代码；有分支的用 `while(true){switch(pc)}`，
// `pc` 是**局部变量**（因为不需要存档）。

// ignore_for_file: lines_longer_than_80_chars

import 'scene.dart';

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
          s.placeholder('SDEQUEUE');
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
          s.placeholder('BLE');
          pc = 9;
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
          s.placeholder('SDEQUEUE');
          pc = 24;
          continue;
        case 24:
          s.placeholder('BLE');
          pc = 25;
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

/// `EventScr_9EEA58`
Future<void> scr_9EEA58(Scene s) async {
    var pc = 0;
    while (true) {
      switch (pc) {
        case 0:
          s.placeholder('CHECK_EVBIT');
          pc = 1;
          continue;
        case 1:
          if (s.slotInt(32795) != 12) { pc = 2; } else { pc = 2; }
          continue;
        case 2:
          s.placeholder('FADI');
          pc = 3;
          continue;
        case 3:
          pc = 4;
          continue;
        case 4:
          s.placeholder('CLEA');
          pc = 5;
          continue;
        case 5:
          s.placeholder('CLEE');
          pc = 6;
          continue;
        case 6:
          s.placeholder('CLEN');
          pc = 7;
          continue;
        case 7:
          s.setSlot(11, 0);
          pc = 8;
          continue;
        case 8:
          s.placeholder('LOMA');
          pc = 9;
          continue;
        case 9:
          s.placeholder('FADU');
          pc = 10;
          continue;
        case 10:
          s.placeholder('BROWNBOXTEXT');
          pc = 11;
          continue;
        case 11:
          s.placeholder('CURSOR_AT');
          pc = 12;
          continue;
        case 12:
          await s.stall(60);
          pc = 13;
          continue;
        case 13:
          s.placeholder('CURE');
          pc = 14;
          continue;
        case 14:
          s.placeholder('FADI');
          pc = 15;
          continue;
        case 15:
          s.slotArith('SADD', 11, 2);
          pc = 16;
          continue;
        case 16:
          s.placeholder('LOMA');
          pc = 17;
          continue;
        case 17:
          return;
        default:
          return;
      }
    }
}

/// `EventScr_ApplyTileChangeForFaction`
Future<void> ApplyTileChangeForFaction(Scene s) async {
    var pc = 0;
    while (true) {
      switch (pc) {
        case 0:
          s.placeholder('EVBIT_MODIFY');
          pc = 1;
          continue;
        case 1:
          s.placeholder('CHECK_ALLEGIANCE');
          pc = 2;
          continue;
        case 2:
          if (s.slotInt(0) != 12) { pc = 3; } else { pc = 3; }
          continue;
        case 3:
          s.placeholder('TILECHANGE');
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

/// `EventScr_CallIfCommonMode`
Future<void> CallIfCommonMode(Scene s) async {
    var pc = 0;
    while (true) {
      switch (pc) {
        case 0:
          s.placeholder('CHECK_MODE');
          pc = 1;
          continue;
        case 1:
          if (s.slotInt(0) != 12) { pc = 2; } else { pc = 2; }
          continue;
        case 2:
          s.slotArith('SADD', 2, 3);
          pc = 3;
          continue;
        case 3:
          s.placeholder('CALL');
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
          s.placeholder('CHECK_CHAPTER_NUMBER');
          pc = 1;
          continue;
        case 1:
          if (s.slotInt(0) != 12) { pc = 2; } else { pc = 2; }
          continue;
        case 2:
          s.placeholder('CALL');
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
          s.placeholder('CHECK_TUTORIAL');
          pc = 1;
          continue;
        case 1:
          if (s.slotInt(0) != 12) { pc = 5; } else { pc = 2; }
          continue;
        case 2:
          s.placeholder('CHECK_HARD');
          pc = 3;
          continue;
        case 3:
          if (s.slotInt(0) == 12) { pc = 5; } else { pc = 4; }
          continue;
        case 4:
          s.placeholder('CALL');
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
          s.placeholder('CHECK_TUTORIAL');
          pc = 1;
          continue;
        case 1:
          if (s.slotInt(0) == 12) { pc = 3; } else { pc = 2; }
          continue;
        case 2:
          s.placeholder('CALL');
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
          s.placeholder('CHECK_MODE');
          pc = 1;
          continue;
        case 1:
          s.setSlot(7, RawArg('CHAPTER_MODE_COMMON'));
          pc = 2;
          continue;
        case 2:
          if (s.slotInt(2) == 12) { pc = 3; } else { pc = 3; }
          continue;
        case 3:
          s.setSlot(7, RawArg('CHAPTER_MODE_EIRIKA'));
          pc = 4;
          continue;
        case 4:
          if (s.slotInt(1) != 12) { pc = 5; } else { pc = 5; }
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
          s.placeholder('CALL');
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
    s.placeholder('CAMERA_CAHR');
    s.placeholder('CURSOR_CHAR');
    await s.stall(60);
    s.placeholder('CURE');
    s.placeholder('MUSC');
    s.placeholder('TEXTSTART');
    await s.textShow(2545);
    s.placeholder('TEXTEND');
    s.placeholder('REMA');
    s.placeholder('CURSOR_AT');
    await s.stall(60);
    s.placeholder('CURE');
    s.placeholder('MUSI');
    s.setSlot(2, 19);
    s.setSlot(3, 2546);
    await s.call(Sym('Event_TextWithBG'));
    s.placeholder('MUNO');
    s.placeholder('EVBIT_T');
    return;
}

/// `EventScr_Ch10A_13`
Future<void> Ch10A_13(Scene s) async {
    s.setSlot(2, 0);
    await s.call(Sym('UnitDef_Ch14BAlly_7'));
    s.placeholder('ENUF');
    s.setSlot(13, 0);
    s.setSlot(1, 1900557);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 1835022);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 1900559);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 1835024);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 1900561);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 1966094);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 1966096);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 1966098);
    s.placeholder('SENQUEUE1');
    s.setSlot(2, 65536);
    await s.call(Sym('EventScr_ChangeAIinQueue'));
    s.placeholder('EVBIT_T');
    return;
}

/// `EventScr_Ch10A_8`
Future<void> Ch10A_8(Scene s) async {
    var pc = 0;
    while (true) {
      switch (pc) {
        case 0:
          s.placeholder('CHECK_TUTORIAL');
          pc = 1;
          continue;
        case 1:
          if (s.slotInt(0) != 12) { pc = 7; } else { pc = 2; }
          continue;
        case 2:
          s.placeholder('CHECK_HARD');
          pc = 3;
          continue;
        case 3:
          if (s.slotInt(0) == 12) { pc = 7; } else { pc = 4; }
          continue;
        case 4:
          s.placeholder('CAMERA');
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
          s.placeholder('EVBIT_T');
          pc = 13;
          continue;
        case 13:
          return;
        default:
          return;
      }
    }
}

/// `EventScr_Ch10B_0`
Future<void> Ch10B_0(Scene s) async {
    s.placeholder('MUSC');
    s.placeholder('CAMERA2');
    await s.stall(15);
    s.loadUnits(1, Sym('frontier_df3_unitdef_b_027_917600', 520));
    s.placeholder('ENUN');
    s.placeholder('DISA');
    s.placeholder('CURSOR_AT');
    await s.stall(60);
    s.placeholder('CURE');
    s.placeholder('MUSI');
    s.setSlot(2, 23);
    await s.call(Sym('EventScr_SetBackground'));
    await s.textShow(2682);
    s.placeholder('TEXTEND');
    s.placeholder('REMA');
    s.placeholder('FADI');
    s.placeholder('CLEAN');
    s.placeholder('DISA');
    s.placeholder('FADU');
    s.loadUnits(1, Sym('frontier_df3_unitdef_b_027_917600', 560));
    s.placeholder('ENUN');
    s.placeholder('DISA');
    s.loadUnits(1, Sym('frontier_df3_unitdef_b_027_917600', 600));
    s.placeholder('ENUN');
    s.loadUnits(1, Sym('frontier_df3_unitdef_b_026_916D14', 1464));
    s.placeholder('ENUN');
    s.placeholder('CURSOR_CHAR');
    await s.stall(60);
    s.placeholder('CURE');
    s.placeholder('TEXTSTART');
    await s.textShow(2683);
    s.placeholder('TEXTEND');
    s.placeholder('REMA');
    s.placeholder('MUNO');
    s.moveUnit('MOVE', [16, 67, 23, 14]);
    s.placeholder('ENUN');
    s.placeholder('DISA');
    s.placeholder('EVBIT_T');
    return;
}

/// `EventScr_Ch10B_1`
Future<void> Ch10B_1(Scene s) async {
    var pc = 0;
    while (true) {
      switch (pc) {
        case 0:
          s.placeholder('CHECK_EXISTS');
          pc = 1;
          continue;
        case 1:
          if (s.slotInt(0) == 12) { pc = 15; } else { pc = 2; }
          continue;
        case 2:
          s.placeholder('CHECK_ALLEGIANCE');
          pc = 3;
          continue;
        case 3:
          s.setSlot(1, 0);
          pc = 4;
          continue;
        case 4:
          if (s.slotInt(0) == 12) { pc = 5; } else { pc = 5; }
          continue;
        case 5:
          s.placeholder('MUSC');
          pc = 6;
          continue;
        case 6:
          s.placeholder('CAMERA_CAHR');
          pc = 7;
          continue;
        case 7:
          await s.stall(15);
          pc = 8;
          continue;
        case 8:
          s.placeholder('CURSOR_CHAR');
          pc = 9;
          continue;
        case 9:
          await s.stall(60);
          pc = 10;
          continue;
        case 10:
          s.placeholder('CURE');
          pc = 11;
          continue;
        case 11:
          s.placeholder('TEXTSTART');
          pc = 12;
          continue;
        case 12:
          await s.textShow(2684);
          pc = 13;
          continue;
        case 13:
          s.placeholder('TEXTEND');
          pc = 14;
          continue;
        case 14:
          s.placeholder('REMA');
          pc = 15;
          continue;
        case 15:
          pc = 16;
          continue;
        case 16:
          s.placeholder('EVBIT_T');
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
          s.placeholder('CHECK_EXISTS');
          pc = 1;
          continue;
        case 1:
          if (s.slotInt(0) == 12) { pc = 15; } else { pc = 2; }
          continue;
        case 2:
          s.placeholder('CHECK_ALLEGIANCE');
          pc = 3;
          continue;
        case 3:
          s.setSlot(1, 0);
          pc = 4;
          continue;
        case 4:
          if (s.slotInt(0) == 12) { pc = 5; } else { pc = 5; }
          continue;
        case 5:
          s.placeholder('MUSC');
          pc = 6;
          continue;
        case 6:
          s.placeholder('CAMERA_CAHR');
          pc = 7;
          continue;
        case 7:
          await s.stall(15);
          pc = 8;
          continue;
        case 8:
          s.placeholder('CURSOR_CHAR');
          pc = 9;
          continue;
        case 9:
          await s.stall(60);
          pc = 10;
          continue;
        case 10:
          s.placeholder('CURE');
          pc = 11;
          continue;
        case 11:
          s.placeholder('TEXTSTART');
          pc = 12;
          continue;
        case 12:
          await s.textShow(2685);
          pc = 13;
          continue;
        case 13:
          s.placeholder('TEXTEND');
          pc = 14;
          continue;
        case 14:
          s.placeholder('REMA');
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
    s.placeholder('MUSC');
    s.setSlot(2, 131087);
    await s.call(Sym('EventScr_9EEA58'));
    s.loadUnits(1, Sym('frontier_df4_banim_b_077_90DB94', 52));
    s.placeholder('ENUN');
    s.placeholder('FADU');
    s.moveUnit('MOVE_1STEP', [16, 105, 3]);
    s.placeholder('ENUN');
    s.placeholder('CURSOR_CHAR');
    await s.stall(60);
    s.placeholder('CURE');
    s.placeholder('TEXTSTART');
    await s.textShow(2540);
    s.placeholder('TEXTEND');
    s.placeholder('REMA');
    s.placeholder('FADI');
    s.placeholder('CLEA');
    s.placeholder('CLEE');
    s.placeholder('CLEN');
    s.placeholder('CAMERA2');
    s.placeholder('UNIT_COLORS');
    s.placeholder('EvtSetLoadUnitNoREDA');
    s.loadUnits(2, Sym('frontier_df4_banim_b_077_90DB94', 212));
    s.placeholder('ENUN');
    s.setSlot(11, 851975);
    s.placeholder('TILECHANGE');
    s.placeholder('FADU');
    s.placeholder('TILECHANGE');
    s.loadUnits(2, Sym('frontier_df4_banim_b_077_90DB94', 212));
    s.placeholder('ENUN');
    s.placeholder('TILEREVERT');
    s.loadUnits(2, Sym('frontier_df4_banim_b_077_90DB94', 272));
    s.placeholder('ENUN');
    s.placeholder('CURSOR_CHAR');
    await s.stall(60);
    s.placeholder('CURE');
    s.setSlot(2, 17);
    s.setSlot(3, 2541);
    await s.call(Sym('Event_TextWithBG'));
    s.loadUnits(2, Sym('frontier_df4_banim_b_077_90DB94', 312));
    s.placeholder('ENUN');
    s.placeholder('MUSI');
    s.placeholder('CURSOR_CHAR');
    await s.stall(60);
    s.placeholder('CURE');
    s.setSlot(2, 17);
    await s.call(Sym('EventScr_SetBackground'));
    await s.textShow(2542);
    s.placeholder('TEXTEND');
    s.placeholder('REMA');
    s.placeholder('FADI');
    s.placeholder('CLEA');
    s.placeholder('CLEE');
    s.placeholder('CLEN');
    s.placeholder('UNIT_COLORS');
    s.setSlot(11, 1048583);
    s.placeholder('LOMA');
    s.loadUnits(1, Sym('UnitDef_Ch10ANPC'));
    s.placeholder('ENUN');
    s.loadUnits(1, Sym('UnitDef_Ch10AEnemy_0'));
    s.placeholder('ENUN');
    s.setSlot(2, Sym('UnitDef_Ch10AEnemy_1'));
    s.setSlot(3, 1);
    await s.call(Sym('EventScr_LoadUnitForTutorial'));
    s.placeholder('FADU');
    s.placeholder('CURSOR_CHAR');
    await s.stall(60);
    s.placeholder('CURE');
    s.placeholder('MUSC');
    s.setSlot(2, 57);
    s.setSlot(3, 2543);
    await s.call(Sym('Event_TextWithBG'));
    s.placeholder('CAMERA');
    s.loadUnits(2, Sym('UnitDef_Ch10AAlly_0'));
    s.placeholder('STAL2');
    s.setSlot(1, 0);
    s.placeholder('SET_STATE');
    s.setSlot(1, 0);
    s.placeholder('SET_STATE');
    s.loadUnits(3, Sym('UnitDef_Ch10AAlly_1'));
    s.placeholder('ENUN');
    s.setSlot(1, 4294967295);
    s.placeholder('SET_STATE');
    s.setSlot(1, 4294967295);
    s.placeholder('SET_STATE');
    s.placeholder('CURSOR_CHAR');
    await s.stall(60);
    s.placeholder('CURE');
    s.setSlot(2, 37);
    await s.call(Sym('EventScr_SetBackground'));
    await s.textShow(2544);
    s.placeholder('TEXTEND');
    s.placeholder('REMA');
    await s.call(Sym('data_085B9BBC', 512));
    s.placeholder('ENUT');
    s.placeholder('ENUT');
    return;
}

/// `EventScr_Ch10a_EndingScene`
Future<void> Ch10a_EndingScene(Scene s) async {
    var pc = 0;
    while (true) {
      switch (pc) {
        case 0:
          s.placeholder('FADI');
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
          s.placeholder('CHECK_EXISTS');
          pc = 5;
          continue;
        case 5:
          if (s.slotInt(0) == 12) { pc = 10; } else { pc = 6; }
          continue;
        case 6:
          s.placeholder('CHECK_ALIVE');
          pc = 7;
          continue;
        case 7:
          if (s.slotInt(0) == 12) { pc = 10; } else { pc = 8; }
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
          s.placeholder('CHECK_EXISTS');
          pc = 12;
          continue;
        case 12:
          if (s.slotInt(1) == 12) { pc = 10; } else { pc = 13; }
          continue;
        case 13:
          s.placeholder('CHECK_ALIVE');
          pc = 14;
          continue;
        case 14:
          if (s.slotInt(1) == 12) { pc = 10; } else { pc = 15; }
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
          if (s.slotInt(2) == 7) { pc = 10; } else { pc = 23; }
          continue;
        case 23:
          s.setSlot(1, 0);
          pc = 24;
          continue;
        case 24:
          s.placeholder('SET_HP');
          pc = 25;
          continue;
        case 25:
          s.setSlot(1, 0);
          pc = 26;
          continue;
        case 26:
          s.placeholder('SET_HP');
          pc = 27;
          continue;
        case 27:
          s.setSlot(1, 0);
          pc = 28;
          continue;
        case 28:
          s.placeholder('SET_STATE');
          pc = 29;
          continue;
        case 29:
          s.setSlot(1, 0);
          pc = 30;
          continue;
        case 30:
          s.placeholder('SET_STATE');
          pc = 31;
          continue;
        case 31:
          s.placeholder('REMU');
          pc = 32;
          continue;
        case 32:
          s.placeholder('REMU');
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
          s.placeholder('CLEA');
          pc = 37;
          continue;
        case 37:
          s.placeholder('CLEE');
          pc = 38;
          continue;
        case 38:
          s.placeholder('CLEN');
          pc = 39;
          continue;
        case 39:
          s.placeholder('MUSC');
          pc = 40;
          continue;
        case 40:
          s.placeholder('CAMERA');
          pc = 41;
          continue;
        case 41:
          s.placeholder('FADU');
          pc = 42;
          continue;
        case 42:
          s.loadUnits(1, Sym('UnitDef_Ch10AEnemy_6'));
          pc = 43;
          continue;
        case 43:
          s.placeholder('ENUN');
          pc = 44;
          continue;
        case 44:
          s.placeholder('CURSOR_CHAR');
          pc = 45;
          continue;
        case 45:
          await s.stall(60);
          pc = 46;
          continue;
        case 46:
          s.placeholder('CURE');
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
          s.placeholder('STAL2');
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
          s.placeholder('FADI');
          pc = 57;
          continue;
        case 57:
          s.placeholder('EvtBgmFadeIn');
          pc = 58;
          continue;
        case 58:
          s.placeholder('ENUN');
          pc = 59;
          continue;
        case 59:
          s.placeholder('CLEA');
          pc = 60;
          continue;
        case 60:
          s.placeholder('CLEE');
          pc = 61;
          continue;
        case 61:
          s.placeholder('CLEN');
          pc = 62;
          continue;
        case 62:
          s.placeholder('CAMERA');
          pc = 63;
          continue;
        case 63:
          s.placeholder('FADU');
          pc = 64;
          continue;
        case 64:
          s.placeholder('CURSOR_AT');
          pc = 65;
          continue;
        case 65:
          await s.stall(60);
          pc = 66;
          continue;
        case 66:
          s.placeholder('CURE');
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
          s.placeholder('MUSC');
          pc = 70;
          continue;
        case 70:
          await s.textShow(2552);
          pc = 71;
          continue;
        case 71:
          s.placeholder('TEXTEND');
          pc = 72;
          continue;
        case 72:
          s.placeholder('REMA');
          pc = 73;
          continue;
        case 73:
          if (s.slotInt(3) != 7) { pc = 10; } else { pc = 74; }
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
          s.placeholder('TEXTEND');
          pc = 78;
          continue;
        case 78:
          s.placeholder('REMA');
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
          s.placeholder('CHECK_ALIVE');
          pc = 83;
          continue;
        case 83:
          if (s.slotInt(10) == 12) { pc = 10; } else { pc = 84; }
          continue;
        case 84:
          s.placeholder('MUSI');
          pc = 85;
          continue;
        case 85:
          await s.textShow(2554);
          pc = 86;
          continue;
        case 86:
          s.placeholder('TEXTEND');
          pc = 87;
          continue;
        case 87:
          s.placeholder('REMA');
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
          s.placeholder('TEXTEND');
          pc = 92;
          continue;
        case 92:
          s.placeholder('REMA');
          pc = 93;
          continue;
        case 93:
          s.placeholder('MUNO');
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
          s.placeholder('TEXTEND');
          pc = 98;
          continue;
        case 98:
          s.placeholder('REMA');
          pc = 99;
          continue;
        case 99:
          pc = 100;
          continue;
        case 100:
          s.placeholder('FADI');
          pc = 101;
          continue;
        case 101:
          s.placeholder('ENUT');
          pc = 102;
          continue;
        case 102:
          s.placeholder('MNCH');
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
    s.placeholder('MUSC');
    s.placeholder('CAMERA_CAHR');
    s.placeholder('CURSOR_CHAR');
    await s.stall(60);
    s.placeholder('CURE');
    s.setSlot(2, 13);
    await s.call(Sym('EventScr_SetBackground'));
    await s.textShow(2707);
    s.placeholder('TEXTEND');
    s.placeholder('REMA');
    s.placeholder('FADI');
    s.placeholder('TILEREVERT');
    s.placeholder('TILECHANGE');
    s.placeholder('CLEAN');
    s.placeholder('CAMERA2');
    s.placeholder('TEXTSTART');
    s.loadUnits(1, Sym('UnitDef_Ch11BEnemy_1'));
    s.placeholder('ENUN');
    s.loadUnits(1, Sym('UnitDef_Ch11BEnemy_2'));
    s.placeholder('ENUN');
    s.placeholder('FADU');
    s.placeholder('EVBIT_T');
    return;
}

/// `EventScr_Ch11B_1`
Future<void> Ch11B_1(Scene s) async {
    s.placeholder('MUSC');
    s.placeholder('CAMERA2');
    s.placeholder('EARTHQUAKE_START');
    await s.stall(30);
    s.placeholder('TILECHANGE');
    await s.stall(30);
    s.placeholder('EARTHQUAKE_END');
    s.placeholder('CAMERA_CAHR');
    s.placeholder('CURSOR_CHAR');
    await s.stall(60);
    s.placeholder('CURE');
    s.placeholder('TEXTSTART');
    await s.textShow(2708);
    s.placeholder('TEXTEND');
    s.placeholder('REMA');
    s.placeholder('EVBIT_T');
    return;
}

/// `EventScr_Ch11B_2`
Future<void> Ch11B_2(Scene s) async {
    s.placeholder('MUSC');
    s.placeholder('CAMERA_CAHR');
    s.placeholder('CURSOR_CHAR');
    await s.stall(60);
    s.placeholder('CURE');
    s.setSlot(2, 13);
    await s.call(Sym('EventScr_SetBackground'));
    await s.textShow(2709);
    s.placeholder('TEXTEND');
    s.placeholder('REMA');
    s.placeholder('FADI');
    s.placeholder('TILECHANGE');
    s.placeholder('CLEAN');
    s.placeholder('CAMERA2');
    s.placeholder('TEXTSTART');
    s.placeholder('EARTHQUAKE_START');
    s.placeholder('FADU');
    await s.stall(32);
    s.placeholder('EARTHQUAKE_END');
    s.loadUnits(1, Sym('frontier_df3_unitdef_b_029_9184F0'));
    s.placeholder('ENUN');
    s.placeholder('CURSOR_CHAR');
    await s.stall(60);
    s.placeholder('CURE');
    s.placeholder('TEXTSTART');
    await s.textShow(2710);
    s.placeholder('TEXTEND');
    s.placeholder('REMA');
    s.placeholder('EVBIT_T');
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
    s.placeholder('EVBIT_T');
    return;
}

/// `EventScr_Ch11a_EndingScene`
Future<void> Ch11a_EndingScene(Scene s) async {
    var pc = 0;
    while (true) {
      switch (pc) {
        case 0:
          s.placeholder('MUSC');
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
          s.placeholder('CHECK_ALIVE');
          pc = 4;
          continue;
        case 4:
          if (s.slotInt(0) == 12) { pc = 8; } else { pc = 5; }
          continue;
        case 5:
          await s.textShow(2571);
          pc = 6;
          continue;
        case 6:
          s.placeholder('TEXTEND');
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
          s.placeholder('TEXTEND');
          pc = 11;
          continue;
        case 11:
          pc = 12;
          continue;
        case 12:
          s.placeholder('FADI');
          pc = 13;
          continue;
        case 13:
          s.placeholder('REMA');
          pc = 14;
          continue;
        case 14:
          s.placeholder('FADU');
          pc = 15;
          continue;
        case 15:
          await s.textShow(2573);
          pc = 16;
          continue;
        case 16:
          s.placeholder('TEXTEND');
          pc = 17;
          continue;
        case 17:
          s.placeholder('CHECK_ALIVE');
          pc = 18;
          continue;
        case 18:
          if (s.slotInt(2) == 12) { pc = 8; } else { pc = 19; }
          continue;
        case 19:
          s.placeholder('EvtTextShow2');
          pc = 20;
          continue;
        case 20:
          s.placeholder('TEXTEND');
          pc = 21;
          continue;
        case 21:
          pc = 22;
          continue;
        case 22:
          s.placeholder('REMA');
          pc = 23;
          continue;
        case 23:
          s.placeholder('EvtBgmFadeIn');
          pc = 24;
          continue;
        case 24:
          s.placeholder('FADI');
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
          s.placeholder('CLEA');
          pc = 30;
          continue;
        case 30:
          s.placeholder('CLEE');
          pc = 31;
          continue;
        case 31:
          s.placeholder('CLEN');
          pc = 32;
          continue;
        case 32:
          s.setSlot(11, 655360);
          pc = 33;
          continue;
        case 33:
          s.placeholder('LOMA');
          pc = 34;
          continue;
        case 34:
          s.placeholder('EvtChangeFogVision');
          pc = 35;
          continue;
        case 35:
          s.placeholder('MUSC');
          pc = 36;
          continue;
        case 36:
          s.placeholder('FADU');
          pc = 37;
          continue;
        case 37:
          s.loadUnits(2, Sym('frontier_df4_banim_b_078_90E58C'));
          pc = 38;
          continue;
        case 38:
          s.placeholder('ENUN');
          pc = 39;
          continue;
        case 39:
          s.placeholder('DISA');
          pc = 40;
          continue;
        case 40:
          await s.stall(30);
          pc = 41;
          continue;
        case 41:
          s.placeholder('CURSOR_AT');
          pc = 42;
          continue;
        case 42:
          await s.stall(60);
          pc = 43;
          continue;
        case 43:
          s.placeholder('CURE');
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
          s.placeholder('MUSI');
          pc = 47;
          continue;
        case 47:
          await s.textShow(2575);
          pc = 48;
          continue;
        case 48:
          s.placeholder('TEXTEND');
          pc = 49;
          continue;
        case 49:
          s.placeholder('REMA');
          pc = 50;
          continue;
        case 50:
          s.placeholder('EvtBgmFadeIn');
          pc = 51;
          continue;
        case 51:
          s.placeholder('FADI');
          pc = 52;
          continue;
        case 52:
          s.placeholder('CLEAN');
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
          s.placeholder('ENUN');
          pc = 56;
          continue;
        case 56:
          s.placeholder('DISA');
          pc = 57;
          continue;
        case 57:
          s.placeholder('DISA');
          pc = 58;
          continue;
        case 58:
          s.placeholder('DISA');
          pc = 59;
          continue;
        case 59:
          s.placeholder('FADU');
          pc = 60;
          continue;
        case 60:
          s.loadUnits(2, Sym('UnitDef_Ch11AMixed'));
          pc = 61;
          continue;
        case 61:
          s.placeholder('ENUN');
          pc = 62;
          continue;
        case 62:
          s.placeholder('CURSOR_CHAR');
          pc = 63;
          continue;
        case 63:
          await s.stall(60);
          pc = 64;
          continue;
        case 64:
          s.placeholder('CURE');
          pc = 65;
          continue;
        case 65:
          s.placeholder('MUSC');
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
          s.placeholder('TEXTEND');
          pc = 70;
          continue;
        case 70:
          s.placeholder('MUSC');
          pc = 71;
          continue;
        case 71:
          s.placeholder('TEXTCONT');
          pc = 72;
          continue;
        case 72:
          s.placeholder('TEXTEND');
          pc = 73;
          continue;
        case 73:
          s.placeholder('REMA');
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
          s.placeholder('ENUN');
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
          s.placeholder('ENUN');
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
          s.placeholder('ENUN');
          pc = 87;
          continue;
        case 87:
          s.placeholder('ENUN');
          pc = 88;
          continue;
        case 88:
          s.placeholder('CURSOR_CHAR');
          pc = 89;
          continue;
        case 89:
          await s.stall(60);
          pc = 90;
          continue;
        case 90:
          s.placeholder('CURE');
          pc = 91;
          continue;
        case 91:
          s.placeholder('MUSC');
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
          s.placeholder('TEXTEND');
          pc = 96;
          continue;
        case 96:
          s.placeholder('MUSC');
          pc = 97;
          continue;
        case 97:
          s.placeholder('TEXTCONT');
          pc = 98;
          continue;
        case 98:
          s.placeholder('TEXTEND');
          pc = 99;
          continue;
        case 99:
          s.placeholder('REMA');
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
          s.placeholder('ENUN');
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
          s.placeholder('SENQUEUE1');
          pc = 106;
          continue;
        case 106:
          s.setSlot(1, 131072);
          pc = 107;
          continue;
        case 107:
          s.placeholder('SENQUEUE1');
          pc = 108;
          continue;
        case 108:
          s.setSlot(1, 91137);
          pc = 109;
          continue;
        case 109:
          s.placeholder('SENQUEUE1');
          pc = 110;
          continue;
        case 110:
          s.setSlot(1, 4294967295);
          pc = 111;
          continue;
        case 111:
          s.placeholder('SENQUEUE1');
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
          s.placeholder('DISA_IF');
          pc = 115;
          continue;
        case 115:
          s.placeholder('CURSOR_CHAR');
          pc = 116;
          continue;
        case 116:
          await s.stall(60);
          pc = 117;
          continue;
        case 117:
          s.placeholder('CURE');
          pc = 118;
          continue;
        case 118:
          s.placeholder('TEXTSTART');
          pc = 119;
          continue;
        case 119:
          await s.textShow(2579);
          pc = 120;
          continue;
        case 120:
          s.placeholder('TEXTEND');
          pc = 121;
          continue;
        case 121:
          s.placeholder('REMA');
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
          s.placeholder('SENQUEUE1');
          pc = 125;
          continue;
        case 125:
          s.setSlot(1, 0);
          pc = 126;
          continue;
        case 126:
          s.placeholder('SENQUEUE1');
          pc = 127;
          continue;
        case 127:
          s.setSlot(1, 131203);
          pc = 128;
          continue;
        case 128:
          s.placeholder('SENQUEUE1');
          pc = 129;
          continue;
        case 129:
          s.setSlot(1, 0);
          pc = 130;
          continue;
        case 130:
          s.placeholder('SENQUEUE1');
          pc = 131;
          continue;
        case 131:
          s.setSlot(1, 131075);
          pc = 132;
          continue;
        case 132:
          s.placeholder('SENQUEUE1');
          pc = 133;
          continue;
        case 133:
          s.setSlot(1, 0);
          pc = 134;
          continue;
        case 134:
          s.placeholder('SENQUEUE1');
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
          s.placeholder('SENQUEUE1');
          pc = 139;
          continue;
        case 139:
          s.setSlot(1, 0);
          pc = 140;
          continue;
        case 140:
          s.placeholder('SENQUEUE1');
          pc = 141;
          continue;
        case 141:
          s.setSlot(1, 131073);
          pc = 142;
          continue;
        case 142:
          s.placeholder('SENQUEUE1');
          pc = 143;
          continue;
        case 143:
          s.setSlot(1, 0);
          pc = 144;
          continue;
        case 144:
          s.placeholder('SENQUEUE1');
          pc = 145;
          continue;
        case 145:
          s.moveUnit('MOVE_DEFINED', [129]);
          pc = 146;
          continue;
        case 146:
          s.placeholder('STAL2');
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
          s.placeholder('SENQUEUE1');
          pc = 150;
          continue;
        case 150:
          s.setSlot(1, 0);
          pc = 151;
          continue;
        case 151:
          s.placeholder('SENQUEUE1');
          pc = 152;
          continue;
        case 152:
          s.setSlot(1, 131203);
          pc = 153;
          continue;
        case 153:
          s.placeholder('SENQUEUE1');
          pc = 154;
          continue;
        case 154:
          s.setSlot(1, 0);
          pc = 155;
          continue;
        case 155:
          s.placeholder('SENQUEUE1');
          pc = 156;
          continue;
        case 156:
          s.setSlot(1, 131075);
          pc = 157;
          continue;
        case 157:
          s.placeholder('SENQUEUE1');
          pc = 158;
          continue;
        case 158:
          s.setSlot(1, 0);
          pc = 159;
          continue;
        case 159:
          s.placeholder('SENQUEUE1');
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
          s.placeholder('SENQUEUE1');
          pc = 164;
          continue;
        case 164:
          s.setSlot(1, 0);
          pc = 165;
          continue;
        case 165:
          s.placeholder('SENQUEUE1');
          pc = 166;
          continue;
        case 166:
          s.setSlot(1, 131073);
          pc = 167;
          continue;
        case 167:
          s.placeholder('SENQUEUE1');
          pc = 168;
          continue;
        case 168:
          s.setSlot(1, 0);
          pc = 169;
          continue;
        case 169:
          s.placeholder('SENQUEUE1');
          pc = 170;
          continue;
        case 170:
          s.moveUnit('MOVE_DEFINED', [103]);
          pc = 171;
          continue;
        case 171:
          s.placeholder('ENUN');
          pc = 172;
          continue;
        case 172:
          s.placeholder('CURSOR_CHAR');
          pc = 173;
          continue;
        case 173:
          await s.stall(60);
          pc = 174;
          continue;
        case 174:
          s.placeholder('CURE');
          pc = 175;
          continue;
        case 175:
          s.placeholder('TEXTSTART');
          pc = 176;
          continue;
        case 176:
          await s.textShow(2580);
          pc = 177;
          continue;
        case 177:
          s.placeholder('TEXTEND');
          pc = 178;
          continue;
        case 178:
          s.placeholder('REMA');
          pc = 179;
          continue;
        case 179:
          s.placeholder('ENUT');
          pc = 180;
          continue;
        case 180:
          s.placeholder('MNC2');
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
    s.placeholder('MUSI');
    s.setSlot(2, 1);
    s.setSlot(3, 2596);
    await s.call(Sym('Event_TextWithBG'));
    s.placeholder('MUNO');
    await s.call(Sym('data_085B9BBC', 360));
    s.setSlot(3, 89);
    s.placeholder('GIVEITEMTO');
    s.placeholder('TILECHANGE');
    s.placeholder('EVBIT_T');
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
    s.placeholder('EVBIT_T');
    return;
}

/// `EventScr_Ch12B_1`
Future<void> Ch12B_1(Scene s) async {
    s.placeholder('CAMERA_CAHR');
    s.placeholder('SPAWN_ENEMY');
    s.setSlot(2, 87);
    s.moveUnit('MOVE_CLOSEST', [65535, 65533, 17, 1]);
    await s.call(Sym('EventScr_UnitWarpIN'));
    s.placeholder('CURSOR_CHAR');
    await s.stall(60);
    s.placeholder('CURE');
    s.placeholder('TEXTSTART');
    await s.textShow(2722);
    s.placeholder('TEXTEND');
    s.placeholder('REMA');
    s.setSlot(2, 87);
    await s.call(Sym('EventScr_UnitWarpOUT'));
    s.placeholder('DISA');
    s.moveUnit('MOVE', [24, 83, 17, 0]);
    s.placeholder('ENUN');
    s.placeholder('DISA');
    s.moveUnit('MOVE', [24, 129, 16, 0]);
    s.moveUnit('MOVE', [24, 130, 18, 0]);
    s.placeholder('ENUN');
    s.placeholder('DISA');
    s.placeholder('DISA');
    s.setSlot(2, Sym('UnitDef_Ch12BEnemy_1'));
    await s.call(Sym('EventScr_LoadReinforce'));
    s.placeholder('STAL2');
    s.setSlot(2, Sym('UnitDef_Ch12BEnemy_2'));
    await s.call(Sym('EventScr_LoadReinforce'));
    s.placeholder('STAL2');
    s.setSlot(2, Sym('frontier_df3_unitdef_b_032_91908C'));
    await s.call(Sym('EventScr_LoadReinforce'));
    s.placeholder('STAL2');
    s.setSlot(2, Sym('UnitDef_Ch12BEnemy_4'));
    await s.call(Sym('EventScr_LoadReinforce'));
    s.placeholder('STAL2');
    s.placeholder('CAMERA_CAHR');
    s.placeholder('CURSOR_CHAR');
    await s.stall(60);
    s.placeholder('CURE');
    s.placeholder('TEXTSTART');
    await s.textShow(2723);
    s.placeholder('TEXTEND');
    s.placeholder('REMA');
    s.placeholder('EVBIT_T');
    return;
}

/// `EventScr_Ch13A_3`
Future<void> Ch13A_3(Scene s) async {
    s.placeholder('MUSC');
    s.setSlot(2, Sym('UnitDef_Ch13AEnemy_3'));
    await s.call(Sym('EventScr_LoadReinforce'));
    s.setSlot(2, Sym('UnitDef_Ch13AEnemy_4'));
    await s.call(Sym('EventScr_LoadReinforceHardMode'));
    s.placeholder('CURSOR_CHAR');
    await s.stall(60);
    s.placeholder('CURE');
    s.placeholder('TEXTSTART');
    await s.textShow(2607);
    s.placeholder('TEXTEND');
    s.placeholder('REMA');
    s.placeholder('EVBIT_T');
    return;
}

/// `EventScr_Ch13A_4`
Future<void> Ch13A_4(Scene s) async {
    var pc = 0;
    while (true) {
      switch (pc) {
        case 0:
          s.placeholder('CHECK_TURNS');
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
          if (s.slotInt(0) == 12) { pc = 8; } else { pc = 4; }
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
          s.placeholder('EVBIT_T');
          pc = 10;
          continue;
        case 10:
          return;
        default:
          return;
      }
    }
}

/// `EventScr_Ch13B_0`
Future<void> Ch13B_0(Scene s) async {
    var pc = 0;
    while (true) {
      switch (pc) {
        case 0:
          s.placeholder('CHECK_EVENTID');
          pc = 1;
          continue;
        case 1:
          if (s.slotInt(0) != 12) { pc = 12; } else { pc = 2; }
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
          s.placeholder('MUSI');
          pc = 7;
          continue;
        case 7:
          s.placeholder('TEXTSTART');
          pc = 8;
          continue;
        case 8:
          await s.textShow(2740);
          pc = 9;
          continue;
        case 9:
          s.placeholder('TEXTEND');
          pc = 10;
          continue;
        case 10:
          s.placeholder('REMA');
          pc = 11;
          continue;
        case 11:
          s.placeholder('MUNO');
          pc = 12;
          continue;
        case 12:
          pc = 13;
          continue;
        case 13:
          s.placeholder('EVBIT_T');
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
          s.placeholder('CHECK_EVENTID');
          pc = 1;
          continue;
        case 1:
          if (s.slotInt(0) != 12) { pc = 12; } else { pc = 2; }
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
          s.placeholder('MUSI');
          pc = 7;
          continue;
        case 7:
          s.placeholder('TEXTSTART');
          pc = 8;
          continue;
        case 8:
          await s.textShow(2741);
          pc = 9;
          continue;
        case 9:
          s.placeholder('TEXTEND');
          pc = 10;
          continue;
        case 10:
          s.placeholder('REMA');
          pc = 11;
          continue;
        case 11:
          s.placeholder('MUNO');
          pc = 12;
          continue;
        case 12:
          pc = 13;
          continue;
        case 13:
          s.placeholder('EVBIT_T');
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
          s.placeholder('CHECK_EVENTID');
          pc = 1;
          continue;
        case 1:
          if (s.slotInt(0) != 12) { pc = 11; } else { pc = 2; }
          continue;
        case 2:
          s.placeholder('CAMERA_CAHR');
          pc = 3;
          continue;
        case 3:
          s.placeholder('CURSOR_CHAR');
          pc = 4;
          continue;
        case 4:
          await s.stall(60);
          pc = 5;
          continue;
        case 5:
          s.placeholder('CURE');
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
          s.placeholder('TEXTEND');
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
          s.placeholder('TEXTEND');
          pc = 16;
          continue;
        case 16:
          pc = 17;
          continue;
        case 17:
          s.placeholder('REMA');
          pc = 18;
          continue;
        case 18:
          s.placeholder('FADI');
          pc = 19;
          continue;
        case 19:
          s.placeholder('CLEE');
          pc = 20;
          continue;
        case 20:
          s.placeholder('CLEAN');
          pc = 21;
          continue;
        case 21:
          s.placeholder('CAMERA');
          pc = 22;
          continue;
        case 22:
          s.placeholder('FADU');
          pc = 23;
          continue;
        case 23:
          s.loadUnits(1, Sym('UnitDef_Ch13ANPC'));
          pc = 24;
          continue;
        case 24:
          s.placeholder('ENUN');
          pc = 25;
          continue;
        case 25:
          s.placeholder('CURSOR_CHAR');
          pc = 26;
          continue;
        case 26:
          await s.stall(60);
          pc = 27;
          continue;
        case 27:
          s.placeholder('CURE');
          pc = 28;
          continue;
        case 28:
          s.placeholder('MUSC');
          pc = 29;
          continue;
        case 29:
          s.placeholder('TEXTSTART');
          pc = 30;
          continue;
        case 30:
          await s.textShow(2616);
          pc = 31;
          continue;
        case 31:
          s.placeholder('TEXTEND');
          pc = 32;
          continue;
        case 32:
          s.placeholder('REMA');
          pc = 33;
          continue;
        case 33:
          s.placeholder('CAMERA_CAHR');
          pc = 34;
          continue;
        case 34:
          s.placeholder('CURSOR_CHAR');
          pc = 35;
          continue;
        case 35:
          await s.stall(60);
          pc = 36;
          continue;
        case 36:
          s.placeholder('CURE');
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
          s.placeholder('TEXTEND');
          pc = 41;
          continue;
        case 41:
          s.placeholder('REMA');
          pc = 42;
          continue;
        case 42:
          s.placeholder('FADI');
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
          s.placeholder('MUSS');
          pc = 46;
          continue;
        case 46:
          await s.stall(33);
          pc = 47;
          continue;
        case 47:
          s.placeholder('CHECK_ALIVE');
          pc = 48;
          continue;
        case 48:
          if (s.slotInt(10) == 12) { pc = 11; } else { pc = 49; }
          continue;
        case 49:
          await s.textShow(2618);
          pc = 50;
          continue;
        case 50:
          s.placeholder('TEXTEND');
          pc = 51;
          continue;
        case 51:
          s.placeholder('REMA');
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
          s.placeholder('GIVEITEMTOMAIN');
          pc = 55;
          continue;
        case 55:
          await s.textShow(2619);
          pc = 56;
          continue;
        case 56:
          s.placeholder('TEXTEND');
          pc = 57;
          continue;
        case 57:
          s.placeholder('EvtBgmFadeIn');
          pc = 58;
          continue;
        case 58:
          s.placeholder('TEXTCONT');
          pc = 59;
          continue;
        case 59:
          s.placeholder('TEXTEND');
          pc = 60;
          continue;
        case 60:
          s.placeholder('MUSC');
          pc = 61;
          continue;
        case 61:
          s.placeholder('TEXTCONT');
          pc = 62;
          continue;
        case 62:
          s.placeholder('TEXTEND');
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
          s.placeholder('TEXTEND');
          pc = 67;
          continue;
        case 67:
          s.placeholder('REMA');
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
          s.placeholder('GIVEITEMTOMAIN');
          pc = 71;
          continue;
        case 71:
          await s.textShow(2621);
          pc = 72;
          continue;
        case 72:
          s.placeholder('TEXTEND');
          pc = 73;
          continue;
        case 73:
          s.placeholder('EvtBgmFadeIn');
          pc = 74;
          continue;
        case 74:
          s.placeholder('TEXTCONT');
          pc = 75;
          continue;
        case 75:
          s.placeholder('TEXTEND');
          pc = 76;
          continue;
        case 76:
          s.placeholder('MUSC');
          pc = 77;
          continue;
        case 77:
          s.placeholder('TEXTCONT');
          pc = 78;
          continue;
        case 78:
          s.placeholder('TEXTEND');
          pc = 79;
          continue;
        case 79:
          pc = 80;
          continue;
        case 80:
          s.placeholder('REMA');
          pc = 81;
          continue;
        case 81:
          s.placeholder('FADI');
          pc = 82;
          continue;
        case 82:
          s.placeholder('CLEA');
          pc = 83;
          continue;
        case 83:
          s.placeholder('CLEE');
          pc = 84;
          continue;
        case 84:
          s.placeholder('CLEN');
          pc = 85;
          continue;
        case 85:
          s.placeholder('CHECK_EVENTID');
          pc = 86;
          continue;
        case 86:
          if (s.slotInt(99) != 12) { pc = 11; } else { pc = 87; }
          continue;
        case 87:
          s.setSlot(11, 0);
          pc = 88;
          continue;
        case 88:
          s.placeholder('LOMA');
          pc = 89;
          continue;
        case 89:
          s.loadUnits(1, Sym('frontier_df3_unitdef_b_000_90F678', 2368));
          pc = 90;
          continue;
        case 90:
          s.placeholder('ENUN');
          pc = 91;
          continue;
        case 91:
          s.placeholder('FADU');
          pc = 92;
          continue;
        case 92:
          s.loadUnits(1, Sym('frontier_df3_unitdef_b_000_90F678', 2408));
          pc = 93;
          continue;
        case 93:
          s.placeholder('ENUN');
          pc = 94;
          continue;
        case 94:
          s.setSlot(1, 5);
          pc = 95;
          continue;
        case 95:
          s.placeholder('SET_HP');
          pc = 96;
          continue;
        case 96:
          s.placeholder('CURSOR_CHAR');
          pc = 97;
          continue;
        case 97:
          await s.stall(60);
          pc = 98;
          continue;
        case 98:
          s.placeholder('CURE');
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
          s.placeholder('MUSC');
          pc = 102;
          continue;
        case 102:
          await s.textShow(2622);
          pc = 103;
          continue;
        case 103:
          s.placeholder('TEXTEND');
          pc = 104;
          continue;
        case 104:
          s.placeholder('REMA');
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
          s.placeholder('SENQUEUE1');
          pc = 109;
          continue;
        case 109:
          s.placeholder('FIGHT_MAP');
          pc = 110;
          continue;
        case 110:
          s.placeholder('FADI');
          pc = 111;
          continue;
        case 111:
          pc = 112;
          continue;
        case 112:
          s.placeholder('ENUT');
          pc = 113;
          continue;
        case 113:
          s.placeholder('MNCH');
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
    s.placeholder('FADI');
    s.placeholder('CLEA');
    s.placeholder('CLEE');
    s.placeholder('CLEN');
    s.placeholder('CAMERA2');
    s.placeholder('EvtSetLoadUnitNoREDA');
    s.loadUnits(2, Sym('frontier_df3_unitdef_b_033_9191E0', 1964));
    s.placeholder('ENUN');
    s.placeholder('FADU');
    s.loadUnits(2, Sym('frontier_df3_unitdef_b_033_9191E0', 1964));
    s.placeholder('ENUN');
    s.placeholder('CURSOR_CHAR');
    await s.stall(60);
    s.placeholder('CURE');
    s.placeholder('MUSC');
    s.setSlot(2, 44);
    await s.call(Sym('EventScr_SetBackground'));
    await s.textShow(2739);
    s.placeholder('TEXTEND');
    s.placeholder('REMA');
    s.placeholder('FADI');
    s.placeholder('CLEA');
    s.placeholder('CLEE');
    s.placeholder('CLEN');
    s.placeholder('ENUT');
    s.placeholder('MNCH');
    return;
}

/// `EventScr_Ch14A_0`
Future<void> Ch14A_0(Scene s) async {
    s.placeholder('CAMERA2');
    s.loadUnits(1, Sym('frontier_df3_unitdef_b_003_91066C_residue'));
    s.placeholder('ENUN');
    s.placeholder('CURSOR_CHAR');
    await s.stall(60);
    s.placeholder('CURE');
    s.placeholder('MUSC');
    s.placeholder('TEXTSTART');
    await s.textShow(2630);
    s.placeholder('TEXTEND');
    s.placeholder('REMA');
    s.moveUnit('MOVEONTO', [0, 83, 203]);
    s.placeholder('ENUN');
    s.moveUnit('MOVE_1STEP', [8, 203, 2]);
    s.moveUnit('MOVE_1STEP', [0, 82, 1]);
    s.placeholder('ENUN');
    s.placeholder('CURSOR_CHAR');
    await s.stall(60);
    s.placeholder('CURE');
    s.placeholder('TEXTSTART');
    await s.textShow(2631);
    s.placeholder('TEXTEND');
    s.placeholder('REMA');
    s.moveUnit('MOVE_1STEP', [0, 82, 0]);
    s.placeholder('ENUN');
    s.moveUnit('MOVEONTO', [0, 83, 203]);
    s.placeholder('ENUN');
    s.placeholder('DISA');
    await s.stall(16);
    s.moveUnit('MOVE', [0, 83, 9, 8]);
    s.placeholder('ENUN');
    s.placeholder('CURSOR_CHAR');
    await s.stall(60);
    s.placeholder('CURE');
    s.placeholder('TEXTSTART');
    await s.textShow(2632);
    s.placeholder('TEXTEND');
    s.placeholder('REMA');
    s.moveUnit('MOVEONTO', [0, 83, 64]);
    s.placeholder('ENUN');
    s.placeholder('DISA');
    s.moveUnit('MOVE', [0, 83, 17, 11]);
    s.placeholder('ENUN');
    s.placeholder('DISA');
    s.placeholder('CAMERA2');
    s.moveUnit('MOVE', [0, 82, 9, 5]);
    s.loadUnits(1, Sym('UnitDef_Ch14AEnemy_6'));
    s.placeholder('ENUN');
    s.placeholder('EVBIT_T');
    return;
}

/// `EventScr_Ch14A_1`
Future<void> Ch14A_1(Scene s) async {
    s.setSlot(2, 9);
    s.setSlot(3, 28);
    s.setSlot(4, 9980);
    s.setSlot(13, 0);
    s.setSlot(1, 2649);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 2650);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 2652);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 2653);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 2654);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 2651);
    s.placeholder('SENQUEUE1');
    await s.call(Sym('EventScr_9EEAAC'));
    return;
}

/// `EventScr_Ch14A_8`
Future<void> Ch14A_8(Scene s) async {
    s.setSlot(2, 0);
    await s.call(Sym('UnitDef_Ch14BAlly_7'));
    s.setSlot(13, 0);
    s.setSlot(1, 458760);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 458761);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 458762);
    s.placeholder('SENQUEUE1');
    s.setSlot(2, 65536);
    await s.call(Sym('EventScr_ChangeAIinQueue'));
    s.placeholder('EVBIT_T');
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
          s.placeholder('COUNTER_DEC');
          pc = 5;
          continue;
        case 5:
          s.placeholder('ENUF');
          pc = 6;
          continue;
        case 6:
          s.placeholder('COUNTER_CHECK');
          pc = 7;
          continue;
        case 7:
          if (s.slotInt(0) != 12) { pc = 9; } else { pc = 8; }
          continue;
        case 8:
          s.placeholder('ENUT');
          pc = 9;
          continue;
        case 9:
          pc = 10;
          continue;
        case 10:
          s.placeholder('EVBIT_T');
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
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 2771);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 2773);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 2774);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 2775);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 2772);
    s.placeholder('SENQUEUE1');
    await s.call(Sym('EventScr_9EEAAC'));
    return;
}

/// `EventScr_Ch14b_BeginningScene`
Future<void> Ch14b_BeginningScene(Scene s) async {
    s.loadUnits(1, Sym('frontier_df3_unitdef_b_037_91AC38_tail_p1', 240));
    s.placeholder('ENUN');
    s.placeholder('REMU');
    s.loadUnits(1, Sym('frontier_df3_unitdef_b_038_91B948_residue', 240));
    s.placeholder('ENUN');
    s.placeholder('CAMERA');
    s.placeholder('CLEAN');
    s.placeholder('MUSC');
    s.placeholder('FADU');
    s.loadUnits(2, Sym('frontier_df3_unitdef_b_038_91B948_residue'));
    s.setSlot(1, 0);
    s.placeholder('SET_STATE');
    s.setSlot(1, 0);
    s.placeholder('SET_STATE');
    s.loadUnits(3, Sym('frontier_df3_unitdef_b_038_91B948_residue', 60));
    s.placeholder('ENUN');
    s.setSlot(1, 4294967295);
    s.placeholder('SET_STATE');
    s.setSlot(1, 4294967295);
    s.placeholder('SET_STATE');
    s.placeholder('CURSOR_CHAR');
    await s.stall(60);
    s.placeholder('CURE');
    s.setSlot(2, 73);
    await s.call(Sym('EventScr_SetBackground'));
    await s.textShow(2778);
    s.placeholder('TEXTEND');
    s.placeholder('REMA');
    s.placeholder('EvtBgmFadeIn');
    s.placeholder('FADI');
    s.placeholder('CLEAN');
    s.placeholder('CAMERA');
    s.placeholder('FADU');
    s.placeholder('SPAWN_ENEMY');
    s.setSlot(2, 64);
    s.moveUnit('MOVE_CLOSEST', [65535, 65533, 5, 2]);
    await s.call(Sym('EventScr_UnitWarpIN'));
    s.placeholder('CURSOR_CHAR');
    await s.stall(60);
    s.placeholder('CURE');
    s.placeholder('MUSC');
    s.setSlot(2, 73);
    s.setSlot(3, 2779);
    await s.call(Sym('Event_TextWithBG'));
    s.setSlot(2, 64);
    await s.call(Sym('EventScr_UnitWarpOUT'));
    s.placeholder('DISA');
    s.moveUnit('MOVE_1STEP', [0, 102, 3]);
    s.placeholder('ENUN');
    s.moveUnit('MOVEONTO', [0, 102, 83]);
    s.placeholder('ENUN');
    s.loadUnits(1, Sym('frontier_df3_unitdef_b_037_91AC38_tail_p1', 1100));
    s.placeholder('ENUN');
    s.placeholder('ENUN');
    s.placeholder('REVEAL');
    s.placeholder('DISA');
    s.placeholder('FADI');
    await s.call(Sym('data_085B9BBC', 512));
    s.placeholder('CAMERA2');
    s.placeholder('FADU');
    s.placeholder('MUSC');
    s.loadUnits(1, Sym('frontier_df3_unitdef_b_037_91AC38_tail_p1', 1180));
    s.placeholder('ENUN');
    s.placeholder('REVEAL');
    s.placeholder('CURSOR_CHAR');
    await s.stall(60);
    s.placeholder('CURE');
    s.setSlot(2, 73);
    s.setSlot(3, 2781);
    await s.call(Sym('Event_TextWithBG'));
    s.placeholder('EVBIT_T');
    return;
}

/// `EventScr_Ch14b_EndingScene`
Future<void> Ch14b_EndingScene(Scene s) async {
    await s.call(Sym('EventScr_Ch15A_26'));
    s.placeholder('ENUT');
    s.placeholder('MNCH');
    return;
    s.placeholder('MUSI');
    s.setSlot(2, 0);
    s.setSlot(3, 2806);
    await s.call(Sym('Event_TextWithBG'));
    s.placeholder('MUNO');
    await s.call(Sym('data_085B9BBC', 360));
    s.setSlot(3, 136);
    s.placeholder('GIVEITEMTO');
    s.placeholder('EVBIT_T');
    return;
    s.placeholder('MUSI');
    s.setSlot(2, 0);
    s.setSlot(3, 2807);
    await s.call(Sym('Event_TextWithBG'));
    s.placeholder('MUNO');
    s.placeholder('EVBIT_T');
    return;
    s.placeholder('MUSI');
    s.setSlot(2, 0);
    s.setSlot(3, 2808);
    await s.call(Sym('Event_TextWithBG'));
    s.placeholder('MUNO');
    s.placeholder('EVBIT_T');
    return;
    s.placeholder('MUSS');
    await s.stall(33);
    s.placeholder('TEXTSTART');
    await s.textShow(2796);
    s.placeholder('TEXTEND');
    s.placeholder('REMA');
    s.placeholder('MURE');
    s.placeholder('EVBIT_T');
    return;
    s.placeholder('MUSI');
    s.placeholder('TEXTSTART');
    await s.textShow(2802);
    s.placeholder('TEXTEND');
    s.placeholder('REMA');
    s.placeholder('MUNO');
    s.placeholder('EVBIT_T');
    return;
    s.placeholder('MUSI');
    s.placeholder('TEXTSTART');
    await s.textShow(2803);
    s.placeholder('TEXTEND');
    s.placeholder('REMA');
    s.placeholder('MUNO');
    s.placeholder('EVBIT_T');
    return;
    s.placeholder('MUSI');
    s.placeholder('TEXTSTART');
    await s.textShow(2804);
    s.placeholder('TEXTEND');
    s.placeholder('REMA');
    s.placeholder('MUNO');
    s.placeholder('EVBIT_T');
    return;
    s.placeholder('MUSI');
    s.placeholder('TEXTSTART');
    await s.textShow(2805);
    s.placeholder('TEXTEND');
    s.placeholder('REMA');
    s.placeholder('MUNO');
    s.placeholder('EVBIT_T');
    return;
    s.setSlot(2, Sym('frontier_df3_unitdef_b_037_91AC38_tail_p1', 1260));
    await s.call(Sym('EventScr_LoadReinforce'));
    s.placeholder('EVBIT_T');
    return;
    s.setSlot(2, Sym('frontier_df3_unitdef_b_037_91AC38_tail_p1', 1320));
    await s.call(Sym('EventScr_LoadReinforce'));
    s.placeholder('EVBIT_T');
    return;
    s.setSlot(2, Sym('UnitDef_Ch15BEnemy_4'));
    await s.call(Sym('EventScr_LoadReinforce'));
    s.placeholder('EVBIT_T');
    return;
    s.setSlot(2, Sym('UnitDef_Ch15BEnemy_5'));
    await s.call(Sym('EventScr_LoadReinforce'));
    s.placeholder('EVBIT_T');
    return;
    s.setSlot(2, Sym('frontier_df3_unitdef_b_038_91B948'));
    await s.call(Sym('EventScr_LoadReinforce'));
    s.placeholder('EVBIT_T');
    return;
    s.setSlot(2, 0);
    await s.call(Sym('UnitDef_Ch14BAlly_7'));
    s.setSlot(1, 65536);
    s.placeholder('CHAI');
    s.setSlot(1, 70144);
    s.placeholder('CHAI');
    s.placeholder('EVBIT_T');
    return;
}

/// `EventScr_Ch15A_0`
Future<void> Ch15A_0(Scene s) async {
    s.placeholder('MUSC');
    s.placeholder('EVBIT_T');
    s.loadUnits(1, Sym('UnitDef_Ch15AAlly_1'));
    s.placeholder('ENUN');
    s.placeholder('EVBIT_F');
    s.placeholder('CURSOR_CHAR');
    await s.stall(60);
    s.placeholder('CURE');
    s.setSlot(2, 73);
    s.setSlot(3, 2780);
    await s.call(Sym('Event_TextWithBG'));
    s.placeholder('REVEAL');
    s.placeholder('EVBIT_T');
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
          s.placeholder('CHECK_LUCK');
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
          if (s.slotInt(33196) != 12) { pc = 7; } else { pc = 7; }
          continue;
        case 7:
          await s.call(Sym('UnitDef_Ch14BAlly_7', 28));
          pc = 8;
          continue;
        case 8:
          pc = 9;
          continue;
        case 9:
          s.placeholder('EVBIT_T');
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
          s.placeholder('CHECK_LUCK');
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
          if (s.slotInt(33212) != 12) { pc = 7; } else { pc = 7; }
          continue;
        case 7:
          await s.call(Sym('UnitDef_Ch14BAlly_7', 28));
          pc = 8;
          continue;
        case 8:
          pc = 9;
          continue;
        case 9:
          s.placeholder('EVBIT_T');
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
          s.placeholder('CHECK_LUCK');
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
          if (s.slotInt(33228) != 12) { pc = 7; } else { pc = 7; }
          continue;
        case 7:
          await s.call(Sym('UnitDef_Ch14BAlly_7', 28));
          pc = 8;
          continue;
        case 8:
          pc = 9;
          continue;
        case 9:
          s.placeholder('EVBIT_T');
          pc = 10;
          continue;
        case 10:
          return;
        default:
          return;
      }
    }
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
          s.placeholder('CHECK_LUCK');
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
          if (s.slotInt(33244) != 12) { pc = 7; } else { pc = 7; }
          continue;
        case 7:
          await s.call(Sym('UnitDef_Ch14BAlly_7', 28));
          pc = 8;
          continue;
        case 8:
          pc = 9;
          continue;
        case 9:
          s.placeholder('EVBIT_T');
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
          s.placeholder('CHECK_LUCK');
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
          if (s.slotInt(33260) != 12) { pc = 7; } else { pc = 7; }
          continue;
        case 7:
          await s.call(Sym('UnitDef_Ch14BAlly_7', 28));
          pc = 8;
          continue;
        case 8:
          pc = 9;
          continue;
        case 9:
          s.placeholder('EVBIT_T');
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
          s.placeholder('CHECK_LUCK');
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
          if (s.slotInt(33276) != 12) { pc = 7; } else { pc = 7; }
          continue;
        case 7:
          await s.call(Sym('UnitDef_Ch14BAlly_7', 28));
          pc = 8;
          continue;
        case 8:
          pc = 9;
          continue;
        case 9:
          s.placeholder('EVBIT_T');
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
          s.placeholder('CHECK_LUCK');
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
          if (s.slotInt(33292) != 12) { pc = 7; } else { pc = 7; }
          continue;
        case 7:
          await s.call(Sym('UnitDef_Ch14BAlly_7', 28));
          pc = 8;
          continue;
        case 8:
          pc = 9;
          continue;
        case 9:
          s.placeholder('EVBIT_T');
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
          s.placeholder('CHECK_LUCK');
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
          if (s.slotInt(33308) != 12) { pc = 7; } else { pc = 7; }
          continue;
        case 7:
          await s.call(Sym('UnitDef_Ch14BAlly_7', 28));
          pc = 8;
          continue;
        case 8:
          pc = 9;
          continue;
        case 9:
          s.placeholder('EVBIT_T');
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
          s.placeholder('CHECK_LUCK');
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
          if (s.slotInt(33324) != 12) { pc = 7; } else { pc = 7; }
          continue;
        case 7:
          await s.call(Sym('UnitDef_Ch14BAlly_7', 28));
          pc = 8;
          continue;
        case 8:
          pc = 9;
          continue;
        case 9:
          s.placeholder('EVBIT_T');
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
          s.placeholder('MUSC');
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
          s.placeholder('CHECK_MODE');
          pc = 4;
          continue;
        case 4:
          s.setSlot(1, 2);
          pc = 5;
          continue;
        case 5:
          if (s.slotInt(0) != 12) { pc = 26; } else { pc = 6; }
          continue;
        case 6:
          await s.textShow(2792);
          pc = 7;
          continue;
        case 7:
          s.placeholder('TEXTEND');
          pc = 8;
          continue;
        case 8:
          s.placeholder('REMA');
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
          s.placeholder('GIVEITEMTO');
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
          s.placeholder('GIVEITEMTO');
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
          s.placeholder('TEXTEND');
          pc = 19;
          continue;
        case 19:
          s.placeholder('REMA');
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
          s.placeholder('GIVEITEMTO');
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
          s.placeholder('GIVEITEMTO');
          pc = 26;
          continue;
        case 26:
          pc = 27;
          continue;
        case 27:
          s.placeholder('FADI');
          pc = 28;
          continue;
        case 28:
          s.placeholder('CLEA');
          pc = 29;
          continue;
        case 29:
          s.placeholder('CLEE');
          pc = 30;
          continue;
        case 30:
          s.placeholder('CLEN');
          pc = 31;
          continue;
        case 31:
          s.placeholder('CAMERA2');
          pc = 32;
          continue;
        case 32:
          s.placeholder('CLEAN');
          pc = 33;
          continue;
        case 33:
          s.placeholder('FADU');
          pc = 34;
          continue;
        case 34:
          s.placeholder('CURSOR_AT');
          pc = 35;
          continue;
        case 35:
          await s.stall(60);
          pc = 36;
          continue;
        case 36:
          s.placeholder('CURE');
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
          s.placeholder('TEXTEND');
          pc = 41;
          continue;
        case 41:
          s.placeholder('MUSS');
          pc = 42;
          continue;
        case 42:
          await s.stall(33);
          pc = 43;
          continue;
        case 43:
          s.placeholder('TEXTCONT');
          pc = 44;
          continue;
        case 44:
          s.placeholder('TEXTEND');
          pc = 45;
          continue;
        case 45:
          s.placeholder('MURE');
          pc = 46;
          continue;
        case 46:
          s.placeholder('TEXTCONT');
          pc = 47;
          continue;
        case 47:
          s.placeholder('TEXTEND');
          pc = 48;
          continue;
        case 48:
          s.placeholder('REMA');
          pc = 49;
          continue;
        case 49:
          s.placeholder('EvtBgmFadeIn');
          pc = 50;
          continue;
        case 50:
          s.placeholder('FADI');
          pc = 51;
          continue;
        case 51:
          s.placeholder('CHECK_ALIVE');
          pc = 52;
          continue;
        case 52:
          if (s.slotInt(99) == 12) { pc = 16; } else { pc = 53; }
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
          s.placeholder('MUSC');
          pc = 56;
          continue;
        case 56:
          await s.textShow(2795);
          pc = 57;
          continue;
        case 57:
          s.placeholder('TEXTEND');
          pc = 58;
          continue;
        case 58:
          s.placeholder('REMA');
          pc = 59;
          continue;
        case 59:
          s.placeholder('FADI');
          pc = 60;
          continue;
        case 60:
          pc = 61;
          continue;
        case 61:
          return;
        case 62:
          s.placeholder('MUSI');
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
          s.placeholder('CHECK_LUCK');
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
          if (s.slotInt(33118) != 12) { pc = 7; } else { pc = 7; }
          continue;
        case 7:
          await s.call(Sym('UnitDef_Ch14BAlly_7', 28));
          pc = 8;
          continue;
        case 8:
          pc = 9;
          continue;
        case 9:
          s.placeholder('EVBIT_T');
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
          s.placeholder('CHECK_LUCK');
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
          if (s.slotInt(33134) != 12) { pc = 7; } else { pc = 7; }
          continue;
        case 7:
          await s.call(Sym('UnitDef_Ch14BAlly_7', 28));
          pc = 8;
          continue;
        case 8:
          pc = 9;
          continue;
        case 9:
          s.placeholder('EVBIT_T');
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
          s.placeholder('CHECK_LUCK');
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
          if (s.slotInt(33150) != 12) { pc = 7; } else { pc = 7; }
          continue;
        case 7:
          await s.call(Sym('UnitDef_Ch14BAlly_7', 28));
          pc = 8;
          continue;
        case 8:
          pc = 9;
          continue;
        case 9:
          s.placeholder('EVBIT_T');
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
          s.placeholder('CHECK_LUCK');
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
          if (s.slotInt(33166) != 12) { pc = 7; } else { pc = 7; }
          continue;
        case 7:
          await s.call(Sym('UnitDef_Ch14BAlly_7', 28));
          pc = 8;
          continue;
        case 8:
          pc = 9;
          continue;
        case 9:
          s.placeholder('EVBIT_T');
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
          s.placeholder('CHECK_LUCK');
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
          if (s.slotInt(33182) != 12) { pc = 7; } else { pc = 7; }
          continue;
        case 7:
          await s.call(Sym('UnitDef_Ch14BAlly_7', 28));
          pc = 8;
          continue;
        case 8:
          pc = 9;
          continue;
        case 9:
          s.placeholder('EVBIT_T');
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
          s.placeholder('CHECK_LUCK');
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
          if (s.slotInt(33198) != 12) { pc = 7; } else { pc = 7; }
          continue;
        case 7:
          await s.call(Sym('UnitDef_Ch14BAlly_7', 28));
          pc = 8;
          continue;
        case 8:
          pc = 9;
          continue;
        case 9:
          s.placeholder('EVBIT_T');
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
          s.placeholder('CHECK_LUCK');
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
          if (s.slotInt(33214) != 12) { pc = 7; } else { pc = 7; }
          continue;
        case 7:
          await s.call(Sym('UnitDef_Ch14BAlly_7', 28));
          pc = 8;
          continue;
        case 8:
          pc = 9;
          continue;
        case 9:
          s.placeholder('EVBIT_T');
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
          s.placeholder('CHECK_LUCK');
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
          if (s.slotInt(33230) != 12) { pc = 7; } else { pc = 7; }
          continue;
        case 7:
          await s.call(Sym('UnitDef_Ch14BAlly_7', 28));
          pc = 8;
          continue;
        case 8:
          pc = 9;
          continue;
        case 9:
          s.placeholder('EVBIT_T');
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
          s.placeholder('CHECK_LUCK');
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
          if (s.slotInt(33246) != 12) { pc = 7; } else { pc = 7; }
          continue;
        case 7:
          await s.call(Sym('UnitDef_Ch14BAlly_7', 28));
          pc = 8;
          continue;
        case 8:
          pc = 9;
          continue;
        case 9:
          s.placeholder('EVBIT_T');
          pc = 10;
          continue;
        case 10:
          return;
        default:
          return;
      }
    }
}

/// `EventScr_Ch16A_1`
Future<void> Ch16A_1(Scene s) async {
    s.slotArith('SADD', 10, 2);
    s.placeholder('STARTFADE');
    s.placeholder('EvtColorFadeSetup');
    s.placeholder('FAWU');
    await s.call(Sym('data_085B9BBC', 360));
    s.placeholder('EVBIT_MODIFY');
    await s.call(Sym('EventScr_Ch16A_1', 84));
    s.placeholder('EvtBgmFadeIn');
    s.placeholder('REMOVEPORTRAITS');
    s.slotArith('SADD', 2, 10);
    s.placeholder('BACG');
    s.placeholder('FAWU');
    s.placeholder('EVBIT_MODIFY');
    return;
    s.placeholder('CHECK_MODE');
    s.placeholder('EVENT_WORD');
}

/// `EventScr_Ch16A_11`
Future<void> Ch16A_11(Scene s) async {
    var pc = 0;
    while (true) {
      switch (pc) {
        case 0:
          s.placeholder('MUSC');
          pc = 1;
          continue;
        case 1:
          s.setSlot(11, 0);
          pc = 2;
          continue;
        case 2:
          s.placeholder('LOMA');
          pc = 3;
          continue;
        case 3:
          s.placeholder('FADU');
          pc = 4;
          continue;
        case 4:
          s.loadUnits(2, Sym('UnitDef_Ch16AAlly_5'));
          pc = 5;
          continue;
        case 5:
          s.placeholder('ENUN');
          pc = 6;
          continue;
        case 6:
          s.placeholder('CURSOR_CHAR');
          pc = 7;
          continue;
        case 7:
          await s.stall(60);
          pc = 8;
          continue;
        case 8:
          s.placeholder('CURE');
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
          s.placeholder('TEXTEND');
          pc = 13;
          continue;
        case 13:
          s.placeholder('MUSC');
          pc = 14;
          continue;
        case 14:
          s.placeholder('TEXTCONT');
          pc = 15;
          continue;
        case 15:
          s.placeholder('TEXTEND');
          pc = 16;
          continue;
        case 16:
          s.placeholder('REMA');
          pc = 17;
          continue;
        case 17:
          s.placeholder('FADI');
          pc = 18;
          continue;
        case 18:
          s.placeholder('CLEAN');
          pc = 19;
          continue;
        case 19:
          s.placeholder('FADU');
          pc = 20;
          continue;
        case 20:
          s.moveUnit('MOVE_1STEP', [16, 30, 3]);
          pc = 21;
          continue;
        case 21:
          s.placeholder('ENUN');
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
          s.placeholder('TEXTEND');
          pc = 26;
          continue;
        case 26:
          s.placeholder('REMA');
          pc = 27;
          continue;
        case 27:
          s.placeholder('EvtBgmFadeIn');
          pc = 28;
          continue;
        case 28:
          s.placeholder('FADI');
          pc = 29;
          continue;
        case 29:
          s.placeholder('CLEA');
          pc = 30;
          continue;
        case 30:
          s.placeholder('CLEE');
          pc = 31;
          continue;
        case 31:
          s.placeholder('CLEN');
          pc = 32;
          continue;
        case 32:
          s.setSlot(11, 786432);
          pc = 33;
          continue;
        case 33:
          s.placeholder('LOMA');
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
          s.placeholder('ENUN');
          pc = 37;
          continue;
        case 37:
          s.placeholder('FADU');
          pc = 38;
          continue;
        case 38:
          s.loadUnits(2, Sym('frontier_df3_unitdef_b_012_911C34', 316));
          pc = 39;
          continue;
        case 39:
          s.placeholder('ENUN');
          pc = 40;
          continue;
        case 40:
          s.placeholder('SOUN');
          pc = 41;
          continue;
        case 41:
          s.placeholder('TILECHANGE');
          pc = 42;
          continue;
        case 42:
          s.moveUnit('MOVE', [0, 109, 7, 6]);
          pc = 43;
          continue;
        case 43:
          s.placeholder('ENUN');
          pc = 44;
          continue;
        case 44:
          s.placeholder('TILEREVERT');
          pc = 45;
          continue;
        case 45:
          s.loadUnits(2, Sym('frontier_df3_unitdef_b_012_911C34', 356));
          pc = 46;
          continue;
        case 46:
          s.placeholder('ENUN');
          pc = 47;
          continue;
        case 47:
          s.placeholder('FADI');
          pc = 48;
          continue;
        case 48:
          s.placeholder('CLEA');
          pc = 49;
          continue;
        case 49:
          s.placeholder('CLEE');
          pc = 50;
          continue;
        case 50:
          s.placeholder('CLEN');
          pc = 51;
          continue;
        case 51:
          s.placeholder('CHECK_MODE');
          pc = 52;
          continue;
        case 52:
          s.setSlot(1, 2);
          pc = 53;
          continue;
        case 53:
          if (s.slotInt(1) != 12) { pc = 61; } else { pc = 54; }
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
          s.placeholder('TEXTEND');
          pc = 58;
          continue;
        case 58:
          s.placeholder('REMA');
          pc = 59;
          continue;
        case 59:
          s.placeholder('FADI');
          pc = 60;
          continue;
        case 60:
          s.placeholder('CLEAN');
          pc = 61;
          continue;
        case 61:
          pc = 62;
          continue;
        case 62:
          s.placeholder('CHECK_MODE');
          pc = 63;
          continue;
        case 63:
          s.setSlot(1, 2);
          pc = 64;
          continue;
        case 64:
          if (s.slotInt(2) == 12) { pc = 61; } else { pc = 65; }
          continue;
        case 65:
          s.placeholder('MUSC');
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
          s.placeholder('ENUN');
          pc = 69;
          continue;
        case 69:
          s.placeholder('REMU');
          pc = 70;
          continue;
        case 70:
          s.placeholder('REMU');
          pc = 71;
          continue;
        case 71:
          s.placeholder('FADU');
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
          s.placeholder('ENUN');
          pc = 80;
          continue;
        case 80:
          s.placeholder('CURSOR_CHAR');
          pc = 81;
          continue;
        case 81:
          await s.stall(60);
          pc = 82;
          continue;
        case 82:
          s.placeholder('CURE');
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
          s.placeholder('ENUN');
          pc = 89;
          continue;
        case 89:
          pc = 90;
          continue;
        case 90:
          s.placeholder('CHECK_MODE');
          pc = 91;
          continue;
        case 91:
          s.setSlot(1, 2);
          pc = 92;
          continue;
        case 92:
          if (s.slotInt(3) != 12) { pc = 61; } else { pc = 93; }
          continue;
        case 93:
          s.loadUnits(2, Sym('UnitDef_Ch16AAlly_8'));
          pc = 94;
          continue;
        case 94:
          s.placeholder('ENUN');
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
          s.placeholder('FADU');
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
          s.placeholder('ENUN');
          pc = 101;
          continue;
        case 101:
          s.placeholder('SOUN');
          pc = 102;
          continue;
        case 102:
          s.placeholder('TILECHANGE');
          pc = 103;
          continue;
        case 103:
          s.moveUnit('MOVE', [16, 64, 7, 5]);
          pc = 104;
          continue;
        case 104:
          s.placeholder('ENUN');
          pc = 105;
          continue;
        case 105:
          s.moveUnit('MOVE', [16, 87, 8, 6]);
          pc = 106;
          continue;
        case 106:
          s.placeholder('ENUN');
          pc = 107;
          continue;
        case 107:
          s.placeholder('TILEREVERT');
          pc = 108;
          continue;
        case 108:
          s.loadUnits(2, Sym('frontier_df3_unitdef_b_013_911E38', 60));
          pc = 109;
          continue;
        case 109:
          s.placeholder('ENUN');
          pc = 110;
          continue;
        case 110:
          s.moveUnit('MOVE_1STEP', [16, 128, 1]);
          pc = 111;
          continue;
        case 111:
          s.placeholder('ENUN');
          pc = 112;
          continue;
        case 112:
          s.moveUnit('MOVE_1STEP', [16, 129, 0]);
          pc = 113;
          continue;
        case 113:
          s.placeholder('ENUN');
          pc = 114;
          continue;
        case 114:
          s.placeholder('MUSC');
          pc = 115;
          continue;
        case 115:
          s.placeholder('CURSOR_CHAR');
          pc = 116;
          continue;
        case 116:
          await s.stall(60);
          pc = 117;
          continue;
        case 117:
          s.placeholder('CURE');
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
          s.placeholder('CHECK_MODE');
          pc = 121;
          continue;
        case 121:
          s.setSlot(1, 2);
          pc = 122;
          continue;
        case 122:
          if (s.slotInt(4) != 12) { pc = 61; } else { pc = 123; }
          continue;
        case 123:
          await s.textShow(2813);
          pc = 124;
          continue;
        case 124:
          s.placeholder('TEXTEND');
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
          s.placeholder('TEXTEND');
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
          s.placeholder('REMA');
          pc = 132;
          continue;
        case 132:
          s.placeholder('FADI');
          pc = 133;
          continue;
        case 133:
          s.placeholder('CLEA');
          pc = 134;
          continue;
        case 134:
          s.placeholder('CLEE');
          pc = 135;
          continue;
        case 135:
          s.placeholder('CLEN');
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
          s.placeholder('CHECK_MODE');
          pc = 139;
          continue;
        case 139:
          s.setSlot(1, 2);
          pc = 140;
          continue;
        case 140:
          if (s.slotInt(6) != 12) { pc = 61; } else { pc = 141; }
          continue;
        case 141:
          await s.textShow(2815);
          pc = 142;
          continue;
        case 142:
          s.placeholder('TEXTEND');
          pc = 143;
          continue;
        case 143:
          pc = 148;
          continue;
        case 144:
          pc = 145;
          continue;
        case 145:
          s.placeholder('MUSC');
          pc = 146;
          continue;
        case 146:
          await s.textShow(2816);
          pc = 147;
          continue;
        case 147:
          s.placeholder('TEXTEND');
          pc = 148;
          continue;
        case 148:
          pc = 149;
          continue;
        case 149:
          s.placeholder('REMA');
          pc = 150;
          continue;
        case 150:
          s.placeholder('FADI');
          pc = 151;
          continue;
        case 151:
          s.placeholder('CHECK_MODE');
          pc = 152;
          continue;
        case 152:
          s.setSlot(1, 2);
          pc = 153;
          continue;
        case 153:
          if (s.slotInt(8) != 12) { pc = 61; } else { pc = 154; }
          continue;
        case 154:
          s.placeholder('CLEAN');
          pc = 155;
          continue;
        case 155:
          s.placeholder('CAMERA');
          pc = 156;
          continue;
        case 156:
          s.placeholder('MUSC');
          pc = 157;
          continue;
        case 157:
          s.placeholder('FADU');
          pc = 158;
          continue;
        case 158:
          s.loadUnits(2, Sym('frontier_df3_unitdef_b_013_911E38', 120));
          pc = 159;
          continue;
        case 159:
          s.placeholder('ENUN');
          pc = 160;
          continue;
        case 160:
          s.placeholder('CURSOR_CHAR');
          pc = 161;
          continue;
        case 161:
          await s.stall(60);
          pc = 162;
          continue;
        case 162:
          s.placeholder('CURE');
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
          s.placeholder('FADI');
          pc = 171;
          continue;
        case 171:
          s.placeholder('CLEA');
          pc = 172;
          continue;
        case 172:
          s.placeholder('CLEE');
          pc = 173;
          continue;
        case 173:
          s.placeholder('CLEN');
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
          s.placeholder('FADI');
          pc = 1;
          continue;
        case 1:
          s.placeholder('CLEA');
          pc = 2;
          continue;
        case 2:
          s.placeholder('CLEE');
          pc = 3;
          continue;
        case 3:
          s.placeholder('CLEN');
          pc = 4;
          continue;
        case 4:
          s.placeholder('MUSC');
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
          s.placeholder('TEXTEND');
          pc = 9;
          continue;
        case 9:
          s.placeholder('REMA');
          pc = 10;
          continue;
        case 10:
          s.placeholder('FADI');
          pc = 11;
          continue;
        case 11:
          s.setSlot(11, 0);
          pc = 12;
          continue;
        case 12:
          s.placeholder('LOMA');
          pc = 13;
          continue;
        case 13:
          s.placeholder('FADU');
          pc = 14;
          continue;
        case 14:
          s.loadUnits(2, Sym('frontier_df3_unitdef_b_013_911E38_tail'));
          pc = 15;
          continue;
        case 15:
          s.placeholder('ENUN');
          pc = 16;
          continue;
        case 16:
          s.placeholder('SOUN');
          pc = 17;
          continue;
        case 17:
          s.placeholder('TILECHANGE');
          pc = 18;
          continue;
        case 18:
          s.loadUnits(2, Sym('UnitDef_Ch16AMixed_1'));
          pc = 19;
          continue;
        case 19:
          s.placeholder('ENUN');
          pc = 20;
          continue;
        case 20:
          s.placeholder('CURSOR_CHAR');
          pc = 21;
          continue;
        case 21:
          await s.stall(60);
          pc = 22;
          continue;
        case 22:
          s.placeholder('CURE');
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
          s.placeholder('TEXTEND');
          pc = 28;
          continue;
        case 28:
          s.placeholder('FADI');
          pc = 29;
          continue;
        case 29:
          s.placeholder('REMA');
          pc = 30;
          continue;
        case 30:
          s.placeholder('CLEA');
          pc = 31;
          continue;
        case 31:
          s.placeholder('CLEE');
          pc = 32;
          continue;
        case 32:
          s.placeholder('CLEN');
          pc = 33;
          continue;
        case 33:
          s.setSlot(11, 262158);
          pc = 34;
          continue;
        case 34:
          s.placeholder('LOMA');
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
          s.placeholder('ENUN');
          pc = 38;
          continue;
        case 38:
          s.placeholder('FADU');
          pc = 39;
          continue;
        case 39:
          s.placeholder('CURSOR_CHAR');
          pc = 40;
          continue;
        case 40:
          await s.stall(60);
          pc = 41;
          continue;
        case 41:
          s.placeholder('CURE');
          pc = 42;
          continue;
        case 42:
          s.placeholder('MUSC');
          pc = 43;
          continue;
        case 43:
          s.placeholder('TEXTSTART');
          pc = 44;
          continue;
        case 44:
          await s.textShow(2827);
          pc = 45;
          continue;
        case 45:
          s.placeholder('TEXTEND');
          pc = 46;
          continue;
        case 46:
          s.placeholder('REMA');
          pc = 47;
          continue;
        case 47:
          s.loadUnits(2, Sym('UnitDef_Ch16AAlly_0'));
          pc = 48;
          continue;
        case 48:
          s.placeholder('ENUN');
          pc = 49;
          continue;
        case 49:
          s.placeholder('CURSOR_CHAR');
          pc = 50;
          continue;
        case 50:
          await s.stall(60);
          pc = 51;
          continue;
        case 51:
          s.placeholder('CURE');
          pc = 52;
          continue;
        case 52:
          s.placeholder('TEXTSTART');
          pc = 53;
          continue;
        case 53:
          await s.textShow(2828);
          pc = 54;
          continue;
        case 54:
          s.placeholder('TEXTEND');
          pc = 55;
          continue;
        case 55:
          s.placeholder('REMA');
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
          s.placeholder('STAL2');
          pc = 60;
          continue;
        case 60:
          s.placeholder('EvtBgmFadeIn');
          pc = 61;
          continue;
        case 61:
          s.placeholder('FADI');
          pc = 62;
          continue;
        case 62:
          s.placeholder('ENUN');
          pc = 63;
          continue;
        case 63:
          s.placeholder('CLEA');
          pc = 64;
          continue;
        case 64:
          s.setSlot(11, 0);
          pc = 65;
          continue;
        case 65:
          s.placeholder('LOMA');
          pc = 66;
          continue;
        case 66:
          s.loadUnits(2, Sym('frontier_df3_unitdef_b_015_91206C', 20));
          pc = 67;
          continue;
        case 67:
          s.placeholder('ENUN');
          pc = 68;
          continue;
        case 68:
          s.placeholder('MUSC');
          pc = 69;
          continue;
        case 69:
          s.placeholder('FADU');
          pc = 70;
          continue;
        case 70:
          s.loadUnits(2, Sym('UnitDef_Ch16AAlly_13'));
          pc = 71;
          continue;
        case 71:
          s.placeholder('SOLOTEXTBOXSTART');
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
          s.placeholder('TEXTEND');
          pc = 75;
          continue;
        case 75:
          s.placeholder('REMA');
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
          s.placeholder('TEXTEND');
          pc = 79;
          continue;
        case 79:
          s.placeholder('REMA');
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
          s.placeholder('TEXTEND');
          pc = 83;
          continue;
        case 83:
          s.placeholder('REMA');
          pc = 84;
          continue;
        case 84:
          s.placeholder('ENUN');
          pc = 85;
          continue;
        case 85:
          s.placeholder('CURSOR_CHAR');
          pc = 86;
          continue;
        case 86:
          await s.stall(60);
          pc = 87;
          continue;
        case 87:
          s.placeholder('CURE');
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
          s.placeholder('TEXTEND');
          pc = 92;
          continue;
        case 92:
          s.placeholder('REMA');
          pc = 93;
          continue;
        case 93:
          s.placeholder('EvtBgmFadeIn');
          pc = 94;
          continue;
        case 94:
          s.placeholder('FADI');
          pc = 95;
          continue;
        case 95:
          s.placeholder('CLEA');
          pc = 96;
          continue;
        case 96:
          s.placeholder('CLEE');
          pc = 97;
          continue;
        case 97:
          s.placeholder('CLEN');
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
          s.placeholder('LOMA');
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
          s.placeholder('ENUN');
          pc = 104;
          continue;
        case 104:
          s.placeholder('FADU');
          pc = 105;
          continue;
        case 105:
          s.placeholder('CURSOR_CHAR');
          pc = 106;
          continue;
        case 106:
          await s.stall(60);
          pc = 107;
          continue;
        case 107:
          s.placeholder('CURE');
          pc = 108;
          continue;
        case 108:
          s.placeholder('TEXTSTART');
          pc = 109;
          continue;
        case 109:
          await s.textShow(2833);
          pc = 110;
          continue;
        case 110:
          s.placeholder('TEXTEND');
          pc = 111;
          continue;
        case 111:
          s.placeholder('REMA');
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
          s.placeholder('TILECHANGE');
          pc = 117;
          continue;
        case 117:
          s.setSlot(11, 196622);
          pc = 118;
          continue;
        case 118:
          s.placeholder('TILECHANGE');
          pc = 119;
          continue;
        case 119:
          s.placeholder('EvtColorFadeSetup');
          pc = 120;
          continue;
        case 120:
          s.placeholder('EVBIT_T');
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
          s.placeholder('FADI');
          pc = 124;
          continue;
        case 124:
          s.placeholder('ENUN');
          pc = 125;
          continue;
        case 125:
          s.placeholder('EVBIT_F');
          pc = 126;
          continue;
        case 126:
          s.placeholder('CLEA');
          pc = 127;
          continue;
        case 127:
          s.setSlot(11, 0);
          pc = 128;
          continue;
        case 128:
          s.placeholder('LOMA');
          pc = 129;
          continue;
        case 129:
          s.placeholder('FADU');
          pc = 130;
          continue;
        case 130:
          s.loadUnits(2, Sym('UnitDef_Ch16AAlly_15'));
          pc = 131;
          continue;
        case 131:
          s.placeholder('ENUN');
          pc = 132;
          continue;
        case 132:
          s.placeholder('CURSOR_CHAR');
          pc = 133;
          continue;
        case 133:
          await s.stall(60);
          pc = 134;
          continue;
        case 134:
          s.placeholder('CURE');
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
          s.placeholder('TEXTEND');
          pc = 140;
          continue;
        case 140:
          s.placeholder('EvtBgmFadeIn');
          pc = 141;
          continue;
        case 141:
          s.placeholder('FADI');
          pc = 142;
          continue;
        case 142:
          s.placeholder('REMA');
          pc = 143;
          continue;
        case 143:
          s.placeholder('CLEAN');
          pc = 144;
          continue;
        case 144:
          s.placeholder('FADU');
          pc = 145;
          continue;
        case 145:
          s.placeholder('CURSOR_CHAR');
          pc = 146;
          continue;
        case 146:
          await s.stall(60);
          pc = 147;
          continue;
        case 147:
          s.placeholder('CURE');
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
          s.placeholder('TEXTEND');
          pc = 152;
          continue;
        case 152:
          s.placeholder('SOUN');
          pc = 153;
          continue;
        case 153:
          s.placeholder('FAWI');
          pc = 154;
          continue;
        case 154:
          s.placeholder('REMA');
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
          s.placeholder('REMOVEPORTRAITS');
          pc = 159;
          continue;
        case 159:
          await s.textShow(2836);
          pc = 160;
          continue;
        case 160:
          s.placeholder('TEXTEND');
          pc = 161;
          continue;
        case 161:
          s.placeholder('REMA');
          pc = 162;
          continue;
        case 162:
          s.placeholder('FADI');
          pc = 163;
          continue;
        case 163:
          s.placeholder('CLEAN');
          pc = 164;
          continue;
        case 164:
          s.placeholder('FADU');
          pc = 165;
          continue;
        case 165:
          s.loadUnits(2, Sym('frontier_df3_unitdef_b_016_912198_residue'));
          pc = 166;
          continue;
        case 166:
          s.placeholder('ENUN');
          pc = 167;
          continue;
        case 167:
          s.placeholder('SOUN');
          pc = 168;
          continue;
        case 168:
          s.placeholder('TILECHANGE');
          pc = 169;
          continue;
        case 169:
          s.loadUnits(2, Sym('frontier_df3_unitdef_b_016_912198', 60));
          pc = 170;
          continue;
        case 170:
          s.placeholder('ENUN');
          pc = 171;
          continue;
        case 171:
          s.placeholder('SOUN');
          pc = 172;
          continue;
        case 172:
          s.placeholder('TILECHANGE');
          pc = 173;
          continue;
        case 173:
          s.loadUnits(2, Sym('frontier_df3_unitdef_b_016_912198', 100));
          pc = 174;
          continue;
        case 174:
          s.placeholder('ENUN');
          pc = 175;
          continue;
        case 175:
          s.placeholder('CURSOR_CHAR');
          pc = 176;
          continue;
        case 176:
          await s.stall(60);
          pc = 177;
          continue;
        case 177:
          s.placeholder('CURE');
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
          s.placeholder('TEXTEND');
          pc = 182;
          continue;
        case 182:
          s.placeholder('REMA');
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
          s.placeholder('GIVEITEMTO');
          pc = 186;
          continue;
        case 186:
          await s.textShow(2838);
          pc = 187;
          continue;
        case 187:
          s.placeholder('TEXTEND');
          pc = 188;
          continue;
        case 188:
          s.placeholder('REMA');
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
          s.placeholder('GIVEITEMTO');
          pc = 192;
          continue;
        case 192:
          s.placeholder('CHECK_MODE');
          pc = 193;
          continue;
        case 193:
          s.setSlot(1, 2);
          pc = 194;
          continue;
        case 194:
          if (s.slotInt(0) != 12) { pc = 201; } else { pc = 195; }
          continue;
        case 195:
          await s.textShow(2839);
          pc = 196;
          continue;
        case 196:
          s.placeholder('TEXTEND');
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
          s.placeholder('TEXTEND');
          pc = 201;
          continue;
        case 201:
          pc = 202;
          continue;
        case 202:
          s.placeholder('FADI');
          pc = 203;
          continue;
        case 203:
          s.placeholder('REMA');
          pc = 204;
          continue;
        case 204:
          s.placeholder('CLEA');
          pc = 205;
          continue;
        case 205:
          s.placeholder('CLEE');
          pc = 206;
          continue;
        case 206:
          s.placeholder('CLEN');
          pc = 207;
          continue;
        case 207:
          s.setSlot(11, 262158);
          pc = 208;
          continue;
        case 208:
          s.placeholder('LOMA');
          pc = 209;
          continue;
        case 209:
          s.setSlot(11, 196621);
          pc = 210;
          continue;
        case 210:
          s.placeholder('TILECHANGE');
          pc = 211;
          continue;
        case 211:
          s.setSlot(11, 196622);
          pc = 212;
          continue;
        case 212:
          s.placeholder('TILECHANGE');
          pc = 213;
          continue;
        case 213:
          s.loadUnits(2, Sym('frontier_df3_unitdef_b_010_9119D0'));
          pc = 214;
          continue;
        case 214:
          s.placeholder('ENUN');
          pc = 215;
          continue;
        case 215:
          s.placeholder('FADU');
          pc = 216;
          continue;
        case 216:
          s.loadUnits(2, Sym('UnitDef_Ch16AAlly_3'));
          pc = 217;
          continue;
        case 217:
          s.placeholder('ENUN');
          pc = 218;
          continue;
        case 218:
          s.setSlot(11, 196621);
          pc = 219;
          continue;
        case 219:
          s.placeholder('TILEREVERT');
          pc = 220;
          continue;
        case 220:
          s.setSlot(11, 196622);
          pc = 221;
          continue;
        case 221:
          s.placeholder('TILEREVERT');
          pc = 222;
          continue;
        case 222:
          s.placeholder('CURSOR_CHAR');
          pc = 223;
          continue;
        case 223:
          await s.stall(60);
          pc = 224;
          continue;
        case 224:
          s.placeholder('CURE');
          pc = 225;
          continue;
        case 225:
          s.placeholder('MUSC');
          pc = 226;
          continue;
        case 226:
          s.placeholder('CHECK_MODE');
          pc = 227;
          continue;
        case 227:
          s.setSlot(1, 2);
          pc = 228;
          continue;
        case 228:
          if (s.slotInt(10) != 12) { pc = 201; } else { pc = 229; }
          continue;
        case 229:
          s.placeholder('TEXTSTART');
          pc = 230;
          continue;
        case 230:
          await s.textShow(2841);
          pc = 231;
          continue;
        case 231:
          s.placeholder('TEXTEND');
          pc = 232;
          continue;
        case 232:
          s.placeholder('REMA');
          pc = 233;
          continue;
        case 233:
          pc = 239;
          continue;
        case 234:
          pc = 235;
          continue;
        case 235:
          s.placeholder('TEXTSTART');
          pc = 236;
          continue;
        case 236:
          await s.textShow(2842);
          pc = 237;
          continue;
        case 237:
          s.placeholder('TEXTEND');
          pc = 238;
          continue;
        case 238:
          s.placeholder('REMA');
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
          s.placeholder('ENUN');
          pc = 242;
          continue;
        case 242:
          s.placeholder('FADI');
          pc = 243;
          continue;
        case 243:
          s.placeholder('ENUN');
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
    s.placeholder('CAMERA');
    s.setSlot(2, Sym('UnitDef_Ch16AEnemy_4'));
    await s.call(Sym('EventScr_LoadReinforce'));
    s.setSlot(2, Sym('frontier_df3_unitdef_b_009_91187C'));
    await s.call(Sym('EventScr_LoadReinforce'));
    s.placeholder('EVBIT_T');
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
          s.placeholder('COUNTER_DEC');
          pc = 5;
          continue;
        case 5:
          s.placeholder('ENUF');
          pc = 6;
          continue;
        case 6:
          s.placeholder('COUNTER_CHECK');
          pc = 7;
          continue;
        case 7:
          if (s.slotInt(0) != 12) { pc = 9; } else { pc = 8; }
          continue;
        case 8:
          s.placeholder('ENUT');
          pc = 9;
          continue;
        case 9:
          pc = 10;
          continue;
        case 10:
          s.placeholder('EVBIT_T');
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
          s.placeholder('COUNTER_DEC');
          pc = 5;
          continue;
        case 5:
          s.placeholder('ENUF');
          pc = 6;
          continue;
        case 6:
          s.placeholder('COUNTER_CHECK');
          pc = 7;
          continue;
        case 7:
          if (s.slotInt(0) != 12) { pc = 9; } else { pc = 8; }
          continue;
        case 8:
          s.placeholder('ENUT');
          pc = 9;
          continue;
        case 9:
          pc = 10;
          continue;
        case 10:
          s.placeholder('EVBIT_T');
          pc = 11;
          continue;
        case 11:
          return;
        default:
          return;
      }
    }
}

/// `EventScr_Ch16b_BeginningScene`
Future<void> Ch16b_BeginningScene(Scene s) async {
    s.setSlot(2, Sym('frontier_df3_unitdef_b_042_91C230'));
    await s.call(Sym('frontier_df3_eventscr_ch_001_A696D4', 48));
    s.placeholder('ENUT');
    return;
    await s.call(Sym('frontier_df3_eventscr_ch_001_A696D4', 996));
    s.placeholder('MNCH');
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
          s.placeholder('MUSC');
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
          s.placeholder('CHECK_MODE');
          pc = 4;
          continue;
        case 4:
          s.setSlot(1, 2);
          pc = 5;
          continue;
        case 5:
          if (s.slotInt(0) != 12) { pc = 24; } else { pc = 6; }
          continue;
        case 6:
          await s.textShow(2874);
          pc = 7;
          continue;
        case 7:
          s.placeholder('TEXTEND');
          pc = 8;
          continue;
        case 8:
          s.placeholder('EvtBgmFadeIn');
          pc = 9;
          continue;
        case 9:
          s.placeholder('TEXTCONT');
          pc = 10;
          continue;
        case 10:
          s.placeholder('TEXTEND');
          pc = 11;
          continue;
        case 11:
          s.placeholder('MUSC');
          pc = 12;
          continue;
        case 12:
          s.placeholder('TEXTCONT');
          pc = 13;
          continue;
        case 13:
          s.placeholder('TEXTEND');
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
          s.placeholder('TEXTEND');
          pc = 18;
          continue;
        case 18:
          s.placeholder('EvtBgmFadeIn');
          pc = 19;
          continue;
        case 19:
          s.placeholder('TEXTCONT');
          pc = 20;
          continue;
        case 20:
          s.placeholder('TEXTEND');
          pc = 21;
          continue;
        case 21:
          s.placeholder('MUSC');
          pc = 22;
          continue;
        case 22:
          s.placeholder('TEXTCONT');
          pc = 23;
          continue;
        case 23:
          s.placeholder('TEXTEND');
          pc = 24;
          continue;
        case 24:
          pc = 25;
          continue;
        case 25:
          s.placeholder('REMA');
          pc = 26;
          continue;
        case 26:
          s.placeholder('EvtBgmFadeIn');
          pc = 27;
          continue;
        case 27:
          s.placeholder('FADI');
          pc = 28;
          continue;
        case 28:
          s.placeholder('CLEAN');
          pc = 29;
          continue;
        case 29:
          s.placeholder('FADU');
          pc = 30;
          continue;
        case 30:
          s.loadUnits(2, Sym('UnitDef_Ch18AMixed'));
          pc = 31;
          continue;
        case 31:
          s.placeholder('ENUN');
          pc = 32;
          continue;
        case 32:
          s.placeholder('MUSC');
          pc = 33;
          continue;
        case 33:
          s.placeholder('CURSOR_CHAR');
          pc = 34;
          continue;
        case 34:
          await s.stall(60);
          pc = 35;
          continue;
        case 35:
          s.placeholder('CURE');
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
          s.placeholder('CAMERA2');
          pc = 40;
          continue;
        case 40:
          await s.stall(60);
          pc = 41;
          continue;
        case 41:
          s.placeholder('CAMERA');
          pc = 42;
          continue;
        case 42:
          s.placeholder('CURSOR_CHAR');
          pc = 43;
          continue;
        case 43:
          await s.stall(60);
          pc = 44;
          continue;
        case 44:
          s.placeholder('CURE');
          pc = 45;
          continue;
        case 45:
          s.placeholder('MUSC');
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
          s.placeholder('TEXTEND');
          pc = 50;
          continue;
        case 50:
          s.placeholder('REMA');
          pc = 51;
          continue;
        case 51:
          s.placeholder('FADI');
          pc = 52;
          continue;
        case 52:
          s.placeholder('CLEN');
          pc = 53;
          continue;
        case 53:
          await s.call(Sym('data_085B9BBC', 512));
          pc = 54;
          continue;
        case 54:
          s.placeholder('ENUT');
          pc = 55;
          continue;
        case 55:
          s.placeholder('ENUT');
          pc = 56;
          continue;
        case 56:
          s.placeholder('ENUT');
          pc = 57;
          continue;
        case 57:
          s.placeholder('ENUT');
          pc = 58;
          continue;
        case 58:
          s.placeholder('EVBIT_T');
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
    s.placeholder('EVBIT_T');
    return;
    s.placeholder('CAMERA_CAHR');
    s.placeholder('CURSOR_CHAR');
    await s.stall(60);
    s.placeholder('CURE');
    s.placeholder('MUSC');
    s.placeholder('EVENT_WORD');
}

/// `EventScr_Ch19A_11`
Future<void> Ch19A_11(Scene s) async {
    var pc = 0;
    while (true) {
      switch (pc) {
        case 0:
          s.placeholder('CHECK_OTHERS');
          pc = 1;
          continue;
        case 1:
          s.slotArith('SADD', 7, 12);
          pc = 2;
          continue;
        case 2:
          s.placeholder('MUSC');
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
          s.placeholder('CHECK_MODE');
          pc = 6;
          continue;
        case 6:
          s.setSlot(1, 2);
          pc = 7;
          continue;
        case 7:
          if (s.slotInt(0) != 12) { pc = 19; } else { pc = 8; }
          continue;
        case 8:
          await s.textShow(2908);
          pc = 9;
          continue;
        case 9:
          s.placeholder('TEXTEND');
          pc = 10;
          continue;
        case 10:
          pc = 26;
          continue;
        case 11:
          pc = 12;
          continue;
        case 12:
          s.placeholder('CHECK_EVENTID');
          pc = 13;
          continue;
        case 13:
          if (s.slotInt(2) != 12) { pc = 11; } else { pc = 14; }
          continue;
        case 14:
          s.placeholder('CHECK_ALIVE');
          pc = 15;
          continue;
        case 15:
          if (s.slotInt(1) == 12) { pc = 11; } else { pc = 16; }
          continue;
        case 16:
          await s.textShow(2909);
          pc = 17;
          continue;
        case 17:
          s.placeholder('TEXTEND');
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
          s.placeholder('TEXTEND');
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
          s.placeholder('TEXTEND');
          pc = 26;
          continue;
        case 26:
          pc = 27;
          continue;
        case 27:
          s.placeholder('REMA');
          pc = 28;
          continue;
        case 28:
          s.placeholder('EvtBgmFadeIn');
          pc = 29;
          continue;
        case 29:
          s.placeholder('FADI');
          pc = 30;
          continue;
        case 30:
          s.placeholder('CLEA');
          pc = 31;
          continue;
        case 31:
          s.placeholder('CLEE');
          pc = 32;
          continue;
        case 32:
          s.placeholder('CLEN');
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
          s.placeholder('LOMA');
          pc = 36;
          continue;
        case 36:
          s.placeholder('FADU');
          pc = 37;
          continue;
        case 37:
          s.loadUnits(2, Sym('frontier_df3_unitdef_b_022_915038_tail_p1'));
          pc = 38;
          continue;
        case 38:
          s.placeholder('ENUN');
          pc = 39;
          continue;
        case 39:
          s.placeholder('SOUN');
          pc = 40;
          continue;
        case 40:
          s.placeholder('TILECHANGE');
          pc = 41;
          continue;
        case 41:
          s.loadUnits(2, Sym('UnitDef_Ch19AAlly_5'));
          pc = 42;
          continue;
        case 42:
          s.placeholder('ENUN');
          pc = 43;
          continue;
        case 43:
          s.loadUnits(2, Sym('frontier_df3_unitdef_b_023_91512C'));
          pc = 44;
          continue;
        case 44:
          s.placeholder('ENUN');
          pc = 45;
          continue;
        case 45:
          s.placeholder('CURSOR_CHAR');
          pc = 46;
          continue;
        case 46:
          await s.stall(60);
          pc = 47;
          continue;
        case 47:
          s.placeholder('CURE');
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
          s.placeholder('MUSC');
          pc = 51;
          continue;
        case 51:
          await s.textShow(2912);
          pc = 52;
          continue;
        case 52:
          s.placeholder('TEXTEND');
          pc = 53;
          continue;
        case 53:
          s.placeholder('REMA');
          pc = 54;
          continue;
        case 54:
          s.placeholder('EvtBgmFadeIn');
          pc = 55;
          continue;
        case 55:
          s.placeholder('FADI');
          pc = 56;
          continue;
        case 56:
          s.placeholder('CLEA');
          pc = 57;
          continue;
        case 57:
          s.placeholder('CLEE');
          pc = 58;
          continue;
        case 58:
          s.placeholder('CLEN');
          pc = 59;
          continue;
        case 59:
          s.placeholder('CHECK_MODE');
          pc = 60;
          continue;
        case 60:
          s.setSlot(1, 2);
          pc = 61;
          continue;
        case 61:
          if (s.slotInt(10) != 12) { pc = 19; } else { pc = 62; }
          continue;
        case 62:
          s.setSlot(11, 1572864);
          pc = 63;
          continue;
        case 63:
          s.placeholder('LOMA');
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
          s.placeholder('LOMA');
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
          s.placeholder('ENUN');
          pc = 71;
          continue;
        case 71:
          s.placeholder('FADU');
          pc = 72;
          continue;
        case 72:
          s.loadUnits(2, Sym('UnitDef_Ch19ANPC_3'));
          pc = 73;
          continue;
        case 73:
          s.placeholder('ENUN');
          pc = 74;
          continue;
        case 74:
          s.placeholder('CURSOR_CHAR');
          pc = 75;
          continue;
        case 75:
          await s.stall(60);
          pc = 76;
          continue;
        case 76:
          s.placeholder('CURE');
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
          s.placeholder('MUSC');
          pc = 80;
          continue;
        case 80:
          await s.textShow(2913);
          pc = 81;
          continue;
        case 81:
          s.placeholder('TEXTEND');
          pc = 82;
          continue;
        case 82:
          s.placeholder('CHECK_MODE');
          pc = 83;
          continue;
        case 83:
          s.setSlot(1, 2);
          pc = 84;
          continue;
        case 84:
          if (s.slotInt(20) != 12) { pc = 19; } else { pc = 85; }
          continue;
        case 85:
          s.placeholder('EvtTextShow2');
          pc = 86;
          continue;
        case 86:
          s.placeholder('TEXTEND');
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
          s.placeholder('TEXTEND');
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
          s.placeholder('TEXTEND');
          pc = 94;
          continue;
        case 94:
          s.placeholder('REMA');
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
          s.placeholder('GIVEITEMTO');
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
          s.placeholder('GIVEITEMTO');
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
          s.placeholder('GIVEITEMTOMAIN');
          pc = 104;
          continue;
        case 104:
          s.placeholder('CHECK_MODE');
          pc = 105;
          continue;
        case 105:
          s.setSlot(1, 2);
          pc = 106;
          continue;
        case 106:
          if (s.slotInt(30) != 12) { pc = 19; } else { pc = 107; }
          continue;
        case 107:
          await s.textShow(2917);
          pc = 108;
          continue;
        case 108:
          s.placeholder('TEXTEND');
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
          s.placeholder('TEXTEND');
          pc = 113;
          continue;
        case 113:
          pc = 114;
          continue;
        case 114:
          s.placeholder('REMA');
          pc = 115;
          continue;
        case 115:
          s.setSlot(8, 6);
          pc = 116;
          continue;
        case 116:
          s.placeholder('BLT');
          pc = 117;
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
          s.placeholder('CHECK_MODE');
          pc = 120;
          continue;
        case 120:
          s.setSlot(1, 2);
          pc = 121;
          continue;
        case 121:
          if (s.slotInt(40) != 12) { pc = 19; } else { pc = 122; }
          continue;
        case 122:
          await s.textShow(2919);
          pc = 123;
          continue;
        case 123:
          s.placeholder('TEXTEND');
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
          s.placeholder('TEXTEND');
          pc = 128;
          continue;
        case 128:
          pc = 129;
          continue;
        case 129:
          s.placeholder('REMA');
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
          s.placeholder('GIVEITEMTO');
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

/// `EventScr_Ch1Tut_BeforeSethMoveToEnemy`
Future<void> Ch1Tut_BeforeSethMoveToEnemy(Scene s) async {
    s.placeholder('EVBIT_T');
    s.placeholder('IGNORE_KEYS');
    s.setSlot(13, 0);
    s.setSlot(1, 393225);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 2320);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 524296);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, Sym('EventScr_Ch1Tut_AfterSethMoveToEnemy'));
    s.placeholder('SENQUEUE1');
    s.setSlot(1, Sym('EventScr_Ch1Tut_BeforeSethMoveToEnemy'));
    s.placeholder('SENQUEUE1');
    await s.call(Sym('EventScr_Tutorial_Exec1'));
    s.placeholder('DISABLEOPTIONS');
    s.placeholder('IGNORE_KEYS');
    return;
}

/// `EventScr_Ch1Tut_ChooseSethTurn1`
Future<void> Ch1Tut_ChooseSethTurn1(Scene s) async {
    s.placeholder('TUTORIALTEXTBOXSTART');
    s.setSlot(11, 4294967295);
    await s.textShow(2318);
    s.placeholder('TEXTEND');
    s.placeholder('REMA');
    s.placeholder('CURSOR_FLASHING_CHAR');
    await s.stall(60);
    s.placeholder('CURE');
    s.setSlot(13, 0);
    s.setSlot(1, 0);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 1);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 65536);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 4294967295);
    s.placeholder('SENQUEUE1');
    s.placeholder('FIGHT_SCRIPT');
    s.placeholder('EvtEnqueueConditionalTutCall');
    s.placeholder('DISABLEOPTIONS');
    return;
}

/// `EventScr_Ch1Tut_EirikaVisitHouseIdle1`
Future<void> Ch1Tut_EirikaVisitHouseIdle1(Scene s) async {
    s.placeholder('EVBIT_T');
    s.setSlot(13, 0);
    s.setSlot(1, 1);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 393229);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 2304);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 524296);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 2303);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 524296);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, Sym('EventScr_Ch1Tut_EirikaVisitHouseIdle2'));
    s.placeholder('SENQUEUE1');
    s.setSlot(1, Sym('EventScr_Ch1Tut_EirikaVisitHouseIdle1'));
    s.placeholder('SENQUEUE1');
    await s.call(Sym('EventScr_Tutorial_Exec0'));
    return;
}

/// `EventScr_Ch1Tut_EirikaVisitHouseIdle2`
Future<void> Ch1Tut_EirikaVisitHouseIdle2(Scene s) async {
    s.placeholder('EVBIT_T');
    s.placeholder('IGNORE_KEYS');
    s.setSlot(13, 0);
    s.setSlot(1, 393229);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 0);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 0);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, Sym('EventScr_Ch1Tut_EirikaVisitHouseEnd'));
    s.placeholder('SENQUEUE1');
    s.setSlot(1, Sym('EventScr_Ch1Tut_EirikaVisitHouseIdle2'));
    s.placeholder('SENQUEUE1');
    await s.call(Sym('EventScr_Tutorial_Exec1'));
    s.placeholder('DISABLEOPTIONS');
    s.placeholder('IGNORE_KEYS');
    return;
}

/// `EventScr_Ch1Tut_EirikaVisitHouseInit`
Future<void> Ch1Tut_EirikaVisitHouseInit(Scene s) async {
    s.placeholder('MUSC');
    s.placeholder('TEXTSTART');
    await s.textShow(2286);
    s.placeholder('TEXTEND');
    s.placeholder('REMA');
    s.placeholder('CURSOR_FLASHING');
    await s.stall(60);
    s.placeholder('CURE');
    s.placeholder('TUTORIALTEXTBOXSTART');
    s.setSlot(11, 4294967295);
    s.placeholder('EVENT_WORD_SYM');
    s.placeholder('TEXTEND');
    s.placeholder('REMA');
    s.placeholder('CURSOR_FLASHING_CHAR');
    await s.stall(60);
    s.placeholder('CURE');
    s.placeholder('EvtEnqueueConditionalTutCall');
    s.placeholder('DISABLEOPTIONS');
    s.placeholder('EVBIT_T');
    return;
}

/// `EventScr_Ch1Tut_GuideTerrainHeal`
Future<void> Ch1Tut_GuideTerrainHeal(Scene s) async {
    s.placeholder('IGNORE_KEYS');
    s.placeholder('CURSOR_FLASHING');
    s.placeholder('CURSOR_FLASHING');
    s.placeholder('CURSOR_FLASHING');
    await s.stall(60);
    s.placeholder('CURE');
    s.placeholder('TUTORIALTEXTBOXSTART');
    s.setSlot(11, 4294967295);
    await s.textShow(2306);
    s.placeholder('TEXTEND');
    s.placeholder('REMA');
    s.placeholder('ENUT');
    s.placeholder('DISABLEOPTIONS');
    s.placeholder('EVBIT_T');
    return;
}

/// `EventScr_Ch1Tut_OnBeginning`
Future<void> Ch1Tut_OnBeginning(Scene s) async {
    s.placeholder('CURSOR_CHAR');
    await s.stall(60);
    s.placeholder('CURE');
    s.placeholder('TUTORIALTEXTBOXSTART');
    s.setSlot(11, 4294967295);
    await s.textShow(2307);
    s.placeholder('TEXTEND');
    s.placeholder('REMA');
    s.placeholder('ENUT');
    s.placeholder('ENUT');
    s.placeholder('TEXTSTART');
    s.placeholder('EVENT_WORD_SYM');
    s.placeholder('TEXTEND');
    s.placeholder('REMA');
    return;
}

/// `EventScr_Ch1Tut_SethMoveToEnemy`
Future<void> Ch1Tut_SethMoveToEnemy(Scene s) async {
    s.placeholder('EVBIT_T');
    s.setSlot(13, 0);
    s.setSlot(1, 2);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 393225);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 2320);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 524296);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 2319);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 524296);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, Sym('EventScr_Ch1Tut_BeforeSethMoveToEnemy'));
    s.placeholder('SENQUEUE1');
    s.setSlot(1, Sym('EventScr_Ch1Tut_SethMoveToEnemy'));
    s.placeholder('SENQUEUE1');
    await s.call(Sym('EventScr_Tutorial_Exec0'));
    return;
}

/// `EventScr_Ch1Tut_TradeSelectGalliamIdle1`
Future<void> Ch1Tut_TradeSelectGalliamIdle1(Scene s) async {
    s.placeholder('EVBIT_T');
    s.setSlot(13, 0);
    s.setSlot(1, 3);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 131080);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 2311);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 4194344);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 2310);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 4194344);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, Sym('EventScr_Ch1Tut_TradeSelectGalliamIdle2'));
    s.placeholder('SENQUEUE1');
    s.setSlot(1, Sym('EventScr_Ch1Tut_TradeSelectGalliamIdle1'));
    s.placeholder('SENQUEUE1');
    await s.call(Sym('EventScr_Tutorial_Exec0'));
    s.placeholder('IGNORE_KEYS');
    return;
}

/// `EventScr_Ch1Tut_TradeSelectGalliamIdle2`
Future<void> Ch1Tut_TradeSelectGalliamIdle2(Scene s) async {
    s.placeholder('EVBIT_T');
    s.placeholder('IGNORE_KEYS');
    s.setSlot(13, 0);
    s.setSlot(1, 131080);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 0);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 0);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, Sym('EventScr_Ch1Tut_TradeSelectGalliamEnd'));
    s.placeholder('SENQUEUE1');
    s.setSlot(1, Sym('EventScr_Ch1Tut_TradeSelectGalliamIdle2'));
    s.placeholder('SENQUEUE1');
    await s.call(Sym('EventScr_Tutorial_Exec1'));
    s.placeholder('DISABLEOPTIONS');
    s.placeholder('IGNORE_KEYS');
    return;
}

/// `EventScr_Ch1_BeginningScene`
Future<void> Ch1_BeginningScene(Scene s) async {
    s.placeholder('MUSC');
    s.loadUnits(1, Sym('UnitDef_Event_Ch1Enemy'));
    s.placeholder('ENUN');
    s.placeholder('STAL2');
    s.placeholder('CURSOR_AT');
    await s.stall(60);
    s.placeholder('CURE');
    s.setSlot(2, 57);
    s.setSlot(3, 2281);
    await s.call(Sym('Event_TextWithBG'));
    s.loadUnits(1, Sym('UnitDef_Event_Ch1NPC'));
    s.placeholder('ENUN');
    s.setSlot(11, 0);
    s.placeholder('DISA');
    s.placeholder('CURSOR_CHAR');
    await s.stall(60);
    s.placeholder('CURE');
    s.setSlot(2, 36);
    s.setSlot(3, 2282);
    await s.call(Sym('Event_TextWithBG'));
    s.moveUnit('MOVE', [0, 70, 2, 3]);
    s.placeholder('ENUN');
    s.placeholder('ENUT');
    s.setSlot(13, 0);
    s.setSlot(1, 70656);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 1);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 4294967295);
    s.placeholder('SENQUEUE1');
    s.placeholder('FIGHT');
    s.placeholder('ENUF');
    s.setSlot(11, 131074);
    s.placeholder('KILL');
    s.placeholder('DISA_IF');
    s.placeholder('CURSOR_CHAR');
    await s.stall(60);
    s.placeholder('CURE');
    await s.textShow(2283);
    s.placeholder('TEXTEND');
    s.placeholder('REMA');
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
    s.placeholder('ENUN');
    s.placeholder('STAL2');
    s.placeholder('CURSOR_AT');
    await s.stall(60);
    s.placeholder('CURE');
    s.setSlot(2, 57);
    s.setSlot(3, 2284);
    await s.call(Sym('Event_TextWithBG'));
    s.placeholder('REMA');
    s.loadUnits(2, Sym('UnitDef_Event_Ch1Ally'));
    s.placeholder('ENUN');
    s.placeholder('CURSOR_CHAR');
    await s.stall(60);
    s.placeholder('CURE');
    s.placeholder('TEXTSTART');
    await s.textShow(2285);
    s.placeholder('TEXTEND');
    s.placeholder('REMA');
    s.setSlot(2, 2);
    await s.call(Sym('EventScr_MoveUnitS2ToLeader'));
    s.setSlot(2, Sym('EventScr_Ch1Tut_OnBeginning'));
    await s.call(Sym('EventScr_CallOnTutorialMode'));
    s.placeholder('ENUT');
    s.placeholder('EVBIT_T');
    return;
}

/// `EventScr_Ch1_EndingScene`
Future<void> Ch1_EndingScene(Scene s) async {
    var pc = 0;
    while (true) {
      switch (pc) {
        case 0:
          s.placeholder('MUSC');
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
          s.placeholder('CHECK_ALIVE');
          pc = 4;
          continue;
        case 4:
          if (s.slotInt(0) == 12) { pc = 8; } else { pc = 5; }
          continue;
        case 5:
          await s.textShow(2295);
          pc = 6;
          continue;
        case 6:
          s.placeholder('TEXTEND');
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
          s.placeholder('TEXTEND');
          pc = 11;
          continue;
        case 11:
          pc = 12;
          continue;
        case 12:
          s.placeholder('REMA');
          pc = 13;
          continue;
        case 13:
          s.placeholder('FADI');
          pc = 14;
          continue;
        case 14:
          s.placeholder('ENUT');
          pc = 15;
          continue;
        case 15:
          s.placeholder('ENUT');
          pc = 16;
          continue;
        case 16:
          s.placeholder('ENUT');
          pc = 17;
          continue;
        case 17:
          s.placeholder('ENUT');
          pc = 18;
          continue;
        case 18:
          s.placeholder('ENUT');
          pc = 19;
          continue;
        case 19:
          s.placeholder('ENUT');
          pc = 20;
          continue;
        case 20:
          s.placeholder('ENUT');
          pc = 21;
          continue;
        case 21:
          s.placeholder('ENUT');
          pc = 22;
          continue;
        case 22:
          s.placeholder('ENUT');
          pc = 23;
          continue;
        case 23:
          s.placeholder('REVEAL');
          pc = 24;
          continue;
        case 24:
          s.placeholder('MNCH');
          pc = 25;
          continue;
        case 25:
          return;
        default:
          return;
      }
    }
}

/// `EventScr_Ch1_Turn_AllyReinforceArrive`
Future<void> Ch1_Turn_AllyReinforceArrive(Scene s) async {
    s.placeholder('MUSC');
    s.loadUnits(1, Sym('UnitDef_Event_Ch1AllyReinforce'));
    s.placeholder('ENUN');
    s.placeholder('CURSOR_CHAR');
    await s.stall(60);
    s.placeholder('CURE');
    s.placeholder('TEXTSTART');
    await s.textShow(2289);
    s.placeholder('TEXTEND');
    s.placeholder('REMA');
    s.setSlot(2, Sym('EventScr_Ch1Tut_GilliamBattle'));
    await s.call(Sym('EventScr_CallOnTutorialMode'));
    s.placeholder('EVBIT_T');
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
          s.placeholder('COUNTER_DEC');
          pc = 3;
          continue;
        case 3:
          s.placeholder('ENUF');
          pc = 4;
          continue;
        case 4:
          s.placeholder('COUNTER_CHECK');
          pc = 5;
          continue;
        case 5:
          if (s.slotInt(0) != 12) { pc = 7; } else { pc = 6; }
          continue;
        case 6:
          s.placeholder('ENUT');
          pc = 7;
          continue;
        case 7:
          pc = 8;
          continue;
        case 8:
          s.placeholder('EVBIT_T');
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
          s.placeholder('COUNTER_DEC');
          pc = 3;
          continue;
        case 3:
          s.placeholder('ENUF');
          pc = 4;
          continue;
        case 4:
          s.placeholder('COUNTER_CHECK');
          pc = 5;
          continue;
        case 5:
          if (s.slotInt(0) != 12) { pc = 7; } else { pc = 6; }
          continue;
        case 6:
          s.placeholder('ENUT');
          pc = 7;
          continue;
        case 7:
          pc = 8;
          continue;
        case 8:
          s.placeholder('EVBIT_T');
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
    s.placeholder('DISA');
    s.placeholder('FADI');
    s.loadUnits(1, Sym('UnitDef_Ch21BEnemy_0'));
    s.placeholder('ENUN');
    await s.call(Sym('data_085B9BBC', 512));
    s.placeholder('ENUT');
    s.placeholder('ENUT');
    s.placeholder('ENUT');
    return;
}

/// `EventScr_Ch21A_0`
Future<void> Ch21A_0(Scene s) async {
    s.placeholder('EvtBgmFadeIn');
    s.placeholder('FADI');
    s.placeholder('CLEA');
    s.placeholder('CLEE');
    s.placeholder('CLEN');
    s.placeholder('CAMERA2');
    s.placeholder('EvtSetLoadUnitNoREDA');
    s.loadUnits(2, Sym('UnitDef_Ch21AMixed'));
    s.placeholder('ENUN');
    s.placeholder('FADU');
    s.loadUnits(2, Sym('UnitDef_Ch21AMixed'));
    s.placeholder('ENUN');
    s.placeholder('CURSOR_CHAR');
    await s.stall(60);
    s.placeholder('CURE');
    s.placeholder('TEXTSTART');
    await s.textShow(2949);
    s.placeholder('TEXTEND');
    s.placeholder('EvtBgmFadeIn');
    s.placeholder('TEXTCONT');
    s.placeholder('TEXTEND');
    s.placeholder('REMA');
    s.placeholder('EvtBgmFadeIn');
    await s.call(Sym('EventScr_Ch21A_9'));
    s.placeholder('MNC3');
    return;
}

/// `EventScr_Ch21A_8`
Future<void> Ch21A_8(Scene s) async {
    var pc = 0;
    while (true) {
      switch (pc) {
        case 0:
          s.placeholder('REMOVEPORTRAITS');
          pc = 1;
          continue;
        case 1:
          s.placeholder('BACG');
          pc = 2;
          continue;
        case 2:
          s.placeholder('FAWI');
          pc = 3;
          continue;
        case 3:
          s.placeholder('BACG');
          pc = 4;
          continue;
        case 4:
          s.placeholder('FAWU');
          pc = 5;
          continue;
        case 5:
          s.placeholder('EvtBgmFadeIn');
          pc = 6;
          continue;
        case 6:
          s.placeholder('BROWNBOXTEXT');
          pc = 7;
          continue;
        case 7:
          s.placeholder('CHECK_MODE');
          pc = 8;
          continue;
        case 8:
          s.setSlot(1, 2);
          pc = 9;
          continue;
        case 9:
          if (s.slotInt(0) != 12) { pc = 16; } else { pc = 10; }
          continue;
        case 10:
          await s.textShow(2938);
          pc = 11;
          continue;
        case 11:
          s.placeholder('TEXTEND');
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
          s.placeholder('TEXTEND');
          pc = 16;
          continue;
        case 16:
          pc = 17;
          continue;
        case 17:
          s.placeholder('REMA');
          pc = 18;
          continue;
        case 18:
          s.placeholder('EvtBgmFadeIn');
          pc = 19;
          continue;
        case 19:
          s.placeholder('FAWI');
          pc = 20;
          continue;
        case 20:
          s.placeholder('CLEAN');
          pc = 21;
          continue;
        case 21:
          s.loadUnits(1, Sym('frontier_df3_unitdef_b_023_91512C', 2792));
          pc = 22;
          continue;
        case 22:
          s.placeholder('ENUN');
          pc = 23;
          continue;
        case 23:
          s.placeholder('FAWU');
          pc = 24;
          continue;
        case 24:
          s.loadUnits(2, Sym('UnitDef_Ch21AAlly_1'));
          pc = 25;
          continue;
        case 25:
          s.placeholder('ENUN');
          pc = 26;
          continue;
        case 26:
          s.moveUnit('MOVE', [16, 0, 11, 20]);
          pc = 27;
          continue;
        case 27:
          s.placeholder('ENUN');
          pc = 28;
          continue;
        case 28:
          s.placeholder('CURSOR_CHAR');
          pc = 29;
          continue;
        case 29:
          await s.stall(60);
          pc = 30;
          continue;
        case 30:
          s.placeholder('CURE');
          pc = 31;
          continue;
        case 31:
          s.placeholder('CHECK_MODE');
          pc = 32;
          continue;
        case 32:
          s.setSlot(1, 2);
          pc = 33;
          continue;
        case 33:
          if (s.slotInt(10) != 12) { pc = 16; } else { pc = 34; }
          continue;
        case 34:
          s.placeholder('MUSC');
          pc = 35;
          continue;
        case 35:
          s.placeholder('TEXTSTART');
          pc = 36;
          continue;
        case 36:
          await s.textShow(2940);
          pc = 37;
          continue;
        case 37:
          s.placeholder('TEXTEND');
          pc = 38;
          continue;
        case 38:
          s.placeholder('REMA');
          pc = 39;
          continue;
        case 39:
          pc = 45;
          continue;
        case 40:
          pc = 41;
          continue;
        case 41:
          s.placeholder('TEXTSTART');
          pc = 42;
          continue;
        case 42:
          await s.textShow(2942);
          pc = 43;
          continue;
        case 43:
          s.placeholder('TEXTEND');
          pc = 44;
          continue;
        case 44:
          s.placeholder('REMA');
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
          s.placeholder('DISA');
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
    s.placeholder('ENUN');
    s.placeholder('STAL2');
    s.setSlot(2, 64);
    await s.call(Sym('EventScr_UnitWarpOUT'));
    s.placeholder('DISA');
    s.placeholder('TEXTSTART');
    await s.textShow(2951);
    s.placeholder('TEXTEND');
    s.placeholder('REMA');
    s.placeholder('SOLOTEXTBOXSTART');
    s.setSlot(11, 8388632);
    await s.textShow(2952);
    s.placeholder('TEXTEND');
    s.placeholder('REMA');
    return;
}

/// `EventScr_Ch21b_BeginningScene`
Future<void> Ch21b_BeginningScene(Scene s) async {
    await s.call(Sym('frontier_df3_eventscr_ch_005_A6B460', 300));
    return;
    await s.call(Sym('UnitDef_Ch21BEnemy_1'));
    s.placeholder('MNC4');
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
    s.placeholder('FADI');
    s.placeholder('CLEA');
    s.placeholder('CLEE');
    s.placeholder('CLEN');
    s.placeholder('CAMERA2');
    s.placeholder('EvtSetLoadUnitNoREDA');
    s.loadUnits(2, Sym('UnitDef_Ch21BMixed'));
    s.placeholder('ENUN');
    s.placeholder('FADU');
    s.loadUnits(2, Sym('UnitDef_Ch21BMixed'));
    s.placeholder('ENUN');
    s.placeholder('CURSOR_CHAR');
    await s.stall(60);
    s.placeholder('CURE');
    s.placeholder('TEXTSTART');
    await s.textShow(2950);
    s.placeholder('TEXTEND');
    s.placeholder('EvtBgmFadeIn');
    s.placeholder('TEXTCONT');
    s.placeholder('TEXTEND');
    s.placeholder('REMA');
    s.placeholder('EvtBgmFadeIn');
    await s.call(Sym('EventScr_Ch21A_9'));
    s.placeholder('MNC3');
    return;
}

/// `EventScr_Ch2Tutorial11`
Future<void> Ch2Tutorial11(Scene s) async {
    s.placeholder('EVBIT_T');
    s.setSlot(13, 0);
    s.setSlot(1, 6);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 262152);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 2358);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 5767200);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 2356);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 5767200);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, Sym('EventScr_Ch2Tutorial12'));
    s.placeholder('SENQUEUE1');
    s.setSlot(1, Sym('EventScr_Ch2Tutorial11'));
    s.placeholder('SENQUEUE1');
    await s.call(Sym('EventScr_Tutorial_Exec0'));
    s.placeholder('IGNORE_KEYS');
    return;
}

/// `EventScr_Ch2Tutorial12`
Future<void> Ch2Tutorial12(Scene s) async {
    s.placeholder('EVBIT_T');
    s.placeholder('IGNORE_KEYS');
    s.setSlot(13, 0);
    s.setSlot(1, 262152);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 0);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 0);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, Sym('EventScr_Ch2Tutorial13'));
    s.placeholder('SENQUEUE1');
    s.setSlot(1, Sym('EventScr_Ch2Tutorial12'));
    s.placeholder('SENQUEUE1');
    await s.call(Sym('EventScr_Tutorial_Exec1'));
    s.placeholder('DISABLEOPTIONS');
    s.placeholder('IGNORE_KEYS');
    return;
}

/// `EventScr_Ch2Tutorial14`
Future<void> Ch2Tutorial14(Scene s) async {
    s.placeholder('EVBIT_T');
    s.placeholder('IGNORE_KEYS');
    s.placeholder('MUSC');
    s.placeholder('TEXTSTART');
    await s.textShow(2334);
    s.placeholder('TEXTEND');
    s.placeholder('REMA');
    s.placeholder('ENUT');
    s.placeholder('DISABLEOPTIONS');
    s.placeholder('SHOW_ATTACK_RANGE');
    s.placeholder('CURSOR_FLASHING');
    await s.stall(60);
    s.placeholder('TUTORIALTEXTBOXSTART');
    s.setSlot(11, 5767184);
    await s.textShow(2359);
    s.placeholder('TEXTEND');
    s.placeholder('REMA');
    s.placeholder('CURE');
    s.placeholder('IGNORE_KEYS');
    s.placeholder('EvtEnqueueConditionalTutCall');
    return;
}

/// `EventScr_Ch2Tutorial15`
Future<void> Ch2Tutorial15(Scene s) async {
    s.placeholder('EVBIT_T');
    s.placeholder('IGNORE_KEYS');
    s.setSlot(13, 0);
    s.setSlot(1, 262153);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 0);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 0);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, Sym('EventScr_Ch2Tutorial16'));
    s.placeholder('SENQUEUE1');
    s.setSlot(1, Sym('EventScr_Ch2Tutorial15'));
    s.placeholder('SENQUEUE1');
    await s.call(Sym('EventScr_Tutorial_Exec1'));
    s.placeholder('IGNORE_KEYS');
    return;
}

/// `EventScr_Ch2Tutorial18`
Future<void> Ch2Tutorial18(Scene s) async {
    s.placeholder('EVBIT_T');
    s.placeholder('CAMERA_CAHR');
    s.setSlot(13, 0);
    s.setSlot(1, 5);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 196615);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 2361);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 5767200);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 2360);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 5767200);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, Sym('EventScr_Ch2Tutorial19'));
    s.placeholder('SENQUEUE1');
    s.setSlot(1, Sym('EventScr_Ch2Tutorial18'));
    s.placeholder('SENQUEUE1');
    await s.call(Sym('EventScr_Tutorial_Exec0'));
    s.placeholder('IGNORE_KEYS');
    return;
}

/// `EventScr_Ch2Tutorial2`
Future<void> Ch2Tutorial2(Scene s) async {
    s.placeholder('EVBIT_T');
    s.placeholder('IGNORE_KEYS');
    s.setSlot(13, 0);
    s.setSlot(1, 327689);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 0);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 0);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, Sym('EventScr_Ch2Tutorial3'));
    s.placeholder('SENQUEUE1');
    s.setSlot(1, Sym('EventScr_Ch2Tutorial2'));
    s.placeholder('SENQUEUE1');
    await s.call(Sym('EventScr_Tutorial_Exec1'));
    s.placeholder('DISABLEOPTIONS');
    s.placeholder('IGNORE_KEYS');
    return;
}

/// `EventScr_Ch2Tutorial21`
Future<void> Ch2Tutorial21(Scene s) async {
    s.placeholder('IGNORE_KEYS');
    s.placeholder('TEXTSTART');
    await s.textShow(2335);
    s.placeholder('TEXTEND');
    s.placeholder('REMA');
    s.placeholder('ENUT');
    s.placeholder('TUTORIALTEXTBOXSTART');
    s.setSlot(11, 4294967295);
    await s.textShow(2365);
    s.placeholder('TEXTEND');
    s.placeholder('REMA');
    s.placeholder('ENUT');
    s.placeholder('DISABLEOPTIONS');
    s.placeholder('EvtEnqueueCallDirectly');
    s.placeholder('EVBIT_T');
    return;
}

/// `EventScr_Ch2Tutorial22`
Future<void> Ch2Tutorial22(Scene s) async {
    s.placeholder('IGNORE_KEYS');
    s.placeholder('CURSOR_CHAR');
    await s.stall(60);
    s.placeholder('CURE');
    s.placeholder('TEXTSTART');
    await s.textShow(2332);
    s.placeholder('TEXTEND');
    s.placeholder('REMA');
    s.placeholder('TUTORIALTEXTBOXSTART');
    s.setSlot(11, 4294967295);
    await s.textShow(2368);
    s.placeholder('TEXTEND');
    s.placeholder('REMA');
    s.placeholder('CURSOR_FLASHING_CHAR');
    await s.stall(60);
    s.placeholder('CURE');
    s.placeholder('EvtEnqueueConditionalTutCall');
    s.placeholder('DISABLEOPTIONS');
    s.placeholder('EVBIT_T');
    return;
}

/// `EventScr_Ch2Tutorial23`
Future<void> Ch2Tutorial23(Scene s) async {
    s.placeholder('EVBIT_T');
    s.setSlot(13, 0);
    s.setSlot(1, 1);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 131076);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 2370);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 5767200);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 2369);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 5767200);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, Sym('EventScr_Ch2Tutorial24'));
    s.placeholder('SENQUEUE1');
    s.setSlot(1, Sym('EventScr_Ch2Tutorial23'));
    s.placeholder('SENQUEUE1');
    await s.call(Sym('EventScr_Tutorial_Exec0'));
    return;
}

/// `EventScr_Ch2Tutorial24`
Future<void> Ch2Tutorial24(Scene s) async {
    s.placeholder('EVBIT_T');
    s.placeholder('IGNORE_KEYS');
    s.setSlot(13, 0);
    s.setSlot(1, 131076);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 0);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 0);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, Sym('EventScr_Ch2Tutorial25'));
    s.placeholder('SENQUEUE1');
    s.setSlot(1, Sym('EventScr_Ch2Tutorial24'));
    s.placeholder('SENQUEUE1');
    await s.call(Sym('EventScr_Tutorial_Exec1'));
    s.placeholder('DISABLEOPTIONS');
    s.placeholder('IGNORE_KEYS');
    return;
}

/// `EventScr_Ch2Tutorial27`
Future<void> Ch2Tutorial27(Scene s) async {
    s.placeholder('EVBIT_T');
    s.placeholder('CAMERA_CAHR');
    s.setSlot(13, 0);
    s.setSlot(1, 1);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 262150);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 2374);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 5767200);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 2373);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 5767200);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, Sym('EventScr_Ch2Tutorial28'));
    s.placeholder('SENQUEUE1');
    s.setSlot(1, Sym('EventScr_Ch2Tutorial27'));
    s.placeholder('SENQUEUE1');
    await s.call(Sym('EventScr_Tutorial_Exec0'));
    return;
}

/// `EventScr_Ch2Tutorial28`
Future<void> Ch2Tutorial28(Scene s) async {
    s.placeholder('EVBIT_T');
    s.placeholder('IGNORE_KEYS');
    s.setSlot(13, 0);
    s.setSlot(1, 262150);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 0);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 0);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, Sym('EventScr_Ch2Tutorial29'));
    s.placeholder('SENQUEUE1');
    s.setSlot(1, Sym('EventScr_Ch2Tutorial28'));
    s.placeholder('SENQUEUE1');
    await s.call(Sym('EventScr_Tutorial_Exec1'));
    s.placeholder('DISABLEOPTIONS');
    s.placeholder('IGNORE_KEYS');
    return;
}

/// `EventScr_Ch2Tutorial4`
Future<void> Ch2Tutorial4(Scene s) async {
    s.placeholder('EVBIT_T');
    s.placeholder('IGNORE_KEYS');
    s.placeholder('MUSI');
    s.placeholder('TEXTSTART');
    await s.textShow(2333);
    s.placeholder('TEXTEND');
    s.placeholder('REMA');
    s.placeholder('MUNO');
    s.placeholder('DISABLEOPTIONS');
    s.placeholder('SHOW_ATTACK_RANGE');
    s.placeholder('CURSOR_FLASHING');
    await s.stall(60);
    s.placeholder('TUTORIALTEXTBOXSTART');
    s.setSlot(11, 5767184);
    await s.textShow(2355);
    s.placeholder('TEXTEND');
    s.placeholder('REMA');
    s.placeholder('CURE');
    s.placeholder('IGNORE_KEYS');
    s.placeholder('EvtEnqueueConditionalTutCall');
    return;
}

/// `EventScr_Ch2Tutorial5`
Future<void> Ch2Tutorial5(Scene s) async {
    s.placeholder('EVBIT_T');
    s.placeholder('IGNORE_KEYS');
    s.setSlot(13, 0);
    s.setSlot(1, 262152);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 0);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 0);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, Sym('EventScr_Ch2Tutorial6'));
    s.placeholder('SENQUEUE1');
    s.setSlot(1, Sym('EventScr_Ch2Tutorial5'));
    s.placeholder('SENQUEUE1');
    await s.call(Sym('EventScr_Tutorial_Exec1'));
    s.placeholder('IGNORE_KEYS');
    return;
}

/// `EventScr_Ch2Tutorial8`
Future<void> Ch2Tutorial8(Scene s) async {
    s.placeholder('EVBIT_T');
    s.setSlot(13, 0);
    s.setSlot(1, 5);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 196615);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 2364);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 5767200);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 2363);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 5767200);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, Sym('EventScr_Ch2Tutorial9'));
    s.placeholder('SENQUEUE1');
    s.setSlot(1, Sym('EventScr_Ch2Tutorial8'));
    s.placeholder('SENQUEUE1');
    await s.call(Sym('EventScr_Tutorial_Exec0'));
    return;
}

/// `EventScr_Ch2Tutorial9`
Future<void> Ch2Tutorial9(Scene s) async {
    s.placeholder('EVBIT_T');
    s.placeholder('IGNORE_KEYS');
    s.setSlot(13, 0);
    s.setSlot(1, 196615);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 0);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 0);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, Sym('EventScr_Ch2Tutorial10'));
    s.placeholder('SENQUEUE1');
    s.setSlot(1, Sym('EventScr_Ch2Tutorial9'));
    s.placeholder('SENQUEUE1');
    await s.call(Sym('EventScr_Tutorial_Exec1'));
    s.placeholder('DISABLEOPTIONS');
    s.placeholder('IGNORE_KEYS');
    return;
}

/// `EventScr_Ch2_10`
Future<void> Ch2_10(Scene s) async {
    s.placeholder('TUTORIALTEXTBOXSTART');
    s.setSlot(11, 4294967295);
    await s.textShow(2376);
    s.placeholder('TEXTEND');
    s.placeholder('REMA');
    s.placeholder('CURSOR_AT');
    await s.stall(60);
    s.placeholder('CURE');
    s.placeholder('TUTORIALTEXTBOXSTART');
    s.setSlot(11, 4294967295);
    await s.textShow(2377);
    s.placeholder('TEXTEND');
    s.placeholder('REMA');
    s.placeholder('ENUT');
    s.placeholder('EVBIT_T');
    return;
}

/// `EventScr_Ch2_8`
Future<void> Ch2_8(Scene s) async {
    s.placeholder('TUTORIALTEXTBOXSTART');
    s.setSlot(11, 4294967295);
    await s.textShow(2366);
    s.placeholder('TEXTEND');
    s.placeholder('REMA');
    s.placeholder('TUTORIALTEXTBOXSTART');
    s.setSlot(11, 4294967295);
    await s.textShow(2378);
    s.placeholder('TEXTEND');
    s.placeholder('REMA');
    s.placeholder('ENUT');
    s.placeholder('ENUT');
    s.placeholder('EVBIT_T');
    return;
}

/// `EventScr_Ch2_BeginningScene`
Future<void> Ch2_BeginningScene(Scene s) async {
    s.placeholder('MUSC');
    s.setSlot(2, 30);
    await s.call(Sym('EventScr_SetBackground'));
    await s.textShow(2324);
    s.placeholder('TEXTEND');
    s.placeholder('REMA');
    s.placeholder('FADI');
    s.placeholder('CLEAN');
    s.placeholder('FADU');
    s.loadUnits(1, Sym('UnitDef_Ch2Ally'));
    s.placeholder('ENUN');
    s.placeholder('EvtBgmFadeIn');
    s.loadUnits(1, Sym('UnitDef_Ch2Enemy_0'));
    s.placeholder('ENUN');
    s.loadUnits(1, Sym('UnitDef_Ch2Enemy_2'));
    s.placeholder('ENUN');
    s.placeholder('STAL2');
    s.placeholder('MUSC');
    s.placeholder('CURSOR_CHAR');
    await s.stall(60);
    s.placeholder('CURE');
    s.placeholder('TEXTSTART');
    await s.textShow(2325);
    s.placeholder('TEXTEND');
    s.placeholder('REMA');
    s.moveUnit('MOVE', [24, 72, 14, 9]);
    s.placeholder('ENUN');
    s.placeholder('DISA');
    s.placeholder('CURSOR_AT');
    await s.stall(60);
    s.placeholder('CURE');
    s.placeholder('MUSC');
    s.setSlot(2, 2);
    s.setSlot(3, 2326);
    await s.call(Sym('Event_TextWithBG'));
    s.placeholder('CURSOR_CHAR');
    await s.stall(60);
    s.placeholder('CURE');
    s.placeholder('TEXTSTART');
    await s.textShow(2327);
    s.placeholder('TEXTEND');
    s.placeholder('REMA');
    s.moveUnit('MOVE', [24, 71, 9, 14]);
    s.placeholder('ENUN');
    s.setSlot(11, 327692);
    s.moveUnit('MOVE', [0, 65534, 12, 3]);
    s.placeholder('ENUN');
    s.placeholder('SOUN');
    s.setSlot(11, 131084);
    s.placeholder('TILECHANGE');
    s.placeholder('SOUN');
    s.placeholder('NOTIFY');
    s.loadUnits(1, Sym('UnitDef_Ch2NPC'));
    s.placeholder('ENUN');
    s.setSlot(1, 5);
    s.placeholder('SET_HP');
    s.placeholder('CURSOR_CHAR');
    await s.stall(60);
    s.placeholder('CURE');
    s.setSlot(2, 37);
    s.setSlot(3, 2328);
    await s.call(Sym('Event_TextWithBG'));
    s.setSlot(2, Sym('EventScr_Ch2_Village2', 192));
    await s.call(Sym('EventScr_CallOnTutorialMode'));
    s.loadUnits(1, Sym('UnitDef_Event_Ch2Ally'));
    s.placeholder('ENUN');
    s.placeholder('CURSOR_CHAR');
    await s.stall(60);
    s.placeholder('CURE');
    s.placeholder('TEXTSTART');
    await s.textShow(2329);
    s.placeholder('TEXTEND');
    s.placeholder('REMA');
    s.moveUnit('MOVE', [24, 6, 2, 3]);
    s.placeholder('ENUN');
    s.placeholder('CURSOR_CHAR');
    await s.stall(60);
    s.placeholder('CURE');
    s.placeholder('TEXTSTART');
    await s.textShow(2330);
    s.placeholder('TEXTEND');
    s.placeholder('REMA');
    s.setSlot(2, Sym('EventScr_Ch2_Village2', 224));
    await s.call(Sym('EventScr_CallOnTutorialMode'));
    s.placeholder('CURSOR_CHAR');
    await s.stall(60);
    s.placeholder('CURE');
    s.placeholder('TEXTSTART');
    await s.textShow(2331);
    s.placeholder('TEXTEND');
    s.placeholder('REMA');
    s.moveUnit('MOVE', [24, 6, 6, 3]);
    s.placeholder('ENUN');
    s.placeholder('EVBIT_T');
    return;
}

/// `EventScr_Ch2_EndingScene`
Future<void> Ch2_EndingScene(Scene s) async {
    var pc = 0;
    while (true) {
      switch (pc) {
        case 0:
          s.placeholder('MUSC');
          pc = 1;
          continue;
        case 1:
          s.placeholder('CHECK_ALIVE');
          pc = 2;
          continue;
        case 2:
          if (s.slotInt(0) == 12) { pc = 15; } else { pc = 3; }
          continue;
        case 3:
          s.placeholder('CHECK_ALIVE');
          pc = 4;
          continue;
        case 4:
          if (s.slotInt(0) == 12) { pc = 15; } else { pc = 5; }
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
          s.placeholder('TEXTEND');
          pc = 9;
          continue;
        case 9:
          s.placeholder('REMA');
          pc = 10;
          continue;
        case 10:
          s.placeholder('FADI');
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
          s.placeholder('TEXTEND');
          pc = 20;
          continue;
        case 20:
          s.placeholder('FADI');
          pc = 21;
          continue;
        case 21:
          s.placeholder('EvtBgmFadeIn');
          pc = 22;
          continue;
        case 22:
          s.placeholder('REMA');
          pc = 23;
          continue;
        case 23:
          s.placeholder('REMOVEPORTRAITS');
          pc = 24;
          continue;
        case 24:
          s.placeholder('BACG');
          pc = 25;
          continue;
        case 25:
          s.placeholder('FADU');
          pc = 26;
          continue;
        case 26:
          await s.textShow(2340);
          pc = 27;
          continue;
        case 27:
          s.placeholder('TEXTEND');
          pc = 28;
          continue;
        case 28:
          s.placeholder('FAWI');
          pc = 29;
          continue;
        case 29:
          s.placeholder('REMA');
          pc = 30;
          continue;
        case 30:
          s.placeholder('BACG');
          pc = 31;
          continue;
        case 31:
          s.placeholder('FAWU');
          pc = 32;
          continue;
        case 32:
          s.placeholder('MUSC');
          pc = 33;
          continue;
        case 33:
          s.placeholder('BROWNBOXTEXT');
          pc = 34;
          continue;
        case 34:
          await s.textShow(2341);
          pc = 35;
          continue;
        case 35:
          s.placeholder('TEXTEND');
          pc = 36;
          continue;
        case 36:
          s.placeholder('FAWI');
          pc = 37;
          continue;
        case 37:
          s.placeholder('EvtBgmFadeIn');
          pc = 38;
          continue;
        case 38:
          s.placeholder('REMA');
          pc = 39;
          continue;
        case 39:
          s.placeholder('BACG');
          pc = 40;
          continue;
        case 40:
          s.placeholder('FAWU');
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
          s.placeholder('TEXTEND');
          pc = 44;
          continue;
        case 44:
          s.placeholder('REMA');
          pc = 45;
          continue;
        case 45:
          s.placeholder('FADI');
          pc = 46;
          continue;
        case 46:
          s.placeholder('ENUT');
          pc = 47;
          continue;
        case 47:
          s.placeholder('ENUT');
          pc = 48;
          continue;
        case 48:
          s.placeholder('ENUT');
          pc = 49;
          continue;
        case 49:
          s.placeholder('ENUT');
          pc = 50;
          continue;
        case 50:
          s.placeholder('ENUT');
          pc = 51;
          continue;
        case 51:
          s.placeholder('ENUT');
          pc = 52;
          continue;
        case 52:
          s.placeholder('ENUT');
          pc = 53;
          continue;
        case 53:
          s.placeholder('ENUT');
          pc = 54;
          continue;
        case 54:
          s.placeholder('ENUT');
          pc = 55;
          continue;
        case 55:
          s.placeholder('ENUT');
          pc = 56;
          continue;
        case 56:
          s.placeholder('ENUT');
          pc = 57;
          continue;
        case 57:
          s.placeholder('ENUT');
          pc = 58;
          continue;
        case 58:
          s.placeholder('MNCH');
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

/// `EventScr_Ch2_Village1`
Future<void> Ch2_Village1(Scene s) async {
    var pc = 0;
    while (true) {
      switch (pc) {
        case 0:
          s.placeholder('IGNORE_KEYS');
          pc = 1;
          continue;
        case 1:
          s.placeholder('CHECK_ACTIVE');
          pc = 2;
          continue;
        case 2:
          s.setSlot(1, 1);
          pc = 3;
          continue;
        case 3:
          if (s.slotInt(0) != 12) { pc = 16; } else { pc = 4; }
          continue;
        case 4:
          s.placeholder('MUSI');
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
          s.placeholder('MUNO');
          pc = 9;
          continue;
        case 9:
          pc = 16;
          continue;
        case 10:
          pc = 11;
          continue;
        case 11:
          s.placeholder('MUSI');
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
          s.placeholder('MUNO');
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
          s.placeholder('GIVEITEMTO');
          pc = 20;
          continue;
        case 20:
          s.placeholder('EVBIT_T');
          pc = 21;
          continue;
        case 21:
          return;
        default:
          return;
      }
    }
}

/// `EventScr_Ch3_0`
Future<void> Ch3_0(Scene s) async {
    s.placeholder('CAMERA2');
    await s.stall(15);
    s.setSlot(13, 0);
    s.setSlot(1, 196610);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 655366);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 327690);
    s.placeholder('SENQUEUE1');
    await s.call(Sym('EventScr_FormatFlashingCursor'));
    await s.stall(60);
    s.placeholder('CURE');
    s.placeholder('TEXTSTART');
    await s.textShow(2381);
    s.placeholder('TEXTEND');
    s.placeholder('REMA');
    s.placeholder('CAMERA2');
    await s.stall(15);
    s.setSlot(13, 0);
    s.setSlot(1, 589828);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 786436);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 524296);
    s.placeholder('SENQUEUE1');
    await s.call(Sym('EventScr_FormatFlashingCursor'));
    await s.stall(60);
    s.placeholder('CURE');
    s.placeholder('TUTORIALTEXTBOXSTART');
    s.setSlot(11, 4294967295);
    await s.textShow(2395);
    s.placeholder('TEXTEND');
    s.placeholder('REMA');
    s.placeholder('ENUT');
    return;
}

/// `EventScr_Ch3_5`
Future<void> Ch3_5(Scene s) async {
    s.placeholder('CURSOR_CHAR');
    await s.stall(60);
    s.placeholder('CURE');
    s.placeholder('TEXTSTART');
    await s.textShow(2383);
    s.placeholder('TEXTEND');
    s.placeholder('REMA');
    s.moveUnit('MOVE', [0, 8, 3, 9]);
    s.placeholder('ENUN');
    s.setSlot(13, 0);
    s.setSlot(1, 0);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 4294967295);
    s.placeholder('SENQUEUE1');
    s.setSlot(11, 589829);
    s.placeholder('FIGHT');
    s.placeholder('TUTORIALTEXTBOXSTART');
    s.setSlot(11, 4294967295);
    await s.textShow(2399);
    s.placeholder('TEXTEND');
    s.placeholder('REMA');
    return;
}

/// `EventScr_Ch3_BeginningScene`
Future<void> Ch3_BeginningScene(Scene s) async {
    var pc = 0;
    while (true) {
      switch (pc) {
        case 0:
          s.placeholder('MUSC');
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
          s.placeholder('TEXTEND');
          pc = 5;
          continue;
        case 5:
          s.placeholder('REMA');
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
          s.placeholder('TEXTEND');
          pc = 10;
          continue;
        case 10:
          s.placeholder('REMA');
          pc = 11;
          continue;
        case 11:
          s.placeholder('FADI');
          pc = 12;
          continue;
        case 12:
          s.placeholder('CLEAN');
          pc = 13;
          continue;
        case 13:
          s.loadUnits(1, Sym('UnitDef_Ch3Enemy_0'));
          pc = 14;
          continue;
        case 14:
          s.placeholder('ENUN');
          pc = 15;
          continue;
        case 15:
          s.placeholder('FADU');
          pc = 16;
          continue;
        case 16:
          s.loadUnits(2, Sym('UnitDef_Event_Ch3Ally'));
          pc = 17;
          continue;
        case 17:
          s.placeholder('ENUN');
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
          s.placeholder('CHECK_TUTORIAL');
          pc = 21;
          continue;
        case 21:
          if (s.slotInt(0) != 12) { pc = 29; } else { pc = 22; }
          continue;
        case 22:
          s.placeholder('CURSOR_CHAR');
          pc = 23;
          continue;
        case 23:
          await s.stall(60);
          pc = 24;
          continue;
        case 24:
          s.placeholder('CURE');
          pc = 25;
          continue;
        case 25:
          s.placeholder('TEXTSTART');
          pc = 26;
          continue;
        case 26:
          await s.textShow(2382);
          pc = 27;
          continue;
        case 27:
          s.placeholder('TEXTEND');
          pc = 28;
          continue;
        case 28:
          s.placeholder('REMA');
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
          s.placeholder('FADI');
          pc = 35;
          continue;
        case 35:
          s.loadUnits(1, Sym('UnitDef_Event_Ch3Ally'));
          pc = 36;
          continue;
        case 36:
          s.placeholder('ENUN');
          pc = 37;
          continue;
        case 37:
          s.placeholder('CHECK_TUTORIAL');
          pc = 38;
          continue;
        case 38:
          if (s.slotInt(1) != 12) { pc = 29; } else { pc = 39; }
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
          s.placeholder('CAMERA_CAHR');
          pc = 44;
          continue;
        case 44:
          s.placeholder('FADU');
          pc = 45;
          continue;
        case 45:
          s.placeholder('CHECK_TUTORIAL');
          pc = 46;
          continue;
        case 46:
          if (s.slotInt(10) != 12) { pc = 29; } else { pc = 47; }
          continue;
        case 47:
          s.placeholder('MUSC');
          pc = 48;
          continue;
        case 48:
          s.placeholder('CURSOR_CHAR');
          pc = 49;
          continue;
        case 49:
          await s.stall(60);
          pc = 50;
          continue;
        case 50:
          s.placeholder('CURE');
          pc = 51;
          continue;
        case 51:
          s.placeholder('TEXTSTART');
          pc = 52;
          continue;
        case 52:
          await s.textShow(2384);
          pc = 53;
          continue;
        case 53:
          s.placeholder('TEXTEND');
          pc = 54;
          continue;
        case 54:
          s.placeholder('REMA');
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
          s.placeholder('EVBIT_T');
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
          s.placeholder('MUSC');
          pc = 1;
          continue;
        case 1:
          s.placeholder('CHECK_ALIVE');
          pc = 2;
          continue;
        case 2:
          if (s.slotInt(0) == 12) { pc = 14; } else { pc = 3; }
          continue;
        case 3:
          s.placeholder('CHECK_ALIVE');
          pc = 4;
          continue;
        case 4:
          if (s.slotInt(0) == 12) { pc = 14; } else { pc = 5; }
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
          s.placeholder('TEXTEND');
          pc = 9;
          continue;
        case 9:
          s.placeholder('REMA');
          pc = 10;
          continue;
        case 10:
          s.placeholder('FADI');
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
          s.placeholder('TEXTEND');
          pc = 22;
          continue;
        case 22:
          s.placeholder('REMA');
          pc = 23;
          continue;
        case 23:
          s.placeholder('EvtBgmFadeIn');
          pc = 24;
          continue;
        case 24:
          s.placeholder('FADI');
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
          s.placeholder('TEXTEND');
          pc = 31;
          continue;
        case 31:
          s.placeholder('REMA');
          pc = 32;
          continue;
        case 32:
          s.placeholder('FADI');
          pc = 33;
          continue;
        case 33:
          s.placeholder('CLEAN');
          pc = 34;
          continue;
        case 34:
          s.loadUnits(1, Sym('UnitDef_Ch3Enemy_1'));
          pc = 35;
          continue;
        case 35:
          s.placeholder('ENUN');
          pc = 36;
          continue;
        case 36:
          s.placeholder('FADU');
          pc = 37;
          continue;
        case 37:
          s.placeholder('MUSC');
          pc = 38;
          continue;
        case 38:
          s.placeholder('CURSOR_CHAR');
          pc = 39;
          continue;
        case 39:
          await s.stall(60);
          pc = 40;
          continue;
        case 40:
          s.placeholder('CURE');
          pc = 41;
          continue;
        case 41:
          s.placeholder('TEXTSTART');
          pc = 42;
          continue;
        case 42:
          await s.textShow(2392);
          pc = 43;
          continue;
        case 43:
          s.placeholder('TEXTEND');
          pc = 44;
          continue;
        case 44:
          s.placeholder('REMA');
          pc = 45;
          continue;
        case 45:
          s.placeholder('SOUN');
          pc = 46;
          continue;
        case 46:
          s.placeholder('TILECHANGE');
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
          s.placeholder('SENQUEUE1');
          pc = 50;
          continue;
        case 50:
          s.setSlot(1, 0);
          pc = 51;
          continue;
        case 51:
          s.placeholder('SENQUEUE1');
          pc = 52;
          continue;
        case 52:
          s.setSlot(1, 65804);
          pc = 53;
          continue;
        case 53:
          s.placeholder('SENQUEUE1');
          pc = 54;
          continue;
        case 54:
          s.setSlot(1, 0);
          pc = 55;
          continue;
        case 55:
          s.placeholder('SENQUEUE1');
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
          s.placeholder('ENUN');
          pc = 60;
          continue;
        case 60:
          s.loadUnits(1, Sym('UnitDef_Ch3Enemy_2'));
          pc = 61;
          continue;
        case 61:
          s.placeholder('ENUN');
          pc = 62;
          continue;
        case 62:
          s.placeholder('CURSOR_CHAR');
          pc = 63;
          continue;
        case 63:
          await s.stall(60);
          pc = 64;
          continue;
        case 64:
          s.placeholder('CURE');
          pc = 65;
          continue;
        case 65:
          s.placeholder('TEXTSTART');
          pc = 66;
          continue;
        case 66:
          await s.textShow(2393);
          pc = 67;
          continue;
        case 67:
          s.placeholder('TEXTEND');
          pc = 68;
          continue;
        case 68:
          s.placeholder('REMA');
          pc = 69;
          continue;
        case 69:
          s.placeholder('FADI');
          pc = 70;
          continue;
        case 70:
          s.placeholder('ENUT');
          pc = 71;
          continue;
        case 71:
          s.placeholder('ENUT');
          pc = 72;
          continue;
        case 72:
          s.placeholder('ENUT');
          pc = 73;
          continue;
        case 73:
          s.placeholder('ENUT');
          pc = 74;
          continue;
        case 74:
          s.placeholder('ENUT');
          pc = 75;
          continue;
        case 75:
          s.placeholder('ENUT');
          pc = 76;
          continue;
        case 76:
          s.placeholder('REVEAL');
          pc = 77;
          continue;
        case 77:
          s.placeholder('MNCH');
          pc = 78;
          continue;
        case 78:
          return;
        default:
          return;
      }
    }
}

/// `EventScr_Ch3_Turn1Npc`
Future<void> Ch3_Turn1Npc(Scene s) async {
    s.placeholder('CAMERA');
    await s.stall(15);
    s.loadUnits(1, Sym('UnitDef_Ch3NPC'));
    s.placeholder('ENUN');
    s.placeholder('MUSC');
    s.placeholder('CURSOR_CHAR');
    await s.stall(60);
    s.placeholder('CURE');
    s.placeholder('TEXTSTART');
    await s.textShow(2386);
    s.placeholder('TEXTEND');
    s.placeholder('REMA');
    s.setSlot(2, Sym('EventScr_Ch3_2'));
    await s.call(Sym('EventScr_CallOnTutorialMode'));
    s.moveUnit('MOVE_CLOSEST', [0, 9, 2, 4]);
    s.placeholder('ENUN');
    s.setSlot(2, Sym('EventScr_Ch3_3'));
    await s.call(Sym('EventScr_CallOnTutorialMode'));
    s.placeholder('EVBIT_T');
    return;
}

/// `EventScr_Ch4_0`
Future<void> Ch4_0(Scene s) async {
    s.placeholder('CAMERA2');
    await s.stall(15);
    s.loadUnits(1, Sym('UnitDef_Ch4NPC_0'));
    s.placeholder('ENUN');
    s.placeholder('MUSC');
    s.placeholder('CURSOR_CHAR');
    await s.stall(60);
    s.placeholder('CURE');
    s.placeholder('TEXTSTART');
    await s.textShow(2412);
    s.placeholder('TEXTEND');
    s.placeholder('REMA');
    s.moveUnit('MOVE', [24, 25, 15, 2]);
    s.moveUnit('MOVE', [24, 26, 15, 1]);
    s.moveUnit('MOVE', [24, 28, 15, 1]);
    s.placeholder('ENUN');
    s.placeholder('CLEN');
    s.placeholder('EVBIT_T');
    return;
}

/// `EventScr_Ch4_1`
Future<void> Ch4_1(Scene s) async {
    var pc = 0;
    while (true) {
      switch (pc) {
        case 0:
          s.placeholder('MUSC');
          pc = 1;
          continue;
        case 1:
          s.placeholder('CHECK_EXISTS');
          pc = 2;
          continue;
        case 2:
          if (s.slotInt(10) != 12) { pc = 9; } else { pc = 3; }
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
          s.placeholder('CHECK_ALIVE');
          pc = 6;
          continue;
        case 6:
          if (s.slotInt(0) == 12) { pc = 9; } else { pc = 7; }
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
          s.placeholder('TEXTEND');
          pc = 14;
          continue;
        case 14:
          s.placeholder('REMA');
          pc = 15;
          continue;
        case 15:
          s.placeholder('FADI');
          pc = 16;
          continue;
        case 16:
          s.loadUnits(1, Sym('UnitDef_Ch4Ally_2'));
          pc = 17;
          continue;
        case 17:
          s.placeholder('ENUN');
          pc = 18;
          continue;
        case 18:
          pc = 19;
          continue;
        case 19:
          s.placeholder('MUSC');
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
          s.placeholder('CHECK_ALIVE');
          pc = 23;
          continue;
        case 23:
          if (s.slotInt(11) == 12) { pc = 9; } else { pc = 24; }
          continue;
        case 24:
          s.placeholder('CHECK_ALIVE');
          pc = 25;
          continue;
        case 25:
          if (s.slotInt(11) == 12) { pc = 9; } else { pc = 26; }
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
          s.placeholder('TEXTEND');
          pc = 33;
          continue;
        case 33:
          s.placeholder('REMA');
          pc = 34;
          continue;
        case 34:
          s.placeholder('FADI');
          pc = 35;
          continue;
        case 35:
          s.placeholder('EvtBgmFadeIn');
          pc = 36;
          continue;
        case 36:
          s.placeholder('CLEAN');
          pc = 37;
          continue;
        case 37:
          s.placeholder('CAMERA2');
          pc = 38;
          continue;
        case 38:
          s.placeholder('CLEA');
          pc = 39;
          continue;
        case 39:
          s.placeholder('CLEE');
          pc = 40;
          continue;
        case 40:
          s.placeholder('CLEN');
          pc = 41;
          continue;
        case 41:
          s.loadUnits(2, Sym('UnitDef_Ch4Ally_3'));
          pc = 42;
          continue;
        case 42:
          s.placeholder('ENUN');
          pc = 43;
          continue;
        case 43:
          s.placeholder('FADU');
          pc = 44;
          continue;
        case 44:
          s.loadUnits(1, Sym('UnitDef_Ch4NPC_1'));
          pc = 45;
          continue;
        case 45:
          s.placeholder('ENUN');
          pc = 46;
          continue;
        case 46:
          s.placeholder('MUSC');
          pc = 47;
          continue;
        case 47:
          s.placeholder('CURSOR_CHAR');
          pc = 48;
          continue;
        case 48:
          await s.stall(60);
          pc = 49;
          continue;
        case 49:
          s.placeholder('CURE');
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
          s.placeholder('TEXTEND');
          pc = 54;
          continue;
        case 54:
          s.placeholder('REMA');
          pc = 55;
          continue;
        case 55:
          s.placeholder('ENUT');
          pc = 56;
          continue;
        case 56:
          s.placeholder('ENUT');
          pc = 57;
          continue;
        case 57:
          s.placeholder('ENUT');
          pc = 58;
          continue;
        case 58:
          s.placeholder('ENUT');
          pc = 59;
          continue;
        case 59:
          s.placeholder('ENUT');
          pc = 60;
          continue;
        case 60:
          s.placeholder('ENUT');
          pc = 61;
          continue;
        case 61:
          s.placeholder('MNCH');
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
    s.placeholder('ENUN');
    s.placeholder('CURSOR_CHAR');
    await s.stall(60);
    s.placeholder('CURE');
    s.placeholder('TEXTSTART');
    await s.textShow(2410);
    s.placeholder('TEXTEND');
    s.placeholder('REMA');
    s.placeholder('CURSOR_CHAR');
    await s.stall(60);
    s.placeholder('CURE');
    s.placeholder('TEXTSTART');
    await s.textShow(2411);
    s.placeholder('TEXTEND');
    s.placeholder('REMA');
    s.placeholder('TUTORIALTEXTBOXSTART');
    s.setSlot(11, 4294967295);
    await s.textShow(2425);
    s.placeholder('TEXTEND');
    s.placeholder('REMA');
    s.placeholder('ENUT');
    return;
}

/// `EventScr_Ch4_2`
Future<void> Ch4_2(Scene s) async {
    var pc = 0;
    while (true) {
      switch (pc) {
        case 0:
          s.placeholder('MUSS');
          pc = 1;
          continue;
        case 1:
          await s.stall(33);
          pc = 2;
          continue;
        case 2:
          s.placeholder('CHECK_ACTIVE');
          pc = 3;
          continue;
        case 3:
          s.setSlot(7, 19);
          pc = 4;
          continue;
        case 4:
          if (s.slotInt(0) == 12) { pc = 5; } else { pc = 5; }
          continue;
        case 5:
          s.setSlot(7, 1);
          pc = 6;
          continue;
        case 6:
          if (s.slotInt(1) == 12) { pc = 7; } else { pc = 7; }
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
          s.placeholder('MURE');
          pc = 22;
          continue;
        case 22:
          s.loadUnits(1, Sym('UnitDef_Ch4Ally_2'));
          pc = 23;
          continue;
        case 23:
          s.placeholder('ENUN');
          pc = 24;
          continue;
        case 24:
          s.placeholder('EVBIT_T');
          pc = 25;
          continue;
        case 25:
          return;
        default:
          return;
      }
    }
}

/// `EventScr_Ch4_BeginningScene`
Future<void> Ch4_BeginningScene(Scene s) async {
    s.loadUnits(2, Sym('UnitDef_Ch4Ally_0'));
    s.placeholder('ENUN');
    s.placeholder('MUSC');
    s.placeholder('CURSOR_CHAR');
    await s.stall(60);
    s.placeholder('CURE');
    s.setSlot(2, 46);
    await s.call(Sym('EventScr_SetBackground'));
    await s.textShow(2403);
    s.placeholder('TEXTEND');
    s.placeholder('REMA');
    s.placeholder('FADI');
    s.placeholder('CLEAN');
    s.loadUnits(1, Sym('UnitDef_Ch4Enemy_0'));
    s.placeholder('ENUN');
    s.placeholder('FADU');
    s.placeholder('MUSC');
    s.placeholder('CURSOR_CHAR');
    await s.stall(60);
    s.placeholder('CURE');
    s.placeholder('TEXTSTART');
    await s.textShow(2404);
    s.placeholder('TEXTEND');
    s.placeholder('REMA');
    s.placeholder('FADI');
    s.placeholder('CAMERA');
    s.placeholder('FADU');
    s.placeholder('MUSI');
    s.placeholder('CURSOR_AT');
    await s.stall(60);
    s.placeholder('CURE');
    s.setSlot(2, 2);
    await s.call(Sym('EventScr_SetBackground'));
    await s.textShow(2405);
    s.placeholder('TEXTEND');
    s.placeholder('REMA');
    s.placeholder('MUNO');
    s.setSlot(2, Sym('EventScr_Ch4_7'));
    await s.call(Sym('EventScr_CallOnTutorialMode'));
    s.placeholder('FADI');
    s.placeholder('CLEAN');
    s.placeholder('CAMERA');
    s.placeholder('FADU');
    s.loadUnits(1, Sym('UnitDef_Ch4Ally_1'));
    s.placeholder('ENUN');
    s.placeholder('CURSOR_CHAR');
    await s.stall(60);
    s.placeholder('CURE');
    s.placeholder('TEXTSTART');
    await s.textShow(2406);
    s.placeholder('TEXTEND');
    s.placeholder('REMA');
    s.setSlot(11, 393227);
    s.moveUnit('MOVE', [0, 65534, 9, 3]);
    s.placeholder('ENUN');
    s.placeholder('CURSOR_CHAR');
    await s.stall(60);
    s.placeholder('CURE');
    s.placeholder('TEXTSTART');
    await s.textShow(2407);
    s.placeholder('TEXTEND');
    s.placeholder('REMA');
    s.setSlot(13, 0);
    s.setSlot(1, 0);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 65536);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 4294967295);
    s.placeholder('SENQUEUE1');
    s.setSlot(11, 196617);
    s.placeholder('FIGHT');
    s.setSlot(11, 196617);
    s.placeholder('KILL');
    s.placeholder('DISA_IF');
    s.setSlot(2, Sym('EventScr_Ch4_8'));
    await s.call(Sym('EventScr_CallOnTutorialMode'));
    s.placeholder('CURSOR_CHAR');
    await s.stall(60);
    s.placeholder('CURE');
    s.placeholder('TEXTSTART');
    await s.textShow(2408);
    s.placeholder('TEXTEND');
    s.placeholder('REMA');
    s.setSlot(2, Sym('EventScr_Ch4_9'));
    await s.call(Sym('EventScr_CallOnTutorialMode'));
    await s.call(Sym('data_085B9BBC', 512));
    s.placeholder('CAMERA');
    s.placeholder('FADU');
    s.placeholder('MUSC');
    s.placeholder('CURSOR_CHAR');
    await s.stall(60);
    s.placeholder('CURE');
    s.placeholder('TEXTSTART');
    await s.textShow(2409);
    s.placeholder('TEXTEND');
    s.placeholder('REMA');
    s.setSlot(2, Sym('EventScr_Ch4_10'));
    await s.call(Sym('EventScr_CallOnTutorialMode'));
    s.placeholder('ENUT');
    s.placeholder('EVBIT_T');
    return;
}

/// `EventScr_Ch5_0`
Future<void> Ch5_0(Scene s) async {
    s.placeholder('MUSI');
    s.setSlot(2, 0);
    s.setSlot(3, 2445);
    await s.call(Sym('Event_TextWithBG'));
    s.placeholder('MUNO');
    await s.call(Sym('data_085B9BBC', 360));
    s.setSlot(3, 14);
    s.placeholder('GIVEITEMTO');
    s.setSlot(2, Sym('EventScr_Ch5_9'));
    await s.call(Sym('EventScr_CallOnTutorialMode'));
    s.placeholder('EVBIT_T');
    return;
}

/// `EventScr_Ch5_10`
Future<void> Ch5_10(Scene s) async {
    s.placeholder('TUTORIALTEXTBOXSTART');
    s.setSlot(11, 4294967295);
    await s.textShow(2451);
    s.placeholder('TEXTEND');
    s.placeholder('REMA');
    s.placeholder('CAMERA');
    s.placeholder('CURSOR_FLASHING');
    await s.stall(60);
    s.placeholder('CAMERA');
    s.placeholder('CURSOR_FLASHING');
    await s.stall(60);
    s.placeholder('TUTORIALTEXTBOXSTART');
    s.setSlot(11, 4294967295);
    await s.textShow(2452);
    s.placeholder('TEXTEND');
    s.placeholder('REMA');
    s.placeholder('ENUT');
    s.placeholder('CURE');
    return;
}

/// `EventScr_Ch5_11`
Future<void> Ch5_11(Scene s) async {
    s.placeholder('TUTORIALTEXTBOXSTART');
    s.setSlot(11, 4294967295);
    await s.textShow(2453);
    s.placeholder('TEXTEND');
    s.placeholder('REMA');
    s.placeholder('CAMERA');
    s.placeholder('CURSOR_FLASHING');
    await s.stall(60);
    s.placeholder('TUTORIALTEXTBOXSTART');
    s.setSlot(11, 4294967295);
    await s.textShow(2454);
    s.placeholder('TEXTEND');
    s.placeholder('REMA');
    s.placeholder('ENUT');
    s.placeholder('CURE');
    return;
}

/// `EventScr_Ch5_5`
Future<void> Ch5_5(Scene s) async {
    s.setSlot(2, Sym('EventScr_Ch5_10'));
    await s.call(Sym('EventScr_CallOnTutorialMode'));
    s.placeholder('MUSC');
    s.setSlot(2, Sym('frontier_df4_banim_b_074_909DE8'));
    await s.call(Sym('EventScr_LoadReinforce'));
    s.placeholder('CURSOR_AT');
    await s.stall(60);
    s.placeholder('CURE');
    s.placeholder('TEXTSTART');
    await s.textShow(2437);
    s.placeholder('TEXTEND');
    s.placeholder('REMA');
    s.placeholder('EVBIT_T');
    return;
}

/// `EventScr_Ch5_BeginningScene`
Future<void> Ch5_BeginningScene(Scene s) async {
    var pc = 0;
    while (true) {
      switch (pc) {
        case 0:
          s.placeholder('CHECK_EVENTID');
          pc = 1;
          continue;
        case 1:
          if (s.slotInt(32800) == 12) { pc = 2; } else { pc = 2; }
          continue;
        case 2:
          await s.call(Sym('EventScr_Ch8_10'));
          pc = 3;
          continue;
        case 3:
          pc = 4;
          continue;
        case 4:
          s.placeholder('MUSC');
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
          s.placeholder('ENUN');
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
          s.placeholder('DISA');
          pc = 12;
          continue;
        case 12:
          s.loadUnits(2, Sym('frontier_df4_banim_b_074_909DE8', 220));
          pc = 13;
          continue;
        case 13:
          s.placeholder('ENUN');
          pc = 14;
          continue;
        case 14:
          s.placeholder('CURSOR_CHAR');
          pc = 15;
          continue;
        case 15:
          await s.stall(60);
          pc = 16;
          continue;
        case 16:
          s.placeholder('CURE');
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
          s.placeholder('TEXTEND');
          pc = 21;
          continue;
        case 21:
          s.placeholder('REMA');
          pc = 22;
          continue;
        case 22:
          s.placeholder('FADI');
          pc = 23;
          continue;
        case 23:
          s.placeholder('CLEA');
          pc = 24;
          continue;
        case 24:
          s.placeholder('CLEE');
          pc = 25;
          continue;
        case 25:
          s.placeholder('CLEN');
          pc = 26;
          continue;
        case 26:
          s.placeholder('CLEAN');
          pc = 27;
          continue;
        case 27:
          s.placeholder('MUSC');
          pc = 28;
          continue;
        case 28:
          s.loadUnits(1, Sym('frontier_df4_banim_b_074_909DE8', 280));
          pc = 29;
          continue;
        case 29:
          s.placeholder('ENUN');
          pc = 30;
          continue;
        case 30:
          s.placeholder('FADU');
          pc = 31;
          continue;
        case 31:
          s.placeholder('CURSOR_CHAR');
          pc = 32;
          continue;
        case 32:
          await s.stall(60);
          pc = 33;
          continue;
        case 33:
          s.placeholder('CURE');
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
          s.placeholder('ENUN');
          pc = 39;
          continue;
        case 39:
          s.moveUnit('MOVE_1STEP', [16, 14, 3]);
          pc = 40;
          continue;
        case 40:
          s.placeholder('ENUN');
          pc = 41;
          continue;
        case 41:
          s.placeholder('CURSOR_CHAR');
          pc = 42;
          continue;
        case 42:
          await s.stall(60);
          pc = 43;
          continue;
        case 43:
          s.placeholder('CURE');
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
          s.placeholder('SENQUEUE1');
          pc = 50;
          continue;
        case 50:
          s.setSlot(1, 0);
          pc = 51;
          continue;
        case 51:
          s.placeholder('SENQUEUE1');
          pc = 52;
          continue;
        case 52:
          s.setSlot(1, 459);
          pc = 53;
          continue;
        case 53:
          s.placeholder('SENQUEUE1');
          pc = 54;
          continue;
        case 54:
          s.setSlot(1, 0);
          pc = 55;
          continue;
        case 55:
          s.placeholder('SENQUEUE1');
          pc = 56;
          continue;
        case 56:
          s.setSlot(1, 267);
          pc = 57;
          continue;
        case 57:
          s.placeholder('SENQUEUE1');
          pc = 58;
          continue;
        case 58:
          s.setSlot(1, 0);
          pc = 59;
          continue;
        case 59:
          s.placeholder('SENQUEUE1');
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
          s.placeholder('SENQUEUE1');
          pc = 64;
          continue;
        case 64:
          s.setSlot(1, 0);
          pc = 65;
          continue;
        case 65:
          s.placeholder('SENQUEUE1');
          pc = 66;
          continue;
        case 66:
          s.setSlot(1, 459);
          pc = 67;
          continue;
        case 67:
          s.placeholder('SENQUEUE1');
          pc = 68;
          continue;
        case 68:
          s.setSlot(1, 0);
          pc = 69;
          continue;
        case 69:
          s.placeholder('SENQUEUE1');
          pc = 70;
          continue;
        case 70:
          s.setSlot(1, 267);
          pc = 71;
          continue;
        case 71:
          s.placeholder('SENQUEUE1');
          pc = 72;
          continue;
        case 72:
          s.setSlot(1, 0);
          pc = 73;
          continue;
        case 73:
          s.placeholder('SENQUEUE1');
          pc = 74;
          continue;
        case 74:
          s.moveUnit('MOVE_DEFINED', [14]);
          pc = 75;
          continue;
        case 75:
          s.placeholder('STAL2');
          pc = 76;
          continue;
        case 76:
          s.placeholder('FADI');
          pc = 77;
          continue;
        case 77:
          s.placeholder('EvtBgmFadeIn');
          pc = 78;
          continue;
        case 78:
          s.placeholder('ENUN');
          pc = 79;
          continue;
        case 79:
          s.placeholder('CLEA');
          pc = 80;
          continue;
        case 80:
          s.placeholder('CLEE');
          pc = 81;
          continue;
        case 81:
          s.placeholder('CLEN');
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
          s.placeholder('MUSC');
          pc = 85;
          continue;
        case 85:
          await s.textShow(2430);
          pc = 86;
          continue;
        case 86:
          s.placeholder('TEXTEND');
          pc = 87;
          continue;
        case 87:
          s.placeholder('MUSI');
          pc = 88;
          continue;
        case 88:
          s.placeholder('TEXTCONT');
          pc = 89;
          continue;
        case 89:
          s.placeholder('TEXTEND');
          pc = 90;
          continue;
        case 90:
          s.placeholder('REMA');
          pc = 91;
          continue;
        case 91:
          s.placeholder('MUNO');
          pc = 92;
          continue;
        case 92:
          await s.textShow(2431);
          pc = 93;
          continue;
        case 93:
          s.placeholder('TEXTEND');
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
          s.placeholder('TEXTCONT');
          pc = 97;
          continue;
        case 97:
          s.placeholder('TEXTEND');
          pc = 98;
          continue;
        case 98:
          s.placeholder('REMA');
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
          s.placeholder('ENUN');
          pc = 102;
          continue;
        case 102:
          s.loadUnits(1, Sym('UnitDef_Ch5Enemy_0'));
          pc = 103;
          continue;
        case 103:
          s.placeholder('ENUN');
          pc = 104;
          continue;
        case 104:
          s.placeholder('MUSC');
          pc = 105;
          continue;
        case 105:
          s.placeholder('TEXTSTART');
          pc = 106;
          continue;
        case 106:
          await s.textShow(2432);
          pc = 107;
          continue;
        case 107:
          s.placeholder('TEXTEND');
          pc = 108;
          continue;
        case 108:
          s.placeholder('REMA');
          pc = 109;
          continue;
        case 109:
          s.loadUnits(1, Sym('UnitDef_Ch5Enemy_1'));
          pc = 110;
          continue;
        case 110:
          s.placeholder('ENUN');
          pc = 111;
          continue;
        case 111:
          s.placeholder('ENUN');
          pc = 112;
          continue;
        case 112:
          s.placeholder('CAMERA2');
          pc = 113;
          continue;
        case 113:
          s.loadUnits(2, Sym('frontier_df4_banim_b_074_909DE8', 400));
          pc = 114;
          continue;
        case 114:
          s.placeholder('ENUN');
          pc = 115;
          continue;
        case 115:
          s.placeholder('CURSOR_CHAR');
          pc = 116;
          continue;
        case 116:
          await s.stall(60);
          pc = 117;
          continue;
        case 117:
          s.placeholder('CURE');
          pc = 118;
          continue;
        case 118:
          s.placeholder('TEXTSTART');
          pc = 119;
          continue;
        case 119:
          await s.textShow(2433);
          pc = 120;
          continue;
        case 120:
          s.placeholder('TEXTEND');
          pc = 121;
          continue;
        case 121:
          s.placeholder('REMA');
          pc = 122;
          continue;
        case 122:
          s.moveUnit('MOVE', [0, 13, 6, 15]);
          pc = 123;
          continue;
        case 123:
          s.placeholder('ENUN');
          pc = 124;
          continue;
        case 124:
          s.placeholder('CURSOR_CHAR');
          pc = 125;
          continue;
        case 125:
          await s.stall(60);
          pc = 126;
          continue;
        case 126:
          s.placeholder('CURE');
          pc = 127;
          continue;
        case 127:
          s.placeholder('TEXTSTART');
          pc = 128;
          continue;
        case 128:
          await s.textShow(2434);
          pc = 129;
          continue;
        case 129:
          s.placeholder('TEXTEND');
          pc = 130;
          continue;
        case 130:
          s.placeholder('REMA');
          pc = 131;
          continue;
        case 131:
          s.placeholder('FADI');
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
          s.placeholder('ENUN');
          pc = 135;
          continue;
        case 135:
          await s.call(Sym('data_085B9BBC', 512));
          pc = 136;
          continue;
        case 136:
          s.placeholder('FADU');
          pc = 137;
          continue;
        case 137:
          s.placeholder('CAMERA');
          pc = 138;
          continue;
        case 138:
          s.placeholder('MUSC');
          pc = 139;
          continue;
        case 139:
          s.placeholder('CURSOR_AT');
          pc = 140;
          continue;
        case 140:
          await s.stall(60);
          pc = 141;
          continue;
        case 141:
          s.placeholder('CURE');
          pc = 142;
          continue;
        case 142:
          s.loadUnits(1, Sym('frontier_df4_banim_b_074_909DE8', 180));
          pc = 143;
          continue;
        case 143:
          s.placeholder('ENUN');
          pc = 144;
          continue;
        case 144:
          s.moveUnit('MOVE', [0, 32, 9, 7]);
          pc = 145;
          continue;
        case 145:
          s.placeholder('ENUN');
          pc = 146;
          continue;
        case 146:
          s.placeholder('CURSOR_CHAR');
          pc = 147;
          continue;
        case 147:
          await s.stall(60);
          pc = 148;
          continue;
        case 148:
          s.placeholder('CURE');
          pc = 149;
          continue;
        case 149:
          s.placeholder('TEXTSTART');
          pc = 150;
          continue;
        case 150:
          await s.textShow(2435);
          pc = 151;
          continue;
        case 151:
          s.placeholder('TEXTEND');
          pc = 152;
          continue;
        case 152:
          s.placeholder('REMA');
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
          s.placeholder('CAMERA');
          pc = 156;
          continue;
        case 156:
          s.placeholder('MUSC');
          pc = 157;
          continue;
        case 157:
          s.placeholder('CURSOR_CHAR');
          pc = 158;
          continue;
        case 158:
          await s.stall(60);
          pc = 159;
          continue;
        case 159:
          s.placeholder('CURE');
          pc = 160;
          continue;
        case 160:
          s.placeholder('TEXTSTART');
          pc = 161;
          continue;
        case 161:
          await s.textShow(2436);
          pc = 162;
          continue;
        case 162:
          s.placeholder('TEXTEND');
          pc = 163;
          continue;
        case 163:
          s.placeholder('REMA');
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
          s.placeholder('EVBIT_T');
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
          s.placeholder('FADI');
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
          s.placeholder('CHECK_ALIVE');
          pc = 6;
          continue;
        case 6:
          if (s.slotInt(0) == 12) { pc = 11; } else { pc = 7; }
          continue;
        case 7:
          s.placeholder('MUSC');
          pc = 8;
          continue;
        case 8:
          await s.textShow(2441);
          pc = 9;
          continue;
        case 9:
          s.placeholder('TEXTEND');
          pc = 10;
          continue;
        case 10:
          pc = 15;
          continue;
        case 11:
          pc = 12;
          continue;
        case 12:
          s.placeholder('MUSC');
          pc = 13;
          continue;
        case 13:
          await s.textShow(2442);
          pc = 14;
          continue;
        case 14:
          s.placeholder('TEXTEND');
          pc = 15;
          continue;
        case 15:
          pc = 16;
          continue;
        case 16:
          s.placeholder('REMA');
          pc = 17;
          continue;
        case 17:
          s.placeholder('CHECK_EVENTID');
          pc = 18;
          continue;
        case 18:
          if (s.slotInt(2) == 12) { pc = 11; } else { pc = 19; }
          continue;
        case 19:
          s.placeholder('CHECK_EVENTID');
          pc = 20;
          continue;
        case 20:
          if (s.slotInt(2) == 12) { pc = 11; } else { pc = 21; }
          continue;
        case 21:
          s.placeholder('CHECK_EVENTID');
          pc = 22;
          continue;
        case 22:
          if (s.slotInt(2) == 12) { pc = 11; } else { pc = 23; }
          continue;
        case 23:
          s.placeholder('CHECK_EVENTID');
          pc = 24;
          continue;
        case 24:
          if (s.slotInt(2) == 12) { pc = 11; } else { pc = 25; }
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
          s.placeholder('TEXTEND');
          pc = 29;
          continue;
        case 29:
          s.placeholder('REMA');
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
          s.placeholder('GIVEITEMTO');
          pc = 33;
          continue;
        case 33:
          pc = 34;
          continue;
        case 34:
          s.placeholder('ENUT');
          pc = 35;
          continue;
        case 35:
          s.placeholder('ENUT');
          pc = 36;
          continue;
        case 36:
          s.placeholder('ENUT');
          pc = 37;
          continue;
        case 37:
          s.placeholder('ENUT');
          pc = 38;
          continue;
        case 38:
          s.placeholder('ENUT');
          pc = 39;
          continue;
        case 39:
          s.placeholder('MNC2');
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
    s.placeholder('MUSC');
    s.setSlot(11, 262154);
    s.placeholder('LOMA');
    s.placeholder('FADU');
    s.placeholder('BROWNBOXTEXT');
    s.placeholder('CURSOR_AT');
    await s.stall(60);
    s.placeholder('CURE');
    s.placeholder('FADI');
    s.setSlot(11, 262155);
    s.placeholder('LOMA');
    s.loadUnits(1, Sym('UnitDef_Ch5xEnemy_1'));
    s.placeholder('ENUN');
    s.placeholder('FADU');
    s.placeholder('SPAWN_ENEMY');
    s.moveUnit('MOVE', [16, 67, 10, 4]);
    s.placeholder('ENUN');
    s.moveUnit('MOVE', [16, 77, 9, 3]);
    s.placeholder('ENUN');
    s.moveUnit('MOVE', [16, 67, 10, 2]);
    s.placeholder('ENUN');
    s.moveUnit('MOVE', [16, 77, 10, 3]);
    s.placeholder('ENUN');
    s.placeholder('CURSOR_CHAR');
    await s.stall(60);
    s.placeholder('CURE');
    s.placeholder('TEXTSTART');
    await s.textShow(2455);
    s.placeholder('TEXTEND');
    s.placeholder('REMA');
    s.placeholder('FADI');
    s.placeholder('EvtBgmFadeIn');
    s.placeholder('CLEA');
    s.placeholder('CLEE');
    s.placeholder('CLEN');
    s.setSlot(11, 786452);
    s.placeholder('LOMA');
    s.loadUnits(2, Sym('UnitDef_Ch5xAlly_1'));
    s.placeholder('ENUN');
    s.placeholder('FADU');
    s.placeholder('CURSOR_CHAR');
    await s.stall(60);
    s.placeholder('CURE');
    s.setSlot(2, 45);
    await s.call(Sym('EventScr_SetBackground'));
    s.placeholder('MUSC');
    await s.textShow(2456);
    s.placeholder('TEXTEND');
    s.placeholder('REMA');
    s.placeholder('FADI');
    s.placeholder('CLEA');
    s.placeholder('CLEE');
    s.placeholder('CLEN');
    s.setSlot(11, 458761);
    s.placeholder('LOMA');
    s.placeholder('FADU');
    s.loadUnits(2, Sym('UnitDef_Ch5xAlly_2'));
    s.placeholder('ENUN');
    s.placeholder('CURSOR_CHAR');
    await s.stall(60);
    s.placeholder('CURE');
    s.setSlot(2, 44);
    s.setSlot(3, 2457);
    await s.call(Sym('Event_TextWithBG'));
    s.moveUnit('MOVE', [0, 15, 9, 4]);
    s.placeholder('STAL2');
    s.moveUnit('MOVE', [0, 16, 9, 5]);
    s.moveUnit('MOVE', [0, 17, 8, 5]);
    s.moveUnit('MOVE', [0, 66, 8, 6]);
    s.placeholder('STAL2');
    s.placeholder('FADI');
    s.placeholder('ENUN');
    s.placeholder('CLEA');
    s.placeholder('CLEE');
    s.placeholder('CLEN');
    s.setSlot(11, 458766);
    s.placeholder('LOMA');
    s.loadUnits(1, Sym('frontier_df4_banim_b_075_90A050'));
    s.placeholder('ENUN');
    s.placeholder('FADU');
    s.placeholder('CURSOR_CHAR');
    await s.stall(60);
    s.placeholder('CURE');
    await s.textShow(2458);
    s.placeholder('TEXTEND');
    s.placeholder('REMA');
    s.placeholder('CAMERA');
    s.loadUnits(1, Sym('UnitDef_Event_Ch5xAlly'));
    s.placeholder('ENUN');
    s.placeholder('CURSOR_CHAR');
    await s.stall(60);
    s.placeholder('CURE');
    s.setSlot(2, 21);
    await s.call(Sym('EventScr_SetBackground'));
    await s.textShow(2459);
    s.placeholder('TEXTEND');
    s.placeholder('REMA');
    s.placeholder('EvtBgmFadeIn');
    return;
}

/// `EventScr_Ch5x_EndingScene`
Future<void> Ch5x_EndingScene(Scene s) async {
    s.placeholder('ASMC');
    s.placeholder('MUSC');
    s.setSlot(2, 21);
    await s.call(Sym('EventScr_SetBackground'));
    await s.textShow(2465);
    s.placeholder('TEXTEND');
    s.placeholder('REMA');
    s.placeholder('FADI');
    s.placeholder('EvtBgmFadeIn');
    s.placeholder('CLEA');
    s.placeholder('CLEE');
    s.placeholder('CLEN');
    s.placeholder('CLEAN');
    s.placeholder('CAMERA2');
    s.placeholder('EvtSetLoadUnitNoREDA');
    s.loadUnits(2, Sym('UnitDef_Ch5xAlly_0'));
    s.placeholder('ENUN');
    s.placeholder('FADU');
    s.loadUnits(1, Sym('UnitDef_Ch5xAlly_0'));
    s.placeholder('ENUN');
    s.placeholder('CURSOR_CHAR');
    await s.stall(60);
    s.placeholder('CURE');
    s.placeholder('TEXTSTART');
    await s.textShow(2466);
    s.placeholder('TEXTEND');
    s.placeholder('REMA');
    s.placeholder('FADI');
    s.placeholder('CLEA');
    s.placeholder('CLEE');
    s.placeholder('CLEN');
    s.setSlot(11, 262154);
    s.placeholder('LOMA');
    s.loadUnits(1, Sym('UnitDef_Ch5xEnemy_2'));
    s.placeholder('ENUN');
    s.placeholder('FADU');
    s.placeholder('EVBIT_T');
    s.loadUnits(2, Sym('UnitDef_Ch5xAlly_3'));
    s.placeholder('ENUN');
    s.placeholder('EVBIT_F');
    s.placeholder('MUSC');
    s.loadUnits(1, Sym('UnitDef_Ch5xEnemy_3'));
    s.placeholder('ENUN');
    s.loadUnits(1, Sym('UnitDef_Ch5xEnemy_4'));
    s.placeholder('ENUN');
    s.placeholder('CURSOR_CHAR');
    await s.stall(60);
    s.placeholder('CURE');
    s.setSlot(2, 44);
    await s.call(Sym('EventScr_SetBackground'));
    await s.textShow(2467);
    s.placeholder('TEXTEND');
    s.placeholder('REMA');
    s.placeholder('FADI');
    s.placeholder('EvtBgmFadeIn');
    s.placeholder('EVENT_WORD');
    s.placeholder('EVENT_WORD');
    s.placeholder('MNCH');
    return;
}

/// `EventScr_Ch6_0`
Future<void> Ch6_0(Scene s) async {
    var pc = 0;
    while (true) {
      switch (pc) {
        case 0:
          s.placeholder('CHECK_ALIVE');
          pc = 1;
          continue;
        case 1:
          if (s.slotInt(99) == 12) { pc = 16; } else { pc = 2; }
          continue;
        case 2:
          s.placeholder('CHECK_INAREA');
          pc = 3;
          continue;
        case 3:
          if (s.slotInt(4) == 12) { pc = 16; } else { pc = 4; }
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
          s.placeholder('MUSC');
          pc = 7;
          continue;
        case 7:
          s.placeholder('CAMERA_CAHR');
          pc = 8;
          continue;
        case 8:
          s.placeholder('CURSOR_CHAR');
          pc = 9;
          continue;
        case 9:
          await s.stall(60);
          pc = 10;
          continue;
        case 10:
          s.placeholder('CURE');
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
          if (s.slotInt(1) == 12) { pc = 14; } else { pc = 14; }
          continue;
        case 14:
          s.setSlot(7, 2);
          pc = 15;
          continue;
        case 15:
          if (s.slotInt(2) == 12) { pc = 16; } else { pc = 16; }
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
          s.placeholder('TEXTSTART');
          pc = 26;
          continue;
        case 26:
          await s.textShow(65535);
          pc = 27;
          continue;
        case 27:
          s.placeholder('TEXTEND');
          pc = 28;
          continue;
        case 28:
          s.placeholder('REMA');
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
          s.placeholder('EVBIT_T');
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
    s.placeholder('MUSI');
    s.setSlot(2, 0);
    s.setSlot(3, 2484);
    await s.call(Sym('Event_TextWithBG'));
    s.placeholder('MUNO');
    await s.call(Sym('data_085B9BBC', 360));
    s.setSlot(3, 111);
    s.placeholder('GIVEITEMTO');
    s.setSlot(2, Sym('EventScr_Ch6_3'));
    await s.call(Sym('EventScr_CallOnTutorialMode'));
    s.placeholder('EVBIT_T');
    return;
}

/// `EventScr_Ch6_2`
Future<void> Ch6_2(Scene s) async {
    var pc = 0;
    while (true) {
      switch (pc) {
        case 0:
          s.placeholder('CLEAN');
          pc = 1;
          continue;
        case 1:
          s.placeholder('CAMERA2');
          pc = 2;
          continue;
        case 2:
          s.placeholder('FADU');
          pc = 3;
          continue;
        case 3:
          s.placeholder('MUSC');
          pc = 4;
          continue;
        case 4:
          s.placeholder('CURSOR_CHAR');
          pc = 5;
          continue;
        case 5:
          await s.stall(60);
          pc = 6;
          continue;
        case 6:
          s.placeholder('CURE');
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
          s.placeholder('TEXTEND');
          pc = 11;
          continue;
        case 11:
          s.placeholder('CHECK_ALIVE');
          pc = 12;
          continue;
        case 12:
          if (s.slotInt(0) == 12) { pc = 15; } else { pc = 13; }
          continue;
        case 13:
          s.placeholder('EvtTextShow2');
          pc = 14;
          continue;
        case 14:
          s.placeholder('TEXTEND');
          pc = 15;
          continue;
        case 15:
          pc = 16;
          continue;
        case 16:
          s.placeholder('REMA');
          pc = 17;
          continue;
        case 17:
          s.placeholder('TUTORIALTEXTBOXSTART');
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
          s.placeholder('TEXTEND');
          pc = 21;
          continue;
        case 21:
          s.placeholder('REMA');
          pc = 22;
          continue;
        case 22:
          s.placeholder('ENUT');
          pc = 23;
          continue;
        case 23:
          return;
        default:
          return;
      }
    }
}

/// `EventScr_Ch6_BeginningScene`
Future<void> Ch6_BeginningScene(Scene s) async {
    s.placeholder('MUSC');
    s.setSlot(2, 34);
    await s.call(Sym('EventScr_SetBackground'));
    await s.textShow(2468);
    s.placeholder('TEXTEND');
    s.placeholder('REMA');
    s.placeholder('EvtBgmFadeIn');
    await s.call(Sym('EventScr_TextShowWithFadeIn'));
    s.placeholder('EVBIT_T');
    s.loadUnits(2, Sym('UnitDef_Ch6Ally_0'));
    s.placeholder('ENUN');
    s.placeholder('EVBIT_F');
    s.placeholder('CAMERA2');
    s.loadUnits(1, Sym('UnitDef_Ch6Mixed'));
    s.placeholder('ENUN');
    s.setSlot(2, 75);
    s.moveUnit('MOVE_CLOSEST', [65535, 65533, 5, 8]);
    await s.call(Sym('EventScr_UnitWarpIN'));
    s.setSlot(2, 249);
    s.moveUnit('MOVE_CLOSEST', [65535, 65533, 6, 8]);
    await s.call(Sym('EventScr_UnitWarpIN'));
    s.moveUnit('MOVE_1STEP', [0, 1, 0]);
    s.moveUnit('MOVE_1STEP', [0, 2, 0]);
    s.placeholder('ENUN');
    s.placeholder('CURSOR_CHAR');
    await s.stall(60);
    s.placeholder('CURE');
    s.setSlot(2, 34);
    await s.call(Sym('EventScr_SetBackground'));
    await s.textShow(2469);
    s.placeholder('TEXTEND');
    s.placeholder('MUSC');
    s.placeholder('TEXTCONT');
    s.placeholder('TEXTEND');
    s.placeholder('REMA');
    s.setSlot(2, 34);
    await s.call(Sym('EventScr_SetBackground'));
    await s.textShow(2470);
    s.placeholder('TEXTEND');
    s.placeholder('REMA');
    s.setSlot(2, 34);
    await s.call(Sym('EventScr_SetBackground'));
    await s.textShow(2471);
    s.placeholder('TEXTEND');
    s.placeholder('REMA');
    await s.call(Sym('EventScr_TextShowWithFadeIn'));
    s.moveUnit('MOVE', [65535, 251, 20, 5]);
    s.setSlot(2, 75);
    await s.call(Sym('EventScr_UnitWarpOUT'));
    s.setSlot(2, 249);
    await s.call(Sym('EventScr_UnitWarpOUT'));
    s.placeholder('CAMERA2');
    s.setSlot(2, 75);
    s.moveUnit('MOVE_CLOSEST', [65535, 65533, 19, 6]);
    await s.call(Sym('EventScr_UnitWarpIN'));
    s.setSlot(2, 249);
    s.moveUnit('MOVE_CLOSEST', [65535, 65533, 20, 6]);
    await s.call(Sym('EventScr_UnitWarpIN'));
    s.placeholder('CURSOR_CHAR');
    await s.stall(60);
    s.placeholder('CURE');
    s.setSlot(2, 39);
    s.setSlot(3, 2472);
    await s.call(Sym('Event_TextWithBG'));
    await s.stall(60);
    s.setSlot(2, 249);
    await s.call(Sym('EventScr_UnitWarpOUT'));
    s.setSlot(2, 251);
    await s.call(Sym('EventScr_UnitWarpOUT'));
    s.placeholder('CAMERA2');
    s.setSlot(2, 249);
    s.moveUnit('MOVE_CLOSEST', [65535, 65533, 26, 12]);
    await s.call(Sym('EventScr_UnitWarpIN'));
    s.setSlot(2, 251);
    s.moveUnit('MOVE_CLOSEST', [65535, 65533, 25, 12]);
    await s.call(Sym('EventScr_UnitWarpIN'));
    s.placeholder('CURSOR_CHAR');
    await s.stall(60);
    s.placeholder('CURE');
    s.setSlot(2, 39);
    await s.call(Sym('EventScr_SetBackground'));
    await s.textShow(2473);
    s.placeholder('TEXTEND');
    s.placeholder('REMA');
    s.placeholder('FADI');
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
          s.placeholder('CHECK_ALIVE');
          pc = 4;
          continue;
        case 4:
          if (s.slotInt(0) == 12) { pc = 17; } else { pc = 5; }
          continue;
        case 5:
          s.placeholder('CHECK_ALIVE');
          pc = 6;
          continue;
        case 6:
          if (s.slotInt(0) == 12) { pc = 17; } else { pc = 7; }
          continue;
        case 7:
          s.placeholder('CHECK_ALIVE');
          pc = 8;
          continue;
        case 8:
          if (s.slotInt(0) == 12) { pc = 17; } else { pc = 9; }
          continue;
        case 9:
          s.placeholder('MUSC');
          pc = 10;
          continue;
        case 10:
          await s.textShow(2482);
          pc = 11;
          continue;
        case 11:
          s.placeholder('TEXTEND');
          pc = 12;
          continue;
        case 12:
          s.placeholder('REMA');
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
          s.placeholder('GIVEITEMTO');
          pc = 17;
          continue;
        case 17:
          pc = 18;
          continue;
        case 18:
          s.placeholder('REMA');
          pc = 19;
          continue;
        case 19:
          s.placeholder('MUSC');
          pc = 20;
          continue;
        case 20:
          await s.textShow(2483);
          pc = 21;
          continue;
        case 21:
          s.placeholder('TEXTEND');
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
          s.placeholder('TEXTCONT');
          pc = 26;
          continue;
        case 26:
          s.placeholder('TEXTEND');
          pc = 27;
          continue;
        case 27:
          s.placeholder('REMA');
          pc = 28;
          continue;
        case 28:
          s.placeholder('ENUT');
          pc = 29;
          continue;
        case 29:
          s.placeholder('ENUT');
          pc = 30;
          continue;
        case 30:
          s.placeholder('MNCH');
          pc = 31;
          continue;
        case 31:
          return;
        default:
          return;
      }
    }
}

/// `EventScr_Ch7_BeginningScene`
Future<void> Ch7_BeginningScene(Scene s) async {
    var pc = 0;
    while (true) {
      switch (pc) {
        case 0:
          s.placeholder('MUSC');
          pc = 1;
          continue;
        case 1:
          s.loadUnits(1, Sym('frontier_df4_banim_b_076_90B4DC'));
          pc = 2;
          continue;
        case 2:
          s.placeholder('ENUN');
          pc = 3;
          continue;
        case 3:
          s.placeholder('FADU');
          pc = 4;
          continue;
        case 4:
          s.loadUnits(3, Sym('UnitDef_Event_Ch7Ally'));
          pc = 5;
          continue;
        case 5:
          s.placeholder('ENUN');
          pc = 6;
          continue;
        case 6:
          await s.stall(15);
          pc = 7;
          continue;
        case 7:
          s.placeholder('CAMERA2');
          pc = 8;
          continue;
        case 8:
          s.placeholder('CURSOR_AT');
          pc = 9;
          continue;
        case 9:
          await s.stall(60);
          pc = 10;
          continue;
        case 10:
          s.placeholder('CURE');
          pc = 11;
          continue;
        case 11:
          s.placeholder('CAMERA');
          pc = 12;
          continue;
        case 12:
          s.placeholder('CURSOR_CHAR');
          pc = 13;
          continue;
        case 13:
          await s.stall(60);
          pc = 14;
          continue;
        case 14:
          s.placeholder('CURE');
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
          s.placeholder('TEXTEND');
          pc = 19;
          continue;
        case 19:
          s.placeholder('CHECK_ALIVE');
          pc = 20;
          continue;
        case 20:
          if (s.slotInt(0) == 12) { pc = 23; } else { pc = 21; }
          continue;
        case 21:
          s.placeholder('EvtTextShow2');
          pc = 22;
          continue;
        case 22:
          s.placeholder('TEXTEND');
          pc = 23;
          continue;
        case 23:
          pc = 24;
          continue;
        case 24:
          s.placeholder('CHECK_ALIVE');
          pc = 25;
          continue;
        case 25:
          if (s.slotInt(1) == 12) { pc = 23; } else { pc = 26; }
          continue;
        case 26:
          s.placeholder('CHECK_ALIVE');
          pc = 27;
          continue;
        case 27:
          if (s.slotInt(1) == 12) { pc = 23; } else { pc = 28; }
          continue;
        case 28:
          s.placeholder('CHECK_ALIVE');
          pc = 29;
          continue;
        case 29:
          if (s.slotInt(1) == 12) { pc = 23; } else { pc = 30; }
          continue;
        case 30:
          s.placeholder('EvtTextShow2');
          pc = 31;
          continue;
        case 31:
          s.placeholder('TEXTEND');
          pc = 32;
          continue;
        case 32:
          pc = 33;
          continue;
        case 33:
          s.placeholder('CHECK_ALIVE');
          pc = 34;
          continue;
        case 34:
          if (s.slotInt(2) == 12) { pc = 23; } else { pc = 35; }
          continue;
        case 35:
          s.placeholder('CHECK_ALIVE');
          pc = 36;
          continue;
        case 36:
          if (s.slotInt(2) == 12) { pc = 23; } else { pc = 37; }
          continue;
        case 37:
          s.placeholder('EvtTextShow2');
          pc = 38;
          continue;
        case 38:
          s.placeholder('TEXTEND');
          pc = 39;
          continue;
        case 39:
          pc = 40;
          continue;
        case 40:
          s.placeholder('CHECK_ALIVE');
          pc = 41;
          continue;
        case 41:
          if (s.slotInt(3) == 12) { pc = 23; } else { pc = 42; }
          continue;
        case 42:
          s.placeholder('CHECK_ALIVE');
          pc = 43;
          continue;
        case 43:
          if (s.slotInt(3) == 12) { pc = 23; } else { pc = 44; }
          continue;
        case 44:
          s.placeholder('EvtTextShow2');
          pc = 45;
          continue;
        case 45:
          s.placeholder('TEXTEND');
          pc = 46;
          continue;
        case 46:
          pc = 47;
          continue;
        case 47:
          s.placeholder('CHECK_ALIVE');
          pc = 48;
          continue;
        case 48:
          if (s.slotInt(4) == 12) { pc = 23; } else { pc = 49; }
          continue;
        case 49:
          s.placeholder('CHECK_ALIVE');
          pc = 50;
          continue;
        case 50:
          if (s.slotInt(4) == 12) { pc = 23; } else { pc = 51; }
          continue;
        case 51:
          s.placeholder('EvtTextShow2');
          pc = 52;
          continue;
        case 52:
          s.placeholder('TEXTEND');
          pc = 53;
          continue;
        case 53:
          pc = 54;
          continue;
        case 54:
          s.placeholder('CHECK_ALIVE');
          pc = 55;
          continue;
        case 55:
          if (s.slotInt(5) == 12) { pc = 23; } else { pc = 56; }
          continue;
        case 56:
          s.placeholder('EvtTextShow2');
          pc = 57;
          continue;
        case 57:
          s.placeholder('TEXTEND');
          pc = 58;
          continue;
        case 58:
          pc = 59;
          continue;
        case 59:
          s.placeholder('CHECK_ALIVE');
          pc = 60;
          continue;
        case 60:
          if (s.slotInt(6) == 12) { pc = 23; } else { pc = 61; }
          continue;
        case 61:
          s.placeholder('EvtTextShow2');
          pc = 62;
          continue;
        case 62:
          s.placeholder('TEXTEND');
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
          s.placeholder('TEXTEND');
          pc = 66;
          continue;
        case 66:
          await s.call(Sym('data_085B9BBC', 512));
          pc = 67;
          continue;
        case 67:
          s.placeholder('MUSC');
          pc = 68;
          continue;
        case 68:
          s.placeholder('FADU');
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
          s.placeholder('EVBIT_T');
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
    s.placeholder('FADI');
    s.setSlot(11, 0);
    s.placeholder('LOMA');
    s.placeholder('CLEA');
    s.placeholder('CLEE');
    s.placeholder('CLEN');
    s.placeholder('FADU');
    s.placeholder('MUSC');
    s.loadUnits(2, Sym('frontier_df4_banim_b_076_90B4DC', 440));
    s.placeholder('ENUN');
    s.placeholder('CURSOR_CHAR');
    await s.stall(60);
    s.placeholder('CURE');
    s.placeholder('TEXTSTART');
    await s.textShow(2501);
    s.placeholder('TEXTEND');
    s.placeholder('REMA');
    s.moveUnit('MOVE_1STEP', [0, 2, 1]);
    s.moveUnit('MOVE_1STEP', [0, 1, 0]);
    s.loadUnits(2, Sym('frontier_df4_banim_b_076_90B4DC', 500));
    s.placeholder('ENUN');
    s.placeholder('ENUN');
    s.placeholder('CURSOR_CHAR');
    await s.stall(60);
    s.placeholder('CURE');
    s.placeholder('MUSI');
    s.setSlot(2, 21);
    s.setSlot(3, 2502);
    await s.call(Sym('Event_TextWithBG'));
    s.placeholder('MUNO');
    s.moveUnit('MOVE_1STEP', [0, 66, 0]);
    s.placeholder('ENUN');
    s.moveUnit('MOVE', [0, 66, 9, 0]);
    s.setSlot(13, 0);
    s.setSlot(1, 265);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 0);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 9);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 0);
    s.placeholder('SENQUEUE1');
    s.moveUnit('MOVE_DEFINED', [1]);
    s.setSlot(13, 0);
    s.setSlot(1, 266);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 0);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 10);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 0);
    s.placeholder('SENQUEUE1');
    s.moveUnit('MOVE_DEFINED', [2]);
    s.placeholder('STAL2');
    s.placeholder('FADI');
    s.placeholder('ENUN');
    s.placeholder('ENUT');
    s.placeholder('MNCH');
    return;
}

/// `EventScr_Ch8_0`
Future<void> Ch8_0(Scene s) async {
    s.placeholder('CAMERA');
    s.loadUnits(1, Sym('UnitDef_Ch8Ally_0'));
    s.placeholder('ENUN');
    s.placeholder('REVEAL');
    s.placeholder('REVEAL');
    s.placeholder('REVEAL');
    s.setSlot(1, 1);
    s.placeholder('SET_STATE');
    s.setSlot(1, 1);
    s.placeholder('SET_STATE');
    s.setSlot(1, 1);
    s.placeholder('SET_STATE');
    s.placeholder('CURSOR_CHAR');
    await s.stall(60);
    s.placeholder('CURE');
    s.placeholder('MUSC');
    s.placeholder('TEXTSTART');
    await s.textShow(2510);
    s.placeholder('TEXTEND');
    s.placeholder('REMA');
    s.placeholder('EVBIT_T');
    return;
}

/// `EventScr_Ch8_10`
Future<void> Ch8_10(Scene s) async {
    s.placeholder('CAMERA');
    s.loadUnits(2, Sym('UnitDef_Ch8Ally_2'));
    s.placeholder('ENUN');
    s.placeholder('MUSC');
    s.placeholder('FADU');
    s.placeholder('CURSOR_CHAR');
    await s.stall(60);
    s.placeholder('CURE');
    s.setSlot(2, 10);
    await s.call(Sym('EventScr_SetBackground'));
    await s.textShow(3010);
    s.placeholder('TEXTEND');
    s.placeholder('EvtBgmFadeIn');
    s.placeholder('FAWI');
    s.placeholder('REMA');
    s.placeholder('CLEA');
    s.placeholder('CLEE');
    s.placeholder('CLEN');
    s.setSlot(11, 1310734);
    s.placeholder('LOMA');
    s.placeholder('UNIT_COLORS');
    s.loadUnits(2, Sym('UnitDef_Ch8Ally_3'));
    s.placeholder('ENUN');
    s.placeholder('EvtBgmFadeIn');
    s.placeholder('FAWU');
    s.placeholder('BROWNBOXTEXT');
    s.placeholder('CURSOR_CHAR');
    await s.stall(60);
    s.placeholder('CURE');
    s.placeholder('REMOVEPORTRAITS');
    s.placeholder('FAWI');
    s.placeholder('BACG');
    s.placeholder('FAWU');
    await s.textShow(3011);
    s.placeholder('TEXTEND');
    s.placeholder('REMA');
    s.placeholder('FAWI');
    s.placeholder('CLEAN');
    s.placeholder('FAWU');
    s.moveUnit('MOVE', [0, 1, 0, 16]);
    s.placeholder('STAL2');
    s.placeholder('FAWI');
    s.placeholder('ENUN');
    s.placeholder('CLEA');
    s.placeholder('CLEE');
    s.placeholder('CLEN');
    s.placeholder('REMOVEPORTRAITS');
    s.placeholder('BACG');
    s.placeholder('FAWU');
    await s.textShow(3012);
    s.placeholder('TEXTEND');
    s.placeholder('EvtBgmFadeIn');
    s.placeholder('FAWI');
    s.placeholder('REMA');
    s.setSlot(11, 1310734);
    s.placeholder('LOMA');
    s.placeholder('UNIT_COLORS');
    s.loadUnits(2, Sym('UnitDef_Ch8Ally_2'));
    s.placeholder('ENUN');
    s.placeholder('MUSC');
    s.placeholder('FAWU');
    s.placeholder('CURSOR_CHAR');
    await s.stall(60);
    s.placeholder('CURE');
    s.setSlot(2, 10);
    await s.call(Sym('EventScr_SetBackground'));
    await s.textShow(3013);
    s.placeholder('TEXTEND');
    s.placeholder('REMA');
    s.placeholder('MNCH');
    s.placeholder('ENDB');
}

/// `EventScr_Ch8_11`
Future<void> Ch8_11(Scene s) async {
    s.slotArith('SADD', 7, 2);
    s.slotArith('SADD', 8, 3);
    s.slotArith('SADD', 9, 4);
    s.setSlot(2, 131087);
    await s.call(Sym('EventScr_9EEA58'));
    s.placeholder('TILECHANGE');
    s.loadUnits(1, Sym('UnitDef_Ch9AEnemy_11'));
    s.placeholder('ENUN');
    s.placeholder('FADU');
    s.placeholder('CURSOR_CHAR');
    await s.stall(60);
    s.placeholder('CURE');
    s.slotArith('SADD', 2, 7);
    s.placeholder('TEXTSTART');
    await s.textShow(65535);
    s.placeholder('TEXTEND');
    s.placeholder('REMA');
    s.moveUnit('MOVE', [16, 105, 13, 10]);
    s.moveUnit('MOVE', [16, 67, 15, 10]);
    s.moveUnit('MOVE', [16, 83, 13, 5]);
    s.setSlot(13, 0);
    s.setSlot(1, 65873);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 0);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 65871);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 0);
    s.placeholder('SENQUEUE1');
    s.moveUnit('MOVE_DEFINED', [87]);
    s.placeholder('ENUN');
    s.placeholder('DISA');
    s.placeholder('DISA');
    s.placeholder('CURSOR_CHAR');
    await s.stall(60);
    s.placeholder('CURE');
    s.slotArith('SADD', 2, 8);
    s.placeholder('TEXTSTART');
    await s.textShow(65535);
    s.placeholder('TEXTEND');
    s.placeholder('REMA');
    s.moveUnit('MOVE', [16, 83, 13, 10]);
    s.moveUnit('MOVE', [16, 87, 15, 10]);
    s.moveUnit('MOVE', [16, 68, 15, 5]);
    s.setSlot(13, 0);
    s.setSlot(1, 65867);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 0);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 65869);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 0);
    s.placeholder('SENQUEUE1');
    s.moveUnit('MOVE_DEFINED', [29]);
    s.placeholder('ENUN');
    s.placeholder('DISA');
    s.placeholder('DISA');
    s.placeholder('CURSOR_CHAR');
    await s.stall(60);
    s.placeholder('CURE');
    s.slotArith('SADD', 2, 9);
    s.placeholder('TEXTSTART');
    await s.textShow(65535);
    s.placeholder('TEXTEND');
    s.placeholder('REMA');
    s.moveUnit('MOVE', [16, 29, 13, 10]);
    s.moveUnit('MOVE', [16, 68, 15, 10]);
    s.placeholder('STAL2');
    s.placeholder('FADI');
    s.placeholder('ENUN');
    s.placeholder('CLEA');
    s.placeholder('CLEE');
    s.placeholder('CLEN');
    return;
}

/// `EventScr_Ch8_BeginningScene`
Future<void> Ch8_BeginningScene(Scene s) async {
    s.placeholder('MUSC');
    s.loadUnits(2, Sym('UnitDef_Ch8Ally_1'));
    s.placeholder('ENUN');
    s.placeholder('CURSOR_CHAR');
    await s.stall(60);
    s.placeholder('CURE');
    s.setSlot(2, 21);
    await s.call(Sym('EventScr_SetBackground'));
    await s.textShow(2505);
    s.placeholder('TEXTEND');
    s.placeholder('EvtBgmFadeIn');
    s.placeholder('TEXTCONT');
    s.placeholder('TEXTEND');
    await s.call(Sym('EventScr_TextShowWithFadeIn'));
    s.loadUnits(1, Sym('UnitDef_Ch8Enemy_3'));
    s.placeholder('ENUN');
    s.placeholder('CURSOR_CHAR');
    await s.stall(60);
    s.placeholder('CURE');
    s.placeholder('MUSC');
    s.placeholder('TEXTSTART');
    await s.textShow(2506);
    s.placeholder('TEXTEND');
    s.placeholder('REMA');
    await s.stall(30);
    s.placeholder('CUSE');
    s.placeholder('CURSOR_CHAR');
    await s.stall(60);
    s.placeholder('CURE');
    s.moveUnit('MOVE', [0, 66, 20, 19]);
    s.setSlot(11, 1048596);
    s.moveUnit('MOVE_1STEP', [0, 65534, 1]);
    s.placeholder('ENUN');
    s.moveUnit('MOVE', [0, 66, 20, 15]);
    s.placeholder('ENUN');
    s.setSlot(11, 1048597);
    s.moveUnit('MOVE_1STEP', [0, 65534, 0]);
    s.moveUnit('MOVE', [0, 66, 19, 10]);
    s.placeholder('ENUN');
    s.placeholder('DISA');
    s.placeholder('CURSOR_CHAR');
    await s.stall(60);
    s.placeholder('CURE');
    s.setSlot(2, 21);
    s.setSlot(3, 2507);
    await s.call(Sym('Event_TextWithBG'));
    s.setSlot(11, 1048595);
    s.moveUnit('MOVE_1STEP', [0, 65534, 0]);
    s.placeholder('ENUN');
    s.moveUnit('MOVE', [0, 77, 19, 14]);
    s.placeholder('ENUN');
    s.setSlot(11, 1048594);
    s.moveUnit('MOVE_1STEP', [0, 65534, 1]);
    s.placeholder('ENUN');
    s.moveUnit('MOVE', [0, 77, 19, 14]);
    s.placeholder('ENUN');
    s.placeholder('CURSOR_CHAR');
    await s.stall(60);
    s.placeholder('CURE');
    s.placeholder('TEXTSTART');
    await s.textShow(2508);
    s.placeholder('TEXTEND');
    s.placeholder('REMA');
    s.setSlot(11, 1376276);
    s.placeholder('SOUN');
    s.placeholder('TILECHANGE');
    s.moveUnit('MOVE', [0, 77, 19, 10]);
    s.setSlot(11, 1048595);
    s.moveUnit('MOVE', [16, 65534, 19, 11]);
    s.setSlot(11, 1048596);
    s.moveUnit('MOVE', [16, 65534, 20, 11]);
    s.placeholder('ENUN');
    s.placeholder('CLEE');
    s.loadUnits(1, Sym('UnitDef_Ch8Enemy_0'));
    s.placeholder('ENUN');
    s.setSlot(2, Sym('UnitDef_Ch8Enemy_4'));
    s.setSlot(3, 1);
    await s.call(Sym('EventScr_LoadUnitForTutorial'));
    s.placeholder('CURSOR_CHAR');
    await s.stall(60);
    s.placeholder('CURE');
    s.setSlot(2, 21);
    await s.call(Sym('EventScr_SetBackground'));
    await s.textShow(2509);
    s.placeholder('TEXTEND');
    s.placeholder('REMA');
    await s.call(Sym('data_085B9BBC', 512));
    s.placeholder('ENUT');
    return;
}

/// `EventScr_Ch9A_2`
Future<void> Ch9A_2(Scene s) async {
    s.placeholder('MUSS');
    await s.stall(33);
    s.setSlot(2, 0);
    s.setSlot(3, 2538);
    await s.call(Sym('Event_TextWithBG'));
    s.placeholder('MURE');
    await s.call(Sym('data_085B9BBC', 360));
    s.setSlot(3, 96);
    s.placeholder('GIVEITEMTO');
    s.placeholder('EVBIT_T');
    return;
}

/// `EventScr_Ch9A_4`
Future<void> Ch9A_4(Scene s) async {
    var pc = 0;
    while (true) {
      switch (pc) {
        case 0:
          s.placeholder('CHECK_ALIVE');
          pc = 1;
          continue;
        case 1:
          if (s.slotInt(0) == 12) { pc = 2; } else { pc = 2; }
          continue;
        case 2:
          s.placeholder('CHECK_ALLEGIANCE');
          pc = 3;
          continue;
        case 3:
          s.setSlot(1, 0);
          pc = 4;
          continue;
        case 4:
          if (s.slotInt(0) == 12) { pc = 5; } else { pc = 5; }
          continue;
        case 5:
          s.placeholder('CAMERA_CAHR');
          pc = 6;
          continue;
        case 6:
          s.placeholder('CURSOR_CHAR');
          pc = 7;
          continue;
        case 7:
          await s.stall(60);
          pc = 8;
          continue;
        case 8:
          s.placeholder('CURE');
          pc = 9;
          continue;
        case 9:
          s.placeholder('MUSS');
          pc = 10;
          continue;
        case 10:
          await s.stall(33);
          pc = 11;
          continue;
        case 11:
          s.placeholder('TEXTSTART');
          pc = 12;
          continue;
        case 12:
          await s.textShow(2528);
          pc = 13;
          continue;
        case 13:
          s.placeholder('TEXTEND');
          pc = 14;
          continue;
        case 14:
          s.placeholder('REMA');
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
          s.placeholder('ENUN');
          pc = 20;
          continue;
        case 20:
          s.placeholder('DISA');
          pc = 21;
          continue;
        case 21:
          s.placeholder('DISA');
          pc = 22;
          continue;
        case 22:
          s.placeholder('DISA');
          pc = 23;
          continue;
        case 23:
          s.placeholder('DISA');
          pc = 24;
          continue;
        case 24:
          s.placeholder('CHECK_ENEMIES');
          pc = 25;
          continue;
        case 25:
          if (s.slotInt(0) != 12) { pc = 26; } else { pc = 26; }
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
          s.placeholder('COUNTER_SET');
          pc = 3;
          continue;
        case 3:
          s.placeholder('CHECK_TUTORIAL');
          pc = 4;
          continue;
        case 4:
          if (s.slotInt(0) != 12) { pc = 8; } else { pc = 5; }
          continue;
        case 5:
          s.placeholder('CHECK_HARD');
          pc = 6;
          continue;
        case 6:
          if (s.slotInt(0) == 12) { pc = 8; } else { pc = 7; }
          continue;
        case 7:
          s.placeholder('COUNTER_SET');
          pc = 8;
          continue;
        case 8:
          pc = 9;
          continue;
        case 9:
          s.placeholder('ENUF');
          pc = 10;
          continue;
        case 10:
          s.placeholder('EVBIT_T');
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
          s.placeholder('MUSC');
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
          s.placeholder('LOMA');
          pc = 8;
          continue;
        case 8:
          s.placeholder('CHECK_EXISTS');
          pc = 9;
          continue;
        case 9:
          if (s.slotInt(0) == 12) { pc = 12; } else { pc = 10; }
          continue;
        case 10:
          s.setSlot(1, 0);
          pc = 11;
          continue;
        case 11:
          s.placeholder('SET_STATE');
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
          s.placeholder('SET_STATE');
          pc = 15;
          continue;
        case 15:
          s.loadUnits(3, Sym('UnitDef_Ch9AAlly_2'));
          pc = 16;
          continue;
        case 16:
          s.placeholder('ENUN');
          pc = 17;
          continue;
        case 17:
          s.placeholder('FADU');
          pc = 18;
          continue;
        case 18:
          s.loadUnits(2, Sym('UnitDef_Ch9AAlly_3'));
          pc = 19;
          continue;
        case 19:
          s.placeholder('ENUN');
          pc = 20;
          continue;
        case 20:
          s.moveUnit('MOVE_1STEP', [0, 1, 0]);
          pc = 21;
          continue;
        case 21:
          s.placeholder('ENUN');
          pc = 22;
          continue;
        case 22:
          s.placeholder('CURSOR_CHAR');
          pc = 23;
          continue;
        case 23:
          await s.stall(60);
          pc = 24;
          continue;
        case 24:
          s.placeholder('CURE');
          pc = 25;
          continue;
        case 25:
          s.placeholder('MUSC');
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
          s.placeholder('TEXTEND');
          pc = 30;
          continue;
        case 30:
          s.placeholder('REMA');
          pc = 31;
          continue;
        case 31:
          s.placeholder('FADI');
          pc = 32;
          continue;
        case 32:
          s.placeholder('CLEA');
          pc = 33;
          continue;
        case 33:
          s.placeholder('CLEE');
          pc = 34;
          continue;
        case 34:
          s.placeholder('CLEN');
          pc = 35;
          continue;
        case 35:
          s.setSlot(11, 262162);
          pc = 36;
          continue;
        case 36:
          s.placeholder('LOMA');
          pc = 37;
          continue;
        case 37:
          s.placeholder('FADU');
          pc = 38;
          continue;
        case 38:
          s.loadUnits(2, Sym('UnitDef_Ch9AAlly_0'));
          pc = 39;
          continue;
        case 39:
          s.placeholder('ENUN');
          pc = 40;
          continue;
        case 40:
          s.placeholder('CURSOR_CHAR');
          pc = 41;
          continue;
        case 41:
          await s.stall(60);
          pc = 42;
          continue;
        case 42:
          s.placeholder('CURE');
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
          s.placeholder('TEXTEND');
          pc = 47;
          continue;
        case 47:
          s.placeholder('MUSI');
          pc = 48;
          continue;
        case 48:
          s.placeholder('TEXTCONT');
          pc = 49;
          continue;
        case 49:
          s.placeholder('TEXTEND');
          pc = 50;
          continue;
        case 50:
          s.placeholder('REMA');
          pc = 51;
          continue;
        case 51:
          s.placeholder('FADI');
          pc = 52;
          continue;
        case 52:
          s.placeholder('CLEAN');
          pc = 53;
          continue;
        case 53:
          s.placeholder('FADU');
          pc = 54;
          continue;
        case 54:
          s.loadUnits(2, Sym('UnitDef_Ch9AMixed_0'));
          pc = 55;
          continue;
        case 55:
          s.placeholder('ENUN');
          pc = 56;
          continue;
        case 56:
          s.placeholder('CURSOR_CHAR');
          pc = 57;
          continue;
        case 57:
          await s.stall(60);
          pc = 58;
          continue;
        case 58:
          s.placeholder('CURE');
          pc = 59;
          continue;
        case 59:
          s.placeholder('MUSS');
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
          s.placeholder('TEXTEND');
          pc = 65;
          continue;
        case 65:
          s.placeholder('MURE');
          pc = 66;
          continue;
        case 66:
          s.placeholder('TEXTCONT');
          pc = 67;
          continue;
        case 67:
          s.placeholder('TEXTEND');
          pc = 68;
          continue;
        case 68:
          s.placeholder('REMA');
          pc = 69;
          continue;
        case 69:
          s.placeholder('FADI');
          pc = 70;
          continue;
        case 70:
          s.placeholder('CLEAN');
          pc = 71;
          continue;
        case 71:
          s.placeholder('FADU');
          pc = 72;
          continue;
        case 72:
          s.moveUnit('MOVE', [0, 25, 9, 2]);
          pc = 73;
          continue;
        case 73:
          s.placeholder('STAL2');
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
          s.placeholder('SENQUEUE1');
          pc = 77;
          continue;
        case 77:
          s.setSlot(1, 0);
          pc = 78;
          continue;
        case 78:
          s.placeholder('SENQUEUE1');
          pc = 79;
          continue;
        case 79:
          s.setSlot(1, 137);
          pc = 80;
          continue;
        case 80:
          s.placeholder('SENQUEUE1');
          pc = 81;
          continue;
        case 81:
          s.setSlot(1, 0);
          pc = 82;
          continue;
        case 82:
          s.placeholder('SENQUEUE1');
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
          s.placeholder('SENQUEUE1');
          pc = 87;
          continue;
        case 87:
          s.setSlot(1, 0);
          pc = 88;
          continue;
        case 88:
          s.placeholder('SENQUEUE1');
          pc = 89;
          continue;
        case 89:
          s.setSlot(1, 137);
          pc = 90;
          continue;
        case 90:
          s.placeholder('SENQUEUE1');
          pc = 91;
          continue;
        case 91:
          s.setSlot(1, 0);
          pc = 92;
          continue;
        case 92:
          s.placeholder('SENQUEUE1');
          pc = 93;
          continue;
        case 93:
          s.moveUnit('MOVE_DEFINED', [28]);
          pc = 94;
          continue;
        case 94:
          s.placeholder('ENUN');
          pc = 95;
          continue;
        case 95:
          s.placeholder('CLEN');
          pc = 96;
          continue;
        case 96:
          s.moveUnit('MOVE_1STEP', [16, 1, 0]);
          pc = 97;
          continue;
        case 97:
          s.placeholder('ENUN');
          pc = 98;
          continue;
        case 98:
          s.placeholder('CURSOR_CHAR');
          pc = 99;
          continue;
        case 99:
          await s.stall(60);
          pc = 100;
          continue;
        case 100:
          s.placeholder('CURE');
          pc = 101;
          continue;
        case 101:
          s.placeholder('TEXTSTART');
          pc = 102;
          continue;
        case 102:
          await s.textShow(2525);
          pc = 103;
          continue;
        case 103:
          s.placeholder('TEXTEND');
          pc = 104;
          continue;
        case 104:
          s.placeholder('REMA');
          pc = 105;
          continue;
        case 105:
          s.placeholder('EvtBgmFadeIn');
          pc = 106;
          continue;
        case 106:
          s.placeholder('CAMERA2');
          pc = 107;
          continue;
        case 107:
          s.loadUnits(1, Sym('UnitDef_Ch9AEnemy_10'));
          pc = 108;
          continue;
        case 108:
          s.placeholder('ENUN');
          pc = 109;
          continue;
        case 109:
          s.moveUnit('MOVE_1STEP', [0, 2, 0]);
          pc = 110;
          continue;
        case 110:
          s.placeholder('ENUN');
          pc = 111;
          continue;
        case 111:
          s.placeholder('CURSOR_CHAR');
          pc = 112;
          continue;
        case 112:
          await s.stall(60);
          pc = 113;
          continue;
        case 113:
          s.placeholder('CURE');
          pc = 114;
          continue;
        case 114:
          s.placeholder('MUSC');
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
          s.placeholder('ENUN');
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
          s.placeholder('FADI');
          pc = 124;
          continue;
        case 124:
          s.placeholder('DISA');
          pc = 125;
          continue;
        case 125:
          s.placeholder('CLEA');
          pc = 126;
          continue;
        case 126:
          s.loadUnits(1, Sym('UnitDef_Event_Ch9aAlly'));
          pc = 127;
          continue;
        case 127:
          s.placeholder('ENUN');
          pc = 128;
          continue;
        case 128:
          s.setSlot(1, 1);
          pc = 129;
          continue;
        case 129:
          s.placeholder('SET_STATE');
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
          s.placeholder('MUSC');
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
          s.placeholder('TEXTEND');
          pc = 5;
          continue;
        case 5:
          s.placeholder('REMA');
          pc = 6;
          continue;
        case 6:
          s.placeholder('FADI');
          pc = 7;
          continue;
        case 7:
          s.placeholder('CLEA');
          pc = 8;
          continue;
        case 8:
          s.placeholder('CLEE');
          pc = 9;
          continue;
        case 9:
          s.placeholder('CLEN');
          pc = 10;
          continue;
        case 10:
          s.placeholder('CLEAN');
          pc = 11;
          continue;
        case 11:
          s.placeholder('CAMERA2');
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
          s.placeholder('ENUN');
          pc = 15;
          continue;
        case 15:
          s.placeholder('FADU');
          pc = 16;
          continue;
        case 16:
          s.loadUnits(2, Sym('UnitDef_Ch9AMixed_1'));
          pc = 17;
          continue;
        case 17:
          s.placeholder('ENUN');
          pc = 18;
          continue;
        case 18:
          s.moveUnit('MOVE_1STEP', [0, 167, 2]);
          pc = 19;
          continue;
        case 19:
          s.placeholder('ENUN');
          pc = 20;
          continue;
        case 20:
          s.placeholder('CURSOR_CHAR');
          pc = 21;
          continue;
        case 21:
          await s.stall(60);
          pc = 22;
          continue;
        case 22:
          s.placeholder('CURE');
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
          s.placeholder('ENUN');
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
          s.placeholder('SENQUEUE1');
          pc = 32;
          continue;
        case 32:
          s.setSlot(1, 0);
          pc = 33;
          continue;
        case 33:
          s.placeholder('SENQUEUE1');
          pc = 34;
          continue;
        case 34:
          s.setSlot(1, 196628);
          pc = 35;
          continue;
        case 35:
          s.placeholder('SENQUEUE1');
          pc = 36;
          continue;
        case 36:
          s.setSlot(1, 0);
          pc = 37;
          continue;
        case 37:
          s.placeholder('SENQUEUE1');
          pc = 38;
          continue;
        case 38:
          s.moveUnit('MOVE_DEFINED', [167]);
          pc = 39;
          continue;
        case 39:
          s.placeholder('ENUN');
          pc = 40;
          continue;
        case 40:
          s.placeholder('CURSOR_CHAR');
          pc = 41;
          continue;
        case 41:
          await s.stall(60);
          pc = 42;
          continue;
        case 42:
          s.placeholder('CURE');
          pc = 43;
          continue;
        case 43:
          s.placeholder('MUSC');
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
          s.placeholder('ENUN');
          pc = 49;
          continue;
        case 49:
          s.placeholder('CURSOR_CHAR');
          pc = 50;
          continue;
        case 50:
          await s.stall(60);
          pc = 51;
          continue;
        case 51:
          s.placeholder('CURE');
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
          s.placeholder('MUSC');
          pc = 55;
          continue;
        case 55:
          await s.textShow(2534);
          pc = 56;
          continue;
        case 56:
          s.placeholder('TEXTEND');
          pc = 57;
          continue;
        case 57:
          s.placeholder('REMA');
          pc = 58;
          continue;
        case 58:
          s.placeholder('CHECK_EVENTID');
          pc = 59;
          continue;
        case 59:
          if (s.slotInt(0) == 12) { pc = 70; } else { pc = 60; }
          continue;
        case 60:
          s.placeholder('CHECK_EVENTID');
          pc = 61;
          continue;
        case 61:
          if (s.slotInt(0) == 12) { pc = 70; } else { pc = 62; }
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
          s.placeholder('TEXTEND');
          pc = 66;
          continue;
        case 66:
          s.placeholder('REMA');
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
          s.placeholder('GIVEITEMTO');
          pc = 70;
          continue;
        case 70:
          pc = 71;
          continue;
        case 71:
          s.placeholder('ENUT');
          pc = 72;
          continue;
        case 72:
          s.placeholder('MNCH');
          pc = 73;
          continue;
        case 73:
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
          s.placeholder('CHECK_HARD');
          pc = 1;
          continue;
        case 1:
          if (s.slotInt(0) != 12) { pc = 4; } else { pc = 2; }
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
          s.placeholder('CHECK_EVBIT');
          pc = 1;
          continue;
        case 1:
          if (s.slotInt(0) != 12) { pc = 5; } else { pc = 2; }
          continue;
        case 2:
          s.placeholder('CHECK_EVBIT');
          pc = 3;
          continue;
        case 3:
          if (s.slotInt(99) != 12) { pc = 5; } else { pc = 4; }
          continue;
        case 4:
          s.placeholder('FADI');
          pc = 5;
          continue;
        case 5:
          pc = 6;
          continue;
        case 6:
          s.placeholder('CLEAN');
          pc = 7;
          continue;
        case 7:
          s.placeholder('FADU');
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
          s.placeholder('CHECK_EVBIT');
          pc = 1;
          continue;
        case 1:
          if (s.slotInt(0) != 12) { pc = 3; } else { pc = 2; }
          continue;
        case 2:
          s.placeholder('FADI');
          pc = 3;
          continue;
        case 3:
          pc = 4;
          continue;
        case 4:
          s.placeholder('CHECK_EVBIT');
          pc = 5;
          continue;
        case 5:
          if (s.slotInt(1) == 12) { pc = 3; } else { pc = 6; }
          continue;
        case 6:
          s.placeholder('CHECK_CHAPTER_NUMBER');
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
          s.placeholder('LOMA');
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
          s.placeholder('EVBIT_MODIFY');
          pc = 1;
          continue;
        case 1:
          s.placeholder('ASMC');
          pc = 2;
          continue;
        case 2:
          s.placeholder('TUTORIALTEXTBOXSTART');
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
          s.placeholder('TEXTEND');
          pc = 6;
          continue;
        case 6:
          s.setSlot(7, 1);
          pc = 7;
          continue;
        case 7:
          if (s.slotInt(0) == 12) { pc = 8; } else { pc = 8; }
          continue;
        case 8:
          s.placeholder('MNCH');
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
          s.placeholder('MNC3');
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
          s.placeholder('BLE');
          pc = 2;
          continue;
        case 2:
          s.placeholder('SDEQUEUE');
          pc = 3;
          continue;
        case 3:
          s.placeholder('CURSOR_FLASHING');
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
          s.placeholder('CHECK_ALIVE');
          pc = 1;
          continue;
        case 1:
          if (s.slotInt(0) == 12) { pc = 6; } else { pc = 2; }
          continue;
        case 2:
          s.placeholder('CHECK_DEPLOYED');
          pc = 3;
          continue;
        case 3:
          if (s.slotInt(0) == 12) { pc = 6; } else { pc = 4; }
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
          if (s.slotInt(1) != 7) { pc = 24; } else { pc = 12; }
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
          if (s.slotInt(2) != 7) { pc = 24; } else { pc = 17; }
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
          if (s.slotInt(3) != 7) { pc = 24; } else { pc = 22; }
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
          s.placeholder('ENUN');
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
          if (s.slotInt(0) == 12) { pc = 3; } else { pc = 3; }
          continue;
        case 3:
          s.setSlot(7, 51);
          pc = 4;
          continue;
        case 4:
          if (s.slotInt(0) == 12) { pc = 5; } else { pc = 5; }
          continue;
        case 5:
          s.placeholder('RANDOMNUMBER');
          pc = 6;
          continue;
        case 6:
          s.placeholder('BLT');
          pc = 7;
          continue;
        case 7:
          pc = 8;
          continue;
        case 8:
          await s.call(Sym('data_085B9BBC', 360));
          pc = 9;
          continue;
        case 9:
          s.placeholder('GIVEITEMTO');
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
          if (s.slotInt(0) == 12) { pc = 7; } else { pc = 2; }
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
          if (s.slotInt(1) == 12) { pc = 14; } else { pc = 5; }
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
          s.placeholder('SET_HP');
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

/// `EventScr_MapSupportConversation`
Future<void> MapSupportConversation(Scene s) async {
    var pc = 0;
    while (true) {
      switch (pc) {
        case 0:
          s.placeholder('EVBIT_MODIFY');
          pc = 1;
          continue;
        case 1:
          if (s.slotInt(0) == 2) { pc = 4; } else { pc = 2; }
          continue;
        case 2:
          s.placeholder('MUSC');
          pc = 3;
          continue;
        case 3:
          pc = 6;
          continue;
        case 4:
          pc = 5;
          continue;
        case 5:
          s.placeholder('MUSI');
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
          s.placeholder('TEXTEND');
          pc = 10;
          continue;
        case 10:
          s.placeholder('REMA');
          pc = 11;
          continue;
        case 11:
          s.placeholder('NOTIFY');
          pc = 12;
          continue;
        case 12:
          s.placeholder('EVBIT_T');
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
          s.placeholder('CHECK_ALIVE');
          pc = 1;
          continue;
        case 1:
          if (s.slotInt(0) == 12) { pc = 5; } else { pc = 2; }
          continue;
        case 2:
          s.placeholder('CHECK_DEPLOYED');
          pc = 3;
          continue;
        case 3:
          if (s.slotInt(0) == 12) { pc = 5; } else { pc = 4; }
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
          s.placeholder('ENUN');
          pc = 8;
          continue;
        case 8:
          s.placeholder('REMU');
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
          s.placeholder('CHECK_TUTORIAL');
          pc = 4;
          continue;
        case 4:
          if (s.slotInt(0) != 12) { pc = 6; } else { pc = 5; }
          continue;
        case 5:
          s.placeholder('ASMC');
          pc = 6;
          continue;
        case 6:
          pc = 7;
          continue;
        case 7:
          s.placeholder('ENUT');
          pc = 8;
          continue;
        case 8:
          s.loadUnits(1, Sym('UnitDef_Event_PrologueAlly'));
          pc = 9;
          continue;
        case 9:
          s.placeholder('ENUN');
          pc = 10;
          continue;
        case 10:
          s.setSlot(1, 13);
          pc = 11;
          continue;
        case 11:
          s.placeholder('SET_HP');
          pc = 12;
          continue;
        case 12:
          s.placeholder('CURSOR_CHAR');
          pc = 13;
          continue;
        case 13:
          await s.stall(60);
          pc = 14;
          continue;
        case 14:
          s.placeholder('CURE');
          pc = 15;
          continue;
        case 15:
          s.placeholder('MUSI');
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
          s.placeholder('MUNO');
          pc = 20;
          continue;
        case 20:
          s.moveUnit('MOVE', [24, 2, 4, 4]);
          pc = 21;
          continue;
        case 21:
          s.placeholder('ENUN');
          pc = 22;
          continue;
        case 22:
          s.placeholder('CURSOR_CHAR');
          pc = 23;
          continue;
        case 23:
          await s.stall(60);
          pc = 24;
          continue;
        case 24:
          s.placeholder('CURE');
          pc = 25;
          continue;
        case 25:
          s.placeholder('TEXTSTART');
          pc = 26;
          continue;
        case 26:
          await s.textShow(2254);
          pc = 27;
          continue;
        case 27:
          s.placeholder('TEXTEND');
          pc = 28;
          continue;
        case 28:
          s.placeholder('REMA');
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
          s.placeholder('ENUN');
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
          s.placeholder('EVBIT_T');
          pc = 36;
          continue;
        case 36:
          return;
        default:
          return;
      }
    }
}

/// `EventScr_Prologue_EndingScene`
Future<void> Prologue_EndingScene(Scene s) async {
    s.placeholder('MUSC');
    s.setSlot(2, 37);
    await s.call(Sym('EventScr_SetBackground'));
    await s.textShow(2264);
    s.placeholder('TEXTEND');
    s.placeholder('FADI');
    s.placeholder('REMA');
    s.placeholder('ENUT');
    s.placeholder('ENUT');
    s.placeholder('ENUT');
    s.placeholder('ENUT');
    s.placeholder('ENUT');
    s.placeholder('ENUT');
    s.placeholder('ENUT');
    s.placeholder('ENUT');
    s.placeholder('ENUT');
    s.placeholder('ENUT');
    s.placeholder('ENUT');
    s.placeholder('MNC2');
    return;
}

/// `EventScr_Prologue_GiveRapier`
Future<void> Prologue_GiveRapier(Scene s) async {
    s.placeholder('CURSOR_CHAR');
    await s.stall(60);
    s.placeholder('CURE');
    s.placeholder('TEXTSTART');
    await s.textShow(2255);
    s.placeholder('TEXTEND');
    s.placeholder('REMA');
    await s.call(Sym('data_085B9BBC', 360));
    s.setSlot(3, 9);
    s.placeholder('GIVEITEMTO');
    s.setSlot(2, Sym('EventScr_Prologue_9EF828'));
    await s.call(Sym('EventScr_CallOnTutorialMode'));
    return;
}

/// `EventScr_Prologue_OneEnemyLeft`
Future<void> Prologue_OneEnemyLeft(Scene s) async {
    var pc = 0;
    while (true) {
      switch (pc) {
        case 0:
          s.placeholder('CHECK_ENEMIES');
          pc = 1;
          continue;
        case 1:
          s.setSlot(7, 1);
          pc = 2;
          continue;
        case 2:
          if (s.slotInt(0) != 12) { pc = 3; } else { pc = 3; }
          continue;
        case 3:
          s.placeholder('CURSOR_CHAR');
          pc = 4;
          continue;
        case 4:
          await s.stall(60);
          pc = 5;
          continue;
        case 5:
          s.placeholder('CURE');
          pc = 6;
          continue;
        case 6:
          s.placeholder('TEXTSTART');
          pc = 7;
          continue;
        case 7:
          s.placeholder('EVENT_WORD_SYM');
          pc = 8;
          continue;
        case 8:
          s.placeholder('TEXTEND');
          pc = 9;
          continue;
        case 9:
          s.placeholder('REMA');
          pc = 10;
          continue;
        case 10:
          s.placeholder('ENUF');
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
          s.placeholder('ENUF');
          pc = 16;
          continue;
        case 16:
          pc = 17;
          continue;
        case 17:
          s.placeholder('EVBIT_T');
          pc = 18;
          continue;
        case 18:
          return;
        default:
          return;
      }
    }
}

/// `EventScr_Prologue_RenaisThroneCutscene`
Future<void> Prologue_RenaisThroneCutscene(Scene s) async {
    s.setSlot(11, 655374);
    s.placeholder('LOMA');
    s.loadUnits(2, Sym('UnitDef_Event_PrologueThroneRoomUnits'));
    s.placeholder('ENUN');
    s.placeholder('FADU');
    s.placeholder('MUSC');
    s.placeholder('BROWNBOXTEXT');
    s.loadUnits(1, Sym('UnitDef_Event_PrologueMessager'));
    s.placeholder('ENUN');
    s.placeholder('CAMERA');
    s.placeholder('CURSOR_CHAR');
    await s.stall(60);
    s.placeholder('CURE');
    s.placeholder('TEXTSTART');
    await s.textShow(2243);
    s.placeholder('TEXTEND');
    s.placeholder('REMA');
    s.moveUnit('MOVE', [0, 15, 13, 11]);
    s.placeholder('ENUN');
    s.placeholder('DISA');
    s.moveUnit('MOVE_1STEP', [0, 1, 0]);
    s.placeholder('ENUN');
    s.placeholder('CURSOR_CHAR');
    await s.stall(60);
    s.placeholder('CURE');
    s.placeholder('TEXTSTART');
    await s.textShow(2244);
    s.placeholder('TEXTEND');
    s.placeholder('REMA');
    s.moveUnit('MOVEONTO', [0, 2, 1]);
    s.placeholder('ENUN');
    s.placeholder('DISA');
    s.placeholder('CURSOR_CHAR');
    await s.stall(60);
    s.placeholder('CURE');
    s.placeholder('TEXTSTART');
    await s.textShow(2245);
    s.placeholder('TEXTEND');
    s.placeholder('REMA');
    s.moveUnit('MOVE', [0, 2, 13, 11]);
    s.setSlot(13, 0);
    s.setSlot(1, 268);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 0);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 716);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 0);
    s.placeholder('SENQUEUE1');
    s.moveUnit('MOVE_DEFINED', [4]);
    s.placeholder('ENUN');
    s.placeholder('DISA');
    s.placeholder('DISA');
    s.moveUnit('MOVE', [0, 5, 11, 4]);
    s.moveUnit('MOVE', [0, 6, 15, 4]);
    s.placeholder('ENUN');
    s.moveUnit('MOVE_1STEP', [0, 5, 1]);
    s.moveUnit('MOVE_1STEP', [0, 6, 0]);
    s.placeholder('ENUN');
    s.loadUnits(1, Sym('UnitDef_Event_PrologueGradoShamans'));
    s.placeholder('ENUN');
    s.loadUnits(1, Sym('UnitDef_Event_PrologueGradoCavalry'));
    s.placeholder('ENUN');
    s.loadUnits(1, Sym('UnitDef_Event_PrologueGradoRoyals'));
    s.placeholder('ENUN');
    s.placeholder('CURSOR_CHAR');
    await s.stall(60);
    s.placeholder('CURE');
    s.placeholder('TEXTSTART');
    await s.textShow(2246);
    s.placeholder('TEXTEND');
    s.placeholder('FADI');
    s.placeholder('REMA');
    s.placeholder('EVBIT_F');
    s.placeholder('CLEA');
    s.placeholder('CLEE');
    s.placeholder('CLEN');
    s.setSlot(11, 0);
    s.placeholder('LOMA');
    s.placeholder('FADU');
    s.loadUnits(2, Sym('UnitDef_Event_PrologueEscapees'));
    s.placeholder('ENUN');
    s.placeholder('CURSOR_CHAR');
    await s.stall(60);
    s.placeholder('CURE');
    s.setSlot(2, 37);
    s.setSlot(3, 2247);
    await s.call(Sym('Event_TextWithBG'));
    s.setSlot(13, 0);
    s.setSlot(1, 260);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 0);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 132);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 0);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 128);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 0);
    s.placeholder('SENQUEUE1');
    s.moveUnit('MOVE_DEFINED', [4]);
    s.placeholder('ENUN');
    s.placeholder('DISA');
    s.placeholder('CURSOR_CHAR');
    await s.stall(60);
    s.placeholder('CURE');
    s.setSlot(2, 37);
    s.setSlot(3, 2248);
    await s.call(Sym('Event_TextWithBG'));
    s.loadUnits(1, Sym('UnitDef_Event_PrologueValterGroup'));
    s.placeholder('ENUN');
    s.moveUnit('MOVE_1STEP', [0, 2, 1]);
    s.placeholder('ENUN');
    s.moveUnit('MOVE_1STEP', [0, 1, 0]);
    s.placeholder('ENUN');
    s.placeholder('CURSOR_CHAR');
    await s.stall(60);
    s.placeholder('CURE');
    s.setSlot(2, 37);
    s.setSlot(3, 2249);
    await s.call(Sym('Event_TextWithBG'));
    s.moveUnit('MOVE_1STEP', [0, 69, 0]);
    s.placeholder('ENUN');
    s.setSlot(13, 0);
    s.setSlot(1, 131072);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 1);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 4294967295);
    s.placeholder('SENQUEUE1');
    s.placeholder('FIGHT');
    s.placeholder('CURSOR_CHAR');
    await s.stall(60);
    s.placeholder('CURE');
    s.placeholder('TEXTSTART');
    await s.textShow(2251);
    s.placeholder('TEXTEND');
    s.placeholder('REMA');
    s.moveUnit('MOVE_1STEP', [8, 2, 0]);
    s.placeholder('ENUN');
    s.placeholder('DISA');
    s.setSlot(13, 0);
    s.setSlot(1, 98564);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 0);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 98436);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 0);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 98432);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 0);
    s.placeholder('SENQUEUE1');
    s.moveUnit('MOVE_DEFINED', [2]);
    s.placeholder('ENUN');
    s.placeholder('DISA');
    s.placeholder('CURSOR_CHAR');
    await s.stall(60);
    s.placeholder('CURE');
    s.placeholder('TEXTSTART');
    await s.textShow(2252);
    s.placeholder('TEXTEND');
    s.placeholder('REMA');
    s.placeholder('FADI');
    s.placeholder('EVBIT_F');
    s.placeholder('CLEA');
    s.placeholder('CLEE');
    s.placeholder('CLEN');
    s.setSlot(11, 0);
    s.placeholder('LOMA');
    s.placeholder('FADU');
    return;
}

/// `EventScr_Prologue_TutEirikaAttack`
Future<void> Prologue_TutEirikaAttack(Scene s) async {
    s.placeholder('TUTORIALTEXTBOXSTART');
    s.setSlot(11, 4294967295);
    await s.textShow(2275);
    s.placeholder('TEXTEND');
    s.placeholder('REMA');
    s.placeholder('CURSOR_FLASHING_CHAR');
    await s.stall(60);
    s.placeholder('CURE');
    s.setSlot(13, 0);
    s.setSlot(1, 0);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 1);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 65536);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 4294967295);
    s.placeholder('SENQUEUE1');
    s.placeholder('FIGHT_SCRIPT');
    s.placeholder('EvtEnqueueConditionalTutCall');
    return;
}

/// `EventScr_Prologue_TutMessageTurn2`
Future<void> Prologue_TutMessageTurn2(Scene s) async {
    s.placeholder('CURSOR_CHAR');
    await s.stall(60);
    s.placeholder('CURE');
    s.placeholder('TEXTSTART');
    await s.textShow(2257);
    s.placeholder('TEXTEND');
    s.placeholder('REMA');
    s.setSlot(13, 0);
    s.setSlot(1, 0);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 131073);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 0);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 4294967295);
    s.placeholder('SENQUEUE1');
    s.placeholder('FIGHT_SCRIPT');
    s.placeholder('TUTORIALTEXTBOXSTART');
    s.setSlot(11, 4294967295);
    await s.textShow(2274);
    s.placeholder('TEXTEND');
    s.placeholder('REMA');
    s.placeholder('ENUF');
    s.placeholder('ENUT');
    s.placeholder('CURSOR_FLASHING_CHAR');
    await s.stall(60);
    s.placeholder('CURE');
    s.placeholder('EvtEnqueueConditionalTutCall');
    return;
}

/// `EventScr_Prologue_Tutorial0`
Future<void> Prologue_Tutorial0(Scene s) async {
    s.placeholder('EVBIT_T');
    s.setSlot(13, 0);
    s.setSlot(1, 1);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 327684);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 2267);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 524376);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 2266);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 524376);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, Sym('EventScr_Prologue_Tutorial1'));
    s.placeholder('SENQUEUE1');
    s.setSlot(1, Sym('EventScr_Prologue_Tutorial0'));
    s.placeholder('SENQUEUE1');
    await s.call(Sym('EventScr_Tutorial_Exec0'));
    return;
}

/// `EventScr_Prologue_Tutorial1`
Future<void> Prologue_Tutorial1(Scene s) async {
    s.placeholder('EVBIT_T');
    s.placeholder('IGNORE_KEYS');
    s.setSlot(13, 0);
    s.setSlot(1, 327684);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 2268);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 524376);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, Sym('EventScr_Prologue_Tutorial2'));
    s.placeholder('SENQUEUE1');
    s.setSlot(1, Sym('EventScr_Prologue_Tutorial1'));
    s.placeholder('SENQUEUE1');
    await s.call(Sym('EventScr_Tutorial_Exec1'));
    s.placeholder('DISABLEOPTIONS');
    s.placeholder('IGNORE_KEYS');
    return;
}

/// `EventScr_Prologue_Tutorial4`
Future<void> Prologue_Tutorial4(Scene s) async {
    s.placeholder('EVBIT_T');
    s.placeholder('IGNORE_KEYS');
    s.setSlot(13, 0);
    s.setSlot(1, 1);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 327684);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 2270);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 524376);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 2271);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 524376);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, Sym('EventScr_Prologue_Tutorial5'));
    s.placeholder('SENQUEUE1');
    s.setSlot(1, Sym('EventScr_Prologue_Tutorial4'));
    s.placeholder('SENQUEUE1');
    await s.call(Sym('EventScr_Tutorial_Exec0'));
    s.placeholder('IGNORE_KEYS');
    return;
}

/// `EventScr_Prologue_TutorialA`
Future<void> Prologue_TutorialA(Scene s) async {
    s.placeholder('EVBIT_T');
    s.setSlot(13, 0);
    s.setSlot(1, 1);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 393224);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 2277);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 524376);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 2276);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 524376);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, Sym('EventScr_Prologue_TutorialB'));
    s.placeholder('SENQUEUE1');
    s.setSlot(1, Sym('EventScr_Prologue_TutorialA'));
    s.placeholder('SENQUEUE1');
    await s.call(Sym('EventScr_Tutorial_Exec0'));
    return;
}

/// `EventScr_Prologue_TutorialB`
Future<void> Prologue_TutorialB(Scene s) async {
    s.placeholder('EVBIT_T');
    s.placeholder('IGNORE_KEYS');
    s.setSlot(13, 0);
    s.setSlot(1, 393224);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 2277);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 524376);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, Sym('EventScr_Prologue_TutorialC'));
    s.placeholder('SENQUEUE1');
    s.setSlot(1, Sym('EventScr_Prologue_TutorialB'));
    s.placeholder('SENQUEUE1');
    await s.call(Sym('EventScr_Tutorial_Exec1'));
    s.placeholder('DISABLEOPTIONS');
    s.placeholder('IGNORE_KEYS');
    return;
}

/// `EventScr_Ruin_37`
Future<void> Ruin_37(Scene s) async {
    var pc = 0;
    while (true) {
      switch (pc) {
        case 0:
          s.placeholder('CHECK_TURNS');
          pc = 1;
          continue;
        case 1:
          s.setSlot(1, 1);
          pc = 2;
          continue;
        case 2:
          if (s.slotInt(0) == 12) { pc = 19; } else { pc = 3; }
          continue;
        case 3:
          s.placeholder('CHECK_TURNS');
          pc = 4;
          continue;
        case 4:
          s.setSlot(1, 10);
          pc = 5;
          continue;
        case 5:
          if (s.slotInt(0) == 12) { pc = 19; } else { pc = 6; }
          continue;
        case 6:
          s.placeholder('CHECK_TURNS');
          pc = 7;
          continue;
        case 7:
          s.setSlot(1, 20);
          pc = 8;
          continue;
        case 8:
          if (s.slotInt(0) == 12) { pc = 19; } else { pc = 9; }
          continue;
        case 9:
          pc = 19;
          continue;
        case 10:
          pc = 11;
          continue;
        case 11:
          s.placeholder('CAMERA');
          pc = 12;
          continue;
        case 12:
          await s.stall(15);
          pc = 13;
          continue;
        case 13:
          s.placeholder('SOUN');
          pc = 14;
          continue;
        case 14:
          s.placeholder('TILECHANGE');
          pc = 15;
          continue;
        case 15:
          s.placeholder('CAMERA2');
          pc = 16;
          continue;
        case 16:
          await s.stall(15);
          pc = 17;
          continue;
        case 17:
          s.placeholder('SOUN');
          pc = 18;
          continue;
        case 18:
          s.placeholder('TILECHANGE');
          pc = 19;
          continue;
        case 19:
          pc = 20;
          continue;
        case 20:
          s.placeholder('EVBIT_T');
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
          s.placeholder('CHECK_TURNS');
          pc = 1;
          continue;
        case 1:
          s.setSlot(1, 6);
          pc = 2;
          continue;
        case 2:
          if (s.slotInt(0) == 12) { pc = 16; } else { pc = 3; }
          continue;
        case 3:
          s.placeholder('CHECK_TURNS');
          pc = 4;
          continue;
        case 4:
          s.setSlot(1, 15);
          pc = 5;
          continue;
        case 5:
          if (s.slotInt(0) == 12) { pc = 16; } else { pc = 6; }
          continue;
        case 6:
          pc = 16;
          continue;
        case 7:
          pc = 8;
          continue;
        case 8:
          s.placeholder('CAMERA');
          pc = 9;
          continue;
        case 9:
          await s.stall(15);
          pc = 10;
          continue;
        case 10:
          s.placeholder('SOUN');
          pc = 11;
          continue;
        case 11:
          s.placeholder('TILEREVERT');
          pc = 12;
          continue;
        case 12:
          s.placeholder('CAMERA2');
          pc = 13;
          continue;
        case 13:
          await s.stall(15);
          pc = 14;
          continue;
        case 14:
          s.placeholder('SOUN');
          pc = 15;
          continue;
        case 15:
          s.placeholder('TILEREVERT');
          pc = 16;
          continue;
        case 16:
          pc = 17;
          continue;
        case 17:
          s.placeholder('EVBIT_T');
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
          s.placeholder('CHECK_TURNS');
          pc = 1;
          continue;
        case 1:
          s.setSlot(1, 2);
          pc = 2;
          continue;
        case 2:
          if (s.slotInt(0) == 12) { pc = 26; } else { pc = 3; }
          continue;
        case 3:
          s.placeholder('CHECK_TURNS');
          pc = 4;
          continue;
        case 4:
          s.setSlot(1, 8);
          pc = 5;
          continue;
        case 5:
          if (s.slotInt(0) == 12) { pc = 26; } else { pc = 6; }
          continue;
        case 6:
          s.placeholder('CHECK_TURNS');
          pc = 7;
          continue;
        case 7:
          s.setSlot(1, 14);
          pc = 8;
          continue;
        case 8:
          if (s.slotInt(0) == 12) { pc = 26; } else { pc = 9; }
          continue;
        case 9:
          s.placeholder('CHECK_TURNS');
          pc = 10;
          continue;
        case 10:
          s.setSlot(1, 20);
          pc = 11;
          continue;
        case 11:
          if (s.slotInt(0) == 12) { pc = 26; } else { pc = 12; }
          continue;
        case 12:
          pc = 26;
          continue;
        case 13:
          pc = 14;
          continue;
        case 14:
          s.placeholder('CAMERA2');
          pc = 15;
          continue;
        case 15:
          await s.stall(15);
          pc = 16;
          continue;
        case 16:
          s.placeholder('SOUN');
          pc = 17;
          continue;
        case 17:
          s.placeholder('TILECHANGE');
          pc = 18;
          continue;
        case 18:
          s.placeholder('CAMERA2');
          pc = 19;
          continue;
        case 19:
          await s.stall(15);
          pc = 20;
          continue;
        case 20:
          s.placeholder('SOUN');
          pc = 21;
          continue;
        case 21:
          s.placeholder('TILECHANGE');
          pc = 22;
          continue;
        case 22:
          s.placeholder('CAMERA');
          pc = 23;
          continue;
        case 23:
          await s.stall(15);
          pc = 24;
          continue;
        case 24:
          s.placeholder('SOUN');
          pc = 25;
          continue;
        case 25:
          s.placeholder('TILECHANGE');
          pc = 26;
          continue;
        case 26:
          pc = 27;
          continue;
        case 27:
          s.placeholder('EVBIT_T');
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
          s.placeholder('CHECK_TURNS');
          pc = 1;
          continue;
        case 1:
          s.setSlot(1, 5);
          pc = 2;
          continue;
        case 2:
          if (s.slotInt(0) == 12) { pc = 23; } else { pc = 3; }
          continue;
        case 3:
          s.placeholder('CHECK_TURNS');
          pc = 4;
          continue;
        case 4:
          s.setSlot(1, 11);
          pc = 5;
          continue;
        case 5:
          if (s.slotInt(0) == 12) { pc = 23; } else { pc = 6; }
          continue;
        case 6:
          s.placeholder('CHECK_TURNS');
          pc = 7;
          continue;
        case 7:
          s.setSlot(1, 17);
          pc = 8;
          continue;
        case 8:
          if (s.slotInt(0) == 12) { pc = 23; } else { pc = 9; }
          continue;
        case 9:
          pc = 23;
          continue;
        case 10:
          pc = 11;
          continue;
        case 11:
          s.placeholder('CAMERA2');
          pc = 12;
          continue;
        case 12:
          await s.stall(15);
          pc = 13;
          continue;
        case 13:
          s.placeholder('SOUN');
          pc = 14;
          continue;
        case 14:
          s.placeholder('TILEREVERT');
          pc = 15;
          continue;
        case 15:
          s.placeholder('CAMERA2');
          pc = 16;
          continue;
        case 16:
          await s.stall(15);
          pc = 17;
          continue;
        case 17:
          s.placeholder('SOUN');
          pc = 18;
          continue;
        case 18:
          s.placeholder('TILEREVERT');
          pc = 19;
          continue;
        case 19:
          s.placeholder('CAMERA');
          pc = 20;
          continue;
        case 20:
          await s.stall(15);
          pc = 21;
          continue;
        case 21:
          s.placeholder('SOUN');
          pc = 22;
          continue;
        case 22:
          s.placeholder('TILEREVERT');
          pc = 23;
          continue;
        case 23:
          pc = 24;
          continue;
        case 24:
          s.placeholder('EVBIT_T');
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
          s.placeholder('CHECK_TURNS');
          pc = 1;
          continue;
        case 1:
          s.setSlot(1, 5);
          pc = 2;
          continue;
        case 2:
          if (s.slotInt(0) == 12) { pc = 19; } else { pc = 3; }
          continue;
        case 3:
          s.placeholder('CHECK_TURNS');
          pc = 4;
          continue;
        case 4:
          s.setSlot(1, 13);
          pc = 5;
          continue;
        case 5:
          if (s.slotInt(0) == 12) { pc = 19; } else { pc = 6; }
          continue;
        case 6:
          s.placeholder('CHECK_TURNS');
          pc = 7;
          continue;
        case 7:
          s.setSlot(1, 20);
          pc = 8;
          continue;
        case 8:
          if (s.slotInt(0) == 12) { pc = 19; } else { pc = 9; }
          continue;
        case 9:
          pc = 19;
          continue;
        case 10:
          pc = 11;
          continue;
        case 11:
          s.placeholder('CAMERA');
          pc = 12;
          continue;
        case 12:
          await s.stall(15);
          pc = 13;
          continue;
        case 13:
          s.placeholder('SOUN');
          pc = 14;
          continue;
        case 14:
          s.placeholder('TILECHANGE');
          pc = 15;
          continue;
        case 15:
          s.placeholder('CAMERA');
          pc = 16;
          continue;
        case 16:
          await s.stall(15);
          pc = 17;
          continue;
        case 17:
          s.placeholder('SOUN');
          pc = 18;
          continue;
        case 18:
          s.placeholder('TILECHANGE');
          pc = 19;
          continue;
        case 19:
          pc = 20;
          continue;
        case 20:
          s.placeholder('EVBIT_T');
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
          s.placeholder('CHECK_TURNS');
          pc = 1;
          continue;
        case 1:
          s.setSlot(1, 9);
          pc = 2;
          continue;
        case 2:
          if (s.slotInt(0) == 12) { pc = 16; } else { pc = 3; }
          continue;
        case 3:
          s.placeholder('CHECK_TURNS');
          pc = 4;
          continue;
        case 4:
          s.setSlot(1, 17);
          pc = 5;
          continue;
        case 5:
          if (s.slotInt(0) == 12) { pc = 16; } else { pc = 6; }
          continue;
        case 6:
          pc = 16;
          continue;
        case 7:
          pc = 8;
          continue;
        case 8:
          s.placeholder('CAMERA');
          pc = 9;
          continue;
        case 9:
          await s.stall(15);
          pc = 10;
          continue;
        case 10:
          s.placeholder('SOUN');
          pc = 11;
          continue;
        case 11:
          s.placeholder('TILEREVERT');
          pc = 12;
          continue;
        case 12:
          s.placeholder('CAMERA');
          pc = 13;
          continue;
        case 13:
          await s.stall(15);
          pc = 14;
          continue;
        case 14:
          s.placeholder('SOUN');
          pc = 15;
          continue;
        case 15:
          s.placeholder('TILEREVERT');
          pc = 16;
          continue;
        case 16:
          pc = 17;
          continue;
        case 17:
          s.placeholder('EVBIT_T');
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
          s.placeholder('CHECK_TURNS');
          pc = 1;
          continue;
        case 1:
          s.setSlot(1, 1);
          pc = 2;
          continue;
        case 2:
          if (s.slotInt(0) == 12) { pc = 28; } else { pc = 3; }
          continue;
        case 3:
          s.placeholder('CHECK_TURNS');
          pc = 4;
          continue;
        case 4:
          s.setSlot(1, 5);
          pc = 5;
          continue;
        case 5:
          if (s.slotInt(0) == 12) { pc = 28; } else { pc = 6; }
          continue;
        case 6:
          s.placeholder('CHECK_TURNS');
          pc = 7;
          continue;
        case 7:
          s.setSlot(1, 9);
          pc = 8;
          continue;
        case 8:
          if (s.slotInt(0) == 12) { pc = 28; } else { pc = 9; }
          continue;
        case 9:
          s.placeholder('CHECK_TURNS');
          pc = 10;
          continue;
        case 10:
          s.setSlot(1, 13);
          pc = 11;
          continue;
        case 11:
          if (s.slotInt(0) == 12) { pc = 28; } else { pc = 12; }
          continue;
        case 12:
          s.placeholder('CHECK_TURNS');
          pc = 13;
          continue;
        case 13:
          s.setSlot(1, 17);
          pc = 14;
          continue;
        case 14:
          if (s.slotInt(0) == 12) { pc = 28; } else { pc = 15; }
          continue;
        case 15:
          s.placeholder('CHECK_TURNS');
          pc = 16;
          continue;
        case 16:
          s.setSlot(1, 20);
          pc = 17;
          continue;
        case 17:
          if (s.slotInt(0) == 12) { pc = 28; } else { pc = 18; }
          continue;
        case 18:
          pc = 28;
          continue;
        case 19:
          pc = 20;
          continue;
        case 20:
          s.placeholder('CAMERA2');
          pc = 21;
          continue;
        case 21:
          await s.stall(15);
          pc = 22;
          continue;
        case 22:
          s.placeholder('SOUN');
          pc = 23;
          continue;
        case 23:
          s.placeholder('TILECHANGE');
          pc = 24;
          continue;
        case 24:
          s.placeholder('CAMERA2');
          pc = 25;
          continue;
        case 25:
          await s.stall(15);
          pc = 26;
          continue;
        case 26:
          s.placeholder('SOUN');
          pc = 27;
          continue;
        case 27:
          s.placeholder('TILECHANGE');
          pc = 28;
          continue;
        case 28:
          pc = 29;
          continue;
        case 29:
          s.placeholder('EVBIT_T');
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
          s.placeholder('CHECK_TURNS');
          pc = 1;
          continue;
        case 1:
          s.setSlot(1, 6);
          pc = 2;
          continue;
        case 2:
          if (s.slotInt(0) == 12) { pc = 18; } else { pc = 3; }
          continue;
        case 3:
          s.placeholder('CHECK_TURNS');
          pc = 4;
          continue;
        case 4:
          s.setSlot(1, 12);
          pc = 5;
          continue;
        case 5:
          if (s.slotInt(0) == 12) { pc = 18; } else { pc = 6; }
          continue;
        case 6:
          s.placeholder('CHECK_TURNS');
          pc = 7;
          continue;
        case 7:
          s.setSlot(1, 18);
          pc = 8;
          continue;
        case 8:
          if (s.slotInt(0) == 12) { pc = 18; } else { pc = 9; }
          continue;
        case 9:
          s.placeholder('CHECK_TURNS');
          pc = 10;
          continue;
        case 10:
          s.setSlot(1, 20);
          pc = 11;
          continue;
        case 11:
          if (s.slotInt(0) == 12) { pc = 18; } else { pc = 12; }
          continue;
        case 12:
          pc = 18;
          continue;
        case 13:
          pc = 14;
          continue;
        case 14:
          s.placeholder('CAMERA');
          pc = 15;
          continue;
        case 15:
          await s.stall(15);
          pc = 16;
          continue;
        case 16:
          s.placeholder('SOUN');
          pc = 17;
          continue;
        case 17:
          s.placeholder('TILECHANGE');
          pc = 18;
          continue;
        case 18:
          pc = 19;
          continue;
        case 19:
          s.placeholder('EVBIT_T');
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
          s.placeholder('CHECK_TURNS');
          pc = 1;
          continue;
        case 1:
          s.setSlot(1, 7);
          pc = 2;
          continue;
        case 2:
          if (s.slotInt(0) == 12) { pc = 15; } else { pc = 3; }
          continue;
        case 3:
          s.placeholder('CHECK_TURNS');
          pc = 4;
          continue;
        case 4:
          s.setSlot(1, 13);
          pc = 5;
          continue;
        case 5:
          if (s.slotInt(0) == 12) { pc = 15; } else { pc = 6; }
          continue;
        case 6:
          s.placeholder('CHECK_TURNS');
          pc = 7;
          continue;
        case 7:
          s.setSlot(1, 19);
          pc = 8;
          continue;
        case 8:
          if (s.slotInt(0) == 12) { pc = 15; } else { pc = 9; }
          continue;
        case 9:
          pc = 15;
          continue;
        case 10:
          pc = 11;
          continue;
        case 11:
          s.placeholder('CAMERA');
          pc = 12;
          continue;
        case 12:
          await s.stall(15);
          pc = 13;
          continue;
        case 13:
          s.placeholder('SOUN');
          pc = 14;
          continue;
        case 14:
          s.placeholder('TILEREVERT');
          pc = 15;
          continue;
        case 15:
          pc = 16;
          continue;
        case 16:
          s.placeholder('EVBIT_T');
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
          s.placeholder('FADI');
          pc = 1;
          continue;
        case 1:
          s.placeholder('CHECK_EVBIT');
          pc = 2;
          continue;
        case 2:
          if (s.slotInt(32898) != 12) { pc = 3; } else { pc = 3; }
          continue;
        case 3:
          s.setSlot(11, 0);
          pc = 4;
          continue;
        case 4:
          s.placeholder('LOMA');
          pc = 5;
          continue;
        case 5:
          s.placeholder('FADU');
          pc = 6;
          continue;
        case 6:
          s.placeholder('BROWNBOXTEXT');
          pc = 7;
          continue;
        case 7:
          s.placeholder('STAL1');
          pc = 8;
          continue;
        case 8:
          s.placeholder('FADI');
          pc = 9;
          continue;
        case 9:
          pc = 10;
          continue;
        case 10:
          s.placeholder('CHECK_EVBIT');
          pc = 11;
          continue;
        case 11:
          if (s.slotInt(32899) != 12) { pc = 12; } else { pc = 12; }
          continue;
        case 12:
          s.setSlot(11, 0);
          pc = 13;
          continue;
        case 13:
          s.placeholder('LOMA');
          pc = 14;
          continue;
        case 14:
          s.placeholder('FADU');
          pc = 15;
          continue;
        case 15:
          s.placeholder('BROWNBOXTEXT');
          pc = 16;
          continue;
        case 16:
          s.placeholder('STAL1');
          pc = 17;
          continue;
        case 17:
          s.placeholder('FADI');
          pc = 18;
          continue;
        case 18:
          pc = 19;
          continue;
        case 19:
          s.placeholder('CHECK_EVBIT');
          pc = 20;
          continue;
        case 20:
          if (s.slotInt(32900) != 12) { pc = 21; } else { pc = 21; }
          continue;
        case 21:
          s.setSlot(11, 0);
          pc = 22;
          continue;
        case 22:
          s.placeholder('LOMA');
          pc = 23;
          continue;
        case 23:
          s.placeholder('FADU');
          pc = 24;
          continue;
        case 24:
          s.placeholder('BROWNBOXTEXT');
          pc = 25;
          continue;
        case 25:
          s.placeholder('STAL1');
          pc = 26;
          continue;
        case 26:
          s.placeholder('FADI');
          pc = 27;
          continue;
        case 27:
          pc = 28;
          continue;
        case 28:
          s.placeholder('CHECK_EVBIT');
          pc = 29;
          continue;
        case 29:
          if (s.slotInt(32901) != 12) { pc = 30; } else { pc = 30; }
          continue;
        case 30:
          s.setSlot(11, 0);
          pc = 31;
          continue;
        case 31:
          s.placeholder('LOMA');
          pc = 32;
          continue;
        case 32:
          s.placeholder('FADU');
          pc = 33;
          continue;
        case 33:
          s.placeholder('BROWNBOXTEXT');
          pc = 34;
          continue;
        case 34:
          s.placeholder('STAL1');
          pc = 35;
          continue;
        case 35:
          s.placeholder('FADI');
          pc = 36;
          continue;
        case 36:
          pc = 37;
          continue;
        case 37:
          s.placeholder('CHECK_EVBIT');
          pc = 38;
          continue;
        case 38:
          if (s.slotInt(32902) != 12) { pc = 39; } else { pc = 39; }
          continue;
        case 39:
          s.setSlot(11, 0);
          pc = 40;
          continue;
        case 40:
          s.placeholder('LOMA');
          pc = 41;
          continue;
        case 41:
          s.placeholder('FADU');
          pc = 42;
          continue;
        case 42:
          s.placeholder('BROWNBOXTEXT');
          pc = 43;
          continue;
        case 43:
          s.placeholder('STAL1');
          pc = 44;
          continue;
        case 44:
          s.placeholder('FADI');
          pc = 45;
          continue;
        case 45:
          pc = 46;
          continue;
        case 46:
          s.placeholder('CHECK_EVBIT');
          pc = 47;
          continue;
        case 47:
          if (s.slotInt(32903) != 12) { pc = 48; } else { pc = 48; }
          continue;
        case 48:
          s.setSlot(11, 0);
          pc = 49;
          continue;
        case 49:
          s.placeholder('LOMA');
          pc = 50;
          continue;
        case 50:
          s.placeholder('FADU');
          pc = 51;
          continue;
        case 51:
          s.placeholder('BROWNBOXTEXT');
          pc = 52;
          continue;
        case 52:
          s.placeholder('STAL1');
          pc = 53;
          continue;
        case 53:
          s.placeholder('FADI');
          pc = 54;
          continue;
        case 54:
          pc = 55;
          continue;
        case 55:
          s.placeholder('CHECK_EVBIT');
          pc = 56;
          continue;
        case 56:
          if (s.slotInt(32904) != 12) { pc = 57; } else { pc = 57; }
          continue;
        case 57:
          s.setSlot(11, 0);
          pc = 58;
          continue;
        case 58:
          s.placeholder('LOMA');
          pc = 59;
          continue;
        case 59:
          s.placeholder('FADU');
          pc = 60;
          continue;
        case 60:
          s.placeholder('BROWNBOXTEXT');
          pc = 61;
          continue;
        case 61:
          s.placeholder('STAL1');
          pc = 62;
          continue;
        case 62:
          s.placeholder('FADI');
          pc = 63;
          continue;
        case 63:
          pc = 64;
          continue;
        case 64:
          s.placeholder('CHECK_EVBIT');
          pc = 65;
          continue;
        case 65:
          if (s.slotInt(32905) != 12) { pc = 66; } else { pc = 66; }
          continue;
        case 66:
          s.setSlot(11, 0);
          pc = 67;
          continue;
        case 67:
          s.placeholder('LOMA');
          pc = 68;
          continue;
        case 68:
          s.placeholder('FADU');
          pc = 69;
          continue;
        case 69:
          s.placeholder('BROWNBOXTEXT');
          pc = 70;
          continue;
        case 70:
          s.placeholder('STAL1');
          pc = 71;
          continue;
        case 71:
          s.placeholder('FADI');
          pc = 72;
          continue;
        case 72:
          pc = 73;
          continue;
        case 73:
          s.placeholder('CHECK_EVBIT');
          pc = 74;
          continue;
        case 74:
          if (s.slotInt(32906) != 12) { pc = 75; } else { pc = 75; }
          continue;
        case 75:
          s.setSlot(11, 0);
          pc = 76;
          continue;
        case 76:
          s.placeholder('LOMA');
          pc = 77;
          continue;
        case 77:
          s.placeholder('FADU');
          pc = 78;
          continue;
        case 78:
          s.placeholder('BROWNBOXTEXT');
          pc = 79;
          continue;
        case 79:
          s.placeholder('STAL1');
          pc = 80;
          continue;
        case 80:
          s.placeholder('FADI');
          pc = 81;
          continue;
        case 81:
          pc = 82;
          continue;
        case 82:
          s.placeholder('CHECK_EVBIT');
          pc = 83;
          continue;
        case 83:
          if (s.slotInt(32907) != 12) { pc = 84; } else { pc = 84; }
          continue;
        case 84:
          s.setSlot(11, 0);
          pc = 85;
          continue;
        case 85:
          s.placeholder('LOMA');
          pc = 86;
          continue;
        case 86:
          s.placeholder('FADU');
          pc = 87;
          continue;
        case 87:
          s.placeholder('BROWNBOXTEXT');
          pc = 88;
          continue;
        case 88:
          s.placeholder('STAL1');
          pc = 89;
          continue;
        case 89:
          s.placeholder('FADI');
          pc = 90;
          continue;
        case 90:
          pc = 91;
          continue;
        case 91:
          s.placeholder('CHECK_EVBIT');
          pc = 92;
          continue;
        case 92:
          if (s.slotInt(32908) != 12) { pc = 93; } else { pc = 93; }
          continue;
        case 93:
          s.setSlot(11, 0);
          pc = 94;
          continue;
        case 94:
          s.placeholder('LOMA');
          pc = 95;
          continue;
        case 95:
          s.placeholder('FADU');
          pc = 96;
          continue;
        case 96:
          s.placeholder('BROWNBOXTEXT');
          pc = 97;
          continue;
        case 97:
          s.placeholder('STAL1');
          pc = 98;
          continue;
        case 98:
          s.placeholder('FADI');
          pc = 99;
          continue;
        case 99:
          pc = 100;
          continue;
        case 100:
          s.placeholder('CHECK_EVBIT');
          pc = 101;
          continue;
        case 101:
          if (s.slotInt(32909) != 12) { pc = 102; } else { pc = 102; }
          continue;
        case 102:
          s.setSlot(11, 0);
          pc = 103;
          continue;
        case 103:
          s.placeholder('LOMA');
          pc = 104;
          continue;
        case 104:
          s.placeholder('FADU');
          pc = 105;
          continue;
        case 105:
          s.placeholder('BROWNBOXTEXT');
          pc = 106;
          continue;
        case 106:
          s.placeholder('STAL1');
          pc = 107;
          continue;
        case 107:
          s.placeholder('FADI');
          pc = 108;
          continue;
        case 108:
          pc = 109;
          continue;
        case 109:
          s.placeholder('CHECK_EVBIT');
          pc = 110;
          continue;
        case 110:
          if (s.slotInt(32910) != 12) { pc = 111; } else { pc = 111; }
          continue;
        case 111:
          s.setSlot(11, 0);
          pc = 112;
          continue;
        case 112:
          s.placeholder('LOMA');
          pc = 113;
          continue;
        case 113:
          s.placeholder('FADU');
          pc = 114;
          continue;
        case 114:
          s.placeholder('BROWNBOXTEXT');
          pc = 115;
          continue;
        case 115:
          s.placeholder('STAL1');
          pc = 116;
          continue;
        case 116:
          s.placeholder('FADI');
          pc = 117;
          continue;
        case 117:
          pc = 118;
          continue;
        case 118:
          s.placeholder('CHECK_EVBIT');
          pc = 119;
          continue;
        case 119:
          if (s.slotInt(32911) != 12) { pc = 120; } else { pc = 120; }
          continue;
        case 120:
          s.setSlot(11, 0);
          pc = 121;
          continue;
        case 121:
          s.placeholder('LOMA');
          pc = 122;
          continue;
        case 122:
          s.placeholder('FADU');
          pc = 123;
          continue;
        case 123:
          s.placeholder('BROWNBOXTEXT');
          pc = 124;
          continue;
        case 124:
          s.placeholder('STAL1');
          pc = 125;
          continue;
        case 125:
          s.placeholder('FADI');
          pc = 126;
          continue;
        case 126:
          pc = 127;
          continue;
        case 127:
          s.placeholder('CHECK_EVBIT');
          pc = 128;
          continue;
        case 128:
          if (s.slotInt(32912) != 12) { pc = 129; } else { pc = 129; }
          continue;
        case 129:
          s.setSlot(11, 0);
          pc = 130;
          continue;
        case 130:
          s.placeholder('LOMA');
          pc = 131;
          continue;
        case 131:
          s.placeholder('FADU');
          pc = 132;
          continue;
        case 132:
          s.placeholder('BROWNBOXTEXT');
          pc = 133;
          continue;
        case 133:
          s.placeholder('STAL1');
          pc = 134;
          continue;
        case 134:
          s.placeholder('FADI');
          pc = 135;
          continue;
        case 135:
          pc = 136;
          continue;
        case 136:
          s.placeholder('CHECK_EVBIT');
          pc = 137;
          continue;
        case 137:
          if (s.slotInt(32913) != 12) { pc = 138; } else { pc = 138; }
          continue;
        case 138:
          s.setSlot(11, 0);
          pc = 139;
          continue;
        case 139:
          s.placeholder('LOMA');
          pc = 140;
          continue;
        case 140:
          s.placeholder('FADU');
          pc = 141;
          continue;
        case 141:
          s.placeholder('BROWNBOXTEXT');
          pc = 142;
          continue;
        case 142:
          s.placeholder('STAL1');
          pc = 143;
          continue;
        case 143:
          s.placeholder('FADI');
          pc = 144;
          continue;
        case 144:
          pc = 145;
          continue;
        case 145:
          s.placeholder('CHECK_EVBIT');
          pc = 146;
          continue;
        case 146:
          if (s.slotInt(32914) != 12) { pc = 147; } else { pc = 147; }
          continue;
        case 147:
          s.setSlot(11, 0);
          pc = 148;
          continue;
        case 148:
          s.placeholder('LOMA');
          pc = 149;
          continue;
        case 149:
          s.placeholder('FADU');
          pc = 150;
          continue;
        case 150:
          s.placeholder('BROWNBOXTEXT');
          pc = 151;
          continue;
        case 151:
          s.placeholder('STAL1');
          pc = 152;
          continue;
        case 152:
          s.placeholder('FADI');
          pc = 153;
          continue;
        case 153:
          pc = 154;
          continue;
        case 154:
          s.placeholder('CHECK_EVBIT');
          pc = 155;
          continue;
        case 155:
          if (s.slotInt(32915) != 12) { pc = 156; } else { pc = 156; }
          continue;
        case 156:
          s.setSlot(11, 0);
          pc = 157;
          continue;
        case 157:
          s.placeholder('LOMA');
          pc = 158;
          continue;
        case 158:
          s.placeholder('FADU');
          pc = 159;
          continue;
        case 159:
          s.placeholder('BROWNBOXTEXT');
          pc = 160;
          continue;
        case 160:
          s.placeholder('STAL1');
          pc = 161;
          continue;
        case 161:
          s.placeholder('FADI');
          pc = 162;
          continue;
        case 162:
          pc = 163;
          continue;
        case 163:
          s.placeholder('CHECK_EVBIT');
          pc = 164;
          continue;
        case 164:
          if (s.slotInt(32916) != 12) { pc = 165; } else { pc = 165; }
          continue;
        case 165:
          s.setSlot(11, 0);
          pc = 166;
          continue;
        case 166:
          s.placeholder('LOMA');
          pc = 167;
          continue;
        case 167:
          s.placeholder('FADU');
          pc = 168;
          continue;
        case 168:
          s.placeholder('BROWNBOXTEXT');
          pc = 169;
          continue;
        case 169:
          s.placeholder('STAL1');
          pc = 170;
          continue;
        case 170:
          s.placeholder('FADI');
          pc = 171;
          continue;
        case 171:
          pc = 172;
          continue;
        case 172:
          s.placeholder('CHECK_EVBIT');
          pc = 173;
          continue;
        case 173:
          if (s.slotInt(32917) != 12) { pc = 174; } else { pc = 174; }
          continue;
        case 174:
          s.setSlot(11, 0);
          pc = 175;
          continue;
        case 175:
          s.placeholder('LOMA');
          pc = 176;
          continue;
        case 176:
          s.placeholder('FADU');
          pc = 177;
          continue;
        case 177:
          s.placeholder('BROWNBOXTEXT');
          pc = 178;
          continue;
        case 178:
          s.placeholder('STAL1');
          pc = 179;
          continue;
        case 179:
          s.placeholder('FADI');
          pc = 180;
          continue;
        case 180:
          pc = 181;
          continue;
        case 181:
          s.placeholder('CHECK_EVBIT');
          pc = 182;
          continue;
        case 182:
          if (s.slotInt(32918) != 12) { pc = 183; } else { pc = 183; }
          continue;
        case 183:
          s.setSlot(11, 0);
          pc = 184;
          continue;
        case 184:
          s.placeholder('LOMA');
          pc = 185;
          continue;
        case 185:
          s.placeholder('FADU');
          pc = 186;
          continue;
        case 186:
          s.placeholder('BROWNBOXTEXT');
          pc = 187;
          continue;
        case 187:
          s.placeholder('STAL1');
          pc = 188;
          continue;
        case 188:
          s.placeholder('FADI');
          pc = 189;
          continue;
        case 189:
          pc = 190;
          continue;
        case 190:
          s.placeholder('CHECK_EVBIT');
          pc = 191;
          continue;
        case 191:
          if (s.slotInt(32919) != 12) { pc = 192; } else { pc = 192; }
          continue;
        case 192:
          s.setSlot(11, 0);
          pc = 193;
          continue;
        case 193:
          s.placeholder('LOMA');
          pc = 194;
          continue;
        case 194:
          s.placeholder('FADU');
          pc = 195;
          continue;
        case 195:
          s.placeholder('BROWNBOXTEXT');
          pc = 196;
          continue;
        case 196:
          s.placeholder('STAL1');
          pc = 197;
          continue;
        case 197:
          s.placeholder('FADI');
          pc = 198;
          continue;
        case 198:
          pc = 199;
          continue;
        case 199:
          s.placeholder('CHECK_EVBIT');
          pc = 200;
          continue;
        case 200:
          if (s.slotInt(32920) != 12) { pc = 201; } else { pc = 201; }
          continue;
        case 201:
          s.setSlot(11, 0);
          pc = 202;
          continue;
        case 202:
          s.placeholder('LOMA');
          pc = 203;
          continue;
        case 203:
          s.placeholder('FADU');
          pc = 204;
          continue;
        case 204:
          s.placeholder('BROWNBOXTEXT');
          pc = 205;
          continue;
        case 205:
          s.placeholder('STAL1');
          pc = 206;
          continue;
        case 206:
          s.placeholder('FADI');
          pc = 207;
          continue;
        case 207:
          pc = 208;
          continue;
        case 208:
          s.placeholder('CHECK_EVBIT');
          pc = 209;
          continue;
        case 209:
          if (s.slotInt(32921) != 12) { pc = 210; } else { pc = 210; }
          continue;
        case 210:
          s.setSlot(11, 0);
          pc = 211;
          continue;
        case 211:
          s.placeholder('LOMA');
          pc = 212;
          continue;
        case 212:
          s.placeholder('FADU');
          pc = 213;
          continue;
        case 213:
          s.placeholder('BROWNBOXTEXT');
          pc = 214;
          continue;
        case 214:
          s.placeholder('STAL1');
          pc = 215;
          continue;
        case 215:
          s.placeholder('FADI');
          pc = 216;
          continue;
        case 216:
          pc = 217;
          continue;
        case 217:
          s.placeholder('CHECK_EVBIT');
          pc = 218;
          continue;
        case 218:
          if (s.slotInt(32922) != 12) { pc = 219; } else { pc = 219; }
          continue;
        case 219:
          s.setSlot(11, 0);
          pc = 220;
          continue;
        case 220:
          s.placeholder('LOMA');
          pc = 221;
          continue;
        case 221:
          s.placeholder('FADU');
          pc = 222;
          continue;
        case 222:
          s.placeholder('BROWNBOXTEXT');
          pc = 223;
          continue;
        case 223:
          s.placeholder('STAL1');
          pc = 224;
          continue;
        case 224:
          s.placeholder('FADI');
          pc = 225;
          continue;
        case 225:
          pc = 226;
          continue;
        case 226:
          s.placeholder('CHECK_EVBIT');
          pc = 227;
          continue;
        case 227:
          if (s.slotInt(32923) != 12) { pc = 228; } else { pc = 228; }
          continue;
        case 228:
          s.setSlot(11, 0);
          pc = 229;
          continue;
        case 229:
          s.placeholder('LOMA');
          pc = 230;
          continue;
        case 230:
          s.placeholder('FADU');
          pc = 231;
          continue;
        case 231:
          s.placeholder('BROWNBOXTEXT');
          pc = 232;
          continue;
        case 232:
          s.placeholder('STAL1');
          pc = 233;
          continue;
        case 233:
          s.placeholder('FADI');
          pc = 234;
          continue;
        case 234:
          pc = 235;
          continue;
        case 235:
          s.placeholder('CHECK_EVBIT');
          pc = 236;
          continue;
        case 236:
          if (s.slotInt(32924) != 12) { pc = 237; } else { pc = 237; }
          continue;
        case 237:
          s.setSlot(11, 0);
          pc = 238;
          continue;
        case 238:
          s.placeholder('LOMA');
          pc = 239;
          continue;
        case 239:
          s.placeholder('FADU');
          pc = 240;
          continue;
        case 240:
          s.placeholder('BROWNBOXTEXT');
          pc = 241;
          continue;
        case 241:
          s.placeholder('STAL1');
          pc = 242;
          continue;
        case 242:
          s.placeholder('FADI');
          pc = 243;
          continue;
        case 243:
          pc = 244;
          continue;
        case 244:
          s.placeholder('CHECK_EVBIT');
          pc = 245;
          continue;
        case 245:
          if (s.slotInt(32925) != 12) { pc = 246; } else { pc = 246; }
          continue;
        case 246:
          s.setSlot(11, 0);
          pc = 247;
          continue;
        case 247:
          s.placeholder('LOMA');
          pc = 248;
          continue;
        case 248:
          s.placeholder('FADU');
          pc = 249;
          continue;
        case 249:
          s.placeholder('BROWNBOXTEXT');
          pc = 250;
          continue;
        case 250:
          s.placeholder('STAL1');
          pc = 251;
          continue;
        case 251:
          s.placeholder('FADI');
          pc = 252;
          continue;
        case 252:
          pc = 253;
          continue;
        case 253:
          s.placeholder('CHECK_EVBIT');
          pc = 254;
          continue;
        case 254:
          if (s.slotInt(32926) != 12) { pc = 255; } else { pc = 255; }
          continue;
        case 255:
          s.setSlot(11, 0);
          pc = 256;
          continue;
        case 256:
          s.placeholder('LOMA');
          pc = 257;
          continue;
        case 257:
          s.placeholder('FADU');
          pc = 258;
          continue;
        case 258:
          s.placeholder('BROWNBOXTEXT');
          pc = 259;
          continue;
        case 259:
          s.placeholder('STAL1');
          pc = 260;
          continue;
        case 260:
          s.placeholder('FADI');
          pc = 261;
          continue;
        case 261:
          pc = 262;
          continue;
        case 262:
          s.placeholder('CHECK_EVBIT');
          pc = 263;
          continue;
        case 263:
          if (s.slotInt(32927) != 12) { pc = 264; } else { pc = 264; }
          continue;
        case 264:
          s.setSlot(11, 0);
          pc = 265;
          continue;
        case 265:
          s.placeholder('LOMA');
          pc = 266;
          continue;
        case 266:
          s.placeholder('FADU');
          pc = 267;
          continue;
        case 267:
          s.placeholder('BROWNBOXTEXT');
          pc = 268;
          continue;
        case 268:
          s.placeholder('STAL1');
          pc = 269;
          continue;
        case 269:
          s.placeholder('FADI');
          pc = 270;
          continue;
        case 270:
          pc = 271;
          continue;
        case 271:
          s.placeholder('CHECK_EVBIT');
          pc = 272;
          continue;
        case 272:
          if (s.slotInt(32928) != 12) { pc = 273; } else { pc = 273; }
          continue;
        case 273:
          s.setSlot(11, 0);
          pc = 274;
          continue;
        case 274:
          s.placeholder('LOMA');
          pc = 275;
          continue;
        case 275:
          s.placeholder('FADU');
          pc = 276;
          continue;
        case 276:
          s.placeholder('BROWNBOXTEXT');
          pc = 277;
          continue;
        case 277:
          s.placeholder('STAL1');
          pc = 278;
          continue;
        case 278:
          s.placeholder('FADI');
          pc = 279;
          continue;
        case 279:
          pc = 280;
          continue;
        case 280:
          s.placeholder('CHECK_EVBIT');
          pc = 281;
          continue;
        case 281:
          if (s.slotInt(32929) != 12) { pc = 282; } else { pc = 282; }
          continue;
        case 282:
          s.setSlot(11, 0);
          pc = 283;
          continue;
        case 283:
          s.placeholder('LOMA');
          pc = 284;
          continue;
        case 284:
          s.placeholder('FADU');
          pc = 285;
          continue;
        case 285:
          s.placeholder('BROWNBOXTEXT');
          pc = 286;
          continue;
        case 286:
          s.placeholder('STAL1');
          pc = 287;
          continue;
        case 287:
          s.placeholder('FADI');
          pc = 288;
          continue;
        case 288:
          pc = 289;
          continue;
        case 289:
          s.placeholder('CHECK_EVBIT');
          pc = 290;
          continue;
        case 290:
          if (s.slotInt(32930) != 12) { pc = 291; } else { pc = 291; }
          continue;
        case 291:
          s.setSlot(11, 0);
          pc = 292;
          continue;
        case 292:
          s.placeholder('LOMA');
          pc = 293;
          continue;
        case 293:
          s.placeholder('FADU');
          pc = 294;
          continue;
        case 294:
          s.placeholder('BROWNBOXTEXT');
          pc = 295;
          continue;
        case 295:
          s.placeholder('STAL1');
          pc = 296;
          continue;
        case 296:
          s.placeholder('FADI');
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
          s.placeholder('LOMA');
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
          s.placeholder('FADI');
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
          s.placeholder('REMOVEPORTRAITS');
          pc = 4;
          continue;
        case 4:
          pc = 5;
          continue;
        case 5:
          s.placeholder('BACG');
          pc = 6;
          continue;
        case 6:
          s.placeholder('FADU');
          pc = 7;
          continue;
        case 7:
          s.placeholder('FACE_SHOW');
          pc = 8;
          continue;
        case 8:
          s.placeholder('TEXTEND');
          pc = 9;
          continue;
        case 9:
          s.placeholder('STAL1');
          pc = 10;
          continue;
        case 10:
          s.placeholder('REMA');
          pc = 11;
          continue;
        case 11:
          s.placeholder('FADI');
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
          s.placeholder('BLT');
          pc = 15;
          continue;
        case 15:
          s.placeholder('CLEAN');
          pc = 16;
          continue;
        case 16:
          s.placeholder('FADU');
          pc = 17;
          continue;
        case 17:
          s.placeholder('EVBIT_T');
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
          s.placeholder('FADI');
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
          s.placeholder('REMOVEPORTRAITS');
          pc = 4;
          continue;
        case 4:
          pc = 5;
          continue;
        case 5:
          s.placeholder('BACG');
          pc = 6;
          continue;
        case 6:
          s.placeholder('FADU');
          pc = 7;
          continue;
        case 7:
          s.placeholder('STAL1');
          pc = 8;
          continue;
        case 8:
          s.placeholder('FADI');
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
          s.placeholder('BLT');
          pc = 12;
          continue;
        case 12:
          s.placeholder('CLEAN');
          pc = 13;
          continue;
        case 13:
          s.placeholder('FADU');
          pc = 14;
          continue;
        case 14:
          s.placeholder('EVBIT_T');
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
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 25);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 15);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 5);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 5);
    s.placeholder('SENQUEUE1');
    await s.call(Sym('EventScr_9EE84C'));
    s.setSlot(1, 0);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 1);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 2);
    s.placeholder('SENQUEUE1');
    return;
}

/// `EventScr_Ruin_62`
Future<void> Ruin_62(Scene s) async {
    s.setSlot(2, 0);
    await s.call(Sym('EventScr_ConfigHardModeLoadUnitHard'));
    s.setSlot(13, 0);
    s.setSlot(1, 50);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 25);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 15);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 5);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 5);
    s.placeholder('SENQUEUE1');
    await s.call(Sym('EventScr_9EE84C'));
    s.setSlot(1, 0);
    s.placeholder('SENQUEUE1');
    return;
}

/// `EventScr_Ruin_64`
Future<void> Ruin_64(Scene s) async {
    s.setSlot(2, 0);
    await s.call(Sym('EventScr_ConfigHardModeLoadUnitHard'));
    s.setSlot(13, 0);
    s.setSlot(1, 50);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 25);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 15);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 5);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 5);
    s.placeholder('SENQUEUE1');
    await s.call(Sym('EventScr_9EE84C'));
    s.setSlot(1, 0);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 1);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 2);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 3);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 4);
    s.placeholder('SENQUEUE1');
    return;
}

/// `EventScr_Ruin_66`
Future<void> Ruin_66(Scene s) async {
    s.setSlot(2, 0);
    await s.call(Sym('EventScr_ConfigHardModeLoadUnitHard'));
    s.setSlot(13, 0);
    s.setSlot(1, 50);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 25);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 15);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 5);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 5);
    s.placeholder('SENQUEUE1');
    await s.call(Sym('EventScr_9EE84C'));
    return;
}

/// `EventScr_Ruin_68`
Future<void> Ruin_68(Scene s) async {
    s.setSlot(2, 0);
    await s.call(Sym('EventScr_ConfigHardModeLoadUnitHard'));
    s.setSlot(13, 0);
    s.setSlot(1, 50);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 25);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 15);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 5);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 5);
    s.placeholder('SENQUEUE1');
    await s.call(Sym('EventScr_9EE84C'));
    s.setSlot(1, 0);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 1);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 2);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 3);
    s.placeholder('SENQUEUE1');
    return;
}

/// `EventScr_Ruin_70`
Future<void> Ruin_70(Scene s) async {
    s.setSlot(2, 0);
    await s.call(Sym('EventScr_ConfigHardModeLoadUnitHard'));
    s.setSlot(13, 0);
    s.setSlot(1, 50);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 25);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 15);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 5);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 5);
    s.placeholder('SENQUEUE1');
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
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 25);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 15);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 5);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 5);
    s.placeholder('SENQUEUE1');
    await s.call(Sym('EventScr_9EE84C'));
    s.setSlot(1, 0);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 1);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 2);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 3);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 6);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 7);
    s.placeholder('SENQUEUE1');
    return;
}

/// `EventScr_Ruin_74`
Future<void> Ruin_74(Scene s) async {
    s.setSlot(2, 0);
    await s.call(Sym('EventScr_ConfigHardModeLoadUnitHard'));
    s.setSlot(13, 0);
    s.setSlot(1, 50);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 25);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 15);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 5);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 5);
    s.placeholder('SENQUEUE1');
    await s.call(Sym('EventScr_9EE84C'));
    s.setSlot(1, 0);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 1);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 4);
    s.placeholder('SENQUEUE1');
    return;
}

/// `EventScr_Ruin_76`
Future<void> Ruin_76(Scene s) async {
    s.setSlot(2, 0);
    await s.call(Sym('EventScr_ConfigHardModeLoadUnitHard'));
    s.setSlot(13, 0);
    s.setSlot(1, 50);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 25);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 15);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 5);
    s.placeholder('SENQUEUE1');
    s.setSlot(1, 5);
    s.placeholder('SENQUEUE1');
    await s.call(Sym('EventScr_9EE84C'));
    return;
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
          if (s.slotInt(0) == 12) { pc = 3; } else { pc = 2; }
          continue;
        case 2:
          s.placeholder('ENUT');
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
          s.placeholder('EVBIT_MODIFY');
          pc = 1;
          continue;
        case 1:
          s.placeholder('TUTORIALTEXTBOXSTART');
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
          s.placeholder('TEXTEND');
          pc = 5;
          continue;
        case 5:
          s.setSlot(7, 1);
          pc = 6;
          continue;
        case 6:
          if (s.slotInt(0) != 12) { pc = 7; } else { pc = 7; }
          continue;
        case 7:
          s.placeholder('EvtBgmFadeIn');
          pc = 8;
          continue;
        case 8:
          s.placeholder('FADI');
          pc = 9;
          continue;
        case 9:
          s.placeholder('MNCH');
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
          if (s.slotInt(0) != 12) { pc = 13; } else { pc = 13; }
          continue;
        case 13:
          s.placeholder('ASMC');
          pc = 14;
          continue;
        case 14:
          pc = 15;
          continue;
        case 15:
          s.placeholder('REMA');
          pc = 16;
          continue;
        case 16:
          s.placeholder('EVBIT_T');
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
          if (s.slotInt(0) != 12) { pc = 5; } else { pc = 2; }
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
          if (s.slotInt(2) == 12) { pc = 10; } else { pc = 9; }
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
          s.placeholder('SET_HP');
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
          s.placeholder('EVBIT_MODIFY');
          pc = 1;
          continue;
        case 1:
          s.placeholder('TEXTSTART');
          pc = 2;
          continue;
        case 2:
          await s.textShow(2079);
          pc = 3;
          continue;
        case 3:
          s.placeholder('TEXTEND');
          pc = 4;
          continue;
        case 4:
          s.setSlot(7, 1);
          pc = 5;
          continue;
        case 5:
          if (s.slotInt(0) != 12) { pc = 6; } else { pc = 6; }
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
          s.placeholder('TEXTEND');
          pc = 9;
          continue;
        case 9:
          s.placeholder('EvtBgmFadeIn');
          pc = 10;
          continue;
        case 10:
          s.placeholder('FADI');
          pc = 11;
          continue;
        case 11:
          s.placeholder('MNTS');
          pc = 12;
          continue;
        case 12:
          pc = 13;
          continue;
        case 13:
          s.placeholder('REMA');
          pc = 14;
          continue;
        case 14:
          s.placeholder('EVBIT_T');
          pc = 15;
          continue;
        case 15:
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
          s.placeholder('TUTORIALTEXTBOXSTART');
          pc = 1;
          continue;
        case 1:
          s.placeholder('CHECK_ACTIVE');
          pc = 2;
          continue;
        case 2:
          s.placeholder('SDEQUEUE');
          pc = 3;
          continue;
        case 3:
          if (s.slotInt(0) != 12) { pc = 4; } else { pc = 4; }
          continue;
        case 4:
          s.placeholder('SHOW_ATTACK_RANGE');
          pc = 5;
          continue;
        case 5:
          s.placeholder('SDEQUEUE');
          pc = 6;
          continue;
        case 6:
          s.placeholder('CURSOR_FLASHING');
          pc = 7;
          continue;
        case 7:
          await s.stall(18);
          pc = 8;
          continue;
        case 8:
          s.placeholder('SDEQUEUE');
          pc = 9;
          continue;
        case 9:
          s.placeholder('SDEQUEUE');
          pc = 10;
          continue;
        case 10:
          await s.textShow(-1);
          pc = 11;
          continue;
        case 11:
          s.placeholder('TEXTEND');
          pc = 12;
          continue;
        case 12:
          s.placeholder('CURE');
          pc = 13;
          continue;
        case 13:
          s.placeholder('IGNORE_KEYS');
          pc = 14;
          continue;
        case 14:
          s.placeholder('SDEQUEUE');
          pc = 15;
          continue;
        case 15:
          s.placeholder('SDEQUEUE');
          pc = 16;
          continue;
        case 16:
          s.placeholder('SDEQUEUE');
          pc = 17;
          continue;
        case 17:
          pc = 32;
          continue;
        case 18:
          pc = 19;
          continue;
        case 19:
          s.placeholder('SDEQUEUE');
          pc = 20;
          continue;
        case 20:
          s.placeholder('SDEQUEUE');
          pc = 21;
          continue;
        case 21:
          s.placeholder('SDEQUEUE');
          pc = 22;
          continue;
        case 22:
          s.placeholder('CURSOR_FLASHING_CHAR');
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
          s.placeholder('SDEQUEUE');
          pc = 26;
          continue;
        case 26:
          s.placeholder('SDEQUEUE');
          pc = 27;
          continue;
        case 27:
          await s.textShow(-1);
          pc = 28;
          continue;
        case 28:
          s.placeholder('TEXTEND');
          pc = 29;
          continue;
        case 29:
          s.placeholder('CURE');
          pc = 30;
          continue;
        case 30:
          s.placeholder('SDEQUEUE');
          pc = 31;
          continue;
        case 31:
          s.placeholder('SDEQUEUE');
          pc = 32;
          continue;
        case 32:
          pc = 33;
          continue;
        case 33:
          s.placeholder('REMA');
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
          s.placeholder('SDEQUEUE');
          pc = 2;
          continue;
        case 2:
          if (s.slotInt(0) != 12) { pc = 3; } else { pc = 3; }
          continue;
        case 3:
          s.placeholder('ASMC');
          pc = 4;
          continue;
        case 4:
          s.placeholder('SDEQUEUE');
          pc = 5;
          continue;
        case 5:
          s.placeholder('SDEQUEUE');
          pc = 6;
          continue;
        case 6:
          s.placeholder('SDEQUEUE');
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
          s.placeholder('CAMERA');
          pc = 13;
          continue;
        case 13:
          s.placeholder('CURSOR_FLASHING');
          pc = 14;
          continue;
        case 14:
          s.placeholder('STAL3');
          pc = 15;
          continue;
        case 15:
          s.placeholder('TUTORIALTEXTBOXSTART');
          pc = 16;
          continue;
        case 16:
          s.placeholder('SDEQUEUE');
          pc = 17;
          continue;
        case 17:
          s.placeholder('SDEQUEUE');
          pc = 18;
          continue;
        case 18:
          if (s.slotInt(1) == 2) { pc = 10; } else { pc = 19; }
          continue;
        case 19:
          await s.textShow(65535);
          pc = 20;
          continue;
        case 20:
          s.placeholder('TEXTEND');
          pc = 21;
          continue;
        case 21:
          s.placeholder('REMA');
          pc = 22;
          continue;
        case 22:
          pc = 23;
          continue;
        case 23:
          s.placeholder('CURE');
          pc = 24;
          continue;
        case 24:
          s.placeholder('SDEQUEUE');
          pc = 25;
          continue;
        case 25:
          s.placeholder('SDEQUEUE');
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

/// `EventScr_UnitFlushingIN`
Future<void> UnitFlushingIN(Scene s) async {
    s.placeholder('CAMERA_CAHR');
    s.placeholder('REVEAL');
    s.placeholder('STAL2');
    s.placeholder('REMU');
    s.placeholder('STAL2');
    s.placeholder('REVEAL');
    s.placeholder('STAL2');
    s.placeholder('REMU');
    s.placeholder('STAL2');
    s.placeholder('REVEAL');
    s.placeholder('STAL2');
    s.placeholder('REMU');
    s.placeholder('STAL2');
    s.placeholder('REVEAL');
    return;
}

/// `EventScr_UnitFlushingOUT`
Future<void> UnitFlushingOUT(Scene s) async {
    s.placeholder('CAMERA_CAHR');
    s.placeholder('REVEAL');
    s.placeholder('STAL2');
    s.placeholder('REMU');
    s.placeholder('STAL2');
    s.placeholder('REVEAL');
    s.placeholder('STAL2');
    s.placeholder('REMU');
    s.placeholder('STAL2');
    s.placeholder('REVEAL');
    s.placeholder('STAL2');
    s.placeholder('REMU');
    s.placeholder('STAL2');
    s.placeholder('REVEAL');
    s.placeholder('STAL2');
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
    s.placeholder('STAL2');
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
    s.placeholder('STAL2');
    s.placeholder('REMU');
    s.placeholder('ENDWARP');
    return;
}

/// ⚠️ `EventScr_9EEAAC` —— 上游尚未 carve，生成的是**记录缺失**的占位
Future<void> missing_EventScr_9EEAAC(Scene s) async {
  s.missing.add('EventScr_9EEAAC');
}

/// ⚠️ `EventScr_Ch1Tut_AfterSethMoveToEnemy` —— 上游尚未 carve，生成的是**记录缺失**的占位
Future<void> missing_EventScr_Ch1Tut_AfterSethMoveToEnemy(Scene s) async {
  s.missing.add('EventScr_Ch1Tut_AfterSethMoveToEnemy');
}

/// ⚠️ `EventScr_Ch1Tut_EirikaVisitHouseEnd` —— 上游尚未 carve，生成的是**记录缺失**的占位
Future<void> missing_EventScr_Ch1Tut_EirikaVisitHouseEnd(Scene s) async {
  s.missing.add('EventScr_Ch1Tut_EirikaVisitHouseEnd');
}

/// ⚠️ `EventScr_Ch1Tut_GilliamBattle` —— 上游尚未 carve，生成的是**记录缺失**的占位
Future<void> missing_EventScr_Ch1Tut_GilliamBattle(Scene s) async {
  s.missing.add('EventScr_Ch1Tut_GilliamBattle');
}

/// ⚠️ `EventScr_Ch1Tut_GuideWTA` —— 上游尚未 carve，生成的是**记录缺失**的占位
Future<void> missing_EventScr_Ch1Tut_GuideWTA(Scene s) async {
  s.missing.add('EventScr_Ch1Tut_GuideWTA');
}

/// ⚠️ `EventScr_Ch1Tut_TradeSelectGalliamEnd` —— 上游尚未 carve，生成的是**记录缺失**的占位
Future<void> missing_EventScr_Ch1Tut_TradeSelectGalliamEnd(Scene s) async {
  s.missing.add('EventScr_Ch1Tut_TradeSelectGalliamEnd');
}

/// ⚠️ `EventScr_Ch2Tutorial10` —— 上游尚未 carve，生成的是**记录缺失**的占位
Future<void> missing_EventScr_Ch2Tutorial10(Scene s) async {
  s.missing.add('EventScr_Ch2Tutorial10');
}

/// ⚠️ `EventScr_Ch2Tutorial13` —— 上游尚未 carve，生成的是**记录缺失**的占位
Future<void> missing_EventScr_Ch2Tutorial13(Scene s) async {
  s.missing.add('EventScr_Ch2Tutorial13');
}

/// ⚠️ `EventScr_Ch2Tutorial16` —— 上游尚未 carve，生成的是**记录缺失**的占位
Future<void> missing_EventScr_Ch2Tutorial16(Scene s) async {
  s.missing.add('EventScr_Ch2Tutorial16');
}

/// ⚠️ `EventScr_Ch2Tutorial19` —— 上游尚未 carve，生成的是**记录缺失**的占位
Future<void> missing_EventScr_Ch2Tutorial19(Scene s) async {
  s.missing.add('EventScr_Ch2Tutorial19');
}

/// ⚠️ `EventScr_Ch2Tutorial25` —— 上游尚未 carve，生成的是**记录缺失**的占位
Future<void> missing_EventScr_Ch2Tutorial25(Scene s) async {
  s.missing.add('EventScr_Ch2Tutorial25');
}

/// ⚠️ `EventScr_Ch2Tutorial29` —— 上游尚未 carve，生成的是**记录缺失**的占位
Future<void> missing_EventScr_Ch2Tutorial29(Scene s) async {
  s.missing.add('EventScr_Ch2Tutorial29');
}

/// ⚠️ `EventScr_Ch2Tutorial3` —— 上游尚未 carve，生成的是**记录缺失**的占位
Future<void> missing_EventScr_Ch2Tutorial3(Scene s) async {
  s.missing.add('EventScr_Ch2Tutorial3');
}

/// ⚠️ `EventScr_Ch2Tutorial6` —— 上游尚未 carve，生成的是**记录缺失**的占位
Future<void> missing_EventScr_Ch2Tutorial6(Scene s) async {
  s.missing.add('EventScr_Ch2Tutorial6');
}

/// ⚠️ `EventScr_Ch2_7` —— 上游尚未 carve，生成的是**记录缺失**的占位
Future<void> missing_EventScr_Ch2_7(Scene s) async {
  s.missing.add('EventScr_Ch2_7');
}

/// ⚠️ `EventScr_Ch2_Village2` —— 上游尚未 carve，生成的是**记录缺失**的占位
Future<void> missing_EventScr_Ch2_Village2(Scene s) async {
  s.missing.add('EventScr_Ch2_Village2');
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

/// ⚠️ `EventScr_Ch6_3` —— 上游尚未 carve，生成的是**记录缺失**的占位
Future<void> missing_EventScr_Ch6_3(Scene s) async {
  s.missing.add('EventScr_Ch6_3');
}

/// ⚠️ `EventScr_Ch7_3` —— 上游尚未 carve，生成的是**记录缺失**的占位
Future<void> missing_EventScr_Ch7_3(Scene s) async {
  s.missing.add('EventScr_Ch7_3');
}

/// ⚠️ `EventScr_ChangeAIinQueue` —— 上游尚未 carve，生成的是**记录缺失**的占位
Future<void> missing_EventScr_ChangeAIinQueue(Scene s) async {
  s.missing.add('EventScr_ChangeAIinQueue');
}

/// ⚠️ `EventScr_LoadReinforce` —— 上游尚未 carve，生成的是**记录缺失**的占位
Future<void> missing_EventScr_LoadReinforce(Scene s) async {
  s.missing.add('EventScr_LoadReinforce');
}

/// ⚠️ `EventScr_LoadReinforceHardMode` —— 上游尚未 carve，生成的是**记录缺失**的占位
Future<void> missing_EventScr_LoadReinforceHardMode(Scene s) async {
  s.missing.add('EventScr_LoadReinforceHardMode');
}

/// ⚠️ `EventScr_LoadUnitForTutorial` —— 上游尚未 carve，生成的是**记录缺失**的占位
Future<void> missing_EventScr_LoadUnitForTutorial(Scene s) async {
  s.missing.add('EventScr_LoadUnitForTutorial');
}

/// ⚠️ `EventScr_Prologue_9EF828` —— 上游尚未 carve，生成的是**记录缺失**的占位
Future<void> missing_EventScr_Prologue_9EF828(Scene s) async {
  s.missing.add('EventScr_Prologue_9EF828');
}

/// ⚠️ `EventScr_Prologue_EirikaAttacked` —— 上游尚未 carve，生成的是**记录缺失**的占位
Future<void> missing_EventScr_Prologue_EirikaAttacked(Scene s) async {
  s.missing.add('EventScr_Prologue_EirikaAttacked');
}

/// ⚠️ `EventScr_Prologue_ExecTut` —— 上游尚未 carve，生成的是**记录缺失**的占位
Future<void> missing_EventScr_Prologue_ExecTut(Scene s) async {
  s.missing.add('EventScr_Prologue_ExecTut');
}

/// ⚠️ `EventScr_Prologue_ONeillSpawn` —— 上游尚未 carve，生成的是**记录缺失**的占位
Future<void> missing_EventScr_Prologue_ONeillSpawn(Scene s) async {
  s.missing.add('EventScr_Prologue_ONeillSpawn');
}

/// ⚠️ `EventScr_Prologue_Tutorial2` —— 上游尚未 carve，生成的是**记录缺失**的占位
Future<void> missing_EventScr_Prologue_Tutorial2(Scene s) async {
  s.missing.add('EventScr_Prologue_Tutorial2');
}

/// ⚠️ `EventScr_Prologue_Tutorial5` —— 上游尚未 carve，生成的是**记录缺失**的占位
Future<void> missing_EventScr_Prologue_Tutorial5(Scene s) async {
  s.missing.add('EventScr_Prologue_Tutorial5');
}

/// ⚠️ `EventScr_Prologue_TutorialC` —— 上游尚未 carve，生成的是**记录缺失**的占位
Future<void> missing_EventScr_Prologue_TutorialC(Scene s) async {
  s.missing.add('EventScr_Prologue_TutorialC');
}

/// ⚠️ `EventScr_SetBackground` —— 上游尚未 carve，生成的是**记录缺失**的占位
Future<void> missing_EventScr_SetBackground(Scene s) async {
  s.missing.add('EventScr_SetBackground');
}

/// ⚠️ `EventScr_TextShowWithFadeIn` —— 上游尚未 carve，生成的是**记录缺失**的占位
Future<void> missing_EventScr_TextShowWithFadeIn(Scene s) async {
  s.missing.add('EventScr_TextShowWithFadeIn');
}

/// ⚠️ `EventScr_UnTriggerIfNotUnit` —— 上游尚未 carve，生成的是**记录缺失**的占位
Future<void> missing_EventScr_UnTriggerIfNotUnit(Scene s) async {
  s.missing.add('EventScr_UnTriggerIfNotUnit');
}

/// **真正被 carve 出来**的脚本名。
///
/// ⚠️ 与 `allSceneFns` 的键**不一样**：后者还包含下面那些
/// 占位函数。存在性检查必须用本集合 —— 用 `allSceneFns` 的话
/// 占位让「缺失」看起来「存在」，检查就失效了（踩过）。
final Set<String> definedSceneScripts = {
  'EventScr_9EE84C',
  'EventScr_9EEA58',
  'EventScr_ApplyTileChangeForFaction',
  'EventScr_CallIfCommonMode',
  'EventScr_CallOnChapterNumber',
  'EventScr_CallOnHardMode',
  'EventScr_CallOnTutorialMode',
  'EventScr_CallWithModeCheck',
  'EventScr_Ch10A_0',
  'EventScr_Ch10A_13',
  'EventScr_Ch10A_8',
  'EventScr_Ch10B_0',
  'EventScr_Ch10B_1',
  'EventScr_Ch10B_2',
  'EventScr_Ch10a_BeginningScene',
  'EventScr_Ch10a_EndingScene',
  'EventScr_Ch11B_0',
  'EventScr_Ch11B_1',
  'EventScr_Ch11B_2',
  'EventScr_Ch11B_6',
  'EventScr_Ch11a_EndingScene',
  'EventScr_Ch12A_0',
  'EventScr_Ch12A_5',
  'EventScr_Ch12B_1',
  'EventScr_Ch13A_3',
  'EventScr_Ch13A_4',
  'EventScr_Ch13B_0',
  'EventScr_Ch13B_1',
  'EventScr_Ch13a_EndingScene',
  'EventScr_Ch13b_EndingScene',
  'EventScr_Ch14A_0',
  'EventScr_Ch14A_1',
  'EventScr_Ch14A_8',
  'EventScr_Ch14B_12',
  'EventScr_Ch14B_2',
  'EventScr_Ch14b_BeginningScene',
  'EventScr_Ch14b_EndingScene',
  'EventScr_Ch15A_0',
  'EventScr_Ch15A_17',
  'EventScr_Ch15A_18',
  'EventScr_Ch15A_19',
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
  'EventScr_Ch16A_1',
  'EventScr_Ch16A_11',
  'EventScr_Ch16A_12',
  'EventScr_Ch16A_9',
  'EventScr_Ch16B_3',
  'EventScr_Ch16B_5',
  'EventScr_Ch16b_BeginningScene',
  'EventScr_Ch18A_11',
  'EventScr_Ch18b_BeginningScene',
  'EventScr_Ch19A_11',
  'EventScr_Ch1Tut_BeforeSethMoveToEnemy',
  'EventScr_Ch1Tut_ChooseSethTurn1',
  'EventScr_Ch1Tut_EirikaVisitHouseIdle1',
  'EventScr_Ch1Tut_EirikaVisitHouseIdle2',
  'EventScr_Ch1Tut_EirikaVisitHouseInit',
  'EventScr_Ch1Tut_GuideTerrainHeal',
  'EventScr_Ch1Tut_OnBeginning',
  'EventScr_Ch1Tut_SethMoveToEnemy',
  'EventScr_Ch1Tut_TradeSelectGalliamIdle1',
  'EventScr_Ch1Tut_TradeSelectGalliamIdle2',
  'EventScr_Ch1_BeginningScene',
  'EventScr_Ch1_EndingScene',
  'EventScr_Ch1_Turn_AllyReinforceArrive',
  'EventScr_Ch20B_1',
  'EventScr_Ch20B_2',
  'EventScr_Ch20b_BeginningScene',
  'EventScr_Ch21A_0',
  'EventScr_Ch21A_8',
  'EventScr_Ch21A_9',
  'EventScr_Ch21b_BeginningScene',
  'EventScr_Ch21b_EndingScene',
  'EventScr_Ch2Tutorial11',
  'EventScr_Ch2Tutorial12',
  'EventScr_Ch2Tutorial14',
  'EventScr_Ch2Tutorial15',
  'EventScr_Ch2Tutorial18',
  'EventScr_Ch2Tutorial2',
  'EventScr_Ch2Tutorial21',
  'EventScr_Ch2Tutorial22',
  'EventScr_Ch2Tutorial23',
  'EventScr_Ch2Tutorial24',
  'EventScr_Ch2Tutorial27',
  'EventScr_Ch2Tutorial28',
  'EventScr_Ch2Tutorial4',
  'EventScr_Ch2Tutorial5',
  'EventScr_Ch2Tutorial8',
  'EventScr_Ch2Tutorial9',
  'EventScr_Ch2_10',
  'EventScr_Ch2_8',
  'EventScr_Ch2_BeginningScene',
  'EventScr_Ch2_EndingScene',
  'EventScr_Ch2_Village1',
  'EventScr_Ch3_0',
  'EventScr_Ch3_5',
  'EventScr_Ch3_BeginningScene',
  'EventScr_Ch3_EndingScene',
  'EventScr_Ch3_Turn1Npc',
  'EventScr_Ch4_0',
  'EventScr_Ch4_1',
  'EventScr_Ch4_10',
  'EventScr_Ch4_2',
  'EventScr_Ch4_BeginningScene',
  'EventScr_Ch5_0',
  'EventScr_Ch5_10',
  'EventScr_Ch5_11',
  'EventScr_Ch5_5',
  'EventScr_Ch5_BeginningScene',
  'EventScr_Ch5_EndingScene',
  'EventScr_Ch5x_BeginningScene',
  'EventScr_Ch5x_EndingScene',
  'EventScr_Ch6_0',
  'EventScr_Ch6_1',
  'EventScr_Ch6_2',
  'EventScr_Ch6_BeginningScene',
  'EventScr_Ch6_EndingScene',
  'EventScr_Ch7_BeginningScene',
  'EventScr_Ch7_EndingScene',
  'EventScr_Ch8_0',
  'EventScr_Ch8_10',
  'EventScr_Ch8_11',
  'EventScr_Ch8_BeginningScene',
  'EventScr_Ch9A_2',
  'EventScr_Ch9A_4',
  'EventScr_Ch9B_9',
  'EventScr_Ch9a_BeginningScene',
  'EventScr_Ch9a_EndingScene',
  'EventScr_ConfigHardModeLoadUnitHard',
  'EventScr_CutsceneExecEnd_Sub0',
  'EventScr_CutsceneExecEnd_Sub1',
  'EventScr_FloorClearInTower',
  'EventScr_FormatFlashingCursor',
  'EventScr_FormatMoveUnit',
  'EventScr_GiveTreasureToLuckyDog',
  'EventScr_LoadUniqueAlly',
  'EventScr_MapSupportConversation',
  'EventScr_MoveUnitS2ToLeader',
  'EventScr_Prologue_BeginningScene',
  'EventScr_Prologue_EndingScene',
  'EventScr_Prologue_GiveRapier',
  'EventScr_Prologue_OneEnemyLeft',
  'EventScr_Prologue_RenaisThroneCutscene',
  'EventScr_Prologue_TutEirikaAttack',
  'EventScr_Prologue_TutMessageTurn2',
  'EventScr_Prologue_Tutorial0',
  'EventScr_Prologue_Tutorial1',
  'EventScr_Prologue_Tutorial4',
  'EventScr_Prologue_TutorialA',
  'EventScr_Prologue_TutorialB',
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
  'EventScr_SetFlagIfPlayedThrough',
  'EventScr_SkirmishRetreat',
  'EventScr_StrictLoadUniqueAlly',
  'EventScr_SuspendPrompt',
  'EventScr_Tutorial_Exec0',
  'EventScr_Tutorial_Exec1',
  'EventScr_UnitFlushingIN',
  'EventScr_UnitFlushingOUT',
  'EventScr_UnitWarpIN',
  'EventScr_UnitWarpOUT',
};

/// 脚本名 → 入口函数
final Map<String, Future<void> Function(Scene)> allSceneFns = {
  'EventScr_9EE84C': scr_9EE84C,
  'EventScr_9EEA58': scr_9EEA58,
  'EventScr_ApplyTileChangeForFaction': ApplyTileChangeForFaction,
  'EventScr_CallIfCommonMode': CallIfCommonMode,
  'EventScr_CallOnChapterNumber': CallOnChapterNumber,
  'EventScr_CallOnHardMode': CallOnHardMode,
  'EventScr_CallOnTutorialMode': CallOnTutorialMode,
  'EventScr_CallWithModeCheck': CallWithModeCheck,
  'EventScr_Ch10A_0': Ch10A_0,
  'EventScr_Ch10A_13': Ch10A_13,
  'EventScr_Ch10A_8': Ch10A_8,
  'EventScr_Ch10B_0': Ch10B_0,
  'EventScr_Ch10B_1': Ch10B_1,
  'EventScr_Ch10B_2': Ch10B_2,
  'EventScr_Ch10a_BeginningScene': Ch10a_BeginningScene,
  'EventScr_Ch10a_EndingScene': Ch10a_EndingScene,
  'EventScr_Ch11B_0': Ch11B_0,
  'EventScr_Ch11B_1': Ch11B_1,
  'EventScr_Ch11B_2': Ch11B_2,
  'EventScr_Ch11B_6': Ch11B_6,
  'EventScr_Ch11a_EndingScene': Ch11a_EndingScene,
  'EventScr_Ch12A_0': Ch12A_0,
  'EventScr_Ch12A_5': Ch12A_5,
  'EventScr_Ch12B_1': Ch12B_1,
  'EventScr_Ch13A_3': Ch13A_3,
  'EventScr_Ch13A_4': Ch13A_4,
  'EventScr_Ch13B_0': Ch13B_0,
  'EventScr_Ch13B_1': Ch13B_1,
  'EventScr_Ch13a_EndingScene': Ch13a_EndingScene,
  'EventScr_Ch13b_EndingScene': Ch13b_EndingScene,
  'EventScr_Ch14A_0': Ch14A_0,
  'EventScr_Ch14A_1': Ch14A_1,
  'EventScr_Ch14A_8': Ch14A_8,
  'EventScr_Ch14B_12': Ch14B_12,
  'EventScr_Ch14B_2': Ch14B_2,
  'EventScr_Ch14b_BeginningScene': Ch14b_BeginningScene,
  'EventScr_Ch14b_EndingScene': Ch14b_EndingScene,
  'EventScr_Ch15A_0': Ch15A_0,
  'EventScr_Ch15A_17': Ch15A_17,
  'EventScr_Ch15A_18': Ch15A_18,
  'EventScr_Ch15A_19': Ch15A_19,
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
  'EventScr_Ch16A_1': Ch16A_1,
  'EventScr_Ch16A_11': Ch16A_11,
  'EventScr_Ch16A_12': Ch16A_12,
  'EventScr_Ch16A_9': Ch16A_9,
  'EventScr_Ch16B_3': Ch16B_3,
  'EventScr_Ch16B_5': Ch16B_5,
  'EventScr_Ch16b_BeginningScene': Ch16b_BeginningScene,
  'EventScr_Ch18A_11': Ch18A_11,
  'EventScr_Ch18b_BeginningScene': Ch18b_BeginningScene,
  'EventScr_Ch19A_11': Ch19A_11,
  'EventScr_Ch1Tut_BeforeSethMoveToEnemy': Ch1Tut_BeforeSethMoveToEnemy,
  'EventScr_Ch1Tut_ChooseSethTurn1': Ch1Tut_ChooseSethTurn1,
  'EventScr_Ch1Tut_EirikaVisitHouseIdle1': Ch1Tut_EirikaVisitHouseIdle1,
  'EventScr_Ch1Tut_EirikaVisitHouseIdle2': Ch1Tut_EirikaVisitHouseIdle2,
  'EventScr_Ch1Tut_EirikaVisitHouseInit': Ch1Tut_EirikaVisitHouseInit,
  'EventScr_Ch1Tut_GuideTerrainHeal': Ch1Tut_GuideTerrainHeal,
  'EventScr_Ch1Tut_OnBeginning': Ch1Tut_OnBeginning,
  'EventScr_Ch1Tut_SethMoveToEnemy': Ch1Tut_SethMoveToEnemy,
  'EventScr_Ch1Tut_TradeSelectGalliamIdle1': Ch1Tut_TradeSelectGalliamIdle1,
  'EventScr_Ch1Tut_TradeSelectGalliamIdle2': Ch1Tut_TradeSelectGalliamIdle2,
  'EventScr_Ch1_BeginningScene': Ch1_BeginningScene,
  'EventScr_Ch1_EndingScene': Ch1_EndingScene,
  'EventScr_Ch1_Turn_AllyReinforceArrive': Ch1_Turn_AllyReinforceArrive,
  'EventScr_Ch20B_1': Ch20B_1,
  'EventScr_Ch20B_2': Ch20B_2,
  'EventScr_Ch20b_BeginningScene': Ch20b_BeginningScene,
  'EventScr_Ch21A_0': Ch21A_0,
  'EventScr_Ch21A_8': Ch21A_8,
  'EventScr_Ch21A_9': Ch21A_9,
  'EventScr_Ch21b_BeginningScene': Ch21b_BeginningScene,
  'EventScr_Ch21b_EndingScene': Ch21b_EndingScene,
  'EventScr_Ch2Tutorial11': Ch2Tutorial11,
  'EventScr_Ch2Tutorial12': Ch2Tutorial12,
  'EventScr_Ch2Tutorial14': Ch2Tutorial14,
  'EventScr_Ch2Tutorial15': Ch2Tutorial15,
  'EventScr_Ch2Tutorial18': Ch2Tutorial18,
  'EventScr_Ch2Tutorial2': Ch2Tutorial2,
  'EventScr_Ch2Tutorial21': Ch2Tutorial21,
  'EventScr_Ch2Tutorial22': Ch2Tutorial22,
  'EventScr_Ch2Tutorial23': Ch2Tutorial23,
  'EventScr_Ch2Tutorial24': Ch2Tutorial24,
  'EventScr_Ch2Tutorial27': Ch2Tutorial27,
  'EventScr_Ch2Tutorial28': Ch2Tutorial28,
  'EventScr_Ch2Tutorial4': Ch2Tutorial4,
  'EventScr_Ch2Tutorial5': Ch2Tutorial5,
  'EventScr_Ch2Tutorial8': Ch2Tutorial8,
  'EventScr_Ch2Tutorial9': Ch2Tutorial9,
  'EventScr_Ch2_10': Ch2_10,
  'EventScr_Ch2_8': Ch2_8,
  'EventScr_Ch2_BeginningScene': Ch2_BeginningScene,
  'EventScr_Ch2_EndingScene': Ch2_EndingScene,
  'EventScr_Ch2_Village1': Ch2_Village1,
  'EventScr_Ch3_0': Ch3_0,
  'EventScr_Ch3_5': Ch3_5,
  'EventScr_Ch3_BeginningScene': Ch3_BeginningScene,
  'EventScr_Ch3_EndingScene': Ch3_EndingScene,
  'EventScr_Ch3_Turn1Npc': Ch3_Turn1Npc,
  'EventScr_Ch4_0': Ch4_0,
  'EventScr_Ch4_1': Ch4_1,
  'EventScr_Ch4_10': Ch4_10,
  'EventScr_Ch4_2': Ch4_2,
  'EventScr_Ch4_BeginningScene': Ch4_BeginningScene,
  'EventScr_Ch5_0': Ch5_0,
  'EventScr_Ch5_10': Ch5_10,
  'EventScr_Ch5_11': Ch5_11,
  'EventScr_Ch5_5': Ch5_5,
  'EventScr_Ch5_BeginningScene': Ch5_BeginningScene,
  'EventScr_Ch5_EndingScene': Ch5_EndingScene,
  'EventScr_Ch5x_BeginningScene': Ch5x_BeginningScene,
  'EventScr_Ch5x_EndingScene': Ch5x_EndingScene,
  'EventScr_Ch6_0': Ch6_0,
  'EventScr_Ch6_1': Ch6_1,
  'EventScr_Ch6_2': Ch6_2,
  'EventScr_Ch6_BeginningScene': Ch6_BeginningScene,
  'EventScr_Ch6_EndingScene': Ch6_EndingScene,
  'EventScr_Ch7_BeginningScene': Ch7_BeginningScene,
  'EventScr_Ch7_EndingScene': Ch7_EndingScene,
  'EventScr_Ch8_0': Ch8_0,
  'EventScr_Ch8_10': Ch8_10,
  'EventScr_Ch8_11': Ch8_11,
  'EventScr_Ch8_BeginningScene': Ch8_BeginningScene,
  'EventScr_Ch9A_2': Ch9A_2,
  'EventScr_Ch9A_4': Ch9A_4,
  'EventScr_Ch9B_9': Ch9B_9,
  'EventScr_Ch9a_BeginningScene': Ch9a_BeginningScene,
  'EventScr_Ch9a_EndingScene': Ch9a_EndingScene,
  'EventScr_ConfigHardModeLoadUnitHard': ConfigHardModeLoadUnitHard,
  'EventScr_CutsceneExecEnd_Sub0': CutsceneExecEnd_Sub0,
  'EventScr_CutsceneExecEnd_Sub1': CutsceneExecEnd_Sub1,
  'EventScr_FloorClearInTower': FloorClearInTower,
  'EventScr_FormatFlashingCursor': FormatFlashingCursor,
  'EventScr_FormatMoveUnit': FormatMoveUnit,
  'EventScr_GiveTreasureToLuckyDog': GiveTreasureToLuckyDog,
  'EventScr_LoadUniqueAlly': LoadUniqueAlly,
  'EventScr_MapSupportConversation': MapSupportConversation,
  'EventScr_MoveUnitS2ToLeader': MoveUnitS2ToLeader,
  'EventScr_Prologue_BeginningScene': Prologue_BeginningScene,
  'EventScr_Prologue_EndingScene': Prologue_EndingScene,
  'EventScr_Prologue_GiveRapier': Prologue_GiveRapier,
  'EventScr_Prologue_OneEnemyLeft': Prologue_OneEnemyLeft,
  'EventScr_Prologue_RenaisThroneCutscene': Prologue_RenaisThroneCutscene,
  'EventScr_Prologue_TutEirikaAttack': Prologue_TutEirikaAttack,
  'EventScr_Prologue_TutMessageTurn2': Prologue_TutMessageTurn2,
  'EventScr_Prologue_Tutorial0': Prologue_Tutorial0,
  'EventScr_Prologue_Tutorial1': Prologue_Tutorial1,
  'EventScr_Prologue_Tutorial4': Prologue_Tutorial4,
  'EventScr_Prologue_TutorialA': Prologue_TutorialA,
  'EventScr_Prologue_TutorialB': Prologue_TutorialB,
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
  'EventScr_SetFlagIfPlayedThrough': SetFlagIfPlayedThrough,
  'EventScr_SkirmishRetreat': SkirmishRetreat,
  'EventScr_StrictLoadUniqueAlly': StrictLoadUniqueAlly,
  'EventScr_SuspendPrompt': SuspendPrompt,
  'EventScr_Tutorial_Exec0': Tutorial_Exec0,
  'EventScr_Tutorial_Exec1': Tutorial_Exec1,
  'EventScr_UnitFlushingIN': UnitFlushingIN,
  'EventScr_UnitFlushingOUT': UnitFlushingOUT,
  'EventScr_UnitWarpIN': UnitWarpIN,
  'EventScr_UnitWarpOUT': UnitWarpOUT,
  'EventScr_9EEAAC': missing_EventScr_9EEAAC,
  'EventScr_Ch1Tut_AfterSethMoveToEnemy': missing_EventScr_Ch1Tut_AfterSethMoveToEnemy,
  'EventScr_Ch1Tut_EirikaVisitHouseEnd': missing_EventScr_Ch1Tut_EirikaVisitHouseEnd,
  'EventScr_Ch1Tut_GilliamBattle': missing_EventScr_Ch1Tut_GilliamBattle,
  'EventScr_Ch1Tut_GuideWTA': missing_EventScr_Ch1Tut_GuideWTA,
  'EventScr_Ch1Tut_TradeSelectGalliamEnd': missing_EventScr_Ch1Tut_TradeSelectGalliamEnd,
  'EventScr_Ch2Tutorial10': missing_EventScr_Ch2Tutorial10,
  'EventScr_Ch2Tutorial13': missing_EventScr_Ch2Tutorial13,
  'EventScr_Ch2Tutorial16': missing_EventScr_Ch2Tutorial16,
  'EventScr_Ch2Tutorial19': missing_EventScr_Ch2Tutorial19,
  'EventScr_Ch2Tutorial25': missing_EventScr_Ch2Tutorial25,
  'EventScr_Ch2Tutorial29': missing_EventScr_Ch2Tutorial29,
  'EventScr_Ch2Tutorial3': missing_EventScr_Ch2Tutorial3,
  'EventScr_Ch2Tutorial6': missing_EventScr_Ch2Tutorial6,
  'EventScr_Ch2_7': missing_EventScr_Ch2_7,
  'EventScr_Ch2_Village2': missing_EventScr_Ch2_Village2,
  'EventScr_Ch3_1': missing_EventScr_Ch3_1,
  'EventScr_Ch3_2': missing_EventScr_Ch3_2,
  'EventScr_Ch3_3': missing_EventScr_Ch3_3,
  'EventScr_Ch3_4': missing_EventScr_Ch3_4,
  'EventScr_Ch4_7': missing_EventScr_Ch4_7,
  'EventScr_Ch4_8': missing_EventScr_Ch4_8,
  'EventScr_Ch4_9': missing_EventScr_Ch4_9,
  'EventScr_Ch5_8': missing_EventScr_Ch5_8,
  'EventScr_Ch5_9': missing_EventScr_Ch5_9,
  'EventScr_Ch6_3': missing_EventScr_Ch6_3,
  'EventScr_Ch7_3': missing_EventScr_Ch7_3,
  'EventScr_ChangeAIinQueue': missing_EventScr_ChangeAIinQueue,
  'EventScr_LoadReinforce': missing_EventScr_LoadReinforce,
  'EventScr_LoadReinforceHardMode': missing_EventScr_LoadReinforceHardMode,
  'EventScr_LoadUnitForTutorial': missing_EventScr_LoadUnitForTutorial,
  'EventScr_Prologue_9EF828': missing_EventScr_Prologue_9EF828,
  'EventScr_Prologue_EirikaAttacked': missing_EventScr_Prologue_EirikaAttacked,
  'EventScr_Prologue_ExecTut': missing_EventScr_Prologue_ExecTut,
  'EventScr_Prologue_ONeillSpawn': missing_EventScr_Prologue_ONeillSpawn,
  'EventScr_Prologue_Tutorial2': missing_EventScr_Prologue_Tutorial2,
  'EventScr_Prologue_Tutorial5': missing_EventScr_Prologue_Tutorial5,
  'EventScr_Prologue_TutorialC': missing_EventScr_Prologue_TutorialC,
  'EventScr_SetBackground': missing_EventScr_SetBackground,
  'EventScr_TextShowWithFadeIn': missing_EventScr_TextShowWithFadeIn,
  'EventScr_UnTriggerIfNotUnit': missing_EventScr_UnTriggerIfNotUnit,
};
