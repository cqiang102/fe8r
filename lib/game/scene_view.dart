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
    // ⚠️ **越大越快**，我原来写反了。
    //
    // 原作参数名是 `q4_speed`（`src/bmlib_08013D88.c:67-77`），是**每帧步进量**：
    // `src/bmlib_08013BAC.c:104-117`  `unk66 -= unk64; blendY = unk66 >> 4;`
    // 初值 0x100 → **帧数 = 0x100 / q4_speed**。
    //
    // 旁证：Fast = 0x40 → 4 帧；Mid = 0x10 → 16 帧；Slow = 0x04 → 64 帧
    // （`src/exact_08013eb8.c:58-60`、`src/exact_08013e98.c:58-60`、
    //   `src/StartSlowLockingFadeFromBlack.c:17`）。
    //
    // 按 60fps 折算成秒。
    final frames = speed <= 0 ? 16.0 : (256.0 / speed).clamp(2.0, 120.0);
    final secs = frames / 60.0;
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
    // 逐页回放。**出处：`src/TalkInterpret.c:140-341`**
    //
    // 三个机制，全部作用于「活动槽」：
    //
    //   `[OpenXXX]`(8..15)  →  SetActiveTalkFace(code - 8)，**只选槽**
    //   `[LoadFace]`(16)+u16 →  载入活动槽，脸号 = u16 - 0x100
    //   `[ClearFace]`(17)   →  清空活动槽
    //   `[$0080]`+下一token →  **0x80 前缀**，下一 token 的值才是子码：
    //                          0x0A..0x11 → MoveTalkFace(active, sub-10) + 改 active
    //                          其它      → 表情/眨眼/数值代入等，与立绘位置无关
    //
    // ⚠️ **`[$0080]` 不是"清空"、也不是脸编号**。我先后错过三次。
    // 它是 dumper 把一个**字节对**（`0x80` + 子码）写成了 u16 token，
    // 所以它**必须和后面那个 token 成对读**。
    //
    // 序章 0x8C3 的真实轨迹（靠这一条才对）：
    //
    //     OpenMidLeft   LoadFace $0152  → slot1 = Fado（x=48，左）
    //     OpenFarFarRight LoadFace $016B → slot7 = 传令兵（x=304，**屏幕外暂存**）
    //     OpenFarFarRight $0080 + 0x0E   → MoveTalkFace(7→4)，即**滑到屏幕内右侧**
    final page = e.page ?? e.message.plain;
    // 用上游给的 token 序号，不再拿文字反查
    final upto = e.upto ?? e.message.segments.length;

    final segs = e.message.segments.take(upto).toList();
    final slots = <int, int>{};
    var activeSlot = 0xFF;
    var pending80 = false;   // 上一个 token 是 $0080 前缀
    var expectFaceArg = false;
    for (final seg in segs) {
      if (seg is! TextControl) {
        pending80 = false;
        // 文字不会打断"等 LoadFace 参数"，但会清掉 0x80 前缀
        continue;
      }

      // ---- 0x80 前缀：当前 token 是**子码** ----
      if (pending80) {
        pending80 = false;
        final sub = seg.codeValue;
        if (sub != null && sub >= 0x0A && sub <= 0x11) {
          // MoveTalkFace(active, sub - 10) + SetActiveTalkFace(sub - 10)
          final dest = sub - 10;
          if (activeSlot != 0xFF && slots.containsKey(activeSlot)) {
            slots[dest] = slots.remove(activeSlot)!;
          }
          activeSlot = dest;
        }
        // 其它子码（表情/眨眼/数值代入）与位置无关，忽略
        continue;
      }

      // ---- $0080：进入前缀态 ----
      if (seg.isFaceSpec && seg.codeValue == 0x0080) {
        pending80 = true;
        continue;
      }

      final sel = seg.faceSlotSelect;
      if (sel != null) {
        activeSlot = sel;
        expectFaceArg = false;   // 位置码会打断"等脸参数"
        continue;
      }
      if (seg.isClearFace) {
        if (activeSlot != 0xFF) slots.remove(activeSlot);
        continue;
      }
      if (seg.isLoadFace) {
        expectFaceArg = true;
        continue;
      }
      if (seg.isFaceSpec) {
        if (!expectFaceArg) continue;
        expectFaceArg = false;
        if (activeSlot == 0xFF) activeSlot = 1;   // 与 `TalkLoadFace` 一致
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

  /// 槽位 → 屏幕 x（**像素，x 是立绘中心**）。
  ///
  /// ## 出处：`src/data/worldmap_gmapunit/dat_worldmap_gmapunit_p680.c:11`
  ///
  /// ```c
  /// int gTalkFaceHPosLut[8] = { 3, 6, 9, 21, 24, 27, -8, 38 };   /* 单位：图块 */
  /// ```
  ///
  /// `src/TalkLoadFace.c:37-58`：`StartFaceAuto(fid, GetTalkFaceHPos(active)*8, 80, ...)`
  /// —— **x 是立绘中心**，包围盒 96×80（`gSprite_Face96x96`），y = 80..160。
  ///
  /// ⚠️ **slot 6 / 7 完全在屏幕外**（x = −64 / 304），它们在原作里是
  /// "先载入再移动进来"的**暂存位** —— 不该直接画。
  ///
  /// 我原来用自造顺序 `[5,4,3,7,6,2,1,0]` 挑"最右"，与真实 x 序不符：
  /// 真实是 `6 < 0 < 1 < 2 < 3 < 4 < 5 < 7`。
  static const faceSlotX = <int, double>{
    0: 24, 1: 48, 2: 72, 3: 168, 4: 192, 5: 216, 6: -64, 7: 304,
  };

  /// 屏幕内的槽位，按 x 从左到右
  static const onScreenSlots = [0, 1, 2, 3, 4, 5];

  /// 最靠右的**可见**立绘
  int? _rightmost(Map<int, int> slots) {
    for (final s in onScreenSlots.reversed) {
      if (slots.containsKey(s)) return slots[s];
    }
    return null;
  }

  /// 最靠左的**可见**立绘
  int? _leftmost(Map<int, int> slots) {
    for (final s in onScreenSlots) {
      if (slots.containsKey(s)) return slots[s];
    }
    return null;
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
