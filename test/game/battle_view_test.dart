// 战场渲染的**组件复用**测试。
//
// ## 为什么必须有这条
//
// 原来 `BattleView` 每次输入都把整棵组件树拆掉重建（`rebuild()`）。
// 那是把 Flame 当画图 API 用 —— 组件本该有自己的状态与生命周期，
// 而且**全拆全建会让任何跨帧的表现都做不了**（组件在动画进行中就被销毁）。
//
// 改成按 id 复用之后，"复用"这件事必须被**验证**，
// 否则哪天被人改回全拆全建也没人知道 —— 而那种回归在画面上看不出来。
import 'package:fe8r/core/core.dart';
import 'package:fe8r/game/battle_components.dart';
import 'package:fe8r/game/battle_view.dart';
import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';

/// 最小可用的地图：10×10，全平原（地形 0 = TERRAIN_PLAINS，移动消耗 1）。
/// 这些测试关心的是**组件复用**，不是地形规则 —— 所以地形取最简单的。
MapGrid makeMap() => MapGrid(
      id: 'test',
      chapter: 'test',
      width: 10,
      height: 10,
      tileSize: 16,
      metatiles: List.filled(100, 0),
      terrainIndices: List.filled(100, 0),
      terrainLegend: List.filled(256, ''),
    );

BattleField makeField() => BattleField(
      width: 10,
      height: 10,
      units: [
        MapUnit(id: 1, faction: Faction.blue, x: 1, y: 1, name: 'a', classId: 1),
        MapUnit(id: 2, faction: Faction.red, x: 5, y: 5, name: 'b', classId: 1),
      ],
    );

FlowState makeState({int cursorX = 0, int cursorY = 0}) => FlowState(
      phase: FlowPhase.freeCursor,
      cursorX: cursorX,
      cursorY: cursorY,
      selectedUnitId: 0,
    );

UnitComponent? unitOf(BattleView v, int id) => v.layer.children
    .whereType<UnitComponent>()
    .cast<UnitComponent?>()
    .firstWhere((c) => c!.unit.id == id, orElse: () => null);

FlowMachine makeFlow() => FlowMachine(
      map: makeMap(),
      costTable: MovementCostTable(List.filled(64, 1)),
    );

void main() {
  group('BattleView 组件复用', () {
    test('同一批单位重复 sync，组件实例**是同一个**（不是重建）', () {
      final v = BattleView(tileSize: 16);
      final f = makeField();

      v.sync(makeState(), f, makeFlow());
      final first = unitOf(v, 1);
      expect(first, isNotNull);

      // 再同步一次（模拟一次输入）
      v.sync(makeState(cursorX: 1), f, makeFlow());
      final second = unitOf(v, 1);

      expect(identical(first, second), isTrue,
          reason: '组件必须被复用 —— 不 identical 说明又回到"全拆全建"了');
    });

    test('单位移动时只改 position，组件实例不变', () {
      final v = BattleView(tileSize: 16);
      final f = makeField();

      v.sync(makeState(), f, makeFlow());
      final c = unitOf(v, 1)!;
      final before = c.position.clone();

      // 把单位挪一格（core 的 `moveUnit` 会改坐标）
      f.units.first.x = 3;
      f.units.first.y = 4;
      v.sync(makeState(), f, makeFlow());

      final after = unitOf(v, 1)!;
      expect(identical(c, after), isTrue, reason: '实例必须不变');
      expect(after.position, isNot(before), reason: '位置必须跟着更新');
      expect(after.position, Vector2(3 * 16, 4 * 16));
    });

    test('单位死亡后组件被移除', () {
      final v = BattleView(tileSize: 16);
      final f = makeField();
      v.sync(makeState(), f, makeFlow());
      expect(v.componentCount, greaterThanOrEqualTo(2));

      f.units[1].hp = 0; // 打死后 isAlive 为假
      v.sync(makeState(), f, makeFlow());
      expect(unitOf(v, 2), isNull, reason: '死了的组件应当被移除');
      expect(unitOf(v, 1), isNotNull, reason: '活着的不能被顺手删掉');
    });

    test('光标是持久的 —— 只改位置', () {
      final v = BattleView(tileSize: 16);
      final f = makeField();
      v.sync(makeState(), f, makeFlow());
      final c1 = v.layer.children.whereType<CursorComponent>().first;

      v.sync(makeState(cursorX: 2, cursorY: 3), f, makeFlow());
      final c2 = v.layer.children.whereType<CursorComponent>().first;

      expect(identical(c1, c2), isTrue, reason: '光标不该每帧重建');
      expect(c2.position, Vector2(2 * 16, 3 * 16));
    });
  });
}
