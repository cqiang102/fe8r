// 音轨步进（第 18 轮）—— 逐条对着 `src/m4a_1.s:1013-1043`
//
// ★ 判据：
//   1. `flags & 0x40` ⇒ 初始化，且 5 个初值**逐个**对上汇编（0x80/2/0x40/0x16/1）；
//   2. 命令字节 `≥ 0x80` ⇒ **消费**；`≥ 0xBD` ⇒ 记进 running status；
//   3. 参数字节 `< 0x80` ⇒ **不消费**，命令取 running status。

import 'package:fe8r/core/core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('★ 初始化常量逐个对上汇编（`_081DD8BA` 那 6 步）', () {
    expect(MPlayTrackPort.initFlags, 0x80);
    expect(MPlayTrackPort.initBendRange, 0x2);
    expect(MPlayTrackPort.initVolX, 0x40);
    expect(MPlayTrackPort.initLfoSpeed, 0x16);
    expect(MPlayTrackPort.initToneType, 0x1);
    expect(MPlayTrackPort.clearBytes, 64, reason: 'Clear64byte');
  });

  test('★ flags bit6 置位 ⇒ 初始化（初值写进去、bit7 变在跑）', () {
    final t = MPlayTrackPort(flags: MPlayTrackPort.flagNeedsInit)
      ..bendRange = 9
      ..volX = 9
      ..load([0x80]);
    t.fetchCommand();
    expect(t.flags, MPlayTrackPort.flagRunning);
    expect(t.bendRange, MPlayTrackPort.initBendRange);
    expect(t.volX, MPlayTrackPort.initVolX);
    expect(t.lfoSpeed, MPlayTrackPort.initLfoSpeed);
    expect(t.toneType, MPlayTrackPort.initToneType);
  });

  test('★ bit6 没置 ⇒ 不初始化（已设的值保持不变）', () {
    final t = MPlayTrackPort(flags: MPlayTrackPort.flagRunning)
      ..bendRange = 9
      ..volX = 7
      ..load([0x80]);
    t.fetchCommand();
    expect(t.bendRange, 9, reason: '不该被重置');
    expect(t.volX, 7);
  });

  test('★ 命令字节 ≥ 0x80 被消费；≥ 0xBD 记进 running status', () {
    final t = MPlayTrackPort(flags: MPlayTrackPort.flagRunning)
      ..load([0xB0, 0xBD, 0xC0]);
    expect(t.fetchCommand(), 0xB0, reason: '< 0xBD ⇒ 不记 running status');
    expect(t.runningStatus, 0, reason: '0xB0 小于阈值 0xBD');
    expect(t.cmdIndex, 1);
    expect(t.fetchCommand(), 0xBD);
    expect(t.runningStatus, 0xBD, reason: '≥ 0xBD ⇒ 记下');
    expect(t.fetchCommand(), 0xC0);
    expect(t.runningStatus, 0xC0, reason: '更大的也记');
  });

  test('★ 参数字节 < 0x80 ⇒ 不消费，命令取 running status', () {
    final t = MPlayTrackPort(flags: MPlayTrackPort.flagRunning)
      ..load([0xC0, 0x40]);
    expect(t.fetchCommand(), 0xC0);
    final before = t.cmdIndex;
    expect(t.fetchCommand(), 0xC0, reason: '0x40 是参数 ⇒ 沿用 0xC0');
    expect(t.cmdIndex, before, reason: '★ 参数字节**不能**被消费');
  });

  test('★ 字节用尽 ⇒ null（不返回假命令）', () {
    final t = MPlayTrackPort(flags: MPlayTrackPort.flagRunning)..load([]);
    expect(t.fetchCommand(), isNull);
    t.load([0x80]);
    expect(t.fetchCommand(), 0x80);
    expect(t.fetchCommand(), isNull, reason: '只有 1 个字节');
  });
}
