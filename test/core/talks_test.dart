// 战斗对话 / 阵亡对话的查表规则。
//
// 出处：
//   * `GetBattleQuoteEntry`（`src/code_8086934.c:17-65`）
//   * `GetDefeatTalkEntry`（`src/code_8086934.c:68-92`）
//   * 三连查顺序（`src/CallBattleQuoteEventsIfAny.c:31-33`、
//     `src/eventinfo_080857A0.c:164-186`）
//
// 数据是**日版**（carve 在 `src/data/frontier_df4_menu/frontier_df4_menu.c:1455`
// 的裸 u32 数组里）。**不许用美版数据** —— 实测两版消息 id 完全不同：
//   奥尼尔战斗台词 日版 0x8D6 / 美版 0x916；阵亡 日版 0x8D7 / 美版 0x917。
import 'dart:io';

import 'package:fe8r/core/core.dart';
import 'package:flutter_test/flutter_test.dart';

TalkTables load() {
  final b = File('tools/pipeline/out/tables/battle_talks.json');
  final d = File('tools/pipeline/out/tables/defeat_talk.json');
  if (!b.existsSync() || !d.existsSync()) fail('缺少对话表 JSON');
  return TalkTables.parse(b.readAsStringSync(), d.readAsStringSync());
}

void main() {
  final t = load();
  bool none(int f) => false;
  // 1 = EVFLAG_BATTLE_QUOTES、2 = EVFLAG_DEFEAT_BOSS
  bool has(int f) => f == 1 || f == EventFlags.defeatBoss;

  test('表条数与槽数（含终止符）', () {
    expect(t.battleTalks.length, 104);   // 105 槽 - 1 终止符
    expect(t.defeatTalks.length, 79);    // 80 槽 - 1 终止符
  });

  test('★ 序章：奥尼尔的两条战斗对话（单边通配）', () {
    // `{pidA=0, pidB=104, chapter=0, flag=1, msg=0x8D6}` —— 谁打奥尼尔都算
    final a = t.battleQuote(
        pidA: 1, pidB: 104, chapterIndex: 0, flagSet: none);
    expect(a, isNotNull);
    expect(a!.msg, 0x08D6);
    expect(a.flag, 1);
    // `{pidA=104, pidB=0}` —— 奥尼尔打谁都算
    final b = t.battleQuote(
        pidA: 104, pidB: 5, chapterIndex: 0, flagSet: none);
    expect(b!.msg, 0x08D6);
  });

  test('★ 三连查：(pidA,pidB) → (pidA,0) → (0,pidB)', () {
    // 用 (pidA=104, pidB=0) 那条：传 pidB=999 时第一查不中，
    // 第二查 `(104, 0)` 命中。
    final e = t.lookupBattleQuote(
        pidA: 104, pidB: 999, chapterIndex: 0, flagSet: none);
    expect(e!.msg, 0x08D6);
  });

  test('flag 已置上 → 不再命中（`GetEventTriggerState`）', () {
    final e = t.battleQuote(
        pidA: 1, pidB: 104, chapterIndex: 0, flagSet: has);
    expect(e, isNull);
  });

  test('章节不符 → 不命中（序章的表在第 1 章不演）', () {
    final e = t.battleQuote(
        pidA: 1, pidB: 104, chapterIndex: 1, flagSet: none);
    expect(e, isNull);
  });

  test('配对条目：两侧都对调也算命中', () {
    // 表里第 1 条是 {pidA=0x45(VALTER_PROLOGUE), pidB=2(SETH), chapter=0x40}
    final fwd = t.battleQuote(
        pidA: 0x45, pidB: 2, chapterIndex: 0x40, flagSet: none);
    final rev = t.battleQuote(
        pidA: 2, pidB: 0x45, chapterIndex: 0x40, flagSet: none);
    expect(fwd, isNotNull);
    expect(rev, isNotNull, reason: '(pidA,pidB) 对调也算命中');
    expect(fwd!.msg, rev!.msg);
  });

  test('chapter == 0xFE 只在三角攻击时命中', () {
    // 天马三姐妹那三条（`frontier_df4_menu.c:1929-1940`）
    final no = t.battleQuote(
        pidA: 0x06, pidB: 0x22, chapterIndex: 0, flagSet: none);
    final yes = t.battleQuote(
        pidA: 0x06, pidB: 0x22, chapterIndex: 0, flagSet: none,
        triangleAttack: true);
    expect(no, isNull);
    expect(yes, isNotNull);
  });

  test('★ 阵亡对话：序章奥尼尔 → flag 2（EVFLAG_DEFEAT_BOSS）+ msg 0x8D7', () {
    final e = t.defeatTalk(pid: 104, chapterIndex: 0, flagSet: none);
    expect(e, isNotNull);
    expect(e!.flag, EventFlags.defeatBoss);
    expect(e.msg, 0x08D7);
    expect(e.route, chapterModeAny);
  });

  test('阵亡对话：章节不符 / flag 已置 → 不命中', () {
    expect(t.defeatTalk(pid: 104, chapterIndex: 1, flagSet: none), isNull);
    expect(t.defeatTalk(pid: 104, chapterIndex: 0, flagSet: has), isNull);
    expect(t.defeatTalk(pid: 999, chapterIndex: 0, flagSet: none), isNull);
  });

  test('★ 每条 msg 都能在日版文本表里查到（正向抽查两条真台词）', () {
    final texts = GameTexts.parse(
        File('tools/pipeline/out/tables/texts.json').readAsStringSync());
    for (final e in t.battleTalks) {
      if (e.msg != 0) expect(texts.messages[e.msg], isNotNull, reason: '战斗 msg ${e.msg}');
    }
    for (final e in t.defeatTalks) {
      if (e.msg != 0) expect(texts.messages[e.msg], isNotNull, reason: '阵亡 msg ${e.msg}');
    }
    expect(texts.messages[0x08D6]!.plain, contains('まずは貴様から'));
    expect(texts.messages[0x08D7]!.plain, contains('なんだと'));
  });
}
