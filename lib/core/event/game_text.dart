// PORT OF: include/scene.h（CHFE_L_* 控制码）+ src/TalkInterpret.c + src/TalkLoadFace.c
//          数据由 tools/pipeline/extract/parse_text.py 从 texts/jp_texts.txt 提取
//
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
  /// `[A]` —— 等玩家按键。文本里的"这一页结束了"。
  bool get isWaitForKey => name == 'A';

  /// `[CR]` —— 换页（清屏重画）。
  bool get isPageBreak => name == 'A' || name == 'CR';

  /// `[$XXXX]` —— `[LoadFace]` 后面的 u16 参数。**脸编号 = raw - 0x100**。
  ///
  /// ## 出处：`src/TalkLoadFace.c:44-51`
  ///
  /// ```c
  /// faceId = sTalkState->str[0];
  /// faceId = (sTalkState->str[1] * 0x100) + faceId;   // 小端 u16
  /// if (faceId == 0xFFFF) {
  ///     faceId = GetUnitPortraitId(gActiveUnit);       // 特殊：取当前单位
  /// } else {
  ///     faceId = faceId - 0x100;                       // ★ 减 0x100
  /// }
  /// ```
  ///
  /// ⚠️ **高字节不是"槽位"，是个常量偏移 0x100。**
  ///
  /// 我先后错过**两次**：
  ///
  ///   1. 当成 `(槽位 << 8) | 脸编号`
  ///   2. 当成"屏幕位置 + 脸编号"
  ///
  /// 两次都"看起来对"，因为 `0x0152 - 0x100 = 0x52` **恰好等于取低字节** ——
  /// **解码结果对，机制全错。**
  ///
  /// 而 `$0080` 在两种错误解读下都会得到垃圾（`128` / 负值），
  /// **那才是暴露模型错误的探针**：它根本不是脸编号，是
  /// `0x80`(face-ctrl 前缀) + 子命令 `0x00`，被 dumper 按 u16 合并写成了 `[$0080]`。
  ///
  /// **教训：结果对不代表模型对。要去找偏离的样本。**
  ///
  /// 返回 `null` 表示"不是一次脸编号"（`0xFFFF` 特殊值，或负值）。
  bool get isFaceSpec => name.startsWith(r'$');

  /// 脸编号 = `raw - 0x100`。见 [isFaceSpec] 的说明。
  int? get faceId {
    if (!isFaceSpec) return null;
    final raw = int.tryParse(name.substring(1), radix: 16);
    if (raw == null || raw == 0xFFFF) return null;
    final id = raw - 0x100;
    return id < 0 ? null : id;
  }

  /// `[OpenFarLeft]`(8) .. `[OpenFarFarRight]`(15) —— **设置活动槽位**。
  ///
  /// ## 出处：`src/TalkInterpret.c:140-165`
  ///
  /// ```c
  /// case CHFE_L_LoadFace:            // 0x10，一个"块"的开始
  ///     while (1) {
  ///         switch (*sTalkState->str) {
  ///             case CHFE_L_OpenFarLeft:   // 0x08
  ///             ... case CHFE_L_OpenFarFarRight:   // 0x0F
  ///                 SetActiveTalkFace(*sTalkState->str - 8);   // ← 只是**选槽**
  ///                 ...
  ///             case CHFE_L_LoadFace:      // 0x10
  ///                 TalkLoadFace(proc);    // ← 读后面 2 字节当脸编号
  /// ```
  ///
  /// ⚠️ **不是"屏幕位置"**，是槽位选择；槽位 0..7 再由
  /// `gTalkFaceHPosLut[8] = {3, 6, 9, 21, 24, 27, -8, 38}`（`src/scene_08008830.c`）
  /// 映射到屏幕 x。
  int? get faceSlotSelect {
    // ⚠️ 不能写成 `if (!isFacePosition) return null;` ——
    // `isFacePosition` 反过来又依赖本方法，会**环形依赖**。
    if (!name.startsWith('Open')) return null;
    const m = {
      'OpenFarLeft': 0, 'OpenMidLeft': 1, 'OpenLeft': 2, 'OpenRight': 3,
      'OpenMidRight': 4, 'OpenFarRight': 5, 'OpenFarFarLeft': 6,
      'OpenFarFarRight': 7,
    };
    return m[name];
  }

  bool get isLineBreak => name == 'LF';
  bool get isLoadFace => name == 'LoadFace';
  bool get isFacePosition =>
      faceSlotSelect != null || name.startsWith('Close');

  /// 立绘位置的**屏幕左/右**。
  ///
  /// 控制码定义（`texts/jp_textdefs.txt`）：
  ///
  ///     [OpenFarLeft]=8  [OpenMidLeft]=9  [OpenLeft]=10
  ///     [OpenRight]=11   [OpenMidRight]=12 [OpenFarRight]=13
  ///     [OpenFarFarLeft]=14  [OpenFarFarRight]=15
  ///
  /// ⚠️ **`$XXXX` 不是"槽位编号"，是"给刚打开的位置放哪张脸"。**
  ///
  /// 我是先按"高字节 = 槽位"实现的，结果序章演到第 9 页（国王说
  /// 「わが軍の兵士に降伏を命じよ」）时画面上还是传令兵 —— 因为
  /// `[LoadFace]$0152`(Fado) 和 `[LoadFace]$016B`(传令兵) 的高字节都是 1，
  /// 后者把前者覆盖了。
  ///
  /// 实际语义是：
  ///
  ///     [OpenMidLeft]     $0152 → Fado 放 MidLeft
  ///     [OpenFarFarRight] $016B → 传令兵 放 FarFarRight
  ///     [OpenFarFarRight] $0080 → 清空 FarFarRight（编号无名字 = 清）
  ///
  /// 所以说话人会变，是靠**位置**区分的。
  static bool isLeftPosition(String name) => const {
        'OpenFarLeft', 'OpenMidLeft', 'OpenLeft', 'OpenFarFarLeft',
      }.contains(name);

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

  /// **分页**。
  ///
  /// FE 的文本是一串控制码：`[A]`（= 3）是"等玩家按键"，`[CR]`（= 2）是
  /// 换页。一条消息里常常有好几页 —— 序章开场那条 0x8c3 就有。
  ///
  /// ⚠️ 我第一版**没有分页**，把整条消息一口气画进两行的框里，
  /// 结果只显示前两行、后面全被裁掉（截图里一眼可见）。
  /// 而当时我甚至没意识到"分页"是个概念 —— 直到去读
  /// `texts/jp_textdefs.txt`（反编译项目把控制码的语义也写下来了）。
  ///
  /// 返回每一页的纯文字（已去掉控制码、`[LF]` 已换成换行）。
  List<String> get pages {
    final out = <String>[];
    final buf = StringBuffer();
    for (final seg in segments) {
      if (seg is TextRun) {
        buf.write(seg.text);
      } else {
        final c = seg as TextControl;
        if (c.isPageBreak) {
          // `[A]` / `[CR]` 都是"这一页到此为止"
          out.add(buf.toString().trim());
          buf.clear();
        } else if (c.isLineBreak) {
          buf.write('\n');
        }
        // 其余控制码（立绘位置、加载脸…）不进正文
      }
    }
    final tail = buf.toString().trim();
    if (tail.isNotEmpty) out.add(tail);
    // 全空的页（连续两个 `[A]`）去掉
    return out.where((p) => p.isNotEmpty).toList();
  }
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
