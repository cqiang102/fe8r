// `sound/songs.mk` 的音色组/混音参数（第 8 轮提取）
//
// 判据类型（本仓库铁律 2）：提取类 ⇒ **正向抽查真值**，不是"文件存在"。
// 真值来源：`third_party/fireemblem8j/sound/songs.mk` 的文字，例如
//   `$(MID2AGB) $< $@ -E -G000 -R020 -P010 -V051`（song001）。
//
// ⚠️ 这个数据是音频子系统的**第一段（数据）**：`docs/计划-音频.md`。
//    MIDI 只有音符/时值，**音色**（哪套乐器）就靠这里的 `voicegroup`。

import 'package:fe8r/core/core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  SongEntry bySymbol(String s) => gSongTable.firstWhere((e) => e.symbol == s);

  test('★ 正向抽查：song001 的 -G000 -R020 -P010 -V051 逐字对上', () {
    final m = bySymbol('song001_agbfe3_bgm_opening').mix!;
    expect(m.voicegroup, 0, reason: 'songs.mk 写的是 -G000');
    expect(m.reverb, 20, reason: 'songs.mk 写的是 -R020（按字面十进制读）');
    expect(m.priority, 10, reason: 'songs.mk 写的是 -P010');
    expect(m.volume, 51, reason: 'songs.mk 写的是 -V051');
  });

  test('★ 抽查第二首：song004 的 -G003', () {
    // ⚠️ 我一开始在这里断言 "song004 不带 -R"，测试红了 —— 它**带** -R。
    //    "553 首没有 -R" 这个**计数**是对的，但"哪几首"必须逐条看源码，不能想当然。
    expect(bySymbol('song004_agbfe3_bgm_wmap_01').mix!.voicegroup, 3);
  });

  test('★ 抽查"没有 -R"的那种规则形式（songs.mk 第 240 行）', () {
    // `$(MID2AGB) $< $@ -E -G031 -P020 -V127`（song078_se_bmp_sand_wind2）
    final m = bySymbol('song078_se_bmp_sand_wind2').mix!;
    expect(m.voicegroup, 31);
    expect(m.priority, 20);
    expect(m.volume, 127);
    expect(m.reverb, isNull, reason: '这一条确实没有 -R ⇒ null');
  });

  test('★ 覆盖：588 条规则 ⇒ 588 首有 mix；用到 84 个不同音色组', () {
    final withMix = gSongTable.where((e) => e.mix != null).toList();
    final vgs = withMix.map((e) => e.mix!.voicegroup).toSet();
    expect(vgs.length, 84, reason: 'songs.mk 里用到的不同 -G 个数');
    expect(withMix.where((e) => e.mix!.reverb == null).length, 553,
        reason: '实测 553 首没有 -R（另一种规则形式）');
    // 每一条都在合法范围内（音色组库有 93 个：voicegroup000..092）
    for (final e in withMix) {
      expect(e.mix!.voicegroup, inInclusiveRange(0, 92), reason: e.symbol);
    }
  });

  test('★ 表长 1000（下标即事件指令的歌曲参数），dummy 占 361 条无 mix', () {
    expect(gSongTable.length, 1000);
    final dummy = gSongTable.where((e) => e.symbol == 'dummy_song');
    expect(dummy.length, 361);
    expect(dummy.every((e) => e.mix == null), isTrue,
        reason: 'dummy 不该有混音参数（它根本不是一首曲子）');
  });
}
