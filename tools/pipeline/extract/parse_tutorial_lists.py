#!/usr/bin/env python3
"""教学事件表（`EventListScr_*_Tutorial`）—— 它是个**指针数组**，不是 EvCheck 列表。

## 为什么单独写一个提取器

* `parse_event_lists.py` 只 glob `src/data/**/*.s`，而教学表被去指针化成了
  **`.c`**（`src/data/EventListScr_Prologue_Tutorial_ref/dat_…_ref.c`）——
  于是整批漏掉，`event_lists.json` 里连键都没有。
* 教学表在源码里的形状就是"一串脚本指针 + 0 结尾"：

      SECTION(...) static const u32 EventListScr_Prologue_Tutorial__shift[] = {
          (u32)&EventScr_Prologue_Tutorial0,
          …
          0x00000000,
      };

  它被 `EnqueueTutEvent`（`src/EnqueueTutEvent.c:24-38`）**按下标**查，被
  `RunTutorialEvent`（`src/eventinfo_0808618C.c:138-149`）按 `counter-1` 取 ——
  所以**顺序与条数都是判据**。

判据（正向抽查真值）：序章必须正好 **15** 条，且第 1 条是
`EventScr_Prologue_Tutorial0`、最后一条是 `EventScr_Prologue_TutorialE`。
"""
import argparse
import glob
import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
DECOMP = os.path.normpath(os.path.join(HERE, "..", "..", "..", "third_party", "fireemblem8j"))

# `(u32)&EventScr_Prologue_Tutorial0,` / `0x00000000,`
ROW = re.compile(r"\(u32\)&(\w+)\s*,|0x0*0\s*,")
NAME = re.compile(r"^(EventListScr_\w+):")


def parse_file(path):
    """返回 [(列表名, [脚本名…]), …]（一个 .c 里可能只有一张表）"""
    txt = open(path, encoding="utf-8", errors="replace").read()
    out = []
    for m in re.finditer(r"^EventListScr_(\w+):\s*$", txt, re.M):
        pass
    # 实际形状是：`static const u32 <NAME>__shift[] = { … };`
    for m in re.finditer(r"static const u32 (\w+)__shift\[\]\s*=\s*\{(.*?)\};", txt, re.S):
        name = m.group(1)
        body = m.group(2)
        items = []
        for row in ROW.finditer(body):
            if row.group(1):
                items.append(row.group(1))
            else:
                break  # 0 结尾
        # 只收教学表：这个文件的语义就是"教学表"。
        #（`.c` 里同形状的还有 `PrologueEvents` / `FinalEphraimEvents1` 等章节事件表，
        #  它们另在 `event_lists.json` 的覆盖里 —— 混进来会让文件名撒谎。）
        if name.endswith("_Tutorial") or name.endswith("_Tutorials"):
            out.append((name, items))

    # ★ 第二种形状（`.s` 数据 blob）：`EventListScr_Ch1_Tutorial:` 后面跟
    # 一串 `.4byte <脚本名>`，以 `.4byte 0x00000000` 结尾
    #（`src/data/data_08A5A828/data_08A5A828.s:46-62`）。
    for m in re.finditer(
            r"^EventListScr_(\w+):\s*$\n((?:\s*\.4byte\s+[^\n]+\n)+)", txt, re.M):
        name = "EventListScr_" + m.group(1)
        items = []
        for row in re.finditer(r"\.4byte\s+(\S+)", m.group(2)):
            tok = row.group(1)
            if tok.startswith("0x") or tok == "0":
                break  # 0 结尾
            items.append(tok)
        # ⚠️ 只收 `*_Tutorial`：这个文件的语义就是"教学表"。
        # 我第一版把 `.s` 里**所有** `EventListScr_*` 都收了，于是
        # `EventListScr_Ch18b_Character` / `Ch20b_Character` 也混了进来
        # —— 那是**角色事件表**，不该出现在教学表文件里（名字会撒谎）。
        # 空表（例如 `EventListScr_Ch1_UnitMove` 只有一个 0）也不进产物。
        # ⚠️ 源码里两种拼写都有：`Ch1_Tutorial`（单数）与 `Ch3_Tutorials`（**复数**）。
        # 我第一版只收单数 ⇒ 14 张复数表被自己的过滤器挡掉（不变量当场响了）。
        if items and (name.endswith("_Tutorial") or name.endswith("_Tutorials")):
            out.append((name, items))
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", default=os.path.join(HERE, "..", "out", "tables"))
    a = ap.parse_args()

    # ★ **覆盖面**：原来只 glob `EventListScr_*_Tutorial_ref/*.c`，
    # 于是 `EventListScr_Ch1_Tutorial` 整张漏掉 —— 它定义在
    # `src/data/data_08A5A828/data_08A5A828.s`（**`.s`**，目录名也不带 `_Tutorial_ref`），
    # 是"一串 `.4byte <脚本指针>` + `0x00000000` 结尾"的形状。
    # 后果实测：Ch1 的教学链缺一环（`教学入队失败：EventScr_Ch1Tut_TradeSelectGalliamIdle1`）。
    # 现在两种形状都收：`.c`（`_ref` 目录里的 `__shift[]`）与 `.s`（数据 blob）。
    # ★★ **发现面**（第 38 轮重做）：前面两次都是"glob 太窄 ⇒ 整批漏掉"。
    #   * 第一版只 glob `EventListScr_*_Tutorial_ref/*.c` ⇒ 漏 Ch1（它在
    #     `data_08A5A828.s` 里）；
    #   * 第二版补了 `src/data/*/*.s` ⇒ 仍然只有 3 张，而源码里有 **17** 张
    #     `EventListScr_*_Tutorial`（Ch3…Ch21b 全缺）。
    # 现在改成**先问源码**：把 `src/` 下所有 `.c`/`.s` 里出现过 `_Tutorial`
    # 的文件挑出来，再逐个解析两种形状。这样"漏"这件事本身会被下面的
    # 不变量判据抓住（提取数必须等于源码里的标签数）。
    cand = []
    for ext in ("*.c", "*.s"):
        for f in glob.glob(os.path.join(DECOMP, "src", "**", ext), recursive=True):
            try:
                if "_Tutorial" in open(f, encoding="utf-8", errors="replace").read():
                    cand.append(f)
            except OSError:
                continue
    files = sorted(set(cand))
    lists = {}
    for f in files:
        for name, items in parse_file(f):
            lists[name] = items

    print(f"  解出 {len(lists)} 张教学表：")
    for k, v in sorted(lists.items()):
        print(f"    {k}: {len(v)} 条")

    # ★ 正向抽查真值 —— 不是"文件存在"
    pro = lists.get("EventListScr_Prologue_Tutorial")
    if pro is None or len(pro) != 15 or pro[0] != "EventScr_Prologue_Tutorial0" \
            or pro[-1] != "EventScr_Prologue_TutorialE":
        print("❌ 序章教学表不是 15 条（或首尾不对）—— "
              f"{None if pro is None else (len(pro), pro[:1], pro[-1:])}", file=sys.stderr)
        return 1
    print("  ✓ 序章 15 条，首 EventScr_Prologue_Tutorial0 / 尾 …TutorialE")

    # ★ 第 36 轮补的：**Ch1 教学表**原来整张漏掉（提取器只 glob 了
    # `EventListScr_*_Tutorial_ref/*.c`，而 Ch1 那张在 `data_08A5A828.s` 里）。
    # 实测后果：`教学入队失败：EventScr_Ch1Tut_TradeSelectGalliamIdle1`。
    ch1 = lists.get("EventListScr_Ch1_Tutorial")
    if ch1 is None or len(ch1) != 14 \
            or ch1[4] != "EventScr_Ch1Tut_TradeSelectGalliamIdle1":
        print(f"❌ Ch1 教学表不对：{None if ch1 is None else (len(ch1), ch1[:1], ch1[4:5])}",
              file=sys.stderr)
        return 1
    print("  ✓ Ch1 14 条，第 5 条 = EventScr_Ch1Tut_TradeSelectGalliamIdle1")

    # ★★ 不变量（第 38 轮重做）：**源码里"非空"的教学表必须全部提取到**。
    #
    # 为什么不是"数量相等"：源码里有 14 张表，但其中 **11 张在 carve 里就是
    # `.4byte 0x00000000`（空表）** —— 实测：
    #   * `src/data/data_08A5AAA8/data_08A5AAA8.s:71-73`  `EventListScr_Ch3_Tutorials:` 后面只有 0；
    #   * `src/data/data_08A5AF38/data_08A5AF38.s:49-51`  `EventListScr_Ch7_Tutorial:` 同样只有 0。
    # 那是 **carve 侧的缺口**（指针内容没 carve 出来，与 `gGuideTable` 同类），
    # 不是解析漏了 —— 所以判据只能要求"**非空的**都提到"，同时把空表**响亮列出来**
    # （将来 carve 补上，这条会立刻显出差异）。
    #
    # ⚠️ 顺带记一次教训：我第一次的审计用 `grep -oE "…*_Tutorial"`（**前缀**匹配），
    # 把 `Ch4_Tutorials` 截成了不存在的 `Ch4_Tutorial`，于是"17 张 vs 3 张"这个
    # 结论里有一半是**审计脚本自己在撒谎**。
    # 名字 → "定义行后面那几行"（原始文本）—— 用得着时**打印出来当证据**
    bodies = {}
    for f in files:
        txt = open(f, encoding="utf-8", errors="replace").read()
        for m in re.finditer(r"^(EventListScr_(\w+_Tutorials?)):\s*$", txt, re.M):
            name = m.group(2)
            bodies.setdefault(name, txt[m.end():m.end() + 200])

    def is_all_zero_body(name):
        """body 里所有 `.4byte` 操作数都是 0 ⇒ carve 侧就是空表"""
        b = bodies.get(name, "")
        ops = re.findall(r"\.4byte\s+(\S+)", b)
        return bool(ops) and all(o in ("0x00000000", "0", "0x0") for o in ops)

    got = {k[len("EventListScr_"):] for k in lists}
    defined = set(bodies)
    not_extracted = sorted(defined - got)
    bad = [n for n in not_extracted if not is_all_zero_body(n)]
    if bad:
        print(f"❌ 有定义、body 非空、但没提取到：{bad[:6]}" +
              "".join(f"\n    {n}: {bodies[n][:60]!r}" for n in bad[:2]),
              file=sys.stderr)
        return 1
    # ⚠️ 打印要**算得平**：`defined` 是"有 `EventListScr_X:` 定义行"的名字，
    # 而序章/Ch2 两张来自 `__shift[]` 形状（**没有 label 行**）⇒ 不在 `defined` 里。
    # 所以恒等式是 `defined = (defined ∩ 已提取) + 空表`，不是"提取数 + 空表"。
    print(f"  ✓ 覆盖不变量：有 label 定义 {len(defined)} 张 "
          f"（已提取 {len(defined & got)} + carve 里为空 {len(not_extracted)}）；"
          f"另从 `__shift[]` 形状提取 {len(got - defined)} 张")
    if not_extracted:
        print(f"    ⚠️ carve 里就是空表（取不到内容）：{not_extracted}")

    dst = os.path.join(a.out, "tutorial_lists.json")
    os.makedirs(a.out, exist_ok=True)
    with open(dst, "w", encoding="utf-8") as f:
        json.dump({
            "note": "教学事件表（指针数组）。下标 = EnqueueTutEvent 用的 counter-1。",
            "lists": lists,
        }, f, ensure_ascii=False, indent=1)
    print(f"→ {dst}  ({os.path.getsize(dst)} B)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
