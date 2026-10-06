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

## ⚠️ 限制：只有部分事件组能被解析（`_ref` 不完整）

我原以为问题是"US 标注有下标偏移"，于是试着测出偏移点：

    T=45 shift=1: 15/59      T=47 shift=1: 16/59
    T=46 shift=1: 16/59      T=48 shift=1: 16/59
    （基准 shift=0 是 16/60）

**任何偏移假设都不比基准好** —— 说明问题不在偏移。

真正的原因：**反编译项目只对 17 个事件组做了去指针化**
（`src/data/*Events_ref` / `*EventData_ref` 一共 17 个目录），
而章节引用了 60 个不同的资产。
**`_ref` 本身不完整**（去指针化是"前沿"工作，还有大量表没做）。

所以本文件的做法是：**按实际存在的 `_ref` 目录来判定**，
而不是猜命名规则（`Events` / `EventData` 两种都有，还会更多）。
能解析多少算多少，不硬凑。

判断"哪个是事件组"的依据来自 `GetChapterEventDataPointer` 的用法
（`mapEventDataId` 必然是事件组），以及**该符号是否真有去指针化的定义**。

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

    # 实际做过去指针化的事件组目录（这才是"能不能解析"的真判据）
    ref_dirs = set()
    ddir = os.path.join(DECOMP, CH_REF_DIR)
    for n in os.listdir(ddir):
        if n.endswith("_ref") and ("Events" in n or "EventData" in n):
            ref_dirs.add(n[:-4])
    print(f"去指针化过的事件组目录 {len(ref_dirs)} 个"
          f"（这是能解析的上限 —— `_ref` 并不完整）")

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
        elif name in ref_dirs:
            # ⚠️ 按**实际存在的 `_ref` 目录**判定，不猜命名规则。
            # 命名有 `Events` 和 `EventData` 两种（`Ch5EventData`、
            # `Ch16EphraimEventData`…），靠字符串猜会漏。
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
    # ⚠️ **未解析必须失败，不能只警告。**
    #
    # 原来这里只 `print("⚠️ N 处未解析")` 然后 `return 0`（:281）。
    # `_ref` 目录改名、`shift[]` 正则失配 → 事件组静默变少而脚本仍绿。
    # 唯一的兜底是 `chapter_loader_test.dart:46` 钉死"只有 8 章能完整装配"——
    # 那是**下游**的兜底，提取器自己不该静默。
    # ⚠️ **判据要精确：跳过是跳过，问题才是问题。**
    #
    # "资产 0 无名"是**合法的** —— 下标 0 是空占位
    # （`gChapterDataAssetTable[0]` 就是 NULL，见 carved_rom.tsv 的注释）。
    # 我第一版把所有 problems 都当失败，误伤了这 3 处。
    benign = [p for p in problems if "资产 0 无名" in str(p)]
    real = [p for p in problems if "资产 0 无名" not in str(p)]
    if benign:
        print(f"  （{len(benign)} 处'资产 0 无名'是合法的空占位，不计）")
    if real:
        print(f"\n❌ {len(real)} 处未解析 —— 提取器不该静默通过:",
              file=sys.stderr)
        for p in real[:20]:
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
    return 1 if real else 0


if __name__ == "__main__":
    sys.exit(main())
