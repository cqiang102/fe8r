// 交互流程状态机的测试。
//
// 这一层**没有 C Oracle 可对照**——它是重写，不是移植。
// 所以判据换成三条：
//   1. 状态迁移符合设计（每条输入在每个阶段的行为都被钉死）
//   2. **完全可序列化**：任意状态编码再解码必须等价
//   3. 不会产生非法状态（光标越界、选中敌方单位、走进不可达格）
//
// 第 2 条是技术方案 §4.4「任意时刻存档」的硬要求，也是把流程写成
// 显式状态机而不是 async 协程的全部理由。
import 'dart:io';

import 'package:fe8r/core/core.dart';
import 'package:flutter_test/flutter_test.dart';

/// 造一张全平原的小地图（用真实导出的那张，保证地形数据是真的）
MapGrid _testMap() =>
    MapGrid.parse(File('assets/maps/prologue.json').readAsStringSync());

/// 全地形消耗 1，便于手算移动范围
MovementCostTable _flatCosts() {
  final c = List<int>.filled(65, 1);
  c[0] = 255; // TERRAIN_NONE 不可通行
  return MovementCostTable(c);
}

BattleField _field() => BattleField(
      width: 15,
      height: 10,
      activeFaction: Faction.blue,
      units: [
        MapUnit(id: 1, faction: Faction.blue, x: 2, y: 2, movement: 3, name: 'Eirika'),
        MapUnit(id: 2, faction: Faction.blue, x: 5, y: 5, movement: 2, name: 'Seth'),
        MapUnit(id: 0x81, faction: Faction.red, x: 8, y: 8, movement: 4, name: 'Fighter'),
      ],
    );

void main() {
  late MapGrid map;
  late MovementCostTable costs;
  late FlowMachine machine;

  setUp(() {
    map = _testMap();
    costs = _flatCosts();
    machine = FlowMachine(map: map, costTable: costs);
  });

  FlowState start() =>
      FlowState(phase: FlowPhase.freeCursor, cursorX: 2, cursorY: 2);

  group('交互流程状态机', () {
    test('光标移动被夹在地图内', () {
      var s = start();
      final f = _field();
      // 往左上狂推，不应越界
      for (var i = 0; i < 20; i++) {
        s = machine.advance(s, f, FlowInput.left).state;
        s = machine.advance(s, f, FlowInput.up).state;
      }
      expect(s.cursorX, 0);
      expect(s.cursorY, 0);

      for (var i = 0; i < 40; i++) {
        s = machine.advance(s, f, FlowInput.right).state;
        s = machine.advance(s, f, FlowInput.down).state;
      }
      expect(s.cursorX, map.width - 1);
      expect(s.cursorY, map.height - 1);
    });

    test('确认能选中我方单位并算出移动范围', () {
      final f = _field();
      final r = machine.advance(start(), f, FlowInput.confirm);
      expect(r.state.phase, FlowPhase.unitSelected);
      expect(r.state.selectedUnitId, 1);
      expect(machine.currentRange, isNotNull);
      expect(machine.currentRange!.canReach(2, 2), isTrue);
    });

    test('不能选中敌方单位', () {
      final f = _field();
      var s = start();
      // 把光标挪到敌方单位所在的 (8,8)
      while (s.cursorX < 8) {
        s = machine.advance(s, f, FlowInput.right).state;
      }
      while (s.cursorY < 8) {
        s = machine.advance(s, f, FlowInput.down).state;
      }
      final r = machine.advance(s, f, FlowInput.confirm);
      expect(r.state.phase, FlowPhase.freeCursor, reason: '敌方单位不该被选中');
      expect(machine.currentRange, isNull);
    });

    test('光标在选中态只能走到移动范围内', () {
      final f = _field();
      var s = machine.advance(start(), f, FlowInput.confirm).state;
      expect(s.phase, FlowPhase.unitSelected);

      // 移动力 3，从 (2,2) 出发最多走到 (5,2)
      var reached5 = false;
      for (var i = 0; i < 10; i++) {
        s = machine.advance(s, f, FlowInput.right).state;
        if (s.cursorX >= 5) reached5 = true;
      }
      expect(s.cursorX, lessThanOrEqualTo(5), reason: '不该走出移动力 3 的范围');
      expect(reached5, isTrue, reason: '范围内应当能走满');
    });

    test('取消回到选中前的位置', () {
      final f = _field();
      var s = machine.advance(start(), f, FlowInput.confirm).state;
      s = machine.advance(s, f, FlowInput.right).state;
      s = machine.advance(s, f, FlowInput.right).state;
      expect(s.cursorX, 4);

      s = machine.advance(s, f, FlowInput.cancel).state;
      expect(s.phase, FlowPhase.freeCursor);
      expect(s.cursorX, 2, reason: '应回到选中前的光标位置');
      expect(s.selectedUnitId, isNull);
      expect(machine.currentRange, isNull);
    });

    test('完整走一遍：选中 → 移动 → 待机', () {
      final f = _field();
      var s = start();

      s = machine.advance(s, f, FlowInput.confirm).state; // 选中
      s = machine.advance(s, f, FlowInput.right).state; // 移动光标
      s = machine.advance(s, f, FlowInput.right).state;
      final confirm = machine.advance(s, f, FlowInput.confirm); // 进行动菜单
      expect(confirm.state.phase, FlowPhase.actionMenu);

      final done = machine.advance(confirm.state, f, FlowInput.confirm);
      expect(done.state.phase, FlowPhase.freeCursor);
      expect(done.committedMove, isTrue);
      expect(done.state.pendingX, isNull);
    });

    test('已行动的单位不能再被选中', () {
      final f = _field();
      f.unitById(1)!.hasActed = true;
      final r = machine.advance(start(), f, FlowInput.confirm);
      expect(r.state.phase, FlowPhase.freeCursor);
    });

    test('allActed 反映还能行动的单位数', () {
      final f = _field();
      expect(f.actionableCount, 2);
      f.unitById(1)!.hasActed = true;
      expect(f.actionableCount, 1);
      f.unitById(2)!.hasActed = true;
      expect(f.allActed, isTrue);
    });
  });

  group('可序列化（存档的基础）', () {
    test('FlowState 编码再解码等价', () {
      final f = _field();
      var s = machine.advance(start(), f, FlowInput.confirm).state;
      s = machine.advance(s, f, FlowInput.right).state;

      final round = FlowState.decode(s.encode());
      expect(round.phase, s.phase);
      expect(round.cursorX, s.cursorX);
      expect(round.cursorY, s.cursorY);
      expect(round.selectedUnitId, s.selectedUnitId);
      expect(round.moveOriginX, s.moveOriginX);
      expect(round.moveOriginY, s.moveOriginY);
      expect(round.turn, s.turn);
      expect(round.faction, s.faction);
    });

    test('BattleField 编码再解码等价（含单位位置与已行动标记）', () {
      final f = _field();
      f.unitById(1)!.hasActed = true;
      f.moveUnit(f.unitById(2)!, 7, 7);
      f.turn = 5;

      final round = BattleField.decode(f.encode());
      expect(round.width, f.width);
      expect(round.height, f.height);
      expect(round.turn, 5);
      expect(round.units.length, f.units.length);
      expect(round.unitById(1)!.hasActed, isTrue);
      expect(round.unitById(2)!.x, 7);
      expect(round.unitById(2)!.y, 7);
    });

    test('解档后能继续推进（不是只能读的死状态）', () {
      final f = _field();
      final s = machine.advance(start(), f, FlowInput.confirm).state;

      // 存
      final ss = s.encode();
      final fs = f.encode();

      // 读（新一场）
      final map2 = _testMap();
      final m2 = FlowMachine(map: map2, costTable: _flatCosts());
      final field2 = BattleField.decode(fs);
      var s2 = FlowState.decode(ss);

      // 读档后移动范围需要按当前选中单位重算——
      // 这是"存档只存语义状态、不存派生数据"的体现
      s2 = m2.advance(s2, field2, FlowInput.cancel).state;
      s2 = m2.advance(s2, field2, FlowInput.confirm).state;
      expect(s2.phase, FlowPhase.unitSelected);
      expect(s2.selectedUnitId, 1);
      expect(m2.currentRange!.canReach(2, 2), isTrue);
    });
  });
}
