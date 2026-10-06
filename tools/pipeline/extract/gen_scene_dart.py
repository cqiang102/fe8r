#!/usr/bin/env python3
"""
从 C 源码**直接生成 Dart** —— 没有 JSON 中间层。

## 为什么去掉 JSON

第一版是：

    C 源码 → [Python] → scene_scripts.json (403KB)
           → [Dart 运行时 jsonDecode + 手工组装] → 字符串操作码 + 无类型参数

运行时才发现的事：指令名字拼错、参数类型不对、引用了不存在的脚本。
**而这些在生成时全都知道。**

现在：

    C 源码 → [Python] → lib/core/event/scene_data.g.dart

  * 数据变成**类型化的 Dart 代码**，编译器帮我们检查
  * 引用了不存在的脚本 → **生成时报错**，不是运行时在 HUD 上显示"缺 6"
  * 加载时没有 JSON 解析开销
  * IDE 能跳转、能重命名

## 生成的 Dart 长什么样

    final prologueBeginningScene = SceneScript(
      'EventScr_Prologue_BeginningScene',
      const <SceneOp>[
        CallScript(Sym('EventScr_Prologue_RenaisThroneCutscene')),
        SetSlot(2, Sym('EventScr_Prologue_EirikaAttacked')),
        AsmCallOp(Sym('BmGuideTextSetAllGreen', 1)),
        ...
      ],
    );

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
    """参数 → Django 侧的字面量源码（字符串），或 ('sym', name, off)"""
    a = a.strip()
    if re.fullmatch(r"0x[0-9A-Fa-f]+", a):
        return int(a, 16)
    if re.fullmatch(r"-?\d+", a):
        return int(a)
    # 类型转换前缀不止 `(u8 *)` —— 还有 `(void *)` / `(void*)` / `(u8*)`。
    # 第一版只认第一种，结果 `CALL((void *)(gap_00006274 + 1))`
    # 这类**目标有名字**的调用被当成"解析不了"。
    cast = r"(?:\(\s*(?:u8|u16|u32|void|int)\s*\*\s*\)\s*)?"
    m = re.fullmatch(
        cast + r"\(?\s*([A-Za-z_]\w*)\s*\+\s*(0x[0-9A-Fa-f]+|\d+)\s*\)?", a)
    if m:
        return ("sym", m.group(1), int(m.group(2), 0))
    if a in SLOTS:
        return SLOTS[a]
    # 可能带类型转换：`(void*)X` / `(u8 *)X`
    m2 = re.fullmatch(cast + r"\(?\s*([A-Za-z_]\w*)\s*\)?", a)
    if m2 and not MACRO_NAME.match(m2.group(1)):
        return ("sym", m2.group(1), 0)
    if re.fullmatch(r"[A-Za-z_]\w*", a) and not MACRO_NAME.match(a):
        return ("sym", a, 0)
    return ("raw", a)


def dart_lit(v):
    """Python 值 → Dart 字面量源码"""
    if isinstance(v, int):
        return str(v)
    if isinstance(v, tuple):
        if v[0] == "sym":
            off = f", {v[2]}" if v[2] else ""
            return f"Sym('{v[1]}'{off})"
        return f"RawArg('{v[1]}')"
    return str(v)


def dart_list(args):
    return "[" + ", ".join(dart_lit(a) for a in args) + "]"


# 指令名 → 生成的 Dart 表达式
def to_dart(op, args, known_scripts):
    A = args

    def sym(i=0):
        return A[i] if i < len(A) and isinstance(A[i], tuple) and A[i][0] == "sym" else None

    def num(i=0, d=0):
        return A[i] if i < len(A) and isinstance(A[i], int) else d

    if op == "CALL":
        s = sym()
        return f"CallScript({dart_lit(s)})" if s else f"MiscOp('CALL', {dart_list(A)})"

    if op == "SVAL":
        slot = num(0)
        val = dart_lit(A[1]) if len(A) > 1 else "0"
        return f"SetSlot({slot}, {val})"

    if op == "SVAL2":
        return f"SetSlot2({num(0)}, {num(1)}, {num(2)})"

    if op in ("SADD", "SSUB", "SMUL", "SDIV", "SAND", "SORR"):
        src = dart_lit(A[1]) if len(A) > 1 else "0"
        return f"SlotArith('{op}', {num(0)}, {src})"

    if op.startswith("SENQUEUE"):
        return f"EnqueueOps({num(0)})"

    if op in ("BNE", "BEQ"):
        return (f"BranchIf(equal: {str(op == 'BEQ').lower()}, slot: {num(0)}, "
                f"label: {num(1)}, opCount: {num(2)})")

    if op == "GOTO":
        return f"GoTo({num(0)})"
    if op == "LABEL":
        return f"Label({num(0)})"
    if op in ("END", "ENDA"):
        return f"EndScript({str(op == 'ENDA').lower()})"
    if op.startswith("CALL_SLOT") or op == "CALL_SLOT":
        return f"CallFromSlot({num(0)})"

    if op == "TEXTSHOW":
        return f"ShowTextOp({num(0)})"
    if op in ("TEXTSTART", "TEXTEND"):
        return f"TextBoxOp({str(op == 'TEXTSTART').lower()})"
    if op == "REMA":
        return "ClearTextOp()"
    if op == "SETTEXTTYPE":
        return f"SetTextTypeOp({num(0)})"

    if op in ("LOAD1", "LOAD2", "LOAD3"):
        s = sym(1)
        grp = int(op[-1])
        if s:
            return f"LoadUnitsOp({grp}, {dart_lit(s)})"
        return f"MiscOp('{op}', {dart_list(A)})"

    if op.startswith("MOVE"):
        return f"MoveUnitOp('{op}', {dart_list(A)})"
    if op.startswith("CAMERA"):
        return f"CAMERA_PLACEHOLDER"  # 下面统一替换
    if op.startswith("CURSOR"):
        return f"CursorOp('{op}', {dart_list(A)})"
    if op in ("ENUN", "ENUT", "ENDA_UNIT"):
        return f"EndUnitOp('{op}')"

    if op in ("MUSI", "MUSC", "MUSC2", "BGMCHANGE_12", "BGMCHANGE_13",
              "BGMOVERWRITE", "BGMVOLUMECHANGE", "MUSC_STOP"):
        return f"MusicOp('{op}', {dart_list(A)})"
    if op.startswith("FAD"):
        return f"FadeOp('{op}', {dart_list(A)})"
    if op == "STAL":
        return f"StallOp({num(0)})"
    if op in ("EVBIT_T", "EVBIT_F"):
        return f"EventBitOp({str(op == 'EVBIT_T').lower()}, {num(0)})"
    if op in ("ASMC", "ASMC2"):
        s = sym()
        return f"AsmCallOp({dart_lit(s)})" if s else f"MiscOp('{op}', {dart_list(A)})"

    if op.startswith(("LOADFACE", "DISPLAYFACE", "MOVEFACE", "CLEARFACE",
                      "FACESTART", "FACEEND")):
        return f"FaceOp('{op}', {dart_list(A)})"
    if op.startswith(("SHOWBG", "CLEARSCREEN", "CLEARBG", "SETBACKGROUND")):
        return f"BackgroundOp('{op}', {dart_list(A)})"

    return f"MiscOp('{op}', {dart_list(A)})"


def to_dart_fixed(op, args, known):
    r = to_dart(op, args, known)
    if r == "CAMERA_PLACEHOLDER" or r.startswith("CAMERA_PLACEHOLDER"):
        return f"CameraOp('{op}', {dart_list(args)})"
    return r


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", default=OUT)
    ap.add_argument("--check", action="store_true",
                    help="只检查，不写文件（CI 用）")
    a = ap.parse_args()

    files = []
    for g in SRC_GLOBS:
        files.extend(glob.glob(os.path.join(DECOMP, g), recursive=True))
    files = sorted(set(files))
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
            ops = []
            for line in raw[i:j].split("\n"):
                line = line.strip().rstrip(",").strip()
                if not line or line.startswith("#"):
                    continue
                mm = re.fullmatch(r"([A-Za-z_]\w*)\s*(?:\((.*)\))?", line, re.S)
                if not mm:
                    continue
                on = mm.group(1)
                ar = [parse_arg(x) for x in split_args(mm.group(2))] \
                    if mm.group(2) else []
                ops.append((on, ar))
            scripts[name] = ops

    print(f"解析出 {len(scripts)} 个脚本，"
          f"{sum(len(v) for v in scripts.values())} 条指令")

    # ---- 引用完整性：引用了不存在的脚本就**报错** ----
    #
    # 这是去掉 JSON 的主要收益：运行时才发现的"缺 6 个脚本"
    # 变成生成时就能看见的清单。
    missing = {}
    for name, ops in scripts.items():
        for on, ar in ops:
            for x in ar:
                if isinstance(x, tuple) and x[0] == "sym" \
                        and x[1].startswith("EventScr_") \
                        and x[1] not in scripts:
                    missing.setdefault(x[1], set()).add(name)

    if missing:
        print(f"\n⚠️  {len(missing)} 个被引用但**不存在**的脚本 "
              f"（反编译项目尚未 carve）:", file=sys.stderr)
        for k, v in sorted(missing.items()):
            print(f"     {k}   ← 被 {', '.join(sorted(v)[:2])} 引用",
                  file=sys.stderr)

    # ---- 生成 ----
    lines = [
        "// GENERATED —— 由 tools/pipeline/extract/gen_scene_dart.py 生成。",
        "// **请勿手改**：改 C 源码或生成器，然后重新生成。",
        "//",
        f"// 来源：third_party/fireemblem8j/src/**/*.c",
        f"// 脚本 {len(scripts)} 个，"
        f"指令 {sum(len(v) for v in scripts.values())} 条",
        "//",
        "// 这里**没有 JSON** —— 数据直接是类型化的 Dart 代码，",
        "// 引用了不存在的脚本会在生成时报出来，而不是运行时。",
        "",
        "// ignore_for_file: prefer_const_constructors, lines_longer_than_80_chars,",
        "// ignore_for_file: non_constant_identifier_names",
        "",
        "import 'scene_op.dart';",
        "",
        "",
    ]

    # 变量名：从脚本名派生，**保证合法且唯一**。
    #
    # ⚠️ 不能直接拿去掉前缀的名字 —— 有 `EventScr_9EE84C` 这种，
    # 去掉前缀就是 `9EE84C`，**以数字开头不是合法 Dart 标识符**。
    def var_of(name):
        v = re.sub(r"^EventScr_", "", name)
        v = re.sub(r"[^A-Za-z0-9]+", "_", v).strip("_")
        if not v:
            v = "unnamed"
        if v[0].isdigit():
            v = "scr_" + v
        return v

    seen_vars = {}
    for name in sorted(scripts):
        v = var_of(name)
        if v in seen_vars:
            v = f"{v}_{seen_vars[v]}"
            seen_vars[var_of(name)] += 1
        seen_vars.setdefault(var_of(name), 1)
        seen_vars.setdefault(v, 1)

    var_names = {}
    used = set()
    for name in sorted(scripts):
        v = var_of(name)
        while v in used:
            v += "_"
        used.add(v)
        var_names[name] = v

    # 按名字排序，保证生成结果稳定（同样的输入 → 同样的输出）
    for name in sorted(scripts):
        var = var_names[name]
        lines.append(f"/// `{name}`")
        lines.append(f"final {var} = SceneScript(")
        lines.append(f"  '{name}',")
        lines.append("  const <SceneOp>[")
        for on, ar in scripts[name]:
            lines.append(f"    {to_dart_fixed(on, ar, scripts)},")
        lines.append("  ],")
        lines.append(");")
        lines.append("")

    lines.append("/// 全部脚本：名字 → 脚本")
    lines.append("final Map<String, SceneScript> allSceneScripts = {")
    for name in sorted(scripts):
        lines.append(f"  '{name}': {var_names[name]},")
    lines.append("};")
    lines.append("")

    if missing:
        lines.append("/// 被引用但**上游尚未 carve**的脚本名。")
        lines.append("///")
        lines.append("/// 生成器把它们列出来而不是让运行时去发现 ——")
        lines.append("/// 调用方据此决定「留空继续」还是「报错停止」。")
        lines.append("const Set<String> missingSceneScripts = {")
        for k in sorted(missing):
            lines.append(f"  '{k}',")
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
    return 0


if __name__ == "__main__":
    sys.exit(main())
