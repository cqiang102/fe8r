/*
 * 场景: turn_switch —— 回合推进
 *
 * 目标函数: src/bm_080153B0.c 的 SwitchPhases
 *
 *     switch (gPlaySt.faction) {
 *     case FACTION_BLUE:  gPlaySt.faction = FACTION_RED;   break;
 *     case FACTION_RED:   gPlaySt.faction = FACTION_GREEN; break;
 *     case FACTION_GREEN: gPlaySt.faction = FACTION_BLUE;
 *         if (gPlaySt.chapterTurnNumber < 999)
 *             gPlaySt.chapterTurnNumber++;
 *     }
 *
 * ## 两个容易写错的点
 *
 * 1. **回合数不是每次切换都加**，只在 GREEN 绕回 BLUE 时加一次。
 *    写成"切一次加一次"会让回合数变成实际的三倍。
 * 2. 回合数有 **999 上限**，到顶之后不再增长。
 *    漏掉上限，长局（或挂机）会让数字溢出显示。
 *
 * 顺序是 蓝 → 红 → 绿 → 蓝，也就是 我方 → 敌方 → 友军 NPC。
 *
 * ## 输入
 *
 *   faction (int) 起始阵营
 *   turn    (int) 起始回合数
 *   steps   (int) 切换几次
 *
 * ## 输出
 *
 *   每次切换后的 `faction,turn`，用 `;` 连接
 */
#include "global.h"
#include "bmunit.h"
#include "chapterdata.h"
#include "oracle_io.h"

#include <string.h>

struct PlaySt gPlaySt;

void SwitchPhases(void);

void oracle_run(const OracleCase* c)
{
    int steps = (int)oracle_long(c, "steps", 1);
    int i;
    char buf[ORA_OUT_MAX];
    int n = 0;

    gPlaySt.faction = (u8)oracle_long(c, "faction", 0);
    gPlaySt.chapterTurnNumber = (u16)oracle_long(c, "turn", 1);

    for (i = 0; i < steps; i++)
    {
        SwitchPhases();
        n += snprintf(buf + n, sizeof(buf) - n, (i ? ";%d,%d" : "%d,%d"),
                      (int)gPlaySt.faction, (int)gPlaySt.chapterTurnNumber);
    }

    oracle_emit_str(c, buf);
}
