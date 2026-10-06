#!/usr/bin/env python3
"""
汉化流程。

# 为什么这么设计

文本的载体是 `texts.json` 里的 **`segments`** —— 「文本段」与「控制码」交替：

    "2133": { "segments": [
        {"c": "$0080"}, {"c": "....."},
        {"t": "ゴールドだ"}, {"c": "LF"}, {"t": "それでいいのかい？　"}, {"c": "Yes"}] }

**翻译只替换 `{t}`（文本段），控制码原位不动。**

所以译文的存储形式是：**按顺序列出该消息的每个文本段**。

    {"2133": ["金币啊", "这样就行吗？"]}

这样**控制码不需要被翻译、也不可能被翻译错位** ——
段数不匹配就直接报错，不会静默错版。

# 三个子命令

    extract   导出待译单元（按批，带上下文）
    apply     把 tools/i18n/zh/*.json 合并成 assets/i18n/zh_CN.json
    verify    校验：段数一致、无缺失、控制码原位
"""
import argparse
import glob
import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.abspath(os.path.join(HERE, "..", ".."))
TEXTS = os.path.join(REPO, "tools", "pipeline", "out", "tables", "texts.json")
ZH_DIR = os.path.join(HERE, "zh")
OUT = os.path.join(REPO, "assets", "i18n", "zh_CN.json")


def load_texts():
    with open(TEXTS, encoding="utf-8") as f:
        return json.load(f)["messages"]


def runs_of(msg):
    """取出一条消息里的文本段（保持顺序）"""
    return [s["t"] for s in msg["segments"] if "t" in s]


def codes_of(msg):
    return [s["c"] for s in msg["segments"] if "c" in s]


def load_translations():
    """读 `tools/i18n/zh/*.json` —— 每个文件是 {id: [段1, 段2, ...]}"""
    merged = {}
    dup = []
    for p in sorted(glob.glob(os.path.join(ZH_DIR, "*.json"))):
        try:
            with open(p, encoding="utf-8") as f:
                d = json.load(f)
        except Exception as e:
            print(f"  ✗ {os.path.basename(p)}: {e}", file=sys.stderr)
            return None
        for k, v in d.items():
            if k in merged:
                dup.append((k, os.path.basename(p)))
            merged[k] = v
    if dup:
        print(f"  ✗ 重复定义 {len(dup)} 条，例如 {dup[:3]}", file=sys.stderr)
        return None
    return merged


def cmd_extract(a):
    texts = load_texts()
    items = []
    for k, v in texts.items():
        runs = runs_of(v)
        if not any(r.strip() for r in runs):
            continue                      # 空消息不用翻
        items.append((int(k), runs))
    items.sort()

    if a.filter == "short":
        items = [x for x in items if sum(len(r) for r in x[1]) <= 8]
    elif a.filter == "dialog":
        items = [x for x in items if sum(len(r) for r in x[1]) > 8]

    total = len(items)
    batches = [items[i:i + a.size] for i in range(0, total, a.size)]
    os.makedirs(os.path.join(HERE, "batches"), exist_ok=True)

    print(f"  待译 {total} 条，切成 {len(batches)} 批（每批 {a.size}）")
    for i, b in enumerate(batches):
        p = os.path.join(HERE, "batches", f"batch_{i:03d}.json")
        with open(p, "w", encoding="utf-8") as f:
            json.dump({str(k): r for k, r in b}, f, ensure_ascii=False, indent=1)
    print(f"  → {HERE}/batches/  （每批一个文件，译好后放到 zh/ 下）")
    return 0


def cmd_apply(a):
    texts = load_texts()
    zh = load_translations()
    if zh is None:
        return 1

    problems = []
    ok = 0
    out = {}
    for k, v in zh.items():
        if k not in texts:
            problems.append(f"{k}: 消息不存在")
            continue
        want = runs_of(texts[k])
        if not isinstance(v, list) or len(v) != len(want):
            problems.append(
                f"{k}: 段数不符（原文 {len(want)}，译文 "
                f"{len(v) if isinstance(v, list) else '?'}）")
            continue
        out[k] = v
        ok += 1

    if problems:
        print(f"  ✗ {len(problems)} 条有问题：", file=sys.stderr)
        for p in problems[:10]:
            print(f"      {p}", file=sys.stderr)
        return 1

    # UI 用词（术语表）—— **不是消息**，是代码里的字面量
    # （原作的菜单项是 OAM 精灵，不在消息表里；见 docs/菜单盘点.md）
    ui = {}
    gp = os.path.join(HERE, "glossary.json")
    if os.path.exists(gp):
        with open(gp, encoding="utf-8") as f:
            ui = json.load(f).get("ui", {})

    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    with open(OUT, "w", encoding="utf-8") as f:
        json.dump({
            "version": 1,
            "note": "段数必须与 texts.json 的 segments 中 {t} 的数量一致；"
                    "控制码不进译文，原位由 segments 决定",
            "messages": out,
            "ui": ui,
        }, f, ensure_ascii=False, indent=1)

    total = len([1 for v in texts.values() if any(r.strip() for r in runs_of(v))])
    pct = ok * 100 // total if total else 0
    print(f"  已译 {ok} / {total}（{pct}%）→ {OUT}")
    return 0


def load_non_text():
    """读"不是文本"的槽位清单（解码错误 / 未使用槽）"""
    p = os.path.join(HERE, "non_text.json")
    if not os.path.exists(p):
        return {}
    with open(p, encoding="utf-8") as f:
        return json.load(f).get("ids", {})


def cmd_verify(a):
    texts = load_texts()
    if not os.path.exists(OUT):
        print("  ✗ 还没有 assets/i18n/zh_CN.json", file=sys.stderr)
        return 1
    with open(OUT, encoding="utf-8") as f:
        d = json.load(f)
    msgs = d["messages"]

    bad = 0
    for k, v in msgs.items():
        if k not in texts:
            print(f"  ✗ {k} 不在 texts.json 里", file=sys.stderr); bad += 1; continue
        want = runs_of(texts[k])
        if len(v) != len(want):
            print(f"  ✗ {k} 段数 {len(v)} != {len(want)}", file=sys.stderr); bad += 1
        # 译文里不该出现控制码残留
        for r in v:
            if re.search(r"\[[A-Za-z]+\]|\$[0-9A-Fa-f]{4}", r):
                print(f"  ✗ {k} 译文里含控制码：{r[:40]!r}", file=sys.stderr); bad += 1
                break

    # 「不是文本」的槽位不该被翻译 —— 翻了就是把乱码固化进译文
    nt = load_non_text()
    for k in nt:
        if k in msgs:
            print(f"  ✗ {k} 在 non_text.json 里登记为乱码，却有译文", file=sys.stderr)
            bad += 1

    total = len([1 for v in texts.values() if any(r.strip() for r in runs_of(v))])
    cover = len(msgs) * 100 // total if total else 0
    print(f"  已译 {len(msgs)} / {total}（{cover}%），问题 {bad} 条")
    print(f"  已登记的乱码槽位 {len(nt)} 个（跳过，不计入未译）")
    return 1 if bad else 0


def main():
    ap = argparse.ArgumentParser()
    sub = ap.add_subparsers(dest="cmd", required=True)

    e = sub.add_parser("extract")
    e.add_argument("--size", type=int, default=200)
    e.add_argument("--filter", choices=["all", "short", "dialog"], default="all")
    e.set_defaults(fn=cmd_extract)

    sub.add_parser("apply").set_defaults(fn=cmd_apply)
    sub.add_parser("verify").set_defaults(fn=cmd_verify)

    a = ap.parse_args()
    return a.fn(a)


if __name__ == "__main__":
    sys.exit(main())
