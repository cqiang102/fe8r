// 状态转储的**断言集** —— 把"看图"换成"读数据 + 判据"。
//
// ## 用法
//
//     dart run tools/verify/check_dump.dart <dump.json> [--scenario prologue]
//     dart run tools/verify/check_dump.dart --selftest
//
// ## 为什么需要它
//
// 用户说过：**「开场链路、序章剧情、序章战斗都还有 bug」**。
// 而这三件事当时的"证据"都是**一张截图** —— 截图只证明那一刻那一帧，
// 证明不了"这条链路"。这份检查器把可观测的事实变成可断言的数据：
//
//     unitIdsUnique        单位编号唯一（id 撞车那次就是这条）
//     render.matches       渲染出的单位组件数 == 存活单位数（幽灵精灵）
//     items.length == 5    `UNIT_ITEM_COUNT`（道具栏被当成 1 元素表那次）
//     坐标在地图内          位域解码错了这里会露出来
//     camera 在地图内       相机越界 / 计算错
//     场景/剧情状态         脚本跑到哪、有没有缺东西
//
// ## `--selftest` 是**必须**的
//
// 本项目有一条铁律：**门禁绿 ≠ 门禁有效**（R7 曾经是一条永不失败的规则）。
// 所以这个检查器自带一组"故意坏掉的转储"，要求**每一条都必须被抓到**。
// 只跑正常转储不算验证过。
import 'dart:convert';
import 'dart:io';

/// 一条判据的结论
class Finding {
  Finding(this.ok, this.name, this.detail);

  final bool ok;
  final String name;
  final String detail;
}

List<Finding> check(Map<String, dynamic> d, {String? scenario}) {
  final out = <Finding>[];
  void ok(bool cond, String name, String detail) =>
      out.add(Finding(cond, name, detail));

  final units = (d['units'] as List? ?? const [])
      .cast<Map<String, dynamic>>()
      .toList();
  final alive = units.where((u) => u['alive'] == true).toList();
  final map = d['map'] as Map<String, dynamic>?;

  // ---- 1) 单位编号唯一 ----
  final ids = units.map((u) => u['id']).toList();
  ok(ids.toSet().length == ids.length, '单位编号唯一',
      '${ids.length} 个单位 / ${ids.toSet().length} 个不同编号');

  // ---- 2) 渲染与规则层一致 ----
  final render = d['render'] as Map<String, dynamic>?;
  if (render == null) {
    ok(false, '渲染计数存在', '转储里没有 render（版本太旧？）');
  } else {
    ok(render['matches'] == true, '渲染组件数 == 存活单位数',
        'unitComponents=${render['unitComponents']} alive=${render['aliveUnits']}');
    // 这一条抓的是"指标本身在撒谎"：总数把光标/标记也算进去
    final total = render['total'] as int?;
    final parts = (render['unitComponents'] as int? ?? 0) +
        (render['markerComponents'] as int? ?? 0) +
        (render['cursorComponents'] as int? ?? 0);
    ok(total == parts, '渲染计数分类自洽',
        'total=$total, 分类之和=$parts');
  }

  // ---- 3) 道具栏是 UNIT_ITEM_COUNT（5）槽 ----
  final badSlots = alive
      .where((u) => ((u['items'] as List?)?.length ?? -1) != 5)
      .map((u) => '${u['name']}#${u['id']}='
          '${(u['items'] as List?)?.length}')
      .toList();
  ok(badSlots.isEmpty, '道具栏 5 槽（UNIT_ITEM_COUNT）',
      badSlots.isEmpty ? '全部 ${alive.length} 个存活单位' : '异常：$badSlots');

  // ---- 4) 坐标落在地图内 ----
  if (map != null) {
    final w = map['width'] as int? ?? 0;
    final h = map['height'] as int? ?? 0;
    final oob = alive
        .where((u) =>
            (u['x'] as int) < 0 ||
            (u['x'] as int) >= w ||
            (u['y'] as int) < 0 ||
            (u['y'] as int) >= h)
        .map((u) => '${u['name']}(${u['x']},${u['y']})')
        .toList();
    ok(oob.isEmpty, '单位坐标在地图内',
        oob.isEmpty ? '$w×$h' : '越界：$oob');

    // ---- 5) 相机夹在地图内（视口 240×160，格 16 像素）----
    final cam = d['camera'] as Map<String, dynamic>?;
    if (cam != null) {
      final maxX = (w * 16 - 240).clamp(0, 1 << 30);
      final maxY = (h * 16 - 160).clamp(0, 1 << 30);
      final cx = (cam['x'] as num).toDouble();
      final cy = (cam['y'] as num).toDouble();
      ok(cx >= 0 && cx <= maxX && cy >= 0 && cy <= maxY, '相机在地图内',
          'camera=($cx,$cy) 允许 [0,$maxX]×[0,$maxY]');
    }
  }

  // ---- 6) 场景状态自洽 ----
  final scene = d['scene'] as Map<String, dynamic>?;
  if (scene != null) {
    if (scene['showDialogue'] == true) {
      ok(scene['currentTextId'] != null, '显示对白时必须有文本 id',
          'currentTextId=${scene['currentTextId']}');
    }
    ok((scene['hudExtra'] as String? ?? '').length < 500, '诊断串没有失控增长',
        'len=${(scene['hudExtra'] as String? ?? '').length}');
  }

  // ---- 7) 场景专属判据 ----
  //
  // `throne`：序章第一幕**演到一半**停下来看取景。
  //
  // 判据是"镜头在脚本要的位置上"，来自两处源码：
  //   * `LOMA(0x10)` 把相机居中到槽 0xB 的 (14,10) → y = 160-80 = 80
  //   * `CAMERA(0xE, 0)` 再把镜头压到 (14,0) → `GetCameraAdjustedY` → y = 0
  // `CAMERA` 曾经是占位符，所以 y 一直是 80（停在地图中央）。
  if (scenario == 'throne') {
    ok(map?['id'] == 'Ch16Map', '王座厅：地图是 Ch16Map', 'map.id=${map?['id']}');
    final cam = d['camera'] as Map<String, dynamic>?;
    final cy = (cam?['y'] as num?)?.toDouble();
    final cx = (cam?['x'] as num?)?.toDouble();
    ok(cy == 0, '王座厅：镜头压在 y=0（`CAMERA(14, 0)` 生效）', 'camera=($cx,$cy)');
    ok(cx == 96, '王座厅：x 在死区内不动（96）', 'camera=($cx,$cy)');

    // ★ `DISA` / `MOVEONTO` / `MOVE_1STEP` 真的生效了吗？
    //
    // 出处 `EventScr_Prologue_RenaisThroneCutscene`（走位顺序）：
    //   CURSOR_CHAR(0xF=艾夫拉姆) → Text(0x8C3)
    //   MOVE(0, 15, 13, 11)  传令兵走到 (13,11)  → DISA(15)   他消失
    //   MOVE_1STEP(0, 1, FACING_LEFT)  艾莉卡往左一格
    //   MOVEONTO(0, 2, 1)   赛特走到**艾莉卡那一格** → DISA(1)  她被抱走
    //
    // ⚠️ 这三个以前全是坏的：`DISA` 是占位符（人不会消失），
    // `MOVE_1STEP`/`MOVEONTO` 被当成 (speed,pid,x,y) 读（走到错误的格子）。
    final names = alive.map((u) => u['charIndex']).toList();
    ok(!names.contains(15), '王座厅：传令兵（艾夫拉姆 15）已 DISA 离场',
        'alive=$names');
    ok(!names.contains(1), '王座厅：艾莉卡（1）已被赛特抱走（DISA）',
        'alive=$names');
    // 赛特应该站在**艾莉卡此刻**的格子上。
    //
    // ⚠️ 不是她一开始的 (14,4)：脚本前面还有一条
    // `MOVE_1STEP(0, 1, FACING_LEFT)` —— 她先往左走到 (13,4)，
    // 赛特再 `MOVEONTO` 过去。**我第一版把预期写成 (14,4)，红了一次**；
    // 那个红恰好同时证明了两条指令都生效（左移 + 踩到目标格）。
    final seth = alive.where((u) => u['charIndex'] == 2).firstOrNull;
    ok(seth != null && seth['x'] == 13 && seth['y'] == 4,
        '王座厅：赛特站在艾莉卡走到的 (13,4)（MOVE_1STEP + MOVEONTO 生效）',
        'charIndex=2 at (${seth?['x']},${seth?['y']})');
    // ⚠️ 不要去查 `trace`：它是**最近 12 条**的环形缓冲，
    // 而 `CAMERA` 发生在这一场很靠前的地方，早被挤出去了。
    // （第一版我在这里断言轨迹里有 CameraControl —— 那是错的判据。）
  }

  if (scenario == 'prologue') {
    ok(map?['id'] == 'PrologueMap', '序章：地图是 PrologueMap',
        'map.id=${map?['id']}');

    // ★ **序章是"三张图、三段剧情"** —— 用户原话：
    //   「卫兵向国王报告的背景地图应该是王宫里，等等一波剧情，
    //     还有王宫外的场景，再后面才到序章的游玩场景地图」
    //
    // 出处：`EventScr_Prologue_RenaisThroneCutscene` 的三次 LOMA
    //   LOMA(0x10=16) → Ch16Map         （王座厅 / 城堡内景）
    //   LOMA(0x40=64) → RenaisCastleMap （Renais 城）
    //   LOMA(0)       → PrologueMap     （可玩地图）
    //
    // ⚠️ 这一条能抓到一个真 bug：`chapter_maps.json` 是按**资产符号名**
    // 建的表（那一章叫 `CH65`），而 `chapters.json` 里它是 `'-'` ——
    // `LOMA(64)` 因此**静默不换图**，第二幕整段消失。
    final history = d['mapHistory'] as String? ?? '';
    for (final m in const ['Ch16Map', 'RenaisCastleMap', 'PrologueMap']) {
      ok(history.contains(m), '序章：地图历史里有 $m', 'history=$history');
    }
    final fails = (d['mapLoadFailures'] as List?) ?? const [];
    ok(fails.isEmpty, '序章：没有 LOMA 失败', 'failures=$fails');

    // `UnitDef_Event_PrologueAlly` = 赛特(charIndex 2) + 艾莉卡(charIndex 1)
    // `UnitDef_Event_PrologueEnemy` = 奥尼尔(104) + 两个杂兵(130/128)
    final blue = alive.where((u) => u['faction'] == 0).toList();
    final red = alive.where((u) => u['faction'] == 0x80).toList();
    ok(blue.length == 2, '序章：我方 2 人', 'blue=${blue.map((u) => u['name'])}');
    ok(red.length == 3, '序章：敌方 3 人', 'red=${red.map((u) => u['name'])}');

    // ★ 「艾莉卡拿不到细剑」那条 bug 的直接判据。
    // `EventScr_Prologue_GiveRapier`：`SVAL(3, ITEM_SWORD_RAPIER)` +
    // `GIVEITEMTO(CHARACTER_EIRIKA)`（`CHARACTER_EIRIKA = 1`）
    final eirika = alive.where((u) => u['charIndex'] == 1).firstOrNull;
    final held = ((eirika?['held'] as List?) ?? const []).cast<int>();
    final idx = held.map((i) => i & 0xFF).toList();
    ok(idx.contains(9), '序章：艾莉卡拿到了细剑（9）',
        'charIndex=1 持有 $idx（${eirika?['itemNames']}）');

    // 赛特的 3 件（`UnitDef_Event_PrologueAlly`: items = {0x03,0x17,0x6C,0}）
    final seth = alive.where((u) => u['charIndex'] == 2).firstOrNull;
    final sethIdx =
        ((seth?['held'] as List?) ?? const []).cast<int>().map((i) => i & 0xFF);
    ok(sethIdx.length == 3, '序章：赛特带着 3 件道具',
        'charIndex=2 持有 ${sethIdx.toList()}');

    // 900 个 confirm 之后，序章开场应该**演完了**
    ok(scene?['running'] == false, '序章：开场脚本已经跑完',
        'running=${scene?['running']} script=${scene?['script']}');
  }

  return out;
}

// ---------------------------------------------------------------- selftest

/// 故意坏掉的转储 —— 每一条**都必须**被 `check` 抓到。
///
/// 这一组就是"门禁真的会红"的证据：如果某条判据永远为真，
/// 这里就会失败，而不是安静地绿着。
Map<String, Map<String, dynamic>> brokenDumps() {
  Map<String, dynamic> base() =>
      jsonDecode(jsonEncode(goodDump())) as Map<String, dynamic>;

  final out = <String, Map<String, dynamic>>{};

  out['id 撞车'] = base()
    ..['units'] = [
      {
        'id': 7,
        'name': 'A',
        'charIndex': 1,
        'faction': 0,
        'x': 1,
        'y': 1,
        'alive': true,
        'items': <int>[0, 0, 0, 0, 0],
        'held': <int>[],
        'itemNames': <String>[],
      },
      {
        'id': 7,
        'name': 'B',
        'charIndex': 2,
        'faction': 0,
        'x': 2,
        'y': 1,
        'alive': true,
        'items': <int>[0, 0, 0, 0, 0],
        'held': <int>[],
        'itemNames': <String>[],
      },
    ];

  out['道具栏只有 1 槽'] = base()
    ..['units'] = [
      {
        'id': 1,
        'name': 'EIRIKA',
        'charIndex': 1,
        'faction': 0,
        'x': 1,
        'y': 1,
        'alive': true,
        'items': [108],
        'held': [108],
        'itemNames': ['VULNERARY'],
      },
    ];

  out['渲染数对不上'] = base()
    ..['render'] = {
      'unitComponents': 4,
      'markerComponents': 0,
      'cursorComponents': 1,
      'total': 5,
      'aliveUnits': 5,
      'matches': false,
    };

  out['坐标越界'] = base()
    ..['units'] = [
      {
        'id': 1,
        'name': 'X',
        'charIndex': 1,
        'faction': 0,
        'x': 99,
        'y': 1,
        'alive': true,
        'items': <int>[0, 0, 0, 0, 0],
        'held': <int>[],
        'itemNames': <String>[],
      },
    ];

  out['相机越界'] = base()
    ..['camera'] = {'x': 9999.0, 'y': 0.0};

  out['序章少了「王宫外」那张图'] = base()
    ..['mapHistory'] = 'Ch16Map PrologueMap';

  out['序章有 LOMA 失败'] = base()
    ..['mapLoadFailures'] = ['LOMA(64) → 章节表里没有地图名'];

  out['序章没拿到细剑'] = base()
    ..['units'] = [
      {
        'id': 1,
        'name': 'EIRIKA',
        'charIndex': 1,
        'faction': 0,
        'x': 4,
        'y': 5,
        'alive': true,
        'items': [108, 0, 0, 0, 0],
        'held': [108],
        'itemNames': ['VULNERARY'],
      },
      {
        'id': 2,
        'name': 'SETH',
        'charIndex': 2,
        'faction': 0,
        'x': 4,
        'y': 4,
        'alive': true,
        'items': <int>[0, 0, 0, 0, 0],
        'held': <int>[],
        'itemNames': <String>[],
      },
      for (var i = 0; i < 3; i++)
        {
          'id': 10 + i,
          'name': 'E$i',
          'charIndex': 100 + i,
          'faction': 0x80,
          'x': 14,
          'y': 7,
          'alive': true,
          'items': <int>[0, 0, 0, 0, 0],
          'held': <int>[],
          'itemNames': <String>[],
        },
    ];

  return out;
}

/// 一份**正常**的序章转储（selftest 的基准）
Map<String, dynamic> goodDump() => {
      'chapter': 0,
      'map': {'width': 15, 'height': 10, 'id': 'PrologueMap'},
      'camera': {'x': 0.0, 'y': 0.0},
      'units': [
        {
          'id': 1,
          'name': 'SETH',
          'charIndex': 2,
          'faction': 0,
          'x': 4,
          'y': 4,
          'alive': true,
          'items': [(30 << 8) | 3, (20 << 8) | 0x17, (3 << 8) | 0x6C, 0, 0],
          'held': [(30 << 8) | 3, (20 << 8) | 0x17, (3 << 8) | 0x6C],
          'itemNames': ['SWORD_STEEL', '?23', 'VULNERARY'],
        },
        {
          'id': 2,
          'name': 'EIRIKA',
          'charIndex': 1,
          'faction': 0,
          'x': 4,
          'y': 5,
          'alive': true,
          'items': [(3 << 8) | 0x6C, (40 << 8) | 9, 0, 0, 0],
          'held': [(3 << 8) | 0x6C, (40 << 8) | 9],
          'itemNames': ['VULNERARY', 'SWORD_RAPIER'],
        },
        for (var i = 0; i < 3; i++)
          {
            'id': 10 + i,
            'name': 'E$i',
            'charIndex': 104 + i,
            'faction': 0x80,
            'x': 14,
            'y': 7,
            'alive': true,
            'items': [(45 << 8) | 31, 0, 0, 0, 0],
            'held': [(45 << 8) | 31],
            'itemNames': ['AXE_IRON'],
          },
      ],
      'unitIdsUnique': true,
      'render': {
        'unitComponents': 5,
        'markerComponents': 0,
        'cursorComponents': 1,
        'total': 6,
        'aliveUnits': 5,
        'matches': true,
      },
      'scene': {
        'running': false,
        'objectiveRunning': false,
        'showDialogue': false,
        'script': '',
        'shown': 46,
        'currentTextId': null,
        'hudExtra': '载入 UnitDef_Event_PrologueEnemy（3 个单位）',
        'slots': {'3': '9'},
        'missing': <String>[],
        'placeholders': <String>[],
      },
      'mapHistory': 'Ch16Map RenaisCastleMap PrologueMap',
      'mapLoadFailures': <String>[],
    };

int runSelfTest() {
  var bad = 0;

  // ① 基准必须是**全绿**的 —— 否则下面的"抓到"毫无意义
  final baseFindings = check(goodDump(), scenario: 'prologue');
  final baseFailed = baseFindings.where((f) => !f.ok).toList();
  if (baseFailed.isNotEmpty) {
    stderr.writeln('✗ selftest 基准转储本身就不通过：');
    for (final f in baseFailed) {
      stderr.writeln('    ${f.name}: ${f.detail}');
    }
    bad++;
  } else {
    stdout.writeln('  ✓ 基准转储全绿（${baseFindings.length} 条判据）');
  }

  // ② 每一个坏转储都必须**至少有一条判据红**
  for (final e in brokenDumps().entries) {
    final f = check(e.value, scenario: 'prologue');
    final failed = f.where((x) => !x.ok).toList();
    if (failed.isEmpty) {
      stderr.writeln('✗ 「${e.key}」没有被任何判据抓到 —— 判据是死的');
      bad++;
    } else {
      stdout.writeln('  ✓ 「${e.key}」被抓到：${failed.first.name}');
    }
  }

  if (bad > 0) {
    stderr.writeln('✗ selftest 失败 $bad 项');
    return 1;
  }
  stdout.writeln('判据自检通过：基准全绿 + ${brokenDumps().length} 个坏转储全被抓到');
  return 0;
}

void main(List<String> argv) {
  if (argv.contains('--selftest')) {
    exit(runSelfTest());
  }

  final path = argv.firstWhere((a) => !a.startsWith('--'), orElse: () => '');
  if (path.isEmpty) {
    stderr.writeln('用法：check_dump.dart <dump.json> [--scenario prologue]');
    exit(2);
  }
  final scenario = argv.contains('--scenario')
      ? argv[argv.indexOf('--scenario') + 1]
      : null;

  final f = File(path);
  if (!f.existsSync()) {
    stderr.writeln('✗ 找不到转储 $path');
    exit(1);
  }

  final Map<String, dynamic> d;
  try {
    d = jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
  } catch (e) {
    stderr.writeln('✗ 转储不是合法 JSON：$e');
    exit(1);
  }

  final findings = check(d, scenario: scenario);
  final failed = findings.where((x) => !x.ok).toList();

  for (final x in findings) {
    stdout.writeln('  ${x.ok ? '✓' : '✗'} ${x.name}  — ${x.detail}');
  }
  if (failed.isEmpty) {
    stdout.writeln('转储判据：全部通过（${findings.length} 条）');
    return;
  }
  stderr.writeln('转储判据：${failed.length} 条失败');
  exit(1);
}
