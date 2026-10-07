#!/usr/bin/env python3
"""
从 `include/eventscript.h` + `include/EAstdlib.h` 抽出 **操作码 → 宏名** 的映射。

## 为什么自动抽而不是手写

宏定义本身就是权威映射：

    #define EvtLoadUnit1(restriction, units) \
        _EvtArg0(EV_CMD_LOADUNIT, 4, EVSUBCMD_LOAD1, (restriction)), (EventListScr)(units),
    #define EvtSleep(time)   _EvtArg0(EV_CMD_STALL, 2, EVSUBCMD_STAL, (time)),
    #define EvtStartBgm(bgm) _EvtArg0(EV_CMD_BGMCHANGE_12, 2, 0, (bgm)),
    #define EvtTextShow(msg) _EvtArg0(EV_CMD_DISPLAYTEXT, 2, EVSUBCMD_TEXTSHOW, (msg)),

手写会漏、会过时；自动抽和我解码 `.s` 用的是**同一份真相**。

## 还要处理别名

    #define LOAD1 EvtLoadUnit1        （EAstdlib.h）
    #define STAL  EvtSleep

所以最后产出的是**别名优先**的名字（`LOAD1` 而不是 `EvtLoadUnit1`），
这样解出来的文本和现有 `.c` 源里的写法**一致**，
生成器可以走同一条路。

## 参数个数

`_EvtArg0(..., (arg))` 只有一个 16 位参数，但宏可能有更多个
（如 `EvtLoadUnit1(restriction, units)` 的 `units` 是**紧跟在后面的表指针**）。
所以每个条目还记 `extraWords`：命令字之后还要跟几个**指针字**。

## 还有第三种形状：**两个 u8 打包进一个参数**

    #define EvtMoveCameraTo(x, y) \
        _EvtArg0(EV_CMD_CAMERACONTROL, 2, EVSUBCMD_CAMERA_AT, _EvtSubParam16u8((x), (y))),
    #define _EvtSubParam16u8(a, b) (((a) & 0xFF) + ((b & 0xFF) << 8))

`CAMERA(x, y)` 就是它。原来的正则要求参数是 `(...)`（不含内层括号），
所以**整条被漏掉** —— `CAMERA` 一直是占位符，王座厅那一幕的取景因此停在地图中央。

这类条目标 `packed: "u8pair"`：解出来的时候要把那一个字拆成低字节/高字节两个参数。
"""
import argparse
import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.abspath(os.path.join(HERE, "..", "..", ".."))
DECOMP = os.path.join(REPO, "third_party", "fireemblem8j")


def read(p):
    return open(p, encoding="utf-8", errors="replace").read()


def enum_values(text):
    """把 `EV_CMD_X = 0xNN,` 与 `EVSUBCMD_X = 0xN,` 抽成字典"""
    out = {}
    for m in re.finditer(r"(EV_?[A-Z_0-9]+)\s*=\s*(0x[0-9A-Fa-f]+|\d+)", text):
        v = int(m.group(2), 16) if m.group(2).startswith("0x") else int(m.group(2))
        out[m.group(1)] = v
    return out


def val(tok, consts):
    tok = tok.strip()
    m = re.fullmatch(r"\(?(EV_?[A-Z_0-9]+)\)?", tok)
    if m and m.group(1) in consts:
        return consts[m.group(1)]
    if tok.startswith("0x"):
        return int(tok, 16)
    if tok.isdigit():
        return int(tok)
    return None


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", default=os.path.join(HERE, "..", "out", "tables"))
    a = ap.parse_args()

    es = read(os.path.join(DECOMP, "include", "eventscript.h"))
    ea = read(os.path.join(DECOMP, "include", "EAstdlib.h"))
    consts = enum_values(es)

    # ---- 1) 抽所有 `_EvtArg0(cmd, len, sub, (arg))` 形式的宏 ----
    entries = {}
    # 宏体可能跨行
    body = re.sub(r"\\\s*\n", " ", es)
    # ⚠️ 两处放宽（原来各漏掉一整批宏）：
    #   1. **无参数宏**：`#define EvtGetCurrentTurn _EvtArg0(...)`（`include/eventscript.h:645`）
    #      —— 原来要求 `(\w+)\s*\(…\)`，无参数宏一条都收不到；
    #   2. 第 4 个参数不一定是 `(arg)`：`EvtDecCounter(idx)` 的末参是
    #      `_EvtSubParam16u8((idx), 0)`，走 pass 2（那条也在本轮修了）。
    for m in re.finditer(
            r"#define\s+(\w+)\s*(?:\(([^)]*)\))?\s*"
            r"_EvtArg0\(\s*([A-Z_0-9]+)\s*,\s*([^,]+),\s*([^,]+),\s*"
            r"(?:\(([^)]*)\)|(\w+))\s*\)"
            r"(.*)$", body, re.M):
        name, params, cmd, ln, sub, arg, arg_bare, rest = m.groups()
        params = params or ""
        arg = arg if arg is not None else (arg_bare or "")
        c = consts.get(cmd)
        if c is None:
            continue
        s_ = val(sub, consts) or 0
        l_ = val(ln, consts) or 2
        # 命令字之后还有几个指针字？数 `(EventListScr)` 转换
        extra = rest.count("EventListScr")
        entries.setdefault((c, s_), []).append({
            "macro": name,
            "params": [p.strip() for p in params.split(",") if p.strip()],
            "arg": arg.strip(),
            "extraWords": extra,
            "extraParamWords": rest.count("_EvtParams2("),
            "len": l_,
        })

    # ---- 2) `_EvtSubParam16u8((a), (b))` 形式：两个 u8 打包进一个参数 ----
    #
    # 出处：`include/eventscript.h:563`
    #
    #     #define _EvtSubParam16u8(u8a, u8b) (((u8a) & 0xFF) + ((u8b & 0xFF) << 8))
    #
    # 例：`EvtMoveCameraTo(x, y)`（= `CAMERA(x, y)`）。
    # 解出来的两个参数**都来自同一个字**（低字节 x、高字节 y），
    # 所以标 `packed: u8pair`，由解码端拆 —— 见 parse_event_scripts_asm.py。
    for m in re.finditer(
            # 两个放宽（原来各漏掉一整批宏）：
            #   1. **无参数宏**（`#define EvtGetCurrentTurn _EvtArg0(...)`，`eventscript.h:645`）
            #   2. `_EvtSubParam16u8` 的**第 2 个参数可以是裸值**：
            #      `EvtDecCounter(idx) _EvtArg0(EV_CMD_COUNTER, 2, EVSUBCMD_COUNTER_DEC,
            #       _EvtSubParam16u8((idx), 0))`（`:627`）——
            #      原来要求两个参数都带括号，于是 COUNTER_DEC 整条收不到。
            r"#define\s+(\w+)\s*(?:\(([^)]*)\))?\s*"
            r"_EvtArg0\(\s*([A-Z_0-9]+)\s*,\s*([^,]+),\s*([^,]+),\s*"
            # ⚠️ 两个参数**都不一定带括号**：
            #   `_EvtSubParam16u8((idx), 0)`（`EvtDecCounter`，`:627`）
            #   `_EvtSubParam16u8(form, to)`（`EvtColorFadeSetup`，`:641`）
            r"_EvtSubParam16u8\(\s*\(?([^),]*)\)?\s*,\s*\(?([^),]*)\)?\s*\)"
            r"\s*\)(.*)$", body, re.M):
        name, params, cmd, ln, sub, _pa, _pb, rest = m.groups()
        params = params or ""
        c = consts.get(cmd)
        if c is None:
            continue
        s_ = val(sub, consts) or 0
        l_ = val(ln, consts) or 2
        # 两个参数的名字来自 `_EvtSubParam16u8((a), (b))`，
        # 而不是宏自己的参数表（宏的参数表里是 (x, y)，这里 (a, b) 就是它们）
        entries.setdefault((c, s_), []).append({
            "macro": name,
            "params": [p.strip() for p in params.split(",") if p.strip()],
            "arg": "u8pair",
            "packed": "u8pair",
            "extraWords": rest.count("EventListScr"),
            "extraParamWords": rest.count("_EvtParams2("),
            "len": l_,
        })

    # ---- 1b) `_EvtAutoCmdLenN(cmd)` 形式 ----
    #
    # 出处：`include/eventscript.h:577-578`
    #     #define _EvtAutoCmdLen2(cmd) _EvtArg0(cmd, 2, 0, 0)
    #     #define _EvtAutoCmdLen4(cmd) _EvtArg0(cmd, 4, 0, 0)
    # ⇒ 等价于 `_EvtArg0(cmd, N, 0, 0)`：**无 sub、无参数**。
    # 例：`EvtWaitUnitMoving`（`ENUN`）= `_EvtAutoCmdLen2(EV_CMD_ENUN),`
    #（`include/eventscript.h`）—— 上一轮只做 `_EvtArg0` 形式，这一批全漏。
    for m in re.finditer(
            r"#define\s+(\w+)\s*(?:\(([^)]*)\))?\s*"
            r"_EvtAutoCmdLen(\d)\(\s*([A-Z_0-9]+)\s*\)(.*)$", body, re.M):
        name, params, n, cmd, rest = m.groups()
        c = consts.get(cmd)
        if c is None:
            continue
        entries.setdefault((c, 0), []).append({
            "macro": name,
            "params": [x.strip() for x in (params or "").split(",") if x.strip()],
            "arg": "",
            "extraWords": rest.count("EventListScr"),
            "extraParamWords": rest.count("_EvtParams2("),
            "len": int(n),
        })

    # ---- 2b) `_EvtSubParam16u4(a, b, c, d)`：**四个 nibble** 打包进一个字 ----
    #
    # 例：`EvtSlotAND(to, a, b)` = `_EvtArg0(EV_CMD_SLOT_OPS, 2, EVSUBCMD_SAND,
    #     _EvtSubParam16u4(to, a, b, 0))`（`SAND`）—— 原来只做 `_EvtSubParam16u8`。
    for m in re.finditer(
            r"#define\s+(\w+)\s*\(([^)]*)\)\s*"
            r"_EvtArg0\(\s*([A-Z_0-9]+)\s*,\s*([^,]+),\s*([^,]+),\s*"
            r"_EvtSubParam16u4\(([^)]*)\)\s*\)(.*)$", body, re.M):
        name, params, cmd, ln, sub, quad, rest = m.groups()
        c = consts.get(cmd)
        if c is None:
            continue
        entries.setdefault((c, val(sub, consts) or 0), []).append({
            "macro": name,
            "params": [x.strip() for x in params.split(",") if x.strip()],
            "arg": "u4quad",
            "packed": "u4quad",
            "extraWords": rest.count("EventListScr"),
            "extraParamWords": rest.count("_EvtParams2("),
            "len": val(ln, consts) or 2,
        })

    # ---- 3) 别名（`#define LOAD1 EvtLoadUnit1`）----
    alias_to = {}
    # ⚠️ 别名**成链**，中间那几步在 `eventscript.h` 里（不在 EAstdlib 里）：
    #     TUTORIALTEXTBOXSTART → EvtTextTutorialStart → EvtTextStartType3 → …
    # 所以两个头都要扫；**EAstdlib 放后面**（它的名字是用户面向的、要用它当最终名）。
    for src in (es, ea):
        # 普通别名 `#define A B`
        # ⚠️ 别名名可以是**混合大小写**（链中间那步 `EvtTextTutorialStart`，
        # `include/eventscript.h:659`）—— 原来要求全大写，链就断在这里。
        for m in re.finditer(r"^#define\s+([A-Za-z_]\w*)\s+(\w+)\s*$", src, re.M):
            alias_to[m.group(2)] = m.group(1)
        # ★ **带参数的别名**：`#define CUSA(pid) EvtChangeFaction(pid, FACTION_ID_BLUE)`
        #（`include/EAstdlib.h:139`）—— 原来只认"无参数别名"，这条漏了。
        for m in re.finditer(
                r"^#define\s+([A-Z][A-Z0-9_]*)\s*\([^)]*\)\s+(\w+)\s*\(", src, re.M):
            alias_to[m.group(2)] = m.group(1)

    # ---- 4) 别名优先（**要走到不动点**：别名可以成链）----
    #
    # 例：`TUTORIALTEXTBOXSTART` → `EvtTextTutorialStart` → `EvtTextStartType3`
    #（`include/eventscript.h:659`）—— 只换一次名字的话，外层别名就查不到字数。
    for k, lst in entries.items():
        for e in lst:
            e["aliasOf"] = e["macro"]      # 改名前（规范名）—— 下游两种名字都可能遇到
            seen = set()
            while e["macro"] in alias_to and e["macro"] not in seen:
                seen.add(e["macro"])
                e["macro"] = alias_to[e["macro"]]

    # ★ **按名字查字数**的表：原名与别名都收。
    #
    # 为什么需要：`.c` 数据里**两种名字都在用** —— blob 数组里既有 `EvtColorFadeSetup`
    # （规范名）也有 `ENDA`/`CUSA`（别名）。只给一个名字的话，另一种就"字数未知"，
    # 整块切分被放弃（我为此白跑了两轮：先改名丢了规范名，再反向丢别名）。
    words_by_name = {}
    for lst in entries.values():
        for e in lst:
            # ★ **总字数 = `len`/2 + `extraWords`**。
            # `len` 只数 `_EvtArg0(cmd, len, sub, arg)` 那几个字；
            # 而宏体后面可能还挂着额外的字，例如
            #   `EvtColorFadeSetup(...) _EvtArg0(EV_CMD_COLORFADE, 6, EVSUBCMD_FADECOLORS,
            #    _EvtSubParam16u8(form, to)), _EvtParams2(speed, r), _EvtParams2(g, b),`
            #（`include/eventscript.h:641`）—— 两个 `_EvtParams2` 各占一个字。
            # 漏了它们 ⇒ 后面所有条目的位置整体前移 ⇒ "偏移不在宏边界上"。
            # ⚠️ `len` **已经包含**宏体里 `(EventListScr)(ptr)` 那类指针字
            #（证：`.s` 全语料 116 个脚本按 `len // 2` 解码**零失败**）。
            # 真正在 `len` 之外、要另加的只有 `_EvtParams2(...)`：
            #   `EvtColorFadeSetup(...) = _EvtArg0(..., 6, ...), _EvtParams2(speed, r),
            #    _EvtParams2(g, b)`（`include/eventscript.h:641`）
            # 我先前把 `extraWords`（数 `EventListScr`）也加上 ⇒ 重复计数、切分反而变差。
            # ★ `len` **就是这条命令的总半字数**（`_EvtArg0` 只出 1 个字，
            # `_EvtParams2` 各出 1 个字，它们的和就是 `len//2`）：
            #   `EvtBNE`   = `_EvtArg0(..., 4, ...), _EvtParams2(...)`  ⇒ 1+1 = 2 字，len 4 ✓
            #   `EvtColorFadeSetup` = `_EvtArg0(..., 6, ...), _EvtParams2, _EvtParams2`
            #                        ⇒ 1+1+1 = **3 字**，len 6 ✓
            # 实证：ch_016 的引用偏移 3/9/15 只有在"EVENT_WORD=1、BNE=2"下才全部落在边界上。
            # 我上一轮额外加了 `extraParamWords` ⇒ **重复计数**（BNE 被算成 3 字）。
            w = max(1, e["len"] // 2)
            words_by_name[e["macro"]] = w
            if e.get("aliasOf"):
                words_by_name[e["aliasOf"]] = w

    # ★ 别名指向"表里已知的宏"时，把字数也挂到别名上（可传递）。
    # 例：`#define SPAWN_ENEMY(pid, x, y) EvtLoadSingleUnit(FACTION_ID_RED, pid, x, y)`
    #（`include/EAstdlib.h:153`）—— blob 数据里写的是 `SPAWN_ENEMY`。
    for _ in range(4):
        for canon, al in alias_to.items():
            if canon in words_by_name and al not in words_by_name:
                words_by_name[al] = words_by_name[canon]

    if not entries:
        print("  ✗ 一个宏都没抽到", file=sys.stderr)
        return 1

    os.makedirs(a.out, exist_ok=True)
    dst = os.path.join(a.out, "event_macros.json")
    with open(dst, "w", encoding="utf-8") as f:
        json.dump({
            "source": "include/eventscript.h + include/EAstdlib.h",
            "note": "操作码 (cmd, sub) -> 宏名 + 参数",
            "byCmdSub": {f"{c}:{s}": v for (c, s), v in entries.items()},
            "wordsByName": words_by_name,
        }, f, ensure_ascii=False, indent=1)

    print(f"  抽出 {len(entries)} 个 (cmd, sub) 组合")
    for key in ("44:0", "48:0", "59:1", "18:0", "27:0"):
        v = entries.get(tuple(int(x) for x in key.split(":")))
        if v:
            print(f"    cmd/sub {key} -> {v[0]['macro']}"
                  f"({', '.join(v[0]['params'])})")
    print(f"→ {dst}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
