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
/// M5：把键盘输入接到 core 的流程状态机上，并用 HUD 显示状态。
/// 输入映射放在外壳层，因为"哪个键对应什么意图"是平台相关的，
/// 而"看到 confirm 该做什么"是规则层的事——两者要分开。
class _GameShell extends StatefulWidget {
  const _GameShell();

  @override
  State<_GameShell> createState() => _GameShellState();
}

class _GameShellState extends State<_GameShell> {
  late final Fe8Game _game = Fe8Game();

  /// 包住**整个界面**（含 HUD），供调试截图抓帧。
  ///
  /// 早先只包 GameWidget，结果截图里看不到 HUD —— 而"战斗日志 / 乱数消耗 /
  /// HP 变化"这些恰恰是视觉验证最需要看的东西。抓帧范围必须覆盖
  /// 你要断言的内容，否则这个能力就是摆设。
  final GlobalKey _captureKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    final path = screenshotPathFromEnv();
    if (path != null) {
      captureWhenReady(_captureKey, path, beforeCapture: () async {
        final script = inputScriptFromEnv();
        if (script != null) await _game.runScript(script);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ⚠️ **不要在这里包 `Focus`**。
      //
      // `GameWidget` 内部有自己的 FocusNode（autofocus 默认 true，会抢走主焦点），
      // 而 Flutter 的按键派发是「主焦点 → 祖先，遇到非 ignored 就停」，
      // 所以包在外面的 `Focus(onKeyEvent:)` **永远不会被调用** ——
      // 真实键盘一个键都收不到。这个 bug 藏了很久，因为视觉验证全走
      // `FE8R_SCRIPT` 直接注入输入，从没经过真实键盘路径。
      //
      // 键盘现在由 `Fe8Game with KeyboardEvents` 处理（见 fe8_game.dart）。
      body: RepaintBoundary(
        key: _captureKey,
        child: Stack(
          children: [
            GameWidget(game: _game),
            // 左上角信息条：确认版本与加载状态
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(status),
                  ),
                ),
              ),
            ),
            // 底部 HUD：回合 / 阵营 / 可行动数 / 光标 / 阶段
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: ValueListenableBuilder<String>(
                valueListenable: _game.hud,
                builder: (context, t, _) => Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  color: Colors.black87,
                  child: Text(
                    t,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.white,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
