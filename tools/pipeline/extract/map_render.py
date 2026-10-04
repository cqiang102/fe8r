#!/usr/bin/env python3
"""
map_render.py —— 把 FE8 的章节地图从 GBA 数据合成为 PNG（并可选导出 Tiled .tmx）。

这是 §4.9「语义形式原则」的第一步与验证器：
    GBA 形式（.mar + TileConfiguration.S + 索引 PNG + JASC .pal）
        ──解析──▶ 语义形式（地形网格 / 视觉瓦片网格 / 预合成纹理）

## GBA 地图的四层结构（全部从源码实测确认）

1. **地图网格**  `graphics/map/layout/<Name>.mar`
   每格 2 字节小端 u16。`metatileIndex = u16_le >> 5`
   （低 5 位是标志位，实测全部 66 张地图 26541 个值低 5 位均为 0；
     最大索引 1022 < 1024。`>> 3` 得到的是 TSA 条目偏移 = 索引 × 4）

2. **metatile 定义**  `graphics/map/TileConfiguration<N>.S`
   1024 个 metatile × 4 个 TSA 条目（TL/TR/BL/BR），共 4096 条 u16。
   TSA 条目：bit 0-9 = 图集瓦片索引；bit 10 = 水平翻转；bit 11 = 垂直翻转；
             bit 12-15 = 调色板 bank 偏移

3. **图集**  `graphics/map/ObjectType*.png` 或 `graphics/frontier_map_objtype/*.png`
   `mode=L`，像素值 = `nibble * 0x11`（4bpp 值复制到 8bit）。
   取索引用 `pixel & 15` 或 `pixel >> 4`（两者等价）。
   瓦片 N 位于 `((N % tilesPerRow) * 8, (N // tilesPerRow) * 8)`。

4. **调色板**  `graphics/map/MapPalette*.pal`（JASC 文本，160 色 = 10 banks × 16）

## 调色板 bank 的选取（最容易搞错的一步）

来自 `src/bmmap_DisplayBmTile.c`：

    u16 base = gBmMapFog[y][x] ? (6 << 12) : (11 << 12);   // 6=正常, 11=迷雾
    out[k] = base + tsaEntry;                              // 直接相加

而 `UnpackChapterMapGraphics`（`src/bmmap_080195E4.c`）用
`ApplyPalettes(pal, 6, 10)` 把调色板装到 bank 6..15。

且 `RefreshEntityBmMaps` 里 `BmMapFill(gBmMapFog, !chapterVisionRange ? 1 : 0)`
—— **没有迷雾的章节 `gBmMapFog` 全填 1**，所以走 `6 << 12` 分支。

于是：**无迷雾章节 → 调色板文件 bank = tsaEntry >> 12**（0..4）
      有迷雾章节 → 被遮蔽的格子用 bank 5 + (tsaEntry >> 12)

## 已知约束（务必注意）

* **绝不能改的**：地形类型网格、地图尺寸与格子坐标、天气对移动力的影响、
  雾战可见性判定、地图变更触发条件。它们都是游戏规则。
* **可以换的**：视觉瓦片、渲染方式、存储格式、编辑器。
* `graphics/frontier_map_objtype/*.png` 的真瓦片宽度在反编译项目里**尚未 pin**
  （见 `docs/bin_verification_wave8.md`）。实测 32 宽（行优先）连贯度最优，
  且与美版反编译的同名素材**字节完全相同**，故采用之。

## 用法

    python3 map_render.py --list
    python3 map_render.py prologue                  # 渲染序章
    python3 map_render.py prologue --scale 3 --out p.png
    python3 map_render.py --roundtrip               # 全部地图的 .mar 往返自检
"""
import argparse
import json
import os
import re
import sys

from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.abspath(os.path.join(HERE, "..", "..", ".."))
DECOMP = os.path.join(REPO, "third_party", "fireemblem8j")
MAPS = os.path.join(DECOMP, "graphics", "map")


# --------------------------------------------------------------- GBA 格式解析

def parse_mar(path):
    """`.mar` → (width, height, [metatileIndex, ...])  行优先"""
    with open(path, "rb") as f:
        data = f.read()
    meta = json.load(open(path[:-4] + ".json", encoding="utf-8"))
    w, h = meta["width"], meta["height"]
    if len(data) != w * h * 2:
        raise ValueError(f"{path}: 大小 {len(data)} != {w}x{h}x2")
    grid = [int.from_bytes([data[i + 1], data[i]], "big") >> 5
            for i in range(0, len(data), 2)]
    return w, h, grid


def build_mar(w, h, grid):
    """[metatileIndex] → `.mar` 字节（往返验证用）"""
    out = bytearray()
    for mv in grid:
        out += ((mv << 5)).to_bytes(2, "little")
    return bytes(out)


def parse_tileconfig(path):
    """`TileConfiguration*.S` → 4096 个 TSA 条目（1024 metatile × 4）"""
    src = open(path, encoding="utf-8").read()
    tsa = []
    for m in re.findall(r"^\s*metatile\s+([^@\n]+)", src, re.M):
        for p in m.split(","):
            p = p.strip()
            if p:
                tsa.append(int(p, 0))
    if len(tsa) != 4096:
        raise ValueError(f"{path}: metatile 条目数 {len(tsa)} != 4096")
    return tsa


def load_sheet(path):
    """4bpp 索引图集 → (PIL 图像, 每行瓦片数)"""
    im = Image.open(path)
    if im.mode != "L":
        raise ValueError(f"{path}: 期望 mode=L（4bpp 索引），实际 {im.mode}")
    return im, im.size[0] // 8


def load_palette(path, bank_reversed=True):
    """JASC-PAL → [(r,g,b), ...]

    ⚠️ **每个 16 色 bank 的顺序要反转**（`bank_reversed=True`，默认）。

    这是本项目踩过的最大的坑，实测推导过程：

      1. 图集 PNG 是 4bit 灰度（bitdepth=4, colortype=0）。手动解码 PNG 的 IDAT
         证实：像素值 nibble `v` 就是调色板索引，PIL 的 `>>4` / `&15` 读取正确。
      2. 构建链（Makefile）是 `png --gbagfx--> .4bpp --lz--> ROM`，且字节精确。
         所以 **ROM 里的 nibble 就是 PNG 的 nibble `v`**。
      3. 用火焰纹章 Wiki 的官方章节地图做逐像素比对，发现官方图上某个像素的颜色，
         恰好是 `.pal` 文件里 **`15 - v`** 位置的颜色（4bit 取反）。
      4. 反查证实：ROM 调色板条目 `i` == `.pal` 文件条目 `15 - i`，
         **但 bank 号不变**。即 `.pal` 文件每个 16 色 bank 内部顺序是反的。

    不修正的后果不是"颜色有点偏"，而是**明暗完全反相**——地图看上去仍像一张地图
    （所以肉眼容易漏过），但地形类型全错。修复后与官方图逐像素平均色差从
    270 / 186 / 239 / 174 降到 17 / 25 / 23 / 24（残差基本只来自官方图上画的角色）。
    验证样本：序章 / Ch1 / Ch2 / Ch3 四张，见 README。
    """
    lines = [l for l in open(path, encoding="utf-8").read().split("\n") if l.strip()]
    if lines[0].strip() != "JASC-PAL":
        raise ValueError(f"{path}: 不是 JASC-PAL")
    n = int(lines[2])
    cols = [tuple(int(v) for v in l.split()) for l in lines[3:3 + n]]
    if not bank_reversed:
        return cols
    out = []
    for b in range(0, len(cols), 16):
        bank = cols[b:b + 16]
        out.extend(reversed(bank))
    return out


# --------------------------------------------------------------- 资产解析

def parse_terrain_lookup(path):
    """`TileConfiguration*.S` 末尾的地形查表 → ([terrainId × 1024], {id: name})

    `tile_config.inc` 说明地图配置解压后是 `sTilesetConfig[0x1000 + 0x200]`：
    前 `0x1000` 个 u16 是瓦片图形配置，后 `0x200` 个 u16（= 1024 字节）是地形查表。

    在 `.S` 源文件里后一段表现为 256 行 `.byte TERRAIN_*, ...`（4 条/行 = 1024 条），
    正好对应 1024 个 metatile。这个查表就是**规则层**——地形类型决定移动消耗、
    回避、防御加成，绝不能改（见 README 的红线）。
    """
    inc = os.path.join(MAPS, "terrains.inc")
    names = {m.group(1): int(m.group(2), 16)
             for m in re.finditer(r"\.equ\s+(TERRAIN_\w+),\s*(0x[0-9A-Fa-f]+)",
                                  open(inc, encoding="utf-8").read())}
    src = open(path, encoding="utf-8").read()
    vals = []
    for line in src.split("\n"):
        s = line.strip()
        if s.startswith(".byte"):
            for p in s[len(".byte"):].split(","):
                p = p.strip()
                if not p:
                    continue
                if p in names:
                    vals.append(names[p])
                else:
                    # 少数条目是裸数值（如 TileConfiguration10.S:1066 的 0x54），
                    # 它们超出了 include/constants/terrains.h 的命名范围。
                    vals.append(int(p, 0))
    if len(vals) != 1024:
        raise ValueError(f"{path}: 地形查表 {len(vals)} 条 != 1024")
    id2name = {v: k for k, v in names.items()}
    for v in set(vals):
        id2name.setdefault(v, f"TERRAIN_UNKNOWN_0x{v:02X}")
    return vals, id2name


def _load_symbol_tables():
    """汇总三处符号表，构建 `地址 -> 符号名`。

    为什么要三处：单独任何一处都不全。
      * `sym_jp.txt`          —— 7554 个（函数 + 部分数据）
      * `layout/baseline_syms.tsv` —— 补一批 data 符号
      * `reference/maps/febuilder_rom_us_jp.tsv` —— FEBuilder 的对照表，补图集等
    """
    a2s = {}
    for line in open(os.path.join(DECOMP, "sym_jp.txt"), encoding="utf-8",
                     errors="replace"):
        m = re.match(r"(\w+)\s*=\s*(0x[0-9A-Fa-f]+);", line.strip())
        if m:
            a2s.setdefault(int(m.group(2), 16), m.group(1))
    bs = os.path.join(DECOMP, "layout/baseline_syms.tsv")
    if os.path.exists(bs):
        for line in open(bs, encoding="utf-8", errors="replace"):
            if line.startswith("#"):
                continue
            p = line.rstrip("\n").split("\t")
            if len(p) >= 3 and p[2] == "data":
                try:
                    a2s.setdefault(int(p[1], 16), p[0])
                except ValueError:
                    pass
    # 段首符号兜底：某些资产（如 TowerOfValniObjectType）没有被任何符号表收录，
    # 但它们恰好位于某个数据段的**起始地址**。用 carved_rom.tsv 的段起点 + 该段
    # .c 文件里第一个 INCBIN 的符号名补上。
    carved = os.path.join(DECOMP, "layout/carved_rom.tsv")
    if os.path.exists(carved):
        seg_first = {}
        for line in open(carved, encoding="utf-8", errors="replace"):
            if line.startswith("#"):
                continue
            f = line.rstrip("\n").split("\t")
            if len(f) < 3 or ".o(" not in f[2]:
                continue
            src = f[2].split(".o(")[0]
            cfile = os.path.join(DECOMP, src + ".c")
            if not os.path.exists(cfile):
                continue
            m = re.search(r"u8 (\w+)\[\] = INCBIN_U8", open(cfile, encoding="utf-8",
                                                            errors="replace").read())
            if m:
                try:
                    seg_first[int(f[0], 16)] = m.group(1)
                except ValueError:
                    pass
        for off, sym in seg_first.items():
            a2s.setdefault(off + 0x08000000, sym)

    fb = os.path.join(DECOMP, "reference/maps/febuilder_rom_us_jp.tsv")
    if os.path.exists(fb):
        for line in open(fb, encoding="utf-8", errors="replace"):
            if line.startswith("#"):
                continue
            p = line.rstrip("\n").split("\t")
            if len(p) >= 5:
                try:
                    a2s.setdefault(int(p[1], 16), p[4])
                except ValueError:
                    pass
    return a2s


def parse_asset_table():
    """`gChapterDataAssetTable` 下标 → **真实符号名**

    ⚠️ **不要用源文件里的 `/* US ... */` 注释。** 它们是美版的名字，而 JP 表比美版
    少了 `MapPalette4` 和 `MapPalette16`（JP 的 `graphics/map/` 里确实没有这两个
    文件），从下标 **47 开始整段漂移**，到后期能差好几个位置。

    正确做法：`gChDAsset_N` → JP 地址 → 反查真实符号名。地址来自
    `layout/baseline_syms.d/dataMore_chapter_asset_table.tsv`。

    实测覆盖率足够：需要的图集/调色板/TSA/地图符号全部能查到
    （查不到的恰好是 MapChanges / Events 那类我们不需要的）。
    """
    a2s = _load_symbol_tables()
    addr = {}
    tsv = os.path.join(DECOMP, "layout/baseline_syms.d/dataMore_chapter_asset_table.tsv")
    for line in open(tsv, encoding="utf-8", errors="replace"):
        p = line.rstrip("\n").split("\t")
        if len(p) >= 2 and p[0].startswith("gChDAsset_"):
            try:
                addr[int(p[0].split("_")[1])] = int(p[1], 16)
            except ValueError:
                pass
    return {i: a2s[a] for i, a in addr.items() if a in a2s}


def parse_chapters():
    """章节 → (名字, obj1Id, obj2Id, paletteId, tileConfigId, mainLayerId)

    ⚠️ 79 个章节条目里有 **19 个 `internalName` 是空字符串**——它们是塔 / 遗迹 /
    城内地牢等**不属于普通章节流程**的地图。早期版本的正则要求名字非空，
    会静默漏掉这 19 条，导致 `--verify-all` 只覆盖 11 张地图。
    空名字的条目用 `CH<序号>` 生成占位名。
    """
    src = open(os.path.join(DECOMP, "src/data/chapter_settings.h"),
               encoding="utf-8", errors="replace").read()
    out = []
    for idx, b in enumerate(re.split(r"\n    \{\n", src)):
        mn = re.search(r'\.internalName = "([^"]*)"', b)
        mo = re.search(
            r"\.obj1Id = (\d+),\s*\.obj2Id = (\d+),\s*\.paletteId = (\d+),"
            r"\s*\.tileConfigId = (\d+),\s*\.mainLayerId = (\d+)", b)
        if mn and mo:
            name = mn.group(1) or f"CH{idx:02d}"
            out.append((name,) + tuple(int(x) for x in mo.groups()))
    return out


# 资产名 → 仓库里的实际文件（实测确定；JP 与 US 命名不完全对应）
def resolve_tileset(asset_name):
    """返回 (路径, 每行瓦片数)

    `asset_name` 现在是**真实的 JP 符号名**（由地址反查得到），例如
    `ObjectType1` / `ObjectType4` / `TowerOfValniObjectType`。
    """
    if asset_name is None:
        return None, None
    if asset_name == "TowerOfValniObjectType":
        p = os.path.join(MAPS, f"{asset_name}.png")
        return (p, None) if os.path.exists(p) else (None, None)
    if re.fullmatch(r"ObjectType\d+", asset_name):
        p = os.path.join(MAPS, f"{asset_name}.png")
        if os.path.exists(p):
            return p, None
        # ObjectType1/2/3 在 JP 里以 frontier 形式存在（未 pin 真瓦片宽度）
        fdir = os.path.join(DECOMP, "graphics", "frontier_map_objtype")
        if os.path.isdir(fdir):
            a2s = _load_symbol_tables()
            for fn in sorted(os.listdir(fdir)):
                mm = re.search(r"_([0-9A-F]{6})\.png$", fn)
                # 文件名里是 6 位 ROM 文件偏移，符号表的键是完整地址
                if mm and a2s.get(int(mm.group(1), 16) + 0x08000000) == asset_name:
                    return os.path.join(fdir, fn), 32
    return None, None


def resolve_palette(asset_name):
    if not asset_name.startswith("MapPalette") and asset_name != "TowerOfValniMapPalette":
        return None
    p = os.path.join(MAPS, f"{asset_name}.pal")
    return p if os.path.exists(p) else None


def resolve_tileconfig(asset_name):
    if "TileConfiguration" not in asset_name:
        return None
    p = os.path.join(MAPS, f"{asset_name}.S")
    return p if os.path.exists(p) else None


def resolve_map(asset_name):
    """'US PrologueMap' → graphics/map/layout/PrologueMap.mar"""
    p = os.path.join(MAPS, "layout", asset_name + ".mar")
    return p if os.path.exists(p) else None


# --------------------------------------------------------------- 渲染

def render(w, h, grid, tsa, sheet, tiles_per_row, cols, fog=False):
    """合成地图为 RGB 图像。fog=False 走 6<<12 分支（无迷雾章节）。"""
    sx = sheet.load()
    # 无迷雾: 文件 bank = tsa>>12;  有迷雾(被遮蔽): 文件 bank = 5 + (tsa>>12)
    base_bank = 5 if fog else 0
    im = Image.new("RGB", (w * 16, h * 16))
    op = im.load()
    nbank = len(cols) // 16
    for my in range(h):
        for mx in range(w):
            b = grid[my * w + mx] * 4
            for k, (dx, dy) in enumerate(((0, 0), (8, 0), (0, 8), (8, 8))):
                e = tsa[b + k]
                ti = e & 0x3FF
                hf = (e >> 10) & 1
                vf = (e >> 11) & 1
                bank = min(base_bank + (e >> 12), nbank - 1)
                tx, ty = (ti % tiles_per_row) * 8, (ti // tiles_per_row) * 8
                for py in range(8):
                    yy = ty + (7 - py if vf else py)
                    for px in range(8):
                        xx = tx + (7 - px if hf else px)
                        idx = (sx[xx, yy] >> 4) & 15
                        op[mx * 16 + dx + px, my * 16 + dy + py] = cols[bank * 16 + idx]
    return im


# --------------------------------------------------------------- 命令

ALIASES = {
    "prologue": "PrologueMap", "ch1": "Ch1Map", "ch2": "Ch2Map",
    "ch3": "Ch3Map", "ch4": "Ch4Map", "ch5": "Ch5Map",
}


def cmd_list():
    print("仓库里的地图布局：")
    lay = os.path.join(MAPS, "layout")
    for f in sorted(os.listdir(lay)):
        if f.endswith(".json"):
            d = json.load(open(os.path.join(lay, f), encoding="utf-8"))
            print(f"  {d['id']:28s} {d['width']:3d}x{d['height']:<3d}")
    print("\n章节 → 资产：")
    ids = parse_asset_table()
    for name, o1, o2, pal, tc, ml in parse_chapters():
        print(f"  {name:5s} tileset={ids.get(o1,'?'):20s} pal={ids.get(pal,'?'):18s} "
              f"tsa={ids.get(tc,'?'):22s} map={ids.get(ml,'?')}")


def cmd_roundtrip():
    """.mar → 网格 → .mar 的字节级往返自检"""
    lay = os.path.join(MAPS, "layout")
    ok = bad = 0
    total = 0
    for f in sorted(os.listdir(lay)):
        if not f.endswith(".mar"):
            continue
        p = os.path.join(lay, f)
        w, h, grid = parse_mar(p)
        total += len(grid)
        if build_mar(w, h, grid) == open(p, "rb").read():
            ok += 1
        else:
            bad += 1
            print(f"  ✗ {f}")
    print(f"往返自检：{ok} 张无损，{bad} 张失败（共 {total} 个瓦片值）")
    return 1 if bad else 0


def cmd_render(map_id, scale, out_path, fog, bank_reversed=True):
    ids = parse_asset_table()
    target = ALIASES.get(map_id.lower(), map_id)

    # 找该地图属于哪一章，从而拿到图集/调色板/TSA
    hit = None
    for name, o1, o2, pal, tc, ml in parse_chapters():
        if ids.get(ml, "").endswith(target):
            hit = (name, o1, o2, pal, tc, ml)
            break
    if hit is None:
        print(f"错误：找不到使用地图 {target} 的章节。用 --list 查看。", file=sys.stderr)
        return 1

    name, o1, o2, pal_id, tc_id, ml_id = hit
    mar = resolve_map(ids[ml_id])
    ts, tpr = resolve_tileset(ids[o1])
    palf = resolve_palette(ids[pal_id])
    tcf = resolve_tileconfig(ids[tc_id])
    if not all([mar, ts, palf, tcf]):
        print(f"错误：资产缺失  mar={mar}\n  tileset={ts}\n  palette={palf}\n  tsa={tcf}",
              file=sys.stderr)
        return 1

    print(f"章节 {name}  地图 {target}")
    print(f"  图集     {os.path.relpath(ts, DECOMP)}  每行 {tpr if tpr else 'auto'} 瓦片")
    print(f"  调色板   {os.path.relpath(palf, DECOMP)}")
    print(f"  TSA      {os.path.relpath(tcf, DECOMP)}")
    print(f"  地图     {os.path.relpath(mar, DECOMP)}")

    w, h, grid = parse_mar(mar)
    tsa = parse_tileconfig(tcf)
    sheet, auto_tpr = load_sheet(ts)
    cols = load_palette(palf, bank_reversed=bank_reversed)
    im = render(w, h, grid, tsa, sheet, tpr or auto_tpr, cols, fog=fog)
    if scale != 1:
        im = im.resize((im.size[0] * scale, im.size[1] * scale), Image.NEAREST)
    im.save(out_path)
    print(f"  → {out_path}  ({im.size[0]}x{im.size[1]})")
    return 0


def main():
    ap = argparse.ArgumentParser(description="FE8 地图渲染 / 往返验证")
    ap.add_argument("map", nargs="?", default="prologue",
                    help="地图 id 或别名（prologue/ch1/ch2/ch3/ch4/ch5）")
    ap.add_argument("--list", action="store_true", help="列出地图与章节资产")
    ap.add_argument("--roundtrip", action="store_true", help=".mar 往返字节级自检")
    ap.add_argument("--scale", type=int, default=2)
    ap.add_argument("--fog", action="store_true", help="按迷雾分支渲染（bank 5+）")
    ap.add_argument("--no-palette-reverse", action="store_true",
                    help="不做调色板 bank 反转（用于对比调试，正常不要用）")
    ap.add_argument("--out", default=None)
    a = ap.parse_args()

    if not os.path.isdir(DECOMP):
        print(f"错误：找不到 {DECOMP}\n请先 clone fireemblem8j 到 third_party/",
              file=sys.stderr)
        return 1
    if a.list:
        cmd_list()
        return 0
    if a.roundtrip:
        return cmd_roundtrip()
    out = a.out or os.path.join(HERE, "..", "out", f"{a.map}.png")
    return cmd_render(a.map, a.scale, out, a.fog,
                      bank_reversed=not a.no_palette_reverse)


if __name__ == "__main__":
    sys.exit(main())
