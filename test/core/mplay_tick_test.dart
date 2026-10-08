// 音轨 tick（第 20 轮）—— 组装前几轮的零件，逐条对着 `src/m4a_1.s:1013-1112`
//
// ★ 判据里最重要的一条是**差一**：等待命令发出后**同一帧**就 `wait -= 1`
//   （控制流又回到 `_081DD938`）。`W96` ⇒ 发出后剩 **95**。
//   ⚠️ 我第一版差点把它写成"发出后剩 96"（那会让所有等待长一帧，
//      而且不会报错 —— 正是本仓库最怕的形状）。

import 'package:fe8r/core/core.dart';
import 'package:flutter_test/flutter_test.dart';

MPlayTrackPort track(List<int> code, {int flags = 0x80}) =>
    MPlayTrackPort(flags: flags)..load(code);

void main() {
  test('★ bit7 没置 ⇒ 这条轨不跑（wait 也不动）', () {
    final t = track([0x80], flags: 0)..wait = 5;
    final r = tickTrack(t);
    expect(r.outcome, MPlayTickOutcome.inactive);
    expect(t.wait, 5);
    expect(t.cmdIndex, 0, reason: '一个字节都没读');
  });

  test('★ wait != 0 ⇒ 只递减（不读指令）', () {
    final t = track([0x80])..wait = 3;
    expect(tickTrack(t).outcome, MPlayTickOutcome.waited);
    expect(t.wait, 2);
    expect(t.cmdIndex, 0);
    tickTrack(t);
    tickTrack(t);
    expect(t.wait, 0);
    // wait 归零后的下一帧才读指令。
    // ⚠️ 我第一版这里写 `command` —— 错：`0x80` 本身就是**等待**命令
    //    （`gClockTable[0] == 0` ⇒ 不设等待），所以结果是 `waitCommand`。
    expect(tickTrack(t).outcome, MPlayTickOutcome.waitCommand);
    expect(t.cmdIndex, 1, reason: '这一帧确实读了那个字节');
  });

  test('★ wait == 0 ⇒ 取指令并分派：音符 / 命令 / 等待', () {
    // 0xCF ⇒ 音符 index 0
    expect(tickTrack(track([0xCF])).outcome, MPlayTickOutcome.note);
    expect(tickTrack(track([0xCF])).index, 0);
    // 0xB1 ⇒ 命令 index 0 = FINE（跳转表第 0 项）
    final c = tickTrack(track([0xB1]));
    expect(c.outcome, MPlayTickOutcome.command);
    expect(c.index, 0);
    expect(c.handler, 'ply_fine');
    // 0xBB ⇒ index 10 = TEMPO（`ply_tempo`）
    expect(tickTrack(track([0xBB])).handler, 'ply_tempo');
    // 0xB9 ⇒ index 8 = 运行时覆盖成 ply_memacc（不是模板的 ply_fine）
    expect(tickTrack(track([0xB9])).handler, 'ply_memacc',
        reason: '★ 只记模板值会把 MEMACC 当成 FINE');
  });

  test('★★ 差一：等待命令发出后**同一帧**就减 1（W96 ⇒ 剩 95）', () {
    final t = track([0xB0]); // op 0xB0 = 等待表最后一项 ⇒ ticks 96
    final r = tickTrack(t);
    expect(r.outcome, MPlayTickOutcome.waitCommand);
    expect(r.index, 48, reason: 'gClockTable[48]');
    expect(t.wait, 95, reason: '★ 96 发出后同帧减 1 ⇒ 95（照抄控制流）');
    // 之后每帧减 1，共还要 95 帧
    var frames = 0;
    while (t.wait != 0) {
      expect(tickTrack(t).outcome, MPlayTickOutcome.waited);
      frames++;
      if (frames > 200) fail('wait 没有递减完');
    }
    expect(frames, 95, reason: '96 tick 的等待 = 发出帧 1 + 递减 95');
  });

  test('★ wait == 0 的等待命令（op 0x80）⇒ 不设等待、直接取下一个字节', () {
    final t = track([0x80, 0xB0]);
    final r1 = tickTrack(t);
    expect(r1.outcome, MPlayTickOutcome.waitCommand);
    expect(r1.index, 0, reason: 'gClockTable[0] == 0');
    expect(t.wait, 0, reason: '0 ⇒ 不减（代码里 `if (wait != 0)`）');
    // 下一帧接着读后面的字节
    final r2 = tickTrack(t);
    expect(r2.outcome, MPlayTickOutcome.waitCommand);
    expect(r2.op, 0xB0);
  });

  test('★ 小于 0x80 的字节 ⇒ 显式报 invalidByte（不静默当命令）', () {
    final t = track([0x40], flags: 0x80);
    expect(tickTrack(t).outcome, MPlayTickOutcome.invalidByte);
  });

  test('★ 指令流用尽 ⇒ endOfStream', () {
    final t = track([]);
    expect(tickTrack(t).outcome, MPlayTickOutcome.endOfStream);
  });
}
