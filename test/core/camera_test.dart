// 战场相机的取景规则（`src/bm.c` + `include/bm.h`）。
//
// ## 为什么必须有这条
//
// 序章王座厅那一幕的取景一直是错的：`CAMERA(14, 0)` 是**占位符**，
// 所以镜头停在地图中央 —— 用户说的「背景地图应该是王宫里」，
// 一半是地图（对），一半是**取景**（不对）。
//
// 相机有两种"对准"，源码里是两个函数，**结果不一样**，很容易混：
//
//   `CAMERA(x, y)`  → `GetCameraAdjustedX/Y`（`src/bm.c:343-379`）
//                     只在目标越出死区时移动，**不做 16 像素对齐**
//   `CAMERA2(x, y)` → `GetCameraCenteredX/Y`（`src/bm.c:381-410`）
//                     居中、夹在 `[0, cameraMax]`、**对齐到 16 像素**
//
// 死区（`include/bm.h:5-8`）：左右 48 / 176，上下 32 / 112。
import 'package:fe8r/core/core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('常量（`include/bm.h:5-8`）', () {
    test('死区是 16*3 / 16*11 / 16*2 / 16*7', () {
      expect(cameraMarginLeft, 48);
      expect(cameraMarginRight, 176);
      expect(cameraMarginTop, 32);
      expect(cameraMarginBottom, 112);
    });

    test('视口 240×160、一格 16 像素', () {
      expect(screenWidthPx, 240);
      expect(screenHeightPx, 160);
      expect(tilePx, 16);
    });

    test('cameraMax = 地图像素 - 视口（不足一屏为 0）', () {
      // `src/bmmap_08019584.c:74-75`
      expect(cameraMaxX(22), 22 * 16 - 240); // 112
      expect(cameraMaxY(28), 28 * 16 - 160); // 288
      expect(cameraMaxX(15), 0); // 序章可玩地图正好一屏
      expect(cameraMaxY(10), 0);
    });
  });

  group('★ GetCameraAdjusted（`CAMERA`，不居中）', () {
    test('目标在死区内 → 相机**不动**', () {
      // 相机 96，死区 x ∈ [96+48, 96+176] = [144, 272]
      expect(cameraAdjustedX(96, 200, 112), 96);
      expect(cameraAdjustedX(96, 144, 112), 96, reason: '正好在左边界上');
    });

    test('目标在死区左侧 → 顶到左边界', () {
      expect(cameraAdjustedX(96, 100, 112), 100 - 48);
    });

    test('目标在死区右侧 → 顶到右边界', () {
      expect(cameraAdjustedX(0, 300, 112), 112, reason: '超过 cameraMax 就夹住');
      expect(cameraAdjustedX(0, 200, 400), 200 - 176);
    });

    test('左边界夹到 0（不会负数）', () {
      expect(cameraAdjustedX(0, 10, 112), 0);
    });

    test('★ 序章王座厅那一幕：y 从 80 被顶到 0', () {
      // `LOMA(0x10)` 的槽 0xB 相机是 (14,10) → y = 160-80 = 80
      // 之后脚本 `CAMERA(0xE, 0)` 要把镜头压到王座上
      final afterLoma = cameraCenteredY(10 * 16, cameraMaxY(28));
      expect(afterLoma, 80);
      final afterCamera = cameraAdjustedY(afterLoma, 0 * 16, cameraMaxY(28));
      expect(afterCamera, 0, reason: '王座在 y=0 附近，镜头必须上去');
      // x 已经在死区内 → 不动
      expect(cameraAdjustedX(96, 14 * 16, cameraMaxX(22)), 96);
    });
  });

  group('GetCameraCentered（`CAMERA2`，居中）', () {
    test('居中、对齐 16 像素、夹在 [0, cameraMax]', () {
      expect(cameraCenteredX(224, 112), (224 - 120) & ~0xF); // 96
      expect(cameraCenteredY(160, 288), (160 - 80) & ~0xF); // 80
      expect(cameraCenteredX(0, 112), 0);
      expect(cameraCenteredX(1000, 112), 112, reason: '夹到 cameraMax');
    });

    test('★ 与 Adjusted **不是同一个值**（这就是两者必须分开的理由）', () {
      // 相机在 96，目标居中位置 (14,10)
      final adj = cameraAdjustedX(96, 224, 112); // 死区内 → 96
      final ctr = cameraCenteredX(224, 112); // 104 & ~0xF = 96
      expect(adj, 96);
      expect(ctr, 96);
      // 换一个目标就分道扬镳了：
      expect(cameraAdjustedX(0, 224, 400), 224 - 176); // 48，不对齐
      expect(cameraCenteredX(224, 400), 96); // 对齐过
      expect(cameraAdjustedX(0, 224, 400), isNot(cameraCenteredX(224, 400)));
    });
  });
}
