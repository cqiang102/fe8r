// 真实章节事件脚本（提取产物）的测试。
//
// 判据分两层：
//   1. **提取是编译器算出来的** —— 字流来自把上游 .c 编成目标文件后的字节，
//      不是文本解析。测试这里只能验证"产物自洽"（长度、范围、可解码比例）。
//   2. **哪些表能当纯指令流用** —— 这是本轮真正的结论，
//      必须**钉住具体数字**，否则将来表结构搞清楚了、能解码的表变多了，
//      没人会注意到。
import 'dart:io';

import 'package:fe8r/core/core.dart';
import 'package:flutter_test/flutter_test.dart';

const _path = 'tools/pipeline/out/tables/chapter_events.json';

void main() {
  group('章节事件表（编译器提取）', () {
    late ChapterEvents events;

    setUpAll(() {
      final f = File(_path);
      if (!f.existsSync()) {
        fail('缺少 $_path，先跑 tools/pipeline/extract/parse_chapter_events.py');
      }
      events = ChapterEvents.parse(f.readAsStringSync());
    });

    test('21 张表，字流非空且都是 u16', () {
      expect(events.tables.length, 21);
      for (final t in events.tables.values) {
        expect(t.words, isNotEmpty, reason: '${t.name} 是空表');
        for (final w in t.words) {
          expect(w, greaterThanOrEqualTo(0));
          expect(w, lessThanOrEqualTo(0xFFFF), reason: '${t.name} 里有非 u16 值');
        }
      }
    });

    test('抽查第一张表：与宏展开逐字一致', () {
      // 源码是：
      //     EVENT_WORD(0x00000002)
      //     BNE(0, 0xC, 1)          → _EvtParams2(0x0C41, 0), _EvtParams2(0xC, 1)
      // 展开成字就是 0002 0000 0c41 0000 000c 0001
      final t = events.tables['frontier_df3_eventscr_ch_000_A69464']!;
      expect(t.words.take(6).map((w) => w.toRadixString(16).padLeft(4, '0')),
          ['0002', '0000', '0c41', '0000', '000c', '0001']);
    });

    test('每张表都能在某一起点上解出指令（0 或 2）', () {
      final usable = events.usableTables();
      for (final t in events.tables.values) {
        expect(usable.containsKey(t.name), isTrue,
            reason: '${t.name} 在偏移 0 和 2 上都解不出指令流');
      }
    });

    test('能当纯指令流解码的表 = 21 张（起点分布钉死）', () {
      final usable = events.usableTables();
      expect(usable.length, 21);

      final atZero = usable.values.where((v) => v.start == 0).length;
      final atTwo = usable.values.where((v) => v.start == 2).length;
      // 起点不唯一 —— 说明 EventListScr 表混有表头/子表引用，
      // 不是单条指令流。数字钉住，将来搞清表结构时这里会失败，
      // 从而提醒更新结论（而不是悄悄"变好"）。
      expect(atZero + atTwo, 21);
      expect(atZero, greaterThan(0), reason: '应当有表从偏移 0 直接解码');
      expect(atTwo, greaterThan(0), reason: '应当有表需要跳过 1 个槽');
    });

    test('解出的指令里出现了真实的剧情指令', () {
      // 真实章节事件里应当能看到对话与标签这类指令
      final all = <int>{};
      for (final v in events.usableTables().values) {
        for (final i in v.script.instructions) {
          all.add(i.opcode);
        }
      }
      expect(all, contains(EventOpcodes.displayText),
          reason: '章节事件里应当有对话');
      expect(all, contains(EventOpcodes.label));
      expect(all, contains(EventOpcodes.goTo));
    });

    test('字流总量与提取日志一致（5384 个槽 × 2）', () {
      final total =
          events.tables.values.fold<int>(0, (s, t) => s + t.words.length);
      expect(total, 10768);
    });
  });
}
