#!/usr/bin/env python3
"""
FE 图形素材（`Img_*.png` / `gGfx_*.png`）的合成。

# ★★★ 核心规则：`L` 模式 PNG 是 **4bpp 数据按 ×17 展开成 8bpp** 的

这些 PNG 是 `L`（灰度）模式、8 位一像素。但它们的**唯一取值全是 17 的倍数**：

    0x00, 0x11, 0x22, 0x33, 0x44, 0x55, 0x66, 0x77,
    0x88, 0x99, 0xAA, 0xBB, 0xCC, 0xDD, 0xEE, 0xFF

因为 `gbagfx` 把 4bpp 的 nibble `n` 展开成一个字节时写的是 `n * 17`
（两个 nibble 相同 = 灰度等价）。

**所以：像素的 4bpp 索引 = 字节 / 17。**

## 我在这一点上错了很久

标题（`gGfx_TitleMainBackground_1` 等）和菜单（`Img_DifficultyMenuObjs`）
两处我都合不出来，根因是同一个：**把字节当成了索引**（值域 0..255，
而 4bpp 只该有 0..15），于是大部分查表越界或落到错误的颜色。

实测三张素材，**非 17 倍数的取值一个都没有**：

    Img_DifficultyMenuObjs.png         15 种值   非17倍数 0
    gGfx_TitleMainBackground_1.png     14 种值   非17倍数 0
    gGfx_TitleDragonForeground.png     14 种值   非17倍数 0

## 还差什么

图块的**排布**还没对上（TSA 项 -> 屏幕格子）。已经确认无误的部分：

* TSA 自洽：`Tsa_DifficultyMenuObjs.tsa.bin` 头 `0x0B0C` = 13x12 = 156 项，
  文件 314 字节 = 2 + 156*2 ✓
* 调色板：`graphics/gmapunit/Pal_DifficultyMenuObjs.pal`，
  `ApplyPalettes(Pal_DifficultyMenuObjs, 17, 10)` -> 装到 bank 17、共 10 bank
* `Img_DifficultyMenuObjs` 在 ROM 里是 LZ77（0xAEB 字节），PNG 是解压后的样子

**判据是"看得出是新手/普通/困难三个词"，不是"有结构"。**
"""
import argparse
import os
import struct
import sys

try:
    from PIL import Image
except ImportError:
    print("需要 Pillow", file=sys.stderr)
    sys.exit(1)

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.abspath(os.path.join(HERE, "..", "..", ".."))
DECOMP = os.path.join(REPO, "third_party", "fireemblem8j")
GFX = os.path.join(DECOMP, "graphics")

# 展开系数：gbagfx 把 nibble n 写成 n * 17
NIBBLE_EXPAND = 17


def bgr555(v):
    r = (v & 0x1F) << 3
    g = ((v >> 5) & 0x1F) << 3
    b = ((v >> 10) & 0x1F) << 3
    return (r | (r >> 5), g | (g >> 5), b | (b >> 5))


def load_palette(path):
    d = open(path, "rb").read()
    return [bgr555(struct.unpack("<H", d[i:i + 2])[0])
            for i in range(0, len(d) - 1, 2)]


def load_pixels(path):
    """读 `L` 模式 PNG，返回**4bpp 索引**的二维表。

    ★ 关键：每个字节除以 17。见模块开头的说明。
    """
    im = Image.open(path).convert("L")
    px = im.load()
    w, h = im.size
    return [[px[x, y] // NIBBLE_EXPAND for x in range(w)] for y in range(h)]


def check_expand(path):
    """检查是否所有取值都是 17 的倍数 —— **这是判据，不是猜测**。"""
    pix = load_pixels_raw = None
    im = Image.open(path).convert("L")
    px = im.load()
    w, h = im.size
    bad = 0
    seen = set()
    for y in range(h):
        for x in range(w):
            v = px[x, y]
            seen.add(v)
            if v % NIBBLE_EXPAND != 0:
                bad += 1
    return len(seen), bad


def load_tiles(path, tile_w=8, tile_h=8):
    """把像素表切成图块（行优先，每行 `w//8` 个）。"""
    pix = load_pixels(path)
    h = len(pix)
    w = len(pix[0]) if h else 0
    tw = w // tile_w
    tiles = []
    for ty in range(h // tile_h):
        for tx in range(tw):
            tiles.append([[pix[ty * tile_h + y][tx * tile_w + x]
                           for x in range(tile_w)] for y in range(tile_h)])
    return tiles, tw, h // tile_h


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", default=os.path.join(HERE, "..", "out", "fe_gfx"))
    a = ap.parse_args()
    os.makedirs(a.out, exist_ok=True)

    checks = [
        "frontier_df4_menu/Img_DifficultyMenuObjs.png",
        "frontier_df4_menu/Img_GameMainMenuObjs.png",
        "misc_gfx/gGfx_TitleMainBackground_1.png",
        "misc_gfx/gGfx_TitleDragonForeground.png",
    ]
    print("  [×17 判据] 非 17 倍数应为 0：")
    ok = True
    for rel in checks:
        p = os.path.join(GFX, rel)
        if not os.path.exists(p):
            print(f"    – {rel}: 缺")
            continue
        seen, bad = check_expand(p)
        mark = "✓" if bad == 0 else "✗"
        print(f"    {mark} {os.path.basename(rel):<36} {seen:>3} 种值  非17倍数 {bad}")
        if bad:
            ok = False

    # 难度菜单：图集 + TSA + 调色板 都已确证自洽，先合成出来看
    tsa = os.path.join(GFX, "frontier_df4_menu/Tsa_DifficultyMenuObjs.tsa.bin")
    img = os.path.join(GFX, "frontier_df4_menu/Img_DifficultyMenuObjs.png")
    pal = os.path.join(GFX, "gmapunit/Pal_DifficultyMenuObjs.pal")
    if not all(os.path.exists(p) for p in (tsa, img, pal)):
        print("  – 难度菜单素材不全", file=sys.stderr)
        return 1 if not ok else 0

    d = open(tsa, "rb").read()
    tw, th = d[0] + 1, d[1] + 1
    ent = [struct.unpack("<H", d[2 + i * 2:4 + i * 2])[0]
           for i in range((len(d) - 2) // 2)]
    if len(ent) != tw * th:
        print(f"  ✗ TSA 项数 {len(ent)} != {tw}x{th}", file=sys.stderr)
        return 1

    tiles, sw, sh = load_tiles(img)
    cols = load_palette(pal)
    print(f"  TSA {tw}x{th} = {len(ent)} 项；图集 {sw}x{sh} = {len(tiles)} 图块")

    out = Image.new("RGBA", (tw * 8, th * 8), (0, 0, 0, 0))
    op = out.load()
    for i, e in enumerate(ent):
        t = e & 0x3FF
        hf = (e >> 10) & 1
        vf = (e >> 11) & 1
        bank = (e >> 12) & 0xF
        if t >= len(tiles):
            continue
        tile = tiles[t]
        for y in range(8):
            for x in range(8):
                v = tile[7 - y if vf else y][7 - x if hf else x]
                if v == 0:
                    continue
                k = bank * 16 + v
                op[(i % tw) * 8 + x, (i // tw) * 8 + y] = (
                    *(cols[k] if k < len(cols) else (255, 0, 255)), 255)

    dst = os.path.join(a.out, "DifficultyMenuObjs.png")
    out.resize((tw * 8 * 4, th * 8 * 4), Image.NEAREST).save(dst)
    print(f"  → {dst}")

    print("  ⚠️ 排布**还没对上** —— 判据是'看得出是新手/普通/困难'，不是'有结构'。",
          file=sys.stderr)
    return 1


if __name__ == "__main__":
    sys.exit(main())
