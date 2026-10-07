#!/usr/bin/env python3
"""游戏设置（設定屏）的数据：选项表 + 显示顺序。

出处：
* `struct GameOption`（`include/uiconfig.h:13-19`）：
       /* 00 */ u16 msgId;                    ← 选项名（文本 id）
       /* 04 */ struct Selector selectors[4];  ← 每个取值一个：helpTextId/optionTextId/xPos/unk_05
       /* 24 */ u8 icon;
       /* 28 */ bool (*func)(ProcPtr);        ← **改值的处理函数**（语义在这）
  共 **44 字节**。
* 表定义：`src/data/gGameOptions_ref/dat_gGameOptions_ref.s`（de-pointerize 后的裸 `.4byte`，
  `func` 保留为**符号名** —— 所以语义可解）。
* 显示顺序 `gGameOptionsUiOrder[13]`：`src/data/data_08AAF6DC/data_08AAF6DC.c` 的
  **前 13 个字节**（`u32[]` 里读出来是 `00 05 04 01 02 0A 0E 0B 03 0C 06 07 08`）。
* 消费方：`src/Config_Loop_KeyHandler.c:30-120`（上下移动 / 左右改值 / B 关）、
  `src/uiconfig_080B6404.c:46`（名字 = `GetStringFromIndex(gGameOptions[order[i]].msgId)`）、
  `src/Config_Init.c:44`（`maxOption = ARRAY_COUNT(gGameOptionsUiOrder)`）。

判据（正向抽查真值 + 字节严丝合缝）：
* 字数 **187** = 17 项 × 11 字（44 B / 4）—— 解完必须**正好用完**，不能多也不能少；
* `options[0].msgId == 9`；
* `uiOrder == [0,5,4,1,2,10,14,11,3,12,6,7,8]`（13 个、互不重复）；
* 每项至少有一个 selector（有取值可选）。

⚠️ 未查证 / 不在这里的：各 `func` **具体怎么改值**（那是 C 代码，不是数据）；
`GAME_OPTION_ANIMATION`（A 键的动画预览特例）等枚举名到下标的映射。
"""
import argparse
import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
DECOMP = os.path.normpath(os.path.join(HERE, "..", "..", "..", "third_party", "fireemblem8j"))

WORDS_PER_OPTION = 11  # 44 B


def read(p):
    return open(p, encoding="utf-8", errors="replace").read()


def parse_options():
    p = os.path.join(DECOMP, "src", "data", "gGameOptions_ref", "dat_gGameOptions_ref.s")
    words = []
    for line in read(p).split("\n"):
        m = re.match(r"\s*\.4byte\s+(.+?)\s*$", line)
        if not m:
            continue
        tok = m.group(1).strip()
        if tok.startswith("0x"):
            words.append(int(tok, 16))
        else:
            words.append(tok)  # 符号（func / 别的东西）——保留原样
    if len(words) % WORDS_PER_OPTION != 0:
        print(f"❌ 字数 {len(words)} 不是 {WORDS_PER_OPTION} 的整数倍", file=sys.stderr)
        return None, None
    opts = []
    for i in range(0, len(words), WORDS_PER_OPTION):
        w = words[i:i + WORDS_PER_OPTION]
        sels = []
        for k in range(4):
            a, b = w[1 + 2 * k], w[2 + 2 * k]
            if not isinstance(a, int) or not isinstance(b, int):
                continue
            help_id = a & 0xFFFF
            opt_id = (a >> 16) & 0xFFFF
            xpos = b & 0xFF
            unk = (b >> 8) & 0xFF
            if help_id == 0 and opt_id == 0:
                continue
            sels.append({"helpTextId": help_id, "optionTextId": opt_id,
                         "xPos": xpos, "unk_05": unk})
        opts.append({
            "msgId": w[0] & 0xFFFF if isinstance(w[0], int) else w[0],
            "selectors": sels,
            "icon": w[9] & 0xFF if isinstance(w[9], int) else w[9],
            "func": w[10] if isinstance(w[10], str) else hex(w[10]),
        })
    return opts, len(words)


def parse_ui_order():
    p = os.path.join(DECOMP, "src", "data", "data_08AAF6DC", "data_08AAF6DC.c")
    body = re.search(r"u32 \w+\[\][^{]*\{(.*?)\};", read(p), re.S).group(1)
    raw = []
    for m in re.finditer(r"0x([0-9A-Fa-f]{8})", body):
        v = int(m.group(1), 16)
        raw += [v & 0xFF, (v >> 8) & 0xFF, (v >> 16) & 0xFF, (v >> 24) & 0xFF]
    return raw[:13]


def parse_enum():
    """`GAME_OPTION_X = N`（`include/uiconfig.h:53+`）—— **枚举值就是 `gGameOptions` 的下标**"""
    txt = read(os.path.join(DECOMP, "include", "uiconfig.h"))
    out = {}
    for m in re.finditer(r"(GAME_OPTION_[A-Z_0-9]+)\s*=\s*(\d+)", txt):
        out[m.group(1)] = int(m.group(2))
    return out


def parse_mapping():
    """`GAME_OPTION_X → gPlaySt.config.<字段>`（`src/uiconfig.c:45+` 的 `GetGameOption` switch）"""
    txt = read(os.path.join(DECOMP, "src", "uiconfig.c"))
    out = {}
    for m in re.finditer(
            r"case (GAME_OPTION_[A-Z_0-9]+):\s*\n\s*value = gPlaySt\.config\.(\w+);", txt):
        out[m.group(1)] = m.group(2)
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", default=os.path.join(HERE, "..", "out", "tables"))
    a = ap.parse_args()

    opts, nwords = parse_options()
    if opts is None:
        return 1
    order = parse_ui_order()
    enum = parse_enum()
    mapping = parse_mapping()
    # 选项表下标 = 枚举值 ⇒ 把"表下标 → 配置字段"接起来
    byIndex = {}
    for name, idx in enum.items():
        if name in mapping:
            byIndex[idx] = {"enum": name, "field": mapping[name]}

    # ---- 判据 ----
    if nwords != 187:
        print(f"❌ 字数 {nwords} != 187（17 项 × 11 字）", file=sys.stderr)
        return 1
    if len(opts) != 17:
        print(f"❌ 选项数 {len(opts)} != 17", file=sys.stderr)
        return 1
    if opts[0]["msgId"] != 9:
        print(f"❌ options[0].msgId = {opts[0]['msgId']}（应为 9）", file=sys.stderr)
        return 1
    # ---- 映射的正向抽查（有出处）----
    # `include/uiconfig.h:53`：`GAME_OPTION_ANIMATION = 0`
    # `src/uiconfig.c`：`case GAME_OPTION_AUTOEND_TURNS: value = gPlaySt.config.disableAutoEndTurns;`
    if enum.get("GAME_OPTION_ANIMATION") != 0:
        print(f"❌ GAME_OPTION_ANIMATION = {enum.get('GAME_OPTION_ANIMATION')}（应为 0）",
              file=sys.stderr)
        return 1
    autoend = [v for v in byIndex.values() if v["field"] == "disableAutoEndTurns"]
    if not autoend or autoend[0]["enum"] != "GAME_OPTION_AUTOEND_TURNS":
        print(f"❌ 自动结束回合那一项没解对：{autoend}", file=sys.stderr)
        return 1
    if len(byIndex) < 12:
        print(f"❌ 只解出 {len(byIndex)} 条 选项→配置字段 映射（太少，解析可能漏了）",
              file=sys.stderr)
        return 1
    if order != [0, 5, 4, 1, 2, 10, 14, 11, 3, 12, 6, 7, 8]:
        print(f"❌ uiOrder = {order}", file=sys.stderr)
        return 1
    if len(set(order)) != 13:
        print(f"❌ uiOrder 里有重复：{order}", file=sys.stderr)
        return 1
    no_sel = [i for i, o in enumerate(opts) if not o["selectors"]]
    if no_sel:
        print(f"❌ 这些选项一个取值都没有：{no_sel}", file=sys.stderr)
        return 1
    funcs = sorted({o["func"] for o in opts if o["func"]})
    print(f"  ✓ {len(opts)} 项 / {nwords} 字（44 B/项）；uiOrder 13 个互不重复；"
          f"func 名 {len(funcs)} 种")
    print(f"  ✓ 选项→配置字段映射 {len(byIndex)} 条；"
          f"AUTOEND_TURNS(idx {enum.get('GAME_OPTION_AUTOEND_TURNS')}) → "
          f"config.{mapping.get('GAME_OPTION_AUTOEND_TURNS')}")

    os.makedirs(a.out, exist_ok=True)
    dst = os.path.join(a.out, "game_options.json")
    with open(dst, "w", encoding="utf-8") as f:
        json.dump({"options": opts, "uiOrder": order,
                   "optionEnum": enum, "optionToConfigField": byIndex,
                   "note": "msgId 是**文本 id**（选项名），selector.optionTextId 是取值标签的文本 id；"
                           "func 是改值处理函数的名字（具体怎么改在 C 代码里，未移植）。"},
                  f, ensure_ascii=False, indent=1)
    print(f"→ {dst}  ({os.path.getsize(dst) // 1024} KB)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
