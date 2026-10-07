// 输送队（convoy）的判据。
//
// 出处：`src/bmcontainer.c:54-77`、`include/bmcontainer.h:7`、
//       `src/SupplyUsability.c:51-80`、`src/SendToConvoyMenu_NormalEffect.c:24-27`。
import 'package:fe8r/core/core.dart';
import 'package:flutter_test/flutter_test.dart';

List<int> emptyConvoy([int n = 5]) => List<int>.filled(n, 0);

void main() {
  test('★ `AddItemToConvoy` 放第一个空槽并返回下标', () {
    final c = emptyConvoy();
    expect(addItemToConvoy(c, 11), 0);
    expect(addItemToConvoy(c, 22), 1);
    c[0] = 0; // 挖个洞
    expect(addItemToConvoy(c, 33), 0, reason: '洞里优先（原文就是找第一个 0）');
    expect(c, [33, 22, 0, 0, 0]);
  });

  test('★ 满了 ⇒ 返回 -1，且**数组一点没变**（原文把道具留在暂存格，不丢）', () {
    final c = [11, 22, 33];
    expect(addItemToConvoy(c, 44), -1);
    expect(c, [11, 22, 33], reason: '★ 不覆盖、不丢弃 —— 调用方还留着那件道具');
    expect(convoyCount(c), 3);
  });

  test('★ `RemoveItemFromConvoy` 取出后**压缩**（`ShrinkConvoyItemList`）', () {
    final c = [11, 22, 33, 0, 0];
    removeItemFromConvoy(c, 0);
    expect(c, [22, 33, 0, 0, 0], reason: '后面的往前挪');
    removeItemFromConvoy(c, 1);
    expect(c, [22, 0, 0, 0, 0]);
    removeItemFromConvoy(c, 99); // 越界：不动，不崩
    expect(c, [22, 0, 0, 0, 0]);
  });

  test('★ 容量常量：`CONVOY_ITEM_COUNT = 100`', () {
    expect(convoyItemCount, 100);
    final c = List<int>.filled(100, 0);
    expect(addItemToConvoy(c, 7), 0);
    for (var i = 1; i < 100; i++) {
      addItemToConvoy(c, i + 100);
    }
    expect(convoyCount(c), 100);
    expect(addItemToConvoy(c, 999), -1, reason: '第 101 件放不下');
  });

  test('★ 谁能用输送：`HasConvoyAccess` + 非幻影 + **领袖**（按章节模式）', () {
    expect(convoyLeaderId(chapterModeIndex: 1), kCharacterEirika, reason: '教学/艾莉卡');
    expect(convoyLeaderId(chapterModeIndex: 2), kCharacterEphraim, reason: '艾弗雷姆路线');
    expect(convoyLeaderId(chapterModeIndex: 9), kCharacterEirika, reason: 'default ⇒ 艾莉卡');
    bool ok({bool access = true, bool phantom = false, bool leader = true}) =>
        supplyAvailable(
            hasConvoyAccess: access, isPhantom: phantom, isLeader: leader);
    expect(ok(), isTrue);
    expect(ok(access: false), isFalse, reason: '`HasConvoyAccess()` 为假');
    expect(ok(phantom: true), isFalse, reason: '幻影职业');
    expect(ok(leader: false), isFalse, reason: '不是领袖');
  });
}
