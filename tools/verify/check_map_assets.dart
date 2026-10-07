// 「脚本要用的地图，assets 里到底有没有」—— 覆盖 + 漂移检查。
//
// ## 为什么需要
//
// 上一轮的真实事故（两处叠在一起）：
//
// 1. `chapter_maps.json` 是按**资产符号名**建的（`CH64` / `CH65`），
//    而 `chapters.json` 里那些章的 `internalName` 是 `'-'` ——
//    `LOMA(64)` 因此**静默不换图**，序章的"王宫外"那一幕直接消失。
//    脚本里 46 个 LOMA 目标里有 **11 个**受影响。
// 2. `assets/maps/` 里只有 3 张图（PrologueMap / Ch16Map / GradoCastleMap），
//    而 `LOMA` 的目标有 40+ 张 —— 缺图时 `_loadChapterMap` 只写了一句 HUD，
//    转储里"地图历史"看起来还是完整的。
//
// 后果里最典型的一个：`docs/images/ch1-map.png` 被当成"第一章地图加载了"，
// 而 HUD 上明明白白写着 **PrologueMap** —— 图根本没换。
//
// ## 判据
//
// 1. 生成脚本里每个 `s.loadMap(N)` 的 N 都要能在 `chapter_maps.json.byIndex`
//    里查到地图名（查不到 = LOMA 会静默失败）
// 2. 已经打包的图必须与 `tools/pipeline/out/tmx/` 的产物**逐字节相同**
//    （漂移 = 素材和管线不是同一版）
// 3. **棘轮**：查不到地图名的目标、以及还没打包的图，各自记进基线文件，
//    只许变好不许变差 —— 这样"还没做的工作"不会假装完成，
//    但也确实挡住了"又多一处静默失败"。
import 'dart:convert';
import 'dart:io';

const String generated = 'lib/core/event/scene_data.g.dart';
const String chapterMaps = 'tools/pipeline/out/tables/chapter_maps.json';
const String tmxSrc = 'tools/pipeline/out/tmx';
const String assetDir = 'assets/maps';

/// 生成脚本里用到的所有 `LOMA` 目标
Set<int> lomaTargets(String src) => {
      for (final m in RegExp(r's\.loadMap\((\d+)\)').allMatches(src))
        int.parse(m.group(1)!),
    };

/// `Event25_ChangeMap`：`short chIndex`，负数 → 用槽 2
/// （`LOMA(0xFFFF)` 就是这条路）。这里只做"是不是有效章节号"的判断。
int signedChapter(int operand) {
  final u16 = operand & 0xFFFF;
  return u16 >= 0x8000 ? u16 - 0x10000 : u16;
}

const String baselinePath = 'tools/verify/map_asset_baseline.json';

int main(List<String> argv) {
  final update = argv.contains('--update');
  final src = File(generated).readAsStringSync();
  final byIndex = (jsonDecode(File(chapterMaps).readAsStringSync())
      as Map<String, dynamic>)['byIndex'] as Map<String, dynamic>;

  final targets = lomaTargets(src);
  var bad = 0;

  // ---- 1) 每个 LOMA 目标都要能解析出地图名 ----
  final names = <String>{};
  final unresolved = <int>[];
  var negative = 0;
  for (final t in targets) {
    if (signedChapter(t) < 0) {
      negative++; // 负数 = 用槽 2，运行期才知道；这里只统计
      continue;
    }
    final v = byIndex['$t'];
    if (v == null) {
      unresolved.add(t);
      continue;
    }
    final n = (v as Map<String, dynamic>)['map'] as String;
    // `?` = 资产表里这个下标**反查不到符号名**（未 carve）——
    // 和"查不到章节"一样是静默失败，所以并列统计
    if (n == '?') {
      unresolved.add(t);
      continue;
    }
    names.add(n);
  }
  final base = File(baselinePath).existsSync()
      ? (jsonDecode(File(baselinePath).readAsStringSync())
          as Map<String, dynamic>)
      : <String, dynamic>{};
  final allowedUnresolved = ((base['unresolvedIndices'] as List?) ?? const [])
      .cast<int>()
      .toSet();
  final newUnresolved =
      unresolved.where((i) => !allowedUnresolved.contains(i)).toList();
  if (newUnresolved.isEmpty) {
    stdout.writeln('  ✓ LOMA 目标没有新增"查不到地图名"的情况'
        '（${targets.length} 个目标，其中 ${unresolved.length} 个是已知缺口、'
        '$negative 个是"用槽 2"的负数形式）');
  } else {
    stderr.writeln('  ✗ **新增** ${newUnresolved.length} 个查不到地图名的 LOMA 目标：'
        '$newUnresolved —— 这些 LOMA 会静默不换图');
    bad++;
  }

  // ---- 2) 已打包的图必须与管线产物逐字节相同 ----
  var bundled = 0, missing = 0, drifted = 0;
  final missingNames = <String>[];
  for (final n in names) {
    final a = File('$assetDir/$n.tmx');
    if (!a.existsSync()) {
      missing++;
      missingNames.add(n);
      continue;
    }
    bundled++;
    final b = File('$tmxSrc/$n.tmx');
    if (!b.existsSync()) {
      stderr.writeln('  ✗ $n：assets 里有，但管线产物 $tmxSrc/$n.tmx 没有');
      bad++;
      continue;
    }
    if (!_sameBytes(a, b)) {
      stderr.writeln('  ✗ $n：assets/maps 与 out/tmx **不一致**（素材漂移）');
      drifted++;
      bad++;
    }
    // 同名 .json / .metatiles.png 也要在
    for (final ext in const ['json', 'metatiles.png']) {
      final aa = File('$assetDir/$n.$ext');
      if (!aa.existsSync()) {
        stderr.writeln('  ✗ $n：缺 $assetDir/$n.$ext（TMX 会加载失败）');
        bad++;
      }
    }
  }
  if (bad == 0 || drifted == 0) {
    stdout.writeln('  ✓ 已打包 $bundled 张，与 out/tmx 逐字节一致');
  }

  // ---- 3) 缺的图：棘轮（只许变少） ----
  final baseMissing = (base['unbundledCount'] as int?) ?? 1 << 30;
  if (missing > baseMissing) {
    stderr.writeln('  ✗ 缺图从 $baseMissing 涨到 $missing —— '
        '脚本用的图变多而没打包（会静默不换图）');
    bad++;
  }
  if (missing > 0) {
    stdout.writeln('  · 还没打包的图 $missing 张（脚本会用到的）：'
        '${missingNames.take(10).toList()}'
        '${missing > 10 ? ' …' : ''}');
    stdout.writeln('    打包方式：cp tools/pipeline/out/tmx/<名>.{tmx,json,metatiles.png} '
        'assets/maps/');
  }

  if (update) {
    File(baselinePath).writeAsStringSync(
        '${const JsonEncoder.withIndent(' ').convert({
              'note': '已知缺口基线：只许变好（见 check_map_assets.dart）',
              'unresolvedIndices': unresolved.toList()..sort(),
              'unbundledCount': missing,
            })}\n');
    stdout.writeln('✓ 基线已更新：查不到地图名 $unresolved / 缺图 $missing');
    return 0;
  }

  if (bad > 0) {
    stderr.writeln('地图资源检查：失败 $bad 项');
    return 1;
  }
  stdout.writeln('地图资源检查：通过');
  return 0;
}

bool _sameBytes(File a, File b) {
  final x = a.readAsBytesSync(), y = b.readAsBytesSync();
  if (x.length != y.length) return false;
  for (var i = 0; i < x.length; i++) {
    if (x[i] != y[i]) return false;
  }
  return true;
}
