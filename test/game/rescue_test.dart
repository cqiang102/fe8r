// ★ 救出 / 降下：游戏层判据（真盘面 + `routeInput`）。
//
// 出处：`src/exact_08018030.c:40-45`（`CanUnitRescue`）、
//       `src/exact_080186cc.c:37-44`（`GetUnitAid`）、
//       `src/exact_08018060.c:37-46`（`UnitRescue`）、`src/UnitDrop.c:31-45`（`UnitDrop`）。
import 'dart:convert';
import 'dart:io';

import 'package:fe8r/core/core.dart';
import 'package:fe8r/game/fe8_game.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> classOf(String key) =>
    (((jsonDecode(File('tools/pipeline/out/tables/classes.json')
                        .readAsStringSync()) as Map<String, dynamic>)['classes']
                as Map)[key] as Map)
        .cast<String, dynamic>();

int numOf(String key) => (classOf(key)['number'] as num).toInt();
int conOf(String key) => (classOf(key)['baseCon'] as num).toInt();

MapGrid flatMap() => MapGrid(
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
  test('★ 救出：相邻同伴被扛起（互记索引 + 挪到同一格）', () async {
    final g = Fe8Game();
    g.loadRuleData();
    final map = flatMap();
    // 挑一个 Con 够大的职业当救人者（数据驱动，不写死职业名）
    final big = ['CLASS_GREAT_KNIGHT', 'CLASS_PALADIN', 'CLASS_GENERAL',
            'CLASS_WYVERN_LORD', 'CLASS_HERO']
        .map((k) => (k, conOf(k), numOf(k)))
        .toList()
      ..sort((a, b) => b.$2.compareTo(a.$2));
    final actorClass = big.first;
    final targetClass = ('CLASS_EIRIKA_LORD', conOf('CLASS_EIRIKA_LORD'),
        numOf('CLASS_EIRIKA_LORD'));
    // Aid(非骑乘) = Con − 1 ⇒ 要 ≥ 目标 Con。不满足就直接跳过（不假装过）
    final aid = actorClass.$2 - 1;
    expect(aid >= targetClass.$2, isTrue,
        reason: '选的救人者 Con 要够（aid=$aid, 目标 con=${targetClass.$2}）');

    final f = BattleField(width: 6, height: 6, units: [
      MapUnit(id: 1, faction: 0, x: 2, y: 2, classId: actorClass.$3, hp: 20, maxHp: 20),
      MapUnit(id: 2, faction: 0, x: 3, y: 2, classId: targetClass.$3, hp: 20, maxHp: 20),
    ]);
    g.map = map;
    g.field = f;
    g.flow = FlowMachine(
        map: map, costsOf: (u) => MovementCostTable(List<int>.filled(64, 1)));
    g.state = FlowState(phase: FlowPhase.freeCursor, cursorX: 2, cursorY: 2);
    g.playConfig.disableAutoEndTurns = true;

    g.routeInput(FlowInput.confirm);   // 选中
    g.routeInput(FlowInput.confirm);   // 原地确认 → 行动菜单
    expect(g.state!.phase, FlowPhase.actionMenu);
    // 菜单 [待機, 救出] ⇒ down 到"救出"
    g.routeInput(FlowInput.down);
    g.routeInput(FlowInput.confirm);
    await Future<void>.delayed(const Duration(milliseconds: 100));

    final r = g.lastRescue;
    expect(r, isNotNull, reason: '★ 救出发生了');
    expect(r!['actor'], 1);
    expect(r['target'], 2);
    expect(f.unitById(1)!.rescueIndex, 2);
    expect(f.unitById(2)!.rescueIndex, 1, reason: '两个方向都记');
    expect(f.unitById(2)!.isHidden, isTrue, reason: '被扛起 ⇒ 隐藏');
    expect(f.unitById(2)!.x, 2, reason: '被救者挪到发起者那一格');

    // ★ 下回合：降ろす（`DropUsability` 要"没行动过"，所以这里把行动标志清掉）
    f.unitById(1)!.hasActed = false;
    g.state = FlowState(phase: FlowPhase.freeCursor, cursorX: 2, cursorY: 2);
    g.routeInput(FlowInput.confirm);
    g.routeInput(FlowInput.confirm);
    expect(g.state!.phase, FlowPhase.actionMenu);
    g.routeInput(FlowInput.down);      // [待機, 降ろす]
    g.routeInput(FlowInput.confirm);
    await Future<void>.delayed(const Duration(milliseconds: 100));

    final d = g.lastDrop;
    expect(d, isNotNull, reason: '★ 降下发生了');
    expect(d!['actor'], 1);
    expect(d['target'], 2);
    expect(f.unitById(2)!.isHidden, isFalse, reason: '重新出现在地图上');
    expect(f.unitById(1)!.rescueIndex, 0);
    expect(f.unitById(2)!.rescueIndex, 0);
    expect(f.unitById(2)!.unselectable, isTrue,
        reason: '★ 我方被降下 ⇒ 当回合不能再动（`US_UNSELECTABLE`）');
    // 落点是相邻格，不再和救人者重叠
    final t2 = f.unitById(2)!;
    expect((t2.x - 2).abs() + (t2.y - 2).abs(), 1, reason: '落在相邻格');
  });
}
