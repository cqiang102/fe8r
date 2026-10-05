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

SRC = "src/data/frontier_df3_unitdef_b/frontier_df3_unitdef_b.c"


def strip_section_attrs(text):
    """机械去掉 `__attribute__((section("...")))`（Mach-O 不接受 `.data.foo`）。"""
    return re.sub(r'__attribute__\s*\(\(\s*section\s*\([^)]*\)\s*\)\)', " ", text)


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
    open(cpath, "w").write(src + PROBE.replace("@BODY@", ""))
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
    open(cpath, "w").write(src + PROBE.replace("@BODY@", "\n".join(body)))

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

    path = os.path.join(DECOMP, SRC)
    if not os.path.exists(path):
        print(f"错误：找不到 {path}", file=sys.stderr)
        return 1

    raw = open(path, encoding="utf-8", errors="replace").read()
    names = re.findall(r"^struct UnitDefinition\s+(\w+)\[\]", raw, re.M)
    print(f"找到 {len(names)} 张单位配置表")
    if a.limit:
        names = names[:a.limit]
    if not names:
        return 1

    with tempfile.TemporaryDirectory() as tmp:
        src = strip_section_attrs(raw)
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
        "source": SRC,
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
