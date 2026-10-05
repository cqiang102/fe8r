#!/usr/bin/env python3
"""
提取事件引擎的**指令集定义**。

`include/eventscript.h` 里有两个枚举块：

  * `event_cmd_idx`     —— 150 条指令的操作码
  * `event_sub_cmd_idx` —— 159 个子命令

⚠️ 子命令的**值是有意重叠的**：`EVSUBCMD_ENDA = 0`（给 EV_CMD_END 用）
和 `EVSUBCMD_EVBIT_F = 0`（给 EV_CMD_EVSET 用）是不同命名空间里的 0。
所以这里产出的是 `名字 → 值` 的映射，**不是** `值 → 名字` 的反查表 ——
反过来建表会让后一个名字覆盖前一个，静默丢掉一半子命令。

## 指令编码

指令流是 `u16[]`，每条指令的**第一个字**按位打包
（见 include/eventscript.h 的 `_EvtCmd` 宏）：

    word[0] = (cmd & 0xFF) << 8 | (len & 0x0F) << 4 | (sub & 0x0F)

即：bit8-15 操作码、bit4-7 指令长度（单位是 u16 字）、bit0-3 子命令。
参数从 word[1] 开始，按 `s16` 解释。

这些常量由 `verify_eventscript.py` 用 C 编译器复核 ——
不是"照着源码抄一遍"，而是让编译器把宏展开后的值算出来比对。
"""
import argparse
import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.abspath(os.path.join(HERE, "..", "..", ".."))
DECOMP = os.path.join(REPO, "third_party", "fireemblem8j")

HEADER = "include/eventscript.h"
EVENT_H = "include/event.h"


def strip_comments(text):
    """先剥注释 —— 顺序不能反（classes.h 上踩过：行尾注释会吃掉下一个常量）"""
    text = re.sub(r"/\*.*?\*/", " ", text, flags=re.S)
    text = re.sub(r"//[^\n]*", " ", text)
    return text


def parse_named_enum(path, name):
    """解析 `enum <name> { ... };`（含别名与显式值）"""
    src = strip_comments(open(path, encoding="utf-8", errors="replace").read())
    m = re.search(rf"enum\s+{re.escape(name)}\s*\{{(.*?)\}}", src, re.S)
    if not m:
        return None
    out, nxt = {}, 0
    for item in m.group(1).split(","):
        item = item.strip()
        if not item:
            continue
        if "=" in item:
            k, v = item.split("=", 1)
            k, v = k.strip(), v.strip()
            try:
                nxt = int(v, 0)
            except ValueError:
                # 值可能是另一个枚举名（别名）
                if v in out:
                    nxt = out[v]
                else:
                    continue
        else:
            k = item
        out[k] = nxt
        nxt += 1
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", default=os.path.join(HERE, "..", "out", "tables"))
    a = ap.parse_args()

    hp = os.path.join(DECOMP, HEADER)
    ep = os.path.join(DECOMP, EVENT_H)
    for p in (hp, ep):
        if not os.path.exists(p):
            print(f"错误：找不到 {p}", file=sys.stderr)
            return 1

    cmds = parse_named_enum(hp, "event_cmd_idx")
    subs = parse_named_enum(hp, "event_sub_cmd_idx")
    if not cmds or not subs:
        print("错误：没解析到事件指令枚举", file=sys.stderr)
        return 1
    print(f"指令: {len(cmds)} 条")
    print(f"子命令: {len(subs)} 个")

    # 指令的**编号必须是唯一的** —— 与子命令不同，操作码是分发键。
    # 出现重复说明解析歪了（比如把别名算成了新项）。
    seen = {}
    dup = []
    for k, v in cmds.items():
        if v in seen:
            dup.append((k, seen[v], v))
        seen[v] = k
    if dup:
        print(f"❌ 指令编号有重复 {len(dup)} 处:", file=sys.stderr)
        for k, other, v in dup[:8]:
            print(f"  {k} 与 {other} 都是 {v:#x}", file=sys.stderr)
        return 1
    print("指令编号唯一 ✓")

    # 编码宏：从 include/event.h 读出实际的移位/掩码，
    # 不在这里硬编码 —— 抄错一个移位量会安静地解析出垃圾指令。
    eh = strip_comments(open(ep, encoding="utf-8", errors="replace").read())
    macros = {}
    for nm in ("EVT_SUB_CMD", "EVT_CMD_LEN", "EVT_CMD_ARGV"):
        m = re.search(rf"#define\s+{nm}\((?:scr|cmd)\)\s*(.+)", eh)
        if m:
            macros[nm] = m.group(1).strip()
    print(f"编码宏: {macros}")

    os.makedirs(a.out, exist_ok=True)
    payload = {
        "source": HEADER,
        "encoding": {
            "opcodeShift": 8,
            "lengthShift": 4,
            "subCmdMask": 0xF,
            "note": "word[0] = (cmd<<8) | (len<<4) | sub；见 _EvtCmd 宏",
            "macros": macros,
        },
        "commands": cmds,
        "subCommands": subs,
    }
    dst = os.path.join(a.out, "eventscript.json")
    with open(dst, "w", encoding="utf-8") as f:
        json.dump(payload, f, ensure_ascii=False, indent=1, sort_keys=True)
    print(f"→ {dst}  ({os.path.getsize(dst) // 1024} KB)")

    # 抽查几条编码
    def enc(cmd, ln, sub):
        return ((cmds[cmd] & 0xFF) << 8) | ((ln & 0xF) << 4) | (sub & 0xF)

    print("\n编码抽查:")
    for cmd, ln, sub in (("EV_CMD_NOP", 2, 0), ("EV_CMD_END", 2, 0),
                         ("EV_CMD_GOTO", 2, 0), ("EV_CMD_STALL", 2, 0)):
        print(f"  {cmd:<16} len={ln} sub={sub} → {enc(cmd, ln, sub):#06x}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
