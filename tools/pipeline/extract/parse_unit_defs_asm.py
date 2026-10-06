#!/usr/bin/env python3
"""
从**汇编**里补出 `UnitDefinition` 表。

## 为什么需要

有一批单位表**没有 C 定义**，只在 `src/data/data/*.s` 里以裸 `.4byte` 存在：

    src/data/data/data_08908354.s
        .global UnitDef_Event_PrologueMessager
    UnitDef_Event_PrologueMessager:
        .4byte 0x08004E0F
        .4byte 0x030003C9
        .4byte REDAs_PrologueMessager
        ...

`parse_unit_defs.py` 走的是"编译 C 探针"的路子，**拿不到这些**。

## 布局（`include/bmunit.h:195`，`BITPACKED`）

    /* 00 */ u8  charIndex;
    /* 01 */ u8  classIndex;
    /* 02 */ u8  leaderCharIndex;
    /* 03 */ u8  autolevel:1, allegiance:2, level:5;
    /* 04 */ u16 xPosition:6, yPosition:6, genMonster:1, itemDrop:1,
                 sumFlag:1, unk_05_7:1, extraData:8;
    /* 07 */ u16 redaCount:8;
    /* 08 */ const void *redas;
    /* 0C */ u8  items[4];
    /* 10 */ u8  ai[4];

**共 20 字节 = 5 个 `.4byte` 一条**，全零那条是终止项。

## ⚠️ 为什么不直接抄美版

美版仓库（`fireemblem8u`）有同样的表，而且是**可读的 C**。
但**坐标并不相同** —— 实测 `UnitDef_Event_PrologueGradoRoyals`：

    日版:  x=12, y=11
    美版:  x=12, y=7    （美版的 REDA 是 y=7）

所以只能解日版自己的字节。
"""
import argparse
import glob
import json
import os
import re
import struct
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.abspath(os.path.join(HERE, "..", "..", ".."))
DECOMP = os.path.join(REPO, "third_party", "fireemblem8j")

LABEL = re.compile(r"^(UnitDef_\w+):\s*$")
WORD = re.compile(r"^\s*\.4byte\s+(.+?)\s*$")


def decode(entry):
    """5 个 u32 -> 一个单位字典（与 `parse_unit_defs.py` 的输出同构）"""
    a, b, c, _items_lo, _ai = entry[0], entry[1], entry[2], entry[3], entry[4]
    char = a & 0xFF
    cls = (a >> 8) & 0xFF
    lead = (a >> 16) & 0xFF
    f3 = (a >> 24) & 0xFF
    autolevel = f3 & 1
    allegiance = (f3 >> 1) & 3
    level = (f3 >> 3) & 0x1F
    x = b & 0x3F
    y = (b >> 6) & 0x3F
    gen = (b >> 12) & 1
    drop = (b >> 13) & 1
    flag = (b >> 14) & 1
    reda_count = c & 0xFF
    items = [(_items_lo >> (8 * i)) & 0xFF for i in range(4)]
    return {
        "charIndex": char, "classIndex": cls, "leaderCharIndex": lead,
        "allegiance": allegiance, "level": level, "autolevel": autolevel,
        "x": x, "y": y, "genMonster": gen, "itemDrop": drop, "sumFlag": flag,
        "redaCount": reda_count,
        "item0": items[0], "item1": items[1], "item2": items[2], "item3": items[3],
    }


def is_zero(e):
    return all(w == 0 for w in e)


def parse_file(path):
    out = {}
    cur = None
    words = []
    for line in open(path, encoding="utf-8", errors="replace"):
        m = LABEL.match(line)
        if m:
            if cur and words:
                out[cur] = words
            cur, words = m.group(1), []
            continue
        if cur is None:
            continue
        if line.startswith("\t.section") or line.startswith(".section"):
            if cur and words:
                out[cur] = words
            cur, words = None, []
            continue
        w = WORD.match(line)
        if w:
            tok = w.group(1).split(",")[0].strip()
            if tok.startswith("0x"):
                try:
                    words.append(int(tok, 16))
                except ValueError:
                    words.append(0)
            else:
                # `REDAs_xxx` 之类 —— 我们不需要它，占位即可
                words.append(0)
    if cur and words:
        out[cur] = words
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", default=os.path.join(HERE, "..", "out", "tables"))
    a = ap.parse_args()

    files = sorted(glob.glob(os.path.join(DECOMP, "src", "data", "**", "*.s"),
                             recursive=True))
    print(f"  扫描 {len(files)} 个 .s 文件")
    raw = {}
    for f in files:
        for name, words in parse_file(f).items():
            raw.setdefault(name, words)

    tables = {}
    for name, words in raw.items():
        if len(words) < 5:
            continue
        entries = []
        for i in range(0, len(words) - 4, 5):
            e = words[i:i + 5]
            if is_zero(e):
                break
            entries.append(decode(e))
        if entries:
            # 补上 index —— 与 C 路径的输出保持同构
            for i, e in enumerate(entries):
                e["index"] = i
            tables[name] = entries

    print(f"  从汇编解出 {len(tables)} 张表，{sum(len(v) for v in tables.values())} 个单位")

    dst = os.path.join(a.out, "unit_defs_asm.json")
    os.makedirs(a.out, exist_ok=True)
    with open(dst, "w", encoding="utf-8") as f:
        json.dump({"source": "src/data/**/*.s", "tables": tables},
                  f, ensure_ascii=False, indent=1)
    print(f"→ {dst}  ({os.path.getsize(dst) // 1024} KB)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
