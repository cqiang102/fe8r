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

    if not out:
        print("错误：没解析到任何章节→地图映射", file=sys.stderr)
        return 1

    os.makedirs(a.out, exist_ok=True)
    dst = os.path.join(a.out, "chapter_maps.json")
    with open(dst, "w", encoding="utf-8") as f:
        json.dump({
            "source": "gChapterDataTable / gChapterDataAssetTable",
            "note": "LOMA 的操作数是 chapterIndex；下表用内部名（L00/E15/CH64…）",
            "chapters": out,
        }, f, ensure_ascii=False, indent=1)
    named = sum(1 for v in out.values() if v["map"] != "?")
    print(f"章节 {len(out)} 个，其中 {named} 个有地图名")
    print(f"  序章用到的三张：")
    for k in ("L00", "E15", "CH64"):
        if k in out:
            print(f"    {k:<6} → {out[k]['map']}")
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
