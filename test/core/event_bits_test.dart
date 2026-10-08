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
