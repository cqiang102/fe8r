#!/usr/bin/env python3
"""
脸编号 → 角色名（`portrait_data[]`）。

## 表在哪

`src/GetPortraitData.c`：

    const struct FaceData* GetPortraitData(int fid) {
        return portrait_data + fid - 1;
    }

所以 **表项下标 + 1 = 脸编号**。

## ⚠️ 关于"有没有代码可读"——我查清了

`struct FaceData` 在反编译项目里**从未被定义过**，只有前向声明
（`include/face.h` 里到处是 `const struct FaceData*`，但没有 `struct FaceData { ... }`）。

所以那张表**真的就是个裸的 `u32[]`**，里面全是符号引用：

    (u32)&portrait_Eirika_tileset, (u32)&portrait_Eirika_chibi,
    (u32)&portrait_Eirika_palette, (u32)&portrait_Eirika_mouth,
    0x00000000, 0x04030602, 0x00000001,

**"读代码"在这里能读到的只有符号名**（那已经是代码的一部分了）；
字段的分组只能推断 —— 每项 7 个字的依据是
`layout/baseline_syms.d/data_face_portrait.tsv` 里的注释
`sizeof(struct FaceData)=0x1C`（= 28 字节 = 7 个 u32）。

分组**验证过**：174 项里 57 个空项的第 0 字干净地全是 `0x00000000`，
且 1218 ÷ 7 = 174.00 整除 —— 错位不会这么整齐。

## ★ 文本里的 `[$XXXX]` = **(槽位 << 8) | 脸编号**

不是纯脸编号。序章开场实测：

    $0152 → 槽 1，脸 82  = Fado（雷诺斯王，留下断后）
    $016B → 槽 1，脸 107 = Soldier_1（传令兵："禀报！城门被突破！"）
    $0102 → 槽 1，脸 2   = Eirika
    $0104 → 槽 1，脸 4   = Seth
    $0142 → 槽 1，脸 66  = Valter（结尾的追兵将领）

**正是序章的全体出场人物。** 而 `0x152` 本身 = 338 越出表范围（174 项），
第一版据此以为"这不是脸编号"—— 拆成高低字节才对上。

## 表项是**可读的 C 源码**

`src/data/frontier_df4_banim_b/frontier_df4_banim_b.c` 的
`frontier_df4_banim_b_070_901138[]`（JP 地址 0x08901138）：

    (u32)&portrait_Eirika_tileset, (u32)&portrait_Eirika_chibi,
    (u32)&portrait_Eirika_palette, (u32)&portrait_Eirika_mouth,
    0x00000000, 0x04030602, 0x00000001,

**每个表项直接写着角色名。** 七个 u32 一项。

## 又一次是同一个道理

我上一轮说"完整表在 ROM 里、未 carve"—— **错的**。
它在 `src/data/` 下，是带符号名的可读 C。

和前面几次完全同类：
  * 指针名字写在源码里，我却去搞重定位
  * 文本编码语义写在 `textdefs.txt` 里，我却不知道有"分页"
  * 立绘排列写在 `face.c` 里，我却去试参数
  * 表项名字写在 C 里，我却说"在 ROM 里"

**每次都是：信息一直都在，我先假设它不在。**
"""
import argparse
import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.abspath(os.path.join(HERE, "..", "..", ".."))
DECOMP = os.path.join(REPO, "third_party", "fireemblem8j")

TABLE_SRC = "src/data/frontier_df4_banim_b/frontier_df4_banim_b.c"
TABLE_SYM = "frontier_df4_banim_b_070_901138"
WORDS_PER_ENTRY = 7


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", default=os.path.join(HERE, "..", "..", "..",
                                                  "tools", "pipeline", "out",
                                                  "tables"))
    a = ap.parse_args()

    path = os.path.join(DECOMP, TABLE_SRC)
    if not os.path.exists(path):
        print(f"错误：找不到 {path}", file=sys.stderr)
        return 1
    src = open(path, encoding="utf-8", errors="replace").read()
    # ⚠️ `[^=]*` **会跨过 `extern` 声明**（那里面没有 `=`），一路跳到别的数组的
    # `= {` 上 —— 实测匹配到的是另一个 9031 字的数组，一个 portrait_ 都没有。
    # 用 `[^;=]*` 禁止跨过分号。
    m = re.search(rf"u32\s+{TABLE_SYM}\[\]\s*[^;=]*=\s*\{{(.*?)\n\}};", src, re.S)
    if not m:
        print("错误：没找到表定义", file=sys.stderr)
        return 1

    # 表项 = 7 个 u32（`struct FaceData` = 0x1C = 28 字节），
    # **表项下标 + 1 = 脸编号**（`GetPortraitData` 是 `portrait_data + fid - 1`）。
    body = re.sub(r"/\*.*?\*/", " ", m.group(1), flags=re.S)
    items = [x.strip() for x in body.split(",") if x.strip()]
    if len(items) % WORDS_PER_ENTRY != 0:
        print(f"❌ 元素数 {len(items)} 不是 {WORDS_PER_ENTRY} 的整数倍",
              file=sys.stderr)
        return 1
    total = len(items) // WORDS_PER_ENTRY
    print(f"  表项 {total} 个（{len(items)} 个 u32 ÷ {WORDS_PER_ENTRY}）")

    # ⚠️ **不要按"`_tileset` 出现顺序"数下标。**
    #
    # 174 个表项里只有 117 个带 `_tileset` —— 空项（占位脸）会让下标整体错位。
    # 实测那样做只有 7/8 个具名常量对得上，末尾偏了。
    faces = {}
    # 顺带带上第 5 个字（`0x04030602`）—— 推测是 `xMouth`/`yMouth`
    # 所在的字。`struct FaceData` 在反编译项目里没有定义，只能带原始字。
    mouth_raw = {}
    for k in range(total):
        e0 = items[k * WORDS_PER_ENTRY]
        mm = re.search(r"&portrait_([A-Za-z0-9_]+)_tileset", e0)
        faces[k + 1] = mm.group(1) if mm else None
        # 第 5 个字（下标 5）：低字节 = xMouth、次字节 = yMouth（推测）
        e5 = items[k * WORDS_PER_ENTRY + 5] if k * WORDS_PER_ENTRY + 5 < len(items) else ''
        mv = re.search(r"0x([0-9A-Fa-f]{8})", e5)
        if mv:
            v = int(mv.group(1), 16)
            mouth_raw[k + 1] = {"raw": f"0x{v:08X}",
                                "xMouth": v & 0xFF, "yMouth": (v >> 8) & 0xFF}

    named = sum(1 for v in faces.values() if v)
    print(f"  其中有名字的 {named} 个，空项 {total - named} 个")

    # ---- 校验：与 `faces.h` 的具名常量对照 ----
    #
    # ⚠️ **`faces.h` 的 `FID_*` 是美版编号，JP 表有差异。**
    #
    # 实测：`0x26`（Myrrh）及以前**偏移 0**，`0x64`（Anna）起**偏移 +1** ——
    # 也就是 JP 表在 fid 39..100 之间比美版**多了一项**。
    #
    # 而**JP 表才是 JP 文本的权威**（文本里的脸编号是 JP 编号），
    # 所以这里以**表**为准，只把美版常量当作"早期项"的交叉验证。
    known = {0x02: "Eirika", 0x10: "Lute", 0x14: "Ephraim", 0x19: "Amelia",
             0x21: "Ewan", 0x23: "Dozla", 0x26: "Myrrh"}
    bad = [(k, v, faces.get(k)) for k, v in known.items()
           if faces.get(k) != v]
    if bad:
        print("\n❌ 与 faces.h 的**早期**具名常量对不上：", file=sys.stderr)
        for k, want, got in bad:
            print(f"   0x{k:02X} 期望 {want} 实得 {got}", file=sys.stderr)
        return 1
    print(f"✅ 早期 {len(known)} 个具名常量**全部对上**（0x02..0x26）")

    # 后期常量带 +1 偏移 —— 记录而不是当失败
    late = {0x64: "Anna", 0x65: "Armoury", 0x66: "Vendor",
            0x67: "Arena", 0x68: "Secret_Shop"}
    drifts = set()
    for k, v in late.items():
        pos = [i for i, n in faces.items() if n == v]
        if pos:
            drifts.add(pos[0] - k)
    if drifts == {1}:
        print("✅ 后期 5 个具名常量**一致偏移 +1** —— JP 表比美版多一项（已记录）")
    else:
        print(f"⚠️ 后期常量偏移不一致：{sorted(drifts)}", file=sys.stderr)

    os.makedirs(a.out, exist_ok=True)
    dst = os.path.join(a.out, "face_ids.json")
    with open(dst, "w", encoding="utf-8") as f:
        json.dump({
            "source": TABLE_SRC,
            "note": "表项下标 + 1 = 脸编号（GetPortraitData 是 fy = portrait_data + fid - 1）",
            "faces": {str(k): v for k, v in sorted(faces.items())},
            "mouthPos": {str(k): v for k, v in sorted(mouth_raw.items())},
            "mouthPosNote": "第 5 个字的低字节/次字节；struct FaceData 未定义，"
                            "此处为**推测**（视觉实验一致，置信度中）",
        }, f, ensure_ascii=False, indent=1)
    print(f"\n→ {dst}  ({os.path.getsize(dst) // 1024} KB)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
