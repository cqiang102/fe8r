// 对话立绘（半身像）。
//
// ## 出处：几何全部来自源码
//
// `src/TalkLoadFace.c:37-58`：
//
// ```c
// faceDisp |= FACE_DISP_KIND(FACE_96x80);
// if (GetTalkFaceHPos(sTalkState->activeFaceSlot) <= 14)
//     faceDisp |= FACE_DISP_FLIPPED;          // ← 左半边镜像
// StartFaceAuto(faceId, GetTalkFaceHPos(active)*8, 80, faceDisp);
// ```
//
// `src/data/worldmap_gmapunit/dat_worldmap_gmapunit_p680.c:11`：
//
// ```c
// int gTalkFaceHPosLut[8] = { 3, 6, 9, 21, 24, 27, -8, 38 };   /* 单位：图块 */
// ```
//
// `src/data/worldmap_gmapunit/dat_worldmap_gmapunit_p676.c:59-70`
// （`gSprite_Face96x96`）：OAM 片 x 覆盖 −48…+48、y 覆盖 0…80
// → **x 是中心，包围盒 96×80**。
//
// 所以（240×160 的 GBA 屏幕）：
//
//     slot 0..2（x = 24/48/72）  左半边，**镜像**
//     slot 3..5（x = 168/192/216）右半边，不镜像
//     slot 6..7（x = −64/304）   **完全在屏幕外** —— 是"先载入再移动进来"的暂存位
//
// ⚠️ 我原来把立绘画成"对话框框角里 20% 宽的小图" —— 位置、尺寸、镜像**全不对**。
// 那条路走不通的根因是：**立绘根本不属于对话框**，它是独立的一层。
import 'dart:ui' show Image, Paint, FilterQuality, Rect, Canvas;

import 'package:flame/components.dart';

/// 一个槽位上的立绘
class PortraitComponent extends PositionComponent {
  PortraitComponent({
    required this.slot,
    required this.image,
    required this.screenSize,
    this.mouthFrames = const [],
    this.xMouth = 0,
    this.yMouth = 0,
  }) : super(
          size: Vector2(screenSize.x * (96 / 240), screenSize.x * (80 / 240)),
        );

  final int slot;
  final Image image;

  /// 嘴型帧（6 帧，每帧 32×16 = 4×2 图块）。
  ///
  /// ## 分组（**关键**）——`src/face_08005EE4.c:64-95`
  ///
  /// ```c
  /// int offsetA = (disp & FACE_DISP_SMILE) ? 0 : 24;   // 微笑 / 普通的基址
  /// offsetA += 16;                                      // 静止时用该组第 3 帧
  /// ...
  /// int offsetB = (disp & FACE_DISP_SMILE) ? 0 : 24;
  /// switch (blinkControl) { case 1: case 3: offsetB += 8; break; case 2: offsetB += 16; break; }
  /// ```
  ///
  /// `imgMouth` 的偏移单位是**图块**（每块 0x20 字节），所以：
  ///
  ///     块  0-7  /  8-15 / 16-23   →  **微笑**的 3 帧（闭 / 半 / 开）
  ///     块 24-31 / 32-39 / 40-47   →  **普通**的 3 帧
  ///
  /// **静止时用该组的第 3 帧**（`+16`），说话时才循环。
  ///
  /// ⚠️ 我第一版把 6 帧当成**一条循环** —— 于是"普通"表情会闪出"微笑"的帧。
  final List<Image> mouthFrames;

  /// 是否微笑（`[ToggleSmile]`，`FACE_DISP_SMILE`）。
  ///
  /// 原作只有**两种**表情：微笑 / 普通（加上说话时嘴动）。
  bool smiling = false;

  /// 该组的 3 帧：微笑用 0-2、普通用 3-5
  List<Image> get _group => mouthFrames.length < 6
      ? mouthFrames
      : (smiling
          ? mouthFrames.sublist(0, 3)
          : mouthFrames.sublist(3, 6));

  /// 没在说话时该用该组的**第 3 帧**（`offsetA + 16` = 该组最后一帧）。
  ///
  /// 等嘴型位置证实之后再接进渲染。
  Image? get staticMouthFrame => _group.length >= 3 ? _group[2] : null;

  /// 嘴在图块坐标系里的位置（来自 `portrait_data[]` 第 5 个字）。
  final int xMouth;
  final int yMouth;

  /// 是否正在"说话"（嘴在动）。
  ///
  /// 由 `[ToggleMouthMove]`(22) 翻转（`src/TalkInterpret.c:130-133`：
  /// `sTalkState->mouthMoveEnabled = 1 - sTalkState->mouthMoveEnabled;`），
  /// 打印每个字符时 `SetTalkFaceMouthMove(activeSlot)`
  /// （`src/scene_08006CA4.c:64-66`）推进一帧。
  bool mouthMoving = false;

  /// 当前嘴型帧
  int _mouthFrame = 0;

  /// 推进嘴型（每次打印一个字符调一次）。
  ///
  /// 原作是在该组的**前两帧**之间切（`blinkControl` 的 1/3 → +8、2 → +16），
  /// 这里用 3 帧循环近似。
  void tickMouth() {
    if (!mouthMoving || mouthFrames.isEmpty) return;
    _mouthFrame = (_mouthFrame + 1) % 3;
  }

  /// 屏幕虚拟分辨率（240×160 一类）
  final Vector2 screenSize;

  /// 槽位 → 屏幕 x（**中心**），单位：图块（8px）
  ///
  /// `gTalkFaceHPosLut[8] = { 3, 6, 9, 21, 24, 27, -8, 38 }`
  static const slotTileX = <int, double>{
    0: 3, 1: 6, 2: 9, 3: 21, 4: 24, 5: 27, 6: -8, 7: 38,
  };

  /// 表情组数：**只有两种**（微笑 / 普通）——`FACE_DISP_SMILE`。
  static const mouthGroupCount = 2;

  /// 每组 3 帧（闭 / 半 / 开）
  static const framesPerMouthGroup = 3;

  /// 屏幕内的槽位（按 x 从左到右）。
  ///
  /// 槽 6/7 的 x 是 −64 / 304 图块 —— **完全在屏幕外**，
  /// 它们是先载入再移动进来的暂存位（序章的传令兵就是这么进场的）。
  static const onScreenSlots = [0, 1, 2, 3, 4, 5];

  /// 这个槽位在屏幕上可见吗
  static bool isOnScreen(int slot) => onScreenSlots.contains(slot);

  /// 是否镜像（`GetTalkFaceHPos <= 14` 图块 → 左半边）
  static bool isFlipped(int slot) => (slotTileX[slot] ?? 99) <= 14;

  /// 像素 x（**中心**）
  double get centerX => (slotTileX[slot] ?? 0) * 8 * (screenSize.x / 240);

  @override
  void onMount() {
    super.onMount();
    // 立绘贴底：y = 80 图块 = 屏幕下半部起点，包围盒 96×80
    position = Vector2(centerX - size.x / 2, screenSize.y * (80 / 160));
  }

  @override
  void render(Canvas canvas) {
    final dst = Rect.fromLTWH(0, 0, size.x, size.y);
    if (isFlipped(slot)) {
      canvas.save();
      canvas.translate(size.x, 0);
      canvas.scale(-1, 1);
      canvas.drawImageRect(
        image,
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
        dst,
        Paint()..filterQuality = FilterQuality.none,
      );
      canvas.restore();
    } else {
      canvas.drawImageRect(
        image,
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
        dst,
        Paint()..filterQuality = FilterQuality.none,
      );
    }

    // ---------------------------------------------------------------------
    // ⚠️ **嘴型覆盖层暂不绘制。**
    //
    // 机制已经查清（`src/face_08005EE4.c:64-95` + `src/face.c:69-82`）：
    // 在 `(xMouth-1, yMouth)` 处覆盖 4×2 图块的嘴，6 帧分「微笑 0-2 /
    // 普通 3-5」两组。素材也提取好了（90 角色 × 6 帧）。
    //
    // **但 `xMouth`/`yMouth` 的来源没有证实。**
    // `struct FaceData` 在反编译项目里没有定义，我只能从
    // `portrait_data[]` 第 5 个字（`0x04030602`）里推。
    //
    // 我一度以为推对了 —— 因为把 `(2,6)` 贴上去"看着差不多"。
    // 但那个实验里**左边有一块明显的杂色，正是嘴画错了位置**，
    // 我把它当成了"tile 选择不准"。
    //
    // 上线之后在真实截图里一眼可见：Fado 的脸颊、士兵的领口都有错位。
    //
    // **判据是"看不出错"，不是"看着差不多"。** 位置没证实之前不画 ——
    // 画错比不画更糟。
    //
    // 下一步（有明确判据）：找到 `struct FaceData` 的真实定义，
    // 或从 `FaceMouth_Loop` 的 `imgMouth` 指针反推字段偏移。
    // ---------------------------------------------------------------------
  }
}
