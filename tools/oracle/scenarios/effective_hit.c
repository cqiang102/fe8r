/*
 * 场景: effective_hit —— 有效命中率与追击判定
 *
 * 目标函数:
 *   ComputeBattleUnitEffectiveHitRate   src/bmbattle_0802ABD0.c
 *   ComputeBattleUnitSilencerRate       src/bmbattle.c
 *   BattleGetFollowUpOrder              src/bmbattle.c
 *   GetBattleUnitHitCount               src/GetBattleUnitHitCount.c
 *
 * ## 为什么值得单独立场景
 *
 * 有效命中率看着就是一句减法，但它有**上限 100** 的钳位：
 *
 *     battleEffectiveHitRate = battleHitRate - defender->battleAvoidRate;
 *     if (> 100) = 100;      // ★ 这一条最容易漏
 *     if (< 0)   = 0;
 *
 * 漏掉上限不会崩，只是命中率会显示成 120、130 这种数字，
 * 而且 `BattleUpdateBattleStats` 会把它直接塞进 gBattleStats.hitRate
 * 参与判定 —— Roll2RN(120) 和 Roll2RN(100) 是不同的分布。
 *
 * 追击判定同理：差值是 `>= 4`（不是 `> 4`），且有 `> 250` 的短路。
 *
 * ## 输入
 *
 *   fn        (str)  effhit | silencer | followup | hitcount
 *   hitRate   (int)  攻击方 battleHitRate
 *   avoidRate (int)  防御方 battleAvoidRate
 *   atkCA     (int)  攻击方职业属性（CA_*）
 *   defCA     (int)  防御方职业属性
 *   atkSpd    (int)  攻击方 battleSpeed
 *   defSpd    (int)  防御方 battleSpeed
 *   weapon    (int)  攻击方武器
 *   wepAttr   (int)  攻击方武器属性（IA_BRAVE 等）
 *   wepEffect (int)  攻击方 weaponBefore 的 GetItemWeaponEffect
 *
 * ## 输出
 *
 *   整数结果（followup 输出 0/1，以及谁先手：1=actor 2=target）
 */
#include "global.h"
#include "bmitem.h"
#include "bmunit.h"
#include "bmbattle.h"
#include "oracle_io.h"

#include <string.h>

struct ItemData gItemData[0x100];

/* BattleGetFollowUpOrder 读写这两个全局 */
struct BattleUnit gBattleActor;
struct BattleUnit gBattleTarget;

/* BattleCheckBraveEffect 会往命中迭代器上打 BATTLE_HIT_ATTR_BRAVE */
struct BattleHit gBattleHitArray[BATTLE_HIT_MAX];
struct BattleHit* gBattleHitIterator;

int GetItemIndex(int item) { return ITEM_INDEX(item); }

void ComputeBattleUnitEffectiveHitRate(struct BattleUnit* attacker, struct BattleUnit* defender);
void ComputeBattleUnitSilencerRate(struct BattleUnit* attacker, struct BattleUnit* defender);
s8 BattleGetFollowUpOrder(struct BattleUnit** outAttacker, struct BattleUnit** outDefender);
int GetBattleUnitHitCount(struct BattleUnit* attacker);

static int str_eq(const char* a, const char* b)
{
    while (*a && *a == *b) { a++; b++; }
    return *a == *b;
}

/* 场景里用角色属性承载 CA_*（UNIT_CATTRIBUTES = char.attributes | class.attributes） */
static struct CharacterData s_atkChar;
static struct ClassData s_atkClass;
static struct CharacterData s_defChar;
static struct ClassData s_defClass;

void oracle_run(const OracleCase* c)
{
    const char* fn = oracle_str(c, "fn", "effhit");
    unsigned char* p;
    unsigned i;

    p = (unsigned char*)&gBattleActor;  for (i = 0; i < sizeof(gBattleActor); i++)  p[i] = 0;
    p = (unsigned char*)&gBattleTarget; for (i = 0; i < sizeof(gBattleTarget); i++) p[i] = 0;
    memset(&s_atkChar, 0, sizeof(s_atkChar));
    memset(&s_atkClass, 0, sizeof(s_atkClass));
    memset(&s_defChar, 0, sizeof(s_defChar));
    memset(&s_defClass, 0, sizeof(s_defClass));
    memset(gItemData, 0, sizeof(gItemData));
    memset(gBattleHitArray, 0, sizeof(gBattleHitArray));
    gBattleHitIterator = &gBattleHitArray[0];

    gBattleActor.unit.pCharacterData = &s_atkChar;
    gBattleActor.unit.pClassData = &s_atkClass;
    gBattleTarget.unit.pCharacterData = &s_defChar;
    gBattleTarget.unit.pClassData = &s_defClass;

    s_atkChar.attributes = (u32)oracle_long(c, "atkCA", 0);
    s_defChar.attributes = (u32)oracle_long(c, "defCA", 0);

    gBattleActor.weapon = (u16)oracle_long(c, "weapon", 1);
    gBattleActor.weaponBefore = (u16)oracle_long(c, "weapon", 1);
    gBattleActor.weaponAttributes = (u32)oracle_long(c, "wepAttr", 0);
    gBattleActor.battleSpeed = (short)oracle_long(c, "atkSpd", 0);
    gBattleActor.battleHitRate = (short)oracle_long(c, "hitRate", 0);
    gBattleTarget.battleSpeed = (short)oracle_long(c, "defSpd", 0);
    gBattleTarget.battleAvoidRate = (short)oracle_long(c, "avoidRate", 0);

    /* weaponBefore 的 GetItemWeaponEffect 从道具表读 */
    gItemData[ITEM_INDEX(gBattleActor.weaponBefore)].weaponEffectId =
        (u8)oracle_long(c, "wepEffect", 0);

    if (str_eq(fn, "silencer"))
    {
        ComputeBattleUnitSilencerRate(&gBattleActor, &gBattleTarget);
        oracle_emit_long(c, gBattleActor.battleSilencerRate);
        return;
    }
    if (str_eq(fn, "hitcount"))
    {
        oracle_emit_long(c, GetBattleUnitHitCount(&gBattleActor));
        return;
    }
    if (str_eq(fn, "followup"))
    {
        struct BattleUnit* a = NULL;
        struct BattleUnit* d = NULL;
        s8 r = BattleGetFollowUpOrder(&a, &d);

        if (!r) { oracle_emit_long(c, 0); return; }
        /* 1 = 攻击方追击，2 = 防御方追击 */
        oracle_emit_long(c, (a == &gBattleActor) ? 1 : 2);
        return;
    }

    ComputeBattleUnitEffectiveHitRate(&gBattleActor, &gBattleTarget);
    oracle_emit_long(c, gBattleActor.battleEffectiveHitRate);
}
