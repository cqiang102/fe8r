#!/usr/bin/env python3
"""
抽 `gCharacterData` 与 `gItemData` —— **战斗属性的另两半**。

## 背景（和 `parse_class_tables.py` 同一个故事）

战斗属性完全由源码里的三张表决定（见 `src/ComputeBattleUnit*.c`）：

    battleAttack  = GetItemMight(weapon) + 三角加成      <- 道具表
    battleDefense = terrainDefense + unit.def            <- 职业表 + 角色表
    battleAvoid   = battleSpeed*2 + terrainAvoid + lck
    battleSpeed   = unit.spd - (武器重量 - conBonus)

`unit.def` / `unit.spd` / `unit.lck` 这些来自
**职业基础值 + 角色基础值**（`InitUnit` 里相加）。

我原来三张表**一张都没有**，于是战斗只能跑硬编码的演示 profile，
**奥尼尔因此打不掉**。

出处：
* `src/data/data_characters.c` —— `struct CharacterData gCharacterData[]`
* `src/data/data_items.c`      —— `struct ItemData gItemData[]`
"""
import argparse
import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.abspath(os.path.join(HERE, "..", "..", ".."))
DECOMP = os.path.join(REPO, "third_party", "fireemblem8j")


def strip_comments(t):
    t = re.sub(r"/\*.*?\*/", " ", t, flags=re.S)
    return re.sub(r"//[^\n]*", " ", t)


def num(tok):
    tok = tok.strip().rstrip(",").strip()
    try:
        if tok.startswith("0x") or tok.startswith("-0x"):
            return int(tok, 16)
        return int(tok)
    except ValueError:
        return None


def eval_const(expr, known):
    """求值 C 常量表达式里**本项目实际出现的**几种写法。

    支持的形状（`include/bmitem.h` 的 `IA_*` 就是这种）：

        IA_WEAPON          = (1 << 0),
        IA_UNBREAKABLE     = (1 << 3),
        .attributes = IA_WEAPON | IA_UNSELLABLE | IA_LOCK_4,

    ⚠️ **不能用"没解析出来就隐式递增"那条路** —— `(1 << 0)` 会变成 0、
    `(1 << 3)` 会变成 1，得到一堆**看着合理但完全错**的位掩码。
    这正是本项目最怕的一类 bug（不报错、值不对）。

    解析不出来就返回 None，由调用方退回原来的字符串 —— 不猜。
    """
    acc = 0
    for part in expr.split("|"):
        tok = part.strip().strip("()").strip()
        m = re.fullmatch(r"(\d+)\s*<<\s*(\d+)", tok)
        if m:
            acc |= int(m.group(1)) << int(m.group(2))
            continue
        v = num(tok)
        if v is None:
            v = known.get(tok)
        if v is None:
            return None
        acc |= v
    return acc


def enum_values(*headers):
    """把 `NAME = 0xNN` / `NAME,`（隐式递增）抽成字典。

    ⚠️ **必须做这一步**。`gItemData` / `gCharacterData` 里写的是
        .number = ITEM_SWORD_IRON
    即**枚举名**，不是数字。直接当字符串留下的话，
    载入时只能按 `n is int` 过滤 -> **索引全空** -> 战斗又退回演示数据。
    （我第一版就是这样，`_itemStats.length == 0`。）
    """
    out, nxt = {}, 0
    for h in headers:
        p = os.path.join(DECOMP, h)
        if not os.path.exists(p):
            continue
        t = strip_comments(open(p, encoding="utf-8", errors="replace").read())
        # ⚠️ 值必须**限制在同一行**（`[^,\n]`），而且逗号要在行尾。
        #
        # 原来写的是 `[^,]+?` —— 它能跨行，于是
        #
        #     IA_LOCK_ANY = (IA_LOCK_0 | ... | IA_UNUSABLE)
        # };
        #
        # enum {
        #     ITYPE_SWORD = 0,          <-- ★ 被当成上面那条的值吞掉了
        #     ITYPE_LANCE = 1,
        #
        # **紧跟多行值的那个枚举的第一项会静默消失** ——
        # `ITYPE_SWORD` 因此查不到（`consts.get()` 返回 None），
        # 物品的 weaponType 就留在字符串上，映射全错。
        for m in re.finditer(
                r"^\s*([A-Z][A-Z0-9_]*)\s*(?:=\s*([^,\n]+?))?\s*,\s*$", t, re.M):
            name, val = m.group(1), m.group(2)
            v = eval_const(val, out) if val else None
            if v is None:
                v = nxt
            out[name] = v
            nxt = v + 1
    return out


def extract(path, want, consts=None):
    """按 `[KEY] = { ... }` 切块，取 `want` 里的标量字段"""
    raw = strip_comments(open(path, encoding="utf-8", errors="replace").read())
    i = raw.index("[] = {")
    body = raw[i:]
    marks = [(m.start(), m.group(1)) for m in
             re.finditer(r"\[(\w+)(?:\s*-\s*1)?\]\s*=\s*\{", body)]
    out, missing = {}, []
    for n, (start, key) in enumerate(marks):
        end = marks[n + 1][0] if n + 1 < len(marks) else len(body)
        blk = body[start:end]
        e = {"key": key}
        for f in want:
            m = re.search(rf"\.{f}\s*=\s*([^,{{}}]+?)\s*,", blk)
            if m:
                v = num(m.group(1))
                if v is not None:
                    e[f] = v
                    continue
                tok = m.group(1).strip()
                # 枚举名 -> 数字（这一步不做，索引就是空的）
                if consts and tok in consts:
                    e[f] = consts[tok]
                    continue
                # `A | B | C` 形式的位掩码（`IA_*`）—— 按位或求值
                if consts:
                    mask = eval_const(tok, consts)
                    if mask is not None:
                        e[f] = mask
                        continue
                e[f] = tok
        out[key] = e
        for f in want:
            if f not in e:
                missing.append(f"{key}.{f}")
    return out, missing


CHAR_FIELDS = (
    "number", "nameTextId", "descTextId", "defaultClass", "portraitId",
    "affinity", "baseLevel", "baseHP", "basePow", "baseSkl", "baseSpd",
    "baseDef", "baseRes", "baseLck", "baseCon", "baseMov",
    "growthHP", "growthPow", "growthSkl", "growthSpd", "growthDef",
    "growthRes", "growthLck",
)
ITEM_FIELDS = (
    "number", "nameTextId", "descTextId", "weaponType", "attributes",
    "maxUses", "might", "hit", "crit", "weight", "minRange", "maxRange",
    "rank", "exp", "cost", "effectId",
    # ★ 射程打包在一个字节里（ / ）：
    #     minRange = encodedRange >> 4
    #     maxRange = encodedRange & 0xF
    "encodedRange",
)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", default=os.path.join(HERE, "..", "out", "tables"))
    a = ap.parse_args()
    os.makedirs(a.out, exist_ok=True)

    consts = enum_values(
        "include/constants/characters.h",
        "include/constants/items.h",
        "include/constants/classes.h",
        # `IA_*` 在 bmitem.h 里（不在 constants/ 下）——道具属性位掩码要用它
        "include/bmitem.h",
    )
    print(f"  常量表 {len(consts)} 个")

    ok = True
    for fname, fields, outname in (
        ("data_characters.c", CHAR_FIELDS, "characters.json"),
        ("data_items.c", ITEM_FIELDS, "items.json"),
    ):
        p = os.path.join(DECOMP, "src", "data", fname)
        if not os.path.exists(p):
            print(f"  ✗ 找不到 {p}", file=sys.stderr)
            ok = False
            continue
        data, missing = extract(p, fields, consts)
        # 抽查：每个条目至少要有 number
        bad = [k for k, v in data.items() if "number" not in v]
        dst = os.path.join(a.out, outname)
        # 判据：**必须所有条目都有数字 number**，否则索引会静默变空
        nonum = [k for k, v in data.items() if not isinstance(v.get("number"), int)]
        from collections import Counter
        by_num = {str(v["number"]): k for k, v in data.items()
                  if isinstance(v.get("number"), int)}
        with open(dst, "w", encoding="utf-8") as f:
            json.dump({"source": f"src/data/{fname}", "entries": data,
                       "byNumber": by_num}, f, ensure_ascii=False, indent=1)
        if nonum:
            print(f"    ⚠️ {len(nonum)} 条 number 不是数字（索引会缺）：{nonum[:3]}",
                  file=sys.stderr)
        print(f"  {outname}: {len(data)} 条，数字键 {len(by_num)} 个"
              f" -> {os.path.getsize(dst)//1024} KB")

    # 抽查两个关键条目 —— 判据是"数值对得上源码"
    cp = os.path.join(a.out, "characters.json")
    ip = os.path.join(a.out, "items.json")
    if os.path.exists(cp):
        e = json.load(open(cp, encoding="utf-8"))["entries"]
        print(f"    CHARACTER_EIRIKA: {e.get('CHARACTER_EIRIKA')}")
    if os.path.exists(ip):
        e = json.load(open(ip, encoding="utf-8"))["entries"]
        print(f"    ITEM_SWORD_IRON: {e.get('ITEM_SWORD_IRON')}")
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
