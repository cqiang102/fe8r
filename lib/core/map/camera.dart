// PORT OF: src/bm.c（GetCameraAdjustedX/Y、GetCameraCenteredX/Y、
//                    HandleMoveCameraWithMapCursor）
//          include/bm.h（CAMERA_MARGIN_*）
//
// 战场相机的**取景规则**。
//
// ## 出处一：死区常量（`include/bm.h:5-8`）
//
// ```c
// CAMERA_MARGIN_LEFT   = 16 * 3   = 48
// CAMERA_MARGIN_RIGHT  = 16 * 11  = 176
// CAMERA_MARGIN_TOP    = 16 * 2   = 32
// CAMERA_MARGIN_BOTTOM = 16 * 7   = 112
// ```
//
// ## 出处二：两个不同的"对准"方式（`src/bm.c:343-410`）
//
// `GetCameraAdjustedX`（**不**居中）：只有目标越出死区时才动，
// 把目标顶到死区边界上，**不做 16 像素对齐**。
//
//     result = camera.x;                                  // 默认不动
//     if (camera.x + MARGIN_LEFT > x)                     // 目标偏左
//         result = (x - MARGIN_LEFT < 0) ? 0 : x - MARGIN_LEFT;
//     if (camera.x + MARGIN_RIGHT < x)                    // 目标偏右
//         result = (x - MARGIN_RIGHT > cameraMax.x) ? cameraMax.x : x - MARGIN_RIGHT;
//
// `GetCameraCenteredX`（**居中**）：`(x - 240/2)` 再夹到 `[0, cameraMax]`，
// **并对齐到 16 像素**。
//
// 这两者的区别是实打实的：`CAMERA(14, 0)`（不居中）与
// `CAMERA2(14, 0)`（居中）在同一个位置上算出来的相机**不是同一个值**。
//
// ## 视口与上限（`src/bmmap_08019584.c:74-75`）
//
//     gBmSt.cameraMax.x = gBmMapSize.x * 16 - 240;
//     gBmSt.cameraMax.y = gBmMapSize.y * 16 - 160;
//
// 视口固定 **240×160**（GBA 屏），一格 16 像素。

/// `DISPLAY_WIDTH` / `DISPLAY_HEIGHT`（GBA 屏）
const int screenWidthPx = 240;
const int screenHeightPx = 160;

/// 一格多少像素
const int tilePx = 16;

/// `CAMERA_MARGIN_LEFT`（`include/bm.h:5` `16 * 3`）
const int cameraMarginLeft = tilePx * 3;

/// `CAMERA_MARGIN_RIGHT`（`include/bm.h:6` `16 * 11`）
const int cameraMarginRight = tilePx * 11;

/// `CAMERA_MARGIN_TOP`（`include/bm.h:7` `16 * 2`）
const int cameraMarginTop = tilePx * 2;

/// `CAMERA_MARGIN_BOTTOM`（`include/bm.h:8` `16 * 7`）
const int cameraMarginBottom = tilePx * 7;

/// `gBmSt.cameraMax.x = gBmMapSize.x * 16 - 240`（不足一屏时为 0）
int cameraMaxX(int mapWidthTiles) =>
    (mapWidthTiles * tilePx - screenWidthPx).clamp(0, 1 << 30);

/// `gBmSt.cameraMax.y = gBmMapSize.y * 16 - 160`
int cameraMaxY(int mapHeightTiles) =>
    (mapHeightTiles * tilePx - screenHeightPx).clamp(0, 1 << 30);

/// `GetCameraAdjustedX`（`src/bm.c:343`）—— **不居中**，只保证目标落在死区内
int cameraAdjustedX(int cameraX, int targetX, int cameraMax) {
  var result = cameraX;
  if (cameraX + cameraMarginLeft > targetX) {
    result = targetX - cameraMarginLeft < 0 ? 0 : targetX - cameraMarginLeft;
  }
  if (cameraX + cameraMarginRight < targetX) {
    result = targetX - cameraMarginRight > cameraMax
        ? cameraMax
        : targetX - cameraMarginRight;
  }
  return result;
}

/// `GetCameraAdjustedY`（`src/bm.c:362`）
int cameraAdjustedY(int cameraY, int targetY, int cameraMax) {
  var result = cameraY;
  if (cameraY + cameraMarginTop > targetY) {
    result = targetY - cameraMarginTop < 0 ? 0 : targetY - cameraMarginTop;
  }
  if (cameraY + cameraMarginBottom < targetY) {
    result = targetY - cameraMarginBottom > cameraMax
        ? cameraMax
        : targetY - cameraMarginBottom;
  }
  return result;
}

/// `GetCameraCenteredX`（`src/bm.c:381`）—— 居中、夹在 `[0, cameraMax]`、
/// **对齐到 16 像素**（`& ~0xF`）
int cameraCenteredX(int targetX, int cameraMax) {
  var result = targetX - screenWidthPx ~/ 2;
  if (result < 0) result = 0;
  if (result > cameraMax) result = cameraMax;
  return result & ~0xF;
}

/// `GetCameraCenteredY`（`src/bm.c:397`）
int cameraCenteredY(int targetY, int cameraMax) {
  var result = targetY - screenHeightPx ~/ 2;
  if (result < 0) result = 0;
  if (result > cameraMax) result = cameraMax;
  return result & ~0xF;
}
