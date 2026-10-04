/*
 * 场景: crit_rate —— 战斗必杀率（进阶复杂度）
 *
 * 目标函数: src/ComputeBattleUnitEffectiveCritRate.c
 *   attacker->battleEffectiveCritRate = attacker->battleCritRate - defender->battleDodgeRate;
 *   若攻击方武器是 ITEM_MONSTER_STONE          -> 0
 *   若结果 < 0                                  -> 0
 *   若防守方任一装备带 IA_NEGATE_CRIT           -> 0（并 break）
 *
 * 为什么选它（比前三个场景复杂一档）：
 *   - 两个 struct 指针参数
 *   - 三条独立的归零分支 + 一条循环短路
 *   - 覆盖"循环在空道具处提前终止"这个容易移植错的细节
 *
 * 依赖: src/ComputeBattleUnitEffectiveCritRate.c
 *       (需要 GetItemIndex / GetItemAttributes，见下方说明)
 *
 * 输入字段:
 *   critRate   (int)  攻击方 battleCritRate
 *   dodgeRate  (int)  防守方 battleDodgeRate
 *   weapon     (int)  攻击方武器原始值（0xB5 = ITEM_MONSTER_STONE）
 *   di0, di1   (int)  防守方 items[0] / items[1]（0 = 空，触发循环终止）
 *                      1 = 普通道具；2 = 带 IA_NEGATE_CRIT 的道具
 *
 * 输出: battleEffectiveCritRate
 */
#include "global.h"
#include "bmitem.h"
#include "bmunit.h"
#include "bmbattle.h"
#include "constants/items.h"
#include "oracle_io.h"

/* ---- 可控的 gItemData ----
   0    : 保留（item 值为 0 表示空）
   1    : 普通道具，attributes = 0
   2    : 带 IA_NEGATE_CRIT 的道具
   0xB5 : ITEM_MONSTER_STONE */
struct ItemData gItemData[0x100];

/* ---- GetItemIndex 在上游是 `extern inline`（GNU89 语义，跨 TU 不产出符号），
   所以这里补一个语义完全相同的定义。它只是 ITEM_INDEX 宏的包装。 */
int GetItemIndex(int item)
{
    return ITEM_INDEX(item);
}

/* GetItemAttributes 由 src/GetItemAttributes.c 提供 */

void ComputeBattleUnitEffectiveCritRate(struct BattleUnit* attacker, struct BattleUnit* defender);

static void zero_bu(struct BattleUnit* bu)
{
    unsigned char* p = (unsigned char*)bu;
    unsigned i;
    for (i = 0; i < sizeof(*bu); i++) p[i] = 0;
}

void oracle_run(const OracleCase* c)
{
    struct BattleUnit atk, def;

    zero_bu(&atk);
    zero_bu(&def);

    gItemData[1].attributes = 0;
    gItemData[2].attributes = IA_NEGATE_CRIT;
    gItemData[ITEM_MONSTER_STONE].attributes = 0;

    atk.battleCritRate = (short)oracle_long(c, "critRate", 0);
    def.battleDodgeRate = (short)oracle_long(c, "dodgeRate", 0);
    atk.weapon = (u16)oracle_long(c, "weapon", 0);
    def.unit.items[0] = (u16)oracle_long(c, "di0", 0);
    def.unit.items[1] = (u16)oracle_long(c, "di1", 0);

    ComputeBattleUnitEffectiveCritRate(&atk, &def);

    oracle_emit_long(c, atk.battleEffectiveCritRate);
}
