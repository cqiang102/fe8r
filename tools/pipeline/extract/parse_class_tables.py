#!/usr/bin/env python3
"""
提取**职业表**里表现层与规则层都需要的那几个字段。

`src/data/data_classes.c` 是 5314 行的指定初始化器大表：

    [CLASS_EIRIKA_LORD - 1] = {
        .number = CLASS_EIRIKA_LORD,
        ...
        .pMovCostTable = {
            TerrainTable_MovCost_CommonT2Normal,
            TerrainTable_MovCost_CommonT2Rain,
            TerrainTable_MovCost_CommonT2Snow,
        },
        .pTerrainAvoidLookup       = TerrainTable_Avo_Common,
        .pTerrainDefenseLookup     = TerrainTable_Def_Common,
        .pTerrainResistanceLookup  = TerrainTable_Res_Common,
    },

只取这四个东西，理由：

  * `pMovCostTable` —— 真实的**按职业、按天气**的移动消耗表。
    之前 `FlowMachine` 用的是"全地形消耗 1"的占位表，
    并明确标注了"非移植"。有了它才能消掉那个占位。
  * 三个 `pTerrain*Lookup` —— 地形防御/回避/魔防加成。
    注意它们是**按职业**查的（飞行职业用的是 `_Fly` 那套，
    地形加成基本为 0），不是全局一张表。这一点很容易搞错。

**不提取**其余字段（成长率、基础值、上限等）：那些属于 M12 的章节/单位
数据管线，现在提取了也没人用，只会增加需要维护的、可能悄悄失准的副本。

判据：所有引用的表名必须在已导出的 `terrains.json` 里存在，
否则报错退出 —— 名字对不上说明解析歪了，不能默默产出一份半成品。
"""
import argparse
import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.abspath(os.path.join(HERE, "..", "..", ".."))
DECOMP = os.path.join(REPO, "third_party", "fireemblem8j")

SRC = "src/data/data_classes.c"
ENUM_HEADER = "include/constants/classes.h"

# 一个职业块的起始：`[CLASS_X - 1] = {`
ENTRY_RX = re.compile(r"\[\s*(CLASS_\w+)\s*-\s*1\s*\]\s*=\s*\{")
FIELD_RX = re.compile(r"\.(\w+)\s*=\s*([^,}]+?)\s*,")
FIELD_ARRAY_RX = re.compile(r"\.(\w+)\s*=\s*\{(.*?)\}\s*,", re.S)

WANTED_SCALAR = ("number",)
WANTED_PTR = (
    "pTerrainAvoidLookup",
    "pTerrainDefenseLookup",
    "pTerrainResistanceLookup",
)
WANTED_ARRAY = ("pMovCostTable",)


def strip_comments(text):
    """先剥注释再解析 —— 顺序不能反（parse_c_tables.py 里踩过这个坑）"""
    text = re.sub(r"/\*.*?\*/", " ", text, flags=re.S)
    text = re.sub(r"//[^\n]*", " ", text)
    return text


def parse_enum(path):
    src = open(path, encoding="utf-8", errors="replace").read()
    # ⚠️ **必须先剥注释**。classes.h 里有形如
    #     CLASS_MANAKETE = 0x0E, // TODO: which one?
    #     CLASS_MERCENARY = 0x0F,
    # 的写法：不剥注释时，按逗号切出来的下一段是
    #     "// TODO: which one?\n    CLASS_MERCENARY = 0x0F"
    # 于是 key 变成 "// TODO: ... CLASS_MERCENARY"，这个常量**被静默丢掉**。
    # 实测 classes.h 因此少了 4 个职业常量（MERCENARY / MANAKETE_MYRRH /
    # FALLEN_PRINCE / OBSTACLE）—— 不报错，只是查不到。
    src = re.sub(r"/\*.*?\*/", " ", src, flags=re.S)
    src = re.sub(r"//[^\n]*", " ", src)
    body = max(re.findall(r"enum\s*\w*\s*\{(.*?)\}", src, re.S), key=len)
    out, nxt = {}, 0
    for item in body.split(","):
        item = item.strip()
        if not item:
            continue
        if "=" in item:
            k, v = item.split("=", 1)
            k, v = k.strip(), v.strip()
            try:
                nxt = int(v, 0)
            except ValueError:
                # 值可能是**另一个枚举名**（别名），例如
                #     CLASS_OBSTACLE = CLASS_EPHRAIM_LORD,
                # 直接把别名解析成它的值；解析不了才跳过。
                if v in out:
                    nxt = out[v]
                else:
                    continue
        else:
            k = item
        out[k] = nxt
        nxt += 1
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", default=os.path.join(HERE, "..", "out", "tables"))
    a = ap.parse_args()

    src_path = os.path.join(DECOMP, SRC)
    if not os.path.exists(src_path):
        print(f"错误：找不到 {src_path}", file=sys.stderr)
        return 1

    # 已导出的表名，用来校验引用
    terr_path = os.path.join(a.out, "terrains.json")
    if not os.path.exists(terr_path):
        print(f"错误：先跑 parse_c_tables.py 生成 {terr_path}", file=sys.stderr)
        return 1
    terr = json.load(open(terr_path, encoding="utf-8"))
    known_tables = set(terr["tables"].keys())

    text = strip_comments(open(src_path, encoding="utf-8", errors="replace").read())
    cls_enum = parse_enum(os.path.join(DECOMP, ENUM_HEADER))
    print(f"职业枚举: {len(cls_enum)} 个常量")

    # 切出每个职业块
    marks = [(m.start(), m.group(1)) for m in ENTRY_RX.finditer(text)]
    print(f"职业块: {len(marks)} 个")

    classes = {}
    problems = []
    no_table = []
    for i, (start, key) in enumerate(marks):
        end = marks[i + 1][0] if i + 1 < len(marks) else len(text)
        block = text[start:end]

        entry = {"key": key}

        for f in WANTED_SCALAR:
            m = re.search(rf"\.{f}\s*=\s*([^,}}]+?)\s*,", block)
            if m:
                v = m.group(1).strip()
                entry[f] = cls_enum.get(v, None) if not v.isdigit() else int(v)
                if entry[f] is None:
                    try:
                        entry[f] = int(v, 0)
                    except ValueError:
                        problems.append(f"{key}: 无法解析 .{f} = {v}")

        for f in WANTED_PTR:
            m = re.search(rf"\.{f}\s*=\s*(\w+)\s*,", block)
            if m:
                entry[f] = m.group(1)
                if m.group(1) not in known_tables:
                    problems.append(f"{key}: .{f} 引用了未知表 {m.group(1)}")
            else:
                # ⚠️ 有些职业**本来就没有**移动消耗表：
                # 石像鬼蛋、弩车（BLST_*）、UNK77 这些不是可正常行走的职业。
                # 缺表是事实，不是解析失败 —— 记成 None 而不是报错。
                # 但要**区分**"真的没有"和"解析歪了"：前者这些块会明显短，
                # 后者会大面积缺字段（下面的比例检查负责兜底）。
                entry[f] = None
                no_table.append(key)

        for f in WANTED_ARRAY:
            # ⚠️ 必须**按字段名**定向搜索。
            # 用通用的"找数组字段"再比较名字，会先命中块里更早的数组字段
            # （职业块里第一个数组字段不是 pMovCostTable），于是全部报缺失。
            m = re.search(rf"\.{f}\s*=\s*\{{(.*?)\}}\s*,", block, re.S)
            if m:
                names = [x.strip() for x in m.group(1).split(",") if x.strip()]
                entry[f] = names
                for n in names:
                    if n not in known_tables:
                        problems.append(f"{key}: .{f} 引用了未知表 {n}")
            else:
                # ⚠️ 有些职业**本来就没有**移动消耗表：
                # 石像鬼蛋、弩车（BLST_*）、UNK77 这些不是可正常行走的职业。
                # 缺表是事实，不是解析失败 —— 记成 None 而不是报错。
                # 但要**区分**"真的没有"和"解析歪了"：前者这些块会明显短，
                # 后者会大面积缺字段（下面的比例检查负责兜底）。
                entry[f] = None
                no_table.append(key)

        classes[key] = entry

    # 兜底：如果**大比例**职业都没有移动表，那不是"这些职业特殊"，
    # 而是块切分或字段名解析歪了。
    if len(classes) and len(no_table) > len(classes) // 4:
        problems.append(
            f"有 {len(no_table)}/{len(classes)} 个职业缺少 pMovCostTable，"
            f"比例过高，怀疑是解析问题而不是数据本身")
    if problems:
        print(f"\n❌ 解析问题 {len(problems)} 项:", file=sys.stderr)
        for p in problems[:12]:
            print(f"  {p}", file=sys.stderr)
        return 1

    if no_table:
        print(f"\nℹ️  这 {len(no_table)} 个职业本来就没有移动消耗表（非错误）:")
        print(f"   {', '.join(sorted(no_table))}")

    # 抽查：飞行职业应当用 _Fly 那套
    fly = [k for k, v in classes.items()
           if v.get("pTerrainAvoidLookup", "").endswith("_Fly")]
    common = [k for k, v in classes.items()
              if v.get("pTerrainAvoidLookup", "").endswith("_Common")]
    print(f"\n用 _Fly 表（地形加成基本为 0）的职业: {len(fly)}")
    print(f"  例: {', '.join(sorted(fly)[:6])}")
    print(f"用 _Common 表的职业: {len(common)}")

    # 抽查一张表的数值含义
    avo_common = terr["tables"]["TerrainTable_Avo_Common"]["values"]
    avo_fly = terr["tables"]["TerrainTable_Avo_Fly"]["values"]
    rev = {v: k for k, v in terr["enum"].items()}
    print("\n地形加成抽查（TERRAIN_FOREST / TERRAIN_PEAK / TERRAIN_PLAINS）:")
    for tid, nm in ((0x05, "TERRAIN_FOREST"), (0x06, "TERRAIN_PEAK"),
                    (0x01, "TERRAIN_PLAINS")):
        print(f"  {nm:<18} 步兵回避 {avo_common[tid]:>3}   "
              f"飞行回避 {avo_fly[tid]:>3}")

    os.makedirs(a.out, exist_ok=True)
    payload = {
        "source": SRC,
        "classEnum": cls_enum,
        "classes": classes,
    }
    dst = os.path.join(a.out, "classes.json")
    with open(dst, "w", encoding="utf-8") as f:
        json.dump(payload, f, ensure_ascii=False, indent=1)
    print(f"\n→ {dst}  ({os.path.getsize(dst) // 1024} KB)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
