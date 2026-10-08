// `MPlayMain` 已移植部分（第 15–16 轮）—— 逐条对着 `src/m4a_1.s:934-1262`
//
// ★ 已核对的语义：
//   1. 入口守卫：`ident != ID_NUMBER` ⇒ **立刻返回**（钩子都不调）；
//   2. `ident++` 上锁 + 调 `func` 钩子（参数 `intp`）；
//   3. PAUSE 门：`status` 最高位 ⇒ 跳过 tempo 计数（但**钩子已调**，顺序照抄）；
//   4. tempo 门：`tempoC = (tempoC + tempoI) & 0xFFFF`（`strh` 是 16 位）；
//      `< 150` ⇒ 只更新通道；`>= 150` ⇒ **推进一个事件**；
//      ⇒ 所以 `tick()` 的返回值是"**是否推进了事件**"，不是"是否跑了"。
//   5. **出口复位** `ident = ID_NUMBER`（`src/m4a_1.s:1254`，PAUSE 分支也走这里）。
//
// ★★ 第 15 轮我在这里判**错**过一次：写过"连续 tick 会被守卫拦下" ✗ ——
//   真相是 `ident` 是**重入锁**（美版 `src/m4a.c:43-50` 的 `MPlayContinue` 写得很清楚：
//   守卫进 → `ident++` 上锁 → 干活 → `ident = ID_NUMBER` 解锁），所以每帧都能进。
//   那是**移植不完整**造出的假象，判据把它暴露了出来。
//   ⇒ 本轮把旧模型的两条测试**删掉**（留错模型比没测试更糟）。

import 'package:fe8r/core/core.dart';
import 'package:flutter_test/flutter_test.dart';

MPlayMainPort make({int? ident, int status = 0, int tempoC = 0, int tempoI = 0}) =>
    MPlayMainPort(
      ident: ident ?? MPlayMainPort.idNumber,
      status: status,
      tempoC: tempoC,
      tempoI: tempoI,
    );

void main() {
  test('★ ID_NUMBER 是 0x68736D53（`m4a_internal.h:8`）', () {
    expect(MPlayMainPort.idNumber, 0x68736D53);
  });

  test('★ 守卫：ident 不等于 ID_NUMBER ⇒ 立刻返回，钩子一次都不调', () {
    var called = 0;
    final p = make(ident: 0x12345678)..hook = ((_) => called++);
    expect(p.tick(), isFalse);
    expect(called, 0, reason: '守卫在钩子之前');
    expect(p.ident, 0x12345678, reason: 'ident 不动');
    expect(p.lastTempoCount, isNull);
    expect(p.ticksRun, 0);
  });

  test('★ 锁的语义：上锁（ident++）→ 干活 → 出口复位', () {
    final got = <int>[];
    final p = make(tempoC: 0, tempoI: 0x30)..hook = (v) => got.add(v);
    p.hookArg = 0xABC;
    p.tick();
    expect(got, [0xABC], reason: '钩子拿到的是 intp');
    expect(p.ident, MPlayMainPort.idNumber, reason: '出口必须已解锁');
  });

  test('★ 出口会复位 ident ⇒ 连续 tick 跑得下去（第 15 轮判错的那条）', () {
    final p = make(tempoC: 0, tempoI: 0x10);
    for (var i = 1; i <= 5; i++) {
      p.tick();
      expect(p.ident, MPlayMainPort.idNumber, reason: '第 $i 次之后必须已解锁');
    }
    expect(p.ticksRun, 5, reason: '5 帧都真的跑了（tempoC 有累加）');
  });

  test('★ PAUSE 门：status 最高位 ⇒ 不计数（但钩子已调、出口已复位）', () {
    var called = 0;
    final p = make(status: MPlayStatus.pause)..hook = ((_) => called++);
    expect(p.tick(), isFalse, reason: '本 tick 不推进事件');
    expect(called, 1, reason: '钩子在 PAUSE 判断**之前**（原版顺序如此）');
    expect(p.ident, MPlayMainPort.idNumber, reason: 'PAUSE 也走出口复位');
    expect(p.lastTempoCount, isNull, reason: '没走到 tempo 计数');
    expect(p.ticksRun, 0);
  });

  test('★ tempo 门：每帧累加 tempoI，累到 150 才推进一步；16 位截断', () {
    // 0x96 = 150（`src/m4a_1.s:1161` 的 `cmp r0, 0x96`）
    expect(MPlayMainPort.tempoThreshold, 0x96);
    final p = make(tempoC: 0, tempoI: 0x30); // 48
    expect(p.tick(), isFalse, reason: '48 < 150');
    expect(p.lastTempoCount, 48);
    expect(p.tick(), isFalse, reason: '96 < 150');
    expect(p.tick(), isFalse, reason: '144 < 150');
    expect(p.tick(), isTrue, reason: '192 ≥ 150 ⇒ 推进一个事件');
    expect(p.lastTempoCount, 192);
    expect(p.advancesRun, 1);
    // `strh` ⇒ 16 位截断（不是无限累加）
    final q = make(tempoC: 0xFFF0, tempoI: 0x20);
    q.tick();
    expect(q.tempoC, (0xFFF0 + 0x20) & 0xFFFF, reason: 'strh 的 16 位语义');
  });
}
