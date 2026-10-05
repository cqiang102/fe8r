// 真实章节事件脚本的**加载**。
//
// ## 数据从哪来
//
// `tools/pipeline/extract/parse_chapter_events.py` 把
// `src/data/frontier_df3_eventscr_ch/frontier_df3_eventscr_ch.c` 里的 21 张
// `EventListScr` 表编成目标文件，用 `nm` 的符号地址求长度，再把字节还原成
// u16 字流。
//
// **让编译器算，而不是文本解析**：脚本里到处是
// `CALL((u8 *)<表> + 0x70)` 这种基于表自身地址的相对偏移，还有跨表符号引用。
// 文本解析要自己算地址、自己展开宏 —— 那等于把编译器干的事重做一遍，
// 而且做错了不会报错，只会产出一份"看起来像脚本"的垃圾。
//
// ## ⚠️ 这些表**不纯是指令流**
//
// 实测：部分表能从字偏移 0 完整解码（如 `..._001_A696D4`，409 条指令），
// 另一些要从偏移 2 开始（如 `..._000_A69464`，95 条），
// 还有的两种起点都不成立。
//
// 原因是 `EventListScr` 表里混着**表头与子表引用** —— 它更接近
// "章节事件的入口清单"，而不是单条指令流。
// 引擎（`src/eventinfo_*.c`）按自己的规则解析这些条目，
// 那套规则还没有被完整梳理出来。
//
// 所以这里**如实提供两种视图**，不假装它们是同一种东西：
//   * [ChapterEventTable.words] —— 原始字流（已由编译器验证）
//   * [ChapterEventTable.decodeAsScript] —— 尝试当纯指令流解码，成功才返回
//
// 把"能解码"和"不能解码"明确区分开，好过给一个"总是返回点什么"的接口。

import 'dart:convert';

import 'event_script.dart';

/// 一张章节事件表
class ChapterEventTable {
  ChapterEventTable({required this.name, required this.words});

  final String name;

  /// 原始字流（u16）。**这是提取的产物，已由 C 编译器验证。**
  final List<int> words;

  /// 尝试从 [start] 处当作**纯指令流**解码。
  ///
  /// 返回 null 表示这张表不是纯指令流（或起点不对）——
  /// 这是**正常情况**，不是错误：表里混着表头与子表引用。
  EventScript? decodeAsScript({int start = 0}) {
    if (start >= words.length) return null;
    try {
      return EventScript.decode(words.sublist(start));
    } on FormatException {
      return null;
    }
  }

  /// 探测这张表作为纯指令流的**可用起点**。
  ///
  /// 只探测 0 和 2 两个候选：从数据看，表头若存在就是 1 个槽
  /// （= 2 个 u16 字）。探测更多偏移会把"碰巧能解码"的噪声当成结论。
  ({int start, EventScript script})? probeScriptStream() {
    for (final start in const [0, 2]) {
      final s = decodeAsScript(start: start);
      if (s != null) return (start: start, script: s);
    }
    return null;
  }
}

/// 全部章节事件表
class ChapterEvents {
  ChapterEvents(this.tables);

  final Map<String, ChapterEventTable> tables;

  static ChapterEvents parse(String json) {
    final d = jsonDecode(json) as Map<String, dynamic>;
    final raw = d['tables'] as Map<String, dynamic>;
    final out = <String, ChapterEventTable>{};
    raw.forEach((name, v) {
      final m = v as Map<String, dynamic>;
      out[name] = ChapterEventTable(
        name: name,
        words: (m['words'] as List<dynamic>).map((e) => e as int).toList(),
      );
    });
    return ChapterEvents(out);
  }

  /// 能作为纯指令流使用的表（其余是混有表头/子表引用的）
  Map<String, ({int start, EventScript script})> usableTables() {
    final out = <String, ({int start, EventScript script})>{};
    tables.forEach((name, t) {
      final p = t.probeScriptStream();
      if (p != null) out[name] = p;
    });
    return out;
  }
}
