// 职业战斗动画映射（M2）的**数据层**判据。
//
// 出处：`struct BattleAnimDef { u16 wtype; u16 index; }`（`include/ekrbattle.h:324-327`）、
//       表定义在 `src/data/data_banimconf_*.c`、
//       消费方 `GetBattleAnimationId_WithUnique`（`include/anime.h:206`）。
//
// ⚠️ 这里**只**断言 carve 里确实有的东西。77 是 `layout/baseline_syms.d/dataCharClass.tsv`
// 里的总数，carve 只给了 **24** 张（缺的 53 张取不到 —— 不是我少写了几行解析）。
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late Map<String, dynamic> d;
  setUpAll(() {
    final f = File('tools/pipeline/out/tables/banim_conf.json');
    if (!f.existsSync()) fail('缺少 ${f.path}（先跑 parse_banim_conf.py）');
    d = jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
  });

  test('★ carve 出的 AnimConf 表 = 24 张（layout 里是 77）', () {
    expect(d['confsInLayout'], 77, reason: 'layout 里的总数（判据的上界）');
    final confs = d['confs'] as Map<String, dynamic>;
    expect(confs.length, 24,
        reason: 'carve 里就这么多：data_banimconf_24_29 / _36_47 / _61_66');
  });

  test('★ 正向抽查真值：AnimConf_24 的第 1 条', () {
    final confs = d['confs'] as Map<String, dynamic>;
    final e0 = (confs['AnimConf_24'] as List).first as Map<String, dynamic>;
    // `src/data/data_banimconf_24_29.c:6-8`：
    //   .wtype = 0x0100 | ITYPE_BOW,  .index = 0x0026
    // ⚠️ 我第一版按 `ITYPE_BOW = 5` 写 —— **错了**：源码里 `ITYPE_BOW = 0`
    //（`include/constants/items.h`）。凡"枚举值"都去源码核，别照印象。
    expect(e0['wtype'], 0x0100 | 0, reason: 'ITYPE_BOW = 0 ⇒ 0x100 | 0 = 256');
    expect(e0['index'], 0x26);
    expect(e0['wtypeRaw'], '0x0100 | ITYPE_BOW');
  });

  test('每张表的条目都带 wtype 与 index（解不出来要留原始文本）', () {
    final confs = d['confs'] as Map<String, dynamic>;
    for (final e in confs.entries) {
      final list = (e.value as List).cast<Map<String, dynamic>>();
      expect(list, isNotEmpty, reason: '${e.key} 是空的');
      for (final it in list) {
        expect(it.containsKey('wtype'), isTrue);
        expect(it.containsKey('index'), isTrue, reason: '${e.key} 有一条没有 index');
      }
    }
  });

  test('产物里**不含**未经证实的 class→AnimConf 链接', () {
    // 我那一版职业块正则解析出 101 条、还有 `AnimConf_100` 这种不存在的表
    // ⇒ 按纪律不进产物。这条判据防止它被"顺手加回来"。
    expect(d.containsKey('classes'), isFalse,
        reason: 'class→AnimConf 还没解对，不许进产物（见文件头）');
    expect('${d['note2']}'.contains('没解'), isTrue);
  });
}
