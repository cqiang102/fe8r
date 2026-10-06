#!/usr/bin/env python3
"""
提取**游戏文本**（对白 / 章节标题 / 界面文字）。

## 数据从哪来 —— 不用解码

FE8 的文本在 ROM 里是 Huffman 压缩的（`src/msg_data.c` 里是压缩后的字节）。
但反编译项目**已经把解码结果导出成了纯文本**：

    texts/jp_texts.txt      1.4 MB · 3339 条 · 格式 `#0xNNNN` + 正文

所以这里**不碰 Huffman**，只做两件事：读文本、拆控制码。

（这和"指针名字本来就写在源码里"是同一类事：信息一直都在。）

## 控制码

正文里混着渲染指令：

    [LoadFace]0104]    加载立绘 #0x104
    [OpenMidLeft]      把立绘放到中左
    [LF]               换行
    [A]                等玩家按键（推进）
    [CR]               清屏/滚动

**立绘位置、换行、等待按键都是渲染层需要的信息**，所以解析出来
而不是当噪声丢掉 —— 丢掉的话渲染层只能瞎猜。

用法:
    python3 tools/pipeline/extract/parse_text.py --out out/tables
"""
import argparse
import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.abspath(os.path.join(HERE, "..", "..", ".."))
DECOMP = os.path.join(REPO, "third_party", "fireemblem8j")

SRC = "texts/jp_texts.txt"

# 控制码：`[Name]` 或 `[Name]` 后跟一个十六进制操作数（如 `[LoadFace]0104]`）
CTRL = re.compile(r"\[([A-Za-z_][A-Za-z0-9_]*)\](?:([0-9A-Fa-f]{2,8})\])?")


def parse_message(body):
    """把一条消息拆成 `segments`（文字与控制码交替）。

    返回 `(segments, plain)`：
      * `segments` 供渲染层按序处理（文字 + 控制码）
      * `plain` 是去掉控制码的纯文字，供人读 / 检索
    """
    segs = []
    pos = 0
    for m in CTRL.finditer(body):
        if m.start() > pos:
            segs.append({"t": body[pos:m.start()]})
        seg = {"c": m.group(1)}
        if m.group(2):
            seg["arg"] = int(m.group(2), 16)
        segs.append(seg)
        pos = m.end()
    if pos < len(body):
        segs.append({"t": body[pos:]})
    plain = "".join(s["t"] for s in segs if "t" in s)
    return segs, plain


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", default=os.path.join(HERE, "..", "out", "tables"))
    a = ap.parse_args()

    path = os.path.join(DECOMP, SRC)
    if not os.path.exists(path):
        print(f"错误：找不到 {path}", file=sys.stderr)
        return 1

    text = open(path, encoding="utf-8", errors="replace").read()
    messages = {}
    cur, buf = None, []
    for line in text.split("\n"):
        m = re.match(r"^#0x([0-9A-Fa-f]+)\s*$", line)
        if m:
            if cur is not None:
                messages[cur] = "\n".join(buf).strip()
            cur, buf = int(m.group(1), 16), []
        elif cur is not None:
            buf.append(line)
    if cur is not None:
        messages[cur] = "\n".join(buf).strip()

    print(f"读到 {len(messages)} 条消息")

    # ---- 章节标题 ----
    ch_path = os.path.join(a.out, "chapters.json")
    titles = {}
    if os.path.exists(ch_path):
        ch = json.load(open(ch_path, encoding="utf-8"))["chapters"]
        hs = os.path.join(DECOMP, "src/data/chapter_settings.h")
        src = open(hs, encoding="utf-8", errors="replace").read()
        names = re.findall(r'\.internalName = "([^"]*)"', src)
        tids = [int(x) for x in
                re.findall(r"\.chapTitleTextId = (\d+)", src)]
        for n, tid in zip(names, tids):
            if n == "-":
                continue
            titles[n] = {"textId": tid, "text": messages.get(tid, "")}
        print(f"章节标题 {len(titles)} 个（含 {n} 这类空槽位已跳过）")

    # ---- 抽查 ----
    pro = titles.get("L00")
    if pro:
        print(f"\n  L00 标题: {pro['text']}")

    out_msgs = {}
    ctrl_names = {}
    for mid, body in messages.items():
        segs, plain = parse_message(body)
        for s in segs:
            if "c" in s:
                ctrl_names[s["c"]] = ctrl_names.get(s["c"], 0) + 1
        out_msgs[str(mid)] = {"segments": segs, "plain": plain}

    print(f"\n控制码 {len(ctrl_names)} 种，用得最多的：")
    for k, v in sorted(ctrl_names.items(), key=lambda kv: -kv[1])[:8]:
        print(f"     [{k}] {v}")

    os.makedirs(a.out, exist_ok=True)
    payload = {
        "source": SRC,
        "messageCount": len(out_msgs),
        "titles": titles,
        "messages": out_msgs,
    }
    dst = os.path.join(a.out, "texts.json")
    with open(dst, "w", encoding="utf-8") as f:
        json.dump(payload, f, ensure_ascii=False, indent=1)
    print(f"\n→ {dst}  ({os.path.getsize(dst) // 1024} KB)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
