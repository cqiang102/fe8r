// PORT OF: src/m4a_1.s:700-711（`ply_tempo`）
//          + src/m4aMPlayTempoControl.c:5-14（**日版是 C，而且与美版逐行一致**，
//            见 docs/路线图.md 记录）
//          + lib/core/sound/mplay_main.dart（150 门）
//
// 时轴的完整链条：
//
// ```asm
// ply_tempo:                       ; TEMPO 命令（跳转表下标 10）
//   bl ld_r3_tp_adr_i              ; r3 = 操作数
//   lsls r3, 1                     ; ★ tempoD = arg * 2
//   strh r3, [r0, o_MusicPlayerInfo_tempoD]
//   ldrh r2, [r0, o_MusicPlayerInfo_tempoU]
//   muls r3, r2
//   lsrs r3, 8                     ; ★ tempoI = (tempoD * tempoU) >> 8
//   strh r3, [r0, o_MusicPlayerInfo_tempoI]
// ```
//
// ```c
// void m4aMPlayTempoControl(struct MusicPlayerInfo *mplayInfo, u16 tempo) {
//     if (mplayInfo->ident == ID_NUMBER) {      // 同一个重入锁（第三次印证）
//         mplayInfo->ident++;
//         mplayInfo->tempoU = tempo;
//         mplayInfo->tempoI = (mplayInfo->tempoD * mplayInfo->tempoU) >> 8;
//         mplayInfo->ident = ID_NUMBER;
//     }
// }
// ```
//
// ★ **两个函数用的是同一个公式形状**（`ply_tempo` 先把 `tempoD` 设成 `arg*2`）
//   ⇒ 互相印证，不是我猜的。
//
// ★★ **时间轴怎么算**：`MPlayMain` 每帧把 `tempoC += tempoI`，
//    **累到 150 才推进一步**（`mplay_main.dart`）。而音轨的 `wait`
//    数的是**步**（`_081DD938` 只在推进那一支里执行）
//    ⇒ 一段 `wait = N` 的真实时长 = `N × 每步帧数`。
//    「每步帧数」直接用**模拟**算（不手推公式，免得又错一帧）。

import 'mplay_main.dart';

/// `TEMPO` 命令：`tempoD = arg * 2`，`tempoI = (tempoD * tempoU) >> 8`
///
/// 返回值是**新**的 `(tempoD, tempoI)`（16 位截断，照抄 `strh`）。
({int tempoD, int tempoI}) plyTempo({required int arg, required int tempoU}) {
  final tempoD = (arg * 2) & 0xFFFF;
  final tempoI = (tempoD * tempoU >> 8) & 0xFFFF;
  return (tempoD: tempoD, tempoI: tempoI);
}

/// `m4aMPlayTempoControl`：设 `tempoU` 并重算 `tempoI`
///
/// ⚠️ 带**重入锁**（`ident == ID_NUMBER` 才做事）—— 与 `MPlayMain` / `MPlayContinue`
/// 同一惯用法（这是第三次印证）。锁不匹配时**什么都不改**。
({bool applied, int tempoU, int tempoI}) m4aMPlayTempoControl({
  required int tempoD,
  required int tempoU,
  required int tempoI,
  required int tempo,
  required int ident,
}) {
  if (ident != MPlayMainPort.idNumber) {
    return (applied: false, tempoU: tempoU, tempoI: tempoI);
  }
  final u = tempo & 0xFFFF;
  return (applied: true, tempoU: u, tempoI: (tempoD * u >> 8) & 0xFFFF);
}

/// 用**模拟**算"推进一个事件需要多少帧"（不手推公式）
///
/// 规则来自 `mplay_main.dart` 的 tempo 门：每帧 `tempoC += tempoI`，
/// `tempoC >= 150` ⇒ 推进。注意它用的是 `>=`（不是 `>`）。
int framesPerStep(int tempoI, {int limit = 100000}) {
  if (tempoI <= 0) return limit; // 永远推不动 ⇒ 由调用方处理（不假装 0）
  final p = MPlayMainPort(
      ident: MPlayMainPort.idNumber, status: 0, tempoC: 0, tempoI: tempoI);
  for (var f = 1; f <= limit; f++) {
    if (p.tick()) return f;
  }
  return limit;
}
