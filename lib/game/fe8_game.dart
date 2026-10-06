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

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' show Color;

import 'package:fe8r/core/core.dart';
import 'package:fe8r/game/battle_view.dart';
import 'package:fe8r/game/demo_event.dart';
import 'package:fe8r/game/hud_view.dart';
import 'package:fe8r/game/scene_view.dart';
// FixedResolutionViewport 只在 flame/camera.dart 里导出
import 'package:flame/camera.dart' show FixedResolutionViewport;
import 'package:flame/cache.dart' show Images;
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:flutter/foundation.dart';
// `LogicalKeyboardKey` / `KeyDownEvent` / `KeyRepeatEvent` 都在 services 里；
// `KeyEvent` / `KeyEventResult` 在 widgets（Flutter 焦点体系）。两处都要。
import 'package:flutter/services.dart'
    show KeyDownEvent, KeyRepeatEvent, LogicalKeyboardKey, rootBundle;
import 'package:flutter/widgets.dart' show KeyEvent, KeyEventResult;

/// FE8 重制版主游戏对象。
/// ⚠️ **必须混 `KeyboardEvents`**，否则真实键盘一个键都收不到。
///
/// `GameWidget` 内部有自己的 `FocusNode`（`autofocus` 默认 true，会抢走主焦点），
/// 它的 `_handleKeyEvent` 逻辑是：
///
///     if (!_focusNode.hasPrimaryFocus) return ignored;
///     if (game is KeyboardEvents) return game.onKeyEvent(...);
///     return KeyEventResult.handled;      // ← 没混就吞掉一切
///
/// 而 Flutter 的按键派发是"主焦点 → 祖先，遇到非 ignored 就停"，
/// 所以在 `GameWidget` 外面再包一层 `Focus(onKeyEvent:)` **永远不会被调用**。
///
/// 这个 bug 被藏了很久，因为**视觉验证全走 `FE8R_SCRIPT` 直接注入输入**，
/// 从没经过真实键盘路径。教训：验证脚本绕过的路径，等于没验证。
class Fe8Game extends FlameGame with KeyboardEvents {
  /// 左上角状态文字（M0 阶段的调试信息）
  final ValueNotifier<String> status = ValueNotifier<String>('启动中…');

  /// 当前地图的**规则层**数据。表现层与规则层在这里汇合。
  MapGrid? map;

  // ---- 场景剧情（从源码解析的真实剧本）----
  //
  // 与 `eventVm` 是**两条不同的输入**：
  //   * `eventVm` 执行打包成字的章节事件表
  //   * `sceneRunner` 执行从源码逐行解析的场景脚本
  // 场景脚本这条路没有指针问题（参数就是名字），所以先把它跑起来。

  GameTexts? gameTexts;
  Scene? scene;

  /// 当前正在显示的对白
  ShowText? _currentText;

  /// 演出是否在进行中
  bool _sceneRunning = false;

  /// 等玩家按键 —— 场景执行到一句话时挂起，按键时放行
  Completer<void>? _sceneWait;

  /// 本次演出显示过的对白条数
  int _sceneShown = 0;

  /// 是否处于场景演出模式（与 `eventVm` 的剧情模式分开）
  bool get inScene => _sceneRunning;

  /// 本次演出的缺口 —— 供 HUD 显示（不藏起来）

  /// 当前该显示的对白
  ShowText? get currentSceneText => _currentText;

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
  SceneView? _sceneView;
  final HudView _hudView = const HudView();
  bool _showDialogue = false;

  /// 正在播的剧情移动：单位 id → 目标格
  final Map<int, (int, int)> _eventMoveTargets = {};
  double _eventMoveAccum = 0;

  /// 当前流程状态
  FlowState? state;

  /// 状态变化通知（HUD 订阅）
  final ValueNotifier<String> hud = ValueNotifier<String>('');

  /// 单位与光标的渲染组件，按单位 id / 状态重建
  BattleView? _battleView;

  /// **屏幕空间**的 UI 层（对话框等）。
  ///
  /// ⚠️ 与 `_overlayLayer` 的区别很重要：
  ///   * `_overlayLayer` 加在 `world` 里 → **相机空间**，跟着地图缩放
  ///   * `_uiLayer` 加在 game 根节点 → **屏幕空间**，固定不动
  ///
  /// 对话框属于后者。第一版把它放进 `_overlayLayer`，
  /// 结果它随地图分辨率缩放，位置和大小都对不上（截图里框跑到屏幕外）。

  /// 地图的 metatile 尺寸（像素）
  static const double metatileSize = 16;

  @override
  Color backgroundColor() => const Color(0xFF101418);

  /// 加载真实剧本与文本（不存在就返回 null —— 不静默用假数据顶替）
  void _loadSceneData() {
    try {
      final tf = File('tools/pipeline/out/tables/texts.json');
      if (!tf.existsSync()) return;
      gameTexts = GameTexts.parse(tf.readAsStringSync());
      // ⚠️ 剧本**不是**从文件读的 —— 它是生成的 Dart `async` 函数
      //（`lib/core/event/scene_data.g.dart`，由 C 源码直接生成）。
      // 没有 JSON、没有指令列表、没有解释器。
      //
      // `onEvent` 决定"等多久"：游戏里等到按键。
      scene = Scene(
        texts: gameTexts!,
        scripts: allSceneFns,
        defined: definedSceneScripts,
        onEvent: _onSceneEvent,
      );
    } catch (e) {
      // 读失败就当作没有 —— 但**不吞掉**，写进 status 让人看得见
      status.value = '剧本加载失败: $e';
    }
  }

  /// 按键 → 流程输入。
  ///
  /// 放在 game 里而不是外层 `Focus` —— 见类文档。
  /// 测试钩子：允许测试观察 `input()` 被调用（不改变生产行为）。
  void Function(FlowInput)? onInputForTest;

  @override
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    // KeyDown 与 KeyRepeat 都要响应；KeyUp 忽略
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final k = event.logicalKey;

    FlowInput? i;
    if (k == LogicalKeyboardKey.arrowUp || k == LogicalKeyboardKey.keyW) {
      i = FlowInput.up;
    } else if (k == LogicalKeyboardKey.arrowDown ||
        k == LogicalKeyboardKey.keyS) {
      i = FlowInput.down;
    } else if (k == LogicalKeyboardKey.arrowLeft ||
        k == LogicalKeyboardKey.keyA) {
      i = FlowInput.left;
    } else if (k == LogicalKeyboardKey.arrowRight ||
        k == LogicalKeyboardKey.keyD) {
      i = FlowInput.right;
    } else if (k == LogicalKeyboardKey.keyZ ||
        k == LogicalKeyboardKey.enter ||
        k == LogicalKeyboardKey.space) {
      i = FlowInput.confirm;
    } else if (k == LogicalKeyboardKey.keyX ||
        k == LogicalKeyboardKey.escape) {
      i = FlowInput.cancel;
    } else if (k == LogicalKeyboardKey.keyE) {
      i = FlowInput.endTurn;
    } else if (k == LogicalKeyboardKey.keyD && keysPressed.isEmpty) {
      i = FlowInput.startDialogue;
    }
    if (i == null) return KeyEventResult.ignored;
    input(i);
    return KeyEventResult.handled;
  }

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

      _battleView = BattleView(tileSize: metatileSize.toDouble());
      world.add(_battleView!.layer);

      // 场景表现层挂 viewport —— 见 scene_view.dart 里的说明
      _sceneView = SceneView(onHudChanged: _updateHud);
      _sceneView!.attachTo(camera.viewport);
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

    _loadSceneData();

    // ⚠️ 序章是**进章就演**的，不需要玩家先按键。
    //
    // 第一版把它挂在"按 dialogue 键"上，结果：进游戏后画面一直不动，
    // 直到按键才开始 —— 而脚本里 `STAL(60)` 之类还要再等一秒。
    // 而且序章第一段对白在剧本里本来就排在开头，不该等输入。
    if (scene != null) unawaited(_startRealScene());
  }

  /// 按脚本驱动一串输入（调试 / 视觉验证用）。
  ///
  /// 交互流程是纯状态机，所以"录一串按键再回放"天然可行——
  /// 这也是把它写成显式状态机的附带收益（原版的 Proc 协程做不到这点）。
  /// 回放一串输入（用于视觉验证）。
  ///
  /// ⚠️ **每个按键之间要等一会儿**：场景演出是 `async` 的，
  /// 按下的键只是完成一个 `Completer`，演出要继续得等微任务轮次。
  /// 第一版同步连着发，结果三个按键只推动了第一句 ——
  /// 截图上是"剧情 第0句"的空对话框。
  Future<void> runScript(String script) async {
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
      if (i != null) {
        input(i);
        await Future<void>.delayed(const Duration(milliseconds: 60));
      }
    }
  }

  /// 推进一次输入。
  ///
  /// **所有规则判断都在 `FlowMachine` 里**，这里只负责把新状态搬到画面上。
  void input(FlowInput i) {
    onInputForTest?.call(i);
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

  @override
  void update(double dt) {
    // 剧情演出的移动是**按帧推进**的：VM 已经因为 waitingForMove 停住，
    // 由这里把单位一格一格挪到位，挪完再通知 VM 继续。
    _tickEventMoves(dt);
    super.update(dt);
  }

  /// 开始剧情演出
  ///
  /// 优先演**真实场景脚本**（如果加载到了），否则退回 `eventVm` 的演示脚本。
  void startDialogue() {
    if (_sceneRunning) return;
    unawaited(_startRealScene());
  }

  /// 演出中发生一件事时调用。
  ///
  /// **每句话都等按键** —— 场景执行到这里会挂起，
  /// `advanceDialogue()` 放行后继续。这就是 `async/await` 的价值：
  /// "等玩家"不需要状态机来表达。
  Future<void> _onSceneEvent(SceneEvent e) async {
    switch (e) {
      case ShowText():
        _currentText = e;
        _sceneShown++;
        _updateSceneDialogue();
        _sceneWait = Completer<void>();
        await _sceneWait!.future;
      case WaitForInput():
        break; // ShowText 已经等过了
      case LoadUnits():
        _sceneHudExtra = '载入单位 ${e.table}';
      case Stall():
        await Future<void>.delayed(Duration(milliseconds: e.frames * 16));
      case MoveUnitInScene():
        _sceneHudExtra = e.op;
    }
  }

  String _sceneHudExtra = '';

  /// 演出真实场景：序章开场。
  ///
  /// 返回 false 表示数据没加载到（那就退回演示脚本，而不是假装成功）。
  Future<void> _startRealScene() async {
    final sc = scene;
    final fn = allSceneFns[realSceneName];
    if (sc == null || fn == null) return;

    _sceneRunning = true;
    _sceneShown = 0;
    _showDialogue = true;
    _updateSceneDialogue();

    await fn(sc);

    _sceneRunning = false;
    _currentText = null;
    _showDialogue = false;
    _updateSceneDialogue();
  }

  /// 该演的脚本 —— 序章开场。这是原作剧情的第一段。
  static const String realSceneName = 'EventScr_Prologue_BeginningScene';

  /// 把当前这句对白画进对话框
  void _updateSceneDialogue() {
    _sceneView?.applyEvent(
      _showDialogue ? _currentText : null,
      camera.viewport.virtualSize,
    );
  }




  /// 把 VM 排出的移动请求交给表现层。
  ///
  /// **规则层只描述意图（谁去哪儿），寻路与动画都在这里做** ——
  /// 与"渲染层不做规则判断"是同一条边界的两侧。
  void _consumeEventMoves() {
    final vm = eventVm;
    final st = eventState;
    if (vm == null || st == null) return;
    if (st.pendingMoves.isEmpty) {
      if (st.waitingForMove) vm.notifyMoveFinished(st);
      return;
    }

    for (final m in st.pendingMoves) {
      final u = field?.unitById(m.unitId);
      if (u == null) continue;

      // 目标解析：绝对坐标直接用；其余模式在这里补全
      int tx = m.toX;
      int ty = m.toY;
      switch (m.targetMode) {
        case MoveTargetMode.absolute:
          break;
        case MoveTargetMode.ontoUnit:
          final t = field?.unitById(m.targetUnitId);
          if (t == null) continue;
          tx = t.x;
          ty = t.y;
        case MoveTargetMode.oneStep:
          // 方向：0 上 / 1 下 / 2 左 / 3 右（先上下后左右）
          switch (m.direction) {
            case MoveDirection.up:
              ty -= 1;
            case MoveDirection.down:
              ty += 1;
            case MoveDirection.left:
              tx -= 1;
            case MoveDirection.right:
              tx += 1;
          }
        case MoveTargetMode.queuedPath:
          continue; // 路径队列未实现
      }

      if (m.instant) {
        field!.moveUnit(u, tx, ty);
      } else {
        _eventMoveTargets[u.id] = (tx, ty);
      }
    }
    st.pendingMoves.clear();
    _rebuildOverlay();
  }

  /// 每帧推进剧情移动（一格一格走，像个角色而不是瞬移）
  void _tickEventMoves(double dt) {
    if (_eventMoveTargets.isEmpty) return;
    _eventMoveAccum += dt;
    // 每 0.18 秒走一格
    if (_eventMoveAccum < 0.18) return;
    _eventMoveAccum = 0;

    final f = field;
    if (f == null) return;

    final done = <int>[];
    _eventMoveTargets.forEach((id, target) {
      final u = f.unitById(id);
      if (u == null) {
        done.add(id);
        return;
      }
      final (tx, ty) = target;
      if (u.x == tx && u.y == ty) {
        done.add(id);
        return;
      }
      // 先走 x 再走 y —— 简单的 L 形路径。
      // 真实寻路（绕开障碍）属于后续；M6 验证的是"事件能驱动单位移动"。
      if (u.x != tx) {
        f.moveUnit(u, u.x + (tx > u.x ? 1 : -1), u.y);
      } else {
        f.moveUnit(u, u.x, u.y + (ty > u.y ? 1 : -1));
      }
    });
    for (final id in done) {
      _eventMoveTargets.remove(id);
    }
    _rebuildOverlay();
    // ⚠️ 必须同时刷新 HUD。只重建画面会让 HUD 停在旧状态 ——
    // 表现出来就是"读数说单位还在原地，画面上它已经走了"。
    // 视觉验证靠的就是这个读数，它说谎等于没有验证。
    _rebuildDialogue();

    // 全部到位的瞬间解除 VM 的等待
    if (_eventMoveTargets.isEmpty) {
      final vm = eventVm;
      final st = eventState;
      if (vm != null && st != null && st.waitingForMove) {
        vm.notifyMoveFinished(st);
        vm.run(st);
        _consumeEventMoves();
      }
      _rebuildDialogue();
    }
  }

  /// 玩家按键推进对白
  void advanceDialogue() {
    // 场景模式：按键 → 放行挂起的演出
    if (inScene) {
      final w = _sceneWait;
      if (w != null && !w.isCompleted) {
        _sceneWait = null;
        w.complete();
      }
      return;
    }

    final vm = eventVm;
    final st = eventState;
    if (vm == null || st == null) return;

    if (st.waitingForPlayer) {
      vm.advanceFromPlayerInput(st);
    }
    vm.run(st);
    _consumeEventMoves();

    if (st.done) {
      _showDialogue = false;
      _rebuildDialogue();
      return;
    }
    _rebuildDialogue();
  }

  void _rebuildDialogue() {
    // 旧事件引擎的剧情也走同一个 SceneView —— 原来这里是**第二条平行路径**，
    // 两条都写 `_dialogue` 却挂在不同父节点上，路径交错会直接 assert 崩。
    final st = eventState;
    if (st == null) {
      _sceneView?.show(text: null, virtualSize: camera.viewport.virtualSize);
      return;
    }
    final pres = st.presentation;
    _sceneView?.show(
      text: _showDialogue ? st.lastText : null,
      virtualSize: camera.viewport.virtualSize,
      hostFace: pres.faces[0],
      guestFace: pres.faces[1],
    );
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

  /// HUD 上关于场景的一行（没有场景时为空）


  void _updateHud() {
    final s = state;
    final f = field;
    if (s == null || f == null) return;

    // ★ 场景模式（真实剧本）优先于演示剧情
    if (inScene) {
      final sc = scene;
      hud.value = _hudView
          .scene(
            shown: _sceneShown,
            current: _currentText,
            missing: sc?.missing ?? const {},
            placeholder: sc?.placeholderCalls ?? const {},
            extra: _sceneHudExtra,
          )
          .value;
      return;
    }

    final ev = eventState;
    if (_showDialogue && ev != null) {
      hud.value = _hudView
          .event(st: ev, field: f, pendingMoves: _eventMoveTargets.length)
          .value;
      return;
    }

    hud.value = _hudView
        .battle(
          field: f,
          state: s,
          rnConsumed: tracker.consumed,
          menu: menuOptions(s, f),
          lastCombat: lastCombat,
        )
        .value;
  }


  /// 按当前流程状态重建叠加层。
  ///
  /// 每次输入都整体重建，而不是增量更新——这个规模（十几到几十个组件）
  /// 重建的开销远小于"增量更新写错导致画面与状态不一致"的风险。
  void _rebuildOverlay() {
    final s = state;
    final f = field;
    final fl = flow;
    final v = _battleView;
    if (v == null || s == null || f == null || fl == null) return;
    v.rebuild(s, f, fl);
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
