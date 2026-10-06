#!/usr/bin/env python3
"""
提取**章节单位配置表**（`struct UnitDefinition`）。

## 数据长什么样

`src/data/frontier_df3_unitdef_b/frontier_df3_unitdef_b.c` 里有 111 张表、
约 3585 条单位配置，是**带字段名的可读初始化器**：

    { .charIndex=0x2, .classIndex=0x7, .leaderCharIndex=0x1, .level=0xA,
      .xPosition=0x2, .yPosition=0x6, .items={0x17, 0x4, 0x6C} },
    { .charIndex=0x5F, .classIndex=0x5E, .autolevel=0x1, .allegiance=0x2,
      .level=0x3, .xPosition=0x16, .yPosition=0x1, .items={0x25}, .ai={0x3,0x3,0xC} },
    {0},   ← 终止符

字段全部具名、结构有文档（`include/bmunit.h`），**不需要考古**。

## 为什么还是"让编译器算"

`xPosition` / `yPosition` / `allegiance` / `level` 都是**位域**：

    /* 04 */ u16 xPosition : 6;
    /* 04 */ u16 yPosition : 6;
    /* 03 */ u8 allegiance : 2;
    /* 03 */ u8 level      : 5;

按文本读会把它们当成独立的数字 —— 但源码里写的是**未打包的字段值**，
真正的存储形态要靠编译器打包。所以这里让编译器算。

## ⚠️ 但**不能**打印原始字节

宿主上 `const void* redas` 是 8 字节（GBA 是 4），位域的分配顺序也不保证
与 GBA 一致。所以探针打印的是**解码后的字段值**，不是结构体的字节 ——
这样产物与宿主布局无关，只与源码有关。

（这个坑在章节事件那边踩过：打印原始字节导致产物平台相关，20/21 张表
macOS 与 Linux 不一致。）

用法:
    python3 tools/pipeline/extract/parse_unit_defs.py --out out/tables
"""
import argparse
import json
import os
import re
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.abspath(os.path.join(HERE, "..", "..", ".."))
DECOMP = os.path.join(REPO, "third_party", "fireemblem8j")
HOST = os.path.join(REPO, "tools", "oracle", "host")

# 要扫的源文件。两批格式**完全一样**（都是 `struct UnitDefinition` 具名初始化器）：
#   1. frontier_df3_unitdef_b.c —— 111 张表（章节增援/遭遇战配置）
#   2. UnitDef_Event_*_ref/*.c  —— 13 张表（**章节事件里直接引用的我方/敌方单位**）
#
# 第 2 批是"章节 → 事件组 → playerUnitsInNormal"那一跳的落点，
# 名字形如 `UnitDef_Event_Ch8Ally` / `UnitDef_Event_PrologueEnemy`。
# 要扫的源文件。三批格式**完全一样**（都是 `struct UnitDefinition` 具名初始化器）：
#   1. frontier_df3_unitdef_b.c —— 章节增援/遭遇战配置
#   2. UnitDef_Event_*_ref/*.c  —— 章节事件引用的单位
#   3. data_prologue_event_udefs.c —— **不在 `_ref` 目录里**的那批
#
# 第 3 批是踩坑补上的：`UnitDef_Event_PrologueAlly`（序章的我方单位）
# 定义在 `data_prologue_event_udefs.c`，不是任何 `_ref` 目录，
# 只按 `_ref` 扫会漏掉它 —— 表现为"章节 0 装配不出来"。
# ⚠️ **必须覆盖整个 src/data/ 树。**
#
# 我第一版只列了三个模式（`UnitDef_Event_*_ref/` 等），结果**少扫了一大批**：
# `UnitDef_Event_PrologueThroneRoomUnits` 定义在
# `src/data/worldmap_gmapunit/dat_worldmap_gmapunit_p1311.c` ——
# 目录名和单位毫无关系，靠"猜目录名"必然漏。
#
# 后果：脚本里的 `LOAD1(1, UnitDef_Event_PrologueThroneRoomUnits)`
# 在游戏里报"缺单位表"，**序章王座厅的单位根本放不出来**。
#
# 现在改成**全树扫描**（凡 `src/data/**/*.c`），并用独立的
# `check_independent_counts()` 交叉校验 —— 不再依赖我猜的目录名。
SRC_GLOBS = [
    "src/data/**/*.c",
]


def strip_section_attrs(text):
    """机械去掉 `__attribute__((section("...")))`（Mach-O 不接受 `.data.foo`）。"""
    return re.sub(r'__attribute__\s*\(\(\s*section\s*\([^)]*\)\s*\)\)', " ", text)


def reda_names_from_includes():
    """从 `eventcall.h` 里读出所有以 `struct REDA` 声明的符号名。

    只剥离**确实冲突的**那些 —— 第一版按类型通配剥离，
    把 `frontier_df4_banim_b_076_90B4DC` 这类**有用的**声明也删了，
    结果报 "use of undeclared identifier"。
    """
    import glob as _g
    names = set()
    for h in _g.glob(os.path.join(DECOMP, "include", "*.h")):
        try:
            t = open(h, encoding="utf-8", errors="replace").read()
        except OSError:
            continue
        for m in re.finditer(
                r"extern\s+\w*\s*CONST_DATA\s+struct\s+REDA\s+(\w+)\s*\[",
                t):
            names.add(m.group(1))
    return names


def strip_redas(text):
    """剥掉 `.redas=...` 初始化项（用括号配平扫描，不用正则）。

    ## 为什么可以剥

    我们只取 `UnitDefinition` 的
    `charIndex/classIndex/level/x/y/items/...` —— **`redas`（增援数据）
    不在输出里**。而它正是全部编译冲突的来源。

    ## 为什么不能用 `\w+` 正则

    源码里的写法是**强制转换表达式**，不是标识符：

        .redas=(const struct REDA *)((const u8 *)REDA_PrologueGradoCavalry2)

    我第一版用 `\.redas\s*=\s*\w+` 匹配，于是这一行**原样留下**，
    报错照旧（`use of undeclared identifier`）。

    这里改成**扫描到括号配平的末尾**（顶层遇到 `,` 或 `}` 就停）。
    """
    # ⚠️ 先去掉注释 —— `.redas` 在注释里也出现过，
    # 直接剥会破坏块注释，报 `unterminated /* comment`。
    text = re.sub(r"/\*.*?\*/", " ", text, flags=re.S)
    text = re.sub(r"//[^\n]*", " ", text)

    out = []
    i = 0
    while True:
        j = text.find(".redas", i)
        if j < 0:
            out.append(text[i:])
            break
        out.append(text[i:j])
        k = text.find("=", j)
        if k < 0:
            out.append(text[j:])
            break
        k += 1
        depth = 0
        while k < len(text):
            c = text[k]
            if c == "(":
                depth += 1
            elif c == ")":
                depth -= 1
            elif depth == 0 and c in ",}":
                break
            k += 1
        # 停在 `,` -> 保留逗号并吃掉它；停在 `}` -> 什么都不加。
        # （我第一版反了：停在 `}` 时补了个逗号，于是 `.foo=1,}` 语法错。）
        out.append(".redas=0")
        if k < len(text) and text[k] == ",":
            out.append(",")
            k += 1
        i = k
    return "".join(out)


def reda_decls(text):
    """为所有被引用的 `REDA_*` 生成 extern 声明。

    ⚠️ **不要减去 `reda_names_from_includes()` 的结果。**
    我第一版减了，理由是"这些在 `eventcall.h` 里已经声明过" ——
    但**探针 C 只 include 了 `global.h` 和 `bmunit.h`，没有 include
    `eventcall.h`**，所以那些名字在探针里同样未声明。

    症状：`use of undeclared identifier 'REDA_Ch10AEnemy_4_2'` 照旧。
    类型一致时重复声明无害，所以这里**全都补上**。
    """
    refd = set(re.findall(r"\b(REDA\w*)\b", text))
    # 源码里**已经有定义**的不要重复声明 —— 它们的类型可能是 `u8[]`
    # （`strip_conflicting_externs` 把冲突的名字改成了 `..._u32`），
    # 再补一个 `struct REDA[]` 会报 redeclaration with a different type。
    defined = set(re.findall(r"\b(REDA\w*)\s*\[?[^;=]*\]?\s*=", text))
    # `_u32` 后缀是 `strip_conflicting_externs` 改名产生的 ——
    # 那些名字已经有 `u32[]` 定义，再补 `struct REDA[]` 会报
    # `redefinition with a different type`。
    skip = {n for n in refd if n.endswith("_u32")}
    return "\n".join(
        f"extern struct REDA {n}[];" for n in sorted(refd - defined - skip)
    )


def strip_conflicting_externs(text):
    """去掉 `extern const u8 Xxx[];` 这类**前置声明**。

    `UnitDef_Event_*_ref/*.c` 为了引用 REDA（增援数据）会在文件头写
        extern const u8 REDA_PrologueGradoCavalry0[];
    而 `eventcall.h` 里的真实声明是
        extern CONST_DATA struct REDA REDA_PrologueGradoCavalry0[];
    两者类型冲突，合到一个 TU 里编会报
    "redeclaration with a different type"。

    这些前置声明对我们**没有用**（我们要的是 `struct UnitDefinition` 表），
    所以机械删掉。与 `strip_section_attrs` 同类的处理：
    **只动声明，不动任何数据。**
    """
    # 只剥离**名字在 eventcall.h 里声明为 `struct REDA`** 的那些。
    # 通配剥离会把有用的声明（如 frontier_df4_banim_b_*）也删掉。
    bad = reda_names_from_includes()

    # 1) 去掉 `extern const u8 REDA_X[];` 这类**前置声明**（无用且冲突）
    out = []
    for line in text.split("\n"):
        m = re.match(
            r"^\s*extern\s+const\s+(?:u8|u16|u32|s8|s16|s32|int|unsigned)\s+"
            r"(\w+)\s*\[\s*\]\s*;\s*$", line)
        if m and m.group(1) in bad:
            continue
        out.append(line)
    text = "\n".join(out)

    # 2) 还有**定义**层面的冲突：`data_prologue_event_udefs.c` 里
    #    `u32 REDAs_PrologueEnemy1[] = {...}` 与 eventcall.h 的
    #    `struct REDA REDAs_PrologueEnemy1[]` 类型不符。
    #
    #    我们不需要这些 REDA 数组（只读 UnitDefinition 的
    #    charIndex/class/level/x/y/items）。所以把该文件里这些名字
    #    **整体改名** —— 定义与引用一起改，语义不变，
    #    只是不再与 eventcall.h 的声明撞名。
    for name in sorted(bad):
        if re.search(rf"\b{re.escape(name)}\s*\[", text):
            text = re.sub(rf"\b{re.escape(name)}\b", f"{name}_u32", text)
    return text


def compile_obj(tmp, src):
    cpath = os.path.join(tmp, "unitdef.c")
    open(cpath, "w").write(src)
    obj = os.path.join(tmp, "unitdef.o")
    cmd = [
        "clang", "-std=gnu89", "-O0", "-w", "-c",
        "-include", os.path.join(HOST, "host_prelude.h"),
        "-I", HOST,
        "-I", os.path.join(DECOMP, "include"),
        "-I", DECOMP,
        "-o", obj, cpath,
    ]
    r = subprocess.run(cmd, capture_output=True, text=True)
    if r.returncode != 0:
        print("❌ 编译失败:", file=sys.stderr)
        print(r.stderr[-1500:], file=sys.stderr)
        return None
    return obj


def undefined_symbols(obj):
    r = subprocess.run(["nm", "-u", obj], capture_output=True, text=True)
    out = []
    for line in r.stdout.split("\n"):
        p = line.split()
        if not p:
            continue
        n = p[-1]
        out.append(n[1:] if n.startswith("_") else n)
    return out


def symbol_sizes(obj, names):
    """用 `nm -n` 的地址差求每张表的**字节长度**。

    ⚠️ **不能"扫到 charIndex==0 就停"**：
    `{0}` 是**同一张表里分组的分隔符**（玩家单位组 / 敌军组 / 增援组），
    不是表的结尾。我第一版就按终止符停，111 张表只导出 9 条 ——
    而实际有 3585 条。

    也不能用 `nm -S`：macOS 的 `nm` 没有这个选项（那是 GNU binutils 的）。
    """
    r = subprocess.run(["nm", "-n", obj], capture_output=True, text=True)
    if r.returncode != 0:
        return {}
    entries = []
    for line in r.stdout.split("\n"):
        p = line.split()
        if len(p) != 3:
            continue
        try:
            addr = int(p[0], 16)
        except ValueError:
            continue
        n = p[2]
        entries.append((addr, n[1:] if n.startswith("_") else n))
    entries.sort()

    addr_of = dict((n, a) for a, n in entries)
    out = {}
    for name in names:
        a = addr_of.get(name)
        if a is None:
            continue
        nxt = next((x for x, _ in entries if x > a), None)
        if nxt is not None:
            out[name] = nxt - a
    return out


PROBE = r"""
#include "global.h"
#include "bmunit.h"
#include <stdio.h>

/* ★ 补上被引用但没声明的 REDA 数组。
 *
 * 为什么需要：`UnitDefinition.redas` 指向 `struct REDA` 增援数据，
 * 而哪些 `REDA_*` 在 `eventcall.h` 里声明过**并不完整** ——
 * 全树扫描之后出现了 `REDA_Ch10AEnemy_4_2` 这类"被引用但未声明"的
 * （报 `use of undeclared identifier`）。
 *
 * 我们要的只是 `UnitDefinition` 的字段，REDA 的具体内容无关紧要 ——
 * 所以给未声明的补一个 extern 就够，**不改任何数据**。
 */
@REDA_DECLS@

int main(void)
{
    printf("SIZEOF %zu\n", sizeof(struct UnitDefinition));
@BODY@
    return 0;
}
"""


def host_sizeof(tmp, src, stub_syms):
    """让探针自己打印 `sizeof(struct UnitDefinition)`。

    不在这里硬编码：宿主上的大小取决于指针宽度与位域布局，
    写死会在换平台时静默算错元素个数。
    """
    cpath = os.path.join(tmp, "szof.c")
    open(cpath, "w").write(src + PROBE.replace("@BODY@", "").replace("@REDA_DECLS@", reda_decls(src)))
    # ⚠️ 桩要在这里自己生成 —— 之前指望调用方先生成，
    # 结果 sizeof 探针先跑，链接器报 "no such file or directory"。
    stub = os.path.join(tmp, "stubs_szof.c")
    with open(stub, "w") as f:
        f.write('#include "global.h"\n')
        for sym in stub_syms:
            f.write(f"unsigned char {sym}[256] = {{0}};\n")
    exe = os.path.join(tmp, "szof")
    cmd = [
        "clang", "-std=gnu89", "-O0", "-w",
        "-include", os.path.join(HOST, "host_prelude.h"),
        "-I", HOST,
        "-I", os.path.join(DECOMP, "include"),
        "-I", DECOMP,
        stub, cpath, "-o", exe,
    ]
    r = subprocess.run(cmd, capture_output=True, text=True)
    if r.returncode != 0:
        print("❌ sizeof 探针编译失败:", file=sys.stderr)
        print(r.stderr[-800:], file=sys.stderr)
        return None
    run = subprocess.run([exe], capture_output=True, text=True)
    for line in run.stdout.split("\n"):
        if line.startswith("SIZEOF "):
            return int(line.split()[1])
    return None


def build_probe(tmp, src, names, stub_syms, counts):
    body = []
    for n in names:
        # ⚠️ 刻意**不**写 `extern struct UnitDefinition {n}[];`：
        # 那样声明出来的是 incomplete type，`sizeof` 用不了，
        # 就只能靠 `nm` 的地址差求长度 —— 而那是**平台相关**的
        # （ELF 与 Mach-O 对"下一个符号"的取法不同，
        #   实测 Linux 2629 条 / macOS 2797 条）。
        #
        # 源码已经拼在本探针里，数组是**已定义**的，直接用 sizeof 即可。
        # 这是编译器算的，两边必然一致。
        body.append(f'  {{ int i = 0;')
        body.append(f'    const long cnt = (long)(sizeof({n}) / sizeof({n}[0]));')
        # 按**表的真实元素个数**遍历，遇到 `{0}` 也照常输出 ——
        # 那是分组分隔符，不是结尾（见 symbol_sizes 的说明）。
        body.append('    while (i < cnt) {')
        body.append(f'      const struct UnitDefinition* u = &{n}[i];')
        body.append(f'      printf("U {n} %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d\\n",')
        body.append('        i, u->charIndex, u->classIndex, u->leaderCharIndex,')
        body.append('        (int)u->allegiance, (int)u->level, (int)u->autolevel,')
        body.append('        (int)u->xPosition, (int)u->yPosition,')
        body.append('        (int)u->genMonster, (int)u->itemDrop, (int)u->sumFlag,')
        body.append('        u->items[0], u->items[1], u->items[2], u->items[3]);')
        body.append('      i++; }')
        body.append(f'    printf("END {n} %d\\n", i); }}')

    cpath = os.path.join(tmp, "probe.c")
    open(cpath, "w").write(src + PROBE.replace("@BODY@", "\n".join(body)).replace("@REDA_DECLS@", reda_decls(src)))

    stub = os.path.join(tmp, "stubs.c")
    with open(stub, "w") as f:
        f.write('#include "global.h"\n')
        for s in stub_syms:
            if s in names:
                continue
            f.write(f"unsigned char {s}[256] = {{0}};\n")

    exe = os.path.join(tmp, "probe")
    cmd = [
        "clang", "-std=gnu89", "-O0", "-w",
        "-include", os.path.join(HOST, "host_prelude.h"),
        "-I", HOST,
        "-I", os.path.join(DECOMP, "include"),
        "-I", DECOMP,
        stub, cpath, "-o", exe,
    ]
    r = subprocess.run(cmd, capture_output=True, text=True)
    if r.returncode != 0:
        print("❌ 探针编译失败:", file=sys.stderr)
        print(r.stderr[-1500:], file=sys.stderr)
        return None
    run = subprocess.run([exe], capture_output=True, text=True)
    if run.returncode != 0:
        print(f"❌ 探针运行失败（{run.returncode}）", file=sys.stderr)
        return None
    return run.stdout


FIELDS = ("index", "charIndex", "classIndex", "leaderCharIndex", "allegiance",
          "level", "autolevel", "x", "y", "genMonster", "itemDrop", "sumFlag",
          "item0", "item1", "item2", "item3")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", default=os.path.join(HERE, "..", "out", "tables"))
    ap.add_argument("--limit", type=int, default=0)
    a = ap.parse_args()

    import glob as _glob
    files = []
    for g in SRC_GLOBS:
        # ⚠️ **必须 `recursive=True`** —— 否则 `**` 不递归展开，
        # `src/data/**/*.c` 只等价于 `src/data/*/*.c`，
        # **直接放在 `src/data/` 下的文件全被漏掉**
        # （`data_prologue_event_udefs.c` 就是其中之一 ——
        #   `UnitDef_Event_PrologueAlly` 因此消失）。
        files.extend(sorted(_glob.glob(os.path.join(DECOMP, g),
                                       recursive=True)))
    if not files:
        print("错误：没找到任何单位配置源文件", file=sys.stderr)
        return 1
    print(f"扫描 {len(files)} 个源文件")

    raw = ""
    names = []
    for f in files:
        t = open(f, encoding="utf-8", errors="replace").read()
        # ⚠️ 不能要求行首就是 `struct UnitDefinition` ——
        # `UnitDef_Event_*_ref/*.c` 里的写法是：
        #     SECTION(".rodata.dat_...") struct UnitDefinition Xxx[] =
        # 前面带一个 SECTION(...)。第一版按行首匹配，13 个文件一个表都没找到。
        found = re.findall(
            r"struct\s+UnitDefinition\s+(\w+)\s*\[\s*\]", t)
        if found:
            raw += "\n" + strip_conflicting_externs(strip_section_attrs(t))
            names.extend(found)
    print(f"找到 {len(names)} 张单位配置表")
    if a.limit:
        names = names[:a.limit]
    if not names:
        return 1

    with tempfile.TemporaryDirectory() as tmp:
        # ★ 把被引用但未声明的 `REDA_*` 的 extern 声明**拼进源本身**。
        #
        # 只在 PROBE 模板里替换是不够的 —— `compile_obj` 写的是**纯 src**，
        # 而报错（`use of undeclared identifier`）正是发生在这一步。
        # 我第一版只改了 PROBE，于是错误照旧。
        src = (reda_decls(raw) + "\n"
               + strip_redas(strip_section_attrs(raw)))
        obj = compile_obj(tmp, src)
        if obj is None:
            return 1
        undef = undefined_symbols(obj)
        print(f"  未定义符号 {len(undef)} 个（生成桩）")
        # 元素个数由**探针里的 sizeof** 算，不在这里做任何长度推断。
        out = build_probe(tmp, src, names, undef, {})
    if out is None:
        return 1

    tables = {}
    size_of = None
    for line in out.split("\n"):
        if line.startswith("SIZEOF "):
            size_of = int(line.split()[1])
            continue
        p = line.split()
        if not p:
            continue
        if p[0] == "U":
            name = p[1]
            vals = [int(x) for x in p[2:]]
            entry = dict(zip(FIELDS, vals))
            tables.setdefault(name, []).append(entry)
        elif p[0] == "END":
            tables.setdefault(p[1], [])

    total = sum(len(v) for v in tables.values())
    print(f"宿主上 sizeof(UnitDefinition) = {size_of}（GBA 上是 18，"
          f"差异来自指针宽度与位域布局）")
    print(f"\n导出 {len(tables)} 张表 / {total} 条单位配置")

    # 抽查
    first = names[0]
    for e in tables[first][:3]:
        print(f"  座位 {e['index']}: char={e['charIndex']} class={e['classIndex']} "
              f"阵营={e['allegiance']} Lv{e['level']} ({e['x']},{e['y']}) "
              f"道具={[e['item0'], e['item1'], e['item2'], e['item3']]}")

    # 自洽性：坐标必须落在 GBA 地图范围内（6 位位域 → 0..63）
    bad = []
    for name, rows in tables.items():
        for e in rows:
            if not (0 <= e['x'] <= 63 and 0 <= e['y'] <= 63):
                bad.append(f"{name}[{e['index']}] 坐标越界 {e['x']},{e['y']}")
            if e['allegiance'] > 2:
                bad.append(f"{name}[{e['index']}] 阵营 {e['allegiance']} 越界")
    if bad:
        print(f"\n❌ 自洽性检查失败 {len(bad)} 项:", file=sys.stderr)
        for b in bad[:8]:
            print(f"  {b}", file=sys.stderr)
        return 1
    print("\n✅ 自洽性检查通过（坐标 0..63、阵营 0..2）")

    os.makedirs(a.out, exist_ok=True)
    payload = {
        "sources": [os.path.relpath(f, DECOMP) for f in files],
        "hostSizeof": size_of,
        "gbaSizeof": 18,
        "tables": tables,
    }
    dst = os.path.join(a.out, "unit_defs.json")
    with open(dst, "w", encoding="utf-8") as f:
        json.dump(payload, f, ensure_ascii=False, indent=1)
    print(f"\n→ {dst}  ({os.path.getsize(dst) // 1024} KB)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
