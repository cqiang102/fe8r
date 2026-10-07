// 事件列表条目**参数**的判据（LOCA / VILL 的 x/y/cmdId）。
//
// 出处：`struct EvCheck05 { u32 unk0; u32 script; u8 x; u8 y; u16 cmdId; }`
//（`src/eventinfo_080851B8.c:88-94`，`EvCheck05_LOCA` / `EvCheck06_VILL`；
//  `src/StartAvailableTileEvent.c:24-60` 按 `locationBasedEvents` 在 (x,y) 匹配）
//
// ★ 为什么单列一条判据：第 42 轮之前这两个命令**只落了 script**，
// `x`/`y`/`cmdId` 全丢 ⇒ "訪問/村"这种**按坐标匹配**的玩法做不了，
// 而数据看起来"在"。真值来自源码原始字：
//   `src/data/EventListScr_Ch14b_Location_ref/dat_EventListScr_Ch14b_Location_ref.s:9`
//   `.4byte 0x00100E01` ⇒ x=1, y=14, cmdId=0x10 (`TILE_COMMAND_VISIT`)
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late Map<String, dynamic> lists;
  setUpAll(() {
    final f = File('tools/pipeline/out/tables/event_lists.json');
    if (!f.existsSync()) fail('缺少 ${f.path}（先跑 parse_event_lists.py）');
    lists = ((jsonDecode(f.readAsStringSync()) as Map<String, dynamic>)['lists']
            as Map)
        .cast<String, dynamic>();
  });

  test('★ 真值抽查：Ch14b_Location 的第 1 条 VILL = (x 1, y 14, cmdId 0x10)', () {
    final e = (lists['EventListScr_Ch14b_Location'] as List)
        .cast<Map<String, dynamic>>()
        .firstWhere((x) => x['cmd'] == 'VILL');
    expect(e['x'], 1, reason: '低字节是 x（`0x00100E01`）');
    expect(e['y'], 14, reason: '次字节是 y');
    expect(e['cmdId'], 0x10, reason: '高 16 位是 cmdId；0x10 = TILE_COMMAND_VISIT');
    expect('${e['script']}', contains('EventScr_Ch14b_EndingScene'));
  });

  test('LOCA / VILL 条目都带 x/y/cmdId（结构判据）', () {
    var loca = 0, vill = 0;
    for (final v in lists.values) {
      for (final e in (v as List).cast<Map<String, dynamic>>()) {
        final cmd = '${e['cmd']}';
        if (cmd == 'LOCA') loca++;
        if (cmd == 'VILL') vill++;
        if (cmd == 'LOCA' || cmd == 'VILL') {
          expect(e.containsKey('x') && e.containsKey('y') &&
              e.containsKey('cmdId'), isTrue,
              reason: '$cmd 条目缺 x/y/cmdId：$e');
        }
      }
    }
    expect(loca, greaterThan(0), reason: '一张 LOCA 都没有 ⇒ 提取口径不对');
    expect(vill, greaterThan(0), reason: '一张 VILL 都没有 ⇒ 提取口径不对');
  });
}
