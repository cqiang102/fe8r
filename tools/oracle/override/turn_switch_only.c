/*
 * 只把 `SwitchPhases` 一个函数从 bm_080153B0.c 里抽出来编。
 *
 * bm_080153B0.c 同一个 TU 里还有一堆 Proc / 相机 / 地图动画相关函数，
 * 直接编会拖进几十个符号。SwitchPhases 本身只碰 gPlaySt 和
 * ProcessTurnSupportExp，所以把它单独抄成一份独立的 TU。
 *
 * ⚠️ 这是**唯一**允许手抄 C 的地方，理由：无法只编一个 TU 中的单个函数。
 * 抄写内容与上游逐字符一致（下面附了来源行号），并由 Oracle 的结果自证：
 * 如果抄错了，Dart 侧（按真实语义实现）就会和它对不上。
 *
 * 来源: third_party/fireemblem8j/src/bm_080153B0.c 的 SwitchPhases
 *       (FE8U = 0x0801538C)
 */
#include "global.h"
#include "bmunit.h"
#include "chapterdata.h"

struct PlaySt gPlaySt;

/* 上游会调用它；本场景不关心支援经验，给个空实现 */
void ProcessTurnSupportExp(void) {}

void SwitchPhases(void)
{
    switch (gPlaySt.faction) {
    case FACTION_BLUE:
        gPlaySt.faction = FACTION_RED;

        break;

    case FACTION_RED:
        gPlaySt.faction = FACTION_GREEN;

        break;

    case FACTION_GREEN:
        gPlaySt.faction = FACTION_BLUE;

        if (gPlaySt.chapterTurnNumber < 999)
            gPlaySt.chapterTurnNumber++;

        ProcessTurnSupportExp();
    }
}
