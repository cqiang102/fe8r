// 可编程波 + 键分离表使用情况（第 11 轮）
//
// 判据两层（都在提取器里算好、这里正向抽查）：
//   1. 每个波 **16 字节**（GBA 波 RAM 一页），且 `programmable_wave_data.s` 的
//      **地址间隙 == 文件实际大小**（11 条里 10 条有后继，全部相符）；
//   2. "键分离表未使用"是**三个计数互证**的事实（源码注释也这么说）。

import 'package:fe8r/core/core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('★ 11 个波，每个 16 字节', () {
    expect(gProgrammableWaves.length, 11);
    expect(gProgrammableWaves.every((w) => w.bytes == 16), isTrue);
  });

  test('★ 抽查：第一个是 wave000_sinewave（地址 0x08214004）', () {
    expect(gProgrammableWaves.first.symbol, 'wave000_sinewave');
  });

  test('★ 键分离表在 FE8 里未使用（0 / 0 / 67 三个计数互证）', () {
    expect(gKeysplitTableRefs, 0, reason: '没有 voicegroup 引用 keysplit_table_*');
    expect(gVoiceKeysplitCount, 0, reason: 'type 0x40 一次都没出现');
    expect(gVoiceKeysplitAllCount, 67,
        reason: 'type 0x80 有 67 次 —— 它指向**音色组**，不需要键分离表');
  });
}
