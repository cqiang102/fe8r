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

  /// 单位组件按 `unit.id` 复用（不再每次输入全拆全建）
  final Map<int, UnitComponent> _unitById = {};
  String? _menuSignature;
  CursorComponent? _cursor;
  MovementRangeComponent? _range;
  ActionMenuComponent? _menu;
  final List<TargetMarkerComponent> _markers = [];

  int get componentCount =>
      _unitById.length + _markers.length + (_cursor != null ? 1 : 0);

  /// 把 core 的结论同步到组件树。
  ///
  /// ## 为什么是"同步"而不是"重建"
  ///
  /// 原来这里是 `rebuild()`：把整棵组件树拆掉重建。
  /// **那是把 Flame 当画图 API 用** —— 组件本该有自己的状态与生命周期，
  /// 而且全拆全建会让任何跨帧的表现（移动动画、淡入）都做不了，
  /// 因为组件在动画进行中就被销毁了。
  ///
  /// 现在是**按 id 复用**：
  ///   * 单位按 `unit.id` 复用 —— 位置变化只是改 `position`，
  ///     将来接 `MoveToEffect` 就能补间
  ///   * 光标 / 范围 / 菜单 / 标记是**瞬态**的（只在某个阶段存在），
  ///     按需建删，但仍然只在"该不该出现"变化时才动组件树
  void sync(FlowState s, BattleField f, FlowMachine fl) {
    _syncUnits(s, f);
    _syncRange(s, fl);
    _syncTargets(s, f, fl);
    _syncMenu(s, f, fl);
    _syncCursor(s, f, fl);
  }

  void _syncUnits(FlowState s, BattleField f) {
    final alive = <int, MapUnit>{
      for (final u in f.units)
        if (u.isAlive) u.id: u,
    };

    // 死了的移除
    for (final id in _unitById.keys.toList()) {
      if (!alive.containsKey(id)) {
        layer.remove(_unitById.remove(id)!);
      }
    }

    // 活着的：有就更新，没有就加
    for (final e in alive.entries) {
      final at = Vector2(e.value.x * tileSize, e.value.y * tileSize);
      final existing = _unitById[e.key];
      if (existing != null) {
        existing.sync(
          next: e.value,
          selected: e.key == s.selectedUnitId,
          active: f.isControllable(e.value),
        );
        // 位置变了才补间 —— 否每帧都加效果会互相打断。
        // 逻辑位置由 `lib/core` 决定，这里只负责"画到那儿去"。
        if (existing.position != at) existing.moveTo(at);
      } else {
        final c = UnitComponent(
          unit: e.value,
          tileSize: tileSize,
          isSelected: e.key == s.selectedUnitId,
          isActive: f.isControllable(e.value),
        )..position = at;
        layer.add(c);
        _unitById[e.key] = c;
      }
    }
  }

  void _syncRange(FlowState s, FlowMachine fl) {
    final range = fl.currentRange;
    final want = range != null && s.phase == FlowPhase.unitSelected;
    if (!want) {
      if (_range != null) layer.remove(_range!);
      _range = null;
      return;
    }
    if (_range == null) {
      _range = MovementRangeComponent(range: range, tileSize: tileSize);
      layer.add(_range!);
    }
  }

  void _syncTargets(FlowState s, BattleField f, FlowMachine fl) {
    final unit = s.phase == FlowPhase.selectTarget
        ? f.unitById(s.selectedUnitId)
        : null;
    final targets = unit == null
        ? const <MapUnit>[]
        : fl.validTargets(f, unit, s.pendingX ?? unit.x, s.pendingY ?? unit.y);

    // 目标集合变了才重建（数量与坐标都对比）
    final same = targets.length == _markers.length &&
        List.generate(targets.length,
                (i) => _markers[i].position ==
                    Vector2(targets[i].x * tileSize, targets[i].y * tileSize))
            .every((x) => x);
    if (same) return;

    layer.removeAll(_markers);
    _markers.clear();
    for (final t in targets) {
      final m = TargetMarkerComponent(tileSize: tileSize)
        ..position = Vector2(t.x * tileSize, t.y * tileSize);
      layer.add(m);
      _markers.add(m);
    }
  }

  void _syncMenu(FlowState s, BattleField f, FlowMachine fl) {
    final want = s.phase == FlowPhase.actionMenu;
    if (!want) {
      if (_menu != null) layer.remove(_menu!);
      _menu = null;
      return;
    }
    final px = s.pendingX ?? s.cursorX;
    final py = s.pendingY ?? s.cursorY;
    // 菜单的**内容与选中项**会变 —— 但组件一建出来就固定了（它的子组件在
    // onLoad 里建），所以内容变化时才重建。位置变化不算。
    final opts = fl.availableActions(s, f);
    final sig = '${opts.map((o) => o.label).join("|")}#${s.actionIndex}';
    if (_menu != null && _menuSignature == sig) {
      _menu!.position = Vector2((px + 1) * tileSize, py * tileSize);
      return;
    }
    if (_menu != null) layer.remove(_menu!);
    _menu = ActionMenuComponent(
      options: opts,
      selectedIndex: s.actionIndex.clamp(0, opts.length - 1),
      tileSize: tileSize,
    )..position = Vector2((px + 1) * tileSize, py * tileSize);
    _menuSignature = sig;
    layer.add(_menu!);
  }

  void _syncCursor(FlowState s, BattleField f, FlowMachine fl) {
    // 光标位置：选目标时停在目标上，否则在 pending 或光标格
    double cx = s.cursorX.toDouble();
    double cy = s.cursorY.toDouble();
    if (s.phase == FlowPhase.selectTarget) {
      final unit = f.unitById(s.selectedUnitId);
      if (unit != null) {
        final targets = fl.validTargets(
            f, unit, s.pendingX ?? unit.x, s.pendingY ?? unit.y);
        if (targets.isNotEmpty) {
          final idx = s.targetIndex.clamp(0, targets.length - 1);
          cx = targets[idx].x.toDouble();
          cy = targets[idx].y.toDouble();
        }
      }
    } else if (s.phase == FlowPhase.actionMenu) {
      cx = (s.pendingX ?? s.cursorX).toDouble();
      cy = (s.pendingY ?? s.cursorY).toDouble();
    }

    final at = Vector2(cx * tileSize, cy * tileSize);
    if (_cursor == null) {
      _cursor = CursorComponent(tileSize: tileSize)..position = at;
      layer.add(_cursor!);
    } else {
      // 光标是持久的 —— 只改位置。改完就能接 `MoveToEffect` 做平滑移动。
      _cursor!.position = at;
    }
  }
}
