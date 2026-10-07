// PORT OF: src/worldmap_screen2.c:16-28（`WMLoc_GetChapterId`）
//          src/WMLoc_GetNextLocId.c:10-33（`WMLoc_GetNextLocId`）
//          src/worldmap_path_080C1DE8.c:36-52（`GetPlayChapterId`：章节 → 节点）
//          include/worldmap.h:334-352（`struct GMapNodeData`）
//          include/worldmap.h:303-317（`GMapMovementPathData` / `GMapPathData`）
//          include/types.h:257-263（`CHAPTER_MODE_*`）
//          include/constants/chapters.h:101-104（`CHAPTER_IS_TOWER` / `CHAPTER_IS_RUINS`）
//          数据：tools/pipeline/out/tables/worldmap.json
//
// # 大地图的**规则层**（纯 Dart、可单测）
//
// 这一层只做"节点 ↔ 章节 ↔ 下一个目的地"的换算，**不碰画面**。
// 它对应的三个函数都很小，但它们是章间流程的判据：
//
// ```c
// // src/worldmap_screen2.c:16-28
// int WMLoc_GetChapterId(int idx) {
//     switch (gPlaySt.chapterModeIndex) {
//         case CHAPTER_MODE_EIRIKA: default: return idx[gWMNodeData].chapteridx_eirika;
//         case CHAPTER_MODE_EPHRAIM:          return idx[gWMNodeData].chapteridx_ephram;
//     }
// }
//
// // src/WMLoc_GetNextLocId.c:10-33
// int WMLoc_GetNextLocId(int idx) {
//     const struct GMapNodeData * node = &idx[gWMNodeData];
//     if (CheckFlag(node->unk_06)) unk_08 = node->unk_08 + 2;   // ★ 条件成立 → 用**后一对**
//     else                         unk_08 = node->unk_08;
//     switch (gPlaySt.chapterModeIndex) {
//         case CHAPTER_MODE_EIRIKA: default: return unk_08[0];
//         case CHAPTER_MODE_EPHRAIM:          return unk_08[1];
//     }
// }
// ```
//
import 'dart:convert';

// ⚠️ `unk_08` 是 **4 个 s8**：两对 `(Eirika, Ephraim)`。`unk_06` 那个旗子决定用哪一对；
// `-1` 表示没有下一个。把这两者搞混就会"走到不存在的节点"。

/// `CHAPTER_MODE_*`（`include/types.h:257-263`）
class ChapterMode {
  static const int common = 1;
  static const int eirika = 2;
  static const int ephraim = 3;
}

/// `struct GMapNodeData`（`include/worldmap.h:334-352`，每条 0x20 字节）
class WorldMapNode {
  const WorldMapNode({
    required this.placementFlag,
    required this.encounters,
    required this.iconPreClear,
    required this.iconPostClear,
    required this.chapterIdxEirika,
    required this.chapterIdxEphraim,
    required this.unk06,
    required this.unk08,
    required this.x,
    required this.y,
    required this.nameTextId,
    required this.shipTravelFlag,
    this.armorySym,
    this.vendorSym,
    this.secretShopSym,
  });

  /// `GMAP_NODE_PLACEMENT_*`（`include/worldmap.h:326-332`）
  final int placementFlag;

  /// `s8`：< 0 表示这个节点不会出遭遇战
  final int encounters;

  final int iconPreClear, iconPostClear;

  /// 章节号（`WMLoc_GetChapterId` 的返回值；0xFF = 没有章节）
  final int chapterIdxEirika, chapterIdxEphraim;

  /// `s16`：`WMLoc_GetNextLocId` 里那个 `CheckFlag` 的条件旗
  final int unk06;

  /// `s8[4]`：两对 `(Eirika, Ephraim)` 的下一个目的地
  final List<int> unk08;

  /// 世界图上的像素坐标
  final int x, y;

  /// 节点名（消息 id）
  final int nameTextId;

  final int shipTravelFlag;

  /// 商店指针的**原始符号**（`data_08AC2510 + off`）——
  /// 指向哪张商品表**未查证**，所以只留符号，不假装知道商品。
  final String? armorySym, vendorSym, secretShopSym;

  Map<String, Object?> toJson() => {
        'placementFlag': placementFlag,
        'encounters': encounters,
        'chapteridx_eirika': chapterIdxEirika,
        'chapteridx_ephram': chapterIdxEphraim,
        'unk_06': unk06,
        'unk_08': unk08,
        'x': x,
        'y': y,
        'nameTextId': nameTextId,
      };
}

/// `struct GMapMovementPathData`（`include/worldmap.h:303-308`）的一个关键帧
class PathKeyframe {
  const PathKeyframe(this.t, this.x, this.y);
  final int t, x, y;
}

/// 大地图的**全部数据 + 规则**（从 `worldmap.json` 读）
class WorldMapData {
  WorldMapData({required this.nodes, required this.paths});

  final List<WorldMapNode> nodes;

  /// `gWorldmapPath_<n>` → 关键帧
  final Map<String, List<PathKeyframe>> paths;

  static WorldMapData parse(String json) {
    final d = jsonDecode(json) as Map<String, dynamic>;
    final nodes = <WorldMapNode>[];
    for (final e in d['nodes'] as List<dynamic>) {
      final m = e as Map<String, dynamic>;
      nodes.add(WorldMapNode(
        placementFlag: m['placementFlag'] as int,
        encounters: m['encounters'] as int,
        iconPreClear: m['iconPreClear'] as int,
        iconPostClear: m['iconPostClear'] as int,
        chapterIdxEirika: m['chapteridx_eirika'] as int,
        chapterIdxEphraim: m['chapteridx_ephram'] as int,
        unk06: m['unk_06'] as int,
        unk08: (m['unk_08'] as List).cast<int>(),
        x: m['x'] as int,
        y: m['y'] as int,
        nameTextId: m['nameTextId'] as int,
        shipTravelFlag: m['shipTravelFlag'] as int,
        armorySym: m['armorySym'] as String?,
        vendorSym: m['vendorSym'] as String?,
        secretShopSym: m['secretShopSym'] as String?,
      ));
    }
    final paths = <String, List<PathKeyframe>>{};
    for (final e in (d['paths'] as Map).entries) {
      paths['${e.key}'] = [
        for (final p in (e.value as List<dynamic>))
          PathKeyframe(
              (p as Map<String, dynamic>)['t'] as int,
              p['x'] as int,
              p['y'] as int),
      ];
    }
    return WorldMapData(nodes: nodes, paths: paths);
  }

  int get nodeCount => nodes.length;
}

/// 大地图的**规则**（`WMLoc_*` / `GetPlayChapterId` 的移植）
class WorldMapRules {
  const WorldMapRules(this.map);
  final WorldMapData map;

  /// `WMLoc_GetChapterId`（`src/worldmap_screen2.c:16-28`）
  int chapterIdOf(int idx, {int mode = ChapterMode.eirika}) {
    final n = map.nodes[idx];
    // `switch` 没有 ephraim 之外的分支：其余（含 COMMON）都走 eirika 那列
    return mode == ChapterMode.ephraim
        ? n.chapterIdxEphraim
        : n.chapterIdxEirika;
  }

  /// `WMLoc_GetNextLocId`（`src/WMLoc_GetNextLocId.c:10-33`）
  ///
  /// `checkFlag` = `CheckFlag(node->unk_06)`（旗子置上就用**后一对**）。
  int nextLocIdOf(
    int idx, {
    int mode = ChapterMode.eirika,
    bool Function(int flag)? checkFlag,
  }) {
    final n = map.nodes[idx];
    final flagged = n.unk06 >= 0 && (checkFlag?.call(n.unk06) ?? false);
    final pair = flagged ? 2 : 0; // `unk_08 + 2` / `unk_08`
    final i = pair + (mode == ChapterMode.ephraim ? 1 : 0);
    return i < n.unk08.length ? n.unk08[i] : -1;
  }

  /// `GetPlayChapterId`（`src/worldmap_path_080C1DE8.c:36-52`）：章节 → 节点下标
  ///
  /// 塔/遗迹先折算到第一层（`CHAPTER_T_01` / `CHAPTER_R_01`）。
  /// 找不到返回 **-1**（原版也是 -1）。
  int nodeIndexOfChapter(int chapterId, {int mode = ChapterMode.eirika}) {
    var ch = chapterId;
    if (isTower(ch)) {
      ch = 0x24; // CHAPTER_T_01
    } else if (isRuins(ch)) {
      ch = 0x2E; // CHAPTER_R_01
    }
    for (var i = 0; i < map.nodes.length; i++) {
      if (chapterIdOf(i, mode: mode) == ch) return i;
    }
    return -1;
  }

  /// `CHAPTER_IS_TOWER(chapterId)`（`include/constants/chapters.h:101`）
  ///
  /// ⚠️ **C 里是无符号减法**：`(chapterId) - CHAPTER_T_02 < 9`，
  /// 而 `GetPlayChapterId(u32 chapterId)` 的形参是 `u32`。
  /// 照字面搬到 Dart（有符号）会出事：`0 - 0x25 = -37 < 9` **成立**
  /// ⇒ **把序章当成塔**、折算去 T01 那个节点。
  /// 我的测试就是被这个咬到的（`nodeIndexOfChapter(0x00)` 返回 26 而不是 0）。
  /// 等价写法：`0x25 <= id <= 0x2D`（T_02..T_0A）。
  static bool isTower(int id) => id >= 0x25 && id <= 0x2D;

  /// `CHAPTER_IS_RUINS(chapterId)`（`:102`）—— 同上，`0x2F <= id <= 0x37`
  static bool isRuins(int id) => id >= 0x2F && id <= 0x37;
}

/// 大地图的**运行时状态**（`gGMData` 里这一层的移植子集）
///
/// 出处：`include/worldmap.h:455-503`（`struct GMapData`）里的
/// `units[0].location`（部队所在节点）与 `nodes[i].state`（是否已通关）。
///
/// ⚠️ 只搬这一层需要的两位：**当前节点**与**已通关节点**。
/// 目标节点由 `WMLoc_GetNextLocId` 推出来（不是"节点表的下一个下标"）——
/// 这两者不同：节点 0 的下一个是 0（自身）或 1，取决于旗子。
///
/// 纯数据 + 纯函数，可 JSON 往返（`lib/core` 的硬要求：能存档）。
class WorldMapState {
  WorldMapState({this.node = 0, Set<int>? cleared})
      : cleared = cleared ?? <int>{};

  /// `gGMData.units[0].location`（0..28）
  int node;

  /// `GM_NODE_STATE_CLEARED` 的那些节点
  final Set<int> cleared;

  /// **展示用**：按当前旗子算出来的下一个节点（-1 = 没有）。
  ///
  /// 放这里是为了让表现层不必自己持有 `eventFlags`（规则仍由 `nextNode` 算）。
  int nextNodeId = -1;

  /// **展示用**：一句话说明（走不动时写原因）。由游戏层写，规则层不产生它。
  String note = '';

  /// 当前节点对应的章节（`WMLoc_GetChapterId`）
  int chapterId(WorldMapRules r, {int mode = ChapterMode.eirika}) =>
      r.chapterIdOf(node, mode: mode);

  /// 下一个目的地（`WMLoc_GetNextLocId`）；-1 = 没有
  int nextNode(
    WorldMapRules r,
    bool Function(int flag) checkFlag, {
    int mode = ChapterMode.eirika,
  }) =>
      r.nextLocIdOf(node, mode: mode, checkFlag: checkFlag);

  /// 走到下一个节点。返回**到达的节点**；`null` = 没有下一个（原地不动）。
  ///
  /// 到过的节点记进 `cleared`（对应原版 `WMLoc_...` 里那一位的用法：
  /// 已通关的节点在图上换图标/可再访）。
  int? travelToNext(
    WorldMapRules r,
    bool Function(int flag) checkFlag, {
    int mode = ChapterMode.eirika,
  }) {
    final n = nextNode(r, checkFlag, mode: mode);
    if (n < 0 || n >= r.map.nodeCount || n == node) return null;
    cleared.add(node);
    node = n;
    return n;
  }

  Map<String, Object?> toJson() => {
        'node': node,
        'cleared': cleared.toList()..sort(),
        'nextNodeId': nextNodeId,
      };

  static WorldMapState fromJson(Map<String, dynamic> j) => WorldMapState(
        node: j['node'] as int? ?? 0,
        cleared: ((j['cleared'] as List?) ?? const []).cast<int>().toSet(),
      )..nextNodeId = j['nextNodeId'] as int? ?? -1;
}
