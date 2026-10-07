// PORT OF: src/MapMenu_IsRecordsCommandAvailable.c:51-56
//          src/bmmenu_08024C7C.c:61-67
//          src/ShouldCallEndEvent.c:25-31
//          src/eventinfo.c:64-77
//          src/CheckForWaitEvents.c:26-45
//          include/types.h:366-371（`BATTLEMAP_KIND_*`）
//          include/constants/chapters.h（章节号）
//
// # `GetBattleMapKind()` —— **函数体没有 carve**
//
// 这是一个**明确记录为未查证**的移植。
//
// * 日版地址：`0x080C1E74`（`layout/baseline_syms.tsv:424`，TU = eventinfo）。
// * `layout/carved_rom.d/perm2_GetBattleMapKind.tsv` 说这一片是
//   `perm2: no-funcmap region-diff -> matching C`；`layout/nofuncmap_region_different.tsv:2025`
//   说美版对应物 `0x080BD068` 是 **418 字节**、日版是 **420 字节** ——
//   **两版不同**。所以美版 `src/worldmap_path.c:1916-2005` 只能当交叉验证，
//   **不能当日版真值**。
// * 我搜遍了 `third_party/fireemblem8j`：除了上面的 layout/reference tsv 和调用点，
//   没有 `GetBattleMapKind` 的定义体。**日版本体读不到。**
//
// ## 能确定的、能引用的部分
//
// 1. 它是一个**以 `chapterIndex` 为被控量的 `switch`**：`reference/maps/febuilder_rom_us_jp.tsv:148-149`
//    给日版 `GetBattleMapKind+0x8`（`map_load_function_switch1_address` = `0x080C1E7C`）
//    和 `+0x1C`（`map_load_function_pointer` = `0x080C1E90`）—— 函数开头 0x20 字节内
//    就有跳转表，形状与美版一致。
// 2. `BATTLEMAP_KIND_STORY = 0` / `DUNGEON = 1` / `SKIRMISH = 2`（`include/types.h:368-370`）。
// 3. **序章与第 1 章不可能是 `SKIRMISH`**，否则游戏走不下去：
//    `ShouldCallEndEvent()`（`src/ShouldCallEndEvent.c:26-30`）
//    `if (GetBattleMapKind() == BATTLEMAP_KIND_SKIRMISH) return 0;`，
//    而 `CallEndEvent()`（`src/eventinfo.c:64-77`）正是靠它才会去演
//    `evGroup->endingSceneEvents`；第 1 章的结束剧情里有 `MNCH(0x38)`
//    （→ C00 フレリア城），这一跳没演的话第 1 章无法结束。
//    `SKIRMISH` 之外只剩 `STORY`（`DUNGEON` 要求章节落在世界地图上
//    `placementFlag == GMAP_NODE_PLACEMENT_DUNGEON` 的节点上，序章/第 1 章不在地图上）。
//
// 所以本文件只覆盖**我们已经能进入的章节**，值一律 `story`；
// 其它章节返回 `null` —— **不兜底、不猜**，由调用方响亮记录（见 `Fe8Game._openMapMenu`）。

/// `BATTLEMAP_KIND_*`（`include/types.h:368-370`）
///
/// ⚠️ 顺序是 **STORY(0) / DUNGEON(1) / SKIRMISH(2)**，不是"故事/遭遇/塔"。
enum BattleMapKind {
  /// `BATTLEMAP_KIND_STORY = 0`
  story,

  /// `BATTLEMAP_KIND_DUNGEON = 1`
  dungeon,

  /// `BATTLEMAP_KIND_SKIRMISH = 2`
  skirmish,
}

/// 已经确定 `GetBattleMapKind()` 的章节。
///
/// 判据不是"美版这么写"，而是**上面那段 `ShouldCallEndEvent` 的推理**：
/// 这两个章节的结束剧情必须能演（第 1 章的 `endingSceneEvents` 里是 `MNCH(0x38)`），
/// 而 `SKIRMISH` 会把结束剧情整个跳过。
///
/// `0x38` = `CHAPTER_CASTLE_FRELIA`（`include/constants/chapters.h:66`）——
/// 第 1 章结束剧情里的 `MNCH(0x38)` 目标，也是本仓库要做的 C00 章。
///
/// 状态：**抽查过**（有源码出处的推理），不是机器验证。
const Map<int, String> battleMapKindVerifiedChapters = {
  0x00: 'CHAPTER_L_PROLOGUE', // include/constants/chapters.h:5
  0x01: 'CHAPTER_L_1', // include/constants/chapters.h:6
  0x38: 'CHAPTER_CASTLE_FRELIA', // include/constants/chapters.h:66
};

/// `GetBattleMapKind()`。**查不到就返回 `null`**（绝不兜底）
///
/// 调用方拿到 `null` 时必须显式记录（`Fe8Game._mapMenuNote`），
/// 不许假装它是 `story`。见 `test/core/battle_map_kind_test.dart`。
BattleMapKind? battleMapKindOf(int chapterIndex) {
  final name = battleMapKindVerifiedChapters[chapterIndex];
  if (name == null) return null;
  // 三个章节都是 STORY；将来接入塔/遗迹/遭遇战时要按各自的 carve 结论补
  return BattleMapKind.story;
}
