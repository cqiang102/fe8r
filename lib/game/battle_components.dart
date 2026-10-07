// 表现层：把 `lib/core` 的语义状态画出来。
//
// ## 这里不做的事
//
// **不在渲染层做任何规则判断。** 能不能选中、能走到哪、哪些格子高亮——
// 全部由 `lib/core` 的 `FlowMachine` 决定，这里只负责"把它的结论画出来"。
//
// 这是技术方案 §4.3「语义形式原则」在表现层的落地：
// 一旦渲染层开始自己判断规则（比如"这里顺手判一下阵营"），
// 规则就有了第二份实现，两份迟早会不一致——而且是很难查的那种不一致。
//
// ## M5 阶段的取舍
//
// 单位暂时画成**色块 + 边框**，不是精灵图。美术管线（M11）还没做，
// 现在画占位图只会掩盖"位置/层级/交互"这些真正需要先验证的东西。
// 地形沿用 M0 就验证过的 Tiled 地图。


import 'package:fe8r/core/core.dart';
import 'dart:ui' show Image;

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
// `ClipComponent` 的 `ShapeBuilder` 要求 Flame 的 `Shape`，
// 具体形状（`Rectangle`）在 experimental 里 —— 这是官方文档给的用法。
import 'package:flame/experimental.dart' show Rectangle;
import 'package:flutter/painting.dart';

/// 一个单位在地图上的表现。
class UnitComponent extends PositionComponent {
  UnitComponent({
    required this.unit,
    required this.tileSize,
    required this.isSelected,
    required this.isActive,
  }) : super(size: Vector2.all(tileSize));

  final double tileSize;

  /// ⚠️ **可变**：组件持久存在，状态变化时更新它而不是重建组件。
  ///
  /// 原来是 `final`（不可变快照），于是 `BattleView` 每次都得把整棵
  /// 组件树拆掉重建 —— 那是把 Flame 当画图 API 用。
  /// 组件本该有自己的状态与生命周期。
  MapUnit unit;

  bool isSelected;

  /// 是否属于当前行动阵营
  bool isActive;

  /// 把新的快照灌进来（组件本身不重建）。
  ///
  /// ⚠️ **不直接设 position** —— 位置交给 [moveTo]，那里用 Flame 的
  /// `MoveToEffect` 做补间。直接赋值会让"逻辑上已经走了格、画面上瞬移"
  /// 这个现象无法消除。
  void sync({
    required MapUnit next,
    required bool selected,
    required bool active,
  }) {
    unit = next;
    isSelected = selected;
    isActive = active;
  }

  /// 平滑移动到目标位置。
  ///
  /// 用 Flame 的 `MoveToEffect` 而不是自己 `dt` 累加 ——
  /// 白拿 pause / reset / onComplete，且与光标闪烁风格统一。
  void moveTo(Vector2 destination, {double seconds = 0.18, bool instant = false}) {
    // 先把上一个移动效果清掉：不清会两个效果同时改 position，抖。
    removeAll(children.whereType<MoveToEffect>().toList());
    if (instant || seconds <= 0) {
      position = destination;
      return;
    }
    add(MoveToEffect(destination, EffectController(duration: seconds)));
  }

  @override
  void render(Canvas canvas) {
    // 三个阵营用三套颜色。注意用的是 `factionBit`（0x80）而不是完整 faction，
    // 与 `PhaseRules.areUnitsAllied` 的判据保持一致。
    final Color base;
    if (unit.factionBit == Faction.red) {
      base = const Color(0xFFB44A3C); // 敌：红
    } else if (unit.factionBit == Faction.green) {
      base = const Color(0xFF3F8F4A); // 友军 NPC：绿
    } else {
      base = const Color(0xFF3A6FB4); // 我方：蓝
    }

    final rect = Rect.fromLTWH(1, 1, size.x - 2, size.y - 2);
    final paint = Paint()..color = base;

    // 已行动的单位画成半透明 —— 一眼能看出还剩谁没动
    if (unit.hasActed) {
      paint.color = base.withValues(alpha: 0.35);
    }

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.deflate(2), const Radius.circular(3)),
      paint,
    );

    // 边框：选中 > 当前阵营 > 普通
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = isSelected ? 2.5 : 1.5;
    if (isSelected) {
      stroke.color = const Color(0xFFFFE066);
    } else if (isActive && !unit.hasActed) {
      stroke.color = const Color(0xFFFFFFFF);
    } else {
      stroke.color = const Color(0x66000000);
    }
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.deflate(2), const Radius.circular(3)),
      stroke,
    );

    // 血量条（底部细条）
    if (unit.maxHp > 0) {
      final hpFrac = (unit.hp / unit.maxHp).clamp(0.0, 1.0);
      final barY = size.y - 4.5;
      canvas.drawRect(
        Rect.fromLTWH(3, barY, size.x - 6, 2.5),
        Paint()..color = const Color(0x88000000),
      );
      canvas.drawRect(
        Rect.fromLTWH(3, barY, (size.x - 6) * hpFrac, 2.5),
        Paint()
          ..color = hpFrac > 0.5
              ? const Color(0xFF6FD36F)
              : (hpFrac > 0.25
                  ? const Color(0xFFE0C24A)
                  : const Color(0xFFD05050)),
      );
    }
  }
}

/// 光标
class CursorComponent extends PositionComponent with HasPaint {
  CursorComponent({required double tileSize})
      : super(size: Vector2.all(tileSize));

  @override
  Future<void> onLoad() async {
    // 呼吸式闪烁交给 Flame 的 `OpacityEffect`，不再自己 `_t += dt` + sin 手算。
    //
    // 用 Effect 白拿的能力：pause / reset / onComplete，
    // 而且和项目其它动画（移动补间）风格统一。
    //
    // `OpacityEffect` 需要 `OpacityProvider` —— `HasPaint` 就提供了它。
    add(OpacityEffect.to(
      0.55,
      EffectController(duration: 0.4, infinite: true, alternate: true),
    ));
  }

  @override
  void render(Canvas canvas) {
    // 圆角框：Flame 没有圆角矩形组件，手绘有理由。
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.x, size.y).deflate(0.5),
        const Radius.circular(3),
      ),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0xFFFFE066),
    );
  }
}

/// 移动范围高亮
class MovementRangeComponent extends PositionComponent {
  MovementRangeComponent({
    required this.range,
    required this.tileSize,
  }) : super(size: Vector2(range.width * tileSize, range.height * tileSize));

  final MovementRange range;
  final double tileSize;

  @override
  void render(Canvas canvas) {
    final fill = Paint()..color = const Color(0x553A6FB4);
    final edge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = const Color(0x883A6FB4);

    for (var y = 0; y < range.height; y++) {
      for (var x = 0; x < range.width; x++) {
        if (!range.canReach(x, y)) continue;
        final r = Rect.fromLTWH(x * tileSize, y * tileSize, tileSize, tileSize);
        canvas.drawRect(r, fill);
        // 只在边界画框，内部不画 —— 否则整片范围会变成网格噪点
        if (!range.canReach(x - 1, y) ||
            !range.canReach(x + 1, y) ||
            !range.canReach(x, y - 1) ||
            !range.canReach(x, y + 1)) {
          canvas.drawRect(r.deflate(0.5), edge);
        }
      }
    }
  }
}

/// 行动菜单（待机 / 攻击）。
///
/// 画在地图上的单位旁边，而不是屏幕角落——原版就是这样，
/// 而且"菜单跟着单位走"能避免玩家看错是哪个单位在行动。
/// 战斗行动菜单。
///
/// ⚠️ **这是独立的实现，不与其他菜单共用组件。**
/// 原版的战斗行动菜单和存档菜单是**两套不同的子系统**
/// （见 `docs/菜单盘点.md`）—— 我曾经把它们抽成一个"通用菜单"，
/// 那是把两边的差异抹掉。
class ActionMenuComponent extends PositionComponent {
  ActionMenuComponent({
    required this.options,
    required this.selectedIndex,
    required this.tileSize,
  }) : super(size: Vector2(tileSize * 2.6, tileSize * options.length));

  final List<ActionOption> options;
  final int selectedIndex;
  final double tileSize;

  @override
  Future<void> onLoad() async {
    // 选中行的高亮用 `RectangleComponent`，不手绘
    add(RectangleComponent(
      position: Vector2(0, selectedIndex * tileSize),
      size: Vector2(size.x, tileSize),
      paint: Paint()..color = const Color(0x66FFE066),
      priority: 0,
    ));

    // 每行文字用 `TextComponent` —— 它自己量尺寸、自己按 anchor 定位
    for (var i = 0; i < options.length; i++) {
      add(TextComponent(
        text: options[i].label,
        textRenderer: TextPaint(
          style: TextStyle(
            color: i == selectedIndex
                ? const Color(0xFFFFE066)
                : const Color(0xFFD8DEE9),
            fontSize: tileSize * 0.52,
          ),
        ),
        anchor: Anchor.centerLeft,
        position: Vector2(4, i * tileSize + tileSize / 2),
        priority: 1,
      ));
    }
  }

  @override
  void render(Canvas canvas) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.x, size.y),
        const Radius.circular(3),
      ),
      Paint()..color = const Color(0xE0101820),
    );
  }
}

/// 攻击目标的标记（准星）
class TargetMarkerComponent extends PositionComponent {
  TargetMarkerComponent({required double tileSize})
      : super(size: Vector2.all(tileSize));

  @override
  void render(Canvas canvas) {
    final r = Rect.fromLTWH(0, 0, size.x, size.y).deflate(1.5);
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..color = const Color(0xFFFF5A5A);
    canvas.drawRRect(
      RRect.fromRectAndRadius(r, const Radius.circular(3)),
      p,
    );
    // 两条对角线，让"这是攻击目标"和"这是普通光标"一眼可分
    canvas.drawLine(r.topLeft, r.bottomRight, p..strokeWidth = 1.5);
    canvas.drawLine(r.topRight, r.bottomLeft, p);
  }
}

/// 对话框。
///
/// **渲染层不做任何剧情判断** —— 显示哪段文字、要不要继续等，
/// 全部由 `lib/core/event` 的 VM 决定。这里只负责把
/// `EventPresentation` 画出来。
///
/// 立绘/背景暂时用色块 + 文字占位：真实素材属于 M11 美术管线，
/// 现在画占位图只会掩盖"引擎对不对"这个真正要验证的东西。
/// 对话框：**GBA 风格的底框 + Flame 的 [TextBoxComponent] 负责文字**。
///
/// ## 为什么不自己画文字
///
/// 第一版这里是一个手写的 `PositionComponent`：`Canvas.drawRRect` 画框、
/// `TextPainter` 自己折行、自己算能放几行。
/// **那些全是 Flame 已经做好了的**：
///
///   * `TextBoxComponent` —— 自动折行、自动重排（`maxWidth` 变了会 reflow）
///   * `TextBoxConfig.timePerChar` —— **逐字显示**（原作就是这么演的）
///   * `TextPaint` —— 文字样式与渲染
///
/// 我手写那一版在两个地方翻过车：抹掉换行导致整段变一行、
/// 算行数把文字算到一个字都不显示。**这些坑 Flame 已经填过了。**
///
/// 这里只保留真正需要自己做的事：**画 GBA 那个底框**
/// （将来换成九宫格贴图 `NineTileBoxComponent`）。
class DialogueBoxComponent extends PositionComponent {
  DialogueBoxComponent({
    required this.text,
    required this.hostFaceId,
    required this.guestFaceId,
    this.hostPortrait,
    this.guestPortrait,
    required this.boxWidth,
    required this.boxHeight,
    this.timePerChar = 0.02,
    this.waitingForInput = false,
    this.tailOnLeft = true,
  }) : super(size: Vector2(boxWidth, boxHeight));

  final String text;
  final int? hostFaceId;
  final int? guestFaceId;

  /// 立绘图像（由 `SceneView` 从 `tools/pipeline/out/portraits/` 预加载）。
  ///
  /// 为 null 时退回"编号占位"—— 数据管线没跑或该脸编号没名字时。
  final Image? hostPortrait;
  final Image? guestPortrait;
  final double boxWidth;
  final double boxHeight;

  /// 是否正在等玩家按键（`[A]`）。为真时画**闪烁箭头**。
  ///
  /// 出处：`src/scene_080079AC.c:98-112`（`TalkWaitForInput_OnIdle`）——
  /// 每 2 帧取一次 `gPressKeyArrowSpriteLut[frame]`，
  /// 即在对话框右下角画一个**闪烁的向下箭头**。
  ///
  /// ⚠️ 我原来完全没有这个提示 —— 玩家不知道"该按键了"。
  final bool waitingForInput;

  /// 气泡尾巴在左边还是右边。
  ///
  /// 出处：`src/scene_080081A0.c` 的 `PutTalkBubble`
  ///   `kind = xAnchor < 16 ? 0 : 1;`
  /// 其中 `xAnchor = GetTalkFaceHPos(talkFace)`（图块）。
  /// slot 0..2 的 x 是 3/6/9（< 16）→ **尾巴在左**；
  /// slot 3..5 是 21/24/27（≥ 16）→ **尾巴在右**。
  ///
  /// 尾巴本身是 2×2 图块，放在气泡**下方**（y = 气泡底 = 72px），
  /// 指向说话人所在的那一侧 —— `src/PutTalkBubbleTail.c:23-53`
  /// （kind 0/1 是左右镜像的一对）。
  final bool tailOnLeft;

  PolygonComponent? _arrow;

  /// 逐字显示的速度（秒/字）。0 表示一次性显示。
  final double timePerChar;

  late final TextBoxComponent _textBox;

  @override
  Future<void> onLoad() async {
    final m = (size.y * 0.10).clamp(6.0, 16.0);
    final fontSize = (size.y * 0.13).clamp(11.0, 18.0);
    _textBox = TextBoxComponent(
      text: text,
      textRenderer: TextPaint(
        style: TextStyle(
          color: const Color(0xFFF0F4FA),
          fontSize: fontSize,
          height: 1.3,
        ),
      ),
      boxConfig: TextBoxConfig(
        // `maxWidth` 会自动折行并 reflow —— 不用自己算
        maxWidth: size.x - m * 2,
        margins: EdgeInsets.all(m),
        // 逐字显示，像原作
        timePerChar: timePerChar,
      ),
      size: size.clone(),
    );

    // ⚠️ 必须**裁进框内**。
    //
    // `TextBoxComponent` 会按内容自己撑高（`updateBounds`），
    // 文字比框高时就画到框外面去（截图里第三行压到了边框上）。
    // Flame 自带 `ClipComponent` 正是干这个的。
    final clip = ClipComponent(
      // ShapeBuilder 的签名是 `Shape Function(Vector2 size)`，
      // 返回的是 Flame 的 `Shape`（用 `Rectangle`，圆角靠底框自己画）
      builder: (s) => Rectangle.fromRect(Offset.zero & s.toSize()),
      size: Vector2(size.x - 8, size.y - 8),
      position: Vector2(4, 4),
      priority: 1,
      children: [_textBox..position = Vector2(m - 2, m - 2)],
    );
    add(clip);

    // 气泡尾巴（指向说话人）
    final t = size.y * 0.14;
    final tailX = tailOnLeft ? size.x * 0.06 : size.x * 0.94 - t;
    add(PolygonComponent(
      [
        Vector2(0, 0),
        Vector2(t, 0),
        Vector2(tailOnLeft ? t * 0.15 : t * 0.85, t * 1.3),
      ],
      position: Vector2(tailX, size.y - 1),
      paint: Paint()..color = const Color(0xE0101820),
      priority: -1,
    ));

    // 等待按键的闪烁箭头（右下角）
    if (waitingForInput) {
      // 原作的 `gPressKeyArrowSpriteLut` 是**向下的箭头**精灵，
      // 这里用三角形近似（`PolygonComponent` + 三个顶点）。
      final s = size.x * 0.028;
      _arrow = PolygonComponent(
        [
          Vector2(0, 0),
          Vector2(s, 0),
          Vector2(s / 2, s * 0.8),
        ],
        position: Vector2(size.x * 0.94, size.y * 0.70),
        paint: Paint()..color = const Color(0xFFFFE066),
        priority: 2,
      );
      // 用 Flame 的 `OpacityEffect` 做闪烁（`duration: 0.25` × 交替 ≈ 2 帧 @60fps 的观感）
      _arrow!.add(OpacityEffect.to(
        0.15,
        EffectController(duration: 0.25, infinite: true, alternate: true),
      ));
      add(_arrow!);
    }


  }

  @override
  void render(Canvas canvas) {
    // 立绘占位：左右各一个色块 + 编号
    // NOTE: portraits are NOT drawn here - they are a separate layer
    // (portrait_component.dart), positioned by gTalkFaceHPosLut.

    final box = Rect.fromLTWH(0, 0, size.x, size.y);
    canvas.drawRRect(
      RRect.fromRectAndRadius(box, const Radius.circular(4)),
      Paint()..color = const Color(0xF0101820),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(box.deflate(1), const Radius.circular(4)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0xFF8FA8C8),
    );
  }


}

// ---------------------------------------------------------------------------
// 章节标题卡（`MNC2` 换章之后、地图淡入之前）
//
// 出处：`src/ChapterIntro_DrawChapterTitle.c:23-37`
//
//   BG_Fill(gBG0TilemapBuffer, TILEREF(0x280, 1));
//   titleId = GetChapterTitleWM(&gPlaySt);
//   DrawChapterTitleStrEx_jp(TILEMAP_LOCATED(gBG0TilemapBuffer, 3, 9), 5, titleId);
//
// 标题字符串画在**图块 (3,9)** = 像素 (24,72)。
//
// ⚠️ 底色图（`_PutChapterTitleGfx` 的整屏图块）**没有移植** ——
// 这里用纯色底代替，字符串是真数据。
// ---------------------------------------------------------------------------

/// 章节标题卡：整屏底色 + 标题字符串（图块 (3,9)）
class ChapterTitleCardComponent extends PositionComponent {
  ChapterTitleCardComponent({
    required this.title,
    required Vector2 size,
  }) : super(size: size.clone());

  final String title;

  @override
  Future<void> onLoad() async {
    add(RectangleComponent(
      size: size.clone(),
      paint: Paint()..color = const Color(0xFF0B0F14),
      priority: 0,
    ));

    // 原作画在**图块 (3,9)**：像素 (24, 72)
    final text = TextComponent(
      text: title,
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 16,
          color: Color(0xFFF2E6C8),
          fontFamily: 'monospace',
        ),
      ),
      position: Vector2(24, 72),
      priority: 1,
    );
    add(text);
  }
}

// ---------------------------------------------------------------------------
// 地图菜单面板（START 打开，`gMapMenuDef`）
//
// 几何**全部来自源码**，不给这里留"我摆的"这类自由度：
//
// * 面板矩形 `gMapMenuDef.rect = 0x00060201` → x=1 / y=2 / w=6 / h=0
//   （`src/data/frontier_df4_uistuff/frontier_df4_uistuff.c:12403-12412`）
// * 左右分侧 `if (xSubject < 120) rect.x = xTileRight;` —— 注意 `xSubject` 是
//   **光标的屏幕像素 x**（`src/exact_0804f924.c:43-55`，调用点
//   `src/playerphase_0801C5A8.c:110` 传 `cursorTarget.x - camera.x`）
// * 条目位置与**行距**、面板高度：`src/StartMenuCore.c:59-98`
//
//     xTileInner = rect.x + 1;  yTileInner = rect.y + 1;
//     每个显示出来的条目：item->xTile = xTileInner; item->yTile = yTileInner;
//                         yTileInner += 2;              // ★ 一行 2 个 UI 图块 = 16px
//     if (rect.y + rect.h < yTileInner) proc->rect.h = yTileInner + 1 - rect.y;
//
// 三者都算在 `lib/core/flow/map_menu.dart` 的 `mapMenuLayout()` 里（纯函数、有测试），
// 这里只负责画出来。
//
// ⚠️ 上一版这里用的是"1 图块/行"（沿用了行动菜单的习惯），面板高度只有应有的一半；
// 而且把**地图图块坐标**当成像素去比 120，导致左侧那套 x 永远走不到。
// 两处都是"照源码重算"之后才对上的。
//
// 单位说明：UI 图块 = 8px（GBA 的 BG 图块），地图图块 = 16px。
// 一屏是 30×20 个 UI 图块，所以 `tileSize = 屏高 / 20`。
// ---------------------------------------------------------------------------

/// 地图菜单面板（`MapMenuLayout` 的画法）
class MapMenuComponent extends PositionComponent {
  MapMenuComponent({
    required this.layout,
    required this.selectedIndex,
    required this.tileSize,
  }) : super(
          size: Vector2(
            tileSize * layout.w,
            tileSize * layout.h,
          ),
        );

  /// 由 `mapMenuLayout()` 算好的几何（UI 图块）
  final MapMenuLayout layout;

  /// `MenuProc::itemCurrent`
  final int selectedIndex;

  /// 一个 **UI 图块**（8px）在屏幕上的像素尺寸
  final double tileSize;

  /// 面板左上角在屏幕上的像素坐标
  static Vector2 originFor(MapMenuLayout layout, double tileSize) =>
      Vector2(layout.x * tileSize, layout.y * tileSize);

  @override
  Future<void> onLoad() async {
    final rows = layout.rows;
    if (selectedIndex >= 0 && selectedIndex < rows.length) {
      final sel = rows[selectedIndex];
      add(RectangleComponent(
        // 行内框：从 item->yTile 起，**2 个 UI 图块高**（一行字 8px + 间距 8px）
        position: Vector2(0, (sel.yTile - layout.y) * tileSize),
        size: Vector2(size.x, tileSize * 2),
        paint: Paint()..color = const Color(0x66FFE066),
        priority: 0,
      ));
    }
    for (var i = 0; i < rows.length; i++) {
      final r = rows[i];
      final disabled = r.entry.isDisabled;
      add(TextComponent(
        text: r.entry.item.label,
        textRenderer: TextPaint(
          style: TextStyle(
            // `Menu_Draw` 的颜色语义：选中 = 高亮色，`MENU_DISABLED` = 灰
            color: i == selectedIndex
                ? const Color(0xFFFFE066)
                : (disabled
                    ? const Color(0xFF6B7280)
                    : const Color(0xFFD8DEE9)),
            fontSize: tileSize * 0.9,
          ),
        ),
        anchor: Anchor.centerLeft,
        // `item->xTile = rect.x + 1` ⇒ 文字比面板左边缘内缩 **1 个 UI 图块**
        position: Vector2(
          (r.xTile - layout.x) * tileSize,
          (r.yTile - layout.y) * tileSize + tileSize,
        ),
        priority: 1,
      ));
    }
  }

  @override
  void render(Canvas canvas) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.x, size.y),
        const Radius.circular(3),
      ),
      Paint()..color = const Color(0xE0101820),
    );
  }
}
