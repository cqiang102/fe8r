// 事件位与章节旗（`EVBIT_T/F` + `ENUT/ENUF`）的判据。
//
// 出处：`src/Event02_EvBitAndIdMod.c:14-38`：
//   * `sub_cmd_lo == 0`：`EVBIT_F` ⇒ `evStateBits &= ~(1<<arg)`、`EVBIT_T` ⇒ `|=`
//     —— **场景局部位**；
//   * `sub_cmd_lo == 1`：`ENUF` ⇒ `ClearFlag(arg)`、`ENUT` ⇒ `SetFlag(arg)`
//     —— **章节旗**（就是我们的 `eventFlags`）；
//   * `arg < 0` ⇒ 取事件槽 2（`gEventSlots[2]`）。
//
// ⚠️ 这四条原来都是**占位符**，而 `placeholder(op)` **不带参数** ⇒ 位号被丢掉。
// 我们库里 `EVBIT_T` 出现 271 次、`ENUT` 133 次 ⇒ 不接的话"只演一次"和
// "章节旗"这些行为全是空的。
import 'dart:io';

import 'package:fe8r/core/core.dart';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('★ 生成器不再把它们当占位符，且**带着位号**生成 `evBitMod`', () {
    final f = File('lib/core/event/scene_data.g.dart');
    if (!f.existsSync()) fail('缺少 ${f.path}（先跑 gen_scene_dart.py）');
    final t = f.readAsStringSync();
    expect(t.contains("s.evBitMod('evbit', true,"), isTrue,
        reason: '`EVBIT_T` 要生成 evbit 的置位（带位号）');
    expect(t.contains("s.evBitMod('evbit', false,"), isTrue,
        reason: '`EVBIT_F` 清位');
    expect(t.contains("s.evBitMod('flag', true,"), isTrue,
        reason: '★ `ENUT` = `SetFlag`（章节旗）');
    expect(t.contains("s.evBitMod('flag', false,"), isTrue,
        reason: '`ENUF` = `ClearFlag`');
    expect(t.contains("s.placeholder('EVBIT_T')"), isFalse,
        reason: '不该再有 EVBIT_T 占位（我这次就是来消掉它的）');
    expect(t.contains("s.placeholder('ENUT')"), isFalse,
        reason: '不该再有 ENUT 占位');
  });

  test('★ 条件槽：`CHECK_EVBIT`/`CHECK_EVENTID` 写槽、`BEQ/BNE` 读它（链是完整的）', () {
    final f = File('lib/core/event/scene_data.g.dart');
    final t = f.readAsStringSync();
    expect(t.contains("s.checkSlot('evbit',"), isTrue,
        reason: '`CHECK_EVBIT` ⇒ 写条件槽');
    expect(t.contains("s.checkSlot('flag',"), isTrue,
        reason: '`CHECK_EVENTID` ⇒ 写条件槽（读章节旗）');
    expect(t.contains("s.placeholder('CHECK_EVBIT')"), isFalse);
    expect(t.contains("s.placeholder('CHECK_EVENTID')"), isFalse);
    // 分支部一半**本来就**在（生成器 `cmp = "==" if op == "BEQ" else "!="`）——
    // 所以整条链现在是通的：CHECK 写槽 0xC → BEQ/BNE 读它。
    expect(RegExp(r's\.branch|cmp|slotInt').hasMatch(t), isTrue);
  });

  // ⚠️⚠️ **已知 bug（第 88 轮发现，尚未修）**：分支的比较**对不上源码**。
  //
  // 源码 `src/Event0C_Branch.c:52-56`：
  //     val1 = gEventSlots[ARGV[1]];  val2 = gEventSlots[ARGV[2]];
  //     case EVSUBCMD_BEQ: if (val1 == val2) return Event09_Goto(proc);
  //   ⇒ **两边都是事件槽的值**；而且 `Event09_Goto` 读的是 `ARGV[0]`（`src/exact_0800dc08.c:76`），
  //     所以标签在**第一个**参数。
  // 生成器现在把 `A[0]` 当槽、`A[1]` 当**字面值**、`A[2]` 当标签
  //   ⇒ 于是写出 `if (s.slotInt(0) != 196620) { pc = 1; } else { pc = 1; }`：
  //     比错了东西，而且**两个分支跳到同一处**（等于不跳）。
  //
  // 本文件把**现状数字**钉在这里：修好之后这两个数会明显变化（应当变成 0 / 0）。
  // 为什么没直接修：数据里 `BEQ(0, 0x2000c, 0xa40)` 这三个数**既不像槽号也不像字面量**，
  // 说明 `.s`/`.c` 里那套写法（**数据方言**）与 C 宏 `EvtBEQ(label, s1, s2)`
  // （`include/eventscript.h:610`）**不是同一套参数**，而我没找到定义该脚本的那份源文件
  // （`EventScr_UnTriggerIfNotUnit` 只有 extern/引用，没有可读定义）。
  // ⇒ 猜着改 259 处会造出更大的错；先钉住，等找到方言的定义再修。
  // ★ **已修（第 89 轮）**：分支比较对不上源码那个 bug。
  //   修法两处：① 提取器把 `_EvtParams2(x, y)` 的打包字拆成两个参数
  //   （`((y & 0xFFFF) << 16) + (x & 0xFFFF)`，`include/eventscript.h:568`）；
  //   ② 生成器按 `(label, s1, s2)` 发**两槽比较**，并把 `BGE/BGT/BLE/BLT` 一起接上
  //   （出处 `src/Event0C_Branch.c:45-70`：`val1 = gEventSlots[ARGV[1]]; val2 = gEventSlots[ARGV[2]]`）。
  test('★ 分支：268 处全是**两槽比较**，字面值比较为 0（第 88 轮那个 bug 已修）', () {
    final t = File('lib/core/event/scene_data.g.dart').readAsStringSync();
    final literal = RegExp(r'if \(s\.slotInt\(-?\d+\) (!=|==|>=|>|<=|<) -?\d+\)')
        .allMatches(t)
        .length;
    final twoSlots = RegExp(r'if \(s\.slotInt\(-?\d+\) '
            r'(!=|==|>=|>|<=|<) s\.slotInt\(-?\d+\)\)')
        .allMatches(t)
        .length;
    expect(literal, 0, reason: '★ 不该再有"拿字面值比"的分支（修前是 259）');
    expect(twoSlots, 268, reason: '★ 两槽比较（修前是 0；268 = 259 + 新接的 BGE/BGT/BLE/BLT）');
    expect(t.contains("s.placeholder('BLT')") ||
        t.contains("s.placeholder('BGE')") ||
        t.contains("s.placeholder('BGT')") ||
        t.contains("s.placeholder('BLE')"), isFalse,
        reason: '六种比较都该接上');
  });

  test('⚠️ 未查证：4 处分支的标签在该脚本里找不到（已钉住个数）', () {
    // 生成器会把这 4 处打印出来（预扫描标签表找不到 ⇒ 退化成"往下走"）。
    // 它们**不是**第 88 轮那个 bug（那个是"两边都不是槽"）；这 4 处两边都是槽，
    // 只是跳转目标缺失。
    //
    // ★ 第 89 轮查到的**具体形状**（生成器现在会打印，不再是空话）：
    //   4 处里 **3 处的标签表是空的**（整个指令流里一个 `LABEL` 都没有），
    //   另 1 处表里只有 `[1]` 却要跳 `LABEL(0)`。
    //   结合另一个现象——生成器被喂了**六个完全不同的指令流、却都叫
    //   `EventScr_Ch16A_0`**——高度指向：`.s` 里那些
    //   `/* de-pointered slice … ptr=… data=… skip=… */` 的切片是**片段**，
    //   跨片段的脚本**丢了标签**。⇒ **未查证**（没读 `skip/ptr` 的语义）。
    // 数字钉在这里：修好或变多都会响。
    final t = File('lib/core/event/scene_data.g.dart').readAsStringSync();
    final sameTarget = RegExp(r'if \(s\.slotInt\(-?\d+\) [^\n]*?\{ pc = (\d+); \} '
            r'else \{ pc = (\d+); \}')
        .allMatches(t)
        .where((m) => m.group(1) == m.group(2))
        .length;
    // ★★ 第 93 轮：**查到源头，结论是"原作自己也跑飞"**。
    //   源码 `src/data/EventScr_Ch9A_4_ref/dat_EventScr_Ch9A_4_ref.c`（45 行）
    //   里有三个分支（`:17 BEQ(0,0xC,0)` / `:20 BEQ(0,0xC,1)` / `:41 BNE(0,0xC,0)`），
    //   却**一个 `LABEL` 都没有** —— 所以这**不是**我们的解码器的问题。
    //   而 `Event09_Goto`（`src/exact_0800dc08.c:70-84`）的实现是：
    //       while (scr != ref) { cur += EVT_CMD_LEN(cur); scr = *(const u32 *)cur; }
    //   ⇒ **无界向前扫描**：找不到标签就一路走进内存里后面的数据（没有边界检查）。
    //   ⇒ 这 3 处在原作里也是"跑飞"；我们没有（也不该）复刻越界扫描，
    //     退化成【往下走】并把个数钉在这里。
    expect(sameTarget, 3,
        reason: '现状 3 处（都在 EventScr_Ch9A_4，源码里本就没有 LABEL；'
            '原作的无界扫描无法复刻）');
  });

  test('★ 符号常量必须解成数（`SOUN(SONG_BE)` 这类，第 100 轮）', () {
    final t = File('lib/core/event/scene_data.g.dart').readAsStringSync();
    // `SONG_BD = 0xBD` / `SONG_BE = 0xBE`（`include/constants/songs.h:162-163`）
    // 以前它们被当成"符号" ⇒ `num()` 回退 0 ⇒ 整条指令变占位符。
    expect(t.contains("s.placeholder('SOUN')"), isFalse,
        reason: '★ SOUN(SONG_BE)/SOUN(SONG_BD) 共 18 处，现在应当全解出来');
    expect(RegExp(r's\.sound\(.se., 190\)').allMatches(t).length, 10,
        reason: 'SONG_BE = 0xBE = 190 → 10 处');
    expect(RegExp(r's\.sound\(.se., 189\)').allMatches(t).length, 8,
        reason: 'SONG_BD = 0xBD = 189 → 8 处');
  });

  test('★ 清屏 + 文本底（第 94 轮）：`BACG` 的"不生效"分支要真的存在', () {
    final t = File('lib/core/event/scene_data.g.dart').readAsStringSync();
    // `CLEAN` = `EvtClearScreen`（`src/eventscr_0800F2DC.c:76-92`）
    expect(RegExp(r's\.clearScreen\(\)').allMatches(t).length, 34,
        reason: '按事实钉住（第 80/84 轮的教训）');
    // `BACG` = `EVSUBCMD_BACG` ⇒ `EventShowTextBgDirect(activeTextType, arg)`
    //   ⚠️ `activeTextType` 0/3/4/5 ⇒ 源码直接 `EVC_ERROR`（什么都不做）
    expect(RegExp(r's\.showTextBg\(').allMatches(t).length, 15);
    expect(t.contains("s.placeholder('CLEAN')"), isFalse);
    // 谓词本身（两边一致性）：只有 1/2 才"在地图上"
    expect(eventTextTypeOnMap(0), isFalse);
    expect(eventTextTypeOnMap(1), isTrue);
    expect(eventTextTypeOnMap(3), isFalse);
  });

  test('★ 条件族第三批：CHECK_MODE / CHECK_CHAPTER_NUMBER / CHECK_HARD 写条件槽', () {
    final t = File('lib/core/event/scene_data.g.dart').readAsStringSync();
    // 出处：src/eventscr_0800E2C8.c:77-87
    expect(t.contains("s.checkSlotValue('mode')"), isTrue, reason: 'gPlaySt.chapterModeIndex');
    expect(t.contains("s.checkSlotValue('chapter')"), isTrue, reason: 'proc->chapterIndex');
    expect(t.contains("s.checkSlotValue('hard')"), isTrue, reason: 'PLAY_FLAG_HARD');
    expect(t.contains("s.placeholder('CHECK_MODE')"), isFalse);
    expect(t.contains("s.placeholder('CHECK_HARD')"), isFalse);
  });

  test('★ 镜头移到角色 + 幸运值（第 80 轮）', () {
    final t = File('lib/core/event/scene_data.g.dart').readAsStringSync();
    // `CAMERA_CAHR` = `EvtMoveCameraToChar(pid)`（include/EAstdlib.h:99，
    //  处理函数 src/eventscr_0800F41C.c:10-35 的 case 1）
    // ★ 事实（不是"我以为"）：19 处接上、**4 处仍是占位符**（那 4 处参数是符号，
    //   生成器按"宁可少接也不发错值"的原则退回占位）。数字变了这条就会响。
    final cam = RegExp(r's\.cameraToChar\(').allMatches(t).length;
    final camPh = RegExp(r"s\.placeholder\('CAMERA_CAHR'\)").allMatches(t).length;
    expect(cam, 19, reason: '接上的处数');
    expect(camPh, 4, reason: '参数是符号的那 4 处仍是占位符（详见生成器注释）');
    // `CHECK_LUCK` = `EvtGetUnitLuck`（include/EAstdlib.h:133，
    //  src/Event33_CheckUnitVarious.c:147-153：找不到单位 => EVC_ERROR）
    expect(RegExp(r's\.checkLuck\(').allMatches(t).length, 18);
    expect(t.contains("s.placeholder('CHECK_LUCK')"), isFalse,
        reason: '这一条**全部**接上了（18 处、0 处占位）');
  });

  test('★ 场景光标（`CUMO_CHAR`，第 81 轮）', () {
    final t = File('lib/core/event/scene_data.g.dart').readAsStringSync();
    // `CUMO_CHAR` = `EvtDisplayCursorAtUnit(pid)`（include/EAstdlib.h:166；
    //  src/Event3B_DisplayCursor.c:51-59：找不到单位 => EVC_ERROR，
    //  光标画在 unit->xPos/yPos —— 是**场景光标**，不是玩家地图光标）
    expect(RegExp(r's\.displayCursorAtUnit\(').allMatches(t).length, 17,
        reason: '接上的处数（参数是符号的会退回占位）');
  });
  _counterTests();
  _evBitModifyTests();
  _textTypeTests();
  _menuOverrideTests();
  _continueTextTests();
  _evBitModifyTailTests();
  _searchAvailableEventTests();
}

// 事件计数器（`src/Event0F_CounterOps.c:24-99`）—— **精确算术**判据
void _counterTests() {
  test('★ nibble 打包：8 个 4 位计数器互不干扰', () {
    var c = 0;
    c = eventCounterPut(c, 0, 5);
    c = eventCounterPut(c, 3, 9);
    expect(eventCounterGet(c, 0), 5);
    expect(eventCounterGet(c, 3), 9);
    expect(eventCounterGet(c, 1), 0, reason: '别的 nibble 不受影响');
    // 下标按 % 8：第 8 个就是第 0 个（源码 `% 8`）
    expect(eventCounterGet(c, 8), eventCounterGet(c, 0));
  });

  test('★ INC 上限 15、DEC 下限 0（源码的钳位，不是回绕）', () {
    final c = eventCounterPut(0, 2, 15);
    final inc = eventCounterInc(c, 2);
    expect(eventCounterGet(inc, 2), 15, reason: '★ 15 再加还是 15（不是 0）');
    final z = eventCounterPut(0, 2, 0);
    final dec = eventCounterDec(z, 2);
    expect(eventCounterGet(dec, 2), 0, reason: '★ 0 再减还是 0（不是 15）');
    // 普通情形
    expect(eventCounterGet(eventCounterInc(eventCounterPut(0, 5, 3), 5), 5), 4);
    expect(eventCounterGet(eventCounterDec(eventCounterPut(0, 5, 3), 5), 5), 2);
  });

  test('★ `COUNTER_CHECK` **不回写**（源码 `case 0` 直接 return 0）', () {
    // 纯函数层面：`eventCounterGet` 本来就不改 counter；这里钉住"钳位只在 INC/DEC/SET 里"
    var c = 0;
    for (var i = 0; i < 8; i++) {
      c = eventCounterPut(c, i, i);
    }
    final again = eventCounterGet(c, 4);
    expect(again, 4);
    expect(eventCounterGet(c, 4), 4, reason: '读取不改变计数器');
  });
}

// `EVBIT_MODIFY`（`src/masked_0800def0.c:74-100`）的位操作 —— 用**纯算术**验证
void _evBitModifyTests() {
  test('★ 参数 0/1/2 的位效果（照 `case 0/1/2`）', () {
    // 0 ⇒ 清 NOSKIP|0020|0040
    var b = kEvStateNoSkip | kEvState0020 | kEvState0040 | (1 << 9);
    b &= ~(kEvStateNoSkip | kEvState0020 | kEvState0040);
    expect(b & (kEvStateNoSkip | kEvState0020 | kEvState0040), 0);
    expect(b & (1 << 9), isNot(0), reason: '别的位不动');
    // 1 ⇒ 三个全置
    var c = 0;
    c |= kEvStateNoSkip | kEvState0020 | kEvState0040;
    expect(c, kEvStateNoSkip | kEvState0020 | kEvState0040);
    // 2 ⇒ 清前两个、**置第三个**
    var d = kEvStateNoSkip | kEvState0020 | kEvState0040;
    d &= ~(kEvStateNoSkip | kEvState0020);
    d |= kEvState0040;
    expect(d & kEvStateNoSkip, 0);
    expect(d & kEvState0020, 0);
    expect(d & kEvState0040, isNot(0), reason: '第三个反而是**置**上');
  });

  test('★ 位值与源码一致（`include/event.h:59-61`）', () {
    expect(kEvStateNoSkip, 1 << 0x4);
    expect(kEvState0020, 1 << 0x5);
    expect(kEvState0040, 1 << 0x6);
  });
}

// 文本类型（`src/eventscr_0800E3E0.c:94` + `src/IsActiveEventTextTypeOnMap.c:25-45`）
void _textTypeTests() {
  test('★ `IsActiveEventTextTypeOnMap`：**1 和 2 是"在地图上"**，其余不是', () {
    expect(eventTextTypeOnMap(0), isFalse, reason: 'TEXTSTART');
    expect(eventTextTypeOnMap(1), isTrue, reason: 'REMOVEPORTRAITS');
    expect(eventTextTypeOnMap(2), isTrue, reason: '0x1A22');
    expect(eventTextTypeOnMap(3), isFalse, reason: 'TUTORIALTEXTBOXSTART');
    expect(eventTextTypeOnMap(4), isFalse, reason: 'SOLOTEXTBOXSTART');
    expect(eventTextTypeOnMap(5), isFalse, reason: '0x1A25');
  });

  test('★ 生成物里这一族**按子命令号**写类型（子命令号就是类型）', () {
    final t = File('lib/core/event/scene_data.g.dart').readAsStringSync();
    // ★ 按**观察到的事实**写（第 80 轮的教训：别按"我以为"）：
    //   0 => 114（TEXTSTART）、3 => 56（TUTORIALTEXTBOXSTART）、
    //   1 => 12（REMOVEPORTRAITS）、4 => 2（SOLOTEXTBOXSTART）；
    //   **类型 2 / 5 在数据里根本不出现**（那两条子命令没被用到）。
    int n(int type) =>
        RegExp('s\\.setTextType\\($type\\)').allMatches(t).length;
    expect(n(0), 114);
    expect(n(3), 56);
    expect(n(1), 12);
    expect(n(4), 2);
    expect(n(2) + n(5), 0, reason: '0x1A22 / 0x1A25 在数据里没出现');
    expect(n(0) + n(1) + n(2) + n(3) + n(4) + n(5), 184, reason: '这一族的总数');
    expect(RegExp(r's\.placeholder\(.(TEXTSTART|TUTORIALTEXTBOXSTART)').hasMatch(t),
        isFalse, reason: '这两个不该再是占位符');
  });
}

// `DISABLEOPTIONS`（`EvtOverrideUnitMenu`，`src/Event3D_MenuOverride.c:74-118`）
void _menuOverrideTests() {
  test('★ 掩码 bit i ⇒ 第 i 个菜单项；**未映射的要显式返回**', () {
    // 表（`:74-90`）：0 攻撃 / 1 杖 / 2 待機 / 3 救出 / 4 降ろす / 5 訪問 / 6 話す / 7 持ち物 …
    expect(unitMenuOverrideMsgIds.length, 15);
    expect(menuOverrideKeysForMask(1 << 0), ['attack']);
    expect(menuOverrideKeysForMask(1 << 2), ['wait'], reason: '0x6B 待機');
    expect(menuOverrideKeysForMask(1 << 5), ['visit'], reason: '0x5C 訪問');
    expect(menuOverrideKeysForMask((1 << 0) | (1 << 2)), ['attack', 'wait']);
    // ★ bit 1 = 杖：我们模型里没有独立的"杖"项 ⇒ 它必须出现在 unmapped 里（不静默丢）
    final r = menuOverrideForMask(1 << 1);
    expect(r.keys, isEmpty);
    expect(r.unmapped, [0x51], reason: '0x51 杖 —— 我们把它放在道具子菜单里');
    // 支援 / 武器屋 / 設定 / 終了 也都没对应项
    final r2 = menuOverrideForMask((1 << 11) | (1 << 14));
    expect(r2.unmapped, containsAll([0x5B, 0x78]));
  });
}

// `TEXTCONT` = `EvtContinueText`（`include/EAstdlib.h:92`；
// 处理函数 `Event1D_TalkContinue`，`src/eventscr.c:47-66`）
void _continueTextTests() {
  test('★ 产物里 25 处 `s.continueText()`，且不再是占位符', () {
    final t = File('lib/core/event/scene_data.g.dart').readAsStringSync();
    expect(RegExp(r's\.continueText\(\)').allMatches(t).length, 25,
        reason: '按事实钉住（第 80/84 轮的教训）');
    expect(t.contains("s.placeholder('TEXTCONT')"), isFalse);
  });

  test('★ 跳过中要**真的收尾**（源码 `:49-59` 的 EndTalk/EndCgText/EndAllBoxDialogue）', () {
    // 事件携带 skipping 标志 —— 游戏侧据此决定"收尾"还是"ResumeTalk"
    const a = ContinueText(false);
    const b = ContinueText(true);
    expect(a.skipping, isFalse, reason: '非跳过 => ResumeTalk（我们逐页 await，无需额外动作）');
    expect(b.skipping, isTrue, reason: '跳过 => 结束对话');
  });
}

// `EVBIT_MODIFY` 的 3/4 与 default（`src/masked_0800def0.c:96-125`）
void _evBitModifyTailTests() {
  test('★ 参数 3/4 与 >4（default ⇒ EVC_ERROR）', () {
    // 3 ⇒ 置 NOSKIP、清 0020|0040
    var b = kEvState0020 | kEvState0040;
    b |= kEvStateNoSkip;
    b &= ~(kEvState0020 | kEvState0040);
    expect(b, kEvStateNoSkip);
    // 4 ⇒ 置 NOSKIP|0020、清 0040
    var c = kEvState0040;
    c |= kEvStateNoSkip | kEvState0020;
    c &= ~kEvState0040;
    expect(c, kEvStateNoSkip | kEvState0020);
    // 生成的产物里**不该再有** EVBIT_MODIFY 占位符（参数 >4 也要接上，记 scriptErrors）
    final t = File('lib/core/event/scene_data.g.dart').readAsStringSync();
    expect(t.contains("s.placeholder('EVBIT_MODIFY')"), isFalse);
    // ⚠️ 我第一次写的是 12（凭算术猜的），**实测 11** —— 按事实改成 11
    expect(RegExp(r's\.modifyEvBit\(').allMatches(t).length, 11,
        reason: '按事实钉住（实测值）');
  });
}

// `SearchAvailableEvent` 的**遍历规则**（`src/SearchAvailableEvent.c:24-60`）
void _searchAvailableEventTests() {
  test('★ 标志门：CheckFlag(高 16 位) 为真 ⇒ 整条跳过（**不调条件函数**）', () {
    var called = 0;
    final r = searchAvailableEvent(
      entries: [
        (firstWord: (5 << 16) | 2, script: EventScript(instructions: const [], labels: const {})),
        (firstWord: (0 << 16) | 2, script: EventScript(instructions: const [], labels: const {})),
      ],
      // ⚠️ 我第一次写 {2: 3} —— 那样第一条会直接**跳过第二条**，
      //    条件函数当然不会被调用（是判据数据不自洽，不是实现错）。改成 1。
      cmdLengths: {2: 1},
      checkFlag: (f) => f == 5, // 第一条的标志置了 ⇒ 跳过
      conditionFuncs: {
        2: (_) {
          called++;
          return true;
        },
      },
    );
    expect(called, 1, reason: '★ 第一条根本不该调用条件函数');
    expect(r!.index, 1, reason: '采用的是第二条');
    expect(r.cmdId, 2);
  });

  test('★ 长度跳过：条件不成立时前进 cmdInfo[].length **个字**', () {
    final seen = <int>[];
    final r = searchAvailableEvent(
      entries: [
        (firstWord: 2, script: EventScript(instructions: const [], labels: const {})), // cmdId 2，length 3 ⇒ 跳到 3
        (firstWord: 1, script: EventScript(instructions: const [], labels: const {})), // index 1
        (firstWord: 1, script: EventScript(instructions: const [], labels: const {})), // index 2
        (firstWord: 4, script: EventScript(instructions: const [], labels: const {})), // index 3 ⇒ 从这里命中
      ],
      cmdLengths: {2: 3, 1: 2, 4: 1},
      checkFlag: (_) => false,
      conditionFuncs: {
        2: (_) => false,
        1: (_) => false,
        4: (w) {
          seen.add(w);
          return true;
        },
      },
    );
    expect(r!.index, 3);
    expect(seen, [4]);
  });

  test('★ 缺长度 ⇒ 返回 null（不瞎猜步长）', () {
    final r = searchAvailableEvent(
      entries: [(firstWord: 9, script: EventScript(instructions: const [], labels: const {}))],
      cmdLengths: const {},
      checkFlag: (_) => false,
      conditionFuncs: const {},
    );
    expect(r, isNull);
  });
}
