#!/usr/bin/env python3
"""
提取**章节配置表**（`gChapterDataTable`，79 章）。

## 数据长什么样

`src/data/chapter_settings.h` 是**完全可读的 C**（79 × `struct ROMChapterData`，
每项 0x94 字节），字段全部具名：

    {
        .internalName = "L00",
        .map = { .obj1Id = 1, .obj2Id = 0, .paletteId = 2, .tileConfigId = 3,
                 .mainLayerId = 4, .objAnimId = 5, .paletteAnimId = 0,
                 .changeLayerId = 6 },
        .initialFogLevel = 0, .hasPrepScreen = FALSE,
        .initialPosX = 1, .initialPosY = 0, .initialWeather = WEATHER_FINE,
        .battleTileSet = 0,
        ...
        .mapEventDataId = 7, .gmapEventId = 1,
        ...
    }

## 为什么还是让编译器算

`internalName` 是**指针**，`battleTileSet` 等有枚举值，`map` 是嵌套结构 ——
文本解析要自己处理这些。让编译器把字段读出来更省事也更可靠。

⚠️ 但**只打印字段值，不打印结构体字节**：
`internalName` 在宿主上是 8 字节指针（GBA 上是 4），
结构体布局两边不同（这是章节事件那边踩过的坑）。
字段值本身是平台无关的。

用法:
    python3 tools/pipeline/extract/parse_chapters.py --out out/tables
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

# 这个头文件里就是表定义本身，把它当 TU 编
SRC = "src/data/chapter_settings.h"

PROBE = r"""
#include "global.h"
#include "chapterdata.h"
#include <stdio.h>

int main(void)
{
    const int n = (int)(sizeof(gChapterDataTable) / sizeof(gChapterDataTable[0]));
    printf("COUNT %d\n", n);
    for (int i = 0; i < n; i++) {
        const struct ROMChapterData* c = &gChapterDataTable[i];
        printf("CH %d %s %d %d %d %d %d %d %d %d %d %d %d %d %d %d\n",
            i,
            (c->internalName && c->internalName[0]) ? c->internalName : "-",
            c->map.obj1Id, c->map.obj2Id, c->map.paletteId, c->map.tileConfigId,
            c->map.mainLayerId, c->map.changeLayerId,
            c->initialFogLevel, (int)c->hasPrepScreen,
            c->initialPosX, c->initialPosY, c->initialWeather, c->battleTileSet,
            c->mapEventDataId, c->gmapEventId);
    }
    return 0;
}
"""

# 这些由 libc 提供，不该生成桩
LIBC_SYMBOLS = {
    "printf", "snprintf", "sprintf", "puts", "putchar", "fputs", "fprintf",
    "memcpy", "memset", "memmove", "memcmp", "strlen", "strcpy", "strcmp",
    "malloc", "free", "calloc", "realloc", "abort", "exit",
}

FIELDS = ("index", "internalName", "obj1Id", "obj2Id", "paletteId",
          "tileConfigId", "mainLayerId", "changeLayerId", "initialFogLevel",
          "hasPrepScreen", "initialPosX", "initialPosY", "initialWeather",
          "battleTileSet", "mapEventDataId", "gmapEventId")


def strip_section_attrs(text):
    return re.sub(r'__attribute__\s*\(\(\s*section\s*\([^)]*\)\s*\)\)', " ", text)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", default=os.path.join(HERE, "..", "out", "tables"))
    a = ap.parse_args()

    path = os.path.join(DECOMP, SRC)
    if not os.path.exists(path):
        print(f"错误：找不到 {path}", file=sys.stderr)
        return 1

    raw = strip_section_attrs(open(path, encoding="utf-8", errors="replace").read())

    with tempfile.TemporaryDirectory() as tmp:
        cpath = os.path.join(tmp, "probe.c")
        # ⚠️ 这个 .h **不自带 include**（它平时是被 chapterdata.c include 的），
        # 单独当 TU 编会报 "array has incomplete element type
        # 'struct ROMChapterData'"。所以在前面补上头文件。
        prefix = '#include "global.h"\n#include "chapterdata.h"\n'
        open(cpath, "w").write(prefix + raw + PROBE)

        # 先编出目标文件，收集未定义符号 → 生成桩（同其它提取器）
        obj = os.path.join(tmp, "probe.o")
        base = [
            "clang", "-std=gnu89", "-O0", "-w",
            "-include", os.path.join(HOST, "host_prelude.h"),
            "-I", HOST,
            "-I", os.path.join(DECOMP, "include"),
            "-I", DECOMP,
        ]
        r = subprocess.run(base + ["-c", "-o", obj, cpath],
                           capture_output=True, text=True)
        if r.returncode != 0:
            print("❌ 编译失败:", file=sys.stderr)
            print(r.stderr[-1500:], file=sys.stderr)
            return 1

        u = subprocess.run(["nm", "-u", obj], capture_output=True, text=True)
        syms = []
        for line in u.stdout.split("\n"):
            p = line.split()
            if p:
                n = p[-1]
                syms.append(n[1:] if n.startswith("_") else n)

        stub = os.path.join(tmp, "stubs.c")
        with open(stub, "w") as f:
            f.write('#include "global.h"\n#include <stdio.h>\n')
            for s in syms:
                # ⚠️ 必须排除 **libc** 符号。`nm -u` 会把 `printf` 之类
                # 也算成未定义，给它生成一个 `unsigned char printf[256]`
                # 会和 <stdio.h> 的声明撞车（"redefinition of 'printf'
                # as different kind of symbol"）。
                if s in ("gChapterDataTable",) or s in LIBC_SYMBOLS:
                    continue
                f.write(f"unsigned char {s}[256] = {{0}};\n")

        exe = os.path.join(tmp, "probe")
        r = subprocess.run(base + [stub, cpath, "-o", exe],
                           capture_output=True, text=True)
        if r.returncode != 0:
            print("❌ 链接失败:", file=sys.stderr)
            print(r.stderr[-1200:], file=sys.stderr)
            return 1

        run = subprocess.run([exe], capture_output=True, text=True)
        if run.returncode != 0:
            print(f"❌ 探针运行失败（{run.returncode}）", file=sys.stderr)
            return 1

    chapters = []
    count = None
    for line in run.stdout.split("\n"):
        p = line.split()
        if not p:
            continue
        if p[0] == "COUNT":
            count = int(p[1])
        elif p[0] == "CH":
            # 第 2 个字段是**章节名字符串**（如 "L00"），其余是数字
            # p[0]="CH"  p[1]=index  p[2]=名字  其余是数字
            vals = [int(p[1]), p[2]] + [int(x) for x in p[3:]]
            if len(vals) != len(FIELDS):
                print(f"❌ 字段数不符：{len(vals)} vs {len(FIELDS)}",
                      file=sys.stderr)
                return 1
            chapters.append(dict(zip(FIELDS, vals)))

    if count is None or len(chapters) != count:
        print(f"❌ 输出不完整：COUNT={count} 实际={len(chapters)}", file=sys.stderr)
        return 1

    print(f"解析出 {count} 章")

    # 自洽性：章节名不应全同、mapEventDataId 应在合理范围
    names = [c['internalName'] for c in chapters]
    if len(set(names)) < count // 2:
        print(f"❌ 章节名大量重复（{len(set(names))}/{count}），疑似解析错位",
              file=sys.stderr)
        return 1
    # `mapEventDataId` 是 **u8** 字段，所以合法范围就是 0..255。
    # 我第一版拍了个 200 的上界，结果 4 章（值 202/204/208/212）被误报越界。
    # 上界应当来自**字段类型**，不该凭印象定。
    bad = [c for c in chapters if not (0 <= c['mapEventDataId'] <= 255)]
    if bad:
        print(f"❌ {len(bad)} 章的 mapEventDataId 越界: "
              f"{[c['mapEventDataId'] for c in bad[:5]]}", file=sys.stderr)
        return 1
    print("✅ 自洽性检查通过（章节名不重复、mapEventDataId 在范围内）")

    print("\n前 8 章:")
    for c in chapters[:8]:
        print(f"  [{c['index']:2d}] {c['internalName']:<6} "
              f"地图 obj1={c['obj1Id']} main={c['mainLayerId']}  "
              f"事件组={c['mapEventDataId']}  起始({c['initialPosX']},{c['initialPosY']})")

    # mapEventDataId 的取值分布 —— 下一步要靠它去查 ChapterEventGroup
    ids = sorted({c['mapEventDataId'] for c in chapters})
    print(f"\n用到的 mapEventDataId 共 {len(ids)} 个: {ids[:12]}"
          f"{' …' if len(ids) > 12 else ''}")

    os.makedirs(a.out, exist_ok=True)
    payload = {
        "source": SRC,
        "count": count,
        "chapters": chapters,
    }
    dst = os.path.join(a.out, "chapters.json")
    with open(dst, "w", encoding="utf-8") as f:
        json.dump(payload, f, ensure_ascii=False, indent=1)
    print(f"\n→ {dst}  ({os.path.getsize(dst) // 1024} KB)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
