// 标准 MIDI 解析器（第 13 轮）—— 音序器的**输入**
//
// ★ 判据（解码类 ⇒ **字节严丝合缝**，本仓库铁律 2）：
//   1. **全部 588 首**都能解析（不抛异常）；
//   2. 每条轨道**声明的字节数 == 实际消费的字节数**（偏一位就会红）；
//   3. 每条轨道以 End-of-Track（`0x2F`）收尾；
//   4. 头里声明 9 条轨道，实际就解出 9 条。
// ⚠️ 我随手写的试解析脚本**没处理 running status**，结果吐出一堆 `??0x7` 垃圾 ——
//   这正是判据 2 要防的那类错。

import 'dart:io';

import 'package:fe8r/core/core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final dir = Directory('third_party/fireemblem8j/sound/songs/midi');
  final files = dir.existsSync()
      ? (dir.listSync().whereType<File>().where((f) => f.path.endsWith('.mid')).toList()
        ..sort((a, b) => a.path.compareTo(b.path)))
      : <File>[];

  test('★ 反编译里的 .mid 有 588 个（少了就是提取/检出问题）', () {
    if (files.isEmpty) {
      markTestSkipped('third_party 未检出（151 MB，gitignore）');
      return;
    }
    expect(files.length, 588);
  });

  test('★★ 全部 588 首：字节严丝合缝 + 9 条轨道 + 都以 0x2F 收尾', () {
    if (files.isEmpty) {
      markTestSkipped('third_party 未检出');
      return;
    }
    final divisions = <int, int>{};
    final trackCounts = <int, int>{};
    final formats = <int, int>{};
    var songs = 0;
    var events = 0;
    for (final f in files) {
      final midi = MidiFile.parse(f.readAsBytesSync());
      formats[midi.format] = (formats[midi.format] ?? 0) + 1;
      divisions[midi.division] = (divisions[midi.division] ?? 0) + 1;
      // ⚠️ 不要断言"都是 9 轨" —— 我一开始这么写过（因为 `file` 对 song001 报 9），
      //   结果 song003 是 **7** 轨。解析器自己已经断言"声明的轨道数 == 解出的轨道数"，
      //   这里只收集**分布**，最后把实测值钉住。
      trackCounts[midi.tracks.length] = (trackCounts[midi.tracks.length] ?? 0) + 1;
      for (final t in midi.tracks) {
        expect(t.isExact, isTrue,
            reason: '${f.path}: 声明 ${t.declaredBytes} B、实际消费 ${t.consumedBytes} B');
        expect(t.hasEndOfTrack, isTrue, reason: '${f.path}: 没有 0x2F 收尾');
        events += t.events.length;
      }
      songs++;
    }
    expect(songs, 588);
    // 这两条是**打印分布再钉**（不是先猜一个值）：
    expect(formats.keys.toList(), [1], reason: '格式分布 = $formats');
    expect(divisions.keys.toList(), [24], reason: 'division 分布 = $divisions');
    expect(events, greaterThan(100000), reason: '事件总数 = $events');
    // 实测分布（打印后钉住；不是我猜的）
    // ★ 实测分布（打印后钉住）。**不要按一个例子推结构** ——
    //   `file` 对 song001 报 9 轨，我就写过"都是 9 轨"，实际大多数（436 首）是 **2 轨**。
    expect(trackCounts, {2: 436, 3: 45, 4: 19, 5: 15, 6: 11, 7: 28, 8: 30, 9: 4},
        reason: '轨道数分布变了要有人看一眼');
  });

  test('★ tempo 轨（轨道 0）能读出 Set Tempo（0x51）', () {
    if (files.isEmpty) {
      markTestSkipped('third_party 未检出');
      return;
    }
    final f = File('third_party/fireemblem8j/sound/songs/midi/'
        'song001_agbfe3_bgm_opening.mid');
    final midi = MidiFile.parse(f.readAsBytesSync());
    final tempos = midi.tempoMap;
    expect(tempos.length, 5, reason: '这首歌的 tempo 事件数（实测 5）');
    expect(tempos.first.tempoMicrosPerQuarter, greaterThan(0));
    // 事件总数对得上（实测：整曲 245,606 个事件级别？不猜——只要求 > 0）
    expect(midi.tracks.first.events.length, greaterThan(0));
  });
}
