// TEMPO 的时轴语义（第 21 轮）—— 对着 `ply_tempo` 与 `m4aMPlayTempoControl`
//
// ★ 判据：
//   1. `TEMPO arg` ⇒ `tempoD = arg*2`、`tempoI = (tempoD*tempoU) >> 8`（16 位）；
//   2. `m4aMPlayTempoControl` 带**重入锁**（ident 不匹配 ⇒ 什么都不改）；
//   3. **两函数公式一致**（`ply_tempo` 先设 tempoD ⇒ 与 API 那条同形）；
//   4. 时轴：`framesPerStep` 用**模拟**算（不手推公式）。

import 'package:fe8r/core/core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('★ ply_tempo：tempoD = arg*2，tempoI = (tempoD*tempoU)>>8', () {
    // arg=43 ⇒ tempoD=86；tempoU=96 ⇒ tempoI = 86*96>>8 = 32
    final r = plyTempo(arg: 43, tempoU: 96);
    expect(r.tempoD, 86);
    expect(r.tempoI, (86 * 96) >> 8);
    expect(r.tempoI, 32);
    // 16 位截断（源码是 `strh`）
    expect(plyTempo(arg: 0x9000, tempoU: 0).tempoD, (0x9000 * 2) & 0xFFFF);
  });

  test('★ m4aMPlayTempoControl：设 tempoU 并重算 tempoI（公式同形）', () {
    final r = m4aMPlayTempoControl(
        tempoD: 86, tempoU: 0, tempoI: 0, tempo: 96,
        ident: MPlayMainPort.idNumber);
    expect(r.applied, isTrue);
    expect(r.tempoU, 96);
    expect(r.tempoI, (86 * 96) >> 8);
    // 与 ply_tempo 一致：先把 tempoD 设成 arg*2，再走同一个公式
    final viaPly = plyTempo(arg: 43, tempoU: 96);
    expect(r.tempoI, viaPly.tempoI, reason: '★ 两个函数必须给同一个答案');
  });

  test('★ 重入锁：ident 不匹配 ⇒ 什么都不改（第三次印证这个惯用法）', () {
    final r = m4aMPlayTempoControl(
        tempoD: 86, tempoU: 7, tempoI: 9, tempo: 96, ident: 0x1234);
    expect(r.applied, isFalse);
    expect(r.tempoU, 7, reason: '没改');
    expect(r.tempoI, 9, reason: '没改');
  });

  test('★ 时轴：framesPerStep 用模拟算（tempoI=48 ⇒ 4 帧）', () {
    // 48, 96, 144, 192 ⇒ 第 4 帧越过 150
    expect(framesPerStep(48), 4);
    expect(framesPerStep(150), 1, reason: '一步就到 150');
    expect(framesPerStep(75), 2);
  });

  test('★ 时轴自洽：一步的真实时长 = 每步帧数（不是"每 tick 一帧"）', () {
    // 由 150 门推出：tempoI 越大，一步越快
    expect(framesPerStep(150) < framesPerStep(75), isTrue);
    expect(framesPerStep(75) < framesPerStep(48), isTrue);
    // tempoI = 0 ⇒ 永远推不动（不许假装 0 帧）
    expect(framesPerStep(0), 100000);
  });
}
