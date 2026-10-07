// 占位符棘轮 —— `s.placeholder(...)` / 缺失脚本**只许降不许升**。
//
// ## 为什么需要
//
// 本项目 12 个真 bug 里有 3 个是这个形状：
//
//     `MNC2` 是占位符      → 游戏永远停在序章
//     `LoadUnits` 只写 HUD → 地图上一直是演示单位
//     `MOVE` 只写 HUD      → 剧情里没人走动
//
// 它们**都不报错**，表现只是"不对"。所以"还有多少没接上源码"必须是一个
// **会自己变红的数字**，而不是我脑子里的印象。
//
// ## 判据
//
//     placeholder 调用点 / 不同 op 名 / 缺失脚本数
//
// 三个数任一个**变大**就红。变小是好事 —— 用 `--update` 把新基线写回去。
//
// ## 为什么要 `--selftest`
//
// 「门禁绿 ≠ 门禁有效」。棘轮最容易坏的方式是**永远不红**，
// 所以自检里直接喂一份"多了一个占位"的源码，要求它必须红。
import 'dart:convert';
import 'dart:io';

const String generated = 'lib/core/event/scene_data.g.dart';
const String baselinePath = 'tools/verify/placeholder_baseline.json';

/// 一份产物里数出来的三个数
class Counts {
  const Counts(this.calls, this.ops, this.missing);

  /// `s.placeholder('...')` 的**调用点**数
  final int calls;

  /// 不同的 op 名数
  final int ops;

  /// 缺失脚本的占位函数数（`Future<void> missing_xxx`）
  final int missing;

  Map<String, int> toJson() =>
      {'placeholderCalls': calls, 'placeholderOps': ops, 'missingScripts': missing};

  factory Counts.fromJson(Map<String, dynamic> j) => Counts(
        j['placeholderCalls'] as int? ?? 0,
        j['placeholderOps'] as int? ?? 0,
        j['missingScripts'] as int? ?? 0,
      );

  @override
  String toString() =>
      'placeholder 调用点 $calls / 不同 op $ops / 缺失脚本 $missing';
}

final RegExp _call = RegExp(r"s\.placeholder\('([A-Za-z0-9_]+)'\)");
final RegExp _missingFn = RegExp(r'^Future<void> missing_\w+\(Scene s\)',
    multiLine: true);

Counts countIn(String src) {
  final names = <String>{};
  var calls = 0;
  for (final m in _call.allMatches(src)) {
    calls++;
    names.add(m.group(1)!);
  }
  return Counts(calls, names.length, _missingFn.allMatches(src).length);
}

/// 比较当前与基线。返回 (是否通过, 说明行)
(bool, List<String>) compare(Counts now, Counts base) {
  final lines = <String>[];
  var ok = true;

  void one(String name, int a, int b) {
    final d = a - b;
    if (d > 0) {
      ok = false;
      lines.add('  ✗ $name：$b → $a（**多了 $d**）—— 不许升，要么接上源码，'
          '要么说清楚为什么');
    } else if (d < 0) {
      lines.add('  ↓ $name：$b → $a（少了 ${-d}，可以 `--update` 收紧基线）');
    } else {
      lines.add('  ✓ $name：$a（与基线一致）');
    }
  }

  one('placeholder 调用点', now.calls, base.calls);
  one('不同 placeholder op', now.ops, base.ops);
  one('缺失脚本占位', now.missing, base.missing);
  return (ok, lines);
}

int runSelfTest() {
  const src = """
Future<void> A(Scene s) async {
  s.placeholder('ENUN');
  s.placeholder('MUSC');
}
Future<void> missing_X(Scene s) async { s.missing.add('X'); }
""";
  final base = countIn('');  // 0/0/0
  final one = countIn(src);
  final (ok, lines) = compare(one, const Counts(2, 2, 1));
  if (!ok) {
    stderr.writeln('✗ selftest：与基线相同的源码被判成红了');
    for (final l in lines) {
      stderr.writeln(l);
    }
    return 1;
  }
  final (ok2, _) = compare(one, base);
  if (ok2) {
    stderr.writeln('✗ selftest：**多出来的占位没被抓住** —— 棘轮是死的');
    return 1;
  }
  stdout.writeln('  ✓ selftest：多出一个占位时确实会红');
  stdout.writeln('  ✓ selftest：与基线一致时不红');
  return 0;
}

void main(List<String> argv) {
  if (argv.contains('--selftest')) {
    exit(runSelfTest());
  }
  final update = argv.contains('--update');

  final f = File(generated);
  if (!f.existsSync()) {
    stderr.writeln('✗ 找不到 $generated（先跑数据管线生成它）');
    exit(1);
  }
  final now = countIn(f.readAsStringSync());
  final bf = File(baselinePath);

  if (update) {
    bf.parent.createSync(recursive: true);
    bf.writeAsStringSync(
        '${const JsonEncoder.withIndent(' ').convert(now.toJson())}\n');
    stdout.writeln('✓ 基线已更新：$now');
    return;
  }

  if (!bf.existsSync()) {
    stderr.writeln('✗ 找不到基线 $baselinePath（先跑一次 `--update`）');
    exit(1);
  }
  final base = Counts.fromJson(
      jsonDecode(bf.readAsStringSync()) as Map<String, dynamic>);

  final (ok, lines) = compare(now, base);
  for (final l in lines) {
    stdout.writeln(l);
  }
  if (!ok) {
    stderr.writeln('占位符棘轮：红了（占位只许降不许升）');
    exit(1);
  }
  stdout.writeln('占位符棘轮：未上升 ✓');
}
