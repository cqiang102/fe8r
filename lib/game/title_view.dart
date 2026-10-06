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
import 'package:flutter/painting.dart';

import 'title_flow.dart';

/// 开场流程的渲染层
class TitleView extends PositionComponent {
  TitleView({required this.flow, required this.screenSize})
      : super(size: screenSize.clone(), priority: 1 << 19);

  final TitleFlow flow;
  final Vector2 screenSize;

  /// 淡入淡出用的覆盖层（0 = 全黑）
  double fade = 1;

  TextComponent? _main;
  TextComponent? _sub;
  int _lastKey = -1;

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
        return ('開始', flow.mainItem == MainMenuItem.newGame
            ? '▶ はじめから\n  おまけ'
            : '  はじめから\n▶ おまけ');
      case TitleScreen.difficulty:
        String mark(Difficulty d) => flow.difficulty == d ? '▶ ' : '  ';
        return ('難易度', '${mark(Difficulty.easy)}あたらしい\n'
            '${mark(Difficulty.normal)}ふつう\n'
            '${mark(Difficulty.hard)}むずかしい');
      case TitleScreen.saveSlot:
        final slots = List.generate(3, (i) {
          final sel = flow.saveSlot == i ? '▶' : ' ';
          final used = flow.saveSlot == i ? '（新建）' : '';
          return '$sel ファイル${i + 1}$used';
        }).join('\n');
        return ('セーブ', slots);
    }
  }

  @override
  Future<void> onLoad() async {
    await _rebuild(force: true);
  }

  @override
  void update(double dt) {
    super.update(dt);
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
      position: Vector2(cx, screenSize.y * 0.34),
    );
    add(_main!);

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
    // 淡入淡出用黑幕
    if (fade > 0) {
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.x, size.y),
        Paint()..color = Color.fromRGBO(0, 0, 0, fade.clamp(0, 1)),
      );
    }
  }
}
