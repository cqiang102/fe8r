// PORT OF: src/SaveMenuWriteNewGame.c:30-51（难度 → isTutorial / isDifficult）
//          src/bmsave_080A98B4.c:20-34（`WriteNewGameSave` → `InitPlayConfig`）
//          src/InitPlayConfig.c:9-14（★ `CpuFill16(0, &gPlaySt, …)` 会把
//              `chapterStateBits` **清零**；`config.controller = unk` 就是 isTutorial）
//          src/eventscr_0800E2C8.c:75-110（`EVSUBCMD_CHECK_TUTORIAL` / `CHECK_HARD`）
//          src/GameControl_InitTutorialGame.c:24-37（唯一一个写 PLAY_FLAG_TUTORIAL 的地方）
//          src/bmguide_080D2C48.c:47-66（`IsGuideLocked`）
//          src/data/EventScr_Prologue_BeginningScene_ref/dat_EventScr_Prologue_BeginningScene_ref.c:26-31
//              （序章开场里那句 `ASMC(BmGuideTextSetAllGreen + 0x1)` 的条件）
//          include/types.h:171-226（`struct PlaySt`）、:239-252（`PLAY_FLAG_*`）
//          include/EAstdlib.h:38 + include/eventscript.h:611（`BNE` = `EvtBNE`）
//          src/Event0C_Branch.c:52-69（`BNE` 比的是 `gEventSlots[s1] != gEventSlots[s2]`）
//          src/exact_080860a8.c:168-175（`CheckFlag`：< 100 走章节旗）
//
// # 为什么需要这个文件
//
// 地图菜单里两条的可见性依赖于"这一局是不是教学模式"：
//
// * `中断` 的 `MapMenu_IsSuspendCommandAvailable`（`src/masked_0802257c.c:63`）
//   读 `gPlaySt.chapterStateBits & PLAY_FLAG_TUTORIAL`；
// * `辞書` 的 `MapMenu_IsGuideCommandAvailable`（`src/MapMenu_IsGuideCommandAvailable.c:53`）
//   读 `IsGuideLocked()`，而**整局只有一个地方**会解锁辞书表：
//   序章开场里那句 `ASMC(BmGuideTextSetAllGreen + 0x1)`。
//
// # 序章那句 ASMC 的条件（照字节推，不是照感觉）
//
// ```c
// // src/data/EventScr_Prologue_BeginningScene_ref/…c:26-31
// SVAL(EVT_SLOT_2, EventScr_Prologue_EirikaAttacked)
// CALL(EventScr_CallOnTutorialMode)
// CHECK_TUTORIAL
// BNE(0, 0xC, 0)                      // EvtBNE(label, s1, s2) ⇒ s1=0xC, s2=0
// ASMC(BmGuideTextSetAllGreen + 0x1)
// LABEL(0)
// ```
//
// * `CHECK_TUTORIAL`（`src/eventscr_0800E2C8.c:105-110`）：
//   `gEventSlots[0xC] = (config.controller || PLAY_FLAG_HARD) ? FALSE : TRUE`
//   —— 也就是说 **slot 0xC == 0 ⟺ 教学模式**。
// * `BNE`（`src/Event0C_Branch.c:65-69` + `src/Event0C_Branch.c:52-56`）比的是
//   `gEventSlots[0xC] != gEventSlots[0]`，而 **`EVT_SLOT_0` 是常量 0**
//   （全作只用它当"和 0 比"的右手边）。
// * 所以 `BNE` 成立 ⟺ `slot[0xC] != 0` ⟺ 非教学 → **跳过** ASMC。
//   ⇒ `BmGuideTextSetAllGreen()` 只在**教学模式**下执行。
// * `BmGuideTextSetAllGreen`（`src/bmguide_080D4158.c:46-56`）把
//   `gGuideTable` 每一条的 `displayFlag` 都 `SetFlag`；
//   于是 `IsGuideLocked()`（`src/bmguide_080D2C48.c:47-66`）在第一条就
//   `CheckFlag(displayFlag)` 命中 → 返回 FALSE → 辞书**可用**。
// * `CheckFlag(n<100)` 走章节旗（`src/exact_080860a8.c:168-175`），新游戏时全 0
//   ⇒ 没跑过那句 ASMC 的话整表全 0 ⇒ `IsGuideLocked()` 一直走到
//   `title == 12` 的哨兵 → 返回 TRUE → 辞书**不显示**。
//
// # 教学模式的判据
//
// `EVSUBCMD_CHECK_TUTORIAL` 用的是 `config.controller || PLAY_FLAG_HARD`，
// 而这两位的来源是**难度**（走标题的存档菜单进新游戏时）：
//
// ```c
// // src/SaveMenuWriteNewGame.c:35-51
// case 0: isTutorial = 0; isDifficult = 0; break;   // 新手
// case 1: isTutorial = 1; isDifficult = 0; break;   // 普通
// case 2: isTutorial = 1; isDifficult = 1; break;   // 困难
// WriteNewGameSave(proc->sus_slot, isDifficult, 1, isTutorial);
// // → src/bmsave_080A98B4.c:31  InitPlayConfig(isDifficult, isTutorial)
// // → src/InitPlayConfig.c:11-14  PLAY_FLAG_HARD |= isDifficult; config.controller = isTutorial;
// ```
//
// # `PLAY_FLAG_TUTORIAL` 与"教学模式"**不是同一个位**
//
// * 写 `PLAY_FLAG_TUTORIAL` 的地方**只有** `src/GameControl_InitTutorialGame.c:33`，
//   而全仓库（`grep -rn GameControl_InitTutorialGame .`）除了它自己的定义、
//   头文件声明、layout tsv 和文档之外**没有任何调用点** —— 调用它的那条
//   `PROC_CALL` 不在 carve 里。
// * 而新游戏走的这条链（`SaveMenuWriteNewGame` → `WriteNewGameSave` →
//   `InitPlayConfig`）里，`src/InitPlayConfig.c:9` 的
//   `CpuFill16(0, &gPlaySt, sizeof(gPlaySt))` 会把 `chapterStateBits` **清零**，
//   之后没有任何一处再置 `PLAY_FLAG_TUTORIAL`。
// * ⇒ 在本仓库复刻的"标题 → 存档菜单 → 难度 → 新游戏"这条链里，
//   `PLAY_FLAG_TUTORIAL == 0`，`中断` 是**可用的**。
//
// 这一条是**抽查过**（靠一处 `grep` 的否定结论 + 一处清零），不是机器验证 ——
// 如果哪天 carve 出了 `GameControl_InitTutorialGame` 的调用点，这个结论要重来。

/// `proc->difficulty`（`src/SaveMenuWriteNewGame.c:35-48` 就是按 0/1/2 分支的）
enum NewGameDifficulty {
  /// 新手（`isTutorial = 0; isDifficult = 0`）
  easy,

  /// 普通（`isTutorial = 1; isDifficult = 0`）
  normal,

  /// 困难（`isTutorial = 1; isDifficult = 1`）
  hard,
}

/// `gPlaySt.config`（`struct PlaySt_OptionBits`，`include/types.h:141-169`）
///
/// 这里只放**已经有行为影响**的那些位。现在只有一项 ——
/// 其余（文字速度、动画开关……）等「設定」屏真的做出来时再补，
/// 免得出现"存了个值但没人读"的假字段。
class PlayConfig {
  PlayConfig({this.disableAutoEndTurns = false});

  /// `config.disableAutoEndTurns`（`include/types.h:155`）
  ///
  /// 全作**只有一处**读它：`PlayerPhase_HandleAutoEnd`
  /// （`src/playerphase_0801D808.c:52-58`）：
  ///
  /// ```c
  /// if (!(gPlaySt.config.disableAutoEndTurns) && (GetPhaseAbleUnitCount(gPlaySt.faction) == 0))
  ///     Proc_Goto(proc, 3);
  /// ```
  ///
  /// ⇒ 它**只管我方阶段**。敌方 / 友军 NPC 阶段的结束与它无关：
  /// 那两个阶段跑的是 `gProcScr_CpPhase`（`src/data/data_085D1E10/data_085D1E10.c:20-25`
  /// = `AiPhaseInit; YIELD; AiPhaseCleanup; END`），AI 把单位跑完就
  /// `Proc_End`（`src/CpDecide_Main.c:78`）——**没有**读这个开关。
  ///
  /// 默认 0（开启自动结束）：`src/InitPlayConfig.c:24`。
  bool disableAutoEndTurns;

  // ---- ★ 其余配置字段（`struct PlaySt_OptionBits`，`include/types.h:141-169`）----
  //
  // 位宽照源码（`unitDisplayType:2` / `textSpeed:2` / `windowColor:2` /
  // `animationType:2` / `battleForecastType:2`，其余 1 位）。
  // **默认值未核对**（原作在 `src/InitPlayConfig.c`）⇒ 这里一律 0。
  int unitColor = 0; // :1
  int disableTerrainDisplay = 0; // :1
  int unitDisplayType = 0; // :2
  int autoCursor = 1; // :1  ← 我们的默认（原作的默认值未核对）
  int textSpeed = 0; // :2
  int gameSpeed = 0; // :1
  int disableBgm = 0; // :1
  int disableSoundEffects = 0; // :1
  int windowColor = 0; // :2
  int noSubtitleHelp = 0; // :1
  int disableGoalDisplay = 0; // :1
  int animationType = 0; // :2
  int battleForecastType = 0; // :2
  // ★ 第 87 轮补：`include/types.h:160-161` 里**确实有**这两位，
  //   而设定屏的表（`optionToConfigField`）已经把它们列了出来 ——
  //   少了它们，那两项在屏上改了也**静默不生效**（是判据抓出来的）。
  int controller = 0; // :1   （`src/uiconfig.c:132/238`）
  int rankDisplay = 0; // :1  （`src/uiconfig.c:137/243`）

  /// 按**源码字段名**读（设定屏的解出来的映射用的就是这些名字）
  int getField(String f) => switch (f) {
        'unitColor' => unitColor,
        'disableTerrainDisplay' => disableTerrainDisplay,
        'unitDisplayType' => unitDisplayType,
        'autoCursor' => autoCursor,
        'textSpeed' => textSpeed,
        'gameSpeed' => gameSpeed,
        'disableBgm' => disableBgm,
        'disableSoundEffects' => disableSoundEffects,
        'windowColor' => windowColor,
        'disableAutoEndTurns' => disableAutoEndTurns ? 1 : 0,
        'noSubtitleHelp' => noSubtitleHelp,
        'disableGoalDisplay' => disableGoalDisplay,
        'animationType' => animationType,
        'battleForecastType' => battleForecastType,
        'controller' => controller,
        'rankDisplay' => rankDisplay,
        _ => 0,
      };

  /// 按源码字段名写。**认不出的字段名返回 false**（不静默忽略）
  bool setField(String f, int v) {
    switch (f) {
      case 'unitColor':
        unitColor = v;
      case 'disableTerrainDisplay':
        disableTerrainDisplay = v;
      case 'unitDisplayType':
        unitDisplayType = v;
      case 'autoCursor':
        autoCursor = v;
      case 'textSpeed':
        textSpeed = v;
      case 'gameSpeed':
        gameSpeed = v;
      case 'disableBgm':
        disableBgm = v;
      case 'disableSoundEffects':
        disableSoundEffects = v;
      case 'windowColor':
        windowColor = v;
      case 'disableAutoEndTurns':
        disableAutoEndTurns = v == 1;
      case 'noSubtitleHelp':
        noSubtitleHelp = v;
      case 'disableGoalDisplay':
        disableGoalDisplay = v;
      case 'animationType':
        animationType = v;
      case 'battleForecastType':
        battleForecastType = v;
      case 'controller':
        controller = v;
      case 'rankDisplay':
        rankDisplay = v;
      default:
        return false;
    }
    return true;
  }
}

/// 新游戏那一刻写进 `gPlaySt` 的、与地图菜单可见性有关的那几位
class NewGamePlayFlags {
  const NewGamePlayFlags(this.difficulty);

  final NewGameDifficulty difficulty;

  /// `gPlaySt.config.controller`（`src/InitPlayConfig.c:14`）
  ///
  /// 它**就是** isTutorial —— 交叉验证：`src/masked_080a9658.c:29-45`
  /// ```c
  /// isTutorial = gPlaySt.config.controller;
  /// case CHAPTER_MODE_EIRIKA:
  ///     if (!isTutorial)       info.Eirk_mode_easy = true;
  ///     else if (difficult)    info.Eirk_mode_hard = true;
  ///     else                   info.Eirk_mode_norm = true;
  /// ```
  bool get configController => difficulty != NewGameDifficulty.easy;

  /// `PLAY_FLAG_HARD`（`src/InitPlayConfig.c:11`，只由 `isDifficult` 置）
  bool get playFlagHard => difficulty == NewGameDifficulty.hard;

  /// `PLAY_FLAG_TUTORIAL`（`include/types.h:243`）
  ///
  /// 见头注释：这条链里没有人置它。要是哪天接上了
  /// `GameControl_InitTutorialGame` 的调用点，这里要改成真的读那个位。
  bool get playFlagTutorial => false;

  /// `EVSUBCMD_CHECK_TUTORIAL` 的结论（`src/eventscr_0800E2C8.c:105-110`）
  bool get isTutorialMode => configController || playFlagHard;

  /// `IsGuideLocked()`（`src/bmguide_080D2C48.c:47-66`）的结论
  ///
  /// 非教学模式 → 序章那句 ASMC 被 `BNE` 跳过 → 表全 0 → 锁住 → 辞书不显示。
  bool get guideLocked => !isTutorialMode;
}
