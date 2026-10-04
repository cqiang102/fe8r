#!/usr/bin/env python3
"""
数据提取：把反编译项目里的 C 数据表转成 JSON。

面向 `src/data/data_terrains.c`（地形表），后续可扩展到其它数据表。

## 为什么不能只做"解析"

C 的指定初始化器（designated initializer）语义有几个容易漏的点：

    CONST_DATA s8 Table[] = {
        [TERRAIN_NONE]  = -1,
        [TERRAIN_PLAINS] = 1,
    };

  * 没写出来的下标**填 0**（不是负数、不是跳过）
  * 数组长度 = **最大下标 + 1**
  * 下标是**枚举值**，必须先解析 `terrains.h` 才能知道是多少
  * 值是 `s8`，范围 -128..127（-1 表示不可通行）

自己写个解析器然后"自己检查自己"没有意义。**这里的判据是宿主机 C 编译器**：
把表定义抽出来编译、dump 出字节，再和 Python 解析的结果逐字节比。
编译器怎么算，我们就怎么算——见 `verify_tables.py`。

用法:
    python3 tools/pipeline/extract/parse_c_tables.py --out out/tables
"""
import argparse
import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.abspath(os.path.join(HERE, "..", "..", ".."))
DECOMP = os.path.join(REPO, "third_party", "fireemblem8j")


# ---------------------------------------------------------------- 枚举解析

def parse_enum(header, enum_name=None):
    """从 C 头文件里解析 `名字 = 值` 形式的枚举常量。

    简化处理：按出现顺序自动编号，显式 `= 0x..` 用显式值。
    反编译项目里地形枚举就是从 0 顺序排到 0x40，所以够用；
    但有显式值时必须尊重它。
    """
    text = open(header, encoding="utf-8", errors="replace").read()
    # 取 enum { ... }; 里最大的块
    blocks = re.findall(r"enum\s*\w*\s*\{(.*?)\}", text, re.S)
    if not blocks:
        return {}
    body = max(blocks, key=len)

    # ⚠️ 必须**先剥注释再按逗号分割**。
    # 反过来做会踩这个坑：第一条条目形如
    #     "\n    // Terrain identifiers\n\n    // ...\n\n    TERRAIN_NONE = 0x00"
    # 它 strip() 之后以 `//` 开头，会被整条当成注释丢掉——
    # 于是 TERRAIN_NONE 消失，**后面所有下标全部错位**。
    body = re.sub(r"/\*.*?\*/", " ", body, flags=re.S)
    body = re.sub(r"//[^\n]*", " ", body)

    vals = {}
    nxt = 0
    for item in body.split(","):
        item = item.strip()
        if not item:
            continue
        m = re.match(r"(\w+)\s*(?:=\s*([^,\s]+))?", item)
        if not m:
            continue
        name, val = m.group(1), m.group(2)
        if val is not None:
            try:
                nxt = int(val, 0)
            except ValueError:
                continue
        vals[name] = nxt
        nxt += 1
    return vals


# ---------------------------------------------------------------- 表解析

ARRAY_RX = re.compile(
    r"(?:CONST_DATA|const)\s+(\w+)\s+(\w+)\s*\[\s*\]\s*=\s*\{(.*?)\n\};",
    re.S,
)


def parse_array(body, enum):
    """解析指定初始化器 → (长度, [值])

    返回的列表已经按 C 语义展开：未指定的下标填 0，
    长度 = 最大下标 + 1。
    """
    entries = {}
    nxt_auto = 0

    # 先去掉注释，避免注释里的 `[X]` 干扰
    body = re.sub(r"/\*.*?\*/", " ", body, flags=re.S)
    body = re.sub(r"//[^\n]*", " ", body)

    for item in body.split(","):
        item = item.strip()
        if not item:
            continue
        m = re.match(r"\[\s*([^\]]+)\s*\]\s*=\s*(.+)$", item, re.S)
        if m:
            idx_expr, val_expr = m.group(1).strip(), m.group(2).strip()
            # 下标可能是枚举名，也可能是数字
            if idx_expr in enum:
                idx = enum[idx_expr]
            else:
                try:
                    idx = int(idx_expr, 0)
                except ValueError:
                    continue  # 表达式下标（如 A + 1）暂不支持，交给校验暴露
            nxt_auto = idx + 1
        else:
            idx = nxt_auto
            val_expr = item
            nxt_auto += 1

        try:
            entries[idx] = int(val_expr, 0)
        except ValueError:
            # 值可能是枚举名或其它符号，暂不支持
            continue

    if not entries:
        return 0, []
    size = max(entries) + 1
    return size, [entries.get(i, 0) for i in range(size)]


def extract(path, enum):
    text = open(path, encoding="utf-8", errors="replace").read()
    out = {}
    for m in ARRAY_RX.finditer(text):
        ctype, name, body = m.group(1), m.group(2), m.group(3)
        size, vals = parse_array(body, enum)
        out[name] = {"type": ctype, "size": size, "values": vals}
    return out


# ---------------------------------------------------------------- 导出

def to_signed8(v):
    """C 的 s8 语义：超出 -128..127 的按补码截断"""
    v &= 0xFF
    return v - 256 if v >= 128 else v


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", default=os.path.join(HERE, "..", "out", "tables"))
    ap.add_argument("--source", default=os.path.join(DECOMP, "src/data/data_terrains.c"))
    a = ap.parse_args()

    if not os.path.exists(a.source):
        print(f"错误：找不到 {a.source}", file=sys.stderr)
        return 1

    enum = parse_enum(os.path.join(DECOMP, "include/constants/terrains.h"))
    print(f"地形枚举: {len(enum)} 个常量，最大下标 {max(enum.values())}")

    tables = extract(a.source, enum)
    print(f"提取到 {len(tables)} 张表")

    os.makedirs(a.out, exist_ok=True)

    # JSON 里保留 s8 语义（-1 = 不可通行）
    payload = {
        "source": os.path.relpath(a.source, REPO),
        "terrainEnum": enum,
        "tables": {
            k: {
                "type": v["type"],
                "size": v["size"],
                "values": [to_signed8(x) for x in v["values"]],
            }
            for k, v in tables.items()
        },
    }
    dst = os.path.join(a.out, "terrains.json")
    with open(dst, "w", encoding="utf-8") as f:
        json.dump(payload, f, ensure_ascii=False, indent=1)
    print(f"→ {dst}  ({os.path.getsize(dst) // 1024} KB)")

    # 抽查一张表
    t = tables.get("TerrainTable_MovCost_CommonT2Normal")
    if t:
        vals = [to_signed8(x) for x in t["values"]]
        names = {v: k for k, v in enum.items()}
        print(f"\n抽查 TerrainTable_MovCost_CommonT2Normal（{t['size']} 项）:")
        for i in range(min(12, len(vals))):
            print(f"  [{names.get(i, i)}] = {vals[i]}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
