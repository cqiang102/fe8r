// ★ 「扉」整条链，在游戏层验证。
//
// 出处：`DoorCommandUsability`（`src/bmmenu_08023D5C.c:58-72`）、
//       `IsThereClosedDoorAt`（`src/eventinfo_08085528.c:141-147`）、
//       `MakeTargetListForDoorAndBridges`（`src/bmtarget_0802506C.c:414-432`：**相邻**）、
//       `GetUnitKeyItemSlotForTerrain` 的 `TERRAIN_DOOR` 支（`src/bmunit_080187B0.c:39-58`）。
import 'dart:convert';
import 'dart:io';

import 'package:fe8r/core/core.dart';
import 'package:fe8r/game/fe8_game.dart';
import 'package:flutter_test/flutter_test.dart';

/// 4×4：**我 (1,1)**，**(1,0) 是门**（图例索引 1 = `TERRAIN_DOOR`）
MapGrid doorMap() => MapGrid(
      id: 'door',
      chapter: '',
      width: 4,
      height: 4,
      tileSize: 16,
      metatiles: List<int>.filled(16, 0),
      terrainIndices: [0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      terrainLegend: const ['TERRAIN_PLAINS', 'TERRAIN_DOOR'],
    );

int itemNum(String key) =>
    ((((jsonDecode(File('tools/pipeline/out/tables/items.json')
                        .readAsStringSync()) as Map<String, dynamic>)['entries']
                    as Map)[key]) as Map)['number'] as int;

void main() {
  test('★ 扉：带门钥匙站在门旁 ⇒ 菜单出现扉，开了置旗', () async {
    final g = Fe8Game();
    g.loadRuleData();
    final map = doorMap();
    final key = itemNum('ITEM_DOORKEY');
    final f = BattleField(width: 4, height: 4, units: [
      MapUnit(id: 1, faction: 0, x: 1, y: 1, hp: 20, maxHp: 20,
          items: [key, 0, 0, 0, 0]),
    ]);
    g.map = map;
    g.field = f;
    g.flow = FlowMachine(
        map: map, costsOf: (u) => MovementCostTable(List<int>.filled(64, 1)));
    g.state = FlowState(phase: FlowPhase.freeCursor, cursorX: 1, cursorY: 1);
    g.playConfig.disableAutoEndTurns = true;
    // (1,0) 那条门（`cmdId 0x12`）
    g.locationEventsForTest = const [
      LocationEvent(cmd: 'DOOR', x: 1, y: 0, cmdId: kTileCommandDoor,
          doneFlag: 9, script: '0x1'),
    ];

    g.routeInput(FlowInput.confirm);
    g.routeInput(FlowInput.confirm);
    expect(g.state!.phase, FlowPhase.actionMenu);
    // 菜单：[待機, 道具, 扉] ⇒ down×2 到扉
    g.routeInput(FlowInput.down);
    g.routeInput(FlowInput.down);
    g.routeInput(FlowInput.confirm);
    await Future<void>.delayed(const Duration(milliseconds: 100));

    final d = g.lastDoor;
    expect(d, isNotNull, reason: '★ 开了门');
    expect(d!['target'], '1,0', reason: '目标是相邻的门格');
    expect(d['doneFlag'], 9);
    expect((g.dumpState()['eventFlags'] as List).contains(9), isTrue);
    expect(d['tileChangeImplemented'], isFalse,
        reason: '如实记录：地形变化本身还没做');
  });

  test('没钥匙 ⇒ 菜单里没有扉', () async {
    final g = Fe8Game();
    g.loadRuleData();
    final map = doorMap();
    final f = BattleField(width: 4, height: 4, units: [
      MapUnit(id: 1, faction: 0, x: 1, y: 1, hp: 20, maxHp: 20,
          items: [0, 0, 0, 0, 0]),
    ]);
    g.map = map;
    g.field = f;
    g.flow = FlowMachine(
        map: map, costsOf: (u) => MovementCostTable(List<int>.filled(64, 1)));
    g.state = FlowState(phase: FlowPhase.freeCursor, cursorX: 1, cursorY: 1);
    g.playConfig.disableAutoEndTurns = true;
    g.locationEventsForTest = const [
      LocationEvent(cmd: 'DOOR', x: 1, y: 0, cmdId: kTileCommandDoor, doneFlag: 9),
    ];
    g.routeInput(FlowInput.confirm);
    g.routeInput(FlowInput.confirm);
    g.routeInput(FlowInput.down);
    g.routeInput(FlowInput.confirm);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(g.lastDoor, isNull, reason: '没有门钥匙/撬锁器 ⇒ 不能开门');
  });
}
