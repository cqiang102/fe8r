// 覆盖率账本 —— 把"还差多少"从**感觉**换成**数字**。
//
// ## 为什么需要它
//
// 用户的话：「先把 fe8j 源码里**确定的、重复性的**先做完，别依赖到一个做一个」。
// 对，但先得有"做完"的定义，否则又会变成假进度
// （占位符棘轮降了几百，玩家还是玩不到东西）。
//
// 这个脚本量两张表，两张都是**只许降**的棘轮：
//
//   1. **规则层**：`third_party/fireemblem8j/src/*.c`（每个函数一个 TU）
//      里，有多少**没有**出现在我们 `lib/**` 的 `PORT OF:` 里。
//   2. **数据层**：`src/data/<dir>` 与 `graphics/<dir>` 里，
//      有多少目录**没有被任何提取器的 glob/正则碰到**。
//
// ⚠️ 口径必须说清楚（否则数字会骗人）：
//   * "没出现在 `PORT OF:`" ≠ "没做" —— 可能是数据表、死代码、
//     或者被别的文件顺带覆盖了。所以表头写"未见引用"，不写"未移植"。
//   * 数据目录"没被提取器碰到"是**强判据**：那个目录的素材/表就是没有进管线。
//
// 用法：
//     dart run tools/verify/coverage_report.dart            # 写 docs/覆盖率.md + 校棘轮
//     dart run tools/verify/coverage_report.dart --update   # 收紧基线
//     dart run tools/verify/coverage_report.dart --selftest # 证明棘轮会红
import 'dart:convert';
import 'dart:io';

const String decomp = 'third_party/fireemblem8j';
const String baselinePath = 'tools/verify/coverage_baseline.json';
const String docPath = 'docs/覆盖率.md';

class Counts {
  Counts(this.ruleTotal, this.ruleSeen, this.dataTotal, this.dataSeen);
  final int ruleTotal, ruleSeen, dataTotal, dataSeen;
  int get ruleUnseen => ruleTotal - ruleSeen;
  int get dataUnseen => dataTotal - dataSeen;
  Map<String, Object> toJson() => {
        'ruleTotal': ruleTotal,
        'ruleSeen': ruleSeen,
        'ruleUnseen': ruleUnseen,
        'dataTotal': dataTotal,
        'dataSeen': dataSeen,
        'dataUnseen': dataUnseen,
      };
}

/// `PORT OF:` 头里出现过的源文件名（basename 去重）
Set<String> portOfRefs() {
  final out = <String>{};
  for (final f in Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))) {
    final lines = f.readAsLinesSync();
    final head = lines.take(60).join('\n'); // 头注释都在开头
    for (final m in RegExp(r'([A-Za-z0-9_./-]+\.(?:c|s))\b').allMatches(head)) {
      out.add(m.group(1)!.split('/').last);
    }
  }
  return out;
}

/// 提取器的**全部源码文本**。
///
/// ⚠️ 只能当**弱判据**用：提取器里路径是 `os.path.join(DECOMP, "src", "data", …)`
/// **分段写的**，所以拼不出 `src/data/xxx` 这种整串。
/// 这里退一步按**目录名**匹配 —— 会**高估**"已覆盖"，也就是**低估待办**
/// （数字偏乐观）。所以表头写"未见提及"，并且另外给一条强判据：
/// 目录里有 `_ref`（carve 去过指针化）的，才是确实存在的表。
String extractorText() {
  final text = StringBuffer();
  for (final f in Directory('tools/pipeline/extract')
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.py'))) {
    text.write(f.readAsStringSync());
  }
  return text.toString();
}

/// 目录名是否在提取器源码里出现过（弱判据，见 [extractorText]）
bool touched(String dir, String text) {
  final name = dir.split('/').last;
  if (name.length < 3) return true; // 太短的名字（如 `data`）会满天飞，按"已覆盖"算
  return text.contains("'$name'") ||
      text.contains('"$name"') ||
      text.contains('/$name') ||
      text.contains('$name/');
}

/// 目录里有没有 carve 出来的 `_ref`（= 确实存在的表/指针表）
bool hasRef(String dir) {
  final d = Directory(dir);
  if (!d.existsSync()) return false;
  return d.listSync().any((e) => e.path.endsWith('_ref'));
}

Counts measure({Set<String>? refsOverride, String? textOverride}) {
  final refs = refsOverride ?? portOfRefs();
  final toks = textOverride ?? extractorText();

  final rule = Directory('$decomp/src')
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.c'))
      .map((f) => f.path.split('/').last)
      .toList();
  final ruleSeen = rule.where(refs.contains).length;

  // 数据目录：src/data/<x> 与 graphics/<x>
  final dirs = <String>{};
  for (final base in ['$decomp/src/data', '$decomp/graphics', '$decomp/banim']) {
    final d = Directory(base);
    if (!d.existsSync()) continue;
    for (final e in d.listSync()) {
      if (e is Directory) dirs.add(e.path);
    }
  }
  final dataSeen = dirs.where((p) => touched(p, toks)).length;
  return Counts(rule.length, ruleSeen, dirs.length, dataSeen);
}

String report(Counts c, List<String> unseenRule, List<String> unseenDirs) {
  final b = StringBuffer()
    ..writeln('# 覆盖率账本（自动生成，不要手改）')
    ..writeln()
    ..writeln('> `dart run tools/verify/coverage_report.dart` 生成。')
    ..writeln('> 两张表都是**只许降**的棘轮（基线在 `tools/verify/coverage_baseline.json`）。')
    ..writeln()
    ..writeln('## 口径（先读这段，不然数字会骗人）')
    ..writeln()
    ..writeln('* **规则层**：`$decomp/src/*.c`（每个函数一个 TU）。')
    ..writeln('  "未见引用" = 没有出现在任何 `lib/**` 的 `PORT OF:` 头里。')
    ..writeln('  ⚠️ 这**不等于没做**：可能是数据表/死代码/被别的文件顺带覆盖。')
    ..writeln('* **数据层**：`src/data/<dir>`、`graphics/<dir>`、`banim/<dir>`。')
    ..writeln('  "未见提及" = 提取器源码里没有出现这个**目录名**。')
    ..writeln('  ⚠️ 这是**弱判据，两个方向都会偏**：递归 glob（`src/data/**/*.s`）')
    ..writeln('  覆盖的目录**不会提到目录名** ⇒ 高估待办；短名字（<3 字符）满天飞 ⇒')
    ..writeln('  按"已覆盖"算 ⇒ 低估待办。带 `_ref` 的才是**确实存在**的表。')
    ..writeln()
    ..writeln('## 数字')
    ..writeln()
    ..writeln('| | 总数 | 已见 | 未见/未提取 |')
    ..writeln('|---|---|---|---|')
    ..writeln('| 规则层 TU | ${c.ruleTotal} | ${c.ruleSeen} '
        '| **${c.ruleUnseen}** （${(100 * c.ruleSeen / c.ruleTotal).toStringAsFixed(1)}% 已见）|')
    ..writeln('| 数据目录 | ${c.dataTotal} | ${c.dataSeen} | **${c.dataUnseen}** |')
    ..writeln()
    ..writeln('## 未见引用的规则层 TU（前 40，按名字排）')
    ..writeln()
    ..writeln('```')
    ..writeln(unseenRule.take(40).join('\n'))
    ..writeln('```')
    ..writeln()
    ..writeln('## 提取器源码里**没提到过**的目录'
        '（共 ${unseenDirs.length}，列前 60；带 `_ref` 的是确实存在的表）')
    ..writeln()
    ..writeln('```')
    ..writeln(unseenDirs.take(60).join('\n'))
    ..writeln('```');
  return b.toString();
}

int main(List<String> argv) {
  if (argv.contains('--selftest')) return selftest();
  final refs = portOfRefs();
  final toks = extractorText();
  final c = measure(refsOverride: refs, textOverride: toks);

  final rule = Directory('$decomp/src')
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.c'))
      .map((f) => f.path.split('/').last)
      .where((n) => !refs.contains(n))
      .toList()
    ..sort();
  final dirs = <String>[];
  for (final base in ['$decomp/src/data', '$decomp/graphics', '$decomp/banim']) {
    final d = Directory(base);
    if (!d.existsSync()) continue;
    for (final e in d.listSync()) {
      if (e is Directory && !touched(e.path, toks)) {
        dirs.add('${e.path}${hasRef(e.path) ? '   ← 有 _ref（确实是表）' : ''}');
      }
    }
  }
  dirs.sort();

  // ⚠️ `--check` **不写文档** —— 验证过程不许修改被 Git 跟踪的文件
  // （`gen_scene_dart.py --check` 那条注释记的就是这个教训）。
  if (argv.contains('--check')) {
    stdout.writeln('  （--check：不写 $docPath）');
  } else {
    File(docPath).writeAsStringSync(report(c, rule, dirs));
    stdout.writeln('→ $docPath');
  }
  stdout.writeln('   规则层 ${c.ruleSeen}/${c.ruleTotal}（未见 ${c.ruleUnseen}）'
      '  数据目录 ${c.dataSeen}/${c.dataTotal}（未提取 ${c.dataUnseen}）');

  final bf = File(baselinePath);
  if (argv.contains('--update') || !bf.existsSync()) {
    bf.writeAsStringSync(
        const JsonEncoder.withIndent(' ').convert(c.toJson()));
    stdout.writeln('  ✓ 基线已写入 $baselinePath');
    return 0;
  }
  final base = jsonDecode(bf.readAsStringSync()) as Map<String, dynamic>;
  var bad = 0;
  for (final k in ['ruleUnseen', 'dataUnseen']) {
    final now = c.toJson()[k] as int;
    final was = base[k] as int;
    if (now > was) {
      stderr.writeln('✗ $k 上升了：$was → $now（棘轮只许降）');
      bad++;
    } else if (now < was) {
      stdout.writeln('  ↓ $k：$was → $now（可以 --update 收紧基线）');
    }
  }
  if (bad > 0) return 1;
  stdout.writeln('覆盖率棘轮：未上升 ✓');
  return 0;
}

/// 证伪：故意造一个"未见引用"变多的局面，要求棘轮红
int selftest() {
  final base = measure();
  // 把已见集合清空 ⇒ 未见数必然上升
  final worse = measure(refsOverride: <String>{}, textOverride: '');
  if (worse.ruleUnseen <= base.ruleUnseen) {
    stderr.writeln('✗ selftest：清空 PORT OF 之后未见数没上升 —— 判据是死的');
    return 1;
  }
  stdout.writeln('  ✓ selftest：未见数会随覆盖率下降而上升（基线 ${base.ruleUnseen} → '
      '${worse.ruleUnseen}）');
  return 0;
}
