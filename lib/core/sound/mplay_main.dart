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
// ```asm
// _081DD9BC:
//   strh r0, [r7, o_MusicPlayerInfo_tempoC]   ; ★ tempoC = tempoC + tempoI（**16 位**存回）
//   cmp  r0, 0x96                             ; ★ 与 150 比较
//   bcc  _081DD9C4                            ; < 150 ⇒ 只走通道更新
//   b    _081DD874                            ; ≥ 150 ⇒ 推进事件那一支
// ```
//
// ```asm
// _081DDA6C:                                  ; 出口（正常与 PAUSE 都汇到这里）
//   ldr r0, lt2_ID_NUMBER
//   str r0, [r7, o_MusicPlayerInfo_ident]     ; ★ ident = ID_NUMBER（复位/解锁）
// ```
//
// ★ **`ident` 是重入锁**：美版 `src/m4a.c:43-50` 的 `MPlayContinue` 把这个惯用法
//   写得很清楚 —— 守卫进、`ident++` 上锁、干活、`ident = ID_NUMBER` 解锁。
//   所以"连续 tick 会被拦下"是我第 15 轮的**误判**（移植不完整造成的假象，
//   而判据把它暴露了出来）。
//
// **还没移植**（明确列出，避免"看着像做完了"）：
//   * 推进事件那一支（`_081DD874` 起，含每音轨的指令读取与 `clock`）；
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

  /// 其中**推进了事件**的次数（`tempoC >= 150`）
  int advancesRun = 0;

  /// 上一次 tick 的 tempo 计数（`tempoC + tempoI`）；暂停/守卫拦住时为 null
  int? lastTempoCount;

  /// 哨兵值（`include/gba/m4a_internal.h:8`）
  static const int idNumber = 0x68736D53;

  /// tempo 门的阈值（`src/m4a_1.s:1161` 的 `cmp r0, 0x96`）
  static const int tempoThreshold = 0x96;

  /// 一个 tick。返回"本 tick 是否**推进了一个事件**"（供上层/判据观察）。
  ///
  /// 流程逐条照抄 `src/m4a_1.s:934-1262`：
  /// 守卫 → `ident++` → 钩子 → PAUSE 门 → `tempoC += tempoI`（16 位）→
  /// `< 150` ⇒ 只更新通道（返回 false）；`≥ 150` ⇒ 推进事件（返回 true）；
  /// **出口：`ident = ID_NUMBER`（复位/解锁）**。
  bool tick() {
    // ★ 入口守卫：ident 不等于哨兵 ⇒ 立刻返回（一个字节都没读）
    if (ident != idNumber) return false;
    ident = ident + 1; // ★ 上锁（原版 `adds r3, 0x1`）
    hook?.call(hookArg);
    // ★ PAUSE 门：status 最高位 ⇒ 直接去出口（`b _081DDA6C`）
    if ((status & MPlayStatus.pause) != 0) {
      ident = idNumber; // ★ 出口复位：**PAUSE 分支也复位**
      return false;
    }
    // ★ tempo 门：`strh` = 16 位存回，所以这里必须**截断**
    tempoC = (tempoC + tempoI) & 0xFFFF;
    lastTempoCount = tempoC;
    ticksRun++;
    final advanced = tempoC >= tempoThreshold;
    if (advanced) advancesRun++;
    // ★ 出口复位（`_081DDA6C`）：正因为有这一步，连续 tick 才跑得下去
    ident = idNumber;
    return advanced;
  }
}
