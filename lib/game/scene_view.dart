// 场景演出的**表现**：对话框。
//
// ## 为什么单独一个类
//
// 原来这块逻辑在 `Fe8Game` 里，而且**有两条平行的路径**：
//   * `_updateSceneDialogue()` —— 场景脚本（挂 `_uiLayer`）
//   * `_rebuildDialogue()`   —— 旧的事件引擎（挂 `_overlayLayer`）
//
// 两条路径写同一个字段 `_dialogue`，但挂在**不同的父节点**上。
// `Component.remove()` 在 debug 下有 `assert(child._parent == this)`，
// 路径交错时会直接 assert 崩，而不是安静失效。
//
// 现在只有**一个** `show()`，挂在 viewport 上（`camera.viewport` 的子组件
// 在世界之后渲染，坐标就是虚拟分辨率 —— 这正是 GBA 风格 UI 要的语义）。

import 'dart:convert';
import 'dart:io';
import 'dart:ui' show Image, instantiateImageCodec;

import 'package:fe8r/core/core.dart';
import 'package:flame/camera.dart' show Viewport;
import 'package:flame/components.dart';

import 'battle_components.dart';

/// 对话框的宿主
class SceneView {
  SceneView({required this.onHudChanged});

  /// 显示状态变化时通知外部更新 HUD
  final void Function() onHudChanged;

  /// UI 层 —— 挂在 `camera.viewport` 上，**不是** `world`
  late final PositionComponent layer = PositionComponent();

  DialogueBoxComponent? _box;

  /// 当前显示的对白（null = 没在显示）
  ShowText? current;

  /// 是否正在显示
  bool get isShowing => _box != null;

  /// 脸编号 → 角色名（由 `face_ids.json` 提供）
  Map<int, String> faceNames = const {};

  /// 已解析的立绘图像缓存（角色名 → 图像）
  final Map<String, Image?> _portraitCache = {};

  /// 从提取产物里读脸编号映射。
  ///
  /// 表项是**可读的 C 源码**里的符号名（`&portrait_Eirika_tileset`），
  /// 由 `tools/pipeline/extract/parse_face_ids.py` 导出。
  void loadFaceIds(String jsonPath) {
    final f = File(jsonPath);
    if (!f.existsSync()) return;
    final d = jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
    final out = <int, String>{};
    (d['faces'] as Map<String, dynamic>).forEach((k, v) {
      if (v is String) out[int.parse(k)] = v;
    });
    faceNames = out;
  }

  /// 已加载的立绘（角色名 → 图像）
  Image? portraitFor(int? faceId) {
    if (faceId == null) return null;
    final name = faceNames[faceId];
    return name == null ? null : _portraitCache[name];
  }

  /// 预加载一批脸编号的立绘。
  ///
  /// ⚠️ 立绘解码是**异步**的（`instantiateImageCodec`），而渲染是同步的。
  /// 所以演出开始前先预热，而不是在 `render` 里现加载 ——
  /// 后者要么阻塞、要么第一帧画不出来。
  Future<void> preload(Iterable<int> faceIds) async {
    for (final id in faceIds.toSet()) {
      final name = faceNames[id];
      if (name == null || _portraitCache.containsKey(name)) continue;
      final f = File('tools/pipeline/out/portraits/$name.png');
      if (!f.existsSync()) {
        _portraitCache[name] = null;
        continue;
      }
      try {
        final codec = await instantiateImageCodec(f.readAsBytesSync());
        final frame = await codec.getNextFrame();
        _portraitCache[name] = frame.image;
      } catch (_) {
        _portraitCache[name] = null;
      }
    }
  }

  /// 把 UI 层挂到 viewport 上。
  ///
  /// ⚠️ 必须挂 viewport：
  ///   * 挂 `world` → 跟着地图缩放、位置错
  ///   * 挂 game 根节点 → `CameraComponent` 的优先级是 `0x7fffffff`，
  ///     **地图画在 UI 之上**，对话框被完全盖住
  void attachTo(Viewport viewport) => viewport.add(layer);

  /// 显示一句话。[text] 为 null 或空则收起对话框。
  void show({
    required String? text,
    required Vector2 virtualSize,
    int? hostFace,
    int? guestFace,
  }) {
    if (_box != null) {
      layer.remove(_box!);
      _box = null;
    }
    if (text == null || text.isEmpty) {
      onHudChanged();
      return;
    }

    // 0.56 + 0.28 = 0.84，下面 16% 留给 HUD
    final boxH = virtualSize.y * 0.28;
    _box = DialogueBoxComponent(
      text: text,
      hostFaceId: hostFace,
      guestFaceId: guestFace,
      hostPortrait: portraitFor(hostFace),
      guestPortrait: portraitFor(guestFace),
      boxWidth: virtualSize.x * 0.92,
      boxHeight: boxH,
    )..position = Vector2(virtualSize.x * 0.04, virtualSize.y * 0.56);
    layer.add(_box!);
    onHudChanged();
  }

  /// 从一条场景事件更新显示
  void applyEvent(SceneEvent? e, Vector2 virtualSize) {
    if (e is! ShowText) {
      current = null;
      show(text: null, virtualSize: virtualSize);
      return;
    }
    current = e;

    // 立绘：`[OpenXXX]` 打开一个**位置**，紧跟着的 `[$XXXX]` 给这个位置放脸。
    //
    // ⚠️ 不是"槽位"！见 `TextControl.isLeftPosition` 的说明 ——
    // 我第一版按"高字节 = 槽位"做，结果说话人一变（Fado → 传令兵）
    // 立绘还是旧的，因为两者的高字节都是 1。
    final page = e.page ?? e.message.plain;
    final upto = _indexOfPage(e.message, page);

    // 每个位置当前的脸（按出现顺序回放，后写的覆盖先写的）
    final left = <String, int>{};
    final right = <String, int>{};
    String? pendingPos;
    for (final seg in e.message.segments.take(upto)) {
      if (seg is! TextControl) continue;
      if (seg.isFacePosition) {
        pendingPos = seg.name;
        // `CloseSpeech*` 之类不改位置，只记 Open*
        if (seg.name.startsWith('Close')) pendingPos = null;
      } else if (seg.isFaceSpec && pendingPos != null) {
        final fid = seg.faceId;
        final bucket = TextControl.isLeftPosition(pendingPos) ? left : right;
        // 没有名字的脸编号 = 清空这个位置
        if (fid == null || faceNames[fid] == null) {
          bucket.remove(pendingPos);
        } else {
          bucket[pendingPos] = fid;
        }
        pendingPos = null;
      }
    }

    show(
      text: page,
      virtualSize: virtualSize,
      hostFace: right.values.isEmpty ? null : right.values.last,
      guestFace: left.values.isEmpty ? null : left.values.last,
    );
  }

  /// 这一页在整条消息里的结束位置（用于"只看这一页之前的脸"）
  int _indexOfPage(GameMessage m, String page) {
    // 简单做法：按分页标记累计，找到哪一段的文字等于本页
    final buf = StringBuffer();
    for (var i = 0; i < m.segments.length; i++) {
      final seg = m.segments[i];
      if (seg is TextRun) {
        buf.write(seg.text);
      } else if (seg is TextControl && seg.isPageBreak) {
        if (buf.toString().trim() == page.trim()) return i;
        buf.clear();
      }
    }
    return m.segments.length;
  }
}
