/*
 * oracle_io.c —— C Oracle 测试向量 I/O 框架的实现。
 * 见 oracle_io.h 的格式说明。C89 兼容。
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "oracle_io.h"

/* 字符串字段的暂存区（oracle_str 返回值指向这里） */
static char s_strpool[ORA_MAX_FIELDS][ORA_KEY_MAX];

static char* skip_ws(char* p)
{
    while (*p == ' ' || *p == '\t')
        p++;
    return p;
}

int oracle_next(OracleCase* c)
{
    static char line[ORA_LINE_MAX];
    char* p;
    int   i;

    for (;;) {
        if (fgets(line, sizeof(line), stdin) == NULL)
            return 0;

        /* 去掉行尾换行 */
        i = (int)strlen(line);
        while (i > 0 && (line[i - 1] == '\n' || line[i - 1] == '\r'))
            line[--i] = '\0';

        p = skip_ws(line);
        if (*p == '\0' || *p == '#')
            continue;   /* 空行与注释 */
        break;
    }

    c->n = 0;

    /* 第一个字段是 id */
    {
        char* tab = strchr(p, '\t');
        if (tab != NULL)
            *tab = '\0';
        strncpy(c->id, p, ORA_ID_MAX - 1);
        c->id[ORA_ID_MAX - 1] = '\0';
        p = (tab != NULL) ? tab + 1 : NULL;
    }

    /* 其余是 key=value */
    while (p != NULL && c->n < ORA_MAX_FIELDS) {
        char* tab = strchr(p, '\t');
        char* eq;

        if (tab != NULL)
            *tab = '\0';

        p = skip_ws(p);
        eq = strchr(p, '=');
        if (eq != NULL) {
            *eq = '\0';
            strncpy(c->keys[c->n], p, ORA_KEY_MAX - 1);
            c->keys[c->n][ORA_KEY_MAX - 1] = '\0';
            c->vals[c->n] = strtol(eq + 1, NULL, 0);

            strncpy(s_strpool[c->n], eq + 1, ORA_KEY_MAX - 1);
            s_strpool[c->n][ORA_KEY_MAX - 1] = '\0';

            c->n++;
        }

        p = (tab != NULL) ? tab + 1 : NULL;
    }

    return 1;
}

static int find_field(const OracleCase* c, const char* key)
{
    int i;
    for (i = 0; i < c->n; i++)
        if (strcmp(c->keys[i], key) == 0)
            return i;
    return -1;
}

long oracle_long(const OracleCase* c, const char* key, long dflt)
{
    int i = find_field(c, key);
    return (i >= 0) ? c->vals[i] : dflt;
}

const char* oracle_str(const OracleCase* c, const char* key, const char* dflt)
{
    int i = find_field(c, key);
    return (i >= 0) ? s_strpool[i] : dflt;
}

void oracle_emit_long(const OracleCase* c, long v)
{
    printf("%s\t%ld\n", c->id, v);
}

void oracle_emit_longs(const OracleCase* c, const long* v, int n)
{
    int i;
    printf("%s\t", c->id);
    for (i = 0; i < n; i++)
        printf("%s%ld", (i > 0) ? "," : "", v[i]);
    printf("\n");
}

void oracle_emit_str(const OracleCase* c, const char* s)
{
    printf("%s\t%s\n", c->id, s);
}

int main(void)
{
    OracleCase c;

    /* 关闭 stdout 缓冲，保证结果与输入严格同序可对应 */
    setvbuf(stdout, NULL, _IOLBF, 0);

    while (oracle_next(&c))
        oracle_run(&c);

    return 0;
}
