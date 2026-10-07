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

export 'battle/battle_rng.dart';
export 'battle/battle_round.dart';
export 'class/class_table.dart';
export 'event/chapter_events.dart';
export 'event/game_text.dart';
export 'event/scene_data.g.dart';
export 'event/scene.dart';
export 'event/event_script.dart';
export 'event/event_vm.dart';
export 'battle/battle_stats.dart';
export 'battle/battle_compute.dart';
export 'battle/hit_effects.dart';
export 'battle/phase.dart';
export 'flow/combat.dart';
export 'flow/chapter_objectives.dart';
export 'flow/battle_field.dart';
export 'flow/chapters.dart';
export 'flow/chapter_loader.dart';
export 'flow/enemy_ai.dart';
export 'flow/flow_machine.dart';
export 'flow/turn_loop.dart';
export 'flow/unit_defs.dart';
export 'flow/battle_map_kind.dart';
export 'flow/map_menu.dart';
export 'flow/play_config.dart';
export 'flow/tutorial_events.dart';
export 'flow/chapter_status.dart';
export 'flow/unit_list.dart';
export 'flow/game_options.dart';
export 'flow/item_use.dart';
export 'flow/world_map.dart';
export 'save/save_state.dart';
export 'flow/move_costs.dart';
export 'flow/talks.dart';
export 'flow/unit_move.dart';
export 'battle/weapon_triangle.dart';
export 'battle/battle_unit.dart';
export 'map/camera.dart';
export 'map/map_grid.dart';
export 'map/movement_range.dart';
export 'rng/game_rng.dart';
export 'terrain/terrain_type.dart';
