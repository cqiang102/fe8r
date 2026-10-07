// ★ 「話す」用**真实的第 2 章数据**（`EventListScr_Ch2_Character` 的 Eirika↔Ross）。
//
// 出处：`src/TalkCommandUsability.c:50-64`、`src/bmtarget_0802506C.c:283-304`、
//       `src/CheckForCharacterEvents.c:25-41`。
import 'dart:convert';
import 'dart:io';

import 'package:fe8r/core/core.dart';
import 'package:fe8r/game/fe8_game.dart';
import 'package:flutter_test/flutter_test.dart';

/// 从产物里读**真实的**第 2 章 CHAR 条目
List<CharacterEvent> ch2CharEvents() {
  final d = jsonDecode(File('tools/pipeline/out/tables/event_lists.json')
      .readAsStringSync()) as Map<String, dynamic>;
  final lists = (d['lists'] as Map).cast<String, dynamic>();
  final raw = lists['EventListScr_Ch2_Character'] as List;
  return [
    for (final e in raw.cast<Map<String, dynamic>>())
      if (e['cmd'] == 'CHAR')
        CharacterEvent(
          pidA: (e['pidA'] as num).toInt(),
          pidB: (e['pidB'] as num).toInt(),
          doneFlag: (e['doneFlag'] as num?)?.toInt() ?? 0,
          script: e['script'] as String?,
        ),
  ];
}

MapGrid flat() => MapGrid(
      id: 'flat',
      chapter: '',
      width: 6,
      height: 6,
      tileSize: 16,
      metatiles: List<int>.filled(36, 0),
      terrainIndices: List<int>.filled(36, 0),
      terrainLegend: const ['TERRAIN_PLAINS'],
    );

void main() {
  test('★ 話す：艾莉卡(pid 1) 与相邻的罗斯(pid 7) 有对话 ⇒ 命令出现，用了置旗', () async {
    final g = Fe8Game();
    g.loadRuleData();
    final events = ch2CharEvents();
    // 真值抽查：数据里确实有 (1,7) 这一条
    final e17 = events.where((e) => e.pidA == 1 && e.pidB == 7).toList();
    expect(e17, isNotEmpty, reason: '第 2 章应当有 Eirika→Ross 的 CHAR 条目');
    final flag = e17.first.doneFlag;

    final map = flat();
    final f = BattleField(width: 6, height: 6, units: [
      // 艾莉卡：pid 1；罗斯：pid 7（**相邻**）
      MapUnit(id: 1, faction: 0, x: 2, y: 2, charIndex: 1, hp: 20, maxHp: 20),
      MapUnit(id: 2, faction: 0, x: 3, y: 2, charIndex: 7, hp: 20, maxHp: 20),
    ]);
    g.map = map;
    g.field = f;
    g.flow = FlowMachine(
        map: map, costsOf: (u) => MovementCostTable(List<int>.filled(64, 1)));
    g.state = FlowState(phase: FlowPhase.freeCursor, cursorX: 2, cursorY: 2);
    g.playConfig.disableAutoEndTurns = true;
    g.characterEventsForTest = events;

    g.routeInput(FlowInput.confirm);
    g.routeInput(FlowInput.confirm);
    final menu = (g.dumpState()['actionMenu'] as List).cast<String>();
    expect(menu.contains('話す'), isTrue, reason: '菜单=$menu');
    for (var k = 0; k < menu.indexOf('話す'); k++) {
      g.routeInput(FlowInput.down);
    }
    g.routeInput(FlowInput.confirm);
    await Future<void>.delayed(const Duration(milliseconds: 200));

    final t = g.lastTalk;
    expect(t, isNotNull, reason: '★ 对话发生了');
    expect(t!['actorPid'], 1);
    expect(t['targetPid'], 7);
    expect((g.dumpState()['eventFlags'] as List).contains(flag), isTrue,
        reason: '`doneFlag` 置上 ⇒ 同一段对话不会演第二遍');
  });

  test('★ 不匹配的一对（pid 1 与 pid 99）没有「話す」', () async {
    final g = Fe8Game();
    g.loadRuleData();
    final map = flat();
    final f = BattleField(width: 6, height: 6, units: [
      MapUnit(id: 1, faction: 0, x: 2, y: 2, charIndex: 1, hp: 20, maxHp: 20),
      MapUnit(id: 2, faction: 0, x: 3, y: 2, charIndex: 99, hp: 20, maxHp: 20),
    ]);
    g.map = map;
    g.field = f;
    g.flow = FlowMachine(
        map: map, costsOf: (u) => MovementCostTable(List<int>.filled(64, 1)));
    g.state = FlowState(phase: FlowPhase.freeCursor, cursorX: 2, cursorY: 2);
    g.playConfig.disableAutoEndTurns = true;
    g.characterEventsForTest = ch2CharEvents();
    g.routeInput(FlowInput.confirm);
    g.routeInput(FlowInput.confirm);
    final menu = (g.dumpState()['actionMenu'] as List).cast<String>();
    expect(menu.contains('話す'), isFalse, reason: '没有匹配条目 ⇒ 不出现（菜单=$menu）');
  });
}
