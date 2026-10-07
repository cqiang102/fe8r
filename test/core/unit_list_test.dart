// 「部隊」列表的规则层判据。
//
// 出处：`src/unitlistscreen_08093744.c:64-190`（A/R/上下与边界翻页）、
//       `src/unitlistscreen_08093DE4.c:54`（B 退出）
import 'package:fe8r/core/core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('★ 上下移动：夹在两端（不在两端循环）', () {
    final s = UnitListState(unitIds: [11, 12, 13]);
    unitListKey(s, UnitListKey.down);
    expect(s.index, 1);
    unitListKey(s, UnitListKey.up);
    expect(s.index, 0);
    unitListKey(s, UnitListKey.up);
    expect(s.index, 0, reason: '顶端再按上不该绕到末尾');
    expect(s.pageUpRequested, isTrue, reason: '源码在顶端再按上是**请求翻页**');
  });

  test('★ 底端再按下 ⇒ 请求翻页（不是停住也不是绕回）', () {
    final s = UnitListState(unitIds: [11, 12]);
    unitListKey(s, UnitListKey.down);
    expect(s.index, 1);
    expect(s.pageDownRequested, isFalse);
    unitListKey(s, UnitListKey.down);
    expect(s.index, 1, reason: '底端不该越界');
    expect(s.pageDownRequested, isTrue);
  });

  test('★ A：记住选中的单位并跳出（随后开的是**那个单位**的状況屏）', () {
    final s = UnitListState(unitIds: [11, 12, 13]);
    unitListKey(s, UnitListKey.down);
    unitListKey(s, UnitListKey.down);
    unitListKey(s, UnitListKey.a);
    expect(s.chosenUnitId, 13, reason: '`SetLastStatScreenUid` 记的是光标那一行');
    expect(s.closed, isTrue, reason: '`Proc_Break` ⇒ 列表关掉');
  });

  test('B：关掉但**不选**任何单位', () {
    final s = UnitListState(unitIds: [11, 12]);
    unitListKey(s, UnitListKey.b);
    expect(s.closed, isTrue);
    expect(s.chosenUnitId, isNull);
  });

  test('R：请求排序（原作有排序，我们**未实现**，只记账）', () {
    final s = UnitListState(unitIds: [11]);
    unitListKey(s, UnitListKey.r);
    expect(s.sortRequested, isTrue);
    expect(s.closed, isFalse, reason: 'R 不该关列表');
  });

  test('空列表：不越界、A 选不到东西但照样关', () {
    final s = UnitListState(unitIds: const []);
    unitListKey(s, UnitListKey.down);
    expect(s.index, 0);
    expect(s.pageDownRequested, isTrue);
    expect(s.shownUnitId, isNull);
    unitListKey(s, UnitListKey.a);
    expect(s.chosenUnitId, isNull);
    expect(s.closed, isTrue);
  });

  test('关掉之后再按键无效', () {
    final s = UnitListState(unitIds: [11, 12]);
    unitListKey(s, UnitListKey.b);
    unitListKey(s, UnitListKey.down);
    expect(s.index, 0);
  });
}
