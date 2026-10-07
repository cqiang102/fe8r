// ★ 「訪問（村）」整条链，在**游戏层**验证。
//
// 出处：`src/bmmenu_08022F50.c:89-118`（`VisitCommandUsability`：4 种村地形 +
//       该格有可用 VILL 事件 + 非幻影 + `!US_HAS_MOVED`）、
//       `src/VisitCommandEffect.c:50-59`（`UNIT_ACTION_VISIT`）、
//       `src/StartAvailableTileEvent.c:24-60`（按 `locationBasedEvents` 匹配后起事件）。
import 'package:fe8r/core/core.dart';
import 'package:fe8r/game/fe8_game.dart';
import 'package:flutter_test/flutter_test.dart';

/// 4×4：**(1,1) 是村**（图例索引 1 = `TERRAIN_VILLAGE_REGULAR`），其余平原
MapGrid villageMap() => MapGrid(
      id: 'v',
      chapter: '',
      width: 4,
      height: 4,
      tileSize: 16,
      metatiles: List<int>.filled(16, 0),
      terrainIndices: [
        0, 0, 0, 0, //
        0, 1, 0, 0, //
        0, 0, 0, 0, //
        0, 0, 0, 0, //
      ],
      terrainLegend: const ['TERRAIN_PLAINS', 'TERRAIN_VILLAGE_REGULAR'],
    );

void main() {
  test('★ 訪問：站在村格上能訪問，跑脚本 + 置 doneFlag', () async {
    final g = Fe8Game();
    g.loadRuleData();
    final map = villageMap();
    final f = BattleField(width: 4, height: 4, units: [
      MapUnit(id: 1, faction: 0, x: 1, y: 1, hp: 20, maxHp: 20),
    ]);
    g.map = map;
    g.field = f;
    g.flow = FlowMachine(
        map: map, costsOf: (u) => MovementCostTable(List<int>.filled(64, 1)));
    g.state = FlowState(phase: FlowPhase.freeCursor, cursorX: 1, cursorY: 1);
    g.playConfig.disableAutoEndTurns = true;
    // 本章的 Location 列表：一条 VILL 在 (1,1)，doneFlag = 7，cmdId = 0x10
    g.locationEventsForTest = const [
      LocationEvent(cmd: 'VILL', x: 1, y: 1, cmdId: kTileCommandVisit,
          doneFlag: 7, script: null),
    ];

    // 选中 → 原地确认（提交移动）→ 行动菜单
    g.routeInput(FlowInput.confirm);
    g.routeInput(FlowInput.confirm);
    expect(g.state!.phase, FlowPhase.actionMenu);
    // 菜单：单位**没有道具**、也没有相邻敌人 ⇒ 只有 [待機, 訪問] ⇒ down 到 訪問
    g.routeInput(FlowInput.down);
    g.routeInput(FlowInput.confirm);
    await Future<void>.delayed(const Duration(milliseconds: 100));

    final v = g.lastVisit;
    expect(v, isNotNull, reason: '★ 訪問发生了（子菜单之外的第一条地形玩法）');
    expect(v!['x'], 1);
    expect(v['y'], 1);
    expect(v['cmd'], 'VILL');
    expect((g.dumpState()['eventFlags'] as List).contains(7), isTrue,
        reason: '★ `doneFlag` 被置上（同一条村不会被訪問两次）');
  });

  test('平地（不是村）上没有「訪問」这一项', () async {
    final g = Fe8Game();
    g.loadRuleData();
    final map = villageMap();
    final f = BattleField(width: 4, height: 4, units: [
      MapUnit(id: 1, faction: 0, x: 0, y: 0, hp: 20, maxHp: 20),
    ]);
    g.map = map;
    g.field = f;
    g.flow = FlowMachine(
        map: map, costsOf: (u) => MovementCostTable(List<int>.filled(64, 1)));
    g.state = FlowState(phase: FlowPhase.freeCursor, cursorX: 0, cursorY: 0);
    g.playConfig.disableAutoEndTurns = true;
    g.locationEventsForTest = const [
      LocationEvent(cmd: 'VILL', x: 1, y: 1, cmdId: kTileCommandVisit, doneFlag: 7),
    ];
    g.routeInput(FlowInput.confirm);
    g.routeInput(FlowInput.confirm);
    expect(g.state!.phase, FlowPhase.actionMenu);
    // 只有「待機」⇒ down 绕回 0，确认之后不该有訪問记录
    g.routeInput(FlowInput.down);
    g.routeInput(FlowInput.confirm);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(g.lastVisit, isNull, reason: '平地不该能訪問');
  });
  _keyIgnoreTests();
}

// ★ `IGNORE_KEYS`（`EvtSetKeyIgnore` ⇒ `SetKeyStatus_IgnoreMask`，
// `src/SetKeyStatus_IgnoreMask.c:7-10`；位见 `include/gba/io_reg.h:663-672`）
void _keyIgnoreTests() {
  test('★ 屏蔽 A 键 ⇒ 确认输入被吞掉（计数 +1，状态不变）；掩码为 0 ⇒ 又正常', () {
    final g = Fe8Game();
    g.loadRuleData();
    final map = villageMap();
    final f = BattleField(width: 4, height: 4, units: [
      MapUnit(id: 1, faction: 0, x: 1, y: 1, hp: 20, maxHp: 20),
    ]);
    g.map = map;
    g.field = f;
    g.flow = FlowMachine(
        map: map, costsOf: (u) => MovementCostTable(List<int>.filled(64, 1)));
    g.state = FlowState(phase: FlowPhase.freeCursor, cursorX: 1, cursorY: 1);
    g.playConfig.disableAutoEndTurns = true;

    // 不屏蔽：确认键正常选中
    g.routeInput(FlowInput.confirm);
    expect(g.state!.selectedUnitId, 1, reason: '掩码为 0 时输入正常');

    // 屏蔽 A 键（= 确认）
    g.keyIgnoreMask = kKeyA;
    final before = g.state!.phase;
    g.routeInput(FlowInput.confirm);
    expect(g.dumpState()['ignoredInputCount'], 1,
        reason: '★ 被掩码吞掉的输入要**计数**（这是判据）');
    expect(g.state!.phase, before, reason: '状态不该变');

    // 屏蔽 B 键不该影响 confirm；清掉掩码后一切恢复
    g.keyIgnoreMask = kKeyB;
    g.routeInput(FlowInput.confirm);
    expect(g.dumpState()['ignoredInputCount'], 1, reason: 'B 键的掩码不吞 confirm');
    g.keyIgnoreMask = 0;
    g.routeInput(FlowInput.cancel);
    expect(g.dumpState()['ignoredInputCount'], 1);
  });
}
