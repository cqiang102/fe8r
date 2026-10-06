// **主菜单**（`SaveDraw_DrawMainMenuOptions`）—— Flame 组件。
//
// # ⚠️ 这是**主菜单专用**，不是通用菜单
//
// 用户提醒：「原版也有几种不同的菜单，不能强行复用」——
// 见 `docs/菜单盘点.md`。主菜单与附加内容菜单**四处不同**：
//
//   起点 X      48    vs  268
//   居中公式    68 - count*25/2  vs  68 - count*12
//   精灵表      _1    vs  _0
//   光标条件    MAIN_LOOP  vs  PL_SAVEMENU_10
//
// 难度画面则是另一回事（边框 + 右侧说明文字）。
// **共用是结果，不是目标** —— 我上一轮把"抽一个通用组件"当成目标，是错的。
//
// # 设计照源码，实现用 Flame
//
// 原作的主菜单构成（逐条有出处）：
//
// ## 整组垂直居中（`src/savedraw.c:193-197`）
//
// ```c
// int y = 68 - ((int)((SAVE_MENU_PARENT(proc)->unk_31) * 25) >> 1);
// if (y < 2) y = 2;
// ```
//
// ## 行距 25、每项 = **图标 + 标签**两个精灵（`savedraw.c:99-103,205`）
//
// ```c
// void SaveDraw_DrawMainMenuOption(..., int x, int y, u8 spriteIdx, u8 palIdA, u8 palIdB)
// {
//     PutSpriteExt(4, OAM1_X(x),     y,     Sprite_Savedraw_0, OAM2_PAL(palIdA));  // 图标
//     PutSpriteExt(4, OAM1_X(x + 8), y + 8, SpriteArray_SavemenuData_1[spriteIdx], OAM2_PAL(palIdB));
// }
// ```
//
// 调用处 `x = 48`；选中时 `palIdA = 1`、未选中 `palIdA = 6`
// —— **图标分高亮/暗淡**（`:203-210`）。
//
// ## 选中指示 = **一对镜像的括弧，且上下浮动**（`savedraw_080AFE14.c:41-70`）
//
// ```c
// PutSpriteExt(4, xOam1 & 0x1FF,            (yOam0 + yOffsetLut[unk_2a >> 3 & 7]), Sprite_Savedraw_3, 0x3000);
// xOam1 = xOam1_ + 0x9c;                     // +156
// PutSpriteExt(4, (xOam1 & 0x1FF) | 0x1000, ...)   // 0x1000 = 水平翻转
// ```
//
// 左右各一个括弧（右边的是镜像），`yOffsetLut` 是 **8 帧循环**的浮动偏移。
//
// # 换成 Flame 的部分
//
//   `TextComponent`      标签（原作的标签是预渲染 OAM 精灵，取自 `Img_*`）
//   `PolygonComponent`   前面的小图标
//   `Canvas`             括弧（形状特殊，组件表达不了）
//   `update(dt)`         浮动动画（原作按帧计数，这里按时间）


import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

/// 一行菜单项
class MenuEntry {
  const MenuEntry(this.label, {this.enabled = true});

  final String label;

  /// 不可选的项 —— 仍然显示，但图标暗淡、不会被括弧选中
  final bool enabled;
}

class SaveMainMenuComponent extends PositionComponent {
  SaveMainMenuComponent({
    required this.entries,
    required this.selectedIndex,
    required this.tileSize,
    this.panelWidth,
  }) : super(
          size: Vector2(
            panelWidth ?? tileSize * 8,
            tileSize * 1.9 * entries.length,
          ),
        );

  final List<MenuEntry> entries;
  final int selectedIndex;

  /// 一个"图块"多少像素 —— 所有尺寸由它派生
  final double tileSize;

  /// 整块多宽（括弧右端的位置由它决定）
  final double? panelWidth;

  /// GBA 屏是 240x160。所有原作像素值都按这个比例换算。
  static const double gbaW = 240;
  static const double gbaH = 160;

  /// 一个 GBA 像素在这里是多少（图块 = 8 GBA 像素）
  /// ⚠️ **不能叫 `scale`** —— `PositionComponent` 已经有 `scale`（`NotifyingVector2`），
  /// 同名会变成非法 override。`width` 同理（踩过两次）。
  double get unit => tileSize / 8;

  /// 行距：原作 **25 像素**（`savedraw.c:205`）
  double get rowH => 25 * unit;

  /// 起点 X：原作 **48 像素**（`savedraw.c:205`）
  double get originX => 48 * unit;

  /// 图标到标签：原作图标在 `x`、标签在 `x + 8`（`savedraw.c:102`）
  double get iconGap => 8 * unit;

  /// 整组垂直居中：原作 `y = 68 - (count * 25) / 2`，下限 2
  /// （`savedraw.c:193-197`）
  double get groupY {
    var y = 68 - (entries.length * 25) / 2;
    if (y < 2) y = 2;
    return y * unit;
  }

  double _bob = 0;
  final List<TextComponent> _labels = [];

  /// 浮动周期：原作 `unk_2a >> 3 & 7` —— **8 帧一步、8 步一轮**。
  /// 按 60fps 算，一步 8 帧 ≈ 0.133 秒。
  static const double _stepSeconds = 8 / 60;

  @override
  Future<void> onLoad() async {
    for (var i = 0; i < entries.length; i++) {
      final y = groupY + i * rowH;

      // 图标 —— 原作的 `Sprite_Savedraw_0`，选中高亮、未选中暗淡
      final on = entries[i].enabled && i == selectedIndex;
      add(_Triangle(
        position: Vector2(originX, y + rowH * 0.30),
        size: tileSize * 0.55,
        color: !entries[i].enabled
            ? const Color(0xFF4A5464)
            : (on ? const Color(0xFFFFE066) : const Color(0xFF8C98AC)),
      ));

      // 标签
      final t = TextComponent(
        text: entries[i].label,
        textRenderer: TextPaint(
          style: TextStyle(
            color: !entries[i].enabled
                ? const Color(0xFF6A7488)
                : (on ? const Color(0xFFFFF6D0) : const Color(0xFFE4EAF4)),
            fontSize: tileSize * 1.0,
          ),
        ),
        anchor: Anchor.centerLeft,
        position: Vector2(originX + iconGap, y + rowH * 0.5),
        priority: 1,
      );
      add(t);
      _labels.add(t);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    // 浮动：离散的 8 帧台阶（原作就是离散的，不是连续正弦）
    _bob += dt;
    final step = (_bob / _stepSeconds).floor();
    _bobY = _bobTable[step % _bobTable.length];
  }

  double _bobY = 0;

  /// 浮动的台阶表。
  ///
  /// ⚠️ **这是推断的，不是读出来的。**
  /// `SaveDrawCursorYOffsetLut` 在符号表里有地址（`081F57F1`）但**没有 carve 出数据**
  /// （`layout/baseline_syms.d/SaveDrawCursor_Loop-8566b734.tsv`）。
  /// 这里用一个"上下各走一步"的形状近似 —— **形状是推断的，机制（8 帧离散浮动）是源码的**。
  static const List<double> _bobTable = [0, 1, 2, 2, 1, 0, -1, -2, -2, -1];

  double get selectedY => (selectedIndex < 0 || selectedIndex >= entries.length)
      ? 0
      : selectedIndex * rowH;

  @override
  void render(Canvas canvas) {
    final i = selectedIndex;
    if (i < 0 || i >= entries.length || !entries[i].enabled) return;

    // 括弧：原作左端在 `x - 2`、右端在 `x + 156`（`savedraw_080AFE14.c:41-70`）
    final y = groupY + i * rowH + rowH * 0.5 + _bobY * unit;
    final x0 = (originX - 2) * unit;
    final x1 = (originX + 156) * unit;
    final h = rowH * 0.62;
    final w = tileSize * 0.42;

    // 括弧：左边「、右边」（原作是同一个精灵 + 0x1000 水平翻转）
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = tileSize * 0.18
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFFFFE066);

    // 左括弧 「
    canvas.drawPath(
      Path()
        ..moveTo(x0 + w, y - h)
        ..lineTo(x0, y - h * 0.35)
        ..lineTo(x0, y + h * 0.35)
        ..lineTo(x0 + w, y + h),
      p,
    );
    // 右括弧 」—— 镜像
    canvas.drawPath(
      Path()
        ..moveTo(x1 - w, y - h)
        ..lineTo(x1, y - h * 0.35)
        ..lineTo(x1, y + h * 0.35)
        ..lineTo(x1 - w, y + h),
      p,
    );
  }
}

/// 前面的小图标（原作 `Sprite_Savedraw_0`）—— 用 Flame 的多边形
class _Triangle extends PolygonComponent {
  _Triangle({
    required Vector2 position,
    required double size,
    required Color color,
  }) : super(
          [Vector2(0, 0), Vector2(0, size), Vector2(size * 0.85, size / 2)],
          position: position,
          paint: Paint()..color = color,
          priority: 0,
        );
}
