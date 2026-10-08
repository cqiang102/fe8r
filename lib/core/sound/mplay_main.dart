// PORT OF: src/m4a_1.s:934-1000（`MPlayMain`，日版带符号名注解的汇编）
//          + include/gba/m4a_internal.h:8（`ID_NUMBER`）、:283-295（status 位）
//          + lib/core/sound/m4a_layout.dart（`MusicPlayerInfo` 字段偏移）
//
// ⚠️ **美版也没有这个函数的 C 代码**：`fireemblem8u/src/m4a.c:562` 只是
//    `soundInfo->func = (u32)MPlayMain;`（引用），函数体在 **`src/m4a_1.s`**。
//    所以规则段只能从**带注解的汇编**移植 —— 好在注解里有符号名
//    （`o_MusicPlayerInfo_tempoC` / `lt2_ID_NUMBER` 之类），可以逐行读。
//
// 本文件目前只移植**已逐行核对过**的三条语义（其余明确未做）：
//
// ```asm
// MPlayMain:
//   ldr r2, lt2_ID_NUMBER
//   ldr r3, [r0, o_MusicPlayerInfo_ident]
//   cmp r2, r3
//   beq _081DD82E          ; 等于才继续
//   bx lr                  ; ★ 不等于 ⇒ 立刻返回（本 tick 什么都不做）
// _081DD82E:
//   adds r3, 0x1
//   str  r3, [r0, o_MusicPlayerInfo_ident]   ; ★ ident += 1（同时充当帧计数）
//   push {r0,lr}
//   ldr r3, [r0, o_MusicPlayerInfo_func]
//   cmp r3, 0
//   beq _081DD840
//   ldr r0, [r0, o_MusicPlayerInfo_intp]
//   bl call_r3                               ; ★ func 钩子（intp 作为参数）
// _081DD840: ...
//   ldr r0, [r7, o_MusicPlayerInfo_status]
//   cmp r0, 0
//   bge _081DD858
//   b _081DDA6C                              ; ★ status 最高位（PAUSE）⇒ 跳到末尾
// _081DD858: ...
//   ldrh r0, [r7, o_MusicPlayerInfo_tempoC]
//   ldrh r1, [r7, o_MusicPlayerInfo_tempoI]
//   adds r0, r1                              ; ★ 本 tick 的计数 = tempoC + tempoI
// ```
//
// **还没移植**（明确列出，避免"看着像做完了"）：
//   * `_081DD9BC` 处的计数比较（`clock` 与阈值的推进规则）；
//   * 每音轨的循环（`trackCount` / `o_MusicPlayerTrack_chan` / `0xC7` 掩码那一段）；
//   * `FadeOutBody`（淡出的实际推进）；
//   * `CgbSound` / `SoundMain`（混音与写寄存器）。

import 'm4a_layout.dart';

/// `MPlayMain` 的**已移植部分**：入口契约（`ident` 守卫 + `func` 钩子 + PAUSE 门）
/// 与每 tick 的 tempo 计数。
///
/// 用法：每个音频帧调用一次 [tick]（原版由 `SoundMain` 的 VBlank/定时驱动）。
class MPlayMainPort {
  MPlayMainPort({required this.ident, required this.status, required this.tempoC,
      required this.tempoI, this.hook});

  /// 对应 `MusicPlayerInfo.ident`（`@52`）。**初值不是 `ID_NUMBER`** 时本函数不做事。
  int ident;

  /// 对应 `MusicPlayerInfo.status`（`@4`）。最高位 = PAUSE。
  int status;

  /// 对应 `MusicPlayerInfo.tempoC`（`@34`）：当前速度
  int tempoC;

  /// 对应 `MusicPlayerInfo.tempoI`（`@32`）：每 tick 增量
  int tempoI;

  /// 对应 `MusicPlayerInfo.func`（`@56`）：可选钩子
  void Function(int intp)? hook;

  /// 对应 `MusicPlayerInfo.intp`（`@60`）：传给钩子的参数
  int hookArg = 0;

  /// 本实例跑过多少次"真正做了事"的 tick（判据用）
  int ticksRun = 0;

  /// 上一次 tick 的 tempo 计数（`tempoC + tempoI`）；暂停/守卫拦住时为 null
  int? lastTempoCount;

  /// 哨兵值（`include/gba/m4a_internal.h:8`）
  static const int idNumber = 0x68736D53;

  /// 一个 tick。返回"这次真的做了事"（供上层/判据观察）。
  bool tick() {
    // ★ 入口守卫：ident 不等于哨兵 ⇒ 立刻返回（一个字节都没读）
    if (ident != idNumber) return false;
    ident = ident + 1; // ★ ident += 1（原版就是这么写的；它同时是帧计数）
    hook?.call(hookArg);
    // ★ PAUSE 门：status 最高位 ⇒ 本 tick 跳过（原版 `b _081DDA6C`）
    if ((status & MPlayStatus.pause) != 0) return false;
    // ★ 本 tick 的 tempo 计数
    lastTempoCount = tempoC + tempoI;
    ticksRun++;
    return true;
  }
}
