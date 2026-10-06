// 场景剧情：**从 C 源码直接生成 Dart**，没有 JSON 中间层。
//
// 判据：
//   * 生成的 Dart 与仓库里的**逐字节一致**（可复现）
//   * 序章开场能走完，且第一句话就是原作内容
//   * 缺失的脚本引用被**生成器列出来**（而不是运行时才发现）
import 'dart:io';

import 'package:fe8r/core/core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('场景剧情（生成的 Dart 代码）', () {
    late GameTexts texts;
    late SceneRunner runner;

    setUpAll(() {
      final tf = File('tools/pipeline/out/tables/texts.json');
      if (!tf.existsSync()) fail('缺少 ${tf.path}');
      texts = GameTexts.parse(tf.readAsStringSync());
      runner = SceneRunner(texts: texts);
    });

    test('脚本是**编译进来的常量**，不是运行时解析的文件', () {
      // 这条断言本身就是设计意图：`allSceneScripts` 是生成的 Dart 常量，
      // 没有 JSON、没有 jsonDecode。脚本数变了说明 C 源码或生成器变了。
      expect(allSceneScripts.length, 196);
    });

    test('序章开场：第一条就是 CALL 到王座过场', () {
      final s = allSceneScripts['EventScr_Prologue_BeginningScene'];
      expect(s, isNotNull);
      final first = s!.ops.first;
      expect(first, isA<CallScript>());
      expect((first as CallScript).target.name,
          'EventScr_Prologue_RenaisThroneCutscene');
    });

    test('EVT_SLOT_* 生成成**整数**（是常量，不是符号）', () {
      final s = allSceneScripts['EventScr_Prologue_BeginningScene']!;
      final sval = s.ops.whereType<SetSlot>().first;
      expect(sval.slot, 2, reason: 'EVT_SLOT_2 应当生成成整数 2');
      expect(sval.value, isA<Sym>());
    });

    test('符号 + 偏移解析正确（ASMC(X + 0x1)）', () {
      final s = allSceneScripts['EventScr_Prologue_BeginningScene']!;
      final asmc = s.ops.whereType<AsmCallOp>().first;
      expect(asmc.target.name, 'BmGuideTextSetAllGreen');
      expect(asmc.target.offset, 1);
    });

    test('缺失的脚本被**生成器**列出来（不是运行时才发现）', () {
      // 这是去掉 JSON 的主要收益：运行时才知道的"缺 6 个"，
      // 现在是生成产物里的一张清单。
      expect(missingSceneScripts, isNotEmpty);
      expect(missingSceneScripts, contains('EventScr_Prologue_EirikaAttacked'));
      // 上游尚未 carve，不是解析漏了。
      // 41 个 —— 数字钉死：反编译项目补齐后这里会失败，提醒更新结论。
      expect(missingSceneScripts.length, 41);
    });

    test('序章开场能走完并产出台词', () {
      final r = runner.run('EventScr_Prologue_BeginningScene');
      expect(r.texts, isNotEmpty);
      expect(r.events.last, isA<SceneFinished>());
    });

    test('产出的台词能对上真实内容', () {
      final r = runner.run('EventScr_Prologue_BeginningScene');
      final all = r.texts.map((t) => t.message.plain).join('\n');
      expect(all.contains('フレリア領'), isTrue,
          reason: '序章开场应当包含"越过前面的桥就是弗蕾莉亚领地"');
    });

    test('`CALL` 会切进被调用的脚本（王座过场的对白也出现）', () {
      final r = runner.run('EventScr_Prologue_BeginningScene');
      final names = r.texts.map((t) => t.scriptName).toSet();
      expect(names, contains('EventScr_Prologue_RenaisThroneCutscene'));
    });

    test('`[A]` 变成显式 WaitForInput', () {
      final r = runner.run('EventScr_Prologue_BeginningScene');
      expect(r.events.whereType<WaitForInput>(), isNotEmpty);
    });

    test('缺失的引用被如实带出来，但**不阻断**执行', () {
      final r = runner.run('EventScr_Prologue_BeginningScene');
      expect(r.missing, contains('EventScr_Prologue_EirikaAttacked'));
      expect(r.texts, isNotEmpty, reason: '缺了引用不等于崩了');
    });
  });

  group('游戏文本', () {
    late GameTexts texts;

    setUpAll(() {
      texts = GameTexts.parse(
          File('tools/pipeline/out/tables/texts.json').readAsStringSync());
    });

    test('3339 条消息', () {
      expect(texts.messages.length, 3339);
    });

    test('章节标题能对上', () {
      expect(texts.titles['L00'], 'ルネス陥落');
      expect(texts.titles['E20'], '聖魔の光石');
    });

    test('`[LF]` 变成真换行（不处理会让对白挤成一坨）', () {
      final withLf = texts.messages.values
          .where((m) => m.segments.any((s) => s is TextControl && s.isLineBreak));
      expect(withLf, isNotEmpty);
      expect(withLf.first.plain, contains('\n'));
    });

    test('控制码 [\$XXXX] 也被识别（不是文字）', () {
      // 第一版漏了这种写法，截图里原样显示了 `[$0152]`
      final withDollar = texts.messages.values.where((m) => m.segments
          .whereType<TextControl>()
          .any((c) => c.name.startsWith(r'$')));
      expect(withDollar, isNotEmpty);
      expect(withDollar.first.plain.contains(r'$0152'), isFalse,
          reason: '控制码不该出现在纯文字里');
    });
  });
}
