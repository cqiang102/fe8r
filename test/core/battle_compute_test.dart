// 战斗属性的**源码对照测试**。
//
// 每个断言的期望值都来自源码里的真实数值，不是"跑一遍看看等于几"。
import 'package:fe8r/core/core.dart';
import 'package:flutter_test/flutter_test.dart';

// CLASS_EIRIKA_LORD（`src/data/data_classes.c`）
const eirikaLord = ClassStats(
  number: 2,
  baseHP: 16, basePow: 4, baseSkl: 8, baseSpd: 9,
  baseDef: 3, baseRes: 1, baseCon: 5, baseMov: 5,
);

// CHARACTER_EIRIKA（`src/data/data_characters.c`）
const eirika = CharStats(number: 1, baseLevel: 1, baseLck: 5);

// ITEM_SWORD_IRON（`src/data/data_items.c`）
const ironSword = ItemStats(
  number: 1, might: 5, hit: 90, crit: 0, weight: 5, encodedRange: 17,
);

// ITEM_LANCE_JAVELIN
const javelin = ItemStats(
  number: 0x2C, might: 6, hit: 65, crit: 0, weight: 11, encodedRange: 18,
);

BattleUnitInput unit({
  ClassStats cls = eirikaLord,
  CharStats chr = eirika,
  ItemStats item = ironSword,
  int def = 0,
  int avo = 0,
  int tri = 0,
}) =>
    BattleUnitInput(
      level: 1, cls: cls, chr: chr, item: item,
      terrainDefense: def, terrainAvoid: avo, triangleDmgBonus: tri,
    );

void main() {
  group('道具数据的射程解码（`GetItemMin/MaxRange`）', () {
    test('铁剑 1..1', () {
      // encodedRange = 0x11 -> min 1, max 1
      expect(ironSword.minRange, 1);
      expect(ironSword.maxRange, 1);
    });
    test('手投枪 1..2', () {
      // encodedRange = 0x12 -> min 1, max 2
      expect(javelin.minRange, 1);
      expect(javelin.maxRange, 2);
    });
  });

  group('按源码算的战斗属性', () {
    test('`battleDefense = terrainDefense + unit.def`', () {
      // ComputeBattleUnitBaseDefense.c
      expect(computeBattleUnitBaseDefense(unit()), 3);
      expect(computeBattleUnitBaseDefense(unit(def: 2)), 5,
          reason: '地形防御要加上去');
    });

    test('`battleAttack = GetItemMight + 三角加成`', () {
      // ComputeBattleUnitAttack.c
      expect(computeBattleUnitAttack(unit()), 5);
      expect(computeBattleUnitAttack(unit(tri: 1)), 6);
    });

    test('`battleSpeed = spd - (武器重量 - con)`，两处都 clamp>=0', () {
      // ComputeBattleUnitSpeed.c
      // 艾莉卡：spd 9, con 5, 铁剑重量 5 -> effWt 0 -> speed 9
      expect(computeBattleUnitSpeed(unit()), 9);
      // 手投枪重量 11 -> effWt 6 -> speed 3
      expect(computeBattleUnitSpeed(unit(item: javelin)), 3);
      // 重武器超过 spd -> clamp 到 0
      const heavy = ItemStats(number: 99, weight: 40);
      expect(computeBattleUnitSpeed(unit(item: heavy)), 0,
          reason: 'clamp>=0，不能出现负速度');
    });

    test('`battleAvoidRate = speed*2 + terrainAvoid + lck`', () {
      // ComputeBattleUnitAvoidRate.c
      expect(computeBattleUnitAvoidRate(unit()), 9 * 2 + 0 + 5);
      expect(computeBattleUnitAvoidRate(unit(avo: 20)), 18 + 20 + 5);
    });

    test('`battleDodgeRate = unit.lck`', () {
      // ComputeBattleUnitDodgeRate.c
      expect(computeBattleUnitDodgeRate(unit()), 5);
    });

    test('伤害 = 攻击 - 防御，且不为负', () {
      // BattleGenerateHitAttributes.c: damage = attack - defense
      expect(computeDamage(unit(), unit()), 5 - 3);
      // 防御远高于攻击 -> 0，不是负数
      const tanky = ClassStats(number: 9, baseDef: 99);
      expect(computeDamage(unit(), unit(cls: tanky)), 0);
    });
  });

  group('职业表确实是源码的值（防止抽错）', () {
    test('CLASS_EIRIKA_LORD 的基础值', () {
      // src/data/data_classes.c
      expect(eirikaLord.baseHP, 16);
      expect(eirikaLord.basePow, 4);
      expect(eirikaLord.baseSkl, 8);
      expect(eirikaLord.baseSpd, 9);
      expect(eirikaLord.baseDef, 3);
      expect(eirikaLord.baseCon, 5);
    });

    test('角色**只有**等级和幸运（GBA FE 的模型）', () {
      // src/data/data_characters.c —— CHARACTER_EIRIKA 里没有 baseDef/baseSpd
      expect(eirika.baseLevel, 1);
      expect(eirika.baseLck, 5);
      // 所以 def/spd 只能来自职业 —— 这正是 `unit({cls: ...})` 的做法
      expect(unit().def, eirikaLord.baseDef);
      expect(unit().spd, eirikaLord.baseSpd);
    });
  });
}
