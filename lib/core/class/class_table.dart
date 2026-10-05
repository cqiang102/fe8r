// PORT OF: include/bmunit.h 的 struct ClassData（只取需要的字段）
//          + src/SetBattleUnitTerrainBonuses.c
//
// 职业表里与**地图/战斗数值**相关的那部分。
//
// ## 为什么地形加成必须按职业查
//
// 原版是：
//
//     bu->terrainAvoid   = bu->unit.pClassData->pTerrainAvoidLookup[terrainId];
//     bu->terrainDefense = bu->unit.pClassData->pTerrainDefenseLookup[terrainId];
//
// 也就是**每个职业带三张查表指针**，而不是全局一张。
// 飞行职业用的是 `_Fly` 那套，地形回避基本为 0 —— 因为"躲进森林"对
// 飞在天上的单位没有意义。
//
// ⚠️ 我最初以为地形加成是全局的，在 `fe8_game.dart` 里写死了
// "森林 (1,10)、山峰 (2,20)" 并标注为"非移植近似值"。
// 那个近似值不仅精度不对，**语义也不对**：它给飞行单位也加了森林回避。
//
// ## 移动消耗表同样是按职业的
//
// `pMovCostTable` 是**三张**表：`[0]=普通 [1]=雨天 [2]=雪天`。
// 与 `lib/core/map/movement_range.dart` 里那个 `pMovCostTable[0/1/2]` 的红线一致。

import 'dart:convert';

/// 一个职业的规则相关数据
class ClassData {
  const ClassData({
    required this.key,
    required this.number,
    required this.terrainAvoidTable,
    required this.terrainDefenseTable,
    required this.terrainResistanceTable,
    required this.movCostTables,
  });

  /// 枚举名，如 `CLASS_EIRIKA_LORD`
  final String key;

  /// `pClassData->number`
  final int number;

  final String terrainAvoidTable;
  final String terrainDefenseTable;
  final String terrainResistanceTable;

  /// `pMovCostTable`：`[普通, 雨天, 雪天]`。
  /// 少数职业（石像鬼蛋、弩车）没有这张表，此时为 null。
  final List<String>? movCostTables;
}

/// 按天气选移动消耗表（与规则层的红线一致）
enum Weather {
  normal,
  rain,
  snow;

  /// `pMovCostTable` 的下标。
  /// 用 `Enum.index` 而不是自己声明一个 `index` 字段（那会与 Enum 冲突）。
  int get tableIndex => index;
}

/// 职业表 + 它引用的地形表。
///
/// 表数据由 `tools/pipeline/extract/parse_class_tables.py` 从
/// `src/data/data_classes.c` 提取，并**校验所有引用的表名都真实存在**。
class ClassTable {
  ClassTable._({
    required this.byNumber,
    required this.terrainAvoid,
    required this.terrainDefense,
    required this.terrainResistance,
    required this.movCost,
  });

  final Map<int, ClassData> byNumber;

  /// 表名 → 65 项的地形加成
  final Map<String, List<int>> terrainAvoid;
  final Map<String, List<int>> terrainDefense;
  final Map<String, List<int>> terrainResistance;

  /// 表名 → 65 项的地形消耗（255 = 不可通行）
  final Map<String, List<int>> movCost;

  /// 从提取出的 JSON 构造。
  ///
  /// [classesJson] 来自 `parse_class_tables.py`，
  /// [terrainsJson] 来自 `parse_c_tables.py`（表本体在那里）。
  factory ClassTable.fromJson(
    Map<String, dynamic> classesJson,
    Map<String, dynamic> terrainsJson,
  ) {
    final terrTables = terrainsJson['tables'] as Map<String, dynamic>;

    List<int> table(String? name) {
      if (name == null) return List<int>.filled(65, 0);
      final t = terrTables[name] as Map<String, dynamic>?;
      if (t == null) return List<int>.filled(65, 0);
      return (t['values'] as List<dynamic>).map((e) => e as int).toList();
    }

    final byNumber = <int, ClassData>{};
    final avoid = <String, List<int>>{};
    final def = <String, List<int>>{};
    final res = <String, List<int>>{};
    final mov = <String, List<int>>{};

    for (final entry in (classesJson['classes'] as Map<String, dynamic>).entries) {
      final v = entry.value as Map<String, dynamic>;
      final num_ = v['number'] as int?;
      if (num_ == null) continue;

      final a = v['pTerrainAvoidLookup'] as String?;
      final d = v['pTerrainDefenseLookup'] as String?;
      final r = v['pTerrainResistanceLookup'] as String?;
      final m = (v['pMovCostTable'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList();

      for (final (name, cache) in [(a, avoid), (d, def), (r, res)]) {
        if (name != null && !cache.containsKey(name)) {
          cache[name] = table(name);
        }
      }
      if (m != null) {
        for (final name in m) {
          mov.putIfAbsent(name, () => table(name));
        }
      }

      byNumber[num_] = ClassData(
        key: entry.key,
        number: num_,
        terrainAvoidTable: a ?? '',
        terrainDefenseTable: d ?? '',
        terrainResistanceTable: r ?? '',
        movCostTables: m,
      );
    }

    return ClassTable._(
      byNumber: byNumber,
      terrainAvoid: avoid,
      terrainDefense: def,
      terrainResistance: res,
      movCost: mov,
    );
  }

  static ClassTable parse(String classesSource, String terrainsSource) =>
      ClassTable.fromJson(
        jsonDecode(classesSource) as Map<String, dynamic>,
        jsonDecode(terrainsSource) as Map<String, dynamic>,
      );

  ClassData? classOf(int number) => byNumber[number];

  /// `SetBattleUnitTerrainBonuses` 里那两行的语义：
  /// 按职业查表，取该地形上的回避 / 防御加成。
  ///
  /// 职业不存在或地形下标越界时返回 `(0, 0)` ——
  /// 与 C 里读到 0 的行为一致，不是"错误兜底"。
  (int avoid, int defense) terrainBonuses(int classNumber, int terrainId) {
    final c = byNumber[classNumber];
    if (c == null) return (0, 0);
    if (terrainId < 0 || terrainId >= 65) return (0, 0);

    final a = terrainAvoid[c.terrainAvoidTable];
    final d = terrainDefense[c.terrainDefenseTable];
    return (
      a != null ? a[terrainId] : 0,
      d != null ? d[terrainId] : 0,
    );
  }

  /// 该职业在指定天气下的移动消耗表，**已经是 u8 语义**（255 = 不可通行）。
  ///
  /// 返回 null 表示这个职业**没有**移动消耗表（石像鬼蛋、弩车），
  /// 不是"解析失败"—— 提取器已经把这两种情况区分开了。
  ///
  /// ## 为什么这里要做一次 s8 → u8 的转换
  ///
  /// ROM 里的表是 `const s8 (*pMovCostTable)[3]`，不可通行写作 **-1**；
  /// 而实际参与泛洪的是 `u8 gWorkingTerrainMoveCosts[]`，转换发生在
  /// `SetWorkingMoveCosts` 里：
  ///
  ///     void SetWorkingMoveCosts(const s8 mct[TERRAIN_COUNT]) {
  ///         for (i = 0; i < TERRAIN_COUNT; ++i)
  ///             gWorkingTerrainMoveCosts[i] = mct[i];   // -1 → 255
  ///     }
  ///
  /// 我们导出的 JSON 保留了 **s8 语义**（因为提取器是按 `s8` 表校验的，
  /// 改成正数会让"逐字节一致"的判据失效）。所以这一层负责转换，
  /// 与 C 的转换点一一对应。
  ///
  /// ⚠️ 漏掉这一步的症状是：`movement_range.dart` 的 `MovementCostTable`
  /// 用 `255` 判不可通行，拿到 `-1` 会把它当成**可通行且消耗为负**的地形，
  /// 于是单位能走进 TERRAIN_NONE。测试里专门钉住了这一条。
  List<int>? movementCosts(int classNumber, Weather weather) {
    final c = byNumber[classNumber];
    final names = c?.movCostTables;
    if (names == null || names.length < 3) return null;
    final raw = movCost[names[weather.tableIndex]];
    if (raw == null) return null;
    // s8 → u8，与 SetWorkingMoveCosts 一致
    return raw.map((v) => v & 0xFF).toList();
  }
}
