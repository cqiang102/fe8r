#!/usr/bin/env python3
"""
章节号 → 地图名（+ 图块集 / 调色板 / TSA）。

## 为什么需要

`LOMA(x)` 的操作数是 **chapterIndex**（`src/eventscr_0800F390.c:45-68`）：

    chIndex = current[1];
    gPlaySt.chapterIndex = chIndex;
    RestartBattleMap();

**不是资产 id。** 序章的 `EventScr_Prologue_RenaisThroneCutscene` 靠三次
`LOMA` 换三张图：

    LOMA(0x10) → 章节 16 (E15) → Ch16Map          ← 王座厅（王宫内）
    LOMA(0x40) → 章节 64 (0x40) → GradoCastleMap  ← 王宫外
    LOMA(0)    → 章节 0  (L00) → PrologueMap      ← 可玩地图

而 `struct ChapterMap`（`include/chapterdata.h:5-13`）里
`obj1Id` 才是地图图块，`mainLayerId` 是事件层 —— 不要搞混
（我一开始按 `mainLayerId` 找，找到的是 `RenaisThroneMap` 那张
**章节 67 的**地图，不是序章用的那张）。

## 数据从哪来

复用 `map_render.py --list` 已经建立的映射（它解析的是
`gChapterDataTable` + `gChapterDataAssetTable`）。
"""
import argparse
import json
import os
import re
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", default=os.path.join(HERE, "..", "out", "tables"))
    a = ap.parse_args()

    r = subprocess.run([sys.executable, os.path.join(HERE, "map_render.py"),
                        "--list"], capture_output=True, text=True)
    if r.returncode != 0:
        print(f"错误：map_render.py --list 失败\n{r.stderr[:400]}", file=sys.stderr)
        return 1

    # 「章节 → 资产」段：`  L00   tileset=...  map=PrologueMap`
    out = {}
    ordered = []          # 与 gChapterDataTable 同序 —— index 就是它的下标
    seen = False
    for line in r.stdout.split("\n"):
        if "章节 → 资产" in line:
            seen = True
            continue
        if not seen:
            continue
        m = re.match(r"\s*(\S+)\s+tileset=(\S+)\s+pal=(\S+)\s+tsa=(\S+)\s+map=(\S+)", line)
        if not m:
            continue
        name, tileset, pal, tsa, mp = m.groups()
        out[name] = {"tileset": tileset, "palette": pal, "tsa": tsa, "map": mp}
        ordered.append(name)

    if not out:
        print("错误：没解析到任何章节→地图映射", file=sys.stderr)
        return 1

    # ★ 同时按 **index** 发一份。
    #
    # ## 为什么必须按 index
    #
    # `map_render.py --list` 打的是**资产表里的符号名**：能查到名字的章节是
    # `L00` / `E15`，查不到的是 `CH64` / `CH67`（这些是过场/外传章）。
    # 而 `chapters.json` 里同一批章节的 `internalName` 是 **`-`**：
    #
    #     index 64:  chapters.json internalName = '-'   （没有章节名）
    #                chapter_maps.json 的键     = 'CH64'
    #
    # 于是 `Fe8Game.chapterMapName('-')` 返回 null → `LOMA(64)` **静默不换图**。
    # 后果：序章的"王宫外"那一幕没有地图（用户指出的），
    # 以及脚本里用到的 46 个 LOMA 目标里有 **11 个**查不到。
    #
    # index 是两边都有的、无歧义的键 —— 用它join。
    idx_by_name = {name: i for i, name in enumerate(ordered)}

    by_index = {}
    for name, v in out.items():
        i = idx_by_name.get(name)
        if i is not None:
            by_index[str(i)] = dict(v, name=name)
    if len(by_index) != len(out):
        print(f"⚠️ 按 index 只有 {len(by_index)} 条，按名字有 {len(out)} 条",
              file=sys.stderr)

    # 对齐判据：凡 `chapters.json` 里有真名的章节，两边名字必须一致。
    # 不一致说明两个提取器的章节顺序错开了 —— 那 index join 就不可信。
    cj = os.path.join(a.out, "chapters.json")
    if os.path.exists(cj):
        ch = json.load(open(cj, encoding="utf-8"))["chapters"]
        mism = []
        for c in ch:
            n, i = c["internalName"], c["index"]
            if n == "-":
                continue
            got = by_index.get(str(i), {}).get("name")
            if got != n:
                mism.append((i, n, got))
        if mism:
            print(f"❌ chapters.json 与 chapter_maps 的章节顺序对不上：{mism[:5]}",
                  file=sys.stderr)
            return 1
        print(f"  对齐判据：{sum(1 for c in ch if c['internalName'] != '-')} "
              f"个有名字的章节，index 与名字全部一致 ✓")

    os.makedirs(a.out, exist_ok=True)
    dst = os.path.join(a.out, "chapter_maps.json")
    with open(dst, "w", encoding="utf-8") as f:
        json.dump({
            "source": "gChapterDataTable / gChapterDataAssetTable",
            "note": "LOMA 的操作数是 chapterIndex；`byIndex` 是权威键，"
                    "`chapters` 按资产符号名（L00/E15/CH64…）保留给人读",
            "byIndex": by_index,
            "chapters": out,
        }, f, ensure_ascii=False, indent=1)
    named = sum(1 for v in out.values() if v["map"] != "?")
    print(f"章节 {len(out)} 个，其中 {named} 个有地图名")
    print(f"  序章用到的三张（按 index）：")
    for i in (0, 16, 64):
        v = by_index.get(str(i))
        print(f"    index {i:<3} name={v['name'] if v else '?':<6} "
              f"→ {v['map'] if v else '（缺）'}")
    print(f"→ {dst}  ({os.path.getsize(dst) // 1024} KB)")
    return 0


def export_for_game(chapters, outdir):
    """把**游戏要用的地图**导出成 `assets/maps/<名字>.{tmx,json,metatiles.png}`。

    ⚠️ 原来游戏只硬编码加载 `assets/maps/prologue.tmx` 一张 ——
    而序章要靠 `LOMA` 在**三张**之间切（王座厅 → 王宫外 → 可玩地图）。
    没有这三张，`LOMA` 实现了也换不出来。
    """
    os.makedirs(outdir, exist_ok=True)
    todo = ["PrologueMap", "Ch16Map", "GradoCastleMap"]
    ok = 0
    for mp in todo:
        r = subprocess.run(
            [sys.executable, os.path.join(HERE, "map_render.py"), mp,
             "--out", os.path.join(outdir, f"{mp}.png")],
            capture_output=True, text=True)
        if r.returncode != 0:
            print(f"  ✗ {mp}: {r.stderr.strip()[:120]}")
            continue
        # map_render 同时产出 .tmx/.json/.metatiles.png（在 --out 同目录）
        ok += 1
    return ok


if __name__ == "__main__":
    sys.exit(main())
