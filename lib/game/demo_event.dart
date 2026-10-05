// 剧情演示：一段手写的事件脚本 + 把它演出来。
//
// ## 这不是从章节数据导出的
//
// 真实章节的事件在 `src/data/frontier_df3_eventscr_ch/` 里，是二进制脚本 +
// `EventListScr` 触发条件。那套数据管线属于 M6 的后半段。
//
// 这里手写一小段脚本，目的是**验证引擎本身**：指令解码、控制流、
// "等玩家按键"、表现状态、以及它在画面上真的能演出来。
//
// 手写脚本用的是**真实的编码**（`_EvtCmd` 的位打包，已由 C 编译器复核），
// 所以它能证明"引擎能执行真实格式的脚本"，而不只是"能执行我编的格式"。

import 'package:fe8r/core/core.dart';

/// 演示脚本用到的文字编号 → 文本。
///
/// 真实文本来自反编译项目的对话数据（M10 的翻译管线）。这里先用占位译文，
/// 因为**这一轮要验证的是引擎，不是译文**。
const Map<int, String> demoTextTable = {
  1: '塞思：艾莉卡殿下，前方发现敌军。',
  2: '艾莉卡：我知道了。全员，准备战斗！',
  3: '塞思：请退后，这里交给我。',
  4: '艾莉卡：不，我也要战斗。',
};

/// 立绘槽位 0 的几张"脸"（用编号占位，真实立绘属于 M11 美术管线）
const int demoFaceEirika = 1;
const int demoFaceSeth = 2;

/// 背景编号
const int demoBgPlain = 7;

/// 构造演示脚本。
///
/// 指令布局按 `_EvtCmd` 打包：`word[0] = opcode<<8 | len<<4 | sub`。
/// 参数从 word[1] 开始。
///
/// 场景：显示背景 → 双方立绘 → 三句对白（每句等玩家按键）→ 清屏 → 结束。
EventScript buildDemoEventScript() {
  int w(int cmd, int len, int sub) =>
      ((cmd & 0xFF) << 8) | ((len & 0xF) << 4) | (sub & 0xF);

  /// 一条 2 字指令：`[word0, arg0]`
  List<int> i2(int cmd, int sub, int arg0) => [w(cmd, 2, sub), arg0 & 0xFFFF];

  /// 一条 4 字指令：`[word0, arg0, arg1, arg2]`
  ///
  /// ⚠️ **必须给满 4 个字**。事件脚本在源码里是 `u32[]`
  /// （`typedef uintptr_t EventScr`），所以每个逗号分隔的元素占 **2 个 u16 字**
  /// —— 包括看起来"只是补一个 0"的那种：
  ///
  ///     #define EvtDisplayTextBg(bg) \
  ///         _EvtArg0(EV_CMD_SHOWBG, 4, EVSUBCMD_BACG, (bg)), 0,
  ///                                                       ^ 这也是 2 个字
  ///
  /// 我第一版按"字面 token 数"写，只给了 3 个字，于是解码器把下一条指令的
  /// 第一个字当成了本条的参数。
  /// **这个错误是解码器的长度检查抓出来的**（"长度为 0 的指令"）——
  /// 如果没有那道检查，它会表现为"剧情莫名跳错地方"。
  List<int> i4(int cmd, int sub, int arg0, int arg1, int arg2) =>
      [w(cmd, 4, sub), arg0 & 0xFFFF, arg1 & 0xFFFF, arg2 & 0xFFFF];

  return EventScript.decode([
    // 背景
    ...i4(EventOpcodes.showBg, ShowBgSubCommand.display, demoBgPlain, 0, 0),
    // 立绘：槽 0 = 艾莉卡，槽 1 = 塞思
    ...i2(EventOpcodes.displayFace, 0, demoFaceEirika),
    ...i2(EventOpcodes.displayFace, 1, demoFaceSeth),

    // 第一句：塞思
    ...i2(EventOpcodes.displayText, TextShowSubCommand.show, 1),
    // 第二句：艾莉卡
    ...i2(EventOpcodes.displayText, TextShowSubCommand.show, 2),
    // 第三句：塞思
    ...i2(EventOpcodes.displayText, TextShowSubCommand.show, 3),
    // 第四句：艾莉卡
    ...i2(EventOpcodes.displayText, TextShowSubCommand.show, 4),

    // 收起文字框、清屏、结束
    ...i2(EventOpcodes.displayText, TextShowSubCommand.removeAll, 0),
    ...i2(EventOpcodes.clearScreen, 0, 0),
    ...i2(EventOpcodes.end, EndSubCommand.endAll, 0),
  ]);
}
