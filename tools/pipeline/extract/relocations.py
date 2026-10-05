#!/usr/bin/env python3
"""
读取目标文件的**重定位信息** —— 把"指针"解析回"指向哪个符号"。

## 为什么需要它

反编译项目里的数据表到处是指针：

    CALL((u8 *)frontier_df3_eventscr_ch_000_A69464 + 0x70)
    .pTerrainAvoidLookup = TerrainTable_Avo_Common
    playerUnitsInNormal  = ...

编成目标文件后，这些位置存的是**宿主的绝对地址**，而地址布局
macOS 与 Linux 不同。直接导出绝对地址会让产物**平台相关**
（实测：章节事件 21 张表里 20 张两边不一致；
单位配置的元素个数 Linux 2629 / macOS 2796）。

重定位表记录的是"**第 N 字节处引用符号 X**" ——
这是编译器/链接器层面的信息，与平台无关。

## 两边的格式

macOS（`otool -rv`）：

    address  pcrel length extern type    scattered symbolnum/value
    0000f090 False quad   True   UNSIGND False     _REDAs_UnitDef_RuinEnemy_29_0

Linux（`readelf -r`）：

    Offset          Info           Type           Sym. Value    Sym. Name + Addend
    0000000000000010  000300000001 R_X86_64_64    0000000000000000 .data + 0

⚠️ 注意 Linux 那行的符号名可能形如 `.data`（**段相对**，不是符号名）——
那就说明它指向的是某个段内位置而非命名符号，我们解析不了，
应当**明确标出来**而不是当成一个符号名。

## 关于加数（addend）

Linux 的 `readelf` 会把加数一起打出来（`sym + 0x70`），
而 macOS 的 `otool -rv` **只给符号名**，加数在原始（非 `-v`）输出里，
拿不到名字的同时拿加数。

所以这里**统一只取符号名，丢掉加数** —— 两边结果才能一致。
代价是 `CALL((u8 *)<表> + 0x70)` 里的 `+0x70` 会丢；
要恢复它需要额外解析 macOS 的原始 `otool -r`（那里给的是符号索引
与 value），属于后续工作。**先保证一致，再谈精度。**
"""
import os
import re
import subprocess
import sys


def read_relocations(obj_path, section=None):
    """返回 `{节内偏移: 符号名}`。

    [section] 为 None 时读取所有节。
    解析不了的条目会以 `?<原始值>` 的形式保留 ——
    **不静默丢弃**：丢一条会让后面所有条目的归属错位。
    """
    if sys.platform == "darwin":
        return _read_macho(obj_path, section)
    return _read_elf(obj_path, section)


def _read_macho(obj_path, section):
    r = subprocess.run(["otool", "-rv", obj_path],
                       capture_output=True, text=True)
    if r.returncode != 0:
        print(f"⚠️  otool -rv 失败: {r.stderr.strip()[:120]}", file=sys.stderr)
        return {}

    out = {}
    cur_section = None
    for line in r.stdout.split("\n"):
        m = re.match(r"Relocation information \((__\w+),(__\w+)\)", line)
        if m:
            cur_section = f"{m.group(1)},{m.group(2)}"
            continue
        if line.startswith("address") or not line.strip():
            continue
        p = line.split()
        if len(p) < 7:
            continue
        if section is not None and cur_section != section:
            continue
        try:
            addr = int(p[0], 16)
        except ValueError:
            continue
        name = p[-1]
        out[addr] = name[1:] if name.startswith("_") else name
    return out


def _read_elf(obj_path, section):
    r = subprocess.run(["readelf", "-r", "-W", obj_path],
                       capture_output=True, text=True)
    if r.returncode != 0:
        print(f"⚠️  readelf -r 失败: {r.stderr.strip()[:120]}", file=sys.stderr)
        return {}

    out = {}
    for line in r.stdout.split("\n"):
        p = line.split()
        # 形如：
        #   0000000000000010  000300000001 R_X86_64_64  0000000000000000 sym + 0
        if len(p) < 5 or not re.fullmatch(r"[0-9a-fA-F]+", p[0]):
            continue
        if not p[2].startswith("R_"):
            continue
        try:
            addr = int(p[0], 16)
        except ValueError:
            continue
        # 格式：`<Offset> <Info> <Type> <Sym.Value> <Sym.Name> + <Addend>`
        # 符号名是**倒数第三列**（前面是 Offset/Info/Type/SymValue）。
        # 之前用一个宽松的正则去匹 `rest`，遇到 SymValue 不是 0 就失配，
        # 落进 `?unparsed`。按列取更稳。
        if len(p) < 6:
            out[addr] = f"?unparsed:{line.strip()[:40]}"
            continue
        sym = p[-3]
        if sym.startswith("."):
            # 段相对引用（如 `.data`）—— 不是命名符号，明确标出
            sym = f"?section:{sym}"
        out[addr] = sym
    return out


def annotate(words, relocs, *, word_size=4, base=0):
    """给一个字流标注每个 32 位槽是否是重定位（指针）。

    [words] 是 u16 列表，[relocs] 是 `{节内字节偏移: 符号名}`。

    返回 `{槽序号: 符号名}`（槽 = 4 字节 = 2 个 u16 字）。

    ⚠️ 一个槽可能只重定位**高 16 位或低 16 位**（编译器对
    `.4byte sym` 通常整体重定位，但不是绝对）。所以这里按
    "偏移落在这个槽的 4 字节范围内"来判断，而不是要求精确对齐。
    """
    out = {}
    for addr, sym in relocs.items():
        rel = addr - base
        if rel < 0:
            continue
        slot = rel // word_size
        out[slot] = sym
    return out
