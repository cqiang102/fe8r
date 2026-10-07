// PORT OF: src/playerphase_0801C5A8.c:105-160（START 打开地图菜单）
//          src/exact_0804f924.c:43-55（`StartOrphanMenuAdjusted` 的左右分侧）
//          src/StartMenuCore.c:30-98（★ 条目筛选、行距、面板高度都在这）
//          include/uimenu.h:24-58（`MenuItemDef` / `MenuDef`）:93-99（`MENU_*`）
//          src/data/frontier_df4_uistuff/frontier_df4_uistuff.c:12166-12250
//              （`gMapMenuDef` 的 8 条 `MenuItemDef`，日版 carve 出来的原始 u32 数组）
//          src/menu_def.c:154-171（8 条标签的 rodata 原文）
//          src/bmmenu_080225C4.c:61-80（`CommandEffectEndPlayerPhase` /
//              `MapMenu_UnitCommand` / `MapMenu_OptionsCommand`）
//          src/MapMenu_StatusCommand.c:50-54、src/MapMenu_RecordsCommand.c:50-54、
//          src/bmmenu_080226AC.c:61-66（`MapMenu_GuideCommand`）
//          src/bmmenu_08024C7C.c:61-75（退却）、src/masked_0802257c.c:61-67（中断可用性）
//          src/MapMenu_SuspendCommand.c:50-60（中断的 `MENU_DISABLED` 分支）
//          src/MapMenu_IsGuideCommandAvailable.c:51-56
//          src/MapMenu_IsRecordsCommandAvailable.c:51-77
//          src/bmguide_080D2C48.c:47-66（`IsGuideLocked`）
//
// # 两种回合结束之一：**主动选择「終了」**
//
// 原作不是"按一个键就结束回合"，而是：
//
// ```c
// // src/playerphase_0801C5A8.c:141
// if ((gKeyStatusPtr->newKeys & START_BUTTON) && !(gKeyStatusPtr->heldKeys & SELECT_BUTTON)) {
//     ...
//     Proc_Goto(proc, 9);
//     return;
// }
// ```
//
// 菜单本体：`StartOrphanMenuAdjusted(&gMapMenuDef, gBmSt.cursorTarget.x - gBmSt.camera.x, 1, 0x17)`
// （`src/playerphase_0801C5A8.c:110`）—— 第 2 个参数是**光标的屏幕像素 x**，
// 第 3/4 个参数是"画左边用 1、画右边用 0x17"两个候选 x。
//
// ```
// struct MenuRect rect = def->rect;       // gMapMenuDef.rect = 0x00060201 → x=1 y=2 w=6 h=0
// if (xSubject < 120) rect.x = xTileRight;   // 0x17
// else                rect.x = xTileLeft;    // 1
// ```
//
// ⚠️ 这里是**像素**（`cursorTarget.x - camera.x`），阈值 120 = 240/2。
// 之前我拿"地图图块坐标"去比 120，于是 `rect.x` 永远取 0x17、左边那套是死代码。
//
// # 条目顺序（**照数组顺序，不是照我猜的**）
//
// | # | `gMenuStr` | 标签 | overrideId | color | nameMsg | helpMsg | 可用性 | onSelected |
// |---|---|---|---|---|---|---|---|---|
// | 1 | `29C` | 部隊 | 0x6E | 0 | 0x0627 | 0x0662 | `MenuAlwaysEnabled` | `MapMenu_UnitCommand` |
// | 2 | `294` | 状況 | 0x6F | 0 | 0x0621 | 0x0663 | `MenuAlwaysEnabled` | `MapMenu_StatusCommand` |
// | 3 | `28C` | 辞書 | 0x74 | 4 | 0x0629 | 0x0668 | `MapMenu_IsGuideCommandAvailable` | `MapMenu_GuideCommand` |
// | 4 | `284` | 戦績 | 0x70 | 0 | 0x062B | 0x0666 | `MapMenu_IsRecordsCommandAvailable` | `MapMenu_RecordsCommand` |
// | 5 | `27C` | 設定 | 0x71 | 0 | 0x0628 | 0x0664 | `MenuAlwaysEnabled` | `MapMenu_OptionsCommand` |
// | 6 | `274` | 退却 | 0x72 | 0 | 0x062A | 0x0665 | `MapMenu_IsRetreatCommandAvailable` | `MapMenu_RetreatCommand` |
// | 7 | `26C` | 中断 | 0x73 | 0 | 0x062C | 0x0667 | `MapMenu_IsSuspendCommandAvailable` | `MapMenu_SuspendCommand` |
// | 8 | `264` | 終了 | 0x78 | 0 | 0x062D | 0x0669 | `MenuAlwaysEnabled` | `CommandEffectEndPlayerPhase` |
//
// ⚠️ **上一版我把「終了」写成 `effect == NULL`、说"由菜单自己收尾"—— 那是错的。**
// 数组里它明明有 effect：`(u32)&CommandEffectEndPlayerPhase`，函数体是
// `Proc_EndEach(gProcScr_PlayerPhase)`（`src/bmmenu_080225C4.c:61-65`）。
//
// # 三条"可见性"结论（都会改变画出来的行数）
//
// 1. `戦績`：`GetBattleMapKind() != BATTLEMAP_KIND_DUNGEON` → **`MENU_NOTSHOWN`**
//    （`src/MapMenu_IsRecordsCommandAvailable.c:53`）。故事章节里**根本不显示**。
// 2. `退却`：`GetBattleMapKind() == BATTLEMAP_KIND_STORY` → **`MENU_NOTSHOWN`**
//    （`src/bmmenu_08024C7C.c:62`）。故事章节里**根本不显示**。
// 3. `中断`：教学（`PLAY_FLAG_TUTORIAL`）→ **`MENU_DISABLED`**（灰的、还在，
//    `src/masked_0802257c.c:63`）；按下只弹消息 `0x7E2`、**菜单不关**
//    （`src/MapMenu_SuspendCommand.c:51-54`）。
//
// `MENU_NOTSHOWN` 的行**不占行**：`StartMenuCore.c:61-72` 的循环里
// `if (availability != MENU_NOTSHOWN)` 才 `Proc_Start` 一个条目 ——
// 所以后面条目的行号会往前顶。
//
// # 面板几何（`src/StartMenuCore.c:34-98`，**不是我摆的**）
//
// ```
// xTileInner = rect.x + 1;   yTileInner = rect.y + 1;
// 每个"显示出来"的条目：item->xTile = xTileInner; item->yTile = yTileInner; yTileInner += 2;
// if (rect.y + rect.h < yTileInner) proc->rect.h = yTileInner + 1 - rect.y;
// ```
//
// * 单位是**UI 图块（8px）**，不是地图图块（16px）。
// * **行距是 2 个 UI 图块 = 16px**（一行字高 8px + 间距 8px）。
//   之前我按 1 图块画，面板只有应有高度的一半。
// * `gMapMenuDef.rect.h == 0` ⇒ 高度由行数算出来：`h = 2 * 行数 + 2`。
// * 光标在屏幕左半边 → 面板贴右（`x = 0x17 = 23`，23+6 = 29 < 30 图块宽）；否则贴左（`x = 1`）。

import 'battle_map_kind.dart';

// ─────────────────────────── 可用性 ───────────────────────────

/// `MENU_ENABLED` / `MENU_DISABLED` / `MENU_NOTSHOWN`（`include/uimenu.h:93-99`）
enum MenuAvailability {
  /// 1：正常显示、可选中
  enabled,

  /// 2：显示但灰掉（选中只弹提示）
  disabled,

  /// 3：**不显示**（不占行）
  notShown,
}

/// 4 个 `isAvailable` 函数需要的全部输入。
///
/// ⚠️ 其中 `battleMapKind` 与 `guideLocked` 的取值本身**未查证**，
/// 见 `battle_map_kind.dart` 的头注释和 `Fe8Game._mapMenuInputsJson()`。
class MapMenuContext {
  const MapMenuContext({
    required this.chapterIndex,
    required this.battleMapKind,
    required this.guideLocked,
    required this.tutorial,
    this.flags = const <int>{},
  });

  /// `gPlaySt.chapterIndex`
  final int chapterIndex;

  /// `GetBattleMapKind()`
  final BattleMapKind battleMapKind;

  /// `IsGuideLocked()`（`src/bmguide_080D2C48.c:47-66`）
  final bool guideLocked;

  /// `gPlaySt.chapterStateBits & PLAY_FLAG_TUTORIAL`
  final bool tutorial;

  /// `CheckFlag(f)` 为真的集合（`src/eventinfo.c` 里的旗帜表）
  final Set<int> flags;

  bool hasFlag(int f) => flags.contains(f);
}

/// `MenuAlwaysEnabled`（`src/uimenu.c:38-41`）
MenuAvailability _alwaysEnabled(MapMenuContext c) => MenuAvailability.enabled;

/// `MapMenu_IsGuideCommandAvailable`（`src/MapMenu_IsGuideCommandAvailable.c:51-56`）
///
/// ```c
/// if (IsGuideLocked()) return MENU_NOTSHOWN;
/// return MENU_ENABLED;
/// ```
MenuAvailability _guideAvailable(MapMenuContext c) =>
    c.guideLocked ? MenuAvailability.notShown : MenuAvailability.enabled;

/// `MapMenu_IsRetreatCommandAvailable`（`src/bmmenu_08024C7C.c:61-67`）
///
/// ```c
/// if (GetBattleMapKind() == BATTLEMAP_KIND_STORY) return MENU_NOTSHOWN;
/// return MENU_ENABLED;
/// ```
MenuAvailability _retreatAvailable(MapMenuContext c) =>
    c.battleMapKind == BattleMapKind.story
        ? MenuAvailability.notShown
        : MenuAvailability.enabled;

/// `MapMenu_IsSuspendCommandAvailable`（`src/masked_0802257c.c:61-67`）
///
/// ```c
/// if (gPlaySt.chapterStateBits & PLAY_FLAG_TUTORIAL) return MENU_DISABLED;
/// return MENU_ENABLED;
/// ```
MenuAvailability _suspendAvailable(MapMenuContext c) =>
    c.tutorial ? MenuAvailability.disabled : MenuAvailability.enabled;

/// `MapMenu_IsRecordsCommandAvailable`（`src/MapMenu_IsRecordsCommandAvailable.c:51-77`）
///
/// ```c
/// if (GetBattleMapKind() != BATTLEMAP_KIND_DUNGEON) return MENU_NOTSHOWN;
/// chapterId = gPlaySt.chapterIndex - 0x24;          // 0x24 = CHAPTER_T_01
/// if (chapterId > 9) return MENU_ENABLED;           // 0x2E 以后（遗迹）无条件开
/// if (CheckFlag(0x71) == 0 || ... || CheckFlag(0x77) == 0) return MENU_NOTSHOWN;
/// return MENU_ENABLED;
/// ```
///
/// `PLAY_FLAG_TUTORIAL` 的位是 `1 << 3`（`include/types.h:243`），这里用不到 ——
/// 上面的 `tutorial` 已经是解出来的布尔。
MenuAvailability _recordsAvailable(MapMenuContext c) {
  if (c.battleMapKind != BattleMapKind.dungeon) {
    return MenuAvailability.notShown;
  }
  final chapterId = c.chapterIndex - 0x24;
  if (chapterId > 9) return MenuAvailability.enabled;
  for (final f in const [0x71, 0x72, 0x73, 0x74, 0x75, 0x76, 0x77]) {
    if (!c.hasFlag(f)) return MenuAvailability.notShown;
  }
  return MenuAvailability.enabled;
}

// ─────────────────────────── 条目表 ───────────────────────────

/// `MenuItemDef::onSelected` 指向的函数（**8 条都有，没有 NULL**）
enum MapMenuCommand {
  /// `MapMenu_UnitCommand` → `Proc_Goto(PlayerPhase, 10); StartUnitListScreenField()`
  unitList,

  /// `MapMenu_StatusCommand` → `StartChapterStatusScreen(NULL)`
  status,

  /// `MapMenu_GuideCommand` → `Proc_Start(ProcScr_E_Guide1, PROC_TREE_3)`
  guide,

  /// `MapMenu_RecordsCommand` → `StartDungeonRecordProcFromMenu(PROC_TREE_3)`
  records,

  /// `MapMenu_OptionsCommand` → `Proc_Start(ProcScr_Config_Field, PROC_TREE_3)`
  options,

  /// `MapMenu_RetreatCommand` → `CallRetreatPromptEvent()`
  retreat,

  /// `MapMenu_SuspendCommand` → `StartSuspendPrompt()`
  suspend,

  /// `CommandEffectEndPlayerPhase` → `Proc_EndEach(gProcScr_PlayerPhase)`
  endPlayerPhase,
}

/// 地图菜单的一个条目（`struct MenuItemDef`，`include/uimenu.h:24-38`）
class MapMenuItem {
  const MapMenuItem({
    required this.label,
    required this.nameMsgId,
    required this.helpMsgId,
    required this.color,
    required this.overrideId,
    required this.availabilityFn,
    required this.availability,
    required this.commandFn,
    required this.command,
  });

  /// 显示标签：`menu_def.c` 的 rodata 原文，**去掉前导全角空格**
  ///
  /// ⚠️ 这是 rodata 字符串，**不在消息表里** ——
  /// 汉化流水线（`tools/i18n`）覆盖不到，所以直接显示日文原文。
  final String label;

  /// `MenuItemDef::nameMsgId`（数组字 u32 的低 16 位）
  final int nameMsgId;

  /// `MenuItemDef::helpMsgId`（高 16 位）
  final int helpMsgId;

  /// `MenuItemDef::color`（字 2 的低字节）
  final int color;

  /// `MenuItemDef::overrideId`（字 2 的高字节）—— `AddMenuOverride` 用它认条目
  /// （`src/OverriddenMenuAvailability.c:33`）。**不是序号。**
  final int overrideId;

  /// `MenuItemDef::isAvailable` 的函数名（照源码写下来，便于对照）
  final String availabilityFn;

  /// 上面那个函数的移植
  final MenuAvailability Function(MapMenuContext) availability;

  /// `MenuItemDef::onSelected` 的函数名
  final String commandFn;

  /// 上面那个函数的语义
  final MapMenuCommand command;
}

/// `gMapMenuDef` 的 8 条（顺序 = 日版 carve 数组的顺序）
const List<MapMenuItem> mapMenuItems = [
  MapMenuItem(
    label: '部隊',
    nameMsgId: 0x0627,
    helpMsgId: 0x0662,
    color: 0,
    overrideId: 0x6E,
    availabilityFn: 'MenuAlwaysEnabled',
    availability: _alwaysEnabled,
    commandFn: 'MapMenu_UnitCommand',
    command: MapMenuCommand.unitList,
  ),
  MapMenuItem(
    label: '状況',
    nameMsgId: 0x0621,
    helpMsgId: 0x0663,
    color: 0,
    overrideId: 0x6F,
    availabilityFn: 'MenuAlwaysEnabled',
    availability: _alwaysEnabled,
    commandFn: 'MapMenu_StatusCommand',
    command: MapMenuCommand.status,
  ),
  MapMenuItem(
    label: '辞書',
    nameMsgId: 0x0629,
    helpMsgId: 0x0668,
    color: 4,
    overrideId: 0x74,
    availabilityFn: 'MapMenu_IsGuideCommandAvailable',
    availability: _guideAvailable,
    commandFn: 'MapMenu_GuideCommand',
    command: MapMenuCommand.guide,
  ),
  MapMenuItem(
    label: '戦績',
    nameMsgId: 0x062B,
    helpMsgId: 0x0666,
    color: 0,
    overrideId: 0x70,
    availabilityFn: 'MapMenu_IsRecordsCommandAvailable',
    availability: _recordsAvailable,
    commandFn: 'MapMenu_RecordsCommand',
    command: MapMenuCommand.records,
  ),
  MapMenuItem(
    label: '設定',
    nameMsgId: 0x0628,
    helpMsgId: 0x0664,
    color: 0,
    overrideId: 0x71,
    availabilityFn: 'MenuAlwaysEnabled',
    availability: _alwaysEnabled,
    commandFn: 'MapMenu_OptionsCommand',
    command: MapMenuCommand.options,
  ),
  MapMenuItem(
    label: '退却',
    nameMsgId: 0x062A,
    helpMsgId: 0x0665,
    color: 0,
    overrideId: 0x72,
    availabilityFn: 'MapMenu_IsRetreatCommandAvailable',
    availability: _retreatAvailable,
    commandFn: 'MapMenu_RetreatCommand',
    command: MapMenuCommand.retreat,
  ),
  MapMenuItem(
    label: '中断',
    nameMsgId: 0x062C,
    helpMsgId: 0x0667,
    color: 0,
    overrideId: 0x73,
    availabilityFn: 'MapMenu_IsSuspendCommandAvailable',
    availability: _suspendAvailable,
    commandFn: 'MapMenu_SuspendCommand',
    command: MapMenuCommand.suspend,
  ),
  MapMenuItem(
    label: '終了',
    nameMsgId: 0x062D,
    helpMsgId: 0x0669,
    color: 0,
    overrideId: 0x78,
    availabilityFn: 'MenuAlwaysEnabled',
    availability: _alwaysEnabled,
    commandFn: 'CommandEffectEndPlayerPhase',
    command: MapMenuCommand.endPlayerPhase,
  ),
];

/// 真正会显示出来的一行
class MapMenuEntry {
  const MapMenuEntry({required this.item, required this.availability});

  final MapMenuItem item;
  final MenuAvailability availability;

  bool get isDisabled => availability == MenuAvailability.disabled;
}

/// `StartMenuCore` 的筛选（`src/StartMenuCore.c:59-87`）：
/// `MENU_NOTSHOWN` 的条目**不进列表、不占行**。
List<MapMenuEntry> buildMapMenu(MapMenuContext ctx) {
  final out = <MapMenuEntry>[];
  for (final it in mapMenuItems) {
    final a = it.availability(ctx);
    if (a == MenuAvailability.notShown) continue;
    out.add(MapMenuEntry(item: it, availability: a));
  }
  return out;
}

// ─────────────────────────── 几何 ───────────────────────────

/// `DISPLAY_WIDTH / 2`（`src/exact_0804f924.c:49` 里写死的 `120`）
const int mapMenuSideThresholdPx = 120;

/// 调用点传进来的两个候选 x（`src/playerphase_0801C5A8.c:110` 的 `1, 0x17`）
const int mapMenuXTileLeft = 1;
const int mapMenuXTileRight = 0x17;

/// `gMapMenuDef.rect`：`0x00060201` → x=1 y=2 w=6 h=0
/// （`src/data/frontier_df4_uistuff/frontier_df4_uistuff.c:12403-12412`）
const int mapMenuRectY = 2; // y
const int mapMenuRectW = 6; // w

/// 菜单里的一行（`struct MenuItemProc` 的 `xTile` / `yTile`）
class MapMenuRow {
  const MapMenuRow({
    required this.entry,
    required this.xTile,
    required this.yTile,
  });

  final MapMenuEntry entry;

  /// UI 图块（8px）
  final int xTile, yTile;
}

/// `StartMenuCore` 算出来的面板几何，单位一律是 **UI 图块（8px）**
class MapMenuLayout {
  const MapMenuLayout({
    required this.x,
    required this.y,
    required this.w,
    required this.h,
    required this.rows,
  });

  final int x, y, w, h;
  final List<MapMenuRow> rows;
}

/// 由**光标的屏幕像素 x** 算面板几何。
///
/// `cursorScreenPx` = `gBmSt.cursorTarget.x - gBmSt.camera.x`
/// （`src/playerphase_0801C5A8.c:110`）—— **像素**，不是图块。
MapMenuLayout mapMenuLayout({
  required List<MapMenuEntry> entries,
  required int cursorScreenPx,
}) {
  final x = cursorScreenPx < mapMenuSideThresholdPx
      ? mapMenuXTileRight
      : mapMenuXTileLeft;

  // `xTileInner = rect.x + 1; yTileInner = rect.y + 1;`
  final xInner = x + 1;
  final yInner = mapMenuRectY + 1;

  final rows = <MapMenuRow>[];
  for (var i = 0; i < entries.length; i++) {
    // `item->yTile = yTileInner; ... yTileInner += 2;`
    rows.add(MapMenuRow(
      entry: entries[i],
      xTile: xInner,
      yTile: yInner + 2 * i,
    ));
  }

  // `if (rect.y + rect.h < yTileInner) proc->rect.h = yTileInner + 1 - rect.y;`
  // 定义里的 h = 0，所以这里总是按行数算：h = (rect.y + 1 + 2*rows) + 1 - rect.y
  final yTileEnd = yInner + 2 * entries.length;
  final h = yTileEnd + 1 - mapMenuRectY;

  return MapMenuLayout(x: x, y: mapMenuRectY, w: mapMenuRectW, h: h, rows: rows);
}

// ─────────────────────────── 选中 ───────────────────────────

/// 选中一个条目之后**立刻**发生的事（`MenuItemDef::onSelected` 的返回值语义）
class MapMenuSelection {
  const MapMenuSelection({
    required this.command,
    required this.note,
    this.closesMenu = true,
    this.helpBoxMsgId,
  });

  final MapMenuCommand command;

  /// 进转储的说明
  final String note;

  /// `MENU_ACT_END`：条目被选中后菜单就关
  ///
  /// 唯一例外是教学状态下的 `中断`（`src/MapMenu_SuspendCommand.c:51-54`
  /// 只返回 `MENU_ACT_SND6B`，**没有** `MENU_ACT_END`）。
  final bool closesMenu;

  /// `MenuFrozenHelpBox(menu, msgId)` 的消息号（只有上面那个例外有）
  final int? helpBoxMsgId;
}

/// 地图菜单的状态（纯数据，可测试）
class MapMenuState {
  const MapMenuState({required this.entries, this.index = 0, this.note = ''});

  /// 已经筛掉 `MENU_NOTSHOWN` 的条目（`buildMapMenu` 的结果）
  final List<MapMenuEntry> entries;

  /// 当前高亮项（`entries` 的下标）
  final int index;

  /// 最近一次操作的说明（进转储）
  final String note;

  bool get isEmpty => entries.isEmpty;

  MapMenuEntry get current => entries[index.clamp(0, entries.length - 1)];

  /// 上下移动（**循环**：`ProcessMenuDpadInput` 到边界会绕）
  MapMenuState move(int delta) {
    if (entries.isEmpty) return this;
    final n = entries.length;
    return MapMenuState(
      entries: entries,
      index: (index + delta) % n,
      note: note,
    );
  }

  /// 确认当前项
  MapMenuSelection select() {
    final e = current;
    final label = e.item.label;

    if (e.isDisabled) {
      // `src/MapMenu_SuspendCommand.c:51-54`（唯一一个 MENU_DISABLED 分支）
      return MapMenuSelection(
        command: e.item.command,
        note: '$label（${e.item.commandFn}）：MENU_DISABLED → 消息 0x7E2，菜单不关',
        closesMenu: false,
        helpBoxMsgId: 0x7E2,
      );
    }

    // 菜单自己收尾的那一条 = 结束回合
    if (e.item.command == MapMenuCommand.endPlayerPhase) {
      return const MapMenuSelection(
        command: MapMenuCommand.endPlayerPhase,
        note: '終了（CommandEffectEndPlayerPhase）：结束我方阶段',
      );
    }

    return MapMenuSelection(
      command: e.item.command,
      note: '$label（${e.item.commandFn}）',
    );
  }
}
