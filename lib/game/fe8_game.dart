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
import 'dart:ui' show Color;

import 'package:fe8r/core/core.dart';
import 'package:fe8r/game/battle_components.dart';
import 'package:fe8r/game/ctl_server.dart';
import 'package:flutter/widgets.dart' show GlobalKey;
import 'package:fe8r/game/world_map_view.dart';
import 'package:fe8r/ui/debug_screenshot.dart';
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
  /// 相机上限 —— 实现在 `lib/core/map/camera.dart`（`cameraMaxX/Y`），
  /// 出处 `src/bmmap_08019584.c:74-75`。**不要再在这里写一份。**
  double get _cameraMaxX => cameraMaxX(map?.width ?? 0).toDouble();
  double get _cameraMaxY => cameraMaxY(map?.height ?? 0).toDouble();

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
  /// 把相机**居中**到某一格 —— `GetCameraCenteredX/Y`
  /// （`src/bm.c:381-410`，实现搬到了 `lib/core/map/camera.dart`）。
  void _centerCameraOn(int tileX, int tileY) {
    final g = map;
    if (g == null) return;
    _cameraX =
        cameraCenteredX((tileX * metatileSize).toInt(), _cameraMaxX.toInt())
            .toDouble();
    _cameraY =
        cameraCenteredY((tileY * metatileSize).toInt(), _cameraMaxY.toInt())
            .toDouble();
    _applyCamera();
  }

  /// 把相机对准某一格但不强行居中 —— `GetCameraAdjustedX/Y`
  /// （`src/bm.c:343-379`）。
  ///
  /// 这是 `CAMERA(x, y)`（**不是** `CAMERA2`）的语义：只有目标越出
  /// `CAMERA_MARGIN_*` 死区时才移动，而且**不做 16 像素对齐**。
  ///
  /// 序章王座厅那一幕靠它把镜头从地图中央压到王座上：
  /// `LOMA(0x10)` 之后相机在 `y=80`（居中于 (14,10)），
  /// `CAMERA(14, 0)` 把 y 顶到 0 —— 王座才进画面。
  void _adjustCameraTo(int tileX, int tileY) {
    final g = map;
    if (g == null) return;
    _cameraX =
        cameraAdjustedX(
                _cameraX.toInt(), (tileX * metatileSize).toInt(), _cameraMaxX.toInt())
            .toDouble();
    _cameraY =
        cameraAdjustedY(
                _cameraY.toInt(), (tileY * metatileSize).toInt(), _cameraMaxY.toInt())
            .toDouble();
    _applyCamera();
  }



  @override
  Color backgroundColor() => const Color(0xFF101418);

  /// ★ **把当前状态转储成 JSON** —— 让验证变成「读数据」而不是「猜像素」。
  ///
  /// ## 为什么需要
  ///
  /// 我一直在用**截图**做验证，而截图只证明"那一刻那一帧"。
  /// 后果：
  /// * 「开场链路 / 序章剧情 / 序章战斗都还有 bug」—— 用户看出来了，
  ///   因为**一张截图证明不了"这条链路"**
  /// * 单位 id 冲突那次，我盯着 HUD 上**对的数字**看了好几轮，
  ///   而错的是画面 —— 反过来也一样：**两边都要有机器可读的输出**
  ///
  /// 用法：`FE8R_DUMP=/tmp/state.json`，脚本跑完后写出。
  /// 内容刻意**从规则层取**（`field` / `state` / `scene`），
  /// 不经过任何渲染，所以它能和截图互相印证。
  Map<String, dynamic> dumpState() {
    final f = field;
    final st = state;
    final sc = scene;
    return {
      'chapter': sceneChapter,
      'map': f == null
          ? null
          : {'width': f.width, 'height': f.height, 'id': map?.id},
      'camera': {'x': _cameraX, 'y': _cameraY},
      'phase': st?.phase.name,
      'cursor': st == null ? null : {'x': st.cursorX, 'y': st.cursorY},
      'turn': f?.turn,
      'activeFaction': f?.activeFaction,
      'selectedUnitId': st?.selectedUnitId,
      // 单位：id 必须唯一 —— 转储里直接带上"是否唯一"，让 bug 无处可藏
      'units': [
        for (final u in f?.units ?? const <MapUnit>[])
          {
            'id': u.id,
            'name': u.name,
            'charIndex': u.charIndex,
            'classId': u.classId,
            'faction': u.faction,
            'x': u.x,
            'y': u.y,
            'hp': u.hp,
            'maxHp': u.maxHp,
            'alive': u.isAlive,
            // ★ **"本回合行动过没有" 必须能看见。**
            //
            // 两条"回合结束"（START→菜单→終了 / 所有单位行动完自动结束）
            // 操纵的正是这个状态：原版 `ClearActiveFactionGrayedStates`
            // 在每个阵营**自己的阶段结束**时清掉
            // `US_UNSELECTABLE | US_HAS_MOVED | US_HAS_MOVED_AI`
            // （`src/ClearActiveFactionGrayedStates.c:47-52`，
            // 由 `BmMain_ChangePhase` 在 `SwitchPhases()` **之前**调用，
            // `src/bm_08015434.c:82-95`）。
            //
            // 之前转储里没有这个字段 —— 也就是说"回合结束后单位还能不能动"
            // 这件事**当时根本没法观察**，只能靠看画面猜。
            'hasActed': u.hasActed,
            'items': u.items,
            'held': u.heldItems,
            'itemNames': [
              for (final it in u.heldItems)
                _itemNames[ItemTable.itemIndex(it)] ?? '?${ItemTable.itemIndex(it)}',
            ],
          },
      ],
      // `GetPhaseAbleUnitCount(faction)`（`src/bmphase.c:8-34`）的**分阵营**结果。
      // 自动结束的判据就是它 == 0（`src/playerphase_0801D808.c:52`）。
      'phaseAble': f == null
          ? null
          : {
              'blue': f.phaseAbleCount(Faction.blue),
              'green': f.phaseAbleCount(Faction.green),
              'red': f.phaseAbleCount(Faction.red),
              'active': f.activeFaction,
            },
      'unitIdsUnique': f == null
          ? null
          : f.units.map((u) => u.id).toSet().length == f.units.length,
      // ---- 渲染层 ----
      //
      // ⚠️ **必须分类计数**。原来只有一个 `componentCount`，而它把
      // 光标和标记也算进去了：`5 个单位 + 1 个光标 = 6`
      // 于是"6 ≠ 5"被我读成"有幽灵精灵" —— **那是假的**，指标本身错了。
      // 一个分不清自己在数什么的指标，比没有指标更糟。
      'render': {
        'unitComponents': _battleView?.unitComponentCount,
        'markerComponents': _battleView?.markerCount,
        'cursorComponents': _battleView?.cursorCount,
        'total': _battleView?.componentCount,
        'aliveUnits': f?.units.where((u) => u.isAlive).length,
        // 这一条才是判据：**渲染出来的单位组件数 == 存活单位数**
        'matches': _battleView == null || f == null
            ? null
            : _battleView!.unitComponentCount ==
                f.units.where((u) => u.isAlive).length,
      },
      'eventFlags': eventFlags.toList()..sort(),
      'scene': {
        // ⚠️ 原来是 `sc != null` —— 场景对象加载后一直非空，
        // 于是这个字段**恒为 true**，看起来像"场景在跑"，其实什么都没说。
        'running': _sceneRunning,
        'objectiveRunning': _objectiveRunning,
        'showDialogue': _showDialogue,
        'script': sc?.currentScript,
        'shown': _sceneShown,
        'currentTextId': _currentText?.message.id,
        'hudExtra': _sceneHudExtra,
        'slots': {
          // ⚠️ 键必须是 **String** —— `jsonEncode` 编不了 `Map<int, ...>`，
          // 而且是**只有在槽非空时**才炸：标题画面那会儿 `slots` 是空的，
          // 转储照写；一到序章（脚本真的用了槽）就整个转储失败。
          for (final k in const [0, 1, 2, 3, 0xC])
            if (sc?.slot(k) != null) '$k': '${sc!.slot(k)}',
        },
        'missing': sc?.missing.toList(),
        'placeholders': sc?.placeholderCalls.keys.toList(),
      },
      'titleFlow': titleFlow == null
          ? null
          : {
              'screen': titleFlow!.screen.name,
              'framesOnScreen': titleFlow!.framesOnScreen,
              'difficulty': titleFlow!.difficulty.name,
              'saveSlot': titleFlow!.saveSlot,
            },
      'objectiveHit': _lastObjectiveHit,
      // 胜负条件的**诊断**：列表有没有载入、当前能推出哪些标志、
      // 第一条命中的是谁。上一版只有 `objectiveHit`，于是"条件没命中"
      // 和"命中了但脚本名为 null"在转储里长得一模一样。
      'objectivesNote': _objectivesNote,
      'turnEventsNote': _turnEventsNote,
      'specialEventsNote': _specialEventsNote,
      'specialEventFired': _specialEventFired,
      'endEventNote': _endEventNote,
      'talksNote': _talksNote,
      'mapMenu': mapMenu == null
          ? null
          : {
              'index': mapMenu!.index,
              'item': mapMenu!.current.item.label,
              'itemCommand': mapMenu!.current.item.commandFn,
              'itemAvailability': mapMenu!.current.availability.name,
              // 只有 `MENU_NOTSHOWN` 之外的条目会在这里（`src/StartMenuCore.c:64`）
              'items': [
                for (final e in mapMenu!.entries)
                  e.isDisabled ? '${e.item.label}（灰）' : e.item.label
              ],
              // `src/StartMenuCore.c:92-98` 算出来的面板，单位是 UI 图块（8px）
              'layout': _mapMenuLayout == null
                  ? null
                  : {
                      'x': _mapMenuLayout!.x,
                      'y': _mapMenuLayout!.y,
                      'w': _mapMenuLayout!.w,
                      'h': _mapMenuLayout!.h,
                      'rowPitch': 2,
                    },
            },
      'mapMenuNote': _mapMenuNote,
      'mapMenuNoteLog': _mapMenuNoteLog.toList(),
      // ★ 决定"显示哪几条"的**输入**也摆出来 ——
      // 只报结论（"5 条"）的话，"输入是怎么来的"就被结论吸收掉了。
      'mapMenuInputs': _mapMenuInputs,
      // 选中了但**界面还没做**的条目，逐次记下来（不静默）
      'mapMenuUnimplemented': _mapMenuUnimplemented,
      'lastBattleQuote': _lastBattleQuote,
      'lastDefeatQuote': _lastDefeatQuote,
      'lastEndEvent': _lastEndEvent,
      'turnEventFired': _turnEventFired,
      'turnLoopNote': _turnLoopNote,
      // 卡住自证 + 回合横幅（用户反馈"卡住""没有回合提示"）
      'waitingFor': waitingFor,
      'phaseBanner': _bannerText,
      'lastPhaseBanner': _lastPhaseBanner,
      // 大地图（`MNCH` 之后）
      'worldMap': worldMap?.toJson(),
      'worldMapTarget': _wmTargetChapter,
      'pendingWorldMapTarget': _pendingWorldMapTarget,
      'worldMapNote': _worldMapNote,
      'lastWmBeginningScript': _lastWmBeginningScript,
      'popups': _popups.length,
      'flashes': _flashes.length,
      'hitFxLog': _hitFxLog.toList(),
      'suspendPath': _suspendPath,
      'suspendBytes': _suspendBytes,
      'suspendNote': _suspendNote,
      'resumeNote': resumeNote,
      'chapterStatus': chapterStatus == null
          ? null
          : {
              'unitIndex': chapterStatus!.unitIndex,
              'shownIndex': chapterStatus!.shownIndex,
              'unitCount': chapterStatus!.unitCount,
            },
      'statusNote': statusNote,
      'unitList': unitList == null
          ? null
          : {
              'index': unitList!.index,
              'count': unitList!.entryCount,
              'chosen': unitList!.chosenUnitId,
              'sortRequested': unitList!.sortRequested,
            },
      'unitListText': _unitListText,
      'gameOptions': gameOptions == null
          ? null
          : {
              'index': gameOptions!.index,
              'count': gameOptions!.count,
              'changes': gameOptions!.changes,
              'value': gameOptions!.current?.value,
            },
      'gameOptionsText': _gameOptionsText,
      'lastItemUse': lastItemUse,
      'lastEquip': lastEquip,
      'lastDiscard': lastDiscard,
      'goalWindow': goalWindow == null
          ? null
          : {
              'visible': goalWindow!.visible,
              'stage': '${goalWindow!.stage}',
              'shownCount': goalWindow!.shownCount,
              'wantVisible': goalWindow!.wantVisible,
            },
      'goalText': _goalText,
      'goalTextId': _chapterGoalTextId[sceneChapter],
      'forecast': forecastForTarget?.toJson(),
      'lastForecast': lastForecast,
      'playerAttackCount': playerAttackCount,
      'actionLog': actionLog.toList(),
      'terrainWindow': lastTerrainWindow,
      // 当前是否**该**显示（设置可能刚被改掉；`lastTerrainWindow` 是留档，不会自己消失）
      'terrainWindowVisible':
          terrainWindowVisible(disableTerrainDisplay: playConfig.disableTerrainDisplay),
      'disableTerrainDisplay': playConfig.disableTerrainDisplay,
      'minimug': {
        'unitId': _minimugUnitId,
        'text': _minimugText,
        'visible': _minimugComp != null,
        'unitDisplayType': playConfig.unitDisplayType,
      },
      'itemSubMenu': itemSubMenu,
      'subMenuDisabled': _subMenuDisabled,
      'equippedWeapon': _equippedWeaponWord(),
      'itemMenuText': _itemMenuText,
      'lastItemMenuText': lastItemMenuText,
      'lastSubMenuText': lastSubMenuText,
      'lastTradeMenuText': lastTradeMenuText,
      'lastTrade': lastTrade,
      'lastConfirmText': lastConfirmText,
      'discardPromptDefault': discardPromptDefault,
      'usableItemSlots': _usableSlots,
      'gameOptionsLast': _gameOptionsLast,
      'gameOptionsWired': gameOptionRowsHasMapping,
      'gameConfigFields': gameOptions == null
          ? null
          : Map<String, int>.from(
              gameOptions!.config?.values ?? const <String, int>{}),
      'disableAutoEndTurns': playConfig.disableAutoEndTurns,
      'statusText': _statusText,
      'resumable': titleFlow?.resumable ?? false,
      'popupLog': _popupLog.toList(),
      'damageDealtTotal': _damageDealtTotal,
      // 教学事件（两段式：入队 → 触发）
      'tutorial': tutorial.toJson(),
      'tutorialTableSize': _currentTutorials.length,
      'tutorialNote': _tutorialNote,
      'lastTutorialFired': _lastTutorialFired,
      // `gPlaySt.config` 现在只有这一项有行为影响
      'configDisableAutoEndTurns': playConfig.disableAutoEndTurns,
      // `RunPhaseSwitchEvents` 被跑过的次数（一次阶段切换一次 —— 判据用）
      'phaseSwitchEventRuns': _phaseSwitchEventRuns,
      'moveCostsNote': _moveCostsNote,
      'moveCostsWeather': _weatherNow.name,
      // 当前移动范围（选中单位时才有）——调"走到哪"这类脚本时，
      // 有它就不用靠猜（山峰不可通行之后尤其明显）
      'range': flow?.currentRange == null
          ? null
          : {
              'count': flow!.currentRange!.reachableCount,
              'tiles': [
                for (var y = 0; y < (field?.height ?? 0); y++)
                  for (var x = 0; x < (field?.width ?? 0); x++)
                    if (flow!.currentRange!.canReach(x, y)) '$x,$y',
              ],
            },
      'objectives': _objectives == null
          ? null
          : {
              'chapter': sceneChapter,
              'count': _objectives!.entries.length,
              'entries': [
                for (final e in _objectives!.entries)
                  {
                    'cmd': e.cmd,
                    'doneFlag': e.doneFlag,
                    'checkFlag': e.checkFlag,
                    'script': e.script,
                  },
              ],
              // 只算不改：把当前能推导出的标志列出来
              'derivedFlags': (field == null)
                  ? null
                  : (deriveEventFlags(
                      units: [
                        for (final u in field!.units)
                          BattleUnitView(
                            charIndex: u.charIndex,
                            faction: u.faction,
                            alive: u.isAlive,
                          ),
                      ],
                      chapterIndex: sceneChapter,
                      defeatTalk: [
                        for (final e in _defeatTalk) DefeatTalkEntry.fromJson(e)
                      ],
                    ).toList()
                      ..sort()),
              'firstMatch': _objectives!
                  .firstMatch(eventFlags.contains)
                  ?.script,
            },
      'mapHistory': _sceneMapHistory.trim(),
      // ⚠️ `mapHistory` 只记**成功**的切换。失败的那次原来哪都不写 ——
      // 于是"序章有三张图"这件事在我自己的诊断里也是完整的，
      // 缺的那张根本不在记录里（我就这么漏掉了"王宫外"那一幕）。
      'mapNote': sceneMapNote,
      'mapLoadFailures': _mapLoadFailures.toList(),
      'trace': _trace.toList(),
      'lastCombat': lastCombat,
      'hud': hud.value,
      'status': status.value,
    };
  }

  /// 道具编号 → 源码里的名字（只用于**转储**，让人一眼看懂带的是什么）
  final Map<int, String> _itemNames = {};

  /// 最近一次命中的胜负条件（诊断用）
  String? _lastObjectiveHit;

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

  /// 测试钩子：按 `LOAD1` 的同一条路把一个单位定义表载入战场。
  ///
  /// 为什么需要：`_loadUnitsFromTable` 是私有的，而"道具栏按源码装载"
  /// 这件事**只有在真实表 + 真实道具表下才能验证**
  /// （赛特带 3 件、艾莉卡带 1 件、细剑放得进 1 号槽）。
  @visibleForTesting
  void loadUnitsForTest(String name, int group) =>
      _loadUnitsFromTable(name, group);

  /// 测试钩子：一个单位参与战斗的 profile —— **与真实战斗走同一个
  /// `_profileFor`**，所以它能测到"接没接上三张表"这类问题。
  @visibleForTesting
  CombatProfile profileForTest(MapUnit u) => _profileFor(u);

  /// 测试钩子：按编号取道具数据（诊断用）
  @visibleForTesting
  ItemStats? itemStatsForTest(int index) => _itemStats[index];

  /// **一次完整的攻击**（含对白/阵亡/以及行动之后的"等待事件 + 自动结束"）。
  ///
  /// 判据要能走 `_attackWithQuote` 这条真实路径 —— 原来的测试都是直接调
  /// `combat.attack(...)`，绕过了 `_afterUnitAction`，于是
  /// "最后一个能动的单位用攻击结束行动"时阶段不自动结束这件事
  /// **一直没被任何测试看到**。
  @visibleForTesting
  Future<void> attackWithQuoteForTest(MapUnit attacker, MapUnit defender) =>
      _attackWithQuote(field!, attacker, defender);

  /// `PlayerPhase_HandleAutoEnd` **判定命中**的次数。
  ///
  /// 用它当判据而不是"回合数 +1"：`_endTurn()` 需要 `state`（`FlowState`），
  /// 而单元测试里没有流程状态机 —— 只断言"最终回合数"会把
  /// "自动结束压根没被求值"和"求值了但后面没走完"混在一起。
  /// 这一条只问源码里那个问题：**`GetPhaseAbleUnitCount == 0` 被求值到了吗**。
  @visibleForTesting
  int autoEndTriggersForTest = 0;

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
    } else if (k == LogicalKeyboardKey.enter) {
      // ⚠️ **回车是 START，不是 A**（`src/event_0800D110.c:27`：
      // `newKeys & START_BUTTON` 触发快进剧情）。
      // 我原来把它当成 confirm 了。
      i = FlowInput.start;
    } else if (k == LogicalKeyboardKey.keyZ ||
        k == LogicalKeyboardKey.space) {
      i = FlowInput.confirm;
    } else if (k == LogicalKeyboardKey.keyX ||
        k == LogicalKeyboardKey.escape) {
      i = FlowInput.cancel;
    } else if (k == LogicalKeyboardKey.keyE) {
      i = FlowInput.endTurn;
    } else if (k == LogicalKeyboardKey.keyH) {
      // 试玩用：随时看/收起按键说明（不占用任何原作按键）
      toggleHelp();
      return KeyEventResult.handled;
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
      // 移动消耗表：**按单位（职业）× 当前天气**取（见 `_moveCostsOf`）
      flow = FlowMachine(map: grid, costsOf: _moveCostsOf);
      ai = EnemyAi(map: grid, costsOf: _moveCostsOf);
      // ⚠️ **章节链路必须先载入**，再载入规则层数据 ——
      // `_loadObjectives()` 要用 `_chapterLinks[chapter].eventGroupName`
      // 去拼 `EventListScr_<组名>_Misc`。顺序反了 `_chapterLinks` 就是空的，
      // **胜负条件表永远载不进来**（`_objectives == null`），
      // "打死首领 → 结束脚本 → 切章"这条链一步都不走 —— 而且不报错。
      _loadChapterMaps();
      _loadChapterLinks();
      // ★ 规则层数据表（职业/角色/道具/单位表/章节/胜负条件）——
      // 它同时负责建 `_items` 与 `combat`（**必须是同一个道具表对象**，
      // 否则伤害算在演示表上：细剑是 9 号而演示表只有 8 项 → 威力 0）。
      loadRuleData();
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
      // ⚠️ **章节链路必须在 `loadRuleData()` 之前** ——
      // `_loadObjectives()` 要用 `_chapterLinks[chapter].eventGroupName`
      // 去拼 `EventListScr_<组名>_Misc`。反过来的话 `_chapterLinks` 是空的，
      // **胜负条件表永远不会载入**（`_objectives == null`），
      // 于是"打死首领 → 结束脚本 → 切章"这条链一步都不走。
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
      if (ch != null && ch.isNotEmpty) {
        final n = int.tryParse(ch);
        if (n != null) sceneChapter = n;
      }
      // 调试：`FE8R_WM=56` 直接进大地图（和 `FE8R_TITLE` / `FE8R_CHAPTER` 同类，
      // **只用于开发**；正常流程由 `MNCH` 进入，见 `ChangeChapter.subcmd`）
      // ⚠️ **空字符串不是"未设置"**：`Platform.environment['X']` 对 `X=`
      // 返回 `''`，而 `int.tryParse('') ?? 0x38` 会兜成 0x38 ⇒ 连"没打算开
      // 大地图"的场景也被拽进大地图。实测代价：`scenario.sh battle` 从
      // "打死奥尼尔 → 第 1 章"变成 `chapter=0 / map=PrologueMap`（4 条判据红）。
      // 这就是 `FE8R_NODELAY` 那一类假信号的形状 —— 环境变量一律**判空**。
      final wmEnv = Platform.environment['FE8R_WM'];
      if (wmEnv != null && wmEnv.isNotEmpty) {
        // 走**同一条**路（待进入 → update 里进），这样调试入口与真实流程一致
        _pendingWorldMapTarget = int.tryParse(wmEnv) ?? 0x38;
      }

      // ★ 实时控制通道（`FE8R_CTL=<port>`）：AI/测试可以**边看状态边按键**，
      //   不用再猜一长串写死的输入（见 ctl_server.dart 的头注释）。
      unawaited(_startCtlIfRequested());

      final forced = Platform.environment['FE8R_TITLE'];
      titleFlow = _newTitleFlow();
      final jump = (forced == null || forced.isEmpty)
          ? null
          : TitleFlow.screenByName(forced);
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
    // ★ 道具子菜单开着时输入归它（`ItemSubMenu`）
    if (itemSubMenu != null) {
      _itemSubMenuInput(i);
      return;
    }

    // ★ 「設定」屏开着时输入归它（`Config_Loop_KeyHandler`）
    final go = gameOptions;
    if (go != null) {
      switch (i) {
        case FlowInput.up:
          gameOptionsKey(go, GameOptionsKey.up);
        case FlowInput.down:
          gameOptionsKey(go, GameOptionsKey.down);
        case FlowInput.left:
          gameOptionsKey(go, GameOptionsKey.left);
        case FlowInput.right:
          gameOptionsKey(go, GameOptionsKey.right);
        case FlowInput.confirm:
          gameOptionsKey(go, GameOptionsKey.a);
        case FlowInput.cancel:
          gameOptionsKey(go, GameOptionsKey.b);
        default:
          return;
      }
      if (go.closed) {
        _closeGameOptions();
      } else {
        _showGameOptions(go);
      }
      return;
    }

    // ★ 「部隊」列表开着时输入归它（`UnitList_LoopKeyHandler`）
    final ul = unitList;
    if (ul != null) {
      final mine = _myUnits();
      switch (i) {
        case FlowInput.up:
          unitListKey(ul, UnitListKey.up);
        case FlowInput.down:
          unitListKey(ul, UnitListKey.down);
        case FlowInput.confirm:
          unitListKey(ul, UnitListKey.a);
        case FlowInput.cancel:
          unitListKey(ul, UnitListKey.b);
        default:
          return;
      }
      if (ul.closed) {
        _closeUnitList(chosen: ul.chosenUnitId, mine: mine);
      } else {
        _showUnitList(ul, mine);
      }
      return;
    }

    // ★ 「状況」屏开着时输入归它（`ChapterStatus_LoopKeyHandler`）：
    // 左右换人、B 关闭、A 关闭并聚焦。
    final cs = chapterStatus;
    if (cs != null) {
      switch (i) {
        case FlowInput.left:
          chapterStatusKey(cs, ChapterStatusKey.left);
        case FlowInput.right:
          chapterStatusKey(cs, ChapterStatusKey.right);
        case FlowInput.cancel:
          chapterStatusKey(cs, ChapterStatusKey.b);
        case FlowInput.confirm:
          chapterStatusKey(cs, ChapterStatusKey.a);
        default:
          return;
      }
      if (cs.closed) {
        _closeChapterStatus(focus: cs.focusUnitOnExit);
      } else {
        _showStatusText(cs, _myUnits());
      }
      return;
    }

    // ★ 大地图模式：确认 = 前进/出发，其余键先不接（原作 WM 有自己的操作集，
    //   未查证完整清单，所以**不假装**支持 —— 只记一行）。
    //
    // ⚠️ **位置很要命**：我第一版把它放在 `routeInput` 的**最前面**，
    // 于是它连标题页的按键一起吞掉 ⇒ 开场流程永远走不完
    // （实测：`FE8R_WM=56` 那轮 32 秒后 `waitingFor` 还是 `title:healthSafety`）。
    // 原作里大地图 proc 是在开场流程与事件**之后**才起的，所以这里也必须排在
    // 标题流程后面 —— 这段代码的顺序就是优先级。
    if (worldMap != null && !inTitleFlow) {
      if (i == FlowInput.confirm) {
        unawaited(worldMapConfirm());
      } else if (i != FlowInput.cancel) {
        _worldMapNote = '大地图模式下 ${i.name} 还没接（未查证原作的 WM 操作集）';
      }
      return;
    }

    // 开场流程没跑完时，输入全给它 —— 但**只是入队**，由 `update` 按帧消费。
    // 见 [_titlePending] 的说明（时间是帧驱动的，不是按键驱动的）。
    if (inTitleFlow) {
      if (_titlePending.length < 32) _titlePending.add(i);
      return;
    }
    // ★ 地图菜单（START 打开）—— 两种回合结束里的"主动选择"
    //
    // 出处：`src/playerphase_0801C5A8.c:141-158`（START → `Proc_Goto(proc, 9)`）
    // 条目与顺序：`gMapMenuDef`（`frontier_df4_uistuff.c:12166+`）
    if (mapMenu != null) {
      switch (i) {
        case FlowInput.up:
          mapMenu = mapMenu!.move(-1);
        case FlowInput.down:
          mapMenu = mapMenu!.move(1);
        case FlowInput.confirm:
          final sel = mapMenu!.select();
          // ⚠️ 标签必须**先取下来**：下面会把 `mapMenu` 置空，
          // 再解引用就是 `Null check operator used on a null value` ——
          // 这一行是我在"试玩版加未实现提示"那次改动里引入的**崩溃**
          // （按地图菜单的确认就崩，也正是用户说的"玩到一半卡住"）。
          // 教训：改完 UI 那条链**必须跑 `--e2e`**（`menuend` 场景就是钉它的），
          // 我那次只跑了 `flutter test`（不覆盖菜单输入路径）。
          final selLabel = mapMenu!.current.item.label;
          // ⚠️ **availability 也要在这里取**：下面会把 `mapMenu` 置空，
          // 而 `_runMapMenuCommand` 是在置空**之后**调的 ——
          // 我在中断分支里写 `mapMenu!.current.item.availability` 就 Null 崩了
          //（与第 5 轮地图菜单那次是**同一个形状**：先置空、再解引用）。
          // ⚠️ `availability` 是**函数** `(MapMenuContext) → MenuAvailability`，
          // 得带上下文**求值**才是"禁用/可用"（我一开始把它当值用，类型直接不过）。
          final selAvailability =
              mapMenu!.current.item.availability(_mapMenuCtx!);
          if (sel.closesMenu) {
            mapMenu = null;
            _mapMenuNote = sel.note;
            _runMapMenuCommand(sel.command, selLabel, selAvailability);
          } else {
            // `src/MapMenu_SuspendCommand.c:51-54`：只弹提示，**菜单不关**
            mapMenu = MapMenuState(
              entries: mapMenu!.entries,
              index: mapMenu!.index,
              note: sel.note,
            );
            _mapMenuNote = sel.note;
          }
          _syncMapMenuPanel();
        case FlowInput.cancel:
          mapMenu = null;
          _syncMapMenuPanel();
          _mapMenuNote = '关闭';
        default:
          break;
      }
      _updateHud();
      return;
    }
    // 只有在自由光标/已选中这类"玩家阶段正常状态"才开菜单
    final st = state;
    final playing = !inTitleFlow &&
        !_sceneRunning &&
        st != null &&
        (st.phase == FlowPhase.freeCursor || st.phase == FlowPhase.unitDone);
    if (i == FlowInput.start && playing) {
      _openMapMenu();
      _updateHud();
      return;
    }

    // 演出期间按 START = **快进整段剧情**
    // （`src/event_0800D110.c:25-28` 置 `EV_STATE_SKIPPING`）
    if (i == FlowInput.start) {
      _skipRequested = true;   // 章节标题卡也看这个（`ChapterIntro_TickTimerMaybe`）
      if (_sceneRunning) {
        scene?.startSkip();
        return;
      }
    }
    input(i);
  }

  /// 开场流程的按键队列 —— **每帧消费一次**。
  ///
  /// ## 为什么必须按键与帧分开
  ///
  /// 原作的每个开场画面都是一个 proc，`timer` **每帧 +1**，
  /// 按键则每帧读一次 `newKeys`（`src/titlescreen_080CB2A0.c:33-52`）：
  ///
  /// ```c
  /// if (newKeys & (A_BUTTON | START_BUTTON)) → 主菜单
  /// else if (timer_idle == 815)              → 职业介绍（等太久自动播）
  /// ```
  ///
  /// ⚠️ 我原来把 `TitleFlow.tick()` 直接接在按键处理里 ——
  /// 于是 `framesOnScreen` 其实是"**按了几次键**"：
  ///
  ///   * Nintendo / IS 的淡入淡出（30 帧淡入 + 40 帧停 + 30 帧淡出）
  ///     **不给按键就永远停在第一屏**
  ///   * 815 帧的"等太久→播职业介绍"永远不会发生
  ///   * 连打按键会把 100 帧的过场"按"过去
  ///
  /// 这类 bug 的特点还是那个：**不报错**，只是"时间不对"。
  final List<FlowInput> _titlePending = [];

  /// 每帧推进开场流程一次。
  void _tickTitleFlow() {
    final f = titleFlow;
    if (f == null) return;

    // 每帧消费一次按键（对应原版每帧读一次 `newKeys`）
    final i = _titlePending.isEmpty ? null : _titlePending.removeAt(0);
    final done = f.tick(
      confirm: i == FlowInput.confirm,
      cancel: i == FlowInput.cancel,
      up: i == FlowInput.up,
      down: i == FlowInput.down,
    );
    if (!done) return;

    // 流程跑完 → 拆掉开场画面，开始演序章
    final v = _titleView;
    if (v != null) {
      camera.viewport.remove(v);
      _titleView = null;
    }
    // ★ 「继续」与「新游戏」在这里分岔：前者**读回中断存档**、直接进地图；
    // 后者才演本章开场（`_startRealScene`）。
    final wasResume = f.mainItem == MainMenuItem.resume;
    titleFlow = null;
    _titlePending.clear();
    if (wasResume) {
      unawaited(_resumeFromSuspend());
    } else {
      unawaited(_startRealScene());
    }
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
  ///
  /// 过场里每个 confirm 之间有 60ms 间隔，而场景是**时间门控**的
  /// （`stall` / `fade`）。间隔一大，confirm 的**速率**就不够，
  /// 长过场推不动（实测：200 个 confirm 才到第 36 句）。
  ///
  /// ⚠️ **`FE8R_NODELAY` 已经被删掉**。它把输入间隔压到 0，于是
  /// 3000 个 confirm 在**场景开始之前**就被丢光了，画面停在"过场还没开始"；
  /// 我把它读成了"过场跑完了"，据此得出「`loadMap(0)` 从未执行」的**错误结论**，
  /// **还写进了提交信息**。
  ///
  /// 能用的做法是**中等速率 + 持续够久**：900 个 confirm、60ms 间隔。
  /// **不要为了"推得快"再加一个会改变被观察对象的开关。**
  CtlServer? _ctl;

  /// 抓帧用的 key（由 `lib/main.dart` 注入）。`shot` 命令要它。
  GlobalKey? repaintKey;

  /// 立刻抓一帧写 PNG（控制通道的 `shot`）
  Future<bool> grabScreenshot(String path) async {
    final k = repaintKey;
    if (k == null) {
      debugPrint('[shot] repaintKey 没设上');
      return false;
    }
    return captureNow(k, path);
  }

  /// `FE8R_CTL=<port>` 时开一条 loopback TCP 控制通道
  ///
  /// ⚠️ 默认端口 **41999**，**不要用 19387** —— 那是 DSH Web GUI 自己的端口，
  /// 第一次试就撞上了：客户端连到 GUI，收到 `HTTP/1.1 400 Bad Request`。
  Future<void> _startCtlIfRequested() async {
    final env = Platform.environment['FE8R_CTL'];
    if (env == null || env.isEmpty) return; // 空串按"没开"处理（同上）
    final port = int.tryParse(env) ?? kCtlDefaultPort;
    _ctl = CtlServer(
      port: port,
      onState: dumpState,
      onPress: (keys) {
        for (final k in keys) {
          // 键盘层独有的键（不是 `FlowInput`）——`h` = 显示/收起按键说明
          if (k == 'h' || k == 'help') {
            toggleHelp();
            continue;
          }
          final i = inputByName(k);
          if (i != null) routeInput(i);
        }
      },
      onScript: runScript,
      onShot: grabScreenshot,
      onQuit: () {
        // 开发通道专用：`quit` 就是退出进程，脚本/CI 靠它收尾
        exit(0);
      },
      log: (m) => debugPrint('[ctl] $m'),
    );
    try {
      await _ctl!.start();
      debugPrint('[ctl] 已监听 127.0.0.1:$port');
    } catch (e) {
      // 响亮：端口占用/权限不足都要看得见，不许静默变成"没有通道"
      debugPrint('[ctl] ✗ 起不来（端口 $port）：$e');
      _ctl = null;
    }
  }

  /// 按键名 → `FlowInput`（`runScript` 与实时控制通道**共用这一份**）
  ///
  /// 出处：真实按键映射在 `onKeyEvent`（`src/event_0800D110.c:25-28` 的 START 语义）。
  static FlowInput? inputByName(String name) => switch (name.trim().toLowerCase()) {
        'up' => FlowInput.up,
        'down' => FlowInput.down,
        'left' => FlowInput.left,
        'right' => FlowInput.right,
        'confirm' || 'z' => FlowInput.confirm,
        'cancel' || 'x' => FlowInput.cancel,
        'endturn' || 'e' => FlowInput.endTurn,
        'dialogue' || 'd' => FlowInput.startDialogue,
        'start' => FlowInput.start,
        _ => null,
      };

  Future<void> runScript(String script) async {
    for (final raw in script.split(',')) {
      final t = raw.trim().toLowerCase();
      if (t.isEmpty) continue;
      // `wait` = 多等一会儿。**场景/地图是异步加载的**，
      // 紧跟其后的按键会在加载完成前发出而丢掉
      // （截图里验证过：加了按键但画面字节完全相同）。
      if (t == 'wait') {
        await Future<void>.delayed(const Duration(milliseconds: 900));
        continue;
      }
      final i = inputByName(t);
      if (i != null) {
        routeInput(i);   // ← 与真实按键同一条路
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
    // ⚠️ 道具菜单**借用了对话框**来显示（`_showItemMenu` 走 `_sceneView.show`），
    // 于是"对话框吃掉确认键"这条把菜单的确认也吃掉了 —— 按 A 永远用不了道具
    // （实测：`phase=itemMenu`、`lastItemUse=null`）。
    // 这里先按阶段让路；**正确做法是把道具菜单做成独立组件**（像行动菜单那样），
    // 已记进路线图欠账。
    if (_showDialogue &&
        i == FlowInput.confirm &&
        state?.phase != FlowPhase.itemMenu) {
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

    // ★ 三个触发点（原作分别在"选中单位 / 确定目的地 / 移动完成"之后调用）
    //   `src/TryCallSelectEvents.c` / `src/StartDestSelectedEvent.c` /
    //   `src/StartAfterUnitMovedEvent.c`。不 await：它们要演事件。
    unawaited(_fireSpecialTriggers(s, r));

    // ★ 道具菜单选了槽 ⇒ 弹 **ItemSubMenu**（`src/ItemSelectMenu_Effect.c:66`）。
    //
    // ⚠️ 这段**必须放在 `committedMove` 块之外**：流程层现在"选槽 ≠ 提交行动"
    //（提交要等子菜单决定，`commitItemAction`）。我一开始把它留在
    // `committedMove` 块里 ⇒ 子菜单永远不弹（实测 `itemSubMenu=None`、零条日志）。
    // —— 和第 28 轮"只发意图不提交"是同一个坑的**镜像**。
    final pickIdx = r.itemUseIndex;
    if (pickIdx != null && _usableSlots.isNotEmpty) {
      final slot = _usableSlots[pickIdx.clamp(0, _usableSlots.length - 1)];
      _openItemSubMenu(slot);
      state = r.state;
      _rebuildOverlay();
      _updateHud();
      return;
    }

    // 提交一次移动
    if (r.committedMove && s.selectedUnitId != null) {
      final u = f.unitById(s.selectedUnitId);
      if (u != null && s.pendingX != null && s.pendingY != null) {
        actionLog.add({
          'unit': u.id,
          'from': '${u.x},${u.y}',
          'to': '${s.pendingX},${s.pendingY}',
        });
        if (actionLog.length > 16) actionLog.removeAt(0);
        f.moveUnit(u, s.pendingX!, s.pendingY!);
        f.finishUnit(u);

        // 落点确定后才结算攻击 —— 顺序不能反：
        // 先移动再打，射程要靠移动**之后**的位置算。

        final atk = r.attack;
        if (atk != null) {
          final target = f.unitById(atk.targetId);
          final attacker = f.unitById(atk.attackerId);
          if (target != null && attacker != null) {
            unawaited(_attackWithQuote(f, attacker, target));
          }
        }
      }
    }

    state = r.state;
    if (state?.phase == FlowPhase.itemMenu) {
      _showItemMenu(state!);
    } else if (_itemMenuText.isNotEmpty) {
      lastItemMenuText = _itemMenuText;   // 留档再清
      _itemMenuText = '';
      _sceneView?.show(text: null, virtualSize: camera.viewport.virtualSize);
    }
    _rebuildOverlay();
    _updateHud();   // ★ 相机跟着光标（原作是每帧跟）

    // ★ 单位行动结束之后：等待事件 + 自动结束阶段
    // （`RunPotentialWaitEvents` / `PlayerPhase_HandleAutoEnd`）
    //
    // ⚠️ 攻击的情况**延到对白演完之后**（`_attackWithQuote` 里）——
    // 否则"该不该结束回合"会在伤害落地之前就算出来。
    if (r.committedMove && r.attack == null) unawaited(_afterUnitAction());

    if (r.endTurn) endTurn();
  }

  /// 回合横幅的倒计时（`PhaseIntro_WaitForEnd` 的最小等价物）
  void _tickBanner() {
    if (_banner == null) return;
    _bannerFrames -= 1;
    if (_bannerFrames <= 0) {
      world.remove(_banner!);
      _banner = null;
      _bannerText = '';
    }
  }

  @override
  void update(double dt) {
    _tickBanner();
    _tickGoalWindow();
    _tickMinimug();
    _tickTerrainWindow();
    _tickForecast();
    _tickPopups();

    // ★ **延迟建视图**：`MNCH`（或 `FE8R_WM`）可能发生在 layout 之前，
    // 那时 `camera.viewport.virtualSize` 会断言失败，所以 `_showWorldMapView`
    // 直接返回 —— 而"返回"就意味着**大地图永远不显示**（我的第一次截图就是这样：
    // 画面还是标题页，两张截图 sha256 完全相同）。这里补上重试。
    if (worldMap != null && _wmView == null) _showWorldMapView();

    // `MNCH` 的**实际入口**：事件与开场流程都结束了才起大地图
    // （原作是 `EXEC_BM` 起 `ProcScr_WorldMapWrapper`，不是事件处理里直接起）
    final pend = _pendingWorldMapTarget;
    if (pend != null &&
        _mapReady &&
        !inTitleFlow &&
        !_sceneRunning &&
        worldMap == null) {
      _pendingWorldMapTarget = null;
      _enterWorldMap(pend);
    }

    // ★ 开场流程**按帧**推进（时间驱动的画面靠这里走，按键只是每帧读一次）。
    // 放在最前面：它没跑完之前，战场输入根本不该被消费。
    if (inTitleFlow) _tickTitleFlow();

    // 剧情演出的移动是**按帧推进**的：VM 已经因为 waitingForMove 停住，
    // 由这里把单位一格一格挪到位，挪完再通知 VM 继续。
    _tickEventMoves(dt);

    // 相机是**逐帧**跟着光标走的（`HandlePlayerCursorMovement`
    // 每帧调 `HandleMoveCameraWithMapCursor(4)`，
    // `src/playerphase_0801C4FC.c:70-77`）。按住 B 时是 8 像素/帧。
    //
    // ⚠️ **只在玩家阶段跑**。`HandlePlayerCursorMovement` 的调用点是
    // `PlayerPhase_MainIdle`（`src/playerphase_0801C5A8.c:62`）——
    // 事件演出期间**没有这一步**。
    //
    // 我原来写成"只要不在开场流程里就每帧跟" —— 于是过场里
    // 玩家光标（停在 (2,2)）把 `LOMA`/`CAMERA` 设好的镜头**每帧拖回去**：
    // 王座厅那一幕 `LOMA` 把相机放到 x=96，下一帧就被拖到 0，
    // 接着 `CAMERA(14,0)` 从 0 算 → 48。**镜头永远到不了脚本要的位置。**
    if (state != null && !inTitleFlow && !_sceneRunning) {
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
        // 快进中不等人（`Event21_TextBg.c:42` 里查 `EVENT_IS_SKIPPING`）
        if (scene?.skipping == true) break;
        _sceneWait = Completer<void>();
        await _sceneWait!.future;
        case ChangeChapter(:final chapterIndex, :final subcmd):
        // ★ `MNCH`(1) = **先走大地图**；`MNC2`(2) 才是直接进地图
        //    （`src/Event2A_MoveToChapter.c:24-31`）。序章结束是 MNC2、
        //    第 1 章结束是 MNCH(56) —— 实测见 `scene_data.g.dart`。
        // ★ `MNTS`(0) = **回标题**（不是切章）。
        //
        // 出处：`src/Event2A_MoveToChapter.c:23-27`
        //     case EVSUBCMD_MNTS:
        //         SetNextGameActionId(GAME_ACTION_EVENT_RETURN);
        //         proc->evStateBits |= EV_STATE_CHANGEGM;
        // 中断提示脚本（`SuspendPrompt`）的最后一条就是 `MNTS(0)`
        // —— 也就是说：写完中断存档 → 淡出 → **回标题**。
        if (subcmd == 0) {
          _returnToTitle();
        } else if (subcmd == 1 && _worldMapData != null) {
          // 只记下来；`update()` 会在事件/开场流程结束后真的进去
          _pendingWorldMapTarget = chapterIndex;
          _worldMapNote = '待进入大地图（目标第 $chapterIndex 章）';
        } else {
          await _gotoChapter(chapterIndex);
        }

        case LoadMap(:final chapterIndex):
          // 出处：`src/eventscr_0800F390.c:31-72`（`Event25_ChangeMap`）
          //
          // ```c
          // short chIndex = current[1];                       // 操作数 = chapterIndex
          // x = ((u16 *)(gEventSlots + 0xB))[0];              // 槽 0xB 低 16 = 相机 x
          // y = ((u16 *)(gEventSlots + 0xB))[1];              // 槽 0xB 高 16 = 相机 y
          // if (chIndex < 0) chIndex = gEventSlots[2];        // ★ 负数 = 用槽 2
          // gPlaySt.chapterIndex = chIndex;
          // RestartBattleMap();
          // gBmSt.camera.x = GetCameraCenteredX(x * 16);
          // gBmSt.camera.y = GetCameraCenteredY(y * 16);
          // ```
          //
          // ⚠️ 脚本里真的用到负数那条路：`EventScr_CutsceneExecEnd_Sub1`
          // 是 `SVAL(0xB, 0)` + `LOMA(0xFFFF)` —— `0xFFFF` 当 **signed short**
          // 就是 -1 → 章节号从**槽 2** 取。
          final sc = scene;
          final resolved = resolveLomaChapter(
            chapterIndex,
            sc?.slotInt(2) ?? 0,
          );
          final cam = sc == null
              ? (x: 0, y: 0)
              : lomaCamera(sc.slotInt(0xB));
          await _loadChapterMap(resolved, cameraX: cam.x, cameraY: cam.y);

        case Choice(:final defaultYes):
          // ⚠️ 结果是 **0=取消 / 1=是 / 2=否**，写进**槽 0xC**
          // （`src/eventscr.c:123` `gEventSlots[0xC] = GetTalkChoiceResult();`）
          // 而**不是**写进某个界面状态 —— 脚本接下来会读这个槽来分支。
          final answer = await _askYesNo(defaultYes);
          _sceneView?.noteChoice(answer);
          eventState?.slots[0xC] = answer;

        case Fade(:final dir, :final speed):
          // 脚本阻塞到淡完 —— 见 src/Event17_Fade.c（四个分支都 ADVANCE_YIELD）
          // ⚠️ `src/Event17_Fade.c:49` 查 `EVENT_IS_SKIPPING` → 快进时立即到位
          await _sceneView?.fade(dir, speed, camera.viewport.virtualSize,
              instant: scene?.skipping == true);

      case WaitForInput():
        break; // ShowText 已经等过了
      case LoadUnits(:final table, :final group):
        _loadUnitsFromTable(table, group);
      case Stall():
        // `STAL` 是时间门控的；快进时直接跳过（原作里这些等待同样被跳过）
        if (scene?.skipping != true) {
          await Future<void>.delayed(Duration(milliseconds: e.frames * 16));
        }
      case MoveUnitInScene(:final op, :final args):
        _moveUnitInScene(op, args);

      case GiveItem(:final pid, :final itemSlot):
        _giveItem(pid, itemSlot);

      // ---- 单位显隐 / 状态（`src/eventscr_080103F4.c:74-232`）----
      case RemoveUnit(:final pid, :final onlyIfDead):
        _removeUnitInScene(pid, onlyIfDead: onlyIfDead);

      case SetUnitHp(:final pid):
        // `SetUnitHp(unit, gEventSlots[1])`；为 0 时还要置 `US_DEAD`
        final u = _eventParamUnit(pid);
        final v = scene?.slotInt(1) ?? 0;
        if (u != null) {
          u.hp = v.clamp(0, u.maxHp);
          _sceneHudExtra = 'SET_HP: ${u.name} -> ${u.hp}';
          _updateHud();
        } else {
          _sceneHudExtra = 'SET_HP: 找不到角色 $pid';
        }

      // ---- 演出光标（`src/Event3B_DisplayCursor.c`）----
      case ShowCursor(:final pid, :final x, :final y, :final flashing):
        final u = pid == null ? null : _eventParamUnit(pid);
        final cx = u?.x ?? x ?? 0;
        final cy = u?.y ?? y ?? 0;
        _eventCursor = (x: cx, y: cy, flashing: flashing);
        final st = state;
        if (st != null) state = st.copyWith(cursorX: cx, cursorY: cy);
        _updateHud();

      case EndCursor():
        _eventCursor = null;
        _updateHud();

      case WaitUnitMoving():
        // 我们的移动是瞬移（见 `_moveUnitInScene`），所以这里立即返回。
        // 明确记成**已实现**（而不是继续占位）—— 棘轮上的数字才说实话。
        _sceneHudExtra = 'ENUN: 移动已完成（瞬移）';

      case EnqueueTutCall(:final execType, :final script):
        // `Event0B_EnqueueCall` sub 1 → `EnqueueTutEvent`（`src/eventscr_0800DC94.c:87-94`）
        //
        // ⚠️ 入队**不是**立刻演：原版只是记 `tutorial_counter = i + 1`
        // （i = 脚本在本章 `tutorialEvents[]` 里的下标）与 `tutorial_exec_type`。
        // 查不到就什么都不做 —— 所以这里失败也要响亮记下来。
        if (tutorial.enqueue(script, execType, _currentTutorials)) {
          _sceneHudExtra = '教学入队：$script（type $execType）';
        } else {
          _sceneHudExtra = '教学入队失败：$script 不在本章表里';
          _tutorialNote = '入队失败：$script 不在 ${_currentTutorials.length} 条教学表里';
        }

      case CameraControl(:final x, :final y, :final centered):
        // 出处：`src/Event26_CameraControl`（`src/eventscr_0800F41C.c:10-62`）
        //
        // ```c
        // x = ARGV[0]; y = ARGV[0] >> 8;            // 低/高字节
        // if (x < 0 || y < 0) { x = slotB low; y = slotB high; }
        // ...
        // SetSomeRealCamPos(x, y, sc2);              // 已淡入 → 立即生效
        // SetCursorMapPosition(x, y);                // ★ 光标也移过去
        // ```
        //
        // `sc2`（sub-cmd bit3）= `centered`：
        //   0 → `GetCameraAdjustedX/Y`（只保证目标在死区内）
        //   1 → `GetCameraCenteredX/Y`（居中）
        var cx = x;
        var cy = y;
        if (cx < 0 || cy < 0) {
          final cam = lomaCamera(scene?.slotInt(0xB) ?? 0);
          cx = cam.x;
          cy = cam.y;
        }
        if (centered) {
          _centerCameraOn(cx, cy);
        } else {
          _adjustCameraTo(cx, cy);
        }
        // `SetCursorMapPosition(x, y)` —— 光标跟着过去。
        // `FlowState` 是不可变的，所以走 `copyWith`。
        final st = state;
        if (st != null) {
          state = st.copyWith(cursorX: cx, cursorY: cy);
        }
        _updateHud();
    }
  }

  String _sceneHudExtra = '';

  /// `MakeNewItem`（`src/MakeNewItem.c:27`）—— 用**真实道具表**算耐久。
  ///
  /// ```c
  /// int MakeNewItem(int item) {
  ///     int uses = GetItemMaxUses(item);
  ///     if (GetItemAttributes(item) & IA_UNBREAKABLE) uses = 0;
  ///     return (uses << 8) + GetItemIndex(item);
  /// }
  /// ```
  ///
  /// 查不到道具就**返回 0**（＝不放进去），调用方会把它当成失败 ——
  /// 这样"道具表没接上"会表现成"东西没进来"，而不是编一个耐久出来。
  int _makeNewItem(int itemIndex) {
    final s = _itemStats[ItemTable.itemIndex(itemIndex)];
    if (s == null) return 0;
    return makeNewItem(itemIndex, s.maxUses, unbreakable: s.unbreakable);
  }

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
  ///
  /// ⚠️ **失败必须响亮**（写进 `_sceneHudExtra`，转储里能看见）：
  /// 这条曾经因为"道具栏只有 1 槽"而**每次都失败**，却没人知道。
  /// `GetUnitStructFromEventParameter(arg)` —— 事件脚本的"角色号"参数。
  ///
  /// 出处：`include/event.h:271`（原型；实现未 carve）。
  /// 约定（源码里到处在用）：
  ///   * `0`      = 当前行动单位（这里退化为"第一个我方单位"）
  ///   * `0xFFFF` = 同 0
  ///   * 其它     = `charIndex`
  ///
  /// ⚠️ 原来这段逻辑只写在 `_giveItem` 里 —— 现在 `DISA` / `SET_HP` /
  /// `CURSOR_CHAR` 都要同一套解析，**不能再各写一份**（那正是
  /// `ChapterLoader` 那次漂移的原因）。
  MapUnit? _eventParamUnit(int pid) {
    final f = field;
    if (f == null) return null;
    if (pid == 0 || pid == 0xFFFF) {
      return f.units.where((u) => u.faction == Faction.blue).firstOrNull;
    }
    return f.units.where((u) => u.charIndex == pid).firstOrNull;
  }

  /// `DISA(pid)` —— `ClearUnit(unit)`（`src/eventscr_080103F4.c:217-223`）。
  ///
  /// ⚠️ 以前是占位符 → **该消失的人一直站在地图上**。
  /// 序章王座厅一幕有 4 次 `DISA`（传令兵走掉、艾莉卡被赛特抱走…）。
  void _removeUnitInScene(int pid, {bool onlyIfDead = false}) {
    final f = field;
    if (f == null) return;
    final u = _eventParamUnit(pid);
    if (u == null) {
      _sceneHudExtra = 'DISA: 找不到角色 $pid';
      _updateHud();
      return;
    }
    // `DISA_IF`：只对已阵亡的生效（`:212-217`）
    if (onlyIfDead && u.isAlive) return;
    field = BattleField(
      width: f.width,
      height: f.height,
      turn: f.turn,
      activeFaction: f.activeFaction,
      units: [for (final x in f.units) if (!identical(x, u)) x],
    );
    _sceneHudExtra = 'DISA: ${u.name} 离场';
    _updateHud();
  }

  /// 演出光标（`CURSOR_CHAR` / `CURE`）—— 画面上那个闪动的框。
  ///
  /// `null` = 没有演出光标（此时过场里**不画**玩家光标：原作的
  /// `CURSOR_CHAR` 之前屏幕上是没有光标的）。
  ({int x, int y, bool flashing})? _eventCursor;

  bool get eventCursorVisible => _eventCursor != null;

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
    final item = _makeNewItem(idx);
    if (item == 0) {
      _sceneHudExtra = 'GIVEITEMTO: 道具表里没有 $idx';
      return;
    }

    // 目标解析走**同一条路**（`GetUnitStructFromEventParameter`）
    final target = _eventParamUnit(pid);
    if (target == null) {
      _sceneHudExtra = 'GIVEITEMTO: 找不到角色 $pid';
      return;
    }

    // `UnitAddItem`：第一个空槽（满了会返回 -1，**不静默丢弃**）
    final slot = target.addItem(item);
    if (slot < 0) {
      _sceneHudExtra = 'GIVEITEMTO: ${target.name} 道具栏满了（$unitItemCount 槽）';
      return;
    }
    _sceneHudExtra = 'GIVEITEMTO: ${target.name} <- 道具 $idx（$slot 号槽）';
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
    if (f == null) return;

    final intent = parseMoveIntent(op, args);
    if (intent == null) {
      _sceneHudExtra = '$op: 不是移动指令';
      return;
    }

    // `pid` 是**角色号**（`charIndex`）；0 / 0xFFFF 表示"当前行动单位"
    final u = _eventParamUnit(intent.pid);
    if (u == null) {
      _sceneHudExtra = '$op: 找不到角色 ${intent.pid}';
      return;
    }

    // MOVEONTO：第三个参数是**目标单位**，走到它那一格
    ({int x, int y})? targetUnitPos;
    if (intent.subcmd == MoveSubcmd.moveOnto) {
      final t = _eventParamUnit(intent.x ?? 0);
      if (t == null) {
        _sceneHudExtra = '$op: 目标单位 ${intent.x} 不在场上';
        return;
      }
      targetUnitPos = (x: t.x, y: t.y);
    }

    final at = moveTarget(
      intent,
      unitPos: (x: u.x, y: u.y),
      targetUnitPos: targetUnitPos,
    );
    if (at == null) {
      // `MOVE_DEFINED` 的路径来自槽队列（`SAVETOQUEUE`）——没实现。
      // **不猜坐标**：记一笔，让它显式可见。
      _sceneHudExtra = intent.subcmd == MoveSubcmd.defined
          ? '$op: 槽队列路径未实现（pid ${intent.pid} 原地不动）'
          : '$op: 参数不足以算出目标格 $args';
      return;
    }

    var nx = at.x, ny = at.y;
    // `MOVE_*_CLOSEST`：目标格被占就退到相邻空格（子命令 bit3）
    if (op.contains('CLOSEST') && f.unitAt(nx, ny) != null) {
      for (final (dx, dy) in const [(0, 1), (0, -1), (1, 0), (-1, 0)]) {
        if (f.unitAt(nx + dx, ny + dy) == null) {
          nx += dx;
          ny += dy;
          break;
        }
      }
    }

    // 按原作 `EvtMoveUnit` 的语义：**移动是演出的一部分，要走过去**。
    // 逻辑位置立刻落位（规则层），画面由 `_tickEventMoves` 补间跟上。
    u.x = nx;
    u.y = ny;
    _eventMoveTargets[u.id] = (nx, ny);
    _rebuildOverlay();   // ★ 立刻同步精灵，别等下一次状态变化
    _sceneHudExtra = '$op(${intent.pid} -> $nx,$ny)';
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

    await runSceneScript(fn);
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

  /// 胜负条件载入的**结论**（转储里带出来）
  String _objectivesNote = '';

  /// 把面板挂到世界层/更新高亮
  ///
  /// 几何全部来自 `lib/core/flow/map_menu.dart` 的 `mapMenuLayout()`
  /// （`src/StartMenuCore.c:34-98`），这里只负责搬像素。
  MapMenuComponent? _mapMenuPanel;
  MapMenuLayout? _mapMenuLayout;

  void _syncMapMenuPanel() {
    final m = mapMenu;
    if (_mapMenuPanel != null) {
      world.remove(_mapMenuPanel!);
      _mapMenuPanel = null;
    }
    _mapMenuLayout = null;
    if (m == null || m.isEmpty) return;
    final v = camera.viewport.virtualSize;

    // `gBmSt.cursorTarget.x - gBmSt.camera.x`（`src/playerphase_0801C5A8.c:110`）：
    // 光标的**屏幕像素** x —— 地图一格 16px（`lib/core/map/camera.dart` 的 `tilePx`）。
    final cursorScreenPx =
        (state?.cursorX ?? 0) * tilePx.toDouble() - _cameraX;

    final layout = mapMenuLayout(
      entries: m.entries,
      cursorScreenPx: cursorScreenPx.round(),
    );
    _mapMenuLayout = layout;

    // 一屏 20 个 UI 图块（160px / 8px）—— UI 图块是 8px，地图图块才是 16px
    final tileSize = v.y / 20.0;
    final comp = MapMenuComponent(
      layout: layout,
      selectedIndex: m.index,
      tileSize: tileSize,
    )..position = MapMenuComponent.originFor(layout, tileSize);
    world.add(comp);
    _mapMenuPanel = comp;
  }

  /// 打开地图菜单（START）
  ///
  /// ★ **查不到 `GetBattleMapKind()` 就不打开**，并把缺失写进转储 ——
  /// 绝不兜底成 `story`（兜底会让"未查证的章节"看起来和序章一模一样）。
  void _openMapMenu() {
    final kind = battleMapKindOf(sceneChapter);
    final diff = titleFlow?.difficulty ?? Difficulty.normal;
    // ★ 从存档继续时用**存档里的**教学/难度位；新游戏才看难度屏选的那个
    final ng = _playFlagsFromSave ?? NewGamePlayFlags(switch (diff) {
      Difficulty.easy => NewGameDifficulty.easy,
      Difficulty.normal => NewGameDifficulty.normal,
      Difficulty.hard => NewGameDifficulty.hard,
    });

    if (kind == null) {
      mapMenu = null;
      _mapMenuLayout = null;
      _mapMenuNote = '未查证：GetBattleMapKind(0x${sceneChapter.toRadixString(16)}) 读不到'
          '（日版本体没有 carve）→ 不打开菜单';
      _mapMenuInputs = {
        'chapterIndex': sceneChapter,
        'battleMapKind': null,
        'battleMapKindVerified': false,
        'guideLocked': ng.guideLocked,
        'tutorial': ng.playFlagTutorial,
        'tutorialMode': ng.isTutorialMode,
        'difficulty': diff.name,
      };
      _syncMapMenuPanel();
      return;
    }

    final ctx = MapMenuContext(
      chapterIndex: sceneChapter,
      battleMapKind: kind,
      guideLocked: ng.guideLocked,
      tutorial: ng.playFlagTutorial,
      flags: eventFlags,
    );
    final entries = buildMapMenu(ctx);
    _mapMenuCtx = ctx;   // `availability` 是函数，求值要用它
    mapMenu = MapMenuState(entries: entries);
    _mapMenuNote = '打开（START）：${entries.length} 条'
        '（${mapMenuItems.length} 条里隐藏了 '
        '${mapMenuItems.length - entries.length} 条）';
    _mapMenuInputs = {
      'chapterIndex': sceneChapter,
      'battleMapKind': kind.name,
      // 抽查过（见 lib/core/flow/battle_map_kind.dart 的头注释），不是机器验证
      'battleMapKindVerified': false,
      'guideLocked': ng.guideLocked,
      'tutorial': ng.playFlagTutorial,
      'tutorialMode': ng.isTutorialMode,
      'difficulty': diff.name,
      'hidden': [
        for (final it in mapMenuItems)
          if (it.availability(ctx) == MenuAvailability.notShown)
            '${it.label}(${it.availabilityFn})'
      ],
    };
    _syncMapMenuPanel();
  }

  /// 执行地图菜单条目（`MenuItemDef::onSelected`）
  ///
  /// 8 条里有 5 条的**整屏界面**（部队/状況/辞書/設定/中断）还没搬进来 ——
  /// 一律**响亮记录**在 `_mapMenuUnimplemented` 里，绝不当没发生。
  /// 退却/戦績 在故事章节里是 `MENU_NOTSHOWN`，根本不会被选中。
  void _runMapMenuCommand(
      MapMenuCommand c, String label, MenuAvailability availability) {
    switch (c) {
      case MapMenuCommand.endPlayerPhase:
        endTurn();
      // ⚠️ **Dart 的 `case a: case b:` 是共用同一个 body**（不会各自穿透到下一段）。
      // 我在第 19 轮把这一段的 body 换成了"中断"的逻辑，于是
      // 部隊/状況/辞書/戦績/設定 **全都去跑中断**了 —— 选「部隊」会写中断存档、
      // 教学模式章节选「部隊」还会弹"不能中断"的提示。
      // 没有任何场景覆盖到这几项，所以一直没红。**各自分开**：
      case MapMenuCommand.unitList:
        // `MapMenu_UnitListCommand` ⇒ 开「部隊」列表（原作的按键语义见
        // `lib/core/flow/unit_list.dart`；A = 记住该单位并跳出 ⇒ 随后开**它**的状況屏）
        _openUnitList();
        _mapMenuNoteLog.add('unitList：开部隊列表');
      case MapMenuCommand.guide:
      case MapMenuCommand.records:
      case MapMenuCommand.options:
        // `src/MapMenu_OptionsCommand.c` ⇒ 开「設定」屏（数据来自
        // `tools/pipeline/out/tables/game_options.json`，见 `parse_game_options.py`）
        _openGameOptions();
        _mapMenuNoteLog.add('options：开設定屏');
        _mapMenuNote = '$_mapMenuNote → 設定（Config_Loop_KeyHandler）';
      case MapMenuCommand.retreat:
        _mapMenuUnimplemented.add(c.name);
        _mapMenuNote = '$_mapMenuNote → 界面未实现（${c.name}）';
        _mapMenuNoteLog.add('${c.name}：未实现');
        // 屏幕上也要说 —— 否则玩家以为按键没反应（试玩反馈里这类最难判）
        _playNote = '「$label」这个界面还没做（见 docs/试玩.md）'
            '${_helpShown ? '\n$kPlayNote' : ''}';
      case MapMenuCommand.status:
        // `MapMenu_StatusCommand`（`src/MapMenu_StatusCommand.c:50-54`）：
        // `StartChapterStatusScreen(NULL)` ⇒ 开「状況」屏。
        _openChapterStatus();
        _mapMenuNoteLog.add('status：开状況屏');
      case MapMenuCommand.suspend:
        // 出处：`src/MapMenu_SuspendCommand.c:1-10`
        //
        // ```c
        // if (menuItem->availability == MENU_DISABLED) {
        //     MenuFrozenHelpBox(menu, 0x7E2);   // "You cannot stop in the middle of the tutorial."
        //     return MENU_ACT_SND6B;
        // }
        // StartSuspendPrompt();
        // ```
        // ⇒ **禁用时弹 0x7E2 冻结提示、菜单不关**；否则走中断流程。
        // 可用性由 `MapMenu_IsSuspendCommandAvailable`（`src/masked_0802257c.c:61-67`）
        // 给：教学模式章节 ⇒ `MENU_DISABLED`。
        if (availability == MenuAvailability.disabled) {
          _showMessageById(_kTutorialNoSuspendMsgId);
          _suspendNote = '教学章节：中断被禁用（弹消息 0x'
              '${_kTutorialNoSuspendMsgId.toRadixString(16)}），**没有写存档**';
        } else {
          _writeSuspendSave();
          // ★ 写完存档之后**照源码把中断提示脚本演完**：
          // `SuspendPrompt` 的末条是 `MNTS(0)`（回标题，见 `_returnToTitle`），
          // 中间那条 `ASMC` 在原件里就是 `WriteSuspendSave`（我们已在上面做了）。
          // 不演它的话，中断完会**留在战场上** —— 与原作不符。
          // ⚠️ 键是 **`EventScr_SuspendPrompt`**（不是 `SuspendPrompt` ——
          // 函数名会被 sanitize，但 `allSceneFns` 的键是**原始脚本名**）。
          // 我用错了键，于是"查不到就静默什么都不做"，中断完留在战场上。
          // 现在查不到要**响亮**记下来。
          const promptScript = 'EventScr_SuspendPrompt';
          final fn = allSceneFns[promptScript];
          if (_suspendBytes > 0 && fn != null) {
            unawaited(runSceneScript(fn));
          } else if (_suspendBytes > 0) {
            _suspendNote = '$_suspendNote；找不到中断提示脚本 $promptScript';
            debugPrint('[SAVE] $_suspendNote');
          }
        }
        _mapMenuNote = '$_mapMenuNote → ${_suspendNote.isEmpty ? c.name : _suspendNote}';
    }
  }

  /// `gPlaySt.config`（`struct PlaySt_OptionBits`，`include/types.h:141-169`）
  ///
  /// 现在只有 `disableAutoEndTurns` 一项真的被读（`PlayerPhase_HandleAutoEnd`，
  /// `src/playerphase_0801D808.c:54`）—— 等「設定」屏做出来就由它写。
  final PlayConfig playConfig = PlayConfig();

  /// 阶段循环的诊断（正常回合结束时是空串）
  String _turnLoopNote = '';

  /// 屏幕底部那行提示（试玩版用：让"还没做的"看得见）
  String _playNote = kPlayNote;

  /// 键位说明是否展开（按 `H` 切换）
  bool _helpShown = false;

  /// 大地图的诊断（走不动时写这里，转储里看得见）
  String _worldMapNote = '';

  /// 地图上的伤害数字（用户反馈"战斗没有反馈"）
  final List<DamagePopupComponent> _popups = [];

  /// 命中闪白（每段一次）
  final List<HitFlashComponent> _flashes = [];

  /// 最近几次飘字（x, y, text）—— 判据用
  final List<Map<String, Object?>> _popupLog = [];

  /// 本次战斗累计造成的伤害（判据用：不等于 0 就说明真的打到了）
  int _damageDealtTotal = 0;

  /// 逐段反馈记录（命中/未命中/暴击 + 伤害 + 目标）—— 判据用
  final List<Map<String, Object?>> _hitFxLog = [];

  /// 当前生效的新游戏标志：优先用**存档恢复**的，否则用难度屏选的
  NewGamePlayFlags get _currentPlayFlags =>
      _playFlagsFromSave ??
      NewGamePlayFlags(switch (titleFlow?.difficulty ?? Difficulty.normal) {
        Difficulty.easy => NewGameDifficulty.easy,
        Difficulty.normal => NewGameDifficulty.normal,
        Difficulty.hard => NewGameDifficulty.hard,
      });

  /// 从存档继续时恢复的"新游戏标志"（教学模式/难度）——
  /// 地图菜单的可用性要用它，而这时 `titleFlow` 已经拆掉了。
  NewGamePlayFlags? _playFlagsFromSave;

  /// 地图菜单里按过哪些项（**按顺序**）—— 转储只有"最后一次"的值，
  /// 中间步骤就断言不了（我写过一条这样的断言，结果永远看不到）。
  final List<String> _mapMenuNoteLog = [];

  /// 打开地图菜单时用的上下文（`availability` 是**函数**，要带它求值）
  MapMenuContext? _mapMenuCtx;

  /// 中断存档：路径 / 字节数 / 说明（写了什么、或**为什么没写**）
  String? _suspendPath;
  int _suspendBytes = 0;
  String _suspendNote = '';

  /// 回合横幅剩余帧数 + 当前文字（`ProcScr_PhaseIntro` 的最小等价物）
  int _bannerFrames = 0;
  String _bannerText = '';

  /// **最后显示过**的横幅文字（不随淡出清空）。
  ///
  /// 横幅只亮 1 秒 —— 只记"当前文字"的话，转储里几乎永远读到空串，
  /// 判据就没法写（我自己第一次验证就踩了这个：轮询太晚，什么都没看到）。
  String _lastPhaseBanner = '';

  /// 阶段循环是否正在跑（`waitingFor` 诊断用）
  bool _turnRunning = false;

  /// ★ 大地图模式（`MNCH` 之后要**先走大地图**再进地图）
  ///
  /// 出处：`src/Event2A_MoveToChapter.c:24-31`（`MNCH` 置 `save_menu_type = 1`）
  /// → `EXEC_BM` 里 `CheckNewGameAndBranch` 不命中 2/4 分支
  /// → 起 `ProcScr_WorldMapWrapper`。也就是说 **`MNCH` 不是"直接进地图"**，
  /// 而我原来把四条 `MNC*` 都发成同一个调用（见 `ChangeChapter.subcmd`）。
  ///
  /// 部队所在节点是**持久状态**：`gGMData.units[0].location`
  /// （初始化 `src/worldmap_path.c:148` → 0），走到节点时由
  /// `src/worldmap_main_080BDA6C.c:140` 更新。**不是**按章节推出来的。
  WorldMapState? worldMap;
  WorldMapData? _worldMapData;
  WorldMapRules? get worldMapRules =>
      _worldMapData == null ? null : WorldMapRules(_worldMapData!);
  int? _wmTargetChapter;

  /// `MNCH` 只是**记下**要去大地图；真正进入要等当前事件/开场流程走完。
  ///
  /// 出处：`MNCH` 只置 `save_menu_type` / `nextAction`（`src/Event2A_MoveToChapter.c:24-31`），
  /// 起 `ProcScr_WorldMapWrapper` 的是**之后的** `EXEC_BM`。我第一次写成
  /// "在 `ChangeChapter` 处理里直接进大地图"，结果 WM 盖在**正在演的过场**上
  /// （截图里是序章王座厅那段对白 + 立绘）。
  int? _pendingWorldMapTarget;

  /// 本章地图是否已经装配完成（`_startRealScene` 走到末尾）。
  ///
  /// 大地图必须**在这之后**才能进：只判 `!_sceneRunning` 不够 ——
  /// 标题流程结束与本章开场过场开始之间有一瞬 `_sceneRunning == false`，
  /// 那一下进去就会被随后的过场盖住（截图里就是这样：WM 上叠着序章王座厅的对白）。
  bool _mapReady = false;

  /// 章节 → {`gmapEventId`, `wmBeginning`, `wmChapterIntro`}
  Map<int, Map<String, dynamic>> _chapterWm = const {};

  /// 敌方每个单位之间的停顿。
  ///
  /// 原作每个 AI 单位是一条**阻塞**的子 proc（`gProcScr_CpPerform`，
  /// `src/data/data_085D1F2C/data_085D1F2C.c:28` + 移动动画），所以是逐个动、
  /// 看得见。我们以前是一帧跑完 ⇒ 用户反馈"敌方行动过快"。
  static const Duration kEnemyStepDelay = Duration(milliseconds: 380);

  /// **卡住时自证**：现在到底在等什么。
  ///
  /// 用户反馈"玩到一半卡住" —— 没有这个字段，只能靠猜。
  /// 有它，玩家把屏幕底部那行/转储发过来，就知道卡在哪一环。
  String get waitingFor {
    if (inTitleFlow) return 'title:${titleFlow?.screen.name}';
    if (worldMap != null) return 'worldMap:node=${worldMap!.node}';
    if (_sceneRunning) {
      final t = _currentText;
      return t == null ? 'scene:running' : 'scene:text 0x${t.message.id.toRadixString(16)}';
    }
    if (mapMenu != null) return 'mapMenu';
    if (_turnRunning) return 'turnLoop:faction=${field?.activeFaction}';
    final s = state;
    if (s == null) return 'noState';
    return 'input:${s.phase.name}';
  }

  /// 显示/收起按键说明（**键盘与控制通道共用** —— 玩家能按的键，通道也要能按）
  void toggleHelp() {
    _helpShown = !_helpShown;
    _playNote = _helpShown ? '$kKeyHelp\n$kPlayNote' : kPlayNote;
    _updateHud();
  }

  /// 试玩版一直在屏幕底部显示的那行（改了它就要同步 `docs/试玩.md`）
  static const String kPlayNote =
      '试玩版：序章/第 1 章可玩 · 缺 战斗动画 / 菜单5屏 / 章间大地图 / 存档 · **按 H 看按键**';

  /// 按键说明 —— 与 `onKeyEvent` 的真实映射**逐条对应**，不是另写一份
  /// （改了 `onKeyEvent` 就要改这里；`test/game/keyboard_test.dart` 钉住几个关键键）
  static const String kKeyHelp =
      '按键：方向键/WASD 移动光标 · Z/空格 确认 · X/ESC 取消 · '
      '回车=START（打开地图菜单 / 跳过剧情）\n'
      '　　　E 直接结束回合（开发捷径，原作没有） · C 触发剧情演示（开发用） · '
      '再按 H 收起这一行';

  /// `gPlaySt.tutorial_counter` / `tutorial_exec_type`（`include/types.h:223-225`）
  final TutorialQueue tutorial = TutorialQueue();

  /// 每章的教学事件表（`tutorial_lists.json` ← `EventListScr_*_Tutorial_ref/*.c`）
  Map<String, List<String>> _tutorialLists = const {};
  String _tutorialNote = '';
  String? _lastTutorialFired;

  /// 本章的教学表名（`ChapterEventGroup.tutorialEvents`）→ 脚本名列表
  ///
  /// 原版是 `GetChapterEventDataPointer(gPlaySt.chapterIndex)->tutorialEvents`，
  /// 一个"脚本指针 + 0 结尾"的数组，`EnqueueTutEvent` 按**指针**查下标。
  List<String> get _currentTutorials {
    final g = _chapterGroup;
    final name = g?['tutorialEvents'];
    if (name is! String) return const [];
    return _tutorialLists[name] ?? const [];
  }

  /// `RunTutorialEvent(type)`（`src/eventinfo_0808618C.c:138-149`）—— 命中就起脚本
  ///
  /// 调用点（都指到了源码）：
  ///   * 阶段切换 → `src/RunPhaseSwitchEvents.c:36`（`TUTORIAL_EVT_TYPE_PHASECHANGE`）
  ///   * 单位行动后 → `src/CheckForWaitEvents.c:45`（`POSTACTION`）
  ///   * 玩家阶段开始/每次行动回到 label 0 → `src/eventinfo_0808682C.c:45-52`
  ///     （`StartPlayerPhaseStartTutorialEvent`，`PLAYERPHASE`）
  /// 按名字跑一条已生成的脚本（找不到就**响亮记录**，不静默）
  Future<void> _runNamedScript(String name) async {
    final fn = allSceneFns[name];
    if (fn == null) {
      _worldMapNote = '脚本 $name 没有生成函数（不在 scene_data.g.dart 里）';
      debugPrint('[WM] $_worldMapNote');
      return;
    }
    await runSceneScript(fn);
  }

  Future<void> _runTutorial(int type) async {
    final name = tutorial.take(type, _currentTutorials);
    if (name == null) return;
    if (name.startsWith('?')) {
      _tutorialNote = name; // 越界：响亮记下来，不静默
      return;
    }
    _lastTutorialFired = name;
    final fn = allSceneFns[name];
    if (fn == null) {
      _tutorialNote = '教学脚本 $name 没有生成函数（不在 scene_data.g.dart 里）';
      return;
    }
    await runSceneScript(fn);
  }

  /// `RunPhaseSwitchEvents` 被调用的次数。判据用它钉住"每个阶段一次"。
  int _phaseSwitchEventRuns = 0;

  /// 地图菜单状态（`null` = 没打开）
  MapMenuState? mapMenu;
  String _mapMenuNote = '';

  /// 决定可见性的输入（含"未查证"标记）
  Map<String, dynamic>? _mapMenuInputs;

  /// 被选中但界面还没做的条目
  final List<String> _mapMenuUnimplemented = [];

  /// 战斗/阵亡对话表（日版 carve 数组 → `tools/pipeline/out/tables/*_talk*.json`）
  TalkTables? talks;

  void _loadTalks() {
    final bf = File('tools/pipeline/out/tables/battle_talks.json');
    final df = File('tools/pipeline/out/tables/defeat_talk.json');
    if (!bf.existsSync() || !df.existsSync()) {
      _talksNote = '对话表缺失（battle_talks.json / defeat_talk.json）';
      return;
    }
    talks = TalkTables.parse(bf.readAsStringSync(), df.readAsStringSync());
    _talksNote = '战斗对话 ${talks!.battleTalks.length} 条、'
        '阵亡对话 ${talks!.defeatTalks.length} 条';
  }

  String _talksNote = '';
  String? _lastBattleQuote;
  String? _lastDefeatQuote;
  final Set<int> _defeatQuoted = {};

  /// 回合事件表（`turnBasedEvents`，`EvListTurn`）
  ChapterObjectives? _turnEvents;
  String _turnEventsNote = '';

  /// ★ 三个**专门的**事件表（原来一张都没读，所以这三类剧情对话一条都不演）
  ///
  /// 出处：`TryCallSelectEvents`（`src/TryCallSelectEvents.c:14-30`）、
  /// `StartDestSelectedEvent`（`src/StartDestSelectedEvent.c`）、
  /// `StartAfterUnitMovedEvent`（`src/StartAfterUnitMovedEvent.c`）
  /// —— 三者都先 `RunTutorialEvent(...)`，再搜自己那张表。
  ChapterObjectives? _selectEvents;
  ChapterObjectives? _destEvents;
  ChapterObjectives? _movedEvents;
  String _specialEventsNote = '';
  String _specialEventFired = '';

  void _loadObjectives() {
    // ① 事件列表：章节 → Misc 列表
    final ef = File('tools/pipeline/out/tables/event_lists.json');
    if (ef.existsSync()) {
      final d = jsonDecode(ef.readAsStringSync()) as Map<String, dynamic>;
      final lists = d['lists'] as Map<String, dynamic>;
      // 章节号 → 事件组名（`PrologueEvents`）→ 列表名（`EventListScr_Prologue_Misc`）
      // ⚠️ 空链路 = 顺序错了（见 onLoad 里的说明）。**不要静默返回。**
      if (_chapterLinks.isEmpty) {
        _objectivesNote = '胜负条件：章节链路还没载入（调用顺序错了）';
        return;
      }
      final ev =
          sceneChapter < _chapterLinks.length
              ? _chapterLinks[sceneChapter]['eventGroupName'] as String?
              : null;
      if (ev != null) {
        final base = ev.replaceAll('Events', '');
        final key = 'EventListScr_${base}_Misc';
        final raw = lists[key];
        if (raw is List) {
          _objectives = ChapterObjectives.fromJson(raw);
          _objectivesNote = '胜负条件 $key：${_objectives!.entries.length} 条';
        } else {
          _objectivesNote = '第 $sceneChapter 章没有 Misc 列表（找的是 $key）';
        }
        // ★ **回合事件表**（`turnBasedEvents`）——
        // `RunPhaseSwitchEvents` 在**每次阶段切换后**搜这张表
        // （`src/RunPhaseSwitchEvents.c:38-39`）。条目的判定是
        // `EvCheck02_TURN`（`src/eventinfo_08085B30.c:69-88`）。
        //
        // ⚠️ 我原来**根本没读这张表** —— 序章的回合 1/2/3 事件与
        // "奥尼尔攻击"教学（`EventScr_Prologue_ONeillAttack`）一次都没演过。
        final tkey = 'EventListScr_${base}_Turn';
        final traw = lists[tkey];
        if (traw is List) {
          _turnEvents = ChapterObjectives.fromJson(traw);
          _turnEventsNote = '回合事件 $tkey：${_turnEvents!.entries.length} 条';
        } else {
          _turnEvents = null;
          _turnEventsNote = '第 $sceneChapter 章没有 Turn 列表（找的是 $tkey）';
        }

        // ★ 三张"专属"事件表：`specialEventsWhenUnitSelected` /
        // `...DestSelected` / `...AfterUnitMoved`（字段名见 `chapter_links.json`）。
        //
        // ⚠️ 之前**一张都没读**：序章教学链第一环 `T0`（`execType = 2` = ONSELECT）
        // 入队后永远不触发 —— 这正是用户说的"对话触发不对"。
        final evGroup =
            _eventGroups[ev] as Map<String, dynamic>?; // 事件组字段表
        ChapterObjectives? pick(String field) {
          final n = evGroup?[field];
          if (n is! String) return null;
          final raw = lists[n];
          return raw is List ? ChapterObjectives.fromJson(raw) : null;
        }

        _selectEvents = pick('specialEventsWhenUnitSelected');
        _destEvents = pick('specialEventsWhenDestSelected');
        _movedEvents = pick('specialEventsAfterUnitMoved');
        _specialEventsNote = '专属事件表：选中 ${_selectEvents?.entries.length ?? "-"} 条 / '
            '目的地 ${_destEvents?.entries.length ?? "-"} 条 / '
            '移动后 ${_movedEvents?.entries.length ?? "-"} 条';
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

    // ⚠️ **这里不清事件标志。**
    //
    // 原来这里是 `eventFlags.clear()`，而 `_loadObjectives()` 会在
    // **每演完一条胜负条件之后**被调一次 —— 于是：
    //   * `doneFlag` 立刻被抹掉 → 同一条事件**无限重演**
    //     （实测 `EventScr_Prologue_OneEnemyLeft` 每回合都重演）
    //   * 刚推导出来的 `EVFLAG_DEFEAT_BOSS` 也被抹掉 →
    //     **打死首领不再触发结束脚本**（切不到下一章）
    //
    // 原作在**战斗地图开始**时清：`StartBattleMap`
    // （`src/bmio_08030D50.c:140-153`）里调 `ResetChapterFlags()`。
    // 对应到我们这边就是 `_gotoChapter()`（换章 = 新地图）。
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
    ));
  }

  /// 跑一段剧情脚本（开场 / 回合事件 / 胜负条件共用一条路径）
  Future<void> runSceneScript(Future<void> Function(Scene) fn) async {
    final sc = scene;
    if (sc == null) return;
    _sceneRunning = true;
    _sceneShown = 0;
    _showDialogue = true;
    _updateSceneDialogue();
    try {
      await fn(sc);
    } finally {
      _sceneRunning = false;
      _currentText = null;
      _showDialogue = false;
      _updateSceneDialogue();
    }
  }

  /// 最近一次命中的回合事件（脚本名）
  String? _turnEventFired;

  /// 本章的**结束剧情**脚本名（`ChapterEventGroup.endingSceneEvents`）
  String? get _endingSceneName {
    final g = _chapterLinks.isEmpty || sceneChapter >= _chapterLinks.length
        ? null
        : _chapterLinks[sceneChapter]['eventGroupName'] as String?;
    if (g == null) return null;
    final eg = _eventGroups[g];
    if (eg is! Map) return null;
    return eg['endingSceneEvents'] as String?;
  }

  /// `MaybeCallEndEvent` / `CallEndEvent`（`src/eventinfo.c:111-127` 与 `:64-77`）
  ///
  /// ```c
  /// void MaybeCallEndEvent(void) {
  ///     if (!CheckFlag(3)) return;            // EVFLAG_WIN
  ///     if (!ShouldCallEndEvent()) return;    // = CheckWin() && 不是演练地图
  ///     CallEndEvent();
  /// }
  ///
  /// void CallEndEvent(void) {
  ///     const struct ChapterEventGroup* evGroup = GetChapterEventDataPointer(gPlaySt.chapterIndex);
  ///     if (GetBattleMapKind() != BATTLEMAP_KIND_SKIRMISH)
  ///         CallEvent(evGroup->endingSceneEvents, 1);   // ★ 本章结束剧情
  ///     RefreshAllies();
  ///     SetFlag(0x84);                        // ← 只演一次
  /// }
  /// ```
  ///
  /// 调用点：`PlayerPhase_FinishAction`（`src/PlayerPhase_FinishAction.c:68-80`）——
  /// **每个我方单位行动结束之后**。
  ///
  /// ⚠️ 我原来只走了 `EventListScr_*_Misc` 里的 `DefeatBoss` 条目，
  /// 那条在序章恰好就是 `EventScr_Prologue_EndingScene`（所以序章看起来是对的），
  /// 但**第 1 章的 Misc 条目是教学提示**（`EventScr_Ch1_Misc_DefeatBoss`），
  /// 真正的"第 1 章 → 第 2 章"剧情在 `endingSceneEvents` 里 ——
  /// 从来没被触发过。
  Future<void> _maybeCallEndEvent() async {
    if (_sceneRunning || _objectiveRunning) return;
    if (!eventFlags.contains(EventFlags.win)) return;
    if (eventFlags.contains(0x84)) return;      // `SetFlag(0x84)` —— 已演过
    final name = _endingSceneName;
    if (name == null) {
      _endEventNote = '第 $sceneChapter 章没有 endingSceneEvents';
      return;
    }
    final fn = allSceneFns[name];
    if (fn == null) {
      _endEventNote = '$name（没有这个脚本）';
      return;
    }
    eventFlags.add(0x84);
    _endEventNote = name;
    _lastEndEvent = name;
    await runSceneScript(fn);
  }

  // ---- 测试钩子（章节流转）----
  /// `loadRuleData()` 不含章节链路（那条在 `onLoad` 里、且必须**先于**它，
  /// 见 `_loadObjectives` 的说明），所以测试里单独载一次。
  @visibleForTesting
  void loadChapterLinksForTest() => _loadChapterLinks();

  /// 建剧情 `Scene`（`onLoad` 里走 `_loadSceneData`；测试要单独来一次）
  @visibleForTesting
  void loadSceneForTest() => _loadSceneData();

  /// 让剧情脚本**不等按键**（等价于玩家按住 START）——
  /// 测"脚本会演到哪一步"时必须开，否则会卡在第一句对白上。
  @visibleForTesting
  void skipSceneForTest() => scene?.startSkip();

  @visibleForTesting
  String? endingSceneNameForTest(int chapterIndex) {
    final g = chapterIndex >= 0 && chapterIndex < _chapterLinks.length
        ? _chapterLinks[chapterIndex]['eventGroupName'] as String?
        : null;
    if (g == null) return null;
    final eg = _eventGroups[g];
    return eg is Map ? eg['endingSceneEvents'] as String? : null;
  }

  /// 某一章的**开场**剧情脚本名（`beginningSceneEvents`）
  @visibleForTesting
  String? beginningSceneNameForTest(int chapterIndex) {
    final g = chapterIndex >= 0 && chapterIndex < _chapterLinks.length
        ? _chapterLinks[chapterIndex]['eventGroupName'] as String?
        : null;
    if (g == null) return null;
    final eg = _eventGroups[g];
    return eg is Map ? eg['beginningSceneEvents'] as String? : null;
  }

  @visibleForTesting
  int get sceneChapterForTest => sceneChapter;
  @visibleForTesting
  set sceneChapterForTest(int v) => sceneChapter = v;

  @visibleForTesting
  String? get lastEndEventForTest => _lastEndEvent;
  @visibleForTesting
  set lastEndEventForTest(String? v) => _lastEndEvent = v;

  @visibleForTesting
  void raiseFlagForTest(int flag) => eventFlags.add(flag);

  @visibleForTesting
  Future<void> maybeCallEndEventForTest() => _maybeCallEndEvent();

  /// 章节结束剧情的**结论**（转储里带出来）
  String _endEventNote = '';
  String? _lastEndEvent;

  /// `RunPhaseSwitchEvents`（`src/RunPhaseSwitchEvents.c:24-54`）——
  /// **每次阶段切换后**搜回合事件表并演出来。
  ///
  /// ```c
  /// info.listScript = GetChapterEventDataPointer(gPlaySt.chapterIndex)->turnBasedEvents;
  /// pInfo = SearchAvailableEvent(&info);
  /// if (pInfo) { ... StartEventFromInfo(&info, EV_EXEC_CUTSCENE); ... }
  /// ```
  ///
  /// 命中就置 `doneFlag`（对应 `info->flag`），所以同一条不会重复触发。
  Future<void> _runPhaseSwitchEvents() async {
    // 计数放在最前面：判据是"**每一次阶段切换**都跑了一次"
    // （原作 `RunPhaseSwitchEvents` 就在 `BmMain_ChangePhase` 里面，
    // `src/bm_08015434.c:88-90`），所以即使这里因为没表/在演出而提前返回，
    // 那也算"跑过一次"——被调用次数才是这条判据要测的东西。
    _phaseSwitchEventRuns += 1;
    if (_sceneRunning) return;

    // ★ `RunPhaseSwitchEvents` 的**第一件事**就是教学事件
    // （`src/RunPhaseSwitchEvents.c:36`：`ret = RunTutorialEvent(TUTORIAL_EVT_TYPE_PHASECHANGE);`），
    // 然后才是回合事件。用户说的"阶段切换也会触发对话"就是这一条。
    await _runTutorial(TutorialEvtType.phaseChange.id);

    final t = _turnEvents;
    final f = field;
    if (t == null || f == null) return;

    // ★ **一次阶段切换把所有命中的都演完**（原作 `SearchNextAvailableEvent`
    // 的 while 循环，`src/RunPhaseSwitchEvents.c:45-49`）。
    // 只演第一条会把序章"奥尼尔攻击"那条教学吞掉。
    final hits = t.allTurnMatches(
      turn: f.turn,
      faction: f.activeFaction,
      hasFlag: eventFlags.contains,
    );
    for (final hit in hits) {
      if (hit.doneFlag != 0) eventFlags.add(hit.doneFlag);
      final name = hit.script;
      if (name == null) continue;
      final fn = allSceneFns[name];
      if (fn == null) {
        _turnEventFired = '$name（没有这个脚本）';
        continue;
      }
      _turnEventFired = name;
      await runSceneScript(fn);
    }
  }

  /// 一次单位行动结束之后要做的事。
  ///
  /// 原作在玩家阶段 proc 里连着两步（`src/data/ProcScr_uistuff148_ref/`
  /// `dat_ProcScr_uistuff148_ref.c:283-289`）：
  ///
  /// ```c
  /// PROC_CALL_2(RunPotentialWaitEvents);          // 等待事件（Misc 表）
  /// PROC_CALL_2(EnsureCameraOntoActiveUnitPosition);
  /// PROC_CALL(PlayerPhase_FinishAction);
  /// PROC_GOTO(0x0);                               // ← 回到阶段开头
  /// ```
  ///
  /// 而阶段开头第一件事是：
  ///
  /// ```c
  /// PROC_CALL(PlayerPhase_HandleAutoEnd);         // 没有能动的单位 → 结束阶段
  /// ```
  ///
  /// 所以"最后一个单位行动完 → 自动结束回合"是**这两步连起来**的结果，
  /// 不是另加的功能。`PlayerPhase_HandleAutoEnd`（`src/playerphase_0801D808.c:52`）：
  ///
  /// ```c
  /// if (!(gPlaySt.config.disableAutoEndTurns) && (GetPhaseAbleUnitCount(gPlaySt.faction) == 0))
  ///     Proc_Goto(proc, 3);
  /// ```
  /// `EventScr_DisplayBattleQuote`：把一条文本当"战斗对白"演出来
  /// （`CallBattleQuoteEventInBattle`，`src/event.c:42-47`）。
  ///
  /// 日版那个脚本本身**未 carve**（`layout/baseline_syms.tsv:330`），
  /// 美版交叉参考的形状是 `TEXTSHOW(0xFFFF) / TEXTEND / REMA / ENDA`
  /// —— 即"显示槽 2 的文本，等按键，收对话框"。这里就按这个形状演。
  Future<void> _playTalkText(int msg, String tag) async {
    final sc = scene;
    if (sc == null || msg == 0) return;
    await runSceneScript((sc) async {
      await sc.textShow(msg);
      await sc.endCursor();
    });
    _sceneHudExtra = '$tag: 文本 ${msg.toRadixString(16)}';
  }

  /// 战斗对白：**开打之前**演（`MapAnim_CallBattleQuoteEvents`，
  /// `src/mapanim_0807CF54.c:33-40` —— 在第一轮伤害之前、
  /// `PROC_WHILE(BattleEventEngineExists)` 等它演完）。
  Future<void> _playBattleQuoteIfAny(MapUnit attacker, MapUnit defender) async {
    final t = talks;
    if (t == null) return;
    final ent = t.lookupBattleQuote(
      pidA: attacker.charIndex,
      pidB: defender.charIndex,
      chapterIndex: sceneChapter,
      flagSet: eventFlags.contains,
    );
    if (ent == null) return;
    // `CallBattleQuoteEventsIfAny`：msg 优先 → 否则 event → 最后置 flag
    _lastBattleQuote = '${attacker.charIndex} vs ${defender.charIndex} '
        '→ ${ent.msg.toRadixString(16)}';
    if (ent.msg != 0) await _playTalkText(ent.msg, '战斗对话');
    if (ent.flag != 0) eventFlags.add(ent.flag);
  }

  /// 阵亡对话：`DisplayDefeatTalkForPid`（`src/eventinfo_080858A8.c:171-195`）
  ///
  /// 先演台词，再 `SetPidDefeatedFlag`（原作就是"先起脚本、紧接着置标志"，
  /// 然后由调用方 `PROC_WHILE` 等它演完）。**没有"主角死了不说话"的分支。**
  Future<void> _playDefeatQuoteIfAny(MapUnit unit) async {
    final t = talks;
    if (t == null) return;
    if (_defeatQuoted.contains(unit.charIndex)) return;
    final ent = t.defeatTalk(
      pid: unit.charIndex,
      chapterIndex: sceneChapter,
      flagSet: eventFlags.contains,
    );
    if (ent == null) return;
    _defeatQuoted.add(unit.charIndex);
    _lastDefeatQuote = '${unit.charIndex} → ${ent.msg.toRadixString(16)}'
        '（flag ${ent.flag}）';
    if (ent.msg != 0) await _playTalkText(ent.msg, '阵亡对话');
    if (ent.flag != 0) eventFlags.add(ent.flag);
  }

  /// 一次攻击：**先对白 → 再结算 → 再处理阵亡**。
  Future<void> _attackWithQuote(
      BattleField f, MapUnit attacker, MapUnit defender) async {
    if (attacker.factionBit == Faction.blue) playerAttackCount++;
    await _playBattleQuoteIfAny(attacker, defender);
    // ★ 攻击**前后**的 HP 差 = 这一下打了多少（结构化，不解析战报字符串）
    final defBefore = defender.hp;
    final atkBefore = attacker.hp;
    _resolveAttack(f, attacker, defender);
    // ⚠️ 这里**不再**飘"整场净伤害"：`_resolveAttack` 里已经**逐段**飘了
    //（MISS / -N / CRIT -N）。上一轮那版是每场一次，看不出打了几下。
    final defDelta = defBefore - defender.hp;
    final atkDelta = atkBefore - attacker.hp;
    if (defDelta == 0 && atkDelta == 0) {
      debugPrint('[FX] 这次交战没有任何 HP 变化（攻击方 ${attacker.id}）');
    }
    _rebuildOverlay();
    _updateHud();
    await _handleDeaths(f);

    // ★ 攻击结束之后**同样**要过"等待事件 + 自动结束阶段"这一关。
    //
    // 顺序出处（proc 脚本即源码）：行动末尾是
    // `dat_ProcScr_uistuff148_ref.c:285-290`
    //   `PROC_CALL_2(ApplyUnitAction); PROC_CALL_2(HandlePostActionTraps);
    //    PROC_CALL_2(RunPotentialWaitEvents); … PlayerPhase_FinishAction; PROC_GOTO(0)`
    // 回到 label 0，而 label 0（`:258-265`）上是
    //   `StartPlayerPhaseStartTutorialEvent; PROC_WHILE(EventEngineExists);
    //    PlayerPhase_HandleAutoEnd`
    // —— **攻击和待机走的是同一条尾巴**。
    //
    // ⚠️ 原来这里**没有这一句**，而唯一的调用点又是
    // `if (r.committedMove && r.attack == null) _afterUnitAction();`
    // ——于是"最后一个能动的单位用**攻击**结束行动"时，
    // `PlayerPhase_HandleAutoEnd` 永远不会被求值：阶段不会自动结束，
    // 只能靠玩家自己开菜单选「終了」。这正是用户报的
    // "回合终了 和 我方全部行动完成结束 有 bug"。
    //
    // 只在**我方阶段**做：敌方/NPC 阶段由 `_runFactionAi` 自己管，
    // `PlayerPhase_HandleAutoEnd` 按名字也只管玩家阶段。
    if (f.activeFaction == Faction.blue) await _afterUnitAction();
  }

  /// 结算之后处理阵亡（台词 + 标志）。
  Future<void> _handleDeaths(BattleField f) async {
    for (final u in f.units.toList()) {
      if (u.hp <= 0 && u.isAlive) u.hp = 0;
      if (u.hp <= 0) await _playDefeatQuoteIfAny(u);
    }
  }

  /// 一次行动结算完：**等待事件 → 章节结束剧情 → 然后**才判要不要自动结束阶段。
  ///
  /// 顺序出处（proc 脚本就是源码，不是我排的）：
  /// `dat_ProcScr_uistuff148_ref.c:279-290` 行动末尾
  /// `… RunPotentialWaitEvents; PlayerPhase_FinishAction; PROC_GOTO(0)`
  /// → label 0（`:258-266`）
  /// `StartPlayerPhaseStartTutorialEvent; PROC_WHILE(EventEngineExists);
  ///  PlayerPhase_HandleAutoEnd`
  /// —— **先等事件引擎跑完，再判自动结束**。
  ///
  /// ⚠️ 原来这里是 `unawaited(_checkObjectives())` + `if (_sceneRunning) return;`：
  /// `unawaited` 之后那一行**立刻**执行，而 `_sceneRunning` 要等异步体跑起来
  /// 才被置上 —— 也就是"剧情还没起来就把阶段结束了"。两条结束路径因此不一致
  /// （菜单那条在 `_endTurn` 里是 `await _checkObjectives()` 的）。
  Future<void> _afterUnitAction() async {
    final f = field;
    if (f == null) return;

    // ① 等待事件（`RunPotentialWaitEvents` → `CheckForWaitEvents`）
    //    里面含 `RunTutorialEvent(TUTORIAL_EVT_TYPE_POSTACTION)`
    //    （`src/CheckForWaitEvents.c:45`）
    await _checkObjectives();
    await _runTutorial(TutorialEvtType.postAction.id);
    // ①'' 行动完之后 proc 会 `PROC_GOTO(0)` 回到 label 0，那里是
    //     `StartPlayerPhaseStartTutorialEvent`（`src/eventinfo_0808682C.c:45-52`）
    await _runTutorial(TutorialEvtType.playerPhase.id);
    // ①' 章节结束剧情（`PlayerPhase_FinishAction` → `MaybeCallEndEvent`）
    await _maybeCallEndEvent();
    // 事件引擎还在跑就不判（原作 label 0 的 `PROC_WHILE(EventEngineExists)`）
    if (_sceneRunning) return;

    // ② 自动结束（`PlayerPhase_HandleAutoEnd`）
    //    源码把配置开关放在**同一个条件**里：
    //    `if (!(gPlaySt.config.disableAutoEndTurns) && (GetPhaseAbleUnitCount(...) == 0))`
    //    （`src/playerphase_0801D808.c:54`）
    if (!(playConfig.disableAutoEndTurns &&
            f.activeFaction == Faction.blue) &&
        f.phaseAbleCount(f.activeFaction) == 0) {
      autoEndTriggersForTest += 1;
      endTurn();
    }
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
      _lastObjectiveHit = hit.script;
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
        ..encodedRange = v.encodedRange
        // ⚠️ `attributes` 也必须拷 —— 否则 `attributesOf()` 恒为 0，
        // `IA_NEGATE_CRIT` / `IA_NEGATE_FLYING` 的判定永远为假。
        ..attributes = v.attributes;
    }
    return t;
  }

  void _loadBattleData() {
    Map<String, dynamic> read(String name) {
      final f = File('tools/pipeline/out/tables/$name');
      if (!f.existsSync()) return const {};
      return jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
    }

    // 設定屏的选项表（`gGameOptions` + `gGameOptionsUiOrder`）
    final oj = read('game_options.json');
    final oList = (oj['options'] as List?)?.cast<Map<String, dynamic>>();
    final oOrder = (oj['uiOrder'] as List?)?.cast<int>();
    if (oList != null && oOrder != null && oList.isNotEmpty) {
      _gameOptionRows = [
        {
          '_options': oList,
          '_uiOrder': oOrder,
          '_toField': (oj['optionToConfigField'] as Map<String, dynamic>? ?? {}),
        },
      ];
      // ⚠️ **"哪个选项对应 `gPlaySt.config.disableAutoEndTurns`" 取不到**：
      // 那个映射在 `func`（`GenericOptionChangeHandler` 等）的 **C 代码**里，
      // 数据表只有 msgId/取值文本/函数名。⇒ 不编一个 msgId 出来；
      // `gameOptionMsgIdAutoEnd` 保持 null ⇒ 屏上的值**不会**写回配置，
      // 转储里的 `gameOptionsWired` 会如实标成 false。
    } else {
      debugPrint('[OPTIONS] 读不到 game_options.json —— 設定屏会明确说取不到，不兜底');
    }

    // 地形窗口的三张表（`terrains.json` 的 `tables`）
    final tj = read('terrains.json');
    List<int> valsOf(String key) {
      final tb = (tj['tables'] as Map<String, dynamic>?)?[key];
      final v = (tb as Map<String, dynamic>?)?['values'];
      return v is List ? v.cast<int>() : const [];
    }

    final tenum = tj['enum'] as Map<String, dynamic>? ?? {};
    for (final e in tenum.entries) {
      final v = (e.value as num?)?.toInt();
      if (v != null) _terrainEnumById[v] = e.key;
    }

    _terrainDefCommon = valsOf('TerrainTable_Def_Common');
    _terrainAvoCommon = valsOf('TerrainTable_Avo_Common');
    _terrainMovCostBerserker = valsOf('TerrainTable_MovCost_BerserkerNormal');

    // 章节的目标窗口文本 id（`goalWindowTextId`，`src/data/chapter_settings.h`）
    final chjGoal = read('chapters.json');
    for (final e in (chjGoal['chapters'] as List? ?? const [])) {
      final m = e as Map<String, dynamic>;
      final i = (m['index'] as num?)?.toInt();
      final g = (m['goalWindowTextId'] as num?)?.toInt();
      if (i != null && g != null) _chapterGoalTextId[i] = g;
    }

    final cj = read('classes.json');
    for (final e in (cj['classes'] as Map<String, dynamic>? ?? {}).entries) {
      final m = e.value as Map<String, dynamic>;
      final n = (m['number'] as num?)?.toInt();
      if (n != null) _classNameByNumber[n] = e.key;
    }
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
      if (n is int) {
        _itemStats[n] = ItemStats.fromJson(mm);
        // 道具名（`ITEM_VULNERARY` 这种）—— 回复量的 switch 按名字分支
        //（`src/GetUnitItemHealAmount.c` 用的是 `ITEM_*` 枚举）
        if (mm['key'] is String) _itemNameByNumber[n] = mm['key'] as String;
        if (mm['nameTextId'] is int) _itemNameTextId[n] = mm['nameTextId'] as int;
        // 只给转储用：`ITEM_SWORD_RAPIER` 比 `9` 好读太多
        final key = mm['key'] as String?;
        if (key != null) _itemNames[n] = key.replaceFirst('ITEM_', '');
      }
    }

    // ★ **结算器必须拿真实表，而且与 `_items` 是同一个对象。**
    //
    // `CombatResolver.items` 存的是**表对象**，不是 `_items` 这个变量 ——
    // 所以"先建结算器、再换 `_items`"会让伤害/命中一路算在演示表上
    // （演示表只有 8 项，细剑是 9 号 → 查不到 → 威力 0 → "打不死人"）。
    if (_itemStats.isEmpty) {
      // 表缺失是**响亮**的失败，不是静默退回演示值
      _items = _demoItems();
      status.value = '⚠️ 道具表缺失（items.json），退回演示表';
    } else {
      _items = _realItems();
    }
    combat = CombatResolver(
      items: _items,
      triangle: _loadTriangleTable(),
      monsterClassList: _monsterClassList(),
    );
    status.value = '战斗数据：职业 ${_classStats.length} / '
        '角色 ${_charStats.length} / 道具 ${_itemStats.length}';
  }

  /// 载入**规则层**的数据表：职业 / 角色 / 道具 / 单位表 / 章节 / 胜负条件。
  ///
  /// ## 为什么单独一个方法，而不是写在 `onLoad` 里
  ///
  /// 这一步是**纯 IO + 纯 Dart**（不碰 Flame），所以测试可以直接调。
  /// 整条 `onLoad` 是测不动的：它要过 `TiledComponent.load`，
  /// 而图片解码在 widget test 的假异步里不会完成 ——
  /// 实测 `status` 会永远停在「启动中…」，于是"战斗数据接错了"这类问题
  /// **在测试里根本走不到**，只能靠肉眼看画面（这正是这次踩的坑）。
  @visibleForTesting
  void loadRuleData() {
    _loadTalks();
    classTable = _loadClassTable();
    _loadUnitDefs();
    _loadBattleData();
    _loadCharNames();
    _loadObjectives();
    _loadChapters();
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
      final def = UnitDef.fromJson(m);
      // `allegiance` -> 阵营。**查表，不猜**：
      //   `include/bmunit.h:299-302`
      //     FACTION_ID_BLUE = 0 / GREEN = 1 / RED = 2 / PURPLE = 3
      // 我第一版写成 `1 => red, 2 => green`（想当然以为"蓝红绿"），
      // 于是序章敌人被载入成绿色 NPC —— "地图上没有敌人"。
      final faction = def.factionBit;
      if (faction == null) {
        _sceneHudExtra = '载入 $name：阵营越界 ${def.allegiance}（跳过）';
        continue;
      }
      final charIndex = def.charIndex;
      // ★ 移动力来自**职业表**（`ClassData.baseMov`），不是默认值。
      //
      // ⚠️ `MapUnit.movement` 的默认值是 5，而这里原来**没有传**它 ——
      // 于是赛特（圣骑士，`baseMov = 8`）只能走 5 格。走不到人面前，
      // 战斗就打不起来（而且不报错）。
      final clsStats = _classStats[def.classIndex];
      if (clsStats == null) {
        _sceneHudExtra = '缺职业 ${def.classIndex}（classes.json）—— 移动力按 5';
      }
      // ★ **同一个角色已经在场上 → 不新建**。
      //
      // 出处 `LoadUnit_0`（`src/eventscr_0800F8D4.c:45-95`）：
      //
      // ```c
      // unit = GetUnitFromCharIdAndFaction(def->charIndex, FACTION_BLUE);
      // if (unit) { UnitChangeFaction(unit, allegianceLookup[def->allegiance]); ... }
      // if (!unit) unit = LoadUnit(def);          // ← 只有找不到才新建
      // else if (def->allegiance == FACTION_ID_BLUE) LoadUnit_MoveToPosition(unit, def, b, quiet);
      // ```
      //
      // ⚠️ 不做这一步的症状：序章**敌人被载入两次** ——
      // 开场脚本末尾 `CALL(EventScr_Prologue_ONeillSpawn)` 一次，
      // 回合 1 的敌方阶段事件 `EventScr_Prologue_Turn1` 又调一次
      // （`src/data/data_08A612F4/data_08A612F4.s:32-40`）→
      // 奥尼尔和两个杂兵各变成两个。
      //
      // 非我方分支里原作只查 BLUE 区块（`GetUnitFromCharIdAndFaction`
      // 只搜一个区块，`src/GetUnitFromCharIdAndFaction.c:31-42`），
      // 按那条读会**照样重复**；这里按"角色在场上唯一"处理，
      // 与可观测行为一致。**这一处与原作的非我方分支不完全等同，记在此处。**
      final existing = cur.units
          .where((u) => u.charIndex == charIndex)
          .firstOrNull;
      if (existing != null) {
        existing.x = def.x;
        existing.y = def.y;
        if (existing.faction != faction) {
          // 阵营变了（`UnitChangeFaction`）——`MapUnit.faction` 是 final，
          // 所以整块换掉，保留编号之外的属性
          final replaced = def.toMapUnit(
            id: existing.id,
            faction: faction,
            movement: _classStats[def.classIndex]?.baseMov ?? 5,
            makeItem: _makeNewItem,
            name: existing.name,
          );
          field = cur.withUnitReplaced(existing.id, replaced);
        }
        continue;
      }

      added.add(def.toMapUnit(
        // ⚠️ **编号必须全局唯一**：原来是 `0x100 + added.length`，
        // 每次 LOAD 都从 0x100 重新数 → 敌人的组件顶掉我方的组件。
        id: _nextUnitId(faction),
        faction: faction,
        movement: clsStats?.baseMov ?? 5,
        makeItem: _makeNewItem,
        // 名字给**人看**（战报里会出现）——角色名来自 `char_names.json`；
        // 查不到就退回"角色NN"，不要用 `C$cls` 这种占位。
        name: _charNames?[charIndex]?.replaceFirst('CHARACTER_', '') ??
            '角色$charIndex',
      ));
    }
    _addUnits(added);
    _sceneHudExtra = '载入 $name（${added.length} 个单位）';
    // 把地图切换记录也带上 —— 它比「载入单位」更能说明脚本走到哪了
    _sceneHudExtra = '$_sceneHudExtra  $_sceneMapHistory';
  }

  /// 单位编号分配器 —— **按阵营区块**分配。
  ///
  /// ## 出处：编号的**高位就是阵营**
  ///
  /// `include/bmunit.h:477`
  ///
  /// ```c
  /// #define UNIT_FACTION(aUnit) ((aUnit)->index & 0xC0)
  /// ```
  ///
  /// 编号是 `gUnitLut` 的下标，区块固定：
  ///
  ///     我方   0x01..0x3F
  ///     友军   0x41..0x7F
  ///     敌方   0x81..0xBF
  ///
  /// 而阶段推进的 `GetPhaseAbleUnitCount(units, faction)`
  /// （`PhaseRules.getPhaseAbleUnitCount`，`lib/core/battle/phase.dart:122`）就是
  /// **按 id 区间数的**：
  ///
  /// ```c
  /// for (id = faction + 1; id < faction + 0x40; id++) { ... }
  /// ```
  ///
  /// ⚠️ 我原来从 `0x100` 开始递增（为了修"敌人顶掉我方组件"那个 id 撞车 bug），
  /// 结果 id 落在**区块之外**：`phaseAbleCount(red)` 恒为 0 →
  /// 敌方阶段被 `shouldAutoEndPhase` 当成"没人能动"直接跳过 →
  /// **AI 一步都不走**，战斗永远打不起来。而且完全不报错。
  ///
  /// 按区块分配同时解决了 id 撞车（区块不重叠）——
  /// 比"从 0x100 开始全局递增"更贴近原作。
  final Map<int, int> _unitIdSeq = {
    Faction.blue: 0x01,
    Faction.green: 0x41,
    Faction.red: 0x81,
  };

  int _nextUnitId(int faction) {
    final key = faction & 0xC0;
    final next = _unitIdSeq[key] ?? 0x01;
    // 区块上限 0x3F 个；真撞上就显式报出来，不要静默绕回去
    if ((next & 0xC0) != key) {
      _sceneHudExtra = '单位编号超出阵营区块：faction=$key next=0x${next.toRadixString(16)}';
      return next;
    }
    _unitIdSeq[key] = next + 1;
    return next;
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

    // 大地图数据（节点/路径/章节→章间脚本）—— `parse_worldmap.py` 的头注释
    final wmf = File('tools/pipeline/out/tables/worldmap.json');
    if (wmf.existsSync()) {
      _worldMapData = WorldMapData.parse(wmf.readAsStringSync());
      _chapterWm = {
        for (final e in (jsonDecode(wmf.readAsStringSync())
                as Map<String, dynamic>)['chapterWm'] as List<dynamic>)
          (e as Map<String, dynamic>)['index'] as int: e,
      };
    } else {
      _tutorialNote = '缺少 worldmap.json —— 大地图不会出现';
    }

    // 教学事件表（指针数组）—— 出处 `parse_tutorial_lists.py` 的头注释
    final tl = File('tools/pipeline/out/tables/tutorial_lists.json');
    if (tl.existsSync()) {
      final td = jsonDecode(tl.readAsStringSync()) as Map<String, dynamic>;
      _tutorialLists = {
        for (final e in (td['lists'] as Map<String, dynamic>).entries)
          e.key: (e.value as List).cast<String>(),
      };
    } else {
      _tutorialNote = '缺少 tutorial_lists.json —— 教学事件不会触发';
    }
  }

  /// 切到某一章：重建地图与单位，然后演这一章的**开场脚本**。
  ///
  /// 出处：`src/gamecontrol_08009CF8.c:53`（`gPlaySt.chapterIndex = proc->nextChapter;`）
  /// 与 `src/Event2A_MoveToChapter.c:39`（`EVSUBCMD_MNC2`）。
  Future<void> _gotoChapter(int chapterIndex) async {
    if (chapterIndex < 0 || chapterIndex >= _chapterLinks.length) return;
    _mapReady = false;
    _clearWorldMapView();
    worldMap = null;
    _wmTargetChapter = null;
    sceneChapter = chapterIndex;
    // `StartBattleMap` → `ResetChapterFlags()`（`src/bmio_08030D50.c:151`）：
    // **战斗地图开始时清事件标志**。事件标志必须跨事件保留 ——
    // `StartEventFromInfo` 靠 `SetFlag(info->flag)` 记「这条演过了」
    // （`src/eventinfo_080851B8.c:148`）。
    eventFlags.clear();
    await _loadChapterMap(chapterIndex);

    // ★ **章节标题卡 + 地图淡入**。
    //
    // 出处：`MNC2`（`src/Event2A_MoveToChapter.c:39-47`）只置
    // `EV_STATE_CHANGECH` 并停掉 BGM；真正把画面从黑里带回来的是
    // 章节开头那一套 `gProcScr_ChapterIntro`
    // （`src/ChapterIntro_DrawChapterTitle.c` 画标题、
    //  `src/chapterintrofx_0802099C.c:46` 的 `ChapterIntro_LoopFadeToMap` 混合淡入）。
    //
    // ⚠️ 不做这一步的症状：`MNC2` **之前**那次 `FADI` 留下的黑屏**永远不散**
    // —— 序章打完切到第 1 章就是一片黑（地图和单位都在，但看不见）。
    _skipRequested = false;
    await _sceneView?.chapterIntro(
      chapterTitle(chapterIndex),
      skipping: () => _skipRequested,
    );
    await _sceneView?.fade(FadeDirection.fromBlack, 16,
        camera.viewport.virtualSize);

    await _startRealScene();
    _mapReady = true;
    // 地图开始 ⇒ 目标窗口（原作 `StartPlayerPhaseSideWindows`：
    // `disableGoalDisplay == 0` 且旗 102 未置位时 `Proc_Start(gProcScr_GoalDisplay)`）
    _touchGoalWindow();
  }

  /// 章节标题（`texts.titles[内部名]`，如 `L01` = 消息 233「脱出行」）
  ///
  /// 出处：`src/chapter_title.c:37` `GetChapterTitleWM` →
  /// `GetROMChapterStruct(chapterData->chapterIndex)->chapTitleId`。
  String chapterTitle(int chapterIndex) {
    final name = chapterInternalName(chapterIndex);
    return gameTexts?.titles[name] ?? '';
  }

  /// START 键是否被按过（章节标题卡用它跳过）
  bool _skipRequested = false;

  /// 把当前这句对白画进对话框
  /// 换地图：`LOMA(chapterIndex)`。
  ///
  /// 两跳查表（都由数据管线产出）：
  ///   `chapterIndex` → `chapters.json[].internalName`
  ///                  → `chapter_maps.json[internalName].map` → `out/tmx/<map>.tmx`
  ///
  /// 出处：`src/eventscr_0800F390.c:45-68` —— 操作数是 **chapterIndex**，
  /// 不是资产 id；序章靠三次 `LOMA` 在王座厅 → 王宫外 → 可玩地图之间切。
  /// 换地图 —— `LOMA(chapterIndex)`。
  ///
  /// ## ⚠️ 查表必须**按 index**
  ///
  /// 原来走的是 `chapterIndex → chapters.json[].internalName
  /// → chapter_maps.json[内部名]` —— 而两张表对同一章用的键**不一样**：
  ///
  /// ```
  /// index 64: chapters.json 的 internalName = '-'      （这一章没有名字）
  ///           chapter_maps.json 的键        = 'CH65'
  /// ```
  ///
  /// 于是 `chapterMapName('-')` 返回 null → **静默不换图**。
  /// 序章的"王宫外"那一幕（`LOMA(0x40)` = 64）就是这么丢的
  /// （用户指出的），脚本里 46 个 LOMA 目标里有 11 个受影响。
  ///
  /// 现在按 `byIndex` 查；名字只作兜底，而且**失败会记下来**。
  Future<void> _loadChapterMap(
    int chapterIndex, {
    int? cameraX,
    int? cameraY,
  }) async {
    final mapName = chapterMapNameByIndex(chapterIndex) ??
        chapterMapName(chapterInternalName(chapterIndex));
    if (mapName == null) {
      sceneMapNote = 'LOMA($chapterIndex) → 章节表里没有地图名';
      _noteMapFailure(chapterIndex, sceneMapNote);
      return;
    }
    // 资源在 `assets/maps/`（与 `TiledComponent` 的默认查找前缀一致）
    if (!File('assets/maps/$mapName.tmx').existsSync()) {
      sceneMapNote = 'LOMA($chapterIndex) → assets/maps/$mapName.tmx 不存在';
      _noteMapFailure(chapterIndex, sceneMapNote);
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

    // ★ 相机：`LOMA` 会把槽 0xB 的 (x, y) 居中（`Event25_ChangeMap` 结尾两行）。
    // 不给就居中到地图中央。
    //
    // ⚠️ 这一条**不是装饰**：序章王座厅那一幕 `SVAL(EVT_SLOT_B, 0x000A000E)`
    // 明确要求相机在 (14, 10)，而地图中央是另一处 —— 取景不同，看到的
    // 房间也不同（用户说的"背景地图应该是王宫里"）。
    _centerCameraOn(
      cameraX ?? (g?.width ?? 2) ~/ 2,
      cameraY ?? (g?.height ?? 2) ~/ 2,
    );

    sceneMapNote = 'LOMA($chapterIndex) → $mapName';
    // 地图切换历史 —— 用它判断脚本走到了哪一步
    _sceneMapHistory = '$_sceneMapHistory $mapName';
    // ★ 地图就绪标志放**这里**（不是 `_gotoChapter` 末尾）。
    //
    // 序章的地图是**开场脚本里的 `LOMA` 装的**，根本不经过 `_gotoChapter`
    // —— 原来的写法让 `_mapReady` 永远为假，于是"等地图就绪再进大地图"
    // 这条条件永远不成立（实测：`FE8R_WM=56` 那轮 WM 一次都没进，
    // 而日志里连一条 `[WM]` 都没有）。
    _mapReady = true;
    _touchGoalWindow();   // LOMA 装完地图 ⇒ 同一套侧窗
    _updateHud();
  }

  /// LOMA 失败**必须留痕**。
  ///
  /// 原来只写 `sceneMapNote`（一个 HUD 字段），而 `_sceneMapHistory`
  /// 照旧 —— 于是转储里"地图历史"看起来是完整的，
  /// **缺的那一张根本不在记录里**。我就是这么漏掉序章第二幕的。
  void _noteMapFailure(int chapterIndex, String why) {
    _sceneMapHistory = '$_sceneMapHistory !LOMA($chapterIndex)';
    if (!_mapLoadFailures.contains(why)) _mapLoadFailures.add(why);
    debugPrint('[LOMA] 失败：$why');
    // ★ 屏幕上也要说：否则玩家看到的就是"黑屏/没反应"（反馈里的"卡住"多半是这个）
    _playNote = '地图没打包：$why（走不下去了，见 docs/试玩.md）';
    _updateHud();
  }

  /// LOMA 失败原因（转储里会带出来）
  final List<String> _mapLoadFailures = [];

  /// 章节号 → 内部名（`chapters.json`）
  String chapterInternalName(int index) {
    for (final c in chapters?.list ?? const <ChapterData>[]) {
      if (c.index == index) return c.internalName;
    }
    return '-';
  }

  /// 内部名 → 地图名（`chapter_maps.json` 的 `chapters`，仅供人读）
  String? chapterMapName(String internalName) => _chapterMaps[internalName];

  /// **章节号 → 地图名**（`chapter_maps.json` 的 `byIndex`，权威键）
  ///
  /// ⚠️ 必须用 index：`chapters.json` 里 19 个过场章的 `internalName` 是 `'-'`，
  /// 而 `chapter_maps.json`（按资产符号名）里它们是 `CH64` / `CH67` 这种 ——
  /// **两张表对同一章用的键不同**，用名字 join 必然静默漏掉。
  String? chapterMapNameByIndex(int index) =>
      _chapterMapsByIndex[index.toString()];

  Map<String, String> _chapterMapsByIndex = const {};

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
    // 权威键（`LOMA` 的操作数是 chapterIndex）
    final byIdx = d['byIndex'] as Map<String, dynamic>? ?? const {};
    _chapterMapsByIndex = {
      for (final e in byIdx.entries)
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
    unawaited(_endTurn());
  }

  /// 回合结束的完整序列。
  ///
  /// 原作是一条 proc 链：`SwitchPhases` →（`RunPhaseSwitchEvents`）→
  /// 敌方/NPC 阶段由 `gProcScr_CpPerform` **逐个单位**行动，每个单位
  /// 行动完都 `PROC_CALL_2(RunPotentialWaitEvents)`
  /// （`src/data/data_085D1F2C/data_085D1F2C.c:40`）。
  ///
  /// ⚠️ 这两步都必须是**阻塞**的：等待事件可能起一段剧情（打死首领 →
  /// 结束脚本 → `MNC2` 切章），后面的事得等它演完。
  /// 我原来把 `_checkObjectives` 写成 `unawaited(...)`、而且只在
  /// `endTurn` 开头查一次 —— 于是**敌方阶段里打死首领，什么都不会发生**
  /// （Seth 反击杀掉奥尼尔那条路就是这么断的）。
  Future<void> _endTurn() async {
    final f = field;
    if (f == null || state == null) return;
    try {
      await _endTurnInner();
    } finally {
      _turnRunning = false;
    }
  }

  Future<void> _endTurnInner() async {
    final f = field;
    if (f == null || state == null) return;

    // 回合结束是胜负判定点之一（原作 `CheckForWaitEvents` 挂在等待事件上）
    await _checkObjectives();

    _turnLoopNote = '';
    _turnRunning = true;
    var steps = 0;
    // 最多转 6 个阶段，防止任何意外造成死循环
    // （正常一个回合是 3 步：蓝→红→绿→蓝）
    for (var guard = 0; guard < 6; guard++) {
      // ★ **一次 `BmMain_ChangePhase`**（`src/bm_08015434.c:82-95`）：
      // `ClearActiveFactionGrayedStates` → `RefreshUnitSprites` → `SwitchPhases`
      // 然后**立刻** `RunPhaseSwitchEvents`。
      //
      // ⚠️ 事件必须**每一步都跑**。原来是把"跳过空阶段"折成一个循环、
      // 循环外只跑一次 —— 于是被跳过的阶段（序章/第 1 章之外的很多章里
      // 绿色阶段有 TURN 条目）的回合事件永远不触发。
      final autoEnd =
          stepPhase(f, disableAutoEndTurns: playConfig.disableAutoEndTurns);
      steps += 1;
      // 回合横幅（`ProcScr_PhaseIntro` 在每次阶段切换都会演一次；
      // 没人可动的阶段由 `PhaseIntro_EndIfNoUnits` 直接跳过 —— 这里同理）
      _showPhaseBanner(f);
      await _runPhaseSwitchEvents();

      if (autoEnd) {
        // 这个阶段**自己**结束：我方 = `PlayerPhase_HandleAutoEnd`；
        // 敌方/NPC = AI 没人可跑（`gProcScr_CpPhase` + `src/CpDecide_Main.c:78`）
        // ⇒ 不跑行动，继续切下一个阶段
        continue;
      }

      if (f.activeFaction == Faction.blue) {
        // 回到玩家回合。
        //
        // ⚠️ 用**当前的** `state`（不是进这个函数时的快照 `s`）：
        // 敌方阶段/剧情可能改过它（光标、选中），拿旧快照会把那些改动抹掉。
        final cur = state;
        if (cur == null) return;
        state = cur.copyWith(
          phase: FlowPhase.freeCursor,
          selectedUnitId: null,
          moveOriginX: null,
          moveOriginY: null,
          turn: f.turn,
          faction: f.activeFaction,
        );
        // label 0 的 `StartPlayerPhaseStartTutorialEvent`
        await _runTutorial(TutorialEvtType.playerPhase.id);
        _rebuildOverlay();
        _updateHud();
        return;
      }

      await _runFactionAi(f);
    }

    // 转满 6 步还没回到我方：只可能是所有阵营都没有能动的人。
    // 响亮记下来（不许静默地"看着像结束了"）。
    _turnLoopNote = '转满 6 步没回到我方阶段：faction=${f.activeFaction} '
        'able=(blue ${f.phaseAbleCount(Faction.blue)} / '
        'green ${f.phaseAbleCount(Faction.green)} / '
        'red ${f.phaseAbleCount(Faction.red)}) steps=$steps';
    _rebuildOverlay();
    _updateHud();
  }

  // ---------------------------------------------------------------------
  // 大地图（`ProcScr_WorldMapWrapper` 的最小等价物）
  // ---------------------------------------------------------------------

  /// 进入大地图。目标章节由 `MNCH(n)` 给出。
  ///
  /// 部队所在节点的**初值**照 `src/worldmap_path.c:148`（`= 0`）；
  /// 之后它是持久状态 —— 所以这里**不重置**已存在的 `worldMap`。
  void _enterWorldMap(int target) {
    final wm = worldMap ?? WorldMapState(node: 0);
    worldMap = wm;
    _wmTargetChapter = target;
    _refreshWorldMap();
    _showWorldMapView();
    if (wm.chapterId(worldMapRules!) == target) {
      _worldMapNote = '已经在目标章节的节点上（${wm.node}）';
    } else if (wm.nextNodeId < 0 || wm.nextNodeId == wm.node) {
      // ★ 响亮：没有可走的边就不许静默（玩家会以为按键坏了）
      _worldMapNote = '节点 ${wm.node} 没有下一个目的地'
          '（条件旗 ${_worldMapData!.nodes[wm.node].unk06} 未置上）';
    } else {
      _worldMapNote = '';
    }
    _playNote = '大地图：当前节点 ${wm.node}（${_wmNodeName(wm.node)}）'
        '· 下一个 ${wm.nextNodeId < 0 ? "—" : wm.nextNodeId}'
        '· 目标第 $target 章 · ${_worldMapNote.isEmpty ? "按确认前进" : _worldMapNote}';
    debugPrint('[WM] 进入大地图 node=${wm.node} target=$target note=$_worldMapNote');
  }

  String _wmNodeName(int idx) {
    final d = _worldMapData;
    if (d == null || idx < 0 || idx >= d.nodeCount) return '?';
    final id = d.nodes[idx].nameTextId;
    final msg = gameTexts?.byId(id);
    final plain = msg?.plain ?? '';
    return plain.isEmpty ? '#$id' : plain;
  }

  /// 按当前事件旗重算"下一个节点"（`WMLoc_GetNextLocId`）
  void _refreshWorldMap() {
    final wm = worldMap;
    final r = worldMapRules;
    if (wm == null || r == null) return;
    wm.note = _worldMapNote;
    wm.nextNodeId = wm.nextNode(
      r,
      eventFlags.contains,
      // ⚠️ 路线模式（`gPlaySt.chapterModeIndex`）的真值来自存档，属于 M9；
      // 这里固定 Eirika 并**记录下来**，不假装支持双路线。
    );
  }

  void _showWorldMapView() {
    final d = _worldMapData;
    final wm = worldMap;
    if (d == null || wm == null) return;
    // ⚠️ **规则与视图解耦**：`camera.viewport.virtualSize` 需要 Game 已经
    // 布局过（`hasLayout`），而 widget test 里跑的是 `loadRuleData()`，
    // 没有 layout —— 没有这一句，`MNCH` 的**状态机**就没法单测。
    if (!hasLayout) return;
    _clearWorldMapView();
    // ★ 必须挂到 **viewport**（屏幕空间），不能挂在 `world` 里。
    //
    // 挂 `world` 会被相机的平移/缩放带着走：节点是按 470×300 的数据坐标画的，
    // 而相机在看战场（可能已滚动），于是 WM 只盖住画面一部分、右侧露出地图瓦片
    // —— 这就是欠账 9（第一张 WM 截图）。
    // 优先级 50 高于 `world`、远低于剧情层（`SceneView` 用 `1 << 20`），
    // 所以对白与立绘仍然在 WM **之上**（与原作一致：WM 上要弹对话框）。
    _wmView = WorldMapView(
      data: d,
      state: wm,
      textForName: (id) {
        final plain = gameTexts?.byId(id)?.plain ?? '';
        return plain.isEmpty ? '#$id' : plain;
      },
      screen: camera.viewport.virtualSize,
    );
    camera.viewport.add(_wmView!);
    _rebuildOverlay();
  }

  WorldMapView? _wmView;

  /// 出发时演的章间脚本（`Events_WM_Beginning[gmapEventId]`）—— 判据用
  String? _lastWmBeginningScript;

  /// 收起大地图视图（**空安全**）。
  ///
  /// ⚠️ 原来三处都写 `world.remove(_wmView!)` —— 而"没有 layout 时根本不建视图"
  /// （见 `_showWorldMapView`），于是单测路径上必然 `null!`。
  /// 这跟地图菜单那次崩溃是**同一个形状**：先置空/没建，再解引用。
  void _clearWorldMapView() {
    if (_wmView != null) {
      camera.viewport.remove(_wmView!);
      _wmView = null;
    }
  }

  /// 大地图上的确认键。
  ///
  /// * 站在**目标章节**的节点上 → 演 `Events_WM_Beginning[gmapEventId]`
  ///   （`src/worldmap_main_080BF178.c:117`）然后进地图
  /// * 否则 → 沿 `WMLoc_GetNextLocId` 走到下一个节点
  ///   （走的是 `src/worldmap_main_080BDA6C.c:140` 那条"到达后更新 location"）
  Future<void> worldMapConfirm() async {
    final wm = worldMap;
    final r = worldMapRules;
    final target = _wmTargetChapter;
    if (wm == null || r == null || target == null) return;

    if (wm.chapterId(r) == target) {
      final script = _chapterWm[target]?['wmBeginning'] as String?;
      _clearWorldMapView();
      worldMap = null;
      _wmTargetChapter = null;
      _playNote = kPlayNote;
      // 章间脚本（`Events_WM_Beginning`）—— 有就演，没有就记下来
      _lastWmBeginningScript = script;
      if (script != null && allSceneFns.containsKey(script)) {
        await _runNamedScript(script);
      } else {
        _worldMapNote = '没有章间脚本（$target → ${script ?? "NULL"}）';
        debugPrint('[WM] $_worldMapNote');
      }
      await _gotoChapter(target);
      return;
    }

    final arrived = wm.travelToNext(r, eventFlags.contains);
    if (arrived == null) {
      _worldMapNote = '节点 ${wm.node} 走不动'
          '（条件旗 ${_worldMapData!.nodes[wm.node].unk06} 未置上）';
      debugPrint('[WM] $_worldMapNote');
    } else {
      _worldMapNote = '';
    }
    _refreshWorldMap();
    _showWorldMapView();
    _playNote = '大地图：当前节点 ${wm.node}（${_wmNodeName(wm.node)}）'
        '· 目标第 $target 章'
        '${_worldMapNote.isEmpty ? "" : " · $_worldMapNote"}';
  }

  @visibleForTesting
  void enterWorldMapForTest(int target) => _enterWorldMap(target);

  @visibleForTesting
  Future<void> worldMapConfirmForTest() => worldMapConfirm();

  /// 三个专用触发点（选中 / 目的地 / 移动后）。
  ///
  /// 每个都照源码的顺序：**先教学钩子**（`RunTutorialEvent`），再搜自己的事件表。
  /// 三张表在各自函数里都有 **skirmish 守卫**（`GetBattleMapKind() ==
  /// BATTLEMAP_KIND_SKIRMISH` 直接返回 0）——我们只在**确认是遭遇战**时跳过，
  /// 章节种类未查证的按剧情处理（并记账，见 `battle_map_kind.dart`）。
  Future<void> _fireSpecialTriggers(FlowState before, FlowResult r) async {
    if (_isSkirmishChapter) return;

    // ① 选中单位（`TryCallSelectEvents.c:14-30`）
    if (before.phase != FlowPhase.unitSelected &&
        r.state.phase == FlowPhase.unitSelected) {
      await _runTutorial(TutorialEvtType.onSelect.id);
      await _runSpecialList('选中', _selectEvents, all: true);
    }

    // ② 目的地确定（`StartDestSelectedEvent`）与
    // ③ 移动完成（`StartAfterUnitMovedEvent`，`src/playerphase.c:94`：
    //    移动结算完、**行动菜单打开之前**）
    if (r.committedMove) {
      await _runTutorial(TutorialEvtType.destSelected.id);
      await _runSpecialList('目的地', _destEvents, all: false);
      await _runTutorial(TutorialEvtType.afterMove.id);
      await _runSpecialList('移动后', _movedEvents, all: false);
    }
  }

  /// 章节是不是**遭遇战**（`GetBattleMapKind() == BATTLEMAP_KIND_SKIRMISH`）。
  ///
  /// 章节种类只有三个章节被验证过（`battle_map_kind.dart`），其余返回 `null`
  /// ⇒ 这里当"不是遭遇战"（照剧情走），并把未查证这件事留在转储里。
  bool get _isSkirmishChapter =>
      battleMapKindOf(sceneChapter) == BattleMapKind.skirmish;

  /// 搜一张专用事件表并演出命中项。
  ///
  /// [all] = true 时演**全部**命中（`TryCallSelectEvents` 是 `while` 循环），
  /// 否则只演第一条（另两个函数是 `if (SearchAvailableEvent(...))`）。
  Future<void> _runSpecialList(
    String what,
    ChapterObjectives? list, {
    required bool all,
  }) async {
    if (list == null) return;
    var hits = list.allAfevMatches(hasFlag: eventFlags.contains);
    if (!all) hits = hits.take(1).toList();
    for (final hit in hits) {
      if (hit.doneFlag != 0) eventFlags.add(hit.doneFlag);
      final name = hit.script;
      if (name == null) continue;
      _specialEventFired = '$what：$name';
      await _runNamedScript(name);
    }
  }

  /// `MenuFrozenHelpBox` 用的那条消息（`src/MapMenu_SuspendCommand.c:4`）：
  /// 0x7E2「You cannot stop in the middle of the tutorial.」
  static const int _kTutorialNoSuspendMsgId = 0x7E2;

  /// 按消息 id 把文本显示在对话框里（找不到就**响亮**记下来）
  void _showMessageById(int id) {
    final plain = gameTexts?.byId(id)?.plain ?? '';
    if (plain.isEmpty) {
      _suspendNote = '消息 0x${id.toRadixString(16)} 取不到文本（texts 表里没有？）';
      debugPrint('[MSG] $_suspendNote');
      return;
    }
    _sceneView?.show(text: plain, virtualSize: camera.viewport.virtualSize);
    _suspendNote = '消息 0x${id.toRadixString(16)}：$plain';
  }

  /// 清场用的最小地图（1×1，只有一种地形）—— 只为让 `BattleView.sync` 有东西可查，
  /// **不参与任何规则**。
  static final MapGrid _emptyGrid = MapGrid(
    id: 'empty',
    chapter: '',
    width: 1,
    height: 1,
    tileSize: 16,
    metatiles: const [0],
    terrainIndices: const [0],
    terrainLegend: const ['TERRAIN_PLAINS'],
  );

  static MovementCostTable get _uniformCosts =>
      MovementCostTable(List<int>.filled(64, 1));

  /// 交换对象列表（`MakeTradeTargetList` + `TryAddUnitToTradeTargetList`）
  ///
  /// 逐条照 `src/bmtarget_0802506C.c:81-114`：同阵营、非幻影职业、
  /// 对方非 `UNIT_STATUS_BERSERK`、**双方 0 号槽至少一个非空**、非输送队。
  /// ⚠️ 状态/`CA_SUPPLY` 我们还没建模（见 `trade.dart` 文件头），按"没有"处理。
  List<MapUnit> tradeTargets(MapUnit subject) {
    final f = field;
    if (f == null) return const [];
    final subjPhantom = _classNameByNumber[subject.classId] == 'CLASS_PHANTOM';
    final out = <MapUnit>[];
    for (final u in f.units) {
      if (u.id == subject.id || !u.isAlive) continue;
      final allied = u.factionBit == subject.factionBit;
      if ((u.x - subject.x).abs() + (u.y - subject.y).abs() != 1) continue;
      if (!isTradeTarget(
        sameAllegiance: allied,
        subjectIsPhantom: subjPhantom,
        unitIsPhantom: _classNameByNumber[u.classId] == 'CLASS_PHANTOM',
        unitStatus: 0,
        subjectItem0: subject.items.isNotEmpty ? subject.items[0] : 0,
        unitItem0: u.items.isNotEmpty ? u.items[0] : 0,
      )) {
        continue;
      }
      out.add(u);
    }
    return out;
  }

  /// 这个单位有没有**相邻同伴**（交换的前提）。
  ///
  /// ⚠️ 原作是 `MakeTradeTargetList(gActiveUnit)` + `GetSelectTargetCount() == 0`
  /// ⇒ `MENU_NOTSHOWN`（`src/ItemSubMenu_IsTradeAvailable.c`）。
  /// 它认可的"同伴"范围我**没有逐行核对**；这里按"同阵营 + 上下左右相邻"。
  bool hasAdjacentAlly(MapUnit u) {
    final f = field;
    if (f == null) return false;
    for (final o in f.units) {
      if (o.id == u.id || !o.isAlive) continue;
      if (o.factionBit != u.factionBit) continue;
      if ((o.x - u.x).abs() + (o.y - u.y).abs() == 1) return true;
    }
    return false;
  }

  /// 子菜单的四项 + 各自可用性（照上面引的源码逐条判断）
  List<Map<String, Object?>> _subMenuEntries(MapUnit u, int slot) {
    final w = u.items[slot];
    final num = ItemTable.itemIndex(w);
    final attrs = _itemStats[num]?.attributes ?? 0;
    final isWeapon = isWeaponItem(w);
    final canUse = canUseItem(u, w);
    final entries = <Map<String, Object?>>[];
    // 使う：回复类才出现；满血则禁用
    final heal = unitItemHealAmount(
        itemNumber: num,
        isStaff: attrs & kItemStaffAttribute != 0,
        nameOf: _itemNameByNumber);
    if (heal > 0) {
      entries.add({
        'key': 'use',
        'label': '使う',
        'enabled': canUse,
        'reason': canUse ? '' : '满血（回了也没用）',
      });
    }
    // 装備：非武器 ⇒ 不显示（`IA_WEAPON`）
    if (isWeapon) {
      entries.add({
        'key': 'equip',
        'label': '装備',
        'enabled': true,
        'reason': '',
      });
    }
    // 捨てる：`IA_UNSELLABLE` ⇒ 禁用
    final unsellable = attrs & kItemUnsellableAttribute != 0;
    entries.add({
      'key': 'discard',
      'label': '捨てる',
      'enabled': !unsellable,
      'reason': unsellable ? 'IA_UNSELLABLE' : '',
    });
    // 交換：没有可交换的同伴 ⇒ 不显示（`ItemSubMenu_IsTradeAvailable` 的
    // `GetSelectTargetCount() == 0 ⇒ MENU_NOTSHOWN`）；有则**可用**
    final targets = tradeTargets(u);
    if (targets.isNotEmpty) {
      entries.add({
        'key': 'trade',
        'label': '交換',
        'enabled': true,
        'reason': '',
      });
    }
    return entries;
  }

  void _openItemSubMenu(int slot) {
    final u = field?.unitById(state?.selectedUnitId ?? -1);
    if (u == null) return;
    final entries = _subMenuEntries(u, slot);
    itemSubMenu = {'slot': slot, 'index': 0, 'entries': entries, 'stage': 'menu'};
    _subMenuDisabled = [
      for (final e in entries)
        if (e['enabled'] != true) '${e['label']}(${e['reason']})',
    ];
    _showItemSubMenu();
  }

  void _showItemSubMenu() {
    final m = itemSubMenu;
    if (m == null) return;
    final entries = (m['entries'] as List).cast<Map<String, Object?>>();
    final idx = m['index'] as int;
    final lines = <String>['道具：做什么？'];
    for (var i = 0; i < entries.length; i++) {
      final e = entries[i];
      final on = e['enabled'] == true;
      lines.add('${i == idx ? '▶ ' : '  '}${e['label']}'
          '${on ? '' : '（${e['reason']}）'}');
    }
    lines.add('A 决定   B 返回');
    lastSubMenuText = lines.join('\n');
    _itemMenuText = lastSubMenuText;
    _sceneView?.show(text: _itemMenuText, virtualSize: camera.viewport.virtualSize);
  }

  /// 子菜单里"舍弃"要先问一句（`src/ItemSubMenu_DiscardItem.c`：
  /// `gYesNoSelectionMenuDef`，且 `proc->itemCurrent = 1` ⇒ **默认落在 No**）
  void _showDiscardConfirm() {
    final yesNo = (itemSubMenu?['yesNoIndex'] as int? ?? 0) == 1;
    _itemMenuText = '「${_pendingDiscardLabel()}」を捨てますか？\n'
        '${yesNo ? '    いいえ\n  ▶ はい' : '  ▶ いいえ\n    はい'}';
    lastConfirmText = _itemMenuText;
    _sceneView?.show(text: _itemMenuText, virtualSize: camera.viewport.virtualSize);
  }

  String _pendingDiscardLabel() {
    final m = itemSubMenu;
    final u = field?.unitById(state?.selectedUnitId ?? -1);
    if (m == null || u == null) return '?';
    final slot = m['slot'] as int;
    final num = ItemTable.itemIndex(u.items[slot]);
    return _itemNameByNumber[num] ?? 'item#$num';
  }

  /// 交易界面：目标 → 我的槽 → 对方的槽 → 对调（`TradeMenu_ApplyItemSwap`）
  List<MapUnit> _tradeTargets = const [];
  int _tradeTargetIdx = 0;
  int _tradeMineSlot = 0;
  int _tradeTheirSlot = 0;

  List<int> _nonEmptySlots(MapUnit u) {
    final out = <int>[];
    for (var i = 0; i < u.items.length; i++) {
      if (u.items[i] != 0) out.add(i);
    }
    return out.isEmpty ? [0] : out;
  }

  String _itemLabel(int w) {
    final num = ItemTable.itemIndex(w);
    return _textOr(gameTexts?.byId(_itemNameTextId[num] ?? 0)?.plain,
        _itemNameByNumber[num] ?? 'item#$num');
  }

  void _showTradeScreen() {
    final f = field;
    final me = f?.unitById(state?.selectedUnitId ?? -1);
    if (me == null || _tradeTargets.isEmpty) return;
    final other = _tradeTargets[_tradeTargetIdx.clamp(0, _tradeTargets.length - 1)];
    final mine = _nonEmptySlots(me);
    final theirs = _nonEmptySlots(other);
    _itemMenuText = <String>[
      '交換：${me.name} ↔ ${other.name}',
      '我的：${mine.map((s) => _itemLabel(me.items[s])).join(" / ")}',
      '对方：${theirs.map((s) => _itemLabel(other.items[s])).join(" / ")}',
      '↑↓ 选   A 决定   B 返回',
    ].join('\n');
    lastTradeMenuText = _itemMenuText;
    _sceneView?.show(text: _itemMenuText, virtualSize: camera.viewport.virtualSize);
  }

  void _applyTrade() {
    final f = field;
    final me = f?.unitById(state?.selectedUnitId ?? -1);
    if (me == null || _tradeTargets.isEmpty) return;
    final other = _tradeTargets[_tradeTargetIdx.clamp(0, _tradeTargets.length - 1)];
    final mine = _nonEmptySlots(me);
    final theirs = _nonEmptySlots(other);
    final sa = mine[_tradeMineSlot.clamp(0, mine.length - 1)];
    final sb = theirs[_tradeTheirSlot.clamp(0, theirs.length - 1)];
    final beforeMe = me.items.toList();
    final beforeOther = other.items.toList();
    // ★ 两格对调 + **双方各自压缩**（`trade.dart` 里有出处）
    final r = applyItemSwap(me.items, sa, other.items, sb);
    for (var i = 0; i < me.items.length; i++) {
      me.items[i] = r.a[i];
    }
    for (var i = 0; i < other.items.length; i++) {
      other.items[i] = r.b[i];
    }
    lastTrade = {
      'me': me.id,
      'other': other.id,
      'slotA': sa,
      'slotB': sb,
      'beforeMe': beforeMe,
      'beforeOther': beforeOther,
      'afterMe': me.items.toList(),
      'afterOther': other.items.toList(),
    };
    debugPrint('[TRADE] $lastTrade');
    _rebuildOverlay();
    _finishItemAction();
  }

  void _itemSubMenuInput(FlowInput i) {
    final m = itemSubMenu!;
    final entries = (m['entries'] as List).cast<Map<String, Object?>>();
    final stage = m['stage'];
    if (stage == 'tradeTarget' || stage == 'tradeMine' || stage == 'tradeTheirs') {
      final me = field?.unitById(state?.selectedUnitId ?? -1);
      if (me == null || _tradeTargets.isEmpty) return;
      final other = _tradeTargets[_tradeTargetIdx.clamp(0, _tradeTargets.length - 1)];
      int count() => stage == 'tradeTarget'
          ? _tradeTargets.length
          : (stage == 'tradeMine'
              ? _nonEmptySlots(me).length
              : _nonEmptySlots(other).length);
      void move(int d) {
        if (stage == 'tradeTarget') {
          _tradeTargetIdx = (_tradeTargetIdx + d + _tradeTargets.length) % _tradeTargets.length;
        } else if (stage == 'tradeMine') {
          _tradeMineSlot = (_tradeMineSlot + d + count()) % count();
        } else {
          _tradeTheirSlot = (_tradeTheirSlot + d + count()) % count();
        }
      }

      switch (i) {
        case FlowInput.up:
        case FlowInput.left:
          move(-1);
          _showTradeScreen();
        case FlowInput.down:
        case FlowInput.right:
          move(1);
          _showTradeScreen();
        case FlowInput.cancel:
          itemSubMenu = {...m, 'stage': 'menu', 'index': 0};
          _showItemSubMenu();
        case FlowInput.confirm:
          if (stage == 'tradeTarget') {
            itemSubMenu = {...m, 'stage': 'tradeMine'};
            _showTradeScreen();
          } else if (stage == 'tradeMine') {
            itemSubMenu = {...m, 'stage': 'tradeTheirs'};
            _showTradeScreen();
          } else {
            _applyTrade();
          }
        default:
          return;
      }
      return;
    }
    if (m['stage'] == 'confirm') {
      // Yes/No：默认 No（索引 0 = No）；确认 = 选中的那个
      if (i == FlowInput.cancel) {
        itemSubMenu = {'slot': m['slot'], 'index': 0,
          'entries': entries, 'stage': 'menu'};
        _showItemSubMenu();
        return;
      }
      if (i == FlowInput.confirm) {
        final yes = (m['yesNoIndex'] as int? ?? 0) == 1;
        if (yes) {
          _applyDiscard();
        } else {
          itemSubMenu = {'slot': m['slot'], 'index': 0,
            'entries': entries, 'stage': 'menu'};
          _showItemSubMenu();
        }
        return;
      }
      if (i == FlowInput.up || i == FlowInput.left) {
        itemSubMenu = {...m, 'yesNoIndex': 0};
        _showDiscardConfirm();
      } else if (i == FlowInput.down || i == FlowInput.right) {
        itemSubMenu = {...m, 'yesNoIndex': 1};
        _showDiscardConfirm();
      }
      return;
    }
    final idx = m['index'] as int;
    switch (i) {
      case FlowInput.up:
      case FlowInput.left:
        itemSubMenu = {...m, 'index': (idx - 1 + entries.length) % entries.length};
        _showItemSubMenu();
      case FlowInput.down:
      case FlowInput.right:
        itemSubMenu = {...m, 'index': (idx + 1) % entries.length};
        _showItemSubMenu();
      case FlowInput.cancel:
        // 子菜单取消 ⇒ 回道具菜单（阶段还是 itemMenu，不提交行动）
        itemSubMenu = null;
        _itemMenuText = '';
        _sceneView?.show(text: null, virtualSize: camera.viewport.virtualSize);
        if (state != null) _showItemMenu(state!);
      case FlowInput.confirm:
        final e = entries[idx];
        if (e['enabled'] != true) return;   // 禁用项：不做事（屏上有原因）
        switch (e['key']) {
          case 'use':
            _applyUse();
          case 'equip':
            _applyEquip();
          case 'discard':
            itemSubMenu = {...m, 'stage': 'confirm', 'yesNoIndex': 0};
            discardPromptDefault = 0;   // 打开时的默认项（照源码 = No）
            _showDiscardConfirm();
          case 'trade':
            final me = field?.unitById(state?.selectedUnitId ?? -1);
            if (me == null) return;
            _tradeTargets = tradeTargets(me);
            if (_tradeTargets.isEmpty) return;
            _tradeTargetIdx = 0;
            _tradeMineSlot = 0;
            _tradeTheirSlot = 0;
            itemSubMenu = {...m, 'stage': 'tradeTarget'};
            _showTradeScreen();
          default:
            return;
        }
      default:
        return;
    }
  }

  /// 取出子菜单当前指向的槽
  int _subMenuSlot() => (itemSubMenu?['slot'] as int?) ?? 0;

  /// 「使う」：回复量按 `GetUnitItemHealAmount`，耐久按打包表示递减
  void _applyUse() {
    final f = field;
    final u = f?.unitById(state?.selectedUnitId ?? -1);
    if (u == null) return;
    final slot = _subMenuSlot();
    final word = u.items[slot];
    final num = ItemTable.itemIndex(word);
    final res = useHealingItem(
      hp: u.hp,
      maxHp: u.maxHp,
      item: word,
      itemNumber: num,
      isStaff: (_itemStats[num]?.attributes ?? 0) & kItemStaffAttribute != 0,
      nameOf: _itemNameByNumber,
    );
    u.hp = res.hp;
    u.items[slot] = res.item; // 耐久 -1；归零则清空（`MakeNewItem` 表示法）
    lastItemUse = {
      'unit': u.id,
      'slot': slot,
      'item': _itemNameByNumber[num],
      'healed': res.healed,
      'hp': u.hp,
      'usesLeft': itemUses(res.item),
      'consumed': res.consumed,
    };
    debugPrint('[ITEM] $lastItemUse');
    _rebuildOverlay();
    _finishItemAction();
  }

  /// 「装備」：`EquipUnitItemSlot`（`src/exact_08016968.c:14-23`）——**轮转**
  void _applyEquip() {
    final f = field;
    final u = f?.unitById(state?.selectedUnitId ?? -1);
    if (u == null) return;
    final slot = _subMenuSlot();
    final num = ItemTable.itemIndex(u.items[slot]);
    final before = List<int>.from(u.items);
    final rotated = equipUnitItemSlot(u.items, slot);
    for (var i = 0; i < u.items.length; i++) {
      u.items[i] = rotated[i];
    }
    lastEquip = {
      'unit': u.id,
      'slot': slot,
      'item': _itemNameByNumber[num],
      'before0': before[0],
      'after0': u.items[0],
    };
    debugPrint('[EQUIP] $lastEquip');
    _syncAttackRange(u); // 射程跟着新武器变
    _rebuildOverlay();
    _finishItemAction();
  }

  /// 「捨てる」：`UnitRemoveItem`（`src/UnitRemoveItem.c:25-28`）——清 0 + 压缩
  void _applyDiscard() {
    final f = field;
    final u = f?.unitById(state?.selectedUnitId ?? -1);
    if (u == null) return;
    final slot = _subMenuSlot();
    final num = ItemTable.itemIndex(u.items[slot]);
    final before = List<int>.from(u.items);
    final after = unitRemoveItem(u.items, slot);
    for (var i = 0; i < u.items.length; i++) {
      u.items[i] = after[i];
    }
    lastDiscard = {
      'unit': u.id,
      'slot': slot,
      'item': _itemNameByNumber[num],
      'before': before,
      'after': u.items.toList(),
    };
    debugPrint('[DISCARD] $lastDiscard');
    _rebuildOverlay();
    _finishItemAction();
  }

  /// 子菜单决定之后：提交这次行动（与"待机"同一条尾巴）
  void _finishItemAction() {
    itemSubMenu = null;
    _itemMenuText = '';
    _sceneView?.show(text: null, virtualSize: camera.viewport.virtualSize);
    final fl = flow;
    final s = state;
    if (fl == null || s == null) return;
    final r = fl.commitItemAction(s);
    final f = field;
    if (r.committedMove && s.selectedUnitId != null && f != null) {
      final u = f.unitById(s.selectedUnitId);
      if (u != null && s.pendingX != null && s.pendingY != null) {
        f.moveUnit(u, s.pendingX!, s.pendingY!);
        f.finishUnit(u);
      }
    }
    state = r.state;
    _rebuildOverlay();
    _updateHud();
    unawaited(_afterUnitAction());
  }

  /// 道具菜单的文本（名字来自道具表的 `nameTextId`）
  void _showItemMenu(FlowState s) {
    final f = field;
    final u = f?.unitById(s.selectedUnitId);
    if (u == null) return;
    final lines = <String>['道具'];
    for (var i = 0; i < _usableSlots.length; i++) {
      final slot = _usableSlots[i];
      final num = ItemTable.itemIndex(u.items[slot]);
      final nameId = _itemNameTextId[num] ?? 0;
      final name = _textOr(gameTexts?.byId(nameId)?.plain, 'item#$num');
      final w = u.items[slot];
      final uses = itemUses(w);
      final tag = isWeaponItem(w) ? '装備' : (canUseItem(u, w) ? '使う' : '—');
      lines.add('${i == s.itemIndex ? '▶ ' : '  '}$name  '
          '${uses == 0 ? '∞' : uses}  $tag');
    }
    lines.add('A 使用   B 返回');
    lastItemMenuText = lines.join('\n');
    _itemMenuText = lastItemMenuText;
    _sceneView?.show(text: _itemMenuText, virtualSize: camera.viewport.virtualSize);
  }

  /// 「設定」屏的状态（开着时非 null）
  GameOptionsState? gameOptions;
  /// 编号 → 道具名（`ITEM_*`），给回复量的 switch 用
  final Map<int, String> _itemNameByNumber = {};

  /// `IA_UNSELLABLE = (1 << 4)`（`include/bmitem.h:59`）——
  /// 带这一位的道具不能"捨てる"（`ItemSubMenu_IsDiscardAvailable`）
  static const int kItemUnsellableAttribute = 1 << 4;

  /// 编号 → 名字的文本 id（`nameTextId`）—— 道具菜单显示真名字用
  final Map<int, int> _itemNameTextId = {};

  /// 这个单位身上**可用**的道具槽（绝对槽位下标）—— 选单位时算一次
  List<int> _usableSlots = const [];

  /// 最近一次"用道具"的记录（判据用）
  Map<String, Object?>? lastItemUse;

  /// 最近一次"装备"的记录（判据用）
  Map<String, Object?>? lastEquip;

  /// 战斗预测的当前值（选目标阶段算）
  BattleForecast? forecastForTarget;

  /// 玩家（我方）**主动出手**的次数 —— 欠账 40 那条链原来完全没有覆盖，
  /// 因为脚本压根没走到过"选中 → 移动 → 攻撃"。
  int playerAttackCount = 0;

  /// 每次"提交一次移动"都记一笔（谁、从哪到哪）—— 固定脚本出问题时，
  /// 这张表能立刻回答"单位到底动没动"。
  final List<Map<String, Object?>> actionLog = [];

  /// 最近一次算出来的预测（**留档**）—— 动作做完 `forecastForTarget` 会被清掉，
  /// 判据要拿它和"实际打出的伤害"对比（欠账 21 的同一个坑）。
  Map<String, Object?>? lastForecast;
  BattleForecastComponent? _forecastComp;

  /// 职业编号 → 职业名（判 `CLASS_PHANTOM` 用；`classes.json`）
  final Map<int, String> _classNameByNumber = {};

  /// 最近一次交换的记录（判据用）
  Map<String, Object?>? lastTrade;

  /// 地形 id → 枚举名（`terrains.json` 的 `enum`）
  final Map<int, String> _terrainEnumById = {};

  /// 地形窗口用的两张**通用**表（`TerrainTable_Def_Common` / `Avo_Common`）
  /// 与"不可通行"判据（`TerrainTable_MovCost_BerserkerNormal`）
  List<int> _terrainDefCommon = const [];
  List<int> _terrainAvoCommon = const [];
  List<int> _terrainMovCostBerserker = const [];

  /// 地形窗口（`gProcScr_TerrainDisplay`）
  TerrainWindowComponent? _terrainComp;
  Map<String, Object?>? lastTerrainWindow;

  /// 单位小窗口（minimug）：光标下那个单位
  MinimugComponent? _minimugComp;
  int? _minimugUnitId;
  String _minimugText = '';

  /// 目标窗口（`GoalDisplay`）—— 章节的 `goalWindowTextId` → 文本 id
  final Map<int, int> _chapterGoalTextId = {};

  /// 当前目标窗口状态（null = 还没建）
  GoalWindowState? goalWindow;
  GoalWindowComponent? _goalWindowComp;
  String _goalText = '';

  /// 最近一次"捨てる"的记录（判据用）
  Map<String, Object?>? lastDiscard;

  /// 道具子菜单（`ItemSubMenu`：装備/使う/捨てる/交換）的状态
  ///
  /// 出处：`src/ItemSelectMenu_Effect.c:66`（`StartMenuAt(&gItemSubMenuDef, …)`）
  /// —— ⚠️ `gItemSubMenuDef` **只有 extern、定义没 carve** ⇒ 条目的**顺序与措辞
  /// 未查证**；四个动作本身有源码（`src/ItemSubMenu_*.c`）：
  ///   * 使う   `ItemSubMenu_UseItem`
  ///   * 装備   `ItemSubMenu_EquipItem` / `ItemSubMenu_IsEquipAvailable`
  ///   * 捨てる `ItemSubMenu_DiscardItem` / `ItemSubMenu_IsDiscardAvailable`
  ///   * 交換   `ItemSubMenu_IsTradeAvailable`（**我们未实现交换本身**）
  Map<String, Object?>? itemSubMenu;

  /// 子菜单里被禁用的项（判据用）
  List<String> _subMenuDisabled = const [];

  /// 道具菜单的文本（判据用）
  String _itemMenuText = '';

  /// 关掉之后仍留一份 —— 否则转储里看不到"菜单显示过什么"
  ///（与欠账 21 同一个坑：只有最后一次的值，中间步骤断言不了）
  String lastItemMenuText = '';

  /// 子菜单 / Yes-No 的留档（三种文本会互相覆盖；我第一版只留了一份，
  /// 加了子菜单之后 `lastItemMenuText` 变成空串 —— 断言当场红）
  String lastSubMenuText = '';

  /// 交易界面的留档（关掉之后判据仍看得到）
  String lastTradeMenuText = '';
  String lastConfirmText = '';

  /// 舍弃确认框**打开时**的默认项（0 = いいえ / No）。
  /// 出处：`src/ItemSubMenu_DiscardItem.c` 末尾 `proc->itemCurrent = 1;`
  ///（Yes/No 菜单的第 2 项 = いいえ ⇒ **默认 No**）。
  ///
  /// ⚠️ 我第一版拿 `lastConfirmText` 去断言默认项 —— 那是**最后一次**的文本
  ///（脚本后来又按下去了），永远看不到默认值。同一个坑第 3 次踩。
  int? discardPromptDefault;

  List<Map<String, dynamic>> _gameOptionRows = const [];

  /// 屏关掉之后仍要能断言"改过什么"（转储时 gameOptions 已是 null）——
  /// 上一次設定屏的结果留在这里。
  Map<String, Object?>? _gameOptionsLast;

  String _gameOptionsText = '';

  /// 选项→配置字段的映射**非空**时为真（不是"屏开着"）
  bool gameOptionRowsHasMapping = false;

  /// 开「設定」屏。选项表与显示顺序来自提取产物。
  void _openGameOptions() {
    final raw = _gameOptionRows;
    if (raw.isEmpty) {
      _playNote = '設定：选项表取不到（game_options.json）';
      debugPrint('[OPTIONS] 选项表为空');
      return;
    }
    _gameOptionRows = raw;
    final order = (raw.first['_uiOrder'] as List<Object?>).cast<int>();
    final table =
        (raw.first['_options'] as List<Object?>).cast<Map<String, dynamic>>();
    final toField = raw.first['_toField'] as Map<String, dynamic>? ?? {};
    gameOptionRowsHasMapping = toField.isNotEmpty;
    // 配置值：`disableAutoEndTurns` 与 `playConfig` **共享**（改它真的生效）；
    // 其余字段先放在这个容器里（名字来自源码 `src/uiconfig.c`，默认值未核对）
    final cfg = GameConfigValues(initial: {
      for (final e in toField.entries)
        if (e.value is Map && (e.value as Map)['field'] is String)
          (e.value as Map)['field'] as String:
              playConfig.getField((e.value as Map)['field'] as String),
    });
    final opts = <GameOptionState>[];
    for (final i in order) {
      if (i < 0 || i >= table.length) continue;
      final o = table[i];
      final sels = (o['selectors'] as List).length;
      final m = toField['$i'];
      final field = m is Map ? m['field'] as String? : null;
      final st0 = GameOptionState(
        msgId: o['msgId'] as int,
        selectorCount: sels,
        field: field,
      );
      // 有字段的从配置读初值；没字段的（例如动画那一项）留 null ⇒ 屏上「—」，不编
      if (field != null) st0.value = cfg.get(field).clamp(0, sels - 1);
      opts.add(st0);
    }
    final st = GameOptionsState(options: opts, config: cfg);
    gameOptions = st;
    _showGameOptions(st);
  }

  /// `disableAutoEndTurns` 那一项的 msgId（从产物里认出来，不硬编码文本 id）
  int? gameOptionMsgIdAutoEnd;

  void _showGameOptions(GameOptionsState st) {
    final lines = <String>['設定'];
    for (var i = 0; i < st.options.length; i++) {
      final o = st.options[i];
      final name = _textOr(gameTexts?.byId(o.msgId)?.plain, 'msg#${o.msgId}');
      final raw = _gameOptionRows.first['_options'] as List;
      final sels = (raw.firstWhere(
                  (e) => (e as Map<String, dynamic>)['msgId'] == o.msgId,
                  orElse: () => <String, dynamic>{'selectors': <Object?>[]})
              as Map<String, dynamic>)['selectors'] as List<Object?>;
      String val;
      if (o.value == null) {
        val = '—';
      } else if (o.value! < sels.length) {
        val = _textOr(
            gameTexts?.byId((sels[o.value!] as Map)['optionTextId'] as int)?.plain,
            'text#${(sels[o.value!] as Map)['optionTextId']}');
      } else {
        val = '?';
      }
      lines.add('${i == st.index ? '▶ ' : '  '}$name  $val');
    }
    lines.add('← → 改值   B 返回');
    _gameOptionsText = lines.join('\n');
    _sceneView?.show(text: _gameOptionsText, virtualSize: camera.viewport.virtualSize);
    _playNote = '設定：${st.current == null ? "—" : _textOr(gameTexts?.byId(st.current!.msgId)?.plain, "msg#${st.current!.msgId}")}';
  }

  String _textOr(String? s, String fallback) =>
      (s == null || s.isEmpty) ? fallback : s;

  void _closeGameOptions() {
    final st = gameOptions;
    if (st != null) {
      // ★ 写回配置。`disableAutoEndTurns` 是我们的流程**真的在读**的那一个
      //（`PlayerPhase_HandleAutoEnd`，`src/playerphase_0801D808.c:52-58`）
      // ⇒ 改它**真的生效**；其余字段目前只存在屏上（转储里成对记账）。
      // ★ 写回：**所有**解出映射的字段都按源码字段名写进 `playConfig`
      //（第 27 轮只做了 auto-end 一个；现在 `PlayConfig` 有真字段了）
      for (final o in st.options) {
        final f = o.field;
        if (f != null && o.value != null) {
          if (!playConfig.setField(f, o.value!)) {
            debugPrint('[OPTIONS] 字段名认不出：$f（没写）');
          }
        }
      }
      _gameOptionsLast = {
        'index': st.index,
        'count': st.count,
        'changes': st.changes,
        'values': {
          for (final o in st.options)
            if (o.field != null) o.field!: o.value,
        },
      };
    }
    gameOptions = null;
    _sceneView?.show(text: null, virtualSize: camera.viewport.virtualSize);
    _playNote = kPlayNote;
    _updateHud();
  }

  /// **刚被操作过**的那个单位，按 `GetUnitEquippedWeapon` 的规则算出的武器字（判据用）。
  ///
  /// ⚠️ 我第一版用 `state.selectedUnitId` —— 动作做完单位就取消选中了，
  /// 于是转储里永远是 `0`：**一个在动作之后必然撒谎的诊断字段**。
  /// 现在改成回顾"最近一次装备/使用"的那个单位。
  int _equippedWeaponWord() {
    final f = field;
    if (f == null) return 0;
    final id = lastEquip?['unit'] ?? lastItemUse?['unit'];
    final u = id == null ? null : f.unitById(id as int);
    if (u == null) return 0;
    final i = equippedWeaponSlot(u.items, isUsableWeapon: isWeaponItem);
    return i < 0 ? 0 : u.items[i];
  }

  /// 「部隊」列表的状态（开着时非 null）
  UnitListState? unitList;
  String _unitListText = '';

  /// 打开「部隊」列表
  ///
  /// ⚠️ 列表顺序 = 我们场上的单位次序；原作是 `gSortedUnits`（可排序，
  /// `src/unitlistscreen_08093AD0.c:51-80`）—— **排序未实现**（欠账）。
  void _openUnitList() {
    final mine = _myUnits();
    final st = UnitListState(unitIds: [for (final u in mine) u.id]);
    unitList = st;
    _showUnitList(st, mine);
  }

  void _showUnitList(UnitListState st, List<MapUnit> mine) {
    final lines = <String>['部隊  ${mine.length} 人'];
    for (var i = 0; i < mine.length; i++) {
      final u = mine[i];
      final cur = i == st.index ? '▶ ' : '  ';
      lines.add('$cur${u.name.isEmpty ? "单位${u.id}" : u.name}  '
          'HP ${u.hp}/${u.maxHp}');
    }
    lines.add('A 看状況   B 返回');
    _unitListText = lines.join('\n');
    _sceneView?.show(text: _unitListText, virtualSize: camera.viewport.virtualSize);
    _playNote = '部隊：${mine.isEmpty ? "没有单位" : "选中 ${mine[st.index.clamp(0, mine.length - 1)].name}"}';
  }

  void _closeUnitList({int? chosen, List<MapUnit>? mine}) {
    unitList = null;
    _sceneView?.show(text: null, virtualSize: camera.viewport.virtualSize);
    if (chosen != null && mine != null) {
      final idx = mine.indexWhere((u) => u.id == chosen);
      if (idx >= 0) {
        // ★ 原作的串法：A 之后开的是**选中那个单位**的状況屏
        final st = ChapterStatusState(unitCount: mine.length, unitIndex: idx);
        chapterStatus = st;
        _showStatusText(st, mine);
        return;
      }
    }
    _playNote = kPlayNote;
    _updateHud();
  }

  /// 「状況」屏的状态（开着时非 null）
  ChapterStatusState? chapterStatus;

  /// 打开「状況」屏（`StartChapterStatusScreen`）
  void _openChapterStatus() {
    final f = field;
    if (f == null) {
      _playNote = '没有战场，开不了状況';
      return;
    }
    final mine = _myUnits();
    final st = ChapterStatusState(unitCount: mine.length);
    chapterStatus = st;
    _showStatusText(st, mine);
  }

  List<MapUnit> _myUnits() => field?.units
          .where((u) => u.isAlive && u.factionBit == Faction.blue)
          .toList() ??
      const <MapUnit>[];

  String _statusText = '';

  void _showStatusText(ChapterStatusState st, List<MapUnit> mine) {
    final f = field!;
    final i = st.shownIndex;
    final u = i >= 0 && i < mine.length ? mine[i] : null;
    _statusText = <String>[
      '状況  第 $sceneChapter 章  回合 ${f.turn}',
      if (u == null)
        '（没有可显示的我方单位）'
      else
        '${u.name.isEmpty ? "单位${u.id}" : u.name}  '
            'HP ${u.hp}/${u.maxHp}  Lv ${u.level}  移动 ${u.movement}',
      '${i + 1} / ${mine.length}     B 关闭   ← → 换人',
    ].join('\n');
    _sceneView?.show(text: _statusText, virtualSize: camera.viewport.virtualSize);
    _playNote = '状況：${u?.name ?? "—"}（$statusNote）';
  }

  /// 状況屏的说明（判据用）
  String get statusNote =>
      chapterStatus == null ? '关着' : '开着 index=${chapterStatus!.unitIndex}';

  /// 关闭「状況」屏（B / A）
  void _closeChapterStatus({bool focus = false}) {
    final st = chapterStatus;
    if (st == null) return;
    st.closed = true;
    if (focus) st.focusUnitOnExit = true;
    chapterStatus = null;
    _sceneView?.show(text: null, virtualSize: camera.viewport.virtualSize);
    _playNote = kPlayNote;
    _updateHud();
  }

  /// 建一个标题流程，并把「继续」那一项按**是否存在中断存档**开关。
  ///
  /// 出处：`TitleFlow.mainMenuOptions` 里 `if (resumable) out.add(resume)`。
  /// ⚠️ 这一句必须在**每次**建标题流程时都设（`onLoad` 与中断回标题都要），
  /// 否则中断回标题之后菜单里**看不到「继续」**（我第一次只设了 onLoad）。
  TitleFlow _newTitleFlow() {
    final f = TitleFlow(texts: gameTexts!);
    f.resumable = _suspendFile().existsSync();
    return f;
  }

  /// 中断存档文件（路径与写盘处一致）
  File _suspendFile() => File(
      '${Directory.systemTemp.path}/fe8r-saves/suspend.json');

  /// 「继续」：读回中断存档并**直接进地图**（不演本章开场）。
  ///
  /// 出处：`src/bmsave.c:111`（`ReadSuspendSave`）——
  /// 它把 `gPlaySt` / `gActionData` / 三阵营单位 / 旗全部读回来；
  /// 读回来之后游戏**直接回到战场**，不重演章节开场。
  ///
  /// ⚠️ 我们这边是"读 JSON → 重建 `BattleField`/`FlowState` → 装本章地图"。
  /// 地图本身还是要按章号装（存档里没有地图瓦片）。
  Future<void> _resumeFromSuspend() async {
    final file = _suspendFile();
    if (!file.existsSync()) {
      _playNote = '没有中断存档，回标题';
      debugPrint('[SAVE] 继续：没有 ${file.path}');
      titleFlow = TitleFlow(texts: gameTexts!)..reset();
      return;
    }
    try {
      final st = SaveState.decode(file.readAsStringSync());
      sceneChapter = st.chapter;
      await _loadChapterMap(st.chapter);
      field = st.field;
      state = st.flow;
      eventFlags
        ..clear()
        ..addAll(st.eventFlags);
      playConfig.disableAutoEndTurns = st.disableAutoEndTurns;
      // 教学模式/难度位也要恢复：地图菜单「中断」的可用性看这一位
      //（`titleFlow` 这时已经拆掉了，所以要把它存到字段上，见 `_playFlagsFromSave`）
      _playFlagsFromSave = NewGamePlayFlags(
        st.isHard
            ? NewGameDifficulty.hard
            : (st.isTutorial
                ? NewGameDifficulty.normal
                : NewGameDifficulty.easy),
      );
      if (st.tutorial != null) {
        tutorial
          ..counter = st.tutorial!.counter
          ..execType = st.tutorial!.execType;
      }
      worldMap = st.worldMap;
      _mapReady = true;
      _touchGoalWindow();   // 地图开始 ⇒ 目标窗口（原作 `StartPlayerPhaseSideWindows`）
      status.value = '（继续）$resumeNote';
      _playNote = '继续：$resumeNote';
      _rebuildOverlay();
      _updateHud();
      debugPrint('[SAVE] 继续：$resumeNote');
    } catch (e, st) {
      _playNote = '中断存档读不了：$e';
      debugPrint('[SAVE] 读中断存档失败：$e\n$st');
    }
  }

  /// 读档结果的说明（判据用）
  String get resumeNote => field == null
      ? '没有战场'
      : '第 $sceneChapter 章 回合 ${field!.turn} 单位 ${field!.units.length}';

  /// `MNTS`：回标题（`GAME_ACTION_EVENT_RETURN`，`src/Event2A_MoveToChapter.c:23-27`）。
  ///
  /// 章节就此结束：清掉战场与剧情状态、把标题流程复位。
  /// 中断提示脚本的末尾就是这一条。
  void _returnToTitle() {
    _sceneRunning = false;
    _pendingWorldMapTarget = null;
    worldMap = null;
    _clearWorldMapView();
    mapMenu = null;
    state = null;
    field = null;
    // 设置回到默认（`PlayConfig` 对象是 final，改它的字段）
    playConfig.disableAutoEndTurns = false;
    // ⚠️ 开场流程跑完之后 `titleFlow` 会被丢掉（它是开场用的状态机），
    // 所以"回标题"必须**重新建一个** —— 只 `reset()` 的话
    // `inTitleFlow` 仍是 false，游戏留在战场上（实测：`waitingFor` 还是
    // `input:freeCursor`、`titleFlow=null`）。原作回的是同一条标题链路，
    // 重建它是移植层的选择，不是原作行为。
    final texts = gameTexts;
    if (texts != null) {
      titleFlow = _newTitleFlow();
      titleFlow!.reset();
    } else {
      _suspendNote = '$_suspendNote；没有文本表，回不了标题';
    }
    // ★ 画面也要收干净：只清 `state`/`field` 不够 —— 战场视图里那 5 个
    // 单位组件还留在 `world` 里，标题下面会露出上一局的棋子。
    // 判据抓到的就是这条（`unitComponents=5` 而 `alive=null`）。
    // 用**空战场**同步一遍，让 `BattleView` 按它自己的规则把组件删掉。
    final v = _battleView;
    if (v != null) {
      v.sync(
        FlowState(phase: FlowPhase.freeCursor, cursorX: 0, cursorY: 0),
        BattleField(width: 1, height: 1, units: const []),
        // `sync` 还要一个状态机；范围/菜单/光标在这几种输入下都不会用到
        flow ?? FlowMachine(map: _emptyGrid, costsOf: (u) => _uniformCosts),
      );
    }
    status.value = '（中断）回到标题';
    _rebuildOverlay();
    _updateHud();
    debugPrint('[SAVE] MNTS → 回标题');
  }

  /// 写中断存档（`StartSuspendPrompt` → `CallSuspendPromptEvent` → `WriteSuspendSave`）。
  ///
  /// ⚠️ **格式是 JSON**，不是 GBA 的 SRAM 布局 —— 见 `lib/core/save/save_state.dart`
  /// 的文件头（原格式为 8KB SRAM 设计，我们只复刻语义）。
  ///
  /// ⚠️ 还没做的：原作中断之后会**回标题**（提示事件里那条流程）。
  /// 这里只写盘 + 在屏幕上说明路径，回标题留到下一步（不假装做了）。
  void _writeSuspendSave() {
    final f = field;
    final fl = state;          // ⚠️ `flow` 是状态机（FlowMachine），`state` 才是快照
    if (f == null || fl == null) {
      _suspendNote = '没有战场状态，没写';
      return;
    }
    final st = SaveState(
      chapter: sceneChapter,
      field: f,
      flow: fl,
      eventFlags: eventFlags,
      rngConsumed: tracker.consumed,
      disableAutoEndTurns: playConfig.disableAutoEndTurns,
      // ⚠️ 写盘时也用它：写了 isTutorial/isHard，读回来才不会把教学模式弄丢
      isTutorial: _currentPlayFlags.playFlagTutorial,
      isHard: _currentPlayFlags.difficulty == NewGameDifficulty.hard,
      worldMap: worldMap,
      tutorial: tutorial,
    );
    try {
      final dir = Directory('${Directory.systemTemp.path}/fe8r-saves')
        ..createSync(recursive: true);
      final file = File('${dir.path}/suspend.json');
      file.writeAsStringSync(st.encode());
      _suspendPath = file.path;
      _suspendBytes = file.lengthSync();
      _suspendNote = '已写中断存档（$_suspendBytes B）';
      _playNote = '中断：$_suspendNote'; // 屏幕上也要说（否则玩家以为没反应）
    } catch (e) {
      _suspendNote = '写中断存档失败：$e';
      debugPrint('[SAVE] $_suspendNote');
    }
  }

  /// 一次命中的即时反馈：闪白 + 飘字（MISS / -N / CRIT -N）。
  ///
  /// 出处（字段）：`AttackResult.hit / crit / damage`
  ///（`lib/core/flow/combat.dart:111-140`）。
  void _spawnHitFx(MapUnit target, AttackResult st) {
    final tile = _battleView?.tileSize ?? 16.0;
    final at = Vector2(target.x * tile, target.y * tile);

    if (st.hit) {
      final f = HitFlashComponent(at: at, tileSize: tile, crit: st.crit);
      _flashes.add(f);
      _battleView?.layer.add(f);
      if (st.damage > 0) _damageDealtTotal += st.damage;
      _spawnDamageText(target, st.crit ? 'CRIT -${st.damage}' : '-${st.damage}');
    } else {
      _spawnDamageText(target, 'MISS');
    }
    _hitFxLog.add({
      'x': target.x,
      'y': target.y,
      'hit': st.hit,
      'crit': st.crit,
      'damage': st.damage,
      'unit': target.id,
    });
    if (_hitFxLog.length > 16) _hitFxLog.removeAt(0);
  }

  /// 飘字（文本由调用方给，便于 `MISS` / `CRIT -N`）
  void _spawnDamageText(MapUnit u, String text) {
    final tile = _battleView?.tileSize ?? 16.0;
    final comp = DamagePopupComponent(
      text: text,
      tileSize: tile,
      at: Vector2(u.x * tile, u.y * tile),
      isHeal: text.startsWith('+'),
    );
    _popups.add(comp);
    _battleView?.layer.add(comp);
    _popupLog.add({'x': u.x, 'y': u.y, 'text': text, 'unit': u.id});
    if (_popupLog.length > 16) _popupLog.removeAt(0);
  }

  /// 每帧推进飘字，到期回收（组件有自己的生命周期，别靠整树重建）
  void _tickPopups() {
    for (final p in _popups.toList()) {
      if (!p.tick()) {
        _popups.remove(p);
        p.removeFromParent();
      }
    }
    for (final f in _flashes.toList()) {
      if (!f.tick()) {
        _flashes.remove(f);
        f.removeFromParent();
      }
    }
  }

  /// 目标窗口要显示吗（两个条件）
  bool get goalWindowWanted =>
      playConfig.disableGoalDisplay == 0 &&
      !eventFlags.contains(kEvFlagObjWindowDisable);

  /// 阵营切换：按条件滑入/收起
  void _touchGoalWindow() {
    final want = goalWindowWanted;
    final st = goalWindow ?? GoalWindowState(wantVisible: want);
    st.wantVisible = want;
    goalWindow = st;
    if (!want) {
      _hideGoalWindow();
      return;
    }
    // 文本：章节的 `goalWindowTextId` → 文本表（取不到就**明确说**，不编）
    final id = _chapterGoalTextId[sceneChapter];
    final txt = id == null ? null : gameTexts?.byId(id)?.plain;
    _goalText = (txt == null || txt.isEmpty)
        ? (id == null
            ? '（本章没有 goalWindowTextId）'
            : '（文本 #$id 取不到）')
        : txt;
    st.onSideChange();
    _showGoalWindowComp();
  }

  void _showGoalWindowComp() {
    // ⚠️ 无头跑（单元测试）时游戏没挂载，`viewport.add` 会炸 ——
    // 状态机照跑（判据看状态），只是不建组件。
    if (!isMounted) return;
    final v = camera.viewport;
    if (_goalWindowComp != null) {
      _goalWindowComp!.removeFromParent();
      _goalWindowComp = null;
    }
    final c = GoalWindowComponent(
      text: _goalText,
      tileSize: 16,
      screen: v.virtualSize,
    );
    _goalWindowComp = c;
    v.add(c);
  }

  void _hideGoalWindow() {
    if (_goalWindowComp != null) {
      _goalWindowComp!.removeFromParent();
      _goalWindowComp = null;
    }
  }

  /// 每帧同步单位小窗口。
  ///
  /// 出处：`MMB_Loop_Display`（`src/player_interface_0808EFC4.c:30-70`）——
  /// 显示的是**光标下**那个单位（`GetUnit(gBmMapUnit[cursor.y][cursor.x])`），
  /// 没有单位就不显示；开不开由 `unitDisplayType == 0` 决定
  ///（`src/player_interface_0808F2C0.c:68-78`）。
  void _tickMinimug() {
    final f = field;
    final s = state;
    if (f == null || s == null) {
      _removeMinimug();
      return;
    }
    final under = f.unitAt(s.cursorX, s.cursorY);
    final show = shouldShowMinimug(
      unitDisplayType: playConfig.unitDisplayType,
      hasUnitUnderCursor: under != null,
    );
    if (!show || under == null) {
      _removeMinimug();
      return;
    }
    // 内容：名字 / HP / 道具（`DrawUnitMapUi` 画的是这些；头像未移植）
    final u = under;
    final name = u.name.isEmpty ? '单位${u.id}' : u.name;
    final items = <String>[];
    for (final w in u.items) {
      if (w == 0) continue;
      final num = ItemTable.itemIndex(w);
      // ⚠️ 用**文本表**的名字（`nameTextId`），不是 `ITEM_*` 枚举名 ——
      // 我第一版直接用了枚举名，界面上就成了 `ITEM_SWORD_STEEL`。
      final nameId = _itemNameTextId[num] ?? 0;
      final nm = _textOr(gameTexts?.byId(nameId)?.plain, 'item#$num');
      final uses = itemUses(w);
      items.add('$nm${uses == 0 ? '' : '($uses)'}');
    }
    final lines = <String>[
      '$name  HP ${u.hp}/${u.maxHp}',
      if (items.isNotEmpty) items.join(' '),
    ];
    _minimugUnitId = u.id;
    _minimugText = lines.join('\n');
    if (_minimugComp != null &&
        _minimugComp!.lines.length == lines.length &&
        _sameLines(_minimugComp!.lines, lines)) {
      return; // 没变就不重建（组件有自己的生命周期）
    }
    _removeMinimug();
    if (!isMounted) return;
    final c = MinimugComponent(
        lines: lines, tileSize: 16, screen: camera.viewport.virtualSize);
    _minimugComp = c;
    camera.viewport.add(c);
  }

  bool _sameLines(List<String> a, List<String> b) {
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  /// 每帧同步战斗预测。
  ///
  /// 触发点：**选目标阶段**（`FlowPhase.selectTarget`）—— 原作在选目标时把
  /// `InitBattleForecastBattleStats`（`src/InitBattleForecastBattleStats.c`）
  /// 算出来的面板滑出来。
  ///
  /// ★ 数值走的是 `CombatEngine.forecast`，而它和实战 `attack` **共用**
  /// `_computeUnitStats` —— 所以"预测与实战不一致"这类 bug 在结构上就不可能出现
  ///（判据仍然会去对一遍，见 `battle` 场景）。
  void _tickForecast() {
    final s = state;
    final f = field;
    if (s == null || f == null || s.phase != FlowPhase.selectTarget) {
      forecastForTarget = null;
      _removeForecast();
      return;
    }
    final unit = f.unitById(s.selectedUnitId ?? -1);
    if (unit == null) {
      _removeForecast();
      return;
    }
    final at = s.pendingX ?? unit.x;
    final atY = s.pendingY ?? unit.y;
    final fl = flow;
    if (fl == null) return;
    final targets = fl.validTargets(f, unit, at, atY); // FlowMachine 的方法 → List<MapUnit>
    if (targets.isEmpty) {
      _removeForecast();
      return;
    }
    final target = targets[s.targetIndex.clamp(0, targets.length - 1)];
    final c = combat;
    if (c == null) return;
    final fc = c.forecast(
      actorUnit: unit,
      targetUnit: target,
      actorProfile: _profileFor(unit),
      targetProfile: _profileFor(target),
      actorTerrainDefense: _terrainBonuses(
              _terrainAt(unit.x, unit.y), _profileFor(unit).classId)
          .defense,
      actorTerrainAvoid: _terrainBonuses(
              _terrainAt(unit.x, unit.y), _profileFor(unit).classId)
          .avoid,
      targetTerrainDefense: _terrainBonuses(
              _terrainAt(target.x, target.y), _profileFor(target).classId)
          .defense,
      targetTerrainAvoid: _terrainBonuses(
              _terrainAt(target.x, target.y), _profileFor(target).classId)
          .avoid,
    );
    forecastForTarget = fc;
    lastForecast = {
      ...fc.toJson(),
      'actorId': unit.id,
      'targetId': target.id,
    };
    if (_forecastComp != null) return;
    if (!isMounted) return;
    final comp = BattleForecastComponent(
      forecast: fc,
      tileSize: 16,
      screen: camera.viewport.virtualSize,
    );
    _forecastComp = comp;
    camera.viewport.add(comp);
  }

  void _removeForecast() {
    if (_forecastComp != null) {
      _forecastComp!.removeFromParent();
      _forecastComp = null;
    }
  }

  /// 每帧同步地形窗口。
  ///
  /// 出处：`src/player_interface_0808F2C0.c:49-52`（`disableTerrainDisplay == 0`
  /// 才 `Proc_Start(gProcScr_TerrainDisplay)`）+ `DrawTerrainMapUi`
  ///（`src/player_interface_0808E8CC.c:182-205`：看**光标下**那块地；
  /// def/avoid 只在 `TerrainTable_MovCost_BerserkerNormal > 0` 时显示）。
  void _tickTerrainWindow() {
    final grid = map;
    final s = state;
    if (grid == null || s == null ||
        !terrainWindowVisible(disableTerrainDisplay: playConfig.disableTerrainDisplay)) {
      _removeTerrainWindow();
      return;
    }
    // ⚠️ `terrainAt` 返回 `TerrainType` 包装，不是 int —— 要 `.id`
    //（早期轮次踩过同一个包装）
    final tid = grid.terrainAt(s.cursorX, s.cursorY).id;
    if (tid < 0) {
      _removeTerrainWindow();
      return;
    }
    final cost = tid < _terrainMovCostBerserker.length
        ? _terrainMovCostBerserker[tid]
        : -1;
    final lines = <String>[
      '地形 ${_terrainEnumName(tid)}',
      if (terrainShowsDefAvo(berserkerNormalCost: cost))
        '防御 +${tid < _terrainDefCommon.length ? _terrainDefCommon[tid] : 0}  '
            '回避 +${tid < _terrainAvoCommon.length ? _terrainAvoCommon[tid] : 0}',
    ];
    lastTerrainWindow = {
      'terrainId': tid,
      'enumName': _terrainEnumName(tid),
      'berserkerCost': cost,
      'def': tid < _terrainDefCommon.length ? _terrainDefCommon[tid] : null,
      'avo': tid < _terrainAvoCommon.length ? _terrainAvoCommon[tid] : null,
      'showsDefAvo': terrainShowsDefAvo(berserkerNormalCost: cost),
      'visible': true,
    };
    if (_terrainComp != null && _sameLines(_terrainComp!.lines, lines)) return;
    _removeTerrainWindow();
    if (!isMounted) return;
    final c = TerrainWindowComponent(
        lines: lines, tileSize: 16, screen: camera.viewport.virtualSize);
    _terrainComp = c;
    camera.viewport.add(c);
  }

  /// 地形枚举名（`terrains.json` 的 `enum`，反查 id → 名）
  String _terrainEnumName(int id) => _terrainEnumById[id] ?? 'TERRAIN_$id';

  void _removeTerrainWindow() {
    if (_terrainComp != null) {
      _terrainComp!.removeFromParent();
      _terrainComp = null;
    }
  }

  void _removeMinimug() {
    if (_minimugComp != null) {
      _minimugComp!.removeFromParent();
      _minimugComp = null;
    }
    _minimugUnitId = null;
    _minimugText = '';
  }

  /// 每帧推进目标窗口：滑入 6 帧 / 停留 / 滑出 4 帧（帧数出处见 `goal_window.dart`）
  void _tickGoalWindow() {
    final st = goalWindow;
    if (st == null) return;
    // ⚠️ **与原作有差异**：原作的 `gProcScr_GoalDisplay` 在 Init 时读一次配置，
    // 中途改设置要等**下一次阵营切换**才生效。我们每帧重读 ⇒ 在設定里关掉
    // 「クリア目的表示」**立刻**收起（这样"设置真的管用"当场可验）。
    st.wantVisible = goalWindowWanted;
    st.tick();
    if (!st.visible) {
      _hideGoalWindow();
    } else if (_goalWindowComp == null) {
      _showGoalWindowComp();
    }
  }

  /// 显示"我方回合 / 敌军回合 / 友军回合"横幅
  ///
  /// 文字照着原作那张表的口径（阵营 → 谁的回合），**没动用的阶段不显示**
  /// （对应 `PhaseIntro_EndIfNoUnits`：没人就跳过整段）。
  void _showPhaseBanner(BattleField f) {
    // ★ 阵营切换 ⇒ 目标窗口滑入（`gProcScr_GoalDisplay` 的
    // `GoalDisplay_Loop_OnSideChange`）。**两个条件**缺一不可：
    // `config.disableGoalDisplay == 0` && 旗 102 未置位
    //（`src/player_interface_0808F2C0.c:61-64`；旗名 `EVFLAG_OBJWINDOW_DISABLE`
    //  = 102，`include/constants/event-flags.h:16`）。
    _touchGoalWindow();
    if (f.phaseAbleCount(f.activeFaction) == 0) return; // 空阶段不演
    final (String text, bool isEnemy) = switch (f.activeFaction) {
      Faction.blue => ('我方回合', false),
      Faction.red => ('敌军回合', true),
      _ => ('友军回合', false),
    };
    _bannerText = text;
    _lastPhaseBanner = text;
    _bannerFrames = 60; // 约 1 秒
    final v = camera.viewport.virtualSize;
    if (_banner != null) {
      world.remove(_banner!);
      _banner = null;
    }
    _banner = PhaseBannerComponent(
      text: text,
      isEnemy: isEnemy,
      tileSize: v.y / 20.0,
      screen: v,
    );
    world.add(_banner!);
  }

  PhaseBannerComponent? _banner;

  /// 让当前阵营的所有单位按 AI 行动一轮。
  ///
  /// 单位按 **id 升序**处理，且每一步都重新查询战场状态——
  /// 因为前面的单位移动后会改变后面单位的落点选择。
  Future<void> _runFactionAi(BattleField f) async {
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
        await _attackWithQuote(f, u, f.unitById(a.targetId)!);
      }

      // ★ AI 行动之后也要查等待事件（`gProcScr_CpPerform` 的
      // `PROC_CALL_2(RunPotentialWaitEvents)`，见函数注释）。
      // 敌方阶段里被打死的首领就是靠这一步触发的。
      await _checkObjectives();

      // 逐单位停顿：原作每个 AI 单位是一条阻塞子 proc（移动动画 + 等待），
      // 所以看得见；一帧跑完就是用户说的"敌方行动过快"。
      await Future<void>.delayed(kEnemyStepDelay);
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
    final defTb = _terrainBonuses(terrainId, defProfile.classId);
    final terrainDef = defTb.defense;
    final terrainAvo = defTb.avoid;
    final atkTerrainId = _terrainAt(attacker.x, attacker.y);
    final atkTb = _terrainBonuses(atkTerrainId, atkProfile.classId);
    final atkDef = atkTb.defense;
    final atkAvo = atkTb.avoid;

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

      // ★ **逐段**的即时反馈（闪白 + 飘字）。
      //
      // 受力方 = `attackerIsActor ? 防御方 : 攻击方`（反击时反过来），
      // 数值与命中/暴击都取**结构化字段**（`AttackResult.hit / crit / damage`），
      // 不解析战报字符串。
      final target = st.attackerIsActor ? defender : attacker;
      _spawnHitFx(target, round.results[i]);   // 结果对象（含 hit/crit/damage）
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
    // ★ 「道具」这一项出不出现、菜单里有几个可用槽 —— 都需要道具表 + 当前 HP，
    // 所以由游戏层算好注入（状态机不持有道具表）。
    _usableSlots = itemMenuSlots(unit);
    fl.hasUsableItem = _usableSlots.isNotEmpty;
    fl.itemSlotCount = _usableSlots.length;
  }

  /// 道具菜单里列出的槽（**所有非空槽**，绝对下标）。
  ///
  /// 原作「道具」打开的是 `ItemSelectMenu`，列出**全部道具**，再对选中的那件弹
  /// `ItemSubMenu`（装備 / 使う / 捨てる / 交換，`src/ItemSubMenu_*.c`）。
  ///
  /// ⚠️ **子菜单未实现**：这里把子菜单的"默认项"直接做了 ——
  /// 武器 ⇒ 装备（`EquipUnitItemSlot`），回复品 ⇒ 使用。子菜单本身还没做。
  /// ⚠️ 可用性（`ItemSelectMenu_Usability`，`src/bmmenu_0802339C.c:64`）未逐行核对；
  /// 这里只按"槽非空"。
  List<int> itemMenuSlots(MapUnit u) {
    final out = <int>[];
    for (var i = 0; i < u.items.length; i++) {
      if (u.items[i] != 0) out.add(i);
    }
    return out;
  }

  /// 这件道具能不能"使用"（回复类，且没满血）
  bool canUseItem(MapUnit u, int word) {
    if (u.hp >= u.maxHp) return false;
    final num = ItemTable.itemIndex(word);
    if (_itemNameByNumber[num] == null) return false;
    return unitItemHealAmount(
            itemNumber: num,
            isStaff: (_itemStats[num]?.attributes ?? 0) & kItemStaffAttribute != 0,
            nameOf: _itemNameByNumber) >
        0;
  }

  /// 这件道具是不是武器（`IA_WEAPON`，见 [ItemStats.isWeapon]）
  bool isWeaponItem(int word) =>
      _itemStats[ItemTable.itemIndex(word)]?.isWeapon ?? false;

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
      // "是不是武器"看 `IA_WEAPON` 属性位（`include/bmitem.h:56`），
      // **不能看 weaponType** —— `ITYPE_SWORD = 0`，与"没有类型"分不开。
      if (s != null && s.isWeapon) {
        weapon = slot;
        break;
      }
    }
    final it = _itemStats[ItemTable.itemIndex(weapon)];

    // 三张表缺任何一张就**明确报出来**，不静默退回假数据
    if (cls == null) {
      _sceneHudExtra = '缺职业 ${u.classId} 的基础值（classes.json）';
    }

    // `ITYPE_*`（`include/bmitem.h:84-96`）与 `WeaponType.*`
    // （`lib/core/battle/weapon_triangle.dart:26-34`）**逐个数相同** —— 恒等映射。
    final weaponType = it?.weaponType ?? WeaponType.sword;

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
  /// 按**职业**查该地形上的加成。
  ///
  /// ⚠️ 返回值是 `(avoid, defense)` 的**具名**记录 —— 调用点必须用
  /// `.defense` / `.avoid` 取值。以前这里返回位置记录，而调用方按
  /// `(def, avo)` 解构，于是防御和回避**整个对调**（山峰的 40 回避
  /// 被当成防御），伤害恒为 0、序章打不动人。
  ({int avoid, int defense}) _terrainBonuses(int terrainId, int classId) {
    final t = classTable;
    if (t == null) return (avoid: 0, defense: 0);
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
          note: _playNote,
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
    // 过场里画的是**演出光标**（`CURSOR_CHAR`），不是玩家光标。
    // 原作在 `CURSOR_CHAR` 之前屏幕上没有光标 —— 所以过场且没有演出光标时
    // 把玩家光标藏起来。
    v.hideCursor = (_sceneRunning && _eventCursor == null) || worldMap != null;
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
  /// 单位 → 移动消耗表。
  ///
  /// ## 出处：`src/masked_08018a60.c` 的 `GetUnitMovementCost`
  ///
  /// ```c
  /// switch (gPlaySt.chapterWeatherId) {
  /// case WEATHER_RAIN:                    return unit->pClassData->pMovCostTable[1];
  /// case WEATHER_SNOW:
  /// case WEATHER_SNOWSTORM:               return unit->pClassData->pMovCostTable[2];
  /// default:                              return unit->pClassData->pMovCostTable[0];
  /// }
  /// ```
  ///
  /// 天气取自**当前章节数据**（`ChapterData.initialWeather` =
  /// `gPlaySt.chapterWeatherId`），常量见 `include/types.h:355-362`。
  ///
  /// ⚠️ 之前是全場一张 `_demoCostTable()`（除 0 号地形外全 1）——
  /// 后果是**山峰也能走**（真实表里绝大多数职业在山峰上是 255 = 不可通行）。
  MovementCostTable _moveCostsOf(MapUnit u) {
    final ct = classTable;
    if (ct == null) {
      _moveCostsNote = '职业表没载入 → 移动消耗退回演示表（全场 1）';
      return _demoCostTable();
    }
    final costs = ct.movementCosts(u.classId, _weatherNow);
    if (costs == null) {
      // 石像鬼蛋 / 弩车这类没有消耗表的职业：原作走 `Unk_TerrainTable_0`
      // （`include/variables.h:539`，**未 carve**）→ 显式记下来，
      // 不当成"全 1 且能走"
      if (_missingMoveCosts.add(u.classId)) {
        _moveCostsNote =
            '职业 ${u.classId} 没有移动消耗表（原作走 Unk_TerrainTable_0，未 carve）';
      }
      return _demoCostTable();
    }
    return MovementCostTable(costs);
  }

  /// 当前天气 → `pMovCostTable` 的第几张（`GetUnitMovementCost` 的分支）
  Weather get _weatherNow {
    final list = chapters?.list ?? const <ChapterData>[];
    final w = sceneChapter < list.length ? list[sceneChapter].initialWeather : 0;
    return switch (w) {
      4 => Weather.rain, // WEATHER_RAIN
      1 || 2 => Weather.snow, // WEATHER_SNOW / WEATHER_SNOWSTORM
      _ => Weather.normal,
    };
  }

  /// 移动消耗/查表失败的**结论**（转储里带出来）
  String _moveCostsNote = '';
  final Set<int> _missingMoveCosts = {};

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
