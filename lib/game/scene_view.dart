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

    // 立绘：文本里的 `[LoadFace]0xNNN]` 就是脸编号
    int? face;
    for (final seg in e.message.segments.whereType<TextControl>()) {
      if (seg.isLoadFace && seg.arg != null) face = seg.arg;
    }
    show(
      // 用**这一页**的文字，不是整条消息
      text: e.text,
      virtualSize: virtualSize,
      hostFace: face,
    );
  }
}
