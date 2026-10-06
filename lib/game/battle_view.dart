// 战场渲染：单位 / 光标 / 移动范围 / 行动菜单 / 目标标记。
//
// ## 为什么单独一个类
//
// 原来这 94 行在 `Fe8Game` 里，叫 `_rebuildOverlay()`，被 **7 处**调用，
// 每次把整棵组件树拆掉重建。
//
// 搬出来之后至少职责清楚了：**这里只负责"把 core 的结论画出来"**，
// 不做任何规则判断（能不能选中、能走到哪由 `FlowMachine` 决定）。
//
// ⚠️ 还没做的一件事：**组件持久化**。现在是"状态变了就全拆全建"，
// 那是把 Flame 当画图 API 用（组件本该有自己的状态与 `update(dt)`）。
// 规模小的时候无所谓（几十个组件），但它是这个文件继续长大的原因。
// 见 battle_components.dart 里各组件 —— 它们目前是"不可变快照"，
// 要改成可变状态才能持久化。

import 'package:fe8r/core/core.dart';
import 'package:flame/components.dart';

import 'battle_components.dart';

/// 战场的表现层
class BattleView {
  BattleView({required this.tileSize});

  /// 一格多少像素
  final double tileSize;

  /// 战场层 —— 挂在 `world` 里（相机空间，跟着地图走）
  final PositionComponent layer = PositionComponent();

  final List<UnitComponent> _units = [];
  CursorComponent? _cursor;
  MovementRangeComponent? _range;
  ActionMenuComponent? _menu;
  final List<TargetMarkerComponent> _markers = [];

  int get componentCount =>
      _units.length + _markers.length + (_cursor != null ? 1 : 0);

  /// 按当前状态重建。
  ///
  /// 刻意**不增量更新** —— 增量更新写错会让画面与状态不一致，
  /// 而那种 bug 极难查。全量重建的开销在这个规模下可以忽略。
  void rebuild(FlowState s, BattleField f, FlowMachine fl) {
    layer.removeAll(_units);
    _units.clear();
    if (_cursor != null) {
      layer.remove(_cursor!);
      _cursor = null;
    }
    if (_range != null) {
      layer.remove(_range!);
      _range = null;
    }
    if (_menu != null) {
      layer.remove(_menu!);
      _menu = null;
    }
    layer.removeAll(_markers);
    _markers.clear();

    // 移动范围画在单位下面
    final range = fl.currentRange;
    if (range != null && s.phase == FlowPhase.unitSelected) {
      _range = MovementRangeComponent(range: range, tileSize: tileSize);
      layer.add(_range!);
    }

    for (final u in f.units) {
      if (!u.isAlive) continue;
      final c = UnitComponent(
        unit: u,
        tileSize: tileSize,
        isSelected: u.id == s.selectedUnitId,
        isActive: f.isControllable(u),
      );
      c.position = Vector2(u.x * tileSize, u.y * tileSize);
      layer.add(c);
      _units.add(c);
    }

    // 选目标阶段：标出所有可选目标，光标停在当前那个
    if (s.phase == FlowPhase.selectTarget) {
      final unit = f.unitById(s.selectedUnitId);
      if (unit != null) {
        final ax = s.pendingX ?? unit.x;
        final ay = s.pendingY ?? unit.y;
        final targets = fl.validTargets(f, unit, ax, ay);
        final idx =
            s.targetIndex.clamp(0, targets.isEmpty ? 0 : targets.length - 1);
        for (final t in targets) {
          final m = TargetMarkerComponent(tileSize: tileSize)
            ..position = Vector2(t.x * tileSize, t.y * tileSize);
          layer.add(m);
          _markers.add(m);
        }
        if (targets.isNotEmpty) {
          final t = targets[idx];
          _cursor = CursorComponent(tileSize: tileSize)
            ..position = Vector2(t.x * tileSize, t.y * tileSize);
          layer.add(_cursor!);
          return;
        }
      }
    }

    // 行动菜单：画在"落点那一格"的右边
    if (s.phase == FlowPhase.actionMenu) {
      final opts = fl.availableActions(s, f);
      final px = s.pendingX ?? s.cursorX;
      final py = s.pendingY ?? s.cursorY;
      _menu = ActionMenuComponent(
        options: opts,
        selectedIndex: s.actionIndex.clamp(0, opts.length - 1),
        tileSize: tileSize,
      )..position = Vector2((px + 1) * tileSize, py * tileSize);
      layer.add(_menu!);
      _cursor = CursorComponent(tileSize: tileSize)
        ..position = Vector2(px * tileSize, py * tileSize);
      layer.add(_cursor!);
      return;
    }

    _cursor = CursorComponent(tileSize: tileSize)
      ..position = Vector2(s.cursorX * tileSize, s.cursorY * tileSize);
    layer.add(_cursor!);
  }
}
