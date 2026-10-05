// 回合推进（SwitchPhases）与 C Oracle 逐值一致。
//
// 这一层值得进 Oracle 的原因是它的两个"看起来显然"的细节：
//   * 回合数**只在 GREEN 绕回 BLUE 时**递增（不是每次切换都加）
//   * 回合数**封顶 999**
// 两者都不会崩，只会让显示与逻辑悄悄偏掉。
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

void main() {
  test('turn_switch：阶段顺序 / 回合数递增与 999 上限', () {
    final cases = _readCases('$_vecDir/turn_switch.cases.tsv');
    final expected = _readExpected('$_vecDir/turn_switch.expected.tsv');
    expect(cases, isNotEmpty);

    final failures = <String>[];

    for (final id in cases.keys.toList()..sort()) {
      final c = cases[id]!;
      final want = expected[id];
      if (want == null) {
        failures.add('$id: 缺少期望值');
        continue;
      }

      var faction = int.parse(c['faction']!);
      var turn = int.parse(c['turn']!);
      final steps = int.parse(c['steps']!);
      final out = <String>[];

      for (var i = 0; i < steps; i++) {
        // ⚠️ 回合数用的是**切换前**的阵营来判断
        // （C 里是在 switch 的分支体内部才改 gPlaySt.faction）
        final prev = faction;
        faction = switchPhasesFaction(prev);
        turn = switchPhasesTurn(prev, turn);
        out.add('$faction,$turn');
      }

      final got = out.join(';');
      if (got != want) failures.add('$id: 期望 $want\n    实际 $got');
    }

    expect(failures, isEmpty, reason: failures.take(5).join('\n'));
    expect(cases.length, 47);
  });
}
