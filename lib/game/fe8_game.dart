// 表现层：Flame 游戏主体。
//
// M0 的目标不是"能玩"，而是**打通一条可验证的渲染链路**：
//
//   graphics/map/layout/PrologueMap.mar              （GBA 二进制）
//     → tools/pipeline/extract/map_tmx.py            （数据管线）
//     → prologue.tmx + 图集 PNG                       → flame_tiled → 画面
//     → prologue.json                                 → lib/core    → 规则
//
// ⚠️ 注意这里**两条线是分开的**：
//   * `.tmx` 只负责"怎么画"
//   * `.json` 只负责"是什么规则"
// 让 lib/core 去解析 Tiled 的 XML 是架构错误——将来换掉渲染方案时，
// 规则层不该跟着动。两者由同一个管线从同一份 GBA 数据导出，所以不可能不一致。

import 'dart:convert';
import 'dart:io';
import 'dart:ui' show Color;

import 'package:fe8r/core/core.dart';
import 'package:fe8r/game/battle_components.dart';
import 'package:fe8r/game/demo_event.dart';
// FixedResolutionViewport 只在 flame/camera.dart 里导出
import 'package:flame/components.dart' show PositionComponent;
import 'package:flame/camera.dart' show FixedResolutionViewport;
import 'package:flame/cache.dart' show Images;
import 'package:flame/game.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

/// FE8 重制版主游戏对象。
class Fe8Game extends FlameGame {
  /// 左上角状态文字（M0 阶段的调试信息）
  final ValueNotifier<String> status = ValueNotifier<String>('启动中…');

  /// 当前地图的**规则层**数据。表现层与规则层在这里汇合。
  MapGrid? map;

  /// 战场（单位 + 回合）
  BattleField? field;

  /// 交互流程状态机（规则层，纯 Dart）
  FlowMachine? flow;

  /// 敌方 AI（M5 的最小实现，不是原版 cp_* 的移植）
  EnemyAi? ai;

  /// 战斗结算器（M4 数值层 → M5 战场流程的桥）
  CombatResolver? combat;

  /// 职业表（地形加成 / 移动消耗，按职业查）
  ClassTable? classTable;

  /// 演示用道具表（射程与威力都从这里取）
  late ItemTable _items;

  /// 乱数与消耗追踪
  final GameRng rng = GameRng();
  late final BattleRngTracker tracker = BattleRngTracker(rng);

  /// 最近一次攻击的结果，供 HUD 显示
  String lastCombat = '';

  /// 剧情引擎（M6）：手写演示脚本 + 虚拟机
  EventVm? eventVm;
  EventVmState? eventState;
  DialogueBoxComponent? _dialogue;
  bool _showDialogue = false;

  /// 当前流程状态
  FlowState? state;

  /// 状态变化通知（HUD 订阅）
  final ValueNotifier<String> hud = ValueNotifier<String>('');

  /// 单位与光标的渲染组件，按单位 id / 状态重建
  final List<UnitComponent> _unitComponents = [];
  CursorComponent? _cursor;
  MovementRangeComponent? _rangeComp;
  ActionMenuComponent? _menuComp;
  final List<TargetMarkerComponent> _targetMarkers = [];
  PositionComponent? _overlayLayer;

  /// 地图的 metatile 尺寸（像素）
  static const double metatileSize = 16;

  @override
  Color backgroundColor() => const Color(0xFF101418);

  @override
  Future<void> onLoad() async {
    try {
      // 1) 规则层数据（纯 Dart，可单独测试，不依赖 Flame）
      final grid = MapGrid.parse(
        await rootBundle.loadString('assets/maps/prologue.json'),
      );
      map = grid;

      // 2) 视觉层（Flame + Tiled）
      //
      // 两处前缀都要显式指定，因为 flame 的两个默认值都不是我们的布局：
      //   * TiledComponent 默认去 `assets/tiles/` 找 .tmx
      //   * Flame.images（图集走它加载）默认前缀是 `assets/images/`
      // 我们统一放在 assets/maps/ 下，所以两个都覆盖掉。
      const assetPrefix = 'assets/maps/';
      final tiled = await TiledComponent.load(
        'prologue.tmx',
        Vector2.all(metatileSize),
        prefix: assetPrefix,
        images: Images(prefix: assetPrefix),
      );
      world.add(tiled);

      // 3) 相机：把整张地图装进视口，保持像素锐利
      final mapSize = Vector2(
        grid.width * metatileSize,
        grid.height * metatileSize,
      );
      camera.viewport = FixedResolutionViewport(resolution: mapSize);
      camera.viewfinder.position = mapSize / 2;

      // 4) 战场与交互流程（规则层）
      field = _makeDemoField(grid);
      flow = FlowMachine(map: grid, costTable: _demoCostTable());
      ai = EnemyAi(map: grid, costTable: _demoCostTable());
      classTable = _loadClassTable();
      _items = _demoItems();
      combat = CombatResolver(
        items: _items,
        triangle: _loadTriangleTable(),
        monsterClassList: _monsterClassList(),
      );
      rng.initRn(1);
      state = FlowState(
        phase: FlowPhase.freeCursor,
        cursorX: 2,
        cursorY: 2,
        turn: field!.turn,
        faction: field!.activeFaction,
      );

      _overlayLayer = PositionComponent();
      world.add(_overlayLayer!);
      _rebuildOverlay();

      // 剧情引擎：脚本用真实编码手写（见 demo_event.dart）
      eventVm = EventVm(textTable: demoTextTable);
      eventState = EventVmState(script: buildDemoEventScript());

      status.value = '${grid.id}  ${grid.width}×${grid.height}  '
          '${_terrainBrief(grid)}';
      _updateHud();
      debugPrint('[Fe8Game] $grid；地形分布 ${grid.terrainHistogram()}');
    } catch (e, st) {
      status.value = '加载失败: $e';
      debugPrint('[Fe8Game] 加载失败: $e\n$st');
      rethrow;
    }
  }

  /// 按脚本驱动一串输入（调试 / 视觉验证用）。
  ///
  /// 交互流程是纯状态机，所以"录一串按键再回放"天然可行——
  /// 这也是把它写成显式状态机的附带收益（原版的 Proc 协程做不到这点）。
  void runScript(String script) {
    for (final raw in script.split(',')) {
      final t = raw.trim().toLowerCase();
      if (t.isEmpty) continue;
      final i = switch (t) {
        'up' => FlowInput.up,
        'down' => FlowInput.down,
        'left' => FlowInput.left,
        'right' => FlowInput.right,
        'confirm' || 'z' => FlowInput.confirm,
        'cancel' || 'x' => FlowInput.cancel,
        'endturn' || 'e' => FlowInput.endTurn,
        'dialogue' || 'd' => FlowInput.startDialogue,
        _ => null,
      };
      if (i != null) input(i);
    }
  }

  /// 推进一次输入。
  ///
  /// **所有规则判断都在 `FlowMachine` 里**，这里只负责把新状态搬到画面上。
  void input(FlowInput i) {
    // 剧情演出期间，confirm 用来推进对白，而不是操作战场。
    // 这个优先级放在**调用点**而不是状态机里：剧情与战场是两个独立的
    // 状态机，谁优先是外壳层的策略，不该污染任何一方。
    if (i == FlowInput.startDialogue) {
      startDialogue();
      return;
    }
    if (_showDialogue && i == FlowInput.confirm) {
      advanceDialogue();
      return;
    }

    final s = state;
    final f = field;
    final fl = flow;
    if (s == null || f == null || fl == null) return;

    // 选中单位的那一刻同步射程（不同武器射程不同）
    if (i == FlowInput.confirm &&
        s.phase == FlowPhase.freeCursor &&
        r0Candidates(f, s) != null) {
      _syncAttackRange(r0Candidates(f, s)!);
    }

    final r = fl.advance(s, f, i);

    // 提交一次移动
    if (r.committedMove && s.selectedUnitId != null) {
      final u = f.unitById(s.selectedUnitId);
      if (u != null && s.pendingX != null && s.pendingY != null) {
        f.moveUnit(u, s.pendingX!, s.pendingY!);
        f.finishUnit(u);

        // 落点确定后才结算攻击 —— 顺序不能反：
        // 先移动再打，射程要靠移动**之后**的位置算。
        final atk = r.attack;
        if (atk != null) {
          final target = f.unitById(atk.targetId);
          final attacker = f.unitById(atk.attackerId);
          if (target != null && attacker != null) {
            _resolveAttack(f, attacker, target);
          }
        }
      }
    }

    state = r.state;
    _rebuildOverlay();
    _updateHud();

    if (r.endTurn) endTurn();
  }

  /// 开始剧情演出
  void startDialogue() {
    if (eventVm == null) return;
    _showDialogue = true;
    _pumpEvent();
  }

  /// 推进剧情：跑引擎直到"等玩家"或结束，然后重画对话框。
  void _pumpEvent() {
    final vm = eventVm;
    final st = eventState;
    if (vm == null || st == null) return;

    vm.run(st);
    _rebuildDialogue();
  }

  /// 玩家按键推进对白
  void advanceDialogue() {
    final vm = eventVm;
    final st = eventState;
    if (vm == null || st == null) return;

    if (st.waitingForPlayer) {
      vm.advanceFromPlayerInput(st);
    }
    vm.run(st);

    if (st.done) {
      _showDialogue = false;
      _rebuildDialogue();
      return;
    }
    _rebuildDialogue();
  }

  void _rebuildDialogue() {
    final st = eventState;
    final layer = _overlayLayer;
    if (layer == null) return;

    if (_dialogue != null) {
      layer.remove(_dialogue!);
      _dialogue = null;
    }
    if (!_showDialogue || st == null) {
      _updateHud();
      return;
    }

    final pres = st.presentation;
    final cam = camera.viewport.virtualSize;
    final boxH = cam.y * 0.26;

    _dialogue = DialogueBoxComponent(
      text: st.lastText,
      hostFaceId: pres.faces[0],
      guestFaceId: pres.faces[1],
      boxWidth: cam.x * 0.86,
      boxHeight: boxH,
    )..position = Vector2(cam.x * 0.07, cam.y * 0.68);
    layer.add(_dialogue!);
    _updateHud();
  }

  /// 结束当前回合：推进阶段，若轮到非玩家阵营就跑 AI，直到回到玩家回合。
  ///
  /// 用 `advanceToNextActivePhase` 而不是"切一次就完事"——
  /// 场上没有友军 NPC 时，绿色阶段必须被跳过（判据是原版的
  /// `GetPhaseAbleUnitCount == 0`，不是我另写的一套规则）。
  void endTurn() {
    final f = field;
    final s = state;
    if (f == null || s == null) return;

    // 最多转 4 个阶段，防止任何意外造成死循环
    for (var guard = 0; guard < 4; guard++) {
      final hops = advanceToNextActivePhase(f);
      if (hops == 0) break;

      if (f.activeFaction == Faction.blue) {
        // 回到玩家回合
        state = s.copyWith(
          phase: FlowPhase.freeCursor,
          selectedUnitId: null,
          moveOriginX: null,
          moveOriginY: null,
          turn: f.turn,
          faction: f.activeFaction,
        );
        _rebuildOverlay();
        _updateHud();
        return;
      }

      _runFactionAi(f);
    }

    _rebuildOverlay();
    _updateHud();
  }

  /// 让当前阵营的所有单位按 AI 行动一轮。
  ///
  /// 单位按 **id 升序**处理，且每一步都重新查询战场状态——
  /// 因为前面的单位移动后会改变后面单位的落点选择。
  void _runFactionAi(BattleField f) {
    final brain = ai;
    if (brain == null) return;

    final actors = f.units
        .where((u) => u.isAlive && !u.hasActed &&
            PhaseRules.isSameAllegiance(u.faction, f.activeFaction))
        .map((u) => u.id)
        .toList()
      ..sort();

    for (final id in actors) {
      final u = f.unitById(id);
      if (u == null || !u.isAlive || u.hasActed) continue;
      if (u.x < 0 || u.x >= f.width || u.y < 0 || u.y >= f.height) continue;

      final a = brain.decide(f, u);
      f.moveUnit(u, a.toX, a.toY);
      f.finishUnit(u);

      // 够得着就打
      if (a.attacked && a.targetId != null) {
        _resolveAttack(f, u, f.unitById(a.targetId)!);
        // 目标阵亡就从战场移除
        final tgt = f.unitById(a.targetId);
        if (tgt != null && tgt.hp <= 0) tgt.hp = 0;
      }
    }
  }

  /// 结算一次攻击（攻击方打防御方），并把结果写进 HUD。
  ///
  /// 这里是 M4 与 M5 的接缝：数值由已通过 C Oracle 的 `CombatResolver` 算，
  /// 表现层只负责把结果说出来。
  void _resolveAttack(BattleField f, MapUnit attacker, MapUnit defender) {
    final c = combat;
    if (c == null) return;

    final atkProfile = _profileFor(attacker);
    final defProfile = _profileFor(defender);

    // 地形防御/回避：按**防御方的职业**查真实表
    final terrainId = _terrainAt(defender.x, defender.y);
    final (terrainDef, terrainAvo) =
        _terrainBonuses(terrainId, defProfile.classId);
    final atkTerrainId = _terrainAt(attacker.x, attacker.y);
    final (atkDef, atkAvo) =
        _terrainBonuses(atkTerrainId, atkProfile.classId);

    // 完整交战：先手 → 反击 → 追击（序列由规则层的 battleUnwind 决定）
    final round = c.resolveCombat(
      tracker: tracker,
      rng: rng,
      actorUnit: attacker,
      targetUnit: defender,
      actorProfile: atkProfile,
      targetProfile: defProfile,
      actorTerrainDefense: atkDef,
      actorTerrainAvoid: atkAvo,
      targetTerrainDefense: terrainDef,
      targetTerrainAvoid: terrainAvo,
    );

    final name = attacker.name.isEmpty ? '单位${attacker.id}' : attacker.name;
    final tname = defender.name.isEmpty ? '单位${defender.id}' : defender.name;

    // 战报按步骤展开，让"谁打了几下、有没有反击"一眼可见
    final lines = <String>[];
    for (var i = 0; i < round.steps.length; i++) {
      final st = round.steps[i];
      final who = st.attackerIsActor ? name : tname;
      final whom = st.attackerIsActor ? tname : name;
      lines.add('$who → $whom  ${round.results[i]}');
    }
    lastCombat = '$name vs $tname（${round.steps.length} 段，'
        '消耗 ${round.rnConsumed} 乱数）\n${lines.join('\n')}';
  }

  /// 把武器的射程同步给流程状态机。
  ///
  /// 每次进入"单位已选中"时都要更新 —— 不同单位拿的武器射程不同。
  void _syncAttackRange(MapUnit unit) {
    final fl = flow;
    if (fl == null) return;
    final p = _profileFor(unit);
    fl.attackMinRange = _items.minRangeOf(p.weaponItem);
    fl.attackMaxRange = _items.maxRangeOf(p.weaponItem);
  }

  /// 按阵营给一套演示用的职业/武器数据。
  ///
  /// 真实数据来自章节配置与职业表（M12）；这里只要够把伤害打出来。
  CombatProfile _profileFor(MapUnit u) {
    if (u.factionBit == Faction.red) {
      // 弓手（id 0x82）用弓，射程 2；其余敌人用斧
      final isArcher = u.id == 0x82;
      return CombatProfile(
        classId: isArcher ? 0x1B : 0x2A,
        level: 3, pow: 6, skl: 5, spd: 5, def: 3, lck: 2,
        weaponItem: isArcher ? 0x04 : 0x03,
        weaponType: isArcher ? WeaponType.bow : WeaponType.axe,
      );
    }
    if (u.factionBit == Faction.green) {
      return const CombatProfile(
        classId: 0x09, level: 2, pow: 4, skl: 4, spd: 3, def: 4, lck: 3,
        weaponItem: 0x02, weaponType: WeaponType.lance,
      );
    }
    return CombatProfile(
      classId: 0x01, level: u.level, pow: 5, skl: 6, spd: 7, def: 4, lck: 5,
      weaponItem: 0x01, weaponType: WeaponType.sword,
    );
  }

  /// 演示用道具表。
  ///
  /// `encodedRange` 是**高 4 位最小、低 4 位最大**：
  ///   剑/枪/斧  0x11 → 射程 1
  ///   弓        0x22 → 射程 2（用来验证射程确实接上了）
  /// 漏设这个字段的话射程会是 0，**谁都打不到** —— 而且不报错，
  /// 只表现为"菜单里永远没有攻击"。是很不好查的一类。
  ItemTable _demoItems() {
    final t = ItemTable(8);
    t[1]
      ..might = 5
      ..hit = 90
      ..crit = 0
      ..weight = 3
      ..encodedRange = 0x11;
    t[2]
      ..might = 7
      ..hit = 85
      ..crit = 0
      ..weight = 8
      ..encodedRange = 0x11;
    t[3]
      ..might = 8
      ..hit = 75
      ..crit = 0
      ..weight = 10
      ..encodedRange = 0x11;
    t[4]
      ..might = 6
      ..hit = 80
      ..crit = 0
      ..weight = 5
      ..encodedRange = 0x22; // 弓：射程 2
    return t;
  }

  /// 从提取出的 JSON 读武器三角规则表（没有 C 源码，由 carve 提取）
  WeaponTriangleTable _loadTriangleTable() {
    final f = File('tools/pipeline/out/tables/weapon_triangle.json');
    if (!f.existsSync()) {
      // 数据没生成时给空表：不静默用一套"假规则"顶替
      return WeaponTriangleTable(const []);
    }
    return WeaponTriangleTable.fromJson(
      jsonDecode(f.readAsStringSync()) as Map<String, dynamic>,
    );
  }

  List<int> _monsterClassList() {
    const p = 'tools/pipeline/out/tables/itemuse.json';
    final f = File(p);
    if (!f.existsSync()) return const [];
    final d = jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
    final t = (d['tables'] as Map<String, dynamic>)['ItemEffectiveness_Monsters']
        as Map<String, dynamic>;
    return (t['values'] as List<dynamic>)
        .map((e) => e as int)
        .where((v) => v != 0)
        .toList();
  }

  int _terrainAt(int x, int y) {
    final g = map;
    if (g == null) return 0;
    if (x < 0 || y < 0 || x >= g.width || y >= g.height) return 0;
    return g.terrainAt(x, y).id;
  }

  /// 地形防御/回避加成。
  ///
  /// 走**规则层按职业查表**的实现（`SetBattleUnitTerrainBonuses` 的语义）。
  /// 早先这里写死过"森林 (1,10)、山峰 (2,20)"并标注为"非移植近似值" ——
  /// 那个近似值不只是精度不对，**语义也不对**：它给飞行单位也加了森林回避，
  /// 而原版飞行职业用的是 `_Fly` 表，地形回避基本为 0。
  (int, int) _terrainBonuses(int terrainId, int classId) {
    final t = classTable;
    if (t == null) return (0, 0);
    return t.terrainBonuses(classId, terrainId);
  }

  /// 读取职业表。数据由 parse_class_tables.py 提取，
  /// 并校验所有引用的表名都真实存在。
  ClassTable? _loadClassTable() {
    final cf = File('tools/pipeline/out/tables/classes.json');
    final tf = File('tools/pipeline/out/tables/terrains.json');
    if (!cf.existsSync() || !tf.existsSync()) return null;
    return ClassTable.parse(cf.readAsStringSync(), tf.readAsStringSync());
  }

  /// 光标下的可选中单位（用于在推进前同步射程）
  MapUnit? r0Candidates(BattleField f, FlowState s) {
    final u = f.unitAt(s.cursorX, s.cursorY);
    if (u == null || u.hasActed) return null;
    if (!f.isControllable(u)) return null;
    return u;
  }

  /// HUD 用：当前可选的行动项
  List<ActionOption> menuOptions(FlowState s, BattleField f) =>
      flow?.availableActions(s, f) ?? const [ActionOption.wait];

  void _updateHud() {
    final s = state;
    final f = field;
    if (s == null || f == null) return;
    final who = f.activeFaction == Faction.red ? '敌方' : '我方';
    final hp = f.units
        .where((u) => u.isAlive)
        .map((u) => '${u.name.isEmpty ? u.id : u.name}:${u.hp}')
        .join(' ');
    final menu = s.phase == FlowPhase.actionMenu
        ? '  [${menuOptions(s, f).map((o) => o.label).join(' / ')}]'
        : (s.phase == FlowPhase.selectTarget ? '  选择目标' : '');
    final ev = eventState;
    if (_showDialogue && ev != null) {
      hud.value = '剧情  ${ev.done ? '结束' : (ev.waitingForPlayer ? '等按键（Z / 回车）' : '演出中）')}'
          '  背景 ${ev.presentation.backgroundId ?? '-'}'
          '  立绘 ${ev.presentation.faces.values.join(',')}'
          '\n${ev.lastText}';
      return;
    }
    hud.value = '回合 ${f.turn}  $who  '
        '可行动 ${f.actionableCount}  '
        '光标 (${s.cursorX},${s.cursorY})  '
        '${s.phase.name}$menu  '
        '乱数 ${tracker.consumed}\n'
        'HP  $hp'
        '${lastCombat.isEmpty ? '' : '\n$lastCombat'}';
  }

  /// 按当前流程状态重建叠加层。
  ///
  /// 每次输入都整体重建，而不是增量更新——这个规模（十几到几十个组件）
  /// 重建的开销远小于"增量更新写错导致画面与状态不一致"的风险。
  void _rebuildOverlay() {
    final layer = _overlayLayer;
    final s = state;
    final f = field;
    final fl = flow;
    if (layer == null || s == null || f == null || fl == null) return;

    layer.removeAll(_unitComponents);
    _unitComponents.clear();
    if (_cursor != null) {
      layer.remove(_cursor!);
      _cursor = null;
    }
    if (_rangeComp != null) {
      layer.remove(_rangeComp!);
      _rangeComp = null;
    }
    if (_menuComp != null) {
      layer.remove(_menuComp!);
      _menuComp = null;
    }
    layer.removeAll(_targetMarkers);
    _targetMarkers.clear();

    // 移动范围画在单位下面
    final range = fl.currentRange;
    if (range != null && s.phase == FlowPhase.unitSelected) {
      _rangeComp = MovementRangeComponent(range: range, tileSize: metatileSize);
      layer.add(_rangeComp!);
    }

    for (final u in f.units) {
      if (!u.isAlive) continue;
      final c = UnitComponent(
        unit: u,
        tileSize: metatileSize,
        isSelected: u.id == s.selectedUnitId,
        isActive: f.isControllable(u),
      );
      c.position = Vector2(u.x * metatileSize, u.y * metatileSize);
      layer.add(c);
      _unitComponents.add(c);
    }

    // 选目标阶段：把所有可选目标标出来，当前那个用实心准星
    if (s.phase == FlowPhase.selectTarget) {
      final unit = f.unitById(s.selectedUnitId);
      if (unit != null) {
        final ax = s.pendingX ?? unit.x;
        final ay = s.pendingY ?? unit.y;
        final targets = fl.validTargets(f, unit, ax, ay);
        final idx = s.targetIndex.clamp(0, targets.isEmpty ? 0 : targets.length - 1);
        for (var i = 0; i < targets.length; i++) {
          final m = TargetMarkerComponent(tileSize: metatileSize)
            ..position =
                Vector2(targets[i].x * metatileSize, targets[i].y * metatileSize);
          layer.add(m);
          _targetMarkers.add(m);
        }
        // 光标停在当前目标上，玩家才知道自己在选谁
        if (targets.isNotEmpty) {
          final t = targets[idx];
          _cursor = CursorComponent(tileSize: metatileSize)
            ..position = Vector2(t.x * metatileSize, t.y * metatileSize);
          layer.add(_cursor!);
          return;
        }
      }
    }

    // 行动菜单：画在"落点那一格"的右边
    if (s.phase == FlowPhase.actionMenu) {
      final opts = fl.availableActions(s, f);
      final px = s.pendingX ?? s.cursorX;
      final py = s.pendingY ?? s.cursorY;
      _menuComp = ActionMenuComponent(
        options: opts,
        selectedIndex: s.actionIndex.clamp(0, opts.length - 1),
        tileSize: metatileSize,
      )..position = Vector2(
          (px + 1) * metatileSize,
          py * metatileSize,
        );
      layer.add(_menuComp!);
      _cursor = CursorComponent(tileSize: metatileSize)
        ..position = Vector2(px * metatileSize, py * metatileSize);
      layer.add(_cursor!);
      return;
    }

    _cursor = CursorComponent(tileSize: metatileSize)
      ..position = Vector2(s.cursorX * metatileSize, s.cursorY * metatileSize);
    layer.add(_cursor!);
  }

  /// M5 阶段用的演示战场。
  ///
  /// 单位数据是**手写的**，不是从章节数据导出的——章节单位配置属于 M12。
  /// 这里只要够验证"选中 / 移动范围 / 移动 / 待机"这条交互闭环即可。
  BattleField _makeDemoField(MapGrid grid) {
    return BattleField(
      width: grid.width,
      height: grid.height,
      turn: 1,
      activeFaction: Faction.blue,
      units: [
        MapUnit(id: 1, faction: Faction.blue, x: 2, y: 2, movement: 3, hp: 18, maxHp: 18, name: 'Eirika'),
        MapUnit(id: 2, faction: Faction.blue, x: 3, y: 4, movement: 5, hp: 28, maxHp: 30, name: 'Seth'),
        MapUnit(id: 3, faction: Faction.blue, x: 5, y: 3, movement: 2, hp: 12, maxHp: 20, name: 'Mage'),
        // 这个敌人贴着 Seth(3,4)，用来演示"玩家侧攻击"的完整流程
        MapUnit(id: 0x81, faction: Faction.red, x: 4, y: 4, movement: 4, hp: 22, maxHp: 22, name: 'Fighter'),
        MapUnit(id: 0x83, faction: Faction.red, x: 8, y: 6, movement: 4, hp: 22, maxHp: 22, name: 'Brigand'),
        MapUnit(id: 0x82, faction: Faction.red, x: 10, y: 3, movement: 4, hp: 20, maxHp: 20, name: 'Archer'),
        MapUnit(id: 0x41, faction: Faction.green, x: 7, y: 8, movement: 3, hp: 16, maxHp: 16, name: 'Ally'),
      ],
    );
  }

  /// 演示用的地形消耗表：全地形可通行、消耗 1，只有 TERRAIN_NONE 不可通行。
  ///
  /// 真实的按职业消耗表已经由数据管线导出（`terrains.json`，104 张表），
  /// 接进来属于 M3 的收尾工作；这里先用平的，让交互闭环能独立验证。
  MovementCostTable _demoCostTable() {
    final c = List<int>.filled(65, 1);
    c[0] = 255;
    return MovementCostTable(c);
  }

  /// 把地形分布压成一行短摘要。
  ///
  /// 这一步的意义：证明**地形类型（规则层数据）确实随地图一起过来了**，
  /// 而不是只渲染了一张好看的图。地形类型决定移动消耗 / 回避 / 防御加成，
  /// 是绝不能丢的东西（见技术方案 §4.9.5 红线）。
  String _terrainBrief(MapGrid g) {
    final h = g.terrainHistogram().entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return h
        .take(3)
        .map((e) => '${e.key.replaceFirst('TERRAIN_', '')}×${e.value}')
        .join(' ');
  }
}
