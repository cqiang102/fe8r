// 「状況」屏的规则层判据。
//
// 出处：`src/uichapterstatus_080908DC.c:30-86`（`ChapterStatus_LoopKeyHandler`）
//
// ⚠️ 这个屏的左右**不对称**（左：`unitIndex != 0` 才减；右：`unitIndex == 0` 才加）。
// 这不是我写错了 —— 源码就是这样。**钉住它**，免得后来的人"顺手修正"。
import 'package:fe8r/core/core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('★ 索引分页：往右**只在 0** 时生效（源码的不对称）', () {
    final s = ChapterStatusState(unitCount: 3);
    chapterStatusKey(s, ChapterStatusKey.right);
    expect(s.unitIndex, 1, reason: 'index 0 时往右 → 1');

    // 已经在 1：再往右**不动**（源码：`unitIndex == 0` 才加）
    chapterStatusKey(s, ChapterStatusKey.right);
    expect(s.unitIndex, 1, reason: 'index != 0 时往右不动 —— 这是源码的写法');

    // 往左可以退回
    chapterStatusKey(s, ChapterStatusKey.left);
    expect(s.unitIndex, 0);
    chapterStatusKey(s, ChapterStatusKey.left);
    expect(s.unitIndex, 0, reason: 'index 0 时往左不动');
  });

  test('★ R 之后**直接返回**：同一条输入里的左右不生效', () {
    final s = ChapterStatusState(unitCount: 3);
    chapterStatusKey(s, ChapterStatusKey.r);
    expect(s.helpTextActive, isTrue);
    expect(s.closed, isFalse);
    // 源码里 R 分支是 `return`，但左右判定在**同一次调用**里位于其**之后**
    // ⇒ 只有当次调用会提前返回；下一次调用照常。这里测的是"R 不当成退出"。
    chapterStatusKey(s, ChapterStatusKey.left);
    expect(s.unitIndex, 0, reason: 'index 已是 0，往左仍不动');
  });

  test('★ B 关闭、A 关闭并标记聚焦', () {
    final b = ChapterStatusState(unitCount: 2);
    chapterStatusKey(b, ChapterStatusKey.b);
    expect(b.closed, isTrue);
    expect(b.focusUnitOnExit, isFalse);

    final a = ChapterStatusState(unitCount: 2);
    chapterStatusKey(a, ChapterStatusKey.a);
    expect(a.closed, isTrue);
    expect(a.focusUnitOnExit, isTrue);
  });

  test('没有单位时：不聚焦、也不越界', () {
    final s = ChapterStatusState(unitCount: 0);
    expect(s.shownIndex, -1);
    chapterStatusKey(s, ChapterStatusKey.a);
    expect(s.focusUnitOnExit, isFalse, reason: '没有单位就不该标记聚焦');
    expect(s.closed, isTrue, reason: 'A 仍然会关屏');
    // 关屏之后按键不该再改变状态（源码里 proc 已经 Goto 走了，循环不再被调用）
    chapterStatusKey(s, ChapterStatusKey.right);
    expect(s.unitIndex, 0, reason: '关屏后按键无效');

    // 源码**没有**在这两行里判 `unitCount` —— 用全新的状态测这一点
    final t = ChapterStatusState(unitCount: 0);
    chapterStatusKey(t, ChapterStatusKey.right);
    expect(t.unitIndex, 1, reason: '源码的分页不判 unitCount（照抄，别顺手加条件）');
  });

  test('关掉之后再按键什么都不做', () {
    final s = ChapterStatusState(unitCount: 3);
    chapterStatusKey(s, ChapterStatusKey.b);
    chapterStatusKey(s, ChapterStatusKey.right);
    expect(s.unitIndex, 0);
  });
}
