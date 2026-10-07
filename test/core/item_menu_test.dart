import 'package:fe8r/core/core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('itemMenu 阶段按确认 ⇒ 发出 itemUseIndex', () {
    final map = MapGrid(
      id: 't', chapter: '', width: 3, height: 3, tileSize: 16,
      metatiles: List<int>.filled(9, 0),
      terrainIndices: List<int>.filled(9, 0),
      terrainLegend: const ['TERRAIN_PLAINS'],
    );
    final fl = FlowMachine(map: map, costsOf: (u) => MovementCostTable(List<int>.filled(64, 1)))
      ..itemSlotCount = 1
      ..hasUsableItem = true;
    final f = BattleField(width: 3, height: 3, units: [
      MapUnit(id: 13, faction: 0, x: 1, y: 1, hp: 13, maxHp: 20, items: [876]),
    ]);
    final s = FlowState(
      phase: FlowPhase.itemMenu, cursorX: 1, cursorY: 1,
      selectedUnitId: 13, pendingX: 1, pendingY: 1, itemIndex: 0,
    );
    final r = fl.advance(s, f, FlowInput.confirm);
    expect(r.itemUseIndex, 0, reason: '确认 = 用第 0 个可用槽');
    expect(r.committedMove, isTrue, reason: '用道具等同于提交这次行动');
    expect(r.state.phase, FlowPhase.freeCursor);
  });

  test('itemMenu 上下移动夹在可用槽数内', () {
    final map = MapGrid(
      id: 't', chapter: '', width: 3, height: 3, tileSize: 16,
      metatiles: List<int>.filled(9, 0),
      terrainIndices: List<int>.filled(9, 0),
      terrainLegend: const ['TERRAIN_PLAINS'],
    );
    final fl = FlowMachine(map: map, costsOf: (u) => MovementCostTable(List<int>.filled(64, 1)))
      ..itemSlotCount = 2;
    final f = BattleField(width: 3, height: 3, units: [
      MapUnit(id: 1, faction: 0, x: 0, y: 0, items: [876, 5143]),
    ]);
    var s = FlowState(phase: FlowPhase.itemMenu, cursorX: 0, cursorY: 0,
        selectedUnitId: 1, pendingX: 0, pendingY: 0);
    s = fl.advance(s, f, FlowInput.down).state;
    expect(s.itemIndex, 1);
    s = fl.advance(s, f, FlowInput.down).state;
    expect(s.itemIndex, 0, reason: '2 槽 ⇒ 回绕到 0');
    s = fl.advance(s, f, FlowInput.cancel).state;
    expect(s.phase, FlowPhase.actionMenu, reason: '取消回行动菜单');
  });
}
