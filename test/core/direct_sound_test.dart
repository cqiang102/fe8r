// 直采采样（`sound/direct_sound_samples/*.aif`）→ 第 10 轮提取
//
// ★ 判据有两层：
//   1. **全量不变量**（在提取器里）：`帧数 × 声道 × 位深/8 == SSND 数据长度`，
//      439 个文件**全部成立** ⇒ 头解析没偏一位；
//   2. 本文件的**正向抽查 + 分布**（值都是从文件读出来核对过的）。
//
// ⚠️ 缺口（未查证）：**符号名 → 采样文件** 的映射不在日版仓库里。
//   美版 `direct_sound_data.s` 映射的是 `<名字>.bin`，而日版是**编号的** `<n>.aif`
//   ⇒ 不能套用。详见 `docs/计划-音频.md` 与 `mappingStatus`。

import 'package:fe8r/core/core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('★ 规模：439 个采样，全部 8 位单声道', () {
    expect(gDirectSoundSamples.length, 439);
    expect(gDirectSoundSamples.values.every((s) => s.bits == 8), isTrue);
    expect(gDirectSoundSamples.values.every((s) => s.channels == 1), isTrue);
  });

  test('★ 正向抽查 0.aif（值从 AIFF 头读出、核对过）', () {
    final s = gDirectSoundSamples['0']!;
    expect(s.frames, 1199);
    expect(s.rate, 13379.0, reason: '80 位扩展浮点解出来就是 13379 Hz');
    expect(s.dataBytes, 1199, reason: '8 位单声道：帧数 == 字节数');
  });

  test('★ 采样率只有这 11 种（13379 Hz 是主体：325 个）', () {
    final byRate = <double, int>{};
    for (final s in gDirectSoundSamples.values) {
      byRate[s.rate] = (byRate[s.rate] ?? 0) + 1;
    }
    expect(byRate.length, 11);
    expect(byRate[13379.0], 325);
    expect(byRate[10512.0], 65);
  });

  test('★ 数据总量 3,264,489 字节（≈3.1 MB）', () {
    final total = gDirectSoundSamples.values.fold<int>(0, (a, s) => a + s.dataBytes);
    expect(total, 3264489);
  });
}
