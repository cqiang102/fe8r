#!/usr/bin/env python3
"""
M1 第一步：特征扫描。

目的不是立刻分类，而是**先验证特征标记本身是对的**——拿 §2.6 实测出来的
特征命中数当标尺（Proc 1301 / Efx 598 / 单位道具 577 / 菜单 341 / ...）。
如果扫描结果与那张表对得上，"GBA 代码里怎么做不值得保留、做什么必须保留"
这条判断线才有可执行的基础。

用法:
    python3 tools/m1/scan_features.py                # 打印特征命中统计
    python3 tools/m1/scan_features.py --diff         # 与 §2.6 的表对比
"""
import argparse
import json
import os
import re
import sys
from collections import defaultdict

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.abspath(os.path.join(HERE, "..", ".."))
DECOMP = os.path.join(REPO, "third_party", "fireemblem8j")
SRC = os.path.join(DECOMP, "src")

# ---------------------------------------------------------------- 特征定义
#
# 每条特征 = (键, 正则列表, 归属层, 一行说明)
#
# 正则用 `\b` 界定标识符边界，避免 `Text_` 命中 `Context_` 这类误报。
# 全部按"整个文件里出现过"判定（与 §2.6 的口径一致）。

LAYER_PLATFORM = "platform"
LAYER_PRESENT = "present"
LAYER_RULES = "rules"

# 每条 = (键, 归属层, 是否决定性, 正则, 说明)
#
# **决定性 / 提示性的区分是这套分类法成立的关键。**
#
# 实测教训：AI 决策文件（`AiEscapeAction` / `CpDecide_Main` / `CpPerform_*`）
# 也用 Proc 做控制流，如果"调用 Proc"就算表现层，331 个规则层文件会被
# 误判成"重写"，AI 行为直接丢失。
#
# 所以：
#   * **决定性** = 只有这一层才会定义的东西
#       `ProcScr_`（定义一段演出时序）是表现层；`Proc_Start`（用协程跑逻辑）不是。
#       `BattleGenerate`（战斗公式）是规则层；`NextRN`（取个随机数）不是。
#   * **提示性** = 两层都可能用的通用设施，只做加权，不单独定性。
FEATURES = [
    # ================= §4.8 N1–N10：平台层（全部决定性）=================
    ("N6_hw_regs", LAYER_PLATFORM, True,
     r"\bREG_(DISPCNT|BG[0-3]CNT|WIN\w*|BLDY|MOSAIC|VCOUNT|DISPSTAT|KEYCNT)\b"
     r"|\bgLCDRegisters\b|\bDMA[0-3]\b|\bIntrMain\b|\bREG_WAITCNT\b|\bREG_IME\b",
     "硬件寄存器 / DMA / 中断"),

    ("N7_sram", LAYER_PLATFORM, True,
     r"\bReadSramFast\b|\bVerifySramFast\b|\bWriteSram\w*|\bgSram\b|\bSramInit\b",
     "SRAM / 存档硬件时序"),

    # ⚠️ 不能匹配裸词 `m4a`：`#include "m4a.h"` 到处都是（实测 1890 个文件中招）
    ("N8_m4a", LAYER_PLATFORM, True,
     r"\bMPlay(Start|Open|Main|Continue|Stop|Jump|FadeOut)\b|\bSoundMain\w*"
     r"|\bSoundInit\b|\bMPlayExt\w*|\bm4aSound\w*|\bgMPlay\w*",
     "m4a 音频引擎"),

    ("N9_compress", LAYER_PLATFORM, True,
     r"\bLZ77\w*|\bHuffman\w*|\bDecompress\b|\bRL_Uncompress\b|\bLZ77UnComp\w*",
     "压缩算法（管线期离线解压）"),

    ("N10_startup", LAYER_PLATFORM, True,
     r"\bAgbMain\b|\bCrashHandler\b|\bInitVector\b|\bAgbMain\b",
     "GBA 启动与主循环"),

    ("sio", LAYER_PLATFORM, True,
     r"\bSio\w+|\bMultiBoot\w*|\bSIO_\w+|\bgSio\w*",
     "串口 / 联机对战硬件"),

    # ================= 表现层 =================
    #
    # 决定性的只有"**定义一段演出**"的东西：Proc 脚本表、特效、菜单骨架、
    # 字形绘制、OAM/VRAM 写入。仅仅 `Proc_Start` 一个协程不算——
    # AI 决策与事件引擎也用协程跑逻辑（实测 331 个规则层文件落在这个陷阱里）。
    ("P_seq", LAYER_PRESENT, True,
     r"\bProcScr_\w+|\bstruct ProcScr\b|\bgProcScr\w*",
     "Proc 脚本表（演出时序定义）"),

    # 任何 `XxxProc` 结构体都是一段协作式演出的状态——
    # 早期只写了 `struct Proc`，结果 `struct FaceBlinkProc` / `struct APHandle`
    # 这类命名全漏了（实测 300+ 个地址名文件卡在这里）。
    ("P_procstruct", LAYER_PRESENT, True,
     r"\bstruct\s+\w*Proc\b|\b\w+Proc\s*\*|\bPROC_HEADER\b",
     "Proc 系结构体（演出状态机）"),

    ("P_efx", LAYER_PRESENT, True,
     r"\bEfx\w*|\bStartEfx\w*|\bColorFade\w*|\bPaletteFade\w*|\bMosaic\w*"
     r"|\bgPaletteBuffer\b|\bPaletteAnim\w*|\bStartPaletteFade\b"
     r"|\bSetBlend\w*|\bStartFadeCore\b|\bInterpolate\w*|\bSetSpecialColEffect\w*",
     "特效与混合 / 调色板过渡"),

    ("P_menu", LAYER_PRESENT, True,
     r"\bMenuProc\b|\bMenuItemProc\b|\bStartMenu\b|\bHelpBox\b|\bMenu_Start\b"
     r"|\bNewMenu\w*|\bgMenu\w*|\bMenu_Draw\w*",
     "菜单 / UI 框架"),

    ("P_text", LAYER_PRESENT, True,
     r"\bText_(Init|Draw|Print|Clear|SetCursor|Advance|Insert|Cancel)\w*"
     r"|\bDrawGlyph\w*|\bTextPrinter\w*|\bgTextFont\b|\bGlyph_\w+"
     r"|\bStartCgText\b|\bCgText\w*|\bGetStringFromIndex\b|\bText_\w+"
     r"|\bstruct\s+Text\b|\bAppendString\b|\bStringInsert\w*",
     "文本绘制"),

    ("P_oam", LAYER_PRESENT, True,
     r"\bPutOam\w*|\bgOamData\b|\bTsa_\w+|\bAPProc\w*|\bOBJCHR\b|\bBGCHR\b"
     r"|\bPutSprite\w*|\bgObjectData\b|\bOAM_\w+|\bAnimDelete\b|\bAnimDisplay\w*"
     r"|\bAP_\w+|\bstruct\s+APHandle\b|\bAPHandle\b|\bAnim_\w+|\bstruct\s+Anim\b",
     "OAM / VRAM / 精灵表 / AP 动画"),

    # --- 提示性：两层都用，只做加权 ---
    ("P_proc_use", LAYER_PRESENT, False,
     r"\bProc_\w+|\bPROC_\w+|\bProcPtr\b|\bstruct Proc\b|\bgProc\w*\b",
     "使用了 Proc 协程（通用控制流，两层都用）"),

    # ================= 规则层 =================
    #
    # 同样只把"定义规则"的算决定性。"读个单位名字来显示"不算规则层。
    ("R_ai", LAYER_RULES, True,
     r"\bAiAttempt\w*|\bAiDecide\w*|\bAiAction\w*|\bCpDecide\w*|\bCpPerform\w*"
     r"|\bCpOrder\w*|\bgAi\w*|\bAiFill\w*|\bAiUpdate\w*",
     "AI 决策"),

    ("R_battle", LAYER_RULES, True,
     r"\bBattleGenerate\w*|\bComputeBattle\w*|\bBattleApply\w*"
     r"|\bBattleHit\w*|\bBattleInit\w*|\bBattleCalc\w*|\bBattleForecast\w*",
     "战斗结算公式"),

    ("R_event", LAYER_RULES, True,
     r"\bEventEngine\w*|\bCallEvent\w*|\bEventListScr\b|\bEventScr_\w+"
     r"|\bEvent_Run\w*|\bEVT_CMD_\w+",
     "事件引擎"),

    ("R_map", LAYER_RULES, True,
     r"\bMapFlood\w*|\bGetMovementCost\w*|\bgBmMap\w*|\bMapAdd\w*"
     r"|\bBMMAP_\w+|\bMapChange\w*|\bTerrain\w*Lookup\w*|\bAddTrap\b",
     "地图 / 寻路 / 地形规则"),

    ("R_unit_def", LAYER_RULES, True,
     r"\bgUnitLut\b|\bgItemData\b|\bgClassData\b|\bgUnitPool\b"
     r"|\bUnitMaxHp\b|\bSetUnit\w*|\bUnit\w*State\b|\bApplyUnit\w*",
     "单位 / 道具 / 职业数据定义"),

    # --- 提示性 ---
    ("R_unit_use", LAYER_RULES, False,
     r"\bGetUnit\w*|\bGetItem\w*|\bGetClassData\w*|\bgActiveUnit\b",
     "读取单位 / 道具（两层都可能读）"),

    ("R_rng_use", LAYER_RULES, False,
     r"\bNextRN\w*|\bRoll1RN\b|\bRoll2RN\b",
     "调用乱数（取随机数本身不定义层）"),
]

# §2.6 表里的实测值，用来验证特征标记是否靠谱
EXPECTED = {
    "N1_proc": 1301,
    "N5_efx": 598,
    "unit_item": 577,
    "N2_menu": 341,
    "N4_oam_vram": 311,
    "map_path": 299,
    "N3_text": 282,
    "ai": 186,
    "event": 185,
    "N6_hw_regs": 89,
    "N7_sram": 76,
    "battle": 49,
    "N8_m4a": 22,
}


def strip_noise(text):
    """去掉 `#include` 行与注释后再匹配。

    这一步不是锦上添花——不加的话 `#include "m4a.h"` 会让几乎所有文件都
    命中"音频引擎"（实测 6213 个文件里有 1890 个中招），
    因为反编译项目的很多头文件是"人人都 include"的。
    """
    out = []
    for line in text.split("\n"):
        st = line.lstrip()
        if st.startswith("#include") or st.startswith("#pragma"):
            continue
        out.append(line)
    text = "\n".join(out)
    text = re.sub(r"/\*.*?\*/", " ", text, flags=re.S)   # 块注释
    text = re.sub(r"//[^\n]*", " ", text)                  # 行注释
    return text


def compile_features():
    out = []
    for key, layer, decisive, pattern, desc in FEATURES:
        out.append((key, layer, decisive, re.compile(pattern), desc))
    return out


def src_files():
    """`src/*.c`（顶层）。§2.6 的 6213 就是这个口径。"""
    return sorted(
        os.path.join(SRC, f) for f in os.listdir(SRC)
        if f.endswith(".c") and os.path.isfile(os.path.join(SRC, f))
    )


def scan():
    feats = compile_features()
    files = src_files()
    hits = defaultdict(set)
    per_file = {}

    for path in files:
        try:
            text = open(path, encoding="utf-8", errors="replace").read()
        except OSError:
            continue
        text = strip_noise(text)
        matched = set()
        for key, layer, decisive, rx, desc in feats:
            if rx.search(text):
                hits[key].add(path)
                matched.add(key)
        per_file[path] = matched

    return files, hits, per_file


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--diff", action="store_true", help="与 §2.6 的表对比")
    ap.add_argument("--json", help="把逐文件命中写成 JSON")
    a = ap.parse_args()

    files, hits, per_file = scan()
    print(f"扫描 {len(files)} 个文件（src/*.c）\n")

    print(f"{'特征':<16}{'命中文件数':>10}{'§2.6 实测':>12}{'偏差':>10}  说明")
    print("-" * 76)
    rows = []
    for key, layer, decisive, rx, desc in FEATURES:
        n = len(hits[key])
        exp = EXPECTED.get(key)
        rows.append((key, n, exp, desc))
    # 按 §2.6 的顺序（命中数降序）展示有实测值的，其余附后
    rows.sort(key=lambda r: (-(r[2] if r[2] else 0), -r[1]))
    for key, n, exp, desc in rows:
        if exp is None:
            print(f"{key:<16}{n:>10}{'—':>12}{'—':>10}  {desc}")
        else:
            d = n - exp
            flag = "✓" if abs(d) <= max(30, exp * 0.08) else "✗"
            print(f"{key:<16}{n:>10}{exp:>12}{d:>+10}  {flag} {desc}")

    if a.json:
        out = {os.path.relpath(p, REPO): sorted(v) for p, v in per_file.items()}
        json.dump(out, open(a.json, "w"), ensure_ascii=False, indent=0)
        print(f"\n逐文件命中已写出：{a.json}")

    return 0


if __name__ == "__main__":
    sys.exit(main())
