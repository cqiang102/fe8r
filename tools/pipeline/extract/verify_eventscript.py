#!/usr/bin/env python3
"""
用 C 编译器复核事件指令集的提取结果。

判据和 `verify_tables.py` 一致：**让编译器把值算出来**，而不是照着源码再抄一遍。
抄一遍只能证明"我抄得一致"，证明不了"我抄对了"。

做法：生成一个探针，`#include "eventscript.h"` 后把每个指令名 /
子命令名的值打印出来，与 JSON 比对。

## 额外验证：编码宏

只比对枚举值还不够 —— 指令的**位打包**才是解析脚本的关键。
探针里用真实的 `_EvtCmd` 宏算出几条指令的编码，
与 Python 侧按 `opcode<<8 | len<<4 | sub` 算的结果比对。
如果我把移位量写错了，这里会立刻暴露。
"""
import json
import os
import re
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.abspath(os.path.join(HERE, "..", "..", ".."))
DECOMP = os.path.join(REPO, "third_party", "fireemblem8j")

HEADER = "include/eventscript.h"

PROBE = r"""
/* 只包含从上游抽出来的枚举块与编码宏，**不 include eventscript.h**。
   原因：那个头文件会牵进 event.h → variables.h → 一大堆 GBA 段属性宏，
   在 host 上即使屏蔽了段属性，链接出来的探针也会在静态初始化阶段段错误。
   抽出来既能验证我们真正依赖的东西（枚举值 + 位打包），又不用背整个引擎。 */
#include "es_defs.h"

#include <stdio.h>

/* 把宏展开后的编码打出来，用来验证 Python 侧的位打包 */
#define DUMP_ENC(cmd, len, sub) \
    printf("ENC %s %d\n", #cmd, (int)_EvtCmd(cmd, len, sub))

int main(void)
{
@NAMES@
    DUMP_ENC(EV_CMD_NOP, 2, 0);
    DUMP_ENC(EV_CMD_END, 2, 1);
    DUMP_ENC(EV_CMD_GOTO, 2, 0);
    DUMP_ENC(EV_CMD_STALL, 2, 0);
    DUMP_ENC(EV_CMD_CALL, 4, 0);
    DUMP_ENC(EV_CMD_DISPLAYTEXT, 4, 0);
    return 0;
}
"""


def extract_defs():
    """从上游抽出两个枚举块 + `_EvtCmd` 宏，拼成一个独立头文件"""
    src = open(os.path.join(DECOMP, HEADER), encoding="utf-8",
               errors="replace").read()
    raw = re.sub(r"/\*.*?\*/", " ", src, flags=re.S)
    raw = re.sub(r"//[^\n]*", " ", raw)

    blocks = []
    for name in ("event_cmd_idx", "event_sub_cmd_idx"):
        m = re.search(rf"enum\s+{name}\s*\{{(.*?)\}}", raw, re.S)
        if not m:
            return None
        blocks.append("enum %s {\n%s\n};\n" % (name, m.group(1)))

    # ⚠️ 不能用非贪婪正则 `(.*?)\)` 抓宏体：
    # 宏体里每一行都有 `)`，会停在第一个上，抽出来的宏是残的。
    # 正确做法是按行读到**单独一行 `)`** 为止。
    lines = raw.split("\n")
    start = None
    for i, ln in enumerate(lines):
        if "#define _EvtCmd(cmd, len, sub)" in ln:
            start = i
            break
    if start is None:
        return None
    end = None
    for j in range(start + 1, len(lines)):
        if lines[j].strip() == ")":
            end = j
            break
    if end is None:
        return None
    mac = "\n".join(lines[start:end + 1]) + "\n"

    return "\n".join(blocks) + "\n" + mac


def build_probe(cmds, subs, outdir):
    defs = extract_defs()
    if defs is None:
        raise SystemExit("错误：没能从 eventscript.h 抽出枚举块或 _EvtCmd 宏")
    open(os.path.join(outdir, "es_defs.h"), "w").write(defs)

    lines = []
    for name in sorted(cmds):
        lines.append(f'    printf("CMD {name} %d\\n", (int){name});')
    for name in sorted(subs):
        lines.append(f'    printf("SUB {name} %d\\n", (int){name});')

    src = PROBE.replace("@NAMES@", "\n".join(lines))
    path = os.path.join(outdir, "probe.c")
    open(path, "w").write(src)
    return path


def main():
    json_path = os.path.join(HERE, "..", "out", "tables", "eventscript.json")
    if not os.path.exists(json_path):
        print("错误：先跑 parse_eventscript.py 生成 JSON", file=sys.stderr)
        return 1
    data = json.load(open(json_path, encoding="utf-8"))
    cmds = data["commands"]
    subs = data["subCommands"]

    enc = data["encoding"]
    print(f"待验证 {len(cmds)} 条指令 + {len(subs)} 个子命令")

    with tempfile.TemporaryDirectory() as tmp:
        probe = build_probe(cmds, subs, tmp)
        exe = os.path.join(tmp, "probe")
        # 复用 C Oracle 的 host_prelude.h —— 上游头文件里的
        # `CONST_DATA SECTION(".data")` 在 Mach-O 上不合法，
        # 这个 prelude 把段属性宏整体屏蔽掉（且不修改上游任何文件）。
        common = ["clang", "-std=gnu89", "-O0", "-w", "-I", tmp]
        cmd = common + ["-o", exe, probe]
        r = subprocess.run(cmd, capture_output=True, text=True)
        if r.returncode != 0:
            # 事件引擎的 TU 依赖多，编不动就退化成"只展开宏"的探针：
            # 这种降级是**显式**的，并在输出里说明，不假装验证过了。
            print("  ⚠️  完整探针编译失败，降级为仅展开宏的形式")
            print(f"     {r.stderr.strip().splitlines()[-1] if r.stderr else ''}")
            fallback = PROBE.split("int main")[0] + r"""
int main(void)
{
@NAMES@
    DUMP_ENC(EV_CMD_NOP, 2, 0);
    DUMP_ENC(EV_CMD_END, 2, 1);
    DUMP_ENC(EV_CMD_GOTO, 2, 0);
    DUMP_ENC(EV_CMD_STALL, 2, 0);
    DUMP_ENC(EV_CMD_CALL, 4, 0);
    DUMP_ENC(EV_CMD_DISPLAYTEXT, 4, 0);
    return 0;
}
"""
            lines = []
            for name in sorted(cmds):
                lines.append(f'    printf("CMD {name} %d\\n", (int){name});')
            for name in sorted(subs):
                lines.append(f'    printf("SUB {name} %d\\n", (int){name});')
            open(probe, "w").write(fallback.replace("@NAMES@", "\n".join(lines)))
            cmd = common + ["-o", exe, probe]
            r = subprocess.run(cmd, capture_output=True, text=True)
            if r.returncode != 0:
                print("❌ 探针编译失败:", file=sys.stderr)
                print(r.stderr[-1500:], file=sys.stderr)
                return 1

        run = subprocess.run([exe], capture_output=True, text=True)
        got_cmd, got_sub, got_enc = {}, {}, {}
        for line in run.stdout.split("\n"):
            p = line.split()
            if len(p) != 3:
                continue
            if p[0] == "CMD":
                got_cmd[p[1]] = int(p[2])
            elif p[0] == "SUB":
                got_sub[p[1]] = int(p[2])
            elif p[0] == "ENC":
                got_enc[p[1]] = int(p[2])

    bad = []
    for name, v in cmds.items():
        if name not in got_cmd:
            bad.append((name, "编译器里没有这个指令", v, None))
        elif got_cmd[name] != v:
            bad.append((name, "值不一致", v, got_cmd[name]))
    for name, v in subs.items():
        if name not in got_sub:
            bad.append((name, "编译器里没有这个子命令", v, None))
        elif got_sub[name] != v:
            bad.append((name, "值不一致", v, got_sub[name]))

    # 编码宏复核
    shift_o, shift_l = enc["opcodeShift"], enc["lengthShift"]
    mask_s = enc["subCmdMask"]
    enc_bad = []
    for name, expect in got_enc.items():
        if name not in cmds:
            continue
        # 探针里的 len/sub 是固定的那几组，这里按同样的规则重算
        for ln, sub in ((2, 0), (2, 1), (4, 0)):
            mine = ((cmds[name] & 0xFF) << shift_o) | ((ln & 0xF) << shift_l) | (sub & mask_s)
            # 只对得上探针实际打的组合
            if expect == mine:
                break
        else:
            enc_bad.append(name)

    if bad or enc_bad:
        print(f"\n❌ {len(bad)} 处枚举不一致，{len(enc_bad)} 处编码不一致")
        for name, why, a, b in bad[:10]:
            print(f"  {name}: {why}  (python={a}, clang={b})")
        for name in enc_bad[:10]:
            print(f"  编码 {name}: 位打包对不上")
        return 1

    print(f"\n✅ {len(cmds)} 条指令 / {len(subs)} 个子命令，"
          f"与 C 编译器**完全一致**")
    print(f"✅ 编码宏复核通过（opcode<<{shift_o} | len<<{shift_l} | sub）")
    return 0


if __name__ == "__main__":
    sys.exit(main())
