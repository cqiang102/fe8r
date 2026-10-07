#!/usr/bin/env python3
"""
解析 `gDefeatTalkList` —— **"首领"的操作性定义**。

## 为什么需要

`EVFLAG_DEFEAT_BOSS`（击破首领）不是由"首领"这个属性决定的，
而是由这张表决定的：**某个角色在某一章死亡时，置上某个标志**。

出处：`src/data_battlequotes.c`（美版；日版同结构）

```c
struct DefeatTalkEnt {
    .pid     = CHARACTER_ONEILL,      // 角色编号
    .route   = CHAPTER_MODE_ANY,      // 路线
    .chapter = CHAPTER_L_PROLOGUE,    // 章节
    .flag    = EVFLAG_DEFEAT_BOSS,    // ★ 死亡时要置的事件标志
    .msg     = 0x0917,                // 死亡台词
};
```

**所以「首领」= 在这张表里出现的角色。** 序章是奥尼尔。

胜负判定要用它：
`单位死亡 -> 查表命中 -> 置标志 -> AFEV 条件满足 -> 执行结束脚本`
"""
import argparse
import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.abspath(os.path.join(HERE, "..", "..", ".."))
DECOMP = os.path.join(REPO, "third_party", "fireemblem8j")
US = os.path.join(REPO, "third_party", "fireemblem8u")


def find_source():
    """优先日版；日版没 carve 就用美版（结构相同，标志语义一致）。"""
    for base in (DECOMP, US):
        for rel in ("src/data_battlequotes.c", "src/data/data_battlequotes.c"):
            p = os.path.join(base, rel)
            if os.path.exists(p):
                return p
    return None


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", default=os.path.join(HERE, "..", "out", "tables"))
    a = ap.parse_args()

    src = find_source()
    if src is None:
        print("  ✗ 找不到 data_battlequotes.c", file=sys.stderr)
        return 1
    text = open(src, encoding="utf-8", errors="replace").read()
    print(f"  源: {os.path.relpath(src, REPO)}")

    # 逐个结构体条目：抓 pid / chapter / flag / msg
    body = text[text.index("gDefeatTalkList"):]
    body = body[:body.index("\n};")] if "\n};" in body else body
    entries = []
    for blk in re.findall(r"\{(.*?)\}", body, re.S):
        def g(key):
            m = re.search(rf"\.{key}\s*=\s*([A-Za-z_0-9x]+)", blk)
            return m.group(1) if m else None
        pid = g("pid")
        if not pid:
            continue
        entries.append({
            "pid": pid,
            "chapter": g("chapter"),
            "flag": g("flag"),
            "msg": g("msg"),
        })

    if not entries:
        print("  ✗ 一条都没解出来", file=sys.stderr)
        return 1

    os.makedirs(a.out, exist_ok=True)
    dst = os.path.join(a.out, "defeat_talk.json")
    with open(dst, "w", encoding="utf-8") as f:
        json.dump({
            "source": os.path.relpath(src, REPO),
            "note": "角色在某章死亡时置上的标志。「首领」= 出现在这张表里的角色。",
            "entries": entries,
        }, f, ensure_ascii=False, indent=1)

    prologue = [e for e in entries if e["chapter"] and "PROLOGUE" in e["chapter"]]
    print(f"  解出 {len(entries)} 条；序章 {len(prologue)} 条")
    for e in prologue[:3]:
        print(f"    {e['pid']} -> {e['flag']} (msg {e['msg']})")
    print(f"→ {dst}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
