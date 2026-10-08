// PORT OF: src/m4a_1.s:1013-1112（`MPlayMain` 的音轨 tick：初始化 / 取指令 / 分派 / wait 递减）
//
// 把前几轮的零件组装成**一条音轨的一个 tick**：
//
// ```asm
// _081DD874:                        ; 每音轨循环开始
//   ldrb r0, [r5]                   ; track.flags
//   movs r1, 0x80
//   tst  r1, r0
//   bne  _081DD886                  ; ★ bit7 没置 ⇒ 这条轨不跑（跳到下一条）
//   ...
// _081DD8BA:
//   tst  0x40, flags                ; ★ bit6 ⇒ 初始化
//   beq  _081DD938
//   ... Clear64byte + 5 个初值 ...
// _081DD8E0:                        ; ★ 取指令（只在 wait == 0 时到达）
//   ... running status + 分派 ...
// _081DD938:
//   ldrb r0, [r5, o_MusicPlayerTrack_wait]
//   cmp  r0, 0
//   beq  _081DD8E0                  ; ★ wait == 0 ⇒ 取指令
//   subs r0, 0x1
//   strb r0, [r5, o_MusicPlayerTrack_wait]   ; ★ 否则 wait -= 1
// ```
//
// ⚠️ **差一必须照抄**：等待命令把 `wait` 设成 `gClockTable[op-0x80]` 之后，
//    控制流**又回到 `_081DD938`** ⇒ 发出那条命令的**同一帧**就会 `wait -= 1`。
//    例：`W96`（`op = 0xB0`）发出后，`wait` 剩 **95**。

import 'mplay_commands.dart';
import 'mplay_dispatch.dart';
import 'mplay_track.dart';

/// 一个 tick 里这条音轨发生了什么（判据用）
enum MPlayTickOutcome {
  /// `flags` 的 bit7 没置 ⇒ 这条轨不跑
  inactive,

  /// 这一帧只是 `wait -= 1`
  waited,

  /// 取到了音符
  note,

  /// 取到了跳转表命令（`op - 0xB1` = 下标）
  command,

  /// 取到了等待命令（`wait` 被设成 `gClockTable[op - 0x80]`，随后同帧减 1）
  waitCommand,

  /// 取到了**不是命令**的字节（`< 0x80`）—— 正常流程不该发生 ⇒ 响亮报出
  invalidByte,

  /// 指令流用尽
  endOfStream,
}

/// 一次 tick 的结果
class MPlayTickResult {
  const MPlayTickResult(this.outcome, {this.op, this.index, this.handler});

  final MPlayTickOutcome outcome;

  /// 本次读到的字节（音符/命令/等待时）
  final int? op;

  /// 音符下标或跳转表下标
  final int? index;

  /// 跳转表里的处理函数名（用 [MPlayCommand.effective]，即**含运行时覆盖**）
  final String? handler;

  @override
  String toString() => 'MPlayTickResult($outcome, op=$op, index=$index, '
      'handler=$handler)';
}

/// 一条音轨的 tick（组合 [MPlayTrackPort] + [MPlayDispatch]）
MPlayTickResult tickTrack(MPlayTrackPort t) {
  // ★ bit7 没置 ⇒ 这条轨不跑
  if ((t.flags & MPlayTrackPort.flagRunning) == 0) {
    return const MPlayTickResult(MPlayTickOutcome.inactive);
  }
  // ★ wait != 0 ⇒ 本帧只递减
  if (t.wait != 0) {
    t.wait = (t.wait - 1) & 0xFF; // `strb`：8 位
    return const MPlayTickResult(MPlayTickOutcome.waited);
  }
  // ★ wait == 0 ⇒ 取指令（内部会先处理 bit6 的初始化）
  final op = t.fetchCommand();
  if (op == null) return const MPlayTickResult(MPlayTickOutcome.endOfStream);
  final d = MPlayDispatch.classify(op);
  if (d is MPlayInvalid) {
    return MPlayTickResult(MPlayTickOutcome.invalidByte, op: op);
  }
  if (d is MPlayNote) {
    return MPlayTickResult(MPlayTickOutcome.note, op: op, index: d.index);
  }
  if (d is MPlayCommandOp) {
    // 下标直接就是跳转表下标（`subs r0, 0xB1`）
    final cmd = MPlayCommands.table[d.index];
    return MPlayTickResult(MPlayTickOutcome.command, op: op, index: d.index,
        handler: cmd.effective);
  }
  // ★ 等待命令：设 wait，然后**同一帧**再减 1（照抄控制流）
  final w = d as MPlayWait;
  t.wait = w.ticks & 0xFF;
  if (t.wait != 0) t.wait = (t.wait - 1) & 0xFF;
  return MPlayTickResult(MPlayTickOutcome.waitCommand, op: op,
      index: w.clockIndex);
}
