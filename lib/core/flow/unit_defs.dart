// 章节单位配置表（`struct UnitDefinition`）的加载。
//
// ## ★ 章节 → 单位表的链路（本轮找到的，尚未实现）
//
// 之前卡在"哪一章用哪张单位表"。这轮把整条链找齐了：
//
//     chapterIndex
//       → gChapterDataTable[i]              （79 条，可读初始化器，
//                                            src/data/chapter_settings.h）
//       → .mapEventDataId                   （u8 索引）
//       → gChapterDataAssetTable[id]        （资源指针表）
//       → struct ChapterEventGroup          （include/chapterdata.h:118）
//           ├── turnBasedEvents             ← 回合事件脚本表
//           ├── characterBasedEvents        ← 角色事件
//           ├── locationBasedEvents         ← 地点事件（村庄/宝箱/门）
//           ├── miscBasedEvents
//           ├── traps / extraTrapsInHard
//           ├── playerUnitsInNormal/Hard    ← **我方单位配置表**
//           ├── playerUnitsChoice1..3InEncounter
//           ├── enemyUnitsChoice1..3InEncounter ← **敌方单位配置表**
//           ├── beginningSceneEvents        ← **开场剧情**
//           └── endingSceneEvents
//
// 也就是说：**已经提取的两样东西（单位配置表、事件脚本表）在这里汇合**，
// 而 `struct ChapterEventGroup` 就是那个汇合点。
//
// 下一步的提取工作：
//   1. 从 chapter_settings.h 读 gChapterDataTable 的
//      (internalName, mapEventDataId, map 资源 id)
//   2. 读 gChapterDataAssetTable（指针表，在 carve 数据里）
//   3. 读各 ChapterEventGroup 实例（同样是 carve 数据），
//      把里面的指针解析回"哪张单位表 / 哪张事件表"
//
// ⚠️ 第 2、3 步涉及**指针**，而指针是平台/布局相关的 ——
// 需要读重定位信息（`otool -r` / `readelf -r`），
// 不能再走"导出绝对地址"的老路（章节事件就是这么栽的）。
//
// ## 数据从哪来
//
// `tools/pipeline/extract/parse_unit_defs.py` 把
// `src/data/frontier_df3_unitdef_b/frontier_df3_unitdef_b.c` 里的 111 张表
// 编成目标文件，用 `nm` 的地址差求长度，**让探针把解码后的字段打印出来**。
//
// 为什么打印字段而不是原始字节：宿主上 `const void* redas` 是 8 字节
// （GBA 是 4），位域布局也不保证一致 —— 打印字节会让产物**平台相关**。
// 这个坑在章节事件那边踩过（20/21 张表 macOS 与 Linux 不一致）。
//
// ## 产物是**可复现**的（已验证）
//
// 两件事一起保证了这一点：
//
//   1. **打印解码后的字段**，不打印原始字节 ——
//      宿主上 `const void*` 是 8 字节、位域布局也不保证与 GBA 一致
//   2. **元素个数用探针里的 `sizeof` 算**，不靠 `nm` 的地址差 ——
//      ELF 与 Mach-O 对"下一个符号"的取法不同
//      （踩过：Linux 2629 条 / macOS 2797 条，逐条都不同）
//
// 实测（仓库**只读**挂载，杜绝污染）：Linux 2796 / macOS 2796，逐条一致。
//
// ⚠️ 这里有个我自己踩过的坑值得记：第一次声称"跨平台一致"时，
// 对比的两边其实**都是 Linux 产物** —— 跑 ci-linux.sh 时容器把产物
// 写进了挂载的仓库（`--out out/tables`），覆盖了 macOS 那份。
// 拿被自己覆盖的基准去对比，当然"一致"。
// **验证跨平台一致性时，必须确认对比的两份确实来自不同平台。**
//
// 正解是让编译器自己算相邻表的地址差（`(char*)&next - (char*)&cur`），
// 那属于后续工作。当前以 macOS 的产物入库，CI 不重新生成。
//
// ## ⚠️ `{0}` 是分组分隔符，不是表的结尾
//
// 一张表里通常有多个 `{0}`：玩家单位组 / 敌军组 / 增援组之间用它隔开。
// 按"扫到 charIndex==0 就停"来读，111 张表只会导出 9 条
// （实际有 2797 条）。表长必须靠符号地址差求。

import 'dart:convert';

/// 一条单位配置。
class UnitDef {
  const UnitDef({
    required this.index,
    required this.charIndex,
    required this.classIndex,
    required this.leaderCharIndex,
    required this.allegiance,
    required this.level,
    required this.autolevel,
    required this.x,
    required this.y,
    required this.genMonster,
    required this.itemDrop,
    required this.sumFlag,
    required this.items,
  });

  /// 在表里的座位号
  final int index;

  final int charIndex;
  final int classIndex;
  final int leaderCharIndex;

  /// 阵营：0 = 我方，1 = 友军 NPC，2 = 敌方
  /// （对应 `FACTION_BLUE << ?` 的编码，见 `bmunit.h` 的 `allegiance : 2`）
  final int allegiance;

  final int level;
  final int autolevel;

  /// 出生坐标。位域只有 **6 位**，所以合法范围是 0..63。
  final int x;
  final int y;

  final int genMonster;
  final int itemDrop;
  final int sumFlag;

  /// 携带道具（最多 4 件，0 表示空）
  final List<int> items;

  /// 分组分隔符（`{0}`）—— 它本身不是单位，而是组与组之间的边界
  bool get isGroupSeparator => charIndex == 0;

  /// 转成地图上的阵营位（与 `lib/core/battle/phase.dart` 的 `Faction` 对齐）
  int? get factionBit => switch (allegiance) {
        0 => 0x00, // 我方
        1 => 0x40, // 友军 NPC
        2 => 0x80, // 敌方
        _ => null,
      };

  static UnitDef fromJson(Map<String, dynamic> j) => UnitDef(
        index: j['index'] as int,
        charIndex: j['charIndex'] as int,
        classIndex: j['classIndex'] as int,
        leaderCharIndex: j['leaderCharIndex'] as int,
        allegiance: j['allegiance'] as int,
        level: j['level'] as int,
        autolevel: j['autolevel'] as int,
        x: j['x'] as int,
        y: j['y'] as int,
        genMonster: j['genMonster'] as int,
        itemDrop: j['itemDrop'] as int,
        sumFlag: j['sumFlag'] as int,
        items: [
          j['item0'] as int,
          j['item1'] as int,
          j['item2'] as int,
          j['item3'] as int,
        ],
      );

  @override
  String toString() => 'UnitDef(char=${charIndex.toString()}, '
      'class=$classIndex, 阵营=$allegiance, Lv$level, ($x,$y))';
}

/// 一张单位配置表
class UnitDefTable {
  UnitDefTable({required this.name, required this.entries});

  final String name;
  final List<UnitDef> entries;

  /// 真正的单位（过滤掉分组分隔符）
  List<UnitDef> get units =>
      entries.where((e) => !e.isGroupSeparator).toList();

  /// 分组：按 `{0}` 分隔符切开的连续段
  List<List<UnitDef>> get groups {
    final out = <List<UnitDef>>[];
    var cur = <UnitDef>[];
    for (final e in entries) {
      if (e.isGroupSeparator) {
        if (cur.isNotEmpty) out.add(cur);
        cur = <UnitDef>[];
      } else {
        cur.add(e);
      }
    }
    if (cur.isNotEmpty) out.add(cur);
    return out;
  }
}

/// 全部单位配置表
class UnitDefs {
  UnitDefs(this.tables);

  final Map<String, UnitDefTable> tables;

  static UnitDefs parse(String json) {
    final d = jsonDecode(json) as Map<String, dynamic>;
    final raw = d['tables'] as Map<String, dynamic>;
    final out = <String, UnitDefTable>{};
    raw.forEach((name, v) {
      out[name] = UnitDefTable(
        name: name,
        entries: (v as List<dynamic>)
            .map((e) => UnitDef.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
    });
    return UnitDefs(out);
  }

  int get totalUnits =>
      tables.values.fold(0, (s, t) => s + t.units.length);
}
