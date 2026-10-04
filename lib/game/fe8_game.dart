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
// FixedResolutionViewport 只在 flame/camera.dart 里导出
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

      status.value = '${grid.id}  ${grid.width}×${grid.height}  '
          '${_terrainBrief(grid)}';
      debugPrint('[Fe8Game] $grid；地形分布 ${grid.terrainHistogram()}');
    } catch (e, st) {
      status.value = '加载失败: $e';
      debugPrint('[Fe8Game] 加载失败: $e\n$st');
      rethrow;
    }
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
