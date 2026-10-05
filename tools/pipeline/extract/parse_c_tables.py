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
    # ⚠️ 先剥注释再解析：行尾注释会把**下一个**枚举名并进当前项的 key，
    # 导致那个常量被静默丢掉（classes.h 实测少 4 个）。
    text = re.sub(r"/\*.*?\*/", " ", text, flags=re.S)
    text = re.sub(r"//[^\n]*", " ", text)
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
                # 值可能是**另一个枚举名**（别名），例如
                #     CLASS_OBSTACLE = CLASS_EPHRAIM_LORD,
                # 之前这里是 `continue`，那个常量被静默丢掉。
                if val in vals:
                    nxt = vals[val]
                else:
                    continue
        vals[name] = nxt
        nxt += 1
    return vals


# ---------------------------------------------------------------- 表解析

ARRAY_RX = re.compile(
    r"(?:CONST_DATA|const)\s+(\w+)\s+(\w+)\s*\[\s*\]\s*=\s*\{(.*?)\n\};",
    re.S,
)


def resolve_value(expr, enum):
    """把 `0x1F` / `TERRAIN_PLAINS` / `CLASS_A + 1` 这类表达式折成整数。

    只支持"单个符号"和"符号/数字 加减常量"这几种形式——反编译项目里
    表示式下标就那么几种写法，不引入完整表达式求值器，遇到不认识的
    就返回 None 让校验阶段暴露出来（而不是悄悄算错）。
    """
    expr = expr.strip().rstrip(",").strip()
    if expr in enum:
        return enum[expr]
    try:
        return int(expr, 0)
    except ValueError:
        pass
    # 形如 `SYM + 3` / `SYM - 1`
    m = re.fullmatch(r"(\w+)\s*([+-])\s*(0x[0-9A-Fa-f]+|\d+)", expr)
    if m and m.group(1) in enum:
        base = enum[m.group(1)]
        delta = int(m.group(3), 0)
        return base + delta if m.group(2) == "+" else base - delta
    return None


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
            resolved = resolve_value(idx_expr, enum)
            if resolved is None:
                continue  # 不认识的表达式下标，交给校验阶段暴露
            idx = resolved
            nxt_auto = idx + 1
        else:
            idx = nxt_auto
            val_expr = item
            nxt_auto += 1

        # 值可能是数字，也可能是枚举名。
        #
        # ⚠️ 早期版本只处理数字，非指定初始化（`{ CLASS_A, CLASS_B, ... }`）
        # 整张表会被丢空——因为 `int('CLASS_A', 0)` 抛异常后直接 continue。
        # `data_terrains.c` 全用指定初始化器 `[TERRAIN_X] = n`，所以一直没暴露；
        # 换成 `data_itemuse.c` 的有效性列表（纯枚举名列表）立刻现形。
        entries[idx] = resolve_value(val_expr, enum)
        if entries[idx] is None:
            del entries[idx]
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


# 要提取的源文件 → 它需要的枚举头
#
# 枚举头的顺序有讲究：解析时用 `setdefault`，先来的优先。
# 地形和职业的枚举名不会冲突，但显式列出来更清楚。
SOURCES = [
    {
        "json": "terrains.json",
        "source": "src/data/data_terrains.c",
        "enums": ["include/constants/terrains.h"],
        "signed": True,     # s8：-1 表示不可通行，必须保留符号
    },
    {
        "json": "itemuse.json",
        "source": "src/data/data_itemuse.c",
        "enums": ["include/constants/classes.h", "include/constants/items.h"],
        "signed": False,    # u8：有效性列表里只有职业编号，0 是终止符
    },
]


def load_enums(paths):
    merged = {}
    for rel in paths:
        full = os.path.join(DECOMP, rel)
        if not os.path.exists(full):
            print(f"  ⚠️  找不到 {rel}，跳过", file=sys.stderr)
            continue
        found = parse_enum(full)
        for k, v in found.items():
            merged.setdefault(k, v)
        print(f"  枚举 {rel}: {len(found)} 个常量")
    return merged


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", default=os.path.join(HERE, "..", "out", "tables"))
    ap.add_argument("--only", help="只处理某个 json 名（调试用）")
    a = ap.parse_args()

    os.makedirs(a.out, exist_ok=True)
    failed = 0

    for spec in SOURCES:
        if a.only and spec["json"] != a.only:
            continue
        src = os.path.join(DECOMP, spec["source"])
        if not os.path.exists(src):
            print(f"错误：找不到 {src}", file=sys.stderr)
            failed += 1
            continue

        print(f"\n── {spec['source']} ──")
        enum = load_enums(spec["enums"])
        tables = extract(src, enum)
        print(f"  提取到 {len(tables)} 张表")

        conv = to_signed8 if spec["signed"] else (lambda v: v & 0xFF)
        payload = {
            "source": spec["source"],
            "enums": spec["enums"],
            "enum": enum,
            "signed": spec["signed"],
            "tables": {
                k: {
                    "type": v["type"],
                    "size": v["size"],
                    "values": [conv(x) for x in v["values"]],
                }
                for k, v in tables.items()
            },
        }
        dst = os.path.join(a.out, spec["json"])
        with open(dst, "w", encoding="utf-8") as f:
            json.dump(payload, f, ensure_ascii=False, indent=1)
        print(f"  → {dst}  ({os.path.getsize(dst) // 1024} KB)")

    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
