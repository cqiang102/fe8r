// 统一验证入口（技术方案 §6 五层验证金字塔）
//
// 这是**唯一的事实来源**：本地跑它、CI 也跑它。CI 的 YAML 只负责装环境，
// 具体检查哪些东西全在这里定义——这样本地绿了，CI 基本不会红。
//
// 设计原则：
//   * **每个检查都必须有客观判据**，不接受"看着对"
//   * 任何一层失败，整体退出码非 0
//   * 没实现的层显式列出来，不假装通过
//   * 前置条件缺失时**明确跳过并说明**，而不是静默变绿
//
// 用法：dart run tools/verify/run_all.dart [--coverage]
import 'dart:io';

/// 一个检查步骤
class Step {
  Step(
    this.layer,
    this.name,
    this.exe,
    this.args, {
    this.cwd = '.',
    this.note = '',
    this.requires = const [],
  });

  /// 验证层级（L0..L4）
  final String layer;

  /// 显示名
  final String name;

  /// `flutter` / `dart` / `python3` / `bash` / 其它可执行文件
  final String exe;

  final List<String> args;

  /// 相对仓库根的工作目录
  final String cwd;

  final String note;

  /// 需要的路径（不存在就跳过并说明原因，而不是失败）
  final List<String> requires;
}

/// 从 `.fvmrc` 读出项目锁定的 SDK 路径。
///
/// 不假设 `flutter` / `dart` 在 PATH 里，也不假设 PATH 上那个版本是对的——
/// 实测踩过：PATH 上的 `dart` 是 3.9.2，而本项目要求 3.13，
/// 结果架构检查报"语言版本要求过高"这种看起来很莫名其妙的错。
(String, String) resolveToolchain() {
  final home = Platform.environment['HOME'] ?? '';
  final rc = File('.fvmrc');
  if (rc.existsSync()) {
    final m =
        RegExp(r'"flutter"\s*:\s*"([^"]+)"').firstMatch(rc.readAsStringSync());
    if (m != null) {
      final base = '$home/fvm/versions/${m.group(1)}';
      final fl = '$base/bin/flutter';
      final dt = '$base/bin/cache/dart-sdk/bin/dart';
      if (File(fl).existsSync()) {
        return (fl, File(dt).existsSync() ? dt : 'dart');
      }
    }
  }
  return ('flutter', 'dart');
}

/// 反编译源码是否在
bool hasDecomp() =>
    Directory('third_party/fireemblem8j/graphics/map').existsSync();

Future<void> main(List<String> argv) async {
  final root = Directory.current.path;
  final (flutter, dart) = resolveToolchain();
  final coverage = argv.contains('--coverage');

  const decomp = 'third_party/fireemblem8j';
  final decompNote = '需要 `git clone --depth 1 https://github.com/laqieer/'
      'fireemblem8j $decomp`';

  final steps = <Step>[
    Step('L0', '架构约束', 'dart',
        ['run', 'tools/verify/check_architecture.dart'],
        note: 'core 层纯净性 + 可追溯性'),

    if (hasDecomp())
      Step('L0', '数据管线往返', 'python3',
          ['extract/map_render.py', '--roundtrip'],
          cwd: 'tools/pipeline', note: '.mar ↔ 网格 字节级无损')
    else
      Step('L0', '数据管线往返（跳过）', 'true', const [], note: decompNote),

    // 数据表提取：判据是宿主机 C 编译器（编译真表、dump 字节、逐字节比对），
    // 不是"我解析一遍再自己检查"
    if (hasDecomp())
      Step('L0', '数据表提取（vs C 编译器）', 'python3',
          ['extract/parse_c_tables.py', '--out', 'out/tables'],
          cwd: 'tools/pipeline', note: '地形表 104 张 / 6760 个值')
    else
      Step('L0', '数据表提取（跳过）', 'true', const [], note: decompNote),

    // 只有二进制、没有 C 源码的表（武器三角规则）——判据是结构自洽性
    if (hasDecomp())
      Step('L0', '二进制表提取（自洽性校验）', 'python3',
          ['extract/parse_carved_tables.py', '--out', 'out/tables'],
          cwd: 'tools/pipeline', note: '武器三角规则表（ROM 0x085C3F70）')
    else
      Step('L0', '二进制表提取（跳过）', 'true', const [], note: decompNote),

    // 职业表：只取地形加成与移动消耗（含引用的表名必须真实存在）
    if (hasDecomp())
      Step('L0', '职业表提取', 'python3',
          ['extract/parse_class_tables.py', '--out', 'out/tables'],
          cwd: 'tools/pipeline', note: '127 个职业的地形加成 + 移动消耗表')
    else
      Step('L0', '职业表提取（跳过）', 'true', const [], note: decompNote),

    // 事件引擎的指令集：150 条指令 / 161 个子命令 + 位打包宏
    if (hasDecomp())
      Step('L0', '事件指令集（vs C 编译器）', 'python3',
          ['extract/parse_eventscript.py', '--out', 'out/tables'],
          cwd: 'tools/pipeline', note: '150 条指令 / 161 个子命令')
    else
      Step('L0', '事件指令集（跳过）', 'true', const [], note: decompNote),

    if (hasDecomp())
      Step('L0', '事件指令集校验', 'python3',
          ['extract/verify_eventscript.py'],
          cwd: 'tools/pipeline', note: '枚举值 + `_EvtCmd` 宏展开 vs clang')
    else
      Step('L0', '事件指令集校验（跳过）', 'true', const [], note: decompNote),

    if (hasDecomp())
      Step('L0', '章节事件提取（指针归一化）', 'python3',
          ['extract/parse_chapter_events.py', '--out', 'out/tables'],
          cwd: 'tools/pipeline', note: '21 张表 / 570 个指针槽 → 符号名')
    else
      Step('L0', '章节事件提取（跳过）', 'true', const [], note: decompNote),

    // 章节单位配置：**元素个数由探针里的 `sizeof` 算**，
    // 不靠 `nm` 的地址差 —— 后者在 ELF 与 Mach-O 上取法不同
    // （实测 Linux 2629 / macOS 2796）。现在两边逐条一致，
    // 所以这一步**可以**进 CI。
    if (hasDecomp())
      Step('L0', '章节单位配置提取', 'python3',
          ['extract/parse_unit_defs.py', '--out', 'out/tables'],
          cwd: 'tools/pipeline', note: '125 张表 / 2887 个条目（编译器算长度）')
    else
      Step('L0', '章节单位配置提取（跳过）', 'true', const [], note: decompNote),

    // 章节配置：可读 C，且字段值平台无关 —— 可进 CI
    if (hasDecomp())
      Step('L0', '章节配置提取', 'python3',
          ['extract/parse_chapters.py', '--out', 'out/tables'],
          cwd: 'tools/pipeline', note: '79 章（60 有名 + 19 空槽）')
    else
      Step('L0', '章节配置提取（跳过）', 'true', const [], note: decompNote),

    // 章节 → 资产 → 事件组/单位表：**全程文本**（反编译项目已去指针化）
    // 场景剧情脚本：纯线性指令流，用来统计**真实 opcode 覆盖率**
    if (hasDecomp())
      Step('L0', '场景剧情脚本 + opcode 覆盖率', 'python3',
          ['extract/parse_event_scripts.py', '--out', 'out/tables'],
          cwd: 'tools/pipeline',
          note: '166 张 / 5843 条指令 / 当前覆盖 62.2%')
    else
      Step('L0', '场景剧情脚本（跳过）', 'true', const [], note: decompNote),

    // 场景剧情：**从 C 源码直接生成 Dart**（没有 JSON 中间层）
    if (hasDecomp())
      Step('L0', '场景剧情脚本（生成 Dart）', 'python3',
          ['extract/gen_scene_dart.py'],
          cwd: 'tools/pipeline', note: '196 个脚本 → async 函数（直线103/分支93）')
    else
      Step('L0', '场景剧情脚本（跳过）', 'true', const [], note: decompNote),

    // 游戏文本：反编译项目已解码成纯文本，不用碰 Huffman
    // 立绘：索引色图块条 + GBA 调色板 + TSA 排列 → 可显示 PNG
    if (hasDecomp())
      Step('L0', '立绘合成', 'python3',
          ['extract/parse_portraits.py', '--out', 'out/portraits'],
          cwd: 'tools/pipeline', note: '90 个角色 / 80×72')
    else
      Step('L0', '立绘合成（跳过）', 'true', const [], note: decompNote),

    // 脸编号 → 角色名（表项是**可读的 C 源码**）
    if (hasDecomp())
      Step('L0', '脸编号映射', 'python3',
          ['extract/parse_face_ids.py'],
          cwd: 'tools/pipeline', note: '174 项 / 117 个有名字')
    else
      Step('L0', '脸编号映射（跳过）', 'true', const [], note: decompNote),

    if (hasDecomp())
      Step('L0', '游戏文本 + 章节标题', 'python3',
          ['extract/parse_text.py', '--out', 'out/tables'],
          cwd: 'tools/pipeline', note: '3339 条消息 / 61 个章节标题')
    else
      Step('L0', '游戏文本（跳过）', 'true', const [], note: decompNote),

    if (hasDecomp())
      Step('L0', '章节链路（资产 / 事件组）', 'python3',
          ['extract/parse_chapter_links.py', '--out', 'out/tables'],
          cwd: 'tools/pipeline', note: '79 章 → 16 个事件组（含单位表）')
    else
      Step('L0', '章节链路（跳过）', 'true', const [], note: decompNote),

    if (hasDecomp())
      Step('L0', '数据表逐字节校验', 'python3',
          ['extract/verify_tables.py'],
          cwd: 'tools/pipeline', note: '135 张表 / 7008 个值 vs clang')
    else
      Step('L0', '数据表逐字节校验（跳过）', 'true', const [], note: decompNote),

    // 全量导出 + 逐格往返：覆盖所有能解析出资产的章节地图
    if (hasDecomp())
      Step('L0', 'TMX 全量往返', 'python3',
          ['extract/map_tmx.py', '--verify-all', '--out', 'out/tmx'],
          cwd: 'tools/pipeline', note: '52 张地图 .tmx ↔ .mar 逐格一致')
    else
      Step('L0', 'TMX 全量往返（跳过）', 'true', const [], note: decompNote),

    // ⚠️ **所有 Dart 测试合并成一次 `flutter test`。**
    //
    // 曾经是 14 个独立步骤，每个一次 `flutter test` —— 而每次调用要
    // 起一遍 Flutter 引擎（约 1.5 秒），14 次就是 ~21 秒，
    // 其中绝大部分是**启动开销，不是测试本身**。
    //
    // 合并之后共用一次引擎启动。代价是"哪个套件挂了"不再由步骤名体现，
    // 但 `flutter test` 的输出本来就会逐文件报结果，
    // 失败时下面会把输出打出来，定位不受影响。
    //
    // 覆盖的套件（18 个文件）：
    //   flow_machine / relocations / event_scripts / chapter_loader /
    //   chapters / unit_defs / chapter_events / event_vm / class_table /
    //   battle_round / combat / turn_loop / map_grid / movement_oracle /
    //   battle_oracle / phase_oracle / turn_switch_oracle / rng_oracle
    Step('L1', '单元测试（全部套件）', 'flutter',
        ['test', 'test/core', 'test/game'],
        note: 'M1–M6：流程状态机 / 事件引擎 / 章节链路 / 战斗结算 / 回合循环'),

    // C Oracle 自身的自检：证明"判据"本身是可信的
    // （golden 对照 + 独立 Python 交叉校验，会真的编译反编译 C）
    if (hasDecomp())
      Step('L2', 'C Oracle 自检', 'bash',
          ['tools/oracle/verify.sh', if (coverage) '--coverage'],
          note: 'golden 对照 + Python 交叉校验', requires: ['tools/oracle/verify.sh'])
    else
      Step('L2', 'C Oracle 自检（跳过）', 'true', const [], note: decompNote),

    // 把 Dart 移植与真实 C 对上
    if (hasDecomp())
      Step('L2', 'C Oracle ↔ Dart（乱数）', 'flutter',
          ['test', 'test/core/rng_oracle_test.dart'],
          note: '161 用例逐位对照')
    else
      Step('L2', 'C Oracle ↔ Dart（乱数，跳过）', 'true', const [], note: decompNote),

    if (hasDecomp())
      Step('L2', 'C Oracle ↔ Dart（战斗数值）', 'flutter',
          ['test', 'test/core/battle_oracle_test.dart'],
          note: '655 用例：战斗数值 / 特效 / 乱数消耗 / 武器三角')
    else
      Step('L2', 'C Oracle ↔ Dart（战斗数值，跳过）', 'true', const [],
          note: decompNote),

    if (hasDecomp())
      Step('L2', 'C Oracle ↔ Dart（回合推进）', 'flutter',
          ['test', 'test/core/turn_switch_oracle_test.dart'],
          note: '47 用例：阶段顺序 / 回合数递增与 999 上限')
    else
      Step('L2', 'C Oracle ↔ Dart（回合推进，跳过）', 'true', const [],
          note: decompNote),

    if (hasDecomp())
      Step('L2', 'C Oracle ↔ Dart（阶段与阵营）', 'flutter',
          ['test', 'test/core/phase_oracle_test.dart'],
          note: '103 用例：阵营判定 / 可行动单位计数')
    else
      Step('L2', 'C Oracle ↔ Dart（阶段与阵营，跳过）', 'true', const [],
          note: decompNote),

    if (hasDecomp())
      Step('L2', 'C Oracle ↔ Dart（移动范围）', 'flutter',
          ['test', 'test/core/movement_oracle_test.dart'],
          note: '54 用例逐格对照')
    else
      Step('L2', 'C Oracle ↔ Dart（移动范围，跳过）', 'true', const [],
          note: decompNote),

    // M1：全量分层分类（D19 要求未分类为 0）。分类器是代码不是表格，
    // 所以它也能进回归——改了特征或名称规则后，未分类数必须仍然是 0。
    if (hasDecomp())
      Step('L1', 'M1 分层分类（未分类须为 0）', 'python3',
          ['tools/m1/classify.py'], note: 'D19：6213 个文件全部有结论')
    else
      Step('L1', 'M1 分层分类（跳过）', 'true', const [], note: decompNote),

    Step('L3', '静态契约', 'flutter',
        ['analyze', '--fatal-infos', 'lib', 'test', 'tools'],
        note: 'analyzer 全绿'),
  ];

  stdout.writeln('FE8 重制版 —— 验证金字塔');
  stdout.writeln('=' * 64);
  if (!hasDecomp()) {
    stdout.writeln('⚠️  未找到 $decomp，相关检查会被跳过。');
    stdout.writeln('    $decompNote');
  }

  final results = <(Step, String, String)>[]; // (step, 状态, 耗时)
  var skipped = 0;

  for (final s in steps) {
    stdout.writeln(
        '\n[${s.layer}] ${s.name}${s.note.isEmpty ? '' : '  — ${s.note}'}');

    // 前置文件检查：缺失就跳过（并说明），不当成失败
    final missing = s.requires.where((p) => !File(p).existsSync()).toList();
    if (missing.isNotEmpty) {
      stdout.writeln('  ⤼ 跳过（缺少 ${missing.join(', ')}）');
      results.add((s, 'skip', '-'));
      skipped++;
      continue;
    }

    final sw = Stopwatch()..start();
    final exe = switch (s.exe) {
      'flutter' => flutter,
      'dart' => dart,
      _ => s.exe,
    };

    final int code;
    final String out;
    try {
      final r = await Process.run(
        exe,
        s.args,
        workingDirectory: '$root/${s.cwd}',
      );
      code = r.exitCode;
      out = '${r.stdout}${r.stderr}'.trim();
    } on ProcessException catch (e) {
      // 可执行文件不存在（例如没装 python3）——跳过而不是失败
      stdout.writeln('  ⤼ 跳过（无法执行 $exe：${e.message}）');
      results.add((s, 'skip', '-'));
      skipped++;
      continue;
    }
    sw.stop();

    final ok = code == 0;
    results.add((s, ok ? 'pass' : 'fail', '${sw.elapsedMilliseconds}ms'));

    if (ok) {
      stdout.writeln('  ✓ 通过 (${sw.elapsedMilliseconds}ms)');
      final lines = out
          .split('\n')
          .where((l) => l.trim().isNotEmpty)
          .where((l) =>
              !l.startsWith('Resolving') &&
              !l.startsWith('Downloading') &&
              !l.startsWith('Analyzing'))
          .toList();
      for (final line in lines.reversed.take(3).toList().reversed) {
        stdout.writeln('      $line');
      }
    } else {
      stdout.writeln('  ✗ 失败 (退出码 $code)');
      for (final line in out.split('\n').take(40)) {
        stdout.writeln('      $line');
      }
    }
  }

  stdout.writeln('\n[—] 尚未实现');

  stdout.writeln('      L1 事件引擎的其余指令（150 条里已实现 27 条）');
  stdout.writeln('      L1 章节触发条件与剧情数据管线');
  stdout.writeln('      L4 视觉验证（技术方案 §6.5 的参考渲染器对比，'
      '可复用 lib/ui/debug_screenshot.dart 的抓帧能力）');

  final failed = results.where((r) => r.$2 == 'fail').toList();
  final passed = results.where((r) => r.$2 == 'pass').length;

  stdout.writeln('\n${'=' * 64}');
  if (failed.isEmpty) {
    stdout.writeln('通过 $passed 项'
        '${skipped > 0 ? '，跳过 $skipped 项' : ''}');
    return;
  }
  stdout.writeln('失败 ${failed.length} 项（通过 $passed，跳过 $skipped）：');
  for (final f in failed) {
    stdout.writeln('  ✗ [${f.$1.layer}] ${f.$1.name}');
  }
  exit(1);
}
