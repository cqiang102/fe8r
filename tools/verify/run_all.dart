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
  /// ⚠️ **"跳过"必须是一种独立状态，不能靠跑 `true` 冒充通过。**
  ///
  /// 原本 19 个"（跳过）"步骤的可执行文件是 `true`（退出 0），
  /// 于是汇总把它们记成 **pass** —— 审计实测：搭一份没有 `third_party/`
  /// 的仓库跑全量，每一步都 `✓ 通过 (4ms)`，结尾 **`通过 27 项`，退出 0**。
  /// 而 `third_party/` 是 gitignore 的，**新克隆的默认状态就是这个**。
  ///
  /// 也就是说：**仓库刚克隆下来、什么都没验，门禁报"通过 27 项"。**
  final bool skip;

  Step(
    this.layer,
    this.name,
    this.exe,
    this.args, {
    this.cwd = '.',
    this.note = '',
    this.requires = const [],
    this.skip = false,
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
  final allowMissingDecomp = argv.contains('--allow-missing-decomp');

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
      Step('L0', '数据管线往返', 'true', const [], skip: true, note: decompNote),

    // 数据表提取：判据是宿主机 C 编译器（编译真表、dump 字节、逐字节比对），
    // 不是"我解析一遍再自己检查"
    if (hasDecomp())
      Step('L0', '数据表提取（vs C 编译器）', 'python3',
          ['extract/parse_c_tables.py', '--out', 'out/tables'],
          cwd: 'tools/pipeline', note: '地形表 104 张 / 6760 个值')
    else
      Step('L0', '数据表提取', 'true', const [], skip: true, note: decompNote),

    // 只有二进制、没有 C 源码的表（武器三角规则）——判据是结构自洽性
    if (hasDecomp())
      Step('L0', '二进制表提取（自洽性校验）', 'python3',
          ['extract/parse_carved_tables.py', '--out', 'out/tables'],
          cwd: 'tools/pipeline', note: '武器三角规则表（ROM 0x085C3F70）')
    else
      Step('L0', '二进制表提取', 'true', const [], skip: true, note: decompNote),

    // 职业表：只取地形加成与移动消耗（含引用的表名必须真实存在）
    if (hasDecomp())
      Step('L0', '职业表提取', 'python3',
          ['extract/parse_class_tables.py', '--out', 'out/tables'],
          cwd: 'tools/pipeline', note: '127 个职业的地形加成 + 移动消耗表')
    else
      Step('L0', '职业表提取', 'true', const [], skip: true, note: decompNote),

    // 事件引擎的指令集：150 条指令 / 161 个子命令 + 位打包宏
    if (hasDecomp())
      Step('L0', '事件指令集（vs C 编译器）', 'python3',
          ['extract/parse_eventscript.py', '--out', 'out/tables'],
          cwd: 'tools/pipeline', note: '150 条指令 / 161 个子命令')
    else
      Step('L0', '事件指令集', 'true', const [], skip: true, note: decompNote),

    if (hasDecomp())
      Step('L0', '事件指令集校验', 'python3',
          ['extract/verify_eventscript.py'],
          cwd: 'tools/pipeline', note: '枚举值 + `_EvtCmd` 宏展开 vs clang')
    else
      Step('L0', '事件指令集校验', 'true', const [], skip: true, note: decompNote),

    if (hasDecomp())
      Step('L0', '章节事件提取（指针归一化）', 'python3',
          ['extract/parse_chapter_events.py', '--out', 'out/tables'],
          cwd: 'tools/pipeline', note: '21 张表 / 570 个指针槽 → 符号名')
    else
      Step('L0', '章节事件提取', 'true', const [], skip: true, note: decompNote),

    // 章节单位配置：**元素个数由探针里的 `sizeof` 算**，
    // 不靠 `nm` 的地址差 —— 后者在 ELF 与 Mach-O 上取法不同
    // （实测 Linux 2629 / macOS 2796）。现在两边逐条一致，
    // 所以这一步**可以**进 CI。
    // ⚠️ **顺序要紧**：汇编里的表要先解出来，
    // `parse_unit_defs.py` 会把它们合并进 `unit_defs.json`。
    if (hasDecomp())
      Step('L0', '单位表（汇编）', 'python3',
          ['extract/parse_unit_defs_asm.py', '--out', 'out/tables'],
          cwd: 'tools/pipeline', note: 'C 里没有、只在 .s 里的 UnitDefinition')
    else
      Step('L0', '单位表（汇编）', 'true', const [], skip: true, note: decompNote),

    if (hasDecomp())
      Step('L0', '章节单位配置提取', 'python3',
          ['extract/parse_unit_defs.py', '--out', 'out/tables'],
          cwd: 'tools/pipeline',
          note: '369 张 C 表 + 37 张汇编表（编译器算长度）')
    else
      Step('L0', '章节单位配置提取', 'true', const [], skip: true, note: decompNote),

    // 章节配置：可读 C，且字段值平台无关 —— 可进 CI
    if (hasDecomp())
      Step('L0', '章节配置提取', 'python3',
          ['extract/parse_chapters.py', '--out', 'out/tables'],
          cwd: 'tools/pipeline', note: '79 章（60 有名 + 19 空槽）')
    else
      Step('L0', '章节配置提取', 'true', const [], skip: true, note: decompNote),

    if (hasDecomp())
      Step('L0', '角色编号→符号名', 'python3',
          ['extract/parse_char_names.py', '--out', 'out/tables'],
          cwd: 'tools/pipeline', note: '胜负判定要把符号名和 charIndex 对起来')
    else
      Step('L0', '角色名', 'true', const [], skip: true, note: decompNote),

    if (hasDecomp())
      Step('L0', '首领定义（死亡台词表）', 'python3',
          // 战斗/阵亡对话：**日版** carve 数组（`parse_defeat_talk.py` 是旧的
          // 美版版版本，已废弃 —— 它会把日版 JSON 覆盖成字符串格式）
          ['extract/parse_talks.py', '--out', 'out/tables'],
          cwd: 'tools/pipeline', note: 'gDefeatTalkList —— 首领的操作性定义')
    else
      Step('L0', '首领定义', 'true', const [], skip: true, note: decompNote),

    if (hasDecomp())
      Step('L0', '事件操作码→宏名', 'python3',
          ['extract/parse_event_macros.py', '--out', 'out/tables'],
          cwd: 'tools/pipeline', note: '从 eventscript.h 抽 (cmd,sub) -> 宏名')
    else
      Step('L0', '事件宏表', 'true', const [], skip: true, note: decompNote),

    if (hasDecomp())
      Step('L0', '事件脚本（汇编）', 'python3',
          ['extract/parse_event_scripts_asm.py', '--out', 'out/tables'],
          cwd: 'tools/pipeline', note: '只以 .4byte 存在的 41 个脚本（含 ONeillSpawn）')
    else
      Step('L0', '事件脚本（汇编）', 'true', const [], skip: true, note: decompNote),

    if (hasDecomp())
      Step('L0', '事件列表（胜负条件）', 'python3',
          ['extract/parse_event_lists.py', '--out', 'out/tables'],
          cwd: 'tools/pipeline', note: 'Misc 里的 FLAG 条目就是胜负条件')
    else
      Step('L0', '事件列表', 'true', const [], skip: true, note: decompNote),

    // 教学事件表：**指针数组**，`parse_event_lists.py` 只扫 `*.s` 会整批漏掉
    // （它们被去指针化成了 `.c`）。判据是序章恰好 15 条。
    if (hasDecomp())
      Step('L0', '教学事件表', 'python3',
          ['extract/parse_tutorial_lists.py', '--out', 'out/tables'],
          cwd: 'tools/pipeline', note: '序章 15 条 / Ch2 29 条（指针数组，按 counter-1 取）')
    else
      Step('L0', '教学事件表', 'true', const [], skip: true, note: decompNote),

    if (hasDecomp())
      Step('L0', '角色表 + 道具表', 'python3',
          ['extract/parse_char_item_data.py', '--out', 'out/tables'],
          cwd: 'tools/pipeline', note: 'gCharacterData / gItemData —— 战斗属性的另两半')
    else
      Step('L0', '角色/道具表', 'true', const [], skip: true, note: decompNote),

    if (hasDecomp())
      Step('L0', '文本表', 'python3',
          ['extract/parse_text.py', '--out', 'out/tables'],
          cwd: 'tools/pipeline', note: '3339 条消息 / 61 个章节标题')
    else
      Step('L0', '游戏文本', 'true', const [], skip: true, note: decompNote),
    // 章节 → 资产 → 事件组/单位表：**全程文本**（反编译项目已去指针化）
    // 场景剧情脚本：纯线性指令流，用来统计**真实 opcode 覆盖率**
    if (hasDecomp())
      Step('L0', '场景剧情脚本 + opcode 覆盖率', 'python3',
          ['extract/parse_event_scripts.py', '--out', 'out/tables'],
          cwd: 'tools/pipeline',
          note: '指令数与覆盖率由事件脚本测试断言')
    else
      Step('L0', '场景剧情脚本', 'true', const [], skip: true, note: decompNote),

    // 场景剧情：**从 C 源码直接生成 Dart**（没有 JSON 中间层）
    // ⚠️ **必须用 `--check`，不能用写模式。**
    //
    // 写模式会**静默覆盖** 438KB 的生成文件：审计实测往
    // `lib/core/event/scene_data.g.dart` 追加一行篡改内容，跑一次就
    // "恢复"了、`git status` 立刻变干净 —— 篡改无痕，而且
    // **验证过程本身在修改被 Git 跟踪的源码**（L0 架构检查看的是旧文件、
    // L3 分析看的是新文件，同一次运行内自相矛盾）。
    if (hasDecomp())
      Step('L0', '场景剧情脚本（生成 Dart，只校验不写）', 'python3',
          ['extract/gen_scene_dart.py', '--check'],
          cwd: 'tools/pipeline', note: '196 个脚本 → async 函数（直线103/分支93）')
    else
      Step('L0', '场景剧情脚本', 'true', const [], skip: true, note: decompNote),

    // 游戏文本：反编译项目已解码成纯文本，不用碰 Huffman
    // 立绘：索引色图块条 + GBA 调色板 + TSA 排列 → 可显示 PNG
    if (hasDecomp())
      Step('L0', '立绘合成', 'python3',
          ['extract/parse_portraits.py', '--out', 'out/portraits'],
          cwd: 'tools/pipeline', note: '90 个角色 / 80×72')
    else
      Step('L0', '立绘合成', 'true', const [], skip: true, note: decompNote),

    // 现成素材复制（去掉 Img_ 前缀 + 洋红转透明）
    Step('L0', '标题素材复制', 'python3',
        ['extract/copy_title_assets.py'], cwd: 'tools/pipeline',
        note: '反编译里 X.png 是合成版、Img_X.png 是裸条'),

    // 章节号 → 地图名（LOMA 的操作数是 chapterIndex）
    if (hasDecomp())
      Step('L0', '章节→地图映射', 'python3',
          ['extract/parse_chapter_maps.py'],
          cwd: 'tools/pipeline', note: 'LOMA 路由：chapterIndex → internalName → map')
    else
      Step('L0', '章节→地图映射（跳过）', 'true', const [], skip: true,
          note: decompNote),

    // 脸编号 → 角色名（表项是**可读的 C 源码**）
    if (hasDecomp())
      Step('L0', '脸编号映射', 'python3',
          ['extract/parse_face_ids.py'],
          cwd: 'tools/pipeline', note: '174 项 / 117 个有名字')
    else
      Step('L0', '脸编号映射', 'true', const [], skip: true, note: decompNote),

    if (hasDecomp())
    // 汉化：段数校验 —— **必须排在文本表生成之后**（它读 texts.json）
    Step('L0', '汉化校验', 'python3', ['i18n.py', 'verify'],
        cwd: 'tools/i18n', note: '段数不符就拒绝，不静默错版'),

    if (hasDecomp())
      Step('L0', '章节链路（资产 / 事件组）', 'python3',
          ['extract/parse_chapter_links.py', '--out', 'out/tables'],
          cwd: 'tools/pipeline', note: '79 章 → 16 个事件组（含单位表）')
    else
      Step('L0', '章节链路', 'true', const [], skip: true, note: decompNote),

    // 覆盖率账本：两张**只许降**的棘轮（未见引用的规则层 TU / 未见提及的数据目录）
    if (hasDecomp())
      Step('L0', '覆盖率棘轮', 'dart',
          ['run', 'tools/verify/coverage_report.dart', '--check'],
          note: 'docs/覆盖率.md；未覆盖数只许降（--update 收紧）')
    else
      Step('L0', '覆盖率棘轮', 'true', const [], skip: true, note: decompNote),

    if (hasDecomp())
      Step('L0', '数据表逐字节校验', 'python3',
          ['extract/verify_tables.py'],
          cwd: 'tools/pipeline', note: '表数与值总数由独立判据断言（不再靠自由文本）')
    else
      Step('L0', '数据表逐字节校验', 'true', const [], skip: true, note: decompNote),

    // 全量导出 + 逐格往返：覆盖所有能解析出资产的章节地图
    if (hasDecomp())
      Step('L0', 'TMX 全量往返', 'python3',
          ['extract/map_tmx.py', '--verify-all', '--out', 'out/tmx'],
          cwd: 'tools/pipeline', note: '52 张地图 .tmx ↔ .mar 逐格一致')
    else
      Step('L0', 'TMX 全量往返', 'true', const [], skip: true, note: decompNote),

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
      Step('L2', 'C Oracle 自检', 'true', const [], skip: true, note: decompNote),

    // 把 Dart 移植与真实 C 对上
    if (hasDecomp())
      Step('L2', 'C Oracle ↔ Dart（乱数）', 'flutter',
          ['test', 'test/core/rng_oracle_test.dart'],
          note: '161 用例逐位对照')
    else
      Step('L2', 'C Oracle ↔ Dart（乱数，跳过）', 'true', const [], skip: true,
          note: decompNote),

    if (hasDecomp())
      Step('L2', 'C Oracle ↔ Dart（战斗数值）', 'flutter',
          ['test', 'test/core/battle_oracle_test.dart'],
          note: '655 用例：战斗数值 / 特效 / 乱数消耗 / 武器三角')
    else
      Step('L2', 'C Oracle ↔ Dart（战斗数值，跳过）', 'true', const [], skip: true,
          note: decompNote),

    if (hasDecomp())
      Step('L2', 'C Oracle ↔ Dart（回合推进）', 'flutter',
          ['test', 'test/core/turn_switch_oracle_test.dart'],
          note: '47 用例：阶段顺序 / 回合数递增与 999 上限')
    else
      Step('L2', 'C Oracle ↔ Dart（回合推进，跳过）', 'true', const [], skip: true,
          note: decompNote),

    if (hasDecomp())
      Step('L2', 'C Oracle ↔ Dart（阶段与阵营）', 'flutter',
          ['test', 'test/core/phase_oracle_test.dart'],
          note: '103 用例：阵营判定 / 可行动单位计数')
    else
      Step('L2', 'C Oracle ↔ Dart（阶段与阵营，跳过）', 'true', const [], skip: true,
          note: decompNote),

    if (hasDecomp())
      Step('L2', 'C Oracle ↔ Dart（移动范围）', 'flutter',
          ['test', 'test/core/movement_oracle_test.dart'],
          note: '54 用例逐格对照')
    else
      Step('L2', 'C Oracle ↔ Dart（移动范围，跳过）', 'true', const [], skip: true,
          note: decompNote),

    // M1：全量分层分类（D19 要求未分类为 0）。分类器是代码不是表格，
    // 所以它也能进回归——改了特征或名称规则后，未分类数必须仍然是 0。
    if (hasDecomp())
      Step('L1', 'M1 分层分类（未分类须为 0）', 'python3',
          ['tools/m1/classify.py'], note: 'D19：6213 个文件全部有结论')
    else
      Step('L1', 'M1 分层分类', 'true', const [], skip: true, note: decompNote),

    // Agent 预设：工具集必须与内置 standard 逐字节一致，且派生可复现、基线未过期。
    //
    // ⚠️ 这条判据本身已**逐条证伪**（见 tools/dsh/verify_preset.py 的注释）：
    //    · 偷改一行工具配置 → 判据 A 红
    //    · 手改生成物       → 判据 B 红
    //    · 伪造基线快照     → 判据 C 红
    // 不用 `requires`：基线快照是**提交进仓库**的文件，缺了就是失败，不是跳过。
    // （DSH 应用不在时判据 C 会明确降级为警告，而不是静默通过。）
    Step('L3', 'Agent 预设（工具集 = standard）', 'python3',
        ['tools/dsh/verify_preset.py'],
        note: '源码优先预设：工具集未变 / 派生可复现 / 基线未过期'),

    // ★ 地图资源：脚本会用到的图，assets 里到底有没有。
    //
    // 两个真实事故：`chapter_maps.json` 按资产符号名建表（`CH65`）而
    // `chapters.json` 那一章叫 `'-'` → `LOMA(64)` **静默不换图**
    // （序章"王宫外"那一幕消失）；`assets/maps/` 只有 3 张图而 LOMA 目标
    // 有 40+ —— `docs/images/ch1-map.png` 被当成"第一章加载了"，
    // 而 HUD 上写的是 **PrologueMap**。
    Step('L4', '地图资源覆盖（LOMA 目标）', 'dart',
        ['run', 'tools/verify/check_map_assets.dart'],
        note: '每个 LOMA 目标都要有地图名；已打包的必须与管线产物逐字节一致'),

    // ★ 占位符棘轮：`s.placeholder(...)` 与缺失脚本**只许降不许升**。
    //
    // 12 个真 bug 里有 3 个就是这个形状（`MNC2` / `LoadUnits` / `MOVE`
    // 都是"先放个占位"，然后忘了接）。它们都不报错，只表现为"不对" ——
    // 所以"还有多少没接上"必须是一个**会自己变红的数字**。
    Step('L4', '占位符棘轮（只许降）', 'dart',
        ['run', 'tools/verify/check_placeholders.dart'],
        note: 'placeholder 调用点 / op 名 / 缺失脚本，任一变大即红'),

    // ★ 转储判据的**自检**：把一组"故意坏掉的转储"喂给检查器，
    // 要求每一条都被抓到。
    //
    // 为什么自检也算一步：本项目的铁律是「**门禁绿 ≠ 门禁有效**」
    // （R7 曾经是一条永不失败的规则）。一个只看正常转储的检查器，
    // 无法证明它真的会红 —— 这一条就是在证明它会红。
    Step('L4', '转储判据自检（判据本身会红）', 'dart',
        ['run', 'tools/verify/check_dump.dart', '--selftest'],
        note: '基准全绿 + 6 个坏转储全被抓到'),

    // 端到端场景：跑真游戏 → 转储 → 判据。
    //
    // **默认不入列**（要 macos release 构建：约 1 分钟构建 + 1 分钟场景）。
    // 用 `dart run tools/verify/run_all.dart --e2e` 显式打开。
    //
    // ⚠️ 这里刻意**不写成 `skip: true` 的占位步骤**：
    // 门禁的规则是"有跳过就不算通过"，一个默认恒跳过的步骤会让
    // 平时那条 `dart run tools/verify/run_all.dart` 永远退出 1 ——
    // 于是大家就会习惯性地加 `--allow-missing-decomp`，
    // **把"有东西没验"这件事变成背景噪音**。
    if (argv.contains('--e2e')) ...[
      Step('L4', '端到端场景（序章）', 'bash',
          ['tools/verify/scenario.sh', 'prologue'],
          note: '开机 → 序章开场 → 可玩地图；细剑/名册/渲染数/相机',
          requires: ['tools/verify/scenario.sh']),
      Step('L4', '端到端场景（王座厅取景）', 'bash',
          ['tools/verify/scenario.sh', 'throne'],
          note: '第一幕中途：地图 Ch16Map / 镜头 (96,0) / DISA / 走位',
          requires: ['tools/verify/scenario.sh']),
      // ★ **"把第一章之前做到玩得通"的核心判据**
      Step('L4', '端到端场景（序章 → 第 1 章）', 'bash',
          ['tools/verify/scenario.sh', 'battle'],
          note: '真机里打死奥尼尔 → EndingScene → MNC2(1) → Ch1Map',
          requires: ['tools/verify/scenario.sh']),
      // 地图菜单：**显示哪几条**（`MENU_NOTSHOWN` 不占行、行距 2 图块、分侧用像素）
      Step('L4', '端到端场景（地图菜单）', 'bash',
          ['tools/verify/scenario.sh', 'mapmenu'],
          note: 'START → 6 条（戦績/退却 被 MENU_NOTSHOWN 滤掉）+ 面板几何',
          requires: ['tools/verify/scenario.sh']),
      // 地图菜单里主动选「終了」= 两种回合结束里的那一种
      Step('L4', '端到端场景（菜单里选終了）', 'bash',
          ['tools/verify/scenario.sh', 'menuend'],
          note: 'START → 5×down → 确认 → 第 2 回合、菜单关闭',
          requires: ['tools/verify/scenario.sh']),
      // 两条回合结束各走一遍：菜单「終了」+ 全部行动完自动结束
      Step('L4', '端到端场景（两条回合结束）', 'bash',
          ['tools/verify/scenario.sh', 'turnend'],
          note: 'turn1 菜单終了 → turn2 两人待机自动结束 → turn3/无人"已行动"/敌我都能动',
          requires: ['tools/verify/scenario.sh']),
    ],

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

    if (s.skip) {
      stdout.writeln('  ⤼ 跳过：${s.note}');
      results.add((s, 'skip', '-'));
      skipped++;
      continue;
    }

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

  stdout.writeln('      L1 事件引擎的其余指令（已实现条数由 event_scripts_test 断言）');
  stdout.writeln('      L1 章节触发条件与剧情数据管线');
  stdout.writeln('      L4 视觉验证（技术方案 §6.5 的参考渲染器对比，'
      '可复用 lib/ui/debug_screenshot.dart 的抓帧能力）');
  if (!argv.contains('--e2e')) {
    stdout.writeln('      L4 端到端场景（`--e2e` 打开；默认不跑，'
        '所以默认的"通过 N 项"**不含**它）');
  }

  final failed = results.where((r) => r.$2 == 'fail').toList();
  final passed = results.where((r) => r.$2 == 'pass').length;

  stdout.writeln('\n${'=' * 64}');
  if (failed.isEmpty) {
    stdout.writeln('通过 $passed 项'
        '${skipped > 0 ? '，跳过 $skipped 项' : ''}');

    // ⚠️ **有跳过就不能算"通过"。**
    //
    // `third_party/` 是 gitignore 的 —— 新克隆的仓库默认没有反编译源码，
    // 于是 19 个数据管线步骤全部跳过。若这里 `return`（退出 0），
    // 门禁就会在"什么都没验"的状态下报"通过 N 项"。
    //
    // 要跳过就必须显式表态：`--allow-missing-decomp`。
    if (skipped > 0) {
      if (allowMissingDecomp) {
        stdout.writeln('（已用 --allow-missing-decomp 放行）');
        return;
      }
      stderr.writeln('\n✗ 有 $skipped 项被跳过 —— **不算通过**。');
      stderr.writeln('  最常见原因：$decompNote');
      stderr.writeln('  确认环境无法提供时，显式加 --allow-missing-decomp。');
      exit(1);
    }
    return;
  }
  stdout.writeln('失败 ${failed.length} 项（通过 $passed，跳过 $skipped）：');
  for (final f in failed) {
    stdout.writeln('  ✗ [${f.$1.layer}] ${f.$1.name}');
  }
  exit(1);
}
