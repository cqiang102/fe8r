// PORT OF: include/event.h 的指令编码宏 + include/eventscript.h 的指令集
//
// 事件脚本的**指令解码**。
//
// ## 指令编码
//
// 脚本是 `u16[]`，每条指令的第一个字按位打包：
//
//     word[0] = (cmd & 0xFF) << 8 | (len & 0x0F) << 4 | (sub & 0x0F)
//               ^^^^^^^^^^^^^^^^    ^^^^^^^^^^^^^^^^    ^^^^^^^^^^^
//               操作码              长度（u16 字数）    子命令
//
// 参数从 `word[1]` 开始，按 **s16** 解释。
//
// 这套常量由 `tools/pipeline/extract/verify_eventscript.py` 用 C 编译器复核：
// 不是"照着源码抄一遍"（那只能证明抄得一致），而是把 `_EvtCmd` 宏展开后
// 让编译器把值算出来比对。
//
// ⚠️ 长度是**字（u16）数**，不是字节数。按字节算会让所有指令错位。

/// 一条已解码的事件指令。
class EventInstruction {
  const EventInstruction({
    required this.offset,
    required this.opcode,
    required this.length,
    required this.subCommand,
    required this.args,
  });

  /// 在脚本里的字偏移（用于跳转与调试）
  final int offset;

  /// 操作码（`EV_CMD_*`）
  final int opcode;

  /// 长度，单位是 **u16 字**（含第一个字）
  final int length;

  /// 子命令（`EVSUBCMD_*`，语义随 [opcode] 变化）
  final int subCommand;

  /// 子命令的**低 3 位**（`EVT_SUB_CMD_LO`）。
  ///
  /// 有些指令把 4 位的子命令字段拆成两半用：低 3 位是子命令，
  /// 第 3 位是附加标志（`MOVEUNIT` 的 `modify`、`CAMERACONTROL` 的第二参数）。
  ///
  ///     #define EVT_SUB_CMD_LO(scr) (*(const u16*)scr & 0x7)
  ///     #define EVT_SUB_CMD_HI(scr) ((*(const u16*)scr & 0xF) >> 0x3)
  ///
  /// ⚠️ 直接用 `subCommand` 当子命令会出错：`MOVEUNIT` 的
  /// `EVSUBCMD_MOVE | (modify << 3)` 在 modify=1 时子命令是 8，
  /// 而真实的子命令是 0（MOVE）。
  int get subCommandLow => subCommand & 0x7;

  /// 子命令的**第 3 位**（`EVT_SUB_CMD_HI`）
  int get subCommandHigh => (subCommand & 0xF) >> 3;

  /// 参数（`s16`）
  final List<int> args;

  /// 编码回一个字流
  List<int> encode() {
    final w0 = ((opcode & 0xFF) << 8) | ((length & 0xF) << 4) | (subCommand & 0xF);
    return [w0, ...args.map((a) => a & 0xFFFF)];
  }

  @override
  String toString() {
    final name = EventOpcodes.nameOf(opcode);
    final a = args.isEmpty ? '' : ' ${args.join(', ')}';
    return '[$offset] $name(0x${opcode.toRadixString(16)}) '
        'len=$length sub=$subCommand$a';
  }
}

/// 事件脚本：一串指令 + 标签表。
class EventScript {
  EventScript({required this.instructions, required this.labels});

  final List<EventInstruction> instructions;

  /// 标签名 → 字偏移
  final Map<String, int> labels;

  /// 从 `u16` 字流解码。
  ///
  /// 遇到 `length == 0` 会**停下来并报错**：长度 0 的指令会让偏移原地打转，
  /// 是死循环的经典成因。原版不会产生这种指令，出现就说明流读歪了。
  static EventScript decode(List<int> words) {
    final out = <EventInstruction>[];
    final labels = <String, int>{};
    var i = 0;
    var guard = 0;

    while (i < words.length) {
      final w0 = words[i] & 0xFFFF;
      final opcode = (w0 >> 8) & 0xFF;
      final len = (w0 >> 4) & 0xF;
      final sub = w0 & 0xF;

      if (len == 0) {
        throw FormatException(
          '字偏移 $i 处的指令长度为 0（word=0x${w0.toRadixString(16)}）。'
          '长度为 0 会让执行器原地踏步。',
        );
      }
      if (i + len > words.length) {
        throw FormatException(
          '字偏移 $i 处的指令声明长度 $len，超出脚本末尾（共 ${words.length} 字）',
        );
      }

      final rawArgs = <int>[];
      for (var k = 1; k < len; k++) {
        final v = words[i + k] & 0xFFFF;
        rawArgs.add(v >= 0x8000 ? v - 0x10000 : v); // s16
      }

      final inst = EventInstruction(
        offset: i,
        opcode: opcode,
        length: len,
        subCommand: sub,
        args: rawArgs,
      );
      out.add(inst);

      // 标签：原版用 GOTO 的目标地址标记，这里把"指向自己的第一个参数"
      // 记录成可读的 label_N，方便调试与测试。
      if (opcode == EventOpcodes.label && rawArgs.isNotEmpty) {
        labels['label_${rawArgs[0]}'] = i;
      }

      i += len;
      guard++;
      if (guard > 1 << 20) {
        throw const FormatException('解码超过 100 万条指令，疑似脚本损坏');
      }
    }

    return EventScript(instructions: out, labels: labels);
  }

  static EventScript fromJsonWords(List<dynamic> words) =>
      decode(words.map((e) => e as int).toList());

  /// 按偏移找指令下标；找不到返回 null
  int? indexAtOffset(int offset) {
    for (var i = 0; i < instructions.length; i++) {
      if (instructions[i].offset == offset) return i;
    }
    return null;
  }

  @override
  String toString() => 'EventScript(${instructions.length} 条指令, '
      '${labels.length} 个标签)';
}

/// 操作码与子命令常量。
///
/// 值全部来自 `tools/pipeline/out/tables/eventscript.json`
/// （由 C 编译器复核）。这里只列**已经实现**的那些 —— 列一堆用不到的
/// 常量只会让"这个引擎支持什么"变得含糊。
class EventOpcodes {
  const EventOpcodes._();

  static const int nop = 0x00;
  static const int end = 0x01;
  static const int evSet = 0x02;
  static const int evCheck = 0x03;
  static const int randomNumber = 0x04;
  static const int sVal = 0x05;
  static const int slotOps = 0x06;
  static const int queueOps = 0x07;

  // ---- 以下由"真实场景频次"驱动补上（见 parse_event_scripts.py）----
  //
  // "150 个指令里实现了 27 个"没有意义 —— 那 27 个是挑的。
  // 这几个是拿 166 张真实场景、4263 条真实指令统计出来的高频缺口：
  //   QUEUE_OPS 7.81% / DISPLAYCURSOR 5.93% / ENUN 4.13%
  //   CHANGESTATE 3.54% / FADE 3.50% / LOADUNIT 2.58%
  // 补上这 6 个，真实覆盖率从 61.0% 升到 ~88.5%。
  static const int fade = 0x17;
  static const int loadUnit = 0x2C;
  static const int enun = 0x30;
  static const int changeState = 0x34;
  static const int displayCursor = 0x3B;
  static const int label = 0x08;
  static const int goTo = 0x09;
  static const int call = 0x0A;
  static const int enqueueCall = 0x0B;
  static const int branch = 0x0C;
  static const int asmc = 0x0D;
  static const int stall = 0x0E;
  static const int counter = 0x0F;
  static const int evBitModify = 0x10;

  // ---- 表现类指令 ----
  // 这一组的"实现"是**重写**而不是移植：原版深绑 GBA 的文字/渲染系统
  // （EventText_StartTalkMsg 之类）。按方案的三层划分，VM 只建模
  // "脚本想要什么"，怎么画由表现层决定。
  static const int setTextType = 0x1A;
  static const int displayText = 0x1B;
  static const int continueText = 0x1C;
  static const int endText = 0x1D;
  static const int displayFace = 0x1E;
  static const int moveFace = 0x1F;
  static const int clearTextBox = 0x20;
  static const int showBg = 0x21;
  static const int clearScreen = 0x22;

  // ---- 单位与镜头 ----
  static const int cameraControl = 0x26;
  static const int moveUnit = 0x2F;

  /// 全表（由提取出的 JSON 注入，用于把操作码翻译成名字）
  static Map<int, String> _names = const {};

  static void loadNames(Map<String, dynamic> commands) {
    final m = <int, String>{};
    for (final e in commands.entries) {
      m[e.value as int] = e.key;
    }
    _names = m;
  }

  static String nameOf(int opcode) =>
      _names[opcode] ?? 'EV_CMD_0x${opcode.toRadixString(16)}';
}

/// `EV_CMD_END` 的子命令
class EndSubCommand {
  static const int returnFromCall = 0; // EVSUBCMD_ENDA
  static const int endAll = 1; // EVSUBCMD_ENDB
}

/// `EV_CMD_BRANCH` 的子命令
class BranchSubCommand {
  static const int eq = 0;
  static const int ne = 1;
  static const int ge = 2;
  static const int gt = 3;
  static const int le = 4;
  static const int lt = 5;
}

/// `EV_CMD_SLOT_OPS` 的子命令
class SlotOpSubCommand {
  static const int add = 0;
  static const int sub = 1;
  static const int mul = 2;
  static const int div = 3;
  static const int mod = 4;
  static const int and = 5;
  static const int or = 6;
  static const int xor = 7;
  static const int lsl = 8;
  static const int lsr = 9;
}

/// `EV_CMD_EVSET` 的子命令
class EvSetSubCommand {
  static const int clearEventBit = 0; // EVSUBCMD_EVBIT_F
  static const int setEventBit = 8; // EVSUBCMD_EVBIT_T
}

/// `EV_CMD_DISPLAYTEXT` 的子命令
class TextShowSubCommand {
  static const int show = 0; // EVSUBCMD_TEXTSHOW
  static const int show2 = 1; // EVSUBCMD_TEXTSHOW2
  static const int removeAll = 2; // EVSUBCMD_REMA
}

/// `EV_CMD_SETTEXTTYPE` 的子命令（对话框样式）
class TextTypeSubCommand {
  static const int talk = 0; // EVSUBCMD_TEXTSTART
  static const int removePortraits = 1; // EVSUBCMD_REMOVEPORTRAITS
  static const int tutorial = 3; // EVSUBCMD_TUTORIALTEXTBOXSTART
  static const int solo = 4; // EVSUBCMD_SOLOTEXTBOXSTART
}

/// `EV_CMD_MOVEUNIT` 的子命令（只用**低 3 位**）
class MoveUnitSubCommand {
  static const int move = 0; // EVSUBCMD_MOVE：走到指定 (x,y)
  static const int moveOnto = 1; // EVSUBCMD_MOVEONTO：走到目标所在位置
  static const int moveOneStep = 2; // EVSUBCMD_MOVE_1STEP：朝指定方向走一格
  static const int moveDefined = 3; // EVSUBCMD_MOVE_DEFINED：按队列路径走
}

/// `EV_CMD_MOVEUNIT` 的 `MOVE_1STEP` 方向。
///
/// 原版是硬编码的四个 case，没有具名常量：
///   0 → y--  1 → y++  2 → x--  3 → x++
/// 注意顺序是"先上下后左右"，不是常见的"上下左右"环。
class MoveDirection {
  static const int up = 0;
  static const int down = 1;
  static const int left = 2;
  static const int right = 3;
}

/// `EV_CMD_CAMERACONTROL` 的子命令（只用**低 3 位**）
class CameraSubCommand {
  static const int at = 0; // EVSUBCMD_CAMERA_AT：移动到 (x,y)
  static const int character = 1; // EVSUBCMD_CAMERA_CHAR：移动到某单位
}

/// `EV_CMD_SHOWBG` 的子命令
class ShowBgSubCommand {
  static const int display = 0; // EVSUBCMD_BACG
  static const int transition = 1; // EVSUBCMD_0x2141
  static const int fadeIn = 2; // EVSUBCMD_2142
}
