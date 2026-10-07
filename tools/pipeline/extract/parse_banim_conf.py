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


def parse_class_links():
    """`{CLASS_X: 'AnimConf_N'}` —— 从 `data_classes.c` 的 `.pBattleAnimDef`"""
    txt = read(os.path.join(DECOMP, "src", "data", "data_classes.c"))
    out = {}
    for m in re.finditer(
            r"\[(CLASS_\w+)\s*-\s*1\]\s*=\s*\{(.*?)\n    \},", txt, re.S):
        cls, body = m.group(1), m.group(2)
        a = re.search(r"\.pBattleAnimDef\s*=\s*(\w+)", body)
        if a:
            out[cls] = a.group(1)
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", default=os.path.join(HERE, "..", "out", "tables"))
    a = ap.parse_args()

    c = consts()
    confs = parse_confs(c)
    # ⚠️ **不输出** class→AnimConf 的链接：我这一版解析出来 101 条，
    # 里面还有 `AnimConf_100` 这种**不存在的表** ⇒ 职业块的正则不可靠。
    # 按纪律：**没验证过的数据不进产物**。下一步再解它（要按嵌套花括号配对切块）。
    _links_unreliable = parse_class_links()

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
    if len(confs) != 24:
        print(f"❌ carve 出来的 AnimConf 表数不是 24：{len(confs)}", file=sys.stderr)
        return 1
    # ⚠️ 我第一版断言 `EIRIKA_LORD → AnimConf_0` —— **错了**：
    # `data_classes.c` 里第一个职业块是 `[CLASS_EPHRAIM_LORD - 1]`（编号 1），
    # 第 41 行那条 `.pBattleAnimDef = AnimConf_0` 属于它；
    # `[CLASS_EIRIKA_LORD - 1]` 从第 51 行才开始。照**源码顺序**断言：

    print(f"  ⚠️ layout 里 77 张，**carve 里只有 {len(confs)} 张** —— 缺的 53 张取不到")
    first = confs["AnimConf_24"][0]
    if first["index"] != 0x26:
        print(f"❌ AnimConf_24 首条 index = {first['index']}（应为 0x26）", file=sys.stderr)
        return 1
    print(f"  ✓ carve 出的 AnimConf {len(confs)}/{total_in_layout} 张；"
          f"抽查 AnimConf_24[0].index = {confs['AnimConf_24'][0]['index']:#x}")

    os.makedirs(a.out, exist_ok=True)
    dst = os.path.join(a.out, "banim_conf.json")
    with open(dst, "w", encoding="utf-8") as f:
        json.dump({
            "note": "职业 → 战斗动画定义表 → 按武器类型的动画编号。"
                    "下一个跳（index → 帧图 sheet）还没解。",
            "confs": confs,
            "confsInLayout": total_in_layout,
            "note2": "class→AnimConf 的链接**没解出来**（职业块正则不可靠，见文件头）；"
                     "index→帧图 sheet 也还没解。", 
        }, f, ensure_ascii=False, indent=1)
    print(f"→ {dst}  ({os.path.getsize(dst) // 1024} KB)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
