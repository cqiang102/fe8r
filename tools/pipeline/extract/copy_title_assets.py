#!/usr/bin/env python3
"""
把反编译项目里**已经合成好的**素材复制到 `assets/title/`。

## 为什么需要这一步

`graphics/` 下的 PNG 有两种：

    Img_X.png     裸图块条（8px 宽、`L` 模式）—— 要 FETSATOOL 才能合成
    X.png         **已经合成好的可编辑源图**（`Makefile:804-808` 用 `$(GBAGFX)`
                  把它转成 `.4bpp`/`.gbapal`）

**所以大部分素材不用我合成** —— 规律是"去掉 `Img_` 前缀"。

## ★ 索引 0 → 透明

GBA 的调色板索引 0 是**透明色**，而这些 PNG 里它被填成**洋红**
（PNG 里常见的"透明标记"）。直接铺到画面上就是一片洋红。

所以复制时把索引 0 的像素转成 alpha=0。
"""
import argparse
import os
import shutil
import sys

try:
    from PIL import Image
except ImportError:
    print("需要 Pillow", file=sys.stderr)
    sys.exit(1)

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.abspath(os.path.join(HERE, "..", "..", ".."))
DECOMP = os.path.join(REPO, "third_party", "fireemblem8j", "graphics")
OUT = os.path.join(REPO, "assets", "title")

# (源相对路径, 输出名)
ASSETS = [
    ("misc_gfx3/IntelligentSystems.png", "IntelligentSystems.png"),
    # 职业介绍 / 开场动画的角色立绘
    ("opanim/OpAnimEirika.png", "OpAnimEirika.png"),
    ("opanim/OpAnimEphraim.png", "OpAnimEphraim.png"),
    ("opanim/OpAnimFaceSeth.png", "OpAnimFaceSeth.png"),
    ("opanim/OpAnimFaceTana.png", "OpAnimFaceTana.png"),
    ("opanim/OpAnimFaceLyon.png", "OpAnimFaceLyon.png"),
]


# 这些 PNG 用**洋红**当透明标记。但洋红可能对应**多个调色板索引**
# （我只处理索引 0 时，画面上还剩零散的洋红块 —— 截图里一眼可见）。
#
# 所以判据用**颜色**而不是索引：洋红即透明。
# 这里限定得比较严（红蓝满、绿接近 0），避免误伤角色身上的紫色。
MAGENTA = ((255, 0, 255), (248, 0, 248), (255, 0, 248), (248, 0, 255),
           (230, 0, 230), (224, 0, 224))


def _is_magenta(r, g, b):
    if g > 40:
        return False
    return any(abs(r - mr) <= 32 and abs(b - mb) <= 32 for mr, _, mb in MAGENTA)


def to_rgba_index0_transparent(src, dst):
    """把**洋红**（透明标记）转成 alpha=0，输出 RGBA。"""
    im = Image.open(src).convert("RGBA")
    px = im.load()
    w, h = im.size
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if a != 0 and _is_magenta(r, g, b):
                px[x, y] = (r, g, b, 0)
    im.save(dst)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", default=OUT)
    a = ap.parse_args()
    os.makedirs(a.out, exist_ok=True)

    ok = 0
    for rel, name in ASSETS:
        src = os.path.join(DECOMP, rel)
        if not os.path.exists(src):
            print(f"  – {name}: 缺 {rel}")
            continue
        dst = os.path.join(a.out, name)
        try:
            to_rgba_index0_transparent(src, dst)
            print(f"  ✓ {name}")
            ok += 1
        except Exception as e:
            print(f"  ✗ {name}: {e}")

    if ok == 0:
        print("❌ 一张都没复制出来", file=sys.stderr)
        return 1
    print(f"→ {a.out}（{ok} 张）")
    return 0


if __name__ == "__main__":
    sys.exit(main())
