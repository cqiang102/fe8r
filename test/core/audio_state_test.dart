// PORT OF: src/m4aSongNumStart.c:5-12（`&gSongTable[n]`）
//          sound/song_table.s（表；`n` 是**下标**）
//
// ★ 音频子系统**状态层**的判据。这些数字全是 ROM 里的真值（正向抽查），
//   故意不写"随便一首"：表一变就会红的才叫判据。
//
// ⚠️ 边界（如实）：**这一层不发声**。它只证明"脚本让放第几首歌、我们解成了哪首"。
//    真正听到声音还需要 M4A 引擎或合成器（未实现）。

import 'package:fe8r/core/core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('★ 表是 1000 条、且**下标**取用（`&gSongTable[n]`）', () {
    expect(gSongTable.length, 1000);
    expect(gSongTableDistinctSymbols, 594, reason: '1000 个 id 只有 594 个符号');
  });

  test('★ 正向抽查：下标 1 / 4 / 9 解出来的就是源码里那三首', () {
    expect(songAt(1)!.symbol, 'song001_agbfe3_bgm_opening');
    expect(songAt(1)!.ms, 0);
    expect(songAt(4)!.symbol, 'song004_agbfe3_bgm_wmap_01');
    expect(songAt(4)!.ms, 1);
    expect(songAt(9)!.symbol, 'song009_agbfe3_bgm_map_pl2',
        reason: '第 9 首是玩家地图 BGM（ms=1）');
    expect(songAt(9)!.hasMidi, isTrue);
    expect(songAt(0)!.symbol, 'dummy_song', reason: '下标 0 是哑元，没有 MIDI');
    expect(songAt(0)!.hasMidi, isFalse);
  });

  test('★ 越界下标必须**留痕**（不是静默忽略）', () {
    final a = AudioState();
    a.startBgm(9);
    expect(a.bgmSymbol, 'song009_agbfe3_bgm_map_pl2');
    a.startBgm(99999);
    expect(a.outOfRangeIds, [99999], reason: '越界要记下来');
    expect(a.bgmSymbol, 'song009_agbfe3_bgm_map_pl2', reason: '越界不改当前 BGM');
    a.playSe(-1);
    expect(a.outOfRangeIds, [99999, -1]);
    expect(a.seSymbol, isNull);
  });

  test('★ `MUSI`/`MUNO` 是音量降低标志（没有歌曲参数）', () {
    final a = AudioState();
    expect(a.volumeDown, isFalse);
    a.setVolumeDown(true);
    expect(a.volumeDown, isTrue);
    a.setVolumeDown(false);
    expect(a.volumeDown, isFalse);
  });

  test('★ `MUSS` 覆盖与 `MUSC` 是**两个**字段（源码也是两个命令）', () {
    final a = AudioState();
    a.startBgm(9);
    a.overrideBgm(4);
    expect(a.bgmSymbol, 'song009_agbfe3_bgm_map_pl2');
    expect(a.overrideSymbol, 'song004_agbfe3_bgm_wmap_01');
  });
  _restoreBgmTests();
}

// `MURE` = `EvtRestoreBgm(speed)`（`include/eventscript.h:631`；
// 处理体 `src/Event14_BgmOverideRestore.c:27-31` 的 `case 1`）
void _restoreBgmTests() {
  test('★ `MURE` 撤销 BGM 覆盖（`_RestoreBgm`），并记下变速参数', () {
    final a = AudioState();
    a.startBgm(9);
    a.overrideBgm(4);
    expect(a.overrideSymbol, 'song004_agbfe3_bgm_wmap_01');
    a.restoreBgm(speed: 6);
    expect(a.bgmOverrideId, isNull, reason: '★ 撤销之后没有覆盖了');
    expect(a.lastRestoreSpeed, 6, reason: '参数是**变速**，不是歌曲 id');
    expect(a.bgmSymbol, 'song009_agbfe3_bgm_map_pl2', reason: '原本的 BGM 不受影响');
  });
}
