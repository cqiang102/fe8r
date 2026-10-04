/*
 * oracle_io.h —— C Oracle 的测试向量 I/O 框架。
 *
 * 通信格式刻意选成最简单的 TSV，原因：
 *   - C89 下不需要 JSON 解析器（agbcc 代码是 C89，harness 也得跟上）
 *   - Dart / Python 侧一行代码就能读写
 *   - 出问题时可以直接用肉眼 diff
 *
 * 输入（stdin，每行一个用例）：
 *     <id> \t key=value \t key=value ...
 *     以 '#' 开头的行与空行被忽略
 *
 * 输出（stdout，每行一个结果，与输入同序）：
 *     <id> \t <result>
 *
 * 场景只需实现 `oracle_run()`，其余由本框架处理。
 */
#ifndef ORACLE_IO_H
#define ORACLE_IO_H

#define ORA_MAX_FIELDS 16
#define ORA_KEY_MAX    32
#define ORA_ID_MAX     64
/* ⚠️ 两个长度限制是分开的，别混用：
 *
 *   ORA_KEY_MAX  字段**名**的长度（"terrain" / "costs" 这种），32 足够
 *   ORA_VAL_MAX  字段**值**作为字符串时的长度
 *
 * 早期版本用 ORA_KEY_MAX 同时限制两者，于是超过 31 字符的字符串字段被
 * **静默截断**。M3 的移动范围需要传整张地图的地形网格（32×32 = 1024 个数，
 * 上千字符），一截断结果就完全错了——而且不报错，只是算错。
 */
#define ORA_VAL_MAX    16384
#define ORA_LINE_MAX   65536
#define ORA_OUT_MAX    65536

typedef struct {
    char id[ORA_ID_MAX];
    int  n;
    char keys[ORA_MAX_FIELDS][ORA_KEY_MAX];
    long vals[ORA_MAX_FIELDS];
} OracleCase;

/* 从 stdin 读入下一个用例。读到 EOF 返回 0，否则返回 1。 */
int  oracle_next(OracleCase* c);

/* 取整数字段；字段不存在时返回 dflt。 */
long oracle_long(const OracleCase* c, const char* key, long dflt);

/* 取字符串字段；字段不存在时返回 dflt。返回指向内部缓冲的指针，
   仅在下一次 oracle_next() 之前有效。 */
const char* oracle_str(const OracleCase* c, const char* key, const char* dflt);

/* 结果输出 */
void oracle_emit_long(const OracleCase* c, long v);
void oracle_emit_longs(const OracleCase* c, const long* v, int n);
void oracle_emit_str(const OracleCase* c, const char* s);

/* 每个场景实现这一个函数。 */
void oracle_run(const OracleCase* c);

#endif /* ORACLE_IO_H */
