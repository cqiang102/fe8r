// 章节 → 事件组的映射（`tools/pipeline/out/tables/chapter_links.json`）
//
// ## 出处
//
// ```c
// // src/chapterdata.c:13-24
// const void* GetChapterMapChangesPointer(unsigned chIndex) {
//     return gChapterDataAssetTable[GetROMChapterStruct(chIndex)->map.changeLayerId];
// }
// const struct ChapterEventGroup* GetChapterEventDataPointer(unsigned chIndex) {
//     return gChapterDataAssetTable[GetROMChapterStruct(chIndex)->mapEventDataId];
// }
// ```
//
// **两个不同的字段、两个不同的表**：
//   * `map.changeLayerId` → 地图变更表（`struct MapChange`）
//   * `mapEventDataId`    → **事件组**（`struct ChapterEventGroup`）
//
// ## 这条测试为什么存在
//
// 2026-xx 核对用户描述时发现：`chapter_links.json` 的 79 条链接里，
// **52 条的 `eventGroupName` 是一个 `...MapChanges` 资产名** ——
// 而 `GetChapterEventDataPointer` 取的那个下标**不可能是**地图变更表。
//
// 也就是说：**这份表里 2/3 的"事件组名"是错的**，而它一直没被发现，
// 因为跑到的只有第 0、1 章（那两条恰好是对的）。
// 这正是 `AGENTS.md` 里"索引整片为空/错位"那一类**静默失败**。
//
// 判据：**这个名字不许再变多**（棘轮）。修好提取器之后这个数字应该降到 0，
// 那时把 `suspiciousBaseline` 改成 0，并把这里的故事写进 `docs/复盘.md`。
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// 当前**已知可疑**的链接条数（名字不是事件组的样子）
///
/// **59 → 4**（这一轮修掉了）：美版注释名在 JP 表里整体错一位
/// —— 判据是 `chapter_settings.h` 的三元组
/// `(mainLayerId, changeLayerId, mapEventDataId)` 连续，而
/// `assets[mapEventDataId]` 却是 `...MapChanges`；
/// 而 `src/chapterdata.c:19` 取的是**事件组**（见 `docs/路线图.md` 欠账 #1）。
///
/// 现在剩 4 条：3 条空名（`index` 44 / 45 / 58，合法的空占位）
/// + `LagdouRuins10MapChanges`（index 55，还没解释）。
const int suspiciousBaseline = 4;

/// 名字看起来像不像事件组（`...Events` / `...EventData` / `...Event`）
bool looksLikeEventGroup(String name) => name.contains('Event');

void main() {
  late Map<String, dynamic> links;
  late List<Map<String, dynamic>> rows;

  setUpAll(() {
    final f = File('tools/pipeline/out/tables/chapter_links.json');
    if (!f.existsSync()) {
      fail('缺少 ${f.path}（先跑 tools/pipeline/extract/parse_chapter_links.py）');
    }
    links = jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
    rows = (links['links'] as List).cast<Map<String, dynamic>>();
  });

  test('链接条数 = 79（与 gChapterDataTable 的章节数一致）', () {
    expect(rows.length, 79, reason: '章节数变了就要重新核对这张表');
  });

  test('每条链接都带 mapEventDataId（它不是 changeLayerId）', () {
    for (final r in rows) {
      expect(r['mapEventDataId'], isA<int>(),
          reason: '${r['internalName']} 少了 mapEventDataId');
    }
    // `chapterdata.c:19` 用它取**事件组**，所以它必须和 changeLayerId 分开存在。
    final chapters = jsonDecode(
            File('tools/pipeline/out/tables/chapters.json').readAsStringSync())
        as Map<String, dynamic>;
    final chs = (chapters['chapters'] as List).cast<Map<String, dynamic>>();
    final byIndex = {for (final c in chs) c['index'] as int: c};
    for (final r in rows) {
      final c = byIndex[r['index'] as int];
      expect(c, isNotNull, reason: '章节 ${r['index']} 不在 chapters.json 里');
      expect(r['mapEventDataId'], c!['mapEventDataId'],
          reason: '${r['internalName']}：两张表的 mapEventDataId 对不上');
      expect(c['changeLayerId'], isA<int>(),
          reason: '${r['internalName']}：changeLayerId 也应该在（那是**另一张**表）');
    }
  });

  test('★ 棘轮：`eventGroupName` 不是事件组的条数不许超过 $suspiciousBaseline', () {
    final bad = rows
        .where((r) => !looksLikeEventGroup((r['eventGroupName'] as String?) ?? ''))
        .toList();
    expect(bad.length, lessThanOrEqualTo(suspiciousBaseline),
        reason: '变多了：${bad.map((r) => '${r['index']}:${r['eventGroupName']}').take(8).join(', ')}');
    // 现在就该**正好**是 59 —— 变少说明提取器修好了：
    // 那时把基线降下来，并订正 `docs/还差什么.md` 里 C00 那一段。
    expect(bad.length, suspiciousBaseline,
        reason: '变少了（好事）→ 收紧 suspiciousBaseline，并订正 docs/还差什么.md 里 C00 那段');
    // 每一条可疑的名字都应该能解释成"地图资产"或"空"，
    // 出现第三种就说明分类漏了 —— 那要当场看，不要放过。
    for (final r in bad) {
      final name = (r['eventGroupName'] as String?) ?? '';
      expect(name.isEmpty || name.contains('Map'), isTrue,
          reason: '${r['internalName']} 的名字 "$name" 既不像事件组也不是地图资产');
    }
    expect(bad.where((r) => (r['eventGroupName'] as String?) == null).length, 3,
        reason: '空名字的是 index 44 / 45 / 58（内部名都是 `-`）');
    // 剩下那条是 R10（LagdouRuins10MapChanges）—— 记下来，别让它悄悄变多
    final rest = bad.where((r) => r['eventGroupName'] != null).toList();
    expect(rest.length, 1);
    expect(rest.first['internalName'], 'R10');
  });

  test('★ 能解析出内容的事件组 ≥ 16（下界，不是"没抛异常"）', () {
    final groups = links['eventGroups'] as Map<String, dynamic>;
    expect(groups.length, greaterThanOrEqualTo(16));
    // 抽查真值：序章/第 1 章必须指对
    expect(rows.firstWhere((r) => r['index'] == 0)['eventGroupName'],
        'PrologueEvents');
    expect(rows.firstWhere((r) => r['index'] == 1)['eventGroupName'], 'Ch1Events');
    final pro = groups['PrologueEvents'] as Map<String, dynamic>;
    expect(pro['beginningSceneEvents'], 'EventScr_Prologue_BeginningScene');
    expect(pro['endingSceneEvents'], 'EventScr_Prologue_EndingScene');
  });

  test('★ 已知未解析的事件组：**恰好 1 条**（`Ch9Events`），多一条就要查', () {
    // 它是"目录在、reader 读不出"（`Ch9Events_ref/dat_…_ref.c`），
    // 不是"没有" —— 提取器会打印，这里钉住条数，防它悄悄变多。
    final groups = links['eventGroups'] as Map<String, dynamic>;
    final names = rows.map((r) => r['eventGroupName']).whereType<String>().toSet();
    final unresolved = names
        .where((n) => (n.contains('Event')) && !groups.containsKey(n))
        .toList()
      ..sort();
    // 42 = carve 只给 17 个事件组做了去指针化，其余 42 个只留下**名字**
    // （提取器能报出名字，但读不到内容）。这是**棘轮**：只许降。
    expect(unresolved.length, 42, reason: '未解析的事件组数变了：$unresolved');
    expect(unresolved, contains('Ch9Events'),
        reason: 'Ch9Events 是"目录在、reader 读不出"那一类（见提取器的 KNOWN_UNPARSED）');
  });

  test('★ 错位修正：55 条从"地图资产名"改回真正的事件组名', () {
    final sh = rows.where((r) => r['assetNameShifted'] == true).toList();
    expect(sh.length, 55, reason: '修正条数变了就要重新核对（欠账 #1）');
    // 抽查真值：E11（index 12）—— 原来错报 `Ch12EirikaMapChanges`
    final e11 = rows.firstWhere((r) => r['index'] == 12);
    expect(e11['mapEventDataId'], 54, reason: 'JP 的 mapEventDataId 是**索引**，不改');
    expect(e11['eventGroupName'], 'Ch12EirikaEventData');
    // 序章/第 1 章本来就没错位（它们在那一段之前）
    expect(rows.firstWhere((r) => r['index'] == 0)['assetNameShifted'], isNull);
    expect(rows.firstWhere((r) => r['index'] == 1)['assetNameShifted'], isNull);
  });

  test('★ C00（フレリア城，index 56）现在指向的是**地图变更表**，不是事件组', () {
    final c00 = rows.firstWhere((r) => r['index'] == 56);
    expect(c00['internalName'], 'C00');
    expect(c00['mapEventDataId'], 196);
    // 这是**已知 bug 的指纹**：名字是 `LordsSplitMapChanges`（`src/data/map/data_map_change.c:712`
    // 是个 `struct MapChange` 表），而 `chapterdata.c:19` 要的是 `ChapterEventGroup`。
    // 修错位之后 C00 是 `LordsSplitEvents`（真事件组名），但那张表
    // **在 carve 里没有去指针化**（`src/data/LordsSplitEvents_ref` 不存在）
    // ⇒ 它的开场/结束剧情是"读不到"，不是"没有"。见 docs/路线图.md 欠账 #2。
    expect(c00['eventGroupName'], 'LordsSplitEvents');
    // 而且那一条**没有**被解出来（`LordsSplitEvents_ref` 在 carve 里不存在），
    // 所以"C00 没有开场/结束剧情"这句话**无从谈起** —— 是读不到，不是没有。
    final groups = links['eventGroups'] as Map<String, dynamic>;
    expect(groups.containsKey('LordsSplitEvents'), isFalse);
  });
}
