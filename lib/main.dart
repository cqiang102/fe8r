// FE8 重制版 —— 程序入口
//
// 层次（技术方案 §4.2，由 tools/verify/check_architecture.dart 强制）：
//
//   lib/core   规则层  纯 Dart，1:1 移植反编译 C，完全可序列化
//   lib/game   表现层  Flame，重新实现
//   lib/ui     外壳层  Flutter widget
//
// 依赖方向只能 core ← game ← ui，反向依赖会被架构检查拦下。

import 'package:fe8r/core/core.dart';
import 'package:fe8r/game/fe8_game.dart';
import 'package:fe8r/ui/debug_screenshot.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

  /// 包住 GameWidget，供调试截图抓帧（见 lib/ui/debug_screenshot.dart）
  final GlobalKey _captureKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    final path = screenshotPathFromEnv();
    if (path != null) {
      captureWhenReady(_captureKey, path, beforeCapture: () {
        final script = inputScriptFromEnv();
        if (script != null) _game.runScript(script);
      });
    }
  }

  /// 键盘 → 流程输入的映射。
  ///
  /// 用 `KeyEventResult.handled` 明确吃掉事件，避免方向键同时被
  /// Flutter 的焦点系统拿去滚动。桌面端这类"两套输入系统抢事件"
  /// 的问题不处理会表现为"按了键但偶尔没反应"。
  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final k = event.logicalKey;
    FlowInput? i;
    if (k == LogicalKeyboardKey.arrowUp || k == LogicalKeyboardKey.keyW) {
      i = FlowInput.up;
    } else if (k == LogicalKeyboardKey.arrowDown ||
        k == LogicalKeyboardKey.keyS) {
      i = FlowInput.down;
    } else if (k == LogicalKeyboardKey.arrowLeft ||
        k == LogicalKeyboardKey.keyA) {
      i = FlowInput.left;
    } else if (k == LogicalKeyboardKey.arrowRight ||
        k == LogicalKeyboardKey.keyD) {
      i = FlowInput.right;
    } else if (k == LogicalKeyboardKey.keyZ ||
        k == LogicalKeyboardKey.enter ||
        k == LogicalKeyboardKey.space) {
      i = FlowInput.confirm;
    } else if (k == LogicalKeyboardKey.keyX ||
        k == LogicalKeyboardKey.escape) {
      i = FlowInput.cancel;
    } else if (k == LogicalKeyboardKey.keyE) {
      i = FlowInput.endTurn;
    }
    if (i == null) return KeyEventResult.ignored;
    _game.input(i);
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Focus(
        autofocus: true,
        onKeyEvent: _onKey,
        child: Stack(
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
          // 底部 HUD：回合 / 阵营 / 可行动数 / 光标 / 阶段
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: ValueListenableBuilder<String>(
              valueListenable: _game.hud,
              builder: (context, t, _) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
