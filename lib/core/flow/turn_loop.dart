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

/// `PlayerPhase_HandleAutoEnd`
///
/// 当前阶段没有任何可行动单位时，自动结束该阶段。
///
/// ⚠️ 判据是 **`GetPhaseAbleUnitCount(faction) == 0`**，
/// 也就是"**当前阶段阵营**还有没有能动的单位"，
/// 不是"还有没有我方单位"。这两个在敌方/NPC 阶段完全不同。
bool shouldAutoEndPhase(BattleField field, {bool disableAutoEndTurns = false}) {
  if (disableAutoEndTurns) return false;
  return field.phaseAbleCount(field.activeFaction) == 0;
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

/// 推进到下一个**有单位可行动**的阶段，最多探测若干轮。
///
/// 原版是在 Proc 里逐阶段跳的；这里做成一步到位的循环，
/// 但**判据与 SwitchPhases 完全一致**——跳过哪些阶段由
/// [shouldAutoEndPhase] 决定，不是另写一套。
///
/// 返回实际切换的次数（0 表示所有阶段都空，调用方应视为僵局）。
int advanceToNextActivePhase(
  BattleField field, {
  bool disableAutoEndTurns = false,
  int maxHops = 3,
}) {
  var hops = 0;
  for (var i = 0; i < maxHops; i++) {
    // ★ 先清**当前**阵营的灰化（= 它的阶段结束），再切阵营。
    // 顺序与 `BmMain_ChangePhase` 一致（`src/bm_08015434.c:85-87`）。
    beginPhase(field);
    switchPhases(field);
    hops += 1;
    if (!shouldAutoEndPhase(field, disableAutoEndTurns: disableAutoEndTurns)) {
      return hops;
    }
  }
  return hops;
}
