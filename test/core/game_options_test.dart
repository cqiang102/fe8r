// PORT OF: src/uiconfig.c:41-250（`GetGameOption` / `SetGameOption`）、
//          src/data/data_08AAF6DC/data_08AAF6DC.c 前 13 字节（`gGameOptionsUiOrder`）、
//          include/uiconfig.h:4-27（`struct GameOption` / `struct Selector`）
//
// 设定屏的**数据**来自 `tools/pipeline/out/tables/game_options.json`
// （提取器 `tools/pipeline/extract/parse_game_options.py`）。
//
// ★ 这个文件存在的理由：那张表里的 `field` 是**字符串**，而写回配置是按字符串
// 分派的（`PlayConfig.setField`）。字段名打错一个字母，运行时**不会报错** ——
// 只是那一项静默不生效。所以这里把"表里的每个字段名"和"代码认得的字段名"
// 对起来，让这类错误在**测试**里响，而不是在玩的时候没人知道。

import 'dart:convert';
import 'dart:io';

import 'package:fe8r/core/core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Map<String, dynamic> table;

  setUpAll(() {
    final f = File('tools/pipeline/out/tables/game_options.json');
    // ★ 缺文件要**响亮地失败**，不是 skip（否则这条判据会无声消失）
    expect(f.existsSync(), isTrue,
        reason: '产物缺失：先在 tools/pipeline 下跑提取器');
    table = jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
  });

  test('★ 17 个选项 × 4 个 selector（`struct GameOption` = 44 字节）', () {
    final opts = table['options'] as List;
    expect(opts.length, 17, reason: '17 条 × 44 字节 = 748 = 0x2EC（与 carve 区间一致）');
    for (final o in opts) {
      final m = o as Map<String, dynamic>;
      expect(m['msgId'], isA<int>());
      expect((m['selectors'] as List).length, inInclusiveRange(1, 4),
          reason: 'msgId=${m['msgId']}: selector 最多 4 个');
    }
  });

  test('★ `gGameOptionsUiOrder` 的前 13 字节（顺序来自源码，不是我摆的）', () {
    expect(table['uiOrder'], [0, 5, 4, 1, 2, 10, 14, 11, 3, 12, 6, 7, 8]);
    // 没列入的正好是这 4 个（CPU_LEVEL / UNIT_COLOR / CONTROLLER / RANK_DISPLAY）
    final en = (table['optionEnum'] as Map).cast<String, dynamic>();
    final listed = (table['uiOrder'] as List).cast<int>().toSet();
    final notListed = en.values
        .cast<int>()
        .where((v) => !listed.contains(v))
        .toSet();
    expect(notListed.length, 4,
        reason: '没进 UI 的应当正好 4 项：$notListed');
  });

  test('★★ 表里的**每个字段名**代码都必须认得（认不出就是静默不写）', () {
    final map = (table['optionToConfigField'] as Map).cast<String, dynamic>();
    final cfg = PlayConfig();
    var checked = 0;
    for (final e in map.entries) {
      final m = e.value as Map<String, dynamic>;
      final field = m['field'] as String;
      // 1) 必须认得
      expect(cfg.setField(field, 1), isTrue,
          reason: '字段名「$field」（选项 ${e.key} / ${m['enum']}）'
              '在 `PlayConfig.setField` 里认不出 —— 运行时这一项会静默不生效');
      // 2) 必须真的写进去（往返）
      expect(cfg.getField(field), 1,
          reason: '字段名「$field」写了但读不回来');
      cfg.setField(field, 0);
      checked++;
    }
    expect(checked, map.length);
    // 断言真的检查了一批量（防止 map 变空导致这条测试"通过"）
    expect(checked, greaterThanOrEqualTo(13),
        reason: '映射条目数不该少于 13；实际 $checked');
  });

  test('★ 每一个选项都有枚举名与字段名（不许有半条）', () {
    final map = (table['optionToConfigField'] as Map).cast<String, dynamic>();
    for (final e in map.entries) {
      final m = e.value as Map<String, dynamic>;
      expect(m['enum'], isA<String>(), reason: '选项 ${e.key} 缺枚举名');
      expect(m['field'], isA<String>(), reason: '选项 ${e.key} 缺字段名');
    }
  });
}
