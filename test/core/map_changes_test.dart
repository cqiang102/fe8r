// PORT OF: include/types.h:395-402（`struct MapChange`：id / xOrigin / yOrigin /
//          xSize / ySize / data；**id == -1 是结束哨兵**）
//          数据：src/data/map/data_map_change.c（typed C，65 张表）
//          运行时：src/bmtrick.c 的 `GetMapChange` / `ApplyMapChangesById`
//                  （`include/bmtrick.h:75-77`）
//
// ★ 这是 `TILECHANGE`（33 处）/ `TILEREVERT`（14 处）要用的数据。
//   ⚠️ 边界：本文件只证明**数据被正确解出来**；「把它贴到地图上」那一步还没接。

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late Map<String, dynamic> t;

  setUpAll(() {
    final f = File('tools/pipeline/out/tables/map_changes.json');
    expect(f.existsSync(), isTrue,
        reason: '产物缺失：在 tools/pipeline 下跑 extract/parse_map_changes.py');
    t = jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
  });

  test('★ 65 张表；表数与"格数组数"自洽', () {
    expect(t['tableCount'], 65);
    // 325 条记录 = 260 条真记录 + 65 个结束哨兵；格数组也正好 260 个
    expect(t['recordCount'], 325);
    expect(t['tileArrayCount'], 260);
    expect((t['recordCount'] as int) - (t['tableCount'] as int),
        t['tileArrayCount'] as int);
  });

  test('★ 正向抽查真值（对着 data_map_change.c 的头几行核过）', () {
    final tables = (t['tables'] as Map).cast<String, dynamic>();
    final ch2 = (tables['Ch2TileChanges'] as List).cast<Map<String, dynamic>>();
    expect(ch2[0]['id'], 0);
    expect(ch2[0]['x'], 3);
    expect(ch2[0]['y'], 0);
    expect(ch2[0]['w'], 3);
    expect(ch2[0]['h'], 3);
    expect(ch2[0]['tiles'],
        [0x0E1C, 0x0E20, 0x0E24, 0x0E9C, 0x0EA0, 0x0EA4, 0x0F1C, 0x0F20, 0x0F24],
        reason: '9 个格，逐字来自源码');
  });

  test('★ 每张表都以 `id == -1` 的哨兵结束（`struct MapChange` 的约定）', () {
    final tables = (t['tables'] as Map).cast<String, dynamic>();
    for (final e in tables.entries) {
      final recs = (e.value as List).cast<Map<String, dynamic>>();
      expect(recs.last['id'], -1, reason: '${e.key} 的最后一条应当是哨兵');
      expect(recs.last['dataSymbol'], isNull, reason: '哨兵的 data 是 NULL');
    }
    final pro = tables['PrologueMapChanges'] as List;
    expect(pro.length, 1, reason: '序章只有哨兵');
  });

  test('⚠️ 未覆盖的 `.s` 切片要**具名**列出（不静默少覆盖）', () {
    final un = (t['uncovered'] as List).cast<String>();
    expect(un.length, 24);
    expect(un.first, 'Ch10EphraimMapChanges_ref');
    // 这些文件里的表**没被解析** ⇒ 用它们的地图会缺数据
  });
}
