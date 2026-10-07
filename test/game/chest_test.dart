// ★ 「宝箱」整条链，在游戏层验证。
//
// 出处：`ChestCommandUsability`（`src/bmmenu_08023D5C.c:85-97`）、
//       `CanUnitUseChestKeyItem`（`src/CanUnitUseChestKeyItem.c:34-43`）、
//       `GetUnitKeyItemSlotForTerrain`（`src/bmunit_080187B0.c:39-58`）、
//       `StartAvailableTileEvent` 的 `TILE_COMMAND_CHEST` 分支（给 `givenItem` + 开箱）。
import 'dart:convert';
import 'dart:io';

import 'package:fe8r/core/core.dart';
import 'package:fe8r/game/fe8_game.dart';
import 'package:flutter_test/flutter_test.dart';

MapGrid chestMap() => MapGrid(
      id: 'chest',
      chapter: '',
      width: 4,
      height: 4,
      tileSize: 16,
      metatiles: List<int>.filled(16, 0),
      terrainIndices: [0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      terrainLegend: const ['TERRAIN_PLAINS', 'TERRAIN_CHEST_FULL'],
    );

int itemNum(String key) {
  final d = jsonDecode(
      File('tools/pipeline/out/tables/items.json').readAsStringSync())
      as Map<String, dynamic>;
  return (((d['entries'] as Map)[key] as Map)['number'] as num).toInt();
}

void main() {
  test('★ 宝箱：带钥匙站在箱格上 ⇒ 菜单出现宝箱，开了拿到 givenItem', () async {
    final g = Fe8Game();
    g.loadRuleData();
    final map = chestMap();
    final loot = itemNum('ITEM_SWORD_SLIM');   // 宝箱里装什么由条目给
    final key = itemNum('ITEM_CHESTKEY');
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
    // 一条**真实的形状**：`TILE_COMMAND_CHEST` 在 (1,1)，装着 `loot`
    g.locationEventsForTest = [
      LocationEvent(cmd: 'CHES', x: 1, y: 1, cmdId: kTileCommandChest,
          doneFlag: 5, givenItem: loot),
    ];

    g.routeInput(FlowInput.confirm);
    g.routeInput(FlowInput.confirm);
    expect(g.state!.phase, FlowPhase.actionMenu);
    // 菜单：[待機, 宝箱]（没敌人；有道具但那是「道具」项 —— 顺序是 待機/道具/宝箱）
    // ⇒ 用**菜单里宝箱的位置**走：先 down 到宝箱（道具在它前面）
    g.routeInput(FlowInput.down);
    g.routeInput(FlowInput.down);
    g.routeInput(FlowInput.confirm);
    await Future<void>.delayed(const Duration(milliseconds: 100));

    final c = g.lastChest;
    expect(c, isNotNull, reason: '★ 开了宝箱');
    expect(c!['x'], 1);
    expect(c['y'], 1);
    expect(c['givenItem'], loot);
    expect(c['added'], isTrue, reason: '道具进了背包（第 2 格）');
    final inv = (c['inventory'] as List).cast<int>();
    expect(inv[0], key, reason: '钥匙还在 0 号槽');
    expect(inv[1] & 0xFF, loot & 0xFF, reason: '★ 宝箱里的东西真的进来了');
    expect((g.dumpState()['eventFlags'] as List).contains(5), isTrue,
        reason: '`doneFlag` 置上 ⇒ 同一个箱子不能开两次');
  });

  test('没钥匙（也不是盗贼）⇒ 菜单里没有宝箱', () async {
    final g = Fe8Game();
    g.loadRuleData();
    final map = chestMap();
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
    g.locationEventsForTest = [
      LocationEvent(cmd: 'CHES', x: 1, y: 1, cmdId: kTileCommandChest, doneFlag: 5),
    ];
    g.routeInput(FlowInput.confirm);
    g.routeInput(FlowInput.confirm);
    expect(g.state!.phase, FlowPhase.actionMenu);
    g.routeInput(FlowInput.down);   // 只有[待機] ⇒ 绕回
    g.routeInput(FlowInput.confirm);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(g.lastChest, isNull, reason: '没有钥匙/撬锁器 ⇒ 不能开箱');
  });
}
