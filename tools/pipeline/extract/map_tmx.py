#!/usr/bin/env python3
"""
map_tmx.py —— 把 FE8 章节地图导出成 Tiled `.tmx`，并做往返一致性验证。

这是技术方案 §4.9.2 的落地：**不消费 Tiled 格式 ≠ 不导出 Tiled 格式**。
导出后白送一个成熟的关卡编辑器，同时把散在五处的数据（视觉网格 / 地形类型 /
尺寸 / 章节配置 / 触发数据）统一到一个文件里。

## 为什么用「metatile 图集」而不是原始 4bpp 瓦片集

原版瓦片是 4bpp 灰度索引图，必须配调色板才能看；而且同一个瓦片索引在不同
metatile 里会用**不同的调色板 bank**，所以无法用一张原始图集表达。

这里改成：**给地图用到的每个 metatile 索引发一个 16×16 的槽位**，
把颜色直接烘焙进去（含每个角的翻转）。于是

  * 图集是一张普通 RGB PNG，任何编辑器都能打开
  * 图层里一个格子 = 一个 GID，与游戏的格子网格一一对应
  * 不需要 Tiled 的翻转标志位

## 无损往返

每个图集槽位在 tileset 的 tile properties 里记录它的原始 `metatile` 索引
和 `terrain` 名称。因此 `.tmx` 是**自包含**的：读回来就能还原出
`(metatile 网格, 地形网格)`，与 `.mar` + 地形查表逐格比对。

**图层是规则层数据，不是装饰**——地形类型决定移动消耗 / 回避 / 防御加成。
见 README 的红线表。

## 用法

    python3 map_tmx.py PrologueMap                     # 导出到 out/tmx/
    python3 map_tmx.py Ch3Map --out /tmp/tmx
    python3 map_tmx.py --verify out/tmx/PrologueMap.tmx   # 往返验证
    python3 map_tmx.py --verify-all                    # 全部导出 + 全部验证
"""
import argparse
import json
import math
import os
import sys
import xml.etree.ElementTree as ET

from PIL import Image

import map_render as mr

HERE = os.path.dirname(os.path.abspath(__file__))
DEFAULT_OUT = os.path.abspath(os.path.join(HERE, "..", "out", "tmx"))

ATLAS_COLUMNS = 32          # 图集每行放多少个 metatile
TILE = 16                   # metatile 边长（像素）= 2×2 个 8×8 瓦片


# --------------------------------------------------------------- 资产解析

def resolve_all(map_id):
    """把一次导出需要的全部资产与数据解析出来。"""
    ids = mr.parse_asset_table()
    chapters = mr.parse_chapters()

    target = mr.ALIASES.get(map_id.lower(), map_id)
    hit = None
    for name, o1, o2, pal, tc, ml in chapters:
        if ids.get(ml, "").endswith(target):
            hit = (name, o1, o2, pal, tc, ml)
            break
    if hit is None:
        raise SystemExit(f"错误：找不到使用地图 {target} 的章节。用 map_render.py --list 查看。")

    chapter, o1, o2, pal_id, tc_id, ml_id = hit
    missing = [k for k in (o1, pal_id, tc_id, ml_id) if k not in ids]
    if missing:
        raise SystemExit(f"错误：章节 {chapter} 引用的资产下标 {missing} 无法反查符号名"
                         f"（MapChanges / Events 那类通常查不到）")
    mar = mr.resolve_map(ids[ml_id])
    ts, tpr = mr.resolve_tileset(ids[o1])
    palf = mr.resolve_palette(ids[pal_id])
    tcf = mr.resolve_tileconfig(ids[tc_id])
    if not all([mar, ts, palf, tcf]):
        raise SystemExit(f"错误：资产缺失\n  map={mar}\n  tileset={ts}\n"
                         f"  palette={palf}\n  tsa={tcf}")

    w, h, grid = mr.parse_mar(mar)
    tsa = mr.parse_tileconfig(tcf)
    sheet, auto_tpr = mr.load_sheet(ts)
    cols = mr.load_palette(palf)
    terrain, terrain_names = mr.parse_terrain_lookup(tcf)

    return dict(chapter=chapter, map_id=target, mar=mar, w=w, h=h, grid=grid,
                tsa=tsa, sheet=sheet, tiles_per_row=tpr or auto_tpr, cols=cols,
                terrain=terrain, terrain_names=terrain_names,
                chapter_name=chapter, tileset_path=ts, palette_path=palf, tsa_path=tcf)


# --------------------------------------------------------------- 图集

def build_atlas(d):
    """给地图用到的每个 metatile 索引渲染一个 16×16 槽位。

    返回 (atlas 图像, [metatile 索引 × 槽位数], {metatile 索引: 槽位})
    """
    used = sorted(set(d["grid"]))
    cols = min(ATLAS_COLUMNS, max(1, len(used)))
    rows = math.ceil(len(used) / cols)
    atlas = Image.new("RGB", (cols * TILE, rows * TILE), (0, 0, 0))

    for slot, mv in enumerate(used):
        # 复用 map_render.render 渲染 1×1 的地图 = 单个 metatile
        cell = mr.render(1, 1, [mv], d["tsa"], d["sheet"], d["tiles_per_row"], d["cols"])
        atlas.paste(cell, ((slot % cols) * TILE, (slot // cols) * TILE))

    return atlas, used, {mv: i for i, mv in enumerate(used)}


# --------------------------------------------------------------- TMX 写出

def write_tmx(d, out_dir, name=None):
    os.makedirs(out_dir, exist_ok=True)
    name = name or d["map_id"]
    atlas_name = f"{name}.metatiles.png"
    tmx_path = os.path.join(out_dir, f"{name}.tmx")

    atlas, used, slot_of = build_atlas(d)
    atlas.save(os.path.join(out_dir, atlas_name))
    cols = min(ATLAS_COLUMNS, max(1, len(used)))

    root = ET.Element("map", {
        "version": "1.10", "tiledversion": "1.10.2",
        "orientation": "orthogonal", "renderorder": "right-down",
        "width": str(d["w"]), "height": str(d["h"]),
        "tilewidth": str(TILE), "tileheight": str(TILE),
        "infinite": "0", "nextlayerid": "2", "nextobjectid": "1",
    })

    ts = ET.SubElement(root, "tileset", {
        "firstgid": "1", "name": f"{name}_metatiles",
        "tilewidth": str(TILE), "tileheight": str(TILE),
        "tilecount": str(len(used)), "columns": str(cols),
    })
    ET.SubElement(ts, "image", {
        "source": atlas_name,
        "width": str(atlas.size[0]), "height": str(atlas.size[1]),
    })

    # 每个槽位的属性：原始 metatile 索引 + 地形类型（自包含，往返验证靠它）
    for slot, mv in enumerate(used):
        t = ET.SubElement(ts, "tile", {"id": str(slot)})
        props = ET.SubElement(t, "properties")
        ET.SubElement(props, "property", {
            "name": "metatile", "type": "int", "value": str(mv)})
        tid = d["terrain"][mv]
        ET.SubElement(props, "property", {
            "name": "terrain", "value": d["terrain_names"][tid]})
        ET.SubElement(props, "property", {
            "name": "terrain_id", "type": "int", "value": str(tid)})

    layer = ET.SubElement(root, "layer", {
        "id": "1", "name": "terrain", "width": str(d["w"]), "height": str(d["h"]),
    })
    data = ET.SubElement(layer, "data", {"encoding": "csv"})
    rows = []
    for y in range(d["h"]):
        row = [str(slot_of[d["grid"][y * d["w"] + x]] + 1) for x in range(d["w"])]
        rows.append(",".join(row))
    data.text = "\n" + ",\n".join(rows) + "\n"

    ET.indent(root, space=" ")
    ET.ElementTree(root).write(tmx_path, encoding="UTF-8", xml_declaration=True)

    print(f"  ✓ {tmx_path}")
    print(f"      图集 {atlas_name}  {atlas.size[0]}x{atlas.size[1]}  "
          f"{len(used)} 个 metatile 槽位")
    print(f"      图层 terrain  {d['w']}x{d['h']} 格")
    return tmx_path


# --------------------------------------------------------------- 纯数据 JSON

def write_json(d, out_dir, name=None):
    """导出**纯数据** JSON，供 `lib/core` 消费。

    为什么要跟 `.tmx` 分开：

      `.tmx` 是**视觉格式**，它把瓦片、图集、图层编码方式绑在一起。
      `lib/core` 是**规则层**，它只关心"哪一格是什么地形"。
      让规则层去解析 Tiled 的 XML 是架构错误——换掉渲染方案时规则层不该跟着动。

    所以：`.tmx` 喂 `lib/game`（Flame 渲染），`.json` 喂 `lib/core`（规则计算）。
    两者都由本管线从同一份 GBA 数据导出，因此不可能不一致。
    """
    name = name or d["map_id"]
    os.makedirs(out_dir, exist_ok=True)
    path = os.path.join(out_dir, f"{name}.json")

    # 地形名做去重字典，避免每格重复存字符串
    used = sorted({d["terrain"][mv] for mv in d["grid"]})
    names = [d["terrain_names"][t] for t in used]
    index_of = {t: i for i, t in enumerate(used)}

    payload = {
        "id": d["map_id"],
        "chapter": d["chapter"],
        "width": d["w"],
        "height": d["h"],
        "tileSize": TILE,
        "grid": d["grid"],
        "terrainIndex": [index_of[d["terrain"][mv]] for mv in d["grid"]],
        "terrainLegend": names,
    }
    with open(path, "w", encoding="utf-8") as f:
        json.dump(payload, f, ensure_ascii=False, separators=(",", ":"))
    print(f"  ✓ {path}  ({d['w']}x{d['h']}, {len(names)} 种地形)")
    return path


# --------------------------------------------------------------- 往返验证

def read_tmx(tmx_path):
    """解析 `.tmx` → (w, h, metatile 网格, terrain 名网格)"""
    root = ET.parse(tmx_path).getroot()
    w, h = int(root.get("width")), int(root.get("height"))

    fallback = os.path.dirname(os.path.abspath(tmx_path))
    slot_meta, slot_terr = {}, {}
    for ts in root.findall("tileset"):
        for t in ts.findall("tile"):
            tid = int(t.get("id"))
            for p in t.findall("./properties/property"):
                if p.get("name") == "metatile":
                    slot_meta[tid] = int(p.get("value"))
                elif p.get("name") == "terrain":
                    slot_terr[tid] = p.get("value")

    layer = root.find("layer")
    gids = []
    for v in layer.find("data").text.replace("\n", "").split(","):
        v = v.strip()
        if v:
            gids.append(int(v))
    if len(gids) != w * h:
        raise ValueError(f"{tmx_path}: 图层 {len(gids)} 格 != {w}x{h}")

    grid = [slot_meta[g - 1] for g in gids]
    terr = [slot_terr[g - 1] for g in gids]
    return w, h, grid, terr


def verify(tmx_path):
    """把 `.tmx` 还原为 metatile 网格 + 地形网格，与 `.mar` + 查表逐格比对。"""
    name = os.path.splitext(os.path.basename(tmx_path))[0]
    d = resolve_all(name)
    w, h, grid, terr = read_tmx(tmx_path)

    problems = []
    if (w, h) != (d["w"], d["h"]):
        problems.append(f"尺寸 {w}x{h} != {d['w']}x{d['h']}")

    bad_meta = bad_terr = 0
    for i in range(min(len(grid), len(d["grid"]))):
        if grid[i] != d["grid"][i]:
            bad_meta += 1
        if terr[i] != d["terrain_names"][d["terrain"][d["grid"][i]]]:
            bad_terr += 1

    if bad_meta:
        problems.append(f"{bad_meta} 格 metatile 不一致")
    if bad_terr:
        problems.append(f"{bad_terr} 格地形类型不一致")

    total = d["w"] * d["h"]
    if problems:
        print(f"  ✗ {name}: " + "；".join(problems))
        return 1
    print(f"  ✓ {name}: {total} 格 metatile 与地形类型全部一致")
    return 0


# --------------------------------------------------------------- 命令

def export_one(map_id, out_dir):
    d = resolve_all(map_id)
    print(f"导出 {d['map_id']}  (章节 {d['chapter']})")
    tmx = write_tmx(d, out_dir)
    write_json(d, out_dir)
    return verify(tmx)


def main():
    ap = argparse.ArgumentParser(description="FE8 地图 → Tiled .tmx")
    ap.add_argument("map", nargs="?", default=None)
    ap.add_argument("--out", default=DEFAULT_OUT)
    ap.add_argument("--verify", metavar="TMX", default=None)
    ap.add_argument("--verify-all", action="store_true")
    ap.add_argument("--maps", nargs="*", default=None,
                    help="--verify-all 时只处理这些地图")
    a = ap.parse_args()

    if not os.path.isdir(mr.DECOMP):
        raise SystemExit(f"错误：找不到 {mr.DECOMP}")

    if a.verify:
        return verify(a.verify)

    if a.verify_all:
        names = a.maps or sorted(
            f[:-4] for f in os.listdir(os.path.join(mr.MAPS, "layout"))
            if f.endswith(".mar"))
        ok = bad = 0
        skipped = 0
        for n in names:
            try:
                if export_one(n, a.out) == 0:
                    ok += 1
                else:
                    bad += 1
            except SystemExit as e:
                # ⚠️ 这里是**合法的跳过**：地图没被任何章节使用、
                # 或资产下标反查不到符号名（`MapChanges`/`Events` 那类查不到）。
                #
                # 真正的问题是**空集门禁**（见下面的 `ok == 0`）：
                # 原来 `--verify-all --maps DefinitelyNotAMap` 会报
                # "0 张通过，0 张失败" 并**退出 0**（审计实测）。
                #
                # 我第一版把这里也改成 `bad += 1`，结果误伤了两张本来
                # 就该跳过的地图（AnotherShrineMap / Ch10EphraimMap）。
                # **判据要精确：跳过是跳过，空集才是失败。**
                print(f"  – {n}: {e}")
                skipped += 1
            except Exception as e:
                import traceback
                tb = traceback.extract_tb(e.__traceback__)[-1]
                print(f"  ✗ {n}: {type(e).__name__}: {e}"
                      f"   [{os.path.basename(tb.filename)}:{tb.lineno}]")
                bad += 1
        print(f"\n导出并验证：{ok} 张通过，{bad} 张失败"
              f"{f'，{skipped} 张跳过' if skipped else ''}")
        # ⚠️ "验证了 0 个"不能算通过（空集门禁）
        if ok == 0:
            print("❌ 一张都没有验证 —— 空集不算通过")
            return 1
        return 1 if bad else 0

    if not a.map:
        raise SystemExit("错误：请给一个地图名，或用 --verify-all")
    return export_one(a.map, a.out)


if __name__ == "__main__":
    sys.exit(main())
