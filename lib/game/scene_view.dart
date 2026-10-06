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

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' show Color, Image, Paint, instantiateImageCodec;

import 'package:fe8r/core/core.dart';
import 'package:flame/camera.dart' show Viewport;
import 'package:flame/components.dart';
import 'package:flame/effects.dart';

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

  /// 全屏淡入淡出用的覆盖层。
  ///
  /// ⚠️ **挂在 viewport 上、优先级最高** —— 它要盖住地图。
  /// 用 Flame 的 `OpacityEffect` 而不是自己 `dt` 累加：白拿
  /// `onComplete`，正好用来在淡完后解除脚本阻塞。
  late final RectangleComponent _fadeOverlay = RectangleComponent(
    paint: Paint()..color = const Color(0xFF000000),
    priority: 1 << 20,
  )..opacity = 0;

  /// 淡入/淡出，返回的 Future 在动画结束时完成。
  ///
  /// ⚠️ **脚本会阻塞到淡完** —— `src/Event17_Fade.c` 里四个分支
  /// 返回的都是 `EVC_ADVANCE_YIELD`。
  Future<void> fade(FadeDirection dir, int speed, Vector2 virtualSize) {
    final done = Completer<void>();
    _fadeOverlay
      ..size = virtualSize.clone()
      ..paint.color = dir.isWhite
          ? const Color(0xFFFFFFFF)
          : const Color(0xFF000000);
    // 速度值是"越大越慢"（原作语义），换算成一个能看的秒数
    final secs = (speed.clamp(1, 32)) * 0.02 + 0.1;
    _fadeOverlay.removeAll(_fadeOverlay.children.whereType<OpacityEffect>());
    _fadeOverlay.add(OpacityEffect.to(
      dir.endsVisible ? 0 : 1,
      EffectController(duration: secs),
      onComplete: () {
        if (!done.isCompleted) done.complete();
      },
    ));
    return done.future;
  }

  /// 把 UI 层挂到 viewport 上。
  ///
  /// ⚠️ 必须挂 viewport：
  ///   * 挂 `world` → 跟着地图缩放、位置错
  ///   * 挂 game 根节点 → `CameraComponent` 的优先级是 `0x7fffffff`，
  ///     **地图画在 UI 之上**，对话框被完全盖住
  void attachTo(Viewport viewport) {
    viewport.add(layer);
    layer.add(_fadeOverlay);
  }

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

    // 立绘模型 —— **出处：`src/TalkInterpret.c:140-165` + `src/TalkLoadFace.c:44-51`**
    //
    //     [OpenFarLeft](8)..[OpenFarFarRight](15)   →  **设置活动槽**（code - 8，0..7）
    //     [LoadFace](16) + u16                      →  读脸编号载入**当前活动槽**
    //                                                 faceId = u16 - 0x100
    //
    // ⚠️ 我先后错过两次：当成"(槽位<<8)|脸编号"，又当成"屏幕位置+脸编号"。
    // 两次都"看起来对"，因为 `0x0152 - 0x100 = 0x52` 恰好等于取低字节。
    // **解码结果对，机制全错。**
    //
    // 偏离样本 `$0080` 才是探针：它根本不是脸编号，是 `0x80`(face-ctrl 前缀)
    // + 子命令 `0x00`，被 dumper 按 u16 合并写成 `[$0080]`。
    final page = e.page ?? e.message.plain;
    final upto = _indexOfPage(e.message, page);

    // 逐页回放：槽位 0..7 → 脸编号
    final slots = <int, int>{};
    var activeSlot = 0xFF; // `TalkLoadFace` 里 0xFF 会被改成 1
    var expectFaceArg = false;
    for (final seg in e.message.segments.take(upto)) {
      if (seg is! TextControl) continue;
      final sel = seg.faceSlotSelect;
      if (sel != null) {
        activeSlot = sel;
        continue;
      }
      if (seg.isLoadFace) {
        expectFaceArg = true;
        continue;
      }
      if (seg.isFaceSpec) {
        if (!expectFaceArg) {
          // `$0080` 这类：不是脸编号，是 face-ctrl 前缀 —— **跳过**
          continue;
        }
        expectFaceArg = false;
        if (activeSlot == 0xFF) activeSlot = 1; // 与 `TalkLoadFace` 一致
        final fid = seg.faceId;
        if (fid == null) {
          slots.remove(activeSlot);
        } else {
          slots[activeSlot] = fid;
        }
      }
    }

    show(
      text: page,
      virtualSize: virtualSize,
      // 槽位 → 屏幕侧：`gTalkFaceHPosLut = {3,6,9,21,24,27,-8,38}`，
      // 前半（0..2）在左，后半（3..7）在右
      hostFace: _rightmost(slots),
      guestFace: _leftmost(slots),
    );
  }

  /// 槽位表里最靠右的那个脸
  int? _rightmost(Map<int, int> slots) {
    for (final s in const [5, 4, 3, 7, 6, 2, 1, 0]) {
      if (slots.containsKey(s)) return slots[s];
    }
    return null;
  }

  /// 槽位表里最靠左的那个脸
  int? _leftmost(Map<int, int> slots) {
    for (final s in const [0, 1, 2, 6, 3, 4, 5, 7]) {
      if (slots.containsKey(s)) return slots[s];
    }
    return null;
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

/// 淡入/淡出的**表现层**属性。
///
/// ⚠️ 放在 `lib/game` 而不是 `lib/core` ——
/// "白色还是黑色""最终可不可见"是表现层的事，
/// `lib/core` 只保留"往哪个方向淡"这个规则层事实。
extension FadeDirectionView on FadeDirection {
  bool get isWhite => this == FadeDirection.fromWhite ||
      this == FadeDirection.toWhite;

  /// 画面最终是否可见
  bool get endsVisible => this == FadeDirection.fromBlack ||
      this == FadeDirection.fromWhite;
}
