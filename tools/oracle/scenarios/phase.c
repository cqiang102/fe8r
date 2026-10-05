/*
 * 场景: phase —— 阵营判定与"本回合可行动单位数"
 *
 * 目标函数: src/bmphase.c
 *   AreUnitsAllied            只看 0x80 一位（玩家与友军 NPC 算同盟）
 *   IsSameAllegiance          看 0xC0 两位（把友军 NPC 与玩家区分开）
 *   GetCurrentPhase           gPlaySt.faction & FACTION_RED
 *   GetNonActiveFaction       (gPlaySt.faction & FACTION_RED) ^ FACTION_RED
 *   GetPhaseAbleUnitCount     遍历 [faction+1, faction+0x40)，统计还能行动的单位
 *   CountUnitsInState         统计**不处于**某状态的单位数（名字有误导性）
 *
 * ## 为什么把它放进 Oracle
 *
 * 这几个函数看着只是位运算，但它们是"这一回合谁还能动"的唯一判据：
 *   - 漏掉一个 notAble 状态位 → 被救出/未出击的单位会变得可以行动
 *   - 阵营掩码少看一位 → 友军 NPC 被当成玩家单位驱动
 *   - CountUnitsInState 写反 → 计数取补集
 * 这些都不会崩，只会让回合流程悄悄走错。
 *
 * ## 输入字段
 *
 *   fn       (str)  allied | allegiance | current | nonactive | abled | instate
 *   left     (int)  allied / allegiance 的左操作数
 *   right    (int)  allied / allegiance 的右操作数
 *   faction  (int)  current / nonactive / abled / instate 的输入
 *   state    (int)  instate 的状态掩码
 *   units    (str)  逗号分隔的单位描述，每项形如
 *                     `<state>:<status>:<classAttr>:<valid>`
 *                   下标即单位编号（0..0xFF），缺省表示该编号没有单位
 *
 * ## 输出
 *
 *   整数结果
 */
#include "global.h"
#include "bmunit.h"
#include "oracle_io.h"

#include <string.h>

/* bmphase.c 的两个函数读 gPlaySt.faction；本场景直接给一个可控的 */
struct PlaySt gPlaySt;

/* 场景自建的单位表：下标就是单位编号。
   pCharacterData / pClassData 必须指向**真实的结构体**：
   `UNIT_CATTRIBUTES` 会解引用它们（pCharacterData->attributes | pClassData->attributes），
   拿一个假指针占位会直接崩。 */
struct Unit s_units[0x100];
u8 s_present[0x100];
static struct CharacterData s_charData[0x100];
static struct ClassData s_classData[0x100];

struct Unit* GetUnit(int id)
{
    if (id < 0 || id >= 0x100) return NULL;
    return s_present[id] ? &s_units[id] : NULL;
}

int GetPhaseAbleUnitCount(int faction);
int CountUnitsInState(int faction, int state);
int GetCurrentPhase(void);
int GetNonActiveFaction(void);
s8 AreUnitsAllied(int left, int right);
s8 IsSameAllegiance(int left, int right);

static int str_eq(const char* a, const char* b)
{
    while (*a && *a == *b) { a++; b++; }
    return *a == *b;
}

/* 解析 `<id>=<state>:<status>:<classAttr>:<valid>` 形式的单位列表 */
static void parse_units(const char* s)
{
    long vals[4];
    int nv = 0;
    int sign = 1;
    long v = 0;
    int in = 0;
    int id = -1;
    int expectId = 1;

    memset(s_present, 0, sizeof(s_present));
    memset(s_units, 0, sizeof(s_units));
    memset(s_charData, 0, sizeof(s_charData));
    memset(s_classData, 0, sizeof(s_classData));

    if (s == NULL) return;

    for (; *s; s++)
    {
        if (*s >= '0' && *s <= '9') { v = v * 10 + (*s - '0'); in = 1; continue; }
        if (*s == '-') { sign = -1; v = 0; in = 1; continue; }

        if (*s == '=' && expectId)
        {
            id = (int)(sign * v);
            sign = 1; v = 0; in = 0; expectId = 0;
            nv = 0;
            continue;
        }
        if (*s == ':' || *s == ',')
        {
            if (in && nv < 4) vals[nv++] = sign * v;
            sign = 1; v = 0; in = 0;
            if (*s == ',')
            {
                if (id >= 0 && id < 0x100 && nv >= 4)
                {
                    s_present[id] = vals[3] ? 1 : 0;
                    s_units[id].state = (u32)vals[0];
                    s_units[id].statusIndex = (u8)vals[1];
                    /* 职业属性放在 pClassData->attributes；角色属性固定 0，
                       于是 UNIT_CATTRIBUTES = classAttr | 0 = classAttr */
                    s_classData[id].attributes = (u32)vals[2];
                    s_units[id].pClassData = &s_classData[id];
                    /* pCharacterData 非空才算 UNIT_IS_VALID */
                    s_units[id].pCharacterData = s_present[id] ? &s_charData[id] : NULL;
                }
                id = -1; nv = 0; expectId = 1;
            }
            continue;
        }
    }
    /* 收尾（最后一个没有逗号） */
    if (in && nv < 4) vals[nv++] = sign * v;
    if (id >= 0 && id < 0x100 && nv >= 4)
    {
        s_present[id] = vals[3] ? 1 : 0;
        s_units[id].state = (u32)vals[0];
        s_units[id].statusIndex = (u8)vals[1];
        s_classData[id].attributes = (u32)vals[2];
        s_units[id].pClassData = &s_classData[id];
        s_units[id].pCharacterData = s_present[id] ? &s_charData[id] : NULL;
    }
}

void oracle_run(const OracleCase* c)
{
    const char* fn = oracle_str(c, "fn", "abled");

    if (str_eq(fn, "allied"))
    {
        oracle_emit_long(c, AreUnitsAllied((int)oracle_long(c, "left", 0),
                                           (int)oracle_long(c, "right", 0)));
        return;
    }
    if (str_eq(fn, "allegiance"))
    {
        oracle_emit_long(c, IsSameAllegiance((int)oracle_long(c, "left", 0),
                                             (int)oracle_long(c, "right", 0)));
        return;
    }
    gPlaySt.faction = (u8)oracle_long(c, "faction", 0);

    if (str_eq(fn, "current"))
    {
        oracle_emit_long(c, GetCurrentPhase());
        return;
    }
    if (str_eq(fn, "nonactive"))
    {
        oracle_emit_long(c, GetNonActiveFaction());
        return;
    }

    parse_units(oracle_str(c, "units", NULL));

    if (str_eq(fn, "instate"))
        oracle_emit_long(c, CountUnitsInState((int)oracle_long(c, "faction", 0),
                                              (int)oracle_long(c, "state", 0)));

    else
        oracle_emit_long(c, GetPhaseAbleUnitCount((int)oracle_long(c, "faction", 0)));
}
