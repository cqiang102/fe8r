// FE8 重制版 —— 程序入口
//
// 层次（技术方案 §4.2，由 tools/verify/check_architecture.dart 强制）：
//
//   lib/core   规则层  纯 Dart，1:1 移植反编译 C，完全可序列化
//   lib/game   表现层  Flame，重新实现
//   lib/ui     外壳层  Flutter widget
//
// 依赖方向只能 core ← game ← ui，反向依赖会被架构检查拦下。

import 'package:fe8r/game/fe8_game.dart';
import 'package:fe8r/ui/debug_screenshot.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(
    MaterialApp(
      title: 'FE8 重制版',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF3A5A40),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const _GameShell(),
    ),
  );
}

/// 游戏外壳。
///
/// M0 阶段只做一件事：把地图渲染出来，证明
///   .mar → 数据管线 → .tmx → Flame 显示
/// 这条链路是通的。UI 后面再长。
class _GameShell extends StatefulWidget {
  const _GameShell();

  @override
  State<_GameShell> createState() => _GameShellState();
}

class _GameShellState extends State<_GameShell> {
  late final Fe8Game _game = Fe8Game();

  /// 包住 GameWidget，供调试截图抓帧（见 lib/ui/debug_screenshot.dart）
  final GlobalKey _captureKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    final path = screenshotPathFromEnv();
    if (path != null) {
      // 不 await：让界面照常启动，截完自己退出即可（由外部脚本控制）
      captureWhenReady(_captureKey, path);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          RepaintBoundary(key: _captureKey, child: GameWidget(game: _game)),
          // 左上角信息条：M0 阶段用来确认版本与加载状态
          Positioned(
            left: 12,
            top: 12,
            child: DefaultTextStyle(
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white70,
                fontFamily: 'monospace',
              ),
              child: ValueListenableBuilder<String>(
                valueListenable: _game.status,
                builder: (context, status, _) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(status),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
