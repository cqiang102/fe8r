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
  pid: 'CHARACTER_ONEILL',
  chapter: 'CHAPTER_L_PROLOGUE',
  flag: 'EVFLAG_DEFEAT_BOSS',
);

/// `CHARACTER_ONEILL = 104`（`include/constants/characters.h`）
const oneill = 104;

String? _charName(int i) => i == oneill ? 'CHARACTER_ONEILL' : 'CHARACTER_X';

void _deriveTests() {
  test('★ 击破首领 -> 置 EVFLAG_DEFEAT_BOSS', () {
    final flags = deriveEventFlags(
      units: const [
        BattleUnitView(charIndex: 104, faction: Faction.red, alive: false),
        BattleUnitView(charIndex: 1, faction: Faction.blue, alive: true),
      ],
      chapterIndex: 0,
      defeatTalk: const [oneillTalk],
      charNameOf: _charName,
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
      charNameOf: _charName,
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
      charNameOf: _charName,
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
      charNameOf: _charName,
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
        charNameOf: _charName,
      ),
      contains(EventFlags.defeatAll),
    );
    expect(
      deriveEventFlags(
        units: blues,
        chapterIndex: 0,
        defeatTalk: const [],
        charNameOf: _charName,
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
      charNameOf: _charName,
    );
    final hit = prologue().firstMatch(flags.contains);
    expect(hit, isNotNull, reason: '击破首领后应当命中一条条件');
    expect(hit!.script, 'EventScr_Prologue_EndingScene',
        reason: '序章击破首领 -> 演结束脚本 -> 它内部 MNC2(1) 切到第 1 章');
  });
}
