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
}
