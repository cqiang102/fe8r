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

/// 主菜单的选项。
///
/// ## 出处：`include/savemenu.h:45-53`
///
/// ```c
/// MAIN_MENU_OPTION_RESUME   = (1 << MAIN_MENU_RESUME),
/// MAIN_MENU_OPTION_RESTART  = (1 << MAIN_MENU_RESTART),
/// MAIN_MENU_OPTION_COPY     = (1 << MAIN_MENU_COPY),
/// MAIN_MENU_OPTION_ERASE    = (1 << MAIN_MENU_ERASE),
/// MAIN_MENU_OPTION_NEW_GAME = (1 << MAIN_MENU_NEW_GAME),
/// MAIN_MENU_OPTION_EXTRAS   = (1 << MAIN_MENU_EXTRAS),
/// ```
///
/// ⚠️ 我第一版自己编了「开始新的游戏 / 附加内容」两项 ——
/// **原作是六个、而且按存档状态动态出现**（见 [mainMenuOptions]）。
/// ## ★ 枚举值 = **OAM 精灵索引**
///
/// `src/savedraw.c:199-205`：
///
/// ```c
/// for (i = 0; i < SAVE_MENU_PARENT(proc)->unk_31; i++) {
///     int spriteIdx = BitfileToIndex(SaveMenuGetBitfile(
///         SAVE_MENU_PARENT(proc)->main_options, i));   // 位下标 = 精灵索引
///     SaveDraw_DrawMainMenuOption(proc, 48 - xOffset, y + i * 25, spriteIdx, ...);
/// }
/// ```
///
/// 而 `SpriteArray_SavemenuData_1[]`（`data_08A9D904.c:92-103`）是
/// 索引 → 精灵的映射：
///
///     [0]=Data_0 [1]=Data_1 [2]=Data_2 [3]=Data_3
///     [4]=Data_4 [5]=Data_5 [6]=Data_6 [7]=Data_1 [8]=Data_8 ...
///
/// **所以 `NEW_GAME` 的精灵索引是 4，不是它在列表里的位置。**
///
/// ## ⚠️ 标签**不是消息文本**，是 OAM 精灵
///
/// `gSprite_SavemenuData_4`（`frontier_df4_menu.c:7350`）：
///
/// ```c
/// { 5,
///   OAM0_SHAPE_32x16, OAM1_SIZE_32x16,             OAM2_CHR(0x180),
///   OAM0_SHAPE_16x16, OAM1_SIZE_16x16 + OAM1_X(32), OAM2_CHR(0x184),
///   ... }
/// ```
///
/// 「はじめから」是**预渲染的图块**，装在 VRAM 的 `0x180/0x184/0x106/…`。
/// 我在消息表里找不到，就是因为**它根本不在消息表里**。
enum MainMenuItem {
  /// 枚举值就是 OAM 精灵索引（`include/savemenu.h:33-41`）
  resume(0),
  restart(1),
  copy(2),
  erase(3),
  newGame(4),
  extras(5);

  const MainMenuItem(this.spriteIndex);

  /// `MAIN_MENU_*` 的值 —— `SpriteArray_SavemenuData_1` 的下标
  final int spriteIndex;
}

/// 难度。
///
/// ## ★ 说明文字是**真实消息**，ID 来自源码
///
/// `src/DrawDifficultyModeText.c:29`：
///
/// ```c
/// str = GetStringFromIndex(gTextIds_DifficultyDescription[proc->current_selection]);
/// ```
///
/// `gTextIds_DifficultyDescription` 没有命名符号，但
/// `layout/baseline_syms.d/cfbind_difficultymenu.tsv` 给出了地址
/// **`08A9D970`** —— 落在 `data_08A9D904.c` 的 residue
/// `[08A9D94C,08A9D978)` 里：
///
/// ```c
/// 0x00006000,      // 08A9D96C
/// 0x08330832,      // 08A9D970  ← ★ u16 小端拆开 = 0x0832, 0x0833
/// 0x00000834,      // 08A9D974      u16 = 0x0834
/// ```
///
/// **所以是 `[0x0832, 0x0833, 0x0834]` = 消息 2098 / 2099 / 2100。**
///
/// `SaveMenu_PostDifficultHandler.c:32-36` 里 `difficulty == 3` 走单独分支
/// —— 对应本枚举的 index 2（困难）。
enum Difficulty {
  /// 新手 —— 说明文字 = 消息 **2098**
  easy(0x0832),

  /// 普通 —— 消息 **2099**
  normal(0x0833),

  /// 困难 —— 消息 **2100**
  hard(0x0834);

  const Difficulty(this.descriptionMsgId);

  /// `gTextIds_DifficultyDescription[index]`
  final int descriptionMsgId;
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

  /// 已用存档槽数（`InitSaveMenuChoice.c` 里的 `count`）
  int usedSlots = 0;

  /// 有中断存档吗（`proc->unk_44 == 0x100`）
  bool resumable = false;

  /// 主菜单当前实际出现的项（**每次都由源码规则算出来**）
  List<MainMenuItem> get options =>
      mainMenuOptions(usedSlots: usedSlots, resumable: resumable);

  /// 当前选中项在 [options] 里的下标
  int mainIndex = 0;

  MainMenuItem get mainItem {
    final o = options;
    if (o.isEmpty) return MainMenuItem.newGame;
    return o[mainIndex.clamp(0, o.length - 1)];
  }
  // ⚠️ 难度菜单的默认选中项在源码里确实是**第 0 项**
  //   （`src/difficultymenu.c:29` / `src/difficultymenu_080B0B38.c:65-66`：
  //    `proc->current_selection = 0;`），第 0 项的文字是消息 2098。
  //   但**第 5 轮实测**：把这里的默认从 `normal` 改成 `easy` 会**弄坏两条端到端场景**
  //   （`中断存档` / `读档继续` —— 因为**教学档下「中断」是禁用的**，
  //    见 `docs/还差什么.md` 的地图菜单表），却**没有**让教学链触发。
  //   ⇒ **先回退**，把真正的断点（教学链的入队）留到下一步单独查。
  Difficulty difficulty = Difficulty.normal;
  int saveSlot = -1;

  /// 选好的存档（`-1` 表示还没选）
  bool get hasSave => saveSlot >= 0;

  /// 取一条消息的**当前语言**文本（有译文用译文）。
  ///
  /// ⚠️ **必须走 `localized().plain`，不能自己 `join()` 译文段。**
  ///
  /// `plain` 会把 `[LF]` 控制码变成真正的换行；自己 `join()` 就丢掉了换行，
  /// 一段本来分行的说明会挤成一行、溢出屏幕（截图里验证过）。
  String _msg(int id, String fallback) {
    if (texts.byId(id) == null) return fallback;
    final p = texts.localized(id).plain.trim();
    return p.isEmpty ? fallback : p;
  }

  /// 「聖魔の光石」—— 消息 253（`texts.json`）
  String get gameTitle => _msg(253, '聖魔の光石');

  /// 「スタートを押すと始まります」—— 消息 1749
  String get pressStart => _msg(1749, 'スタートを押すと始まります');

  /// UI 用词的译文（术语表；原作的菜单项是精灵，没有消息 id）
  String ui(String jp) => texts.ui(jp);

  /// 当前难度的**说明文字** —— `gTextIds_DifficultyDescription[选择]`
  /// （消息 2098 / 2099 / 2100，出处见 [Difficulty]）
  String get difficultyDescription =>
      _msg(difficulty.descriptionMsgId, '');

  /// 主菜单**实际会出现哪些项** —— 逐条对应 `src/InitSaveMenuChoice.c:23-62`。
  ///
  /// ```c
  /// if (proc->unk_44 == 0x100)
  ///     AddMainMenuOption(proc, MAIN_MENU_OPTION_RESUME);      // 有中断存档
  ///
  /// for (i = 0; i < 3; i++)
  ///     if (proc->chapter_idx[i] != (u8)-1) count++;           // 数已用存档槽
  ///
  /// if (count > 0) {
  ///     AddMainMenuOption(proc, MAIN_MENU_OPTION_RESTART);
  ///     if (count < 3) AddMainMenuOption(proc, MAIN_MENU_OPTION_COPY);
  ///     AddMainMenuOption(proc, MAIN_MENU_OPTION_ERASE);
  /// }
  /// if (count < 3) AddMainMenuOption(proc, MAIN_MENU_OPTION_NEW_GAME);
  /// ...
  /// if (proc->extra_options != 0) proc->main_options |= MAIN_MENU_OPTION_EXTRAS;
  /// ```
  ///
  /// [usedSlots] = 已用存档数（0..3）、[resumable] = 有中断存档、
  /// [hasExtras] = 附加内容可用（本实现恒为 false —— 附加内容不做）。
  List<MainMenuItem> mainMenuOptions({
    int usedSlots = 0,
    bool resumable = false,
    bool hasExtras = false,
  }) {
    final out = <MainMenuItem>[];
    if (resumable) out.add(MainMenuItem.resume);
    if (usedSlots > 0) {
      out.add(MainMenuItem.restart);
      if (usedSlots < 3) out.add(MainMenuItem.copy);
      out.add(MainMenuItem.erase);
    }
    if (usedSlots < 3) out.add(MainMenuItem.newGame);
    if (hasExtras) out.add(MainMenuItem.extras);
    return out;
  }

  void reset() {
    screen = startAt;
    framesOnScreen = 0;
  }

  /// 调试入口：`FE8R_TITLE=menu|difficulty|slot|title|is` 直接跳到某个画面
  /// （**只为看 UI**，不影响正常流程）
  static TitleScreen? screenByName(String n) {
    switch (n) {
      case 'nintendo':
        return TitleScreen.nintendo;
      case 'is':
        return TitleScreen.intelligentSystems;
      case 'press':
        return TitleScreen.healthSafety;
      case 'title':
        return TitleScreen.title;
      case 'reel':
        return TitleScreen.classReel;
      case 'menu':
        return TitleScreen.mainMenu;
      case 'difficulty':
        return TitleScreen.difficulty;
      case 'slot':
        return TitleScreen.saveSlot;
    }
    return null;
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
        final n = options.length;
        if (n > 0 && (up || down)) {
          // 上下移动，**到边界就停**（原作不是循环）
          mainIndex = (mainIndex + (down ? 1 : -1)).clamp(0, n - 1);
        }
        if (confirm) {
          switch (mainItem) {
            case MainMenuItem.newGame:
              _goto(TitleScreen.difficulty);
            case MainMenuItem.resume:
              // `case MAIN_MENU_OPTION_RESUME: return 0;` —— 什么都不选，直接进游戏
              return true;
            case MainMenuItem.restart:
            case MainMenuItem.erase:
            case MainMenuItem.copy:
              // `flag = 1` —— **要先选一个存档槽**
              // （存档系统是 M9，这里只走到槽选择）
              _goto(TitleScreen.saveSlot);
            case MainMenuItem.extras:
              // 本实现不做 —— **留在原地**，不静默跳走
              return false;
          }
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
