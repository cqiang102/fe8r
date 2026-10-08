// 采样映射：`DirectSoundData_<名字>` → `<名字>.aif`（第 12 轮实测建立）
//
// ★ 这是第 10 轮那个"缺口"的更正：映射**存在**，就是同名文件。
//   实测：439 个文件 = 45 个编号式 + 394 个带名字式；
//   voicegroup 引用的 398 个不同符号 **398/398 全部命中**（缺 0）。
//   提取器里有硬断言 `assert not missing`，所以这类"没看全目录"的错会当场红。

import 'package:fe8r/core/core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('★ 解析函数：去前缀后按同名取', () {
    final a = directSoundSampleFor('DirectSoundData_k_tubular_c4_13k_s');
    final b = gDirectSoundSamples['k_tubular_c4_13k_s'];
    expect(a, isNotNull);
    expect(a!.frames, b!.frames);
    expect(a.rate, b.rate);
  });

  test('★ 抽查一个真实存在的采样（值从 AIFF 头读出）', () {
    final s = directSoundSampleFor('DirectSoundData_btl_evl_magic1_13k');
    expect(s, isNotNull);
    expect(s!.bits, 8);
    expect(s.channels, 1);
  });

  test('★ 不存在时返回 null（调用方必须记录，不许静默兜底）', () {
    expect(directSoundSampleFor('DirectSoundData_不存在的采样名字'), isNull);
  });
}
