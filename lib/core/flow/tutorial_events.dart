// PORT OF: src/EnqueueTutEvent.c:24-38（`EnqueueTutEvent`）
//          src/eventinfo_0808618C.c:138-149（`RunTutorialEvent`）
//          include/eventinfo.h:30-36（`TUTORIAL_EVT_TYPE_*`）
//          src/RunPhaseSwitchEvents.c:29-59（阶段切换的第一个动作就是它）
//          src/eventscr_0800DC94.c:76-100（`Event0B_EnqueueCall` 事件命令）
//          src/data/EventListScr_Prologue_Tutorial_ref/dat_…_ref.c（序章 15 条教学脚本表）
//          include/types.h:223-225（`tutorial_exec_type` / `tutorial_counter`）
//
// # 为什么需要它
//
// 用户说「有时候阶段切换也会触发对话」。对——原作里**每一次阶段切换**，
// `RunPhaseSwitchEvents` 的**第一件事**就是：
//
// ```c
// // src/RunPhaseSwitchEvents.c:29-40
// ret = RunTutorialEvent(TUTORIAL_EVT_TYPE_PHASECHANGE);   // ★ 先教学
// info.listScript = GetChapterEventDataPointer(...)->turnBasedEvents;
// pInfo = SearchAvailableEvent(&info);                     // 再回合事件
// ```
//
// 而教学事件是**两段式**的（入队 → 触发），跟其它事件表都不一样：
//
// 1. 事件脚本里写
//    `EvtEnqueueConditionalTutCall(exec_type, scr)`
//    → `Event0B_EnqueueCall`（`src/eventscr_0800DC94.c:87-94`）→
//      `EnqueueTutEvent(scr, exec_type)`：在本章的 `tutorialEvents[]` 里**按指针查**
//      这个脚本的下标，记下 `tutorial_counter = i + 1`、`tutorial_exec_type = exec_type`。
// 2. 某个钩子（阶段切换 / 行动后 / 选中 / 移动后 / 换目标 / 玩家阶段开始）调
//    `RunTutorialEvent(type)`：只有当 `tutorial_exec_type == type` 时才把
//    `tutorialEvents[counter - 1]` 起成事件，然后把两位都清 0。
//
// 序章那条链是：`EventScr_Prologue_ExecTut` 入队 T0（type 2=ONSELECT）
// → T0…T2 入队 T3（1=POSTACTION）→ … → T8 入队 **T9（6=PLAYERPHASE）**
// → **下一个玩家阶段开始时演 T9**。整条链在我们这边原来全是
// `s.placeholder('EvtEnqueueConditionalTutCall')` —— 一句都没触发。

/// `TUTORIAL_EVT_TYPE_*`（`include/eventinfo.h:30-36`）
///
/// ⚠️ `phaseChange` 是 **0**，而"没有待触发教学"时 `tutorial_exec_type` 也是 **0**
/// （`RunTutorialEvent` 演完把它清 0）。原版就是这样 —— 判据不能靠
/// "type == 0 说明没有"，只能靠 `counter != 0`。
enum TutorialEvtType {
  /// `TUTORIAL_EVT_TYPE_PHASECHANGE = 0` —— 每次阶段切换都查
  phaseChange(0),

  /// `TUTORIAL_EVT_TYPE_POSTACTION = 1` —— 单位行动结算之后（`CheckForWaitEvents`）
  postAction(1),

  /// `TUTORIAL_EVT_TYPE_ONSELECT = 2`
  onSelect(2),

  /// `TUTORIAL_EVT_TYPE_DESTSELECTED = 3`
  destSelected(3),

  /// `TUTORIAL_EVT_TYPE_AFTERMOVE = 4`
  afterMove(4),

  /// `TUTORIAL_EVT_TYPE_FORECAST = 5`
  forecast(5),

  /// `TUTORIAL_EVT_TYPE_PLAYERPHASE = 6` —— 我方阶段开始时
  playerPhase(6);

  const TutorialEvtType(this.id);

  /// 源码里的数值
  final int id;

  static TutorialEvtType? fromId(int id) {
    for (final t in TutorialEvtType.values) {
      if (t.id == id) return t;
    }
    return null;
  }
}

/// `gPlaySt.tutorial_counter` / `gPlaySt.tutorial_exec_type`
/// （`include/types.h:223-225`，两个 u8）
///
/// 纯状态 + 纯函数，没有副作用 —— 起脚本那一步由游戏层做。
class TutorialQueue {
  TutorialQueue({this.counter = 0, this.execType = 0});

  /// `tutorial_counter`：**下标 + 1**（0 = 没有待触发的）
  int counter;

  /// `tutorial_exec_type`
  int execType;

  bool get hasPending => counter != 0;

  /// `EnqueueTutEvent(ptr, type)`（`src/EnqueueTutEvent.c:24-38`）
  ///
  /// 原版是**按指针在本章的 `tutorialEvents[]` 里查**，查不到就什么也不做。
  /// 所以这里也必须拿到那张表 —— 不能"反正入队就完了"，
  /// 否则会演出原版根本不会演的脚本。
  ///
  /// 返回是否入队成功（查不到 → false）。
  bool enqueue(
    String script,
    int type,
    List<String> chapterTutorialEvents,
  ) {
    final i = chapterTutorialEvents.indexOf(script);
    if (i < 0) return false;
    counter = i + 1;
    execType = type;
    return true;
  }

  /// `RunTutorialEvent(type)`（`src/eventinfo_0808618C.c:138-149`）
  ///
  /// 返回**要演的脚本名**；`null` = 这条钩子没有待触发的教学。
  ///
  /// ⚠️ 命中的时候原版会把两位都清 0 —— 也就是**只演一次**。
  String? take(int type, List<String> chapterTutorialEvents) {
    if (counter == 0 || execType != type) return null;
    final i = counter - 1;
    // 复位与命中无关：原版是先 CallEvent 再清，但清是必然发生的
    final saved = counter;
    counter = 0;
    execType = 0;
    if (i < 0 || i >= chapterTutorialEvents.length) {
      return '?越界教程下标 $saved（表里只有 ${chapterTutorialEvents.length} 条）';
    }
    return chapterTutorialEvents[i];
  }

  Map<String, Object?> toJson() => {
        'counter': counter,
        'execType': execType,
        'pending': hasPending,
      };
}
