// ★ 「制圧」整条链，用**真实的第 1 章数据**（`EventListScr_Ch1_Location` 的 (2,2)）。
//
// 出处：`UnitActionMenu_CanSeize`（`src/bmmenu_08022F50.c:68-80`）、
//       `CanUnitSeize`（`src/masked_08037bfc.c:50-70`：按 `chapterModeIndex` 选领袖，
//       第 5 章特例）、`include/eventinfo.h:15`（`TILE_COMMAND_SEIZE = 0x11`）。
import 'dart:convert';
import 'dart:io';

import 'package:fe8r/core/core.dart';
import 'package:fe8r/game/fe8_game.dart';
import 'package:flutter_test/flutter_test.dart';

/// 15×10 全平原（第 1 章的地图尺寸），(2,2) 是制圧点
MapGrid ch1LikeMap() => MapGrid(
      id: 'ch1like',
      chapter: '',
      width: 15,
      height: 10,
      tileSize: 16,
      metatiles: List<int>.filled(150, 0),
      terrainIndices: List<int>.filled(150, 0),
      terrainLegend: const ['TERRAIN_PLAINS'],
    );

/// 从产物里读**真实的**第 1 章 Location 条目（`EventListScr_Ch1_Location`）
List<LocationEvent> ch1LocationEvents() {
  final f = File('tools/pipeline/out/tables/event_lists.json');
  if (!f.existsSync()) fail('缺少 ${f.path}（先跑 parse_event_lists.py）');
  final d = jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
  final lists = (d['lists'] as Map).cast<String, dynamic>();
  return [
    for (final e in (lists['EventListScr_Ch1_Location'] as List)
        .cast<Map<String, dynamic>>())
      if (e['cmd'] == 'VILL' || e['cmd'] == 'LOCA')
        LocationEvent(
          cmd: '${e['cmd']}',
          x: (e['x'] as num).toInt(),
          y: (e['y'] as num).toInt(),
          cmdId: (e['cmdId'] as num).toInt(),
          doneFlag: (e['doneFlag'] as num?)?.toInt() ?? 0,
          script: e['script'] as String?,
        ),
  ];
}

void main() {
  test('★ 制圧：艾莉卡站在 (2,2) ⇒ 菜单出现制圧，用了会走章节结束', () async {
    final g = Fe8Game();
    g.loadRuleData();
    g.loadChapterLinksForTest();
    g.sceneChapterForTest = 1;          // 第 1 章
    g.chapterModeIndex = 1;             // 教学（＝艾莉卡）——`CanUnitSeize` 的模式 1
    final map = ch1LikeMap();
    // 艾莉卡：`CHARACTER_EIRIKA = 1`（`include/constants/characters.h`）
    final f = BattleField(width: 15, height: 10, units: [
      MapUnit(id: 1, faction: 0, x: 2, y: 2, charIndex: 1, hp: 20, maxHp: 20),
    ]);
    g.map = map;
    g.field = f;
    g.flow = FlowMachine(
        map: map, costsOf: (u) => MovementCostTable(List<int>.filled(64, 1)));
    g.state = FlowState(phase: FlowPhase.freeCursor, cursorX: 2, cursorY: 2);
    g.playConfig.disableAutoEndTurns = true;
    // ★ 用**真实的第 1 章 Location 数据**（不依赖游戏的加载顺序）
    g.locationEventsForTest = ch1LocationEvents();

    g.routeInput(FlowInput.confirm);   // 选中
    g.routeInput(FlowInput.confirm);   // 原地确认 → 行动菜单
    expect(g.state!.phase, FlowPhase.actionMenu);
    // 菜单：[待機, 制圧]（没道具、没敌人）⇒ down 到制圧
    g.routeInput(FlowInput.down);
    g.routeInput(FlowInput.confirm);
    await Future<void>.delayed(const Duration(milliseconds: 200));

    final sz = g.lastSeize;
    expect(sz, isNotNull, reason: '★ 制圧发生了（章节结束的正规入口）');
    expect(sz!['x'], 2);
    expect(sz['y'], 2);
    expect(sz['doneFlag'], 3, reason: '条目里的 `doneFlag` 来自数据');
    expect(g.dumpState()['chapterModeIndex'], 1);
  });

  test('★ 非领袖（赛特，charIndex 2）在同一个格子上**没有**制圧', () async {
    final g = Fe8Game();
    g.loadRuleData();
    g.loadChapterLinksForTest();
    g.sceneChapterForTest = 1;
    g.chapterModeIndex = 1;
    final map = ch1LikeMap();
    final f = BattleField(width: 15, height: 10, units: [
      MapUnit(id: 1, faction: 0, x: 2, y: 2, charIndex: 2, hp: 20, maxHp: 20),
    ]);
    g.map = map;
    g.field = f;
    g.flow = FlowMachine(
        map: map, costsOf: (u) => MovementCostTable(List<int>.filled(64, 1)));
    g.state = FlowState(phase: FlowPhase.freeCursor, cursorX: 2, cursorY: 2);
    g.playConfig.disableAutoEndTurns = true;
    g.locationEventsForTest = ch1LocationEvents();
    g.routeInput(FlowInput.confirm);
    g.routeInput(FlowInput.confirm);
    expect(g.state!.phase, FlowPhase.actionMenu);
    g.routeInput(FlowInput.down);       // 只有[待機] ⇒ 绕回 0
    g.routeInput(FlowInput.confirm);
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(g.lastSeize, isNull, reason: '`CanUnitSeize` 为假 ⇒ 没有制圧这一项');
  });
}
