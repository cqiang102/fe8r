// ★ 玩家**主动攻击**这条链（欠账 44）。
//
// 为什么在游戏层写：序章/第 1 章都是**教学模式章节**，盘面被教学脚本驱动
// —— 固定输入脚本撞角落拿到的格子会被教学挪走（`scenario.sh battle` 的
// `actionLog` 只有一条"原地待机"）。这里**程序化构造**盘面，直接驱动
// `routeInput`，走的是和玩家一样的那条路：
//
//   选中 → 提交移动 → 行动菜单「攻撃」→ 选目标（**战斗预测**在这一步算）
//   → 确认 → `_attackWithQuote`
//
// 判据是**游戏层状态**：出手计数 + 预测与实战的伤害对照。
import 'dart:convert';
import 'dart:io';

import 'package:fe8r/core/core.dart';
import 'package:fe8r/game/fe8_game.dart';
import 'package:flutter_test/flutter_test.dart';

Fe8Game loadGame() {
  final g = Fe8Game();
  g.loadRuleData();
  return g;
}

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

/// 从产物里挑一个**真实的**武器编号与职业编号（不硬编码，表格变了也不会假绿）
(int, int) pickWeaponAndClass() {
  final t = jsonDecode(
          File('tools/pipeline/out/tables/items.json').readAsStringSync())
      as Map<String, dynamic>;
  final entries = (t['entries'] as Map).cast<String, dynamic>();
  final sword = (entries['ITEM_SWORD_IRON'] as Map).cast<String, dynamic>();
  final c = jsonDecode(
          File('tools/pipeline/out/tables/classes.json').readAsStringSync())
      as Map<String, dynamic>;
  final cls = (c['classes'] as Map).cast<String, dynamic>();
  final eirika =
      (cls['CLASS_EIRIKA_LORD'] as Map<String, dynamic>)['number'] as int;
  return (sword['number'] as int, eirika);
}

void main() {
  test('★ 玩家主动攻击：选中 → 移动 → 攻撃 → 选目标（预测）→ 结算', () async {
    final g = loadGame();
    final (weapon, cls) = pickWeaponAndClass();
    final map = testMap();
    final f = BattleField(width: 4, height: 4, units: [
      MapUnit(
          id: 1, faction: 0, x: 1, y: 1, classId: cls,
          hp: 20, maxHp: 20, items: [weapon]),
      MapUnit(
          id: 0x81, faction: 0x80, x: 2, y: 1, classId: cls,
          hp: 20, maxHp: 20, items: [weapon]),
    ]);
    g.map = map;
    g.field = f;
    g.flow = FlowMachine(
        map: map, costsOf: (u) => MovementCostTable(List<int>.filled(64, 1)));
    g.state = FlowState(phase: FlowPhase.freeCursor, cursorX: 1, cursorY: 1);
    // ⚠️ 关掉"自动结束回合"：打完这一下之后 `_afterUnitAction` 会去演阶段横幅，
    // 而**无头测试里没有布局**（Flame 的 `size is not ready yet` 断言）。
    // 这里只判"玩家主动攻击"这条链；自动结束那条**另有覆盖**
    //（`battle_data_wiring_test.dart` 的"最后一个单位的攻击该不该结束阶段"）。
    g.playConfig.disableAutoEndTurns = true;

    // ① 选中
    g.routeInput(FlowInput.confirm);
    expect(g.state!.phase, FlowPhase.unitSelected,
        reason: '光标在我方单位上，确认应当选中他');

    // ② 原地确认 = 提交移动 → 行动菜单
    g.routeInput(FlowInput.confirm);
    expect(g.state!.phase, FlowPhase.actionMenu);

    // ③ 行动菜单第 2 项是「攻撃」（有相邻敌人）→ 进选目标
    g.routeInput(FlowInput.down);
    g.routeInput(FlowInput.confirm);
    expect(g.state!.phase, FlowPhase.selectTarget,
        reason: '相邻有敌人 ⇒ 菜单是 [待機, 攻撃, …]，down 之后确认就是攻撃');

    // ④ 预测在 update() 里算（`_tickForecast`）
    g.update(0.016);
    final fc = g.forecastForTarget;
    expect(fc, isNotNull, reason: '选目标阶段必须有战斗预测（欠账 41 的"看得见"）');
    expect(fc!.actorDamage, isNotNull);

    // ⑤ 确认 = 打
    g.routeInput(FlowInput.confirm);
    await Future<void>.delayed(const Duration(milliseconds: 200));
    expect(g.playerAttackCount, 1,
        reason: '★ 玩家真的主动出手了一次（这是欠账 44 的核心）');

    // ⑥ 预测与实际对照：命中过的话，每一下的伤害必须等于预测值
    final events = ((g.dumpState()['hitFxLog'] as List?) ?? const [])
        .cast<Map<String, dynamic>>();
    final landed = events
        .where((e) => e['unit'] == 0x81 && e['hit'] == true)
        .toList();
    // ⚠️ 必杀是 **3 倍**（`src/battle_rng.dart:284`：`ctx.damage = ctx.damage * 3`，
    // 与 `BattleForecast` 面板的"伤害"列不同 —— 面板给的是**普通一下**）。
    // 我第一次写这条断言时没跳过必杀，于是实测到"预测 6 / 实际 18"
    // —— 那正是必杀，**不是**预测算错了。
    var crits = 0;
    for (final e in landed) {
      final crit = e['crit'] == true;
      if (crit) crits++;
      expect(e['damage'], (fc.actorDamage ?? 0) * (crit ? 3 : 1),
          reason: '实际每一下 = 预测 ×（必杀 3 倍），预测与实战共用同一份计算');
    }
    // 把这次是不是必杀记进测试输出（方便回看，不作为判据）
    // ignore: avoid_print
    print('玩家攻击：预测 ${fc.actorDamage} / 命中 ${landed.length} 次（必杀 $crits 次）');
    expect(g.lastForecast, isNotNull, reason: '预测要留档（判据要能回看）');
  });
}
