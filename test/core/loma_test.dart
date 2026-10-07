// `LOMA` —— 换地图指令的**操作数语义**与「章节号 → 地图名」这条表。
//
// ## 为什么必须有这条
//
// 用户说过：「卫兵向国王报告的背景地图应该是王宫里，等等一波剧情，
// 还有王宫外的场景，再后面才到序章的游玩场景地图」。
//
// 核对源码后发现**三张图两处错**：
//
//   1. `chapter_maps.json` 用**资产符号名**当键（`CH65`），
//      而 `chapters.json` 里那一章的 `internalName` 是 `'-'` ——
//      `LOMA(64)` 静默不换图，**"王宫外"那一幕整段消失**
//   2. `LOMA` 的相机坐标在**槽 0xB**，不读它就只能居中到地图中央
//
// 出处：`src/eventscr_0800F390.c:31-72`（`Event25_ChangeMap`）
//
// ```c
// short chIndex = current[1];
// x = ((u16 *)(gEventSlots + 0xB))[0];
// y = ((u16 *)(gEventSlots + 0xB))[1];
// if (chIndex < 0) chIndex = gEventSlots[2];
// ```
import 'dart:convert';
import 'dart:io';

import 'package:fe8r/core/core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('resolveLomaChapter（`short chIndex` + 负数用槽 2）', () {
    test('普通章节号原样返回', () {
      expect(resolveLomaChapter(0x10, 0), 16);
      expect(resolveLomaChapter(0x40, 0), 64);
      expect(resolveLomaChapter(0, 0), 0);
    });

    test('★ 0xFFFF 当 **signed short** 是 -1 → 章节号取槽 2', () {
      // 脚本里真的用到：`EventScr_CutsceneExecEnd_Sub1` 是
      // `SVAL(0xB, 0)` + `LOMA(0xFFFF)`。
      // 当成无符号 65535 处理就永远查不到地图（而且不报错）。
      expect(resolveLomaChapter(0xFFFF, 7), 7);
      expect(resolveLomaChapter(0x8000, 3), 3);
    });
  });

  group('lomaCamera（槽 0xB：低 16 = x，高 16 = y）', () {
    test('序章王座厅那一幕是 (14, 10)', () {
      // `SVAL(EVT_SLOT_B, 0x000A000E)` —— 高 16 位 0x000A=10、低 16 位 0x000E=14
      final c = lomaCamera(0x000A000E);
      expect(c.x, 14);
      expect(c.y, 10);
    });

    test('0 就是 (0,0)', () {
      final c = lomaCamera(0);
      expect((c.x, c.y), (0, 0));
    });
  });

  group('章节号 → 地图名（chapter_maps.json）', () {
    late Map<String, dynamic> byIndex;
    late List<Map<String, dynamic>> chapters;

    setUpAll(() {
      final p = 'tools/pipeline/out/tables/chapter_maps.json';
      if (!File(p).existsSync()) fail('缺少 $p');
      byIndex = (jsonDecode(File(p).readAsStringSync())
          as Map<String, dynamic>)['byIndex'] as Map<String, dynamic>;
      final cp = 'tools/pipeline/out/tables/chapters.json';
      chapters = ((jsonDecode(File(cp).readAsStringSync())
              as Map<String, dynamic>)['chapters'] as List)
          .cast<Map<String, dynamic>>();
    });

    test('79 章全都有 index 键', () {
      expect(byIndex.length, chapters.length);
      for (final c in chapters) {
        expect(byIndex['${c['index']}'], isNotNull,
            reason: 'index ${c['index']} 在 byIndex 里找不到');
      }
    });

    test('★ 序章的三张图（用户描述的那三段剧情）', () {
      String mapOf(int i) =>
          (byIndex['$i'] as Map<String, dynamic>)['map'] as String;
      // LOMA(0x10) / LOMA(0x40) / LOMA(0)
      expect(mapOf(16), 'Ch16Map', reason: '第一段：王座厅（城堡内景）');
      expect(mapOf(64), 'RenaisCastleMap', reason: '第二段：Renais 城');
      expect(mapOf(0), 'PrologueMap', reason: '第三段：可玩地图');
    });

    test('★ `internalName` 是 `-` 的章节也必须查得到（这次的根因）', () {
      // 这些章在 `chapters.json` 里没有名字（`-`），但它们的 LOMA 目标
      // 必须能解析 —— 否则就是静默不换图。
      final dashes = chapters.where((c) => c['internalName'] == '-').toList();
      expect(dashes, isNotEmpty, reason: '数据变了？原本有 19 个这样的章节');
      final bad = <int>[];
      for (final c in dashes) {
        final v = byIndex['${c['index']}'] as Map<String, dynamic>?;
        final m = v?['map'] as String?;
        if (m == null || m == '?') bad.add(c['index'] as int);
      }
      // `?` = 资产表反查不到符号名（未 carve），是**已知缺口**；
      // 这里只钉住"不能变多"。基线见 tools/verify/map_asset_baseline.json
      expect(bad.length, lessThanOrEqualTo(4),
          reason: '查不到地图名的无名章节变多了：$bad');
    });
  });
}
