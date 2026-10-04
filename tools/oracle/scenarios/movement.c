/*
 * 场景: movement —— 移动范围（BFS 泛洪）
 *
 * 目标算法: `MapFloodCore` + `MapFloodCoreStep`
 *   `GenerateMovementMap(x, y, movement, unitId)`
 *     → 初始化 gMovMapFillState 与 gWorkingBmMap
 *     → `MapFloodCore()` 反复调用 `MapFloodCoreStep()` 做双缓冲 BFS
 *   结果：gWorkingBmMap[y][x] = 走到 (x,y) 的最小消耗；255 表示到不了。
 *
 * ## 代码来源与保真度（重要）
 *
 * `MapFloodCoreStep` 用的是仓库里**真实的 C 实现** `src/MapFloodCoreStepThumb.c`。
 *
 * `MapFloodCore` 驱动循环在 `src/arm.s` 里是 ARM 汇编（GBA 上要拷进 RAM 跑，
 * 因为 ROM 里按 16 位取指太慢）。宿主机编译器汇编不了 GBA 的 ARM 代码，
 * 所以本文件里的驱动循环是从 `arm.s` 中那段**重构源码注释**转写的
 * （`src/arm.s:652-713`）。转写时逐条对照了汇编，两处关键语义都以汇编为准：
 *
 *   1. 比较用的是 `bhs`（无符号 `>=`），不是注释里写的 `>`
 *      —— Thumb 版实现 `MapFloodCoreStepThumb.c` 也是 `>=`，两处一致
 *   2. `connexion` 编码的是"从父节点走到本节点的方向"，
 *      本节点不再往父节点方向扩散（避免走回头路）
 *
 * ## 输入字段
 *
 *   w, h     (int)  地图尺寸
 *   move     (int)  移动力
 *   x, y     (int)  起点
 *   terrain  (str)  逗号分隔的 h*w 个地形 ID
 *   costs    (str)  逗号分隔的 65 个地形移动消耗（-1 = 不可通行）
 *   unit     (int)  单位归属（0 = 不做占用检查）
 *
 * ## 输出
 *
 * 逗号分隔的 h*w 个值：走到该格的最小消耗，255 = 到不了
 */
#include "global.h"
#include "bmmap.h"
#include "bmidoten.h"
#include "oracle_io.h"

#include <string.h>

/* ---- 被测代码依赖的全局量（本 harness 提供可控版本）----
   类型必须与 include/bmidoten.h、include/bmmap.h 里的声明完全一致，
   否则是重定义错误。 */
u8** gBmMapTerrain;                    /* 同样是二级指针 */
u8** gBmMapUnit;
u8** gWorkingBmMap;                    /* 注意是二级指针 */
u8  gWorkingTerrainMoveCosts[256];     /* 注意是 u8，不是 s8 */
struct MovMapFillState gMovMapFillState;

/* 双缓冲 BFS 队列。
 *
 * 真实 ROM 里每个池是 **128 项**（IWRAM 符号布局：
 *   gMovMapFillStPool1 @0x03004950 → gWorkingTerrainMoveCosts @0x03004B50，0x200 字节
 *   gMovMapFillStPool2 @0x03004BF0 → gActiveUnit            @0x03004DF0，0x200 字节
 * 每项 4 字节，故 128 项）。
 *
 * 而且 `arm.s` 里的指针推进是裸的 `add r6, r6, #4`，**没有任何环绕检查**——
 * 也就是说真机上池子不够大就是内存踩踏。这里给足空间，是为了让 Oracle
 * 测的是**算法行为**而不是缓冲区溢出。被测的 MapFloodCoreStep 本身仍是
 * 仓库里那份真实 C 实现。 */
#define POOL_SIZE 4096
struct MovMapFillStateExt gMovMapFillStPool1[POOL_SIZE];
struct MovMapFillStateExt gMovMapFillStPool2[POOL_SIZE];

/* 真实实现，来自 src/MapFloodCoreStepThumb.c */
void MapFloodCoreStepThumb(int connexion, int x, int y);

/* ---------------------------------------------------------------- 驱动
 *
 * 转写自 src/arm.s:652-713 的重构源码。语义见文件头说明。
 */
static void MapFloodCore(void)
{
    int i = 0;

    for (;;)
    {
        i = i ^ 1;
        if (i)
        {
            gMovMapFillState.src = gMovMapFillStPool1;
            gMovMapFillState.dst = gMovMapFillStPool2;
        }
        else
        {
            gMovMapFillState.src = gMovMapFillStPool2;
            gMovMapFillState.dst = gMovMapFillStPool1;
        }

        /* 4 是终止标记 */
        if (gMovMapFillState.src->connexion == 4)
            return;

        for (;;)
        {
            switch (gMovMapFillState.src->connexion) {
            case 3:
                MapFloodCoreStepThumb(3, 0, -1);
                MapFloodCoreStepThumb(0, -1, 0);
                MapFloodCoreStepThumb(1, 1, 0);
                break;

            case 2:
                MapFloodCoreStepThumb(2, 0, 1);
                MapFloodCoreStepThumb(0, -1, 0);
                MapFloodCoreStepThumb(1, 1, 0);
                break;

            case 0:
                MapFloodCoreStepThumb(3, 0, -1);
                MapFloodCoreStepThumb(2, 0, 1);
                MapFloodCoreStepThumb(0, -1, 0);
                break;

            case 1:
                MapFloodCoreStepThumb(3, 0, -1);
                MapFloodCoreStepThumb(2, 0, 1);
                MapFloodCoreStepThumb(1, 1, 0);
                break;

            case 4:
                goto break_internal_loop;

            case 5:
                MapFloodCoreStepThumb(3, 0, -1);
                MapFloodCoreStepThumb(2, 0, 1);
                MapFloodCoreStepThumb(0, -1, 0);
                MapFloodCoreStepThumb(1, 1, 0);
                break;
            }

            gMovMapFillState.dst->connexion = 4;
            gMovMapFillState.src++;
        }
    break_internal_loop:
        ;
    }
}

/* ---------------------------------------------------------------- 工具 */

static int parse_ints(const char* s, long* out, int max)
{
    int n = 0;
    int sign = 1;
    long v = 0;
    int in = 0;

    if (s == NULL)
        return 0;

    for (; *s; s++)
    {
        if (*s == '-') { sign = -1; v = 0; in = 1; }
        else if (*s >= '0' && *s <= '9') { v = v * 10 + (*s - '0'); in = 1; }
        else if (*s == ',')
        {
            if (in && n < max) out[n++] = sign * v;
            sign = 1; v = 0; in = 0;
        }
    }
    if (in && n < max) out[n++] = sign * v;
    return n;
}

/* ---------------------------------------------------------------- 缓冲
 *
 * ⚠️ **必须带一圈边界**。真实游戏里 gBmMapTerrain 等是"带边框分配"的：
 * 地图外圈留一格，由 BmMapFillEdges 填成不可通行，行指针指向**内部**。
 * 泛洪算法会访问 x-1 / y-1，没有边界就会踩到别的行甚至越界。
 *
 * 布局（以 32x32 上限为例，实际用 W+2 列）：
 *
 *     行指针数组 [0]      → 上边界行（全不可通行）
 *                [1..H]  → 地图内部第 0..H-1 行
 *                [H+1]   → 下边界行
 *
 * gBmMapTerrain 指向 [1]，于是 gBmMapTerrain[-1] 正好是上边界行。
 */
#define MAXDIM 32
#define STRIDE (MAXDIM + 2)

static u8 s_terrain[STRIDE * STRIDE];
static u8 s_unit[STRIDE * STRIDE];
static u8 s_work[STRIDE * STRIDE];
static u8* s_terrainRow[STRIDE];
static u8* s_unitRow[STRIDE];
static u8* s_workRow[STRIDE];
static long s_scratch[STRIDE * STRIDE];

/* 边界用的地形 ID。
 *
 * ⚠️ **必须取真实地形表之外的编号。** 曾经用过 64 —— 那正好是
 * TERRAIN_MAST（最后一个真实地形），而 costs 数组有 65 项（下标 0..64），
 * 于是"把边界设为不可通行"这一步被随后的 costs 覆盖掉，边界变成可通行，
 * 泛洪直接跑出地图，y 越界到负值，行指针读到垃圾 → 段错误。
 *
 * 用 200：gWorkingTerrainMoveCosts 有 256 项，200 在表外，永远不会被
 * costs 数组碰到。 */
#define BORDER_TERRAIN 200

void oracle_run(const OracleCase* c)
{
    long w = oracle_long(c, "w", 8);
    long h = oracle_long(c, "h", 8);
    long move = oracle_long(c, "move", 5);
    long sx = oracle_long(c, "x", 0);
    long sy = oracle_long(c, "y", 0);
    long unitId = oracle_long(c, "unit", 0);
    const char* terrain = oracle_str(c, "terrain", NULL);
    const char* costs = oracle_str(c, "costs", NULL);
    long out[MAXDIM * MAXDIM];
    int i;

    if (w < 1) w = 1;
    if (h < 1) h = 1;
    if (w > MAXDIM) w = MAXDIM;
    if (h > MAXDIM) h = MAXDIM;

    /* ---- 移动消耗表 ---- */
    for (i = 0; i < 256; i++) gWorkingTerrainMoveCosts[i] = 1;
    if (costs != NULL)
    {
        int n = parse_ints(costs, s_scratch, 256);
        for (i = 0; i < n && i < 256; i++)
            gWorkingTerrainMoveCosts[i] = (u8)s_scratch[i];
    }
    /* 必须在应用 costs **之后**设置，且 ID 在真实地形表之外 */
    gWorkingTerrainMoveCosts[BORDER_TERRAIN] = (u8)-1;   /* 边界不可通行 */

    /* ---- 缓冲区：先整块填成边界地形，再写内部 ----
       地图是 (MAXDIM+2) x (MAXDIM+2)，行指针整体偏移一格，
       于是 gBmMap*[-1] 落在上边界行上（真机也是这样分配的）。 */
    memset(s_terrain, BORDER_TERRAIN, sizeof(s_terrain));
    memset(s_unit, 0, sizeof(s_unit));
    memset(s_work, 0xFF, sizeof(s_work));   /* 未访问 = -1 */

    /* 行指针指向每行的**第 1 列**（第 0 列留给左边界）。
       于是 gBmMapTerrain[y][x] 落在 s_terrain[(y+1)*STRIDE + (x+1)]，
       与下面的写入位置一致；而 gBmMapTerrain[y][-1] 正好是左边界。 */
    for (i = 0; i < STRIDE; i++)
    {
        s_terrainRow[i] = &s_terrain[i * STRIDE + 1];
        s_unitRow[i] = &s_unit[i * STRIDE + 1];
        s_workRow[i] = &s_work[i * STRIDE + 1];
    }
    gBmMapTerrain = &s_terrainRow[1];
    gBmMapUnit = &s_unitRow[1];
    gWorkingBmMap = &s_workRow[1];

    if (terrain != NULL)
    {
        int n = parse_ints(terrain, s_scratch, STRIDE * STRIDE);
        for (i = 0; i < n && i < w * h; i++)
            s_terrain[(i / w + 1) * STRIDE + (i % w + 1)] = (u8)s_scratch[i];
    }

    /* ---- 与 GenerateMovementMap 一致地初始化 ---- */
    gMovMapFillState.dst = gMovMapFillStPool1;
    gMovMapFillState.src = gMovMapFillStPool2;
    gMovMapFillState.movement = (u8)move;

    if (unitId == 0)
    {
        gMovMapFillState.hasUnit = FALSE;
    }
    else
    {
        gMovMapFillState.hasUnit = TRUE;
        gMovMapFillState.unitId = (u8)unitId;
    }
    gMovMapFillState.maxMovementValue = MAP_MOVEMENT_MAX;

    gMovMapFillState.dst->xPos = (s8)sx;
    gMovMapFillState.dst->yPos = (s8)sy;
    gMovMapFillState.dst->connexion = 5;
    gMovMapFillState.dst->leastMoveCost = 0;

    s_work[(sy + 1) * STRIDE + (sx + 1)] = 0;

    gMovMapFillState.dst++;
    gMovMapFillState.dst->connexion = 4;
    for (i = 0; i < STRIDE; i++)
    MapFloodCore();

    for (i = 0; i < w * h; i++)
        out[i] = s_work[(i / w + 1) * STRIDE + (i % w + 1)];

    oracle_emit_longs(c, out, (int)(w * h));
}
