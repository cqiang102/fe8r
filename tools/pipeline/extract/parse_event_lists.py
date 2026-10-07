#!/usr/bin/env python3
"""
解析事件列表（`EventListScr_*_*`）—— **胜负条件在这里**。

# 机制（出处逐条）

## 列表的遍历（`src/SearchAvailableEvent.c:40-54`）

```c
for (;;) {
    int cmdId = EVT_CMD_LO(info->listScript[0]);      // 低 16 位 = 命令
    if (!CheckFlag(EVT_CMD_HI(info->listScript[0])))  // 高 16 位 = 「已执行」标志
        if (cmdInfo[cmdId].func(info) == 1) goto _end;
    info->listScript += len[cmdId << 1];              // 每条长度由命令决定
}
```

`EVT_CMD_LO(cmd) = cmd & 0xFFFF`、`EVT_CMD_HI(cmd) = cmd >> 16`。

**所以 HI 是"这条已经执行过"的标志** —— 执行后置上，避免重复触发。

## 命令表（`src/data/gEventListCmdInfoTable_ref/*.s`）

    EvCheck00_Always   长度 1     cmd 0  = END
    EvCheck01_AFEV     长度 3     cmd 1  = FLAG   <- 胜负条件用它
    EvCheck02_TURN     长度 3     cmd 2  = TURN
    EvCheck03_CHAR     长度 4     cmd 3  = CHAR
    EvCheck05_LOCA     长度 3     cmd 5  = LOCA
    ...

## FLAG 条目的结构（`src/EvCheck01_AFEV.c`）

```c
struct EvCheck01 { u32 unk0; u32 script; u32 unk8; };

int EvCheck01_AFEV(struct EventInfo* info) {
    if ((unk8 == 0) || (unk8 == 100) || (CheckFlag(unk8) == 1)) {
        info->script = listScript->script;
        info->flag   = EVT_CMD_HI(listScript->unk0);
        return 1;
    }
    return 0;
}
```

**`{命令|已执行标志, 脚本指针, 要检查的事件标志}` 三个字。**

## ⚠️ 我在这里绕过一次

我一开始以为末尾的 `0x65` 是**终止符** —— 其实它是**第三条的检查标志**
（`EVFLAG_GAMEOVER = 101 = 0x65`）。真正的终止符是后面那条 `cmd = 0`（END）。

**判据**：字节数按"每条长度由命令决定"完全对齐，一条不多一条不少。
"""
import argparse
import glob
import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.abspath(os.path.join(HERE, "..", "..", ".."))
DECOMP = os.path.join(REPO, "third_party", "fireemblem8j")

# 命令 id -> (名字, 长度)
CMDS = {
    0x00: ("END", 1), 0x01: ("FLAG", 3), 0x02: ("TURN", 3), 0x03: ("CHAR", 4),
    0x04: ("CHARASM", 4), 0x05: ("LOCA", 3), 0x06: ("VILL", 3),
    0x07: ("CHES", 3), 0x08: ("DOOR", 3), 0x09: ("DRAWBRIDGE", 3),
    0x0A: ("SHOP", 3), 0x0B: ("AREA", 3), 0x0C: ("NEVER_C", 3),
    0x0D: ("NEVER_D", 3), 0x0E: ("E", 3), 0x0F: ("F", 3), 0x10: ("10", 3),
}

LABEL = re.compile(r"^(EventListScr_\w+):\s*$")


def parse_file(path):
    """把一个 .s 里的所有 `EventListScr_*` 解出来。

    返回值：`{列表名: (字节流, {字下标: 符号名})}`。
    ⚠️ 符号名（`.4byte EventScr_Xxx`）必须**单独记下来** ——
    它没有数值地址（会重定位），摊成字节只会变成 0，脚本名就丢了。
    """
    out = {}
    cur, words, syms = None, [], {}
    for line in open(path, encoding="utf-8", errors="replace"):
        m = LABEL.match(line)
        if m:
            if cur:
                out[cur] = (words, syms)
            cur, words, syms = m.group(1), [], {}
            continue
        if cur is None:
            continue
        if line.startswith("\t.section") or line.startswith(".section"):
            out[cur] = (words, syms)
            cur, words, syms = None, [], {}
            continue
        # ★ **统一攒字节**，不要混着攒。
        #
        # 我第一版把 `.byte` 的值和 `.4byte` 的值塞进同一个 list，
        # 再当成字节流重新分字 —— 结果 `.4byte` 的指针被拆成了 4 个字节值，
        # 解出来的 `raw` 大得离谱（`0x1e131307000b`）。
        #
        # 正确做法：一律摊成字节；`.byte` 是 1 字节/值，`.4byte` 是 4 字节小端。
        mb = re.match(r"^\s*\.byte\s+(.+?)\s*$", line)
        mw = re.match(r"^\s*\.4byte\s+(.+?)\s*$", line)
        if mb:
            for x in mb.group(1).split(","):
                x = x.strip()
                if x.startswith("0x"):
                    words.append(int(x, 16) & 0xFF)
        elif mw:
            # 先补齐到 4 字节边界（汇编里 .4byte 本来就对齐）
            while len(words) % 4:
                words.append(0)
            for tok in mw.group(1).split(","):
                tok = tok.strip()
                if tok.startswith("0x"):
                    v = int(tok, 16)
                else:
                    # 符号名（可能带 `+ 0x1` 之类）—— 记名字，字节填 0
                    v = 0
                    syms[len(words) // 4] = tok
                words.extend([v & 0xFF, (v >> 8) & 0xFF,
                              (v >> 16) & 0xFF, (v >> 24) & 0xFF])
    if cur:
        out[cur] = (words, syms)
    return out


def to_words(bs):
    """把字节流按 4 字节小端攒成字（`.byte` 是按字节写的）"""
    out = []
    for i in range(0, len(bs) - 3, 4):
        w = bs[i] | (bs[i + 1] << 8) | (bs[i + 2] << 16) | (bs[i + 3] << 24)
        out.append(w)
    return out


def decode_list(words, syms=None):
    """按命令长度逐条走，返回条目列表。**字节数必须严丝合缝。**"""
    entries = []
    i = 0
    while i < len(words):
        w0 = words[i]
        cmd = w0 & 0xFFFF
        flag = (w0 >> 16) & 0xFFFF
        if cmd not in CMDS:
            entries.append({"i": i, "cmd": cmd, "raw": hex(w0), "unknown": True})
            break
        name, n = CMDS[cmd]
        if cmd == 0x00:  # END
            entries.append({"i": i, "cmd": name})
            i += 1
            break
        if i + n > len(words):
            entries.append({"i": i, "cmd": name, "raw": hex(w0), "truncated": True})
            break
        e = {"i": i, "cmd": name, "doneFlag": flag}
        if cmd == 0x01:  # FLAG
            e["script"] = (syms or {}).get(i + 1) or (
                hex(words[i + 1]) if words[i + 1] else None)
            e["checkFlag"] = words[i + 2]
        entries.append(e)
        i += n
    return entries


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", default=os.path.join(HERE, "..", "out", "tables"))
    ap.add_argument("--script-syms", default=None,
                    help="脚本名映射（可选）：hex 地址 -> 名字")
    a = ap.parse_args()

    files = sorted(glob.glob(
        os.path.join(DECOMP, "src", "data", "**", "*.s"), recursive=True))
    raw = {}
    for f in files:
        for name, (w, syms) in parse_file(f).items():
            if name not in raw and len(w) >= 4:
                raw[name] = (w, syms)

    # 只保留事件列表（8 张一组：Turn/Character/Location/Misc/...）
    lists = {}
    for name, (bs, syms) in raw.items():
        lists[name] = decode_list(to_words(bs), syms)

    print(f"  解出 {len(lists)} 个事件列表")
    # 重点：Misc（胜负条件）
    misc = {k: v for k, v in lists.items() if "Misc" in k}
    print(f"  其中 Misc（胜负条件）{len(misc)} 个")
    for k in sorted(misc)[:3]:
        print(f"    {k}: {misc[k]}")

    dst = os.path.join(a.out, "event_lists.json")
    os.makedirs(a.out, exist_ok=True)
    with open(dst, "w", encoding="utf-8") as f:
        json.dump({
            "note": "事件列表。Misc 里的 FLAG 条目就是胜负条件（见文件头）。",
            "cmdTable": {str(k): v for k, v in CMDS.items()},
            "lists": lists,
        }, f, ensure_ascii=False, indent=1)
    print(f"→ {dst}  ({os.path.getsize(dst) // 1024} KB)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
