// 地图菜单（回合的第二种结束：**主动选择「終了」**）
//
// 出处：
//   * START 打开 —— `src/playerphase_0801C5A8.c:141-158`
//   * 左右分侧 —— `src/exact_0804f924.c:43-55`（`xSubject < 120`，**像素**）
//   * 条目顺序 + 字段 —— `gMapMenuDef` 的数组
//     （`src/data/frontier_df4_uistuff/frontier_df4_uistuff.c:12166-12250`）
//   * 标签 —— `src/menu_def.c:154-171`
//   * 筛选 / 行距 / 面板高度 —— `src/StartMenuCore.c:59-98`
//   * 各条可用性 —— `src/MapMenu_Is*CommandAvailable.c`、`src/masked_0802257c.c`
//
// ⚠️ 上一版这里断言过两件事，**都是错的**：
//   1.「終了」的 effect 是 NULL —— 实际是 `CommandEffectEndPlayerPhase`；
//   2. 菜单永远 8 条 —— 实际 `MENU_NOTSHOWN` 的条目不占行。
import 'package:fe8r/core/core.dart';
import 'package:flutter_test/flutter_test.dart';

/// 故事章节 + 非教学（新手难度）：序章 / 第 1 章常见的那个组合
MapMenuContext _ctx({
  BattleMapKind kind = BattleMapKind.story,
  bool guideLocked = false,
  bool tutorial = false,
  Set<int> flags = const {},
  int chapterIndex = 0x00,
}) =>
    MapMenuContext(
      chapterIndex: chapterIndex,
      battleMapKind: kind,
      guideLocked: guideLocked,
      tutorial: tutorial,
      flags: flags,
    );

void main() {
  test('条目顺序 = 源码数组顺序（8 条，含「終了」）', () {
    expect(mapMenuItems.map((e) => e.label).toList(),
        ['部隊', '状況', '辞書', '戦績', '設定', '退却', '中断', '終了']);
  });

  test('overrideId / color / 消息号 = carve 数组里的原始值', () {
    // `0x06620627` 这种字：低 16 位 = nameMsgId、高 16 位 = helpMsgId；
    // 再下一个字的低字节 = color、高字节 = overrideId
    expect(mapMenuItems.map((e) => (e.overrideId, e.color)).toList(), [
      (0x6E, 0),
      (0x6F, 0),
      (0x74, 4), // 辞书是唯一一个 color != 0 的
      (0x70, 0),
      (0x71, 0),
      (0x72, 0),
      (0x73, 0),
      (0x78, 0),
    ]);
    expect(mapMenuItems.map((e) => e.nameMsgId).toList(),
        [0x0627, 0x0621, 0x0629, 0x062B, 0x0628, 0x062A, 0x062C, 0x062D]);
    expect(mapMenuItems.map((e) => e.helpMsgId).toList(),
        [0x0662, 0x0663, 0x0668, 0x0666, 0x0664, 0x0665, 0x0667, 0x0669]);
  });

  test('★「終了」的 effect 是 CommandEffectEndPlayerPhase，不是 NULL', () {
    final end = mapMenuItems.last;
    expect(end.label, '終了');
    expect(end.commandFn, 'CommandEffectEndPlayerPhase');
    expect(end.command, MapMenuCommand.endPlayerPhase);
  });

  test('★ 故事章节：退却/戦績 是 MENU_NOTSHOWN（不显示、不占行）', () {
    final entries = buildMapMenu(_ctx());
    expect(entries.map((e) => e.item.label).toList(),
        ['部隊', '状況', '辞書', '設定', '中断', '終了'],
        reason: '6 条');
    expect(entries.map((e) => e.item.label), isNot(contains('退却')));
    expect(entries.map((e) => e.item.label), isNot(contains('戦績')));
  });

  test('★ 教学（PLAY_FLAG_TUTORIAL）：中断 变 MENU_DISABLED，行还在', () {
    final entries = buildMapMenu(_ctx(tutorial: true));
    final suspend = entries.firstWhere((e) => e.item.label == '中断');
    expect(suspend.availability, MenuAvailability.disabled);
    expect(entries.map((e) => e.item.label), contains('中断'),
        reason: '灰的也要占行');
  });

  test('★ 辞书锁定：辞书 整条不显示（IsGuideLocked → MENU_NOTSHOWN）', () {
    final entries = buildMapMenu(_ctx(guideLocked: true));
    expect(entries.map((e) => e.item.label).toList(),
        ['部隊', '状況', '設定', '中断', '終了'],
        reason: '5 条');
  });

  test('★ 迷宫（dungeon）：戦績 出现，退却 也出现（不是 story）', () {
    final entries =
        buildMapMenu(_ctx(kind: BattleMapKind.dungeon, chapterIndex: 0x2E));
    expect(entries.map((e) => e.item.label).toList(),
        ['部隊', '状況', '辞書', '戦績', '設定', '退却', '中断', '終了']);
  });

  test('戦績 的旗子检查：塔 1..10（chapterIndex-0x24 <= 9）要 0x71..0x77 全开', () {
    // 缺一个 → 不显示
    final missing = buildMapMenu(_ctx(
      kind: BattleMapKind.dungeon,
      chapterIndex: 0x24,
      flags: {0x71, 0x72, 0x73, 0x74, 0x75, 0x76},
    ));
    expect(missing.map((e) => e.item.label), isNot(contains('戦績')));

    final all = buildMapMenu(_ctx(
      kind: BattleMapKind.dungeon,
      chapterIndex: 0x24,
      flags: {0x71, 0x72, 0x73, 0x74, 0x75, 0x76, 0x77},
    ));
    expect(all.map((e) => e.item.label), contains('戦績'));

    // chapterIndex - 0x24 > 9（遗迹）→ 不问旗子
    final ruins = buildMapMenu(_ctx(
      kind: BattleMapKind.dungeon,
      chapterIndex: 0x2E,
      flags: const {},
    ));
    expect(ruins.map((e) => e.item.label), contains('戦績'));
  });

  test('★ 面板几何：行距 2 个 UI 图块、h = 2*行数 + 2、文字内缩 1 图块', () {
    final entries = buildMapMenu(_ctx()); // 6 条
    final l = mapMenuLayout(entries: entries, cursorScreenPx: 40);
    expect(l.x, mapMenuXTileRight, reason: '光标在屏幕左半边 → 面板贴右');
    expect(l.y, 2);
    expect(l.w, 6);
    expect(l.h, 2 * 6 + 2);
    expect(l.rows.length, 6);
    expect(l.rows.first.xTile, l.x + 1, reason: '`xTileInner = rect.x + 1`');
    expect(l.rows.first.yTile, 3, reason: '`yTileInner = rect.y + 1`');
    // `yTileInner += 2` —— 行距就是 2，不是 1
    for (var i = 0; i < l.rows.length; i++) {
      expect(l.rows[i].yTile, 3 + 2 * i);
    }
  });

  test('★ 左右分侧用的是**屏幕像素**（120 = 240/2），不是图块坐标', () {
    final entries = buildMapMenu(_ctx());
    expect(mapMenuLayout(entries: entries, cursorScreenPx: 119).x,
        mapMenuXTileRight);
    expect(mapMenuLayout(entries: entries, cursorScreenPx: 120).x,
        mapMenuXTileLeft);
    // 只有 5 行时高度跟着变
    final five = buildMapMenu(_ctx(guideLocked: true));
    expect(mapMenuLayout(entries: five, cursorScreenPx: 0).h, 2 * 5 + 2);
  });

  test('上下移动是环形的（绕的是**筛过之后**的列表）', () {
    final entries = buildMapMenu(_ctx());
    var s = MapMenuState(entries: entries);
    expect(s.current.item.label, '部隊');
    s = s.move(-1);
    expect(s.current.item.label, '終了', reason: '从第一项往上 → 绕到最后一项');
    s = s.move(1);
    expect(s.current.item.label, '部隊');
  });

  test('★ 选中「終了」→ 结束我方阶段（菜单关闭）', () {
    final entries = buildMapMenu(_ctx());
    final s = MapMenuState(entries: entries, index: entries.length - 1);
    expect(s.current.item.label, '終了');
    final sel = s.select();
    expect(sel.command, MapMenuCommand.endPlayerPhase);
    expect(sel.closesMenu, isTrue);
  });

  test('★ 教学状态下选「中断」：只弹消息 0x7E2，**菜单不关**', () {
    final entries = buildMapMenu(_ctx(tutorial: true));
    final idx = entries.indexWhere((e) => e.item.label == '中断');
    final s = MapMenuState(entries: entries, index: idx);
    final sel = s.select();
    expect(sel.command, MapMenuCommand.suspend);
    expect(sel.closesMenu, isFalse, reason: 'MENU_ACT_SND6B 没有 MENU_ACT_END');
    expect(sel.helpBoxMsgId, 0x7E2);
    expect(sel.note, contains('MENU_DISABLED'));
  });

  test('其它条目 → 报出**源码函数名**（好对照，不静默）', () {
    final entries = buildMapMenu(_ctx());
    const parts = [
      '部隊：MapMenu_UnitCommand',
      '状況：MapMenu_StatusCommand',
      '辞書：MapMenu_GuideCommand',
      '設定：MapMenu_OptionsCommand',
      '中断：MapMenu_SuspendCommand',
    ];
    for (var i = 0; i < parts.length; i++) {
      final item = entries[i].item;
      expect('${item.label}：${item.commandFn}', parts[i]);
      final sel = MapMenuState(entries: entries, index: i).select();
      expect(sel.note, contains(item.commandFn));
      expect(sel.closesMenu, isTrue);
    }
  });
}
