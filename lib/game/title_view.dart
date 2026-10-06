// 开场流程的画面。
//
// ⚠️ **图形是占位的，流程是真的。**
//
// 标题/logo 的素材在 `graphics/frontier_df3_titlescreen/`，
// 是 **8px 宽的灰度图块条**（`L` 模式），和立绘一样要按 TSA 合成。
// 那是独立的一块工作（参照 `tools/pipeline/extract/parse_portraits.py`）。
//
// 所以这里只画：
//   * 纯色背景（Nintendo / IntSys / 健康警告各自的底色）
//   * **真实的文字**（标题「聖魔の光石」= 消息 253、
//     「スタートを押すと始まります」= 消息 1749）
//
// 这样下一步接图形时**只改这个文件**，流程与状态机不动。
import 'package:flame/components.dart';
import 'dart:ui' show Image;

import 'package:flame/cache.dart' show Images;
import 'package:flutter/painting.dart';

import 'title_flow.dart';

/// 开场流程的渲染层
class TitleView extends PositionComponent {
  TitleView({required this.flow, required this.screenSize})
      : super(size: screenSize.clone(), priority: 1 << 19);

  final TitleFlow flow;
  final Vector2 screenSize;

  /// 淡入淡出用的覆盖层（0 = 透明、1 = 全黑）。
  ///
  /// ⚠️ **必须自己在 `update` 里推进。**
  /// 我第一版把它初始化成 `1` 就不管了 —— 于是**整屏全黑**，
  /// 底下的素材一张都看不见（截图里只有文字）。
  /// 「图没显示」和「图被黑幕盖住」在截图里长得一样。
  double fade = 1;

  /// 当前画面已经淡了多久（帧）
  int _fadeFrame = 0;
  TitleScreen? _fadeScreen;

  /// 淡入用 **30 帧**（`src/GameIntroNintendoFadeOUT.c:17` 的 `0x1E`）
  static const int fadeFrames = 30;

  TextComponent? _main;
  TextComponent? _sub;

  /// 菜单项的文字组件（每次重建时替换）
  final List<TextComponent> _menuTexts = [];
  int _lastKey = -1;

  /// 已加载的**现成素材**（反编译项目里已经合成好的 PNG）。
  ///
  /// ## ⚠️ 大部分素材不用我合成 —— 用户提醒后才发现
  ///
  /// 规律是 **`Img_X.png` 是裸图块条、`X.png` 是合成版**：
  ///
  ///     misc_gfx3/IntelligentSystems.png    240×160  mode P   ← 合成好的
  ///     misc_gfx3/Img_IntelligentSystems.png  8×1192  mode L   ← 裸条
  ///
  /// `Makefile:804-808` 用 `$(GBAGFX)` 把合成版转成 `.4bpp`/`.gbapal` ——
  /// 也就是说**那些 PNG 是可编辑的源图**。
  ///
  /// 我本来打算自己合成标题素材，**差点重复劳动**。
  final Map<String, Image> _images = {};

  /// 每个画面用哪张现成素材（没有的留空，退回纯色底）
  static const _assetFor = <TitleScreen, String>{
    TitleScreen.intelligentSystems: 'IntelligentSystems.png',
    // 存档菜单背景在反编译里只有裸条（`Img_SaveMenuBG.png`），先不用
    TitleScreen.classReel: 'OpAnimEirika.png',
  };

  /// 每个画面的底色（占位；接图形后删掉）
  static const _bg = <TitleScreen, Color>{
    TitleScreen.nintendo: Color(0xFF101418),
    TitleScreen.intelligentSystems: Color(0xFF141018),
    TitleScreen.healthSafety: Color(0xFF101014),
    TitleScreen.title: Color(0xFF1A2233),
    TitleScreen.classReel: Color(0xFF12202A),
    TitleScreen.mainMenu: Color(0xFF16202C),
    TitleScreen.difficulty: Color(0xFF16202C),
    TitleScreen.saveSlot: Color(0xFF16202C),
  };

  /// 当前画面的**菜单项**（空 = 不是菜单）
  ///
  /// ⚠️ 之前我把菜单也拼成一个字符串、用 `▶` 标选中 ——
  /// **那不算 UI**：看不出"这东西能选"、没有框、没有行高亮。
  /// 用户指出"缺的是 UI 交互"，这就是那部分。
  List<String> get menuItems {
    switch (flow.screen) {
      case TitleScreen.mainMenu:
        // ⚠️ 选项由 `InitSaveMenuChoice.c` 的规则动态决定（不是写死的两项）
        return [for (final o in flow.options) _label(o)];
      case TitleScreen.difficulty:
        return const ['あたらしい', 'ふつう', 'むずかしい'];
      case TitleScreen.saveSlot:
        return const ['ファイル１', 'ファイル２', 'ファイル３'];
      default:
        return const [];
    }
  }

  /// 菜单项的文字。
  ///
  /// ⚠️ **这几个是我按语义写的占位**，不是从消息表里查出来的 ——
  /// 我找了 `texts.json` 但没定位到存档菜单那批标签
  /// （1..8 字的短标签扫了一遍，命中都是地图地名）。
  ///
  /// **下一步（有明确判据）**：在 `src/savemenu*.c` 里找到
  /// `main_options` 的位 → 消息 id 的映射表。找到之前不假装它是真的。
  static String _label(MainMenuItem o) {
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

  /// 菜单里当前选中的下标
  int get menuIndex {
    switch (flow.screen) {
      case TitleScreen.mainMenu:
        return flow.mainIndex;
      case TitleScreen.difficulty:
        return flow.difficulty.index;
      case TitleScreen.saveSlot:
        return flow.saveSlot < 0 ? 0 : flow.saveSlot;
      default:
        return -1;
    }
  }

  /// 主文字 / 副文字（副文字可以没有）
  (String, String?) _lines() {
    switch (flow.screen) {
      case TitleScreen.nintendo:
        return ('Nintendo', null);
      case TitleScreen.intelligentSystems:
        return ('INTELLIGENT SYSTEMS', null);
      case TitleScreen.healthSafety:
        // 真实文案：消息 1749
        return (flow.pressStart, '（健康与安全提示画面）');
      case TitleScreen.title:
        // 真实标题：消息 253
        return (flow.gameTitle, flow.pressStart);
      case TitleScreen.classReel:
        return ('職業紹介', '（不按键 815 帧会自动播放）');
      case TitleScreen.mainMenu:
        return ('開始', null);
      case TitleScreen.difficulty:
        return ('難易度', null);
      case TitleScreen.saveSlot:
        return ('セーブ', null);
    }
  }

  @override
  Future<void> onLoad() async {
    await _loadAssets();
    await _rebuild(force: true);
  }

  Future<void> _loadAssets() async {
    final images = Images(prefix: 'assets/title/');
    for (final name in _assetFor.values.toSet()) {
      // 直接读字节再解码 —— 不依赖 flame 的资源清单，
      // 这样"素材在不在"是**文件系统层面**能看出来的
      try {
        // `Images.load` 会走 Flame 自己的缓存（`Flame.images`），
        // 所以用文件名当 key 就够了 —— 不用自己拿字节解码。
        _images[name] = await images.load(name);
      } catch (e) {
        // 缺素材就退回纯色底，不静默崩
        // ignore: avoid_print
        print('  [title] 素材 $name 加载失败：$e');
      }
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    // 画面切了就从头淡入
    if (_fadeScreen != flow.screen) {
      _fadeScreen = flow.screen;
      _fadeFrame = 0;
    }
    if (_fadeFrame < fadeFrames) {
      _fadeFrame++;
      fade = 1 - _fadeFrame / fadeFrames;
      if (fade < 0) fade = 0;
    }

    // 状态机由 `Fe8Game` 按帧推进；这里只负责"状态变了就重建文字"
    final key = flow.screen.index * 16 +
        flow.mainItem.index * 4 +
        flow.difficulty.index * 2 +
        (flow.saveSlot + 1);
    if (key != _lastKey) _rebuild();
  }

  Future<void> _rebuild({bool force = false}) async {
    final key = flow.screen.index * 16 +
        flow.mainItem.index * 4 +
        flow.difficulty.index * 2 +
        (flow.saveSlot + 1);
    if (!force && key == _lastKey) return;
    _lastKey = key;

    final (main, sub) = _lines();
    if (_main != null) remove(_main!);
    if (_sub != null) remove(_sub!);

    // ⚠️ **有现成素材就不画占位文字。**
    //
    // 我第一版两个都画，结果占位文字压在真实的 INTELLIGENT SYSTEMS logo 上
    // （截图里一眼可见）—— 素材越真，这个错越显眼。
    //
    // 判据：`_assetFor` 里有这个画面、且素材**真的加载成功**。
    final asset = _assetFor[flow.screen];
    final hasArt = asset != null && _images.containsKey(asset);
    if (hasArt) {
      return;   // 素材自己会说话
    }

    final cx = screenSize.x / 2;
    _main = TextComponent(
      text: main,
      textRenderer: TextPaint(
        style: TextStyle(
          color: const Color(0xFFFFFFFF),
          fontSize: screenSize.x * 0.075,
          height: 1.2,
        ),
      ),
      anchor: Anchor.topCenter,
      // 菜单画面的标题要**上移**：菜单框从 0.42 开始，压在一起会重叠
      position: Vector2(cx, menuItems.isEmpty
          ? screenSize.y * 0.34
          : screenSize.y * 0.16),
    );
    add(_main!);

    // 菜单项：**每项一个 TextComponent**，才能各自定位到框里
    final items = menuItems;
    if (items.isNotEmpty) {
      _menuTexts.clear();
      final m = _MenuMetrics(size, count: items.length);
      for (var i = 0; i < items.length; i++) {
        final t = TextComponent(
          text: items[i],
          textRenderer: TextPaint(
            style: TextStyle(
              color: const Color(0xFFF0F4FA),
              fontSize: m.tile * 1.5,
            ),
          ),
          anchor: Anchor.centerLeft,
          position: Vector2(
            m.boxX + m.tile * 0.9,
            m.originY + m.tile * 0.7 + i * m.rowH + m.rowH / 2,
          ),
          priority: 2,
        );
        add(t);
        _menuTexts.add(t);
      }
    } else {
      for (final t in _menuTexts) {
        remove(t);
      }
      _menuTexts.clear();
    }

    if (sub != null) {
      _sub = TextComponent(
        text: sub,
        textRenderer: TextPaint(
          style: TextStyle(
            color: const Color(0xFFB8C4D4),
            fontSize: screenSize.x * 0.045,
            height: 1.4,
          ),
        ),
        anchor: Anchor.topCenter,
        position: Vector2(cx, screenSize.y * 0.56),
      );
      add(_sub!);
    }
  }

  @override
  void render(Canvas canvas) {
    // 底色
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.x, size.y),
      Paint()..color = _bg[flow.screen] ?? const Color(0xFF101418),
    );

    // 有现成素材就画素材（**像素风：不插值**）
    final name = _assetFor[flow.screen];
    final img = name == null ? null : _images[name];
    if (img != null) {
      // 素材是 GBA 分辨率（240×160 或 256×160），铺满视口
      final scale = size.y / img.height;
      final w = img.width * scale;
      canvas.drawImageRect(
        img,
        Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble()),
        Rect.fromLTWH((size.x - w) / 2, 0, w, size.y),
        Paint()..filterQuality = FilterQuality.none,
      );
    }
    // ---- 菜单：带框的列表 + 行高亮 ----
    final items = menuItems;
    if (items.isNotEmpty) {
      final m = _MenuMetrics(size, count: items.length);
      final w = m.boxW(size);
      final h = m.boxH();
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(m.boxX, m.originY, w, h),
        Radius.circular(m.tile * 0.4),
      );
      // 底
      canvas.drawRRect(rect, Paint()..color = const Color(0xE0101820));
      // 选中行的高亮块
      final sel = menuIndex.clamp(0, items.length - 1);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            m.boxX + m.tile * 0.3,
            m.originY + m.tile * 0.7 + sel * m.rowH,
            w - m.tile * 0.6,
            m.rowH,
          ),
          Radius.circular(m.tile * 0.2),
        ),
        Paint()..color = const Color(0x66FFE066),
      );
      // 框线（描边）
      canvas.drawRRect(
        rect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = m.tile * 0.25
          ..color = const Color(0xFF8FA8C8),
      );
    }

    // 淡入淡出用黑幕
    if (fade > 0) {
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.x, size.y),
        Paint()..color = Color.fromRGBO(0, 0, 0, fade.clamp(0, 1)),
      );
    }
  }
}

/// 菜单的绘制参数（**从视口尺寸算，不写死像素**）
class _MenuMetrics {
  _MenuMetrics(Vector2 screen, {required this.count})
      : tile = screen.x / 30,          // GBA 是 30 图块宽
        originY = screen.y * 0.42;

  /// 一个图块多少像素（GBA 是 8px）
  final double tile;
  final double originY;
  final int count;

  /// 行高：原作菜单是 2 图块一行
  double get rowH => tile * 2.2;

  /// 框的宽：够放下最长的一项
  double boxW(Vector2 screen) => screen.x * 0.52;
  double boxH() => rowH * count + tile * 1.4;
  double get boxX => tile * 3;
}
