// 架构约束检查（技术方案 §4.8 负面清单的机器执行版）
//
// 为什么不用 analyzer 的自定义规则：我们要表达的是"**整棵子树**禁止某类 import"，
// 以及"禁止出现某类调用"，用 lint 规则表达很别扭。纯文本扫描 + 精确的作用域
// 过滤已经足够可靠，而且零依赖、跑得快、错误信息可以写得很具体。
//
// 用法：dart run tools/verify/check_architecture.dart
// 有违规时退出码 1。
//
// ⚠️ 改这个文件后**务必重新跑一次误报/漏报自检**：构造一个违规文件确认被拦下，
// 再确认注释和字符串里的同名内容不会被误报。一个从不报错的 lint 比没有 lint
// 更危险——它会让人以为约束被守住了。
import 'dart:io';

/// 规则的匹配范围
enum Scope {
  /// 只在 `import` / `export` / `part` 指令行上匹配。
  ///
  /// 用这个而不是"全局保留字符串"，否则代码里任何一个写着
  /// `"import 'package:flame/x.dart'"` 的普通字符串都会被误报。
  directive,

  /// 在去掉了注释和字符串的整份代码上匹配（用于"禁止某个调用"类规则）。
  ///
  /// 去掉字符串是为了不让文档里举的反例被当真。
  code,
}

/// 一条规则
class Rule {
  const Rule(
    this.id,
    this.description,
    this.targets,
    this.pattern, {
    required this.scope,
    this.hint = '',
    this.skipPortOfCheck = false,
  });

  /// 规则编号，出现在报错里
  final String id;

  /// 一句话说明
  final String description;

  /// 作用范围（目录前缀，相对仓库根）
  final List<String> targets;

  /// 触发正则
  final RegExp pattern;

  /// 在哪个范围里找
  final Scope scope;

  /// 违规了怎么改
  final String hint;

  /// R7 专用：跳过纯导出文件
  final bool skipPortOfCheck;
}

/// 违规记录
class Violation {
  Violation(this.file, this.line, this.text, this.rule);
  final String file;
  final int line;
  final String text;
  final Rule rule;

  @override
  String toString() => '  [$file:$line] ${rule.id}  ${rule.description}\n'
      '      ${text.trim()}\n'
      '      → ${rule.hint}';
}

// ---------------------------------------------------------------- 规则定义

/// `lib/core` 是规则层：必须是纯 Dart，且完全可序列化。
const String coreDir = 'lib/core';

final List<Rule> rules = [
  Rule(
    'R1',
    '$coreDir 不得依赖 Flutter / Flame / dart:ui（规则层必须是纯 Dart）',
    [coreDir],
    RegExp('(package:flutter/|package:flame|dart:ui)'),
    scope: Scope.directive,
    hint: '把 UI 相关的东西移到 lib/game 或 lib/ui，core 只留可测试的纯逻辑',
  ),
  Rule(
    'R2',
    '$coreDir 不得依赖 dart:io（存档要能跨平台序列化，不能直接碰文件系统）',
    [coreDir],
    RegExp('dart:io'),
    scope: Scope.directive,
    hint: '由外层的 SaveStore 注入字节，core 只负责序列化/反序列化',
  ),
  Rule(
    'R3',
    '$coreDir 不得有非确定性来源（DateTime.now / Random / Stopwatch）',
    [coreDir],
    RegExp(r'\b(DateTime\.now|Random\s*\(|Stopwatch\s*\(|DateTime\.timestamp)'),
    scope: Scope.code,
    hint: '时间和随机数都必须注入，否则存档回放不可能一致',
  ),
  Rule(
    'R4',
    '$coreDir 不得使用 async/await（事件引擎必须是可中断、可存档的状态机）',
    [coreDir],
    RegExp(r'(\basync\b|\bawait\b)'),
    scope: Scope.code,
    hint: '用显式状态机推进；async 的调用栈无法序列化，存档就断了',
  ),
  Rule(
    'R5',
    '$coreDir 不得出现 GBA 平台层的直接依赖（技术方案 §4.8 负面清单）',
    [coreDir],
    RegExp('(package:gba|package:libgba|dart:ffi)'),
    scope: Scope.directive,
    hint: '平台层是明确丢弃的 485 个文件，语义在 core 里重新表达',
  ),
  Rule(
    'R6',
    'lib/ui 不得反向依赖 lib/game 的内部实现',
    ['lib/ui'],
    RegExp('package:fe8r/game/.+/.+'),
    scope: Scope.directive,
    hint: 'ui 只通过 public 入口（package:fe8r/game/fe8_game.dart）与游戏交互',
  ),
  Rule(
    'R7',
    '$coreDir 的文件必须带 `PORT OF: <C 源文件>` 头注释',
    [coreDir],
    RegExp(r'PORT OF:\s*\S'),
    scope: Scope.code,
    hint: '在文件顶部加一行，例如：// PORT OF: src/rng.c',
    skipPortOfCheck: true,
  ),
];

// ---------------------------------------------------------------- 源码处理

/// 从 [start]（引号位置）扫描到字符串结束，返回结束后的下标
int _scanString(String src, int start) {
  final n = src.length;
  final quote = src[start];
  final triple =
      start + 2 < n && src[start + 1] == quote && src[start + 2] == quote;
  var i = start + (triple ? 3 : 1);

  while (i < n) {
    if (src[i] == r'\' && i + 1 < n) {
      i += 2;
      continue;
    }
    if (triple) {
      if (src[i] == quote &&
          i + 2 < n &&
          src[i + 1] == quote &&
          src[i + 2] == quote) {
        return i + 3;
      }
    } else {
      if (src[i] == quote) return i + 1;
      if (src[i] == '\n') return i; // 未闭合，保险
    }
    i++;
  }
  return n;
}

/// 去掉注释（保留换行以维持行号）。
///
/// 字符串字面量**原样保留**——import 的路径就在里面，抹掉它 R1/R2/R5/R6
/// 就永远不会命中，最关键的那几条规则会静默失效。
String stripComments(String src) {
  final out = StringBuffer();
  var i = 0;
  final n = src.length;

  while (i < n) {
    final c = src[i];

    // 行注释
    if (c == '/' && i + 1 < n && src[i + 1] == '/') {
      while (i < n && src[i] != '\n') {
        i++;
      }
      continue;
    }
    // 块注释（Dart 支持嵌套）
    if (c == '/' && i + 1 < n && src[i + 1] == '*') {
      var depth = 1;
      i += 2;
      while (i < n && depth > 0) {
        if (src[i] == '/' && i + 1 < n && src[i + 1] == '*') {
          depth++;
          i += 2;
        } else if (src[i] == '*' && i + 1 < n && src[i + 1] == '/') {
          depth--;
          i += 2;
        } else {
          if (src[i] == '\n') out.write('\n'); // 保住行号
          i++;
        }
      }
      continue;
    }
    // 字符串：整段原样复制（要正确跳过其中的 // 和 /*）
    if (c == "'" || c == '"') {
      final end = _scanString(src, i);
      out.write(src.substring(i, end));
      i = end;
      continue;
    }

    out.write(c);
    i++;
  }
  return out.toString();
}

/// 把字符串字面量替换成占位符，用于"禁止某个调用"类规则。
String blankStrings(String src) {
  final out = StringBuffer();
  var i = 0;
  final n = src.length;

  while (i < n) {
    final c = src[i];
    if (c == "'" || c == '"') {
      final end = _scanString(src, i);
      // 保留其中的换行，行号才不会错位
      out.write('\n' * '\n'.allMatches(src.substring(i, end)).length);
      out.write('""');
      i = end;
      continue;
    }
    out.write(c);
    i++;
  }
  return out.toString();
}

/// 一行是不是 import / export / part 指令
final RegExp _directiveLine = RegExp(r'^\s*(import|export|part)\b');

/// 递归列出目录下所有 `.dart` 文件
List<String> dartFilesUnder(String dir) {
  final d = Directory(dir);
  if (!d.existsSync()) return [];
  return d
      .listSync(recursive: true)
      .whereType<File>()
      .map((f) => f.path)
      .where((p) => p.endsWith('.dart'))
      .toList()
    ..sort();
}

// ---------------------------------------------------------------- 主流程

/// 执行检查，返回违规列表
List<Violation> check(List<Rule> rules) {
  final violations = <Violation>[];

  for (final rule in rules) {
    for (final target in rule.targets) {
      for (final file in dartFilesUnder(target)) {
        // R7 只看 core 下的实现文件，纯导出文件豁免
        if (rule.skipPortOfCheck && RegExp(r'/core\.dart$').hasMatch(file)) {
          continue;
        }

        final raw = File(file).readAsStringSync();
        final noc = stripComments(raw);

        if (rule.scope == Scope.directive) {
          final lines = noc.split('\n');
          for (var i = 0; i < lines.length; i++) {
            if (_directiveLine.hasMatch(lines[i]) &&
                rule.pattern.hasMatch(lines[i])) {
              violations.add(Violation(file, i + 1, lines[i], rule));
            }
          }
        } else {
          final code = blankStrings(noc);
          final lines = code.split('\n');
          for (var i = 0; i < lines.length; i++) {
            if (rule.pattern.hasMatch(lines[i])) {
              violations.add(Violation(file, i + 1, lines[i], rule));
            }
          }
        }
      }
    }
  }
  return violations;
}

int main(List<String> args) {
  if (!Directory('lib').existsSync()) {
    stderr.writeln('错误：请在仓库根目录运行（找不到 lib/）');
    return 2;
  }

  final violations = check(rules);

  if (violations.isEmpty) {
    stdout.writeln('架构检查通过（扫描 ${dartFilesUnder('lib').length} 个 Dart 文件，'
        '${rules.length} 条规则）');
    for (final r in rules) {
      stdout.writeln('  ${r.id}  ${r.description}');
    }
    return 0;
  }

  stderr.writeln('架构检查失败：${violations.length} 处违规\n');
  for (final v in violations) {
    stderr.writeln(v);
  }
  stderr.writeln('\n共 ${violations.length} 处。'
      '规则说明见 tools/verify/check_architecture.dart');
  return 1;
}
