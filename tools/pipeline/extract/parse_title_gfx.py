#!/usr/bin/env python3
"""
标题画面 / 开场动画的图形合成。

## 素材形态（`src/data/titlescreen/dat_data_titlescreen.c`）

    gGfx_TitleMainBackground_1/2   .4bpp.lz  图块
    gTsa_TitleMainBackground       bin (无头 TSA)
    gPal_TitleMainBackground       .pal      **二进制 BGR555**
    gGfx_TitleDragonForeground     .4bpp.lz
    gTsa_TitleDragonForeground     bin
    gPal_TitleDragonForeground     .pal
    ...（DemonKing / LargeGlowingOrb / SmallLightBubbles / Titlescreen_0/1/2）

## ⚠️ 为什么不直接用反编译项目自带的 `scripts/gfxtools/tsa_preview.py`

它确实干这件事，但有一个**真实 bug**：

    # scripts/gfxtools/tsa_preview.py:58-65
    if path.endswith('.pal'):
        # JASC-PAL text                      ← 当成**文本**调色板读
        lines = open(path).read().splitlines()

而 `graphics/misc_gfx/gPal_*.pal` 是 **200 字节的二进制 BGR555**（100 色）。
按文本读会得到垃圾颜色，渲染出来**整片洋红**（调色板越界）。

所以这里自己读 —— `parse_portraits.py` 里那套 BGR555 解码已经被立绘验证过了。

## TSA 是**无头**的

`gTsa_*.bin` 没有 `[width-1, height-1]` 头（那是 `.tsa.bin` 才有）。
`gTsa_TitleMainBackground.bin` = 1280 字节 = 640 项 = **32×20**。
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
GFX = os.path.join(DECOMP, "graphics", "misc_gfx")


def bgr555(v):
    """GBA BGR555 → RGB（每通道 5 位，左移 3 位再补低位）"""
    r = (v & 0x1F) << 3
    g = ((v >> 5) & 0x1F) << 3
    b = ((v >> 10) & 0x1F) << 3
    return (r | (r >> 5), g | (g >> 5), b | (b >> 5))


def load_bin_palette(path):
    """**二进制** BGR555 调色板（不是 JASC-PAL 文本）"""
    d = open(path, "rb").read()
    return [bgr555(struct.unpack("<H", d[i:i + 2])[0])
            for i in range(0, len(d) - 1, 2)]


def load_one_tileset(path):
    """把 `L` 模式的 8×N PNG 还原成 8×8 图块列表。

    ## ★ 图块数由**装载地址**定，不是猜的

    `src/Title_SetupMainGraphics.c`：

    ```c
    case 0: Decompress(gGfx_TitleMainBackground_1, (void*)0x06000000);  // VRAM tile 0
    case 1: Decompress(gGfx_TitleMainBackground_2, (void*)0x06003000);  // VRAM tile 0x180 = 384
    ```

    而 `_1.png` 是 **8×3072 像素 = 3072 行**；一个 8×8 图块 **8 行**：

        3072 / 8 = **384 图块**    ← 与 `_2` 的装载地址 tile 384 **正好接上**

    **这就是判据** —— 不用试参数就能确认"8 行一个图块、像素值就是 4bpp 的索引"。

    （我一度改成"4 行一个图块 + 解 nibble"，那是**错的**：
    那样 `_1` 会变成 768 块，与 tile 384 的装载地址矛盾。）
    """
    im = Image.open(path).convert("L")
    w, h = im.size
    if w != 8:
        raise SystemExit(f"{path}: 期望 8 像素宽，实得 {w}")
    px = im.load()
    if h % 8 != 0:
        raise SystemExit(f"{path}: 高度 {h} 不是 8 的整数倍")
    tiles = []
    for ty in range(h // 8):
        tile = [[px[x, ty * 8 + y] for x in range(8)] for y in range(8)]
        tiles.append(tile)
    return tiles


def load_tiles_4bpp(paths):
    """把**若干张**图块条按顺序拼成一份图块表。

    ⚠️ **必须拼接。** `gTsa_TitleMainBackground` 引用的 tile 范围是
    **0..600**，而 `_1.png`（8×3072）只有 **384** 块 ——
    后面 256 块在 `_2.png`（8×2048）里。384 + 256 = 640 ✓
    （`tsa_preview.py` 的 `'+'` 拼接参数就是为这个准备的。）

    我一开始只读了 `_1`，于是 385 以上的图块全部落空 ——
    渲染出来下半屏全是洋红。
    """
    tiles = []
    for p in paths:
        tiles.extend(load_one_tileset(p))
    return tiles


def compose(tsa_path, tiles_paths, pal_path, width, height=None, bank=0):
    """合成一张 BG 画面。

    ## ★ 调色板 bank 来自**装载代码**，不是 TSA 里的值

    `src/Title_SetupMainGraphics.c` 的 `case 1`：

    ```c
    Decompress(gGfx_TitleMainBackground_1, (void*)0x06000000);   // tile 0
    Decompress(gGfx_TitleMainBackground_2, (void*)0x06003000);   // tile 0x180 = 384
    Decompress(gTsa_TitleMainBackground, gBG1TilemapBuffer);
    ApplyPalette(gPal_TitleMainBackground, 0xE);                 // 调到 bank 14
    for (i = 0; i < 0x280; i++)
        gBG1TilemapBuffer[i] += 0xE000;                          // ★ 项 += 0xE000
    ```

    **TSA 里读出来的 bank 全是 0，但装载时被统一加了 `0xE000`** ——
    实际用的是**调色板 bank 14**。我一直按 bank 0 查色，所以颜色全错。

    同理 `case 2`（恶魔王前景）是 `+= 0xF280`
    —— 基址 tile `0x280 = 640`、bank `0xF = 15`。

    所以每个素材的 bank 与基址**都要从这段装载代码里读**，不能猜。
    """
    tsa = open(tsa_path, "rb").read()
    n = len(tsa) // 2
    if height is None:
        height = n // width
    # `src/Title_SetupMainGraphics.c` 用的是 `for (i = 0; i < 0x280; i++)`
    # —— **640 项**（0x280），正好 32×20。屏幕 30×20=600，多出的 40 项在右边。
    if width * height != n:
        pass
    entries = [struct.unpack("<H", tsa[i * 2:i * 2 + 2])[0] for i in range(n)]
    tiles = load_tiles_4bpp(tiles_paths)
    pal = load_bin_palette(pal_path)

    out = Image.new("RGB", (width * 8, height * 8), (0, 0, 0))
    op = out.load()
    for i in range(width * height):
        e = entries[i]
        tile = e & 0x3FF
        hf = (e >> 10) & 1
        vf = (e >> 11) & 1
        # ⚠️ **不要用 `bank` 这个名字** —— 它和函数参数同名，
        # 会遮蔽掉调用方从装载代码里读出来的值。
        # 我在这里犯过一次：改了参数却"字节完全相同"，因为参数根本没被用到。
        tsa_bank = (e >> 12) & 0xF
        if tile >= len(tiles):
            continue
        t = tiles[tile]
        for y in range(8):
            for x in range(8):
                idx = t[7 - y if vf else y][7 - x if hf else x]
                if idx == 0:
                    continue
                # 4bpp：每个图块用调色板的**一个 16 色 bank**。
                # ⚠️ `ApplyPalette(gPal_X, 0xE)` 是把**源调色板装到** bank 14，
                # 所以查色仍然是 `pal[idx]` —— bank 只决定"装到哪"。
                # （我一度写成 `(bank + tsa_bank) * 16 + idx`，那是越界的。）
                k = idx
                c = pal[k] if k < len(pal) else (255, 0, 255)
                op[(i % width) * 8 + x, (i // width) * 8 + y] = c
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", default=os.path.join(HERE, "..", "out", "title"))
    a = ap.parse_args()

    # `(名字, gfx, tsa, pal, 宽度)`
    # `(名字, [图块条...], tsa, pal, 宽度, 调色板 bank)`
    #
    # bank 全部来自 `src/Title_SetupMainGraphics.c` 的装载代码
    # （`gBGxTilemapBuffer[i] += <bank><tilebase>`），**不能猜**。
    jobs = [
        # case 1: += 0xE000
        ("TitleMainBackground",
         ["gGfx_TitleMainBackground_1.png", "gGfx_TitleMainBackground_2.png"],
         "gTsa_TitleMainBackground.bin", "gPal_TitleMainBackground.pal", 32, 0xE),
        # case 2: += 0xF280 —— 基址 0x280、bank 0xF
        ("TitleDragonForeground", ["gGfx_TitleDragonForeground.png"],
         "gTsa_TitleDragonForeground.bin", "gPal_TitleDragonForeground.pal", 32, 0xF),
        ("TitleDemonKing", ["gGfx_TitleDemonKing.png"],
         "gTsa_TitleDemonKing.bin", "gPal_TitleDemonKing.pal", 32, 0xF),
    ]
    os.makedirs(a.out, exist_ok=True)
    ok = 0
    for name, gfx_list, tsa, pal, w, bank in jobs:
        gps = [os.path.join(GFX, x) for x in gfx_list]
        tp, pp = (os.path.join(GFX, x) for x in (tsa, pal))
        if not all(os.path.exists(x) for x in (gps + [tp, pp])):
            print(f"  – {name}: 素材不全，跳过")
            continue
        try:
            im = compose(tp, gps, pp, w, bank=bank)
        except SystemExit as e:
            print(f"  ✗ {name}: {e}")
            continue
        # 标题素材是 32 图块宽（256px），但屏幕只有 240 —— 裁掉右边
        if im.size[0] > 240:
            im = im.crop((0, 0, 240, im.size[1]))
        dst = os.path.join(a.out, f"{name}.png")
        im.save(dst)
        print(f"  ✓ {name}: {im.size[0]}x{im.size[1]} → {dst}")
        ok += 1

    if ok == 0:
        print("❌ 一张都没合成出来", file=sys.stderr)
        return 1

    # ⚠️ **合成结果目前是噪点，所以默认退出码非零。**
    #
    # 已经查清的（三条，都有依据）：
    #   1. `scripts/gfxtools/tsa_preview.py:58-65` 把二进制 `.pal` 当成
    #      JASC-PAL **文本**读 —— 而 `gPal_TitleMainBackground.pal` 是
    #      200 字节的二进制 BGR555。用它渲染整片洋红。
    #   2. 图块条**必须拼接**：TSA 引用 tile 0..600，而 `_1.png` 只有
    #      768 块、`_2.png` 另有 512 块（`tsa_preview.py` 的 `'+'` 参数
    #      就是为这个准备的）。
    #   3. 这些 `L` 模式 PNG 是**原始字节**的逐字节转写，4bpp 一个字节装
    #      两个索引 —— 必须先解 nibble，不能把字节当索引。
    #
    # **还没对上的**：图块在屏幕上的排布。解出来是结构化的噪点，
    # 说明 tile/TSA 的对应关系还有一层没搞对（可能是 TSA 的行序、
    # 或图块条内部的行序）。
    #
    # 判据是"看得出是标题画面"，不是"不再有洋红"。**没到那一步就不上线。**
    print("⚠️ 合成结果仍是噪点（见本文件末尾的说明）—— 产物仅供下一步调试，",
          file=sys.stderr)
    print("   不要接进游戏。", file=sys.stderr)
    return 1


if __name__ == "__main__":
    sys.exit(main())
