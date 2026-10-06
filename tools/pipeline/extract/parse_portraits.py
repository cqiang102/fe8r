#!/usr/bin/env python3
"""
立绘合成：把**索引色图块条 + GBA 调色板 + TSA 排列**拼成可显示的 PNG。

## 素材是什么

立绘不是现成图片：

    graphics/portrait/portrait_<名字>_tileset.png    256×32 索引色 PNG（4bpp 图块条）
    graphics/portrait/portrait_<名字>_palette.agbpal  GBA BGR555 调色板（16 色）
    graphics/portrait/portrait_<名字>_mouth.png       口型层
    graphics/portrait/portrait_<名字>_chibi.png       地图小头像

    共 483 个角色

## 排列从哪来

`src/face.c` 的 `PutFace80x72_Standard`：

    CallARM_FillTileRect(tm, gBattleForecast_0, (u16)tileref);
    ...

`CallARM_FillTileRect` → `TmApplyTsa`（ROM 里的 ARM 函数）。
`gBattleForecast_0` 是一张 **10×9 图块的 TSA**
（`graphics/battle_forecast/gBattleForecast_0.tsa.bin`；
头 2 字节是 `[width-1, height-1]`，随后每项 u16 = `tile(10b) | hflip | vflip | pal(4b)`）。

它的内部是个干净的 8×8 网格：

    y=8:  0  1  2  3  4  5  6  7      ← 在文件里 y 越小越靠前
    y=7: 32 33 34 35 36 37 38 39
    y=6: 64 65 66 67 68 69 70 71
    y=5: 96 97 98 99 100 101 102 103
    y=4:  8  9 10 11 12 13 14 15
    y=3: 40 41 42 43 44 45 46 47
    y=2: 72 73 74 75 76 77 78 79
    y=1: 104 ... 111

## ★ 关键：**TSA 的 y 轴是自下而上的**

`gBattleForecast_0` 的第 0 行对应画面的**底部**。

我在这里绕了几轮：先按行优先直接铺（错位）、再试列优先（更差）、
再试翻转……**直到把整张输出上下翻转才对上**。

这个坑值得记：GBA 的 BG tilemap 是"行号向下增长"，
但 `PutFace80x72_Standard` 用的这张 TSA 是**给"向上堆叠"的缓冲区**写的 ——
所以映射到我们的图像坐标时要翻转 y。

**不要凭"哪个看起来更像"来选** —— 试了 4 种组合，只有一种完全对。
"""
import argparse
import glob
import json
import os
import struct
import sys

try:
    from PIL import Image
except ImportError:
    print("需要 Pillow：pip install Pillow", file=sys.stderr)
    sys.exit(1)

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.abspath(os.path.join(HERE, "..", "..", ".."))
DECOMP = os.path.join(REPO, "third_party", "fireemblem8j")
PORTRAIT_DIR = os.path.join(DECOMP, "graphics", "portrait")
TSA_PATH = os.path.join(DECOMP, "graphics", "battle_forecast",
                        "gBattleForecast_0.tsa.bin")


def bgr555_to_rgb(v):
    """GBA 调色板是 BGR555：每通道 5 位，左移 3 位再补上高位当低位。"""
    r = (v & 0x1F) << 3
    g = ((v >> 5) & 0x1F) << 3
    b = ((v >> 10) & 0x1F) << 3
    return (r | (r >> 5), g | (g >> 5), b | (b >> 5))


def load_palette(path):
    raw = open(path, "rb").read()
    return [bgr555_to_rgb(struct.unpack("<H", raw[i:i + 2])[0])
            for i in range(0, len(raw), 2)]


def load_tsa(path):
    t = open(path, "rb").read()
    w, h = t[0] + 1, t[1] + 1
    return w, h, [struct.unpack("<H", t[2 + i * 2:4 + i * 2])[0]
                  for i in range(w * h)]


def compose(name, tsa):
    """合成一个角色的立绘。返回 PIL Image 或 None。"""
    ts_path = os.path.join(PORTRAIT_DIR, f"portrait_{name}_tileset.png")
    pal_path = os.path.join(PORTRAIT_DIR, f"portrait_{name}_palette.agbpal")
    if not (os.path.exists(ts_path) and os.path.exists(pal_path)):
        return None

    ts = Image.open(ts_path)
    pal = load_palette(pal_path)
    w, h, entries = tsa

    px = ts.load()
    tw = ts.size[0] // 8
    th = ts.size[1] // 8

    # ⚠️ **用 RGBA，索引 0 = 透明。**
    #
    # GBA 立绘的调色板第 0 色是"透明/背景色"（实测是浅绿）。
    # 第一版存成 RGB，于是每张立绘都顶着一块浅绿方块，
    # 贴在对话框上像是画错了。
    out = Image.new("RGBA", (w * 8, h * 8), (0, 0, 0, 0))
    op = out.load()

    for i, e in enumerate(entries):
        tile = e & 0x3FF
        hf = (e >> 10) & 1
        vf = (e >> 11) & 1
        sx, sy = (tile % tw) * 8, (tile // tw) * 8
        if sy + 8 > ts.size[1]:
            continue
        ix, iy = i % w, i // w
        # ★ y 翻转：TSA 的第 0 行是画面底部
        tx, ty = ix * 8, (h - 1 - iy) * 8
        for y in range(8):
            for x in range(8):
                idx = px[sx + (7 - x if hf else x), sy + (7 - y if vf else y)]
                if idx == 0:
                    continue  # 索引 0 = 透明
                c = pal[idx] if idx < len(pal) else (0, 0, 0)
                op[tx + x, ty + y] = (c[0], c[1], c[2], 255)
    return out


# ---------------------------------------------------------------------------
# 嘴型（表情）
#
# ## 机制（`src/face.c` 的 `PutFace80x72_Standard`）
#
# ```c
# int x = info->xMouth - 1;
# int y = info->yMouth;
# CallARM_FillTileRect(tm, gBattleForecast_0, (u16)tileref);
# tm[TILEMAP_INDEX(x, y) + 0x00 + 0] = tileref + 0x00 + 0x1C;
# ...
# tm[TILEMAP_INDEX(x, y) + 0x20 + 0] = tileref + 0x20 + 0x1C;
# ```
#
# 即：在 **(xMouth-1, yMouth)** 处覆盖一个 **4×2 图块（32×16px）** 的嘴。
#
# ## `_mouth.png` 是什么
#
# 32×96 = 4×12 图块 = **6 帧 × 8 块（每帧 4×2）**。
# 实测帧间确实不同（与帧 0 差 11/24/7/14/24 个像素），所以这个切分是对的。
#
# ## 位置从哪来
#
# `struct FaceData` 在反编译项目里**没有定义**（只有前向声明），
# 所以 `xMouth`/`yMouth` 只能从 `portrait_data[]` 的字里推。
# 表里第 5 个字是 `0x04030602`，按小端拆是 `02 06 03 04` ——
# 低字节 `2` / 次字节 `6`，与**视觉实验**一致（贴上去正落在嘴的位置）。
#
# ⚠️ 置信度：**中**。位置看着对，但字段的正式含义仍未证实
# （`0x03`/`0x04` 是什么不知道）。所以导出时把原始字也带上，
# 免得将来只能靠重新推。
MOUTH_FRAMES = 6
MOUTH_TILES_PER_FRAME = 8


def compose_mouth(name, pal):
    """把一个角色的嘴型条切成 6 帧 RGBA。返回 list[Image] 或 None。"""
    p = os.path.join(PORTRAIT_DIR, f"portrait_{name}_mouth.png")
    if not os.path.exists(p):
        return None
    m = Image.open(p)
    if m.size[0] != 32 or m.size[1] != 96:
        return None
    px = m.load()
    frames = []
    for f in range(MOUTH_FRAMES):
        im = Image.new("RGBA", (32, 16), (0, 0, 0, 0))
        op = im.load()
        for row in range(2):
            for col in range(4):
                n = f * MOUTH_TILES_PER_FRAME + row * 4 + col
                tx, ty = (n % 4) * 8, (n // 4) * 8
                for y in range(8):
                    for x in range(8):
                        idx = px[tx + x, ty + y]
                        if idx == 0:
                            continue
                        c = pal[idx] if idx < len(pal) else (0, 0, 0)
                        op[col * 8 + x, row * 8 + y] = (c[0], c[1], c[2], 255)
        frames.append(im)
    return frames


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", default=os.path.join(HERE, "..", "out", "portraits"))
    ap.add_argument("--limit", type=int, default=0)
    a = ap.parse_args()

    if not os.path.exists(TSA_PATH):
        print(f"错误：找不到 {TSA_PATH}", file=sys.stderr)
        return 1
    tsa = load_tsa(TSA_PATH)
    print(f"TSA {tsa[0]}x{tsa[1]} 图块 = {tsa[0]*8}x{tsa[1]*8} 像素")

    names = sorted({
        os.path.basename(p)[len("portrait_"):-len("_tileset.png")]
        for p in glob.glob(os.path.join(PORTRAIT_DIR, "portrait_*_tileset.png"))
    })
    print(f"找到 {len(names)} 个角色")
    if a.limit:
        names = names[:a.limit]

    os.makedirs(a.out, exist_ok=True)
    mouth_dir = os.path.join(a.out, "mouth")
    os.makedirs(mouth_dir, exist_ok=True)
    ok, skip, meta = 0, 0, {}
    mouths = 0
    for n in names:
        img = compose(n, tsa)
        if img is None:
            skip += 1
            continue
        img.save(os.path.join(a.out, f"{n}.png"))
        meta[n] = {"w": img.size[0], "h": img.size[1]}
        ok += 1

        # 嘴型：6 帧 × 32×16（`_mouth.png` = 4×12 图块）
        pal = load_palette(os.path.join(
            PORTRAIT_DIR, f"portrait_{n}_palette.agbpal"))
        frames = compose_mouth(n, pal)
        if frames:
            for fi, fr in enumerate(frames):
                fr.save(os.path.join(mouth_dir, f"{n}_{fi}.png"))
            meta[n]["mouthFrames"] = len(frames)
            mouths += 1

    print(f"合成 {ok} 张（跳过 {skip}），其中 {mouths} 张带嘴型")
    # ⚠️ 空集不算通过：一张都没合成出来必定是素材路径或 TSA 解析坏了
    if ok == 0:
        print("❌ 一张都没合成出来 —— 空集不算通过", file=sys.stderr)
        return 1
    with open(os.path.join(a.out, "index.json"), "w", encoding="utf-8") as f:
        json.dump({"tsa": os.path.relpath(TSA_PATH, DECOMP),
                   "size": [tsa[0] * 8, tsa[1] * 8],
                   "portraits": meta}, f, ensure_ascii=False, indent=1)
    print(f"→ {a.out}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
