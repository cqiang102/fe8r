// 调试用：把当前画面写成 PNG。
//
// 为什么需要它：macOS 桌面端 `flutter screenshot` 不被支持，
// 系统级 `screencapture` 又要屏幕录制权限。而 L4 视觉验证（技术方案 §6.5）
// 必须有办法把"应用真实渲染出来的东西"落成文件才能做回归对比。
//
// 用法：设置环境变量后启动，首帧渲染完成即写出 PNG。
//
//   FE8R_SCREENSHOT=/tmp/fe8r.png fvm flutter run -d macos
//
// 之所以走 RepaintBoundary 而不是截屏：拿到的就是 Flutter 自己栅格化的结果，
// 不含窗口装饰，也不受系统权限影响。

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// 从环境变量读取截图输出路径；未设置则返回 null（正常运行不产生任何开销）
String? screenshotPathFromEnv() {
  final p = Platform.environment['FE8R_SCREENSHOT'];
  return (p == null || p.isEmpty) ? null : p;
}

/// 从环境变量读取要回放的输入脚本，形如 `right,right,confirm`
///
/// 用于视觉验证：把交互驱动到某个状态再截图。
/// 没有这个能力就只能截到"刚启动"的画面，而交互状态恰恰是最需要看的。
String? inputScriptFromEnv() {
  final p = Platform.environment['FE8R_SCRIPT'];
  return (p == null || p.isEmpty) ? null : p;
}

/// 延迟若干帧后抓取 [key] 对应的 RepaintBoundary 并写文件。
///
/// 之所以要等几帧：Flame 的 `onLoad` 是异步的，地图与图集加载完之后
/// 还要再渲染一两帧画面才是完整的。
Future<void> captureWhenReady(
  GlobalKey key,
  String path, {
  int waitFrames = 30,
  Future<void> Function()? beforeCapture,
}) async {
  // 等足够多的帧，确保异步加载（地图 / 图集）已经完成并画出来了
  for (var i = 0; i < waitFrames; i++) {
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }

  // 抓帧前把交互驱动到目标状态
  await beforeCapture?.call();
  // 再等两帧让新状态画出来
  for (var i = 0; i < 3; i++) {
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }

  final ctx = key.currentContext;
  // 跨过 async gap 后 BuildContext 可能已失效，必须检查 mounted
  if (ctx == null || !ctx.mounted) {
    debugPrint('[screenshot] 找不到 RepaintBoundary，跳过');
    return;
  }
  final boundary = ctx.findRenderObject() as RenderRepaintBoundary?;
  if (boundary == null) {
    debugPrint('[screenshot] RenderObject 不是 RepaintBoundary，跳过');
    return;
  }

  final image = await boundary.toImage(pixelRatio: 1);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  if (data == null) {
    debugPrint('[screenshot] toByteData 返回 null');
    return;
  }

  final file = File(path);
  await file.parent.create(recursive: true);
  await file.writeAsBytes(data.buffer.asUint8List());
  debugPrint('[screenshot] 已写出 $path '
      '(${image.width}x${image.height}, ${data.lengthInBytes} 字节)');
}
