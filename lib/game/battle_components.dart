// 表现层：把 `lib/core` 的语义状态画出来。
//
// ## 这里不做的事
//
// **不在渲染层做任何规则判断。** 能不能选中、能走到哪、哪些格子高亮——
// 全部由 `lib/core` 的 `FlowMachine` 决定，这里只负责"把它的结论画出来"。
//
// 这是技术方案 §4.3「语义形式原则」在表现层的落地：
// 一旦渲染层开始自己判断规则（比如"这里顺手判一下阵营"），
// 规则就有了第二份实现，两份迟早会不一致——而且是很难查的那种不一致。
//
// ## M5 阶段的取舍
//
// 单位暂时画成**色块 + 边框**，不是精灵图。美术管线（M11）还没做，
// 现在画占位图只会掩盖"位置/层级/交互"这些真正需要先验证的东西。
// 地形沿用 M0 就验证过的 Tiled 地图。


import 'package:fe8r/core/core.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
// `ClipComponent` 的 `ShapeBuilder` 要求 Flame 的 `Shape`，
// 具体形状（`Rectangle`）在 experimental 里 —— 这是官方文档给的用法。
import 'package:flame/experimental.dart' show Rectangle;
import 'package:flutter/painting.dart';

/// 一个单位在地图上的表现。
class UnitComponent extends PositionComponent {
  UnitComponent({
    required this.unit,
    required this.tileSize,
    required this.isSelected,
    required this.isActive,
  }) : super(size: Vector2.all(tileSize));

  final double tileSize;

  /// ⚠️ **可变**：组件持久存在，状态变化时更新它而不是重建组件。
  ///
  /// 原来是 `final`（不可变快照），于是 `BattleView` 每次都得把整棵
  /// 组件树拆掉重建 —— 那是把 Flame 当画图 API 用。
  /// 组件本该有自己的状态与生命周期。
  MapUnit unit;

  bool isSelected;

  /// 是否属于当前行动阵营
  bool isActive;

  /// 把新的快照灌进来（组件本身不重建）。
  ///
  /// ⚠️ **不直接设 position** —— 位置交给 [moveTo]，那里用 Flame 的
  /// `MoveToEffect` 做补间。直接赋值会让"逻辑上已经走了格、画面上瞬移"
  /// 这个现象无法消除。
  void sync({
    required MapUnit next,
    required bool selected,
    required bool active,
  }) {
    unit = next;
    isSelected = selected;
    isActive = active;
  }

  /// 平滑移动到目标位置。
  ///
  /// 用 Flame 的 `MoveToEffect` 而不是自己 `dt` 累加 ——
  /// 白拿 pause / reset / onComplete，且与光标闪烁风格统一。
  void moveTo(Vector2 destination, {double seconds = 0.18, bool instant = false}) {
    // 先把上一个移动效果清掉：不清会两个效果同时改 position，抖。
    removeAll(children.whereType<MoveToEffect>().toList());
    if (instant || seconds <= 0) {
      position = destination;
      return;
    }
    add(MoveToEffect(destination, EffectController(duration: seconds)));
  }

  @override
  void render(Canvas canvas) {
    // 三个阵营用三套颜色。注意用的是 `factionBit`（0x80）而不是完整 faction，
    // 与 `PhaseRules.areUnitsAllied` 的判据保持一致。
    final Color base;
    if (unit.factionBit == Faction.red) {
      base = const Color(0xFFB44A3C); // 敌：红
    } else if (unit.factionBit == Faction.green) {
      base = const Color(0xFF3F8F4A); // 友军 NPC：绿
    } else {
      base = const Color(0xFF3A6FB4); // 我方：蓝
    }

    final rect = Rect.fromLTWH(1, 1, size.x - 2, size.y - 2);
    final paint = Paint()..color = base;

    // 已行动的单位画成半透明 —— 一眼能看出还剩谁没动
    if (unit.hasActed) {
      paint.color = base.withValues(alpha: 0.35);
    }

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.deflate(2), const Radius.circular(3)),
      paint,
    );

    // 边框：选中 > 当前阵营 > 普通
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = isSelected ? 2.5 : 1.5;
    if (isSelected) {
      stroke.color = const Color(0xFFFFE066);
    } else if (isActive && !unit.hasActed) {
      stroke.color = const Color(0xFFFFFFFF);
    } else {
      stroke.color = const Color(0x66000000);
    }
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.deflate(2), const Radius.circular(3)),
      stroke,
    );

    // 血量条（底部细条）
    if (unit.maxHp > 0) {
      final hpFrac = (unit.hp / unit.maxHp).clamp(0.0, 1.0);
      final barY = size.y - 4.5;
      canvas.drawRect(
        Rect.fromLTWH(3, barY, size.x - 6, 2.5),
        Paint()..color = const Color(0x88000000),
      );
      canvas.drawRect(
        Rect.fromLTWH(3, barY, (size.x - 6) * hpFrac, 2.5),
        Paint()
          ..color = hpFrac > 0.5
              ? const Color(0xFF6FD36F)
              : (hpFrac > 0.25
                  ? const Color(0xFFE0C24A)
                  : const Color(0xFFD05050)),
      );
    }
  }
}

/// 光标
class CursorComponent extends PositionComponent with HasPaint {
  CursorComponent({required double tileSize})
      : super(size: Vector2.all(tileSize));

  @override
  Future<void> onLoad() async {
    // 呼吸式闪烁交给 Flame 的 `OpacityEffect`，不再自己 `_t += dt` + sin 手算。
    //
    // 用 Effect 白拿的能力：pause / reset / onComplete，
    // 而且和项目其它动画（移动补间）风格统一。
    //
    // `OpacityEffect` 需要 `OpacityProvider` —— `HasPaint` 就提供了它。
    add(OpacityEffect.to(
      0.55,
      EffectController(duration: 0.4, infinite: true, alternate: true),
    ));
  }

  @override
  void render(Canvas canvas) {
    // 圆角框：Flame 没有圆角矩形组件，手绘有理由。
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.x, size.y).deflate(0.5),
        const Radius.circular(3),
      ),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0xFFFFE066),
    );
  }
}

/// 移动范围高亮
class MovementRangeComponent extends PositionComponent {
  MovementRangeComponent({
    required this.range,
    required this.tileSize,
  }) : super(size: Vector2(range.width * tileSize, range.height * tileSize));

  final MovementRange range;
  final double tileSize;

  @override
  void render(Canvas canvas) {
    final fill = Paint()..color = const Color(0x553A6FB4);
    final edge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = const Color(0x883A6FB4);

    for (var y = 0; y < range.height; y++) {
      for (var x = 0; x < range.width; x++) {
        if (!range.canReach(x, y)) continue;
        final r = Rect.fromLTWH(x * tileSize, y * tileSize, tileSize, tileSize);
        canvas.drawRect(r, fill);
        // 只在边界画框，内部不画 —— 否则整片范围会变成网格噪点
        if (!range.canReach(x - 1, y) ||
            !range.canReach(x + 1, y) ||
            !range.canReach(x, y - 1) ||
            !range.canReach(x, y + 1)) {
          canvas.drawRect(r.deflate(0.5), edge);
        }
      }
    }
  }
}

/// 行动菜单（待机 / 攻击）。
///
/// 画在地图上的单位旁边，而不是屏幕角落——原版就是这样，
/// 而且"菜单跟着单位走"能避免玩家看错是哪个单位在行动。
class ActionMenuComponent extends PositionComponent {
  ActionMenuComponent({
    required this.options,
    required this.selectedIndex,
    required this.tileSize,
  }) : super(size: Vector2(tileSize * 2.6, tileSize * options.length));

  final List<ActionOption> options;
  final int selectedIndex;
  final double tileSize;

  @override
  Future<void> onLoad() async {
    // 选中行的高亮用 `RectangleComponent`，不再手绘
    add(RectangleComponent(
      position: Vector2(0, selectedIndex * tileSize),
      size: Vector2(size.x, tileSize),
      paint: Paint()..color = const Color(0x66FFE066),
      priority: 0,
    ));

    // 每行文字用 `TextComponent` —— 它自己量尺寸、自己按 anchor 定位，
    // 不用手算 `(tileSize - tp.height) / 2` 这种居中偏移。
    for (var i = 0; i < options.length; i++) {
      add(TextComponent(
        text: options[i].label,
        textRenderer: TextPaint(
          style: TextStyle(
            color: i == selectedIndex
                ? const Color(0xFFFFE066)
                : const Color(0xFFD8DEE9),
            fontSize: tileSize * 0.52,
          ),
        ),
        // 垂直居中靠 anchor，不靠手算
        anchor: Anchor.centerLeft,
        position: Vector2(4, i * tileSize + tileSize / 2),
        priority: 1,
      ));
    }
  }

  @override
  void render(Canvas canvas) {
    // 圆角框：Flame 没有圆角矩形组件（只有 `RectangleComponent` 画直角），
    // 这一处手绘是有理由的。
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.x, size.y),
        const Radius.circular(3),
      ),
      Paint()..color = const Color(0xE0101820),
    );
  }
}

/// 攻击目标的标记（准星）
class TargetMarkerComponent extends PositionComponent {
  TargetMarkerComponent({required double tileSize})
      : super(size: Vector2.all(tileSize));

  @override
  void render(Canvas canvas) {
    final r = Rect.fromLTWH(0, 0, size.x, size.y).deflate(1.5);
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..color = const Color(0xFFFF5A5A);
    canvas.drawRRect(
      RRect.fromRectAndRadius(r, const Radius.circular(3)),
      p,
    );
    // 两条对角线，让"这是攻击目标"和"这是普通光标"一眼可分
    canvas.drawLine(r.topLeft, r.bottomRight, p..strokeWidth = 1.5);
    canvas.drawLine(r.topRight, r.bottomLeft, p);
  }
}

/// 对话框。
///
/// **渲染层不做任何剧情判断** —— 显示哪段文字、要不要继续等，
/// 全部由 `lib/core/event` 的 VM 决定。这里只负责把
/// `EventPresentation` 画出来。
///
/// 立绘/背景暂时用色块 + 文字占位：真实素材属于 M11 美术管线，
/// 现在画占位图只会掩盖"引擎对不对"这个真正要验证的东西。
/// 对话框：**GBA 风格的底框 + Flame 的 [TextBoxComponent] 负责文字**。
///
/// ## 为什么不自己画文字
///
/// 第一版这里是一个手写的 `PositionComponent`：`Canvas.drawRRect` 画框、
/// `TextPainter` 自己折行、自己算能放几行。
/// **那些全是 Flame 已经做好了的**：
///
///   * `TextBoxComponent` —— 自动折行、自动重排（`maxWidth` 变了会 reflow）
///   * `TextBoxConfig.timePerChar` —— **逐字显示**（原作就是这么演的）
///   * `TextPaint` —— 文字样式与渲染
///
/// 我手写那一版在两个地方翻过车：抹掉换行导致整段变一行、
/// 算行数把文字算到一个字都不显示。**这些坑 Flame 已经填过了。**
///
/// 这里只保留真正需要自己做的事：**画 GBA 那个底框**
/// （将来换成九宫格贴图 `NineTileBoxComponent`）。
class DialogueBoxComponent extends PositionComponent {
  DialogueBoxComponent({
    required this.text,
    required this.hostFaceId,
    required this.guestFaceId,
    required this.boxWidth,
    required this.boxHeight,
    this.timePerChar = 0.02,
  }) : super(size: Vector2(boxWidth, boxHeight));

  final String text;
  final int? hostFaceId;
  final int? guestFaceId;
  final double boxWidth;
  final double boxHeight;

  /// 逐字显示的速度（秒/字）。0 表示一次性显示。
  final double timePerChar;

  late final TextBoxComponent _textBox;

  @override
  Future<void> onLoad() async {
    final m = (size.y * 0.10).clamp(6.0, 16.0);
    final fontSize = (size.y * 0.13).clamp(11.0, 18.0);
    _textBox = TextBoxComponent(
      text: text,
      textRenderer: TextPaint(
        style: TextStyle(
          color: const Color(0xFFF0F4FA),
          fontSize: fontSize,
          height: 1.3,
        ),
      ),
      boxConfig: TextBoxConfig(
        // `maxWidth` 会自动折行并 reflow —— 不用自己算
        maxWidth: size.x - m * 2,
        margins: EdgeInsets.all(m),
        // 逐字显示，像原作
        timePerChar: timePerChar,
      ),
      size: size.clone(),
    );

    // ⚠️ 必须**裁进框内**。
    //
    // `TextBoxComponent` 会按内容自己撑高（`updateBounds`），
    // 文字比框高时就画到框外面去（截图里第三行压到了边框上）。
    // Flame 自带 `ClipComponent` 正是干这个的。
    final clip = ClipComponent(
      // ShapeBuilder 的签名是 `Shape Function(Vector2 size)`，
      // 返回的是 Flame 的 `Shape`（用 `Rectangle`，圆角靠底框自己画）
      builder: (s) => Rectangle.fromRect(Offset.zero & s.toSize()),
      size: Vector2(size.x - 8, size.y - 8),
      position: Vector2(4, 4),
      priority: 1,
      children: [_textBox..position = Vector2(m - 2, m - 2)],
    );
    add(clip);

    _addFaceLabel(guestFaceId, 0);
    _addFaceLabel(hostFaceId, 1);
  }

  @override
  void render(Canvas canvas) {
    // 立绘占位：左右各一个色块 + 编号
    _face(canvas, guestFaceId, 0);
    _face(canvas, hostFaceId, 1);

    final box = Rect.fromLTWH(0, 0, size.x, size.y);
    canvas.drawRRect(
      RRect.fromRectAndRadius(box, const Radius.circular(4)),
      Paint()..color = const Color(0xF0101820),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(box.deflate(1), const Radius.circular(4)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0xFF8FA8C8),
    );
  }

  void _face(Canvas canvas, int? id, int side) {
    if (id == null) return;
    final w = size.x * 0.12;
    final r = Rect.fromLTWH(
      side == 0 ? size.x * 0.02 : size.x - w - size.x * 0.02,
      -w * 0.8,
      w,
      w,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(r, const Radius.circular(4)),
      Paint()..color = const Color(0xCC2A3A50),
    );
    // 编号由 `onLoad` 里建好的 `TextComponent` 画 ——
    // **不在 render 里建组件**（render 应当是纯的）。
  }

  /// 立绘占位的编号。用 `TextComponent` + `Anchor.center`，
  /// 不再手算 `r.center - Offset(tp.width/2, tp.height/2)`。
  void _addFaceLabel(int? id, int side) {
    if (id == null) return;
    final w = size.x * 0.12;
    final rect = Rect.fromLTWH(
      side == 0 ? size.x * 0.02 : size.x - w - size.x * 0.02,
      -w * 0.8,
      w,
      w,
    );
    add(TextComponent(
      text: id.toRadixString(16).toUpperCase(),
      textRenderer: TextPaint(
        style: TextStyle(color: const Color(0xFFFFFFFF), fontSize: w * 0.3),
      ),
      anchor: Anchor.center,
      position: Vector2(rect.center.dx, rect.center.dy),
      priority: 1,
    ));
  }
}
