/*
 * 场景: unit_defense —— 单位防御力
 *
 * 目标函数: src/GetUnitDefense.c
 *   GetUnitDefense(unit) = unit->def + GetItemDefBonus(GetUnitEquippedWeapon(unit))
 *
 * 依赖的真实反编译代码:
 *   src/GetItemDefBonus.c   (含 GetItemData / GetItemStatBonuses)
 *
 * 为什么选它：
 *   - 覆盖**跨文件调用链** + **嵌套 struct 指针解引用**（ItemData -> pStatBonuses）
 *   - 覆盖 agbcc 的 GNU89 `extern inline` 语义（GetItemStatBonuses 在多个文件里重复定义）
 *
 * 本 harness 负责构造可控的 gItemData，并 stub 掉依赖过深的那一个函数
 * （GetUnitEquippedWeapon 会一路依赖到武器等级判定，不适合放进 Oracle 场景）。
 *
 * 输入字段:
 *   def        (int)  单位防御力
 *   item       (int)  装备道具的原始值（0 表示空手）
 *   defBonus   (int)  该道具的防御加成
 *
 * 输出: 防御力
 */
#include "global.h"
#include "bmunit.h"
#include "bmitem.h"
#include "oracle_io.h"

/* ---- 可控的 gItemData ----
   索引 1 = 带 defBonus 的测试道具；索引 0 = 空 */
static struct ItemStatBonuses s_bonus;
struct ItemData gItemData[2];

/* ---- stub：GetUnitEquippedWeapon 依赖链过深，这里直接取 items[0] ----
   注意这不影响被测函数：GetUnitDefense 只关心"装备了哪个道具"这个结果值。 */
u16 GetUnitEquippedWeapon(struct Unit* unit)
{
    return (u16)(unit->items[0] & 0xFF);
}

int GetUnitDefense(struct Unit* unit);

void oracle_run(const OracleCase* c)
{
    struct Unit unit;
    long def = oracle_long(c, "def", 0);
    long item = oracle_long(c, "item", 0);
    unsigned char* p = (unsigned char*)&unit;
    unsigned i;

    for (i = 0; i < sizeof(unit); i++) p[i] = 0;

    s_bonus.defBonus = (signed char)oracle_long(c, "defBonus", 0);
    gItemData[0].pStatBonuses = 0;
    gItemData[1].pStatBonuses = &s_bonus;

    unit.def = (signed char)def;
    unit.items[0] = (u16)item;

    oracle_emit_long(c, GetUnitDefense(&unit));
}
