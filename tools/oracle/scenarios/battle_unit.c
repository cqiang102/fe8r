/*
 * 场景: battle_unit —— 战斗单位的派生属性计算
 *
 * 目标函数（都在 src/ 里，且都是纯 struct 访问、无外部函数调用）:
 *   ComputeBattleUnitAvoidRate   bu->battleAvoidRate = speed*2 + terrainAvoid + lck，负数钳位到 0
 *   ComputeBattleUnitBaseDefense bu->battleDefense  = terrainDefense + unit.def
 *   ComputeBattleUnitDodgeRate   bu->battleDodgeRate = unit.lck
 *
 * 为什么选这三个：
 *   - 零外部依赖，Oracle 不需要任何 mock
 *   - 覆盖了 struct 嵌套访问（BattleUnit 内嵌 Unit）、算术、以及**分支钳位**
 *   - AvoidRate 的"负数钳位到 0"正是手写移植最容易漏掉的分支
 *
 * 输入字段:
 *   fn              (str) avoid | defense | dodge        默认 avoid
 *   battleSpeed     (int)
 *   terrainAvoid    (int)
 *   terrainDefense  (int)
 *   def             (int)  unit.def
 *   lck             (int)  unit.lck
 *
 * 输出: 计算结果
 */
#include "global.h"
#include "bmbattle.h"
#include "bmitem.h"
#include "oracle_io.h"

static int str_eq(const char* a, const char* b)
{
    while (*a && *a == *b) { a++; b++; }
    return *a == *b;
}

void ComputeBattleUnitAvoidRate(struct BattleUnit* bu);
void ComputeBattleUnitBaseDefense(struct BattleUnit* bu);
void ComputeBattleUnitDodgeRate(struct BattleUnit* bu);

/* ---- 可控的道具表 ----
   ComputeBattleUnitSpeed 通过 GetItemWeight(bu->weaponBefore) 读重量。
   道具编号 1..4 给不同重量，0 表示空手（重量 0）。 */
struct ItemData gItemData[8];

void oracle_run(const OracleCase* c)
{
    struct BattleUnit bu;
    const char* fn = oracle_str(c, "fn", "avoid");
    unsigned char* p = (unsigned char*)&bu;
    unsigned i;

    /* 清零，保证未设置的字段是确定的（默认 0） */
    for (i = 0; i < sizeof(bu); i++) p[i] = 0;

    gItemData[0].weight = 0;
    gItemData[1].weight = 1;
    gItemData[2].weight = 5;
    gItemData[3].weight = 12;
    gItemData[4].weight = 20;

    bu.weaponBefore  = (u16)oracle_long(c, "weaponBefore", 0);
    bu.unit.conBonus = (signed char)oracle_long(c, "conBonus", 0);
    bu.unit.spd      = (signed char)oracle_long(c, "spd", 0);

    bu.battleSpeed   = (short)oracle_long(c, "battleSpeed", 0);
    bu.terrainAvoid  = (signed char)oracle_long(c, "terrainAvoid", 0);
    bu.terrainDefense = (signed char)oracle_long(c, "terrainDefense", 0);
    bu.unit.def      = (signed char)oracle_long(c, "def", 0);
    bu.unit.lck      = (signed char)oracle_long(c, "lck", 0);

    if (str_eq(fn, "speed")) {
        ComputeBattleUnitSpeed(&bu);
        oracle_emit_long(c, bu.battleSpeed);
    }
    else if (str_eq(fn, "defense")) {
        ComputeBattleUnitBaseDefense(&bu);
        oracle_emit_long(c, bu.battleDefense);
    }
    else if (str_eq(fn, "dodge")) {
        ComputeBattleUnitDodgeRate(&bu);
        oracle_emit_long(c, bu.battleDodgeRate);
    }
    else {
        ComputeBattleUnitAvoidRate(&bu);
        oracle_emit_long(c, bu.battleAvoidRate);
    }
}
