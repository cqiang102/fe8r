// PORT OF: src/m4a_1.s:1046-1076（`MPlayMain` 的命令分派）
//          + src/m4a_tables.c:122-170（`gClockTable`，等待时长）
//          + lib/core/sound/mplay_commands.dart（跳转表 36 项）
//
// 逐行对照（`src/m4a_1.s:1046-1076`）：
//
// ```asm
// _081DD8F6:
//   cmp r1, 0xCF
//   bcc _081DD90C
//   mov r0, r8
//   ldr r3, [r0, o_SoundInfo_plynote]
//   adds r0, r1, 0
//   subs r0, 0xCF                    ; ★ 音符：下标 = 命令 - 0xCF
//   bl call_r3                       ; ⇒ plynote(...)
//   b _081DD938
// _081DD90C:
//   cmp r1, 0xB0
//   bls _081DD92E                    ; ★ ≤0xB0 ⇒ 等待
//   adds r0, r1, 0
//   subs r0, 0xB1                    ; ★ 跳转表命令：index = 命令 - 0xB1
//   strb r0, [r7, o_MusicPlayerInfo_cmd]
//   ldr r3, [SoundInfo.MPlayJumpTable]
//   lsls r0, 2
//   ldr r3, [r3, r0]
//   bl call_r3
// _081DD92E:
//   ldr r0, lt_gClockTable
//   subs r1, 0x80
//   adds r1, r0
//   ldrb r0, [r1]
//   strb r0, [r5, o_MusicPlayerTrack_wait]   ; ★ wait = gClockTable[命令 - 0x80]
// ```

import 'm4a_tables.g.dart';

/// 分派结果
sealed class MPlayOp {
  const MPlayOp(this.op);
  final int op;
}

/// 音符（`op >= 0xCF`）：`index = op - 0xCF`
class MPlayNote extends MPlayOp {
  const MPlayNote(super.op) : super();
  int get index => op - MPlayDispatch.noteBase;
}

/// 跳转表命令（`0xB1..0xCE`）：`index = op - 0xB1`（**就是跳转表下标**）
class MPlayCommandOp extends MPlayOp {
  const MPlayCommandOp(super.op) : super();
  int get index => op - MPlayDispatch.commandBase;
}

/// 等待（`0x80..0xB0`）：`wait = gClockTable[op - 0x80]` 个 tick
class MPlayWait extends MPlayOp {
  const MPlayWait(super.op) : super();
  int get clockIndex => op - MPlayDispatch.waitBase;
  int get ticks => gClockTable[clockIndex];
}

/// 参数/无效字节（`< 0x80`）：**不是命令** —— 它属于上一条命令
/// （`src/m4a_1.s:1031-1034` 的 running status 规则）
class MPlayInvalid extends MPlayOp {
  const MPlayInvalid(super.op) : super();
}

abstract final class MPlayDispatch {
  /// 音符基址（`cmp r1, 0xCF`）
  static const int noteBase = 0xCF;

  /// 跳转表命令基址（`subs r0, 0xB1`）
  static const int commandBase = 0xB1;

  /// 等待基址（`subs r1, 0x80`）
  static const int waitBase = 0x80;

  /// 等待区间的上界（含）：`cmp r1, 0xB0` / `bls`
  static const int waitMax = 0xB0;

  /// 跳转表命令区间的上界（含）：`0xCE`（`cmp r1, 0xCF` 的反面）
  static const int commandMax = 0xCE;

  /// ★ 可由"跳转表命令"到达的**下标上界**：`commandMax - commandBase` = **29**
  ///
  /// ⇒ 跳转表 36 项里**后 6 项**（30..35：`SampleFreqSet`/`TrackStop`/
  /// `FadeOutBody`/`TrkVolPitSet`/`RealClearChain`/`SoundMainBTM`）
  /// **不是指令**，是内部函数 —— 与 36 项表**互相印证**。
  static int get maxCommandIndex => commandMax - commandBase;

  /// 分派一个字节（**只分派，不执行**）
  static MPlayOp classify(int op) {
    if (op >= noteBase) return MPlayNote(op);
    if (op > waitMax) return MPlayCommandOp(op);
    if (op >= waitBase) return MPlayWait(op);
    return MPlayInvalid(op);
  }
}
