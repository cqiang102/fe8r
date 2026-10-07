// PORT OF: src/code_8086934.c（`GetBattleQuoteEntry` / `GetDefeatTalkEntry`）
//          src/CallBattleQuoteEventsIfAny.c（`ShouldCallBattleQuote` / 三连查）
//          src/eventinfo_080858A8.c（`CheckBattleDefeatTalk` / `DisplayDefeatTalkForPid`）
//
// # 两张表
//
// * **战斗对话** `gBattleTalkList`（`BattleTalkExtEnt`）：开打前"谁对谁说什么"。
// * **阵亡对话** `gDefeatTalkList`（`DefeatTalkEnt`）：单位阵亡时的遗言。
//
// 数据是**日版**（carve 在 `src/data/frontier_df4_menu/frontier_df4_menu.c:1455`
// 的裸 u32 数组里；见 `tools/pipeline/extract/parse_talks.py` 的说明）。
//
// # 战斗对话的匹配规则（`src/code_8086934.c:17-65`）
//
// 按表序、先到先得：
//   1. `chapter` 必须 `0xFF`（任意）或 == 当前章；否则**只有**
//      `chapter == 0xFE` 且正在三角攻击时才放行。
//   2. `flag` 已置上 → 跳过（`GetEventTriggerState`）。
//   3. 匹配：
//      * `pidA != 0 && pidB == 0` → 只比 `pidA`（"某人对任何人"）
//      * `pidA == 0 && pidB != 0` → 只比 `pidB`
//      * 两者都 0 → 永不命中
//      * 都非 0 → `(pidA,pidB)` 相等**或交换**都算
//   4. 都不中 → null。
//
// 而 `ShouldCallBattleQuote` / `CallBattleQuoteEventsIfAny` 是**三连查**：
//
//     (pidA, pidB) → (pidA, 0) → (0, pidB)
//
// —— 这个顺序必须两处一致，否则会出现"判定说要演、演的时候查不到"。
//
// # 阵亡对话的匹配规则（`src/code_8086934.c:68-92`）
//
// ① `route` 必须 `0xFF` 或 == `chapterModeIndex`；
// ② `chapter` 必须 `0xFF` 或 == 当前章；
// ③ `flag` 已置 → 跳过；④ `pid` 精确相等；⑤ 表序第一条。
// **没有"主角死了不说话"这类分支**（`SetPidDefeatedFlag` 的特例只影响
// 是否置 `EVFLAG_GAMEOVER`，与台词无关 —— `src/eventinfo_080858A8.c:143-152`）。

import 'dart:convert';

/// 章节字段的通配值
const int chapterAny = 0xFF;

/// 三角攻击专用章节值（`chapter == 0xFE` 的条目只在三角攻击时放行）
const int chapterTriangleAttack = 0xFE;

/// `CHAPTER_MODE_ANY`（`include/types.h:262`）
const int chapterModeAny = 0xFF;

/// 一条战斗对话（`struct BattleTalkExtEnt`，16 字节）
class BattleTalkEntry {
  const BattleTalkEntry({
    required this.pidA,
    required this.pidB,
    required this.chapter,
    required this.flag,
    required this.msg,
    this.event = 0,
  });

  final int pidA;
  final int pidB;
  final int chapter;
  final int flag;
  final int msg;

  /// 可选脚本指针（日版表里全为 0）
  final int event;

  factory BattleTalkEntry.fromJson(Map<String, dynamic> j) => BattleTalkEntry(
        pidA: (j['pidA'] as num).toInt(),
        pidB: (j['pidB'] as num).toInt(),
        chapter: (j['chapter'] as num).toInt(),
        flag: (j['flag'] as num).toInt(),
        msg: (j['msg'] as num).toInt(),
        event: (j['event'] as num?)?.toInt() ?? 0,
      );

  @override
  String toString() =>
      'BattleTalk(pidA=$pidA pidB=$pidB ch=$chapter flag=$flag msg=${msg.toRadixString(16)})';
}

/// 一条阵亡对话（`struct DefeatTalkEnt`，12 字节）
class DefeatTalkEntry {
  const DefeatTalkEntry({
    required this.pid,
    required this.route,
    required this.chapter,
    required this.flag,
    required this.msg,
    this.event = 0,
  });

  final int pid;

  /// 路线（`CHAPTER_MODE_*`；`0xFF` = 任意）
  final int route;
  final int chapter;

  /// 命中时置上的事件标志（序章首领 = `EVFLAG_DEFEAT_BOSS`）
  final int flag;
  final int msg;
  final int event;

  factory DefeatTalkEntry.fromJson(Map<String, dynamic> j) => DefeatTalkEntry(
        pid: (j['pid'] as num).toInt(),
        route: (j['route'] as num).toInt(),
        chapter: (j['chapter'] as num).toInt(),
        flag: (j['flag'] as num).toInt(),
        msg: (j['msg'] as num).toInt(),
        event: (j['event'] as num?)?.toInt() ?? 0,
      );

  @override
  String toString() =>
      'DefeatTalk(pid=$pid route=$route ch=$chapter flag=$flag msg=${msg.toRadixString(16)})';
}

/// 两张对话表 + 两个查表函数（纯函数，可测试、可存档）
class TalkTables {
  TalkTables({required this.battleTalks, required this.defeatTalks});

  final List<BattleTalkEntry> battleTalks;
  final List<DefeatTalkEntry> defeatTalks;

  factory TalkTables.parse(String battleJson, String defeatJson) {
    final b = _entries(battleJson);
    final d = _entries(defeatJson);
    return TalkTables(
      battleTalks: [
        for (final e in b) BattleTalkEntry.fromJson(e),
      ],
      defeatTalks: [
        for (final e in d) DefeatTalkEntry.fromJson(e),
      ],
    );
  }

  static List<Map<String, dynamic>> _entries(String json) {
    final d = jsonDecode(json) as Map<String, dynamic>;
    return [
      for (final e in (d['entries'] as List<dynamic>))
        e as Map<String, dynamic>,
    ];
  }

  /// `GetBattleQuoteEntry(pidA, pidB)`（`src/code_8086934.c:17-65`）
  BattleTalkEntry? battleQuote({
    required int pidA,
    required int pidB,
    required int chapterIndex,
    bool triangleAttack = false,
    required bool Function(int flag) flagSet,
  }) {
    for (final it in battleTalks) {
      // ① 章节
      if (it.chapter != chapterAny && it.chapter != chapterIndex) {
        if (it.chapter != chapterTriangleAttack || !triangleAttack) continue;
      }
      // ② flag
      if (flagSet(it.flag)) continue;
      // ③ 匹配
      if (it.pidA != 0) {
        if (it.pidB == 0) {
          if (pidA == it.pidA) return it;
          continue;
        }
      } else {
        if (it.pidB == 0) continue;
        if (pidB == it.pidB) return it;
        continue;
      }
      if (pidA == it.pidA && pidB == it.pidB) return it;
      if (pidB == it.pidA && pidA == it.pidB) return it;
    }
    return null;
  }

  /// `ShouldCallBattleQuote` / `CallBattleQuoteEventsIfAny` 的**三连查**
  ///
  /// 出处：`src/eventinfo_080857A0.c:164-186` 与
  /// `src/CallBattleQuoteEventsIfAny.c:31-33` —— 两处顺序必须一致。
  BattleTalkEntry? lookupBattleQuote({
    required int pidA,
    required int pidB,
    required int chapterIndex,
    bool triangleAttack = false,
    required bool Function(int flag) flagSet,
  }) =>
      battleQuote(
        pidA: pidA,
        pidB: pidB,
        chapterIndex: chapterIndex,
        triangleAttack: triangleAttack,
        flagSet: flagSet,
      ) ??
      battleQuote(
        pidA: pidA,
        pidB: 0,
        chapterIndex: chapterIndex,
        triangleAttack: triangleAttack,
        flagSet: flagSet,
      ) ??
      battleQuote(
        pidA: 0,
        pidB: pidB,
        chapterIndex: chapterIndex,
        triangleAttack: triangleAttack,
        flagSet: flagSet,
      );

  /// `GetDefeatTalkEntry(pid)`（`src/code_8086934.c:68-92`）
  DefeatTalkEntry? defeatTalk({
    required int pid,
    required int chapterIndex,
    int chapterMode = chapterModeAny,
    required bool Function(int flag) flagSet,
  }) {
    for (final it in defeatTalks) {
      if (it.route != chapterModeAny && it.route != chapterMode) continue;
      if (it.chapter != chapterAny && it.chapter != chapterIndex) continue;
      if (flagSet(it.flag)) continue;
      if (pid != it.pid) continue;
      return it;
    }
    return null;
  }
}
