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
import 'portrait_component.dart';

/// 对话框的宿主
class SceneView {
  SceneView({required this.onHudChanged});

  /// 显示状态变化时通知外部更新 HUD
  final void Function() onHudChanged;

  /// UI 层 —— 挂在 `camera.viewport` 上，**不是** `world`
  late final PositionComponent layer = PositionComponent();

  DialogueBoxComponent? _box;

  /// 每个槽位上的立绘（**独立于对话框**）
  final Map<int, PortraitComponent> _portraits = {};

  /// 记录一次选择的结果（`TALK_CHOICE_*`），用于 HUD 与调试。
  void noteChoice(int answer) {
    _lastChoice = answer;
    onHudChanged();
  }

  int? _lastChoice;

  int? get lastChoice => _lastChoice;

  /// 当前说话人的槽位（决定气泡尾巴朝向）。
  ///
  /// 出处：`src/scene_080087A4.c` 的 `StartTalkOpen` —— 它把
  /// `speakingFaceSlot` 设成刚打开的那个脸槽。
  int? _speakerSlot;

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
    bool waitingForInput = false,
  }) {
    if (_box != null) {
      layer.remove(_box!);
      _box = null;
    }
    _screenSize = virtualSize;
    if (text == null || text.isEmpty) {
      _syncPortraits(const {});
      onHudChanged();
      return;
    }

    // ⚠️ **对话框在屏幕上方**，不是下面。
    //
    // 原作 `src/scene_080081A0.c:99-163`（`PutTalkBubble`）：
    //   `y = (yAnchor - height) + 1 = 3`（图块）→ **像素 24..72**，
    //   高度 6 图块 = 48px；宽度 = `2 + Div(GetStrTalkLen(...)+7, 8)` 图块
    //   （**随这一页文字长度变化**）；x 跟着说话人走（`StartTalkOpen` 里
    //   `GetTalkFaceHPos(talkFace)`，clamp 到 0..30）。
    //
    // 我原来是"固定 92% 宽、y=0.56..0.84 的方框" —— 位置和形状都不对。
    final boxH = virtualSize.y * (48 / 160);          // 6 图块 = 48px
    final boxY = virtualSize.y * (24 / 160);          // y = 3 图块 = 24px

    // ⚠️ 宽度**随这一页文字长度变化**，不是固定 92%。
    //
    // `src/scene_080087A4.c:23-43`（`StartTalkOpen`）：
    //     proc->unk68 = activeWidth;
    // 而 `activeWidth = 2 + Div(GetStrTalkLen(str, ...) + 7, 8)`
    // （`src/TalkInterpret.c:40-43`，**单位是图块**）。
    // `src/scene_080081A0.c:99-155`（`PutTalkBubble`）用它算气泡的 x 与宽。
    //
    // 「2 + ceil(行长/8)」= 左右各留 1 图块内边距，中间放文字。
    // 每行最多 8 图块 = 64px（`xText = x + 1`，`src/scene_080081A0.c:163`）。
    final linePx = _maxLinePx(text);
    final boxTiles = (2 + ((linePx + 7) ~/ 8)).clamp(6, 28).toDouble();
    final boxW = virtualSize.x * (boxTiles * 8 / 240);
    _box = DialogueBoxComponent(
      text: text,
      hostFaceId: hostFace,
      guestFaceId: guestFace,
      boxWidth: boxW,
      boxHeight: boxH,
      waitingForInput: waitingForInput,
      // 尾巴指向说话人：左侧槽位（x<16 图块）尾巴在左
      tailOnLeft: _speakerSlot == null ||
          (PortraitComponent.slotTileX[_speakerSlot!] ?? 0) < 16,
    )..position = Vector2(virtualSize.x * 0.04, boxY);
    layer.add(_box!);
    onHudChanged();
  }

  Vector2 _screenSize = Vector2.zero();

  /// 这一页最长一行的**像素宽**。
  ///
  /// ⚠️ `GetStrTalkLen` 返回的是**像素**（`src/sub_8008A40.c:244`
  /// `currentLineLen += chrLen`，`chrLen` 来自 `GetCharTextLen`），
  /// 调用方再 `Div(x + 7, 8)` 转成图块。
  ///
  /// 我第一版把"字符数"当成了像素，于是 11 个全角字只算出 5 图块 = 40px，
  /// **文字被裁成「城門が突破さ」**（截图一眼可见）。
  ///
  /// FE 的字体是 12px 高：全角 12px、半角（ASCII）6px。
  static int _maxLinePx(String text) {
    var best = 0;
    var cur = 0;
    for (final rune in text.runes) {
      if (rune == 0x0A) {
        if (cur > best) best = cur;
        cur = 0;
        continue;
      }
      cur += rune < 0x80 ? 6 : 12;
    }
    return cur > best ? cur : best;
  }

  /// 按槽位表同步立绘组件。
  ///
  /// 立绘**不属于对话框** —— 它是独立的一层，位置由
  /// `gTalkFaceHPosLut` 决定（见 `portrait_component.dart`）。
  void _syncPortraits(Map<int, int> slots) {
    if (_screenSize == Vector2.zero()) return;
    // 移除不再需要的
    for (final slot in _portraits.keys.toList()) {
      if (!slots.containsKey(slot)) {
        layer.remove(_portraits.remove(slot)!);
      }
    }
    // 加上新的 / 换图的
    slots.forEach((slot, fid) {
      if (!PortraitComponent.isOnScreen(slot)) return; // 6/7 在屏幕外
      final img = portraitFor(fid);
      if (img == null) return;
      final existing = _portraits[slot];
      if (existing != null && existing.image == img) return;
      if (existing != null) layer.remove(existing);
      final c = PortraitComponent(
        slot: slot,
        image: img,
        screenSize: _screenSize,
      );
      layer.add(c);
      _portraits[slot] = c;
    });
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
    // `0xFFFF`（当前单位的立绘）目前无法解析 —— 记下来而不是静默抹掉
    final unknownFaceSlots = <int>{};
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
        _speakerSlot = sel;
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
        if (seg.isFaceFromActiveUnit) {
          // `0xFFFF` = 取**当前单位**的立绘（`src/TalkLoadFace.c:46-49`），
          // **不是清空**。当前实现没有"当前单位"这个概念，
          // 所以明确记成未知而不是静默抹掉 —— 见 HUD 的"未执行"列表。
          unknownFaceSlots.add(activeSlot);
          continue;
        }
        final fid = seg.faceId;
        if (fid == null) {
          unknownFaceSlots.add(activeSlot);
        } else {
          slots[activeSlot] = fid;
        }
      }
    }

    show(
      text: page,
      virtualSize: virtualSize,
      // 这两个只用于 HUD 显示与占位编号；真正的绘制走 _syncPortraits
      hostFace: _rightmost(slots),
      guestFace: _leftmost(slots),
      // 这一页是靠 `[A]` 结束的 → 画闪烁箭头提示玩家按键
      waitingForInput: e.message.isWaitForKeyAt(upto),
    );
    _syncPortraits(slots);
    if (unknownFaceSlots.isNotEmpty) {
      // 出声：这类槽位没有画出来，不是因为"没有脸"
      assert(() {
        // ignore: avoid_print
        print('  [立绘] 这些槽位用了 \$FFFF（当前单位的立绘），本实现暂不支持：'
            '$unknownFaceSlots');
        return true;
      }());
    }
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

  /// 最靠右的**可见**立绘
  int? _rightmost(Map<int, int> slots) {
    for (final s in PortraitComponent.onScreenSlots.reversed) {
      if (slots.containsKey(s)) return slots[s];
    }
    return null;
  }

  /// 最靠左的**可见**立绘
  int? _leftmost(Map<int, int> slots) {
    for (final s in PortraitComponent.onScreenSlots) {
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
