// PORT OF: src/event.c + src/TalkInterpret.c（场景演出的运行时）
//          ⚠️ 不是 1:1 移植：脚本改成了 async 函数，不是可序列化的指令流
//
// arch-exempt: R4 「完全可序列化」这条约束已由用户明确取消（不需要随时存档），
//           所以场景脚本改用 async 函数直接表达"等玩家按键"，
//           不再用可序列化的状态机。见 tools/pipeline/extract/gen_scene_dart.py。
//
// 场景演出的运行时。
//
// ## 为什么可以生成 `async` 函数
//
// 之前保留"指令列表 + 程序计数器"的唯一理由是**随时存档**。
// 用户明确说不需要之后，那层数据模型就没有存在理由了 ——
// `SceneOp` 那些类型存在的唯一意义就是"被解释"。
//
// 现在生成的代码**直接调用本类的方法**：
//
//     Future<void> prologueBeginningScene(Scene s) async {
//       await s.call(prologueRenaisThroneCutscene);
//       s.setSlot(2, Sym('EventScr_Prologue_EirikaAttacked'));
//       await s.textShow(0x8CE);
//       ...
//     }
//
// `await` 天然表达"等玩家按键"，`CALL` 就是函数调用。
//
// ## 等多久由调用方决定
//
// [onEvent] 返回 `Future` —— 游戏里它等到按键，测试里它立即返回。
// 所以**同一份脚本既能演、也能测**，不用为测试准备假的输入。

import 'game_text.dart';

/// 演出中发生的一件事
/// 淡入/淡出方向。取值对应 `EVSUBCMD_FAD*`。
enum FadeDirection {
  /// subcode 0：从黑淡出（画面出现）
  fromBlack,

  /// subcode 1：淡到黑（画面消失）
  toBlack,

  /// subcode 2：从白淡出
  fromWhite,

  /// subcode 3：淡到白
  toWhite,
}

/// `UnitMenuOverrideConf[15]`（`src/Event3D_MenuOverride.c:74-90`）
///
/// **bit i ⇒ 把第 i 个菜单项永久隐藏**（`AddMenuOverride(..., MenuAlwaysNotShown)`，
/// `:110-118`）。表里是菜单项的 **msgId**，注释是反编译自带的。
/// 我们按"语义键"映射到自己的 `ActionOption`；映射不到的（如"杖"在我们的模型里
/// 属于道具子菜单、没有独立项）在 [menuOverrideKeys] 里留 `null`，
/// 由调用方**显式记录**，而不是悄悄丢掉。
const List<int> unitMenuOverrideMsgIds = [
  0x4F, 0x51, 0x6B, 0x63, 0x64, 0x5C, 0x5A, 0x67,
  0x37, 0x68, 0x69, 0x5B, 0x5F, 0x71, 0x78,
];

/// msgId → 我们的 ActionOption 语义键（`null` = 我们模型里没有对应项）
const List<String?> menuOverrideKeys = [
  'attack', //  0x4F 攻撃
  null, //      0x51 杖    —— 我们把它放在道具子菜单里，没有独立项（走 unmapped）
  'wait', //    0x6B 待機
  'rescue', //  0x63 救出
  'drop', //    0x64 降ろす
  'visit', //   0x5C 訪問
  'talk', //    0x5A 話す
  'item', //    0x67 持ち物
  'discard', // 0x37 捨てる
  'trade', //   0x68 交換
  'supply', //  0x69 輸送隊
  null, //      0x5B 支援    —— 我们还没做支援
  null, //      0x5F 武器屋  —— 商店还没做（数据被 gUidebug_2 挡住）
  null, //      0x71 設定    —— 設定是地图菜单，不是行动菜单
  null, //      0x78 終了
];

/// `DISABLEOPTIONS` = `EvtOverrideUnitMenu(mask)`（`include/eventscript.h:738`）
/// ⇒ 把掩码里置位的那些菜单项**永久隐藏**。
/// 返回 `(我们能隐藏的键, 我们模型里没有对应项的 msgId 列表)`
///
/// ⚠️ 第二项**必须**返回：那些位（杖 / 支援 / 武器屋 / 設定 / 終了）我们没法隐藏，
/// 静默丢掉就等于"原作隐藏了、我们没隐藏"而没人知道。
({List<String> keys, List<int> unmapped}) menuOverrideForMask(int mask) {
  final keys = <String>[];
  final unmapped = <int>[];
  for (var i = 0; i < menuOverrideKeys.length; i++) {
    if ((mask & (1 << i)) == 0) continue;
    final k = menuOverrideKeys[i];
    if (k != null) {
      keys.add(k);
    } else {
      unmapped.add(unitMenuOverrideMsgIds[i]);
    }
  }
  return (keys: keys, unmapped: unmapped);
}

/// 只要键的那部分（判据用；未映射的请看 [menuOverrideForMask]）
List<String> menuOverrideKeysForMask(int mask) =>
    menuOverrideForMask(mask).keys;

/// `IsActiveEventTextTypeOnMap`（`src/IsActiveEventTextTypeOnMap.c:25-45`）：
/// **类型 1 和 2 是"在地图上"的文本框**，0/3/4/5 不是。
bool eventTextTypeOnMap(int type) => type == 1 || type == 2;

/// `EV_STATE_*` 位（`include/event.h:59-63`）—— `EVBIT_MODIFY` 动的是这几位
const int kEvStateNoSkip = 1 << 0x4;
const int kEvState0020 = 1 << 0x5;
const int kEvState0040 = 1 << 0x6;
/// `EV_STATE_SKIPPING`（`include/event.h` 里那一位；注释见 `EVENT_IS_SKIPPING`）
const int kEvStateSkipping = 1 << 2;
/// `EV_STATE_FADEDIN`（跳过 EVBIT_MODIFY 时翻到的位）
const int kEvStateFadedIn = 1 << 7;

/// 事件计数器的**纯运算**（`src/Event0F_CounterOps.c:24-99`）
///
/// 32 位按 **nibble** 打包（8 个 4 位计数器）；`shift = 4 * (idx % 8)`
/// （源码：`shift = 4 * ((*((const u8 *)(event + 1))) % 8)`）。
int eventCounterShift(int idx) => 4 * (idx % 8);

int eventCounterGet(int counter, int idx) =>
    (counter >> eventCounterShift(idx)) & 0xF;

int eventCounterPut(int counter, int idx, int value) {
  final shift = eventCounterShift(idx);
  final clearMask = 0xF << shift;
  return (counter & ~clearMask) | ((value & 0xF) << shift);
}

/// `COUNTER_INC`：+1，**上限 15**（源码：`if (newValue > mask) newValue = 0xF;`）
int eventCounterInc(int counter, int idx) {
  final v = eventCounterGet(counter, idx) + 1;
  return eventCounterPut(counter, idx, v > 0xF ? 0xF : v);
}

/// `COUNTER_DEC`：-1，**下限 0**
int eventCounterDec(int counter, int idx) {
  final v = eventCounterGet(counter, idx) - 1;
  return eventCounterPut(counter, idx, v < 0 ? 0 : v);
}

sealed class SceneEvent {
  const SceneEvent();
}

/// 显示一段文字
class ShowText extends SceneEvent {
  const ShowText({
    required this.message,
    required this.scriptName,
    required this.step,
    this.page,
    this.upto,
    this.pageIndex = 0,
    this.pageCount = 1,
  });

  final GameMessage message;
  final String scriptName;
  final int step;

  /// **这一页**的文字（一条消息可能有好几页，见 `GameMessage.pageSpans`）
  final String? page;

  /// 这一页在 `message.segments` 里的结束下标。
  ///
  /// ⚠️ 有它就不必"拿文字去反查页界" —— 那个做法在含 `[LF]` 的页上
  /// 永远匹配不到，退了会退化成"用整条消息的脸状态"。
  final int? upto;
  final int pageIndex;
  final int pageCount;

  /// 实际要显示的文字
  String get text => page ?? message.plain;

  bool get hasMorePages => pageIndex + 1 < pageCount;

  @override
  String toString() => 'ShowText(0x${message.id.toRadixString(16)}'
      '${pageCount > 1 ? ' 第${pageIndex + 1}/$pageCount页' : ''})';
}

/// 换章节（`MNC2`）。
///
/// ## 出处：`include/eventscript.h:681`
///
/// ```c
/// #define EvtChangeChapterBM(chapter) \
///     _EvtArg0(EV_CMD_CHANGECHAPTER, 2, EVSUBCMD_MNC2, (chapter))
/// ```
///
/// **序章的结束脚本里就是 `MNC2(1)`** —— 显式切到第 1 章。
///
/// ⚠️ 我第一版把它当占位（`s.placeholder('MNC2')`），
/// **结果游戏永远停在序章** —— 第 1 章根本到不了。
class ChangeChapter extends SceneEvent {
  const ChangeChapter({
    required this.chapterIndex,
    required this.scriptName,
    this.subcmd = 2,
  });

  /// 目标 `chapterIndex`
  final int chapterIndex;
  final String scriptName;

  /// `EVSUBCMD_MNTS/MNCH/MNC2/MNC3/MNC4`（`src/Event2A_MoveToChapter.c:22-57`）
  ///
  /// ⚠️ 这四条**不是同一条流程**：
  ///   * `MNCH`(1) → `save_menu_type = 1` + `nextAction = CLASS_REEL`
  ///     ⇒ 之后 `EXEC_BM` 会先起 **`ProcScr_WorldMapWrapper`（大地图）** 再进地图
  ///   * `MNC2`(2) → `save_menu_type = 2` ⇒ `CheckNewGameAndBranch` 命中 2/4，
  ///     **直接进地图，跳过大地图**
  ///   * `MNC3`(3) → `GotoChapterWithoutSave`（另一条路径）
  ///   * `MNC4`(4) → `save_menu_type = 3` + `PLAYED_THROUGH`
  ///   * `MNTS`(0) → 回标题（`GAME_ACTION_EVENT_RETURN`），**不是换章**
  final int subcmd;

  @override
  String toString() => 'ChangeChapter($chapterIndex, subcmd $subcmd)';
}

/// 换地图（`LOMA`）。
///
/// ## 出处：`src/eventscr_0800F390.c:45-68`（`Event25_ChangeMap`）
///
/// ```c
/// chIndex = current[1];              // ← 操作数是 **chapterIndex**
/// gPlaySt.chapterIndex = chIndex;
/// RestartBattleMap();                // 用新章节号重建地图
/// ```
///
/// ⚠️ **不是资产 id。** 序章的 `EventScr_Prologue_RenaisThroneCutscene`
/// 靠三次 `LOMA` 换三张图：
///
///     LOMA(0x10) → 章节 16 (E15) → Ch16Map          ← 王座厅（王宫内）
///     LOMA(0x40) → 章节 64 (0x40) → GradoCastleMap  ← 王宫外
///     LOMA(0)    → 章节 0  (L00) → PrologueMap      ← 可玩地图
///
/// 我之前把 `LOMA` 当占位，于是**地图从来没换过** —— 一直在画
/// `PrologueMap`（绿草地），而前两段剧情本该在王座厅和王宫外。
class LoadMap extends SceneEvent {
  const LoadMap({required this.chapterIndex, required this.scriptName});

  /// `chapterIndex`（不是资产 id）
  final int chapterIndex;
  final String scriptName;

  @override
  String toString() => 'LoadMap(chapter $chapterIndex)';
}

/// 把单位从地图上拿掉（`DISA` / `DISA_IF`）。
///
/// 出处：`src/eventscr_080103F4.c:212-223`
///
/// ⚠️ 这一条以前是占位符，后果是**该消失的人一直站在地图上**：
/// 序章王座厅那一幕里有 4 次 `DISA`（传令兵走掉、艾莉卡被赛特抱走…）。
class RemoveUnit extends SceneEvent {
  const RemoveUnit({required this.pid, this.onlyIfDead = false});

  /// 角色号（`GetUnitStructFromEventParameter`）
  final int pid;

  /// `DISA_IF`：只对已阵亡的生效
  final bool onlyIfDead;

  @override
  String toString() => 'RemoveUnit($pid${onlyIfDead ? ', ifDead' : ''})';
}

/// 设置单位 HP —— 值**从槽 1 取**（`SET_HP` = `EvtSetUnitHpFormSlot1`）。
///
/// 出处：`src/eventscr_080103F4.c:127-132`
class SetUnitHp extends SceneEvent {
  const SetUnitHp({required this.pid});

  final int pid;

  @override
  String toString() => 'SetUnitHp($pid <- 槽1)';
}

/// 演出光标（`CURSOR_CHAR` / `DISPLAYCURSOR` / `CURSOR_FLASHING*`）。
///
/// 出处：`src/Event3B_DisplayCursor.c:22-80`。
/// [pid] 给定时用单位的位置；否则用 [x]/[y]。
class ShowCursor extends SceneEvent {
  const ShowCursor({this.pid, this.x, this.y, this.flashing = false});

  final int? pid;
  final int? x;
  final int? y;
  final bool flashing;

  @override
  String toString() => pid != null
      ? 'ShowCursor(unit $pid${flashing ? ', flashing' : ''})'
      : 'ShowCursor($x, $y${flashing ? ', flashing' : ''})';
}

/// 结束演出光标（`CURE` = `EvtEndCursor`）。
class EndCursor extends SceneEvent {
  const EndCursor();

  @override
  String toString() => 'EndCursor';
}

/// 等所有单位走完（`ENUN` = `EvtWaitUnitMoving`）。
///
/// 本实现里移动是瞬移，所以它立即返回 —— 但它是**已实现**的事件，
/// 不是占位符。
class WaitUnitMoving extends SceneEvent {
  const WaitUnitMoving();

  @override
  String toString() => 'WaitUnitMoving';
}

/// 教学事件**入队**（`EvtEnqueueConditionalTutCall(exec_type, scr)`）。
///
/// 出处：`src/eventscr_0800DC94.c:76-100` `Event0B_EnqueueCall`
/// （`EV_CMD_ENQUEUE_CALL`，sub 1 = `EVSUBCMD_ENQUEUE_TRIGGER`）→
/// `EnqueueTutEvent`（`src/EnqueueTutEvent.c:24-38`）。
///
/// 它**不立刻演**：只是把"下一个 `<type>` 钩子来的时候演这段"记进
/// `gPlaySt.tutorial_counter` / `tutorial_exec_type`。
/// 真正的演出在 `RunTutorialEvent`（见 `lib/core/flow/tutorial_events.dart`）。
class EnqueueTutCall extends SceneEvent {
  const EnqueueTutCall({required this.execType, required this.script});

  /// `TUTORIAL_EVT_TYPE_*`（`include/eventinfo.h:30-36`）
  final int execType;

  /// 要入队的脚本名
  final String script;

  @override
  String toString() => 'EnqueueTutCall(type $execType, $script)';
}

/// 相机取景（`CAMERA(x, y)` / `CAMERA2(x, y)`）。
///
/// 出处：`src/Event26_CameraControl`（`src/eventscr_0800F41C.c:10-62`）。
///
/// 序章王座厅那一幕就是靠它把镜头压到王座上：
///
///     SVAL(EVT_SLOT_B, 0x000A000E)   ← LOMA 的初始相机 (14,10)
///     LOMA(0x10)                     ← 换到 Ch16Map
///     ...
///     CAMERA(0xE, 0)                 ← ★ 镜头移到 (14,0)：王座在画面里
///
/// ⚠️ 这一条一直是占位符，所以镜头停在地图中央 —— 用户看到的"取景不对"。
class CameraControl extends SceneEvent {
  const CameraControl({
    required this.x,
    required this.y,
    this.centered = false,
  });

  /// 目标格（`s8`；**负数表示"用槽 0xB"**，见 `Event26_CameraControl`）
  final int x;
  final int y;

  /// sub-cmd bit3：`false` = `CAMERA`（不居中），`true` = `CAMERA2`（居中）
  final bool centered;

  @override
  String toString() =>
      'CameraControl($x, $y${centered ? ', centered' : ''})';
}

/// 是/否选择（`[Yes]`(24) / `[No]`(25)）。
///
/// ## 出处
///
/// `src/TalkInterpret.c:207-231`：
///
/// ```c
/// case CHFE_L_Yes:
///     StartTalkChoice(gYesNoTalkChoice, ..., 1, ...);   // 默认选"是"
/// case CHFE_L_No:
///     StartTalkChoice(gYesNoTalkChoice, ..., 2, ...);   // 默认选"否"
/// ```
///
/// 结果写在 `sTalkChoiceResult`，文本事件结束时由
/// `src/eventscr.c:123` 写进 **`gEventSlots[0xC]`**：
///
/// ```c
/// gEventSlots[0xC] = GetTalkChoiceResult();
/// ```
///
/// 取值 `TALK_CHOICE_CANCEL = 0` / `TALK_CHOICE_YES = 1` / `TALK_CHOICE_NO = 2`
/// （`include/scene.h:39-41`）。
class Choice extends SceneEvent {
  const Choice({
    required this.defaultYes,
    required this.scriptName,
  });

  /// 默认选中项：`[Yes]` 为 true、`[No]` 为 false
  final bool defaultYes;
  final String scriptName;

  @override
  String toString() => 'Choice(默认${defaultYes ? '是' : '否'})';
}

/// 淡入/淡出（`FADU` / `FADI` / `FAWU` / `FAWI`）
class Fade extends SceneEvent {
  const Fade({
    required this.dir,
    required this.speed,
    required this.scriptName,
  });

  final FadeDirection dir;

  /// 速度参数：值越大越慢（原作语义）
  final int speed;
  final String scriptName;

  @override
  String toString() => 'Fade(${dir.name}, speed=$speed)';
}

/// 等玩家按键（文本里有 `[A]` 时自动产生）
class WaitForInput extends SceneEvent {
  const WaitForInput(this.scriptName, this.step);
  final String scriptName;
  final int step;

  @override
  String toString() => 'WaitForInput';
}

/// 加载单位表
/// `SetFlag` / `ClearFlag`（章节旗）—— 由 `ENUT`/`ENUF` 产生
///
/// 出处：`src/Event02_EvBitAndIdMod.c:31-34`（`sub_cmd_lo == 1` 那一支）。
/// `IGNORE_KEYS` —— 输入屏蔽掩码（游戏侧生效）
class KeyIgnore extends SceneEvent {
  const KeyIgnore(this.mask);

  final int mask;
}

/// 音频指令（`MUSC`/`MUSS`/`SOUN`/`MUSI`/`MUNO`）—— 只表达"要放什么"
class SoundOp extends SceneEvent {
  const SoundOp({required this.kind, required this.id});

  /// `bgm`（MUSC）/ `override`（MUSS）/ `se`（SOUN）/ `volume`（MUSI/MUNO）
  final String kind;

  /// 歌曲表下标（`volume` 时 1=降低、0=恢复）
  final int id;
}

/// `TEXTCONT` —— 继续/结束对话（带"是否跳过中"：跳过时要真的收尾）
class ContinueText extends SceneEvent {
  const ContinueText(this.skipping);

  final bool skipping;
}

/// `DISABLEOPTIONS` —— 永久隐藏掩码里置位的那些菜单项
class MenuOverride extends SceneEvent {
  const MenuOverride(this.mask);

  final int mask;
}

/// `CUMO_CHAR` —— 场景光标画到某个单位上
class DisplayCursorAtUnit extends SceneEvent {
  const DisplayCursorAtUnit(this.pid);

  final int pid;
}

/// `CAMERA_CAHR` —— 把镜头移到某个角色（游戏侧解析坐标后调 `cameraTo`）
class CameraToChar extends SceneEvent {
  const CameraToChar(this.pid);

  final int pid;
}

/// `BROWNBOXTEXT` —— 棕色弹窗（带文本与坐标，自己计时结束）
class PopupText extends SceneEvent {
  const PopupText({required this.textId, required this.x, required this.y});

  final int textId;
  final int x;
  final int y;
}

/// `REMU` / `REVEAL` / `SET_STATE` —— 单单位状态
class UnitStateOp extends SceneEvent {
  const UnitStateOp({required this.kind, required this.arg});

  /// `hide` / `reveal` / `setState`
  final String kind;

  /// 角色编号（负数 = 事件槽 2，由调用方解析）
  final int arg;
}

/// `CLEA`/`CLEN`/`CLEE` —— 把某个阵营的单位全部藏起来
class HideFaction extends SceneEvent {
  const HideFaction(this.faction);

  /// `blue` / `green` / `red`
  final String faction;
}

/// `TEXTEND`（`EV_CMD_ENDTEXT`）—— 收起/锁定文本框
class EndText extends SceneEvent {
  const EndText(this.scriptName);

  final String scriptName;
}

/// `REMA`（`EvtTextRemoveAll`）—— 清掉当前显示的所有文本
class RemoveAllText extends SceneEvent {
  const RemoveAllText(this.scriptName);

  final String scriptName;
}

class SetEventFlag extends SceneEvent {
  const SetEventFlag({required this.flag, required this.value});

  final int flag;
  final bool value;
}

class LoadUnits extends SceneEvent {
  const LoadUnits(this.table, this.group);
  final String table;
  final int group;

  @override
  String toString() => 'LoadUnits($table)';
}

/// 移动单位
class MoveUnitInScene extends SceneEvent {
  const MoveUnitInScene(this.op, this.args);
  final String op;
  final List<Object> args;

  @override
  String toString() => '$op(${args.join(', ')})';
}

/// 把**槽 3** 里的道具给某个角色（`GIVEITEMTO`）。
///
/// ## 出处：`src/eventscr_080106FC.c:90-93`
///
/// ```c
/// case EVSUBCMD_GIVEITEMTO:
///     NewPopup_ItemGot(proc, target, gEventSlots[3]);
///     break;
/// ```
///
/// 而 `NewPopup_ItemGot` -> ... -> `UnitAddItem`（`src/exact_080176f0.c:37`）：
///
/// ```c
/// s8 UnitAddItem(struct Unit* unit, int item) {
///     for (i = 0; i < UNIT_ITEM_COUNT; ++i)
///         if (unit->items[i] == 0) { unit->items[i] = item; return TRUE; }
///     return FALSE;
/// }
/// ```
///
/// **道具的编码**由 `MakeNewItem`（`src/MakeNewItem.c:27`）给出：
///
///     return (uses << 8) + GetItemIndex(item);
///
/// 序章里艾莉卡的细剑就是这么来的（`EventScr_Prologue_GiveRapier`）：
///
///     SVAL(EVT_SLOT_3, ITEM_SWORD_RAPIER)
///     GIVEITEMTO(CHARACTER_EIRIKA)
class GiveItem extends SceneEvent {
  const GiveItem({required this.pid, required this.itemSlot});

  /// 目标角色（`charIndex`；`0xFFFF` = 当前行动单位）
  final int pid;

  /// 道具所在的槽（原作是槽 3）
  final int itemSlot;

  @override
  String toString() => 'GiveItem(pid=$pid, slot=$itemSlot)';
}

/// 暂停若干帧
class Stall extends SceneEvent {
  const Stall(this.frames, {this.cancellable = false});
  final int frames;

  @override
  String toString() => 'Stall($frames)';

  /// `STAL1` ⇒ true（B 键/跳过可提前结束）
  final bool cancellable;
}

/// 符号引用（脚本名 / 单位表名 / 函数名），可带偏移
class Sym {
  const Sym(this.name, [this.offset = 0]);

  final String name;
  final int offset;

  @override
  bool operator ==(Object other) =>
      other is Sym && other.name == name && other.offset == offset;

  @override
  int get hashCode => Object.hash(name, offset);

  @override
  String toString() =>
      offset == 0 ? name : '$name+0x${offset.toRadixString(16)}';
}

/// 生成器没能归类的参数原文。
///
/// **它出现就代表生成器要补映射**，不是正常状态。
class RawArg {
  const RawArg(this.text);
  final String text;

  @override
  String toString() => '?$text';
}

/// 场景演出的运行时状态
class Scene {
  Scene({
    required this.texts,
    required this.onEvent,
    required this.scripts,
    Set<String>? defined,
  }) : defined = defined ?? const {};

  /// **快进中**（START 键）—— 对应原作的 `EV_STATE_SKIPPING`。
  ///
  /// 出处：`include/event.h:57`
  ///
  /// ```c
  /// EV_STATE_SKIPPING = (1 << 0x2), // currently skipping events (trigger with start)
  /// #define EVENT_IS_SKIPPING(aEventProc) (((aEventProc)->evStateBits >> 2) & 1)
  /// ```
  ///
  /// 触发：`src/event_0800D110.c:27`（START 键）。
  /// 各指令里的检查：`Event17_Fade.c:49`、`Event21_TextBg.c:42`、
  /// `Event2F_MoveUnit`、`Event3B_DisplayCursor`、`Event34`（KILL 的死亡淡出）…
  ///
  /// ⚠️ 触发条件是 `START_BUTTON` 的 **newKeys**（按下那一刻），不是按住。
  bool get skipping => _skipping;
  bool _skipping = false;

  /// 开始快进（重复调用无副作用）
  void startSkip() => _skipping = true;

  /// 结束快进（`EV_EXEC_CUTSCENE` 分支会清掉它，`src/eventscr_0800D860.c:79-83`）
  void stopSkip() => _skipping = false;

  final GameTexts texts;

  /// 演出中发生一件事时调用。
  ///
  /// 返回的 Future 被 `await` —— **游戏里等到按键，测试里立即返回**。
  final Future<void> Function(SceneEvent) onEvent;

  /// 脚本名 → 入口函数（含缺失脚本的占位函数）
  final Map<String, Future<void> Function(Scene)> scripts;

  /// **真正被 carve 出来**的脚本名 —— 存在性检查用这个。
  ///
  /// ⚠️ 不能用 `scripts.keys`：它包含缺失脚本的**占位函数**，
  /// 那样"缺失"会看起来"存在"，检查就失效了（踩过）。
  final Set<String> defined;

  /// 当前正在执行的脚本名（事件定位用）
  String currentScript = '';

  /// 本次演出碰到的缺口
  final Set<String> missing = {};

  /// 走到的兜底调用（认得但不执行的）—— 列出来而不是藏起来
  final Map<String, int> placeholderCalls = {};

  /// 生成器未归类的参数
  final Set<String> unmappedArgs = {};

  /// 调用栈深度（`CALL` 嵌套）—— 防止脚本成环时无限递归
  int depth = 0;
  static const int maxDepth = 64;

  // ---- 生成的代码调用的方法 ----

  /// `CALL(x)` —— 运行另一个脚本
  Future<void> call(Sym target) async {
    if (depth >= maxDepth) {
      missing.add('?CALL 嵌套过深($maxDepth)：${target.name}');
      return;
    }
    final fn = scripts[target.name];
    if (fn == null) {
      // ⚠️ 不静默跳过 —— 否则"剧情少了一段"查不出来
      missing.add(target.name);
      return;
    }
    final prev = currentScript;
    currentScript = target.name;
    depth++;
    try {
      await fn(this);
    } finally {
      depth--;
      currentScript = prev;
    }
  }

  /// `CALL_SLOT(n)` —— 调用插槽里存的脚本
  Future<void> callSlot(int slot) async {
    final v = _slots[slot];
    if (v is Sym) {
      await call(v);
    } else if (v is String) {
      await call(Sym(v));
    }
  }

  /// `EvtEnqueueConditionalTutCall(exec_type, scr)` —— 入队，不是立刻演
  ///
  /// 出处：`src/eventscr_0800DC94.c:87-94`（sub 1 → `EnqueueTutEvent`）
  void enqueueTutCall(int execType, Sym script) => onEvent(
        EnqueueTutCall(execType: execType, script: script.name),
      );

  final Map<int, Object> _slots = {};

  void setSlot(int slot, Object value) {
    _slots[slot] = value;
    // 插槽里存脚本引用时也检查存在性 —— 这类**间接引用**
    // 比直接 CALL 更隐蔽（序章缺的 3 个就是这么漏掉的）
    final String? name = value is Sym
        ? value.name
        : (value is String ? value : null);
    if (name != null &&
        name.startsWith('EventScr_') &&
        defined.isNotEmpty &&
        !defined.contains(name)) {
      missing.add(name);
    }
  }

  void setSlot2(int slot, int lo, int hi) {
    _slots[slot] = lo;
    _slots[slot + 1] = hi;
  }

  int slotInt(int i) => _slots[i] is int ? _slots[i] as int : 0;
  Object? slot(int i) => _slots[i];

  void slotArith(String op, int dst, Object src) {
    final a = slotInt(dst);
    final b = src is int ? src : slotInt(0);
    _slots[dst] = switch (op) {
      'SADD' => a + b,
      'SSUB' => a - b,
      'SMUL' => a * b,
      'SDIV' => b == 0 ? 0 : a ~/ b,
      'SAND' => a & b,
      'SORR' => a | b,
      _ => a,
    };
  }

  /// 事件计数器（`gEventSlotCounter`）：**32 位按 nibble 打包**（8 个计数器）
  ///
  /// 出处：`src/Event0F_CounterOps.c:24-99`。下标 `idx` 取 `idx % 8`（源码：
  /// `shift = 4 * ((*((const u8 *)(event + 1))) % 8)`）。
  int eventSlotCounter = 0;

  /// 音频（`MUSC` / `MUSS` / `SOUN` / `MUSI` / `MUNO`）—— 场景只**发信号**，
  /// 状态与发声都归游戏侧（与 `IGNORE_KEYS` 同一条教训：谁拥有资源谁持有状态）。
  void sound(String kind, int id) => onEvent(SoundOp(kind: kind, id: id));

  /// `MUSI`（降低）/ `MUNO`（恢复）
  void volumeDown(bool down) => onEvent(SoundOp(kind: 'volume', id: down ? 1 : 0));

  /// `TEXTCONT` = `EvtContinueText`（`include/EAstdlib.h:92`；
  /// 处理函数 `Event1D_TalkContinue`，`src/eventscr.c:47-66`）
  ///
  /// * **跳过中** ⇒ `EndTalk/EndCgText/EndAllBoxDialogue`（结束对话）；
  /// * 否则 ⇒ `ResumeTalk()`；
  /// * 两种都返回 `EVC_ADVANCE_YIELD`。
  Future<void> continueText() => onEvent(ContinueText(skipping));

  /// `DISABLEOPTIONS` = `EvtOverrideUnitMenu(mask)`（`include/eventscript.h:738`）
  ///
  /// 菜单是**游戏侧**的 ⇒ 场景发事件，由游戏把对应项永久隐藏
  /// （原作：`AddMenuOverride(..., MenuAlwaysNotShown)`，`src/Event3D_MenuOverride.c:110-118`）。
  void overrideUnitMenu(int mask) => onEvent(MenuOverride(mask));

  /// `proc->activeTextType` —— **子命令号就是类型**（`src/eventscr_0800E3E0.c:94`）
  ///
  /// 含义见 [eventTextTypeOnMap]（`src/IsActiveEventTextTypeOnMap.c:25-45`）。
  int activeTextType = 0;

  void setTextType(int type) => activeTextType = type;

  /// `EVBIT_MODIFY` = `EvtModifyEvBit(type)`（`include/eventscript.h:622`）
  ///
  /// 出处：`src/masked_0800def0.c:74-100`：
  ///   * `0` ⇒ 清 `EV_STATE_NOSKIP | 0020 | 0040`；
  ///   * `1` ⇒ 三个全置；
  ///   * `2` ⇒ 清前两个、**置第三个**；
  ///   * 跳过中且参数非 0 ⇒ 把状态翻成 `EV_STATE_FADEDIN`（`:78-79`）。
  /// 位值见 `include/event.h:59-61`。其余参数值**未读** ⇒ 生成器保持占位符。
  void modifyEvBit(int type) {
    if (skipping && type != 0) {
      evStateBits =
          (evStateBits & ~kEvStateSkipping) | kEvStateFadedIn;
    }
    switch (type) {
      case 0:
        evStateBits &= ~(kEvStateNoSkip | kEvState0020 | kEvState0040);
      case 1:
        evStateBits |= kEvStateNoSkip | kEvState0020 | kEvState0040;
      case 2:
        evStateBits &= ~(kEvStateNoSkip | kEvState0020);
        evStateBits |= kEvState0040;
    }
  }

  /// `COUNTER_CHECK`：写条件槽 **0xC**，**不回写**计数器（源码 `case 0` 里直接 `return 0`）
  void counterCheck(int idx) => setSlot(0xC, eventCounterGet(eventSlotCounter, idx));

  void counterSet(int idx, int value) {
    eventSlotCounter = eventCounterPut(eventSlotCounter, idx, value);
  }

  void counterInc(int idx) {
    eventSlotCounter = eventCounterInc(eventSlotCounter, idx);
  }

  void counterDec(int idx) {
    eventSlotCounter = eventCounterDec(eventSlotCounter, idx);
  }

  /// `CUMO_CHAR` = `EvtDisplayCursorAtUnit(pid)`（`include/EAstdlib.h:166`；
  /// `src/Event3B_DisplayCursor.c:51-59`）：把**场景光标**画到那个单位所在的格。
  /// ⚠️ 这是**场景光标**（`ProcScr_EventDisplayCursor`），不是玩家的地图光标。
  /// 找不到单位 ⇒ 源码是 `EVC_ERROR` ⇒ 我们记一次 `scriptErrors`。
  void displayCursorAtUnit(int pid) {
    if (unitAliveReader == null) {
      scriptErrors++;
      return;
    }
    onEvent(DisplayCursorAtUnit(pid));
  }

  /// `CAMERA_CAHR` = `EvtMoveCameraToChar(pid)`（`include/EAstdlib.h:99`）
  ///
  /// **复用**既有的 [cameraTo]（普通 `CAMERA`/`CAMERA2` 早就走它了）：
  /// 场景不持有单位表 ⇒ 发事件让游戏把角色坐标算出来再调 `cameraTo`。
  void cameraToChar(int pid) => onEvent(CameraToChar(pid));

  /// `CHECK_LUCK` = `EvtGetUnitLuck`（`include/EAstdlib.h:133`；
  /// `src/Event33_CheckUnitVarious.c:147-153`）：**找不到单位 ⇒ 报错**（不是写 0！），
  /// 否则把幸运值写进条件槽。
  void checkLuck(int pid) {
    final r = unitLuckReader;
    if (r == null) {
      // 没注入读幸运的钩子 —— 记一次**脚本错误**（源码是 `EVC_ERROR`），
      // 并**不**写条件槽（写 0 会让后面的分支走错方向）。
      scriptErrors++;
      return;
    }
    final v = r(pid);
    if (v == null) {
      scriptErrors++; // 源码：找不到单位 ⇒ EVC_ERROR（不写条件槽）
      return;
    }
    setSlot(0xC, v);
  }

  /// `BROWNBOXTEXT` = `EvtDisplayPopupSilently(msg, x, y)`
  /// （`include/eventscript.h:732`；处理函数 `src/Event3A_DisplayPopup.c:11-40`）
  ///
  /// 跳过中不弹（`:16-19`）；弹窗**自己计时结束**（"Silently" = 不等按键）。
  /// 注意：40 处能接（x/y 都在 0..0xFF），**1 处参数不是坐标** ⇒ 那一处仍是占位符。
  Future<void> popupText(int textId, int x, int y) =>
      onEvent(PopupText(textId: textId, x: x, y: y));

  /// `REMU`/`REVEAL`/`SET_STATE`：**单单位**状态（`Event34_MessWithUnitState`）
  ///
  /// `arg` 是 `GetUnitStructFromEventParameter` 的入参（**角色编号**；负数 = 事件槽 2）。
  /// 场景不持有单位表 ⇒ 发一个 [UnitStateOp] 事件，由游戏侧解析并施加
  /// （`unitStateOp(...)` 在核心层，可测）。
  void unitStateOp(String kind, int arg) =>
      onEvent(UnitStateOp(kind: kind, arg: arg));

  /// `CLEA`/`CLEN`/`CLEE`：把某个阵营的单位全部"藏起来"
  ///
  /// 出处：`src/eventscr_080103F4.c:60-135`（`Event34_MessWithUnitState`）——
  /// `CLEA` 遍历**蓝色**阵营、`CLEN` 绿色、`CLEE` 红色；
  /// "remove" 用的状态位与 `REMU` 相同（`US_HIDDEN | US_BIT16 | US_BIT26`，`:110-111`）。
  void hideFaction(String faction) => onEvent(HideFaction(faction));

  /// `TEXTEND` = `EvtTextWaitLock`（`EV_CMD_ENDTEXT`，`include/eventscript.h:664`）
  ///
  /// 语义是"**等文本锁定**"（显示完）。我们的 [textShow] 本来就是逐页 `await` 的，
  /// 所以这里没有"未完成的文本"要等；但它**不是空操作** —— 它发一个 [EndText] 事件，
  /// 游戏据此收起/锁定文本框（原作这一支就是干这个的）。
  Future<void> textEnd() => onEvent(EndText(currentScript));

  /// `REMA` = `EvtTextRemoveAll`（`EV_CMD_DISPLAYTEXT` subcmd 2，`include/eventscript.h:662`）
  void textRemoveAll() => onEvent(RemoveAllText(currentScript));

  /// `TEXTSHOW(id)` —— 显示文字；文本里有 `[A]` 就等玩家按键
  Future<void> textShow(int textId) async {
    if (texts.byId(textId) == null) {
      missing.add('text:0x${textId.toRadixString(16)}');
      return;
    }
    // **汉化在这里生效**：有译文就用译文，段数不符自动退回原文
    // （见 `GameTexts.localized`）—— 所以译错一条不会让游戏显示错版，
    // 只会那一句仍是日文。
    final m = texts.localized(textId);
    // ⚠️ **一页一页地演**，不是整条消息一口气画出来。
    //
    // 一条消息里 `[A]` / `[CR]` 把正文切成多页（序章开场那条就有好几页）。
    // 第一版不分页，结果只显示前两行、后面全被裁掉。
    final pages = m.pageSpans;
    if (pages.isEmpty) {
      await onEvent(ShowText(
        message: m,
        scriptName: currentScript,
        step: 0,
      ));
      return;
    }
    for (var i = 0; i < pages.length; i++) {
      await onEvent(ShowText(
        message: m,
        scriptName: currentScript,
        step: 0,
        page: pages[i].$1,
        // ⚠️ 页界**按 token 序号**给，下游不再"拿文字反查" —— 见 pageSpans 的说明
        upto: pages[i].$2,
        pageIndex: i,
        pageCount: pages.length,
      ));
      // ⚠️ **只有 `[A]` 才等按键，`[CR]` 不等。**
      //
      // 原作：
      //   * `[A]`(3)  → `StartTalkWaitForInput`（`src/TalkInterpret.c:99-108`）**等**
      //   * `[CR]`(2) → `Proc_StartBlocking(gProcScr_TalkShiftClearAll)`
      //     （`:86-97`），滚动清屏完就继续 —— **不等按键**
      //     （`src/TalkShiftClearAll_OnIdle.c:21-33`）
      //
      // 我原来对**每一页**都 `await WaitForInput` —— 每个非空 `[CR]` 页
      // 都会多要一次按键（全量 395 处；播放集 53 条消息含 `[CR]`）。
      //
      // 另外：2127/3339 条消息**没有 `[A]`**，它们也不该在最后等按键。
      if (m.isWaitForKeyAt(pages[i].$2)) {
        await onEvent(WaitForInput(currentScript, 0));
      }
    }
  }

  void loadUnits(int group, Sym table) {
    onEvent(LoadUnits(table.name, group));
  }

  void moveUnit(String op, List<Object> args) {
    onEvent(MoveUnitInScene(op, args));
  }

  /// 把槽里的道具给角色（`GIVEITEMTO`）
  Future<void> giveItem(int pid, int itemSlot) =>
      onEvent(GiveItem(pid: pid, itemSlot: itemSlot));

  /// 换章节 —— 序章结束时会切到第 1 章
  ///
  /// `subcmd` 默认 `2`（`MNC2`）：直接进地图。`MNCH`(1) 要**先走大地图**，
  /// 见 [ChangeChapter.subcmd]。
  Future<void> changeChapter(int chapterIndex, {int subcmd = 2}) => onEvent(
        ChangeChapter(
            chapterIndex: chapterIndex,
            scriptName: currentScript,
            subcmd: subcmd),
      );

  /// `IGNORE_KEYS`（`EvtSetKeyIgnore`，`include/eventscript.h:623`）
  /// ⇒ `SetKeyStatus_IgnoreMask(mask)`（`src/SetKeyStatus_IgnoreMask.c:7-10`：
  /// 就是把参数存进 `gKeyStatusIgnoredSt`）。
  ///
  /// 位值来自 `include/gba/io_reg.h:663-672`（见 [keyBit]）。游戏在输入入口查这个掩码。
  int ignoredKeyMask = 0;

  /// ⚠️ **发事件**而不是只改自己的字段：输入的所有者是**游戏**层，
  /// 场景存一份没有意义（游戏查不到）。两处都留（场景侧供转储、游戏侧真正生效）。
  void setKeyIgnore(int mask) {
    ignoredKeyMask = mask;
    onEvent(KeyIgnore(mask));
  }

  /// `STAL` / `STAL1` / `STAL2`：按帧等待（`EV_CMD_STALL`，`src/eventscr_0800DD9C.c:9-31`）
  ///
  /// * 跳过中（`skipping`）⇒ **不等待**（`:16-20`）；
  /// * `cancellable`（`STAL1` = `EvtSleepWithCancel`）⇒ B 键或跳过位可提前结束（`:22-23`）；
  /// * `STAL2`（`EvtSleepWithGameCtrl`）不可取消 ⇒ 默认 [cancellable] = false。
  Future<void> stall(int frames, {bool cancellable = false}) =>
      onEvent(Stall(frames, cancellable: cancellable));

  /// `DISA(pid)` —— 把单位从地图上拿掉。
  ///
  /// 出处：`src/Event34_MessWithUnitState`（`src/eventscr_080103F4.c:217-223`）
  ///
  /// ```c
  /// case EVSUBCMD_DISA:
  ///     ClearUnit(unit);          // ★ 连槽位一起清掉
  ///     break;
  /// ```
  ///
  /// [onlyIfDead] 对应 `DISA_IF`（`:212-217`：先等死亡淡出再落到同一个分支）。
  Future<void> removeUnit(int pid, {bool onlyIfDead = false}) =>
      onEvent(RemoveUnit(pid: pid, onlyIfDead: onlyIfDead));

  /// `SET_HP(pid)` —— HP **从槽 1 取**（`EvtSetUnitHpFormSlot1`）。
  ///
  /// 出处：`src/eventscr_080103F4.c:127-132`
  ///
  /// ```c
  /// case EVSUBCMD_SET_HP:
  ///     SetUnitHp(unit, gEventSlots[1]);
  ///     if (gEventSlots[1] == 0) unit->state |= US_DEAD;
  /// ```
  Future<void> setUnitHpFromSlot(int pid) => onEvent(SetUnitHp(pid: pid));

  /// `CURSOR_CHAR(pid)` / `CURSOR_FLASHING_CHAR(pid)` —— 把演出光标放到单位身上。
  ///
  /// 出处：`src/Event3B_DisplayCursor.c:22-80`
  Future<void> showCursorAtUnit(int pid, {bool flashing = false}) =>
      onEvent(ShowCursor(pid: pid, flashing: flashing));

  /// `DISPLAYCURSOR(x, y)` / `CURSOR_FLASHING(x, y)` —— 光标直接放到坐标上。
  Future<void> showCursorAt(int x, int y, {bool flashing = false}) =>
      onEvent(ShowCursor(x: x, y: y, flashing: flashing));

  /// `CURE`（= `EvtEndCursor`）—— 结束演出光标。
  ///
  /// 出处：`src/Event3B_DisplayCursor.c:56-58`
  ///
  /// ```c
  /// case EVSUBCMD_CURE:
  ///     Proc_EndEach(ProcScr_EventDisplayCursor);
  /// ```
  Future<void> endCursor() => onEvent(const EndCursor());

  /// `ENUN`（= `EvtWaitUnitMoving`）—— 等所有单位走完。
  ///
  /// ⚠️ **本实现是个显式空操作**：`_moveUnitInScene` 是瞬移，没有行走过程。
  /// 但仍然把它做成一个事件（而不是占位符）—— 这样棘轮上的数字说实话，
  /// 将来接上行走动画时也只改这一处。
  Future<void> waitUnitMoving() => onEvent(const WaitUnitMoving());

  /// 换地图（`LOMA`）。操作数是 **chapterIndex**（`src/eventscr_0800F390.c:54`）。
  Future<void> loadMap(int chapterIndex) =>
      onEvent(LoadMap(chapterIndex: chapterIndex, scriptName: currentScript));

  /// 相机取景（`CAMERA(x, y)` / `CAMERA2(x, y)`）。
  ///
  /// 出处：`src/Event26_CameraControl`（`src/eventscr_0800F41C.c:10-62`）
  ///
  /// ```c
  /// case 0: // position
  ///     x = EVT_CMD_ARGV(proc->pEventCurrent)[0];        // 低字节
  ///     y = EVT_CMD_ARGV(proc->pEventCurrent)[0] >> 8;   // 高字节
  ///     if (x < 0 || y < 0) {                            // 负数 = 用槽 0xB
  ///         x = ((u16 *)(gEventSlots + 0xB))[0];
  ///         y = ((u16 *)(gEventSlots + 0xB))[1];
  ///     }
  /// ```
  ///
  /// [centered] 就是 sub-cmd 的 bit3（`EVT_SUB_CMD_HI`，`include/event.h:135`）：
  /// `CAMERA` 不置位（走 `GetCameraAdjusted*`），`CAMERA2` 置位（走 `GetCameraCentered*`）。
  Future<void> cameraTo(int x, int y, {bool centered = false}) =>
      onEvent(CameraControl(x: x, y: y, centered: centered));

  /// 淡入/淡出。
  ///
  /// ⚠️ **缩写名是反的** —— 看 `src/Event17_Fade.c`：
  ///
  ///     case 0: // FADU
  ///         StartLockingFadeFromBlack(...);   // 从黑淡出 → 画面出现
  ///     case 1: // FADI
  ///         StartLockingFadeToBlack(...);     // 淡到黑 → 画面消失
  ///
  /// 按缩写猜会**正好做反**。生成器里也是显式映射，不靠名字。
  ///
  /// 四个分支都返回 `EVC_ADVANCE_YIELD` —— **脚本阻塞到淡完为止**。
  Future<void> fade(FadeDirection dir, int speed) =>
      onEvent(Fade(dir: dir, speed: speed, scriptName: currentScript));

  /// 认得但本阶段不执行的调用（`CURSOR_CHAR` / `MUSI` / `CHECK_TUTORIAL`…）
  void placeholder(String op) {
    placeholderCalls[op] = (placeholderCalls[op] ?? 0) + 1;
  }

  /// **场景内的局部位**（`proc->evStateBits`，`src/Event02_EvBitAndIdMod.c:14-38`）
  ///
  /// ⚠️ 这是**场景局部**的位（32 位），**不是**章节旗：
  ///   * `EVBIT_T` / `EVBIT_F` 动的就是它（`sub_cmd_lo == 0`）；
  ///   * `ENUT` / `ENUF` 动的是**章节旗**（`SetFlag` / `ClearFlag`，`sub_cmd_lo == 1`）
  ///     —— 那才是我们也有的 `eventFlags`。
  /// `arg < 0` 时取**事件槽 2**（`gEventSlots[2]`）。
  int evStateBits = 0;

  /// 读章节旗的**注入点**（`CheckFlag`）。
  ///
  /// 场景本身**不持有**旗（旗在游戏侧 `eventFlags` 里）⇒ 由调用方注入一个读旗器；
  /// 没注入时退回"本场景自己置过的那几个"（`_flagsSetHere`），并在
  /// [flagsReadWithoutReader] 里计数 —— 免得"读不到"被当成"旗没置位"。
  bool Function(int flag)? flagReader;
  final Set<int> _flagsSetHere = {};
  int flagsReadWithoutReader = 0;

  /// `CHECK_ALIVE` 没注入读单位器时的计数
  int checksWithoutReader = 0;

  bool flagIsSet(int flag) {
    final r = flagReader;
    if (r != null) return r(flag);
    flagsReadWithoutReader++;
    return _flagsSetHere.contains(flag);
  }

  /// `CHECK_EVBIT` / `CHECK_EVENTID`：把结果写进**条件槽** `gEventSlots[0xC]`
  /// （`src/Event03_CheckEvBitOrId.c:14-33`），随后由 `BEQ`/`BNE` 消费。
  /// `gPlaySt.chapterTurnNumber`（由游戏侧更新；`CHECK_TURNS` 要用）
  int turnNumber = 1;

  /// `gPlaySt.chapterModeIndex`（`CHECK_MODE` 用；1=教学/艾莉卡、2=Ephraim…）
  int chapterModeIndex = 1;

  /// `proc->chapterIndex`（`CHECK_CHAPTER_NUMBER` 用）
  int chapterIndex = 0;

  /// `gPlaySt.chapterStateBits & PLAY_FLAG_HARD`（`CHECK_HARD` 用）
  bool isHard = false;

  /// `gPlaySt.config.controller`（`CHECK_TUTORIAL` 用）
  bool controllerConfig = false;

  /// 红方 / 绿方的**在场**单位数（`CountRedUnits` / `CountGreenUnits`），由游戏侧更新
  int redUnitCount = 0;
  int greenUnitCount = 0;

  /// 读某角色的幸运值（`CHECK_LUCK` 用）。返回 null 表示**找不到这个单位**
  /// （源码在那一支是 `EVC_ERROR`，所以"找不到"不能退化成 0）
  int? Function(int pid)? unitLuckReader;

  /// 脚本层报错的次数（源码里 `EVC_ERROR` 的地方；比静默写 0 更有用）
  int scriptErrors = 0;

  /// 这个角色还活着吗（`GetUnitStructFromEventParameter` + `US_DEAD` 判定）。
  /// 场景不持有单位表 => 由游戏侧注入；注入不了就按源码的 `!unit => 0` 处理，
  /// 并在 [checksWithoutReader] 里**计数**（不把读不到当成不活着）。
  bool Function(int pid)? unitAliveReader;

  /// `CHECK_TURNS` / `CHECK_ENEMIES` / `CHECK_OTHERS`：把**数值**写进条件槽
  void checkSlotValue(String kind) {
    final v = switch (kind) {
      'turn' => turnNumber,
      // 第三批（`src/eventscr_0800E2C8.c:77-87`）
      'mode' => chapterModeIndex,
      'chapter' => chapterIndex,
      'hard' => isHard ? 1 : 0,
      // `CHECK_TUTORIAL`（`src/eventscr_0800E2C8.c:109-115`）：
      // slot 0xC = !(config.controller || hard)
      'tutorial' => (controllerConfig || isHard) ? 0 : 1,
      'redCount' => redUnitCount,
      'greenCount' => greenUnitCount,
      _ => 0,
    };
    setSlot(0xC, v);
  }

  void checkSlot(String kind, int arg) {
    final a = arg < 0 ? slotInt(2) : arg;
    final bool v;
    switch (kind) {
      case 'evbit':
        v = evBit(a);
      case 'flag':
        v = flagIsSet(a);
      case 'alive':
        // src/Event33_CheckUnitVarious.c:69-81：找不到单位 => 0；US_DEAD => 0
        final r = unitAliveReader;
        if (r == null) {
          checksWithoutReader++;
          v = false;
        } else {
          v = r(a);
        }
      default:
        v = false;
    }
    setSlot(0xC, v ? 1 : 0);
  }

  void evBitMod(String kind, bool set, int arg) {
    var a = arg;
    if (a < 0) a = slotInt(2);
    if (kind == 'flag') {
      if (set) {
        _flagsSetHere.add(a);
      } else {
        _flagsSetHere.remove(a);
      }
      onEvent(SetEventFlag(flag: a, value: set));
    } else if (set) {
      evStateBits |= 1 << a;
    } else {
      evStateBits &= ~(1 << a);
    }
  }

  /// `CHECK_EVBIT` / `CHECK_EVENTID` 读的那一位（`src/Event03_CheckEvBitOrId.c:14-33`）
  bool evBit(int arg) {
    final a = arg < 0 ? slotInt(2) : arg;
    return ((evStateBits >> a) & 1) == 1;
  }

  void noteUnmapped(RawArg a) => unmappedArgs.add(a.text);
}


