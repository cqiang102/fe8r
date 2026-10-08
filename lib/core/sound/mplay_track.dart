// PORT OF: src/m4a_1.s:1013-1055（`MPlayMain` 的音轨步进：初始化 + 取指令）
//          + include/gba/m4a_internal.h（`MusicPlayerTrack` 的字段名）
//
// ⚠️ `MusicPlayerTrack` 的**结构体布局还没移植**（第 14 轮只移植了
//    `MusicPlayerInfo`）⇒ 本文件用**具名字段**表达，不去碰偏移。
//    等音序器要按字节读内存时再补，并配偏移判据。
//
// 逐行对照的汇编（`src/m4a_1.s:1013-1043`）：
//
// ```asm
// _081DD8BA:
//   ldrb r3, [r5, o_MusicPlayerTrack_flags]
//   movs r0, 0x40
//   tst  r0, r3
//   beq  _081DD938                     ; ★ bit6 没置 ⇒ 跳过初始化，直接取指令
//   adds r0, r5, 0
//   bl Clear64byte                     ; ★ 清 64 字节（整条 track）
//   movs r0, 0x80
//   strb r0, [r5]                      ; flags = 0x80（在跑）
//   movs r0, 0x2
//   strb r0, [r5, o_MusicPlayerTrack_bendRange]   ; BENDRANGE = 2
//   movs r0, 0x40
//   strb r0, [r5, o_MusicPlayerTrack_volX]        ; VOLX = 64
//   movs r0, 0x16
//   strb r0, [r5, o_MusicPlayerTrack_lfoSpeed]    ; LFOSPEED = 22
//   movs r0, 0x1
//   strb r0, [ToneData_type]                      ; tone.type = 1
// _081DD8E0:
//   ldr r2, [r5, o_MusicPlayerTrack_cmdPtr]
//   ldrb r1, [r2]
//   cmp r1, 0x80
//   bhs _081DD8EC
//   ldrb r1, [r5, o_MusicPlayerTrack_runningStatus]  ; ★ <0x80 ⇒ 用 running status
//   b _081DD8F6
// _081DD8EC:
//   adds r2, 0x1
//   str r2, [cmdPtr]
//   cmp r1, 0xBD
//   bcc _081DD8F6
//   strb r1, [runningStatus]          ; ★ ≥0xBD ⇒ 记进 running status
// ```

/// 一条 M4A 音轨的**已移植部分**（初始化 + 取指令）。
class MPlayTrackPort {
  MPlayTrackPort({this.flags = 0, this.bendRange = 0, this.volX = 0,
      this.lfoSpeed = 0, this.toneType = 0, this.runningStatus = 0});

  /// `MusicPlayerTrack.flags`（bit7 = 在跑；**bit6 = 需要初始化**）
  int flags;

  /// `bendRange`（初始化置 2）
  int bendRange;

  /// `volX`（初始化置 0x40 = 64）
  int volX;

  /// `lfoSpeed`（初始化置 0x16 = 22）
  int lfoSpeed;

  /// `ToneData.type`（初始化置 1）
  int toneType;

  /// `runningStatus`：上一条**带参**命令（`≥ 0xBD` 的那些）
  int runningStatus;

  /// 指令流已消费到的下标（对应 `cmdPtr`）
  int cmdIndex = 0;

  /// 初始化时用的常量（**逐条来自汇编**，判据钉住）
  static const int initFlags = 0x80;
  static const int initBendRange = 0x2;
  static const int initVolX = 0x40;
  static const int initLfoSpeed = 0x16;
  static const int initToneType = 0x1;

  /// `flags` 的位（`src/m4a_1.s:1015-1017` 的 `tst 0x40` / `tst 0x80`）
  static const int flagRunning = 0x80;
  static const int flagNeedsInit = 0x40;

  /// `src/m4a_1.s:1040` 的 `cmp r1, 0xBD`：**≥ 此值**的命令才写 running status
  static const int runningStatusThreshold = 0xBD;

  /// 需要初始化时清空整条 track（原版 `Clear64byte` **清 64 字节**）
  static const int clearBytes = 64;

  /// `MusicPlayerTrack.wait`：还要等几个 tick 才读下一条指令
  /// （`o_MusicPlayerTrack_wait`，`src/m4a_1.s:1085-1090`）
  int wait = 0;

  /// 指令流（对应原版的 `cmdPtr` 指向的那段内存）
  ///
  /// ⚠️ 第一版我把字节流当**参数**传进来、游标却留在对象里 —— 第二次调用就错位
  /// （判据当场抓到）。原版持有的是 **`cmdPtr` 指针**，所以字节流应当属于对象。
  List<int> bytes = const [];

  /// 载入指令流（对应把 `cmdPtr` 指向 song 数据）
  void load(List<int> code) {
    bytes = code;
    cmdIndex = 0;
  }

  /// ★ 一个 tick 里的"取指令"步骤：
  /// 1. `flags & 0x40` ⇒ **初始化**（清 64 B + 写 5 个初值，并置 `flags = 0x80`）；
  /// 2. 取一个字节：`≥ 0x80` ⇒ 它是命令（消费掉；`≥ 0xBD` 记进 running status）；
  ///    `< 0x80` ⇒ 它是**参数**，命令取 `runningStatus`（**不消费**这个字节）。
  ///
  /// 返回本次得到的命令号；字节用完时返回 null。
  int? fetchCommand() {
    if ((flags & flagNeedsInit) != 0) {
      init();
    }
    if (cmdIndex >= bytes.length) return null;
    final b = bytes[cmdIndex];
    if (b >= 0x80) {
      cmdIndex++; // ★ 命令字节被消费
      if (b >= runningStatusThreshold) runningStatus = b;
      return b;
    }
    // ★ 参数字节：命令来自 running status（**这一字节留给调用方当参数**）
    return runningStatus;
  }

  /// 原版初始化那 6 步（`Clear64byte` + 5 个初值）
  void init() {
    // Clear64byte：整条 track 清零（除本对象已建模的字段，其余字段未移植）
    flags = 0;
    bendRange = 0;
    volX = 0;
    lfoSpeed = 0;
    toneType = 0;
    runningStatus = 0;
    flags = initFlags;
    bendRange = initBendRange;
    volX = initVolX;
    lfoSpeed = initLfoSpeed;
    toneType = initToneType;
  }
}
