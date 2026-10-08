#!/usr/bin/env python3
"""地形/地图变化表（`MapChange`）—— `TILECHANGE` / `TILEREVERT` 要用的数据。

出处：
* `struct MapChange`（`include/types.h:395-402`）：
      s8  id;        ← **-1 = 结束哨兵**
      u8  xOrigin; u8 yOrigin; u8 xSize; u8 ySize;
      const void* data;   ← 该条变化覆盖的 u16 格数据
* 表：`src/data/map/data_map_change.c`（**typed C**）——按 `layout/carved_rom.tsv:1254`
  的说明：`data_map_change typed C: per-map MapChange/TileChange tables
  (chapters 1-16 + all maps)`。共 **65** 张表。
* 另有 **24** 个 `src/data/*MapChanges_ref/`（de-pointer 过的 `.s` 切片），
  ⚠️ **本提取器暂不覆盖它们** ⇒ 在 `uncovered` 里**具名列出**（不静默少覆盖）。
* 运行时取用：`src/bmtrick.c` 的 `GetMapChange(id)` / `ApplyMapChangesById(id)`
  （`include/bmtrick.h:75-77`）。

判据（正向抽查真值 + 条数）：
* `Ch2TileChanges[0]` 必须是 `{id:0, x:3, y:0, w:3, h:3}` 且 9 个格
  `[0x0E1C,0x0E20,0x0E24,0x0E9C,0x0EA0,0x0EA4,0x0F1C,0x0F20,0x0F24]`
  （直接对着 `data_map_change.c` 的头几行核过）；
* `PrologueMapChanges` 只有哨兵一条（`{ -1, 0, 0, 0, 0, NULL }`）；
* 表数 == 65（少于 65 就说明解析漏了）。

⚠️ **未查证**：那 65 张表**各自属于哪张地图**（文件名是 `Ch2TileChanges` 这种，
但 `chapters.json` 里的章节 → 地图映射我**没**在这里接）；
以及 `data` 里 u16 的**具体含义**（是新 metatile id 还是打包值）——
要看 `src/bmtrick.c` 的 `ApplyMapChangesById`。
"""
import argparse
import json
import os
import re

HERE = os.path.dirname(os.path.abspath(__file__))
DECOMP = os.path.normpath(os.path.join(HERE, "..", "..", "..", "third_party", "fireemblem8j"))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", required=True)
    a = ap.parse_args()

    src = os.path.join(DECOMP, "src", "data", "map", "data_map_change.c")
    text = open(src, encoding="utf-8", errors="replace").read()

    # ① 每条的格数据：`static const u16 <名>[] = { ... };`
    tiles = {}
    for m in re.finditer(r"static const u16 (\w+)\[\]\s*=\s*\{([^}]*)\}", text):
        vals = [int(x, 16) if x.strip().lower().startswith("0x") else int(x)
                for x in m.group(2).split(",") if x.strip()]
        tiles[m.group(1)] = vals

    # ② 表：`static const struct MapChange <名>[] = { {..}, .. };`
    tables = {}
    for m in re.finditer(r"static const struct MapChange (\w+)\[\]\s*=\s*\{", text):
        name = m.group(1)
        i = m.end() - 1
        depth, j = 0, i
        while j < len(text):
            if text[j] == "{":
                depth += 1
            elif text[j] == "}":
                depth -= 1
                if depth == 0:
                    break
            j += 1
        body = text[i + 1:j]
        recs = []
        for rm in re.finditer(r"\{\s*(-?\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*,"
                              r"\s*([A-Za-z_]\w*|NULL)\s*\}", body):
            rid = int(rm.group(1))
            data = rm.group(6)
            recs.append({
                "id": rid,
                "x": int(rm.group(2)),
                "y": int(rm.group(3)),
                "w": int(rm.group(4)),
                "h": int(rm.group(5)),
                "tiles": tiles.get(data, None),
                "dataSymbol": None if data == "NULL" else data,
            })
        tables[name] = recs

    # ③ 未覆盖的 `.s` 切片（具名列出，不静默）
    d = os.path.join(DECOMP, "src", "data")
    uncovered = sorted(x for x in os.listdir(d) if x.endswith("MapChanges_ref"))

    # ---- 判据（正向抽查真值）----
    ch2 = tables["Ch2TileChanges"]
    assert ch2[0]["id"] == 0 and ch2[0]["x"] == 3 and ch2[0]["y"] == 0, ch2[0]
    assert ch2[0]["w"] == 3 and ch2[0]["h"] == 3, ch2[0]
    assert ch2[0]["tiles"] == [0x0E1C, 0x0E20, 0x0E24, 0x0E9C, 0x0EA0,
                               0x0EA4, 0x0F1C, 0x0F20, 0x0F24], ch2[0]["tiles"]
    assert tables["PrologueMapChanges"][0]["id"] == -1, tables["PrologueMapChanges"]
    assert len(tables) == 65, len(tables)

    out = {
        "tables": tables,
        "tableCount": len(tables),
        "recordCount": sum(len(v) for v in tables.values()),
        "tileArrayCount": len(tiles),
        "uncovered": uncovered,
        "note": "id=-1 是结束哨兵；tiles 里的 u16 含义见 bmtrick.c 的 ApplyMapChangesById（未查证）",
    }
    os.makedirs(a.out, exist_ok=True)
    with open(os.path.join(a.out, "map_changes.json"), "w", encoding="utf-8") as f:
        json.dump(out, f, ensure_ascii=False, indent=1)
    print(f"地图变化表：{len(tables)} 张 / {out['recordCount']} 条记录 / {len(tiles)} 个格数组")
    print(f"  未覆盖的 .s 切片：{len(uncovered)} 个（{', '.join(uncovered[:3])} …）")


if __name__ == "__main__":
    main()
