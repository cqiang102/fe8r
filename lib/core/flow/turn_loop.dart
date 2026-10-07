// PORT OF: src/bm_080153B0.c 的 SwitchPhases（FE8U = 0x0801538C）
//          + src/playerphase_0801D808.c 的 PlayerPhase_HandleAutoEnd
//
// 回合推进与自动结束。
//
// ## SwitchPhases 的两个坑
//
// 1. **回合数不是每次切换都加**，只在 GREEN 绕回 BLUE 时加一次。
//    写成"切一次加一次"会让回合数变成实际的三倍。
// 2. 回合数有 **999 上限**，到顶后不再增长。
//
// 顺序是 蓝 → 红 → 绿 → 蓝，即 我方 → 敌方 → 友军 NPC。
// 注意：即使场上没有友军 NPC，阶段**依然会经过 GREEN** ——
// 这是 SwitchPhases 的行为，跳过空阶段的逻辑在别处（见 shouldAutoEndPhase）。

import 'battle_field.dart';
import '../battle/phase.dart';

/// `FACTION_*` 的完整取值（含编号位）
class TurnFaction {
  static const int blue = Faction.blue;
  static const int green = Faction.green;
  static const int red = Faction.red;
}

/// `gPlaySt.chapterTurnNumber` 的上限
const int maxTurnNumber = 999;

/// `SwitchPhases`
///
/// 返回切换后的 `(faction, turnNumber)`。
int switchPhasesFaction(int faction) {
  switch (faction) {
    case Faction.blue:
      return Faction.red;
    case Faction.red:
      return Faction.green;
    case Faction.green:
      return Faction.blue;
    default:
      // 未知阵营：原版 switch 没有 default，会**保持原值**
      return faction;
  }
}

/// `SwitchPhases` 里对回合数的处理：只有绕回 BLUE 时才递增，且封顶 999。
///
/// 单独抽出来是为了让"什么时候加"这件事在调用点一眼可见——
/// 把它混进阵营切换的分支里，是这类 bug 最常见的藏身处。
int switchPhasesTurn(int faction, int turn) {
  if (faction != Faction.green) return turn;
  if (turn < maxTurnNumber) return turn + 1;
  return turn;
}

/// 推进一个回合阶段。原地修改 [field]。
void switchPhases(BattleField field) {
  final prev = field.activeFaction;
  field.activeFaction = switchPhasesFaction(prev);
  field.turn = switchPhasesTurn(prev, field.turn);
}

/// `PlayerPhase_HandleAutoEnd`（`src/playerphase_0801D808.c:52-58`）
/// ＋ 敌方 / 友军 NPC 阶段的"没人就结束"
///
/// 判据是 **`GetPhaseAbleUnitCount(当前阶段阵营) == 0`**，
/// 也就是"**当前阶段阵营**还有没有能动的单位"，
/// 不是"还有没有我方单位"。这两个在敌方/NPC 阶段完全不同。
///
/// ⚠️ `disableAutoEndTurns` **只对我方阶段有效**。
/// 全作只有 `PlayerPhase_HandleAutoEnd` 一处读它
/// （`grep -rn disableAutoEndTurns src/` 一共 5 处：初始化、这一处、設定屏的读与写）。
/// 敌方 / 友军 NPC 阶段跑的是 `gProcScr_CpPhase`
/// （`src/data/data_085D1E10/data_085D1E10.c:20-25` = `AiPhaseInit; YIELD; AiPhaseCleanup; END`）
/// —— AI 把单位跑完就 `Proc_End`（`src/CpDecide_Main.c:78`），**与这个开关无关**。
///
/// 把它套到所有阵营上有一个很具体的后果：关掉自动结束后，
/// **没有敌人的阶段（比如序章的绿色阶段）也会停下来等人**，整局卡住。
bool shouldAutoEndPhase(BattleField field, {bool disableAutoEndTurns = false}) {
  if (field.activeFaction == Faction.blue && disableAutoEndTurns) return false;
  return field.phaseAbleCount(field.activeFaction) == 0;
}

/// **一次阶段切换** = `BmMain_ChangePhase` 的纯逻辑部分
/// （`src/bm_08015434.c:82-95`，去掉里面那次 `RunPhaseSwitchEvents`）：
///
/// ```c
/// int BmMain_ChangePhase(void) {
///     ClearActiveFactionGrayedStates();   // ← 清**当前**（即将结束的）阵营
///     RefreshUnitSprites();
///     SwitchPhases();                     // ← 离开 GREEN 时回合 +1
///     if (RunPhaseSwitchEvents() == true) // ← ★ 这一步在**里面**
///         return false;
///     return true;
/// }
/// ```
///
/// 返回"这个新阶段会不会**自己**结束"。
///
/// ⚠️ **调用方必须在每一步之后跑一次 `RunPhaseSwitchEvents`** ——
/// 原作里它就在 `BmMain_ChangePhase` 内部，也就是**每一次阶段切换都跑**，
/// 包括那些"一个人都没有、下一个循环就被跳过"的阶段。
/// 我原来把"跳过空阶段"折成一个循环、循环外只跑一次事件 ——
/// 于是**被跳过阶段的回合事件永远不触发**。
bool stepPhase(BattleField field, {bool disableAutoEndTurns = false}) {
  beginPhase(field); // `ClearActiveFactionGrayedStates`（清即将结束的那个阵营）
  switchPhases(field); // `SwitchPhases`（离开 GREEN 时回合 +1）
  return shouldAutoEndPhase(field, disableAutoEndTurns: disableAutoEndTurns);
}

/// 清掉**当前**阵营的灰化标记。
///
/// 对应 `ClearActiveFactionGrayedStates`（`src/ClearActiveFactionGrayedStates.c:29`）：
///
/// ```c
/// for (i = gPlaySt.faction + 1; i < gPlaySt.faction + 0x40; ++i) {
///     struct Unit* unit = GetUnit(i);
///     if (UNIT_IS_VALID(unit))
///         unit->state &= ~(US_UNSELECTABLE | US_HAS_MOVED | US_HAS_MOVED_AI);
/// }
/// ```
///
/// ## ⚠️ 它是**阶段结束时**调的，不是开始时
///
/// `src/bm_08015434.c:82-95` `BmMain_ChangePhase`：
///
/// ```c
/// ClearActiveFactionGrayedStates();   // ← 清的是**当前**（即将结束的）阵营
/// RefreshUnitSprites();
/// SwitchPhases();                     // ← 然后才切阵营
/// ```
///
/// 于是每个阵营的灰化都在**自己阶段结束时**被清掉，轮到它时自然都能动。
/// 我原来的注释写的是"必须在每个阶段开始时调用"，实现的也是"清**新**阵营、
/// 而且只在它还有能动的人时才清" —— 后果是**被跳过的阵营永远保持全灰**：
/// 第 2 回合起敌人一步都不动（第 1 回合是正常的，因为单位刚载入还没灰）。
void beginPhase(BattleField field) {
  field.clearActiveFactionGrayedStates();
}

/// 纯逻辑版：一路切到**下一个有单位可行动**的阶段，返回切换次数。
///
/// ⚠️ 这个函数**不跑 `RunPhaseSwitchEvents`** —— 只适合纯 Dart 的测试。
/// 游戏层请用 [stepPhase] **逐阶段**走，每走一步跑一次回合事件
/// （原作 `RunPhaseSwitchEvents` 就在 `BmMain_ChangePhase` 里面，
/// `src/bm_08015434.c:88-90`）。
///
/// 保留它是因为 `turn_loop_test.dart` 用它验"跳过哪些阶段"这条判据；
/// 真机上那条判据由 `scenario.sh turnend` 的 `phaseSwitchEventRuns==6` 覆盖。
int advanceToNextActivePhase(
  BattleField field, {
  bool disableAutoEndTurns = false,
  int maxHops = 3,
}) {
  var hops = 0;
  for (var i = 0; i < maxHops; i++) {
    final autoEnd =
        stepPhase(field, disableAutoEndTurns: disableAutoEndTurns);
    hops += 1;
    if (!autoEnd) return hops;
  }
  return hops;
}
