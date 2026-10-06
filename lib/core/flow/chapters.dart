// PORT OF: src/data/chapterdata.c（gChapterDataTable）的加载
//          数据由 tools/pipeline/extract/parse_chapters.py 提取
//
// 章节配置表（`gChapterDataTable`，79 章）的加载。
//
// ## 这是「章节 → 单位表 / 事件表」链路的第一段
//
//     chapterIndex
//       → **gChapterDataTable[i]**          ← 本文件
//       → .mapEventDataId
//       → gChapterDataAssetTable[id]        （指针表，未提取）
//       → struct ChapterEventGroup          （未提取）
//           ├── playerUnitsInNormal/Hard    ← 我方单位配置表
//           ├── enemyUnitsChoice1..3InEncounter ← 敌方单位配置表
//           └── beginningSceneEvents 等     ← 剧情脚本表
//
// 数据源 `src/data/chapter_settings.h` 是**完全可读的 C**
// （79 × `struct ROMChapterData`，字段全部具名），
// 所以这一段不需要重定位信息 —— 它是整条链路里唯一"现成"的一段。
//
// 后两段全是指针，必须读重定位信息才能解析（见 `unit_defs.dart` 里的说明）。

import 'dart:convert';

/// 一章的配置。
class ChapterData {
  const ChapterData({
    required this.index,
    required this.internalName,
    required this.obj1Id,
    required this.obj2Id,
    required this.paletteId,
    required this.tileConfigId,
    required this.mainLayerId,
    required this.changeLayerId,
    required this.initialFogLevel,
    required this.hasPrepScreen,
    required this.initialPosX,
    required this.initialPosY,
    required this.initialWeather,
    required this.battleTileSet,
    required this.mapEventDataId,
    required this.gmapEventId,
  });

  /// 章节序号（0 基）
  final int index;

  /// 内部名，如 `L00` / `I05`（**不是**给玩家看的章节标题）
  final String internalName;

  // ---- 地图资源 id（都要经 gChapterDataAssetTable 解析）----
  final int obj1Id;
  final int obj2Id;
  final int paletteId;
  final int tileConfigId;
  final int mainLayerId;
  final int changeLayerId;

  final int initialFogLevel;
  final bool hasPrepScreen;

  /// 开场镜头位置
  final int initialPosX;
  final int initialPosY;

  final int initialWeather;
  final int battleTileSet;

  /// **事件组索引** —— 整条链路的下一跳
  final int mapEventDataId;

  final int gmapEventId;

  static ChapterData fromJson(Map<String, dynamic> j) => ChapterData(
        index: j['index'] as int,
        internalName: j['internalName'] as String,
        obj1Id: j['obj1Id'] as int,
        obj2Id: j['obj2Id'] as int,
        paletteId: j['paletteId'] as int,
        tileConfigId: j['tileConfigId'] as int,
        mainLayerId: j['mainLayerId'] as int,
        changeLayerId: j['changeLayerId'] as int,
        initialFogLevel: j['initialFogLevel'] as int,
        hasPrepScreen: j['hasPrepScreen'] == 1,
        initialPosX: j['initialPosX'] as int,
        initialPosY: j['initialPosY'] as int,
        initialWeather: j['initialWeather'] as int,
        battleTileSet: j['battleTileSet'] as int,
        mapEventDataId: j['mapEventDataId'] as int,
        gmapEventId: j['gmapEventId'] as int,
      );

  @override
  String toString() => 'ChapterData[$index] $internalName '
      '事件组=$mapEventDataId 起始($initialPosX,$initialPosY)';
}

/// 全部章节
class Chapters {
  Chapters(this.list);

  final List<ChapterData> list;

  static Chapters parse(String json) {
    final d = jsonDecode(json) as Map<String, dynamic>;
    return Chapters((d['chapters'] as List<dynamic>)
        .map((e) => ChapterData.fromJson(e as Map<String, dynamic>))
        .toList());
  }

  ChapterData? byName(String name) {
    for (final c in list) {
      if (c.internalName == name) return c;
    }
    return null;
  }

  /// 用到的 `mapEventDataId` 集合 —— 下一步要按它去查 `ChapterEventGroup`
  Set<int> get eventGroupIds =>
      list.map((c) => c.mapEventDataId).toSet();
}
