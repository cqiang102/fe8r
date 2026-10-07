// ★ 「盗む」：从相邻的红方身上偷走一件 `ITYPE_ITEM` 类道具。
//
// 出处：`src/StealCommandUsability.c:50-64`、`src/AddAsTarget_IfCanStealFrom.c`
//       （只能偷红方、速度不低于对方、只偷 `ITYPE_ITEM`）、
//       `src/IsItemStealable.c`（`GetItemType == ITYPE_ITEM`，即 `weaponType == 9`，
//       见 `include/bmitem.h:93`）。
// ⚠️ 效果是**推导**的（`gSelectInfo_Steal` 的处理不在反编译里）——见 `steal.dart` 文件头。
import 'dart:convert';
import 'dart:io';

import 'package:fe8r/core/core.dart';
import 'package:fe8r/game/fe8_game.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> classes() =>
    ((jsonDecode(File('tools/pipeline/out/tables/classes.json')
                .readAsStringSync()) as Map<String, dynamic>)['classes'] as Map)
        .cast<String, dynamic>();

int classWith(String attr) {
  for (final e in classes().entries) {
    final v = (e.value as Map).cast<String, dynamic>();
    final names = (v['attributeNames'] as List? ?? const []).cast<String>();
    if (names.contains(attr)) return (v['number'] as num).toInt();
  }
  fail('classes.json 里没有 $attr 的职业');
}

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
  test('★ 盗む：偷走红方的伤药（`ITYPE_ITEM`），武器偷不走', () async {
    final g = Fe8Game();
    g.loadRuleData();
    final thiefCls = classWith('CA_STEAL');
    final map = flat();
    final vuln = itemNum('ITEM_VULNERARY');
    final sword = itemNum('ITEM_SWORD_IRON');
    final f = BattleField(width: 6, height: 6, units: [
      // 盗贼 (2,2)：速度用职业成长算（`_profileFor`），所以给他一个高等级的盗贼
      MapUnit(id: 1, faction: 0, x: 2, y: 2, classId: thiefCls, level: 20,
          hp: 20, maxHp: 20),
      // 红方 (3,2)：第 0 件是**剑**（偷不走）、第 1 件是**伤药**（能偷）
      MapUnit(id: 2, faction: Faction.red, x: 3, y: 2,
          classId: classWith('CA_LORD') /* 速度低一点 */, level: 1,
          hp: 20, maxHp: 20,
          items: [makeNewItem(sword, 30), makeNewItem(vuln, 3), 0, 0, 0]),
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
    expect(menu.contains('盗む'), isTrue, reason: '菜单=$menu');
    for (var k = 0; k < menu.indexOf('盗む'); k++) {
      g.routeInput(FlowInput.down);
    }
    g.routeInput(FlowInput.confirm);
    await Future<void>.delayed(const Duration(milliseconds: 100));

    final st = g.lastSteal;
    expect(st, isNotNull, reason: '★ 盗む发生了');
    expect(st!['ok'], isTrue);
    expect(st['target'], 2);
    expect(st['slot'], 1, reason: '★ 第 0 件是剑（`ITYPE_SWORD`）⇒ 跳过后才轮到伤药');
    expect(ItemTable.itemIndex(st['item'] as int), vuln);
    expect(f.unitById(2)!.items[0] & 0xFF, sword, reason: '武器还在对方身上');
    expect(f.unitById(1)!.items[0] & 0xFF, vuln, reason: '★ 伤药进了盗贼的背包');
  });

  test('速度不够 ⇒ 菜单里没有「盗む」', () async {
    final g = Fe8Game();
    g.loadRuleData();
    final thiefCls = classWith('CA_STEAL');
    final map = flat();
    final f = BattleField(width: 6, height: 6, units: [
      MapUnit(id: 1, faction: 0, x: 2, y: 2, classId: thiefCls, level: 1,
          hp: 20, maxHp: 20),
      // 红方等级 20 ⇒ 速度高（用同一套成长算），盗贼 1 级追不上
      MapUnit(id: 2, faction: Faction.red, x: 3, y: 2, classId: thiefCls,
          level: 20, hp: 20, maxHp: 20,
          items: [makeNewItem(itemNum('ITEM_VULNERARY'), 3), 0, 0, 0, 0]),
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
    expect(menu.contains('盗む'), isFalse, reason: '速度不够 ⇒ 不出现（菜单=$menu）');
  });
}
