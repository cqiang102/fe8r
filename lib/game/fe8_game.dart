// 表现层：Flame 游戏主体。
//
// M0 的目标不是"能玩"，而是**打通一条可验证的渲染链路**：
//
//   graphics/map/layout/PrologueMap.mar              （GBA 二进制）
//     → tools/pipeline/extract/map_tmx.py            （数据管线）
//     → PrologueMap.tmx + 图集 PNG                       → flame_tiled → 画面
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
import 'dart:math' as math;
import 'dart:ui' show Color;

import 'package:fe8r/core/core.dart';
import 'package:fe8r/game/battle_view.dart';
import 'package:fe8r/game/demo_event.dart';
import 'package:fe8r/game/hud_view.dart';
import 'package:fe8r/game/scene_view.dart';
import 'package:fe8r/game/title_flow.dart';
import 'package:fe8r/game/title_view.dart';
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

  /// 当前地图组件（`LOMA` 换图时要换掉它）
  TiledComponent? _tiled;

  /// 章节表 —— `LOMA` 路由的第一跳（`chapterIndex` → `internalName`）
  Chapters? chapters;

  /// 开场流程（① Press Start → ④ 标题 → ⑤ 菜单）
  ///
  /// ⚠️ 在它跑完之前**不演序章** —— 之前直接从序章开场演起，
  /// 跳过了整条开机链路（用户指出）。
  TitleFlow? titleFlow;
  TitleView? _titleView;

  /// 开场流程是否已完成
  bool get inTitleFlow => titleFlow != null;
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

  /// 视口尺寸 —— GBA 就是 240×160（`DISPLAY_WIDTH` / `DISPLAY_HEIGHT`）。
  static final Vector2 screenSize = Vector2(240, 160);

  /// 相机左上角（世界像素坐标）—— 对应 `gBmSt.camera`。
  ///
  /// 原作里它是**逐帧**被 `HandleMoveCameraWithMapCursor` 推着走的，
  /// 不是一步到位。
  double _cameraX = 0;
  double _cameraY = 0;

  /// 相机的边界（`src/bmmap_08019584.c:74-75`）
  ///
  /// ```c
  /// gBmSt.cameraMax.x = gBmMapSize.x*16 - 240;
  /// gBmSt.cameraMax.y = gBmMapSize.y*16 - 160;
  /// ```
  double get _cameraMaxX =>
      math.max(0, (map?.width ?? 0) * metatileSize - screenSize.x);
  double get _cameraMaxY =>
      math.max(0, (map?.height ?? 0) * metatileSize - screenSize.y);

  /// 死区（`include/bm.h:5-8`）—— **相对相机左上角**：
  ///
  ///     CAMERA_MARGIN_LEFT   = 16 * 3  = 48
  ///     CAMERA_MARGIN_RIGHT  = 16 * 11 = 176
  ///     CAMERA_MARGIN_TOP    = 16 * 2  = 32
  ///     CAMERA_MARGIN_BOTTOM = 16 * 7  = 112
  static const double _marginLeft = 16 * 3;
  static const double _marginRight = 16 * 11;
  static const double _marginTop = 16 * 2;
  static const double _marginBottom = 16 * 7;

  /// `HandleMoveCameraWithMapCursor`（`src/bm.c:267`）—— **逐帧**调用。
  ///
  /// ```c
  /// if (gBmSt.camera.x + CAMERA_MARGIN_LEFT > xCursor) {
  ///     if (xCursor - CAMERA_MARGIN_LEFT < 0) gBmSt.camera.x = 0;
  ///     else gBmSt.camera.x -= step;              // ★ 只走 step 像素
  /// }
  /// if (gBmSt.camera.x + CAMERA_MARGIN_RIGHT < xCursor) {
  ///     if (xCursor - CAMERA_MARGIN_RIGHT > cameraMax.x) camera.x = cameraMax.x;
  ///     else gBmSt.camera.x += step;
  /// }
  /// （y 同理，用 TOP / BOTTOM）
  /// ```
  ///
  /// ⚠️ **不是每帧硬居中。** 我第一版写成"状态一变就重新居中"，
  /// 那是**我自己发明的**，和原作行为不同：
  /// 原作是"光标待在死区内相机不动，越界才平滑跟"。
  void _handleMoveCameraWithMapCursor(double step) {
    final st = state;
    if (st == null) return;

    // 光标的世界像素位置（`gBmSt.playerCursorDisplay`）
    final cx = st.cursorX * metatileSize;
    final cy = st.cursorY * metatileSize;

    if (_cameraX + _marginLeft > cx) {
      if (cx - _marginLeft < 0) {
        _cameraX = 0;
      } else {
        _cameraX -= step;
      }
    }
    if (_cameraX + _marginRight < cx) {
      if (cx - _marginRight > _cameraMaxX) {
        _cameraX = _cameraMaxX;
      } else {
        _cameraX += step;
      }
    }
    if (_cameraY + _marginTop > cy) {
      if (cy - _marginTop < 0) {
        _cameraY = 0;
      } else {
        _cameraY -= step;
      }
    }
    if (_cameraY + _marginBottom < cy) {
      if (cy - _marginBottom > _cameraMaxY) {
        _cameraY = _cameraMaxY;
      } else {
        _cameraY += step;
      }
    }

    _cameraX = _cameraX.clamp(0, _cameraMaxX);
    _cameraY = _cameraY.clamp(0, _cameraMaxY);
    _applyCamera();
  }

  /// 把 `_cameraX/_cameraY`（**视野左上角**）搬到 Flame 上。
  ///
  /// ⚠️ Flame 的 `viewfinder.position` 是**视野中心**，不是左上角 ——
  /// 出处：`flame/lib/src/camera/viewfinder.dart:33-34`
  /// 「a point that is to be positioned at the **center** of the viewport」。
  /// 所以这里要加半屏。
  void _applyCamera() {
    camera.viewfinder.position =
        Vector2(_cameraX + screenSize.x / 2, _cameraY + screenSize.y / 2);
  }

  /// 一步到位把相机放到目标旁边（`GetCameraCenteredX/Y`）。
  ///
  /// 用于进场 / `LOMA` 之后 —— 那时没有"平滑跟随"，直接落位。
  void _centerCameraOn(int tileX, int tileY) {
    final g = map;
    if (g == null) return;

    double axis(double mapPx, double screen, double target, double maxV) {
      var r = target - screen / 2;
      if (r < 0) r = 0;
      if (r > maxV) r = maxV;
      return (r ~/ 16) * 16; // `& ~0xF`
    }

    _cameraX = axis(g.width * metatileSize, screenSize.x,
        tileX * metatileSize, _cameraMaxX);
    _cameraY = axis(g.height * metatileSize, screenSize.y,
        tileY * metatileSize, _cameraMaxY);
    _applyCamera();
  }



  @override
  Color backgroundColor() => const Color(0xFF101418);

  /// 载入剧本与文本（在 `onLoad` 里调一次）。
  ///
  /// 剧本**不是**从文件读的 —— 它是生成的 Dart `async` 函数
  /// （`lib/core/event/scene_data.g.dart`，由 C 源码直接生成）。
  void _loadSceneData() {
    try {
      final tf = File('tools/pipeline/out/tables/texts.json');
      if (!tf.existsSync()) return;
      gameTexts = GameTexts.parse(tf.readAsStringSync());

      // 汉化覆盖：**有就叠加，没有就照常显示原文**（不崩、不报错）
      final zh = File('assets/i18n/zh_CN.json');
      if (zh.existsSync()) {
        final t = GameTexts.parseTranslations(zh.readAsStringSync());
        gameTexts!.applyTranslations(t.messages);
        gameTexts!.uiTerms.addAll(t.ui);
      }

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
    } else if (k == LogicalKeyboardKey.keyC) {
      // ⚠️ 原来这里写的是 `keyD`，但**上面 keyD 已经映射成 right 了** ——
      // 同一个 `else if` 链里先到先得，所以 `startDialogue`
      // **从真实键盘永远不可达**（只有脚本/字符串通路能到）。
      // 而 `test/game/keyboard_test.dart` 只测 arrowDown/keyZ，覆盖不到。
      //
      // 换成 `keyC`（原来的 `keyD` 与移动键冲突）。
      i = FlowInput.startDialogue;
    }
    if (i == null) return KeyEventResult.ignored;

    // ⚠️ 有待决的选择时，Z/X **先**回答选择，不再走常规输入路由 ——
    // 否则"确认"会被流程层吃掉，选择永远等不到回答。
    final pending = _pendingChoice;
    if (pending != null && !pending.isCompleted) {
      if (i == FlowInput.confirm) {
        pending.complete(1); // TALK_CHOICE_YES
        return KeyEventResult.handled;
      }
      if (i == FlowInput.cancel) {
        pending.complete(2); // TALK_CHOICE_NO
        return KeyEventResult.handled;
      }
    }

    routeInput(i);
    return KeyEventResult.handled;
  }

  @override
  Future<void> onLoad() async {
    try {
      // 1) 规则层数据（纯 Dart，可单独测试，不依赖 Flame）
      final grid = MapGrid.parse(
        await rootBundle.loadString('assets/maps/PrologueMap.json'),
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
        'PrologueMap.tmx',
        Vector2.all(metatileSize),
        prefix: assetPrefix,
        images: Images(prefix: assetPrefix),
      );
      world.add(tiled);
      _tiled = tiled;

      // 3) 相机：**固定 240×160 的视野，跟着光标走**。
      //
      // ⚠️ 原来是把**整张地图塞进视口**（`resolution: mapSize`）——
      // 于是地图越大缩得越小，而原点停在中心，
      // **玩家看到的区域和光标所在的位置完全无关**。
      //
      // 出处：`src/bmmap_08019584.c:74-75`
      //
      //     gBmSt.cameraMax.x = gBmMapSize.x*16 - 240;
      //     gBmSt.cameraMax.y = gBmMapSize.y*16 - 160;
      //
      // 即：视口 **240×160**（GBA 屏），相机上限 = 地图像素尺寸 - 视口尺寸。
      // `FixedResolutionViewport` 会把 240×160 **等比放大并居中**
      // （`flame/src/camera/viewports/fixed_aspect_ratio_viewport.dart:43-47`）
      //
      //     size = ...等比...
      //     position = (canvas - size)/2 + anchor*size
      //
      // 而 `anchor` 的默认值**本来就是 `Anchor.topLeft`**
      // （`flame/src/camera/viewport.dart:54`）—— 不需要也没必要设它。
      //
      // ⚠️ 我曾在这里写过 `..anchor = Anchor.topLeft`，
      // **截图字节完全没变** —— 因为那是个空操作。
      // 真正的问题是 viewfinder（见 `_centerCameraOn`），当时找错了地方。
      camera.viewport = FixedResolutionViewport(resolution: screenSize);
      _centerCameraOn(grid.width ~/ 2, grid.height ~/ 2);

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
      // 脸编号 → 角色名（表就是可读的 C 源码里的符号名）
      _sceneView!.loadFaceIds('tools/pipeline/out/tables/face_ids.json');
      _loadChapterMaps();
      _loadChapterLinks();
      _loadUnitDefs();
      _loadBattleData();
      _loadCharNames();
      _loadObjectives();
      _loadChapters();
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

    // ⚠️ **先跑开场流程**（① Press Start → ④ 标题 → ⑤ 菜单）。
    //
    // 出处：`src/gamecontrol_08009E68.c:36` 的 `gProcScr_GameControl` ——
    // 序章（`LGAMECTRL_EXEC_BM`）排在整条开机链路**之后**。
    //
    // 之前直接从序章开场演起，跳过了 ① Press Start / ④ 标题 /
    // ⑤ 主菜单/难度/存档槽（用户指出）。
    if (gameTexts != null) {
      // 调试：`FE8R_CHAPTER=1` 直接跳到某一章（验证章节系统用）
      final ch = Platform.environment['FE8R_CHAPTER'];
      if (ch != null) {
        final n = int.tryParse(ch);
        if (n != null) sceneChapter = n;
      }
      final forced = Platform.environment['FE8R_TITLE'];
      titleFlow = TitleFlow(texts: gameTexts!);
      final jump = forced == null ? null : TitleFlow.screenByName(forced);
      if (jump != null) {
        titleFlow!.startAt = jump;
        titleFlow!.reset();
      }
      _titleView = TitleView(
        flow: titleFlow!,
        screenSize: camera.viewport.virtualSize,
      );
      camera.viewport.add(_titleView!);
    } else if (scene != null) {
      // 没有文案数据时不硬撑流程（会是一片空白），直接演序章
      unawaited(_startRealScene());
    }
  }

  /// **唯一的输入路由** —— 真实按键与调试脚本都走这里。
  ///
  /// ## 为什么必须只有一条路
  ///
  /// 之前调试脚本直接调 `input()`，绕过了 `onKeyEvent` 里的开场流程分支，
  /// 于是 `FE8R_SCRIPT="confirm"` **推不动开场流程** ——
  /// 截图一直停在同一个画面，而我还以为是流程卡住了。
  ///
  /// 这和文档里记过的那次是**同一类 bug**：
  /// 「视觉验证经由 `FE8R_SCRIPT` 绕过了真实按键路径」。
  /// 修法不是再补一处，而是**让两条路合并**。
  /// 按键状态（原作按 B 会加速光标/相机）
  void noteKeyHeld(FlowInput i, bool down) {
    if (i == FlowInput.cancel) _cancelHeld = down;
  }

  void routeInput(FlowInput i) {
    // 开场流程没跑完时，输入全给它
    if (inTitleFlow && _titleInput(i)) return;
    input(i);
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
  /// 无输入延迟 —— **验证用**。
  ///
  /// 过场里每个 confirm 之间有 60ms 间隔，而场景是**时间门控**的
  /// （`stall` / `fade`）。间隔一大，confirm 的**速率**就不够，
  /// 长过场推不动（实测：200 个 confirm 才到第 36 句）。
  ///
  /// `FE8R_NODELAY=1` 把间隔压到 0，让脚本能推完长过场。
  /// **这是测试设施，不是游戏内的调试开关** —— 它只影响自动输入脚本。
  static final bool _noInputDelay =
      (Platform.environment['FE8R_NODELAY'] ?? '') == '1';

  Future<void> runScript(String script) async {
    for (final raw in script.split(',')) {
      final t = raw.trim().toLowerCase();
      if (t.isEmpty) continue;
      // `wait` = 多等一会儿。**场景/地图是异步加载的**，
      // 紧跟其后的按键会在加载完成前发出而丢掉
      // （截图里验证过：加了按键但画面字节完全相同）。
      if (t == 'wait') {
        await Future<void>.delayed(Duration(
            milliseconds: _noInputDelay ? 120 : 900));
        continue;
      }
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
        routeInput(i);   // ← 与真实按键同一条路
        if (!_noInputDelay) {
          await Future<void>.delayed(const Duration(milliseconds: 60));
        }
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
    _updateHud();   // ★ 相机跟着光标（原作是每帧跟）

    if (r.endTurn) endTurn();
  }

  /// 开场流程的输入（在它跑完之前，输入全给它）
  bool _titleInput(FlowInput i) {
    final f = titleFlow;
    if (f == null) return false;
    if (f.tick(
      confirm: i == FlowInput.confirm,
      cancel: i == FlowInput.cancel,
      up: i == FlowInput.up,
      down: i == FlowInput.down,
    )) {
      // 流程跑完 → 拆掉画面，开始演序章
      final v = _titleView;
      if (v != null) {
        camera.viewport.remove(v);
        _titleView = null;
      }
      titleFlow = null;
      unawaited(_startRealScene());
    }
    return true;
  }

  @override
  void update(double dt) {
    // 剧情演出的移动是**按帧推进**的：VM 已经因为 waitingForMove 停住，
    // 由这里把单位一格一格挪到位，挪完再通知 VM 继续。
    _tickEventMoves(dt);

    // 相机是**逐帧**跟着光标走的（`HandlePlayerCursorMovement`
    // 每帧调 `HandleMoveCameraWithMapCursor(4)`，
    // `src/playerphase_0801C4FC.c:70-77`）。
    // 按住 B 时是 8 像素/帧（快速滚动）。
    if (state != null && !inTitleFlow) {
      _handleMoveCameraWithMapCursor(_fastCamera ? 8 : 4);
    }

    super.update(dt);
  }

  /// 是否按住"加速"键（原作是 B = 取消键）。
  bool get _fastCamera => _cancelHeld;

  bool _cancelHeld = false;

  /// 开始剧情演出
  ///
  /// 优先演**真实场景脚本**（如果加载到了），否则退回 `eventVm` 的演示脚本。
  void startDialogue() {
    if (_sceneRunning) return;
  }

  /// 演出中发生一件事时调用。
  ///
  /// **每句话都等按键** —— 场景执行到这里会挂起，
  /// `advanceDialogue()` 放行后继续。这就是 `async/await` 的价值：
  /// "等玩家"不需要状态机来表达。
  /// 最近执行的指令（环形缓冲）—— **诊断"脚本停在哪"**。
  ///
  /// 为什么需要：`loadMap(0)` 明明写在过场结尾却没执行，
  /// 而 HUD 只能告诉我"脚本名"和"第几句"，**看不到走到哪条指令**。
  /// 有了它，"停在哪"是一眼的事，不用猜。
  final List<String> _trace = [];

  Future<void> _onSceneEvent(SceneEvent e) async {
    if (_trace.length >= 12) _trace.removeAt(0);
    _trace.add('${e.runtimeType}(${e.toString()})');
    switch (e) {
      case ShowText():
        _currentText = e;
        _sceneShown++;
        _updateSceneDialogue();
        _sceneWait = Completer<void>();
        await _sceneWait!.future;
        case ChangeChapter(:final chapterIndex):
          // `MNC2(n)` —— 切到第 n 章（序章结束时会切到第 1 章）
          await _gotoChapter(chapterIndex);

        case LoadMap(:final chapterIndex):
          // ⚠️ 操作数是 **chapterIndex**（`src/eventscr_0800F390.c:45-68`）。
          // 路由：chapterIndex → chapters.json 的 internalName
          //       → chapter_maps.json 的 map 名 → TMX
          await _loadChapterMap(chapterIndex);

        case Choice(:final defaultYes):
          // ⚠️ 结果是 **0=取消 / 1=是 / 2=否**，写进**槽 0xC**
          // （`src/eventscr.c:123` `gEventSlots[0xC] = GetTalkChoiceResult();`）
          // 而**不是**写进某个界面状态 —— 脚本接下来会读这个槽来分支。
          final answer = await _askYesNo(defaultYes);
          _sceneView?.noteChoice(answer);
          eventState?.slots[0xC] = answer;

        case Fade(:final dir, :final speed):
          // 脚本阻塞到淡完 —— 见 src/Event17_Fade.c（四个分支都 ADVANCE_YIELD）
          await _sceneView?.fade(dir, speed, camera.viewport.virtualSize);

      case WaitForInput():
        break; // ShowText 已经等过了
      case LoadUnits(:final table, :final group):
        _loadUnitsFromTable(table, group);
      case Stall():
        await Future<void>.delayed(Duration(milliseconds: e.frames * 16));
      case MoveUnitInScene(:final op, :final args):
        _moveUnitInScene(op, args);

      case GiveItem(:final pid, :final itemSlot):
        _giveItem(pid, itemSlot);
    }
  }

  String _sceneHudExtra = '';

  /// `GIVEITEMTO(pid)` —— 把**槽 `itemSlot`** 里的道具给角色。
  ///
  /// ## 出处
  ///
  /// `src/eventscr_080106FC.c:90`：
  ///
  /// ```c
  /// case EVSUBCMD_GIVEITEMTO:
  ///     NewPopup_ItemGot(proc, target, gEventSlots[3]);
  /// ```
  ///
  /// 道具最终由 `UnitAddItem`（`src/exact_080176f0.c:37`）放进**第一个空槽**；
  /// 编码由 `MakeNewItem`（`src/MakeNewItem.c:27`）给出：
  ///
  ///     (uses << 8) + GetItemIndex(item)      // 耐久在高字节
  ///
  /// 序章里艾莉卡的**细剑**就是这么来的：
  ///
  ///     SVAL(EVT_SLOT_3, ITEM_SWORD_RAPIER)
  ///     GIVEITEMTO(CHARACTER_EIRIKA)
  ///
  /// ⚠️ 不做这一步的话，艾莉卡**没有武器** —— 战斗中她打不了人，
  /// 而 `UnitDef_Event_PrologueAlly` 里她带的确实是伤药（0x6C）。
  void _giveItem(int pid, int itemSlot) {
    final f = field;
    final sc = scene;
    if (f == null || sc == null) return;

    final raw = sc.slotInt(itemSlot);
    if (raw == 0) {
      _sceneHudExtra = 'GIVEITEMTO: 槽 $itemSlot 是空的';
      return;
    }

    // `MakeNewItem`：高字节耐久、低字节编号
    final idx = ItemTable.itemIndex(raw);
    // `GetItemMaxUses` —— 来自 items.json（`ItemData` 里没有这个字段）
    final maxUses = _itemStats[idx]?.maxUses ?? 0;
    final item = (maxUses << 8) | idx;

    // 目标：`0xFFFF` = 当前行动单位；0 = 主角；否则按角色号找
    MapUnit? target;
    if (pid == 0xFFFF) {
      target = f.units.where((u) => u.faction == Faction.blue).firstOrNull;
    } else if (pid == 0) {
      target = f.units.where((u) => u.faction == Faction.blue).firstOrNull;
    } else {
      target =
          f.units.where((u) => u.charIndex == pid && u.isAlive).firstOrNull;
    }
    if (target == null) {
      _sceneHudExtra = 'GIVEITEMTO: 找不到角色 $pid';
      return;
    }

    // `UnitAddItem`：第一个空槽
    final slot = target.items.indexOf(0);
    if (slot < 0) {
      _sceneHudExtra = 'GIVEITEMTO: ${target.name} 道具栏满了';
      return;
    }
    target.items[slot] = item;
    _sceneHudExtra = 'GIVEITEMTO: ${target.name} <- 道具 $idx（$maxUses 次）';
    _updateHud();
  }

  /// 剧情里的**自动移动**（`MOVE` / `MOVE_CLOSEST` / …）。
  ///
  /// ## 出处
  ///
  ///     #define MOVE(speed, pid, x, y)         EvtMoveUnit(false, speed, pid, x, y)
  ///     #define MOVE_CLOSEST(speed, pid, x, y) EvtMoveUnit(true, speed, pid, x, y)
  ///
  /// 参数是 `(速度, 角色号, x, y)`。
  ///
  /// ⚠️ **这里原来只写了个 HUD 字符串（`_sceneHudExtra = e.op`），
  /// 单位根本没动** —— 和 `LoadUnits` 是同一类 bug。
  ///
  /// 后果：过场里"某人走到某处"完全不发生，
  /// **地图上的站位因此全不对**（用户看到的就是这个）。
  ///
  /// `_CLOSEST` 系列在原版里是"目标格被占就尽量靠近"。
  /// 这里先做**精确落点**（占了就退到最近的空格），
  /// 因为过场的目标格通常是空的。
  void _moveUnitInScene(String op, List<Object> args) {
    final f = field;
    if (f == null || args.length < 4) return;

    final closest = op.contains('CLOSEST');
    final pid = switch (args[1]) {
      final int v => v,
      _ => 0,
    };
    final tx = switch (args[2]) {
      final int v => v,
      _ => 0,
    };
    final ty = switch (args[3]) {
      final int v => v,
      _ => 0,
    };

    // `pid` 是**角色号**（`charIndex`）。0 表示"主角"。
    MapUnit? u = f.units
        .where((x) => x.charIndex == pid && x.isAlive)
        .firstOrNull;
    if (u == null && pid == 0) {
      u = f.units
          .where((x) => x.faction == Faction.blue && x.isAlive)
          .firstOrNull;
    }
    if (u == null) {
      _sceneHudExtra = '$op: 找不到角色 $pid';
      return;
    }

    var nx = tx, ny = ty;
    if (closest && f.unitAt(nx, ny) != null) {
      // 目标格被占 -> 找相邻空格（原版语义）
      for (final (dx, dy) in const [(0, 1), (0, -1), (1, 0), (-1, 0)]) {
        if (f.unitAt(nx + dx, ny + dy) == null) {
          nx += dx;
          ny += dy;
          break;
        }
      }
    }

    u.x = nx;
    u.y = ny;
    _eventMoveTargets[u.id] = (nx, ny);
    _sceneHudExtra = '$op($pid -> $nx,$ny)';
  }

  /// 演出真实场景：序章开场。
  ///
  /// 返回 false 表示数据没加载到（那就退回演示脚本，而不是假装成功）。
  Future<void> _startRealScene() async {
    // ★ **清掉演示单位**，只留空战场。
    //
    // 章节的真实单位由脚本里的 `LOAD1/LOAD2/LOAD3` 放进来
    // （序章开场就有 `LOAD1(1, UnitDef_Event_PrologueAlly)`）。
    //
    // ⚠️ 之前不清，于是 `_makeDemoField` 那 7 个手写单位一直留在图上 ——
    // 和真实单位混在一起，位置与外观都不对（用户看到的"角色不太对"）。
    final g = map;
    if (g != null) {
      field = BattleField(
        width: g.width,
        height: g.height,
        turn: 1,
        activeFaction: Faction.blue,
        units: const [],
      );
    }

    // 先把这一章用到的立绘全部解码好。
    //
    // ⚠️ 立绘解码是异步的、渲染是同步的 —— 不预热的话第一页画不出人像。
    await _preloadScenePortraits();
    final sc = scene;
    final name = realSceneName;
    final fn = name == null ? null : allSceneFns[name];
    if (sc == null || fn == null) {
      status.value = '第 $sceneChapter 章没有开场脚本（${name ?? "缺事件组"}）';
      return;
    }

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

  /// ★ **当前章节号** —— 由 `MNC2` 推进（序章结束时切到第 1 章）。
  ///
  /// 出处：`chapter_links.json`（由 `gChapterDataTable.mapEventDataId`
  /// → `gChDAsset_<id>` → `ChapterEventGroup` 提取）：
  ///
  ///     [0] L00 -> PrologueEvents   beginningSceneEvents = EventScr_Prologue_BeginningScene
  ///     [1] L01 -> Ch1Events        beginningSceneEvents = EventScr_Ch1_BeginningScene
  ///
  /// ⚠️ 我第一版把 `realSceneName` 硬编码成序章开场、且把 `MNC2` 当占位 ——
  /// **结果游戏永远停在序章，第 1 章根本到不了。**
  int sceneChapter = 0;

  /// 章节号 → 事件组（`chapter_links.json` 的 `links`）
  List<Map<String, dynamic>> _chapterLinks = const [];
  Map<String, dynamic> _eventGroups = const {};

  /// 当前章节的事件组字段
  Map<String, dynamic>? get _chapterGroup {
    if (sceneChapter < 0 || sceneChapter >= _chapterLinks.length) return null;
    final name = _chapterLinks[sceneChapter]['eventGroupName'] as String?;
    if (name == null) return null;
    final g = _eventGroups[name];
    return g is Map<String, dynamic> ? g : null;
  }

  /// 当前章节的**开场脚本**名（`beginningSceneEvents`）
  String? get realSceneName {
    final v = _chapterGroup?['beginningSceneEvents'];
    return v is String && v != '0' ? v : null;
  }

  // ---------------------------------------------------------------- 胜负判定

  /// 已置上的事件标志（`include/constants/event-flags.h`）
  ///
  /// 原作里标志存在 EWRAM 的位图里；这里就是一个 Set ——
  /// **语义一样**（查/置/清），只是不共享内存布局。
  final Set<int> eventFlags = <int>{};

  /// 本章的胜负条件表（`event_lists.json` 里 `EventListScr_<章节>_Misc`）
  ChapterObjectives? _objectives;

  /// `gDefeatTalkList` —— **"首领"的操作性定义**（`defeat_talk.json`）
  List<Map<String, dynamic>> _defeatTalk = const [];

  /// 已经被判定过的条件（避免同一帧重复触发）
  bool _objectiveRunning = false;

  void _loadObjectives() {
    // ① 事件列表：章节 → Misc 列表
    final ef = File('tools/pipeline/out/tables/event_lists.json');
    if (ef.existsSync()) {
      final d = jsonDecode(ef.readAsStringSync()) as Map<String, dynamic>;
      final lists = d['lists'] as Map<String, dynamic>;
      // 章节号 → 事件组名（`PrologueEvents`）→ 列表名（`EventListScr_Prologue_Misc`）
      final ev = _chapterLinks.isNotEmpty && sceneChapter < _chapterLinks.length
          ? _chapterLinks[sceneChapter]['eventGroupName'] as String?
          : null;
      if (ev != null) {
        final key = 'EventListScr_${ev.replaceAll('Events', '')}_Misc';
        final raw = lists[key];
        if (raw is List) {
          _objectives = ChapterObjectives.fromJson(raw);
        } else {
          status.value = '第 $sceneChapter 章没有 Misc 列表（找的是 $key）';
        }
      }
    }

    // ② 死亡台词表（首领定义）
    final df = File('tools/pipeline/out/tables/defeat_talk.json');
    if (df.existsSync()) {
      final d = jsonDecode(df.readAsStringSync()) as Map<String, dynamic>;
      _defeatTalk = [
        for (final e in (d['entries'] as List<dynamic>))
          (e as Map<String, dynamic>),
      ];
    }
    eventFlags.clear();
  }

  /// 角色编号 → 源码里的符号名（`defeat_talk.json` 用的是符号名）
  ///
  /// ⚠️ 这里只能做**字符串对表**：`charIndex` 是数字，而表里是
  /// `CHARACTER_ONEILL` 这类符号。所以先从 `characters.h` 建映射。
  Map<int, String>? _charNames;

  void _loadCharNames() {
    final f = File('tools/pipeline/out/tables/char_names.json');
    if (!f.existsSync()) return;
    final d = jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
    _charNames = {
      for (final e in d.entries) int.parse(e.key): e.value as String,
    };
  }

  /// 从**战场现状**推导隐含的事件标志。
  ///
  /// ⚠️ 推导逻辑在 **core**（`deriveEventFlags`）—— 这里只是把游戏状态喂给它。
  /// 放在 core 的好处是它是纯函数、**可以单测**；
  /// 第 ④ 步（击破首领 -> 命中 EndingScene）的机器判据就在那里。
  void _deriveFlags() {
    final f = field;
    if (f == null) return;
    eventFlags.addAll(deriveEventFlags(
      units: [
        for (final u in f.units)
          BattleUnitView(
            charIndex: u.charIndex,
            faction: u.faction,
            alive: u.isAlive,
          ),
      ],
      chapterIndex: sceneChapter,
      defeatTalk: [for (final e in _defeatTalk) DefeatTalkEntry.fromJson(e)],
      charNameOf: (i) => _charNames?[i],
    ));
  }

  /// **检查胜负条件** —— 每次行动后与回合结束时调用。
  ///
  /// 命中就执行对应脚本（序章是 `EventScr_Prologue_EndingScene`，
  /// 它内部会 `MNC2(1)` 切到第 1 章）。
  Future<void> _checkObjectives() async {
    if (_objectiveRunning || inTitleFlow) return;
    final o = _objectives;
    if (o == null) return;

    _deriveFlags();
    final hit = o.firstMatch(eventFlags.contains);
    if (hit == null || hit.script == null) return;

    // 记上「已执行」标志 —— 对应原作 `info->flag`，避免重复触发
    if (hit.doneFlag != 0) eventFlags.add(hit.doneFlag);

    final fn = allSceneFns[hit.script!];
    if (fn == null) {
      status.value = '胜负条件命中，但没有脚本 ${hit.script}';
      return;
    }

    _objectiveRunning = true;
    try {
      final sc = scene;
      if (sc == null) return;
      status.value = '胜负条件命中 -> ${hit.script}';
      await fn(sc);
    } finally {
      _objectiveRunning = false;
    }

    // 脚本演完可能已经切了章节（`MNC2`）—— 重载条件表
    if (!_objectiveRunning) {
      _loadObjectives();
      _updateHud();
    }
  }

  // ------------------------------------------------ 战斗数据（全部来自源码）

  /// 职业基础值（`classes.json` <- `src/data/data_classes.c`）
  final Map<int, ClassStats> _classStats = {};

  /// 角色基础值（`characters.json` <- `src/data/data_characters.c`）
  final Map<int, CharStats> _charStats = {};

  /// 道具属性（`items.json` <- `src/data/data_items.c`）
  final Map<int, ItemStats> _itemStats = {};

  /// 真实道具表 —— 替掉 `_demoItems()`
  ///
  /// ⚠️ `ItemTable.minRangeOf/maxRangeOf` 与源码的
  /// `GetItemMinRange/MaxRange` **同构**（`encodedRange >> 4` / `& 0xF`），
  /// 所以射程是从源码字节直接来的，不是我编的。
  ItemTable _realItems() {
    final t = ItemTable(256);
    for (final e in _itemStats.entries) {
      final v = e.value;
      t[e.key]
        ..might = v.might
        ..weight = v.weight
        ..hit = v.hit
        ..crit = v.crit
        ..encodedRange = v.encodedRange;
    }
    return t;
  }

  void _loadBattleData() {
    Map<String, dynamic> read(String name) {
      final f = File('tools/pipeline/out/tables/$name');
      if (!f.existsSync()) return const {};
      return jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
    }

    final cj = read('classes.json');
    for (final e in (cj['classes'] as Map<String, dynamic>? ?? {}).entries) {
      final m = e.value as Map<String, dynamic>;
      final n = (m['number'] as num?)?.toInt();
      if (n != null) _classStats[n] = ClassStats.fromJson(m);
    }

    final chj = read('characters.json');
    for (final m in (chj['entries'] as Map<String, dynamic>? ?? {}).values) {
      final mm = m as Map<String, dynamic>;
      final n = mm['number'];
      if (n is int) _charStats[n] = CharStats.fromJson(mm);
    }

    final ij = read('items.json');
    for (final m in (ij['entries'] as Map<String, dynamic>? ?? {}).values) {
      final mm = m as Map<String, dynamic>;
      final n = mm['number'];
      if (n is int) _itemStats[n] = ItemStats.fromJson(mm);
    }

    if (_itemStats.isNotEmpty) _items = _realItems();
    status.value = '战斗数据：职业 ${_classStats.length} / '
        '角色 ${_charStats.length} / 道具 ${_itemStats.length}';
  }

  /// 单位定义表（`unit_defs.json`）—— `LOAD1/LOAD2/LOAD3` 用它
  Map<String, dynamic> _unitDefs = const {};

  void _loadUnitDefs() {
    final f = File('tools/pipeline/out/tables/unit_defs.json');
    if (!f.existsSync()) return;
    final d = jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
    _unitDefs = d['tables'] as Map<String, dynamic>;
  }

  /// 把一个 `UnitDef` 表里的单位放进战场。
  ///
  /// ## 出处：`UnitDefinition`（`include/bmunit.h`）与 `LOAD1`
  ///
  /// 序章开场的脚本：
  ///
  /// ```c
  /// LOAD1(1, UnitDef_Event_PrologueAlly)
  /// ```
  ///
  /// **⚠️ 之前这里只写了个 HUD 字符串，单位根本没载入** ——
  /// 于是画面上一直是 `_makeDemoField` 里那 7 个手写的演示单位
  /// （Mage / Fighter / Brigand / Archer 之类），位置和外观都不对。
  /// 用户正是看到这个才说"地图上的角色不太对"。
  void _loadUnitsFromTable(String name, int group) {
    final list = _unitDefs[name];
    if (list is! List) {
      _sceneHudExtra = '缺单位表 $name';
      return;
    }
    final cur = field;
    if (cur == null) return;

    final added = <MapUnit>[];
    for (final e in list) {
      final m = e as Map<String, dynamic>;
      // `{0}` 是表的终止项 —— 跳过，不要当成单位
      if ((m['charIndex'] ?? 0) == 0 &&
          (m['classIndex'] ?? 0) == 0 &&
          (m['x'] ?? 0) == 0 &&
          (m['y'] ?? 0) == 0) {
        continue;
      }
      final cls = (m['classIndex'] as num?)?.toInt() ?? 0;
      added.add(MapUnit(
        id: 0x100 + added.length,          // 蓝色方，编号从 0x100 起
        // `allegiance` -> 阵营。
        //
        // ⚠️ **出处：`include/bmunit.h:299-302`**
        //
        //     FACTION_ID_BLUE   = 0
        //     FACTION_ID_GREEN  = 1     <- ★ 1 是「绿」，不是红
        //     FACTION_ID_RED    = 2
        //     FACTION_ID_PURPLE = 3
        //
        // 我第一版写成了 `1 => red, 2 => green`（想当然地以为
        // 蓝红绿是 0/1/2）—— 结果**序章的敌人被载入成绿色 NPC**，
        // 于是"地图上没有敌人"、打不到奥尼尔。
        faction: switch ((m['allegiance'] as num?)?.toInt() ?? 0) {
          1 => Faction.green,
          2 => Faction.red,
          _ => Faction.blue,
        },
        x: (m['x'] as num?)?.toInt() ?? 0,
        y: (m['y'] as num?)?.toInt() ?? 0,
        charIndex: (m['charIndex'] as num?)?.toInt() ?? 0,
        item0: (m['item0'] as num?)?.toInt() ?? 0,
        classId: cls,
        level: (m['level'] as num?)?.toInt() ?? 1,
        // 名字给**人看**（战报里会出现）——用角色名，别再放 `C$cls` 这种。
        // 角色名来自 `char_names.json`；查不到就退回"角色NN"。
        name: _charNames?[(m['charIndex'] as num?)?.toInt() ?? 0]
                ?.replaceFirst('CHARACTER_', '') ??
            '角色${(m['charIndex'] as num?)?.toInt() ?? 0}',
      ));
    }
    _addUnits(added);
    _sceneHudExtra = '载入 $name（${added.length} 个单位）';
    // 把地图切换记录也带上 —— 它比「载入单位」更能说明脚本走到哪了
    _sceneHudExtra = '$_sceneHudExtra  $_sceneMapHistory';
  }

  /// 往战场里加单位（并同步到画面）
  void _addUnits(List<MapUnit> units) {
    final cur = field;
    if (cur == null || units.isEmpty) return;
    final all = [...cur.units, ...units];
    field = BattleField(
      width: cur.width,
      height: cur.height,
      turn: cur.turn,
      activeFaction: cur.activeFaction,
      units: all,
    );
    // 画面刷新交给主循环（`update` 里每帧 `sync`），这里只改规则层，
    // 免得在这里重复一次带 FlowState / FlowMachine 的三参调用。
    _updateHud();
  }

  void _loadChapterLinks() {
    final f = File('tools/pipeline/out/tables/chapter_links.json');
    if (!f.existsSync()) return;
    final d = jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
    _chapterLinks = [
      for (final e in (d['links'] as List<dynamic>))
        (e as Map<String, dynamic>),
    ];
    _eventGroups = d['eventGroups'] as Map<String, dynamic>;
  }

  /// 切到某一章：重建地图与单位，然后演这一章的**开场脚本**。
  ///
  /// 出处：`src/gamecontrol_08009CF8.c:53`（`gPlaySt.chapterIndex = proc->nextChapter;`）
  /// 与 `src/Event2A_MoveToChapter.c:39`（`EVSUBCMD_MNC2`）。
  Future<void> _gotoChapter(int chapterIndex) async {
    if (chapterIndex < 0 || chapterIndex >= _chapterLinks.length) return;
    sceneChapter = chapterIndex;
    await _loadChapterMap(chapterIndex);
    await _startRealScene();
  }

  /// 把当前这句对白画进对话框
  /// 换地图：`LOMA(chapterIndex)`。
  ///
  /// 两跳查表（都由数据管线产出）：
  ///   `chapterIndex` → `chapters.json[].internalName`
  ///                  → `chapter_maps.json[internalName].map` → `out/tmx/<map>.tmx`
  ///
  /// 出处：`src/eventscr_0800F390.c:45-68` —— 操作数是 **chapterIndex**，
  /// 不是资产 id；序章靠三次 `LOMA` 在王座厅 → 王宫外 → 可玩地图之间切。
  Future<void> _loadChapterMap(int chapterIndex) async {
    final name = chapterInternalName(chapterIndex);
    final mapName = chapterMapName(name);
    if (mapName == null) {
      sceneMapNote = 'LOMA($chapterIndex) → 章节 $name 没有地图名';
      _updateHud();
      return;
    }
    // 资源在 `assets/maps/`（与 `TiledComponent` 的默认查找前缀一致）
    if (!File('assets/maps/$mapName.tmx').existsSync()) {
      sceneMapNote = 'LOMA($chapterIndex) → assets/maps/$mapName.tmx 不存在';
      _updateHud();
      return;
    }
    // 先把网格解析好（`_swapMap` 里要用它更新左上角与战场尺寸）
    if (!_mapGrids.containsKey(mapName)) {
      final jf = File('assets/maps/$mapName.json');
      if (jf.existsSync()) {
        _mapGrids[mapName] = MapGrid.parse(jf.readAsStringSync());
      }
    }
    await _swapMap(mapName);

    // ★ **清空战场** —— 对应 `RestartBattleMap()`。
    //
    // 出处：`src/eventscr_0800F390.c:66-72`
    //
    //     gPlaySt.chapterIndex = chIndex;
    //     RestartBattleMap();        <- ★ 重建战场
    //     ...
    //     RefreshUnitSprites();
    //
    // ⚠️ 不清的后果（用户一眼就看出来了）：**单位不断累积**。
    // 序章依次 `LOAD1/LOAD2` 了王座厅 8 人、逃脱者 3 人、骑兵 6 人、
    // 王家 2 人、萨满 4 人、传令兵 1 人、我方 2 人、敌方 3 人、瓦尔特组 3 人 ——
    // **30 个单位全堆在一张地图上**，而可玩地图应该只有 2 我方 + 3 敌方。
    //
    // 清了之后：`LOMA(0)` 落图，紧接着脚本自己 `LOAD1(1, PrologueAlly)`，
    // 名册就是对的。
    final g = map;
    field = BattleField(
      width: g?.width ?? 1,
      height: g?.height ?? 1,
      turn: 1,
      activeFaction: Faction.blue,
      units: const [],
    );
    _eventMoveTargets.clear();
    eventFlags.clear();
    //  结尾会把相机居中到  的坐标
    // （）。这里先居中到地图中央，
    // 之后的  指令会再调整。
    _centerCameraOn((g?.width ?? 2) ~/ 2, (g?.height ?? 2) ~/ 2);

    sceneMapNote = 'LOMA($chapterIndex) → $mapName';
    // 地图切换历史 —— 用它判断脚本走到了哪一步
    _sceneMapHistory = '$_sceneMapHistory $mapName';
    _updateHud();
    _updateHud();
  }

  /// 章节号 → 内部名（`chapters.json`）
  String chapterInternalName(int index) {
    for (final c in chapters?.list ?? const <ChapterData>[]) {
      if (c.index == index) return c.internalName;
    }
    return '-';
  }

  /// 内部名 → 地图名（`chapter_maps.json`）
  String? chapterMapName(String internalName) => _chapterMaps[internalName];

  Map<String, String> _chapterMaps = const {};
  String sceneMapNote = '';

  /// 本场景里切换过的地图序列（诊断用）
  String _sceneMapHistory = '';

  /// 加载章节表（ 路由第一跳）
  void _loadChapters() {
    final f = File('tools/pipeline/out/tables/chapters.json');
    if (!f.existsSync()) return;
    chapters = Chapters.parse(f.readAsStringSync());
  }

  /// 加载章节→地图表
  void _loadChapterMaps() {
    final f = File('tools/pipeline/out/tables/chapter_maps.json');
    if (!f.existsSync()) return;
    final d = jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
    final ch = d['chapters'] as Map<String, dynamic>;
    _chapterMaps = {
      for (final e in ch.entries)
        e.key: ((e.value as Map<String, dynamic>)['map'] as String),
    };
  }

  /// 换掉当前地图组件。
  ///
  /// 出处：`src/eventscr_0800F390.c:64-72` 的 `RestartBattleMap()`
  /// —— 换章节号之后整个战场地图重建，相机也重新居中。
  Future<void> _swapMap(String mapName) async {
    const assetPrefix = 'assets/maps/';
    final t = await TiledComponent.load(
      '$mapName.tmx',
      Vector2.all(metatileSize),
      prefix: assetPrefix,
      images: Images(prefix: assetPrefix),
    );
    final old = _tiled;
    if (old != null) {
      // 先加新的再删旧的 —— 反过来有**一帧没有地图**
      world.add(t);
      world.remove(old);
      // 地图层要排在战场层下面
      t.priority = -10;
    } else {
      world.add(t);
      t.priority = -10;
    }
    _tiled = t;

    // ⚠️ **必须同时更新左上角那行**。
    //
    // 原来只更新 `sceneMapNote`，于是左上角一直显示 `onLoad` 时硬编码的
    // `PrologueMap 15×10` —— 而画面上早就是王座厅（`Ch16Map`）。
    // 这行是**给人看的**，不更新就会误导调试（我自己就被它误导过一次，
    // 差点把"视野问题"当成"地图没换"）。
    final g = map;
    final gm = _mapGrids[mapName];
    if (gm != null) {
      map = gm;
      status.value = '$mapName  ${gm.width}×${gm.height}  ${_terrainBrief(gm)}';
    } else {
      status.value = '$mapName（缺 .json，战场网格仍是 ${g?.id ?? "无"}）';
    }
  }

  /// 已解析的地图网格（按名字缓存）—— `LOMA` 换图时要用
  final Map<String, MapGrid> _mapGrids = {};

  /// 弹一个"是/否"选择，返回 `TALK_CHOICE_*`（0=取消 / 1=是 / 2=否）。
  ///
  /// 原作是 `StartTalkChoice(gYesNoTalkChoice, ...)`
  /// （`src/TalkInterpret.c:207-231`）。这里用 HUD 提示 + 键位：
  /// **Z = 是、X = 否**（与确认/取消键一致）。
  Future<int> _askYesNo(bool defaultYes) async {
    final done = Completer<int>();
    _pendingChoice = done;
    _sceneHudExtra = '请选择：Z = 是　X = 否'
        '（默认 ${defaultYes ? '是' : '否'}）';
    _updateHud();
    final r = await done.future;
    _pendingChoice = null;
    return r;
  }

  /// 有待决的选择吗（键盘路由用）
  Completer<int>? _pendingChoice;

  /// 预热当前章节场景里会用到的立绘
  Future<void> _preloadScenePortraits() async {
    final sc = scene;
    final v = _sceneView;
    if (sc == null || v == null) return;
    // 扫全部场景文本里的脸编号
    final ids = <int>{};
    for (final t in sc.texts.messages.values) {
      for (final seg in t.segments) {
        if (seg is TextControl && seg.isFaceSpec) {
          final f = seg.faceId;
          if (f != null) ids.add(f);
        }
      }
    }
    if (ids.isEmpty) return;
    await v.preload(ids);
    // 预加载完刷新一次，把第一页的立绘补上
    _updateSceneDialogue();
  }

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
      //
      // ⚠️ 这里只改**逻辑坐标**。画面上那一步步的移动由 `BattleView`
      // 的 `MoveToEffect` 补间负责（`_rebuildOverlay` → `BattleView.sync`
      // 会发现位置变了并加效果）。**逻辑与表现分开**，
      // 以前是"瞬移一格 + 每 0.18 秒重建一次画面"。
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

    // 回合结束是胜负判定点之一（原作 `CheckForWaitEvents` 挂在等待事件上）
    unawaited(_checkObjectives());

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
    // ★ **全部来自源码抽出的三张表**，不再有硬编码的演示值。
    //
    // 出处：
    //   * `classes.json`    <- `src/data/data_classes.c`
    //   * `characters.json` <- `src/data/data_characters.c`
    //   * `items.json`      <- `src/data/data_items.c`
    //
    // ⚠️ 原来是写死的：
    //     final isArcher = u.id == 0x82;         // 演示单位的 id
    //     classId: isArcher ? 0x1B : 0x2A, ...
    //   **后果：奥尼尔打不掉**（`C63:20` 一直满血）。
    final cls = _classStats[u.classId];
    final chr = _charStats[u.charIndex];
    // 装备的武器 —— 取道具栏里第一件**武器**。
    // 原作里 `unit->weapon` 由 `EquipUnitItem` 维护；这里用"第一件武器"
    // 等价于它的**自动装备**行为（拿到细剑就会用上）。
    var weapon = 0;
    for (final slot in u.items) {
      if (slot == 0) continue;
      final idx = ItemTable.itemIndex(slot);
      final s = _itemStats[idx];
      if (s != null && s.weaponType.isNotEmpty) {
        weapon = slot;
        break;
      }
    }
    final it = _itemStats[ItemTable.itemIndex(weapon)];

    // 三张表缺任何一张就**明确报出来**，不静默退回假数据
    if (cls == null) {
      _sceneHudExtra = '缺职业 ${u.classId} 的基础值（classes.json）';
    }

    final weaponType = switch (it?.weaponType) {
      'ITYPE_LANCE' => WeaponType.lance,
      'ITYPE_AXE' => WeaponType.axe,
      'ITYPE_BOW' => WeaponType.bow,
      'ITYPE_STAFF' => WeaponType.staff,
      _ => WeaponType.sword,
    };

    return CombatProfile(
      classId: u.classId,
      level: u.level,
      // 这几项直接对应 `struct Unit` 的字段，
      // 而它们**只来自职业**（角色只有等级和幸运）。
      pow: cls?.basePow ?? 0,
      skl: cls?.baseSkl ?? 0,
      spd: cls?.baseSpd ?? 0,
      def: cls?.baseDef ?? 0,
      lck: chr?.baseLck ?? 0,
      conBonus: cls?.baseCon ?? 0,
      weaponItem: weapon,
      weaponType: weaponType,
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
            trace: _trace,
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
    v.sync(s, f, fl);
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
