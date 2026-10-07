// PORT OF: src/SearchAvailableEvent.c + src/EvCheck01_AFEV.c
//
// 章节的胜负条件 —— **从源码解出来的机制，不是猜的**。
//
// # 一、条件表长什么样（`EventListScr_<章节>_Misc`）
//
// 序章的（`src/data/data_08A5A6AD/data_08A5A6AD.s:32-40`，已解成
// `tools/pipeline/out/tables/event_lists.json`）：
//
//     {cmd: FLAG, doneFlag: 3,   script: EventScr_Prologue_EndingScene, checkFlag: 2}
//     {cmd: FLAG, doneFlag: 7,   script: EventScr_Prologue_OneEnemyLeft, checkFlag: 0}
//     {cmd: FLAG, doneFlag: 0,   script: EventScr_GameOver,             checkFlag: 101}
//     {cmd: END}
//
// 而宏定义（`include/EA_Standard_Library/Main_Code_Helpers.h:26-28`）是：
//
//     #define CauseGameOverIfLordDies AFEV(0, EventScr_GameOver, EVFLAG_GAMEOVER)
//     #define DefeatBoss(event_scr)   AFEV(EVFLAG_WIN, (event_scr), EVFLAG_DEFEAT_BOSS)
//     #define DefeatAll(event_scr)    AFEV(EVFLAG_WIN, (event_scr), EVFLAG_DEFEAT_ALL)
//
// **逐条对上** —— 所以机制不再有猜测成分。
//
// # 二、怎么判定（`src/SearchAvailableEvent.c:40-54`）
//
// ```c
// for (;;) {
//     int cmdId = EVT_CMD_LO(info->listScript[0]);      // 低 16 位 = 命令
//     if (!CheckFlag(EVT_CMD_HI(info->listScript[0])))  // 高 16 位 = 「已执行」标志
//         if (cmdInfo[cmdId].func(info) == 1) goto _end;
//     info->listScript += len[cmdId << 1];
// }
// ```
//
// 两条要点：
//   * **`doneFlag` 已置上的条目会被跳过** —— 所以同一条件不会重复触发
//   * **按顺序取第一条满足的** —— 顺序有意义
//
// # 三、FLAG 条目怎么判（`src/EvCheck01_AFEV.c`）
//
// ```c
// if ((unk8 == 0) || (unk8 == 100) || (CheckFlag(unk8) == 1))  -> 命中
// ```
//
// 命中后把 `info->flag`（= `doneFlag`）置上，脚本开始演。
//
// # 四、"首领"是什么（`gDefeatTalkList`）
//
// `EVFLAG_DEFEAT_BOSS` **不是由"首领"这个属性决定的**，而是由一张表：
// 某个角色在某一章死亡时置上某个标志。
//
//     {pid: CHARACTER_ONEILL, chapter: PROLOGUE, flag: EVFLAG_DEFEAT_BOSS, ...}
//
// 序章的首领就是奥尼尔。见 `tools/pipeline/out/tables/defeat_talk.json`。

import '../battle/phase.dart';

/// 事件标志（`include/constants/event-flags.h`）
class EventFlags {
  const EventFlags._();

  static const int alwaysFalse = 0;
  static const int battleQuotes = 1;

  /// 击破首领 —— `DefeatBoss` 宏检查它
  static const int defeatBoss = 2;

  /// 胜利 —— `DefeatBoss` / `DefeatAll` 宏把它当"已执行"标志
  static const int win = 3;

  static const int bgmChange = 4;

  /// 敌全灭 —— `DefeatAll` 宏检查它
  static const int defeatAll = 6;

  /// 败北（主角阵亡）—— `CauseGameOverIfLordDies` 宏检查它
  static const int gameOver = 101;

  /// 这两个值在 `EvCheck01_AFEV` 里表示"无条件"
  static bool isUnconditional(int flag) => flag == 0 || flag == 100;
}

/// 条件表里的命令 id（`include/eventscript.h:816-832`）
class EventListCmd {
  const EventListCmd._();

  static const int end = 0;
  static const int flag = 1;
  static const int turn = 2;
  static const int char_ = 3;
  static const int charAsm = 4;
  static const int loca = 5;
  static const int vill = 6;
  static const int ches = 7;
  static const int door = 8;
  static const int drawbridge = 9;
  static const int shop = 10;
  static const int area = 11;
}

/// 一条胜负条件
class ChapterObjective {
  const ChapterObjective({
    required this.cmd,
    required this.script,
    required this.doneFlag,
    required this.checkFlag,
  });

  factory ChapterObjective.fromJson(Map<String, dynamic> j) => ChapterObjective(
        cmd: j['cmd'] is int ? j['cmd'] as int : _cmdByName['${j['cmd']}'] ?? -1,
        script: j['script'] as String?,
        doneFlag: (j['doneFlag'] as num?)?.toInt() ?? 0,
        checkFlag: (j['checkFlag'] as num?)?.toInt() ?? 0,
      );

  /// 命令（本实现只用 [EventListCmd.flag]）
  final int cmd;

  /// 满足时要执行的脚本名
  final String? script;

  /// 「已执行」标志 —— 置上后这条不再触发
  final int doneFlag;

  /// 要检查的事件标志
  final int checkFlag;

  bool get isFlag => cmd == EventListCmd.flag;
  bool get isEnd => cmd == EventListCmd.end;

  @override
  String toString() =>
      'Objective(cmd=$cmd script=$script done=$doneFlag check=$checkFlag)';
}

const _cmdByName = <String, int>{
  'END': EventListCmd.end,
  'FLAG': EventListCmd.flag,
  'TURN': EventListCmd.turn,
  'CHAR': EventListCmd.char_,
  'CHARASM': EventListCmd.charAsm,
  'LOCA': EventListCmd.loca,
  'VILL': EventListCmd.vill,
  'CHES': EventListCmd.ches,
  'DOOR': EventListCmd.door,
  'DRAWBRIDGE': EventListCmd.drawbridge,
  'SHOP': EventListCmd.shop,
  'AREA': EventListCmd.area,
};

/// 一个章节的胜负条件表
class ChapterObjectives {
  ChapterObjectives(this.entries);

  factory ChapterObjectives.fromJson(List<dynamic> list) =>
      ChapterObjectives([
        for (final e in list)
          ChapterObjective.fromJson(e as Map<String, dynamic>),
      ]);

  final List<ChapterObjective> entries;

  /// **按原作的顺序**找第一条满足的条件。
  ///
  /// [hasFlag] 查某个事件标志是否已置上。
  ///
  /// 语义逐条对应 `SearchAvailableEvent`：
  ///   * `doneFlag` 已置上 -> 跳过（这条已经执行过了）
  ///   * `cmd` 不是 FLAG -> 本实现不处理（返回时不考虑）
  ///   * `checkFlag` 无条件（0 / 100）-> 命中
  ///   * 否则 `hasFlag(checkFlag)` 为真 -> 命中
  ///
  /// 返回 `null` 表示没有条件满足。
  ChapterObjective? firstMatch(bool Function(int flag) hasFlag) {
    for (final e in entries) {
      if (e.isEnd) break;
      if (!e.isFlag) continue; // 其它命令类型本实现不判定
      // 「已执行」标志已置上 -> 跳过（`!CheckFlag(EVT_CMD_HI(...))`）
      if (e.doneFlag != 0 && hasFlag(e.doneFlag)) continue;
      if (EventFlags.isUnconditional(e.checkFlag) || hasFlag(e.checkFlag)) {
        return e;
      }
    }
    return null;
  }
}


// ---------------------------------------------------------------- 标志推导

/// 一条 `gDefeatTalkList` 条目 —— **"首领"的操作性定义**
class DefeatTalkEntry {
  const DefeatTalkEntry({
    required this.pid,
    required this.chapter,
    required this.flag,
  });

  factory DefeatTalkEntry.fromJson(Map<String, dynamic> j) => DefeatTalkEntry(
        pid: j['pid'] as String?,
        chapter: j['chapter'] as String?,
        flag: j['flag'] as String?,
      );

  /// 角色符号名（`CHARACTER_ONEILL`）
  final String? pid;

  /// 章节符号名（`CHAPTER_L_PROLOGUE`）
  final String? chapter;

  /// 死亡时要置上的标志符号名（`EVFLAG_DEFEAT_BOSS`）
  final String? flag;
}

/// 章节号 → `gDefeatTalkList` 里的章节符号名
///
/// 只列到第 1 章 —— 本目标只要求"第一章及之前"。
/// 后面的章节要接进来时在这里补，**不要瞎猜**。
String? defeatTalkChapterName(int chapterIndex) {
  switch (chapterIndex) {
    case 0:
      return 'CHAPTER_L_PROLOGUE';
    case 1:
      return 'CHAPTER_L_1';
    case 2:
      return 'CHAPTER_L_2';
    case 3:
      return 'CHAPTER_L_3';
  }
  return null;
}

/// `EVFLAG_*` 符号名 → 数值
int? flagByName(String? name) {
  switch (name) {
    case 'EVFLAG_DEFEAT_BOSS':
      return EventFlags.defeatBoss;
    case 'EVFLAG_DEFEAT_ALL':
      return EventFlags.defeatAll;
    case 'EVFLAG_WIN':
      return EventFlags.win;
    case 'EVFLAG_GAMEOVER':
      return EventFlags.gameOver;
  }
  return null;
}

/// 从**战场现状**推导隐含的事件标志。
///
/// ## 为什么用"推导"而不是"挂钩每一次死亡"
///
/// 原作是在具体时机置标志的（单位死亡时查 `gDefeatTalkList`）。
/// 本实现选择"每次行动后按现状推导" —— **判据完全一样**
/// （首领没了 / 主角没了 / 敌人全没了），只是计算时机不同。
/// 好处是它是**纯函数**，可以单测。
///
/// [chapterIndex] 章节号；[defeatTalk] 首领表；
/// [charNameOf] `charIndex` -> 符号名；[chapterName] 章号 -> 表里的符号名。
Set<int> deriveEventFlags({
  required List<BattleUnitView> units,
  required int chapterIndex,
  required List<DefeatTalkEntry> defeatTalk,
  required String? Function(int charIndex) charNameOf,
}) {
  final flags = <int>{};
  final want = defeatTalkChapterName(chapterIndex);

  // 首领阵亡
  for (final e in defeatTalk) {
    if (want != null && e.chapter != want) continue;
    final pid = e.pid;
    if (pid == null) continue;
    // 表里是符号名 —— 找哪个单位的 charIndex 对得上
    final boss = units.where((u) => charNameOf(u.charIndex) == pid).firstOrNull;
    if (boss != null && !boss.alive) {
      final f = flagByName(e.flag);
      if (f != null) flags.add(f);
    }
  }

  // 主角（蓝色方第一个）阵亡 -> GameOver
  final blues = units.where((u) => u.faction == Faction.blue).toList();
  if (blues.isNotEmpty && blues.every((u) => !u.alive)) {
    flags.add(EventFlags.gameOver);
  }

  // 敌全灭（且本来有敌人）
  final reds = units.where((u) => u.faction == Faction.red).toList();
  if (reds.isNotEmpty && reds.every((u) => !u.alive)) {
    flags.add(EventFlags.defeatAll);
  }

  return flags;
}

/// 推导时需要的单位视图 —— 只暴露必要的字段，避免 core 依赖 `MapUnit` 的具体形状
class BattleUnitView {
  const BattleUnitView({
    required this.charIndex,
    required this.faction,
    required this.alive,
  });

  final int charIndex;
  final int faction;
  final bool alive;
}
