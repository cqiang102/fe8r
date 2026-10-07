// ★ 「踊る」：让一个**已经行动过**的相邻同伴再动一次。
//
// 出处：`src/masked_0802315c.c:64-70`（`CA_DANCE`）、
//       `src/PlayDanceCommandUsabilityCommon.c:50-72`、
//       `src/bmtarget_08025ABC.c:26-53`（目标必须是 `US_UNSELECTABLE` = 已行动）。
// ⚠️ 效果函数我**没定位到**（`RefreshAllies` 是阶段开始的全体刷新，不是它）⇒
//    效果是从"目标必须是已行动的人"推出来的，见 `lib/core/flow/dance.dart` 文件头。
import 'dart:convert';
import 'dart:io';

import 'package:fe8r/core/core.dart';
import 'package:fe8r/game/fe8_game.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> classes() =>
    ((jsonDecode(File('tools/pipeline/out/tables/classes.json')
                .readAsStringSync()) as Map<String, dynamic>)['classes'] as Map)
        .cast<String, dynamic>();

/// 找一个带 `CA_DANCE`（舞娘）的职业
int dancerClass() {
  for (final e in classes().entries) {
    final v = (e.value as Map).cast<String, dynamic>();
    final names = (v['attributeNames'] as List? ?? const []).cast<String>();
    if (names.contains('CA_DANCE')) return (v['number'] as num).toInt();
  }
  fail('classes.json 里没有 CA_DANCE 的职业');
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
  test('★ 踊る：舞娘刷新相邻的已行动同伴（hasActed 变回 false）', () async {
    final g = Fe8Game();
    g.loadRuleData();
    final dCls = dancerClass();
    final map = flat();
    final f = BattleField(width: 6, height: 6, units: [
      // 舞娘 (2,2)，自己没行动过
      MapUnit(id: 1, faction: 0, x: 2, y: 2, classId: dCls, hp: 20, maxHp: 20),
      // 已经行动过的同伴 (3,2) —— 这才是可刷新的目标
      MapUnit(id: 2, faction: 0, x: 3, y: 2, hp: 20, maxHp: 20)
        ..hasActed = true,
      // 还没行动的同伴 (2,3)：**不该**是目标
      MapUnit(id: 3, faction: 0, x: 2, y: 3, hp: 20, maxHp: 20),
    ]);
    g.map = map;
    g.field = f;
    g.flow = FlowMachine(
        map: map, costsOf: (u) => MovementCostTable(List<int>.filled(64, 1)));
    g.state = FlowState(phase: FlowPhase.freeCursor, cursorX: 2, cursorY: 2);
    g.playConfig.disableAutoEndTurns = true;

    g.routeInput(FlowInput.confirm);
    g.routeInput(FlowInput.confirm);
    final menu = (g.dumpState()['actionMenu'] as List).cast<String>();
    expect(menu.contains('踊る'), isTrue, reason: '菜单=$menu');
    for (var k = 0; k < menu.indexOf('踊る'); k++) {
      g.routeInput(FlowInput.down);
    }
    g.routeInput(FlowInput.confirm);
    await Future<void>.delayed(const Duration(milliseconds: 100));

    final d = g.lastDance;
    expect(d, isNotNull, reason: '★ 踊る发生了');
    expect(d!['target'], 2, reason: '★ 刷的是**已行动过**的那个（不是 id 3）');
    expect(f.unitById(2)!.hasActed, isFalse, reason: '★ 刷新后他能再动一次');
    expect(d['targetCanActNow'], isTrue);
    expect(f.unitById(3)!.hasActed, isFalse, reason: 'id 3 本来就没行动过（没被碰）');
  });
}
