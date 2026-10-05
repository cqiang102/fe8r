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

import 'dart:math' as math;

import 'package:fe8r/core/core.dart';
import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

/// 一个单位在地图上的表现。
class UnitComponent extends PositionComponent {
  UnitComponent({
    required this.unit,
    required this.tileSize,
    required this.isSelected,
    required this.isActive,
  }) : super(size: Vector2.all(tileSize));

  final MapUnit unit;
  final double tileSize;
  final bool isSelected;

  /// 是否属于当前行动阵营
  final bool isActive;

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
class CursorComponent extends PositionComponent {
  CursorComponent({required double tileSize})
      : super(size: Vector2.all(tileSize));

  /// 闪烁相位（渲染层的时间表现，不影响规则）
  double _t = 0;

  @override
  void update(double dt) {
    _t += dt;
  }

  @override
  void render(Canvas canvas) {
    // 呼吸式闪烁：规则层没有"光标动画"这个概念，这纯粹是表现
    final a = 0.55 + 0.45 * (0.5 + 0.5 * math.sin(_t * 4));
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = Color.fromRGBO(255, 224, 102, a);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.x, size.y).deflate(0.5),
        const Radius.circular(3),
      ),
      stroke,
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
  void render(Canvas canvas) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.x, size.y),
        const Radius.circular(3),
      ),
      Paint()..color = const Color(0xE0101820),
    );

    for (var i = 0; i < options.length; i++) {
      final y = i * tileSize;
      if (i == selectedIndex) {
        canvas.drawRect(
          Rect.fromLTWH(0, y, size.x, tileSize),
          Paint()..color = const Color(0x66FFE066),
        );
      }
      final tp = TextPainter(
        text: TextSpan(
          text: options[i].label,
          style: TextStyle(
            color: i == selectedIndex
                ? const Color(0xFFFFE066)
                : const Color(0xFFD8DEE9),
            fontSize: tileSize * 0.52,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(4, y + (tileSize - tp.height) / 2));
    }
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
