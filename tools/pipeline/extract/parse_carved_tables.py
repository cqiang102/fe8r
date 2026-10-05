#!/usr/bin/env python3
"""
提取**只有二进制、没有 C 源**的数据表。

`src/data/frontier_df4_uistuff/frontier_df4_uistuff.c` 是 carve 出来的：
它把 ROM 数据块原样倒成一个 `u32` 数组，没有任何 struct 语义。
`struct WeaponTriangleRule` 的声明在另一个文件里
（`src/BattleApplyWeaponTriangleEffect.c`），而表的定义被绑成 ABS 符号
指向这段原始数据（见 `layout/baseline_syms.d/data_bmbattle_wtriangle.tsv`）。

所以这张表**没有 C 源码可以编译**，没法用 `verify_tables.py` 那套
"让编译器算一遍"的办法验证。这里的判据换成：

  1. 从 carve 文件里按 `u32` 读出原始字节（这是 ROM 的忠实副本）
  2. 按 `struct WeaponTriangleRule` 的布局拆成 4 个 `s8`
  3. **用结构自洽性校验**：终止符必须恰好出现在表尾、
     且每个非终止项的 weapon type 必须在已知范围内

第 3 条能抓住"起点算错""结构体布局搞错"这类错误——
它们都会破坏表的自洽性，而不是产生一个看起来还行的数组。

用法:
    python3 tools/pipeline/extract/parse_carved_tables.py --out out/tables
"""
import argparse
import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.abspath(os.path.join(HERE, "..", "..", ".."))
DECOMP = os.path.join(REPO, "third_party", "fireemblem8j")

# 段起点与表符号的 ROM 地址（来自 layout/baseline_syms.d/）
GAP27_START = 0x5C3C9C
TRIANGLE_ADDR = 0x5C3F70
GAP27_SYMBOL = "frontier_df4_uistuff_027_5C3C9C"
GAP27_FILE = "src/data/frontier_df4_uistuff/frontier_df4_uistuff.c"

# `ITYPE_*`：武器类型（include/bmitem.h）
WEAPON_TYPES = {
    0: "ITYPE_SWORD", 1: "ITYPE_LANCE", 2: "ITYPE_AXE", 3: "ITYPE_BOW",
    4: "ITYPE_STAFF", 5: "ITYPE_ANIMA", 6: "ITYPE_LIGHT", 7: "ITYPE_DARK",
}


def read_u32_array(path, symbol):
    """从 carve 出来的 .c 里读一个 `u32 SYM[] = { ... };`

    数组里可能混有重定位表达式（`(u32)&Foo + 0x1`），这里**原样保留字符串**，
    由调用方决定怎么处理——静默跳过会让下标错位。
    """
    src = open(path, encoding="utf-8", errors="replace").read()
    i = src.index(symbol)
    j = src.index("{", i)
    k = src.index("};", j)
    body = src[j + 1:k]
    # 先剥注释，再按逗号切（顺序不能反，见 parse_c_tables.py 里的同类教训）
    body = re.sub(r"/\*.*?\*/", " ", body, flags=re.S)
    body = re.sub(r"//[^\n]*", " ", body)
    return [t.strip() for t in body.split(",") if t.strip()]


def s8(v):
    v &= 0xFF
    return v - 256 if v >= 128 else v


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", default=os.path.join(HERE, "..", "out", "tables"))
    a = ap.parse_args()

    path = os.path.join(DECOMP, GAP27_FILE)
    if not os.path.exists(path):
        print(f"错误：找不到 {path}", file=sys.stderr)
        return 1

    toks = read_u32_array(path, GAP27_SYMBOL)
    print(f"{GAP27_SYMBOL}: {len(toks)} 项 u32（{len(toks) * 4} 字节）")

    off = (TRIANGLE_ADDR - GAP27_START) // 4
    if not (0 <= off < len(toks)):
        print(f"错误：三角表偏移 {off} 超出数组范围", file=sys.stderr)
        return 1
    print(f"武器三角表起始下标 {off}（地址 {TRIANGLE_ADDR:#x}）")

    rules = []
    problems = []
    end = None
    for n in range(off, len(toks)):
        t = toks[n]
        if not re.fullmatch(r"0[xX][0-9A-Fa-f]+|\d+", t):
            problems.append(f"下标 {n} 是重定位表达式，表内不该出现：{t[:60]}")
            break
        v = int(t, 0)
        a_t = s8(v)
        d_t = s8((v >> 8) & 0xFF)
        hit = s8((v >> 16) & 0xFF)
        atk = s8((v >> 24) & 0xFF)

        if a_t < 0:
            end = n
            break
        rules.append({
            "attackerWeaponType": a_t,
            "defenderWeaponType": d_t,
            "hitBonus": hit,
            "atkBonus": atk,
        })

    # ---- 自洽性校验 ----
    if end is None:
        problems.append("没有找到终止符（attackerWeaponType < 0）")
    for i, r in enumerate(rules):
        if r["attackerWeaponType"] not in WEAPON_TYPES:
            problems.append(f"第 {i} 项的攻击方武器类型 {r['attackerWeaponType']} 不是已知类型")
        if r["defenderWeaponType"] not in WEAPON_TYPES:
            problems.append(f"第 {i} 项的防御方武器类型 {r['defenderWeaponType']} 不是已知类型")
        if abs(r["hitBonus"]) != 15 or abs(r["atkBonus"]) != 1:
            problems.append(
                f"第 {i} 项的加成 ({r['hitBonus']}, {r['atkBonus']}) 不是预期的 ±15 / ±1")
        if r["hitBonus"] * r["atkBonus"] < 0:
            problems.append(f"第 {i} 项命中与攻击加成符号相反，不合理")

    print(f"\n解析出 {len(rules)} 条规则（终止符在下标 {end}）:")
    for r in rules:
        atk = WEAPON_TYPES[r["attackerWeaponType"]].replace("ITYPE_", "")
        dfn = WEAPON_TYPES[r["defenderWeaponType"]].replace("ITYPE_", "")
        sign = "克" if r["hitBonus"] > 0 else "被克"
        print(f"  {atk:<6} vs {dfn:<6} {sign}  命中 {r['hitBonus']:+d}  攻击 {r['atkBonus']:+d}")

    if problems:
        print(f"\n❌ 自洽性校验失败（{len(problems)} 项）:", file=sys.stderr)
        for p in problems[:10]:
            print(f"  {p}", file=sys.stderr)
        return 1
    print("\n✅ 自洽性校验通过")

    os.makedirs(a.out, exist_ok=True)
    payload = {
        "source": GAP27_FILE,
        "symbol": "sWeaponTriangleRules",
        "romAddress": TRIANGLE_ADDR,
        "weaponTypeNames": {str(k): v for k, v in WEAPON_TYPES.items()},
        "rules": rules,
    }
    dst = os.path.join(a.out, "weapon_triangle.json")
    with open(dst, "w", encoding="utf-8") as f:
        json.dump(payload, f, ensure_ascii=False, indent=1)
    print(f"→ {dst}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
