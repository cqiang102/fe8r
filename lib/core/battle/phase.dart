// PORT OF: src/bmphase.c + include/bmunit.h（阵营与状态位）
//
// 回合/阵营的判定逻辑。**这是规则层，必须 1:1 移植。**
//
// 看起来只是几个位运算，但它们是"这一回合谁还能动"的唯一判据：
// 漏掉一个状态位，就会让被救出/未出击/在屋顶下的单位变得可以行动；
// 阵营掩码写错一位，敌方回合就会把友军也一起驱动。
//
// 全部由 C Oracle 逐值锁定，见 test/core/battle_oracle_test.dart。

/// 阵营（`FACTION_*`）
class Faction {
  /// 玩家单位
  static const int blue = 0x00;

  /// 友军 NPC
  static const int green = 0x40;

  /// 敌军
  static const int red = 0x80;
}

/// 单位状态位（`US_*`）
class UnitState {
  static const int unselectable = 1 << 1;
  static const int dead = 1 << 2;
  static const int notDeployed = 1 << 3;
  static const int rescued = 1 << 5;
  static const int underARoof = 1 << 7;
  static const int bit16 = 1 << 16;
}

/// 异常状态（`UNIT_STATUS_*`）
class UnitStatus {
  static const int none = 0;
  static const int sleep = 2;
  static const int berserk = 4;
}

/// 职业属性位（`CA_*`）
class ClassAttribute {
  static const int unselectable = 1 << 20;
}

/// `GetPhaseAbleUnitCount` 里那个"不能行动"的掩码。
///
/// 单独抽出来是为了让它**可被测试直接引用**——这 6 个位就是"这一回合
/// 谁还能动"的全部判据，少一个都会让不该动的单位动起来。
const int phaseNotAbleMask = UnitState.unselectable |
    UnitState.dead |
    UnitState.notDeployed |
    UnitState.rescued |
    UnitState.underARoof |
    UnitState.bit16;

/// 阵营判定所需的最小单位视图。
///
/// 刻意不复用完整的 `Unit` 模型：这段逻辑只碰这 4 个字段，
/// 依赖越窄越容易构造用例，也越不容易在别处被误改。
class PhaseUnit {
  PhaseUnit({
    required this.faction,
    this.state = 0,
    this.statusIndex = UnitStatus.none,
    this.classAttributes = 0,
    this.hasCharacterData = true,
  });

  /// `UNIT_FACTION`：低 7 位是编号，高位是阵营
  final int faction;

  /// `unit->state`
  final int state;

  /// `unit->statusIndex`
  final int statusIndex;

  /// `UNIT_CATTRIBUTES(unit)`：角色属性 | 职业属性
  final int classAttributes;

  /// `UNIT_IS_VALID` 要求 `pCharacterData` 非空
  final bool hasCharacterData;

  /// 阵营位（`faction & 0x80`）
  int get factionBit => faction & 0x80;

  /// 阵营大类（`faction & 0xC0`）
  int get allegianceBits => faction & 0xC0;
}

/// 阵营与阶段判定。
class PhaseRules {
  const PhaseRules._();

  /// `AreUnitsAllied(left, right)`
  ///
  /// ⚠️ 只看 `0x80` 这一位：玩家与友军 NPC 算"同盟"，敌军不算。
  static bool areUnitsAllied(int left, int right) =>
      (left & 0x80) == (right & 0x80);

  /// `IsSameAllegiance(left, right)`
  ///
  /// 看 `0xC0` 两位：把玩家(0x00)与友军(0x40)区分开。
  /// 与 [areUnitsAllied] 的区别就在这里——"同盟"不等于"同一阵营"，
  /// 混用会导致友军 NPC 被当成玩家单位来驱动。
  static bool isSameAllegiance(int left, int right) =>
      (left & 0xC0) == (right & 0xC0);

  /// `GetCurrentPhase` —— 当前是谁的回合
  static int getCurrentPhase(int playStFaction) => playStFaction & Faction.red;

  /// `GetNonActiveFaction`
  static int getNonActiveFaction(int playStFaction) =>
      (playStFaction & Faction.red) ^ Faction.red;

  /// `GetPhaseAbleUnitCount(faction)`
  ///
  /// 遍历 `[faction + 1, faction + 0x40)` 这段编号，统计**还能行动**的单位。
  ///
  /// 编号范围本身就是判据的一部分：每个阵营占 0x40 个编号槽，
  /// 用阵营基址偏移来取，不是"遍历所有单位再按阵营过滤"。
  static int getPhaseAbleUnitCount(
    List<PhaseUnit?> units,
    int faction,
  ) {
    var count = 0;
    for (var id = faction + 1; id < faction + 0x40; id++) {
      if (id < 0 || id >= units.length) continue;
      final unit = units[id];
      if (!_isValid(unit)) continue;

      final u = unit!;
      if (u.state & phaseNotAbleMask != 0) continue;
      if (u.statusIndex == UnitStatus.sleep) continue;
      if (u.statusIndex == UnitStatus.berserk) continue;
      if (u.classAttributes & ClassAttribute.unselectable != 0) continue;

      count += 1;
    }
    return count;
  }

  /// `CountUnitsInState(faction, state)`
  ///
  /// ⚠️ 语义是"**不处于**该状态的单位数"（C 里是 `if (!(state & state))`），
  /// 不是"处于该状态的单位数"。函数名很容易让人写反。
  static int countUnitsInState(
    List<PhaseUnit?> units,
    int faction,
    int state,
  ) {
    var count = 0;
    for (var id = faction + 1; id < faction + 0x40; id++) {
      if (id < 0 || id >= units.length) continue;
      final unit = units[id];
      if (!_isValid(unit)) continue;
      if (unit!.state & state == 0) count += 1;
    }
    return count;
  }

  /// `UNIT_IS_VALID`：单位存在**且**有角色数据
  static bool _isValid(PhaseUnit? u) => u != null && u.hasCharacterData;
}
