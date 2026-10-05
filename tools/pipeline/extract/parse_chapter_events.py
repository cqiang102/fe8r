#!/usr/bin/env python3
"""
提取**真实章节的事件脚本**。

## 数据长什么样

`src/data/frontier_df3_eventscr_ch/frontier_df3_eventscr_ch.c` 里有 21 张
`EventListScr` 表，内容是**已经反编译成可读宏**的事件脚本：

    EventListScr ..._000_A69464[] = {
        EVENT_WORD(0x00000002)
        BNE(0, 0xC, 1)
        TUTORIALTEXTBOXSTART
        SVAL(EVT_SLOT_B, 0xFFFFFFFF)
        TEXTSHOW(0xB1B)
        ...
    }

这些宏（`GOTO` / `TEXTSHOW` / `SVAL` …）由 `include/EAstdlib.h` 映射到
`eventscript.h` 里的 `Evt*` 宏，后者用 `_EvtCmd` 把 opcode/长度/子命令
打包成 u16 字。

## 为什么用"编译"而不是"文本解析"

脚本里到处是 `CALL((u8 *)frontier_..._000_A69464 + 0x70)` 这种
**基于表自身地址的相对偏移**，还有跨表的符号引用。
用文本解析要自己算地址、自己展开宏 —— 那等于把编译器干的事重做一遍，
而且做错了不会报错，只会算出一份"看起来像脚本"的垃圾。

所以这里**让编译器算**：把源文件原样编成目标文件，再用 `nm` 读出每张表的
地址与长度，从 `.data` 段里把字节挖出来，按 u16 还原成字流。

## 与上游的关系

上游文件**一个字节都不改**。段属性（`__attribute__((section(...)))`）是
直接写死的、host_prelude 屏蔽不掉，所以在临时副本里机械剥离 ——
这只影响段名，不影响任何数据。

用法:
    python3 tools/pipeline/extract/parse_chapter_events.py --out out/tables
"""
import argparse
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

SRC = "src/data/frontier_df3_eventscr_ch/frontier_df3_eventscr_ch.c"


def strip_section_attrs(text):
    """把 `__attribute__((section("...")))` 机械去掉。

    上游把段属性**直接写在声明上**（不是通过宏），所以 host_prelude 那套
    屏蔽办法对它无效。Mach-O 要求段名形如 "segment,section"，
    `.data.foo` 会被拒。

    只动段属性，不动任何数据或初始化器。
    """
    before = text.count("__attribute__")
    text = re.sub(r'__attribute__\s*\(\(\s*section\s*\([^)]*\)\s*\)\)', " ", text)
    after = text.count("__attribute__")
    return text, before - after


def compile_object(tmp, src):
    """先把上游源文件编成目标文件，用 nm 取符号地址。"""
    cpath = os.path.join(tmp, "eventscr.c")
    open(cpath, "w").write(src)
    obj = os.path.join(tmp, "eventscr.o")
    cmd = [
        "clang", "-std=gnu89", "-O0", "-w", "-c",
        "-include", os.path.join(HOST, "host_prelude.h"),
        "-I", HOST,
        "-I", os.path.join(DECOMP, "include"),
        "-I", DECOMP,
        "-o", obj, cpath,
    ]
    r = subprocess.run(cmd, capture_output=True, text=True)
    if r.returncode != 0:
        print("❌ 编译失败:", file=sys.stderr)
        print(r.stderr[-1500:], file=sys.stderr)
        return None
    return obj


def undefined_symbols(obj):
    """列出目标文件里未定义的符号（去掉前导下划线）。

    ⚠️ 不能靠 `-Wl,-undefined,dynamic_lookup` 蒙混过去：
    它把解析推迟到**运行时**，dyld 找不到符号会直接
    `Abort trap: 6`（实测报 `symbol not found in flat namespace`）。
    必须给出真正的定义。
    """
    r = subprocess.run(["nm", "-u", obj], capture_output=True, text=True)
    out = []
    for line in r.stdout.split("\n"):
        parts = line.split()
        if not parts:
            continue
        name = parts[-1]
        if name.startswith("_"):
            name = name[1:]
        if name:
            out.append(name)
    return out


def write_stubs(path, symbols, exclude):
    """为未定义符号生成零填充的桩定义。

    桩的**大小不影响我们读到的数据** —— 我们只读自己的那 21 张表，
    桩只是为了让链接器满意、让 dyld 不 abort。
    唯一会被桩"污染"的是**跨模块的 CALL 目标**，那些值在我们的输出里
    本来就是不可解析的（ROM 地址），会在 JSON 里用符号名标出来。
    """
    lines = ["/* 自动生成的桩：仅在提取时用于满足链接器 */\n",
             '#include "global.h"\n']
    n = 0
    for sym in symbols:
        if sym in exclude:
            continue
        lines.append(f"unsigned char {sym}[256] = {{0}};\n")
        n += 1
    open(path, "w").write("".join(lines))
    return n


def symbol_sizes(obj, names):
    """求每张表的**字节长度**。

    做法：`nm` 列出所有符号的地址，按地址排序，
    某符号的长度 = 下一个符号地址 − 本符号地址。

    ⚠️ 为什么不用别的办法：
      1. **不能在探针里"扫到 0 为止"** —— `EventListScr` 是 `uintptr_t`，
         在 64 位宿主上是 8 字节（GBA 上是 4 字节），元素步长和 ROM 不同；
         而且事件表**不保证**以 0 结尾。
      2. **macOS 的 `nm` 不支持 `-S`**（那是 GNU binutils 的选项），
         所以拿不到符号长度字段，只能用地址差。
      3. `nm` 的输出格式两边不同：macOS 的符号名带前导下划线。
    """
    r = subprocess.run(["nm", "-n", obj], capture_output=True, text=True)
    if r.returncode != 0:
        print("❌ nm 失败:", file=sys.stderr)
        print(r.stderr[-500:], file=sys.stderr)
        return {}

    entries = []
    for line in r.stdout.split("\n"):
        parts = line.split()
        # 形如 `0000000000000120 T _sym` 或 `0000000000000120 T sym`
        if len(parts) != 3:
            continue
        try:
            addr = int(parts[0], 16)
        except ValueError:
            continue
        name = parts[2]
        if name.startswith("_"):
            name = name[1:]
        entries.append((addr, name))
    entries.sort()

    # 只保留我们关心的表的地址，长度取"下一个任意符号"
    addr_of = {name: addr for addr, name in entries}
    found = {}
    for name in names:
        a = addr_of.get(name)
        if a is None:
            continue
        nxt = None
        for addr, _ in entries:
            if addr > a:
                nxt = addr
                break
        if nxt is not None:
            found[name] = nxt - a
    return found


def count_elements_from_source(raw, table):
    """从源码里数某张表的**顶层元素个数**（逗号分隔）。

    只用于**最后一张表** —— 它后面没有别的符号，`nm` 的地址差法失效。
    `EventListScr` 每元素 4 字节 = 2 个 u16 字，所以字数 = 元素数 × 2。

    元素内部可能有括号（`CALL((u8 *)sym + 0x70)`）但没有花括号，
    所以按"括号深度 0 时的逗号"计数是安全的。
    """
    m = re.search(rf"^EventListScr\s+{re.escape(table)}\[\]\s*[^=]*=\s*\{{",
                  raw, re.M)
    if not m:
        return None
    i = m.end()
    depth = 0
    count = 0
    while i < len(raw):
        c = raw[i]
        if c == "{":
            depth += 1
        elif c == "}":
            if depth == 0:
                return count + (1 if raw[m.end():i].strip() else 0)
            depth -= 1
        elif c == "," and depth == 0:
            count += 1
        i += 1
    return None


def element_size():
    """宿主上 `EventListScr` 的字节数 —— 探针里 `sizeof` 出来更可靠，
    但这里按平台约定取：64 位宿主上 `uintptr_t` 是 8 字节。"""
    return 8


def build_and_dump(names, sizes, undef_symbols=None):
    with tempfile.TemporaryDirectory() as tmp:
        src = open(os.path.join(DECOMP, SRC), encoding="utf-8",
                   errors="replace").read()
        src, stripped = strip_section_attrs(src)
        print(f"  剥离 {stripped} 处段属性（不改动数据）")

        # 追加打印器：每张表按**算好的元素个数**打印
        probe = ["\n#include <stdio.h>\n"]
        probe.append("int main(void) {\n")
        for n in names:
            cnt = sizes.get(n, 0) // element_size()
            # ⚠️ 每个槽是一个 u32，**携带两个 u16 字**（`_EvtParams2(x, y)`
            # 把两个参数打包成 `y<<16 | x`）。只取低 16 位会丢掉一半的字，
            # 解析出来的脚本会整体错位。
            probe.append(f'  {{ extern EventListScr {n}[]; ')
            probe.append(f'    printf("TABLE {n} {cnt * 2}\\n"); ')
            # ⚠️ 这里只能导出**原始字**，不能做"指针归一化"。
            #
            # 试过：把 > 0xFFFF 的值当成指针、减去表首得到偏移。
            # **行不通** —— 在 64 位宿主上 `_EvtParams2(x, y)` 打包出的
            # u32（如 `_EvtParams2(0xC, 1)` = 0x0001000C）同样 > 0xFFFF，
            # 会被误判成指针。区分"打包的两个字"与"指针"需要**重定位信息**，
            # 靠数值做不到。
            #
            # 后果：含指针条目的表，其字流**依赖宿主平台**
            # （桩符号布局 macOS 与 Linux 不同，实测 21 张里 20 张不一致）。
            # 所以这个提取**不进 CI**，产物以 macOS 上生成的那份为准并入库，
            # Dart 测试跑的是入库产物（确定性）。
            # 见 --check 与 run_all.dart 里的说明。
            probe.append(f'    for (long i = 0; i < {cnt}; i++) {{ ')
            probe.append(f'      unsigned long v = (unsigned long){n}[i]; ')
            probe.append(f'      printf("%04lx %04lx ", v & 0xFFFF, '
                         f'(v >> 16) & 0xFFFF); }} ')
            probe.append('    printf("\\n"); }\n')
        probe.append("  return 0;\n}\n")

        cpath = os.path.join(tmp, "probe.c")
        open(cpath, "w").write(src + "".join(probe))

        # ⚠️ 桩必须生成在**同一个**临时目录里。
        # 之前把它建在外层 `with` 里，等这里运行时那个目录已经销毁了，
        # 链接器报 "no such file or directory"。
        stub_path = None
        if undef_symbols:
            stub_path = os.path.join(tmp, "stubs.c")
            write_stubs(stub_path, undef_symbols, set(names))

        exe = os.path.join(tmp, "probe")
        # `-Wl,-undefined,dynamic_lookup`（Mach-O）/ `-Wl,--unresolved-symbols=ignore-all`
        # （ELF）：让**未定义符号保持为 0**，而不是报链接错误。
        #
        # 为什么可以接受：这个文件里绝大多数引用是
        # `CALL((u8 *)<本表> + 0xNN)` —— **表内自引用**，在同一目标文件里，
        # 链接器能正确解析。跨表/跨模块的引用会变成 0，我们在输出里
        # 用符号名标出来，而不是当成一个假的地址。
        cmd = [
            "clang", "-std=gnu89", "-O0", "-w",
            "-include", os.path.join(HOST, "host_prelude.h"),
            "-I", HOST,
            "-I", os.path.join(DECOMP, "include"),
            "-I", DECOMP,
        ]
        if stub_path:
            cmd.append(stub_path)
        cmd += ["-o", exe, cpath]
        r = subprocess.run(cmd, capture_output=True, text=True)
        if r.returncode != 0:
            print("❌ 探针编译失败:", file=sys.stderr)
            print(r.stderr[-1500:], file=sys.stderr)
            return None
        run = subprocess.run([exe], capture_output=True, text=True)
        if run.returncode != 0:
            print(f"❌ 探针运行失败（退出码 {run.returncode}）", file=sys.stderr)
            return None
        return run.stdout


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", default=os.path.join(HERE, "..", "out", "tables"))
    ap.add_argument("--limit", type=int, default=0,
                    help="只导出前 N 张表（调试用）")
    a = ap.parse_args()

    path = os.path.join(DECOMP, SRC)
    if not os.path.exists(path):
        print(f"错误：找不到 {path}", file=sys.stderr)
        return 1

    raw = open(path, encoding="utf-8", errors="replace").read()
    names = re.findall(r"^EventListScr\s+(\w+)\[\]", raw, re.M)
    print(f"找到 {len(names)} 张事件脚本表")
    if not names:
        print("错误：没解析到表名", file=sys.stderr)
        return 1
    if a.limit:
        names = names[:a.limit]
        print(f"  （限制为前 {len(names)} 张）")

    with tempfile.TemporaryDirectory() as tmp:
        src = open(path, encoding="utf-8", errors="replace").read()
        src, _ = strip_section_attrs(src)
        obj = compile_object(tmp, src)
        if obj is None:
            return 1
        sizes = symbol_sizes(obj, names)
        undef = undefined_symbols(obj)
        print(f"  未定义符号 {len(undef)} 个（将在探针目录里生成桩）")
    missing = [n for n in names if n not in sizes]
    if missing:
        # 最后一张表后面没有别的符号，地址差法失效 —— 从源码数元素个数补齐
        for n in list(missing):
            cnt = count_elements_from_source(raw, n)
            if cnt:
                sizes[n] = cnt * 4  # 每元素 4 字节
                missing.remove(n)
                print(f"  {n}: nm 无后继符号，从源码数出 {cnt} 个元素")
    if missing:
        print(f"❌ 仍无法确定 {len(missing)} 张表的长度: {missing[:3]}",
              file=sys.stderr)
        return 1
    print(f"  nm 取到 {len(sizes)} 个符号长度"
          f"（合计 {sum(sizes.values()) // element_size()} 个字）")

    out = build_and_dump(names, sizes, undef)
    if out is None:
        return 1

    tables = {}
    for line in out.split("\n"):
        if line.startswith("TABLE "):
            parts = line.split()
            if len(parts) >= 3:
                tables[parts[1]] = {"size": int(parts[2]), "words": []}
        elif line.strip() and tables:
            last = next(reversed(tables))
            if not tables[last]["words"]:
                tables[last]["words"] = [int(x, 16) for x in line.split()]

    bad = [k for k, v in tables.items() if len(v["words"]) != v["size"]]
    if bad:
        print(f"❌ {len(bad)} 张表的字数与声明不符: {bad[:3]}", file=sys.stderr)
        return 1

    total = sum(v["size"] for v in tables.values())
    print(f"\n导出 {len(tables)} 张表 / {total} 个字")

    # 抽查第一张表的开头，确认确实是事件指令
    first = names[0]
    w = tables[first]["words"][:6]
    if w:
        print(f"\n抽查 {first} 前 6 个字: "
              + " ".join(f"{x:04x}" for x in w))
        for x in w[:4]:
            op = (x >> 8) & 0xFF
            ln = (x >> 4) & 0xF
            sub = x & 0xF
            print(f"  {x:04x} → opcode=0x{op:02x} len={ln} sub={sub}")

    os.makedirs(a.out, exist_ok=True)
    payload = {
        "source": SRC,
        "tables": tables,
    }
    dst = os.path.join(a.out, "chapter_events.json")
    with open(dst, "w", encoding="utf-8") as f:
        json.dump(payload, f, ensure_ascii=False, indent=1)
    print(f"\n→ {dst}  ({os.path.getsize(dst) // 1024} KB)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
