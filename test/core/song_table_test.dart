// PORT OF: sound/song_table.s（`gSongTable`）、asm/macros/m4a.inc:1-5（`song` 宏）、
//          src/m4aSongNumStart.c:5-12（`&gSongTable[n]` ⇒ **n 是下标**）
//
// 音频子系统的第一块数据。★ 这条判据的重点是那个**反直觉**的事实：
// 1000 个 id 只有 594 个不同符号（`dummy_song` 一个就占 361 条）——
// 所以**符号不能当唯一键**，`n` 是下标。谁要把符号当 id 用，这里会响。

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late Map<String, dynamic> t;

  setUpAll(() {
    final f = File('tools/pipeline/out/tables/song_table.json');
    // ★ 缺文件要响亮失败，不 skip
    expect(f.existsSync(), isTrue,
        reason: '产物缺失：在 tools/pipeline 下跑 extract/parse_song_table.py');
    t = jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
  });

  test('★ 1000 条 × 8 字节 = 8000（`song` 宏：4B 头 + 2B ms + 2B unknown）', () {
    expect(t['count'], 1000);
    expect(t['bytesPerEntry'], 8);
    expect(t['totalBytes'], 8000);
  });

  test('★ 正向抽查真值（对源码逐条核过）', () {
    final songs = (t['songs'] as List).cast<Map<String, dynamic>>();
    expect(songs[0]['symbol'], 'dummy_song', reason: '下标 0 是哑元');
    expect(songs[1]['symbol'], 'song001_agbfe3_bgm_opening');
    expect(songs[1]['ms'], 0, reason: '第 1 条 ms=0（`song ... , 0, 0`）');
    expect(songs[4]['symbol'], 'song004_agbfe3_bgm_wmap_01');
    expect(songs[4]['ms'], 1, reason: '第 4 条 ms=1（`song ... , 1, 1`）');
    expect(songs[4]['midi'], 'song004_agbfe3_bgm_wmap_01.mid');
  });

  test('★★ 1000 个 id 只有 594 个不同符号（dummy 361）—— 符号不是唯一键', () {
    expect(t['distinctSymbols'], 594);
    expect(t['dummySongCount'], 361, reason: '361 个槽位是"没有 BGM"');
    expect(t['duplicateSymbols'], 35);
    // 反过来钉住：如果哪天有人把下标当符号去重，count 会掉到 594，这条就会红
    expect(t['count'], isNot(t['distinctSymbols']));
  });

  test('★ 缺 MIDI 的 5 条要**具名**记下来（不静默）', () {
    final missing = (t['missingMidi'] as List).cast<Map<String, dynamic>>();
    expect(missing.length, 5);
    expect(missing.map((m) => m['symbol']).toList(), [
      'song089_h_muon',
      'song814_mon_gar_critical1',
      'song815_mon_gog_attack2',
      'song816_mon_gog_attack3',
      'song962_mon_bgl_attack3',
    ]);
    // midi 总数自洽：588 个 midi + 5 条缺 + dummy_song = 594 个不同符号
    expect((t['midiCount'] as int) + missing.length + 1, t['distinctSymbols'],
        reason: '588 + 5 + 1(dummy) == 594');
  });
}
