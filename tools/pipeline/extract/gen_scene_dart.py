#!/usr/bin/env python3
"""
从 C 源码**直接生成 Dart 的 async 函数** —— 没有 JSON，也没有指令列表。

## 三条演进

1. 第一版：编译成字节 → 指针槽是宿主地址 → 造工具还原符号名（绕了三轮）
2. 第二版：从源码逐行解析 → JSON → 运行时的 sealed class 解释器
3. **现在**：从源码直接生成 `async` 函数

## 为什么能去掉指令列表

保留"指令列表 + 程序计数器"的唯一理由是**随时存档**。
用户明确说不需要之后，那层数据模型就没有存在理由了 ——
`SceneOp` 那些类型存在的唯一意义就是"被解释"。

## 两种代码形态（按脚本是否有分支）

    * **无分支（53%）** → 顺序的 async 代码，像人写的一样
    * **有分支（47%）** → `while(true) { switch (pc) { ... } }`

    Future<void> prologueBeginningScene(Scene s) async {
      await s.call(prologueRenaisThroneCutscene);
      s.setSlot(2, Sym('EventScr_Prologue_EirikaAttacked'));
      s.checkTutorial();
      if (s.slotInt(0) != 12) { s.asm('BmGuideTextSetAllGreen', 1); }
      ...
    }

## ⚠️ `BNE(a, b, c)` 的第三个参数是**标签**，不是"跳过条数"

第一版把它当成 opCount，语义就错了。
实测 `BNE(0, 0xC, 0)` 后面紧跟 `ASMC(...)` 和 `LABEL(0)` ——
"若 slot0 ≠ 0xC 则跳到 LABEL(0)"，也就是**跳过那条 ASMC**，语义自洽。

用法:
    python3 tools/pipeline/extract/gen_scene_dart.py
"""
import argparse
import glob
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.abspath(os.path.join(HERE, "..", "..", ".."))
DECOMP = os.path.join(REPO, "third_party", "fireemblem8j")
OUT = os.path.join(REPO, "lib", "core", "event", "scene_data.g.dart")

SRC_GLOBS = ["src/**/*.c"]
MACRO_NAME = re.compile(r"^[A-Z][A-Z0-9_]*$")

# 有分支的判定
BRANCH_OPS = {"LABEL", "GOTO"}


def strip_comments(t):
    t = re.sub(r"/\*.*?\*/", " ", t, flags=re.S)
    return re.sub(r"//[^\n]*", " ", t)


def slot_constants():
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


SLOTS = slot_constants()
CAST = r"(?:\(\s*(?:u8|u16|u32|void|int)\s*\*\s*\)\s*)?"


def split_args(s):
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


def parse_arg(a):
    a = a.strip()
    if re.fullmatch(r"0x[0-9A-Fa-f]+", a):
        return int(a, 16)
    if re.fullmatch(r"-?\d+", a):
        return int(a)
    m = re.fullmatch(CAST + r"\(?\s*([A-Za-z_]\w*)\s*\+\s*(0x[0-9A-Fa-f]+|\d+)\s*\)?", a)
    if m:
        return ("sym", m.group(1), int(m.group(2), 0))
    m2 = re.fullmatch(CAST + r"\(?\s*([A-Za-z_]\w*)\s*\)?", a)
    if m2 and not MACRO_NAME.match(m2.group(1)):
        return ("sym", m2.group(1), 0)
    if a in SLOTS:
        return SLOTS[a]
    if re.fullmatch(r"[A-Za-z_]\w*", a) and not MACRO_NAME.match(a):
        return ("sym", a, 0)
    return ("raw", a)


def lit(v):
    if isinstance(v, int):
        return str(v)
    if isinstance(v, tuple):
        if v[0] == "sym":
            off = f", {v[2]}" if v[2] else ""
            return f"Sym('{v[1]}'{off})"
        return f"RawArg('{v[1]}')"
    return str(v)


def lst(args):
    return "[" + ", ".join(lit(a) for a in args) + "]"


def is_sym(v):
    return isinstance(v, tuple) and v[0] == "sym"


def num(v, d=0):
    return v if isinstance(v, int) else d


# ---------------------------------------------------------------------------
# 指令 → Dart 语句
# ---------------------------------------------------------------------------

def stmt(op, A):
    """(语句, 是否为 await 调用)"""
    if op == "CALL":
        if is_sym(A[0]) if A else False:
            return (f"await s.call({lit(A[0])});", False)
        if A and isinstance(A[0], int) and A[0] >= 0:
            return (f"await s.callSlot({A[0]});", False)
        return (f"s.placeholder('CALL');", True)

    if op == "SVAL":
        return (f"s.setSlot({num(A[0])}, {lit(A[1]) if len(A) > 1 else '0'});", True)
    if op == "SVAL2":
        return (f"s.setSlot2({num(A[0])}, {num(A[1])}, {num(A[2])});", True)
    if op in ("SADD", "SSUB", "SMUL", "SDIV", "SAND", "SORR"):
        return (f"s.slotArith('{op}', {num(A[0])}, {lit(A[1]) if len(A) > 1 else '0'});", True)

    if op == "TEXTSHOW":
        return (f"await s.textShow({num(A[0])});", False)
    if op in ("TEXTSTART", "TEXTEND", "REMA", "CLEARTEXT", "SETTEXTTYPE"):
        return (f"s.placeholder('{op}');", True)

    if op in ("LOAD1", "LOAD2", "LOAD3"):
        grp = int(op[-1])
        if len(A) > 1 and is_sym(A[1]):
            return (f"s.loadUnits({grp}, {lit(A[1])});", True)
        return (f"s.placeholder('{op}');", True)

    if op.startswith("MOVE") and not op.startswith("MOVERANGE"):
        return (f"s.moveUnit('{op}', {lst(A)});", True)

    # 换章节 —— `MNC2(n)` = `EvtChangeChapterBM(n)`（`include/eventscript.h:681`）
    # `GIVEITEMTO(pid)` —— 把槽 3 的道具给角色
    # 出处：`src/eventscr_080106FC.c:90`（`EVSUBCMD_GIVEITEMTO`）
    if op in ("GIVEITEMTO", "GIVEITEMTOMAIN"):
        if A:
            return (f"await s.giveItem({lit(A[0])}, 3);", False)
        return (f"s.placeholder('{op}');", True)

    if op == "MNC2":
        return (f"await s.changeChapter({num(A[0]) if A else 0});", False)

    # 换地图 —— 操作数是 **chapterIndex**（`src/eventscr_0800F390.c:54`）
    if op == "LOMA":
        return (f"await s.loadMap({num(A[0]) if A else 0});", False)

    if op == "STAL":
        return (f"await s.stall({num(A[0])});", False)

    # ---- 淡入/淡出 ----
    #
    # ⚠️ **缩写名是反的**，看 `src/Event17_Fade.c`：
    #     case 0: // FADU → StartLockingFadeFromBlack  （从黑淡出 = 画面出现）
    #     case 1: // FADI → StartLockingFadeToBlack    （淡到黑 = 画面消失）
    # 按名字猜会正好做反。所以这里显式映射，不靠名字。
    if op in ("FADU", "FADI", "FAWU", "FAWI"):
        d = {"FADU": "fromBlack", "FADI": "toBlack",
             "FAWU": "fromWhite", "FAWI": "toWhite"}[op]
        return (f"await s.fade(FadeDirection.{d}, {num(A[0]) if A else 0});", False)

    if op in ("END", "ENDA"):
        return ("return;", True)

    if op == "CALL_SLOT" or op.startswith("CALL_SLOT"):
        return (f"await s.callSlot({num(A[0])});", False)

    # 其余全部走兜底：**认得但本阶段不执行**，记名字而不是静默吞掉
    return (f"s.placeholder('{op}');", True)


def gen_straight(ops):
    out = []
    for op, A in ops:
        if op == "LABEL":
            continue  # 直线脚本里的 LABEL 是空操作
        if op in BRANCH_OPS:
            out.append(f"    // ⚠️ 直线模式遇到 {op}，生成器判定有误")
            continue
        s, _ = stmt(op, A)
        out.append("    " + s)
    return out


def gen_switch(ops, labels):
    """有分支：`while(true) { switch (pc) }`，`pc` 是**局部变量**（不需要存档）"""
    out = ["    var pc = 0;", "    while (true) {", "      switch (pc) {"]
    for i, (op, A) in enumerate(ops):
        out.append(f"        case {i}:")
        if op == "LABEL":
            # 标签本身不做事，直接落到下一条
            out.append(f"          pc = {i + 1};")
            out.append("          continue;")
            continue
        if op == "GOTO":
            tgt = labels.get(num(A[0]))
            out.append(f"          pc = {tgt if tgt is not None else i + 1};")
            out.append("          continue;")
            continue
        if op in ("BNE", "BEQ"):
            # ⚠️ `BNE(a, b, c)`：slot=a, 比较值=b, 跳转目标=**标签 c**
            slot, val = num(A[0]), num(A[1])
            tgt = labels.get(num(A[2]))
            if tgt is None:
                tgt = i + 1
            cmp = "==" if op == "BEQ" else "!="
            out.append(f"          if (s.slotInt({slot}) {cmp} {val}) {{ pc = {tgt}; }} "
                       f"else {{ pc = {i + 1}; }}")
            out.append("          continue;")
            continue
        if op in ("END", "ENDA"):
            out.append("          return;")
            continue
        s, _ = stmt(op, A)
        out.append("          " + s)
        out.append(f"          pc = {i + 1};")
        out.append("          continue;")
    out.append("        default:")
    out.append("          return;")
    out.append("      }")
    out.append("    }")
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", default=OUT)
    ap.add_argument("--check", action="store_true")
    a = ap.parse_args()

    files = []
    for g in SRC_GLOBS:
        files.extend(glob.glob(os.path.join(DECOMP, g), recursive=True))
    files = sorted(set(files))
    print(f"扫描 {len(files)} 个源文件")

    scripts = {}
    for f in files:
        raw = strip_comments(open(f, encoding="utf-8", errors="replace").read())
        for m in re.finditer(r"EventListScr\s+(EventScr_\w+)\s*\[\s*\]\s*=\s*\{", raw):
            name = m.group(1)
            i = m.end()
            try:
                j = raw.index("\n};", i)
            except ValueError:
                continue
            ops = []
            for line in raw[i:j].split("\n"):
                line = line.strip().rstrip(",").strip()
                if not line or line.startswith("#"):
                    continue
                mm = re.fullmatch(r"([A-Za-z_]\w*)\s*(?:\((.*)\))?", line, re.S)
                if not mm:
                    continue
                ar = [parse_arg(x) for x in split_args(mm.group(2))] if mm.group(2) else []
                ops.append((mm.group(1), ar))
            scripts[name] = ops

    # ---- ★ 并入从 `.s` 裸字节解出来的脚本 ----
    #
    # 有 **41 个脚本只以 `.4byte` 存在**（例如
    # `EventScr_Prologue_ONeillSpawn` —— 它负责放敌人）。
    # 没有它们，序章地图上永远没有敌人，也就永远到不了第 1 章。
    #
    # `parse_event_scripts_asm.py` 已经把字节解成了**同样的宏形式**，
    # 这里当成普通脚本文本走同一条解析路 —— 不另开分支。
    asm_path = os.path.join(HERE, "..", "out", "tables",
                            "event_scripts_asm.json")
    asm_added = 0
    if os.path.exists(asm_path):
        import json as _json
        asm = _json.load(open(asm_path, encoding="utf-8"))["scripts"]
        for name, lines in asm.items():
            if name in scripts:
                continue          # C 源优先 —— 它带类型与注释
            ops = []
            for line in lines:
                mm = re.fullmatch(r"([A-Za-z_]\w*)\s*(?:\((.*)\))?", line, re.S)
                if not mm:
                    continue
                ar = ([parse_arg(x) for x in split_args(mm.group(2))]
                      if mm.group(2) else [])
                ops.append((mm.group(1), ar))
            if ops:
                scripts[name] = ops
                asm_added += 1
        print(f"  并入汇编脚本 {asm_added} 个")

    print(f"解析出 {len(scripts)} 个脚本，{sum(len(v) for v in scripts.values())} 条指令")

    # 引用完整性
    missing = {}
    for name, ops in scripts.items():
        for op, ar in ops:
            for x in ar:
                if is_sym(x) and x[1].startswith("EventScr_") and x[1] not in scripts:
                    missing.setdefault(x[1], set()).add(name)

    if missing:
        print(f"\n⚠️  {len(missing)} 个被引用但**不存在**的脚本:", file=sys.stderr)
        for k, v in sorted(missing.items())[:5]:
            print(f"     {k}   ← 被 {', '.join(sorted(v)[:2])} 引用", file=sys.stderr)

    # 变量名（合法且唯一）
    def var_of(n):
        v = re.sub(r"^EventScr_", "", n)
        v = re.sub(r"[^A-Za-z0-9]+", "_", v).strip("_") or "unnamed"
        if v[0].isdigit():
            v = "scr_" + v
        return v

    names, used = {}, set()
    for n in sorted(scripts):
        v = var_of(n)
        while v in used:
            v += "_"
        used.add(v)
        names[n] = v

    straight = [n for n in sorted(scripts)
                if not any(op in BRANCH_OPS or op in ("BNE", "BEQ", "GOTO")
                           for op, _ in scripts[n])]

    lines = [
        "// arch-exempt: R4 「完全可序列化」这条约束已由用户明确取消"
        "（不需要随时存档），",
        "//            所以场景脚本用 async 函数直接表达「等玩家按键」，"
        "不再用可序列化的状态机。",
        "//",
        "// ignore_for_file: type=lint, dead_code",
        "//",
        "// PORT OF: src/event.c + src/TalkInterpret.c（场景脚本）",
        "// ^ 只压 lint 噪音；**类型错误照样报** —— 见 analysis_options.yaml 的说明。",
        "//",
        "// GENERATED —— 由 tools/pipeline/extract/gen_scene_dart.py 生成。",
        "// **请勿手改**：改 C 源码或生成器，然后重新生成。",
        "//",
        "// 每个脚本编译成一个 `async` 函数 —— **没有指令列表，没有解释器**。",
        f"// 脚本 {len(scripts)} 个（直线 {len(straight)} 个 / 有分支 "
        f"{len(scripts) - len(straight)} 个）",
        "//",
        "// 直线脚本是顺序的 async 代码；有分支的用 `while(true){switch(pc)}`，",
        "// `pc` 是**局部变量**（因为不需要存档）。",
        "",
        "// ignore_for_file: lines_longer_than_80_chars",
        "",
        "import 'scene.dart';",
        "",
    ]

    for n in sorted(scripts):
        ops = scripts[n]
        has_branch = any(op in BRANCH_OPS or op in ("BNE", "BEQ", "GOTO")
                         for op, _ in ops)
        lines.append(f"/// `{n}`")
        lines.append(f"Future<void> {names[n]}(Scene s) async {{")
        if has_branch:
            labels = {num(A[0]): i for i, (op, A) in enumerate(ops) if op == "LABEL"}
            lines.extend(gen_switch(ops, labels))
        else:
            lines.extend(gen_straight(ops))
        lines.append("}")
        lines.append("")

    # 兜底：引用了但没定义的脚本 → 生成一个"记录缺失"的函数，
    # 这样代码仍然能编译，但缺口**在生成产物里可见**
    for n in sorted(missing):
        v = "missing_" + re.sub(r"[^A-Za-z0-9]+", "_", n)
        lines.append(f"/// ⚠️ `{n}` —— 上游尚未 carve，生成的是**记录缺失**的占位")
        lines.append(f"Future<void> {v}(Scene s) async {{")
        lines.append(f"  s.missing.add('{n}');")
        lines.append("}")
        lines.append("")

    lines.append("/// **真正被 carve 出来**的脚本名。")
    lines.append("///")
    lines.append("/// ⚠️ 与 `allSceneFns` 的键**不一样**：后者还包含下面那些")
    lines.append("/// 占位函数。存在性检查必须用本集合 —— 用 `allSceneFns` 的话")
    lines.append("/// 占位让「缺失」看起来「存在」，检查就失效了（踩过）。")
    lines.append("final Set<String> definedSceneScripts = {")
    for n in sorted(scripts):
        lines.append(f"  '{n}',")
    lines.append("};")
    lines.append("")
    lines.append("/// 脚本名 → 入口函数")
    lines.append("final Map<String, Future<void> Function(Scene)> allSceneFns = {")
    for n in sorted(scripts):
        lines.append(f"  '{n}': {names[n]},")
    for n in sorted(missing):
        v = "missing_" + re.sub(r"[^A-Za-z0-9]+", "_", n)
        lines.append(f"  '{n}': {v},")
    lines.append("};")
    lines.append("")

    src = "\n".join(lines)

    if a.check:
        cur = open(a.out, encoding="utf-8").read() if os.path.exists(a.out) else ""
        if cur != src:
            print("❌ 生成的 Dart 与仓库里的不一致", file=sys.stderr)
            return 1
        print("✅ 生成的 Dart 与仓库一致")
        return 0

    os.makedirs(os.path.dirname(a.out), exist_ok=True)
    with open(a.out, "w", encoding="utf-8") as f:
        f.write(src)

    print(f"\n→ {a.out}  ({os.path.getsize(a.out) // 1024} KB)")
    print(f"   直线 {len(straight)} / 有分支 {len(scripts) - len(straight)} / "
          f"缺失占位 {len(missing)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
