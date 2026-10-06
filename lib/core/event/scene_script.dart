// 场景剧情脚本（从**源码**解析）与游戏文本。
//
// ## 为什么不是编译产物
//
// 场景脚本走的是"直接读源码"这条路，不是"编译成字节再读回来"。
// 源码里每行就是一条指令，参数就是名字：
//
//     EventListScr EventScr_Prologue_BeginningScene[] = {
//         CALL(EventScr_Prologue_RenaisThroneCutscene)
//         SVAL(EVT_SLOT_2, EventScr_Prologue_EirikaAttacked)
//         TEXTSTART
//         TEXTSHOW(0x8CE)
//         TEXTEND
//         ...
//     }
//
// 前面绕了三轮"编译 → 指针槽是宿主地址 → 还原符号名"，
// 而**名字本来就写在源码里**。更关键的是：**虚拟机不需要 GBA 的打包字** ——
// `word[0]=(cmd<<8)|(len<<4)|sub` 是实现细节，Dart 侧的输入就该是
// `(指令名, 参数)`。
//
// ## 参数三类
//
//   * `int`                    数值（含 `EVT_SLOT_*` 这类常量）
//   * `SceneSym`               符号引用（`CALL(X)` / `LOAD1(1, X)`）
//   * `SceneRaw`              解析不了的原文 —— **保留而不猜**
//
// `SceneRaw` 的存在是刻意的：猜一个错误的解释，比承认"这里没解析出来"
// 要危险得多。

import 'dart:convert';

/// 符号引用（可带偏移，如 `ASMC(BmGuideTextSetAllGreen + 0x1)`）
class SceneSym {
  const SceneSym(this.name, [this.offset = 0]);

  final String name;
  final int offset;

  @override
  String toString() => offset == 0 ? name : '$name+0x${offset.toRadixString(16)}';
}

/// 解析不了的参数原文
class SceneRaw {
  const SceneRaw(this.text);

  final String text;

  @override
  String toString() => '?$text';
}

/// 一条场景指令
class SceneInstruction {
  const SceneInstruction({required this.op, required this.args});

  /// 指令名 —— 直接用 `EAstdlib.h` 的**宏名**（`CALL` / `TEXTSHOW` / `ENUT`…）
  ///
  /// 刻意不用 `EV_CMD_*` 的数字：那是另一套命名，而且
  /// `case 'TEXTSHOW'` 比 `case 0x1B` 可读得多。
  final String op;

  final List<Object> args;

  /// 这一条引用的符号名（用于依赖分析：`CALL` 指向哪个脚本）
  List<SceneSym> get syms =>
      args.whereType<SceneSym>().toList();

  @override
  String toString() => '$op(${args.join(', ')})';
}

/// 一个场景脚本
class SceneScript {
  const SceneScript({required this.name, required this.instructions});

  final String name;
  final List<SceneInstruction> instructions;

  static SceneScript fromJson(String name, List<dynamic> raw) => SceneScript(
        name: name,
        instructions: raw.map((e) {
          final m = e as Map<String, dynamic>;
          return SceneInstruction(
            op: m['op'] as String,
            args: (m['args'] as List<dynamic>).map(_arg).toList(),
          );
        }).toList(),
      );

  static Object _arg(dynamic a) {
    if (a is int) return a;
    final m = a as Map<String, dynamic>;
    if (m.containsKey('sym')) {
      return SceneSym(m['sym'] as String, (m['off'] as int?) ?? 0);
    }
    return SceneRaw(m['raw'] as String? ?? '?');
  }
}

/// 全部场景脚本
class SceneScripts {
  SceneScripts(this.scripts);

  final Map<String, SceneScript> scripts;

  static SceneScripts parse(String json) {
    final d = jsonDecode(json) as Map<String, dynamic>;
    final raw = d['scripts'] as Map<String, dynamic>;
    return SceneScripts(raw.map((k, v) =>
        MapEntry(k, SceneScript.fromJson(k, v as List<dynamic>))));
  }

  /// 一条脚本引用到的**全部**符号名（不论是否存在）。
  ///
  /// ⚠️ 刻意**不**过滤掉不存在的那种。
  /// 第一版只返回"存在的"，结果一个**真实缺口**被藏了起来：
  /// 序章开场 `CALL(EventScr_CallOnTutorialMode)`，而那个脚本
  /// 并不在解析出的 166 个里 —— 跑序章会在那里断掉。
  /// 过滤掉等于把"跑不起来的原因"从视野里删掉。
  Set<String> referencedSymbolsOf(String name) {
    final s = scripts[name];
    if (s == null) return {};
    return {for (final i in s.instructions) ...i.syms.map((x) => x.name)};
  }

  /// 引用到、但**找不到定义**的符号 —— 也就是"跑不通的原因"
  Set<String> missingOf(String name) {
    final refs = referencedSymbolsOf(name);
    return refs.where((r) =>
        r.startsWith('EventScr_') && !scripts.containsKey(r)).toSet();
  }

  /// 引用到的、且确实存在的脚本
  Set<String> dependenciesOf(String name) =>
      referencedSymbolsOf(name).where(scripts.containsKey).toSet();
}

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
  String toString() => '[$name${arg == null ? '' : ']${arg!.toRadixString(16)}'}]';
}

/// 一条游戏文本
class GameMessage {
  const GameMessage({required this.id, required this.segments});

  final int id;
  final List<TextSegment> segments;

  /// 去掉控制码的纯文字
  String get plain =>
      segments.whereType<TextRun>().map((r) => r.text).join();

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
