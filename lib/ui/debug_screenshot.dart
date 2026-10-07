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

import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// 从环境变量读取截图输出路径；未设置则返回 null（正常运行不产生任何开销）
String? screenshotPathFromEnv() {
  final p = Platform.environment['FE8R_SCREENSHOT'];
  return (p == null || p.isEmpty) ? null : p;
}

/// 从环境变量读取**状态转储**的输出路径。
///
/// ## 为什么需要（这是我最该早点做的东西）
///
/// 我一直在用**截图**做验证，而截图只证明"那一刻那一帧" ——
/// 于是"开场链路 / 序章剧情 / 序章战斗都还有 bug"这类问题
/// **靠截图永远发现不了**：它证明不了"这条链路"。
///
/// 转储是**机器可读**的：单位坐标 / id 是否唯一 / 渲染组件数 /
/// 事件标志 / 场景停在哪条指令 / 相机位置 …… 一次跑完全都有。
///
/// 判据因此可以做成**断言**，而不是"我盯着图看"。
String? dumpPathFromEnv() {
  final p = Platform.environment['FE8R_DUMP'];
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
  Map<String, dynamic> Function()? beforeDump,
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

  // ★ 状态转储（`FE8R_DUMP`）—— 和截图一起写出。
  //
  // ⚠️ **必须在 `exit(0)` 之前**，否则拿不到东西。
  final dumpPath = dumpPathFromEnv();
  if (dumpPath != null && beforeDump != null) {
    try {
      final f = File(dumpPath);
      await f.parent.create(recursive: true);
      await f.writeAsString(
        const JsonEncoder.withIndent(' ').convert(beforeDump()),
      );
      debugPrint('[dump] 已写出 $dumpPath');
    } catch (e) {
      debugPrint('[dump] 失败: $e');
    }
  }

  // ⚠️⚠️ **必须退出，否则这条命令会一直挂着。**
  //
  // 我漏了这一步很久：截图写完之后应用继续跑、`flutter run` 不退出，
  // 于是命令一直等到外层的 `timeout 300`（**5 分钟**）才被杀掉。
  //
  // 因为命令最终"成功"（grep 得到那行 `已写出`），**从没被怀疑过** ——
  // 约 20 次截图 = 纯等待约 100 分钟。
  //
  // 这类"成功但慢得离谱"的坑，和"永远返回 0 的门禁"是同一族：
  // **它不报错，只是在浪费你的时间。**
  exit(0);
}

/// **立刻**抓一帧写 PNG（不等任何帧）。
///
/// 给实时控制通道的 `shot` 用：先 `state` 看状态、再决定何时抓，
/// 比 `FE8R_SCREENSHOT`（启动时等 3 秒 + 脚本）可控得多。
/// 返回是否真的写出了文件。
Future<bool> captureNow(GlobalKey key, String path) async {
  final ctx = key.currentContext;
  if (ctx == null || !ctx.mounted) {
    debugPrint('[shot] 找不到 RepaintBoundary');
    return false;
  }
  final boundary = ctx.findRenderObject() as RenderRepaintBoundary?;
  if (boundary == null) {
    debugPrint('[shot] RenderObject 不是 RepaintBoundary');
    return false;
  }
  final image = await boundary.toImage(pixelRatio: 1);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  if (data == null) {
    debugPrint('[shot] toByteData 返回 null');
    return false;
  }
  final f = File(path);
  f.parent.createSync(recursive: true);
  f.writeAsBytesSync(data.buffer.asUint8List());
  debugPrint('[shot] → $path (${data.lengthInBytes} B)');
  return true;
}
