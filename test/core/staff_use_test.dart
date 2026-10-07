// 杖的目标选择与治疗的判据。
//
// 出处：`src/DoUseHealStaff.c:33-46`（流程：先 `func(unit)`，再目标选择）、
//       `src/GetUnitItemHealAmount.c:24+`（治疗量，已在 `item_use.dart` 移植）。
// ⚠️ `gSelectInfo_Heal` 的**定义不在反编译里** ⇒ 目标列表的**精确判据未查证**，
//    这里用的是同类函数 `MakeTerrainHealTargetList` 的判据（见 `staff_use.dart` 文件头）。
import 'package:fe8r/core/core.dart';
import 'package:flutter_test/flutter_test.dart';

MapUnit u(int id, {int x = 0, int y = 0, int hp = 10, int maxHp = 20, int f = Faction.blue}) =>
    MapUnit(id: id, faction: f, x: x, y: y, hp: hp, maxHp: maxHp);

void main() {
  test('★ 只治**没满血**的同阵营，排除死亡/敌方/被救走（照 `TryAddUnitToHealTargetList`）', () {
    final user = u(1, x: 0, y: 0);
    final hurt = u(2, x: 1, y: 0, hp: 5);
    final full = u(3, x: 1, y: 0, hp: 20);
    final dead = u(4, x: 1, y: 0, hp: 0);
    final enemy = u(5, x: 1, y: 0, hp: 5, f: Faction.red); // 敌方 = 0x80（factionBit = faction & 0x80）
    // 源码第 2 条只看 `US_RESCUED`（**不是** `US_HIDDEN`）——
    // 所以"隐藏但没被救走"的单位**仍是合法目标**（显示层再决定画不画）。
    final rescued = u(6, x: 1, y: 0, hp: 5)..isRescued = true;
    final got = staffTargets(
      user: user,
      units: [user, hurt, full, dead, enemy, rescued],
      healAmount: 20,
      ranged: false,
    );
    expect(got.map((t) => t.unitId).toList(), [2],
        reason: '满血 / 死亡 / 敌方 / **被救走（US_RESCUED）** 的都不算（逐条照源码）');
  });

  test('★ 相邻型：只有 4 邻居（距离 2 不算），且**施术者自己永远不在列表里**', () {
    final user = u(1, x: 0, y: 0, hp: 5);   // 自己也是残血
    final near = u(2, x: 1, y: 0, hp: 5);   // 距离 1
    final far = u(3, x: 2, y: 0, hp: 5);    // 距离 2
    final got = staffTargets(
        user: user, units: [user, near, far], healAmount: 10, ranged: false);
    expect(got.map((t) => t.unitId).toList(), [2],
        reason: '★ 距离 2 超范围；★ 自己（距离 0）被 `MapAddInRange(x,y,0,-1)` 抹掉');
  });

  test('★ 远程型射程 = `max(5, 魔力/2)`（不是道具射程）', () {
    // `src/GetUnitMagBy2Range.c:12-26`
    expect(magBy2Range(4), 5, reason: '4/2=2 ⇒ 下限 5');
    expect(magBy2Range(14), 7, reason: '14/2=7');
    expect(magBy2Range(30), 15);
    final user = u(1, x: 0, y: 0);
    final at5 = u(2, x: 5, y: 0, hp: 5);
    final at6 = u(3, x: 6, y: 0, hp: 5);
    final got = staffTargets(
        user: user, units: [user, at5, at6],
        healAmount: 10, ranged: true, unitPower: 4); // ⇒ 半径 5
    expect(got.map((t) => t.unitId).toList(), [2], reason: '距离 6 超出半径 5');
  });

  test('★ 被救走的人（`US_RESCUED`）不能治 —— 照源码第 2 条', () {
    final user = u(1, x: 0, y: 0);
    final carried = u(2, x: 1, y: 0, hp: 5)..isRescued = true;
    final got = staffTargets(
        user: user, units: [user, carried], healAmount: 10, ranged: false);
    expect(got, isEmpty);
  });

  test('★ 治疗不超过上限，返回**实际**回复量', () {
    final t = u(2, hp: 15, maxHp: 20);
    expect(applyStaffHeal(t, 20), 5, reason: '只回复 5（到上限为止）');
    expect(t.hp, 20);
    expect(applyStaffHeal(t, 20), 0, reason: '满血回复 0');
  });

  test('治疗量：杖 = 基础 + 魔力，上限 80（`unitItemHealAmount`）', () {
    final names = {10: 'ITEM_STAFF_MEND', 11: 'ITEM_STAFF_HEAL'};
    expect(unitItemHealAmount(itemNumber: 10, isStaff: true, unitPower: 0,
        nameOf: names), 20, reason: 'MEND 基础 20');
    expect(unitItemHealAmount(itemNumber: 11, isStaff: true, unitPower: 4,
        nameOf: names), 14, reason: 'HEAL 基础 10 + 魔力 4');
    expect(unitItemHealAmount(itemNumber: 11, isStaff: true, unitPower: 99,
        nameOf: names), 80, reason: '★ 杖有 80 上限');
    expect(unitItemHealAmount(itemNumber: 11, isStaff: false, unitPower: 99,
        nameOf: names), 10, reason: '非杖不加魔力、也没上限（伤药就是 10）');
  });
}
