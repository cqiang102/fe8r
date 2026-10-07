#!/usr/bin/env python3
"""大地图的两张**数据**表：节点（29 条）与节点间路径（20 条）。

出处：
* 节点 `gWMNodeData` —— `src/data/worldmap_node_data_gf/dat_worldmap_node_data_gf.s`
  （裸 `.4byte`，按 `struct GMapNodeData` 解，`include/worldmap.h:334-352`，每条 0x20 字节）
* 路径 `gWorldmapPath_0..19` —— `src/data/worldmap_path_data.c`
  （`struct GMapMovementPathData { int elapsedTime; s16 x; s16 y; }`，
  `include/worldmap.h:303-308`；`{ -1 }` 结尾）

判据（正向抽查真值，不是"文件存在"）：
* 节点 **29** 条，且第 0 条 `chapteridx_eirika == 0`（序章）
* 路径 **20** 条，且 `gWorldmapPath_0` == `[{1351,128,88},{2703,112,72}]`

⚠️ 节点里的 `armory/vendor/secretShop` 是指针（`data_08AC2510 + off`），
这里**只记原始符号**，不解析它指向哪张商品表（未查证）。
"""
import argparse
import json
import os
import re
import struct
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
DECOMP = os.path.normpath(os.path.join(HERE, "..", "..", "..", "third_party", "fireemblem8j"))
NODE_STRIDE = 0x20


def parse_nodes():
    path = os.path.join(DECOMP, "src/data/worldmap_node_data_gf/dat_worldmap_node_data_gf.s")
    words = []
    syms = []
    for line in open(path, encoding="utf-8", errors="replace"):
        m = re.match(r"\s*\.4byte\s+0x([0-9A-Fa-f]{8})\s*$", line)
        if m:
            words.append(int(m.group(1), 16))
            syms.append(None)
            continue
        # ⚠️ 指针字是**符号 + 偏移**（`data_08AC2510 + 0x468`）而不是十六进制字面量。
        # 第一版只认字面量 ⇒ 少算 11 个字、整个数组错位（节点只剩 18 条）。
        m2 = re.match(r"\s*\.4byte\s+(\w+)\s*\+\s*0x([0-9A-Fa-f]+)\s*$", line)
        if m2:
            words.append(0)  # 值不用（未查证指向哪张表），但**位次必须占住**
            syms.append(f"{m2.group(1)} + 0x{m2.group(2)}")
    if not words:
        print("❌ 没读到 gWMNodeData 的字", file=sys.stderr)
        return None
    raws = b"".join(w.to_bytes(4, "little") for w in words)
    # 指针字段的原始符号（按节点序号对齐取出，供审计）
    ptrSyms = [syms[i * (NODE_STRIDE // 4) + j]
               for i in range(len(words) // (NODE_STRIDE // 4))
               for j in (3, 4, 5)]
    n = len(raws) // NODE_STRIDE
    out = []
    for i in range(n):
        b = raws[i * NODE_STRIDE:(i + 1) * NODE_STRIDE]
        (placementFlag, encounters, iconPre, iconPost, chEirika, chEphraim,
         unk06) = struct.unpack_from("<BBBBBBh", b, 0)
        unk08 = list(struct.unpack_from("<4b", b, 8))
        armory, vendor, secret = struct.unpack_from("<III", b, 12)
        x, y, nameTextId, shipFlag = struct.unpack_from("<hhHB", b, 24)
        out.append({
            "placementFlag": placementFlag, "encounters": encounters,
            "iconPreClear": iconPre, "iconPostClear": iconPost,
            "chapteridx_eirika": chEirika, "chapteridx_ephram": chEphraim,
            "unk_06": unk06, "unk_08": unk08,
            # 指针只留"是不是 data_08AC2510 + off"这一事实
            "armorySym": ptrSyms[i * 3], "vendorSym": ptrSyms[i * 3 + 1],
            "secretShopSym": ptrSyms[i * 3 + 2],
            "hasShopPointers": any(ptrSyms[i * 3 + k] is not None for k in (0, 1, 2)),
            "x": x, "y": y, "nameTextId": nameTextId, "shipTravelFlag": shipFlag,
        })
    return out


def parse_paths():
    path = os.path.join(DECOMP, "src/data/worldmap_path_data.c")
    txt = open(path, encoding="utf-8", errors="replace").read()
    out = {}
    for m in re.finditer(
            r"gWorldmapPath_(\d+)\[\]\s*=\s*\{(.*?)\n\};", txt, re.S):
        idx = int(m.group(1))
        pts = []
        for row in re.finditer(r"\{\s*(-?\d+)\s*,\s*(-?\d+)\s*,\s*(-?\d+)\s*,?\s*\}", m.group(2)):
            t, x, y = (int(row.group(i)) for i in (1, 2, 3))
            if t < 0:
                break
            pts.append({"t": t, "x": x, "y": y})
        out[f"gWorldmapPath_{idx}"] = pts
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", default=os.path.join(HERE, "..", "out", "tables"))
    a = ap.parse_args()

    nodes = parse_nodes()
    paths = parse_paths()
    if nodes is None:
        return 1

    # ★ 正向抽查真值
    if len(nodes) != 29:
        print(f"❌ 节点数不是 29：{len(nodes)}", file=sys.stderr)
        return 1
    if nodes[0]["chapteridx_eirika"] != 0:
        print(f"❌ 节点 0 的 chapteridx_eirika 不是 0（序章）：{nodes[0]}", file=sys.stderr)
        return 1
    if len(paths) != 20:
        print(f"❌ 路径数不是 20：{len(paths)}", file=sys.stderr)
        return 1
    p0 = [(p["t"], p["x"], p["y"]) for p in paths["gWorldmapPath_0"]]
    if p0 != [(1351, 128, 88), (2703, 112, 72)]:
        print(f"❌ gWorldmapPath_0 不对：{p0}", file=sys.stderr)
        return 1
    print(f"  ✓ 节点 29 条（第 0 条 chapteridx_eirika=0）；"
          f"路径 20 条（path_0 = {p0}）")
    print(f"    带商店指针的节点：{sum(1 for n in nodes if n['hasShopPointers'])} 条")

    os.makedirs(a.out, exist_ok=True)
    dst = os.path.join(a.out, "worldmap.json")
    with open(dst, "w", encoding="utf-8") as f:
        json.dump({
            "note": "大地图节点与路径。节点顺序 = gWMNodeData 顺序（= WMLoc_GetChapterId 的 i）。",
            "nodes": nodes,
            "paths": paths,
        }, f, ensure_ascii=False, indent=1)
    print(f"→ {dst}  ({os.path.getsize(dst)} B)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
