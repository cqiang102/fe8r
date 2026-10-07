// 大地图的**表现层**（Flame 组件）。
//
// 规则在 `lib/core/flow/world_map.dart`（`WMLoc_*` 的移植），这里只画。
//
// ⚠️ **诚实说明**：节点之间的连线画的是**直线**，不是原作那条走出来的路线。
// 原作的路径图 `gWMPathData`（`struct GMapPathData`，`include/worldmap.h:310-317`）
// 在 carve 里是 **region-different、未去指针化** ⇒ 真值读不到（未查证），
// 所以"哪个节点连哪个节点、走哪条 keyframe"这一层我没有数据。
// 已解出来的 `gWorldmapPath_n` 只有 keyframe 坐标，缺"属于哪条边"的索引。
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import 'package:fe8r/core/core.dart';

class WorldMapView extends PositionComponent {
  WorldMapView({
    required this.data,
    required this.state,
    required this.textForName,
    required Vector2 screen,
  }) : _screen = screen,
       super(size: screen, priority: 50);

  final WorldMapData data;
  final WorldMapState state;

  /// 节点名消息 id → 文本（没有就显示 `#id`）
  final String Function(int textId) textForName;

  final Vector2 _screen;

  /// 世界图坐标 → 屏幕坐标。节点 x∈[72,408]、y∈[40,264]（实测范围）
  static const double _dataW = 470, _dataH = 300;

  Offset _toScreen(int x, int y) => Offset(
        (x + 20) / _dataW * _screen.x,
        (y + 10) / _dataH * _screen.y,
      );

  @override
  void render(Canvas canvas) {
    // 底色：深海的蓝，让节点浮出来
    canvas.drawRect(
      Rect.fromLTWH(0, 0, _screen.x, _screen.y),
      Paint()..color = const Color(0xFF16324F),
    );

    final dot = Paint()..color = const Color(0xFFCFE8FF);
    final cur = Paint()..color = const Color(0xFFFFD84D);
    final box = Paint()..color = const Color(0xCC0B0F14);

    // 节点
    for (var i = 0; i < data.nodeCount; i++) {
      final n = data.nodes[i];
      final o = _toScreen(n.x, n.y);
      final isCurrent = i == state.node;
      final r = isCurrent ? 9.0 : 5.0;
      canvas.drawCircle(o, r, isCurrent ? cur : dot);
      if (state.cleared.contains(i)) {
        // 已通关：套一圈
        canvas.drawCircle(
          o,
          r + 3,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..color = const Color(0xFFFF8A5C),
        );
      }
    }

    // 底部信息条：当前节点名 + 目标 + 下一个
    final nodeNow = data.nodes[state.node];
    final next = state.nextNodeId;
    final lines = <String>[
      '大地图  ${textForName(nodeNow.nameTextId)}'
          '   当前节点 ${state.node} / 下一个 ${next < 0 ? "—" : "$next"}',
      '确认 = 走到下一个节点；走到目标章节所在节点再确认 = 出发',
    ];
    final barH = 18.0 * lines.length + 8;
    canvas.drawRect(
      Rect.fromLTWH(0, _screen.y - barH, _screen.x, barH),
      box,
    );
    for (var i = 0; i < lines.length; i++) {
      final tp = TextPainter(
        text: TextSpan(
          text: lines[i],
          style: const TextStyle(color: Colors.white, fontSize: 13),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(8, _screen.y - barH + 6 + i * 18));
    }
  }
}
