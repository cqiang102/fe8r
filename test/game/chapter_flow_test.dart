// 章节之间的剧情：**第 1 章 → 第 2 章**。
//
// ## 出处
//
// `src/eventinfo.c:111-127` 与 `:64-77`
//
// ```c
// void MaybeCallEndEvent(void) {
//     if (!CheckFlag(3)) return;             // EVFLAG_WIN
//     if (!ShouldCallEndEvent()) return;     // CheckWin()，演练地图不算
//     CallEndEvent();
// }
//
// void CallEndEvent(void) {
//     const struct ChapterEventGroup* evGroup = GetChapterEventDataPointer(gPlaySt.chapterIndex);
//     if (GetBattleMapKind() != BATTLEMAP_KIND_SKIRMISH)
//         CallEvent(evGroup->endingSceneEvents, 1);   // ★ 本章结束剧情
//     RefreshAllies();
//     SetFlag(0x84);                                  // 只演一次
// }
// ```
//
// 调用点 `PlayerPhase_FinishAction`（`src/PlayerPhase_FinishAction.c:68-80`）：
// **每个我方单位行动结束之后**。
//
// ## 为什么必须有这条
//
// 序章看起来是对的 —— 因为序章的 `EventListScr_Prologue_Misc` 里那条
// `DefeatBoss` 的脚本**恰好就是** `EventScr_Prologue_EndingScene`。
// 但第 1 章的 Misc 条目是**教学提示**（`EventScr_Ch1_Misc_DefeatBoss`），
// 真正的"第 1 章结束剧情"在 `endingSceneEvents` 里，从来没被触发过 ——
// 于是第 1 章永远接不到第 2 章。
import 'package:fe8r/core/core.dart';
import 'package:fe8r/game/fe8_game.dart';
import 'package:flutter_test/flutter_test.dart';

Fe8Game loadTables() {
  final game = Fe8Game();
  game.loadChapterLinksForTest();  // 章节链路（`endingSceneEvents` 在里面）
  game.loadSceneForTest();         // 真剧情 `Scene`（含文本表）
  game.loadRuleData();
  game.skipSceneForTest();         // 不等按键，脚本一路跑到底
  return game;
}

void main() {
  test('★ 第 1 章的结束剧情指向 C00（フレリア城）= 第 1→2 章之间的那一章', () {
    final game = loadTables();
    // 日版脚本末行是 `MNCH(0x38)`，而 0x38 = CHAPTER_CASTLE_FRELIA（C00）
    expect(game.endingSceneNameForTest(1), 'EventScr_Ch1_EndingScene');
    expect(game.endingSceneNameForTest(56), isNull,
        reason: 'C00 的事件组（LordsSplitMapChanges）在本仓库**没有**开场/结束脚本 '
            '—— 第 1→2 章之间的那段剧情还没接上（未查证：C00 走的是世界地图流程）');
  });

  test('章节事件组里有 beginningSceneEvents / endingSceneEvents', () {
    final game = loadTables();
    // 数据来自 `chapter_links.json`（`parse_chapter_links.py` 从
    // `struct ChapterEventGroup` 的字段顺序解出来）
    expect(game.endingSceneNameForTest(0), 'EventScr_Prologue_EndingScene');
    expect(game.endingSceneNameForTest(1), 'EventScr_Ch1_EndingScene');
    expect(game.endingSceneNameForTest(2), 'EventScr_Ch2_EndingScene');
  });

  test('★ 第 1 章拿到 EVFLAG_WIN → 演结束剧情 → **MNCH 进大地图**（目标 C00）',
      () async {
    // ⚠️ 语义变更（照源码改的，不是回归）：
    // 第 1 章结束用的是 `MNCH(56)`（`Ch1_EndingScene` 实测
    // `changeChapter(56, subcmd: 1)`），而 `MNCH` 是 `save_menu_type = 1`
    // ⇒ **先起大地图**（`src/Event2A_MoveToChapter.c:24-31`），
    // 由玩家走到目标节点再出发。原来四条 `MNC*` 生成的是同一个调用，
    // 所以"第 1 章 → C00 之间那段大地图"在流程上根本不存在。
    final game = loadTables();
    game.sceneChapterForTest = 1;
    expect(game.endingSceneNameForTest(1), 'EventScr_Ch1_EndingScene');

    // 没置 EVFLAG_WIN 时**不能**触发
    await game.maybeCallEndEventForTest();
    expect(game.lastEndEventForTest, isNull,
        reason: '没有 EVFLAG_WIN 就不该演结束剧情');
    expect(game.sceneChapterForTest, 1);

    // 置上 EVFLAG_WIN（= `CheckFlag(3)`）
    game.raiseFlagForTest(EventFlags.win);
    await game.maybeCallEndEventForTest();

    expect(game.lastEndEventForTest, 'EventScr_Ch1_EndingScene',
        reason: '★ 应该演第 1 章的结束剧情');
    // ★ 不是第 2 章！日版脚本写的是 `MNCH(0x38)`
    // （`src/data/EventScr_Ch1_EndingScene_ref/dat_EventScr_Ch1_EndingScene_ref.c` 末行），
    // 而 `0x38 = CHAPTER_CASTLE_FRELIA`（`include/constants/chapters.h:67`，
    // 内部名 `C00`）—— 也就是**「フレリア城」那一章间章**。
    // 第 1 章 → 第 2 章之间的剧情，就在这章里（C00 自己的开场/结束脚本）。
    // `MNCH` 只**记下**要去大地图；真的进去要等事件演完
    // （原作是之后的 `EXEC_BM` 起 `ProcScr_WorldMapWrapper`，
    //  直接在事件处理里起会让 WM 盖在正在演的过场上 —— 截图里验证过）
    expect(game.dumpState()['pendingWorldMapTarget'], 56,
        reason: '★ `MNCH(0x38)` = CHAPTER_CASTLE_FRELIA');
    expect(game.worldMap, isNull, reason: '事件还没演完，不该已经在大地图里');
    expect(game.sceneChapterForTest, 1, reason: '还没出发 —— 章节仍是第 1 章');

    // 同一章只演一次（`CallEndEvent` 末尾的 `SetFlag(0x84)`）
    game.sceneChapterForTest = 1;
    game.lastEndEventForTest = null;
    await game.maybeCallEndEventForTest();
    expect(game.lastEndEventForTest, isNull, reason: '0x84 已置上 → 不再重演');
  });
}
