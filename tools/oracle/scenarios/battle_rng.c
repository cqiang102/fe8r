/*
 * 场景: battle_rng —— 战斗流程的**乱数消耗**
 *
 * 目标函数: src/BattleGenerateHitAttributes.c
 *   一次攻击判定的完整乱数消耗顺序：
 *     1. BattleCheckSureShot        —— 纯职业判定，不消耗
 *     2. BattleRoll2RN(hitRate)     —— **2 个乱数**（被 SURESHOT 短路时 0 个）
 *     3. BattleCheckGreatShield     —— 视职业，可能 BattleRoll1RN（1 个）
 *     4. BattleCheckPierce          —— 天马骑士/翼骑士职业时 BattleRoll1RN（1 个）
 *     5. BattleRoll1RN(critRate)    —— **1 个乱数**
 *     6. BattleCheckSilencer        —— 非魔王时 BattleRoll1RN（1 个）
 *
 * ## 为什么输出里要带 RNG 状态
 *
 * M4 的验收是"乱数序列与**消耗次数**逐位一致"。数次数最直接的办法是插桩，
 * 但插桩会改动被测代码。
 *
 * 这里换了个更强的判据：**把调用结束后的 RNG 状态一起输出**。
 * LFSR 的状态是 3 个 u16，任何"少消耗一次""多消耗一次""顺序不同"
 * 都会让它变成完全不同的值。也就是说状态本身就是消耗过程的指纹，
 * 而且**不需要碰被测代码**——`src/rng.c` 原样链接。
 *
 * ## 输入字段
 *
 *   seed        (int)  初始种子
 *   hitRate     (int)  命中率
 *   critRate    (int)  必杀率
 *   silencerRate(int)  瞬杀率
 *   attack      (int)  攻击力
 *   defense     (int)  防御力
 *   actorCls    (int)  攻击方职业
 *   targetCls   (int)  防御方职业
 *   actorLevel  (int)  攻击方等级（Pierce 判定用）
 *   attrs       (int)  进入时的 hit attributes（预设 SURESHOT 等标志）
 *   config      (int)  gBattleStats.config（SIMULATE 会让判定不消耗乱数）
 *
 * ## 输出
 *
 *   <damage>,<attributes>,<seed0>,<seed1>,<seed2>
 */
#include "global.h"
#include "rng.h"
#include "bmitem.h"
#include "bmunit.h"
#include "bmbattle.h"
#include "oracle_io.h"

#include <string.h>

/* ---- 被测代码依赖的全局量 ---- */
struct BattleStats gBattleStats;
struct BattleHit gBattleHitBuf[4];
struct BattleHit* gBattleHitIterator;
struct BattleUnit* gpBattleUnit[2];
struct BattleUnit gBattleActorDummy;
struct BattleUnit gBattleTargetDummy;

/* 道具表：只用到 weaponEffect（判断是否毒武器）与 attributes。
   全部留 0，让 BattleCheckGreatShield 的毒武器分支不被触发。 */
struct ItemData gItemData[0x100];

/* 场景里自己维护的战场单位（真实代码通过 attacker/defender 参数拿到） */
static struct ClassData s_actorClass;
static struct ClassData s_targetClass;

/* GetItemIndex 在上游是 extern inline，跨 TU 不产出符号（与 crit_rate 场景同处理） */
int GetItemIndex(int item)
{
    return ITEM_INDEX(item);
}

void BattleGenerateHitAttributes(struct BattleUnit* attacker, struct BattleUnit* defender);

void oracle_run(const OracleCase* c)
{
    struct BattleUnit attacker, defender;
    unsigned char* p;
    unsigned i;
    u16 seeds[3];
    long out[5];

    p = (unsigned char*)&attacker; for (i = 0; i < sizeof(attacker); i++) p[i] = 0;
    p = (unsigned char*)&defender; for (i = 0; i < sizeof(defender); i++) p[i] = 0;
    memset(&gBattleStats, 0, sizeof(gBattleStats));

    s_actorClass.number  = (u8)oracle_long(c, "actorCls", 1);
    s_targetClass.number = (u8)oracle_long(c, "targetCls", 1);
    attacker.unit.pClassData = &s_actorClass;
    defender.unit.pClassData = &s_targetClass;
    attacker.unit.level = (u8)oracle_long(c, "actorLevel", 1);

    attacker.weapon = 1;                 /* 普通武器，避免 poison 等特殊分支 */
    attacker.unit.items[0] = 1;

    gBattleStats.config      = (u16)oracle_long(c, "config", BATTLE_CONFIG_REAL);
    gBattleStats.hitRate     = (short)oracle_long(c, "hitRate", 100);
    gBattleStats.critRate    = (short)oracle_long(c, "critRate", 0);
    gBattleStats.silencerRate= (short)oracle_long(c, "silencerRate", 0);
    gBattleStats.attack      = (short)oracle_long(c, "attack", 10);
    gBattleStats.defense     = (short)oracle_long(c, "defense", 0);

    memset(gBattleHitBuf, 0, sizeof(gBattleHitBuf));
    gBattleHitIterator = &gBattleHitBuf[0];
    gBattleHitIterator->attributes = (unsigned)oracle_long(c, "attrs", 0);

    InitRN((int)oracle_long(c, "seed", 0));

    BattleGenerateHitAttributes(&attacker, &defender);

    StoreRNState(seeds);

    out[0] = gBattleStats.damage;
    out[1] = (long)gBattleHitIterator->attributes;
    out[2] = seeds[0];
    out[3] = seeds[1];
    out[4] = seeds[2];

    {
        char buf[ORA_OUT_MAX];
        int n = 0;
        for (i = 0; i < 5; i++)
            n += snprintf(buf + n, sizeof(buf) - n, (i ? ",%ld" : "%ld"), out[i]);
        oracle_emit_str(c, buf);
    }
}
