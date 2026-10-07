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

  test('★ class→AnimConf：职业块按**花括号配对**切，101 条（每个职业一条）', () {
    // ⚠️ 上一版用非贪婪正则切块，解出 101 条里混着 `AnimConf_100` 这种**不存在的表**；
    // 改成花括号配对后每个职业块恰好切出一条。职业块里嵌着 `.pMovCostTable = { … }`
    // 这类内层花括号 —— 就是它让非贪婪匹配提前收尾的。
    final links = (d['classes'] as Map).cast<String, dynamic>();
    expect(links.length, 101, reason: '有 pBattleAnimDef 的职业数');
    final confs = (d['confs'] as Map).cast<String, dynamic>();
    // 每个职业一张表：引用数 == 职业数（引用集合也在 JSON 里，看 classes 的值）
    expect(links.values.toSet().length, 101);
    // 引用的名字都合法
    for (final v in links.values) {
      expect(RegExp(r'^AnimConf_\d+$').hasMatch('$v'), isTrue, reason: '$v');
    }
    // 有定义 vs 没定义
    final have = links.values.where((v) => confs.containsKey(v)).toSet();
    expect(have.length, 24, reason: 'carve 里定义了 24 张，其中能对上职业的也是 24 张');
  });

  test('★ 阻塞点：序章要动的职业，动画表**没有定义**（这条钉住"做不了"的事实）', () {
    final links = (d['classes'] as Map).cast<String, dynamic>();
    final confs = (d['confs'] as Map).cast<String, dynamic>();
    // Eirika 有表名但没定义；Seth/Franz/Gilliam 连表名都没解析到
    expect(confs.containsKey(links['CLASS_EIRIKA_LORD']), isFalse,
        reason: 'CLASS_EIRIKA_LORD → ${links['CLASS_EIRIKA_LORD']} 若已被 carve，'
            '说明数据补齐了 —— 那就该把动画做起来，而不是继续记"做不了"');
    expect('${d['blocker']}'.contains('CLASS_EIRIKA_LORD'), isTrue);
    expect('${d['blocker']}'.contains('地图战斗动画目前做不了'), isTrue);
  });
}
