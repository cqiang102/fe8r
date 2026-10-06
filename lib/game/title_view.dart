// 开场流程的画面。
//
// # 设计原则：**用 Flame 的方式重做，不照抄 GBA 的实现**
//
// 原作的这些画面是 GBA 的 BG 图块 + OAM 精灵拼出来的：
// 边框是一张 `Tsa_*` 图块图、菜单项是预渲染的 OAM 精灵
// （见 `docs/源码索引.md` 与各处的 `PORT OF` 注释）。
//
// **那套实现方式不该被照搬。** 我们从源码里取的是**结构与内容**：
//
//   * 顺序与时机（`gProcScr_GameControl`、`Title_IDLE` 的 815 帧）
//   * 有哪些项、什么时候出现（`InitSaveMenuChoice.c` 的规则）
//   * 布局（`DifficultySelect_PutModeText` 的列行）
//   * **真实文案**（消息表里的 ID —— 253 / 1749 / 2098-2100 等）
//
// 呈现方式换成 Flutter + Flame：
//
//   * 菜单用 `MenuPanelComponent`（与战斗行动菜单**同一个组件**）
//   * 文字用 `TextComponent`，尺寸全部由图块尺寸派生
//   * 只有"现成素材"才当图片贴（`assets/title/`）
import 'dart:ui' show Image;

import 'package:fe8r/game/menu_panel.dart';
import 'package:flame/cache.dart' show Images;
import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import 'title_flow.dart';

class TitleView extends PositionComponent {
  TitleView({required this.flow, required this.screenSize})
      : super(size: screenSize.clone(), priority: 1 << 19);

  final TitleFlow flow;
  final Vector2 screenSize;

  /// 淡入用的覆盖层（0 = 透明、1 = 全黑）
  double fade = 1;
  int _fadeFrame = 0;
  TitleScreen? _fadeScreen;

  /// 淡入 **30 帧**（`src/GameIntroNintendoFadeOUT.c:17` 的 `0x1E`）
  static const int fadeFrames = 30;

  /// 一个 GBA 图块多少像素 —— **所有尺寸都从它派生**
  double get tile => screenSize.x / 30;

  final Map<String, Image> _images = {};

  /// 有现成素材的画面（`assets/title/`，由 `copy_title_assets.py` 产出）
  static const _assetFor = <TitleScreen, String>{
    TitleScreen.intelligentSystems: 'IntelligentSystems.png',
    TitleScreen.classReel: 'OpAnimEirika.png',
  };

  TextComponent? _title;
  TextComponent? _body;
  SaveMainMenuComponent? _menu;
  int _layoutKey = -1;

  @override
  Future<void> onLoad() async {
    await _loadAssets();
    await _layout();
  }

  Future<void> _loadAssets() async {
    final images = Images(prefix: 'assets/title/');
    for (final name in _assetFor.values.toSet()) {
      try {
        _images[name] = await images.load(name);
      } catch (_) {
        // 缺素材就退回纯色底 —— 不静默崩，也不假装有图
      }
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (_fadeScreen != flow.screen) {
      _fadeScreen = flow.screen;
      _fadeFrame = 0;
    }
    if (_fadeFrame < fadeFrames) {
      _fadeFrame++;
      fade = (1 - _fadeFrame / fadeFrames).clamp(0, 1);
    }

    // 选择变了要重排菜单（高亮行跟着走）
    final key = Object.hash(flow.screen, flow.mainIndex, flow.difficulty,
        flow.saveSlot, flow.options.length);
    if (key != _layoutKey) _layout();
  }

  // ---------------------------------------------------------------- 布局

  Future<void> _layout() async {
    _layoutKey = Object.hash(flow.screen, flow.mainIndex, flow.difficulty,
        flow.saveSlot, flow.options.length);

    _title?.removeFromParent();
    _body?.removeFromParent();
    _menu?.removeFromParent();
    _title = null;
    _body = null;
    _menu = null;

    final asset = _assetFor[flow.screen];
    final hasArt = asset != null && _images.containsKey(asset);

    // 标题：有素材的画面不写字（素材自己会说话）
    if (!hasArt) {
      _title = TextComponent(
        text: _headline(),
        textRenderer: TextPaint(
          style: TextStyle(
            color: const Color(0xFFFFFFFF),
            fontSize: tile * 2.0,
          ),
        ),
        anchor: Anchor.topCenter,
        position: Vector2(screenSize.x / 2, screenSize.y * 0.14),
      );
      add(_title!);
    }

    // 菜单：**与战斗行动菜单同一个组件**
    final entries = _entries();
    if (entries.isNotEmpty) {
      final w = flow.screen == TitleScreen.difficulty
          ? screenSize.x * 0.34
          : screenSize.x * 0.44;
      _menu = SaveMainMenuComponent(
        entries: entries,
        selectedIndex: _selected(),
        tileSize: tile,
        panelWidth: w,
      )..position = Vector2(
          tile * 2.5,
          flow.screen == TitleScreen.difficulty
              ? screenSize.y * 0.40
              : screenSize.y * 0.34,
        );
      add(_menu!);
    }

    // 正文：难度说明在**右边**（源码 `DifficultySelect_PutModeText`
    // 把它放在 BG0 第 18 列），其余画面居中在下方
    final body = _bodyText();
    if (body.isNotEmpty) {
      final isDiff = flow.screen == TitleScreen.difficulty;
      _body = TextComponent(
        text: body,
        textRenderer: TextPaint(
          style: TextStyle(
            color: const Color(0xFFB8C4D4),
            fontSize: tile * (isDiff ? 0.95 : 1.15),
            height: 1.5,
          ),
        ),
        anchor: isDiff ? Anchor.topLeft : Anchor.topCenter,
        position: Vector2(
          isDiff ? screenSize.x * 0.52 : screenSize.x / 2,
          isDiff ? screenSize.y * 0.40 : screenSize.y * 0.62,
        ),
      );
      add(_body!);
    }
  }

  // ---------------------------------------------------------------- 内容

  String _headline() {
    switch (flow.screen) {
      case TitleScreen.nintendo:
        return 'Nintendo';
      case TitleScreen.intelligentSystems:
        return 'INTELLIGENT SYSTEMS';
      case TitleScreen.healthSafety:
        return flow.pressStart; // 真实消息 1749
      case TitleScreen.title:
        return flow.gameTitle; // 真实消息 253「聖魔の光石」
      case TitleScreen.classReel:
        return '職業紹介';
      case TitleScreen.mainMenu:
        return flow.ui('開始');
      case TitleScreen.difficulty:
        return flow.ui('難易度');
      case TitleScreen.saveSlot:
        return flow.ui('セーブ');
    }
  }

  /// 菜单项。**内容全部来自 [TitleFlow] 的源码规则**，这里只做显示。
  List<MenuEntry> _entries() {
    switch (flow.screen) {
      case TitleScreen.mainMenu:
        return [
          for (final o in flow.options)
            MenuEntry(_label(o), enabled: o != MainMenuItem.extras),
        ];
      case TitleScreen.difficulty:
        return [
          for (final d in Difficulty.values) MenuEntry(_difficultyLabel(d)),
        ];
      case TitleScreen.saveSlot:
        return [
          for (var i = 0; i < 3; i++)
            // ⚠️ **全角数字** —— 术语表的 key 是「ファイル１」，
            // 用半角 `${i + 1}` 拼出来的字符串匹配不上，界面会一直是日文
            MenuEntry(flow.ui('ファイル${_fullWidth(i + 1)}')),
        ];
      default:
        return const [];
    }
  }

  int _selected() {
    switch (flow.screen) {
      case TitleScreen.mainMenu:
        return flow.mainIndex;
      case TitleScreen.difficulty:
        return flow.difficulty.index;
      case TitleScreen.saveSlot:
        return flow.saveSlot < 0 ? 0 : flow.saveSlot;
      default:
        return 0;
    }
  }

  /// 正文（空串 = 这个画面没有正文）
  String _bodyText() {
    switch (flow.screen) {
      case TitleScreen.healthSafety:
        return '（健康与安全提示画面）';
      case TitleScreen.title:
        return flow.pressStart;
      case TitleScreen.classReel:
        return '（不按键 815 帧会自动播放）';
      case TitleScreen.difficulty:
        // ★ 真实消息 2098 / 2099 / 2100
        // （`gTextIds_DifficultyDescription`，见 `Difficulty` 的出处）
        return flow.difficultyDescription;
      default:
        return '';
    }
  }

  /// 主菜单项的名字。
  ///
  /// ⚠️ **原作里这几个不是文字，是 OAM 精灵**（`gSprite_SavemenuData_N`）。
  /// 取不到那些图块，所以这里是**按语义写的日文**，不是消息表原文。
  /// 结构（哪些项、什么顺序、能不能选）是真的，字面是占位的。
  String _label(MainMenuItem o) {
    return flow.ui(_labelJp(o));
  }

  /// 半角数字转全角（原作的字面量用全角）
  static String _fullWidth(int n) =>
      const ['０', '１', '２', '３', '４', '５', '６', '７', '８', '９'][n];

  static String _labelJp(MainMenuItem o) {
    switch (o) {
      case MainMenuItem.resume:
        return 'つづきから';
      case MainMenuItem.restart:
        return 'さいしょから';
      case MainMenuItem.copy:
        return 'コピー';
      case MainMenuItem.erase:
        return 'けす';
      case MainMenuItem.newGame:
        return 'はじめから';
      case MainMenuItem.extras:
        return 'おまけ';
    }
  }

  /// 难度名。同样是精灵（`gSprite_DifficultyMenuSelectModeText`），字面占位。
  String _difficultyLabel(Difficulty d) {
    return flow.ui(_difficultyLabelJp(d));
  }

  static String _difficultyLabelJp(Difficulty d) {
    switch (d) {
      case Difficulty.easy:
        return 'あたらしい';
      case Difficulty.normal:
        return 'ふつう';
      case Difficulty.hard:
        return 'むずかしい';
    }
  }

  // ---------------------------------------------------------------- 绘制

  @override
  void render(Canvas canvas) {
    // 纯色底 —— 只有素材表达不了的部分才落到 canvas
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.x, size.y),
      Paint()..color = const Color(0xFF141A22),
    );

    final name = _assetFor[flow.screen];
    final img = name == null ? null : _images[name];
    if (img != null) {
      final iw = img.width.toDouble();
      final ih = img.height.toDouble();
      // 像素风：**不插值**
      canvas.drawImageRect(
        img,
        Rect.fromLTWH(0, 0, iw, ih),
        Rect.fromLTWH(0, 0, size.x, size.x * ih / iw),
        Paint()..filterQuality = FilterQuality.none,
      );
    }

    if (fade > 0) {
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.x, size.y),
        Paint()..color = Color.fromRGBO(0, 0, 0, fade),
      );
    }
  }
}
