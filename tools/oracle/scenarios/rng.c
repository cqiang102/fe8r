/*
 * 场景: rng —— 乱数系统
 *
 * 目标函数: src/rng.c
 *   NextRN / NextRN_100 / NextRN_N / Roll2RN / AdvanceGetLCGRNValue
 *
 * 为什么先做这个：src/rng.c 完全自包含（108 行，无外部依赖），是最干净的
 * 端到端验证目标。而且乱数消耗顺序是 1:1 保真里最容易出错的地方——
 * 错一位后面全部错位，所以它必须是最先被锁死的模块。
 *
 * 输入字段:
 *   seed   (int)  初始种子
 *   fn     (str)  next | next100 | nextn | roll2 | lcg     默认 next
 *   count  (int)  输出多少个值                              默认 8
 *   thr    (int)  roll2 的阈值 / nextn 的上限               默认 50
 *
 * 输出: 逗号分隔的结果序列
 */
#include "global.h"
#include "rng.h"
#include "oracle_io.h"

static int str_eq(const char* a, const char* b)
{
    while (*a && *a == *b) { a++; b++; }
    return *a == *b;
}

void oracle_run(const OracleCase* c)
{
    long        seed  = oracle_long(c, "seed", 0);
    long        count = oracle_long(c, "count", 8);
    long        thr   = oracle_long(c, "thr", 50);
    const char* fn    = oracle_str(c, "fn", "next");
    long        out[64];
    int         i;

    if (count > 64) count = 64;
    if (count < 0)  count = 0;

    if (str_eq(fn, "lcg")) {
        SetLCGRNValue((int)seed);
        for (i = 0; i < (int)count; i++)
            out[i] = (long)(unsigned)AdvanceGetLCGRNValue();
    }
    else {
        InitRN((int)seed);

        if (str_eq(fn, "next100")) {
            for (i = 0; i < (int)count; i++) out[i] = NextRN_100();
        }
        else if (str_eq(fn, "nextn")) {
            for (i = 0; i < (int)count; i++) out[i] = NextRN_N((int)thr);
        }
        else if (str_eq(fn, "roll2")) {
            for (i = 0; i < (int)count; i++) out[i] = Roll2RN((int)thr);
        }
        else {
            for (i = 0; i < (int)count; i++) out[i] = NextRN();
        }
    }

    oracle_emit_longs(c, out, (int)count);
}
