// 表现层：Flame 游戏主体。
//
// M0 的目标不是"能玩"，而是**打通一条可验证的渲染链路**：
//
//   graphics/map/layout/PrologueMap.mar              （GBA 二进制）
//     → tools/pipeline/extract/map_tmx.py            （数据管线）
//     → prologue.tmx + 图集 PNG                       → flame_tiled → 画面
//     → prologue.json                                 → lib/core    → 规则
//
// ⚠️ 注意这里**两条线是分开的**：
//   * `.tmx` 只负责"怎么画"
//   * `.json` 只负责"是什么规则"
// 让 lib/core 去解析 Tiled 的 XML 是架构错误——将来换掉渲染方案时，
// 规则层不该跟着动。两者由同一个管线从同一份 GBA 数据导出，所以不可能不一致。

import 'dart:ui' show Color;

import 'package:fe8r/core/core.dart';
import 'package:fe8r/game/battle_components.dart';
// FixedResolutionViewport 只在 flame/camera.dart 里导出
import 'package:flame/components.dart' show PositionComponent;
import 'package:flame/camera.dart' show FixedResolutionViewport;
import 'package:flame/cache.dart' show Images;
import 'package:flame/game.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

/// FE8 重制版主游戏对象。
class Fe8Game extends FlameGame {
  /// 左上角状态文字（M0 阶段的调试信息）
  final ValueNotifier<String> status = ValueNotifier<String>('启动中…');

  /// 当前地图的**规则层**数据。表现层与规则层在这里汇合。
  MapGrid? map;

  /// 战场（单位 + 回合）
  BattleField? field;

  /// 交互流程状态机（规则层，纯 Dart）
  FlowMachine? flow;

  /// 当前流程状态
  FlowState? state;

  /// 状态变化通知（HUD 订阅）
  final ValueNotifier<String> hud = ValueNotifier<String>('');

  /// 单位与光标的渲染组件，按单位 id / 状态重建
  final List<UnitComponent> _unitComponents = [];
  CursorComponent? _cursor;
  MovementRangeComponent? _rangeComp;
  PositionComponent? _overlayLayer;

  /// 地图的 metatile 尺寸（像素）
  static const double metatileSize = 16;

  @override
  Color backgroundColor() => const Color(0xFF101418);

  @override
  Future<void> onLoad() async {
    try {
      // 1) 规则层数据（纯 Dart，可单独测试，不依赖 Flame）
      final grid = MapGrid.parse(
        await rootBundle.loadString('assets/maps/prologue.json'),
      );
      map = grid;

      // 2) 视觉层（Flame + Tiled）
      //
      // 两处前缀都要显式指定，因为 flame 的两个默认值都不是我们的布局：
      //   * TiledComponent 默认去 `assets/tiles/` 找 .tmx
      //   * Flame.images（图集走它加载）默认前缀是 `assets/images/`
      // 我们统一放在 assets/maps/ 下，所以两个都覆盖掉。
      const assetPrefix = 'assets/maps/';
      final tiled = await TiledComponent.load(
        'prologue.tmx',
        Vector2.all(metatileSize),
        prefix: assetPrefix,
        images: Images(prefix: assetPrefix),
      );
      world.add(tiled);

      // 3) 相机：把整张地图装进视口，保持像素锐利
      final mapSize = Vector2(
        grid.width * metatileSize,
        grid.height * metatileSize,
      );
      camera.viewport = FixedResolutionViewport(resolution: mapSize);
      camera.viewfinder.position = mapSize / 2;

      // 4) 战场与交互流程（规则层）
      field = _makeDemoField(grid);
      flow = FlowMachine(map: grid, costTable: _demoCostTable());
      state = FlowState(
        phase: FlowPhase.freeCursor,
        cursorX: 2,
        cursorY: 2,
        turn: field!.turn,
        faction: field!.activeFaction,
      );

      _overlayLayer = PositionComponent();
      world.add(_overlayLayer!);
      _rebuildOverlay();

      status.value = '${grid.id}  ${grid.width}×${grid.height}  '
          '${_terrainBrief(grid)}';
      _updateHud();
      debugPrint('[Fe8Game] $grid；地形分布 ${grid.terrainHistogram()}');
    } catch (e, st) {
      status.value = '加载失败: $e';
      debugPrint('[Fe8Game] 加载失败: $e\n$st');
      rethrow;
    }
  }

  /// 按脚本驱动一串输入（调试 / 视觉验证用）。
  ///
  /// 交互流程是纯状态机，所以"录一串按键再回放"天然可行——
  /// 这也是把它写成显式状态机的附带收益（原版的 Proc 协程做不到这点）。
  void runScript(String script) {
    for (final raw in script.split(',')) {
      final t = raw.trim().toLowerCase();
      if (t.isEmpty) continue;
      final i = switch (t) {
        'up' => FlowInput.up,
        'down' => FlowInput.down,
        'left' => FlowInput.left,
        'right' => FlowInput.right,
        'confirm' || 'z' => FlowInput.confirm,
        'cancel' || 'x' => FlowInput.cancel,
        _ => null,
      };
      if (i != null) input(i);
    }
  }

  /// 推进一次输入。
  ///
  /// **所有规则判断都在 `FlowMachine` 里**，这里只负责把新状态搬到画面上。
  void input(FlowInput i) {
    final s = state;
    final f = field;
    final fl = flow;
    if (s == null || f == null || fl == null) return;

    final r = fl.advance(s, f, i);

    // 提交一次移动（当前只实现"待机"这一个行动）
    if (r.committedMove && s.selectedUnitId != null) {
      final u = f.unitById(s.selectedUnitId);
      if (u != null && s.pendingX != null && s.pendingY != null) {
        f.moveUnit(u, s.pendingX!, s.pendingY!);
        f.finishUnit(u);
      }
    }

    state = r.state;
    _rebuildOverlay();
    _updateHud();
  }

  void _updateHud() {
    final s = state;
    final f = field;
    if (s == null || f == null) return;
    final who = f.activeFaction == Faction.red ? '敌方' : '我方';
    hud.value = '回合 ${f.turn}  $who  '
        '可行动 ${f.actionableCount}  '
        '光标 (${s.cursorX},${s.cursorY})  '
        '${s.phase.name}';
  }

  /// 按当前流程状态重建叠加层。
  ///
  /// 每次输入都整体重建，而不是增量更新——这个规模（十几到几十个组件）
  /// 重建的开销远小于"增量更新写错导致画面与状态不一致"的风险。
  void _rebuildOverlay() {
    final layer = _overlayLayer;
    final s = state;
    final f = field;
    final fl = flow;
    if (layer == null || s == null || f == null || fl == null) return;

    layer.removeAll(_unitComponents);
    _unitComponents.clear();
    if (_cursor != null) {
      layer.remove(_cursor!);
      _cursor = null;
    }
    if (_rangeComp != null) {
      layer.remove(_rangeComp!);
      _rangeComp = null;
    }

    // 移动范围画在单位下面
    final range = fl.currentRange;
    if (range != null && s.phase == FlowPhase.unitSelected) {
      _rangeComp = MovementRangeComponent(range: range, tileSize: metatileSize);
      layer.add(_rangeComp!);
    }

    for (final u in f.units) {
      if (!u.isAlive) continue;
      final c = UnitComponent(
        unit: u,
        tileSize: metatileSize,
        isSelected: u.id == s.selectedUnitId,
        isActive: f.isControllable(u),
      );
      c.position = Vector2(u.x * metatileSize, u.y * metatileSize);
      layer.add(c);
      _unitComponents.add(c);
    }

    _cursor = CursorComponent(tileSize: metatileSize)
      ..position = Vector2(s.cursorX * metatileSize, s.cursorY * metatileSize);
    layer.add(_cursor!);
  }

  /// M5 阶段用的演示战场。
  ///
  /// 单位数据是**手写的**，不是从章节数据导出的——章节单位配置属于 M12。
  /// 这里只要够验证"选中 / 移动范围 / 移动 / 待机"这条交互闭环即可。
  BattleField _makeDemoField(MapGrid grid) {
    return BattleField(
      width: grid.width,
      height: grid.height,
      turn: 1,
      activeFaction: Faction.blue,
      units: [
        MapUnit(id: 1, faction: Faction.blue, x: 2, y: 2, movement: 3, hp: 18, maxHp: 18, name: 'Eirika'),
        MapUnit(id: 2, faction: Faction.blue, x: 3, y: 4, movement: 5, hp: 28, maxHp: 30, name: 'Seth'),
        MapUnit(id: 3, faction: Faction.blue, x: 5, y: 3, movement: 2, hp: 12, maxHp: 20, name: 'Mage'),
        MapUnit(id: 0x81, faction: Faction.red, x: 8, y: 6, movement: 4, hp: 22, maxHp: 22, name: 'Fighter'),
        MapUnit(id: 0x82, faction: Faction.red, x: 10, y: 3, movement: 4, hp: 20, maxHp: 20, name: 'Archer'),
        MapUnit(id: 0x41, faction: Faction.green, x: 7, y: 8, movement: 3, hp: 16, maxHp: 16, name: 'Ally'),
      ],
    );
  }

  /// 演示用的地形消耗表：全地形可通行、消耗 1，只有 TERRAIN_NONE 不可通行。
  ///
  /// 真实的按职业消耗表已经由数据管线导出（`terrains.json`，104 张表），
  /// 接进来属于 M3 的收尾工作；这里先用平的，让交互闭环能独立验证。
  MovementCostTable _demoCostTable() {
    final c = List<int>.filled(65, 1);
    c[0] = 255;
    return MovementCostTable(c);
  }

  /// 把地形分布压成一行短摘要。
  ///
  /// 这一步的意义：证明**地形类型（规则层数据）确实随地图一起过来了**，
  /// 而不是只渲染了一张好看的图。地形类型决定移动消耗 / 回避 / 防御加成，
  /// 是绝不能丢的东西（见技术方案 §4.9.5 红线）。
  String _terrainBrief(MapGrid g) {
    final h = g.terrainHistogram().entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return h
        .take(3)
        .map((e) => '${e.key.replaceFirst('TERRAIN_', '')}×${e.value}')
        .join(' ');
  }
}
