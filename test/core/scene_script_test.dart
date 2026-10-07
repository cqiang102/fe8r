// 场景剧情：**从 C 源码直接生成 Dart 的 async 函数**。
//
// 没有 JSON、没有指令列表、没有解释器。
// `await` 表达"等玩家按键"，`CALL` 就是函数调用。
import 'dart:io';

import 'package:fe8r/core/core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  _chapterChainTests();

  group('场景剧情（生成的 async 函数）', () {
    late GameTexts texts;
    late List<SceneEvent> log;

    /// 测试里的 `onEvent` **立即返回** —— 不等按键。
    /// 同一份脚本既能演、也能测，不用为测试准备假输入。
    Future<void> record(SceneEvent e) async {
      log.add(e);
    }

    Scene makeScene(GameTexts t) => Scene(
          texts: t,
          scripts: allSceneFns,
          defined: definedSceneScripts,
          onEvent: record,
        );

    setUpAll(() {
      final tf = File('tools/pipeline/out/tables/texts.json');
      if (!tf.existsSync()) fail('缺少 ${tf.path}');
      texts = GameTexts.parse(tf.readAsStringSync());
    });

    setUp(() => log = []);

    test('196 个脚本都被编译成了函数（含 41 个缺失占位）', () {
      // 缺失的脚本也生成占位函数 —— 这样代码能编译，
      // 而缺口在**运行时被记录**，不是静默消失。
      expect(allSceneFns.length, greaterThanOrEqualTo(196));
      expect(allSceneFns.containsKey('EventScr_Prologue_BeginningScene'), isTrue);
      expect(allSceneFns.containsKey('EventScr_Prologue_EirikaAttacked'), isTrue,
          reason: '缺失的上游脚本也生成占位，否则调用处编译不过');
    });

    test('序章开场：`CALL` 就是函数调用，对白按顺序产出', () async {
      await allSceneFns['EventScr_Prologue_BeginningScene']!(makeScene(texts));
      final shown = log.whereType<ShowText>().toList();
      expect(shown, isNotEmpty);
      final all = shown.map((t) => t.message.plain).join('\n');
      expect(all.contains('フレリア領'), isTrue);
    });

    test('`CALL` 会切进被调用的脚本（王座过场的对白也出现）', () async {
      await allSceneFns['EventScr_Prologue_BeginningScene']!(makeScene(texts));
      final names = log.whereType<ShowText>().map((t) => t.scriptName).toSet();
      expect(names, contains('EventScr_Prologue_RenaisThroneCutscene'));
    });

    test('缺失的引用被记录，但**不阻断**演出', () async {
      final sc = makeScene(texts);
      await allSceneFns['EventScr_Prologue_BeginningScene']!(sc);
      // ⚠️ **这里原来断言 `EventScr_Prologue_EirikaAttacked` 缺失** ——
      // 它现在**存在了**（`parse_event_scripts_asm.py` 把只以 `.4byte`
      // 存在的脚本解了出来）。**测试红了，而红是对的。**
      //
      // 所以改成断言"仍然会记录缺口"（这是不变量），而不是钉某个名字。
      expect(sc.missing, isNotEmpty, reason: '仍然有没解出来的脚本，应当如实记录');
      expect(log.whereType<ShowText>(), isNotEmpty, reason: '缺了引用不等于崩了');
    });

    test('★ 只以 `.4byte` 存在的脚本已经被解出来（41 -> 16 个缺口）', () {
      // `EventScr_Prologue_ONeillSpawn` 负责放敌人 ——
      // 它缺着的时候，序章地图上永远没有敌人，也就打不到奥尼尔。
      for (final n in const [
        'EventScr_Prologue_ONeillSpawn',
        'EventScr_Prologue_EirikaAttacked',
        'EventScr_Prologue_ExecTut',
        'EventScr_LoadReinforce',
      ]) {
        expect(definedSceneScripts, contains(n), reason: '$n 应当已经解出来');
      }
    });

    test('`LOAD1` 产出 LoadUnits 事件（接上已提取的单位表）', () async {
      await allSceneFns['EventScr_Prologue_BeginningScene']!(makeScene(texts));
      final loads = log.whereType<LoadUnits>().toList();
      expect(loads, isNotEmpty, reason: '序章会 LOAD1 我方单位');
    });

    test('直线脚本生成的是**顺序代码**（没有 while/switch 包袱）', () {
      // `EventScr_Ch11B_6` 是直线脚本（无 LABEL/GOTO/BNE）
      expect(allSceneFns.containsKey('EventScr_Ch11B_6'), isTrue);
    });

    test('有分支的脚本也能跑完（`while(true){switch(pc)}` 形态）', () async {
      // 序章开场就有一处 `BNE` —— 它走的是分支形态
      final sc = makeScene(texts);
      await allSceneFns['EventScr_Prologue_BeginningScene']!(sc);
      expect(sc.missing.where((m) => m.startsWith('?CALL')),
          isEmpty, reason: '不应该出现"嵌套过深"这类执行器问题');
    });

    test('兜底指令被记下来（HUD 要显示的那些）', () async {
      final sc = makeScene(texts);
      await allSceneFns['EventScr_Prologue_BeginningScene']!(sc);
      expect(sc.placeholderCalls, isNotEmpty,
          reason: '真实脚本里必然有本阶段不执行的指令');
    });
  });

  group('游戏文本', () {
    late GameTexts texts;

    setUpAll(() {
      texts = GameTexts.parse(
          File('tools/pipeline/out/tables/texts.json').readAsStringSync());
    });

    test('3339 条消息', () => expect(texts.messages.length, 3339));

    test('章节标题能对上', () {
      expect(texts.titles['L00'], 'ルネス陥落');
      expect(texts.titles['E20'], '聖魔の光石');
    });

    test('`[LF]` 变成真换行', () {
      final withLf = texts.messages.values
          .where((m) => m.segments.any((s) => s is TextControl && s.isLineBreak));
      expect(withLf, isNotEmpty);
      expect(withLf.first.plain, contains('\n'));
    });

    test('控制码 [\$XXXX] 也被识别（不是文字）', () {
      final withDollar = texts.messages.values.where((m) => m.segments
          .whereType<TextControl>()
          .any((c) => c.name.startsWith(r'$')));
      expect(withDollar, isNotEmpty);
      expect(withDollar.first.plain.contains(r'$0152'), isFalse);
    });
  });

  _pagingGroup();
}

// ---------------------------------------------------------------------------
// 分页：FE 的文本用 `[A]`（等按键）/ `[CR]`（换页）把正文切成多页。
//
// 我第一版**没有分页**，把整条消息一口气画进两行的框里，
// 结果只显示前两行、后面全被裁掉。而当时甚至没意识到"分页"是个概念 ——
// 直到去读反编译项目的 `texts/jp_textdefs.txt`（它把控制码语义也写下来了）。
// ---------------------------------------------------------------------------
void _pagingGroup() {
  group('文本分页', () {
    late GameTexts texts;

    setUpAll(() {
      texts = GameTexts.parse(
          File('tools/pipeline/out/tables/texts.json').readAsStringSync());
    });

    test('序章开场那条消息**不止一页**（就是它撑爆了框）', () {
      final m = texts.byId(0x8c3);
      expect(m, isNotNull);
      expect(m!.pages.length, greaterThan(1),
          reason: '这条消息原本就分了好几页 —— 不分页就会溢出');
    });

    test('每一页都不含控制码，`[LF]` 保留为换行', () {
      for (final m in texts.messages.values.take(500)) {
        for (final p in m.pages) {
          expect(p.contains('['), isFalse, reason: '页里不该残留控制码');
        }
      }
    });

    test('分页不丢内容（拼起来等于纯文字去掉换行）', () {
      final m = texts.byId(0x8c3)!;
      final joined = m.pages.join().replaceAll('\n', '');
      final plain = m.plain.replaceAll('\n', '');
      expect(joined, plain, reason: '分页只是切分，不该丢字');
    });

    test('`[A]` 与 `[CR]` 都算分页标记', () {
      final keys = texts.messages.values
          .expand((m) => m.segments)
          .whereType<TextControl>()
          .where((c) => c.isPageBreak)
          .map((c) => c.name)
          .toSet();
      expect(keys, contains('A'));
      expect(keys.any((k) => k == 'CR'), isTrue,
          reason: '应当有 `[CR]`（换页）出现');
    });
  });
}

// ---------------------------------------------------------------- 第 ④ 步
//
// 「击破首领 -> EndingScene -> MNC2 -> 第 1 章」这条链的**场景级判据**。
//
// 上一组测试证明了「首领阵亡 -> 命中 EndingScene」（纯逻辑）。
// 这一组证明**那个脚本真的会切章** —— 两半拼起来，链就闭合了。
void _chapterChainTests() {
  // ⚠️ 用**真实文本表** —— 结束脚本里有对白，空表会让
  // `localized()` 抛「没有消息」，测试会以"场景异常"的形式失败。
  late GameTexts realTexts;
  setUpAll(() {
    final f = File('tools/pipeline/out/tables/texts.json');
    if (!f.existsSync()) fail('缺少 ${f.path}');
    realTexts = GameTexts.parse(f.readAsStringSync());
  });

  Scene makeScene(GameTexts t, List<SceneEvent> log) => Scene(
        texts: t,
        scripts: allSceneFns,
        defined: definedSceneScripts,
        onEvent: (e) async => log.add(e),
      );

  test('★★ EndingScene 会切到第 1 章（MNC2(1)）', () async {
    final log = <SceneEvent>[];
    // 用真实文本 —— 结束脚本里有对白，空表会抛「没有消息」
    final t = realTexts;
    await allSceneFns['EventScr_Prologue_EndingScene']!(makeScene(t, log));

    final ch = log.whereType<ChangeChapter>().toList();
    expect(ch, isNotEmpty,
        reason: '序章结束脚本里必须有 MNC2 —— 否则永远到不了第 1 章');
    expect(ch.first.chapterIndex, 1, reason: 'MNC2(1) = 切到第 1 章');
  });

  test('★★ 完整链：首领阵亡 -> 命中 EndingScene -> 真的切到第 1 章', () async {
    // ① 从战场现状推导标志（首领 = CHARACTER_ONEILL = 104）
    final flags = deriveEventFlags(
      units: const [
        BattleUnitView(charIndex: 104, faction: Faction.red, alive: false),
        BattleUnitView(charIndex: 1, faction: Faction.blue, alive: true),
      ],
      chapterIndex: 0,
      defeatTalk: const [
        DefeatTalkEntry(
          pid: 'CHARACTER_ONEILL',
          chapter: 'CHAPTER_L_PROLOGUE',
          flag: 'EVFLAG_DEFEAT_BOSS',
        ),
      ],
      charNameOf: (i) => i == 104 ? 'CHARACTER_ONEILL' : 'CHARACTER_X',
    );

    // ② 序章的真实 Misc 列表
    final objectives = ChapterObjectives([
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
        checkFlag: 0,
      ),
      const ChapterObjective(
        cmd: EventListCmd.flag,
        script: 'EventScr_GameOver',
        doneFlag: 0,
        checkFlag: EventFlags.gameOver,
      ),
      const ChapterObjective(
          cmd: EventListCmd.end, script: null, doneFlag: 0, checkFlag: 0),
    ]);

    // ③ 命中哪条
    final hit = objectives.firstMatch(flags.contains);
    expect(hit!.script, 'EventScr_Prologue_EndingScene');

    // ④ 真的跑那个脚本，看它切不切章
    final log = <SceneEvent>[];
    // 用真实文本 —— 结束脚本里有对白，空表会抛「没有消息」
    final t = realTexts;
    await allSceneFns[hit.script!]!(makeScene(t, log));

    final ch = log.whereType<ChangeChapter>().toList();
    expect(ch, isNotEmpty, reason: '结束脚本应当触发换章');
    expect(ch.first.chapterIndex, 1, reason: '第 1 章');
  });
}
