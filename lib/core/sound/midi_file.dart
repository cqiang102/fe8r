// PORT OF: （**不是移植**——这是"标准 MIDI 解析器"，规则来自 SMF 规范；
//   本文件存在的原因：M4A 音序器的**输入**就是 mid2agb 从
//   `sound/songs/midi/*.mid` 编译出来的东西，而 `.mid` 是本案唯一可得的原始形态。
//   引擎语义（tempo/loop/track-bits/fade）在日版 masked、美版可读，
//   见 `include/m4a.h` 与 `docs/计划-音频.md`。）
//
// ⚠️ 本仓库的 `lib/core` 规则：纯 Dart、无 dart:io、无 async、无 DateTime/Random。
//   所以这里只吃**字节**（调用方负责读文件）。

/// 事件之后：一个 MIDI 事件
sealed class MidiEvent {
  const MidiEvent(this.tick);

  /// 绝对 tick（相对文件开头）
  final int tick;
}

/// 通道消息（`0x8n`…`0xEn`）
class MidiChannelEvent extends MidiEvent {
  const MidiChannelEvent(super.tick, this.status, this.data1, this.data2);

  final int status; // 含通道号
  final int data1;
  final int? data2;

  int get kind => status & 0xF0;
  int get channel => status & 0x0F;

  @override
  String toString() => 'ch(${status.toRadixString(16)}) $data1 ${data2 ?? ""}';
}

/// 元事件（`0xFF`）
class MidiMetaEvent extends MidiEvent {
  const MidiMetaEvent(super.tick, this.type, this.data);

  final int type;
  final List<int> data;

  /// `0x51` = Set Tempo（3 字节，微秒/四分音符）
  int? get tempoMicrosPerQuarter =>
      type == 0x51 && data.length >= 3
          ? (data[0] << 16) | (data[1] << 8) | data[2]
          : null;

  /// `0x2F` = End of Track
  bool get isEndOfTrack => type == 0x2F;

  @override
  String toString() => 'meta(${type.toRadixString(16)}) ${data.length}B';
}

/// 系统专用（`0xF0` / `0xF7`）
class MidiSysExEvent extends MidiEvent {
  const MidiSysExEvent(super.tick, this.status, this.data);
  final int status;
  final List<int> data;
}

/// 一条轨道
class MidiTrack {
  const MidiTrack(this.events, this.declaredBytes, this.consumedBytes);

  final List<MidiEvent> events;

  /// `MTrk` 块里声明的字节数
  final int declaredBytes;

  /// 解析时**实际**消费的字节数 —— 必须等于 [declaredBytes]（字节严丝合缝）
  final int consumedBytes;

  bool get isExact => declaredBytes == consumedBytes;

  /// 轨道末是否有 End-of-Track（`0x2F`）
  bool get hasEndOfTrack => events.any((e) => e is MidiMetaEvent && e.isEndOfTrack);
}

/// 一个 MIDI 文件
class MidiFile {
  const MidiFile({
    required this.format,
    required this.division,
    required this.tracks,
  });

  final int format;
  final int division;
  final List<MidiTrack> tracks;

  /// 轨道 0 的 tempo 变化（Set Tempo）。空表示"没写 tempo"（默认 120 BPM）。
  List<MidiMetaEvent> get tempoMap => tracks.isEmpty
      ? const []
      : [
          for (final e in tracks.first.events)
            if (e is MidiMetaEvent && e.tempoMicrosPerQuarter != null) e,
        ];

  /// 解析失败时抛这个（**不返回半成品** —— 本仓库铁律 4：静默失败必须响亮）
  static MidiFile parse(List<int> bytes) {
    final r = _Reader(bytes);
    if (r.takeAscii(4) != 'MThd') throw const MidiFormatException('开头不是 MThd');
    final headerLen = r.u32();
    if (headerLen < 6) throw MidiFormatException('MThd 长度异常 $headerLen');
    final format = r.u16();
    final nTracks = r.u16();
    final division = r.u16();
    for (var i = 6; i < headerLen; i++) {
      r.u8();
    }
    final tracks = <MidiTrack>[];
    while (r.remaining >= 8) {
      final id = r.takeAscii(4);
      final size = r.u32();
      if (id != 'MTrk') {
        // 未知块：跳过（标准允许），但**记录**在末尾由调用方检查轨道数
        r.skip(size);
        continue;
      }
      final start = r.pos;
      final events = _parseTrack(r, size);
      final consumed = r.pos - start;
      tracks.add(MidiTrack(events, size, consumed));
    }
    if (tracks.length != nTracks) {
      throw MidiFormatException('声明 $nTracks 条轨道，实际解出 ${tracks.length} 条');
    }
    return MidiFile(format: format, division: division, tracks: tracks);
  }
}

class MidiFormatException implements Exception {
  const MidiFormatException(this.message);
  final String message;
  @override
  String toString() => 'MidiFormatException: $message';
}

List<MidiEvent> _parseTrack(_Reader r, int size) {
  final end = r.pos + size;
  final out = <MidiEvent>[];
  var tick = 0;
  int? running; // ★ running status：状态字节 < 0x80 时沿用上一个
  while (r.pos < end) {
    // 变长量（variable-length quantity）
    var dt = 0;
    while (true) {
      final c = r.u8();
      dt = (dt << 7) | (c & 0x7F);
      if ((c & 0x80) == 0) break;
      if (r.pos > end) throw const MidiFormatException('VLQ 越界');
    }
    tick += dt;
    var status = r.peek();
    if (status < 0x80) {
      if (running == null) throw const MidiFormatException('running status 无前值');
      status = running; // 复用，**不消费**这个字节
    } else {
      r.u8();
    }
    if (status == 0xFF) {
      final type = r.u8();
      final len = _vlq(r);
      final data = r.take(len);
      running = null; // 元事件后 running status 失效
      out.add(MidiMetaEvent(tick, type, data));
    } else if (status == 0xF0 || status == 0xF7) {
      final len = _vlq(r);
      out.add(MidiSysExEvent(tick, status, r.take(len)));
      running = null;
    } else {
      final kind = status & 0xF0;
      final n = (kind == 0xC0 || kind == 0xD0) ? 1 : 2;
      final d1 = r.u8();
      final d2 = n == 2 ? r.u8() : null;
      running = status;
      out.add(MidiChannelEvent(tick, status, d1, d2));
    }
  }
  if (r.pos != end) throw const MidiFormatException('轨道没有恰好消费完声明的字节');
  return out;
}

int _vlq(_Reader r) {
  var v = 0;
  while (true) {
    final c = r.u8();
    v = (v << 7) | (c & 0x7F);
    if ((c & 0x80) == 0) return v;
  }
}

class _Reader {
  _Reader(this.bytes);
  final List<int> bytes;
  int pos = 0;

  int get remaining => bytes.length - pos;
  int u8() {
    if (pos >= bytes.length) throw const MidiFormatException('读到文件末尾');
    return bytes[pos++];
  }

  int peek() {
    if (pos >= bytes.length) throw const MidiFormatException('读到文件末尾');
    return bytes[pos];
  }

  int u16() => (u8() << 8) | u8();
  int u32() => (u16() << 16) | u16();

  String takeAscii(int n) {
    final s = String.fromCharCodes(take(n));
    return s;
  }

  List<int> take(int n) {
    if (pos + n > bytes.length) throw const MidiFormatException('块长度越界');
    final out = bytes.sublist(pos, pos + n);
    pos += n;
    return out;
  }

  void skip(int n) {
    if (pos + n > bytes.length) throw const MidiFormatException('跳过越界');
    pos += n;
  }
}
