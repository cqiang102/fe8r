// PORT OF: include/gba/m4a_internal.h:294-319（`struct MusicPlayerInfo`）
//
// ⚠️ 本文件只移植**结构体布局**，不含行为。行为（tempo 推进 / loop / fade）在
//   日版 masked、**美版可读**（`src/m4a.c` 的 `MPlayMain` / `SoundMain` / `CgbSound`），
//   见 `docs/计划-音频.md` 的"规则"段。
//
// 为什么先移植结构体：M4A 的时序语义**全部**读写这些字段
// （尤其 `tempoD/tempoU/tempoI/tempoC` 与 `fadeOI/fadeOC/fadeOV`），
// 字段位置错了后面每一步都错，而且**不会报错**。
//
// 布局判据在 `test/core/m4a_layout_test.dart`：逐字段偏移与大小被钉住。

/// `struct MusicPlayerInfo` 的一个字段（名字、C 类型、偏移、大小）
class M4aField {
  const M4aField(this.name, this.cType, this.offset, this.size);
  final String name;
  final String cType;
  final int offset;
  final int size;

  @override
  String toString() => '$cType $name; // @$offset (+$size)';
}

/// `struct MusicPlayerInfo`（GBA/ARM32 自然对齐；指针 4 字节）
///
/// 来源：`include/gba/m4a_internal.h:294-319`，字段顺序与名字逐字照抄。
/// ⚠️ `gap[8]` 是**源码里就有的显式空洞**，不是我省略掉的字段。
abstract final class MusicPlayerInfo {
  /// 字段表（顺序 = 源码顺序）
  static const List<M4aField> fields = [
    M4aField('songHeader', 'struct SongHeader *', 0, 4),
    M4aField('status', 'u32', 4, 4),
    M4aField('trackCount', 'u8', 8, 1),
    M4aField('priority', 'u8', 9, 1),
    M4aField('cmd', 'u8', 10, 1),
    M4aField('unk_B', 'u8', 11, 1),
    M4aField('clock', 'u32', 12, 4),
    M4aField('gap', 'u8[8]', 16, 8),
    M4aField('memAccArea', 'u8 *', 24, 4),
    M4aField('tempoD', 'u16', 28, 2),
    M4aField('tempoU', 'u16', 30, 2),
    M4aField('tempoI', 'u16', 32, 2),
    M4aField('tempoC', 'u16', 34, 2),
    M4aField('fadeOI', 'u16', 36, 2),
    M4aField('fadeOC', 'u16', 38, 2),
    M4aField('fadeOV', 'u16', 40, 2),
    // 42..43 是**对齐补白**（`tracks` 是 4 字节指针），源码里没有对应字段
    M4aField('tracks', 'struct MusicPlayerTrack *', 44, 4),
    M4aField('tone', 'struct ToneData *', 48, 4),
    M4aField('ident', 'u32', 52, 4),
    M4aField('func', 'u32', 56, 4),
    M4aField('intp', 'u32', 60, 4),
  ];

  /// 结构体总大小（含尾部对齐）
  static const int size = 64;

  /// 对齐补白的位置 → 字节数（源码里**没有**字段名，但真实存在）
  static const Map<int, int> padding = {42: 2};

  static M4aField field(String name) =>
      fields.firstWhere((f) => f.name == name,
          orElse: () => throw ArgumentError('MusicPlayerInfo 没有字段 $name'));
}

/// M4A 的 `status` 位 —— **逐条来自头文件**（`include/gba/m4a_internal.h:283-288`）
///
/// ⚠️ 我第一版凭印象写了 `playing = 0x01`，头里**没有**这个常量 —— 已删。
///   只收录查到的位；查不到的写「未查证」，**不猜**。
abstract final class MPlayStatus {
  /// `MUSICPLAYER_STATUS_TRACK`：低 16 位是**音轨位掩码**
  static const int track = 0x0000FFFF;

  /// `MUSICPLAYER_STATUS_PAUSE`：暂停
  static const int pause = 0x80000000;

  /// `MAX_MUSICPLAYER_TRACKS`（`m4a_internal.h:290`）：一个播放器最多 16 条音轨
  static const int maxTracks = 16;
}

/// 淡入/淡出相关常量 —— **逐条来自头文件**（`include/gba/m4a_internal.h:292-295`）
abstract final class MPlayFade {
  /// `TEMPORARY_FADE`：临时淡出（暂停用）
  static const int temporaryFade = 0x0001;

  /// `FADE_IN`：淡入
  static const int fadeIn = 0x0002;

  /// `FADE_VOL_MAX`：淡入淡出的音量上限
  static const int volMax = 64;

  /// `FADE_VOL_SHIFT`：`FADE_VOL_MAX` 对应的移位量
  static const int volShift = 2;
}
