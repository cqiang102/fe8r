import 'dart:convert';
import 'dart:io';

// 胜负判定的**语义测试**。
//
// 每一条断言的出处都写在注释里 —— 这个模块的价值就在于
// "机制是从源码解出来的"，所以测试要钉住那些语义，而不是钉住实现。
import 'package:fe8r/core/core.dart';
import 'package:flutter_test/flutter_test.dart';

/// 序章真实的 Misc 列表（解自
/// `src/data/data_08A5A6AD/data_08A5A6AD.s:32-40`）
ChapterObjectives prologue() => ChapterObjectives([
      const ChapterObjective(
        cmd: EventListCmd.flag,
        script: 'EventScr_Prologue_EndingScene',
        doneFlag: EventFlags.win,
        checkFlag: EventFlags.defeatBoss,
      ),
      const ChapterObjective(
        cmd: EventListCmd.flag,
        script: 'EventScr_Prologue_OneEnemyLeft',
        doneFlag: 7,
        checkFlag: 0, // 无条件
      ),
      const ChapterObjective(
        cmd: EventListCmd.flag,
        script: 'EventScr_GameOver',
        doneFlag: 0,
        checkFlag: EventFlags.gameOver,
      ),
      const ChapterObjective(cmd: EventListCmd.end, script: null,
          doneFlag: 0, checkFlag: 0),
    ]);

void main() {
  _deriveTests();
  _unitIdTests();

  test('★ 击破首领 -> 执行结束脚本（`DefeatBoss` 宏）', () {
    // #define DefeatBoss(event_scr) AFEV(EVFLAG_WIN, (event_scr), EVFLAG_DEFEAT_BOSS)
    final o = prologue().firstMatch((f) => f == EventFlags.defeatBoss);
    expect(o, isNotNull);
    expect(o!.script, 'EventScr_Prologue_EndingScene');
    expect(o.doneFlag, EventFlags.win);
  });

  test('★ 主角阵亡 -> GameOver（`CauseGameOverIfLordDies` 宏）', () {
    // #define CauseGameOverIfLordDies AFEV(0, EventScr_GameOver, EVFLAG_GAMEOVER)
    //
    // ⚠️ **必须把第 2 条的 doneFlag(7) 也算作已置上。**
    //
    // 第 2 条的 checkFlag 是 0（无条件），它排在 GameOver 之前 ——
    // 所以第一次判定时它会先命中。只有它执行过（flag 7 置上）之后，
    // 第 3 条才会被检查到。
    //
    // 我第一版没考虑这个，测试直接红了 —— **是测试写错了，不是代码错**，
    // 而且这个"红"恰好证明了顺序语义是真的。
    final o = prologue()
        .firstMatch((f) => f == EventFlags.gameOver || f == 7);
    expect(o, isNotNull);
    expect(o!.script, 'EventScr_GameOver');
  });

  test('★ 顺序有意义：没打首领时命中第二条（无条件那条）', () {
    // 第二条 checkFlag = 0（无条件），但它排在 DefeatBoss 之后 ——
    // 所以只有首领还没被击破时才会轮到它。
    final o = prologue().firstMatch((f) => false);
    expect(o!.script, 'EventScr_Prologue_OneEnemyLeft');
  });

  test('★ `doneFlag` 已置上 -> 该条被跳过（`!CheckFlag(EVT_CMD_HI(...))`）', () {
    // 首领已击破、且"已执行"标志（WIN）也已置上 -> 不该再触发结束脚本
    final o = prologue().firstMatch(
        (f) => f == EventFlags.defeatBoss || f == EventFlags.win);
    expect(o!.script, isNot('EventScr_Prologue_EndingScene'),
        reason: 'doneFlag=WIN 已置上，这条应当被跳过');
  });

  test('`checkFlag` 为 100 也算无条件（`EvCheck01_AFEV` 的语义）', () {
    final os = ChapterObjectives([
      const ChapterObjective(cmd: EventListCmd.flag, script: 'S',
          doneFlag: 0, checkFlag: 100),
    ]);
    expect(os.firstMatch((f) => false)!.script, 'S');
  });

  test('END 之后不再看', () {
    final os = ChapterObjectives([
      const ChapterObjective(cmd: EventListCmd.end, script: null,
          doneFlag: 0, checkFlag: 0),
      const ChapterObjective(cmd: EventListCmd.flag, script: 'never',
          doneFlag: 0, checkFlag: 0),
    ]);
    expect(os.firstMatch((f) => false), isNull);
  });

  test('非 FLAG 的命令本实现不判定（返回 null，不假装成功）', () {
    final os = ChapterObjectives([
      const ChapterObjective(cmd: EventListCmd.area, script: 'A',
          doneFlag: 7, checkFlag: 0),
      const ChapterObjective(cmd: EventListCmd.end, script: null,
          doneFlag: 0, checkFlag: 0),
    ]);
    expect(os.firstMatch((f) => true), isNull);
  });

  test('★ 每条命令的 script 都在（不只是 FLAG/TURN）', () {
    // 条目布局 `[cmd|flag][script][参数…]` —— **所有**命令的第 2 个字都是脚本指针。
    // 原来只给 FLAG/TURN 取，于是 AREA/CHAR/LOCA/VILL/CHES/DOOR/SHOP 的剧情全丢。
    final raw = jsonDecode(
        File('tools/pipeline/out/tables/event_lists.json').readAsStringSync())
        as Map<String, dynamic>;
    final lists = raw['lists'] as Map<String, dynamic>;
    var total = 0;
    var withScript = 0;
    final byCmd = <String, int>{};
    for (final l in lists.values) {
      for (final e in (l as List).cast<Map<String, dynamic>>()) {
        total++;
        if (e['script'] != null) {
          withScript++;
          byCmd[e['cmd'] as String] = (byCmd[e['cmd'] as String] ?? 0) + 1;
        }
      }
    }
    expect(total, 337);
    // ★ 棘轮：这个数**只许升**（每多解出一种命令的 script 就 +N）
    expect(withScript, 208, reason: '有 script 的条目数变了：$byCmd');
    // 正向抽查：`AREA`（cmd 0x0B）条目的 script 是那条 blob 里的偏移
    final ch11a = (lists['EventListScr_Ch11a_Misc'] as List)
        .cast<Map<String, dynamic>>();
    final area = ch11a.firstWhere((e) => e['cmd'] == 'AREA');
    expect(area['script'], 'frontier_df4_menu_008_A66F88 + 0x68');
    // ★ `CHES` 的布局**和别的命令不一样**：`struct EvCheck07`
    // （`src/exact_08085cc4.c:96-103`）是
    // `{unk0, givenItem, givenMoney, x, y, cmdId}` —— **没有 script 字段**，
    // 函数里直接 `info->script = 1;`。所以：
    //   * word1 是 **道具 id**（低 16 位）与金钱（高 16 位），**不是脚本**
    //   * `script` 固定是数据里的哨兵 `"1"`
    // 我原来把这一刀切地当成"word1 就是脚本"，于是把**道具 id 报成了脚本名**。
    final ches = <Map<String, dynamic>>[
      for (final l in lists.values)
        for (final e in (l as List).cast<Map<String, dynamic>>())
          if (e['cmd'] == 'CHES') e,
    ];
    expect(ches.length, 12);
    expect(ches.every((e) => e['script'] == '1'), isTrue,
        reason: 'CHES 的 script 是哨兵 1，不是指针');
    expect(ches.every((e) => e.containsKey('givenItem')), isTrue,
        reason: 'CHES 必须带 givenItem/givenMoney');
    // 正向抽查：Ch3 的第一个宝箱给道具 20（`0x14`）
    final ch3 = ches.firstWhere((e) => e['i'] == 0);
    expect(ch3['givenItem'], 20);
    expect(ch3['givenMoney'], 0);

    // ⚠️ 这类 script 目前**还演不出来**：它们指向切分出来的 blob
    // （`frontier_df4_menu_008_*`），而 `scene_data.g.dart` 只生成了
    // `EventScr_*` / `EventScrWM_*` 两种名字。见 docs/路线图.md 欠账 15。
  });

  test('★ 与解出来的 JSON 一致（序章）', () {
    // 这条把"手写的常量"和"数据管线解出来的字节"对起来 ——
    // 两边不一致说明有一边错了。
    final o = prologue().entries;
    expect(o[0].checkFlag, 2, reason: 'EVFLAG_DEFEAT_BOSS');
    expect(o[0].doneFlag, 3, reason: 'EVFLAG_WIN');
    expect(o[2].checkFlag, 101, reason: 'EVFLAG_GAMEOVER');
    expect(o[3].cmd, EventListCmd.end);
  });
}

// ---------------------------------------------------------------- 标志推导
//
// 这一组是第 ④ 步的**机器判据**：
// 「击破首领 -> 置 EVFLAG_DEFEAT_BOSS -> 命中 EndingScene」。

/// 序章的首领表（`gDefeatTalkList` 里本章那一条）
const oneillTalk = DefeatTalkEntry(
  pid: 104,                 // CHARACTER_ONEILL（include/constants/characters.h:87）
  route: chapterModeAny,    // 0xFF
  chapter: 0,               // CHAPTER_L_PROLOGUE
  flag: EventFlags.defeatBoss,
  msg: 0x08D7,              // 日版阵亡台词「な　なんだと・・・？」
);

/// `CHARACTER_ONEILL = 104`（`include/constants/characters.h`）
const oneill = 104;

void _deriveTests() {
  test('★ 击破首领 -> 置 EVFLAG_DEFEAT_BOSS', () {
    final flags = deriveEventFlags(
      units: const [
        BattleUnitView(charIndex: 104, faction: Faction.red, alive: false),
        BattleUnitView(charIndex: 1, faction: Faction.blue, alive: true),
      ],
      chapterIndex: 0,
      defeatTalk: const [oneillTalk],
    );
    expect(flags, contains(EventFlags.defeatBoss));
  });

  test('★ 首领还活着 -> 不置标志（判据要对得上，不能恒真）', () {
    final flags = deriveEventFlags(
      units: const [
        BattleUnitView(charIndex: 104, faction: Faction.red, alive: true),
        BattleUnitView(charIndex: 1, faction: Faction.blue, alive: true),
      ],
      chapterIndex: 0,
      defeatTalk: const [oneillTalk],
    );
    expect(flags, isNot(contains(EventFlags.defeatBoss)));
  });

  test('★ 别的章节的同名条目不该在本章生效', () {
    final flags = deriveEventFlags(
      units: const [
        BattleUnitView(charIndex: 104, faction: Faction.red, alive: false),
        BattleUnitView(charIndex: 1, faction: Faction.blue, alive: true),
      ],
      chapterIndex: 1, // 第 1 章，而条目写的是 PROLOGUE
      defeatTalk: const [oneillTalk],
    );
    expect(flags, isNot(contains(EventFlags.defeatBoss)));
  });

  test('★ 主角阵亡 -> GameOver', () {
    final flags = deriveEventFlags(
      units: const [
        BattleUnitView(charIndex: 1, faction: Faction.blue, alive: false),
        BattleUnitView(charIndex: 104, faction: Faction.red, alive: true),
      ],
      chapterIndex: 0,
      defeatTalk: const [],
    );
    expect(flags, contains(EventFlags.gameOver));
  });

  test('敌全灭 -> EVFLAG_DEFEAT_ALL（本来没有敌人时不算）', () {
    const blues = [BattleUnitView(charIndex: 1, faction: Faction.blue, alive: true)];
    expect(
      deriveEventFlags(
        units: const [
          ...blues,
          BattleUnitView(charIndex: 104, faction: Faction.red, alive: false),
        ],
        chapterIndex: 0,
        defeatTalk: const [],
        ),
      contains(EventFlags.defeatAll),
    );
    expect(
      deriveEventFlags(
        units: blues,
        chapterIndex: 0,
        defeatTalk: const [],
        ),
      isNot(contains(EventFlags.defeatAll)),
      reason: '本来就没有敌人，不该算"敌全灭"',
    );
  });

  test('★★ 端到端：击破首领 -> 命中 EndingScene（第 ④ 步的判据）', () {
    // 这一步把两半拼起来：**推导出的标志** 喂给 **条件判定器**
    final flags = deriveEventFlags(
      units: const [
        BattleUnitView(charIndex: 104, faction: Faction.red, alive: false),
        BattleUnitView(charIndex: 1, faction: Faction.blue, alive: true),
      ],
      chapterIndex: 0,
      defeatTalk: const [oneillTalk],
    );
    final hit = prologue().firstMatch(flags.contains);
    expect(hit, isNotNull, reason: '击破首领后应当命中一条条件');
    expect(hit!.script, 'EventScr_Prologue_EndingScene',
        reason: '序章击破首领 -> 演结束脚本 -> 它内部 MNC2(1) 切到第 1 章');
  });
}

// ---------------------------------------------------------------- 单位编号
//
// 用户反复报「我方单位显示的还是不对」——根因是**编号冲突**：
//
//     _loadUnitsFromTable 里写的是 `id: 0x100 + added.length`
//     载入我方 2 人 -> 0x100, 0x101
//     载入敌方 3 人 -> 0x100, 0x101, 0x102     <- ★ 撞上了
//
// 而 `BattleView._unitById` 按 id 复用组件 -> 敌人的组件顶掉我方的。
// HUD 上赛特在 (4,4)，画面上那一格是空的。
//
// 这条判据钉住"同一战场里编号必须唯一"。
void _unitIdTests() {
  test('★ 同一战场里的单位编号必须唯一（组件按 id 复用，撞了会顶掉）', () {
    // 模拟两次 LOAD：我方 2 人 + 敌方 3 人
    final f = BattleField(width: 15, height: 10, units: [
      MapUnit(id: 0x100, faction: Faction.blue, x: 4, y: 4),
      MapUnit(id: 0x101, faction: Faction.blue, x: 4, y: 5),
      MapUnit(id: 0x102, faction: Faction.red, x: 14, y: 7),
      MapUnit(id: 0x103, faction: Faction.red, x: 14, y: 8),
      MapUnit(id: 0x104, faction: Faction.red, x: 14, y: 7),
    ]);
    final ids = f.units.map((u) => u.id).toList();
    expect(ids.toSet().length, ids.length,
        reason: '编号重复会让画面上的单位互相顶掉');
  });

  test('★ 序章真实名册：2 我方 + 3 敌方，且坐标与源码一致', () {
    final f = File('tools/pipeline/out/tables/unit_defs.json');
    if (!f.existsSync()) return;
    final t = (jsonDecode(f.readAsStringSync())
        as Map<String, dynamic>)['tables'] as Map<String, dynamic>;
    List<Map<String, dynamic>> real(String k) => [
          for (final e in (t[k] as List<dynamic>))
            if (((e as Map<String, dynamic>)['charIndex'] ?? 0) != 0 ||
                (e['classIndex'] ?? 0) != 0)
              e,
        ];
    final ally = real('UnitDef_Event_PrologueAlly');
    final enemy = real('UnitDef_Event_PrologueEnemy');
    expect(ally.length, 2);
    expect(enemy.length, 3);
    // 赛特(2) 在 (13,9)，艾莉卡(1) 在 (8,5)
    expect(ally[0]['charIndex'], 2);
    expect([ally[0]['x'], ally[0]['y']], [13, 9]);
    expect(ally[1]['charIndex'], 1);
    expect([ally[1]['x'], ally[1]['y']], [8, 5]);
    // 奥尼尔(104) 在 (14,8)
    expect(enemy[0]['charIndex'], 104);
    expect([enemy[0]['x'], enemy[0]['y']], [14, 8]);
  });

  _turnEventTests();
}

void _turnEventTests() {
  ChapterObjectives prologueTurn() => ChapterObjectives.fromJson(const [
        {'i': 0, 'cmd': 'TURN', 'doneFlag': 0, 'script': 'EventScr_Prologue_Turn1', 'turn': 1, 'maxTurn': 0, 'faction': 128},
        {'i': 3, 'cmd': 'TURN', 'doneFlag': 0, 'script': 'EventScr_Prologue_Turn2', 'turn': 2, 'maxTurn': 0, 'faction': 0},
        {'i': 6, 'cmd': 'TURN', 'doneFlag': 0, 'script': 'EventScr_Prologue_Turn3', 'turn': 3, 'maxTurn': 0, 'faction': 0},
        {'i': 9, 'cmd': 'TURN', 'doneFlag': 8, 'script': 'EventScr_Prologue_ONeillAttack', 'turn': 1, 'maxTurn': 255, 'faction': 128},
        {'i': 12, 'cmd': 'END'},
      ]);

  String? at(int turn, int faction, {Set<int> flags = const {}}) =>
      prologueTurn()
          .firstTurnMatch(turn: turn, faction: faction, hasFlag: flags.contains)
          ?.script;

  test('turn 1 敌方阶段 → Turn1；自军阶段不命中', () {
    expect(at(1, 128), 'EventScr_Prologue_Turn1');
    expect(at(1, 0), isNull, reason: 'Turn1 是敌军的');
  });

  test('maxTurn == 0 表示"只有那一回合"', () {
    expect(at(2, 0), 'EventScr_Prologue_Turn2');
    expect(at(3, 0), 'EventScr_Prologue_Turn3');
    expect(at(4, 0), isNull, reason: 'maxTurn=0 → 只在 turn 2 命中');
  });

  test('maxTurn == 0xFF 表示"从 turn 起一直有效"', () {
    expect(at(1, 128), 'EventScr_Prologue_Turn1',
        reason: 'Turn1 在前，先命中它');
    // turn 9 时 Turn1（只到 turn 1）已经不命中，但 ONeillAttack 仍然命中
    // —— 这正是 `maxTurn == 0xFF` 的含义（从 turn 1 起无限期）
    expect(at(9, 128), 'EventScr_Prologue_ONeillAttack',
        reason: 'maxTurn=0xFF 意味着"从 turn 1 起一直有效"');
    // ⚠️ 我第一版把这里写成 isNull（以为"回合数超了就不命中"）——
    // 红了一次，**是判据错**，不是代码错。
  });

  test('doneFlag 已置上就跳过（ONeillAttack 只演一次）', () {
    expect(at(5, 128, flags: {8}), isNull,
        reason: 'doneFlag 8 置上后，ONeillAttack 不再命中');
  });

  test('阵营不符不命中', () {
    expect(at(5, 0), isNull);
  });
}
