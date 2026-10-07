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
        out.append((name, items))
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", default=os.path.join(HERE, "..", "out", "tables"))
    a = ap.parse_args()

    files = sorted(glob.glob(os.path.join(
        DECOMP, "src", "data", "EventListScr_*_Tutorial_ref", "*.c")))
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
