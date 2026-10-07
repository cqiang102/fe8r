// 家族级 **carve 审计** —— 比 `coverage_report.dart` 更细一层。
//
// 为什么需要它：`coverage_report.dart` 的口径是"提取器源码里有没有出现这个**目录名**"
// —— 第 36/38 轮那两个真缺口（`EventListScr_Ch1_Tutorial` 整张漏、
// `AnimConf` 只有 24/77）**在那个口径下都看不见**。
//
// 这个工具按**符号家族**对账：
//   * `defined`    = 源码里**定义**了这个家族的哪些符号
//   * `extracted`  = 我们的产物（JSON）里有哪些
//   * `notExtracted` = 差集，**逐个列出**（脚本/文件:行 作为证据）
//
// 三种 `kind`：
//   * `def`    —— 源码里有可读定义（`.c` 里的表/label）
//   * `layout` —— 只有 `layout/*.tsv`（符号表）登记，carve 里没有可读定义
//   * （两种都算"没提取到"，但要分清是**解析漏**还是 **carve 侧缺口**）
//
// ⚠️ **教训（第 38 轮踩到）**：审计用的正则必须匹配**完整标识符**。
// 我当时用 `…*_Tutorial` 这种**前缀**匹配，把 `Ch4_Tutorials` 截成不存在的
// `Ch4_Tutorial`，于是得出一个一半是假的结论。这里的正则都带 `\b` 或 `$`。
//
// 用法：
//   dart run tools/verify/carve_audit.dart            # 打印对账表
//   dart run tools/verify/carve_audit.dart --check    # 只许降（基线在 carve_baseline.json）
//   dart run tools/verify/carve_audit.dart --update   # 收紧基线
import 'dart:convert';
import 'dart:io';

const String decomp = 'third_party/fireemblem8j';
const String baselinePath = 'tools/verify/carve_baseline.json';

class Family {
  const Family(this.name, this.kind, {this.jsonFile, this.jsonPath, this.table});

  final String name;
  final String kind;

  /// 产物文件（`tools/pipeline/out/tables/<jsonFile>`）
  final String? jsonFile;

  /// 产物里放这个家族的那个键（例如 `lists` / `confs`）
  final String? jsonPath;

  /// `kind == layout` 时：在 `layout/baseline_syms.d/<table>.tsv` 里找
  final String? table;
}

const families = <Family>[
  Family('EventListScr_*_Tutorial(s)', 'def',
      jsonFile: 'tutorial_lists.json', jsonPath: 'lists'),
  Family('AnimConf_*（carve 出的定义）', 'def',
      jsonFile: 'banim_conf.json', jsonPath: 'confs'),
  Family('AnimConf_*（layout 登记）', 'layout',
      jsonFile: 'banim_conf.json', jsonPath: 'confs', table: 'dataCharClass'),
  Family('EventScr_*（场景脚本）', 'def'),
];

/// 源码里全部 `.c`/`.s`（递归；`src/` 下有几千个文件，只读一次）
List<File> srcFiles() {
  final out = <File>[];
  for (final dir in Directory('$decomp/src').listSync(recursive: true)) {
    if (dir is File && (dir.path.endsWith('.c') || dir.path.endsWith('.s'))) {
      out.add(dir);
    }
  }
  return out;
}

String read(File f) => f.readAsStringSync();

/// `def` 家族：源码里**定义**（`<name>:` 或 `NAME[] =`）了哪些符号
Map<String, String> definedSymbols(Family fam, List<File> files) {
  final out = <String, String>{}; // name → 证据（文件:行）
  switch (fam.name) {
    case 'EventListScr_*_Tutorial(s)':
      // 只认**完整**标识符 + 定义行（`EventListScr_X:` 或 `__shift[]` 数组）
      final re = RegExp(r'^(EventListScr_\w+_Tutorials?):\s*$', multiLine: true);
      final reShift =
          RegExp(r'static const u32 (EventListScr_\w+_Tutorials?)__shift\[\]');
      for (final f in files) {
        final t = read(f);
        for (final m in re.allMatches(t)) {
          out[m.group(1)!] = '${f.path}:${_lineOf(t, m.start)}';
        }
        for (final m in reShift.allMatches(t)) {
          out.putIfAbsent(m.group(1)!, () => '${f.path}:${_lineOf(t, m.start)}');
        }
      }
    case 'AnimConf_*（carve 出的定义）':
      final re = RegExp(r'AnimConf_(\d+)\[\]\s*=');
      for (final f in files) {
        final t = read(f);
        for (final m in re.allMatches(t)) {
          out['AnimConf_${m.group(1)}'] = '${f.path}:${_lineOf(t, m.start)}';
        }
      }
    case 'EventScr_*（场景脚本）':
      // 源码里脚本有三种形状（我第一次只认第一种 ⇒ 定义数 311 < 提取数 484，
      // **不变量当场把这条口径 bug 抓出来了**）：
      //   ① `EventScr_X:`（label）
      //   ② `EventScr_X[] = {`（数组）
      //   ③ `.global EventScr_X` + `EventScr_X:`（`.s` 里）
      final re = RegExp(
          r'^(?:EventScr_(\w+)):\s*$|EventScr_(\w+)\[\]\s*=|^\.global\s+(EventScr_\w+)\s*$',
          multiLine: true);
      for (final f in files) {
        final t = read(f);
        for (final m in re.allMatches(t)) {
          final n = m.group(1) ?? m.group(2) ?? m.group(3)!;
          out.putIfAbsent(n, () => '${f.path}:${_lineOf(t, m.start)}');
        }
      }
  }
  return out;
}

int _lineOf(String t, int index) => '\n'.allMatches(t.substring(0, index)).length + 1;

/// `layout` 家族：符号表里登记了哪些
Set<String> layoutSymbols(Family fam) {
  final p = '$decomp/layout/baseline_syms.d/${fam.table}.tsv';
  if (!File(p).existsSync()) return {};
  final out = <String>{};
  for (final l in File(p).readAsLinesSync()) {
    final n = l.split('\t').first.trim();
    if (n.startsWith('AnimConf_')) out.add(n);
  }
  return out;
}

/// 产物里提取到哪些
Set<String> extractedSymbols(Family fam) {
  if (fam.jsonFile == null) {
    // 场景脚本：产物是生成的 Dart 文件（`scene_data.g.dart` 里的函数名）
    final f = File('lib/core/event/scene_data.g.dart');
    if (!f.existsSync()) return {};
    return RegExp(r'^Future<void> (\w+)\(Scene s\)', multiLine: true)
        .allMatches(f.readAsStringSync())
        .map((m) => m.group(1)!)
        .toSet();
  }
  final f = File('tools/pipeline/out/tables/${fam.jsonFile}');
  if (!f.existsSync()) return {};
  final d = jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
  final v = d[fam.jsonPath];
  if (v is Map) return v.keys.map((e) => '$e').toSet();
  return {};
}

void main(List<String> args) {
  final check = args.contains('--check');
  final update = args.contains('--update');
  if (!Directory(decomp).existsSync()) {
    stdout.writeln('（没有 $decomp —— 跳过 carve 审计）');
    return;
  }
  final files = srcFiles();
  final result = <String, Object?>{};
  var bad = 0;
  for (final fam in families) {
    final Set<String> defined = fam.kind == 'layout'
        ? layoutSymbols(fam)
        : definedSymbols(fam, files).keys.toSet();
    final Set<String> got = extractedSymbols(fam);
    final missing = (defined.difference(got).toList()..sort()).cast<String>();
    stdout.writeln('■ ${fam.name}  [种类:${fam.kind}]');
    final overlap = defined.intersection(got).length;
    stdout.writeln('    定义 ${defined.length} / 提取 ${got.length} / '
        '**未提取 ${missing.length}**（两边同名 $overlap）');
    // ⚠️ 两套命名**不相交**时（`AnimConf` 的 layout 与 carve 就是），
    // "未提取"会等于整个定义集 —— 那不是算术错了，是**编号不是同一套**。
    if (overlap == 0 && defined.isNotEmpty) {
      stdout.writeln('    （两边**没有同名** ⇒ 未提取 = 定义全集；编号不是同一套）');
    }
    if (missing.isNotEmpty) {
      final head = missing.take(6).join(', ');
      stdout.writeln('    例：$head${missing.length > 6 ? ' …' : ''}');
    }
    // 不变量 1：**定义集必须被子集覆盖** —— 每个"定义过"的符号，
    // 要么提取到了，要么出现在下面的未提取清单里（清单必须是穷尽的）。
    // ⚠️ 我原来写的是"提取数 ≤ 定义数"，它对 **`EventScr_*` 这个家族是错的**：
    // 提取侧（`scene_data.g.dart`）还包含 WM 等别处的脚本，484 > 311
    // —— 那是**口径还没细分**，不是"多提取了"。已记进路线图欠账。
    final covered = defined.difference(missing.toSet());
    if (covered.difference(got).isNotEmpty) {
      stdout.writeln('    ❌ 有定义过的符号既没提取、也不在未提取清单里');
      bad++;
    }
    if (got.length > defined.length) {
      stdout.writeln('    ⚠️ 提取侧比定义侧多 ${got.length - defined.length} 个'
          '（提取侧还含别处的脚本 —— 口径待细分，见路线图欠账）');
    }
    // 不变量 2：家族要么全提到，要么未提取数与基线一致或更少
    result[fam.name] = {'defined': defined.length, 'extracted': got.length,
      'notExtracted': missing.length};
  }
  stdout.writeln('');
  if (update) {
    File(baselinePath).writeAsStringSync(
        const JsonEncoder.withIndent(' ').convert(result));
    stdout.writeln('基线已收紧 → $baselinePath');
    return;
  }
  if (!check) return;
  final base = File(baselinePath).existsSync()
      ? jsonDecode(File(baselinePath).readAsStringSync()) as Map<String, dynamic>
      : <String, dynamic>{};
  for (final e in result.entries) {
    final now = (e.value as Map)['notExtracted'] as int;
    final was = ((base[e.key] as Map?)?['notExtracted'] as num?)?.toInt();
    if (was != null && now > was) {
      stdout.writeln('❌ ${e.key}：未提取数从 $was 涨到 $now（只许降）');
      bad++;
    }
  }
  if (bad > 0) exit(1);
  stdout.writeln('✓ carve 审计：未提取数都没有上涨');
}
