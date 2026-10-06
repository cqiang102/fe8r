#!/usr/bin/env python3
"""
提取**场景剧情脚本**（`EventScr_*`）并统计真实 opcode 覆盖率。

## 为什么单独做这一类

之前啃的是**章节条件表**（`EventListScr`，`*Events` 那些）——
那是**异构**的：混着"条件清单"和"指令流"，元素边界只有编译器知道，
变量切不完整（见 parse_chapter_events.py 的说明）。

场景脚本不一样：**它们是纯线性指令流**。

    EventListScr EventScr_Prologue_BeginningScene[] = {
        CALL(EventScr_Prologue_RenaisThroneCutscene)
        CHECK_TUTORIAL
        BNE(0, 0xC, 0)
        ENUT(8)
        LOAD1(1, UnitDef_Event_PrologueAlly)     ← 加载单位
        MUSI                                      ← 音乐
        TEXTSHOW(0x...)
        ...
    }

从偏移 0 就能解，没有异构问题。

## 这一步的产出：**真实的 opcode 覆盖率**

"150 个指令里实现了 27 个"这个说法没有意义 —— 那 27 个是我挑的。
有了 196 张真实场景，可以统计**每个 opcode 实际出现多少次**，
然后按频次实现。覆盖率就变成"**真实剧情里 X% 的指令我都支持**"。

## 实测结果（166 张场景 / 5842 条真实指令）

    解码：159/166 张完整解出
    用到的 opcode：**59 种**
    频次前 8：SVAL 16.8% / DISPLAYTEXT 7.9% / CALL 6.9% / QUEUE_OPS 6.2%
              DISPLAYCURSOR 5.8% / ENDTEXT 4.6% / FADE 4.4% / STALL 4.3%

    **按频次实现**能覆盖多少真实指令：
        前 10 个 → 64.7%
        前 20 个 → 88.5%
        前 30 个 → 95.8%
        前 40 个 → 98.6%

    我**当前**实现的覆盖率：**62.2%**（19 种 opcode 真的出现过）

所以"该实现哪个指令"不再是猜的。补频次最高的 6 个
（QUEUE_OPS / DISPLAYCURSOR / FADE / ENUN / CHANGESTATE / LOADUNIT）
就能过 85%。

## ⚠️ 指针操作数不进产物

指针（`CALL(...)` / `ASMC(...)` / `LOAD1` 的表引用）编出来是**宿主地址**，
平台相关。但它们**不影响 opcode 统计** —— opcode 在第一字的
高 8 位里，与操作数无关。

所以本文件**只统计、不落盘指针值**，从而天然与平台无关。
要真正**运行**这些场景时，才需要把指针解析回符号名。

用法:
    python3 tools/pipeline/extract/parse_event_scripts.py --out out/tables
"""
import argparse
import glob
import json
import os
import re
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.abspath(os.path.join(HERE, "..", "..", ".."))
DECOMP = os.path.join(REPO, "third_party", "fireemblem8j")
HOST = os.path.join(REPO, "tools", "oracle", "host")

SRC_GLOBS = [
    "src/data/EventScr_*_ref/*.c",
    "src/data/EventScr_*.c",
]

# libc 符号不该生成桩
LIBC = {
    "printf", "snprintf", "sprintf", "puts", "putchar", "fputs", "fprintf",
    "memcpy", "memset", "memmove", "memcmp", "strlen", "strcpy", "strcmp",
    "malloc", "free", "calloc", "realloc", "abort", "exit",
}


def strip_all(text):
    """做机械的文本整理，**只动声明，不动数据**。"""
    # 段属性（Mach-O 不接受 `.data.foo`）
    text = re.sub(r'__attribute__\s*\(\(\s*section\s*\([^)]*\)\s*\)\)', " ", text)
    # ⚠️ **不要**剥掉 `extern const u8 X[];` 这类前置声明。
    #
    # 我第一版照搬了 parse_unit_defs.py 的做法把它们剥了，结果
    # `CALL(Event_TextWithBG)` / `LOAD2(1, frontier_df4_banim_b_077_90DB94 + 0xD4)`
    # 全部报 "use of undeclared identifier" ——
    # **这些声明正是让名字可见的东西**，剥了它们等于把地基拆了。
    #
    # 单位配置那边剥是因为它们与 eventcall.h 的真实声明**类型冲突**；
    # 这里是纯文本引用，没有冲突，保留即可（缺的符号由桩补上）。
    return text


PROBE_HEAD = r"""
#include "global.h"
#include "eventscript.h"
#include <stdio.h>
"""

PROBE_BODY = r"""
int main(void) {
@BODY@
    return 0;
}
"""


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", default=os.path.join(HERE, "..", "out", "tables"))
    # opcode 名字表来自 parse_eventscript.py 的产物（键是 `commands`）
    ap.add_argument("--opcodes",
                    default=os.path.join(REPO, "tools", "pipeline", "out",
                                         "tables", "eventscript.json"))
    a = ap.parse_args()

    files = []
    for g in SRC_GLOBS:
        files.extend(sorted(glob.glob(os.path.join(DECOMP, g))))
    files = sorted(set(files))
    if not files:
        print("错误：没找到场景脚本源文件", file=sys.stderr)
        return 1
    print(f"扫描 {len(files)} 个源文件")

    texts = []
    names = []
    for f in files:
        t = open(f, encoding="utf-8", errors="replace").read()
        texts.append(t)
        # 表名可能没有任何限定（`SECTION(...) EventListScr X[]`）或带 CONST_DATA
        names.extend(re.findall(
            r"(?:EventListScr|EventScr)\s+(EventScr_\w+)\s*\[\s*\]", t))
    names = sorted(set(names))

    # 只保留**真正有定义**的表（`EventListScr X[] = {`）。
    # 有些名字只是被 `CALL(...)` 引用，定义在别的文件/别处 ——
    # 把它们也算进"要提取的表"会让探针去 sizeof 一个不存在的符号。
    joined = "\n".join(texts)
    defined = set(re.findall(
        r"(?:EventListScr|EventScr)\s+(EventScr_\w+)\s*\[\s*\]\s*=",
        joined))
    skipped = [n for n in names if n not in defined]
    names = [n for n in names if n in defined]
    if skipped:
        print(f"  （跳过 {len(skipped)} 个只有引用没有定义的名字，"
              f"如 {skipped[:2]}）")

    # ⚠️ 只剥掉**我自己要提取的那些表**的前置声明。
    #
    # 这些文件之间会互相 `extern const u8 OtherEventScr[];`，
    # 而真实定义是 `EventListScr OtherEventScr[] = {...}` —— 类型不符。
    # 全剥会拆掉别人的地基（"use of undeclared identifier"），
    # 全留会撞名（"redefinition with a different type"）。
    #
    # 精确做法：**只剥我将要定义的那些名字**。
    mine = set(names)
    raw = ""
    for t in texts:
        t = strip_all(t)
        out = []
        for line in t.split("\n"):
            # 剥掉**所有** `extern <基础类型> EventScr_*[];` —— 不管它是不是
            # 我要提取的表。
            #
            # 理由：这些文件的写法不统一（有的 `extern const u8 X[]`，
            # 有的直接定义 `EventListScr X[]`），类型互相冲突。
            # 与其逐个甄别，不如**统一成一种类型**：
            # 全部剥掉，然后在最前面统一声明成 `EventListScr`（见下）。
            # 名字一个不少，类型只有一个，冲突自然消失。
            m = re.match(
                r"^\s*extern\s+(?:const\s+)?(?:u8|u16|u32|s8|s16|s32|"
                r"int|unsigned)\s+(EventScr_\w+)\s*\[\s*\]\s*;\s*$", line)
            if m:
                continue
            out.append(line)
        raw += "\n" + "\n".join(out)

    # 兜底：把所有被引用的 `EventScr_*` 名字先声明一遍。
    #
    # 有些名字只在 `CALL(...)` 里出现，声明原本来自某个头文件，
    # 但把 166 个文件拼成一个 TU 后不一定可见 ——
    # 表现为 "use of undeclared identifier"。
    #
    # 统一前置声明是安全的：**同名同类型**的重复声明在 C 里合法，
    # 后面的真实定义与之相符。
    referenced = sorted(set(re.findall(r"\b(EventScr_\w+)\b", raw)))
    decls = "\n".join(f"extern EventListScr {n}[];" for n in referenced)
    raw = decls + "\n" + raw
    print(f"找到 {len(names)} 张场景脚本表")
    if not names:
        return 1

    with tempfile.TemporaryDirectory() as tmp:
        cpath = os.path.join(tmp, "scr.c")
        body = []
        for n in names:
            body.append(f'  {{ extern EventListScr {n}[];')
            # ⚠️ 元素个数用 **sizeof**（编译器算，平台无关）——
            # 不要用 nm 的地址差，那个 ELF 与 Mach-O 取法不同。
            body.append(f'    long cnt = (long)(sizeof({n}) / sizeof({n}[0]));')
            body.append(f'    printf("T {n} %ld\\n", cnt);')
            # ⚠️ 每个槽（GBA 上 `EventListScr` = 4 字节）含**两个 u16 字**。
            # 只打低 16 位会丢掉一半 —— 表现为"字数 = 槽数"，
            # 而指令是按 u16 字走的，于是解不出任何东西。
            body.append(f'    for (long i = 0; i < cnt; i++) {{')
            body.append(f'      unsigned long v = (unsigned long){n}[i];')
            body.append(f'      printf("%04lx %04lx ", v & 0xFFFF,'
                        f' (v >> 16) & 0xFFFF); }}')
            body.append('    printf("\\n"); }')
        open(cpath, "w").write(
            PROBE_HEAD + raw + PROBE_BODY.replace("@BODY@", "\n".join(body)))

        base = ["clang", "-std=gnu89", "-O0", "-w",
                "-include", os.path.join(HOST, "host_prelude.h"),
                "-I", HOST,
                "-I", os.path.join(DECOMP, "include"),
                "-I", DECOMP]
        obj = os.path.join(tmp, "scr.o")
        r = subprocess.run(base + ["-c", "-o", obj, cpath],
                           capture_output=True, text=True)
        if r.returncode != 0:
            print("❌ 编译失败:", file=sys.stderr)
            print(r.stderr[-1200:], file=sys.stderr)
            return 1

        u = subprocess.run(["nm", "-u", obj], capture_output=True, text=True)
        syms = []
        for line in u.stdout.split("\n"):
            p = line.split()
            if p:
                n = p[-1]
                syms.append(n[1:] if n.startswith("_") else n)

        stub = os.path.join(tmp, "stubs.c")
        with open(stub, "w") as f:
            # ⚠️ 桩文件**不要** include global.h。
            #
            # 它会把 functions.h 拉进来，里面有大量函数声明；
            # 我们再定义一个同名数组就撞车：
            #   "redefinition of 'WriteSuspendPlayerIdle' as different kind
            #    of symbol"
            # 桩的目的只是让链接器有事可做，不需要任何类型信息。
            f.write("\n")
            for s in syms:
                if s in LIBC or s in names:
                    continue
                f.write(f"unsigned char {s}[256] = {{0}};\n")

        # ⚠️ 桩**单独编译**成 .o，不参与 `-include host_prelude.h`。
        #
        # host_prelude.h 会拉进 global.h → functions.h，里面有大量函数声明；
        # 我们再定义同名数组就撞车（"redefinition of 'X' as different kind
        # of symbol"）。桩不需要任何类型信息，单独编最干净。
        stub_obj = os.path.join(tmp, "stubs.o")
        r = subprocess.run(["clang", "-std=gnu89", "-O0", "-w", "-c",
                            "-o", stub_obj, stub],
                           capture_output=True, text=True)
        if r.returncode != 0:
            print("❌ 桩编译失败:", file=sys.stderr)
            print(r.stderr[-600:], file=sys.stderr)
            return 1

        exe = os.path.join(tmp, "scr")
        r = subprocess.run(base + [stub_obj, cpath, "-o", exe],
                           capture_output=True, text=True)
        if r.returncode != 0:
            print("❌ 链接失败:", file=sys.stderr)
            print(r.stderr[-1200:], file=sys.stderr)
            return 1
        run = subprocess.run([exe], capture_output=True, text=True)
        if run.returncode != 0:
            print(f"❌ 探针运行失败（{run.returncode}）", file=sys.stderr)
            return 1

    # ---- 切指令、统计 opcode ----
    opcode_names = {}
    op_path = a.opcodes
    if os.path.exists(op_path):
        d = json.load(open(op_path, encoding="utf-8"))
        # 结构：{"commands": {"EV_CMD_ASMC": 13, ...}, ...}
        for k, v in (d.get("commands") or {}).items():
            if isinstance(v, int):
                opcode_names[v] = k
    print(f"opcode 名字表 {len(opcode_names)} 条"
          f"{'（缺失，只报编号）' if not opcode_names else ''}")

    counts = {}
    subs = {}
    total_ins = 0
    bad_tables = []
    per_table = {}

    for line in run.stdout.split("\n"):
        if line.startswith("T "):
            p = line.split()
            cur = p[1]
            per_table[cur] = {"declared": int(p[2]), "words": []}
        elif line.strip() and per_table:
            last = next(reversed(per_table))
            per_table[last]["words"] = [int(x, 16) for x in line.split()]

    for name, t in per_table.items():
        w = t["words"]
        if len(w) != t["declared"] * 2:
            bad_tables.append(f"{name}: {len(w)} 字 vs 声明 {t['declared']} 槽")
            continue
        i = 0
        ok = True
        while i < len(w):
            w0 = w[i]
            op = (w0 >> 8) & 0xFF
            ln = (w0 >> 4) & 0xF
            sb = w0 & 0xF
            if ln == 0:
                ok = False
                bad_tables.append(f"{name}: 字偏移 {i} 长度为 0")
                break
            if i + ln > len(w):
                ok = False
                bad_tables.append(f"{name}: 字偏移 {i} 越界（len={ln}）")
                break
            counts[op] = counts.get(op, 0) + 1
            subs[(op, sb)] = subs.get((op, sb), 0) + 1
            total_ins += 1
            i += ln
        t["ok"] = ok
        t["ins"] = i

    good = sum(1 for t in per_table.values() if t.get("ok"))
    print(f"\n解码：{good}/{len(per_table)} 张表完整解出，"
          f"共 {total_ins} 条指令")
    if bad_tables:
        print(f"⚠️  {len(bad_tables)} 处问题（前 4 条）:")
        for b in bad_tables[:4]:
            print(f"   {b}")

    # ---- 报告 ----
    top = sorted(counts.items(), key=lambda kv: -kv[1])
    print(f"\n用到的 opcode 种类：{len(counts)}")
    print("  频次前 15:")
    for op, c in top[:15]:
        nm = opcode_names.get(op, "")
        pct = 100.0 * c / total_ins
        print(f"    0x{op:02X} {nm:<24} {c:>6}  {pct:5.1f}%")

    # 累计覆盖率：实现前 N 个能覆盖多少指令
    acc = 0
    for idx, (op, c) in enumerate(top, 1):
        acc += c
        if idx in (10, 20, 30, 40, 50):
            print(f"  实现前 {idx:>2} 个 opcode → 覆盖 {100.0*acc/total_ins:5.1f}% 的指令")

    # ---- 我当前实现的**真实覆盖率** ----
    #
    # "150 个指令里实现了 27 个"没有意义 —— 那 27 个是我挑的。
    # 拿真实场景统计出来的这个百分比才有意义。
    #
    # 名字映射：C 里是 `EV_CMD_SVAL`，Dart 里是 `EventOpcodes.sVal`。
    # 两边归一化（去前缀、去下划线、小写）后匹配。
    vm_src = os.path.join(REPO, "lib", "core", "event", "event_vm.dart")
    impl_percent = None
    impl_names = []
    if os.path.exists(vm_src):
        vm = open(vm_src, encoding="utf-8").read()
        used = set(re.findall(r"EventOpcodes\.(\w+)", vm))

        def _norm(x):
            return re.sub(r"[^a-z0-9]", "", x.replace("EV_CMD_", "").lower())

        n2v = {_norm(k): v for k, v in
               (json.load(open(op_path, encoding="utf-8")).get("commands")
                or {}).items() if isinstance(v, int)}
        vals = {n2v[_norm(u)] for u in used if _norm(u) in n2v}
        cov = sum(c for op, c in counts.items() if op in vals)
        impl_percent = round(100.0 * cov / total_ins, 1)
        impl_names = sorted(u for u in used if _norm(u) in n2v)
        print(f"\n当前实现覆盖真实指令的 **{impl_percent}%**"
              f"（VM 引用 {len(used)} 个常量，命中 {len(vals)} 个 opcode）")
        missing = [o for o in top if o[0] not in vals][:6]
        if missing:
            print("  补这几个收益最大:")
            for op, c in missing:
                print(f"    0x{op:02X} {opcode_names.get(op, ''):<22}"
                      f" {100.0*c/total_ins:5.1f}%")

    os.makedirs(a.out, exist_ok=True)
    payload = {
        "sources": [os.path.relpath(f, DECOMP) for f in files[:0]],
        "tableCount": len(per_table),
        "instructionCount": total_ins,
        "decodedTables": good,
        "opcodes": [
            {"opcode": op, "name": opcode_names.get(op, ""), "count": c,
             "percent": round(100.0 * c / total_ins, 2)}
            for op, c in top
        ],
        "subCommands": [
            {"opcode": op, "sub": sb, "count": c}
            for (op, sb), c in sorted(subs.items(), key=lambda kv: -kv[1])
        ],
        "implementedCoveragePercent": impl_percent,
        "implementedOpcodes": impl_names,
        "problems": bad_tables[:200],
        "tables": {k: {"slots": v["declared"], "ok": v.get("ok", False)}
                   for k, v in per_table.items()},
    }
    dst = os.path.join(a.out, "event_scripts.json")
    with open(dst, "w", encoding="utf-8") as f:
        json.dump(payload, f, ensure_ascii=False, indent=1)
    print(f"\n→ {dst}  ({os.path.getsize(dst) // 1024} KB)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
