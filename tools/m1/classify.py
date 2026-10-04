#!/usr/bin/env python3
"""
M1：6213 个源文件的层归类。

## 要解决什么

技术方案 §2.6 把 `src/*.c` 的 6213 个文件分成四类：

    平台层  485   不再存在（Flutter 直接替代）
    表现层  2151  用 Flutter 原语重新实现，不移植
    规则层  1051  必须 1:1 移植
    未分类  2911  ← M1 要把它降到 0（决策 D19）

## 为什么不能只靠符号特征

纯符号特征的扫描会留下 2600+ 个未分类（实测），因为大量文件的语义没有
从地址名还原出来（`sub_803A2E8` 这类）。而 D19 要求未分类为 0——
**每一个文件都必须有一条能写进任务配方的结论。**

所以这里用**五级判定**，从强到弱，每级都记录"是哪条规则判的"：

    A 空函数        `nullsub_*` 这种空壳，直接舍弃
    B 强特征        §4.8 N1–N10 的符号特征（Proc / Efx / Menu / REG_ / ...）
    C 调用图传播    被谁调用、调用了谁——文件在依赖图里的位置决定它属于哪层
    D 弱特征        改游戏状态还是改硬件/显存（比符号名更接近本质）
    E 命名兜底      目录与名字里的语义（banim- / worldmap / eventscr / sio）

**每一级都必须有客观判据**，并且最终输出里带着"判据"这一列，
这样派发任务时能直接抄进配方，也能一眼看出哪些结论是勉强下的。

## 用法

    python3 tools/m1/classify.py                     # 跑分类，打印统计
    python3 tools/m1/classify.py --csv out.csv       # 导出逐文件清单
    python3 tools/m1/classify.py --why Ch1Map        # 查某个文件为什么这么判
"""
import argparse
import csv
import os
import re
import sys
from collections import Counter, defaultdict

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.abspath(os.path.join(HERE, "..", ".."))
DECOMP = os.path.join(REPO, "third_party", "fireemblem8j")
SRC = os.path.join(DECOMP, "src")

sys.path.insert(0, HERE)
import scan_features as sf  # noqa: E402

DISCARD = "discard"      # 平台层：不再存在
REWRITE = "rewrite"      # 表现层：用 Flutter 原语重写
PORT = "port"            # 规则层：1:1 移植
DATA = "data"            # 数据层：管线自动导出（本轮不涉及 src/*.c，留给 src/data）

LAYER_ORDER = [PORT, REWRITE, DISCARD, DATA]

# ---------------------------------------------------------------- A 级：空函数

NULLSUB_RX = re.compile(r"^nullsub_", re.I)

# ---------------------------------------------------------------- D 级：弱特征
#
# 比符号名更接近本质：**这个函数动的是游戏状态，还是硬件/显存？**
#
# 规则层的本质是"读写游戏状态"：单位、道具、地图、章节进度、回合。
# 表现层的本质是"往硬件能看见的地方写东西"：调色板缓冲、OAM、BG 图块。

# 游戏状态全局：碰到它们基本可以断定是规则层
GAME_STATE_RX = re.compile(
    r"\bg(PlaySt|ChapterData|BmMap\w*|UnitLut|UnitPool|ActiveUnit|Units|ItemData"
    r"|ClassData|Trap\w*|MapChangeData|Support\w*|SupplyItems|Convoy\w*"
    r"|ArenaData|EventSlots|GlobalFlags|ChapterFlags|BWLData|GameSave\w*)\b"
    r"|\bGetUnit\w*\(|\bGetItem\w*\(|\bSetUnit\w*\(|\bUnit\w*State\b"
)

# 硬件可见的写目标：碰到它们基本可以断定是表现层
PRESENT_RX = re.compile(
    r"\bg(PaletteBuffer|Pal\w*Buffer|OamData|Oam\w*|Vram\w*|Bg\w*Buffer"
    r"|Lcd\w*|DispCnt|Obj\w*Buffer)\b"
    r"|\bPutOam\w*\(|\bPutSprite\w*\(|\bCopyToPaletteBuffer\s*\(|\bCpuFastCopy\s*\("
    r"|\bWriteToVram\w*\(|\bBG_\w+\("
)

# ---------------------------------------------------------------- E 级：命名兜底
#
# 名字里带明确语义的，按语义判。这些规则**只看文件名**，所以必须足够可靠；
# 拿不准的一律不写进来，留给人工清单。

# 名称规则。**同时作用于文件名与文件里定义的函数名**——
# 因为大量文件是按 ROM 地址命名的（`exact_08005c68.c`），
# 但里面的函数叫 `FaceBgBlink_Init`，语义在函数名上而不是文件名上。
NAME_RULES = [
    # ---------- 平台层 ----------
    (r"Cgb\w*", DISCARD, "GB 音源硬件寄存器（m4a 的底层，§4.8 N8）"),
    (r"^Sram|^Sio|MultiBoot", DISCARD, "SRAM / 串口硬件（§4.8 N7/N6）"),
    (r"^REG_|^Dma\w*|^Intr\w*|IrqHandler", DISCARD, "硬件寄存器与中断"),
    (r"^LZ77|^Huffman|^RLUnComp|UnCompVram|UnCompWram", DISCARD, "压缩算法（§4.8 N9）"),

    # ---------- 规则层 ----------
    (r"^Ai\w*|^Cp(Decide|Perform|Order)\w*", PORT, "AI 决策"),
    (r"^Battle\w*|^ComputeBattle|^BmBattle", PORT, "战斗结算"),
    (r"^Map(Flood|Add|Change|Data)|^BmMap|^GetMovementCost|Terrain", PORT, "地图 / 寻路 / 地形"),
    (r"^Trap\w*|^CountDown\w*|^AddTrap|^ApplyTrap", PORT, "陷阱（规则层）"),
    (r"^Event\w*|^CallEvent|EventEngine", PORT, "事件引擎"),
    (r"^Convoy\w*|^Supply\w*", PORT, "运输队（规则层）"),
    (r"^Support\w*|^Affinity\w*", PORT, "支援（规则层）"),
    (r"^Unit\w*|^GetUnit\w*|^SetUnit\w*|Unitdef", PORT, "单位（规则层）"),
    (r"^Item\w*|^GetItem\w*", PORT, "道具（规则层）"),
    (r"^Growth\w*|^Promotion\w*|^ClassChg\w*|Classchg", PORT, "成长 / 转职（规则数值）"),
    (r"^Arena\w*(?!Ui)", PORT, "斗技场结算（规则层）"),
    (r"^Bmsave|^Save\w*Game|^WriteGameSave|^ReadGameSave|^GameCtrl_\w*Save|^BonusClaim\w*Save|^BonusClaim_Read", PORT, "存档逻辑（介质换 JSON）"),
    (r"^Init\w*(Ruins|Tower|Dungeon)\w*|^IsValidExtraMap", PORT, "塔 / 遗迹进度（规则层）"),
    (r"^ExecFireTileTrap|^CanAssassinPlaceTrap|^ExecNightmareStaff|^ExecAllAIS", PORT, "陷阱 / AI 执行（规则层）"),
    (r"^LA\w*|^LABattleMap|^LAUnit", PORT, "联机对战结算（规则层）"),
    (r"^EndSioSession", DISCARD, "串口会话（§4.8 N6）"),
    (r"^EndingDetails|^Subtitle", REWRITE, "结局演出细节"),
    (r"^GmIsNodeInList|^GetOverallRank|^GetNextFreeIcon|^GetSelectedGameOption", PORT, "列表 / 评价 / 选项查询（规则层 helper）"),
    (r"^Bmlib_\w*|^ClearModM|^Clear_UnkData|^ClearBgsModified", REWRITE, "底层缓冲清理"),
    (r"^Shop(?!Ui)|^Armory|^Vendor", PORT, "商店逻辑（规则层）"),
    (r"^Dungeon\w*(?!Record)", PORT, "塔 / 遗迹进度（规则层）"),

    # ---------- 表现层 ----------
    (r"^Spline\w*", REWRITE, "样条插值（动画 / 界面）"),
    (r"^Menu\w*|^StartMenu|^HelpBox|^AtMenu|^BoxDialogue", REWRITE, "菜单 / UI（§4.8 N2）"),
    (r"^Ui\w*|^UiSupport|\w+Ui$|\w+Menu$|\w+Screen$", REWRITE, "UI 界面（§4.8 N2）"),
    (r"^Prep\w*|^Prepscreen", REWRITE, "出击准备界面（§4.8 N2）"),
    (r"^Stat(Screen|screen)|UnitListScreen|^StatusScreen", REWRITE, "状态 / 列表界面"),
    (r"^Draw\w*|^Display\w*|^Print\w*|^Blit\w*|^Put\w*(Tile|Sprite|Oam)", REWRITE, "绘制"),
    (r"(?i)^efx\w*|^Fade\w*|^Blend\w*|^Ekr\w*|^Palette\w*", REWRITE, "特效 / 调色板"),
    (r"^MapAnim\w*", REWRITE, "地图动画演出（表现层）"),
    (r"^Anim\w*|^AP_\w*|^Face\w*|^Mu\w*|^Sprite\w*|^DeathDrop\w*|^Guide\w*", REWRITE, "动画 / 精灵"),
    (r"^GenerateGradientPalette|^GreenText|^GreenPal", REWRITE, "调色板 / 文字着色"),
    (r"^GetScanline|^GetCursorScreen|^Gmap\w*|^GetKeyStatus", REWRITE, "扫描线 / 光标 / 世界地图 UI"),
    (r"^Clear(Bg|Wm|Tilemap|Screen)|^CopyTilemap|TilemapBuffer", REWRITE, "图层 / 瓦片图缓冲"),
    (r"^EnableAllDisplay|^DisableAllDisplay|DisplayPage", REWRITE, "显示开关（硬件层，§4.8 N6）"),
    (r"^StartBgm|^ChangeBgm|^PlaySound|^Sound\w*|^MPlay", REWRITE, "音频播放意图（引擎由 flame_audio 替代）"),
    (r"^HBlank\w*|^VBlank\w*|^HB\w*", REWRITE, "扫描线效果（§4.8 N5/N6）"),
    (r"^Hardware\w*|^CopyViaDma|^EraseSaveData", DISCARD, "硬件 / DMA / 擦除存档（§4.8 N6/N7）"),
    (r"^Dummv|^Dummy", DISCARD, "占位桩函数"),
    (r"^nullsub", DISCARD, "空函数"),
    (r"^ClassIntro|^OpAnim|^Opening", REWRITE, "片头 / 职业演示演出"),
    (r"^Debug|^Uidebug|^Bmdebug", REWRITE, "调试界面"),
    (r"^SaveDraw|^SaveMenu", REWRITE, "存档界面（绘制部分）"),
    (r"^Config(Set|Sprites|_)|^GetConfigSource", REWRITE, "设置界面"),
    (r"^Record\w*|^SoundRoom|^SupportRoom", REWRITE, "图鉴 / 记录界面"),
]


# ---------------------------------------------------------------- 调用图

# 函数定义：行首的返回类型 + 名字 + 左括号
# 允许 `void *`, `const u8 *`, `struct Foo *` 这类返回类型
FUNC_DEF_RX = re.compile(
    r"^(?:[A-Za-z_][\w \t\*]*?[\s\*])([A-Za-z_]\w*)\s*\(",
    re.M,
)
# 调用点
CALL_RX = re.compile(r"\b([A-Za-z_]\w*)\s*\(")

# 控制流关键字与明显的非函数，避免污染调用图
NOT_A_CALL = {
    "if", "for", "while", "switch", "return", "sizeof", "do", "else",
    "defined", "case", "break", "continue", "goto", "default",
}


def load_files():
    return sorted(
        os.path.join(SRC, f) for f in os.listdir(SRC)
        if f.endswith(".c") and os.path.isfile(os.path.join(SRC, f))
    )


def build_call_graph(files):
    """返回 (定义表, 每个文件的被调用函数集合)"""
    defines = {}          # 函数名 -> 文件
    calls = defaultdict(set)

    for path in files:
        text = sf.strip_noise(
            open(path, encoding="utf-8", errors="replace").read())
        for m in FUNC_DEF_RX.finditer(text):
            name = m.group(1)
            if name not in NOT_A_CALL:
                defines.setdefault(name, path)
        for m in CALL_RX.finditer(text):
            name = m.group(1)
            if name not in NOT_A_CALL:
                calls[path].add(name)

    return defines, calls


def classify(verbose=False):
    files = load_files()
    feats = sf.compile_features()
    strong = {k: (layer, decisive, rx) for k, layer, decisive, rx, _ in feats}

    defines, calls = build_call_graph(files)

    # 反向调用图：函数名 -> 调用它的文件
    callers = defaultdict(set)
    for path, names in calls.items():
        for n in names:
            callers[n].add(path)

    result = {}      # path -> (layer, rule, evidence)
    body_cache = {}

    # 先把"每个文件定义了哪些函数"建好——判定时要靠它区分
    # "定义子系统"和"调用子系统"。
    my_funcs_of_phase1 = defaultdict(list)
    for n, p in defines.items():
        my_funcs_of_phase1[p].append(n)

    # ---- 阶段 1：A（空函数）+ B（强特征）作为种子 ----
    for path in files:
        raw = open(path, encoding="utf-8", errors="replace").read()
        text = sf.strip_noise(raw)
        body_cache[path] = text
        base = os.path.basename(path)

        if NULLSUB_RX.match(base):
            inner = re.search(r"\)\s*\{(.*)\}", raw, re.S)
            if inner is None or not inner.group(1).strip():
                result[path] = (DISCARD, "A:空函数", "nullsub 且函数体为空")
                continue

        # ⚠️ 关键区分：**定义某子系统** vs **只是调用它**。
        #
        # 实测教训：`\bDecompress\b` 命中 285 个文件，但绝大多数只是在
        # 解压贴图——它们不是压缩算法。同理 `MPlayStart`（放个音乐）、
        # `SioSend`（发个包）都是"调用"。按调用判定会把整个平台层的规模
        # 虚高到 1038（§2.6 估算是 485），而且会误丢规则代码。
        #
        # 所以：只有当文件**自己定义**了该子系统的函数时，才算"定义级"证据。
        defined_here = set(my_funcs_of_phase1.get(path, ()))
        matched = []
        defining = []
        for k, (layer, dec, rx) in strong.items():
            syms = {m.group(0) for m in rx.finditer(text)}
            if not syms:
                continue
            matched.append(k)
            if syms & defined_here:
                defining.append(k)

        decisive = {sf.LAYER_PLATFORM: [], sf.LAYER_PRESENT: [], sf.LAYER_RULES: []}
        suggestive = {sf.LAYER_PRESENT: [], sf.LAYER_RULES: []}
        # 定义级证据优先；没有定义级证据时，平台层不靠"调用"入罪
        for k in defining:
            decisive[strong[k][0]].append(k)
        for k in matched:
            if k in defining:
                continue
            layer, dec, _ = strong[k]
            if layer == sf.LAYER_PLATFORM:
                continue          # 调用平台函数不构成平台层
            (decisive if dec else suggestive)[layer].append(k)

        # 优先序：平台 > 规则 > 表现
        #
        # 规则排在表现前面是刻意的：**漏掉一条规则比多写一份 UI 严重得多**。
        # 一个文件若同时定义了战斗公式和一段演出，它必须进移植队列。
        if decisive[sf.LAYER_PLATFORM]:
            result[path] = (DISCARD, "B:平台决定性特征",
                            f"{sorted(decisive[sf.LAYER_PLATFORM])}")
        elif decisive[sf.LAYER_RULES]:
            result[path] = (PORT, "B:规则决定性特征",
                            f"{sorted(decisive[sf.LAYER_RULES])}")
        elif decisive[sf.LAYER_PRESENT]:
            result[path] = (REWRITE, "B:表现决定性特征",
                            f"{sorted(decisive[sf.LAYER_PRESENT])}")

    seeds = len(result)

    # ---- 阶段 2：C（调用图传播），迭代到不动点 ----
    #
    # 反复扫描，每轮把"定义的函数被哪些已判定文件调用"用上，
    # 直到一轮下来没有任何新文件被判定为止。
    #
    # 注意方向：**看调用者而不是被调用者**。表现层和规则层都会调用通用工具
    # （比如内存拷贝），看被调用者会把它们混在一起；而"谁在调用我"更能说明
    # 这段代码是为哪一层服务的。
    my_funcs_of = defaultdict(list)
    for n, p in defines.items():
        my_funcs_of[p].append(n)

    propagated = 0
    for _round in range(30):
        changed = 0
        for path in files:
            if path in result:
                continue
            caller_files = set()
            for n in my_funcs_of.get(path, ()):
                caller_files |= callers.get(n, set())
            layers = Counter(
                result[c][0] for c in caller_files
                if c in result and result[c][0] is not None)
            if not layers:
                continue
            # **多数票**，不是"有规则层调用者就算规则层"。
            #
            # 实测教训：`BG_EnableSyncByMask` 被 28 个规则层文件调用，但被
            # 152 个表现层 + 121 个平台层调用——它是通用的显存同步工具。
            # 早期版本"见 port 即 port"把它误判成规则层，这类误判会成片出现。
            top, n = layers.most_common(1)[0]
            total = sum(layers.values())
            result[path] = (top, "C:调用者多数",
                            f"{n}/{total} 个调用者属于 {top}；分布 {dict(layers)}")
            changed += 1
        propagated += changed
        if not changed:
            break

    # ---- 阶段 3：提示性特征（两层都可能用的通用设施）----
    #
    # `Proc_Start`（用协程跑逻辑）和 `NextRN`（取个随机数）单独都不定义层。
    # 只有在**没有更硬的证据**时，才拿它们做加权。
    suggestive_at = {}
    for path in files:
        if path in result:
            continue
        text = body_cache[path]
        matched = [k for k, (layer, dec, rx) in strong.items() if rx.search(text)]
        pres = [k for k in matched if strong[k][0] == sf.LAYER_PRESENT]
        rule = [k for k in matched if strong[k][0] == sf.LAYER_RULES]
        suggestive_at[path] = (pres, rule)

        if pres and not rule:
            result[path] = (REWRITE, "C:仅提示性表现特征", f"{sorted(pres)}")
        elif rule and not pres:
            result[path] = (PORT, "C:仅提示性规则特征", f"{sorted(rule)}")
        elif pres and rule:
            # 两边都有提示性特征：按数量多的一边，平手判规则层（保守）
            if len(rule) >= len(pres):
                result[path] = (PORT, "C:提示性平手判规则",
                                f"规则{sorted(rule)} vs 表现{sorted(pres)}")
            else:
                result[path] = (REWRITE, "C:提示性表现占多",
                                f"表现{sorted(pres)} vs 规则{sorted(rule)}")

    # ---- 阶段 4：D（弱特征） + E（命名兜底） ----
    for path in files:
        if path in result:
            continue
        text = body_cache[path]
        base = os.path.basename(path)

        gs = GAME_STATE_RX.search(text)
        pr = PRESENT_RX.search(text)
        if gs and not pr:
            result[path] = (PORT, "D:改游戏状态", f"命中 {gs.group(0)!r}，无硬件写")
            continue
        if pr and not gs:
            result[path] = (REWRITE, "D:写硬件/显存", f"命中 {pr.group(0)!r}，无游戏状态")
            continue
        if gs and pr:
            if re.search(r"\bREG_\w+", text):
                result[path] = (DISCARD, "D:含寄存器", "同时改游戏状态与硬件寄存器")
            else:
                result[path] = (PORT, "D:以游戏状态为主",
                                "同时改游戏状态与显存，判为规则层")
            continue

        # 名称规则同时看**文件名**和**本文件定义的函数名**。
        # 后者才是主信号：大量文件按 ROM 地址命名（exact_08005c68.c），
        # 但里面的函数叫 FaceBgBlink_Init —— 语义在函数名上。
        candidates = [base] + list(my_funcs_of.get(path, ()))
        for rx, layer, why in NAME_RULES:
            hit = next((c for c in candidates if re.search(rx, c)), None)
            if hit:
                result[path] = (layer, "E:命名", f"{why}（命中 {hit}）")
                break
        else:
            # ---- 阶段 5：兜底 ----
            #
            # 走到这里说明：没有决定性特征、没有可用的调用者、不碰游戏状态也不碰
            # 硬件、名字也对不上任何语义规则。**这些是本轮真正没有把握的文件。**
            #
            # 默认判 **port** 而不是 rewrite，理由是风险不对称：
            #   漏掉一条规则 → 游戏行为错，且很难发现
            #   多移植一个 UI 辅助 → 只是浪费一点时间
            #
            # 但它们全部带 needs_review 标记，会进复核清单——
            # **有结论** 和 **有把握** 是两件事，这里不把它们混为一谈。
            result[path] = (PORT, "F:兜底待复核",
                            "无任何特征与调用者证据，按「不丢规则」保守判为规则层")

    return files, result, defines, callers, calls, body_cache


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--csv", help="导出逐文件清单")
    ap.add_argument("--why", help="查某个文件为什么这么判（子串匹配）")
    ap.add_argument("--rules", action="store_true", help="打印各级判定数量")
    a = ap.parse_args()

    files, result, defines, callers, calls, body_cache = classify()

    unclassified = [p for p in files if result[p][0] is None]

    if a.why:
        for p in files:
            if a.why.lower() in os.path.basename(p).lower():
                layer, rule, ev = result[p]
                print(f"{os.path.basename(p)}\n  判定: {layer or '未分类'}\n"
                      f"  依据: {rule}\n" f"  证据: {ev}\n")
        return 0

    # --- 置信度 ---
    #
    # high   : 定义级特征 / 空函数 / 明确的命名语义
    # medium : 调用图多数票、提示性特征
    # low    : 弱特征与兜底——**这些会进复核清单**
    HIGH = {"A:空函数", "B:平台决定性特征", "B:规则决定性特征",
            "B:表现决定性特征", "E:命名"}
    MED = {"C:调用者多数", "C:仅提示性表现特征", "C:仅提示性规则特征",
           "C:提示性平手判规则"}

    def confidence(rule):
        if rule in HIGH:
            return "high"
        if rule in MED:
            return "medium"
        return "low"

    review = [p for p in files if confidence(result[p][1]) == "low"]

    # --- 风险检查：被"重写"但重度操作游戏状态的文件 ---
    #
    # 这是**唯一会真正丢东西的误判方向**：把规则层代码判成"用 Flutter 重写"，
    # 等于把游戏规则丢掉。反过来（把 UI 判成移植）只是浪费时间。
    #
    # 所以专门把这类文件挑出来单独看：它们被判了 rewrite，
    # 却在读写单位 / 地图 / 章节进度这些游戏状态。
    RISK_STATE = re.compile(
        r"\bg(PlaySt|ChapterData|BmMap\w*|UnitLut|UnitPool|ActiveUnit|ItemData"
        r"|ClassData|Trap\w*|MapChangeData|Support\w*|Convoy\w*|BWLData)\b")
    risky = []
    for p in files:
        if result[p][0] != REWRITE:
            continue
        text = body_cache[p]
        hits = {m.group(0) for m in RISK_STATE.finditer(text)}
        if len(hits) >= 2:      # 至少碰两种游戏状态，才算"重度"
            risky.append((p, sorted(hits), result[p][1]))

    # --- 统计 ---
    dist = Counter(result[p][0] for p in files)
    rule_dist = Counter(result[p][1] for p in files)

    print(f"扫描 {len(files)} 个文件（src/*.c）\n")
    print("层级分布:")
    exp = {DISCARD: 485, REWRITE: 2151, PORT: 1051}
    for layer in LAYER_ORDER:
        n = dist.get(layer, 0)
        e = exp.get(layer)
        if e:
            print(f"  {layer:<10} {n:>5}   §2.6 估算 {e:>5}   偏差 {n - e:+6}")
        else:
            print(f"  {layer:<10} {n:>5}")
    print(f"  未分类     {dist.get(None, 0):>5}")
    print(f"  合计       {sum(dist.values()):>5}")

    if a.rules or dist.get(None, 0):
        print("\n各判定依据的数量:")
        for r, n in rule_dist.most_common():
            print(f"  {r:<18} {n:>5}")

    conf_dist = Counter(confidence(result[p][1]) for p in files)
    print("\n置信度:")
    for k in ("high", "medium", "low"):
        print(f"  {k:<8} {conf_dist.get(k, 0):>5}")
    print(f"\n需要人工/AI 复核的（低置信度）{len(review)} 个，样本:")
    for p in review[:8]:
        print(f"  {os.path.basename(p)}")

    print(f"\n⚠️ 风险检查：判为 rewrite 但重度操作游戏状态的 {len(risky)} 个")
    print("   （这是唯一会真正丢规则的方向，必须优先复核）")
    for p, hits, rule in risky[:8]:
        print(f"  {os.path.basename(p):<44} {','.join(hits)}")

    if unclassified:
        print(f"\n⚠️ 仍有 {len(unclassified)} 个没有结论——这违反 D19")

    if a.csv:
        with open(a.csv, "w", newline="", encoding="utf-8") as f:
            w = csv.writer(f)
            risk_set = {p for p, _, _ in risky}
            w.writerow(["file", "layer", "confidence", "rule", "evidence",
                        "risk_state", "funcs"])
            for p in files:
                layer, rule, ev = result[p]
                fns = [n for n, q in defines.items() if q == p]
                w.writerow([os.path.relpath(p, REPO), layer or "",
                            confidence(rule), rule, ev,
                            "yes" if p in risk_set else "",
                            ";".join(fns[:4])])
        print(f"\n清单已写出：{a.csv}")

    # D19：每个文件都必须有结论。低置信度不算失败（它们已标出待复核），
    # 但"没有结论"是失败。
    return 1 if unclassified else 0


if __name__ == "__main__":
    sys.exit(main())
