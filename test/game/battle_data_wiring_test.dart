// 战斗数据接线：**源码表真的接到了结算器上**。
//
// ## 为什么必须有这条
//
// 出过两次"接了一半"的 bug，都不报错：
//
// 1. **结算器持有的是演示表**
//    `onLoad` 里先 `_items = _demoItems()`（`ItemTable(8)`）并把它交给
//    `CombatResolver`，之后 `_loadBattleData()` 又把 `_items` **换成新对象**
//    （`_realItems()`）。`CombatResolver.items` 存的是**表对象**，不是变量 ——
//    于是所有伤害/命中都算在 8 项的演示表上：
//    细剑是 9 号 → 查不到 → **威力 0**（"打不死人"）
//
// 2. **道具属性位（`IA_*`）没接上**
//    提取器原来把 `.attributes = IA_WEAPON | ...` 当**字符串**留下，
//    `_realItems()` 也就没往上拷 → `attributesOf()` 恒为 0
//    → `IA_NEGATE_CRIT` / `IA_NEGATE_FLYING` 永远为假
//
// 判据都是**正向抽查真值**（值来自源码），不是"没抛异常"。
import 'dart:convert';

import 'package:fe8r/core/core.dart';
import 'package:fe8r/game/fe8_game.dart';
import 'package:flutter_test/flutter_test.dart';

/// 载入规则层数据表。
///
/// ⚠️ **不能走 `onLoad`**：它要过 `TiledComponent.load`，而图片解码在
/// widget test 的假异步里不会完成（实测 status 永远停在「启动中…」）。
/// 所以 `Fe8Game.loadRuleData()` 被单独拆了出来 —— 见它的文档。
Fe8Game loadTables() {
  final game = Fe8Game();
  game.loadRuleData();
  return game;
}

void main() {
  test('结算器用的是**真实**道具表，不是演示表', () {
    final game = loadTables();
    final items = game.combat!.items;

    // 演示表是 `ItemTable(8)`，真实表是 `ItemTable(256)` —— 长度就能分开
    expect(items.length, 256,
        reason: '还是 8 项说明 CombatResolver 拿的是演示表（换表后没重建）');

    // 正向抽查：细剑（`items.json` 的 ITEM_SWORD_RAPIER，源码 .maxUses=40
    // .might=7 .hit=95 .weight=5 .encodedRange=0x11）
    expect(items[9].might, 7, reason: '细剑威力必须是 7（源码值）');
    expect(items[9].hit, 95);
    expect(items[9].weight, 5);
    expect(items.minRangeOf(9), 1);
    expect(items.maxRangeOf(9), 1);

    // 铁剑 `IA_WEAPON = (1 << 0)` —— 属性位必须接上
    expect(items.attributesOf(1) & 1, 1,
        reason: 'attributes 没拷进 ItemTable 的话这里恒为 0');
  });

  test('★ 序章我方按源码装载：赛特 3 件、艾莉卡 1 件，且道具栏是 5 槽', () {
    final game = loadTables();
    // `LOAD1` 往当前战场追加单位；这里先给一个空战场
    game.field = BattleField(width: 30, height: 30, units: []);
    game.loadUnitsForTest('UnitDef_Event_PrologueAlly', 1);

    final units = game.field!.units;
    final seth = units.firstWhere((u) => u.charIndex == 2);
    final eirika = units.firstWhere((u) => u.charIndex == 1);

    // `UnitDef_Event_PrologueAlly`：SETH items = {0x03, 0x17, 0x6C, 0}
    expect(seth.items.length, unitItemCount);
    expect(seth.heldItems.map(ItemTable.itemIndex), [0x03, 0x17, 0x6C],
        reason: 'item1/item2 曾经整片丢掉（只读了 item0）');
    // 耐久来自真实道具表：钢剑 maxUses = 30
    expect(seth.items[0], (30 << 8) | 0x03);

    // EIRIKA items = {0x6C, 0, 0, 0}
    expect(eirika.heldItems.map(ItemTable.itemIndex), [0x6C]);

    // ★ 这一条就是「艾莉卡拿不到细剑」的直接判据：
    //   如果道具栏只有 1 个元素，这里一定是 -1
    final rapier = (40 << 8) | 9; // MakeNewItem(ITEM_SWORD_RAPIER)
    expect(eirika.addItem(rapier), 1, reason: '细剑必须放得进 1 号槽');
    expect(eirika.heldItems.map(ItemTable.itemIndex), [0x6C, 9]);
  });

  test('★ 状态转储必须**可 JSON 编码**（槽非空时也要）', () {
    // 真实踩过：`slots` 的键写成了 int —— `jsonEncode` 编不了，
    // 而且是**只有槽非空时才炸**：标题画面那会儿 slots 是空的，
    // 转储照写；一到序章（脚本真的用了槽）整个转储静默失败。
    // 那一次我只能靠"跑 60 秒 + 看文件在不在"发现 —— 这条测试是 1 毫秒。
    final game = loadTables();
    game.field = BattleField(width: 15, height: 10, units: [
      MapUnit(id: 1, faction: Faction.blue, x: 4, y: 4, name: 'SETH'),
    ]);
    final sc = Scene(
      texts: GameTexts.empty(),
      scripts: const {},
      onEvent: (_) async {},
    );
    sc.setSlot(3, 9); // 脚本槽非空 —— 就是这个状态炸的
    game.scene = sc;

    final d = game.dumpState();
    final scene = d['scene'] as Map<String, dynamic>;
    expect(scene['slots'], isNotEmpty, reason: '槽非空才测得到那条路');
    expect(() => jsonEncode(d), returnsNormally);
  });

  test('★ 载入的单位编号必须落在**阵营区块**里（否则敌方阶段会被跳过）', () {
    // `UNIT_FACTION(u) = u->index & 0xC0`（`include/bmunit.h:477`）：
    //   我方 0x01..0x3F / 友军 0x41..0x7F / 敌方 0x81..0xBF
    // 而 `GetPhaseAbleUnitCount` 是**按 id 区间**数的 —— 编号跑出区块，
    // 敌方阶段会被当成"没人能动"直接跳过（**AI 一步都不走，还不报错**）。
    final game = loadTables();
    game.field = BattleField(width: 30, height: 30, units: []);
    game.loadUnitsForTest('UnitDef_Event_PrologueAlly', 1);
    game.loadUnitsForTest('UnitDef_Event_PrologueEnemy', 1);

    for (final u in game.field!.units) {
      expect(u.id & 0xC0, u.faction,
          reason: '${u.name} 的编号 0x${u.id.toRadixString(16)} 与阵营 '
              '0x${u.faction.toRadixString(16)} 不在同一个区块');
    }
    // 阶段计数必须真的数得到人
    expect(game.field!.phaseAbleCount(Faction.blue), 2);
    expect(game.field!.phaseAbleCount(Faction.red), 3);
  });

  test('★ 同一张单位表载入两次**不会**变成两份（`LoadUnit_0`）', () {
    // 序章开场脚本末尾 `CALL(EventScr_Prologue_ONeillSpawn)`（LOAD1 敌人），
    // 回合 1 的敌方阶段事件 `EventScr_Prologue_Turn1` **又调一次**
    // （`src/data/data_08A612F4/data_08A612F4.s:32-40`）。
    //
    // 出处 `LoadUnit_0`（`src/eventscr_0800F8D4.c:45-95`）：
    // 场上已有同角色时**不新建**，只改阵营/挪位置。
    final game = loadTables();
    game.field = BattleField(width: 30, height: 30, units: []);
    game.loadUnitsForTest('UnitDef_Event_PrologueEnemy', 1);
    final first = game.field!.units.length;
    expect(first, 3);
    game.loadUnitsForTest('UnitDef_Event_PrologueEnemy', 1);
    expect(game.field!.units.length, first,
        reason: '★ 第二次 LOAD 不能凭空多出单位来');
    // 编号也必须仍然唯一
    final ids = game.field!.units.map((u) => u.id).toList();
    expect(ids.toSet().length, ids.length);
  });

  test('★ 序章战斗：艾莉卡拿细剑打奥尼尔，伤害落在**奥尼尔**身上', () {
    // 这一条钉的是"序章战斗能不能真的打掉血"：
    //   * `_profileFor` 从三张表取职业/角色/武器（不是演示值）
    //   * 伤害算在**被攻击方**（曾经"伤害全落在艾莉卡身上"）
    //   * 细剑（9 号）必须在结算器认识的道具表里 —— 演示表只有 8 项，
    //     9 号查不到 → 威力 0
    final game = loadTables();
    game.field = BattleField(width: 15, height: 10, units: []);
    game.loadUnitsForTest('UnitDef_Event_PrologueAlly', 1);
    game.loadUnitsForTest('UnitDef_Event_PrologueEnemy', 1);

    final f = game.field!;
    final eirika = f.units.firstWhere((u) => u.charIndex == 1);
    final oneill = f.units.firstWhere((u) => u.charIndex == 104);

    // `EventScr_Prologue_GiveRapier`：`SVAL(3, ITEM_SWORD_RAPIER)` + GIVEITEMTO
    expect(eirika.addItem(makeNewItem(9, 40)), isNonNegative);

    final pa = game.profileForTest(eirika);
    final pd = game.profileForTest(oneill);

    // 装备的是**真武器**（`items.json`：细剑 9 / 铁斧 31）
    expect(pa.weaponItem & 0xFF, 9, reason: '艾莉卡必须装备细剑');
    expect(pd.weaponItem & 0xFF, 31, reason: '奥尼尔拿的是铁斧');
    // 攻击力基础值来自**职业**（`CLASS_EIRIKA_LORD.basePow == 4`）
    expect(pa.pow, 4, reason: '角色表不提供 pow —— 它只来自职业');

    final before = oneill.hp;
    final eirikaBefore = eirika.hp;
    // 乱数种子固定 —— 不然"这一击有没有必杀"就随初始状态漂，
    // 而必杀是 ×3 伤害（`battle_rng.dart:284`），还会被钳到守方当前 HP（20）。
    // 实测：不固定种子时第一击就是必杀，伤害被钳成 20 —— **不是 10**。
    game.rng.initRn(1);
    final res = game.combat!.attack(
      tracker: game.tracker,
      rng: game.rng,
      attackerUnit: eirika,
      defenderUnit: oneill,
      attackerProfile: pa,
      defenderProfile: pd,
      terrainDefense: 0,
      terrainAvoid: 0,
    );

    expect(res.hit, isTrue, reason: '先手必须能打出去（命中率不会是 0）');
    expect(res.crit, isFalse, reason: '种子 1 这一击不是必杀（判据要可复现）');
    // ★ 正向抽查：**这一击的伤害是 10**，四段来源全部可在源码里查到 ——
    //
    //     CLASS_EIRIKA_LORD.basePow = 4   （`classes.json` ← data_classes.c）
    //     ITEM_SWORD_RAPIER.might   = 7   （`items.json` ← data_items.c）
    //     武器三角：剑 > 斧 → +1 伤害     （`weapon_triangle.json`）
    //     CLASS_FIGHTER.baseDef     = 2   （奥尼尔的职业是 63）
    //     ------------------------------------------------
    //     4 + 7 + 1 - 2 = 10
    //
    // 钉死它是有意义的：任何一环没接上（武器编号、属性位、三角表、职业表）
    // 这个数都会变 —— 而"变了却不报错"正是这个项目最常见的失败形状。
    expect(res.damage, 10,
        reason: '4(pow) + 7(细剑威力) + 1(三角) - 2(守方防御) = 10');
    expect(oneill.hp, before - res.damage,
        reason: '掉血必须落在**被攻击方**身上');
    expect(eirika.hp, eirikaBefore,
        reason: '单次 attack 只结算一次攻击（反击由 resolveCombat 决定）');
  });

  test('★ 最后一个能动的单位用**攻击**结束行动 → 阶段必须自动结束', () {
    // 用户报：「回合终了 和 我方全部行动完成结束 有 bug」。
    //
    // 原因是这条：`PlayerPhase_HandleAutoEnd` 只在**待机**那条路上被调过
    // （`if (r.committedMove && r.attack == null) _afterUnitAction();`），
    // 而唯一的调用点把**攻击**排除了 —— 注释说"延到 `_attackWithQuote` 里"，
    // 但 `_attackWithQuote` 根本没调。
    //
    // ⇒ 用攻击收尾时阶段不会自动结束，只能靠菜单「終了」。
    //
    // 源码依据（proc 脚本即源码）：`dat_ProcScr_uistuff148_ref.c:285-290`
    //   `ApplyUnitAction; HandlePostActionTraps; RunPotentialWaitEvents;
    //    … PlayerPhase_FinishAction; PROC_GOTO(0)`
    // → label 0（`:258-265`）
    //   `… PROC_WHILE(EventEngineExists); PlayerPhase_HandleAutoEnd`
    // **攻击与待机是同一条尾巴。**
    final game = loadTables();
    game.field = BattleField(width: 15, height: 10, units: []);
    game.loadUnitsForTest('UnitDef_Event_PrologueAlly', 1);
    game.loadUnitsForTest('UnitDef_Event_PrologueEnemy', 1);

    final f = game.field!;
    final seth = f.units.firstWhere((u) => u.charIndex == 2);
    final eirika = f.units.firstWhere((u) => u.charIndex == 1);
    final oneill = f.units.firstWhere((u) => u.charIndex == 104);

    // 艾莉卡先待机 → 赛特成为**最后一个**还能动的我方单位
    f.finishUnit(eirika);
    expect(f.phaseAbleCount(Faction.blue), 1,
        reason: '现在只剩赛特能动（自动结束的判据就是他行动完之后 == 0）');

    // 把赛特挪到奥尼尔旁边（移动本身不是这条判据要测的东西）
    f.moveUnit(seth, oneill.x - 1, oneill.y);
    // ⚠️ 顺序要与真实路径一致：输入处理器是 **先 `moveUnit` + `finishUnit`，
    //    再 `_attackWithQuote`**（`fe8_game.dart` 的 `committedMove` 分支）。
    //    `finishUnit` 不在这条调用里做 —— 少写这一句，判据测的就不是真实路径。
    f.finishUnit(seth);
    // 赛特拿的是铁剑；给奥尼尔留够 HP，这一下打不死（不然会走结束剧情那条路）
    game.rng.initRn(1);

    final turnBefore = f.turn;
    expect(turnBefore, 1);

    // 走**真实**的攻击路径（`_attackWithQuote` → `_afterUnitAction`）
    expect(game.autoEndTriggersForTest, 0, reason: '攻击之前没人判定过自动结束');
    expect(turnBefore, 1);

    return game.attackWithQuoteForTest(seth, oneill).then((_) {
      expect(oneill.hp, lessThan(oneill.maxHp), reason: '这一下真的打到了');
      expect(game.autoEndTriggersForTest, 1,
          reason: '最后一个能动的单位行动完（这里是**攻击**）→ '
              '`PlayerPhase_HandleAutoEnd` 必须被求值到一次');
    });
  });

  test('★ 关掉"自动结束回合"后，最后一个单位的攻击**不该**结束阶段', () {
    // 出处：`src/playerphase_0801D808.c:52-58` —— 配置开关与判据在**同一个条件**里：
    //   if (!(gPlaySt.config.disableAutoEndTurns) && (GetPhaseAbleUnitCount(...) == 0))
    //       Proc_Goto(proc, 3);
    // ⇒ 关掉之后，阶段只能由玩家在菜单里选「終了」结束。
    final game = loadTables();
    game.field = BattleField(width: 15, height: 10, units: []);
    game.loadUnitsForTest('UnitDef_Event_PrologueAlly', 1);
    game.loadUnitsForTest('UnitDef_Event_PrologueEnemy', 1);

    final f = game.field!;
    final seth = f.units.firstWhere((u) => u.charIndex == 2);
    final eirika = f.units.firstWhere((u) => u.charIndex == 1);
    final oneill = f.units.firstWhere((u) => u.charIndex == 104);

    game.playConfig.disableAutoEndTurns = true;
    f.finishUnit(eirika); // 赛特成为最后一个能动的
    f.moveUnit(seth, oneill.x - 1, oneill.y);
    f.finishUnit(seth);
    game.rng.initRn(1);

    return game.attackWithQuoteForTest(seth, oneill).then((_) {
      expect(oneill.hp, lessThan(oneill.maxHp), reason: '这一下真的打到了');
      expect(game.autoEndTriggersForTest, 0,
          reason: '关掉自动结束后，不该有任何一次自动结束判定命中');
      expect(f.activeFaction, Faction.blue, reason: '还在我方阶段（没被自动结束）');
    });
  });
}
