// 开场流程状态机 —— 从开机到「能玩」。
//
// ## 出处：`src/gamecontrol_08009E68.c:36`（`gProcScr_GameControl`）
//
// ```
// LGAMECTRL_GAME_INTRO_UI  → ProcScr_GameEarlyStartUI   ① 开机动画 + Press Start
// LGAMECTRL_OP_ANIM        → ProcScr_OpAnim             ② 开场动画
// LGAMECTRL_CLASS_REEL     → GamceControl_StartClassReel ③ 职业介绍
// LGAMECTRL_TITLE_DIRECT   → StartTitleScreen_WithMusic ④ 标题画面
// LGAMECTRL_EXEC_SAVEMENU  → StartSaveMenu              ⑤ 主菜单
// LGAMECTRL_EXEC_BM        → GameCtrl_CheckNewGameAndBranch ⑥ 序章
// ```
//
// ## ① 的三个画面（`include/opanim.h:631-646`）
//
//     GameIntroPrepareNintendofx → GameIntroNintendoFadeIN / FadeOUT
//     GameIntroIntelligentSystemsFadeIN / FadeOUT
//     GameIntroHealthSafetyFadeIN → **HealthSafetyWaitButton** → FadeOUT
//
// 每个淡入淡出 **30 帧**（`src/GameIntroNintendoFadeOUT.c:17`：`0x1E`），
// 之后停 **40 帧**（`:22`：`0x30 = 0x28`）。
// `HealthSafetyWaitButton` 里启动的子进程就是等按键的那个。
//
// ## ④ 的 815 帧超时（`src/titlescreen_080CB2A0.c:33-52`）
//
//     if (newKeys & (A_BUTTON | START_BUTTON)) → GAME_ACTION_EVENT_RETURN（主菜单）
//     else if (timer_idle == 815)              → GAME_ACTION_CLASS_REEL（职业介绍）
//
// ## 文字用的是**真实消息表**
//
// `texts.json` 253/254/266/267 = 「聖魔の光石」、1749 = 「スタートを押すと始まります」。
//
// ## ⚠️ 画面图形还是占位
//
// 标题/logo 的素材在 `graphics/frontier_df3_titlescreen/`，
// 是 **8px 宽的灰度图块条**（`L` 模式），和立绘一样需要按 TSA 合成。
// 那是独立的一块工作（参照 `parse_portraits.py` 的做法）。
//
// **流程逻辑是真的，画面是占位的** —— 这样下一步接图形时只改渲染，不改流程。

import 'package:fe8r/core/core.dart';

/// 开场流程的每一个画面
enum TitleScreen {
  /// ①-a Nintendo 淡入淡出
  nintendo,

  /// ①-b Intelligent Systems 淡入淡出
  intelligentSystems,

  /// ①-c 健康警告 + **「Press Start」**
  healthSafety,

  /// ④ 标题画面（有开场动画；等按键或 815 帧超时）
  title,

  /// ③ 职业介绍（不按键时自动播）
  classReel,

  /// ⑤ 主菜单：开始新的游戏 / 附加内容
  mainMenu,

  /// ⑤-b 难度：新手 / 普通 / 困难
  difficulty,

  /// ⑤-c 存档槽：新建存档
  saveSlot,
}

/// 主菜单的选项（`src/StartSaveMenu.c:35-36` 的 `main_sel_bitfile`）
enum MainMenuItem { newGame, extras }

/// 难度（`SaveMenu_PostDifficultHandler.c:32-36`：`difficulty == 3` 走单独分支）
enum Difficulty {
  /// 新手（说明文案见消息 2100 一类）
  easy,

  /// 普通
  normal,

  /// 困难
  hard,
}

/// 每个画面的停留帧数（60fps）
class TitleTimings {
  const TitleTimings._();

  /// 淡入或淡出 **30 帧**（`src/GameIntroNintendoFadeOUT.c:17` `0x1E`）
  static const int fadeFrames = 30;

  /// 淡完停 **40 帧**（`:22` `proc->timer = 0x28`）
  static const int holdFrames = 40;

  /// 标题画面等 **815 帧**就播职业介绍
  /// （`src/titlescreen_080CB2A0.c:46` `timer_idle == 815`）
  static const int classReelTimeout = 815;
}

/// 开场流程
///
/// **纯 Dart、可单测** —— 不碰 Flame。渲染由 `TitleView` 负责。
class TitleFlow {
  TitleFlow({required this.texts, this.startAt = TitleScreen.nintendo});

  final GameTexts texts;
  TitleScreen startAt;

  TitleScreen screen = TitleScreen.nintendo;

  /// 在这个画面上待了多少帧（对应原作的 `timer_idle`）
  int framesOnScreen = 0;

  /// 当前选中项
  MainMenuItem mainItem = MainMenuItem.newGame;
  Difficulty difficulty = Difficulty.normal;
  int saveSlot = -1;

  /// 选好的存档（`-1` 表示还没选）
  bool get hasSave => saveSlot >= 0;

  /// 「聖魔の光石」—— 消息 253（`texts.json`）
  String get gameTitle => texts.byId(253)?.plain.trim() ?? '聖魔の光石';

  /// 「スタートを押すと始まります」—— 消息 1749
  String get pressStart => texts.byId(1749)?.plain.trim() ?? 'スタートを押すと始まります';

  void reset() {
    screen = startAt;
    framesOnScreen = 0;
  }

  /// 每帧推进。[confirm]/[cancel]/[up]/[down] 来自输入层。
  ///
  /// 返回 `true` 表示"可以进游戏了"。
  bool tick({
    required bool confirm,
    required bool cancel,
    required bool up,
    required bool down,
  }) {
    framesOnScreen++;

    switch (screen) {
      // ---- ① Nintendo / Intelligent Systems：纯过场，只按时间推进 ----
      case TitleScreen.nintendo:
      case TitleScreen.intelligentSystems:
        if (_passed(TitleTimings.fadeFrames * 2 + TitleTimings.holdFrames)) {
          _goto(screen == TitleScreen.nintendo
              ? TitleScreen.intelligentSystems
              : TitleScreen.healthSafety);
        }

      // ---- ①-c 健康警告：**等按键** ----
      //
      // `GameIntroHealthSafetyWaitButton` 启动的子进程就是等这个的。
      // 原作这里没有超时（不给按键就一直等）—— 所以我也不加超时。
      case TitleScreen.healthSafety:
        if (confirm || cancel) {
          _goto(TitleScreen.title);
        }

      // ---- ④ 标题：按键 → 主菜单；815 帧 → 职业介绍 ----
      //
      // `src/titlescreen_080CB2A0.c:38-50`
      case TitleScreen.title:
        if (confirm || cancel) {
          _goto(TitleScreen.mainMenu);
        } else if (framesOnScreen == TitleTimings.classReelTimeout) {
          _goto(TitleScreen.classReel);
        }

      // ---- ③ 职业介绍：看完（或按键跳过）回标题 ----
      case TitleScreen.classReel:
        if (confirm || cancel || framesOnScreen > 600) {
          _goto(TitleScreen.title);
        }

      // ---- ⑤ 主菜单 ----
      case TitleScreen.mainMenu:
        if (up || down) {
          mainItem = mainItem == MainMenuItem.newGame
              ? MainMenuItem.extras
              : MainMenuItem.newGame;
        }
        if (confirm) {
          if (mainItem == MainMenuItem.extras) {
            // 附加内容本实现不做 —— 留在原地而不是静默跳走
            return false;
          }
          _goto(TitleScreen.difficulty);
        }
        if (cancel) _goto(TitleScreen.title);

      // ---- ⑤-b 难度 ----
      case TitleScreen.difficulty:
        if (up && difficulty.index > 0) {
          difficulty = Difficulty.values[difficulty.index - 1];
        }
        if (down && difficulty.index < Difficulty.values.length - 1) {
          difficulty = Difficulty.values[difficulty.index + 1];
        }
        if (confirm) _goto(TitleScreen.saveSlot);
        if (cancel) _goto(TitleScreen.mainMenu);

      // ---- ⑤-c 存档槽 ----
      case TitleScreen.saveSlot:
        if (up && saveSlot > 0) saveSlot--;
        if (down && saveSlot < 2) saveSlot++;
        if (confirm) {
          if (saveSlot < 0) saveSlot = 0; // 没选过就给第一个
          return true; // ← 可以进游戏了
        }
        if (cancel) _goto(TitleScreen.difficulty);
    }
    return false;
  }

  bool _passed(int n) => framesOnScreen >= n;

  void _goto(TitleScreen s) {
    screen = s;
    framesOnScreen = 0;
    if (s == TitleScreen.saveSlot && saveSlot < 0) saveSlot = -1;
  }
}
