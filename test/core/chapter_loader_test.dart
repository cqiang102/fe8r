// 章节装配的测试。
//
// 这是整条链的第一个**消费者**：把「章节 → 事件组 → 单位表」
// 组装成能打的 BattleField。
import 'dart:io';

import 'package:fe8r/core/core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('章节装配', () {
    late Chapters chapters;
    late ChapterLinks links;
    late UnitDefs unitDefs;
    late ChapterLoader loader;

    setUpAll(() {
      for (final p in [
        'tools/pipeline/out/tables/chapters.json',
        'tools/pipeline/out/tables/chapter_links.json',
        'tools/pipeline/out/tables/unit_defs.json',
      ]) {
        if (!File(p).existsSync()) fail('缺少 $p');
      }
      chapters = Chapters.parse(
          File('tools/pipeline/out/tables/chapters.json').readAsStringSync());
      links = ChapterLinks.parse(
          File('tools/pipeline/out/tables/chapter_links.json').readAsStringSync());
      unitDefs = UnitDefs.parse(
          File('tools/pipeline/out/tables/unit_defs.json').readAsStringSync());
      loader = ChapterLoader(links: links, unitDefs: unitDefs);
    });

    test('能装配的章节数（钉死：数据覆盖范围变了这里会失败）', () {
      // ⚠️ **15** —— 从 8 -> 14（补全 C 里的单位表）-> 15（再并入汇编里的 37 张）。
      //
      // 原因：`parse_unit_defs.py` 原来只扫三个目录模式，
      // 漏掉了一大批单位表（125 -> 369 张）。补全之后，
      // 能完整装配的章节从 8 涨到 14。
      //
      // 这个数字会随着数据覆盖上升 —— **到那时这里失败并提醒更新**。
      // （它确实提醒了：改提取器之后这个测试立刻红了。）
      var can = 0;
      for (final c in chapters.list) {
        if (loader.canLoad(c.index)) can++;
      }
      expect(can, 15, reason: '79 章里目前有 15 章能完整装配');
    });

    test('装配不出来的章节返回 null，而不是空战场', () {
      // 这是刻意的：**不假装成功**。
      // 返回空战场会让调用方以为"这章没有敌人"，而真相是数据缺失。
      var nullCount = 0;
      for (final c in chapters.list) {
        final f = loader.load(c.index, width: 20, height: 20);
        if (f == null) {
          nullCount++;
          continue;
        }
        expect(f.units, isNotEmpty, reason: '${c.internalName} 装配出了空战场');
      }
      expect(nullCount, 65);
    });

    test('装配出的单位落在真实坐标上', () {
      BattleField? any;
      for (final c in chapters.list) {
        final f = loader.load(c.index, width: 40, height: 40);
        if (f != null) {
          any = f;
          break;
        }
      }
      expect(any, isNotNull, reason: '至少要有一章能装配');

      for (final u in any!.units) {
        // 坐标必须落在地图内 —— 单位配置是 6 位位域，可能超出小地图
        expect(u.x, inInclusiveRange(0, 39));
        expect(u.y, inInclusiveRange(0, 39));
        expect([Faction.blue, Faction.green, Faction.red], contains(u.faction));
      }
      // 单位编号唯一
      final ids = any.units.map((u) => u.id).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('★ 装配出的章节现在**有敌军**了（原来只有我方）', () {
      // ⚠️ **这个测试原来断言"没有敌军"，现在反过来了。**
      //
      // 原注释写着：「这句失败说明数据补齐了，那时应当删掉这个测试
      // 并更新结论」—— 它确实失败了，所以这里按它说的更新。
      //
      // 原因：`parse_unit_defs.py` 的目录 glob 漏扫了一大半单位表
      // （125 -> 369 张），补全之后敌方单位也能装配出来了。
      final factions = <int>{};
      for (final c in chapters.list) {
        final f = loader.load(c.index, width: 40, height: 40);
        if (f == null) continue;
        factions.addAll(f.units.map((u) => u.faction));
      }
      expect(factions, contains(Faction.blue),
          reason: '应当能看到我方单位');
      expect(factions.contains(Faction.red), isTrue,
          reason: '敌军现在应当能装配出来（原来不行）');
    });

    test('单位表名来自事件组字段（Prologue 抽查）', () {
      final names = loader.unitTableNames(0); // L00 = Prologue
      expect(names, contains('UnitDef_Event_PrologueAlly'));
      expect(names, isNotEmpty);
    });

    test('章节的回合数初始为 1、行动方为我方', () {
      final f = loader.load(0, width: 30, height: 30);
      expect(f, isNotNull);
      expect(f!.turn, 1);
      expect(f.activeFaction, Faction.blue);
    });
  });
}
