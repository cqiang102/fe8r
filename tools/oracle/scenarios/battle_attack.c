/*
 * 场景: battle_attack —— 攻击力与特效判定
 *
 * 目标函数:
 *   ComputeBattleUnitAttack      src/ComputeBattleUnitAttack.c
 *   IsItemEffectiveAgainst       src/IsItemEffectiveAgainst.c
 *   IsUnitEffectiveAgainst       src/IsUnitEffectiveAgainst.c
 *
 * 为什么选它：
 *   - 覆盖**武器特效**这条核心规则（对重甲 / 对飞行 / 对魔物 / 对龙）
 *   - 覆盖**两处不同的倍率**：普通特效 ×3，而"神器"（圣剑/圣枪等）×2
 *   - 覆盖**飞行特效抵消**：防御方携带 IA_NEGATE_FLYING 时特效失效
 *   - 覆盖**魔物职业的整体特效**（职业 0x2B/0x2C 攻击一切魔物 ×3）
 *
 * 本 harness 提供可控的 gItemData（威力 + 特效列表）与 ClassData（职业编号）。
 * 特效列表用仓库里真实的 ItemEffectiveness_* 表，不自己编。
 *
 * 输入字段:
 *   fn        (str)  attack | item_eff | unit_eff   默认 attack
 *   weapon    (int)  攻击方武器（低 8 位是道具编号）
 *   might     (int)  武器威力
 *   triBonus  (int)  武器三角伤害加成（wTriangleDmgBonus）
 *   pow       (int)  攻击方力量
 *   actorCls  (int)  攻击方职业编号
 *   targetCls (int)  防御方职业编号
 *   effList   (str)  武器特效列表：none|armor|horse|flier|dragon|monsters|flierAndMonsters
 *   negFly    (int)  防御方道具属性（含 IA_NEGATE_FLYING 则抵消飞行特效）
 *
 * 输出: 攻击力（attack）/ 判定结果 0 或 1（item_eff / unit_eff）
 */
#include "global.h"
#include "bmunit.h"
#include "bmitem.h"
#include "bmbattle.h"
#include "constants/items.h"
#include "oracle_io.h"

#include <string.h>

/* 真实的特效列表定义在 src/data/data_itemuse.c，
   声明已经在 variables.h 里（经由头文件链引入），这里不再重复 extern，
   否则会因为 CONST_DATA 限定不同而重定义报错。 */

/* ---- 可控的全局数据 ---- */
struct ItemData gItemData[4];
static struct ClassData s_actorClass;
static struct ClassData s_targetClass;

/* ---- GetItemIndex 在上游是 `extern inline`（GNU89 语义，跨 TU 不产出符号），
   所以这里补一个语义完全相同的定义——它只是 ITEM_INDEX 宏的包装。
   这与 scenarios/crit_rate.c 的做法一致。 */
int GetItemIndex(int item)
{
    return ITEM_INDEX(item);
}

static int str_eq(const char* a, const char* b)
{
    while (*a && *a == *b) { a++; b++; }
    return *a == *b;
}

static const u8* pick_list(const char* name)
{
    if (name == NULL) return NULL;
    if (str_eq(name, "none"))              return NULL;
    if (str_eq(name, "armor"))             return ItemEffectiveness_Armor;
    if (str_eq(name, "armorAndHorse"))     return ItemEffectiveness_ArmorAndHorse;
    if (str_eq(name, "horse"))             return ItemEffectiveness_Horse;
    if (str_eq(name, "flier"))             return ItemEffectiveness_Flier;
    if (str_eq(name, "flierAndMonsters"))  return ItemEffectiveness_FlierAndMonsters;
    if (str_eq(name, "dragon"))            return ItemEffectiveness_Dragon;
    if (str_eq(name, "monsters"))          return ItemEffectiveness_Monsters;
    return NULL;
}

void oracle_run(const OracleCase* c)
{
    struct BattleUnit attacker, defender;
    unsigned char* p;
    unsigned i;
    const char* fn = oracle_str(c, "fn", "attack");
    int itemIdx = (int)oracle_long(c, "weapon", 0) & 0xFF;

    p = (unsigned char*)&attacker; for (i = 0; i < sizeof(attacker); i++) p[i] = 0;
    p = (unsigned char*)&defender; for (i = 0; i < sizeof(defender); i++) p[i] = 0;

    /* 道具 1 承载被测武器的威力与特效；索引 0 = 空手 */
    gItemData[1].might = (signed char)oracle_long(c, "might", 0);
    gItemData[1].pEffectiveness = pick_list(oracle_str(c, "effList", "none"));
    gItemData[1].attributes = 0;

    /* 防御方道具 0 用来携带 IA_NEGATE_FLYING */
    gItemData[2].attributes = (int)oracle_long(c, "negFly", 0);
    defender.unit.items[0] = (u16)(oracle_long(c, "negFly", 0) ? 2 : 0);

    s_actorClass.number  = (u8)oracle_long(c, "actorCls", 1);
    s_targetClass.number = (u8)oracle_long(c, "targetCls", 1);
    attacker.unit.pClassData = &s_actorClass;
    defender.unit.pClassData = &s_targetClass;

    attacker.weapon = (u16)oracle_long(c, "weapon", 1);
    attacker.wTriangleDmgBonus = (short)oracle_long(c, "triBonus", 0);
    attacker.unit.pow = (signed char)oracle_long(c, "pow", 0);

    if (str_eq(fn, "item_eff"))
    {
        oracle_emit_long(c, IsItemEffectiveAgainst(attacker.weapon, &defender.unit) ? 1 : 0);
        return;
    }
    if (str_eq(fn, "unit_eff"))
    {
        oracle_emit_long(c, IsUnitEffectiveAgainst(&attacker.unit, &defender.unit) ? 1 : 0);
        return;
    }

    ComputeBattleUnitAttack(&attacker, &defender);
    oracle_emit_long(c, attacker.battleAttack);
}
