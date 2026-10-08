// PORT OF: src/sub_800DBA0.c:7-29（`Event07_SlotQueueOperations`）
//          src/masked_0800d7ec.c:37-40（`SlotQueuePush`）
//          src/SlotQueuePop.c:2-19（`SlotQueuePop`）
//
// 「事件槽队列」——`SENQUEUE`/`SENQUEUE1`/`SDEQUEUE` 用它（产物里 **417 处**）。
// 判据全是**精确算术**：FIFO 顺序、长度写回、以及两个"原作没有检查"的边界。

import 'package:fe8r/core/core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('★ FIFO：先压先弹（源码 `result = p[0]` 后整体左移）', () {
    final q = EventSlotQueue();
    var len = q.push(11, lenInSlot: 0); // 槽 0xD 初始 0
    expect(len, 1);
    len = q.push(22, lenInSlot: len);
    len = q.push(33, lenInSlot: len);
    expect(len, 3);
    expect(q.pop(lenInSlot: len).value, 11, reason: '队首是第一个压进去的');
    expect(q.pop(lenInSlot: 2).value, 22);
    expect(q.pop(lenInSlot: 1).value, 33);
    expect(q.length, 0);
  });

  test('★ 长度由**槽 0xD** 承载（push/pop 都吐回新长度）', () {
    final q = EventSlotQueue();
    final len = q.push(7, lenInSlot: 0);
    expect(len, 1, reason: '`gEventSlots[0xD]++`');
    expect(q.pop(lenInSlot: len).lenInSlot, 0, reason: '`gEventSlots[0xD]--`');
  });

  test('★ 空队列弹出：源码让 0xD 变成 **-1**（照做，但**留痕**）', () {
    final q = EventSlotQueue();
    final r = q.pop(lenInSlot: 0);
    expect(r.lenInSlot, -1, reason: '★ 不钳到 0 —— 源码没有下溢检查');
    expect(q.underflows, 1, reason: '★ 我们额外留痕（原作是静默越界）');
    expect(r.value, 0, reason: '源码读的是旧值（未定义）⇒ 我们用 0，并已留痕');
  });

  test('★ 槽 0xD 被别处改过 ⇒ 记不一致（不静默对齐）', () {
    final q = EventSlotQueue();
    q.push(1, lenInSlot: 0);
    // 现在真实长度 1，但调用方说槽 0xD 是 5
    q.push(2, lenInSlot: 5);
    expect(q.inconsistencies, 1);
    expect(q.length, 2, reason: '仍然真的压进去了（不因为不一致就丢数据）');
  });
}
