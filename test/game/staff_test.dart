// ★ 杖的使用：**治的是目标，不是自己**（这轮修的就是"杖也会治自己"这个 bug）。
//
// 出处：`src/DoUseHealStaff.c:33-46`（流程：先 `func(unit)` 扣次数，再开目标选择）、
//       `src/GetUnitItemHealAmount.c:24+`（治疗量：基础 + `GetUnitPower`，上限 80）、
//       `src/bmtarget_08025BD8.c:152`（`MakeTargetListForAdjacentHeal`）。
import 'dart:convert';
import 'dart:io';

import 'package:fe8r/core/core.dart';
import 'package:fe8r/game/fe8_game.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> items() =>
    jsonDecode(File('tools/pipeline/out/tables/items.json').readAsStringSync())
        as Map<String, dynamic>;

int itemNum(String k) =>
    (((items()['entries'] as Map)[k] as Map)['number'] as num).toInt();

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
  test('★ 杖：施术者扣次数，**同伴**回血，施术者自己**不**回血', () async {
    final g = Fe8Game();
    g.loadRuleData();
    final staffNum = itemNum('ITEM_STAFF_MEND');
    final staff = makeNewItem(staffNum, 20); // 带次数（`MakeNewItem` 表示法）
    final map = flat();
    final f = BattleField(width: 6, height: 6, units: [
      // 施术者 (2,2)，自己也是残血 —— 用来证明"不会顺手治自己"
      MapUnit(id: 1, faction: 0, x: 2, y: 2, classId: 2, hp: 5, maxHp: 20,
          items: [staff, 0, 0, 0, 0]),
      // 相邻的残血同伴
      MapUnit(id: 2, faction: 0, x: 3, y: 2, classId: 2, hp: 3, maxHp: 20),
    ]);
    g.map = map;
    g.field = f;
    g.flow = FlowMachine(
        map: map, costsOf: (u) => MovementCostTable(List<int>.filled(64, 1)));
    g.state = FlowState(phase: FlowPhase.freeCursor, cursorX: 2, cursorY: 2);
    g.playConfig.disableAutoEndTurns = true;

    g.routeInput(FlowInput.confirm);  // 选中
    g.routeInput(FlowInput.confirm);  // 原地确认 → 行动菜单
    g.routeInput(FlowInput.down);     // [待機, 道具]（没有相邻敌人）
    g.routeInput(FlowInput.confirm);  // 进道具菜单
    g.routeInput(FlowInput.confirm);  // 第 1 件（杖）→ 子菜单
    // 子菜单：[使う, 捨てる, 交換?] —— 杖 ⇒ 第 1 项是"使う"
    g.routeInput(FlowInput.confirm);
    await Future<void>.delayed(const Duration(milliseconds: 60));
    expect(g.lastStaffTargetsShown, 1, reason: '只有那个残血同伴可治');
    // 目标选择：确认
    g.routeInput(FlowInput.confirm);
    await Future<void>.delayed(const Duration(milliseconds: 100));

    final s = g.lastStaff;
    expect(s, isNotNull, reason: '★ 杖真的用出去了');
    expect(s!['user'], 1);
    expect(s['target'], 2, reason: '★ 治的是同伴（不是自己）');
    expect(f.unitById(2)!.hp, greaterThan(3), reason: '同伴回血了');
    expect(f.unitById(1)!.hp, 5, reason: '★ 施术者**自己没被治**（这就是这轮修的 bug）');
    expect(itemUses(f.unitById(1)!.items[0]), 19,
        reason: '次数扣了 1（Mend 原始 20 次）');
  });
}
