/*
 * 场景: weapon_triangle —— 武器三角与命中率
 *
 * 目标函数:
 *   BattleApplyWeaponTriangleEffect  src/BattleApplyWeaponTriangleEffect.c
 *   BattleApplyReaverEffect          src/BattleApplyReaverEffect.c
 *   ComputeBattleUnitHitRate         src/bmbattle_0802AB1C.c
 *
 * ## 关于规则表
 *
 * `sWeaponTriangleRules` **没有 C 源码**：它被绑成 ABS 符号指向 carve 出来的
 * ROM 数据块（layout/baseline_syms.d/data_bmbattle_wtriangle.tsv，
 * JP 0x085C3F70）。下面的定义就是按 `struct WeaponTriangleRule`
 * 从那段原始字节解出来的（tools/pipeline/extract/parse_carved_tables.py）。
 *
 * 也就是说：**表的正确性由提取器的自洽性校验负责，本场景负责算法的正确性。**
 * 两边都用同一张表，所以这里测的是"我的 Dart 实现和真实 C 实现在同一输入下
 * 是否给出同一结果"，这正是 Oracle 该干的事。
 *
 * ## 输入字段
 *
 *   fn         (str)  triangle | hitrate   默认 triangle
 *   atkType    (int)  攻击方武器类型（ITYPE_*）
 *   defType    (int)  防御方武器类型
 *   atkAttr    (int)  攻击方武器属性（IA_REVERTTRIANGLE = 1<<8）
 *   defAttr    (int)  防御方武器属性
 *   skl        (int)  技巧（hitrate 用）
 *   lck        (int)  幸运（hitrate 用）
 *   itemHit    (int)  武器命中（hitrate 用）
 *   wth        (int)  预先设置的三角命中加成（hitrate 用）
 *
 * ## 输出
 *
 *   triangle: atkHit,atkDmg,defHit,defDmg
 *   hitrate : battleHitRate
 */
#include "global.h"
#include "bmitem.h"
#include "bmunit.h"
#include "bmbattle.h"
#include "oracle_io.h"

#include <string.h>

struct WeaponTriangleRule {
    s8 attackerWeaponType;
    s8 defenderWeaponType;
    s8 hitBonus;
    s8 atkBonus;
};

/* 解自 JP 0x085C3F70（见文件头说明） */
const struct WeaponTriangleRule sWeaponTriangleRules[] = {
    { 0, 1, -15, -1 }, { 0, 2,  15,  1 },
    { 1, 2, -15, -1 }, { 1, 0,  15,  1 },
    { 2, 0, -15, -1 }, { 2, 1,  15,  1 },
    { 5, 7, -15, -1 }, { 5, 6,  15,  1 },
    { 6, 5, -15, -1 }, { 6, 7,  15,  1 },
    { 7, 6, -15, -1 }, { 7, 5,  15,  1 },
    { -1, 0, 0, 0 },   /* 终止符 */
};

/* 可控道具表：只需要 hit 字段 */
struct ItemData gItemData[4];

int GetItemIndex(int item)
{
    return ITEM_INDEX(item);
}

void BattleApplyWeaponTriangleEffect(struct BattleUnit* attacker, struct BattleUnit* defender);
void ComputeBattleUnitHitRate(struct BattleUnit* bu);

static int str_eq(const char* a, const char* b)
{
    while (*a && *a == *b) { a++; b++; }
    return *a == *b;
}

void oracle_run(const OracleCase* c)
{
    struct BattleUnit attacker, defender;
    unsigned char* p;
    unsigned i;
    const char* fn = oracle_str(c, "fn", "triangle");

    p = (unsigned char*)&attacker; for (i = 0; i < sizeof(attacker); i++) p[i] = 0;
    p = (unsigned char*)&defender; for (i = 0; i < sizeof(defender); i++) p[i] = 0;

    attacker.weaponType = (s8)oracle_long(c, "atkType", 0);
    defender.weaponType = (s8)oracle_long(c, "defType", 0);
    attacker.weaponAttributes = (u32)oracle_long(c, "atkAttr", 0);
    defender.weaponAttributes = (u32)oracle_long(c, "defAttr", 0);

    if (str_eq(fn, "hitrate"))
    {
        gItemData[1].hit = (signed char)oracle_long(c, "itemHit", 0);
        attacker.weapon = 1;
        attacker.unit.skl = (signed char)oracle_long(c, "skl", 0);
        attacker.unit.lck = (signed char)oracle_long(c, "lck", 0);
        attacker.wTriangleHitBonus = (s8)oracle_long(c, "wth", 0);

        ComputeBattleUnitHitRate(&attacker);
        oracle_emit_long(c, attacker.battleHitRate);
        return;
    }

    BattleApplyWeaponTriangleEffect(&attacker, &defender);

    {
        long out[4];
        char buf[ORA_OUT_MAX];
        int n = 0;
        out[0] = attacker.wTriangleHitBonus;
        out[1] = attacker.wTriangleDmgBonus;
        out[2] = defender.wTriangleHitBonus;
        out[3] = defender.wTriangleDmgBonus;
        for (i = 0; i < 4; i++)
            n += snprintf(buf + n, sizeof(buf) - n, (i ? ",%ld" : "%ld"), out[i]);
        oracle_emit_str(c, buf);
    }
}
