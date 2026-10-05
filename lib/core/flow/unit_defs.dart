// 章节单位配置表（`struct UnitDefinition`）的加载。
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
