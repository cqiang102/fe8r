/*
 * 从 bmbattle.c 抽出两个函数单独编（理由同 turn_switch_only.c：
 * 整个 TU 依赖太多，无法只编其中两个函数）。
 *
 * 来源: third_party/fireemblem8j/src/bmbattle.c
 *   ComputeBattleUnitSilencerRate
 *   BattleGetFollowUpOrder
 *
 * 抄写内容与上游逐字符一致；如果抄错，Dart 侧（按真实语义实现）
 * 就会和它对不上，Oracle 会立刻报错。
 */
#include "global.h"
#include "bmitem.h"
#include "bmunit.h"
#include "bmbattle.h"
#include "constants/classes.h"
#include "constants/items.h"

/* ⚠️ 这两个是外部全局（定义在 bmbattle.c，场景里提供），
   这里只能 extern。定义两次会被 -fno-common 立刻拦下。 */
extern struct BattleUnit gBattleActor;
extern struct BattleUnit gBattleTarget;

void ComputeBattleUnitSilencerRate(struct BattleUnit* attacker, struct BattleUnit* defender) {
    if (!(UNIT_CATTRIBUTES(&attacker->unit) & CA_ASSASSIN))
        attacker->battleSilencerRate = 0;
    else {
        attacker->battleSilencerRate = 50;

        if (UNIT_CATTRIBUTES(&defender->unit) & CA_BOSS)
            attacker->battleSilencerRate = 25;

        if (UNIT_CATTRIBUTES(&defender->unit) & CA_NEGATE_LETHALITY)
            attacker->battleSilencerRate = 0;
    }
}

s8 BattleGetFollowUpOrder(struct BattleUnit** outAttacker, struct BattleUnit** outDefender) {
    if (gBattleTarget.battleSpeed > 250)
        return FALSE;

    if (ABS(gBattleActor.battleSpeed - gBattleTarget.battleSpeed) < BATTLE_FOLLOWUP_SPEED_THRESHOLD)
        return FALSE;

    if (gBattleActor.battleSpeed > gBattleTarget.battleSpeed) {
        *outAttacker = &gBattleActor;
        *outDefender = &gBattleTarget;
    } else {
        *outAttacker = &gBattleTarget;
        *outDefender = &gBattleActor;
    }

    if (GetItemWeaponEffect((*outAttacker)->weaponBefore) == WPN_EFFECT_HPHALVE)
        return FALSE;

    if (GetItemIndex((*outAttacker)->weapon) == ITEM_MONSTER_STONE)
        return FALSE;

    return TRUE;
}
