// 用道具（回复类）的判据。
//
// 出处：`src/GetUnitItemHealAmount.c:24-48`（回复量表）、
//       `include/bmitem.h:148-149`（`ITEM_INDEX` / `ITEM_USES`）、
//       `include/bmitem.h:57`（`IA_STAFF`）。
import 'dart:convert';
import 'dart:io';

import 'package:fe8r/core/core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Map<int, String> names; // 编号 → 名字
  late Map<String, int> numbers; // 名字 → 编号
  setUpAll(() {
    final f = File('tools/pipeline/out/tables/items.json');
    if (!f.existsSync()) fail('缺少 ${f.path}');
    final d = jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
    final e = (d['entries'] as Map).cast<String, dynamic>();
    names = {
      for (final v in e.values)
        if ((v as Map)['number'] != null) (v['number'] as num).toInt(): v['key'] as String,
    };
    numbers = {for (final v in e.entries) v.key: ((v.value as Map)['number'] as num).toInt()};
  });

  test('★ 回复量真值：伤药 10 / 万能药(mend) 20 / 圣水(recover) 80', () {
    int heal(String name, {bool staff = false, int pow = 0}) => unitItemHealAmount(
        itemNumber: numbers[name]!, isStaff: staff, unitPower: pow, nameOf: names);
    expect(heal('ITEM_VULNERARY'), 10);
    expect(heal('ITEM_VULNERARY_2'), 10);
    expect(heal('ITEM_STAFF_HEAL'), 10);
    expect(heal('ITEM_STAFF_MEND'), 20);
    expect(heal('ITEM_STAFF_RECOVER'), 80);
    expect(heal('ITEM_ELIXIR'), 80);
    // 不是回复道具 ⇒ 0
    expect(heal('ITEM_SWORD_IRON'), 0);
  });

  test('★ 杖才加魔力、且上限 80（`IA_STAFF` 那一支）', () {
    final n = numbers['ITEM_STAFF_HEAL']!;
    expect(unitItemHealAmount(itemNumber: n, isStaff: true, unitPower: 5, nameOf: names), 15);
    expect(unitItemHealAmount(itemNumber: n, isStaff: true, unitPower: 99, nameOf: names), 80,
        reason: '`if (result > 80) result = 80;`');
    // 非杖：加了 `isStaff=false` ⇒ 不受魔力影响
    expect(unitItemHealAmount(itemNumber: n, isStaff: false, unitPower: 99, nameOf: names), 10);
  });

  test('★ 用一次：HP 加、耐久减；耐久到 0 ⇒ 道具没了', () {
    final n = numbers['ITEM_VULNERARY']!;
    // 耐久 3 的伤药
    final item = makeNewItem(n, 3);
    expect(itemUses(item), 3);
    var r = useHealingItem(hp: 5, maxHp: 20, item: item, itemNumber: n,
        isStaff: false, nameOf: names);
    expect(r.hp, 15, reason: '5 + 10');
    expect(r.healed, 10);
    expect(itemUses(r.item), 2);
    expect(r.consumed, isFalse);
    // 耐久 1 ⇒ 用完就没了
    r = useHealingItem(hp: 5, maxHp: 20, item: makeNewItem(n, 1), itemNumber: n,
        isStaff: false, nameOf: names);
    expect(r.item, 0, reason: '耐久归零 ⇒ 槽清空');
    expect(r.consumed, isTrue);
  });

  test('★ HP 上限：满血附近不会超上限', () {
    final n = numbers['ITEM_VULNERARY']!;
    final r = useHealingItem(hp: 15, maxHp: 20, item: makeNewItem(n, 3), itemNumber: n,
        isStaff: false, nameOf: names);
    expect(r.hp, 20);
    expect(r.healed, 5, reason: '实际只回了 5');
    // 满血用：回了 0，但**耐久照样扣**（原作可用性过滤我没核对，见文件头）
    final r2 = useHealingItem(hp: 20, maxHp: 20, item: makeNewItem(n, 3), itemNumber: n,
        isStaff: false, nameOf: names);
    expect(r2.healed, 0);
    expect(itemUses(r2.item), 2);
  });

  test('不消耗道具（`ITEM_USES == 0`）用完之后原样留着', () {
    final n = numbers['ITEM_VULNERARY']!;
    final item = makeNewItem(n, 0, unbreakable: true);
    expect(itemUses(item), 0);
    final r = useHealingItem(hp: 1, maxHp: 20, item: item, itemNumber: n,
        isStaff: false, nameOf: names);
    expect(r.hp, 11);
    expect(r.item, item, reason: '不消耗 ⇒ 原样');
    expect(r.consumed, isFalse);
  });
}
