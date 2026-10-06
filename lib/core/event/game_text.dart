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
  /// ⚠️ `0xFFFF` 是**特殊值**：表示"取当前单位的立绘"
  /// （`src/TalkLoadFace.c:46-49` `GetUnitPortraitId(gActiveUnit)`），
  /// **不是"清空"**。我原来返回 null 并被下游当成"抹掉这张脸"。
  ///
  /// 全量 32 处（当前不在播放集 → latent，但语义要写对）。
  bool get isFaceFromActiveUnit {
    if (!isFaceSpec) return false;
    return int.tryParse(name.substring(1), radix: 16) == 0xFFFF;
  }

  /// 返回 `null` 表示"不是一次脸编号"（负值）。
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
  /// token 的**码值**（u16）。
  ///
  /// ⚠️ `[$0080]` 之后的"子码"**可以是具名 token**。
  ///
  /// 语料实测：`[$0080]` 的子码分布是
  /// `$0021`×640、`[....]`×235、**`[OpenRight]`×137**、`$0025`×108、
  /// **`[OpenFarFarLeft]`×105**、`[OpenFarRight]`×83、`[FastPrint2]`×72、
  /// `[OpenMidRight]`×70 … —— **一半以上是具名控制码**。
  ///
  /// 我第一版只按 `[$XXXX]` 解析子码，遇到 `[OpenFarFarLeft]` 就得到 null，
  /// 于是序章的 `[$0080][OpenFarFarLeft]`（= 传到槽 4）整个丢掉，
  /// 结果**国王在屏幕左右两侧各画一次**。
  ///
  /// 映射来自 `texts/jp_textdefs.txt`（dumper 用的就是这张表）。
  int? get codeValue {
    if (isFaceSpec) return int.tryParse(name.substring(1), radix: 16);
    return _codeByName[name];
  }

  static const _codeByName = <String, int>{
    'X': 0, 'LF': 1, 'CR': 2, 'A': 3,
    '....': 4, '.....': 5, '......': 6, '.......': 7,
    'OpenFarLeft': 8, 'OpenMidLeft': 9, 'OpenLeft': 10, 'OpenRight': 11,
    'OpenMidRight': 12, 'OpenFarRight': 13, 'OpenFarFarLeft': 14,
    'OpenFarFarRight': 15,
    'LoadFace': 16, 'ClearFace': 17,
    'NormalPrint': 18, 'FastPrint': 19,
    'CloseSpeechFast': 20, 'CloseSpeechSlow': 21,
    'ToggleMouthMove': 22, 'ToggleSmile': 23,
    'Yes': 24, 'No': 25, 'BuySell': 26, 'ShopContinue': 27,
    'SendToBack': 28, 'FastPrint2': 29, '.': 31,
    'HASH': 0x23, 'DashedLine': 0x7F, 'AccentedE': 0xE9,
  };

  bool get isLoadFace => name == 'LoadFace';

  /// `[ClearFace]`(17) —— 清空**活动槽**（淡出）。
  ///
  /// `src/TalkInterpret.c:167-176`：
  /// `StartFaceFadeOut(faces[activeFaceSlot]); faces[activeFaceSlot] = 0;`
  ///
  /// 全量 398 次，其中 5 次其实是 `[$0080]` 的移动子码 0x11 → **393 次真命令**。
  bool get isClearFace => name == 'ClearFace';
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

  /// 按顺序的**文本段**（不含控制码）—— 译文的对应单位
  List<String> get runs => [
        for (final s in segments)
          if (s is TextRun) s.text,
      ];

  /// 用新的文本段造一条消息（控制码原位保留）
  ///
  /// ⚠️ [newRuns] 的数量必须与 [runs] 一致 —— 调用方（[GameTexts.localized]）
  /// 已经检查过；这里不一致就抛，避免静默错版。
  GameMessage withRuns(List<String> newRuns) {
    if (newRuns.length != runs.length) {
      throw ArgumentError('段数不符：需要 ${runs.length}，给了 ${newRuns.length}');
    }
    var i = 0;
    return GameMessage(id: id, segments: [
      for (final s in segments)
        if (s is TextRun) TextRun(newRuns[i++]) else s,
    ]);
  }

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
  /// 每一页：`(文字, 该页在 segments 里的结束下标)`。
  ///
  /// ⚠️ **必须连下标一起给。**
  ///
  /// 原来下游靠"拿这一页的文字去 `segments` 里比对"反推结束位置
  /// （`scene_view.dart` 的 `_indexOfPage`），而那个比对**把 `[LF]` 当成了
  /// 不在文字里的东西** —— 只要这一页含换行就永不匹配，于是退化成
  /// "用整条消息的脸状态"。
  ///
  /// 审计量化：18459 页里 **646 页纯粹因为这个 bug 选错立绘**。
  ///
  /// 按 token 序号直接给，就没有"比对"这一步，也就没有这个 bug。
  List<(String, int)> get pageSpans {
    final out = <(String, int)>[];
    final buf = StringBuffer();
    for (var i = 0; i < segments.length; i++) {
      final seg = segments[i];
      if (seg is TextRun) {
        buf.write(seg.text);
      } else if (seg is TextControl) {
        if (seg.isPageBreak) {
          final t = buf.toString().trim();
          if (t.isNotEmpty) out.add((t, i));
          buf.clear();
        } else if (seg.isLineBreak) {
          buf.write('\n');
        }
      }
    }
    final tail = buf.toString().trim();
    if (tail.isNotEmpty) out.add((tail, segments.length));
    return out;
  }

  /// 这一页（`segments[..upto)`）里有没有 `[Yes]`(24) / `[No]`(25)。
  ///
  /// ⚠️ `[Yes]`/`[No]` 是**文本控制码**，不是事件指令 ——
  /// 它们出现在 `TEXTSHOW` 的消息正文里，由文本引擎处理
  /// （`src/TalkInterpret.c:207-231` 的 `StartTalkChoice`）。
  ///
  /// 我第一版把它当成事件指令去生成器里找，自然一个都找不到。
  ///
  /// 返回 `(有, 默认是否选"是")`：`[Yes]` 默认选是、`[No]` 默认选否。
  (bool, bool) choiceInPage(int upto) {
    for (var i = 0; i < upto && i < segments.length; i++) {
      final seg = segments[i];
      if (seg is TextControl) {
        if (seg.name == 'Yes') return (true, true);
        if (seg.name == 'No') return (true, false);
      }
    }
    return (false, true);
  }

  /// 在 [upto]（页界 token 下标）处结束这一页的，是不是 `[A]`（等按键）？
  ///
  /// `[A]` 等按键、`[CR]` 只是滚动清屏（`src/TalkInterpret.c:86-108`）。
  bool isWaitForKeyAt(int upto) {
    // ⚠️ `pageSpans` 存的是**分页控制码本身**的下标
    // （`out.add((t, i))` 里的 `i` 就是那个控制码的位置），
    // 所以要看 `segments[upto]`，**不是 `upto - 1`**。
    // 我第一版写成 `upto - 1`，差一位 → 箭头永远画不出来
    // （截图字节与改动前完全一致，是"根本没变"的信号）。
    if (upto < 0 || upto >= segments.length) return false;
    final seg = segments[upto];
    return seg is TextControl && seg.isWaitForKey;
  }

  /// 返回每一页的纯文字（已去掉控制码、`[LF]` 已换成换行）。
  List<String> get pages => [for (final p in pageSpans) p.$1];


}

/// 全部游戏文本
class GameTexts {
  GameTexts({
    required this.messages,
    required this.titles,
    Map<int, List<String>>? translations,
  }) : translations = translations ?? <int, List<String>>{};
  //                                  ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  // ⚠️ **不能用 `const {}` 当默认值** —— 那是**不可变 map**，
  // `applyTranslations` 一 `clear()` 就抛
  // `Unsupported operation: Cannot modify unmodifiable map`，
  // 而它被 `try` 包着 —— 结果是**整个剧本加载失败**（截图里 HUD 上能看见）。
  //
  // 教训：`const` 默认值藏在构造函数签名里，很容易看漏。</

  /// 空表 —— 给"不依赖数据文件"的单测用（例如开场流程的状态机）。
  ///
  /// ⚠️ 数据管线没跑时**不要**拿它当兜底：那会静默丢掉全部文案。
  /// 它只用于"本来就不需要文案"的测试。
  /// 空表 —— 给"不依赖数据文件"的单测用。
  GameTexts.empty()
      : messages = const {},
        titles = const {},
        translations = <int, List<String>>{};

  final Map<int, GameMessage> messages;

  /// 章节内部名 → 标题
  final Map<String, String> titles;

  /// **译文覆盖**：消息 id → 按顺序的文本段。
  ///
  /// ## 为什么是"按段的数组"而不是一段文本
  ///
  /// 消息的载体是「文本段」与「控制码」交替（见 [TextSegment]）。
  /// 译文**只替换文本段，控制码原位不动** —— 所以译文按顺序给出每一段，
  /// **段数不匹配就直接不采用**，不会静默错版。
  ///
  /// 出处：`assets/i18n/zh_CN.json`，由 `tools/i18n/i18n.py apply` 产出。
  final Map<int, List<String>> translations;

  /// 有译文吗
  bool get hasTranslation => translations.isNotEmpty;

  /// **UI 用词**：日文字面量 → 译文。
  ///
  /// 为什么单独一张表：原作的菜单项是 **OAM 精灵**，不在消息表里
  /// （见 `docs/菜单盘点.md`）—— 所以代码里那几个字面量没有消息 id 可用。
  final Map<String, String> uiTerms = {};

  /// 读译文覆盖（缺文件就当作没有汉化 —— 不崩）
  void applyTranslations(Map<int, List<String>> t) {
    translations
      ..clear()
      ..addAll(t);
  }

  /// 取 UI 用词的译文；没有就返回原文
  String ui(String jp) => uiTerms[jp] ?? jp;

  /// 带译文的消息 —— **段数不符时退回原文**（宁可显示日文，也不要错版）
  GameMessage localized(int id) {
    final m = byId(id);
    if (m == null) throw StateError('没有消息 $id');
    final t = translations[id];
    if (t == null || t.length != m.runs.length) return m;
    return m.withRuns(t);
  }

  /// 解析译文覆盖文件（`assets/i18n/zh_CN.json`）。
  ///
  /// 结构：`{"messages": {"253": ["圣魔的光石"], ...}}`
  static ({Map<int, List<String>> messages, Map<String, String> ui})
      parseTranslations(String json) {
    final d = jsonDecode(json) as Map<String, dynamic>;
    final msgs = <int, List<String>>{};
    (d['messages'] as Map<String, dynamic>).forEach((k, v) {
      msgs[int.parse(k)] = [for (final s in (v as List<dynamic>)) s as String];
    });
    final ui = <String, String>{};
    final u = d['ui'];
    if (u is Map<String, dynamic>) {
      u.forEach((k, v) => ui[k] = v as String);
    }
    return (messages: msgs, ui: ui);
  }

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
