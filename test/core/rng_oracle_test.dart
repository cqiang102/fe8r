// L2 C Oracle 验证：把 Dart 的乱数移植与**真实反编译 C 代码**的运行结果对照。
//
// 这里的期望值不是手写的，是 tools/oracle/ 把第三方反编译项目的 src/rng.c
// 在宿主机上编译并运行得到的（见 tools/oracle/README.md）。
//
// 换句话说：这份测试的"标准答案"由原版 C 代码产出，Dart 必须逐位相同。
//
// 运行：fvm flutter test test/core/rng_oracle_test.dart
import 'dart:io';

import 'package:fe8r/core/rng/game_rng.dart';
import 'package:flutter_test/flutter_test.dart';

/// 解析 `<id>\t key=value \t key=value ...` 形式的用例文件
Map<String, Map<String, String>> _readCases(String path) {
  final out = <String, Map<String, String>>{};
  for (final line in File(path).readAsLinesSync()) {
    if (line.startsWith('#') || line.trim().isEmpty) continue;
    final parts = line.split('\t');
    final id = parts.first;
    final fields = <String, String>{};
    for (final p in parts.skip(1)) {
      final eq = p.indexOf('=');
      if (eq > 0) fields[p.substring(0, eq)] = p.substring(eq + 1);
    }
    out[id] = fields;
  }
  return out;
}

/// 解析 `<id>\t <result>` 形式
Map<String, String> _readExpected(String path) {
  final out = <String, String>{};
  for (final line in File(path).readAsLinesSync()) {
    if (line.startsWith('#') || line.trim().isEmpty) continue;
    final parts = line.split('\t');
    if (parts.length >= 2) out[parts[0]] = parts[1];
  }
  return out;
}

void main() {
  const vecDir = 'tools/oracle/vectors';

  group('乱数与 C Oracle 逐位一致', () {
    late Map<String, Map<String, String>> cases;
    late Map<String, String> expected;

    setUpAll(() {
      final casesFile = File('$vecDir/rng.cases.tsv');
      if (!casesFile.existsSync()) {
        fail('找不到 ${casesFile.path}。先在 tools/oracle/ 下跑 ./run_all.sh 生成向量。');
      }
      cases = _readCases(casesFile.path);
      expected = _readExpected('$vecDir/rng.expected.tsv');
    });

    test('向量文件非空', () {
      expect(cases, isNotEmpty);
      expect(expected, isNotEmpty);
    });

    for (final entry in <String, int Function(GameRng, int, int)>{
      'next': (r, count, thr) => r.nextRn(),
      'next100': (r, count, thr) => r.nextRn100(),
      'nextn': (r, count, thr) => r.nextRnN(thr),
      'lcg': (r, count, thr) => r.advanceGetLcgRnValue(),
    }.entries) {
      test('fn=${entry.key}', () {
        final ids = cases.entries
            .where((e) => (e.value['fn'] ?? 'next') == entry.key)
            .map((e) => e.key)
            .toList()
          ..sort();
        expect(ids, isNotEmpty, reason: '没有 fn=${entry.key} 的用例');

        var checked = 0;
        final failures = <String>[];

        for (final id in ids) {
          final c = cases[id]!;
          final want = expected[id];
          if (want == null) {
            failures.add('$id: 缺少期望值');
            continue;
          }

          // 初始化必须与 tools/oracle/scenarios/rng.c 的分支完全对应：
          //   lcg 分支用 SetLCGRNValue(seed)，其余分支用 InitRN(seed)
          final seed = int.parse(c['seed'] ?? '0');
          final rng = GameRng();
          if (entry.key == 'lcg') {
            rng.setLcgRnValue(seed);
          } else {
            rng.initRn(seed);
          }
          final count = int.parse(c['count'] ?? '8');
          final thr = int.parse(c['thr'] ?? '50');

          final got = <String>[];
          for (var i = 0; i < count; i++) {
            got.add('${entry.value(rng, count, thr)}');
          }

          if (got.join(',') != want) {
            failures.add('$id\n    期望 $want\n    实际 ${got.join(',')}');
          }
          checked++;
        }

        expect(failures, isEmpty,
            reason: '${failures.length} 条不一致：\n  ${failures.take(5).join('\n  ')}');
        expect(checked, greaterThan(0));
      });
    }
  });
}
