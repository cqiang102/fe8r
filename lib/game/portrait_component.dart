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
  }) : super(
          size: Vector2(screenSize.x * (96 / 240), screenSize.x * (80 / 240)),
        );

  final int slot;
  final Image image;

  /// 屏幕虚拟分辨率（240×160 一类）
  final Vector2 screenSize;

  /// 槽位 → 屏幕 x（**中心**），单位：图块（8px）
  ///
  /// `gTalkFaceHPosLut[8] = { 3, 6, 9, 21, 24, 27, -8, 38 }`
  static const slotTileX = <int, double>{
    0: 3, 1: 6, 2: 9, 3: 21, 4: 24, 5: 27, 6: -8, 7: 38,
  };

  /// 这个槽位在屏幕上可见吗（6/7 在屏幕外）
  static bool isOnScreen(int slot) => slot >= 0 && slot <= 5;

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
  }
}
