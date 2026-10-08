// `MPlayMain` 已移植部分（第 15 轮）—— 逐条对着 `src/m4a_1.s:934-1000` 的汇编
//
// ★ 判据：三条语义各自可观察
//   1. `ident != ID_NUMBER` ⇒ **立刻返回**（钩子都不调、计数不更新）；
//   2. `ident == ID_NUMBER` ⇒ `ident += 1` 且调 `func` 钩子（参数是 `intp`）；
//   3. `status` 最高位（PAUSE）⇒ 跳过本 tick（`lastTempoCount` 不变）；
//   4. 正常 tick ⇒ 计数 = `tempoC + tempoI`。

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

  test('★ ident == ID_NUMBER ⇒ ident += 1 并调钩子（参数是 intp）', () {
    final got = <int>[];
    final p = make()..hook = (v) => got.add(v);
    p.hookArg = 0xABC;
    expect(p.tick(), isTrue);
    expect(p.ident, MPlayMainPort.idNumber + 1, reason: '原版 `adds r3, 0x1`');
    expect(got, [0xABC], reason: '钩子拿到的是 intp');
  });

  test('★ PAUSE 门：status 最高位 ⇒ 跳过计数（但 ident 已经 += 1）', () {
    var called = 0;
    final p = make(status: MPlayStatus.pause)..hook = ((_) => called++);
    expect(p.tick(), isFalse, reason: '本 tick 不做事');
    expect(called, 1, reason: '钩子在 PAUSE 判断**之前**（原版顺序如此）');
    expect(p.ident, MPlayMainPort.idNumber + 1, reason: 'ident 先加了');
    expect(p.lastTempoCount, isNull, reason: '没走到 tempo 计数');
    expect(p.ticksRun, 0);
  });

  test('★ 正常 tick：计数 = tempoC + tempoI', () {
    final p = make(tempoC: 0x10, tempoI: 0x05);
    expect(p.tick(), isTrue);
    expect(p.lastTempoCount, 0x15, reason: 'tempoC + tempoI');
  });

  test('★ **连续 tick 会被守卫拦下** —— 谁复位 ident 还没查证', () {
    // ⚠️ 这是判据帮我发现的真问题：`ident` 自增之后，下一次 `tick()` 不再等于
    //   `ID_NUMBER` ⇒ 守卫直接返回 ⇒ **连续调用不会连续跑**。
    //   原版必然有别处把它复位（M4A 的经典做法是 `SoundMain` 每帧重置），
    //   但**我还没读到那一处** ⇒ 标「未查证」，下一步读 `SoundMain` 时一并确认。
    final p = make(tempoC: 0x10, tempoI: 0x05);
    expect(p.tick(), isTrue);
    expect(p.tick(), isFalse, reason: 'ident 已是 ID_NUMBER+1');
    expect(p.ticksRun, 1);
    // 复位之后又能跑（把上面那条"未查证"变成可验证的假设）
    p.ident = MPlayMainPort.idNumber;
    expect(p.tick(), isTrue);
    expect(p.ticksRun, 2);
  });
}
