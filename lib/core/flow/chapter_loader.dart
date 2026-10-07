// PORT OF: src/chapterdata.c + src/eventinfo.c（章节数据表与事件表的分派）
//
// 「章节 → 事件组 → 单位表」这条链的加载。
//
// ## 链路的每一跳（全部是文本，见 tools/pipeline/extract/）
//
//     chapterIndex
//       → gChapterDataTable[i].mapEventDataId     parse_chapters.py
//       → gChDAsset_<id> → US <Name>              baseline_syms TSV
//       → <Name>_ref/*.c 的 20 个字段              parse_chapter_links.py
//           ├── playerUnitsInNormal   ← 我方单位表名
//           ├── playerUnitsInHard
//           ├── enemyUnitsChoice1..3InEncounter
//           └── beginningSceneEvents 等
//       → UnitDef_Event_* 表的内容                  parse_unit_defs.py
//
// 本文件负责**最后两跳**：把章节 + 单位表组装成 [BattleField]。
//
// ⚠️ 覆盖不完整：反编译项目只对 17 个事件组做了去指针化，
// 所以 79 章里只有 16 章能解析出事件组（见 parse_chapter_links.py 的说明）。
// 解析不出来的章节，[ChapterLoader.load] 会返回 null 而不是编造一个空战场。

import 'dart:convert';

import '../battle/phase.dart';
import 'battle_field.dart';
import 'unit_defs.dart';

/// 一个事件组（`struct ChapterEventGroup`）——20 个字段全是符号名。
class ChapterEventGroup {
  const ChapterEventGroup({required this.name, required this.fields});

  /// 如 `PrologueEvents`
  final String name;

  /// 字段名 → 符号名（`0` 表示空）
  final Map<String, String> fields;

  String? get playerUnitsInNormal => _nonZero('playerUnitsInNormal');
  String? get playerUnitsInHard => _nonZero('playerUnitsInHard');
  String? get enemyUnitsChoice1 => _nonZero('enemyUnitsChoice1InEncounter');
  String? get enemyUnitsChoice2 => _nonZero('enemyUnitsChoice2InEncounter');
  String? get enemyUnitsChoice3 => _nonZero('enemyUnitsChoice3InEncounter');
  String? get beginningSceneEvents => _nonZero('beginningSceneEvents');
  String? get endingSceneEvents => _nonZero('endingSceneEvents');
  String? get turnBasedEvents => _nonZero('turnBasedEvents');

  String? _nonZero(String k) {
    final v = fields[k];
    if (v == null || v == '0') return null;
    return v;
  }
}

/// 章节 → 资产 / 事件组 的映射
class ChapterLinks {
  ChapterLinks({required this.links, required this.groups});

  /// 章节下标 → 事件组名（解析不出来的为 null）
  final Map<int, String?> links;

  final Map<String, ChapterEventGroup> groups;

  static ChapterLinks parse(String json) {
    final d = jsonDecode(json) as Map<String, dynamic>;
    final links = <int, String?>{};
    for (final l in d['links'] as List<dynamic>) {
      final m = l as Map<String, dynamic>;
      links[m['index'] as int] = m['eventGroupName'] as String?;
    }
    final groups = <String, ChapterEventGroup>{};
    (d['eventGroups'] as Map<String, dynamic>).forEach((k, v) {
      groups[k] = ChapterEventGroup(
        name: k,
        fields: (v as Map<String, dynamic>).map((a, b) => MapEntry(a, b as String)),
      );
    });
    return ChapterLinks(links: links, groups: groups);
  }
}

/// 把一章组装成可以打的 [BattleField]。
///
/// 只做**装配**，不做规则判断 —— 那是 `lib/core` 里其它模块的事。
class ChapterLoader {
  ChapterLoader({required this.links, required this.unitDefs});

  final ChapterLinks links;
  final UnitDefs unitDefs;
  /// 这一章能不能装配（事件组解析出来了 + 单位表在）
  bool canLoad(int chapterIndex) => _unitsOf(chapterIndex).isNotEmpty;

  /// 这一章用到的单位表名（我方组在前，敌方组在后）
  List<String> unitTableNames(int chapterIndex) {
    final g = _group(chapterIndex);
    if (g == null) return const [];
    return [
      if (g.playerUnitsInNormal != null) g.playerUnitsInNormal!,
      if (g.playerUnitsInHard != null) g.playerUnitsInHard!,
      if (g.enemyUnitsChoice1 != null) g.enemyUnitsChoice1!,
      if (g.enemyUnitsChoice2 != null) g.enemyUnitsChoice2!,
      if (g.enemyUnitsChoice3 != null) g.enemyUnitsChoice3!,
    ];
  }

  ChapterEventGroup? _group(int chapterIndex) {
    final name = links.links[chapterIndex];
    if (name == null) return null;
    return links.groups[name];
  }

  List<UnitDef> _unitsOf(int chapterIndex) {
    final out = <UnitDef>[];
    for (final t in unitTableNames(chapterIndex)) {
      final table = unitDefs.tables[t];
      if (table != null) out.addAll(table.units);
    }
    return out;
  }

  /// 装配出一个章节的战场。
  ///
  /// [width] / [height] 来自地图（TMX），因为单位配置里只有坐标没有尺寸。
  /// [makeItem] 是 `MakeNewItem`（`src/MakeNewItem.c:27`）——
  /// 它要查道具表算耐久，所以由调用方（持有道具表的那一层）给。
  /// **不给默认值**：道具耐久编不出来时应当显式处理，而不是塞一个 0 进去。
  ///
  /// 返回 null 表示**这一章装配不出来**（事件组没解析出来，或单位表缺失）——
  /// 不返回一个空的战场来假装成功。
  BattleField? load(
    int chapterIndex, {
    required int width,
    required int height,
    required int Function(int itemIndex) makeItem,
    int Function(int classId)? movementOf,
  }) {
    final names = unitTableNames(chapterIndex);
    if (names.isEmpty) return null;

    final units = <MapUnit>[];
    var nextId = 1;
    final missing = <String>[];

    for (final tname in names) {
      final table = unitDefs.tables[tname];
      if (table == null) {
        missing.add(tname);
        continue;
      }
      for (final u in table.units) {
        final faction = _factionOf(u);
        if (faction == null) continue; // 阵营越界：跳过而不是猜
        // ⚠️ **必须走 `UnitDef.toMapUnit`**（与游戏里的 `LOAD1` 同一条路）——
        // 这里原来手写 `MapUnit(...)`，漏了 `charIndex` 和 `items`：
        // 装配出来的单位**没有角色身份、没有武器**。
        units.add(u.toMapUnit(
          id: nextId++,
          faction: faction,
          makeItem: makeItem,
          movement: movementOf?.call(u.classIndex) ?? 5,
          name: '${u.charIndex}',
        ));
      }
    }

    if (missing.isNotEmpty) {
      // 有表缺失时**不静默返回半个战场** —— 那样打起来会莫名其妙少人。
      // 调用方要么补数据，要么显式接受。
      return null;
    }
    if (units.isEmpty) return null;

    return BattleField(
      width: width,
      height: height,
      units: units,
      turn: 1,
      activeFaction: Faction.blue,
    );
  }

  static int? _factionOf(UnitDef u) => switch (u.allegiance) {
        0 => Faction.blue,
        1 => Faction.green,
        2 => Faction.red,
        _ => null,
      };
}
