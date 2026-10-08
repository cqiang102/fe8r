// PORT OF: src/m4aSongNumStart.c:5-12（`&gSongTable[n]` ⇒ n 是下标）
//          src/Event??_BgmChange.c 一族（`EV_CMD_BGMCHANGE_12` / `BGMOVERWRITE` /
//          `BGMVOLUMECHANGE` / `PLAYSE` 各自的处理函数 —— **具体行为未逐条读**，
//          这里只建模"当前在放什么"，因为**发声**要靠表现层）
//
// 音频子系统的**状态**层。分工：
//   * 核心（本文件）：当前 BGM / 覆盖 BGM / 最近一次 SE / 音量降低标志；
//   * 表现层（`lib/game`）：真正发声（**尚未实现** —— 需要 M4A 引擎或合成器）。
// ⚠️ 所以现在这层是**可验证但不发声**的：转储里能看到"脚本让放第几首歌"，
//    但听不到。别把它当成"音频做完了"。

import 'song_table.g.dart';

// 表本身也导出（调用方/测试要能按**下标**直接看表）
export 'song_table.g.dart';
export 'voicegroups.g.dart';
export 'direct_sound_samples.g.dart';
export 'programmable_waves.g.dart';

/// 按**下标**取表项（`&gSongTable[n]`）。越界返回 null —— 调用方必须**记录**，
/// 不能静默当成"没这首歌"。
SongEntry? songAt(int n) =>
    (n >= 0 && n < gSongTable.length) ? gSongTable[n] : null;

/// 音频状态（由游戏侧持有；核心只提供语义）
class AudioState {
  /// 当前 BGM 的下标（`MUSC` / 原作的 `m4aSongNumStart`）
  int? bgmId;

  /// 被覆盖的 BGM 下标（`MUSS` = `EvtOverrideBgm`）
  int? bgmOverrideId;

  /// 最近一次一次性音效（`SOUN` = `EvtPlaySong`）
  int? lastSeId;

  /// `MUSI`（`EvtSetVolumeDown`）/ `MUNO`（`EvtUnsetVolumeDown`）
  bool volumeDown = false;

  /// **越界下标**（脚本让放的歌不在表里）——必须留痕
  final List<int> outOfRangeIds = [];

  String? get bgmSymbol => bgmId == null ? null : songAt(bgmId!)?.symbol;
  String? get overrideSymbol =>
      bgmOverrideId == null ? null : songAt(bgmOverrideId!)?.symbol;
  String? get seSymbol => lastSeId == null ? null : songAt(lastSeId!)?.symbol;

  void startBgm(int n) {
    if (songAt(n) == null) {
      outOfRangeIds.add(n);
      return;
    }
    bgmId = n;
  }

  void overrideBgm(int n) {
    if (songAt(n) == null) {
      outOfRangeIds.add(n);
      return;
    }
    bgmOverrideId = n;
  }

  void playSe(int n) {
    if (songAt(n) == null) {
      outOfRangeIds.add(n);
      return;
    }
    lastSeId = n;
  }

  void setVolumeDown(bool down) => volumeDown = down;

  /// `MURE` = `EvtRestoreBgm(speed)`（`include/eventscript.h:631`）
  ///
  /// 出处 `src/Event14_BgmOverideRestore.c:27-31`（`case 1`）：
  /// `DeleteAll6CWaitMusicRelated(); _RestoreBgm(evArgument);`
  /// ⇒ **撤销 [bgmOverrideId]**（恢复原本的 BGM）。
  /// ⚠️ 参数是**变速**（`speed`），不是歌曲 id。
  void restoreBgm({required int speed}) {
    lastRestoreSpeed = speed;
    bgmOverrideId = null;
  }

  /// 最近一次 `MURE` 的变速参数（判据用）
  int? lastRestoreSpeed;
}
