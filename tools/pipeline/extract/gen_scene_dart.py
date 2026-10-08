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
        # 目标脚本是**符号**时直接调它（`Event0A_Call` 拿的是指针）
        for a in A:
            if is_sym(a):
                return (f"await s.call({lit(a)});", False)
        # 指针为负 → 从**槽 2** 取（`src/sub_800DC40.c:10-11`）
        if A and isinstance(A[0], int) and A[0] < 0:
            return ("await s.callSlot(2);", False)
        # 其余情况**响亮**记下来，不要假装成"槽 0"。
        # ⚠️ 原来 `A[0] == 0` 会生成 `callSlot(0)` —— 槽 0 从来不是
        # `CALL` 的目标，那一下把整段被调脚本吞掉了。
        return (f"s.placeholder('CALL({A[0] if A else '?'})');", True)

    # 教学事件入队 —— `EvtEnqueueConditionalTutCall(scr, exec_type)`
    # 解出来是 `EvtEnqueueConditionalTutCall(<exec_type>, <scr>)`（命令字的 arg0
    # 是 exec_type，脚本指针在紧接着的那个字里）。
    # 出处：`include/eventscript.h:609` 的宏 + `src/eventscr_0800DC94.c:84-94`。
    #
    # ⚠️ 它原来是占位符 —— 于是序章那条 15 步教学链**一步都没触发**，
    # 而用户看到的正是"阶段切换/玩家阶段开始时应该跳教学对话"。
    if op in ("EvtEnqueueConditionalTutCall", "ENQUEUE_CALL"):
        if len(A) >= 2 and is_sym(A[1]):
            return (f"s.enqueueTutCall({num(A[0])}, {lit(A[1])});", True)
        return (f"s.placeholder('{op}');", True)

    # `EvtEnqueueCallDirectly(scr)` —— 同一命令的 sub 0：**直接调**（不是入队）
    if op == "EvtEnqueueCallDirectly":
        for a in A:
            if is_sym(a):
                return (f"await s.call({lit(a)});", False)
        return (f"s.placeholder('{op}');", True)

    # 阵营级的"藏起来" —— `EV_CMD_CHANGESTATE`（`src/eventscr_080103F4.c:60-135`）。
    #   `CLEA` = `EvtHideAllAlliess`（`include/EAstdlib.h:146`）⇒ 遍历**蓝色**阵营
    #            （源码：`for (i = FACTION_BLUE + 1; i < FACTION_GREEN; i++)`）
    #   `CLEN` = `EvtRemoveAllNpcs`   ⇒ 绿色（NPC）
    #   `CLEE` = `EvtRemoveAllEimies` ⇒ 红色（敌军）
    # ★ "remove" 在这套指令里的**实际状态位**就是 `REMU` 用的那三个
    #   （`src/eventscr_080103F4.c:110-111`：`unit->state |= US_HIDDEN | US_BIT16 | US_BIT26`）
    #   ⇒ 对应我们模型里的 `isHidden`（`visibleUnits` 已尊重它）。
    # 条件族第二批（写 `gEventSlots[0xC]`，随后 `BEQ`/`BNE` 消费）：
    #   CHECK_TURNS   = EvtGetCurrentTurn（include/EAstdlib.h:75）
    #                 => gEventSlots[0xC] = gPlaySt.chapterTurnNumber
    #                    （src/eventscr_0800E2C8.c:93-95）
    #   CHECK_ENEMIES = CountRedUnits()   （:97-99）
    #   CHECK_OTHERS  = CountGreenUnits() （:101-103）
    #   CHECK_ALIVE   = EvtCheckUnitNotDead（include/EAstdlib.h:127）
    #                 => src/Event33_CheckUnitVarious.c:69-81：找不到单位 => 0；US_DEAD => 0；否则 1
    if op in ("CHECK_TURNS", "CHECK_ENEMIES", "CHECK_OTHERS"):
        kind = {"CHECK_TURNS": "turn", "CHECK_ENEMIES": "redCount",
                "CHECK_OTHERS": "greenCount"}[op]
        return (f"s.checkSlotValue('{kind}');", True)
    if op == "CHECK_ALIVE":
        a = A[0] if A else 0
        arg = num(a) if isinstance(a, int) else lit(a)
        return (f"s.checkSlot('alive', {arg});", True)

    # 输入屏蔽：`IGNORE_KEYS` = `EvtSetKeyIgnore(mask)`（`include/eventscript.h:623`）
    #   ⇒ `SetKeyStatus_IgnoreMask(mask)`（`src/SetKeyStatus_IgnoreMask.c:7-10`）
    # 掩码的位见 `include/gba/io_reg.h:663-672`。
    # 棕色弹窗：`BROWNBOXTEXT` = `EvtDisplayPopupSilently(msg, x, y)`
    #   （`include/eventscript.h:732`；`EV_CMD_DISPLAYPOPUP` subcmd `EVSUBCMD_BROWNTEXTBOX`=1）
    #   处理函数 `Event3A_DisplayPopup`（`src/Event3A_DisplayPopup.c:11-40`）：
    #   **跳过中不弹**（`:16-19`）；`textId = ARGV[0]`，为负 ⇒ 取事件槽 2（`:23-28`）。
    #   ⚠️ 只有三个参数**都是整数**才接（符号参数仍保持占位符）。
    if op == "BROWNBOXTEXT":
        # ★ 抽查产物时发现：**不是所有站点**的 (A[1], A[2]) 都是坐标
        #   （有一条生成了 `popupText(407, 524296, 172104480)` —— 后两个是巨大的值）。
        #   ⇒ 加**合理性守卫**：x/y 必须落在 0..0xFF（地图坐标的量级），
        #     不合格的**退回占位符**（继续计在棘轮里），而不是发一个错的值。
        if (len(A) >= 3 and all(isinstance(x, int) for x in A[:3])
                and 0 <= A[1] <= 0xFF and 0 <= A[2] <= 0xFF):
            return (f"await s.popupText({num(A[0])}, {num(A[1])}, {num(A[2])});", False)
        return (f"s.placeholder('{op}');", True)

    if op == "IGNORE_KEYS":
        a = A[0] if A else 0
        if isinstance(a, int):
            return (f"s.setKeyIgnore({num(a)});", True)
        return (f"s.placeholder('{op}');", True)

    # 帧等待（`EV_CMD_STALL`，`src/eventscr_0800DD9C.c:9-31` 的 `Event0E_STAL`）：
    #   `STAL1` = `EvtSleepWithCancel`   ⇒ subcode 奇数：**可取消**
    #             （源码 `subcode & 1` 时，看跳过位或 **B 键**就提前结束）
    #   `STAL2` = `EvtSleepWithGameCtrl` ⇒ 不可取消
    #   两者都是 `evStallTimer = 参数` 的**按帧**计时（`:25-30`）；
    #   ⚠️ 跳过中（`EVENT_IS_SKIPPING`）**不等待**（`:16-20`）。
    if op in ("STAL1", "STAL2"):
        a = A[0] if A else 0
        if isinstance(a, int):
            cancel = "true" if op == "STAL1" else "false"
            return (f"await s.stall({num(a)}, cancellable: {cancel});", False)
        return (f"s.placeholder('{op}');", True)

    # 事件槽队列（`EV_CMD_QUEUE_OPS`，`src/sub_800DBA0.c:7-29`）：
    #   `SENQUEUE(slot)`  = `EvtEnqueueFormSlot(slot)`  => `SlotQueuePush(gEventSlots[slot])`
    #   `SENQUEUE1`       = `EvtEnqueueFormSlot1`       => `SlotQueuePush(gEventSlots[0x1])`（**无参数**）
    #   `SDEQUEUE(slot)`  = `EvtDequeueToSlot(slot)`    => `gEventSlots[slot] = SlotQueuePop()`
    # 队列写下标就是**槽 0xD**（`src/masked_0800d7ec.c:37-40`），Pop 是 FIFO + 左移
    # （`src/SlotQueuePop.c:2-19`；⚠️ **空队列弹出会让 0xD 变成 −1**，原作没检查）。
    if op == "SENQUEUE1":
        return ("s.slotQueuePushSlot(0x1);", True)
    if op in ("SENQUEUE", "SDEQUEUE"):
        a7 = A[0] if A else 0
        if isinstance(a7, int):
            if op == "SENQUEUE":
                return (f"s.slotQueuePushSlot({num(a7)});", True)
            return (f"s.slotQueuePopToSlot({num(a7)});", True)
        return (f"s.placeholder('{op}');", True)

    # 音频（`include/EAstdlib.h:55-64`）—— **只接"放什么"，不发声**：
    #   `MUSC` = `EvtStartBgm(bgm)`       => `_EvtArg0(EV_CMD_BGMCHANGE_12, 2, 0, bgm)`
    #   `MUSS` = `EvtOverrideBgm(bgm)`    => `EV_CMD_BGMOVERWRITE`
    #   `SOUN` = `EvtPlaySong(songid)`    => `EV_CMD_PLAYSE`
    #   取用方式：`src/m4aSongNumStart.c:5-12` 的 `&gSongTable[n]` ⇒ **n 是表下标**
    #   `MUSI` = `EvtSetVolumeDown` / `MUNO` = `EvtUnsetVolumeDown`
    #          => `EV_CMD_BGMVOLUMECHANGE`（**没有歌曲参数**）
    if op in ("MUSC", "MUSS", "SOUN"):
        a6 = A[0] if A else 0
        if isinstance(a6, int):
            kind = {"MUSC": "bgm", "MUSS": "override", "SOUN": "se"}[op]
            return (f"s.sound('{kind}', {num(a6)});", True)
        return (f"s.placeholder('{op}');", True)
    if op in ("MUSI", "MUNO"):
        return (f"s.volumeDown({str(op == 'MUSI').lower()});", True)

    # 文本继续：`TEXTCONT` = `EvtContinueText`（`include/EAstdlib.h:92`，
    #   `EV_CMD_CONTINUETEXT` = 0x1C，处理函数 `Event1D_TalkContinue`，
    #   `src/eventscr.c:47-66`）：
    #   跳过中 => `EndTalk/EndCgText/EndAllBoxDialogue`（**结束对话**）；
    #   否则 => `ResumeTalk()`；返回 `EVC_ADVANCE_YIELD`。
    if op == "TEXTCONT":
        return ("await s.continueText();", False)

    # 菜单屏蔽：`DISABLEOPTIONS` = `EvtOverrideUnitMenu(mask)`
    #   （`include/eventscript.h:738`，`EV_CMD_MENUOVERRIDE` subcmd 0）
    #   => `src/Event3D_MenuOverride.c:110-118`：掩码里置位的位 => 对应菜单项**永久隐藏**
    #      （表是 `UnitMenuOverrideConf[15]`，`:74-90`）。
    if op == "DISABLEOPTIONS":
        a5 = A[0] if A else 0
        if isinstance(a5, int):
            return (f"s.overrideUnitMenu({num(a5)});", True)
        return (f"s.placeholder('{op}');", True)

    # 文本类型（`EV_CMD_SETTEXTTYPE`）—— 子命令号**就是**文本类型：
    #   `src/eventscr_0800E3E0.c:94`：`proc->activeTextType = subcode;`
    #   号码见 `include/eventscript.h:415-420`（TEXTSTART=0、REMOVEPORTRAITS=1、
    #   0x1A22=2、TUTORIALTEXTBOXSTART=3、SOLOTEXTBOXSTART=4、0x1A25=5）。
    #   含义见 `src/IsActiveEventTextTypeOnMap.c:25-45`：**1/2 是在地图上的文本框**，
    #   其余（0/3/4/5）不是。
    _TEXT_TYPES = {
        "TEXTSTART": 0, "REMOVEPORTRAITS": 1, "0x1A22": 2,
        "TUTORIALTEXTBOXSTART": 3, "SOLOTEXTBOXSTART": 4, "0x1A25": 5,
    }
    if op in _TEXT_TYPES:
        return (f"s.setTextType({_TEXT_TYPES[op]});", True)

    # 三个小条件/状态命令（都读全了）：
    #   `CHECK_TUTORIAL` = `EvtGetIsTutorial`（include/EAstdlib.h:79）
    #     => `src/eventscr_0800E2C8.c:109-115`：
    #        slot 0xC = !(config.controller || (chapterStateBits & PLAY_FLAG_HARD))
    #   `EVBIT_MODIFY` = `EvtModifyEvBit(type)`（include/eventscript.h:622）
    #     => `src/masked_0800def0.c:74-100`：0 => 清 NOSKIP|0020|0040；
    #        1 => 三个全置；2 => 清前两个、**置第三个**（其余值未读 => 保持占位）
    if op == "CHECK_TUTORIAL":
        return ("s.checkSlotValue('tutorial');", True)
    if op == "EVBIT_MODIFY":
        t = A[0] if A else 0
        if isinstance(t, int) and t in (0, 1, 2):
            return (f"s.modifyEvBit({num(t)});", True)
        return (f"s.placeholder('{op}');", True)

    # 事件计数器（`EV_CMD_COUNTER`，`src/Event0F_CounterOps.c:24-99`）：
    #   32 位里**按 nibble 打包**，`shift = 4 * ((参数低字节) % 8)`；
    #   `COUNTER_CHECK` => `gEventSlots[0xC] = (counter >> shift) & 0xF`（**不回写**）；
    #   `COUNTER_SET`   => 取参数**高字节**（符号扩展）写进该 nibble；
    #   `COUNTER_INC`   => +1，**上限 15**；`COUNTER_DEC` => -1，**下限 0**。
    # 宏形式：`_EvtSubParam16u8((idx), (val))`（`include/eventscript.h:624-627`）
    #   => 参数 = idx(低字节) | val(高字节)。
    if op in ("COUNTER_CHECK", "COUNTER_SET", "COUNTER_INC", "COUNTER_DEC"):
        w = A[0] if A else 0
        if isinstance(w, int):
            idx = w & 0xFF
            val = (w >> 8) & 0xFF
            if op == "COUNTER_CHECK":
                return (f"s.counterCheck({num(idx)});", True)
            if op == "COUNTER_SET":
                return (f"s.counterSet({num(idx)}, {num(val)});", True)
            if op == "COUNTER_INC":
                return (f"s.counterInc({num(idx)});", True)
            return (f"s.counterDec({num(idx)});", True)
        return (f"s.placeholder('{op}');", True)

    # 场景光标移到角色：`CUMO_CHAR` = `CURSOR_CHAR` = `EvtDisplayCursorAtUnit`
    #   （`include/EAstdlib.h:166`，`EV_CMD_DISPLAYCURSOR` subcmd `EVSUBCMD_CURSOR_UNIT`=1）
    #   处理函数 `Event3B_DisplayCursor`（`src/Event3B_DisplayCursor.c:51-59`）：
    #   `unit = GetUnitStructFromEventParameter(ARGV[0])`；**找不到 => EVC_ERROR**；
    #   光标画在 `unit->xPos/yPos`（注意这是**场景光标**，不是玩家的地图光标）。
    if op == "CUMO_CHAR":
        a2 = A[0] if A else 0
        if isinstance(a2, int):
            return (f"s.displayCursorAtUnit({num(a2)});", True)
        return (f"s.placeholder('{op}');", True)

    # 镜头移到**角色**：`CAMERA_CAHR` = `EvtMoveCameraToChar(pid)`
    #   （`include/EAstdlib.h:99`，`EV_CMD_CAMERACONTROL` subcmd 1）
    #   处理函数 `Event26_CameraControl`（`src/eventscr_0800F41C.c:10-35`）：
    #   `case 1: unit = GetUnitStructFromEventParameter(pEventCurrent[1]);`（`:31-32`）。
    #   ⚠️ 普通 `CAMERA`/`CAMERA2` **早就接好了**（`s.cameraTo`，71 处），
    #      这里只是补"移到角色"这一支，**复用同一个 `cameraTo`**。
    if op == "CAMERA_CAHR":
        a = A[0] if A else 0
        if isinstance(a, int):
            return (f"s.cameraToChar({num(a)});", True)
        return (f"s.placeholder('{op}');", True)
    # 幸运值：`CHECK_LUCK` = `EvtGetUnitLuck`（`include/EAstdlib.h:133`）
    #   `src/Event33_CheckUnitVarious.c:147-153`：**找不到单位 => EVC_ERROR**（不是 0！），
    #   否则 `gEventSlots[0xC] = GetUnitLuck(unit)`。
    if op == "CHECK_LUCK":
        a = A[0] if A else 0
        if isinstance(a, int):
            return (f"s.checkLuck({num(a)});", True)
        return (f"s.placeholder('{op}');", True)

    # 条件族第三批（写 `gEventSlots[0xC]`）：`src/eventscr_0800E2C8.c:77-87`
    #   CHECK_MODE             => gEventSlots[0xC] = gPlaySt.chapterModeIndex
    #   CHECK_CHAPTER_NUMBER   => gEventSlots[0xC] = proc->chapterIndex
    #   CHECK_HARD             => (& PLAY_FLAG_HARD) ? 1 : 0（`:85-87` 起）
    if op in ("CHECK_MODE", "CHECK_CHAPTER_NUMBER", "CHECK_HARD"):
        kind = {"CHECK_MODE": "mode", "CHECK_CHAPTER_NUMBER": "chapter",
                "CHECK_HARD": "hard"}[op]
        return (f"s.checkSlotValue('{kind}');", True)

    # 单单位状态（`EV_CMD_CHANGESTATE`，`src/eventscr_080103F4.c:60-135`）：
    #   REMU   = `state |= US_HIDDEN | US_BIT16 | US_BIT26`（`:110-111`）
    #   REVEAL = 清那三位（`:114-115`）
    #   SET_STATE = 按 `gEventSlots[1]`：1 => 清 `US_NOT_DEPLOYED`、0 => 置、
    #               -1 => 看 `US_BIT21`（我们没建模那一位）
    if op in ("REMU", "REVEAL", "SET_STATE"):
        a = A[0] if A else 0
        # ⚠️ 只有**整数**参数才接：少数几处的参数是**符号/表达式**，
        # 我们解析不了它指谁 ⇒ **保持占位符**（继续计在棘轮里），
        # 而不是硬塞一个错的值进去（那会变成"看起来接上了"）。
        if isinstance(a, int):
            kind = "setState" if op == "SET_STATE" else op.lower()
            return (f"s.unitStateOp('{kind}', {num(a)});", True)
        return (f"s.placeholder('{op}');", True)

    if op in ("CLEA", "CLEN", "CLEE"):
        faction = {"CLEA": "blue", "CLEN": "green", "CLEE": "red"}[op]
        return (f"s.hideFaction('{faction}');", True)

    # 条件槽：`CHECK_EVBIT` / `CHECK_EVENTID` 写 `gEventSlots[0xC]`，
    # 紧跟的 `BEQ`/`BNE` 读它 —— 生成器**早就**支持 BEQ/BNE 了（`cmp = "==" / "!="`），
    # 缺的一直是"往槽里写值"的这一半。
    # 出处：`src/Event03_CheckEvBitOrId.c:14-33`：
    #   CHECK_EVBIT   ⇒ `gEventSlots[0xC] = (evStateBits >> arg) & 1`
    #   CHECK_EVENTID ⇒ `gEventSlots[0xC] = CheckFlag(arg)`
    # `arg < 0` ⇒ 取事件槽 2。
    if op in ("CHECK_EVBIT", "CHECK_EVENTID"):
        a = A[0] if A else 0
        kind = "evbit" if op == "CHECK_EVBIT" else "flag"
        arg = num(a) if isinstance(a, int) else lit(a)
        return (f"s.checkSlot('{kind}', {arg});", True)

    # 事件位 / 章节旗 —— 同一个处理函数（`src/Event02_EvBitAndIdMod.c:14-38`）：
    #     sub_cmd_lo == 0：`EVBIT_F` ⇒ `evStateBits &= ~(1<<arg)`、`EVBIT_T` ⇒ `|=`
    #     sub_cmd_lo == 1：`ENUF` ⇒ `ClearFlag(arg)`、`ENUT` ⇒ `SetFlag(arg)`
    # `arg < 0` 时取**事件槽 2**（`gEventSlots[2]`）。
    # ⚠️ 这四条原来是占位符，而且 `placeholder(op)` **不带参数** ⇒ 位号被丢掉了。
    #    我们库里 `EVBIT_T` 出现 271 次、`ENUT` 133 次 ⇒ 不接的话
    #    "只演一次"和"章节旗"这些行为全是空的。
    if op in ("EVBIT_T", "EVBIT_F", "ENUT", "ENUF"):
        a = A[0] if A else 0
        kind = "flag" if op.startswith("ENU") else "evbit"
        set_ = "true" if op.endswith("T") else "false"
        arg = num(a) if isinstance(a, int) else lit(a)
        return (f"s.evBitMod('{kind}', {set_}, {arg});", True)

    if op == "SVAL":
        return (f"s.setSlot({num(A[0])}, {lit(A[1]) if len(A) > 1 else '0'});", True)
    if op == "SVAL2":
        return (f"s.setSlot2({num(A[0])}, {num(A[1])}, {num(A[2])});", True)
    if op in ("SADD", "SSUB", "SMUL", "SDIV", "SAND", "SORR"):
        return (f"s.slotArith('{op}', {num(A[0])}, {lit(A[1]) if len(A) > 1 else '0'});", True)

    # 文本族的另两条（`EV_CMD_DISPLAYTEXT` / `EV_CMD_ENDTEXT`，同一套宏）：
    #   `REMA`    = `EvtTextRemoveAll`（`include/eventscript.h:662`，subcmd 2）
    #               ⇒ 清掉当前显示的所有文本
    #   `TEXTEND` = `EvtTextWaitLock`（`include/eventscript.h:664`，`EV_CMD_ENDTEXT`）
    #               ⇒ 等文本"锁定"（显示完）
    # ⚠️ 我们库里 `TEXTEND` 341 次、`REMA` 282 次 —— 文本族是占位符里最大的一块。
    # 注意 `TEXTEND` **不是**"什么都不做"：它发一个 `EndText` 事件（游戏据此收/锁文本框），
    # 而不是假装接上了。
    if op == "REMA":
        return ("s.textRemoveAll();", True)
    if op == "TEXTEND":
        return ("await s.textEnd();", False)

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

    # 换章：`Event2A_MoveToChapter`（`src/Event2A_MoveToChapter.c:22-57`）
    #   MNTS(0)  → 回标题（`GAME_ACTION_EVENT_RETURN`）—— **不是换章**
    #   MNCH(1)  → `SetNextChapterId` + CLASS_REEL   ← 第 1 章→第 2 章走的是这条
    #   MNC2(2)  → `SetNextChapterId` + USR_SKIPPED  ← 序章→第 1 章
    #   MNC3(3)  → `GotoChapterWithoutSave`
    #   MNC4(4)  → played-through
    #
    # ⚠️ 原来只认 `MNC2` —— 于是**第 1 章的结束剧情演完后什么都没发生**
    # （`MNCH` 落成占位符），第 1 章永远接不到第 2 章。
    # `EVSUBCMD_*`（`src/Event2A_MoveToChapter.c:22-57`）
    # ⚠️ 必须带上子命令：`MNCH` 之后要**先走大地图**（`save_menu_type = 1`），
    # `MNC2` 才是直接进地图（`save_menu_type = 2`）。原来四条都发成同一个调用，
    # 于是"第 1 章 → C00 之间那段大地图"在流程上根本不存在。
    _MNC_SUBCMD = {"MNTS": 0, "MNCH": 1, "MNC2": 2, "MNC3": 3, "MNC4": 4}
    if op in _MNC_SUBCMD:
        return (f"await s.changeChapter({num(A[0]) if A else 0}, "
                f"subcmd: {_MNC_SUBCMD[op]});", False)
    if op == "MNTS":
        return ("s.placeholder('MNTS(回标题)');", True)

    # 换地图 —— 操作数是 **chapterIndex**（`src/eventscr_0800F390.c:54`）
    if op == "LOMA":
        return (f"await s.loadMap({num(A[0]) if A else 0});", False)

    if op == "STAL":
        return (f"await s.stall({num(A[0])});", False)

    # ---- 单位显隐 / 状态 ----
    #
    # 出处：`src/Event34_MessWithUnitState`（`src/eventscr_080103F4.c:74-232`）
    #
    #     case EVSUBCMD_DISA:      ClearUnit(unit);            // ★ 从地图上拿掉
    #     case EVSUBCMD_SET_HP:    SetUnitHp(unit, gEventSlots[1]);
    #                              if (gEventSlots[1] == 0) unit->state |= US_DEAD;
    #
    # 序章王座厅那一幕用了 4 次 `DISA`（传令兵走掉、艾莉卡被赛特抱走…）——
    # 一直是占位符，所以**该消失的人一直站在地图上**。
    if op == "DISA":
        return (f"await s.removeUnit({num(A[0]) if A else 0});", False)
    if op == "DISA_IF":
        # `EVSUBCMD_DISA_IF`：先等死亡淡出，再落到 `ClearUnit`
        return (f"await s.removeUnit({num(A[0]) if A else 0}, onlyIfDead: true);", False)
    if op == "SET_HP":
        # `EvtSetUnitHpFormSlot1(pid)` —— HP **从槽 1 取**
        return (f"await s.setUnitHpFromSlot({num(A[0]) if A else 0});", False)

    # ---- 演出用光标（`src/Event3B_DisplayCursor.c`）----
    #
    #     case EVSUBCMD_CURSOR_UNIT:     x/y = unit->xPos/yPos
    #     case EVSUBCMD_CURSOR_AT:       x = 低字节, y = 高字节
    #     case EVSUBCMD_CURE:            Proc_EndEach(ProcScr_EventDisplayCursor)
    #
    # 过场里"说话的人身上有个闪动的框"就是它。序章用了
    # `CURSOR_CHAR` + `CURE` 各十几次。
    if op == "CURSOR_CHAR":
        return (f"s.showCursorAtUnit({num(A[0]) if A else 0});", False)
    if op == "CURSOR_FLASHING_CHAR":
        _pid = num(A[0]) if A else 0
        return (f"s.showCursorAtUnit({_pid}, flashing: true);", False)
    if op == "CURSOR_AT":
        _x = num(A[0]) if A else 0
        _y = num(A[1]) if len(A) > 1 else 0
        return (f"s.showCursorAt({_x}, {_y});", False)
    if op == "CURSOR_FLASHING":
        _x = num(A[0]) if A else 0
        _y = num(A[1]) if len(A) > 1 else 0
        return (f"s.showCursorAt({_x}, {_y}, flashing: true);", False)
    if op == "CURE":
        # `#define CURE EvtEndCursor`（`include/EAstdlib.h:169`）
        return ("await s.endCursor();", False)

    # `ENUN` = `EvtWaitUnitMoving`（`include/EAstdlib.h:134`）——
    # 等所有单位走完。我们的移动是**瞬移**（`_moveUnitInScene` 直接落位），
    # 所以这是个显式的空操作：**记成"已实现"而不是占位**，
    # 这样棘轮上的数字才说实话。
    if op == "ENUN":
        return ("await s.waitUnitMoving();", False)

    # ---- 相机取景 ----
    #
    # 出处：`src/Event26_CameraControl`（`src/eventscr_0800F41C.c`）+
    #       `include/eventscript.h:672-675`
    #
    #     #define EvtMoveCameraTo(x, y)       sub EVSUBCMD_CAMERA_AT  → CAMERA(x, y)
    #     #define EvtMoveCameraToCenter(x, y) sub EVSUBCMD_CAMERA2_AT → CAMERA2(x, y)
    #
    # 两个参数（x, y）**打包在同一个字里**：低字节 x、高字节 y
    # （`_EvtSubParam16u8`，`include/eventscript.h:563`）。
    # 区别只在"怎么对准"：
    #   * `CAMERA`  → `GetCameraAdjustedX/Y`（只在越出死区时移动，**不对齐 16 像素**）
    #   * `CAMERA2` → `GetCameraCenteredX/Y`（居中、夹在 [0, cameraMax]、对齐 16 像素）
    if op in ("CAMERA", "CAMERA2"):
        _x = num(A[0]) if A else 0
        _y = num(A[1]) if len(A) > 1 else 0
        _c = "true" if op == "CAMERA2" else "false"
        return (f"await s.cameraTo({_x}, {_y}, centered: {_c});", False)

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


UNRESOLVED = []   # (script, label) pairs whose label is missing in that script
_CURRENT_SCRIPT = "?"


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
    global _CURRENT_SCRIPT
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
        if op in ("BEQ", "BNE", "BGE", "BGT", "BLE", "BLT"):
            # ★ 出处 `src/Event0C_Branch.c:45-70`：
            #     val1 = gEventSlots[(u16)ARGV[1]];
            #     val2 = gEventSlots[(u16)ARGV[2]];
            #   ⇒ 比较的是**两个事件槽的值**；参数顺序 `(label, s1, s2)`
            #     （宏 `EvtBEQ(label, s1, s2)`，`include/eventscript.h:610`），
            #     标签在 **ARGV[0]**（`Event09_Goto`，`src/exact_0800dc08.c:76`）。
            #
            # ⚠️ 以前写成 `slot=A[0], val=A[1], 标签=A[2]` —— 三样全错，
            #    产出 `if (s.slotInt(0) != 196620) { pc = 1; } else { pc = 1; }`
            #    （比错东西 + 两分支同目标 = 永不跳转；第 88 轮量化为 259 / 109 处）。
            label, s1, s2 = num(A[0]), num(A[1]), num(A[2])
            tgt = labels.get(label)
            if tgt is None:
                UNRESOLVED.append((_CURRENT_SCRIPT, label))
                tgt = i + 1
            cmp = {"BEQ": "==", "BNE": "!=", "BGE": ">=", "BGT": ">",
                   "BLE": "<=", "BLT": "<"}[op]
            out.append(f"          if (s.slotInt({s1}) {cmp} s.slotInt({s2})) "
                       f"{{ pc = {tgt}; }} else {{ pc = {i + 1}; }}")
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

    # ★ 事件表里那些**按偏移引用**的 blob 脚本（`frontier_df4_menu_008_A66F88 + 0x68` …）。
    #
    # 它们的定义在 `.c` 里也是**类型化数组 + 事件宏**
    #（`EventListScr frontier_df3_eventscr_ch_016_A6EFD8[] __attribute__((...)) = { EVENT_WORD(...) EVBIT_T(7) ENDA … }`，
    #  `src/data/frontier_df3_eventscr_ch/frontier_df3_eventscr_ch.c:3739`），
    # 只是**名字不以 `EventScr` 开头** ⇒ 生成器原来一条都收不到。
    #
    # ⚠️ 不能像上一轮那样"把整个数组当脚本存"：那些函数**没有调用者**，
    # 只会把占位符棘轮推上去（上一轮就是这么 +284 的）。这里**只存切片**。
    wanted_blobs, blob_refs = set(), {}
    unresolved_early = []   # 字节偏移不是 4 的倍数（先记下来，最后报）
    el = os.path.join(HERE, "..", "out", "tables", "event_lists.json")
    if os.path.exists(el):
        import json as _j
        for _lst in _j.load(open(el, encoding="utf-8"))["lists"].values():
            for _e in _lst:
                _sc = _e.get("script")
                if not isinstance(_sc, str) or _sc.startswith("EventScr"):
                    continue
                _m = re.match(r"^(\w+)\s*\+\s*(0x[0-9A-Fa-f]+)$", _sc)
                if _m:
                    # ⚠️ **偏移是字节**（事件表里写的是 `(u8 *)sym + 0x68`），
                    # 而字数累加是按**字**（4 字节）——不换算就永远对不上边界
                    # （`0xC` 是 3 个字、不是 12 个字；我为此白跑了一轮）。
                    _b = int(_m.group(2), 16)
                    if _b % 4:
                        unresolved_early.append(_sc)
                    wanted_blobs.add(_m.group(1))
                    blob_refs.setdefault(_m.group(1), {})[_b // 4] = _sc
                else:
                    wanted_blobs.add(_sc)
                    blob_refs.setdefault(_sc, {})[0] = _sc

    # 宏名 → **字数**（`event_macros.json` 的 `len` 是半字）
    macro_words = {}
    mp = os.path.join(HERE, "..", "out", "tables", "event_macros.json")
    if os.path.exists(mp):
        import json as _j2
        _mx = _j2.load(open(mp, encoding="utf-8"))
        # 宏表直接给了"**按名字**查字数"（原名 + 别名都在）—— 优先用它，
        # 免得下游再自己推别名（我推错过两次方向）。
        for _n, _w in (_mx.get("wordsByName") or {}).items():
            macro_words.setdefault(_n, max(1, int(_w)))
        for _specs in _mx["byCmdSub"].values():
            for _sp in _specs:
                macro_words.setdefault(_sp["macro"], max(1, _sp["len"] // 2))
    # ⚠️ `EVENT_WORD(w)` 是 carve 侧的宏：`#define EVENT_WORD(w) (EventListScr)(w),`
    #（`third_party/fireemblem8j/scripts/eventscr_disasm.py:505`）⇒ **1 个字**。
    # 而 `EVENT_WORD_SYM(s)` = `(EventListScr)(s),` 也是 1 个字（值就是那个词）。
    # 我原来写死 2 ⇒ 数组里每个 `EVENT_WORD` 都多算一个字、后面全部错位
    #（ch_016 的首个引用偏移是 3，只有在 EVENT_WORD=1 时才对得上）。
    macro_words.setdefault("EVENT_WORD", 1)
    macro_words.setdefault("EVENT_WORD_SYM", 1)
    # `CALL` 是 `_EvtAutoCmdLen4(EV_CMD_CALL), (EventListScr)(scr),`
    #（`include/eventscript.h:607`）⇒ 4 半字 = 2 字。它不走 `_EvtArg0`，宏表里没有。
    macro_words.setdefault("CALL", 2)

    # `EAstdlib.h` 的**别名**：`#define ENDA EvtReturn` / `#define COUNTER_DEC EvtDecCounter`…
    alias = {}
    ea = os.path.join(DECOMP, "include", "EAstdlib.h")
    if os.path.exists(ea):
        for line in open(ea, encoding="utf-8", errors="replace"):
            m = re.match(r"#define\s+([A-Z][A-Z0-9_]*)\s+(\w+)\s*$", line)
            if m:
                alias[m.group(1)] = m.group(2)

    def words_of(op):
        if op in macro_words:
            return macro_words[op]
        t = alias.get(op)
        return macro_words.get(t) if t else None

    unresolved = []
    name_alt = "|".join(re.escape(w) for w in sorted(wanted_blobs))
    name_pat = "EventScr\\w*" + (("|" + name_alt) if name_alt else "")
    print(f"  事件表按偏移引用的 blob 符号 {len(wanted_blobs)} 个"
          f"（偏移 {sum(len(v) for v in blob_refs.values())} 个）")

    scripts = {}
    ops_body = {}      # 数组的原始体（逐元素数字数要用）
    for f in files:
        raw = strip_comments(open(f, encoding="utf-8", errors="replace").read())
        # ⚠️ 两个都放宽：
        #   1. 名字：`EventScr_\w+` → `EventScr\w*`，否则 **`EventScrWM_*` 一个都收不到**
        #      （大地图那 132 个章间脚本全在 `src/events_wm.c` 里）
        #   2. 长度：原来要求**空方括号** `[]`，而 WM 脚本写的是 `[358]`（带长度）
        # 这两条合起来就是"那个目录的脚本一条都没进管线"的原因。
        # 3. 方括号与 `=` 之间还可能有 `__attribute__((section("...")))`
        #    —— `src/events_wm.c` 里每个脚本都长这样，非 WM 的没有，所以一直没暴露。
        # 4. **类型名也不一样**：WM 那些写的是 `EventScr EventScrWM_X[358] …`，
        #    不是 `EventListScr …`。（4 处差异叠在一起 ⇒ 132 条一条都收不到。）
        for m in re.finditer(
                r"(?:EventListScr|EventScr)\s+(" + name_pat +
                r")\s*\[\s*\d*\s*\]\s*[^=]*=\s*\{",
                raw):
            name = m.group(1)
            i = m.end()
            try:
                j = raw.index("\n};", i)
            except ValueError:
                continue
            ops_body[name] = raw[i:j]
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
            if name in blob_refs:
                # 按**每一个元素**的字数累加定位，再在被引用的偏移处切开。
                #
                # ⚠️ 不能只遍历 `ops`（它只收"标识符+括号"的行）：数组体里还有
                # **裸字面量/表达式**（如 `.4byte` 风格的一个字），
                # 那些被跳过 ⇒ 累加的字数比真实短 ⇒ "偏移 152 不在宏边界上"
                # 这类假失败。这里直接按顶层逗号切元素，逐个数。
                offs = sorted(blob_refs[name])
                body_txt = ops_body.get(name, "")
                # ⚠️ 这些数组体的元素是**按行**写的宏（逗号在宏自己的展开里，
                # `_EvtArg0(...)` 末尾自带逗号），不是顶层逗号分隔 ——
                # 用 `split_args` 只会切出 1 个元素（我踩过）。
                elems = []
                for _l in body_txt.split("\n"):
                    _l = _l.strip().rstrip(",").strip()
                    if _l and not _l.startswith("#"):
                        elems.append(_l)
                pos, starts, el_ops = 0, [], []
                for el in elems:
                    if not el:
                        continue
                    mm = re.match(r"([A-Za-z_]\w*)\s*(?:\((.*)\))?$", el, re.S)
                    if mm:
                        w = words_of(mm.group(1))
                        if w is None:
                            unresolved.append((name, f"宏 {mm.group(1)} 的字数未知"))
                            starts = None
                            break
                    else:
                        w = 1          # 裸字面量 = 1 个字
                    starts.append(pos)
                    if mm:
                        ar = ([parse_arg(x) for x in split_args(mm.group(2))]
                              if mm.group(2) else [])
                        el_ops.append((mm.group(1), ar))
                    else:
                        el_ops.append(("EVENT_WORD", [lit(el)]))
                    pos += w
                if starts is not None and len(el_ops) == len(starts):
                    idx_of = {o: i for i, o in enumerate(starts)}
                    for k, off in enumerate(offs):
                        if off not in idx_of:
                            unresolved.append((blob_refs[name][off],
                                               f"偏移 {off} 不在宏边界上"))
                            continue
                        # ★ 最后一个引用的结束边界是**数组末尾**（`pos`）——
                        # 它按定义不是任何元素的起点，所以**不能**用
                        # `end_off in idx_of` 去卡它。我原来卡了，
                        # 于是"每个符号的最后一个引用"永远切不出来
                        # （诊断里 ch_014/015/017/020 的边界其实都是对的）。
                        if k + 1 < len(offs):
                            end_off = offs[k + 1]
                            if end_off not in idx_of:
                                unresolved.append((blob_refs[name][off],
                                                   f"下一个偏移 {end_off} 不在宏边界上"))
                                continue
                            end_idx = idx_of[end_off]
                        else:
                            end_idx = len(el_ops)
                        sub = el_ops[idx_of[off]:end_idx]
                        if sub:
                            # 键 = 事件表里的**原字符串**（`allSceneFns` 按原始名查）
                            scripts[blob_refs[name][off]] = sub
                # ★ **不存整块**：它没有调用者（上一轮就是这么把棘轮推上去的）
            else:
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

    if blob_refs:
        got = sum(1 for _s in blob_refs.values() for _o in _s.values()
                  if _o in scripts)
        total = sum(len(_s) for _s in blob_refs.values())
        print(f"  按偏移切出的 blob 脚本 {got}/{total}")
        for nm, why in unresolved[:5]:
            print(f"      未切出：{nm} —— {why}")
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
            _CURRENT_SCRIPT = name
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
    # 分支跳不到标签 = 静默的【跳不动】（第 88/89 轮那个 bug 的兜底路径）。
    if UNRESOLVED:
        print("! 未解析分支目标 {} 处（这些分支退化成【往下走】）：".format(len(UNRESOLVED)))
        for sc, lb in UNRESOLVED[:6]:
            print("    {} : LABEL({}) 找不到".format(sc, lb))
        print("    生成器的标签表是**预扫描**的，前向引用本应能找到")
        print("    => 要么数据缺 LABEL、要么方言不同（**未查证**）；个数已进判据")

    return 0


if __name__ == "__main__":
    sys.exit(main())
