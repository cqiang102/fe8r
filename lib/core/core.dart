// lib/core —— 规则层
//
// 纯 Dart。不依赖 Flutter / Flame / dart:ui / dart:io（由
// tools/verify/check_architecture.dart 强制检查）。
//
// 这一层是 1:1 移植反编译 C 代码的产物，定位是"**游戏规则本身**"：
// 乱数、战斗计算、移动消耗、地图变更、事件状态机……
//
// 三条硬约束：
//   1. 纯 Dart —— 能在没有 UI 的环境里跑测试（也是 C Oracle 对照的前提）
//   2. 完全可序列化 —— 支持任意时刻存档（技术方案 §4.4）
//   3. 每个文件带 `PORT OF: <C 源文件>` 头注释 —— 保证可追溯
//
// 表现层（lib/game）和外壳层（lib/ui）都可以依赖它，反过来不行。

export 'map/map_grid.dart';
export 'rng/game_rng.dart';
export 'terrain/terrain_type.dart';
