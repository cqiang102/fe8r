// 道具栏（`struct Unit.items[UNIT_ITEM_COUNT]`）的装载与追加。
//
// ## 为什么必须有这条
//
// `MapUnit.items` 原来是 `[if (item0 != 0) item0]` —— 一个**只有 1 个元素的表**。
// 后果有两个，**都不报错**：
//
//   1. `UnitAddItem`（第一个空槽）永远找不到空槽
//      → `GIVEITEMTO` 永远失败 → **序章里艾莉卡拿不到细剑**（她没有武器）
//   2. `UnitDefinition.items[1..3]` 被丢掉
//      → 赛特本该带 3 件（`{0x03, 0x17, 0x6C}`），实际只剩 1 件
//
// 而当时的转储里 `EIRIKA items=[108]` 就摆在那儿 —— 我看见了，但没读出来。
//
// 出处：
//   * `include/bmunit.h:11`  `enum { UNIT_ITEM_COUNT = 5 };`
//   * `include/bmunit.h:12`  `enum { UNIT_DEFINITION_ITEM_COUNT = 4 };`
//   * `src/exact_08017714.c:37`  UnitClearInventory
//   * `src/exact_080176f0.c:37`  UnitAddItem
//   * `src/MakeNewItem.c:27`     MakeNewItem
//   * `src/UnitInitFromDefinition.c:62`  装载循环
import 'package:fe8r/core/core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UNIT_ITEM_COUNT / UNIT_DEFINITION_ITEM_COUNT（源码常量）', () {
    test('单位道具栏是 5 槽，单位定义里只有 4 槽', () {
      // 这两个数**不是同一个**，混用就会少一件或越界 —— 出处见文件头
      expect(unitItemCount, 5);
      expect(unitDefinitionItemCount, 4);
    });
  });

  group('UnitClearInventory / UnitAddItem', () {
    test('清空后是 5 个 0', () {
      final inv = unitClearInventory();
      expect(inv.length, 5);
      expect(inv, everyElement(0));
    });

    test('UnitAddItem 放进第一个空槽，返回该下标', () {
      final inv = unitClearInventory();
      expect(unitAddItem(inv, 0x1234), 0);
      expect(unitAddItem(inv, 0x5678), 1);
      expect(inv, [0x1234, 0x5678, 0, 0, 0]);
    });

    test('★ 5 槽满了返回 -1（不是"随便找个地方塞"）', () {
      final inv = unitClearInventory();
      for (var i = 0; i < unitItemCount; i++) {
        expect(unitAddItem(inv, 0x100 + i), i);
      }
      expect(unitAddItem(inv, 0x999), -1, reason: '满了必须报失败');
      // 满了之后**内容不能被改**
      expect(inv, [0x100, 0x101, 0x102, 0x103, 0x104]);
    });
  });

  group('MakeNewItem（耐久在高字节）', () {
    test('(uses << 8) | index', () {
      // 细剑：`items.json` 的 ITEM_SWORD_RAPIER maxUses = 40（源码 .maxUses = 40）
      expect(makeNewItem(9, 40), (40 << 8) | 9);
      expect(ItemTable.itemIndex(makeNewItem(9, 40)), 9);
    });

    test('IA_UNBREAKABLE 的道具耐久归零', () {
      // `MakeNewItem` 里 `if (attributes & IA_UNBREAKABLE) uses = 0;`
      expect(makeNewItem(9, 40, unbreakable: true), 9);
    });
  });

  group('inventoryFromDefinition（UnitInitFromDefinition 的装载循环）', () {
    int make(int idx) => makeNewItem(idx, 10);

    test('序章赛特的 3 件道具**全都在**（原来只留第 1 件）', () {
      // `UnitDef_Event_PrologueAlly`：charIndex=2 (SETH) 的 items = {0x03, 0x17, 0x6C}
      final inv = inventoryFromDefinition([0x03, 0x17, 0x6C, 0], make);
      expect(inv.length, unitItemCount);
      expect(inv.take(3).map(ItemTable.itemIndex), [0x03, 0x17, 0x6C]);
      expect(inv.sublist(3), [0, 0], reason: '剩下的槽必须是空的');
    });

    test('只有 1 件时，后面 4 个槽是空的（GIVEITEMTO 才有地方放）', () {
      // `UnitDef_Event_PrologueAlly`：艾莉卡 items = {0x6C, 0, 0, 0}
      final inv = inventoryFromDefinition([0x6C, 0, 0, 0], make);
      expect(inv[0], make(0x6C));
      expect(inv.sublist(1), [0, 0, 0, 0]);
      // 细剑来了要放得进去 —— 这正是原来失败的那一步
      expect(unitAddItem(inv, make(9)), 1);
    });

    test('0 是**终止符**：遇到就停，后面的槽不再看', () {
      // 源码的循环条件是 `(i < 4) && (uDef->items[i])`，不是"跳过这一件"
      final inv = inventoryFromDefinition([0x03, 0, 0x6C, 0], make);
      expect(ItemTable.itemIndex(inv[0]), 0x03);
      expect(inv.sublist(1), [0, 0, 0, 0], reason: '0 之后的 0x6C 不该被载入');
    });
  });

  group('MapUnit 的道具栏', () {
    MapUnit unit({List<int>? items, int item0 = 0}) => MapUnit(
          id: 1,
          faction: Faction.blue,
          x: 0,
          y: 0,
          items: items,
          item0: item0,
        );

    test('显式给的表也补齐到 5 槽', () {
      final u = unit(items: [0x1234]);
      expect(u.items.length, unitItemCount);
      expect(u.items, [0x1234, 0, 0, 0, 0]);
    });

    test('只给 item0 时同样是 5 槽（这是修 bug 前唯一的那条路）', () {
      final u = unit(item0: 0x6C);
      expect(u.items.length, unitItemCount);
      expect(u.items[0], 0x6C);
      expect(u.items.sublist(1), [0, 0, 0, 0]);
    });

    test('addItem 走 UnitAddItem —— 满 5 件后返回 -1', () {
      final u = unit();
      for (var i = 0; i < unitItemCount; i++) {
        expect(u.addItem(0x100 + i), i);
      }
      expect(u.addItem(0x999), -1);
    });

    test('heldItems 只列非空槽', () {
      final u = unit(items: [0x6C, 9, 0, 0, 0]);
      expect(u.heldItems, [0x6C, 9]);
    });

    test('道具栏与 charIndex 进得了存档', () {
      final u = unit(items: [0x6C, 9, 0, 0, 0]);
      final back = MapUnit.fromJson(u.toJson());
      expect(back.items, u.items);
      expect(back.charIndex, u.charIndex);
    });
  });
}
