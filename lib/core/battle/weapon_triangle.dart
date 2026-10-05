// PORT OF: src/BattleApplyWeaponTriangleEffect.c + src/BattleApplyReaverEffect.c
//          + src/bmbattle_0802AB1C.c (ComputeBattleUnitHitRate)
//          + src/GetItemHit.c
//
// 武器三角与命中率。
//
// ## 武器三角
//
// 剑 > 斧 > 枪 > 剑；魔法侧 理 > 光 > 暗 > 理。
// 优势方 +15 命中 / +1 攻击，劣势方取负。
//
// **规则表不是 C 源码**：`sWeaponTriangleRules` 被绑成一个 ABS 符号指向
// carve 出来的 ROM 数据块（`layout/baseline_syms.d/data_bmbattle_wtriangle.tsv`），
// 所以它由 `tools/pipeline/extract/parse_carved_tables.py` 从原始字节提取，
// 并用结构自洽性（终止符位置、武器类型范围、加成必须成对且符号一致）校验。
//
// ## 勇者武器（Reaver）
//
// `IA_REVERTTRIANGLE` 的武器把三角**反转**：不是简单取负，而是
// `-(x * 2)` —— 因为基础值已经加过一次了，反转等于把"优势"变成"劣势"。
// 而且**双方都带 Reaver 时互相抵消，谁都不反转**（前两个 if 是一起判的）。

import 'battle_unit.dart';

/// `ITYPE_*` —— 武器类型
class WeaponType {
  static const int sword = 0;
  static const int lance = 1;
  static const int axe = 2;
  static const int bow = 3;
  static const int staff = 4;
  static const int anima = 5;
  static const int light = 6;
  static const int dark = 7;
}

/// `IA_REVERTTRIANGLE` —— 勇者武器属性位
const int iaRevertTriangle = 1 << 8;

/// 一条武器三角规则（对应 `struct WeaponTriangleRule`）
class WeaponTriangleRule {
  const WeaponTriangleRule({
    required this.attackerWeaponType,
    required this.defenderWeaponType,
    required this.hitBonus,
    required this.atkBonus,
  });

  final int attackerWeaponType;
  final int defenderWeaponType;
  final int hitBonus;
  final int atkBonus;
}

/// 武器三角规则表。
///
/// 终止条件是 `attackerWeaponType < 0`（与 C 的 `it->attackerWeaponType >= 0`
/// 循环条件一致），**不是靠数组长度**。
class WeaponTriangleTable {
  WeaponTriangleTable(this.rules);

  final List<WeaponTriangleRule> rules;

  factory WeaponTriangleTable.fromJson(Map<String, dynamic> json) {
    final list = (json['rules'] as List<dynamic>)
        .map((e) => e as Map<String, dynamic>)
        .map((m) => WeaponTriangleRule(
              attackerWeaponType: m['attackerWeaponType'] as int,
              defenderWeaponType: m['defenderWeaponType'] as int,
              hitBonus: m['hitBonus'] as int,
              atkBonus: m['atkBonus'] as int,
            ))
        .toList();
    return WeaponTriangleTable(list);
  }

  /// `BattleApplyWeaponTriangleEffect`
  ///
  /// 注意 `wTriangleHitBonus` / `wTriangleDmgBonus` 是 `s8`，加法会截断；
  /// 反转时的 `-(x*2)` 同样按 s8 存。
  void apply(BattleUnit attacker, BattleUnit defender) {
    for (final r in rules) {
      if (attacker.weaponType == r.attackerWeaponType &&
          defender.weaponType == r.defenderWeaponType) {
        attacker.wTriangleHitBonus = r.hitBonus;
        attacker.wTriangleDmgBonus = r.atkBonus;

        // 防御方取负——注意 C 里是对 `it->hitBonus` 取负，不是对攻击方字段取负
        defender.wTriangleHitBonus = -r.hitBonus;
        defender.wTriangleDmgBonus = -r.atkBonus;
        break;
      }
    }

    if (attacker.weaponAttributes & iaRevertTriangle != 0) {
      _applyReaverEffect(attacker, defender);
    }
    if (defender.weaponAttributes & iaRevertTriangle != 0) {
      _applyReaverEffect(attacker, defender);
    }
  }

  /// `BattleApplyReaverEffect`
  ///
  /// ⚠️ 条件是"**双方不都**带 Reaver"。双方都带时这个函数什么都不做，
  /// 三角保持原样——因为两个反转会互相抵消。
  static void _applyReaverEffect(BattleUnit attacker, BattleUnit defender) {
    final bothReaver = attacker.weaponAttributes & iaRevertTriangle != 0 &&
        defender.weaponAttributes & iaRevertTriangle != 0;
    if (bothReaver) return;

    attacker.wTriangleHitBonus = -(attacker.wTriangleHitBonus * 2);
    attacker.wTriangleDmgBonus = -(attacker.wTriangleDmgBonus * 2);
    defender.wTriangleHitBonus = -(defender.wTriangleHitBonus * 2);
    defender.wTriangleDmgBonus = -(defender.wTriangleDmgBonus * 2);
  }
}

/// `ComputeBattleUnitHitRate`
///
/// `skl * 2 + 武器命中 + lck / 2 + 三角命中加成`
///
/// ⚠️ `lck / 2` 是 **C 的整数除法（向零截断）**。Dart 的 `~/` 对正数等价，
/// 但负数会不同——幸运值不会为负，所以这里安全；不过仍然照 C 写，不图省事。
void computeHitRate(BattleUnit bu, ItemTable items) {
  bu.battleHitRate = bu.unit.skl * 2 +
      items.hitOf(bu.weapon) +
      _cDiv(bu.unit.lck, 2) +
      bu.wTriangleHitBonus;
}

/// C 的整数除法（向零截断）
int _cDiv(int a, int b) => a ~/ b;
