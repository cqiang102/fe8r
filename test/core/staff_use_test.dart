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
  test('★ 只治**没满血**的同阵营、且排除隐藏/死亡', () {
    final user = u(1, x: 0, y: 0);
    final hurt = u(2, x: 1, y: 0, hp: 5);
    final full = u(3, x: 1, y: 0, hp: 20);
    final dead = u(4, x: 1, y: 0, hp: 0);
    final enemy = u(5, x: 1, y: 0, hp: 5, f: Faction.red); // 敌方 = 0x80（factionBit = faction & 0x80）
    final hidden = u(6, x: 1, y: 0, hp: 5)..isHidden = true;
    final got = staffTargets(
      user: user,
      units: [user, hurt, full, dead, enemy, hidden],
      healAmount: 20,
      minRange: 1,
      maxRange: 1,
    );
    expect(got.map((t) => t.unitId).toList(), [2],
        reason: '满血/死亡/敌方/被扛走的都不算');
  });

  test('★ 射程：曼哈顿距离落在 [min, max]（自愈杖 min=0 时能选自己吗？——不能）', () {
    final user = u(1, x: 0, y: 0);
    final near = u(2, x: 2, y: 0, hp: 5);   // 距离 2
    final far = u(3, x: 3, y: 0, hp: 5);    // 距离 3
    final got = staffTargets(
        user: user, units: [user, near, far],
        healAmount: 10, minRange: 1, maxRange: 2);
    expect(got.map((t) => t.unitId).toList(), [2], reason: '距离 3 超出射程');
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
