// 話す（对话事件）的判据。
//
// 出处：`src/TalkCommandUsability.c:50-64`、`src/bmtarget_0802506C.c:283-304`、
//       `src/CheckForCharacterEvents.c:25-41`。
// 真值样例取自我们抽出来的第 2 章 `_Character` 表：
//   `{pidA: 1, pidB: 7, script: EventScr_Ch2_Talk_EirikaRoss, doneFlag: 7}`
import 'package:fe8r/core/core.dart';
import 'package:flutter_test/flutter_test.dart';

MapUnit u(int id, {int pid = 0, int x = 0, int y = 0, int f = Faction.blue}) =>
    MapUnit(id: id, faction: f, x: x, y: y, charIndex: pid);

void main() {
  test('★ 方向由**数据**决定：`(1,7)` 命中，`(7,1)` 不命中（除非数据里也有）', () {
    const e = CharacterEvent(pidA: 1, pidB: 7, doneFlag: 7, script: 'S');
    expect(checkForCharacterEvents(const [e], 1, 7, {}), isNotNull);
    expect(checkForCharacterEvents(const [e], 7, 1, {}), isNull,
        reason: '★ 反着来不算 —— 第 2 章里两个方向是**两条不同条目**，不能自己补方向');
  });

  test('★ `doneFlag` 置位 ⇒ 这条对话不再出现', () {
    const e = CharacterEvent(pidA: 1, pidB: 7, doneFlag: 7);
    expect(checkForCharacterEvents(const [e], 1, 7, {7}), isNull);
    expect(checkForCharacterEvents(const [e], 1, 7, {8}), isNotNull, reason: '别的旗不影响');
  });

  test('★ 目标：相邻（四邻居、**不含自己**）+ 有 CHAR 条目', () {
    final a = u(1, pid: 1, x: 2, y: 2);
    final adj = u(2, pid: 7, x: 3, y: 2);
    final far = u(3, pid: 7, x: 4, y: 2);
    final wrong = u(4, pid: 99, x: 2, y: 3);
    final me = u(5, pid: 1, x: 2, y: 2);
    const e = CharacterEvent(pidA: 1, pidB: 7, doneFlag: 7);
    final got = talkTargets(
      actor: a,
      units: [adj, far, wrong, me],
      eventFor: (t) => (t.charIndex == 7) ? e : null,
    );
    expect(got.map((x) => x.id).toList(), [2],
        reason: '距离 2 不算；pid 不匹配不算；**自己那格不算**');
  });

  test('★ 可用性：没行动过 + 有目标（沉默那条我们没建模，见文件头）', () {
    expect(talkAvailable(hasActed: false, hasTarget: true), isTrue);
    expect(talkAvailable(hasActed: true, hasTarget: true), isFalse,
        reason: '对应 `US_HAS_MOVED`');
    expect(talkAvailable(hasActed: false, hasTarget: false), isFalse);
  });
  _hideFactionTests();
}

// `CLEA`/`CLEN`/`CLEE`（`src/eventscr_080103F4.c:60-135`）—— 阵营级隐藏
void _hideFactionTests() {
  test('★ 藏起某阵营：只动那一阵营、返回个数、且从"可见单位"里消失', () {
    final blue = u(1, x: 0, y: 0);
    final blue2 = u(2, x: 1, y: 0);
    final green = u(3, x: 2, y: 0, f: Faction.green);
    final red = u(4, x: 3, y: 0, f: Faction.red);
    final f = BattleField(width: 6, height: 6, units: [blue, blue2, green, red]);
    expect(visibleUnits(f).length, 4);
    expect(hideFactionUnits(f, Faction.red), 1, reason: '只有 1 个红方');
    expect(red.isHidden, isTrue);
    expect(blue.isHidden, isFalse, reason: '别的阵营不动');
    expect(visibleUnits(f).map((x) => x.id).toList(), [1, 2, 3]);
    expect(hideFactionUnits(f, Faction.blue), 2, reason: '两个蓝方');
    expect(visibleUnits(f).map((x) => x.id).toList(), [3]);
    expect(hideFactionUnits(f, Faction.blue), 0, reason: '★ 已经藏过的不重复计数');
  });
}
