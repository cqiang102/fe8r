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


def build_probe(arrays_src, enum_names, outdir, enum_headers=None):
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

    # 枚举：把所有相关头文件里的 enum 块拼到一起给探针用
    out = []
    for h in (enum_headers or [HDR]):
        hdr = open(h, encoding="utf-8", errors="replace").read()
        blocks = re.findall(r"enum\s*\w*\s*\{(.*?)\}", hdr, re.S)
        if blocks:
            # 每个块自带结尾逗号，拼起来会出现 `,,`，先剥掉
            out.append(max(blocks, key=len).rstrip().rstrip(","))
    with open(os.path.join(outdir, "terrains_enum.h"), "w") as f:
        f.write("enum {\n" + ",\n".join(out) + "\n};\n")


def arrays_source(path):
    """抽出源文件里所有 `CONST_DATA <type> X[] = {...};` 定义"""
    text = open(path, encoding="utf-8", errors="replace").read()
    return "\n\n".join(m.group(0) for m in ARRAY_RX.finditer(text))


def verify_one(json_name):
    """验证一个 JSON 对应的源文件里的所有表"""
    json_path = os.path.join(HERE, "..", "out", "tables", json_name)
    if not os.path.exists(json_path):
        print(f"错误：先跑 parse_c_tables.py 生成 {json_name}", file=sys.stderr)
        return 1
    data = json.load(open(json_path, encoding="utf-8"))
    tables = data["tables"]
    src = os.path.join(DECOMP, data["source"])

    # 探针里按 signed char dump；u8 的值在 0..255，signed char 读回来是负的，
    # 所以比对时统一折算回 0..255
    s8_tables = {k: v for k, v in tables.items() if v["type"] in ("s8", "u8")}
    print(f"── {data['source']} ──")
    print(f"待验证 {len(s8_tables)} 张表")

    with tempfile.TemporaryDirectory() as tmp:
        enums = [os.path.join(DECOMP, e) for e in data.get("enums", [])] or None
        build_probe(arrays_source(src), list(s8_tables), tmp, enums)

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

        # 解析 dump。signed char dump 出来的负数折算回 0..255，
        # 这样 s8 表和 u8 表能用同一套比对逻辑。
        got = {}
        for line in r.stdout.split("\n"):
            parts = line.split()
            if len(parts) >= 2:
                got[parts[0]] = [int(x) & 0xFF for x in parts[1:]]

    # --- 比对 ---
    bad = []
    for name, tbl in s8_tables.items():
        mine = [x & 0xFF for x in tbl["values"]]
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


def main():
    sources = ["terrains.json", "itemuse.json"]
    failed = 0
    for name in sources:
        if verify_one(name) != 0:
            failed += 1
    print()
    if failed == 0:
        print(f"全部 {len(sources)} 个数据表文件通过")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
