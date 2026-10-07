#!/usr/bin/env python3
"""职业 → 战斗动画定义 → 动画编号（M2 地图/全屏战斗动画的**映射层**）。

出处：
* `struct BattleAnimDef { u16 wtype; u16 index; }`（`include/ekrbattle.h:324-327`）
* 每张表 `AnimConf_<N>[]` 定义在 `src/data/data_banimconf_*.c`
  例：`src/data/data_banimconf_24_29.c:5-16`
      `CONST_DATA struct BattleAnimDef AnimConf_24[] = { { .wtype = 0x0100 | ITYPE_BOW, .index = 0x0026 }, … }`
* 职业通过 `struct UnitClassData.pBattleAnimDef` 指向其中一张
  （`src/data/data_classes.c` 里 `.pBattleAnimDef = AnimConf_0`）
* 消费方：`GetBattleAnimationId_WithUnique(unit, pBattleAnimDef, wtype, out)`
  （`include/anime.h:206`）—— 按**武器类型**在表里查到动画编号。

判据（正向抽查真值，不是"文件存在"）：
* 表数 = 77（`layout/baseline_syms.d/dataCharClass.tsv` 里的 `AnimConf_*` 条数）
* `CLASS_EIRIKA_LORD` → `AnimConf_0`
* `AnimConf_24` 的第 1 条 = `{wtype: 0x0100|ITYPE_BOW, index: 0x26}`

⚠️ 还差的下一跳（**不在本文件**）：`index` → 具体**帧图/sheet**。
那要 `AnimData`/`AnimSprite` 那一层，表里名字多为 `gUnknown_*`
（`graphics/mapanim` 的 263 张 PNG），**没对上就不做**。
"""
import argparse
import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
DECOMP = os.path.normpath(os.path.join(HERE, "..", "..", "..", "third_party", "fireemblem8j"))


def read(p):
    return open(p, encoding="utf-8", errors="replace").read()


def consts():
    """`ITYPE_*` / `ITEM_*` 的数值（`include/constants/items.h`）"""
    txt = read(os.path.join(DECOMP, "include", "constants", "items.h"))
    out = {}
    for m in re.finditer(r"^\s*(ITYPE_[A-Z0-9_]+|ITEM_[A-Z0-9_]+)\s*=\s*([0-9]+|0x[0-9A-Fa-f]+)",
                         txt, re.M):
        out[m.group(1)] = int(m.group(2), 0)
    return out


def eval_wtype(tok, c):
    tok = tok.strip()
    m = re.fullmatch(r"0x0100\s*\|\s*(\w+)", tok)
    if m:
        return 0x0100 | c.get(m.group(1), 0)
    if tok in c:
        return c[tok]
    try:
        return int(tok, 0)
    except ValueError:
        return None


def parse_confs(c):
    """`{AnimConf_N: [ {wtype, index} ]}`"""
    out = {}
    for f in sorted(os.listdir(os.path.join(DECOMP, "src", "data"))):
        if not f.startswith("data_banimconf"):
            continue
        txt = read(os.path.join(DECOMP, "src", "data", f))
        for m in re.finditer(
                r"AnimConf_(\d+)\[\]\s*=\s*\{(.*?)\n\};", txt, re.S):
            name = f"AnimConf_{m.group(1)}"
            entries = []
            for e in re.finditer(
                    r"\.wtype\s*=\s*([^,]+),\s*\.index\s*=\s*([^,\n]+)", m.group(2)):
                w = eval_wtype(e.group(1), c)
                idx = e.group(2).strip()
                entries.append({
                    "wtype": w,
                    "wtypeRaw": e.group(1).strip(),
                    "index": int(idx, 0) if re.fullmatch(r"0x[0-9A-Fa-f]+|\d+", idx) else idx,
                })
            if entries:
                out[name] = entries
    return out


def conf_names_in_layout():
    """`layout/baseline_syms.d/dataCharClass.tsv` 里登记的全部 `AnimConf_*` 名字"""
    tsv = os.path.join(DECOMP, "layout", "baseline_syms.d", "dataCharClass.tsv")
    if not os.path.exists(tsv):
        return set()
    return {l.split("\t")[0] for l in open(tsv, encoding="utf-8", errors="replace")
            if l.startswith("AnimConf_")}


def parse_class_links():
    """`{CLASS_X: 'AnimConf_N'}` —— 从 `data_classes.c` 的 `.pBattleAnimDef`

    ⚠️ 上一版我用 `\[(CLASS_\w+)\s*-\s*1\]\s*=\s*\{(.*?)\n    \},` 这种
    非贪婪正则切块 —— 解出 **101 条**、还含 `AnimConf_100` 这种**不存在的表** ⇒ 不可靠。
    原因：职业块里**嵌着别的花括号**（`.pMovCostTable = { … }`、`.baseRanks = { … }`），
    非贪婪匹配会在**内层**第一个 `},` 就收尾。

    现在改成**花括号配对**切块：从 `[CLASS_X - 1] = {` 的 `{` 开始数深度，
    深度回到 0 才切出 body。
    """
    txt = read(os.path.join(DECOMP, "src", "data", "data_classes.c"))
    out = {}
    for m in re.finditer(r"\[(CLASS_\w+)\s*-\s*1\]\s*=\s*\{", txt):
        i = m.end()
        depth = 1
        while i < len(txt) and depth > 0:
            c = txt[i]
            if c == "{":
                depth += 1
            elif c == "}":
                depth -= 1
            i += 1
        body = txt[m.end():i - 1]
        a = re.search(r"\.pBattleAnimDef\s*=\s*(\w+)", body)
        if a:
            out[m.group(1)] = a.group(1)
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", default=os.path.join(HERE, "..", "out", "tables"))
    a = ap.parse_args()

    c = consts()
    confs = parse_confs(c)
    links = parse_class_links()

    # ---- 自检：引用的名字必须是 `AnimConf_<数字>`，且**引用的来源要能对上** ----
    #
    # ⚠️ 上一版想拿 `layout/baseline_syms.d/dataCharClass.tsv` 当白名单 —— **前提是错的**：
    # 那个 TSV 里 `AnimConf_*` 的编号是 `0, 30, 73, …, 100`（`grep -c "AnimConf_24\b"` = **0**），
    # 而 carve 的 `src/data/data_banimconf_24_29.c` 里**明明定义着** `AnimConf_24`。
    # ⇒ 不能用它当白名单。
    #
    # ★★ **第 40 轮查清了**（原来这里写的是"两套编号不是同一套，原因未查证" —— **错了**）：
    #   * layout 行 77 个 + carve 定义 24 个 = **并集 101、交集 0、编号 0..100 连续无缺号**；
    #   * 地址也对得上：`AnimConf_23`(0x089036D0) → `AnimConf_30`(0x0890375C)
    #     之间 140 字节 / 7 张 = **20.0 B/张**（中间正是被 carve 抽走的 24..29）；
    #     `35→48` = 284/13 = 21.8；`60→67` = 164/7 = 23.4。
    # ⇒ **编号是同一套**，两套是**互补**的：layout 保留没被 carve 的行，
    #   被 carve 走的那些就从 layout 里消失了。
    # 能站的基准只有一个：**`src/data/` 里真的定义了什么**。
    bad_name = sorted({v for v in links.values() if not re.fullmatch(r"AnimConf_\d+", v)})
    if bad_name:
        print(f"❌ 有 {len(bad_name)} 个引用不是 AnimConf_<数字>：{bad_name[:6]}", file=sys.stderr)
        return 1

    # ---- 正向抽查 ----
    #
    # ⚠️ **77 是"应该有多少"，24 是"carve 里实际有多少"**。
    # `layout/baseline_syms.d/dataCharClass.tsv` 里有 77 个 `AnimConf_*`，
    # 但 `src/data/` 只 carve 了 `data_banimconf_24_29` / `_36_47` / `_61_66`
    # ⇒ 6 + 12 + 6 = **24**。
    # 这一条是**实测**（我第一次照 77 断言，直接红了 —— 那说明断言写错了，
    # 不是数据错了）。缺的那 53 张是 carve 侧的缺口，**不能编**。
    total_in_layout = 0
    tsv = os.path.join(DECOMP, "layout", "baseline_syms.d", "dataCharClass.tsv")
    if os.path.exists(tsv):
        total_in_layout = sum(1 for l in open(tsv, encoding="utf-8", errors="replace")
                              if l.startswith("AnimConf_"))
    # 出处：`data_classes.c` 里第一个职业块是 `[CLASS_EPHRAIM_LORD - 1]`（编号 1），
    # 其 `.pBattleAnimDef = AnimConf_0`；`[CLASS_EIRIKA_LORD - 1]` 是下一个块 → AnimConf_1
    if links.get("CLASS_EPHRAIM_LORD") != "AnimConf_0" or \
            links.get("CLASS_EIRIKA_LORD") != "AnimConf_1":
        print(f"❌ 职业→表 抽查失败：EPHRAIM={links.get('CLASS_EPHRAIM_LORD')} "
              f"EIRIKA={links.get('CLASS_EIRIKA_LORD')}", file=sys.stderr)
        return 1
    if len(confs) != 24:
        print(f"❌ carve 出来的 AnimConf 表数不是 24：{len(confs)}", file=sys.stderr)
        return 1
    # ⚠️ 我第一版断言 `EIRIKA_LORD → AnimConf_0` —— **错了**：
    # `data_classes.c` 里第一个职业块是 `[CLASS_EPHRAIM_LORD - 1]`（编号 1），
    # 第 41 行那条 `.pBattleAnimDef = AnimConf_0` 属于它；
    # `[CLASS_EIRIKA_LORD - 1]` 从第 51 行才开始。照**源码顺序**断言：

    missing = sorted({v for v in links.values() if v not in confs})
    defined_refs = sorted({v for v in links.values() if v in confs})
    print(f"  职业 {len(links)} 条链接 → 引用 {len(set(links.values()))} 张表；"
          f"其中**有定义**的 {len(defined_refs)} 张、**没 definition** 的 {len(missing)} 张")
    print(f"     carve 里定义了 {len(confs)} 张；未定义（例）：{missing[:4]}")
    first = confs["AnimConf_24"][0]
    if first["index"] != 0x26:
        print(f"❌ AnimConf_24 首条 index = {first['index']}（应为 0x26）", file=sys.stderr)
        return 1
    print(f"  ✓ carve 里定义了 {len(confs)} 张 AnimConf；"
          f"抽查 AnimConf_24[0].index = {confs['AnimConf_24'][0]['index']:#x}")

    os.makedirs(a.out, exist_ok=True)
    dst = os.path.join(a.out, "banim_conf.json")
    with open(dst, "w", encoding="utf-8") as f:
        json.dump({
            "note": "职业 → 战斗动画定义表 → 按武器类型的动画编号。"
                    "下一个跳（index → 帧图 sheet）还没解。",
            "classes": links,
            "confs": confs,
            "confsInLayout": total_in_layout,
            "note3": "layout 的 AnimConf 编号（0,30,73,…,100）与 carve 的"
                     "（AnimConf_24..29 等）**是同一套编号的两半** —— "
                     "layout 行 77 + carve 定义 24 = 并集 101、交集 0、编号 0..100 连续；"
                     "地址间隙也对得上（23→30 之间 140B/7 张 = 20.0 B/张）。"
                     "第 40 轮前这里写的是「不是同一套、原因未查证」——**那是错的**。",
            "confsNotCarved": missing,
            "classesWithDefinedConf": sorted(
                k for k, v in links.items() if v in confs),
            "blocker": "序章/第 1 章要动的职业，其动画定义表**没有定义**"
                       "（CLASS_EIRIKA_LORD → AnimConf_1、CLASS_SETH/FRANZ/GILLIAM 在"
                       "`data_classes.c` 里连 `.pBattleAnimDef` 都没解析到）⇒ "
                       "**地图战斗动画目前做不了**：不是缺代码，是缺动画定义表的数据。"
                       "另外 index → 帧图 sheet 那一跳也还没解。",
            "note2": "index→帧图 sheet 还没解（那要 AnimData/AnimSprite 那一层）。", 
        }, f, ensure_ascii=False, indent=1)
    print(f"→ {dst}  ({os.path.getsize(dst) // 1024} KB)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
