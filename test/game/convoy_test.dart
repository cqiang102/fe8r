// ★ 輸送队的存取：**送进去再取回来**（往返判据）。
//
// 出处：`src/SupplyUsability.c:51-80`（誰能用）、`src/bmcontainer.c:54-77`（存取）、
//       `include/bmcontainer.h:7`（100 格）。
import 'dart:convert';
import 'dart:io';

import 'package:fe8r/core/core.dart';
import 'package:fe8r/game/fe8_game.dart';
import 'package:flutter_test/flutter_test.dart';

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

/// 挑一件**既不是武器也不能用**的道具（宝石）—— 这样行动菜单里只会有「待機/輸送」，
/// 不会多出「道具」（我第一版随手用了 `makeNewItem(11, 20)`，而 11 是**勇者之剑** ⇒
/// 输入序列走进了装备流程）。
({int num, int word}) pickGem() {
  final d = jsonDecode(File('tools/pipeline/out/tables/items.json')
      .readAsStringSync()) as Map<String, dynamic>;
  final e = (d['entries'] as Map).cast<String, dynamic>();
  Map<String, dynamic>? pick;
  for (final pat in ['GEM', 'SEAL']) {
    for (final kv in e.entries) {
      if (kv.key.contains(pat)) {
        pick = (kv.value as Map).cast<String, dynamic>();
        break;
      }
    }
    if (pick != null) break;
  }
  if (pick == null) fail('items.json 里找不到宝石/證类道具');
  final itemNum = (pick['number'] as num).toInt();
  return (
    num: itemNum,
    word: makeNewItem(itemNum, (pick['maxUses'] as num?)?.toInt() ?? 1)
  );
}

void main() {
  test('★ 輸送：领袖送一件进去、再取回来（往返）', () async {
    final gem = pickGem();
    final g = Fe8Game();
    g.loadRuleData();
    final map = flat();
    // 领袖 = `convoyLeaderId(chapterModeIndex)`；游戏默认 1 ⇒ 艾莉卡（charIndex 1）
    final f = BattleField(width: 6, height: 6, units: [
      MapUnit(id: 1, faction: 0, x: 2, y: 2, charIndex: 1, hp: 20, maxHp: 20,
          items: [gem.word, 0, 0, 0, 0]),
    ]);
    g.map = map;
    g.field = f;
    g.flow = FlowMachine(
        map: map, costsOf: (u) => MovementCostTable(List<int>.filled(64, 1)));
    g.state = FlowState(phase: FlowPhase.freeCursor, cursorX: 2, cursorY: 2);
    g.playConfig.disableAutoEndTurns = true;

    // 选中 → 行动菜单 → 輸送（菜单里最后一项）
    g.routeInput(FlowInput.confirm);
    g.routeInput(FlowInput.confirm);
    expect(g.state!.phase, FlowPhase.actionMenu);
    // ★ 按**名字**定位「輸送」，不数 down 几次
    //（我第一版随手按了一次 down，结果菜单里还有「道具」项 ⇒ 走进了装备流程）
    final menu = (g.dumpState()['actionMenu'] as List).cast<String>();
    expect(menu.contains('輸送'), isTrue, reason: '领袖应当有輸送项（菜单=$menu）');
    final target = menu.indexOf('輸送');
    for (var k = 0; k < target; k++) {
      g.routeInput(FlowInput.down);
    }
    expect(g.dumpState()['actionIndex'], target);
    g.routeInput(FlowInput.confirm);
    await Future<void>.delayed(const Duration(milliseconds: 50));

    // 菜单：确认 = 送る；再确认 = 选第一件送进去
    g.routeInput(FlowInput.confirm);
    g.routeInput(FlowInput.confirm);
    await Future<void>.delayed(const Duration(milliseconds: 50));

    var c = g.lastConvoy!;
    expect(c['action'], 'store');
    expect(c['ok'], isTrue);
    expect(convoyCount(g.convoyItems), 1, reason: '★ 送进去了一件');
    expect(f.unitById(1)!.items[0], 0, reason: '送出后背包该空了（压缩过）');
    // 送出后回到菜单；再 down 到「引き出す」并确认
    g.routeInput(FlowInput.down);      // 菜单项 → 引き出す
    g.routeInput(FlowInput.confirm);   // 进入 take 阶段
    g.routeInput(FlowInput.confirm);   // 取第一件
    await Future<void>.delayed(const Duration(milliseconds: 50));

    c = g.lastConvoy!;
    expect(c['action'], 'take');
    expect(c['ok'], isTrue, reason: '★ 取回来了');
    expect(convoyCount(g.convoyItems), 0, reason: '★ 往返之后输送队又是空的');
    expect(f.unitById(1)!.items[0] & 0xFF, gem.num, reason: '道具回到背包（同一件）');
    expect(g.dumpState()['convoyAccessAssumed'], isTrue,
        reason: '`HasConvoyAccess()` 的实现没读到 ⇒ 转储里明确标出这是"假定的"');
  });
}
