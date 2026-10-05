// 阶段与阵营判定与 C Oracle 逐值一致。
import 'dart:io';

import 'package:fe8r/core/core.dart';
import 'package:flutter_test/flutter_test.dart';

const String _vecDir = 'tools/oracle/vectors';

Map<String, Map<String, String>> _readCases(String path) {
  final out = <String, Map<String, String>>{};
  for (final line in File(path).readAsLinesSync()) {
    if (line.startsWith('#') || line.trim().isEmpty) continue;
    final parts = line.split('\t');
    final f = <String, String>{};
    for (final p in parts.skip(1)) {
      final eq = p.indexOf('=');
      if (eq > 0) f[p.substring(0, eq)] = p.substring(eq + 1);
    }
    out[parts.first] = f;
  }
  return out;
}

Map<String, String> _readExpected(String path) {
  final out = <String, String>{};
  for (final line in File(path).readAsLinesSync()) {
    if (line.startsWith('#') || line.trim().isEmpty) continue;
    final p = line.split('\t');
    if (p.length >= 2) out[p.first] = p[1];
  }
  return out;
}

int _v(Map<String, String> c, String k, [int dflt = 0]) =>
    c.containsKey(k) ? int.parse(c[k]!) : dflt;

/// 解析 `<id>=<state>:<status>:<classAttr>:<valid>` 列表
List<PhaseUnit?> _parseUnits(String spec) {
  final units = List<PhaseUnit?>.filled(0x100, null);
  if (spec.isEmpty) return units;
  final parts = spec.split(',');
  for (final p in parts) {
    final eq = p.indexOf('=');
    if (eq <= 0) continue;
    final id = int.parse(p.substring(0, eq));
    final f = p.substring(eq + 1).split(':');
    if (f.length < 4) continue;
    units[id] = PhaseUnit(
      faction: id,
      state: int.parse(f[0]),
      statusIndex: int.parse(f[1]),
      classAttributes: int.parse(f[2]),
      hasCharacterData: f[3] != '0',
    );
  }
  return units;
}

void main() {
  group('阶段与阵营与 C Oracle 逐值一致', () {
    late Map<String, Map<String, String>> cases;
    late Map<String, String> expected;

    setUpAll(() {
      final f = File('$_vecDir/phase.cases.tsv');
      if (!f.existsSync()) fail('找不到 ${f.path}');
      cases = _readCases(f.path);
      expected = _readExpected('$_vecDir/phase.expected.tsv');
    });

    test('全部 103 条用例', () {
      final failures = <String>[];
      for (final id in cases.keys.toList()..sort()) {
        final c = cases[id]!;
        final want = expected[id];
        if (want == null) {
          failures.add('$id: 缺少期望值');
          continue;
        }

        final fn = c['fn'] ?? 'abled';
        final int got;
        switch (fn) {
          case 'allied':
            got = PhaseRules.areUnitsAllied(_v(c, 'left'), _v(c, 'right')) ? 1 : 0;
          case 'allegiance':
            got =
                PhaseRules.isSameAllegiance(_v(c, 'left'), _v(c, 'right')) ? 1 : 0;
          case 'current':
            got = PhaseRules.getCurrentPhase(_v(c, 'faction'));
          case 'nonactive':
            got = PhaseRules.getNonActiveFaction(_v(c, 'faction'));
          case 'instate':
            got = PhaseRules.countUnitsInState(
              _parseUnits(c['units'] ?? ''),
              _v(c, 'faction'),
              _v(c, 'state'),
            );
          default:
            got = PhaseRules.getPhaseAbleUnitCount(
              _parseUnits(c['units'] ?? ''),
              _v(c, 'faction'),
            );
        }

        if ('$got' != want) failures.add('$id ($fn): 期望 $want，实际 $got');
      }
      expect(failures, isEmpty, reason: failures.take(8).join('\n'));
    });

    test('向量总数（防止文件被误删）', () {
      expect(cases.length, 103);
    });
  });
}
