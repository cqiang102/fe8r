// PORT OF: 玩家阶段的 START 键 → 地图菜单
//   src/playerphase_0801C5A8.c:141-158（START 打开）
//   src/data/frontier_df4_uistuff/frontier_df4_uistuff.c:12166+
//       （`frontier_df4_uistuff_030_5C534C` —— `gMapMenuDef` 的条目数组）
//   src/menu_def.c:154-171（各条目的标签字符串）
//
// # 两种回合结束之一：**主动选择「終了」**
//
// 原作不是"按一个键就结束回合"，而是：
//
// ```c
// // src/playerphase_0801C5A8.c:141
// if ((gKeyStatusPtr->newKeys & START_BUTTON) && !(gKeyStatusPtr->heldKeys & SELECT_BUTTON)) {
//     ...
//     EndPlayerPhaseSideWindows();
//     StartMinimapPlayerPhase();
//     Proc_Goto(proc, 9);
//     return;
// }
// ```
//
// 菜单本体：`StartOrphanMenuAdjusted(&gMapMenuDef, gBmSt.cursorTarget.x - gBmSt.camera.x, 1, 0x17)`
// （`src/playerphase_0801C5A8.c:111`）—— **贴着光标所在格**、第 1 行。
//
// # 条目顺序与标签（**照数组顺序，不是照我猜的**）
//
// | # | `gMenuStr` | 标签 | index | 可用性 | 效果 |
// |---|---|---|---|---|---|
// | 1 | `29C` | 部隊 | 0x6E | 恒可用 | `MapMenu_UnitCommand` |
// | 2 | `294` | 状況 | 0x6F | 恒可用 | `MapMenu_StatusCommand` |
// | 3 | `28C` | 辞書 | 0x74 | `MapMenu_IsGuideCommandAvailable` | `MapMenu_GuideCommand` |
// | 4 | `284` | 戦績 | 0x70 | `MapMenu_IsRecordsCommandAvailable` | `MapMenu_RecordsCommand` |
// | 5 | `27C` | 設定 | 0x71 | 恒可用 | `MapMenu_OptionsCommand` |
// | 6 | `274` | 退却 | 0x72 | `MapMenu_IsRetreatCommandAvailable` | `MapMenu_RetreatCommand` |
// | 7 | `26C` | 中断 | 0x73 | `MapMenu_IsSuspendCommandAvailable` | `MapMenu_SuspendCommand` |
// | 8 | `264` | **終了** | 0x78 | 恒可用 | **NULL → 菜单默认动作（结束回合）** |
//
// 「終了」的 effect 指针为 **0**，这就是它"由菜单本身收尾"的证据
// （对比其它条目都有 effect 函数）。
//
// ⚠️ 标签是 `menu_def.c` 里的 **rodata 字符串**，不在消息表里 ——
// 所以汉化流水线（`tools/i18n`）覆盖不到它们，这里直接显示日文原文。

/// 地图菜单的一个条目（`struct MenuItemDef` 里我们需要的字段）
class MapMenuItem {
  const MapMenuItem({
    required this.label,
    required this.index,
    required this.command,
  });

  /// 显示标签（`menu_def.c` 的 rodata 原文，去掉前导全角空格）
  final String label;

  /// `MenuItemDef` 的 index 字段（**不是序号**，是原作用的稳定 id）
  final int index;

  /// 效果函数名（照源码写下来，便于对照；`null` = 由菜单收尾）
  final String? command;

  /// 「終了」：`effect == NULL`
  bool get isEnd => command == null;
}

/// `gMapMenuDef` 的条目（顺序 = 数组顺序）
const List<MapMenuItem> mapMenuItems = [
  MapMenuItem(label: '部隊', index: 0x6E, command: 'MapMenu_UnitCommand'),
  MapMenuItem(label: '状況', index: 0x6F, command: 'MapMenu_StatusCommand'),
  MapMenuItem(label: '辞書', index: 0x74, command: 'MapMenu_GuideCommand'),
  MapMenuItem(label: '戦績', index: 0x70, command: 'MapMenu_RecordsCommand'),
  MapMenuItem(label: '設定', index: 0x71, command: 'MapMenu_OptionsCommand'),
  MapMenuItem(label: '退却', index: 0x72, command: 'MapMenu_RetreatCommand'),
  MapMenuItem(label: '中断', index: 0x73, command: 'MapMenu_SuspendCommand'),
  // 終了：`effect` 为 NULL
  MapMenuItem(label: '終了', index: 0x78, command: null),
];

/// 玩家在地图菜单上按下确认之后**要做什么**
enum MapMenuAction {
  /// 自己那一条 = 结束回合（`終了`）
  endTurn,

  /// 其余条目：本实现还没做（**响亮记下来，不静默忽略**）
  notImplemented,
}

/// 地图菜单的状态（纯数据，可测试）
class MapMenuState {
  const MapMenuState({this.index = 0, this.note = ''});

  /// 当前高亮项（`mapMenuItems` 的下标）
  final int index;

  /// 最近一次操作的说明（进转储）
  final String note;

  MapMenuItem get current => mapMenuItems[index.clamp(0, mapMenuItems.length - 1)];

  /// 上下移动（**循环**：原作的菜单是环形的，`MenuStdHelpBox` 那套）
  MapMenuState move(int delta) {
    final n = mapMenuItems.length;
    return MapMenuState(index: (index + delta) % n, note: note);
  }

  /// 当前项的标签（并列出来，便于 HUD 显示）
  String get text => mapMenuItems[index].label;

  /// 确认当前项
  (MapMenuAction, MapMenuState) select() {
    final it = current;
    if (it.isEnd) {
      return (MapMenuAction.endTurn, MapMenuState(index: index, note: '終了'));
    }
    return (
      MapMenuAction.notImplemented,
      MapMenuState(index: index, note: '${it.label}（${it.command}）：未实现'),
    );
  }
}
