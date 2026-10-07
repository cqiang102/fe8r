#!/usr/bin/env python3
"""
把 `.s` 里裸字节的**事件脚本**解成宏形式的文本。

## 为什么需要

`gen_scene_dart.py` 只解析 C 的宏形式：

    CONST_DATA EventListScr EventScr_X[] = { LOAD1(1, UnitDef_Y) ENUN ... };

但有 **41 个脚本**在日版仓库里**只以裸 `.4byte` 存在**，例如
`EventScr_Prologue_ONeillSpawn`（`src/data/data_08A611DC/data_08A611DC.s:6`）：

    EventScr_Prologue_ONeillSpawn:
        .4byte 0x00012C40
        .4byte UnitDef_Event_PrologueEnemy
        .4byte 0x00003020
        ...

**后果（实测）**：序章地图上永远没有敌人 —— 因为放敌人的正是
`ONeillSpawn`（`LOAD1(1, UnitDef_Event_PrologueEnemy)`），
于是打不到奥尼尔，胜负条件永不满足，**到不了第 1 章**。

## 命令字的位域（`include/eventscript.h:570-576`）

    bit  0..3   sub
    bit  4..7   len      <- ★ **参数字节数**；步进 = len / 2 个字
    bit  8..15  cmd
    bit 16..31  arg0

⚠️ 两个踩过的坑：
* 我以为 `len` 是**字数** -> 走错（LOADUNIT 吞掉了后两条命令）
* **指针占一个字宽，但不算命令字**

## 判据

**字节数严丝合缝**：解完必须正好走到末尾。
（`EventScr_Prologue_ONeillSpawn` 是 12 条命令 / 13 个字，实测吻合。）
"""
import argparse
import glob
import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
REPO = os.path.abspath(os.path.join(HERE, "..", "..", ".."))
DECOMP = os.path.join(REPO, "third_party", "fireemblem8j")

from event_opcodes import decode_word, OPCODES  # noqa: E402

LABEL = re.compile(r"^(EventScr_\w+):\s*$")


def load_macros():
    p = os.path.join(HERE, "..", "out", "tables", "event_macros.json")
    if not os.path.exists(p):
        return {}
    d = json.load(open(p, encoding="utf-8"))
    out = {}
    for k, v in d["byCmdSub"].items():
        c, s = k.split(":")
        out[(int(c), int(s))] = v[0]
    return out


def parse_file(path):
    """`{脚本名: (字节值列表, {字下标: 符号名})}`"""
    out = {}
    cur, words, syms = None, [], {}
    for line in open(path, encoding="utf-8", errors="replace"):
        m = LABEL.match(line)
        if m:
            if cur:
                out[cur] = (words, syms)
            cur, words, syms = m.group(1), [], {}
            continue
        if cur is None:
            continue
        if line.startswith("\t.section") or line.startswith(".section"):
            out[cur] = (words, syms)
            cur, words, syms = None, [], {}
            continue
        mw = re.match(r"^\s*\.4byte\s+(.+?)\s*$", line)
        if mw:
            for tok in mw.group(1).split(","):
                tok = tok.strip()
                if tok.startswith("0x"):
                    v = int(tok, 16)
                else:
                    v, syms[len(words)] = 0, tok
                words.append(v)
    if cur:
        out[cur] = (words, syms)
    return out


def to_macro(words, syms, macros):
    """解成宏形式的行。返回 `(行列表, 是否严丝合缝)`"""
    lines = []
    i = 0
    while i < len(words):
        w = words[i]
        cmd, name, ln, sub, arg = decode_word(w)
        step = max(1, ln // 2)
        m = macros.get((cmd, sub))
        if m:
            params = m["params"]
            if m.get("packed") == "u8pair":
                # `_EvtSubParam16u8((a), (b))`：**两个参数来自同一个字** ——
                # 低字节是 a、高字节是 b（`include/eventscript.h:563`）。
                #
                # 例：`CAMERA(x, y)` → `EvtMoveCameraTo`。
                # 不拆的话参数个数对不上，生成器只能记成占位符。
                lo = arg & 0xFF
                hi = (arg >> 8) & 0xFF
                # 有符号：`Event26_CameraControl` 里 x/y 是 `s8`，
                # 负值表示"用槽 0xB"（见那里 `if (x < 0 || y < 0)`）
                if lo >= 0x80:
                    lo -= 0x100
                if hi >= 0x80:
                    hi -= 0x100
                lines.append(f"{m['macro']}({lo}, {hi})")
            elif params:
                # 第一个参数取 arg0；多参数时后面的来自紧随的指针字
                args = [str(arg)]
                for k in range(1, len(params)):
                    j = i + k
                    if j < len(words):
                        args.append(syms.get(j, hex(words[j])))
                lines.append(f"{m['macro']}({', '.join(args)})")
            else:
                lines.append(m["macro"])
        else:
            lines.append(f"{name}({arg})")
        i += step
    return lines, i == len(words)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", default=os.path.join(HERE, "..", "out", "tables"))
    a = ap.parse_args()

    macros = load_macros()
    print(f"  宏表 {len(macros)} 条")

    files = sorted(glob.glob(
        os.path.join(DECOMP, "src", "data", "**", "*.s"), recursive=True))
    scripts, bad = {}, 0
    for f in files:
        for name, (words, syms) in parse_file(f).items():
            if name in scripts or not words:
                continue
            lines, ok = to_macro(words, syms, macros)
            if not ok:
                bad += 1
                continue          # ★ 对不上就不收 —— 不假装成功
            scripts[name] = lines

    print(f"  解出 {len(scripts)} 个脚本（{bad} 个字节数对不上，已丢弃）")
    for n in ("EventScr_Prologue_ONeillSpawn",):
        if n in scripts:
            print(f"    {n}: {scripts[n]}")

    os.makedirs(a.out, exist_ok=True)
    dst = os.path.join(a.out, "event_scripts_asm.json")
    with open(dst, "w", encoding="utf-8") as f:
        json.dump({
            "source": "src/data/**/*.s",
            "note": "裸字节事件脚本解成宏形式；字节数对不上的已丢弃",
            "scripts": scripts,
        }, f, ensure_ascii=False, indent=1)
    print(f"→ {dst}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
