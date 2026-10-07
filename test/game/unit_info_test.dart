// ★ 光标所指单位的**信息窗**内容（原作 `struct UnitInfoWindowProc`）。
//
// 出处：`src/StartUnitHpInfoWindow.c:22-26`（`struct Text name; struct Text lines[5];`）、
//       `src/RefreshUnitInventoryInfoWindow.c:41-47`
//       （行数 = `itemCount != 0 ? itemCount : 1` ⇒ **空手也占 1 行**）。
import 'dart:convert';
import 'dart:io';

import 'package:fe8r/core/core.dart';
import 'package:fe8r/game/fe8_game.dart';
import 'package:flutter_test/flutter_test.dart';

int itemNum(String k) =>
    ((((jsonDecode(File('tools/pipeline/out/tables/items.json')
                        .readAsStringSync()) as Map<String, dynamic>)['entries']
                    as Map)[k]) as Map)['number'] as int;

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
  test('★ 信息窗：名字 + 道具行（行数 = 道具数）；空手也有 1 行', () async {
    final g = Fe8Game();
    g.loadRuleData();
    final map = flat();
    final f = BattleField(width: 6, height: 6, units: [
      MapUnit(id: 1, faction: 0, x: 2, y: 2, hp: 13, maxHp: 20, name: '赛特',
          items: [
            makeNewItem(itemNum('ITEM_SWORD_IRON'), 46),
            makeNewItem(itemNum('ITEM_VULNERARY'), 3),
            0, 0, 0
          ]),
      MapUnit(id: 2, faction: 0, x: 4, y: 4, hp: 20, maxHp: 20, name: '空手的人'),
    ]);
    g.map = map;
    g.field = f;
    g.flow = FlowMachine(
        map: map, costsOf: (u) => MovementCostTable(List<int>.filled(64, 1)));
    g.state = FlowState(phase: FlowPhase.freeCursor, cursorX: 2, cursorY: 2);
    g.playConfig.disableAutoEndTurns = true;

    var info = g.dumpState()['unitInfo'] as Map?;
    expect(info, isNotNull, reason: '光标在单位上 ⇒ 有信息窗');
    expect(info!['name'], '赛特');
    expect(info['hp'], 13);
    expect(info['maxHp'], 20);
    expect(info['itemCount'], 2);
    expect((info['lines'] as List).length, 2, reason: '行数 = 道具数');
    // ⚠️ 这里断言**原始道具名**（`ITEM_SWORD_IRON`）：测试没载入文本表 ⇒
    //    `_itemLabel` 走兜底返回枚举名。**这正是我们要的"查不到就显式露出"**，
    //    而不是悄悄显示一个空串。实战里文本表是载入的（会显示"铁剑"）。
    expect('${(info['lines'] as List)[0]}', 'ITEM_SWORD_IRON');

    // 空手的单位：**仍然有 1 行**（`itemCount != 0 ? itemCount : 1`）
    g.state = FlowState(phase: FlowPhase.freeCursor, cursorX: 4, cursorY: 4);
    info = g.dumpState()['unitInfo'] as Map?;
    expect(info!['itemCount'], 0);
    expect((info['lines'] as List).length, 1, reason: '★ 空手也占 1 行（照源码）');

    // 光标在空格上 ⇒ 没有信息窗
    g.state = FlowState(phase: FlowPhase.freeCursor, cursorX: 0, cursorY: 0);
    expect(g.dumpState()['unitInfo'], isNull);
  });
}
