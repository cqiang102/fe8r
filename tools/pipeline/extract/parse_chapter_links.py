#!/usr/bin/env python3
"""
把「章节 → 地图 / 事件组 / 单位表」整条链打通。

## 关键发现：反编译项目**已经做过去指针化**了

我一直以为需要"编译 → 读重定位 → 反推指向哪个符号"。**完全不需要。**

反编译项目用 `scripts/repoint_table.py` 把所有指针表转成了**符号引用**：

1. `layout/baseline_syms.d/dataMore_chapter_asset_table.tsv`
   已经把每个资产的**名字**写好了：

       gChDAsset_7    08A5A760  data  ... pointee (idx 7, US PrologueEvents)
       gChDAsset_10   08A5A8C0  data  ... pointee (idx 10, US Ch1Events)

2. `src/data/<Name>_ref/dat_<Name>_ref.c` 里，`ChapterEventGroup` 的
   **20 个字段全部是符号名**：

       static const u32 PrologueEvents__shift[] = {
           (u32)&EventListScr_Prologue_Turn,        // turnBasedEvents
           (u32)&EventListScr_Prologue_Character,   // characterBasedEvents
           ...
           (u32)&UnitDef_Event_PrologueAlly,        // playerUnitsInNormal
           (u32)&EventScr_Prologue_BeginningScene,  // beginningSceneEvents
           (u32)&EventScr_Prologue_EndingScene,
       };

**名字就明明白白写在文件里。** 我为了"恢复"这些字符串，
绕道编译 + 重定位表，花了四轮 —— 这是过度套用
"让编译器算"那条原则（它只适用于**位域**）。

## ⚠️ 一个已知的下标偏移

`dataMore_chapter_asset_table.tsv` 的 `US <Name>` 标注是**美版**的。
JP 版缺少 `MapPalette4` / `MapPalette16` 两个条目，所以**从某个下标起，
US 名字与 JP 的实际内容会错位**。

实测：79 章里引用到 60 个不同的资产名，其中只有 9 个以 `Events` 结尾
并被正确解析成事件组；其余 51 个落在偏移区，名字是错位的。

**这 9 个是可信的**（都在偏移点之前）。要覆盖全部章节，
需要先确定偏移点并做 JP↔US 的下标校正 —— 属于后续工作。

判断依据不是"我猜偏移在哪"，而是：`mapEventDataId` 按
`GetChapterEventDataPointer` 的用法**必然是事件组**，
出现 `Ch10EphraimMapChanges` 这种名字就说明标注错位了。

## 这条链

    chapterIndex
      → gChapterDataTable[i].mapEventDataId        （parse_chapters.py）
      → gChDAsset_<id>  →  US <Name>                （本文件，读 TSV）
      → <Name>Events__shift[] 的 20 个符号名          （本文件，读 C）

用法:
    python3 tools/pipeline/extract/parse_chapter_links.py --out out/tables
"""
import argparse
import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.abspath(os.path.join(HERE, "..", "..", ".."))
DECOMP = os.path.join(REPO, "third_party", "fireemblem8j")

ASSET_TSV = "layout/baseline_syms.d/dataMore_chapter_asset_table.tsv"
CH_REF_DIR = "src/data"

# `struct ChapterEventGroup` 的字段顺序（include/chapterdata.h:118）。
# ⚠️ 顺序必须与结构体一致 —— 数组是按位置对应的，错一位就全错。
# 从 C 源里读出来而不是手抄：手抄会因为结构体变动而静默失准。
GROUP_FIELDS = (
    "turnBasedEvents",
    "characterBasedEvents",
    "locationBasedEvents",
    "miscBasedEvents",
    "specialEventsWhenUnitSelected",
    "specialEventsWhenDestSelected",
    "specialEventsAfterUnitMoved",
    "tutorialEvents",
    "traps",
    "extraTrapsInHard",
    "playerUnitsInNormal",
    "playerUnitsInHard",
    "playerUnitsChoice1InEncounter",
    "playerUnitsChoice2InEncounter",
    "playerUnitsChoice3InEncounter",
    "enemyUnitsChoice1InEncounter",
    "enemyUnitsChoice2InEncounter",
    "enemyUnitsChoice3InEncounter",
    "beginningSceneEvents",
    "endingSceneEvents",
)


def strip_comments(text):
    text = re.sub(r"/\*.*?\*/", " ", text, flags=re.S)
    return re.sub(r"//[^\n]*", " ", text)


def group_fields_from_header():
    """从 `include/chapterdata.h` 读 `struct ChapterEventGroup` 的字段名与顺序。

    比手抄一份可靠：结构体改了这里会跟着变，不会静默错位。
    """
    path = os.path.join(DECOMP, "include/chapterdata.h")
    src = strip_comments(open(path, encoding="utf-8", errors="replace").read())
    m = re.search(r"struct ChapterEventGroup\s*\{(.*?)\n\};", src, re.S)
    if not m:
        return None
    out = []
    for line in m.group(1).split("\n"):
        # ⚠️ 注释在上面已经被剥掉了，所以这里**不能**再要求 `*/`。
        # 第一版就是因为写了 `\*/\s*const` 而一个字段都没匹配到。
        mm = re.search(r"const\s+void\s*\*\s*(\w+)\s*;", line)
        if mm:
            out.append(mm.group(1))
    return out or None


def read_asset_names():
    """`gChDAsset_<idx>` → `US <Name>` 里的 `<Name>`。"""
    path = os.path.join(DECOMP, ASSET_TSV)
    if not os.path.exists(path):
        return None
    out = {}
    for line in open(path, encoding="utf-8", errors="replace"):
        p = line.rstrip("\n").split("\t")
        if len(p) < 4:
            continue
        m = re.fullmatch(r"gChDAsset_(\d+)", p[0])
        if not m:
            continue
        nm = re.search(r"\(idx \d+,\s*US\s+([^)]+)\)", p[3])
        if nm:
            out[int(m.group(1))] = nm.group(1).strip()
    return out


def read_event_group(name):
    """读 `src/data/<name>_ref/dat_<name>_ref.c` 里的 20 个符号名。

    返回 `{字段名: 符号名或 0}`；文件不存在返回 None。
    """
    d = os.path.join(DECOMP, CH_REF_DIR, f"{name}_ref")
    if not os.path.isdir(d):
        return None
    f = None
    for cand in os.listdir(d):
        if cand.endswith(".c"):
            f = os.path.join(d, cand)
            break
    if f is None:
        return None

    src = strip_comments(open(f, encoding="utf-8", errors="replace").read())
    m = re.search(r"shift\[\]\s*=\s*\{(.*?)\n\};", src, re.S)
    if not m:
        return None

    vals = []
    for item in m.group(1).split(","):
        item = item.strip()
        if not item:
            continue
        # `(u32)&Sym` / `(u32)&Sym + 0xNN` / `0x00000000`
        mm = re.match(r"\(u32\)\s*&\s*([A-Za-z_]\w*)\s*(?:\+\s*(0x[0-9A-Fa-f]+))?$",
                      item)
        if mm:
            vals.append(f"{mm.group(1)}+{mm.group(2)}" if mm.group(2)
                        else mm.group(1))
            continue
        mm = re.match(r"0x0*$|0$", item)
        if mm:
            vals.append("0")
            continue
        vals.append(f"?unparsed:{item[:32]}")

    fields = group_fields_from_header() or GROUP_FIELDS
    if len(vals) != len(fields):
        return {"__count_mismatch__": f"{len(vals)} vs {len(fields)}",
                "raw": vals}
    return dict(zip(fields, vals))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", default=os.path.join(HERE, "..", "out", "tables"))
    a = ap.parse_args()

    fields = group_fields_from_header()
    if not fields:
        print("错误：没能从 chapterdata.h 读出 ChapterEventGroup 字段", file=sys.stderr)
        return 1
    print(f"ChapterEventGroup 字段 {len(fields)} 个（从 chapterdata.h 读出）")

    assets = read_asset_names()
    if assets is None:
        print(f"错误：找不到 {ASSET_TSV}", file=sys.stderr)
        return 1
    print(f"资产表 {len(assets)} 条（从 baseline_syms TSV 读出）")

    # 章节 → 事件组
    ch_path = os.path.join(a.out, "chapters.json")
    if not os.path.exists(ch_path):
        print(f"错误：先跑 parse_chapters.py 生成 {ch_path}", file=sys.stderr)
        return 1
    chapters = json.load(open(ch_path, encoding="utf-8"))["chapters"]

    links = []
    groups = {}
    problems = []
    for c in chapters:
        aid = c["mapEventDataId"]
        name = assets.get(aid)
        entry = {
            "index": c["index"],
            "internalName": c["internalName"],
            "mapEventDataId": aid,
            "eventGroupName": name,
        }
        if name is None:
            problems.append(f"{c['internalName']}: 资产 {aid} 无名")
        elif name.endswith("Events"):
            g = read_event_group(name)
            if g is None:
                problems.append(f"{c['internalName']}: 找不到 {name}_ref")
            elif "__count_mismatch__" in g:
                problems.append(
                    f"{name}: 字段数不符 {g['__count_mismatch__']}")
            else:
                groups[name] = g
        links.append(entry)

    print(f"\n章节 {len(links)} 条，解析出事件组 {len(groups)} 个")
    if problems:
        print(f"⚠️  {len(problems)} 处未解析:", file=sys.stderr)
        for p in problems[:6]:
            print(f"   {p}", file=sys.stderr)

    # 抽查：Prologue 的盟友单位表
    pro = groups.get("PrologueEvents")
    if pro:
        print("\n抽查 PrologueEvents:")
        for k in ("playerUnitsInNormal", "beginningSceneEvents",
                  "turnBasedEvents", "endingSceneEvents"):
            print(f"   {k:<26} = {pro.get(k)}")

    os.makedirs(a.out, exist_ok=True)
    payload = {
        "source": [ASSET_TSV, f"{CH_REF_DIR}/<Name>_ref/"],
        "groupFields": list(fields),
        "links": links,
        "eventGroups": groups,
    }
    dst = os.path.join(a.out, "chapter_links.json")
    with open(dst, "w", encoding="utf-8") as f:
        json.dump(payload, f, ensure_ascii=False, indent=1)
    print(f"\n→ {dst}  ({os.path.getsize(dst) // 1024} KB)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
