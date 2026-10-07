// PORT OF: src/player_interface_0808F2C0.c:68-78（`unitDisplayType` 决定开哪个：
//            0 ⇒ `gProcScr_UnitDisplay_MinimugBox`、1 ⇒ `gProcScr_UnitDisplay_Burst`）
//          src/player_interface_0808EFC4.c:30-70（`MMB_Loop_Display`：
//            显示的是**光标下的单位** `GetUnit(gBmMapUnit[cursor.y][cursor.x])`）
//          src/player_interface_0808E8CC.c（`DrawUnitMapUi`：名字 `nameTextId` +
//            Q 版头像 `GetUnitMiniPortraitId` + HP/道具）
//          include/types.h:144（`unitDisplayType:2`）
//
// ⚠️ **未移植**：
//   * 滑入/滑出的动画（`MMB_Loop_SlideIn/SlideOut` 是**象限 LUT + 逐帧 tile 宽度**，
//     `sPlayerInterfaceConfigLut[quadrant].xMinimug/yMinimug` —— 帧数与位移都没解出来，
//     不编）；
//   * **象限翻转**（`GetCursorQuadrant` 决定窗口贴哪边）—— 我们固定贴底部；
//   * Q 版头像绘制（素材接线待做）；
//   * `unitDisplayType == 1`（Burst 式）**未实现**。

/// `unitDisplayType`（`include/types.h:144`，2 位）
enum UnitDisplayMode {
  /// 0：小窗口（名字 + HP + 道具）
  minimug,

  /// 1：Burst 式（**未实现**）
  burst,

  /// 2/3：不显示
  none,
}

UnitDisplayMode unitDisplayModeOf(int unitDisplayType) =>
    switch (unitDisplayType) {
      0 => UnitDisplayMode.minimug,
      1 => UnitDisplayMode.burst,
      _ => UnitDisplayMode.none,
    };

/// 光标下的单位该不该显示小窗口
///
/// 出处：`MMB_Loop_Display` 第一句就是 `GetUnit(gBmMapUnit[cursor.y][cursor.x])`，
/// `unit == NULL` 直接 return ⇒ **光标下没有单位就不显示**。
bool shouldShowMinimug({
  required int unitDisplayType,
  required bool hasUnitUnderCursor,
}) =>
    hasUnitUnderCursor && unitDisplayModeOf(unitDisplayType) == UnitDisplayMode.minimug;
