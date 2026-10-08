// 命令分派（第 19 轮）—— 逐条对着 `src/m4a_1.s:1046-1076`
//
// ★ 判据：
//   1. `op >= 0xCF` ⇒ 音符，`index = op - 0xCF`；
//   2. `0xB1..0xCE` ⇒ 跳转表命令，`index = op - 0xB1`（上界 **29** ⇒ 印证 36 项表里后 6 项不是指令）；
//   3. `0x80..0xB0` ⇒ 等待，`ticks = gClockTable[op - 0x80]`（**49 条**，且尾部不连续）；
//   4. `< 0x80` ⇒ **不是命令**（参数/无效），必须显式返回 Invalid。

import 'package:fe8r/core/core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('★ 三个基址与区间（都是汇编里的立即数）', () {
    expect(MPlayDispatch.noteBase, 0xCF);
    expect(MPlayDispatch.commandBase, 0xB1);
    expect(MPlayDispatch.waitBase, 0x80);
    expect(MPlayDispatch.waitMax, 0xB0);
    expect(MPlayDispatch.commandMax, 0xCE);
  });

  test('★ 音符：≥0xCF ⇒ index = op - 0xCF', () {
    expect((MPlayDispatch.classify(0xCF) as MPlayNote).index, 0);
    expect((MPlayDispatch.classify(0xD0) as MPlayNote).index, 1);
    expect((MPlayDispatch.classify(0xFF) as MPlayNote).index, 0x30);
  });

  test('★ 跳转表命令：0xB1..0xCE ⇒ index = op - 0xB1，上界 29', () {
    expect((MPlayDispatch.classify(0xB1) as MPlayCommandOp).index, 0, reason: 'FINE');
    expect((MPlayDispatch.classify(0xBB) as MPlayCommandOp).index, 10, reason: 'TEMPO');
    expect((MPlayDispatch.classify(0xCE) as MPlayCommandOp).index, 29, reason: 'ENDTIE');
    expect(MPlayDispatch.maxCommandIndex, 29);
    // ⇒ 跳转表 36 项里后 6 项（30..35）**不是指令**（与第 17 轮那张表互证）
    expect(MPlayCommands.count - (MPlayDispatch.maxCommandIndex + 1), 6);
  });

  test('★ 等待：0x80..0xB0 ⇒ ticks = gClockTable[op - 0x80]（49 条）', () {
    expect(gClockTable.length, 49, reason: '0xB0 - 0x80 + 1');
    expect((MPlayDispatch.classify(0x80) as MPlayWait).ticks, 0, reason: '表首是 0');
    expect((MPlayDispatch.classify(0xB0) as MPlayWait).ticks, 96, reason: '表尾是 96');
    // ★ 尾部**不连续** ⇒ 只能查表（手抄会错）
    expect((MPlayDispatch.classify(0xB0) as MPlayWait).clockIndex, 48);
    expect(gClockTable[48], 96);
    expect(gClockTable[47], 92);
    expect(gClockTable[46], 90);
  });

  test('★ <0x80 ⇒ 不是命令（参数/无效），显式返回 Invalid', () {
    for (final op in [0x00, 0x40, 0x7F]) {
      expect(MPlayDispatch.classify(op), isA<MPlayInvalid>(), reason: 'op=$op');
    }
  });
}
