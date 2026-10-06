// 场景剧情脚本 + 游戏文本的端到端测试。
//
// **这是"理解剧情"这条线第一次有可验证的产物**：
//   源码 → 指令序列（参数是名字） → 文本表 → 实际对白
import 'dart:io';

import 'package:fe8r/core/core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('场景剧情（从源码解析）', () {
    late SceneScripts scenes;
    late GameTexts texts;

    setUpAll(() {
      for (final p in [
        'tools/pipeline/out/tables/scene_scripts.json',
        'tools/pipeline/out/tables/texts.json',
      ]) {
        if (!File(p).existsSync()) fail('缺少 $p');
      }
      scenes = SceneScripts.parse(
          File('tools/pipeline/out/tables/scene_scripts.json').readAsStringSync());
      texts = GameTexts.parse(
          File('tools/pipeline/out/tables/texts.json').readAsStringSync());
    });

    test('解析出 196 个场景脚本', () {
      // ⚠️ 166 → 196 是**修正**：第一版按文件名扫
      //（`src/data/EventScr_*`），漏掉了定义在
      // `worldmap_gmapunit/dat_worldmap_gmapunit_p1542.c` 里的
      // `EventScr_CallOnTutorialMode` —— 而序章第 3 条就 CALL 它。
      // **按文件名猜内容，就会漏。**
      expect(scenes.scripts.length, 196);
    });

    test('序章开场脚本：37 条指令，第一条是 CALL 到王座过场', () {
      final s = scenes.scripts['EventScr_Prologue_BeginningScene'];
      expect(s, isNotNull);
      expect(s!.instructions.length, 37);

      final first = s.instructions.first;
      expect(first.op, 'CALL');
      expect(first.args.length, 1);
      expect(first.syms.single.name,
          'EventScr_Prologue_RenaisThroneCutscene');
    });

    test('EVT_SLOT_* 被解析成**整数**（是常量，不是符号引用）', () {
      final s = scenes.scripts['EventScr_Prologue_BeginningScene']!;
      final sval = s.instructions.firstWhere((i) => i.op == 'SVAL');
      // SVAL(EVT_SLOT_2, <符号>) —— 槽位是 2，值是符号
      expect(sval.args[0], 2, reason: 'EVT_SLOT_2 应当解析成整数 2');
      expect(sval.args[1], isA<SceneSym>());
    });

    test('符号 + 偏移正确解析（ASMC(X + 0x1)）', () {
      final s = scenes.scripts['EventScr_Prologue_BeginningScene']!;
      final asmc = s.instructions.firstWhere((i) => i.op == 'ASMC');
      final sym = asmc.syms.single;
      expect(sym.name, 'BmGuideTextSetAllGreen');
      expect(sym.offset, 1);
    });

    test('依赖分析：能找到引用的脚本，也会**暴露缺失的**', () {
      const pro = 'EventScr_Prologue_BeginningScene';
      final deps = scenes.dependenciesOf(pro);
      expect(deps, contains('EventScr_Prologue_RenaisThroneCutscene'));
      expect(deps, contains('EventScr_Prologue_GiveRapier'));
      for (final d in deps) {
        expect(scenes.scripts.containsKey(d), isTrue);
      }

      // `EventScr_CallOnTutorialMode` 现在找到了（扩大扫描范围之后）。
      expect(scenes.scripts.containsKey('EventScr_CallOnTutorialMode'), isTrue);

      // ⚠️ 但仍有 3 个**在整个反编译项目里都没有定义** ——
      // 是上游尚未 carve 出来的，不是解析漏了。
      // 如实记录：**这就是序章跑起来会缺的地方**。
      final missing = scenes.missingOf(pro);
      expect(missing, contains('EventScr_Prologue_EirikaAttacked'));
      expect(missing, contains('EventScr_Prologue_ONeillSpawn'));
      expect(missing, contains('EventScr_Prologue_ExecTut'));
      // 它们都是通过 `SVAL(槽位, 脚本)` 间接引用的，
      // 所以运行时的表现是"某个槽位指向一个不存在的脚本"，
      // 而不是"直接 CALL 不存在的脚本" —— 处理方式不同。
    });

    test('**序章开场的实际对白能读出来**（这条是整条链的终点）', () {
      // 序章开场里的 TEXTSHOW 参数就是文本 id —— 纯数字，不受指针问题影响
      final s = scenes.scripts['EventScr_Prologue_BeginningScene']!;
      final ids = <int>[];
      for (final i in s.instructions) {
        if (i.op == 'TEXTSHOW' && i.args.isNotEmpty && i.args[0] is int) {
          ids.add(i.args[0] as int);
        }
      }
      expect(ids, isNotEmpty, reason: '序章开场应当有对白');

      final m = texts.byId(ids.first);
      expect(m, isNotNull, reason: '文本 id ${ids.first} 应当存在');
      expect(m!.plain, isNotEmpty);

      // 文本里应当带有渲染层需要的控制码（位置、换行、等待按键）
      final ctrls = m.segments.whereType<TextControl>().toList();
      expect(ctrls, isNotEmpty, reason: '对白里应当有控制码');
    });

    test('章节标题能对上（L00 = ルネス陥落）', () {
      expect(texts.titles['L00'], 'ルネス陥落');
      expect(texts.titles['L01'], '脱出行');
      // 终章标题
      expect(texts.titles['E20'], '聖魔の光石');
    });

    test('文本表 3339 条，且大部分不是空的', () {
      expect(texts.messages.length, 3339);
      final nonEmpty = texts.messages.values.where((m) => !m.isEmpty).length;
      expect(nonEmpty, greaterThan(3000));
    });

    test('控制码语义正确（[A] 等按键、[LF] 换行、[LoadFace] 立绘）', () {
      final withA = texts.messages.values.where(
          (m) => m.segments.whereType<TextControl>().any((c) => c.isWaitForKey));
      expect(withA, isNotEmpty, reason: '应当有等待玩家按键的对白');

      final withFace = texts.messages.values.where((m) => m.segments
          .whereType<TextControl>()
          .any((c) => c.isLoadFace));
      expect(withFace, isNotEmpty, reason: '应当有加载立绘的对白');
    });
  });
}
