#!/usr/bin/env python3
"""
用**宿主机 C 编译器**验证数据表提取结果。

## 为什么需要这一步

自己写个解析器、再自己写个检查，只能证明"我算得跟我自己一致"。
C 的指定初始化器有几条不直观的语义（未指定下标填 0、长度 = 最大下标 + 1、
`s8` 截断），任何一条理解错都会让整张表错位——而且是**静默错位**。

所以这里的做法是：

  1. 把表定义原样抽成一个独立的 `.c`
  2. 用 clang 编译它，让编译器按 C 标准算出真实字节
  3. 把编译产物里的符号字节 dump 出来
  4. 与 `parse_c_tables.py` 的 JSON 逐字节比对

**判据是编译器，不是我的理解。**

用法:
    python3 tools/pipeline/extract/verify_tables.py
"""
import json
import os
import re
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.abspath(os.path.join(HERE, "..", "..", ".."))
DECOMP = os.path.join(REPO, "third_party", "fireemblem8j")
SRC = os.path.join(DECOMP, "src/data/data_terrains.c")
HDR = os.path.join(DECOMP, "include/constants/terrains.h")

ARRAY_RX = re.compile(
    r"(?:CONST_DATA|const)\s+(\w+)\s+(\w+)\s*\[\s*\]\s*=\s*\{.*?\n\};",
    re.S,
)


def build_probe(arrays_src, enum_names, outdir):
    """拼出一个能独立编译的探针程序，并在运行时打印每张表的字节。"""
    # 不写 extern 声明：定义就在上面，直接 sizeof 即可。
    # 写 `extern const signed char X[]` 会与 `s8 X[]`（非 const）冲突。
    dumps = "\n".join(
        f'''    printf("{n} ");
    for (i = 0; i < (int)sizeof({n}); i++) printf("%d ", (int){n}[i]);
    printf("\\n");'''
        for n in enum_names
    )

    probe = f'''#include <stdio.h>
#include <stdint.h>

#define CONST_DATA
#define ARRAY_COUNT(a) (sizeof(a) / sizeof((a)[0]))

/* GBA 的那套 typedef，探针里自己补上，免得去拖 global.h 的一大串依赖 */
typedef signed char   s8;
typedef unsigned char u8;
typedef signed short  s16;
typedef unsigned short u16;
typedef signed int    s32;
typedef unsigned int  u32;

/* 只取表定义本身。顺带把 `[TERRAIN_X]` 展开成数字下标——
   反编译源码里的下标是枚举名，这里用同等价的枚举定义，
   编译器会算出与真实构建完全一样的布局。 */
#include "terrains_enum.h"

{arrays_src}


int main(void) {{
    int i;
{dumps}
    return 0;
}}
'''
    with open(os.path.join(outdir, "probe.c"), "w") as f:
        f.write(probe)

    # 地形枚举：直接用原头文件里的 enum 块
    hdr = open(HDR, encoding="utf-8", errors="replace").read()
    block = max(re.findall(r"enum\s*\w*\s*\{(.*?)\}", hdr, re.S), key=len)
    with open(os.path.join(outdir, "terrains_enum.h"), "w") as f:
        f.write("enum {\n" + block + "\n};\n")


def arrays_source():
    """抽出 data_terrains.c 里所有 `CONST_DATA s8 X[] = {...};` 定义"""
    text = open(SRC, encoding="utf-8", errors="replace").read()
    return "\n\n".join(m.group(0) for m in ARRAY_RX.finditer(text))


def main():
    json_path = os.path.join(HERE, "..", "out", "tables", "terrains.json")
    if not os.path.exists(json_path):
        print("错误：先跑 parse_c_tables.py 生成 JSON", file=sys.stderr)
        return 1
    data = json.load(open(json_path, encoding="utf-8"))
    tables = data["tables"]

    # 只验证 s8 的表（探针里按 signed char dump）
    s8_tables = {k: v for k, v in tables.items() if v["type"] in ("s8", "u8")}
    print(f"待验证 {len(s8_tables)} 张表（s8/u8）")

    with tempfile.TemporaryDirectory() as tmp:
        build_probe(arrays_source(), list(s8_tables), tmp)

        exe = os.path.join(tmp, "probe")
        r = subprocess.run(
            ["clang", "-std=gnu89", "-O0", "-w",
             os.path.join(tmp, "probe.c"), "-o", exe],
            capture_output=True, text=True,
        )
        if r.returncode != 0:
            print("编译失败:", file=sys.stderr)
            print(r.stderr[:3000], file=sys.stderr)
            return 1

        r = subprocess.run([exe], capture_output=True, text=True)
        if r.returncode != 0:
            print("探针运行失败", file=sys.stderr)
            return 1

        # 解析 dump
        got = {}
        for line in r.stdout.split("\n"):
            parts = line.split()
            if len(parts) >= 2:
                got[parts[0]] = [int(x) for x in parts[1:]]

    # --- 比对 ---
    bad = []
    for name, tbl in s8_tables.items():
        mine = tbl["values"]
        theirs = got.get(name)
        if theirs is None:
            bad.append((name, "探针没有这张表", len(mine), 0))
            continue
        # C 侧长度由编译器定；以它为准
        if len(mine) != len(theirs):
            bad.append((name, "长度不一致", len(mine), len(theirs)))
            continue
        for i, (a, b) in enumerate(zip(mine, theirs)):
            if a != b:
                bad.append((name, f"下标 {i} 不一致", a, b))
                break

    print()
    if not bad:
        total = sum(len(v["values"]) for v in s8_tables.values())
        print(f"✅ {len(s8_tables)} 张表 / {total} 个值，与 C 编译器结果**逐字节一致**")
        return 0

    print(f"❌ {len(bad)} 张表不一致：")
    for name, why, a, b in bad[:15]:
        print(f"  {name}: {why}  (python={a}, clang={b})")
    return 1


if __name__ == "__main__":
    sys.exit(main())
