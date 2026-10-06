#!/usr/bin/env python3
"""
FE 图形素材的合成 —— **格式由项目自带的 `tsa_generator.py` 定义并验证**。

# 格式（已往返验证 100%）

`scripts/gfxtools/tsa_generator.py` 是**正向**工具（PNG -> feimg4 + fetsa4）。
把它跑一遍、再把结果拼回去，就能确定格式 —— **这是判据，不是猜测**：

    tsa_generator.py IntelligentSystems.png out.feimg4.bin out.fetsa4.bin
    -> 用 out 拼回 240x160
    -> 与原图逐像素比对: 38400/38400 = 100%

读它的源码（`extract_tiles` / `convert_to_4bpp`）得到：

    * 输入必须是 **P 模式**（索引调色板）PNG，**像素值就是 4bpp 索引**
    * 图块 8x8、**行优先**
    * 打包：`byte = (低 nibble) | (高 nibble << 4)` —— **第一个像素在低 nibble**
    * `feimg4.bin` = 去重后的图块串接，每个 32 字节
    * `fetsa4.bin` = **小端** u16：tile=bit0-9、hflip=bit10、vflip=bit11、bank=bit12-15

# ⚠️ 两类 PNG 要分开处理

    X.png       **P 模式** —— 可编辑的合成源图，像素值 = 索引
    Img_X.png   **L 模式** —— `gbagfx` 把灰度 PNG 当**裸字节**，所以它
                就是 `feimg4.bin` 的内容（已经打包好的 4bpp 字节）

# ⚠️ 我在这里错过两次，都值得记下来

1. 把 `L` 模式的**字节**当成索引（值域 0..255，而 4bpp 只该有 0..15）
2. 看到字节全是 17 的倍数，就以为 `gbagfx` 把 nibble 展开了 `n*17`，
   于是搞出个 `÷17` —— **那只是"两个 nibble 相同"**：

       (1 & 0xF) | ((1 & 0xF) << 4) = 0x11 = 17

   **÷17 对平色区域碰巧成立，一般情况是错的。**

**教训**：格式要**用工具定义**（跑一遍、往返验证），
不是对着数据看规律。规律会骗人。
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


def bgr555(v):
    r = (v & 0x1F) << 3
    g = ((v >> 5) & 0x1F) << 3
    b = ((v >> 10) & 0x1F) << 3
    return (r | (r >> 5), g | (g >> 5), b | (b >> 5))


def load_palette(path):
    d = open(path, "rb").read()
    return [bgr555(struct.unpack("<H", d[i:i + 2])[0])
            for i in range(0, len(d) - 1, 2)]


def load_tiles_from_bytes(data, per_tile=32):
    """把**打包好的 4bpp 字节**切成图块（`Img_*.png` / `feimg4.bin` 用）。

    每个图块 32 字节 = 8 行 × 4 字节；每字节两个像素，**低 nibble 在前**。
    """
    tiles = []
    for t in range(len(data) // per_tile):
        c = data[t * per_tile:(t + 1) * per_tile]
        tile = [[0] * 8 for _ in range(8)]
        for y in range(8):
            for b in range(4):
                byte = c[y * 4 + b]
                tile[y][b * 2] = byte & 0xF
                tile[y][b * 2 + 1] = (byte >> 4) & 0xF
        tiles.append(tile)
    return tiles


def load_tiles_from_lpng(path):
    """`Img_*.png`（L 模式）—— **逐字节**读，不要当索引。

    依据：`gbagfx` 对灰度 PNG 是**直通**（把它当裸数据），
    所以文件里的字节就是 `feimg4.bin` 的内容。
    """
    im = Image.open(path).convert("L")
    px = im.load()
    w, h = im.size
    return load_tiles_from_bytes([px[x, y] for y in range(h) for x in range(w)])


def load_tiles_from_ppng(path):
    """`X.png`（P 模式）—— 像素值就是索引（`extract_tiles` 的语义）。"""
    im = Image.open(path)
    if im.mode != "P":
        raise ValueError(f"{path}: 期望 P 模式，实得 {im.mode}")
    px = im.load()
    w, h = im.size
    tiles = []
    for ty in range(h // 8):
        for tx in range(w // 8):
            tiles.append([[px[tx * 8 + x, ty * 8 + y] & 0xF for x in range(8)]
                          for y in range(8)])
    return tiles


def load_tsa(path):
    """读 TSA。**有 2 字节尺寸头**时返回 (w, h, entries)，否则 (None, None, entries)。"""
    d = open(path, "rb").read()
    n = len(d) // 2
    # `.tsa.bin` 有 [w-1, h-1] 头；`fetsa4.bin` 没有
    if path.endswith(".tsa.bin"):
        w, h = d[0] + 1, d[1] + 1
        d = d[2:]
        if w * h != len(d) // 2:
            return None, None, [struct.unpack("<H", d[i * 2:i * 2 + 2])[0]
                                for i in range(len(d) // 2)]
        ent = [struct.unpack("<H", d[i * 2:i * 2 + 2])[0] for i in range(len(d) // 2)]
        return w, h, ent
    return None, None, [struct.unpack("<H", d[i * 2:i * 2 + 2])[0]
                        for i in range(len(d) // 2)]


def compose(tiles, entries, cols, width, height=None, tileref=0):
    """按 TSA 拼图。

    `tileref` = `CallARM_FillTileRect(dest, tsa, tileref)` 的第三个参数，
    **会加到每一项上**（`src/difficultymenu_080B0B38.c:52` 用 `0x1000`）。
    """
    if height is None:
        height = len(entries) // width
    out = Image.new("RGBA", (width * 8, height * 8), (0, 0, 0, 0))
    op = out.load()
    for i, e0 in enumerate(entries):
        if i >= width * height:
            break
        e = e0 + tileref
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
                op[(i % width) * 8 + x, (i // width) * 8 + y] = (
                    *(cols[k] if k < len(cols) else (255, 0, 255)), 255)
    return out


def selfcheck():
    """用 `IntelligentSystems.png` 做**往返验证** —— 格式的自检。"""
    src_png = os.path.join(GFX, "misc_gfx3/IntelligentSystems.png")
    if not os.path.exists(src_png):
        print("  – 自检跳过（缺 IntelligentSystems.png）")
        return True

    import subprocess
    import tempfile
    tool = os.path.join(DECOMP, "scripts/gfxtools/tsa_generator.py")
    with tempfile.TemporaryDirectory() as td:
        fe = os.path.join(td, "x.feimg4.bin")
        ts = os.path.join(td, "x.fetsa4.bin")
        r = subprocess.run([sys.executable, tool, src_png, fe, ts],
                           capture_output=True, text=True)
        if r.returncode != 0:
            print(f"  ✗ tsa_generator 失败：{r.stderr.strip()[:160]}")
            return False

        tiles = load_tiles_from_bytes(open(fe, "rb").read())
        _, _, ent = load_tsa(ts)
        src = Image.open(src_png)
        pal = src.getpalette()
        cols = [(pal[i * 3], pal[i * 3 + 1], pal[i * 3 + 2])
                for i in range(len(pal) // 3)]
        got = compose(tiles, ent, cols, 30, 20)

        a = src.convert("RGB")
        b = got.convert("RGB")
        same = sum(1 for y in range(160) for x in range(240)
                   if a.getpixel((x, y)) == b.getpixel((x, y)))
        pct = same * 100 // (240 * 160)
        ok = same == 240 * 160
        print(f"  {'✓' if ok else '✗'} 往返验证：{same}/38400 = {pct}%")
        return ok


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", default=os.path.join(HERE, "..", "out", "fe_gfx"))
    a = ap.parse_args()
    os.makedirs(a.out, exist_ok=True)

    print("  [格式自检] tsa_generator 往返：")
    if not selfcheck():
        return 1

    print("  ⚠️ 见本文件末尾「仍未解」。")
    return 1


if __name__ == "__main__":
    sys.exit(main())


# ============================================================================
# 仍未解 / 已解
# ============================================================================
#
# ## 已解（都有判据）
#
# * **格式** —— 由 `tsa_generator.py` 往返验证（38400/38400 = 100%）
# * **`CallARM_FillTileRect` = `TmApplyTsa`**
#   （`src/arm_call.s:5-12`：`bx pc; nop; .ARM; b TmApplyTsa`）
# * **`tileref` 是加到每一项上的 bank** —— 对照 `j_TmApplyTsa` 的其它调用点：
#   `0x7000`/`0x6000`/`0xc000`/`0x1000`（`Augury_InitResultScreen.c:160`、
#   `opinfo_080B83A8.c:138,143`）
# * **TSA 的行是自下而上的** —— `parse_portraits.py` 里早就记过这个坑
#   （「试了 4 种组合，只有一种完全对」）
# * **`Tsa_DifficultyMenuObjs` 是一张装饰边框，里面没有文字**
#   —— 把 TSA 的图块号打成网格就看得很清楚：
#
#       26  27  28  28  28  28 ...  32  33     <- 上边
#        6   9   9   9   9 ... 62  64  66  68  69
#        ...
#        1   2   3   3   3   3 ...   4   5     <- 下边
#
#   `9` 是平的填充、`6`/`10` 是左右边、`62..69` 是斜角装饰。
#   **所以难度的"名字"不可能来自它** —— 那些是 OAM 精灵
#   （`gSprite_DifficultyMenuSelectModeText`）。
#
# ## 仍未解
#
# * **OAM 精灵 -> 图块** 的映射（主菜单 / 难度的名字）。
#   精灵表 `gSprite_SavemenuData_N` 的 OAM 项已经在手
#   （`OAM2_CHR(0x180)` 等），但 CHR 基址与图块号的对应还没定。
# * `SaveDrawCursorYOffsetLut` 的 8 个字节 —— **不在仓库里**（只有地址）。
