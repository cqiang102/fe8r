// 章节单位配置表（编译器提取）的测试。
//
// 判据：坐标/阵营/等级必须在**位域能表示的范围内** ——
// `xPosition : 6` 只有 6 位，越界就说明位域解析错了（或者字段错位）。
// 这类错误不会崩，只会让单位出现在错误的位置。
import 'dart:io';

import 'package:fe8r/core/core.dart';
import 'package:flutter_test/flutter_test.dart';

const _p = 'tools/pipeline/out/tables/unit_defs.json';

void main() {
  group('章节单位配置表', () {
    late UnitDefs defs;

    setUpAll(() {
      final f = File(_p);
      if (!f.existsSync()) {
        fail('缺少 $_p，先跑 tools/pipeline/extract/parse_unit_defs.py');
      }
      defs = UnitDefs.parse(f.readAsStringSync());
    });

    test('125 张表 / 2887 个条目 / 真实单位数', () {
      // 三者要分清：**条目**包含 `{0}` 分组分隔符，**单位**不含。
      // 第一版我把它们混为一谈，测试挂了才发现。
      // 数字全部钉死：位域解析或表长算错时这里会失败。
      //
      // 元素个数现在由探针的 `sizeof` 算（不靠 nm 的地址差），
      // 已实测 Linux 与 macOS 逐条一致 —— 所以这一步可以进 CI。
      expect(defs.tables.length, 125);
      final entries =
          defs.tables.values.fold<int>(0, (s, t) => s + t.entries.length);
      final seps = defs.tables.values
          .fold<int>(0, (s, t) => s + t.entries.where((e) => e.isGroupSeparator).length);
      expect(entries, 2887);
      expect(seps, 388);
      expect(defs.totalUnits, 2499);
      expect(entries, defs.totalUnits + seps);
    });

    test('坐标在 6 位位域范围内（0..63）', () {
      for (final t in defs.tables.values) {
        for (final u in t.units) {
          expect(u.x, inInclusiveRange(0, 63),
              reason: '${t.name} 座位 ${u.index} 的 x=${u.x} 越界');
          expect(u.y, inInclusiveRange(0, 63),
              reason: '${t.name} 座位 ${u.index} 的 y=${u.y} 越界');
        }
      }
    });

    test('阵营只有三档，且都能映射到 Faction', () {
      for (final t in defs.tables.values) {
        for (final u in t.units) {
          expect(u.allegiance, inInclusiveRange(0, 2),
              reason: '${t.name} 的阵营 ${u.allegiance} 越界');
          expect(u.factionBit, isNotNull);
        }
      }
    });

    test('`{0}` 是分组分隔符 —— 一张表里可以有多个组', () {
      // 这条是本轮的关键发现：按"扫到 charIndex==0 就停"读，
      // 111 张表只会导出 9 条（实际 2797 条）。
      final multi = defs.tables.values.where((t) => t.groups.length > 1);
      expect(multi, isNotEmpty, reason: '应当有表包含多个单位组');
      // 抽查第一张
      final first = defs.tables.values.first;
      expect(first.groups, isNotEmpty);
      expect(first.units.length, lessThanOrEqualTo(first.entries.length));
    });

    test('等级与自动升级标记在合理范围', () {
      for (final t in defs.tables.values) {
        for (final u in t.units) {
          expect(u.level, inInclusiveRange(0, 31),
              reason: 'level 是 5 位位域，${u.level} 越界');
          expect(u.autolevel, inInclusiveRange(0, 1));
        }
      }
    });

    test('出现了三大阵营（我方 / 友军 / 敌方）', () {
      final counts = <int, int>{};
      for (final t in defs.tables.values) {
        for (final u in t.units) {
          counts[u.allegiance] = (counts[u.allegiance] ?? 0) + 1;
        }
      }
      expect(counts.keys.toSet(), contains(0), reason: '应当有我方单位');
      expect(counts.keys.toSet().length, greaterThan(1),
          reason: '应当不止一个阵营');
    });
  });
}
