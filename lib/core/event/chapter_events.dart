// PORT OF: src/eventinfo.c + src/eventscr_0800F8D4.c（事件脚本表的装配）
//          数据由 tools/pipeline/extract/parse_chapter_events.py 提取
//
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
// ## ⚠️ 产物是**平台相关**的，所以入库而不在 CI 里重新生成
//
// 源码里 `CALL((u8 *)<本表> + 0x70)` 是**字节偏移**，编出来却是宿主的绝对地址。
// 桩符号的布局 macOS 与 Linux 不同 —— 实测 21 张表里 20 张两边不一致。
//
// 想把它归一化成偏移也做不到：`_EvtParams2(x, y)` 打包出的 u32
// （如 `_EvtParams2(0xC, 1)` = 0x0001000C）同样大于 0xFFFF，
// 会被误判成指针。区分二者需要**重定位信息**，靠数值做不到。
//
// 所以 `chapter_events.json` 以 macOS 上生成的那份入库，
// Dart 测试跑入库产物，CI 不重新生成。
// 真正的修法是读目标文件的重定位表（`otool -r` / `readelf -r`），
// 那属于后续工作。
//
// ## 表的结构（这一轮才搞清）
//
// `EventListScr` 表**不是指令流**，而是**事件条目清单**。
// 引擎的遍历（`src/SearchAvailableEvent.c`）：
//
//     int cmdId = EVT_CMD_LO(info->listScript[0]);   // 首字低 16 位 = 条件类型
//     if (!CheckFlag(EVT_CMD_HI(info->listScript[0])))  // 高 16 位 = 标志
//         if (cmdInfo[cmdId].func(info) == 1) break;    // 条件成立就采用这条
//     info->listScript += cmdInfo[cmdId].length;        // 否则按长度跳过
//
// ⚠️ **长度单位是 `EventListScr` 元素（4 字节 = 2 个 u16 字），不是字节。**
// 条件类型各带自己的长度（实测取值 1 / 3 / 4），所以"一条条目占几个字"
// 取决于它的条件类型 —— 这也是为什么之前"当纯指令流解码"时，
// 有的表从 0 能解、有的要从 2 解：那是碰巧。
//
// 条件成立后，条目的**载荷**会被填进 `struct EventInfo`（指针、坐标、
// pid 等），其中的 `script` 才是真正的**指令流**入口。
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

/// 事件条目：条件 + 载荷。
///
/// 对应 `struct EventInfo` 里由条目字流填出来的那部分字段。
class EventListEntry {
  const EventListEntry({
    required this.offset,
    required this.conditionId,
    required this.flag,
    required this.length,
    required this.payload,
  });

  /// 在表里的**元素**偏移（不是字偏移）
  final int offset;

  /// 条件类型（首字的低 16 位）
  final int conditionId;

  /// 标志（首字的高 16 位）—— 引擎会先 `CheckFlag`
  final int flag;

  /// 本条目占多少个 `EventListScr` 元素
  final int length;

  /// 载荷元素（首字之后的部分），每个元素是 32 位
  final List<int> payload;

  /// 载荷里的**指针类**字段。
  ///
  /// ⚠️ 这些值在当前产物里是**宿主地址**（平台相关），不能当 ROM 地址用。
  /// 标出来是为了让调用方知道"这里有个待解析的引用"，
  /// 而不是把它当成一个有意义的数字。
  bool get hasUnresolvedPointer => payload.any((v) => v > 0xFFFF);

  @override
  String toString() => 'Entry(@$offset cond=$conditionId flag=0x'
      '${flag.toRadixString(16)} len=$length'
      '${hasUnresolvedPointer ? ' 含指针' : ''})';
}

/// 一张章节事件表
class ChapterEventTable {
  ChapterEventTable({
    required this.name,
    required this.words,
    Map<int, String>? ptrs,
  }) : ptrs = ptrs ?? const {};

  final String name;

  /// 原始字流（u16）。**这是提取的产物，已由 C 编译器验证。**
  ///
  /// ⚠️ 指针槽是 `null` —— 它的含义在 [ptrs] 里（符号名）。
  /// 早先这些位置存的是**宿主绝对地址**（平台相关，21 张表里 20 张
  /// macOS 与 Linux 不一致）。现在靠重定位表归一化成符号引用。
  final List<int?> words;

  /// 槽序号 → 指向的符号名。
  ///
  /// `CALL((u8 *)<本表> + 0xNN)` 会解析成"指向本表"的符号名。
  final Map<int, String> ptrs;

  /// 指针槽个数
  int get pointerSlotCount => ptrs.length;

  /// 尝试从 [start] 处当作**纯指令流**解码。
  ///
  /// 返回 null 表示这张表不是纯指令流（或起点不对）——
  /// 这是**正常情况**，不是错误：表里混着表头与子表引用。
  EventScript? decodeAsScript({int start = 0}) {
    if (start >= words.length) return null;
    try {
      return EventScript.decode(
          words.sublist(start).whereType<int>().toList());
    } on FormatException {
      return null;
    }
  }

  /// 按**条件类型长度**把表切成事件条目。
  ///
  /// [cmdInfo] 来自提取产物：条件类型 → `{func, length}`。
  ///
  /// 元素是 4 字节（2 个 u16 字），长度单位是元素 —— 换算关系别搞错。
  List<EventListEntry> parseEntries(Map<int, int> lengths) {
    final out = <EventListEntry>[];
    var elem = 0; // 元素偏移
    var guard = 0;
    while (true) {
      final wordIdx = elem * 2;
      if (wordIdx + 1 >= words.length) break;
      // 首字 = 低 16 位是条件类型，高 16 位是标志
      // 指针槽是 null —— 条目解析遇到它就停（长度规则对不上）
      final w0 = words[wordIdx];
      final w1 = words[wordIdx + 1];
      if (w0 == null || w1 == null) break;
      final conditionId = w0 & 0xFFFF;
      final flag = w1 & 0xFFFF;

      final len = lengths[conditionId];
      if (len == null) {
        // 未知条件类型：不知道要跳多少，**停下来**而不是猜一个长度。
        // 猜错会让后面所有条目错位，而且不会报错。
        break;
      }
      if (len <= 0) break;

      final payload = <int>[];
      for (var k = 1; k < len; k++) {
        final i = (elem + k) * 2;
        if (i + 1 >= words.length) break;
        final lo = words[i];
        final hi = words[i + 1];
        if (lo == null || hi == null) break;
        payload.add((hi << 16) | lo);
      }

      out.add(EventListEntry(
        offset: elem,
        conditionId: conditionId,
        flag: flag,
        length: len,
        payload: payload,
      ));

      elem += len;
      if (++guard > 100000) break;
    }
    return out;
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
  ChapterEvents(this.tables, this.cmdInfo);

  final Map<String, ChapterEventTable> tables;

  /// 条件类型 → `{func, length}`
  final Map<int, ({String func, int length})> cmdInfo;

  /// 条件类型 → 长度（供 [ChapterEventTable.parseEntries] 用）
  Map<int, int> get cmdLengths =>
      cmdInfo.map((k, v) => MapEntry(k, v.length));

  static ChapterEvents parse(String json) {
    final d = jsonDecode(json) as Map<String, dynamic>;
    final raw = d['tables'] as Map<String, dynamic>;
    final ci = <int, ({String func, int length})>{};
    (d['cmdInfo'] as Map<String, dynamic>? ?? {}).forEach((k, v) {
      final m = v as Map<String, dynamic>;
      ci[int.parse(k)] = (
        func: m['func'] as String,
        length: m['length'] as int,
      );
    });
    final out = <String, ChapterEventTable>{};
    raw.forEach((name, v) {
      final m = v as Map<String, dynamic>;
      out[name] = ChapterEventTable(
        name: name,
        words: (m['words'] as List<dynamic>)
            .map((e) => e as int?)
            .toList(),
        ptrs: (m['ptrs'] as Map<String, dynamic>? ?? {})
            .map((k, v) => MapEntry(int.parse(k), v as String)),
      );
    });
    return ChapterEvents(out, ci);
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

// ---------------------------------------------------------------------------
// `LOMA` / `CAMERA` 的**操作数语义**
//
// 出处：`src/eventscr_0800F390.c:31-72`（`Event25_ChangeMap`）
//
// ```c
// short chIndex = current[1];
// x = ((u16 *)(gEventSlots + 0xB))[0];
// y = ((u16 *)(gEventSlots + 0xB))[1];
// if (chIndex < 0) chIndex = gEventSlots[2];
// gPlaySt.chapterIndex = chIndex;
// RestartBattleMap();
// gBmSt.camera.x = GetCameraCenteredX(x * 16);
// gBmSt.camera.y = GetCameraCenteredY(y * 16);
// ```
//
// 两处都容易想当然：
//
// 1. **`chIndex` 是有符号 short**。脚本里 `LOMA(0xFFFF)` 真的存在
//    （`EventScr_CutsceneExecEnd_Sub1`），它的意思是"章节号取槽 2"，
//    不是"第 65535 章"。当成无符号处理就永远查不到地图。
// 2. **相机坐标在槽 0xB**：低 16 位是 x、高 16 位是 y
//    （`SVAL(EVT_SLOT_B, 0x000A000E)` → x=14, y=10）。
//    不读它就只能居中到地图中央 —— 取景就不是脚本要的那一块。

/// `chIndex` 的解析（含"负数 → 用槽 2"这条分支）
int resolveLomaChapter(int operand, int slot2) {
  final u16 = operand & 0xFFFF;
  final signed = u16 >= 0x8000 ? u16 - 0x10000 : u16;
  return signed < 0 ? slot2 : signed;
}

/// `LOMA` 的相机坐标：槽 0xB 的**低 16 位 = x，高 16 位 = y**
({int x, int y}) lomaCamera(int slotB) =>
    (x: slotB & 0xFFFF, y: (slotB >> 16) & 0xFFFF);

// ---------------------------------------------------------------------------
// 事件条目的**遍历**（`SearchAvailableEvent`，`src/SearchAvailableEvent.c:24-60`）
//
// ```c
// for (;;) {
//     int cmdId  = EVT_CMD_LO(info->listScript[0]);      // 首字**低 16 位** = 条件类型
//     if (!CheckFlag(EVT_CMD_HI(info->listScript[0])))   // 首字**高 16 位** = 标志
//         if (cmdInfo[cmdId].func(info) == 1) break;     // 条件成立 ⇒ 采用这条
//     info->listScript += cmdInfo[cmdId].length;         // 否则按**长度**跳过
// }
// ```
//
// ★ 两条已确证的规则（本函数只做这两条）：
//   1. **标志门**：`CheckFlag(高 16 位)` 为真 ⇒ **整条跳过**（连条件函数都不调）；
//   2. **长度跳过**：条件不成立时，前进 `cmdInfo[cmdId].length` **个字**。
//
// ⚠️ **未读**：各个 `EvCheck*`（`EvCheck02_TURN` / `EvCheck03_CHAR` / `EvCheck05_LOCA`
//    / `EvCheck06_VILL` / `EvCheck07_CHES` / `EvCheck01_AFEV` …）**函数体**我还没读
//    ⇒ 条件是否成立由调用方通过 [conditionFuncs] 注入，**本文件不猜**。
//    调用方给不出实现时，返回 `null`（= "没找到可用条目"），而不是假装成立。
//
// [entries]: 每条 = 首字 + 该条的脚本（跳过用长度，不用脚本长度）
// [conditionFuncs]: `cmdId → (首字) → bool`
// 返回：被采用的那条（`null` = 走到末尾都没找到）
/// 条件函数：读**整条 entry 的字**，成立时**回写** `script` / `flag`
/// （照 `src/eventinfo_08085B30.c` 的 `EvCheck01_AFEV` / `EvCheck02_TURN`：
/// 两者都在成立时写 `info->script = listScript->script;`
/// `info->flag = EVT_CMD_HI(listScript->unk0);`）。
///
/// ⚠️ `Always`（`:51-53`）**只 `return 1`，不写** `script`/`flag` —— 所以这里允许返回
/// `null` 表示"没写"，调用方据此沿用外层已有的值（**不替它编一个**）。
class EventCheckResult {
  const EventCheckResult({this.script, this.flag});

  final EventScript? script;
  final int? flag;
}

/// `searchAvailableEvent` 的返回值
typedef AvailableEvent = ({int cmdId, List<int> words, EventScript? script, int? flag, int index});

/// 事件条目的**遍历**（`SearchAvailableEvent`，`src/SearchAvailableEvent.c:24-60`）
///
/// ```c
/// for (;;) {
///     int cmdId = EVT_CMD_LO(info->listScript[0]);      // 首字低 16 位 = 条件类型
///     if (!CheckFlag(EVT_CMD_HI(info->listScript[0])))  // 首字高 16 位 = 标志
///         if (cmdInfo[cmdId].func(info) == 1) break;    // 成立 ⇒ 采用这条
///     info->listScript += cmdInfo[cmdId].length;        // 否则按**长度**跳过
/// }
/// ```
///
/// ★ 三条已确证的规则：
///   1. **标志门**：`CheckFlag(高 16 位)` 为真 ⇒ 整条跳过（**不调条件函数**）；
///   2. **长度跳过**：条件不成立时前进 `cmdInfo[cmdId].length` **个字**；
///   3. **条件拿的是整条 entry 的字**（不是只有首字）—— 见 [EventCheckResult]。
AvailableEvent? searchAvailableEvent({
  required List<({List<int> words, EventScript script})> entries,
  required Map<int, int> cmdLengths,
  required bool Function(int flag) checkFlag,
  required Map<int, EventCheckResult? Function(List<int> words)> conditionFuncs,
}) {
  var i = 0;
  while (i < entries.length) {
    final words = entries[i].words;
    if (words.isEmpty) return null;
    final first = words[0];
    final cmdId = first & 0xFFFF; // 低 16 位 = 条件类型
    final flag = (first >> 16) & 0xFFFF; // 高 16 位 = 标志
    // 规则 1：标志门 —— 为真就整条跳过（**不调条件函数**）
    if (!checkFlag(flag)) {
      final f = conditionFuncs[cmdId];
      final r = f == null ? null : f(words);
      if (r != null) {
        return (
          cmdId: cmdId,
          words: words,
          script: r.script ?? entries[i].script,
          flag: r.flag,
          index: i,
        );
      }
    }
    // 规则 2：按**长度**跳过（缺长度 = 无法前进 ⇒ 停，不瞎猜）
    final len = cmdLengths[cmdId];
    if (len == null || len <= 0) return null;
    i += len;
  }
  return null;
}

// ---------------------------------------------------------------------------
// 两个**读过函数体**的条件（`src/eventinfo_08085B30.c`）
// ---------------------------------------------------------------------------

/// `EvCheck00_Always`（`:51-53`）：`return 1;` —— **不写** `script`/`flag`。
EventCheckResult alwaysCheck(List<int> words) => const EventCheckResult();

/// `EvCheck02_TURN`（`:64-79`）：
///
/// ```c
/// struct EvCheck02 { u32 unk0; u32 script; u8 turn; u8 maxTurn; u16 faction; };
/// if (maxTurn == 0)        maxTurn = turn;          // 单回合事件
/// else if (maxTurn == 0xff) maxTurn = INT32_MAX;
/// if (turn <= chapterTurn && chapterTurn <= maxTurn && gPlaySt.faction == faction) { …; return 1; }
/// return 0;
/// ```
///
/// ⚠️ `maxTurn == 0` **就是** `turn`（不是"无上限"）；`0xFF` 才是无上限。
EventCheckResult? turnCheck(
  List<int> words, {
  required int chapterTurn,
  required int chapterFaction,
}) {
  if (words.length < 3) return null; // 长度不够 ⇒ 不猜
  final w2 = words[2];
  final turn = w2 & 0xFF;
  var maxTurn = (w2 >> 8) & 0xFF;
  final faction = (w2 >> 16) & 0xFFFF;
  if (maxTurn == 0) {
    maxTurn = turn;
  } else if (maxTurn == 0xFF) {
    maxTurn = 0x7FFFFFFF; // INT32_MAX
  }
  if (turn <= chapterTurn && chapterTurn <= maxTurn && chapterFaction == faction) {
    return EventCheckResult(
      script: null, // 调用方用 entry 自己的 script（words[1] 是它的字偏移）
      flag: (words[0] >> 16) & 0xFFFF,
    );
  }
  return null;
}

/// `EvCheck01_AFEV`（`:55-62`）：
/// `unk8 ∈ {0, 100}` 或 `CheckFlag(unk8)` 成立时采用该条，并写 `script`/`flag`。
EventCheckResult? afevCheck(List<int> words, {required bool Function(int flag) checkFlag}) {
  if (words.length < 3) return null;
  final unk8 = words[2];
  if (unk8 == 0 || unk8 == 100 || checkFlag(unk8)) {
    return EventCheckResult(
      script: null,
      flag: (words[0] >> 16) & 0xFFFF,
    );
  }
  return null;
}
