/* host_prelude.h —— 让 GBA 反编译代码能在 macOS/host 上编译。
   用 `clang -include host_prelude.h` 强制最先加载。
   完全不修改上游 third_party/fireemblem8j 的任何文件。 */
#ifndef HOST_PRELUDE_H
#define HOST_PRELUDE_H

/* ---- 1. 让 include/prelude.h 整体失效 ----
   （上游的 guard 是空的：#ifndef PRELUDE_H 但从不 #define，所以外部定义即可屏蔽） */
#define PRELUDE_H 1
#define ALIGN(m) __attribute__((aligned(m)))
#define BITPACKED __attribute__((packed))
#define SECTION(name)
#define CONST_DATA
#define EWRAM_OVERLAY(id)
#define SHOULD_BE_CONST
#define NAKEDFUNC

/* ---- 2. 段属性宏：Mach-O 需要 "segment,section" 格式，直接去掉 ----
   技巧：先真正加载一次 include/gba/defines.h（让它的 guard 生效），
   再 #undef + 重定义。之后 global.h 再 include 时 guard 已定义 → no-op，
   我们的定义得以保留。 */
#include "gba/defines.h"
#undef IWRAM_DATA
#undef EWRAM_DATA
#undef ALIGNED
#define IWRAM_DATA
#define EWRAM_DATA
#define ALIGNED(n) __attribute__((aligned(n)))

/* ---- 3. 修正 include 顺序问题 ----
   include/eventcall.h 在 include/muctrl.h 之前就声明了
   `extern struct REDA gUdefREDAs[];`，而 struct REDA 定义在 muctrl.h 里。
   agbcc 容忍数组元素类型不完整，现代 clang 不容忍。
   办法：在预包含头里先把 global.h 与 muctrl.h 拉进来，
   之后主文件再 include 时 guard 生效、变成 no-op。 */
#include "global.h"
#include "muctrl.h"
#include "fontgrp.h"

#endif /* HOST_PRELUDE_H */
