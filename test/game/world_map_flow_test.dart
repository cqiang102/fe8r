// `MNCH` 走**大地图**这条链 —— 规则层接进游戏层了吗？
//
// ## 为什么必须有这条
//
// 原来 `MNCH` / `MNC2` / `MNC3` / `MNC4` 四条命令生成的是**同一个调用**
// （`s.changeChapter(n)`），于是"第 1 章 → C00 之间那段大地图"在流程上
// 根本不存在。而原作里它们是两条路：
//
//   * `MNC2`(2) → `save_menu_type = 2` → `CheckNewGameAndBranch` 命中 2/4
//     ⇒ **直接进地图**（序章结束就是这条：`Prologue_EndingScene` 实测 `subcmd: 2`）
//   * `MNCH`(1) → `save_menu_type = 1` → 起 `ProcScr_WorldMapWrapper`
//     ⇒ **先走大地图**（第 1 章结束实测 `Ch1_EndingScene` → `changeChapter(56, subcmd: 1)`）
//
// 出处：`src/Event2A_MoveToChapter.c:22-57`、
//       `src/worldmap_main_080BF178.c:104-117`（`WMLoc_GetNextLocId` → `WMLoc_GetChapterId`）、
//       `src/worldmap_path.c:148`（部队节点初值 0）
//
// 判据是**游戏层状态**（不是"没抛异常"）：进 WM → 节点与下一个节点对不对 →
// 确认能不能走到目标节点 → 到了目标才切章。
import 'package:fe8r/game/fe8_game.dart';
import 'package:flutter_test/flutter_test.dart';

Fe8Game loadGame() {
  final game = Fe8Game();
  game.loadChapterLinksForTest();
  game.loadRuleData();
  return game;
}

void main() {
  test('★ `MNCH` 进大地图；目标章节 56（C00）且站在节点 0', () {
    final g = loadGame();
    expect(g.worldMap, isNull, reason: '一开始不该在大地图里');
    g.enterWorldMapForTest(0x38);
    final wm = g.worldMap;
    expect(wm, isNotNull, reason: '`MNCH` 必须进大地图（原来直接切章了）');
    expect(wm!.node, 0, reason: '部队节点初值照 `src/worldmap_path.c:148` = 0');
    expect(g.waitingFor, 'worldMap:node=0', reason: '诊断串要指出停在大地图');
  });

  test('★ 节点 0 的条件旗没置上时"走不动"，且**响亮**（不静默）', () {
    final g = loadGame();
    g.enterWorldMapForTest(0x38);
    // `gWMNodeData[0].unk_06 = 137`（`CheckFlag` 的条件旗）
    final note = g.dumpState()['worldMapNote'] as String? ?? '';
    expect(note, contains('137'),
        reason: '没有下一个目的地必须写清是哪个旗没置上：$note');
  });

  test('★ 置上旗 137 后：节点 0 → 1，而节点 1 就是 C00', () {
    final g = loadGame();
    g.eventFlags.add(137);
    g.enterWorldMapForTest(0x38);
    final wm = g.worldMap!;
    expect(wm.node, 0);
    expect(g.dumpState()['worldMapNote'], '', reason: '有路可走就不该有告警');
    // 走一步：确认键
    g.worldMapConfirmForTest();
    expect(g.worldMap!.node, 1,
        reason: '旗 137 置上 → `unk_08 + 2` 那一对 → 下一个节点是 1');
  });

  test('★ 站在目标节点上确认 = 出发（离开大地图）', () async {
    final g = loadGame();
    g.eventFlags.add(137);
    g.enterWorldMapForTest(0x38);
    await g.worldMapConfirmForTest(); // 0 → 1（C00 的节点）
    expect(g.worldMap!.node, 1);
    await g.worldMapConfirmForTest(); // 站在 C00 节点上 → 出发
    expect(g.worldMap, isNull, reason: '出发后必须退出大地图模式');
    expect(g.dumpState()['worldMapTarget'], isNull);
    // 出发时演的章间脚本必须是**数据说的那一条**
    // （`Events_WM_Beginning[gmapEventId]`，见 `worldmap.json.chapterWm`）
    expect(g.dumpState()['lastWmBeginningScript'],
        'EventScrWM_CastleFrelia_Beginning');
  });

  test('`MNC2`（序章结束那条）**不进**大地图 —— 不能一刀切', () {
    // 序章结束是 `changeChapter(1, subcmd: 2)`（实测 `scene_data.g.dart`）。
    // 这条走 `_gotoChapter`，所以 `worldMap` 保持 null。
    final g = loadGame();
    expect(g.worldMap, isNull);
    expect(g.dumpState()['worldMap'], isNull);
  });
}
