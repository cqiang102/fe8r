// 游戏文本（对白 / 章节标题 / 界面文字）。
//
// ## 数据从哪来 —— 不用解码
//
// FE8 的文本在 ROM 里是 Huffman 压缩的（`src/msg_data.c` 里是压缩字节）。
// 但反编译项目**已经把解码结果导成了纯文本**：
//
//     texts/jp_texts.txt   1.4 MB · 3339 条 · 格式 `#0xNNNN` + 正文
//
// 所以这里不碰 Huffman。
//
// ## 两种控制码写法
//
//     [LF] / [A] / [OpenMidLeft]      名字形式
//     [LoadFace]0104]                 名字 + 十六进制操作数
//     [$0152]                         `$` + 十六进制（第一版漏了它）
//
// `[LF]` 是换行、`[A]` 是等玩家按键 —— 都是有语义的，
// 所以解析出来而不是当噪声丢掉。

import 'dart:convert';

/// 文本里的一段：要么是文字，要么是控制码
sealed class TextSegment {
  const TextSegment();
}

class TextRun extends TextSegment {
  const TextRun(this.text);
  final String text;
}

class TextControl extends TextSegment {
  const TextControl(this.name, [this.arg]);
  final String name;
  final int? arg;

  /// 渲染层真正需要的语义
  bool get isWaitForKey => name == 'A';
  bool get isLineBreak => name == 'LF';
  bool get isLoadFace => name == 'LoadFace';
  bool get isFacePosition => name.startsWith('Open') || name.startsWith('Close');

  @override
  String toString() =>
      '[$name${arg == null ? '' : ']${arg!.toRadixString(16)}'}]';
}

/// 一条游戏文本
class GameMessage {
  const GameMessage({required this.id, required this.segments});

  final int id;
  final List<TextSegment> segments;

  /// 去掉控制码的纯文字；`[LF]` 变成真正的换行。
  ///
  /// 不处理 `[LF]` 的话所有对白会挤成一坨（截图里验证过）。
  String get plain => segments
      .map((s) => switch (s) {
            TextRun(:final text) => text,
            TextControl(isLineBreak: true) => '\n',
            TextControl() => '',
          })
      .join()
      .trim();

  bool get isEmpty => plain.trim().isEmpty;
}

/// 全部游戏文本
class GameTexts {
  GameTexts({required this.messages, required this.titles});

  final Map<int, GameMessage> messages;

  /// 章节内部名 → 标题
  final Map<String, String> titles;

  static GameTexts parse(String json) {
    final d = jsonDecode(json) as Map<String, dynamic>;
    final msgs = <int, GameMessage>{};
    (d['messages'] as Map<String, dynamic>).forEach((k, v) {
      final m = v as Map<String, dynamic>;
      msgs[int.parse(k)] = GameMessage(
        id: int.parse(k),
        segments: (m['segments'] as List<dynamic>).map((s) {
          final sm = s as Map<String, dynamic>;
          if (sm.containsKey('t')) return TextRun(sm['t'] as String);
          return TextControl(sm['c'] as String, sm['arg'] as int?);
        }).toList(),
      );
    });
    final titles = <String, String>{};
    (d['titles'] as Map<String, dynamic>? ?? {}).forEach((k, v) {
      titles[k] = ((v as Map<String, dynamic>)['text'] as String?) ?? '';
    });
    return GameTexts(messages: msgs, titles: titles);
  }

  GameMessage? byId(int id) => messages[id];
}
