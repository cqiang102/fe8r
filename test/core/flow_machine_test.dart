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
    MapGrid.parse(File('assets/maps/PrologueMap.json').readAsStringSync());

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
    machine = FlowMachine(map: map, costsOf: uniformCosts(costs));
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

  group('玩家侧攻击', () {
    /// 我方在 (2,2)，一个敌人在移动后能够到的位置
    BattleField attackField() => BattleField(
          width: 15,
          height: 10,
          activeFaction: Faction.blue,
          units: [
            MapUnit(id: 1, faction: Faction.blue, x: 2, y: 2, movement: 4),
            // 敌人在 (4,2)，我方移动后可以贴到 (3,2) 打它
            MapUnit(id: 0x81, faction: Faction.red, x: 4, y: 2, movement: 4),
            // 远处还有一个敌人，用来验证"不是随便谁都能打"
            MapUnit(id: 0x82, faction: Faction.red, x: 12, y: 9, movement: 4),
          ],
        );

    /// 选中单位 → 走到 [tx],[ty] → 进入行动菜单
    FlowState gotoMenu(FlowMachine m, BattleField f, int tx, int ty) {
      var s = m.advance(start(), f, FlowInput.confirm).state;
      while (s.cursorX < tx) {
        s = m.advance(s, f, FlowInput.right).state;
      }
      while (s.cursorY < ty) {
        s = m.advance(s, f, FlowInput.down).state;
      }
      return m.advance(s, f, FlowInput.confirm).state;
    }

    test('贴着敌人时菜单里会出现"攻击"', () {
      final f = attackField();
      final s = gotoMenu(machine, f, 3, 2);
      expect(s.phase, FlowPhase.actionMenu);
      final opts = machine.availableActions(s, f);
      expect(opts, contains(ActionOption.attack));
      expect(opts.first, ActionOption.wait, reason: '待机应当永远是第一项');
    });

    test('够不着时菜单里没有"攻击"', () {
      final f = attackField();
      // (2,2) 原地进菜单 —— 离敌人 (4,2) 距离 2，够不着
      final s = gotoMenu(machine, f, 2, 2);
      final opts = machine.availableActions(s, f);
      expect(opts, isNot(contains(ActionOption.attack)));
      expect(opts.length, 1);
    });

    test('validTargets 只返回相邻的敌人，且按 id 升序', () {
      final f = attackField();
      final me = f.unitById(1)!;
      final near = machine.validTargets(f, me, 3, 2);
      expect(near.map((u) => u.id), [0x81]);

      final none = machine.validTargets(f, me, 2, 2);
      expect(none, isEmpty);

      // 把我方夹在两个敌人中间，验证排序
      final f2 = BattleField(
        width: 15,
        height: 10,
        units: [
          MapUnit(id: 1, faction: Faction.blue, x: 5, y: 5),
          MapUnit(id: 0x90, faction: Faction.red, x: 6, y: 5),
          MapUnit(id: 0x83, faction: Faction.red, x: 4, y: 5),
        ],
      );
      final both = machine.validTargets(f2, f2.unitById(1)!, 5, 5);
      expect(both.map((u) => u.id), [0x83, 0x90], reason: '必须按 id 升序');
    });

    test('选"攻击"进入选目标阶段，确认后带回 attack 载荷', () {
      final f = attackField();
      var s = gotoMenu(machine, f, 3, 2);

      // 菜单里第 2 项是攻击
      s = machine.advance(s, f, FlowInput.down).state;
      expect(s.actionIndex, 1);
      s = machine.advance(s, f, FlowInput.confirm).state;
      expect(s.phase, FlowPhase.selectTarget);

      final r = machine.advance(s, f, FlowInput.confirm);
      expect(r.attack, isNotNull);
      expect(r.attack!.attackerId, 1);
      expect(r.attack!.targetId, 0x81);
      expect(r.state.phase, FlowPhase.freeCursor);
      expect(r.committedMove, isTrue, reason: '攻击也算这个单位行动完了');
    });

    test('选目标时取消能回到菜单', () {
      final f = attackField();
      var s = gotoMenu(machine, f, 3, 2);
      s = machine.advance(s, f, FlowInput.down).state;
      s = machine.advance(s, f, FlowInput.confirm).state;
      expect(s.phase, FlowPhase.selectTarget);

      s = machine.advance(s, f, FlowInput.cancel).state;
      expect(s.phase, FlowPhase.actionMenu);
      expect(s.targetIndex, 0);
    });

    test('选"待机"时 attack 为空', () {
      final f = attackField();
      final s = gotoMenu(machine, f, 3, 2);
      final r = machine.advance(s, f, FlowInput.confirm); // 第一项 = 待机
      expect(r.attack, isNull);
      expect(r.committedMove, isTrue);
    });

    test('阶段推进不依赖 unit.x（菜单弹出时单位还没真的移动）', () {
      final f = attackField();
      final s = gotoMenu(machine, f, 3, 2);
      // 单位此刻仍在 (2,2)
      expect(f.unitById(1)!.x, 2);
      // 但菜单要按落点 (3,2) 来算，所以应当有攻击
      expect(machine.availableActions(s, f), contains(ActionOption.attack));
    });

    test('攻击流程的状态可以存取（载荷不入档，但状态可复原）', () {
      final f = attackField();
      var s = gotoMenu(machine, f, 3, 2);
      s = machine.advance(s, f, FlowInput.down).state;
      s = machine.advance(s, f, FlowInput.confirm).state;
      expect(s.phase, FlowPhase.selectTarget);

      final round = FlowState.decode(s.encode());
      expect(round.phase, FlowPhase.selectTarget);
      expect(round.actionIndex, s.actionIndex);
      expect(round.targetIndex, s.targetIndex);
      expect(round.pendingX, s.pendingX);
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
      final m2 = FlowMachine(map: map2, costsOf: uniformCosts(_flatCosts()));
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
