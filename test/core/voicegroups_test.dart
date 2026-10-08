// 音色组（`sound/voicegroups/*.s`）→ 第 9 轮提取
//
// 判据类型（本仓库铁律 2）：提取类 ⇒ **正向抽查真值**。
// ★ 但这里有一条**比抽查更强**的判据，而且它在**提取器里**：
//   每个 voice 行后面都带 `@08207A70` 这样的**地址注解**，
//   提取器按"上一条地址 + 上一条长度"推出下一条地址，并**断言它等于注解地址**。
//   93 个文件、9787 条 voice **全部相符** ⇒ 长度表与偏移**字节严丝合缝**。
//
// ⚠️ 教训：我一开始假设"每个音色组 128 条"（想当然）——
//   实测**最小 1、最大 465**，只有 54 个文件正好 128 条。

import 'package:fe8r/core/core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('★ 规模：93 个音色组文件、9787 条 voice', () {
    expect(gVoiceGroups.length, 93);
    final total = gVoiceGroups.values.fold<int>(0, (a, b) => a + b.length);
    expect(total, 9787);
  });

  test('★ 正向抽查 voicegroup001 的第 0 条（对着 .s 文本核过）', () {
    final v = gVoiceGroups['voicegroup001']!.first;
    expect(v.macro, 'voice_square_1');
    expect(v.type, 1, reason: '`_voice_square_1 1, …`');
    expect(v.offset, 0);
    expect(v.length, 12, reason: '源码地址间隙：@08207A70 → @08207A7C');
    expect(v.args, ['0', '2', '0', '0', '15', '0']);
  });

  test('★ 正向抽查：voicegroup087 只有 1 条（不是 128）', () {
    expect(gVoiceGroups['voicegroup087']!.length, 1);
    final v = gVoiceGroups['voicegroup087']!.first;
    expect(v.macro, 'voice_directsound');
    expect(v.length, 12, reason: 'directsound 也是 12 B（不是我一开始以为的 16）');
    expect(v.args[2], contains('DirectSoundData_'));
  });

  test('★ 出现的 type 字节就那么几种（不在表里的必然是解析错位）', () {
    final types = <int>{
      for (final g in gVoiceGroups.values) for (final v in g) v.type
    };
    expect(types, {0x0, 0x1, 0x2, 0x3, 0x4, 0x8, 0xa, 0x80});
  });

  test('★ 每条 voice 长度都是 12（实测；宏体推出来的）', () {
    final lens = <int>{
      for (final g in gVoiceGroups.values) for (final v in g) v.length
    };
    expect(lens, {12});
  });
}
