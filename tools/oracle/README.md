# C Oracle

**在开发机上编译真实的 FE8 反编译 C 代码，作为 Dart 实现的判卷标准。**

反编译项目的 C 代码经过 `make compare` 的字节级验证，是**绝对权威**。本工具把其中可移植的部分编译到 macOS 原生执行，用测试向量对照 Dart 实现，从而实现"AI 生成 + AI 测试"的闭环。

> **不需要 ROM、不需要 arm 工具链、不需要修改上游任何文件。**

```bash
./verify.sh              # 总入口，约 5 秒
./verify.sh --coverage   # 追加全量编译覆盖率，约 80 秒
```

---

## 现状

| 指标 | 值 |
|---|---|
| 全量编译覆盖率 | **6175 / 6213 = 99.39%** |
| 已实现场景 | 4 个 |
| 已覆盖向量 | **451 条** |
| C ↔ 独立 Python 交叉一致 | **451 / 451** |

| 场景 | 目标函数 | 向量数 | 覆盖的关键点 |
|---|---|---:|---|
| `rng` | `NextRN` / `NextRN_100` / `NextRN_N` / `Roll2RN` / `AdvanceGetLCGRNValue` | 161 | 乱数算法与序列（1:1 保真最容易出错处） |
| `battle_unit` | `ComputeBattleUnitAvoidRate` / `BaseDefense` / `DodgeRate` | 131 | 嵌套 struct、算术、**负数钳位分支** |
| `crit_rate` | `ComputeBattleUnitEffectiveCritRate` | 90 | 多分支归零、**循环在空道具处短路** |
| `unit_defense` | `GetUnitDefense` | 69 | 跨文件调用链、嵌套 struct 指针解引用 |

---

## 目录结构

```
tools/oracle/
├── verify.sh              ⭐ 总入口（CI 调用这个）
├── build.sh               构建单个/全部场景
├── run_all.sh             跑向量，产出或校验 golden
├── gen_vectors.py         生成测试向量（固定种子，可复现）
├── crosscheck.py          独立 Python 实现，交叉校验 harness 管道
├── compile_coverage.sh    全量编译覆盖率统计
├── host/
│   └── host_prelude.h     ⭐ 让 GBA 代码在 host 编译的核心兼容头
├── lib/
│   ├── oracle_io.h        测试向量 I/O 框架
│   └── oracle_io.c
├── scenarios/
│   ├── <名字>.c           场景实现（只需写 oracle_run）
│   └── <名字>.deps        该场景依赖的反编译源文件列表
├── vectors/
│   ├── <名字>.cases.tsv       测试向量（提交）
│   └── <名字>.expected.tsv    golden 期望值（提交）
└── out/                   构建产物（gitignore）
```

---

## 核心机制：`host/host_prelude.h`

只靠一个预包含头，就能让 GBA 代码在 host 上编译，且**不碰上游一行代码**。

```bash
clang -std=gnu89 -O2 -include host/host_prelude.h \
      -I third_party/fireemblem8j/include -I third_party/fireemblem8j \
      -o oracle scenario.c lib/oracle_io.c <deps...>
```

它解决三类 host/GBA 差异：

| # | 问题 | 解法 |
|---|---|---|
| 1 | `include/prelude.h` 用 `SECTION(".data")` 等 GBA 段属性，Mach-O 要求 `"segment,section"` 格式 | 该文件的 include guard **是空的**（`#ifndef PRELUDE_H` 但从不 `#define`），所以外部 `#define PRELUDE_H 1` 就能让整个文件变 no-op，再自己定义这些宏 |
| 2 | `include/gba/defines.h` 的 `IWRAM_DATA` / `EWRAM_DATA` 同样带段属性 | 该文件 guard 正常，用「**先真加载一次让 guard 生效 → `#undef` → 重定义**」 |
| 3 | `eventcall.h` 在 `muctrl.h` / `fontgrp.h` 之前引用不完整 struct（`REDA` / `Text`）。agbcc 容忍，clang 不容忍 | 在预包含头里先拉入 `global.h` + `muctrl.h` + `fontgrp.h` |

### 编译参数：两个都不能少

| 参数 | 为什么 |
|---|---|
| `-std=gnu89` | C99 的 `extern inline` 语义与 GNU89 **相反**（C99 会产出外部定义）。上游有多个函数（如 `GetItemStatBonuses`、`GetItemIndex`）在多个 `.c` 里重复定义，用 C99 会符号冲突 |
| `-O2` | 上游 agbcc 就在 `-O2` 下编译。GNU89 的 `extern inline` 不产出符号，靠**内联消除**才不产生未定义引用；`-O0` 会链接失败 |

---

## 测试向量格式

刻意选最简单的 TSV，理由：C89 下不需要 JSON 解析器；Dart / Python 一行就能读写；出问题可以直接肉眼 diff。

**输入** `vectors/<场景>.cases.tsv`：

```
# 注释行会被忽略
rng_next_000	seed=0	fn=next	count=8
bu_avoid_edge_02	fn=avoid	battleSpeed=0	terrainAvoid=-5	lck=2
```

**输出** `vectors/<场景>.expected.tsv`：

```
rng_next_000	1,0,0,0,1,0,1,1
bu_avoid_edge_02	0
```

---

## 怎么加一个新场景

**1. 挑函数。** 优先选：
- 无外部依赖或依赖浅（在 `.deps` 里能列完）
- 有分支 / 边界 / 循环（这些才是容易移植错的地方）
- 在关键路径上（战斗公式、AI 评分、寻路）

**2. 写 `scenarios/<名字>.c`。** 只需实现 `oracle_run()`：

```c
#include "global.h"
#include "oracle_io.h"

void oracle_run(const OracleCase* c)
{
    long a = oracle_long(c, "a", 0);          /* 取输入字段，带默认值 */
    const char* fn = oracle_str(c, "fn", "x");

    /* ... 调用真实的反编译函数 ... */

    oracle_emit_long(c, result);              /* 输出结果 */
}
```

**3. 写 `scenarios/<名字>.deps`** —— 每行一个反编译源文件路径（相对 `third_party/fireemblem8j`）：

```
src/SomeFunction.c
src/SomeDependency.c
```

**4. 在 `gen_vectors.py` 加生成函数并注册到 `SCENARIOS`。** 记得带上**手工边界用例**，不要只写随机——随机几乎不会命中边界。

**5. 在 `crosscheck.py` 加独立 Python 实现并注册到 `MODELS`。** 这一步不能省，理由见下。

**6. 跑 `./run_all.sh` 生成 golden，再跑 `./verify.sh` 确认全绿。**

---

## 为什么要有 `crosscheck.py`

C Oracle 用的是真实反编译代码，所以它算出的**数值**是权威的。但 **harness 的管道可能写错**：

- struct 字段填错位置
- TSV 解析错
- 类型截断没模拟对（`s8` / `s16` / `u16`）

这些错误会让 Oracle **安静地给出错误的期望值**，而 Dart 侧"老老实实对齐"就会一起错。`crosscheck.py` 从 C 源码**独立重写**一遍逻辑并逐条比对，两者一致才说明管道是通的。

> 这同时也是 **Dart 侧实现的预演** —— Dart 移植会遇到完全相同的整数截断问题。`crosscheck.py` 里 `s8()` / `s16()` / `c_mod()`（C 的 `%` 向零截断，Python 是向下取整）这些辅助函数，Dart 侧几乎要原样再写一遍。

---

## ⚠️ 已知限制

### 64 位指针导致结构体布局不同

`struct Unit` 含 3 个指针，host 上每个占 8 字节（GBA 是 4 字节）：

| | host (arm64) | GBA (armv4t) |
|---|---:|---:|
| `sizeof(struct Unit)` | **88** | **72** |
| `offsetof(Unit, def)` | **0x1F** | **0x17** |
| `offsetof(Unit, items)` | 0x26 | 0x1E |

**不影响绝大多数逻辑函数**：只要函数用命名字段访问，host 侧的内部自洽布局就给出与 GBA 相同的**逻辑结果**（`unit_defense` 场景就是证明）。

**影响少数函数**：直接对结构体 `memcpy`、按硬编码偏移做指针运算、或处理存档原始块的函数。这类函数标记为 `ORACLE_UNSUPPORTED`，改用代码审查验证。

`diag/layout_probe.c` 可以随时重新测量布局差异。

**曾尝试的修法（均不可行）**：`clang -m32`（macOS 已移除 32 位支持）、`clang --target=wasm32`（缺 sysroot/libc）。
**后路**：`zig cc --target=wasm32-wasi`（32 位指针 + 可移植运行）。

### 剩余 38 个无法编译的源文件

| 数量 | 原因 | 处置 |
|---:|---|---|
| ~16 | 内联汇编（GBA 寄存器 / 指示符 / 助记符） | 硬件相关，**本应豁免** |
| 9 | 源文件里直接写的 `__attribute__((section(...)))` | 数据定义文件，不在 Oracle 范围 |
| 6 | `assignment to cast is illegal`（agbcc 允许 `(u8)x = y`） | 需源码改写或豁免 |
| 其余 7 | 返回类型不匹配 / 类型冲突 / `reent.h` 缺失等 | 逐个处理 |

---

## 与整体验证体系的关系

本工具是五层验证金字塔里的 **L2**：

| 层 | 手段 | 覆盖 |
|---|---|---|
| L0 | 字节级往返验证 | 数据资产（地图 / 文本 / 表） |
| L1 | Dart 单元测试 | 单个函数 |
| **L2** | **C Oracle（本工具）** | 公式、算法、AI 评分、寻路 |
| L3 | 静态契约（乱数消耗序表、事件状态机回放） | 跨操作的时序 |
| L4 | 视觉验证（结构断言 + 参考渲染器 + 多模态） | 渲染输出 |

见 `docs/技术方案.md` §6。
