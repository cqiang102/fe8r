// ★ 交換（子菜单第三项）整条链，在**游戏层**验证。
//
// 出处：`src/bmmenu_08022F50.c:50-66`（`TradeCommandEffect` → 选目标 → `StartTradeMenu`）、
//       `src/bmtrade_0802D520.c:124-135`（`TradeMenu_ApplyItemSwap`：两格对调 + 双方各自压缩）、
//       `src/bmtarget_0802506C.c:81-114`（交换对象条件）。
//
// 为什么在游戏层：这条链要 选中 → 移动 → 行动菜单「道具」→ 子菜单「交換」
// → 选目标 → 选我的槽 → 选对方的槽 六步输入；用 `routeInput` 直接驱动最稳。
import 'dart:convert';
import 'dart:io';

import 'package:fe8r/core/core.dart';
import 'package:fe8r/game/fe8_game.dart';
import 'package:flutter_test/flutter_test.dart';

MapGrid testMap() => MapGrid(
      id: 't',
      chapter: '',
      width: 4,
      height: 4,
      tileSize: 16,
      metatiles: List<int>.filled(16, 0),
      terrainIndices: List<int>.filled(16, 0),
      terrainLegend: const ['TERRAIN_PLAINS'],
    );

int itemNumber(String key) {
  final d = jsonDecode(
      File('tools/pipeline/out/tables/items.json').readAsStringSync())
      as Map<String, dynamic>;
  final e = (d['entries'] as Map).cast<String, dynamic>();
  return ((e[key] as Map)['number'] as num).toInt();
}

int classNumber(String key) {
  final d = jsonDecode(
      File('tools/pipeline/out/tables/classes.json').readAsStringSync())
      as Map<String, dynamic>;
  final c = (d['classes'] as Map).cast<String, dynamic>();
  return ((c[key] as Map)['number'] as num).toInt();
}

void main() {
  test('★ 交換：两格对调 + 双方各自压缩（游戏层六步输入）', () async {
    final g = Fe8Game();
    g.loadRuleData();
    final sword = itemNumber('ITEM_SWORD_IRON');
    final vuln = itemNumber('ITEM_VULNERARY');
    final cls = classNumber('CLASS_EIRIKA_LORD');
    final map = testMap();
    // 我：(1,1) 带铁剑；同伴：(2,1) 带伤药（两人相邻、同阵营、0 号槽都非空）
    final f = BattleField(width: 4, height: 4, units: [
      MapUnit(id: 1, faction: 0, x: 1, y: 1, classId: cls, hp: 20, maxHp: 20,
          items: [sword, 0, 0, 0, 0]),
      MapUnit(id: 2, faction: 0, x: 2, y: 1, classId: cls, hp: 20, maxHp: 20,
          items: [vuln, 0, 0, 0, 0]),
    ]);
    g.map = map;
    g.field = f;
    g.flow = FlowMachine(
        map: map, costsOf: (u) => MovementCostTable(List<int>.filled(64, 1)));
    g.state = FlowState(phase: FlowPhase.freeCursor, cursorX: 1, cursorY: 1);
    g.playConfig.disableAutoEndTurns = true;   // 同 `player_attack_test`：无头测试不演横幅

    // 选中 → 原地确认 → 行动菜单：选「道具」（第 3 项，菜单 [待機, 攻撃?, 道具]）
    g.routeInput(FlowInput.confirm);
    g.routeInput(FlowInput.confirm);
    expect(g.state!.phase, FlowPhase.actionMenu, reason: 'committedMove ⇒ 行动菜单');
    // 没有相邻敌人 ⇒ 菜单是 [待機, 道具] ⇒ down 一次到「道具」
    g.routeInput(FlowInput.down);
    g.routeInput(FlowInput.confirm);
    // 道具菜单：第 1 件（铁剑）→ 子菜单
    g.update(0.016);
    expect(g.state!.phase, FlowPhase.itemMenu, reason: '进道具菜单');
    g.routeInput(FlowInput.confirm);
    // 子菜单：铁剑 ⇒ [装備, 捨てる, 交換]（交換在最后）
    g.routeInput(FlowInput.down);
    g.routeInput(FlowInput.down);
    g.routeInput(FlowInput.confirm);
    // 目标 → 我的槽 → 对方的槽
    g.routeInput(FlowInput.confirm);
    g.routeInput(FlowInput.confirm);
    g.routeInput(FlowInput.confirm);
    await Future<void>.delayed(const Duration(milliseconds: 100));

    final tr = g.lastTrade;
    expect(tr, isNotNull, reason: '★ 真的换了一次（欠账 31 的"交換未实现"到此结束）');
    final me = g.field!.unitById(1)!;
    final other = g.field!.unitById(2)!;
    expect(me.items[0], vuln, reason: '★ 我拿到了对方的伤药');
    expect(other.items[0], sword, reason: '★ 对方拿到了我的铁剑');
    expect(tr!['beforeMe'], [sword, 0, 0, 0, 0]);
    expect(tr['beforeOther'], [vuln, 0, 0, 0, 0]);
    expect('${g.dumpState()['lastTradeMenuText']}'.contains('交換'), isTrue,
        reason: '交易界面留下了文本（判据能回看）');
  });
}
