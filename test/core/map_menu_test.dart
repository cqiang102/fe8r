// 地图菜单（回合的第二种结束：**主动选择「終了」**）
//
// 出处：
//   * START 打开 —— `src/playerphase_0801C5A8.c:141-158`
//   * 条目与顺序 —— `gMapMenuDef` 的数组
//     （`src/data/frontier_df4_uistuff/frontier_df4_uistuff.c:12166+`）
//   * 标签 —— `src/menu_def.c:154-171`
//
// ⚠️ 「終了」那一条的 effect 指针是 **NULL**（其余条目都有 effect 函数）——
// 这就是"它由菜单本身收尾（结束回合）"的证据。
import 'package:fe8r/core/core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('条目顺序 = 源码数组顺序，且「終了」在最后（effect 为 NULL）', () {
    expect(mapMenuItems.map((e) => e.label).toList(),
        ['部隊', '状況', '辞書', '戦績', '設定', '退却', '中断', '終了']);
    expect(mapMenuItems.map((e) => e.index).toList(),
        [0x6E, 0x6F, 0x74, 0x70, 0x71, 0x72, 0x73, 0x78]);
    // 只有最後一条是"菜单自己收尾"
    expect(mapMenuItems.where((e) => e.isEnd).length, 1);
    expect(mapMenuItems.last.isEnd, isTrue);
    expect(mapMenuItems.last.label, '終了');
  });

  test('上下移动是环形的', () {
    var s = const MapMenuState();
    expect(s.current.label, '部隊');
    s = s.move(-1);
    expect(s.current.label, '終了', reason: '从第一项往上 → 绕到最后一项');
    s = s.move(1);
    expect(s.current.label, '部隊');
  });

  test('★ 选中「終了」→ 结束回合', () {
    var s = const MapMenuState();
    for (var i = 0; i < mapMenuItems.length - 1; i++) {
      s = s.move(1);
    }
    expect(s.current.label, '終了');
    final (action, st) = s.select();
    expect(action, MapMenuAction.endTurn);
    expect(st.note, '終了');
  });

  test('其它条目 → 显式记「未实现」（不静默忽略）', () {
    const s = MapMenuState();
    final (action, st) = s.select();
    expect(action, MapMenuAction.notImplemented);
    expect(st.note, contains('未实现'));
    expect(st.note, contains('MapMenu_UnitCommand'));
  });
}
