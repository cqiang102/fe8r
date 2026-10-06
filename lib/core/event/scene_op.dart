// 场景剧情脚本的**类型模型**。
//
// ## 这是手写的稳定部分
//
// 由 `tools/pipeline/extract/gen_scene_dart.py` 从 C 源码**直接生成**
// `scene_data.g.dart`，里面是数据；本文件是它依赖的类型与执行器。
//
// ## 为什么用 sealed class 而不是"字符串操作码 + 无类型参数"
//
// 第一版是：
//
//     class SceneInstruction {
//       final String op;          // 字符串当操作码
//       final List<Object> args;  // 无类型参数
//     }
//     switch (ins.op) { case 'TEXTSHOW': ... default: 记进"未实现" }
//
// **那是把 Dart 当动态语言写。** 换成 sealed class 之后：
//
//   * `switch` 由**编译器保证穷尽** —— 新增一种指令，
//     所有没处理它的地方直接编译不过
//   * 参数是**真实字段**，不再靠运行时 `whereType` 和 `is int`
//   * "未实现指令"从一个运行时统计变成**编译期错误**
//
// ## 为什么仍然保留"指令列表"而不是生成 async 函数
//
// 项目要求**随时存档**（技术方案 §4.4）。`async` 函数的状态没法序列化，
// 而"指令列表 + 程序计数器"可以。所以生成的是数据，执行靠 [SceneRunner]。
//
// 编译期检查由生成器负责：生成器知道所有脚本的名字，
// 引用到不存在的脚本时它会**直接报错**，而不是让运行时去发现。

/// 一条场景指令
sealed class SceneOp {
  const SceneOp();
}

/// 符号引用（脚本名、单位表名、函数名…），可带偏移
///
/// 用**名字**而不是地址：Dart 里没有指针，符号在运行期由名字查表。
class Sym {
  const Sym(this.name, [this.offset = 0]);

  final String name;
  final int offset;

  @override
  bool operator ==(Object other) =>
      other is Sym && other.name == name && other.offset == offset;

  @override
  int get hashCode => Object.hash(name, offset);

  @override
  String toString() =>
      offset == 0 ? name : '$name+0x${offset.toRadixString(16)}';
}

/// 生成器没能归类的参数原文。
///
/// **它出现就代表生成器要补映射**，不是一个正常的运行时状态 ——
/// 所以它是个 const 类（能进 `const` 列表），而不是一个函数。
final class RawArg {
  const RawArg(this.text);
  final String text;
  @override
  String toString() => '?$text';
}

// ---------------------------------------------------------------------------
// 控制流
// ---------------------------------------------------------------------------

/// `CALL(target)` / `CALL((u8 *)target + 0xNN)` —— 调用另一个脚本
final class CallScript extends SceneOp {
  const CallScript(this.target);
  final Sym target;
}

/// `SVAL(slot, value)` —— 给插槽赋值（值可能是符号）
final class SetSlot extends SceneOp {
  const SetSlot(this.slot, this.value);
  final int slot;
  final Object value;

  Sym? get sym => value is Sym ? value as Sym : null;
}

/// `SVAL2` —— 双字插槽赋值
final class SetSlot2 extends SceneOp {
  const SetSlot2(this.slot, this.lo, this.hi);
  final int slot;
  final int lo;
  final int hi;
}

/// `SADD` / `SSUB` 等插槽算术
final class SlotArith extends SceneOp {
  const SlotArith(this.op, this.dst, this.src);
  final String op;
  final int dst;
  final Object src;
}

/// `SENQUEUE1/2/3` —— 把后续指令排队
final class EnqueueOps extends SceneOp {
  const EnqueueOps(this.count);
  final int count;
}

/// `BNE` / `BEQ` —— 条件跳转
final class BranchIf extends SceneOp {
  const BranchIf({
    required this.equal,
    required this.slot,
    required this.label,
    required this.opCount,
  });

  final bool equal;
  final int slot;
  final int label;
  final int opCount;
}

/// `GOTO(label)` —— 无条件跳转
final class GoTo extends SceneOp {
  const GoTo(this.label);
  final int label;
}

/// `LABEL(n)` —— 跳转目标
final class Label extends SceneOp {
  const Label(this.index);
  final int index;
}

/// `END` / `ENDA` —— 脚本结束
final class EndScript extends SceneOp {
  const EndScript(this.all);
  final bool all;
}

/// `CALL_SLOT` 之类 —— 调用插槽里存的脚本
final class CallFromSlot extends SceneOp {
  const CallFromSlot(this.slot);
  final int slot;
}

// ---------------------------------------------------------------------------
// 文本与立绘
// ---------------------------------------------------------------------------

/// `TEXTSHOW(id)` —— 显示一段文字
final class ShowTextOp extends SceneOp {
  const ShowTextOp(this.textId);
  final int textId;
}

/// `TEXTSTART` / `TEXTEND`
final class TextBoxOp extends SceneOp {
  const TextBoxOp(this.start);
  final bool start;
}

/// `REMA` —— 清掉当前文字
final class ClearTextOp extends SceneOp {
  const ClearTextOp();
}

/// `SETTEXTTYPE(type)`
final class SetTextTypeOp extends SceneOp {
  const SetTextTypeOp(this.type);
  final int type;
}

/// 立绘相关：`LOADFACE` / `DISPLAYFACE` / `MOVEFACE` / `CLEARFACE`…
final class FaceOp extends SceneOp {
  const FaceOp(this.op, this.args);
  final String op;
  final List<Object> args;
}

/// 背景相关：`SHOWBG` / `CLEARSCREEN`…
final class BackgroundOp extends SceneOp {
  const BackgroundOp(this.op, this.args);
  final String op;
  final List<Object> args;
}

// ---------------------------------------------------------------------------
// 单位与镜头
// ---------------------------------------------------------------------------

/// `LOAD1/2/3(slot, unitDef)` —— 加载单位表
final class LoadUnitsOp extends SceneOp {
  const LoadUnitsOp(this.group, this.table);
  final int group;
  final Sym table;
}

/// `MOVE` / `MOVE_CLOSEST` / `MOVEONTO` / `MOVE_1STEP`
final class MoveUnitOp extends SceneOp {
  const MoveUnitOp(this.op, this.args);
  final String op;
  final List<Object> args;
}

/// `CAMERA_AT` / `CAMERA_CHAR` 等
final class CameraOp extends SceneOp {
  const CameraOp(this.op, this.args);
  final String op;
  final List<Object> args;
}

/// `CURSOR_CHAR` / `CURSOR_FLASH` —— 光标
final class CursorOp extends SceneOp {
  const CursorOp(this.op, this.args);
  final String op;
  final List<Object> args;
}

/// `ENUN` / `ENUT` / `ENDA` —— 结束单位行动
final class EndUnitOp extends SceneOp {
  const EndUnitOp(this.op);
  final String op;
}

// ---------------------------------------------------------------------------
// 音频与画面效果
// ---------------------------------------------------------------------------

/// `MUSI` / `MUSC` / `MUSC` / `BGMCHANGE` 等
final class MusicOp extends SceneOp {
  const MusicOp(this.op, this.args);
  final String op;
  final List<Object> args;
}

/// `FADI` / `FADU` / `FADECONF` —— 淡入淡出
final class FadeOp extends SceneOp {
  const FadeOp(this.op, this.args);
  final String op;
  final List<Object> args;
}

/// `STAL(frames)` —— 暂停若干帧
final class StallOp extends SceneOp {
  const StallOp(this.frames);
  final int frames;
}

/// `EVBIT_T` / `EVBIT_F` —— 事件位
final class EventBitOp extends SceneOp {
  const EventBitOp(this.set, this.id);
  final bool set;
  final int id;
}

/// `ASMC(addr)` —— 调用一段 C 函数（重制版需要逐个替换成 Dart 实现）
final class AsmCallOp extends SceneOp {
  const AsmCallOp(this.target);
  final Sym target;
}

/// 认得、但本阶段只记录不执行的指令（状态类）
final class MiscOp extends SceneOp {
  const MiscOp(this.op, this.args);
  final String op;
  final List<Object> args;
}

// ---------------------------------------------------------------------------
// 脚本
// ---------------------------------------------------------------------------

/// 一个场景脚本：名字 + 指令列表
class SceneScript {
  const SceneScript(this.name, this.ops);

  final String name;
  final List<SceneOp> ops;

  @override
  String toString() => 'SceneScript($name, ${ops.length} 条)';
}
