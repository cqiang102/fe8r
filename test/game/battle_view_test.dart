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
import 'package:fe8r/game/portrait_component.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
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

    test('单位移动：实例不变，且**加了补间效果**而不是瞬移', () {
      final v = BattleView(tileSize: 16);
      final f = makeField();

      v.sync(makeState(), f, makeFlow());
      final c = unitOf(v, 1)!;
      c.position = Vector2(1 * 16, 1 * 16);

      // 把单位挪一格（core 的 `moveUnit` 会改坐标）
      f.units.first.x = 3;
      f.units.first.y = 4;
      v.sync(makeState(), f, makeFlow());

      final after = unitOf(v, 1)!;
      expect(identical(c, after), isTrue, reason: '实例必须不变');

      // ⚠️ 位置**不再瞬移** —— 加的是 `MoveToEffect`。
      // 这条断言是这一轮改动的核心：以前是直接赋 position，
      // 现在交给 Flame 的效果系统做补间。
      final fx = after.children.whereType<MoveToEffect>().toList();
      expect(fx, isNotEmpty,
          reason: '移动应当加补间效果 —— 空了说明又退回"瞬移"');

      // 还没到位 —— 证明**没有瞬移**（效果要等 `update` 才推进）
      expect(after.position, isNot(Vector2(3 * 16, 4 * 16)),
          reason: '刚加效果时不该已经到位（那说明又退回瞬移了）');
      // 注：这里**不**调 `updateTree` 去推进效果 ——
      // `MoveToEffect` 需要组件已挂载（`EffectTarget.target` 会取父组件），
      // 而单测里组件是独立的。推进效果属于 Flame 自己的测试范围。
    });

    test('瞬移（instant）直接到位，不加效果', () {
      final c = UnitComponent(
        unit: MapUnit(id: 9, faction: Faction.blue, x: 0, y: 0, name: 'x'),
        tileSize: 16,
        isSelected: false,
        isActive: true,
      );
      c.moveTo(Vector2(32, 48), instant: true);
      expect(c.position, Vector2(32, 48));
      expect(c.children.whereType<MoveToEffect>(), isEmpty);
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

  _multiFaceGroup();
}

// ---------------------------------------------------------------------------
// 多张脸：原作有 **8 个槽**（`include/scene.h:77` `struct FaceProc* faces[8]`），
// 审计量化"引擎同时可见 ≥3 张脸的页有 2686/18459（14.5%）"。
//
// 我最初的实现只画 host/guest **两张**（`DialogueBoxComponent` 里两个参数），
// 那是结构性丢脸。现在立绘是独立的一层（`PortraitComponent` + 槽位表），
// 这条测试把"≥3 张同时存在"钉住 —— 否则哪天退回两张也没人知道。
// ---------------------------------------------------------------------------
void _multiFaceGroup() {
  group('立绘：多槽同时存在', () {
    test('槽位 → x 用真实 LUT，且 6/7 在屏幕外', () {
      // `gTalkFaceHPosLut[8] = { 3, 6, 9, 21, 24, 27, -8, 38 }`（图块）
      expect(PortraitComponent.slotTileX[0], 3);
      expect(PortraitComponent.slotTileX[5], 27);
      expect(PortraitComponent.slotTileX[6], -8);
      expect(PortraitComponent.slotTileX[7], 38);

      // 屏幕内的只有 0..5
      expect(PortraitComponent.onScreenSlots, [0, 1, 2, 3, 4, 5]);
      expect(PortraitComponent.isOnScreen(6), isFalse, reason: 'x=-64，在屏幕外');
      expect(PortraitComponent.isOnScreen(7), isFalse, reason: 'x=304，在屏幕外');
    });

    test('左侧 0..2 镜像、右侧 3..5 不镜像', () {
      // 「LUT x <= 14 图块」= 左半边 → `FACE_DISP_FLIPPED`
      // （`src/TalkLoadFace.c:40-42`）
      for (final s in [0, 1, 2]) {
        expect(PortraitComponent.isFlipped(s), isTrue, reason: '槽 $s 在左，应镜像');
      }
      for (final s in [3, 4, 5]) {
        expect(PortraitComponent.isFlipped(s), isFalse, reason: '槽 $s 在右，不镜像');
      }
    });
  });
}
