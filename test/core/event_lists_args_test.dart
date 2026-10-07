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

  test('★ 地形玩法地块：制圧 5 处（含 Ch1 的 (2,2)）都在数据里', () {
    // `TILE_COMMAND_SEIZE = 0x11`（`include/eventinfo.h:15`）；
    // 可用性 `UnitActionMenu_CanSeize`（`src/bmmenu_08022F50.c:68-80`）=
    // `!US_HAS_MOVED` + `CanUnitSeize` + 该格 `cmdId == 0x11`。
    final seize = <String>[];
    for (final e in lists.entries) {
      for (final it in (e.value as List).cast<Map<String, dynamic>>()) {
        if (it['cmdId'] == 0x11) seize.add('${e.key}:${it['x']},${it['y']}');
      }
    }
    expect(seize.length, 5, reason: '制圧地块数（提取口径变了就会在这里响）');
    expect(seize.any((s) => s.startsWith('EventListScr_Ch1_Location:2,2')), isTrue,
        reason: '第 1 章的制圧点是 (2,2)（BOSS 站的那格）');
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
