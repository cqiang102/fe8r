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

  // `battle`：**序章 → 第 1 章** 的端到端判据。
  //
  // 这是整个"把第一章之前做到玩得通"最关键的一条：它证明
  //   打死首领 → 置 `EVFLAG_DEFEAT_BOSS` → 命中 `EventScr_Prologue_EndingScene`
  //   → `MNC2(1)` → **真的换到了第 1 章的地图**
  // 这条链在真实对局里跑通，而不是只在单元测试里。
  if (scenario == 'battle') {
    ok(d['chapter'] == 1, '切到了第 1 章（chapter 字段）', 'chapter=${d['chapter']}');
    ok(map?['id'] == 'Ch1Map', '地图是 Ch1Map', 'map.id=${map?['id']}');
    final hist = d['mapHistory'] as String? ?? '';
    ok(hist.contains('Ch1Map'), '地图历史里出现 Ch1Map', 'history=$hist');
    ok(d['objectiveHit'] == 'EventScr_Prologue_EndingScene',
        '命中的是序章结束脚本', 'objectiveHit=${d['objectiveHit']}');
    ok(((d['mapLoadFailures'] as List?) ?? const []).isEmpty,
        '没有 LOMA 失败', 'failures=${d['mapLoadFailures']}');
    // 到了第 1 章要有单位（换图会清空战场，随后脚本 LOAD1）
    ok(alive.isNotEmpty, '第 1 章场上有单位', 'alive=${alive.length}');
  }

  // `mapmenu`：START 打开地图菜单 —— **"显示哪几条"** 的端到端判据。
  //
  // 这一组证的是源码里那三条可见性结论（都不是"我摆的"）：
  //   * `MapMenu_IsRecordsCommandAvailable`（`src/MapMenu_IsRecordsCommandAvailable.c:53`）
  //     故事章节 → `MENU_NOTSHOWN` ⇒ 「戦績」**不占行**
  //   * `MapMenu_IsRetreatCommandAvailable`（`src/bmmenu_08024C7C.c:62`）
  //     `BATTLEMAP_KIND_STORY` → `MENU_NOTSHOWN` ⇒ 「退却」**不占行**
  //   * `StartMenuCore`（`src/StartMenuCore.c:61-72,92-98`）
  //     ⇒ 行距 2 个 UI 图块、面板高 = 2*行数 + 2
  //
  // ⚠️ 场景默认难度是 `Difficulty.normal` → `config.controller = 1` → 教学模式
  // → 序章那句 `ASMC(BmGuideTextSetAllGreen)` 会执行 → 辞书**显示**。
  // 这也是"教学模式"这条链第一次在真机上被验。
  if (scenario == 'mapmenu' || scenario == 'menuend') {
    final mm = d['mapMenu'] as Map<String, dynamic>?;
    final inputs = d['mapMenuInputs'] as Map<String, dynamic>?;

    if (scenario == 'menuend') {
      // 主动选「終了」→ 我方阶段结束、回合数 +1、菜单关闭
      ok(d['turn'] == 2, '菜单里选「終了」后进到第 2 回合', 'turn=${d['turn']}');
      ok(mm == null, '选完菜单就关了', 'mapMenu=$mm');
      ok((d['mapMenuNote'] as String? ?? '').contains('終了'),
          '记录里写着是「終了」', 'note=${d['mapMenuNote']}');
      return out;
    }

    ok(map?['id'] == 'PrologueMap', '地图菜单：在序章可玩地图上',
        'map.id=${map?['id']}');
    ok(mm != null, '地图菜单打开了（START）', 'mapMenu=$mm');
    if (mm == null) return out;

    final items = (mm['items'] as List? ?? const []).cast<String>().toList();
    ok(items.length == 6, '菜单是 6 条（8 条里 2 条 MENU_NOTSHOWN）',
        'items=$items');
    ok(!items.any((s) => s.contains('退却')), '「退却」不显示（故事章节）',
        'items=$items');
    ok(!items.any((s) => s.contains('戦績')), '「戦績」不显示（不是迷宫）',
        'items=$items');
    ok(items.join(',') == '部隊,状況,辞書,設定,中断,終了',
        '顺序 = 源码数组顺序（滤掉隐藏项之后）', 'items=$items');

    final layout = mm['layout'] as Map<String, dynamic>?;
    ok(layout?['h'] == 14, '面板高 = 2*6 + 2 = 14 个 UI 图块', 'layout=$layout');
    ok(layout?['rowPitch'] == 2, '行距是 2 个 UI 图块（`yTileInner += 2`）',
        'rowPitch=${layout?['rowPitch']}');
    // ★ 左右分侧用的是**光标的屏幕像素**（`src/exact_0804f924.c:49` 的 `120`；
    //   调用点传的是 `gBmSt.cursorTarget.x - gBmSt.camera.x`，
    //   `src/playerphase_0801C5A8.c:110`）。地图一格 16px
    //   （`lib/core/map/camera.dart` 的 `tilePx`）。
    //
    //   这一条**能抓到"拿图块坐标去比 120"那个 bug**：那时光标在 x=14
    //   会被算成 `14 < 120` → 0x17，而真值是 `224 >= 120` → 1。
    //   判据两边是**独立的数据**：cursor/camera 来自规则层，x 来自菜单几何。
    final cur = d['cursor'] as Map<String, dynamic>?;
    final cam = d['camera'] as Map<String, dynamic>?;
    final screenPx = ((cur?['x'] as num?)?.toDouble() ?? 0) * 16 -
        ((cam?['x'] as num?)?.toDouble() ?? 0);
    final wantX = screenPx < 120 ? 0x17 : 1;
    ok(layout?['x'] == wantX,
        '分侧 = 光标屏幕像素 < 120 ? 0x17 : 1（这里是 ${screenPx.toInt()} px）',
        'x=${layout?['x']} want=$wantX cursor=${cur?['x']} camera=${cam?['x']}');
    ok(layout?['w'] == 6, '面板宽 6 个 UI 图块（`gMapMenuDef.rect.w`）',
        'w=${layout?['w']}');

    ok(inputs?['battleMapKind'] == 'story', '输入的 kind 是 story',
        'inputs=$inputs');
    ok(inputs?['difficulty'] == 'normal', '默认难度 normal → 教学模式',
        'difficulty=${inputs?['difficulty']}');
    ok(inputs?['tutorial'] == false, 'PLAY_FLAG_TUTORIAL = 0（这条链上没人置它）',
        'tutorial=${inputs?['tutorial']}');
    ok(inputs?['guideLocked'] == false, '教学模式 ⇒ 辞书没锁',
        'guideLocked=${inputs?['guideLocked']}');
    final hidden =
        (inputs?['hidden'] as List? ?? const []).cast<String>().toList();
    ok(hidden.length == 2 && hidden.any((s) => s.startsWith('戦績')),
        '隐藏的两条就是 戦績/退却，且带着源码函数名', 'hidden=$hidden');
    ok(((d['mapMenuUnimplemented'] as List?) ?? const []).isEmpty,
        '没选中任何"未实现"的条目', 'unimplemented=${d['mapMenuUnimplemented']}');
  }

  // `turnend`：**两条回合结束**各走一遍之后的裁决状态。
  //
  // 用户报"回合终了和我方全部行动完成结束有 bug"。
  // 这两条路在原作里最终都汇到同一处（结束 `gProcScr_PlayerPhase`）：
  //   * 主动：`CommandEffectEndPlayerPhase` → `Proc_EndEach(gProcScr_PlayerPhase)`
  //           （`src/bmmenu_080225C4.c:61-65`）
  //   * 自动：`PlayerPhase_HandleAutoEnd` → `Proc_Goto(proc, 3)`，而 label 3 就是
  //           `PROC_WHILE(DoesBMXFADEExist); PROC_END`
  //           （`src/playerphase_0801D808.c:52` + `dat_ProcScr_uistuff148_ref.c:318-320`）
  //
  // 之后由父 proc 调 `BmMain_ChangePhase`（`src/bm_08015434.c:82-95`）：
  //   清**当前**阵营的灰化 → `SwitchPhases`（**离开 GREEN 时回合 +1**，
  //   `src/bm_080153B0.c:88-93`）→ `RunPhaseSwitchEvents`
  //
  // 所以判据是四条：回合数 +1、回到我方、我方**所有人都能再动**、敌方也能动。
  if (scenario == 'turnend') {
    ok(d['turn'] == 3, '两次结束（一次菜单、一次自动）后是第 3 回合',
        'turn=${d['turn']}');
    ok(d['activeFaction'] == 0, '回到我方（FACTION_BLUE = 0）',
        'activeFaction=${d['activeFaction']}');
    ok(d['phase'] == 'freeCursor', '停在我方自由光标', 'phase=${d['phase']}');

    final able = d['phaseAble'] as Map<String, dynamic>?;
    ok(able?['blue'] == 2, '我方 2 个单位都能动（`GetPhaseAbleUnitCount`）',
        'phaseAble=$able');
    ok(able?['red'] == 3, '敌方 3 个也能动（红方灰化也清了）', 'phaseAble=$able');

    // ★ 这条才是"两条路有没有差别"的核心：
    //   `ClearActiveFactionGrayedStates` 在每个阵营**自己阶段结束时**清，
    //   所以第 3 回合开始时**没有任何人**是"已行动"。
    final stillActed =
        alive.where((u) => u['hasActed'] == true).map((u) => u['name']).toList();
    ok(stillActed.isEmpty, '第 3 回合开始时没人还是"已行动"',
        'stillActed=$stillActed');

    ok(d['turnEventFired'] == 'EventScr_Prologue_Turn3',
        '第 3 回合的回合事件跑了', 'turnEventFired=${d['turnEventFired']}');

    // ★ `RunPhaseSwitchEvents` 必须**每一次阶段切换都跑**。
    //
    // 出处：`src/bm_08015434.c:82-95` —— 它就在 `BmMain_ChangePhase` **里面**：
    //   ClearActiveFactionGrayedStates(); RefreshUnitSprites(); SwitchPhases();
    //   if (RunPhaseSwitchEvents() == true) return false;
    //
    // 一次结束 = 3 步（蓝→红、红→绿、绿→蓝），两次结束 = 6 次。
    // ⚠️ 原来把"跳过空阶段"折成一个循环、循环外只跑一次 ⇒ 只有 2 次/回合，
    //    绿色阶段的 TURN 条目永远不触发（序章恰好没有这种条目，所以看不出来）。
    ok(d['phaseSwitchEventRuns'] == 6,
        '两次结束共跑 6 次阶段切换事件（3 步/次）',
        'runs=${d['phaseSwitchEventRuns']}');
    ok(d['configDisableAutoEndTurns'] == false,
        '`disableAutoEndTurns` 默认 0（`src/InitPlayConfig.c:24`）',
        'disableAutoEndTurns=${d['configDisableAutoEndTurns']}');
    ok((d['turnLoopNote'] as String? ?? '').isEmpty,
        '阶段循环没有异常告警', 'turnLoopNote=${d['turnLoopNote']}');

    // ★ 回合横幅（`ProcScr_PhaseIntro` 的最小等价物）
    // 用户反馈"没有回合切换动画、没有显示是谁的回合" —— 这条钉住它真的亮过。
    // 用 `lastPhaseBanner` 而不是 `phaseBanner`：横幅只亮 1 秒，
    // 转储几乎永远读到空串（我自己第一次验证就这么白跑了一轮）。
    ok(d['lastPhaseBanner'] == '我方回合',
        '回合横幅亮过（最后一次是回到我方）',
        'lastPhaseBanner=${d['lastPhaseBanner']} / phaseBanner=${d['phaseBanner']}');
    // 卡住自证：正常停在"等输入"
    ok('${d['waitingFor']}'.startsWith('input:'),
        '`waitingFor` 说得出在等什么（现在应是在等输入）',
        'waitingFor=${d['waitingFor']}');

    // ★ 教学事件（两段式：入队 → 触发）—— 用户说的"阶段切换/玩家阶段开始时触发对话"
    //
    // 序章那张表是 `EventListScr_Prologue_Tutorial`（15 条，
    // `src/data/EventListScr_Prologue_Tutorial_ref/dat_…_ref.c`）。
    ok(d['tutorialTableSize'] == 15,
        '本章教学表 15 条（序章 Tutorial0..E）',
        'tableSize=${d['tutorialTableSize']}');
    // 入队**真的执行了**：开场脚本 `EventScr_Prologue_ExecTut` 里那句
    // `EvtEnqueueConditionalTutCall(2, EventScr_Prologue_Tutorial0)`
    // → `EnqueueTutEvent` → `counter = 1`（下标 0 + 1）、`execType = 2`（ONSELECT）。
    // ⚠️ 这一条**原来恒为 0**：整条命令是 `s.placeholder('EvtEnqueueConditionalTutCall')`。
    final tut = d['tutorial'] as Map<String, dynamic>?;
    // ⚠️ 这条**改过语义**：原来钉的是"T0 入队了、但永远等着 ONSELECT 钩子"
    // （`counter == 1`、`lastTutorialFired == null`）。`TryCallSelectEvents` 那条
    // 钩子接上之后，选中单位就会把 T0 **演掉** ⇒ 现在钉"已触发"。
    // 这正是"判据会随实现推进而变"的正常形态 —— 但它必须是**改判据**，不是删判据。
    ok('${d['lastTutorialFired']}'.startsWith('EventScr_Prologue_Tutorial'),
        '教学链第一环**已触发**（选中单位 → ONSELECT）',
        'last=${d['lastTutorialFired']} tutorial=$tut');
    ok((d['tutorialNote'] as String? ?? '').isEmpty,
        '教学事件没有出错（入队失败 / 脚本缺函数 / 表缺失都会写这里）',
        'tutorialNote=${d['tutorialNote']}');
    ok((d['scene'] as Map?)?['running'] == false, '没有卡在剧情里',
        'scene=${d['scene']}');
    // 敌方真的动过（出生在 x=14）
    ok(alive.where((u) => u['faction'] == 0x80).every((u) => u['x'] != 14),
        '敌方离开出生列（AI 真的行动了）',
        'enemies=${alive.where((u) => u['faction'] == 0x80).map((u) => '${u['x']},${u['y']}').toList()}');
  }

  if (scenario == 'range') {
    // ★ 移动范围（用户报过"行动力好像也不对"）—— 钉住**可观测的数值**。
    // 算法本身有 54 条逐格 C oracle 向量（`movement_oracle_test.dart`）；
    // 这里钉的是**接线**（真表 + 真地图 + 真职业）。
    final r = d['range'] as Map<String, dynamic>?;
    ok(r != null, '选中单位后有移动范围', 'range=$r');
    ok(d['phase'] == 'unitSelected', '停在"已选中单位"', 'phase=${d['phase']}');
    ok(d['moveCostsWeather'] == 'normal', '晴天用第 0 张表', 'weather=${d['moveCostsWeather']}');
    ok(r?['count'] == 20,
        '赛特(帕拉丁 mov=8) 在序章地图上的可达格数 = 20',
        'count=${r?['count']}');
    // 山峰不可通行：序章地图有 101 格山峰，可达格列表里一个都不该有
    final tiles = ((r?['tiles'] as List?) ?? const []).cast<String>();
    // ★ 选中单位必须触发教学链的第一环（`TryCallSelectEvents.c:33`）
    //
    // 序章的 `T0` 是 `execType = 2`（ONSELECT）：**原来这一环永远不触发**
    // （`lastTutorialFired` 恒为 null），因为"选中单位"这个触发点根本没接。
    // 这就是用户说的"对话触发不对"。
    ok(d['lastTutorialFired'] == 'EventScr_Prologue_Tutorial0',
        '选中单位触发了教学链第一环 T0（ONSELECT）',
        'lastTutorialFired=${d['lastTutorialFired']} tutorial=${d['tutorial']}');
    ok(d['specialEventsNote'] != null && '${d['specialEventsNote']}'.contains('选中'),
        '三张专属事件表已载入', 'specialEventsNote=${d['specialEventsNote']}');
    ok(tiles.contains('4,3') && tiles.contains('2,4'),
        '相邻可走格在可达列表里（(4,3) 与 (2,4)）',
        'tiles=${tiles.take(8).toList()}…（共 ${tiles.length}）');
  }

  if (scenario == 'worldmap') {
    // ★ 章间大地图：`MNCH` 之后**必须**先到这里，而不是直接切章。
    // 出处：`src/Event2A_MoveToChapter.c:24-31`（`MNCH` → `save_menu_type = 1`
    // → `EXEC_BM` 起 `ProcScr_WorldMapWrapper`）。
    ok('${d['waitingFor']}'.startsWith('worldMap:'),
        '停在**大地图**里（`MNCH` 不是直接切章）', 'waitingFor=${d['waitingFor']}');
    final wm = d['worldMap'] as Map<String, dynamic>?;
    ok(wm != null, '转储里带大地图状态', 'worldMap=$wm');
    ok(wm?['node'] == 0,
        '部队在节点 0（`src/worldmap_path.c:148` 初值 0）', 'node=${wm?['node']}');
    ok(d['worldMapTarget'] == 56,
        '目标章 = `MNCH(0x38)` = CHAPTER_CASTLE_FRELIA',
        'worldMapTarget=${d['worldMapTarget']}');
    // ⚠️ 这一条**钉的是当前的欠账**（不是"正确行为"）：
    // 节点 0 的条件旗 137 在我们的游戏里没人置上 ⇒ 走不动。
    // 哪天有了设置点（或确认原作怎么置），这条必须改成"能走到节点 1"。
    ok('${d['worldMapNote']}'.contains('137'),
        '走不动时必须**响亮**写出是哪个旗（欠账 8）',
        'worldMapNote=${d['worldMapNote']}');
    final sc = d['scene'] as Map<String, dynamic>?;
    ok(sc?['running'] != true, '没有卡在剧情里（WM 是独立模式）',
        'scene.running=${sc?['running']}');
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

/// 一份**正常**的地图菜单转储（selftest 的基准）
///
/// 对应 `Difficulty.normal` 的序章：`config.controller = 1` → 教学模式 →
/// 辞书没锁、`中断` 可用、`戦績`/`退却` 因为是故事章节而不显示。
Map<String, dynamic> goodMapMenuDump() {
  final d = goodDump();
  d['mapMenu'] = <String, Object>{
    'index': 0,
    'item': '部隊',
    'itemCommand': 'MapMenu_UnitCommand',
    'itemAvailability': 'enabled',
    'items': <String>['部隊', '状況', '辞書', '設定', '中断', '終了'],
    'layout': <String, int>{'x': 0x17, 'y': 2, 'w': 6, 'h': 14, 'rowPitch': 2},
  };
  d['mapMenuNote'] = '打开（START）：6 条（8 条里隐藏了 2 条）';
  d['mapMenuInputs'] = <String, Object?>{
    'chapterIndex': 0,
    'battleMapKind': 'story',
    'battleMapKindVerified': false,
    'guideLocked': false,
    'tutorial': false,
    'tutorialMode': true,
    'difficulty': 'normal',
    'hidden': <String>[
      '戦績(MapMenu_IsRecordsCommandAvailable)',
      '退却(MapMenu_IsRetreatCommandAvailable)',
    ],
  };
  d['mapMenuUnimplemented'] = <String>[];
  return d;
}

/// 一组**故意坏掉**的地图菜单转储 —— 每条都必须被 `check(..., scenario:'mapmenu')` 抓到
Map<String, Map<String, dynamic>> brokenMapMenuDumps() {
  Map<String, dynamic> base() => goodMapMenuDump();
  Map<String, dynamic> menuOf(Map<String, dynamic> d) =>
      d['mapMenu'] as Map<String, dynamic>;
  Map<String, dynamic> layoutOf(Map<String, dynamic> d) =>
      menuOf(d)['layout'] as Map<String, dynamic>;
  Map<String, dynamic> inputsOf(Map<String, dynamic> d) =>
      d['mapMenuInputs'] as Map<String, dynamic>;

  final out = <String, Map<String, dynamic>>{};

  final a = base();
  menuOf(a)['items'] = <String>[
    '部隊', '状況', '辞書', '戦績', '設定', '退却', '中断', '終了',
  ];
  out['菜单显示了 8 条（退却/戦績 没被滤掉）'] = a;

  final b = base();
  layoutOf(b)['h'] = 18;
  out['面板高度按 8 行算'] = b;

  final c = base();
  layoutOf(c)['rowPitch'] = 1;
  out['行距还是 1 个 UI 图块'] = c;

  final e = base();
  inputsOf(e)['guideLocked'] = true;
  out['辞书被锁住却还显示了'] = e;

  final f = base();
  inputsOf(f)['battleMapKind'] = null;
  out['GetBattleMapKind 读不到却照样开菜单'] = f;

  final g = base();
  g['mapMenuUnimplemented'] = <String>['unitList'];
  out['选中了未实现的条目'] = g;

  final h = base();
  layoutOf(h)['x'] = 1;
  out['面板画在了左边（分侧用错坐标）'] = h;

  return out;
}

/// 一组**故意坏掉**的「菜单里选終了」转储
Map<String, Map<String, dynamic>> brokenMenuEndDumps() {
  final base = goodMapMenuDump();
  base['mapMenu'] = null;
  base['turn'] = 2;
  base['mapMenuNote'] = '終了（CommandEffectEndPlayerPhase）：结束我方阶段';

  final out = <String, Map<String, dynamic>>{};

  final a = Map<String, dynamic>.from(base);
  a['turn'] = 1; // 「終了」没真的结束我方阶段
  out['选了終了但回合没推进'] = a;

  final b = Map<String, dynamic>.from(base);
  b['mapMenu'] = goodMapMenuDump()['mapMenu']; // 菜单没关
  out['选完菜单还开着'] = b;

  return out;
}

/// 一份**正常**的 `turnend` 转储（selftest 的基准）
///
/// 两次回合结束（一次菜单、一次自动）之后应当：turn 3、我方阶段、
/// 两个我方都能动、**没有任何人还是"已行动"**、敌方已经动过。
/// `worldmap` 场景的基准转储（在 turnend 的基础上叠大地图字段）
Map<String, dynamic> goodRangeDump() {
  final d = goodDump();
  d['phase'] = 'unitSelected';
  d['moveCostsWeather'] = 'normal';
  d['range'] = <String, Object?>{
    'count': 20,
    'tiles': <String>['0,0', '4,3', '2,4'],
  };
  d['lastTutorialFired'] = 'EventScr_Prologue_Tutorial0';
  d['tutorial'] = <String, Object?>{'counter': 0, 'execType': 0, 'pending': false};
  d['specialEventsNote'] = '专属事件表：选中 1 条 / 目的地 1 条 / 移动后 1 条';
  d['specialEventFired'] = '';
  return d;
}

Map<String, dynamic> goodWorldMapDump() {
  final d = goodTurnEndDump();
  d['turn'] = 1;
  d['waitingFor'] = 'worldMap:node=0';
  d['worldMap'] = <String, Object?>{'node': 0, 'nextNodeId': 0, 'cleared': <int>[]};
  d['worldMapTarget'] = 56;
  d['worldMapNote'] = '节点 0 没有下一个目的地（条件旗 137 未置上）';
  (d['scene'] as Map<String, dynamic>)['running'] = false;
  return d;
}

Map<String, dynamic> goodTurnEndDump() {
  final d = goodDump();
  d['turn'] = 3;
  d['activeFaction'] = 0;
  d['phase'] = 'freeCursor';
  d['phaseAble'] = <String, Object>{
    'blue': 2,
    'green': 0,
    'red': 3,
    'active': 0,
  };
  d['turnEventFired'] = 'EventScr_Prologue_Turn3';
  d['phaseSwitchEventRuns'] = 6;
  d['configDisableAutoEndTurns'] = false;
  d['turnLoopNote'] = '';
  d['lastPhaseBanner'] = '我方回合';
  d['phaseBanner'] = '';
  d['waitingFor'] = 'input:freeCursor';
  d['tutorialTableSize'] = 15;
  // 教学链在 turnend 里**已经走过去一环**了（选中单位 → T0 演掉）
  d['tutorial'] = <String, Object?>{'counter': 0, 'execType': 0, 'pending': false};
  d['tutorialNote'] = '';
  d['lastTutorialFired'] = 'EventScr_Prologue_Tutorial0';
  for (final u in (d['units'] as List).cast<Map<String, dynamic>>()) {
    u['hasActed'] = false;
    if (u['faction'] == 0x80) u['x'] = 9; // 敌方已经离开出生列 x=14
  }
  return d;
}

/// 一组**故意坏掉**的 `turnend` 转储
Map<String, Map<String, dynamic>> brokenTurnEndDumps() {
  final out = <String, Map<String, dynamic>>{};

  final a = goodTurnEndDump();
  a['turn'] = 2; // 其中一条"回合结束"没生效
  out['只结束了一次（回合停在 2）'] = a;

  final b = goodTurnEndDump();
  (b['units'] as List).cast<Map<String, dynamic>>().first['hasActed'] = true;
  out['有人在新回合还挂着"已行动"'] = b;

  final c = goodTurnEndDump();
  (c['phaseAble'] as Map<String, dynamic>)['blue'] = 1;
  out['新回合我方只有 1 个能行动'] = c;

  final e = goodTurnEndDump();
  e['activeFaction'] = 0x80; // 停在了敌方
  out['结束完停在了敌方阶段'] = e;

  final f = goodTurnEndDump();
  for (final u in (f['units'] as List).cast<Map<String, dynamic>>()) {
    if (u['faction'] == 0x80) u['x'] = 14; // 敌人没动
  }
  out['敌方一步都没动'] = f;

  final g = goodTurnEndDump();
  g['phaseSwitchEventRuns'] = 4; // 旧实现：每个回合只跑 2 次
  out['跳过的阶段没跑回合事件（旧实现）'] = g;

  final h = goodTurnEndDump();
  h['turnLoopNote'] = '转满 6 步没回到我方阶段';
  out['阶段循环转满了 6 步'] = h;

  // "教学链第一环没触发"—— 这正是 `TryCallSelectEvents` 钩子接上**之前**的真实现状
  // （T0 入队了、`lastTutorialFired` 恒为 null）。改这条坏转储是因为
  // 我把 turnend 的断言从"入队了"改成了"已触发"：**断言改了，证伪样本也要改**，
  // 否则新断言就是一条永远不会红的死断言（R7 的教训）。
  final i = goodTurnEndDump();
  i['lastTutorialFired'] = null;
  out['教学链第一环没触发（钩子没接的那版）'] = i;

  final j = goodTurnEndDump();
  j['tutorialTableSize'] = 0;
  out['教学表没载进来'] = j;

  final k = goodTurnEndDump();
  k['tutorialNote'] = '入队失败：EventScr_… 不在 0 条教学表里';
  out['教学入队失败'] = k;

  final l = goodTurnEndDump();
  l['lastPhaseBanner'] = '';
  out['回合横幅从没亮过（用户反馈的那条）'] = l;

  final m = goodTurnEndDump();
  m['waitingFor'] = 'scene:text 0x8c3';
  out['停在剧情里（可能是卡住）'] = m;

  return out;
}

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

  // ③ 地图菜单那一组判据也必须**会红**
  //
  // 理由同 R7 那次的教训（一条永远不可能失败的规则）：新加的断言
  // 如果没被证伪过，就不知道它是活的。
  for (final sc in const ['mapmenu', 'menuend', 'turnend', 'worldmap', 'range']) {
    final good = switch (sc) {
      'mapmenu' => goodMapMenuDump(),
      'menuend' => (goodMapMenuDump()
        ..['mapMenu'] = null
        ..['turn'] = 2
        ..['mapMenuNote'] = '終了（CommandEffectEndPlayerPhase）：结束我方阶段'),
      'worldmap' => goodWorldMapDump(),
      'range' => goodRangeDump(),
      _ => goodTurnEndDump(),
    };
    final goodFailed =
        check(good, scenario: sc).where((f) => !f.ok).toList();
    if (goodFailed.isNotEmpty) {
      stderr.writeln('✗ selftest：$sc 的基准转储不通过：');
      for (final f in goodFailed) {
        stderr.writeln('    ${f.name}: ${f.detail}');
      }
      bad++;
    } else {
      stdout.writeln('  ✓ $sc 基准转储全绿');
    }

    final broken = switch (sc) {
      'mapmenu' => brokenMapMenuDumps(),
      'menuend' => brokenMenuEndDumps(),
      _ => brokenTurnEndDumps(),
    };
    for (final e in broken.entries) {
      final failed = check(e.value, scenario: sc).where((f) => !f.ok).toList();
      if (failed.isEmpty) {
        stderr.writeln('✗ 「${e.key}」没有被任何判据抓到 —— 判据是死的');
        bad++;
      } else {
        stdout.writeln('  ✓ 「${e.key}」被抓到：${failed.first.name}');
      }
    }
  }

  if (bad > 0) {
    stderr.writeln('✗ selftest 失败 $bad 项');
    return 1;
  }
  stdout.writeln('判据自检通过：基准全绿 + '
      '${brokenDumps().length + brokenMapMenuDumps().length + brokenMenuEndDumps().length}'
      ' 个坏转储全被抓到');
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
