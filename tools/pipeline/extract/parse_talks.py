#!/usr/bin/env python3
"""战斗对话表 `gBattleTalkList` 与阵亡对话表 `gDefeatTalkList`（**日版数据**）。

# 数据出处

两张表是 **baseline-resident**（只有符号，没有 typed C 定义）：

```
gBattleTalkList  08A5E7E0   layout/baseline_syms.d/code_8086934-cfe2cbce.tsv:3
gDefeatTalkList  08A5EE70   同上 :4
```

但**数据被 carve 成裸 u32 数组**了：

    src/data/frontier_df4_menu/frontier_df4_menu.c:1455
    u32 frontier_df4_menu_003_A5E6CC[] = { ... };    // 729 个字，基址 0x08A5E6CC

数组首尾正好卡在两张表上（本脚本每次运行都断言）：

    base + 69 字  = 0x08A5E7E0 = gBattleTalkList  （105 槽 × 4 字 = 420 字）
    base + 489 字 = 0x08A5EE70 = gDefeatTalkList  （80 槽 × 3 字 = 240 字）
    69 + 420 + 240 = 729 = 数组长度 ✓  且 0x08A5E6CC + 729*4 = 0x08A5F230 = gSupportTalkList ✓

⚠️ **不要拿美版的 `data_battlequotes.c` 当数据源。** 我第一版就是那么写的，
之后实测两版**消息 id 完全不同**（同一 id 的内容毫无关系）：

| | 美版 | 日版 |
|---|---|---|
| 奥尼尔战斗台词 | msg 0x0916 | msg **0x08D6**「まずは貴様から仕留めてくれる！」|
| 奥尼尔阵亡台词 | msg 0x0917 | msg **0x08D7**「な　なんだと・・・？」|
| id 0x08D0 | "Welcome to the arena!" | 「ルネスの敗残兵どもめ　逃がしはせんぞ！」|

结构体（`include/eventinfo.h:83-99`）：

    struct BattleTalkExtEnt { u16 pidA, pidB, chapter, flag, msg; EventScr* event; }   // 16 B
    struct DefeatTalkEnt    { u16 pid; u8 route, chapter; u16 flag, msg; EventScr* event; } // 12 B
"""
import argparse
import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.abspath(os.path.join(HERE, "..", "..", ".."))
JP = os.path.join(REPO, "third_party", "fireemblem8j")

ARRAY = "src/data/frontier_df4_menu/frontier_df4_menu.c"
SYMBOL = "frontier_df4_menu_003_A5E6CC"
BASE = 0x08A5E6CC
BATTLE_ADDR = 0x08A5E7E0
DEFEAT_ADDR = 0x08A5EE70
BATTLE_SLOTS = 105   # 104 条 + 终止符
DEFEAT_SLOTS = 80    # 79 条 + 终止符


def parse_array():
    src = open(os.path.join(JP, ARRAY), encoding="utf-8", errors="replace").read()
    i = src.index(SYMBOL + "[]")
    j = src.index("\n};", i)
    words, syms = [], 0
    for line in src[i:j].split("\n")[1:]:
        t = line.strip().rstrip(",")
        if not t:
            continue
        m = re.fullmatch(r"0x([0-9A-Fa-f]+)", t)
        if m:
            words.append(int(m.group(1), 16))
        else:
            # 指针表达式（`(u32)&X + 0x4`）—— 只允许出现在两张表**之前**
            words.append(None)
            syms += 1
    return words, syms


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", default=os.path.join(HERE, "..", "out", "tables"))
    a = ap.parse_args()

    words, syms = parse_array()
    problems = []
    if len(words) != 729:
        problems.append(f"数组长度 {len(words)} != 729")
    bo = (BATTLE_ADDR - BASE) // 4
    do = (DEFEAT_ADDR - BASE) // 4
    if bo != 69 or do != 489:
        problems.append(f"表偏移算错：battle={bo} defeat={do}")

    battle = []
    for k in range(BATTLE_SLOTS):
        w = words[bo + k * 4: bo + k * 4 + 4]
        if len(w) < 4 or any(x is None for x in w):
            problems.append(f"战斗对话第 {k} 条含指针表达式")
            continue
        w0, w1, w2, w3 = w
        pidA, pidB = w0 & 0xFFFF, (w0 >> 16) & 0xFFFF
        if pidA == 0xFFFF:
            break
        battle.append({"pidA": pidA, "pidB": pidB,
                       "chapter": w1 & 0xFFFF, "flag": (w1 >> 16) & 0xFFFF,
                       "msg": w2 & 0xFFFF, "pad": (w2 >> 16) & 0xFFFF,
                       "event": w3})

    defeat = []
    for k in range(DEFEAT_SLOTS):
        w = words[do + k * 3: do + k * 3 + 3]
        if len(w) < 3 or any(x is None for x in w):
            problems.append(f"阵亡对话第 {k} 条含指针表达式")
            continue
        w0, w1, w2 = w
        pid = w0 & 0xFFFF
        if pid == 0xFFFF:
            break
        defeat.append({"pid": pid,
                       "route": (w0 >> 16) & 0xFF,
                       "chapter": (w0 >> 24) & 0xFF,
                       "flag": w1 & 0xFFFF,
                       "msg": (w1 >> 16) & 0xFFFF,
                       "event": w2})

    if len(battle) != BATTLE_SLOTS - 1:
        problems.append(f"战斗对话条数 {len(battle)} != {BATTLE_SLOTS-1}")
    if len(defeat) != DEFEAT_SLOTS - 1:
        problems.append(f"阵亡对话条数 {len(defeat)} != {DEFEAT_SLOTS-1}")

    # 每条 msg 必须在日版文本表里
    texts = json.load(open(os.path.join(a.out, "texts.json"), encoding="utf-8"))
    known = set(texts["messages"].keys())
    for kind, entries in (("战斗", battle), ("阵亡", defeat)):
        for e in entries:
            if e["msg"] and str(e["msg"]) not in known:
                problems.append(f"{kind}对话 msg {e['msg']} 不在日版文本表里")

    if problems:
        for p in problems:
            print(f"  ✗ {p}", file=sys.stderr)
        return 1

    os.makedirs(a.out, exist_ok=True)
    note = (f"日版：carve 在 {ARRAY} 的 {SYMBOL}（基址 {hex(BASE)}），数组 {len(words)} 字；"
            "两张表的字偏移、终止符位置、条目数每次运行都断言。")
    for name, entries, extra in (
        ("battle_talks.json", battle, {"slots": BATTLE_SLOTS, "base": hex(BATTLE_ADDR)}),
        ("defeat_talk.json", defeat, {"slots": DEFEAT_SLOTS, "base": hex(DEFEAT_ADDR)}),
    ):
        with open(os.path.join(a.out, name), "w", encoding="utf-8") as f:
            json.dump({"source": f"third_party/fireemblem8j/{ARRAY}",
                       "note": note, "layout": extra, "entries": entries},
                      f, ensure_ascii=False, indent=1)

    print(f"  战斗对话 {len(battle)} 条、阵亡对话 {len(defeat)} 条"
          f"（各 +1 终止符 → {BATTLE_SLOTS}/{DEFEAT_SLOTS} 槽）")
    print(f"  数组 {len(words)} 字（指针表达式 {syms} 个，全在两张表之前）")
    pro = [e for e in battle if e["chapter"] == 0]
    print(f"  序章战斗对话 {len(pro)} 条："
          + ", ".join(f"{e['pidA']}v{e['pidB']}→msg {hex(e['msg'])}" for e in pro))
    return 0


if __name__ == "__main__":
    sys.exit(main())
