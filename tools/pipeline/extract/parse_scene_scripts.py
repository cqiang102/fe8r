#!/usr/bin/env python3
"""
从**源码**解析场景剧情脚本（`EventScr_*`）。

## 为什么不再走"编译成字节"

前面绕了三轮：编译 → 指针槽是宿主地址 → 造工具把地址还原成符号名。
**而名字本来就明明白白写在源码里：**

    EventListScr EventScr_Prologue_BeginningScene[] = {
        CALL(EventScr_Prologue_RenaisThroneCutscene)
        SVAL(EVT_SLOT_2, EventScr_Prologue_EirikaAttacked)
        ENUT(8)
        LOAD1(1, UnitDef_Event_PrologueAlly)
        TEXTSTART
        TEXTSHOW(0x8CE)
        TEXTEND
        ...
    }

**每行就是一条指令**（宏之间没有逗号 —— 逗号是宏展开带出来的，
所以"按逗号切元素"会失败；但**按行切**不会）。

## 关键简化：不还原 GBA 的打包字

原版把指令打包成 `word[0] = (cmd<<8)|(len<<4)|sub`，参数按 `s16` 读 ——
那是 **GBA 的实现细节**。

既然虚拟机用 Dart 写，它的输入就该是**它真正需要的东西**：

    (指令名, 参数列表)

    {"op": "CALL",  "args": [{"sym": "EventScr_Prologue_RenaisThroneCutscene"}]}
    {"op": "TEXTSHOW", "args": [2318]}
    {"op": "SVAL",  "args": [{"sym": "EVT_SLOT_2"}, {"sym": "EventScr_..."}]}

参数分三类：
  * **整数**  `ENUT(8)` → `8`
  * **符号引用**  `CALL(X)` / `LOAD1(1, X)` → `{"sym": "X"}`
  * **符号 + 偏移**  `ASMC(X + 0x1)` → `{"sym": "X", "off": 1}`

**没有指针，没有字节序，没有打包。** 符号在 Dart 里就是字符串。

用法:
    python3 tools/pipeline/extract/parse_scene_scripts.py --out out/tables
"""
import argparse
import glob
import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.abspath(os.path.join(HERE, "..", "..", ".."))
DECOMP = os.path.join(REPO, "third_party", "fireemblem8j")

# ⚠️ **不要按文件名猜哪个文件装脚本。**
#
# 第一版只扫 `src/data/EventScr_*`，结果漏掉了
# `EventScr_CallOnTutorialMode` —— 它定义在
# `src/data/worldmap_gmapunit/dat_worldmap_gmapunit_p1542.c`，
# 文件名和 `EventScr_` 毫不相干。
#
# 漏掉它的后果很具体：序章开场第 3 条就 `CALL(EventScr_CallOnTutorialMode)`，
# 于是"序章跑不起来"。**按文件名猜内容，就会漏。**
#
# 所以扫**整个 src/**，靠内容找（正则匹配定义），不靠路径。
SRC_GLOBS = [
    "src/**/*.c",
]

# 一眼是"宏/常量"而不是符号名的写法：全大写 + 下划线
MACRO_NAME = re.compile(r"^[A-Z][A-Z0-9_]*$")


def slot_constants():
    """从 `include/event.h` 读 `EVT_SLOT_*` 枚举 → 整数。

    这些是**常量**，不是符号引用 —— 归到 `int` 那一类。
    从 C 源读而不是手抄：枚举增删时不会静默错位。
    """
    p = os.path.join(DECOMP, "include", "event.h")
    if not os.path.exists(p):
        return {}
    t = strip_comments(open(p, encoding="utf-8", errors="replace").read())
    m = re.search(r"enum\s+EventSlotIdx\s*\{(.*?)\}", t, re.S)
    if not m:
        return {}
    out, val = {}, 0
    for item in m.group(1).split(","):
        item = item.strip()
        if not item:
            continue
        if "=" in item:
            n, v = item.split("=", 1)
            val = int(v.strip(), 0)
            out[n.strip()] = val
        else:
            out[item] = val
        val += 1
    return out


def strip_comments(text):
    text = re.sub(r"/\*.*?\*/", " ", text, flags=re.S)
    return re.sub(r"//[^\n]*", " ", text)


def split_args(s):
    """按**顶层逗号**切参数（括号内的逗号不算）。"""
    out, depth, cur = [], 0, []
    for ch in s:
        if ch in "([":
            depth += 1
            cur.append(ch)
        elif ch in ")]":
            depth -= 1
            cur.append(ch)
        elif ch == "," and depth == 0:
            out.append("".join(cur).strip())
            cur = []
        else:
            cur.append(ch)
    tail = "".join(cur).strip()
    if tail:
        out.append(tail)
    return [a for a in out if a]


SLOTS = slot_constants()


def parse_arg(a):
    """一个参数 → Dart 侧好用的形式。

    返回值是 `int` 或 `dict`（符号引用）。
    """
    a = a.strip()

    # 纯数字（十进制 / 十六进制）
    if re.fullmatch(r"0x[0-9A-Fa-f]+", a):
        return int(a, 16)
    if re.fullmatch(r"-?\d+", a):
        return int(a)

    # 符号 + 偏移：`X + 0x1C` / `X+0x1` / `(u8 *)X + 0x70`
    m = re.fullmatch(
        r"(?:\(\s*u8\s*\*\s*\)\s*)?([A-Za-z_]\w*)\s*\+\s*(0x[0-9A-Fa-f]+|\d+)", a)
    if m:
        return {"sym": m.group(1), "off": int(m.group(2), 0)}

    # EVT_SLOT_* 之类的**常量** → 整数（不是符号引用）
    if a in SLOTS:
        return SLOTS[a]

    # 纯符号名（排除一眼是宏的）
    if re.fullmatch(r"[A-Za-z_]\w*", a) and not MACRO_NAME.match(a):
        return {"sym": a}

    # 其它：原样保留，**不猜**。调用方能看到 `raw` 并决定怎么办。
    return {"raw": a}


def parse_body(body):
    """把脚本体切成指令：**一行一条**。

    ⚠️ 这里不按逗号切 —— 宏之间的逗号是宏展开带出来的，
    源码里**没有逗号**。按行切才是对的。
    """
    out = []
    for raw_line in body.split("\n"):
        line = raw_line.strip().rstrip(",").strip()
        if not line:
            continue
        if line.startswith("#"):
            continue
        m = re.fullmatch(r"([A-Za-z_]\w*)\s*(?:\((.*)\))?", line, re.S)
        if not m:
            # ⚠️ 兜底分支也要带 `args` —— 否则 Dart 侧读 `args` 会拿到 null。
            # 结构统一比"省一个空数组"重要得多。
            out.append({"op": "?", "args": [], "raw": line[:120]})
            continue
        op = m.group(1)
        args_s = m.group(2)
        args = [parse_arg(a) for a in split_args(args_s)] if args_s else []
        out.append({"op": op, "args": args})
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", default=os.path.join(HERE, "..", "out", "tables"))
    a = ap.parse_args()

    files = []
    for g in SRC_GLOBS:
        # ⚠️ 必须 `recursive=True` —— 否则 `**` 不展开，
        # 上面那行会只匹配到 16 个文件（而不是 src 下全部 .c）。
        files.extend(sorted(
            glob.glob(os.path.join(DECOMP, g), recursive=True)))
    files = sorted(set(files))
    if not files:
        print("错误：没找到场景脚本源文件", file=sys.stderr)
        return 1
    print(f"扫描 {len(files)} 个源文件")

    scripts = {}
    for f in files:
        raw = strip_comments(open(f, encoding="utf-8", errors="replace").read())
        for m in re.finditer(
                r"EventListScr\s+(EventScr_\w+)\s*\[\s*\]\s*=\s*\{", raw):
            name = m.group(1)
            i = m.end()
            try:
                j = raw.index("\n};", i)
            except ValueError:
                continue
            scripts[name] = parse_body(raw[i:j])

    print(f"解析出 {len(scripts)} 个场景脚本，"
          f"共 {sum(len(v) for v in scripts.values())} 条指令")

    # ---- 自洽性检查 ----
    #
    # ⚠️ **不拿 `EV_CMD_*` 表去校验指令名。**
    #
    # `EAstdlib.h` 的**宏名**（`TEXTSHOW`、`ENUT`、`BNE`…）与
    # `EV_CMD_*` 枚举名（`EV_CMD_DISPLAYTEXT`…）是**两套命名**，
    # 第一版拿后者去校验前者，误报了 122/130 个"未知指令"。
    #
    # 而且**根本不需要 opcode 数字**：虚拟机的输入格式是我们自己定的，
    # 直接用宏名当 API 更清楚 —— `case 'TEXTSHOW'` 比 `case 0x1B` 可读。
    ops = {}
    for name, ins in scripts.items():
        for ins_ in ins:
            ops[ins_["op"]] = ops.get(ins_["op"], 0) + 1

    bad = sum(v for k, v in ops.items() if k == "?")
    if bad:
        print(f"  ⚠️ {bad} 行没能解析成指令（保留原始文本）", file=sys.stderr)

    print(f"  用到的指令名 {len(ops)} 种")
    for k, v in sorted(ops.items(), key=lambda kv: -kv[1])[:8]:
        print(f"     {k:<26} {v}")

    # ---- 抽查：序章开场 ----
    pro = scripts.get("EventScr_Prologue_BeginningScene")
    if pro:
        print(f"\n抽查 EventScr_Prologue_BeginningScene（{len(pro)} 条）:")
        for ins_ in pro[:7]:
            print(f"   {ins_['op']:<16} {ins_['args']}")

    os.makedirs(a.out, exist_ok=True)
    payload = {
        "source": SRC_GLOBS,
        "note": "从源码逐行解析；参数为 int 或 {sym}/{sym,off}/{raw}",
        "scriptCount": len(scripts),
        "scripts": scripts,
    }
    dst = os.path.join(a.out, "scene_scripts.json")
    with open(dst, "w", encoding="utf-8") as f:
        json.dump(payload, f, ensure_ascii=False, indent=1)
    print(f"\n→ {dst}  ({os.path.getsize(dst) // 1024} KB)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
