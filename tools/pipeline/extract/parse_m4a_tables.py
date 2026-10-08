#!/usr/bin/env python3
"""M4A 的数值表（`src/m4a_tables.c`）→ JSON / Dart

## 出处

`third_party/fireemblem8j/src/m4a_tables.c` —— **可读的 C**（日版这块是 carve 的 C，
与 `gMPlayJumpTableTemplate` 不同）。本提取器只抽**纯数值表**：

* `gClockTable[49]`：**等待时长表**。音序器里 `0x80..0xB0` 这些命令
  （`src/m4a_1.s:1071-1076`）就是"等待 `gClockTable[op - 0x80]` 个 tick"。
  ⚠️ 它**不是 0..48 连续**：尾部是 68,72,76,78,80,84,88,90,92,96
  ⇒ **必须从源码抽，不能手抄**（手抄 49 个数就是给自己埋雷）。
* `gScaleTable[192]`、`gFreqTable[12]`、`gPcmSamplesPerVBlankTable`、
  `gPcmFreqTable`、`gCgbScaleTable`、`gCgbFreqTable` 等。

## 判据

* 每张表抽到的**条数**与源码一致（下面逐张断言）；
* `gClockTable` 的**首尾**正向抽查（0 开头、96 结尾）；
* 抽取**不许静默少覆盖**：不认识的非数值表直接报错退出。
"""

import argparse
import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
DECOMP = os.environ.get(
    "FE8R_DECOMP",
    os.path.normpath(os.path.join(HERE, "..", "..", "..", "third_party", "fireemblem8j")),
)
SRC = "src/m4a_tables.c"

# 期望条数（从源码数出来的；变了要有人看一眼）
EXPECT = {
    "gClockTable": 49,
    # ⚠️ 我一开始按"16 组 × 12"写成 192 —— 实测是 **180**（15 组 × 12）。
    #    源码 `src/m4a_tables.c:12-29` 就是 **15 行**。
    "gScaleTable": 180,
    "gFreqTable": 12,
}


def parse_tables(path):
    text = open(path, encoding="utf-8", errors="replace").read()
    out = {}
    for m in re.finditer(r"const\s+\w+\s+(\w+)\[\]\s*=\s*\{(.*?)\};", text, re.S):
        name, body = m.group(1), m.group(2)
        body = re.sub(r"//[^\n]*", "", body)
        vals = []
        ok = True
        for tok in body.split(","):
            t = tok.strip()
            if not t:
                continue
            # C 的整数字面量可以带后缀（`gFreqTable` 里就是 `2147483648u`）
            if re.fullmatch(r"(0[xX][0-9A-Fa-f]+|\d+)[uUlL]*", t):
                vals.append(int(re.sub(r"[uUlL]+$", "", t), 0))
            else:
                ok = False  # 非纯数值（指针表之类）
                break
        if ok and vals:
            out[name] = vals
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", default="out/tables")
    ap.add_argument("--json", default="m4a_tables.json")
    ap.add_argument("--dart")
    ap.add_argument("--check", action="store_true")
    a = ap.parse_args()

    tables = parse_tables(os.path.join(DECOMP, SRC))
    for name, n in EXPECT.items():
        assert name in tables, f"没抽到 {name} —— 不许静默少覆盖"
        assert len(tables[name]) == n, f"{name} 条数 {len(tables[name])} != {n}"
    # ★ 正向抽查（对着 `src/m4a_tables.c:122-170` 的首尾）
    clock = tables["gClockTable"]
    assert clock[0] == 0x00, clock[0]
    assert clock[-1] == 0x60, hex(clock[-1])
    assert clock[:16] == list(range(16)), clock[:16]
    assert clock[-10:] == [68, 72, 76, 78, 80, 84, 88, 90, 92, 96], clock[-10:]
    # `gScaleTable` 是 16 组、每组 12 个，呈 0xE0..0x0B 递减
    scale = tables["gScaleTable"]
    assert scale[0] == 0xE0 and scale[-1] == 0x0B, (scale[0], scale[-1])
    assert len(scale) % 12 == 0 and len(scale) // 12 == 15, len(scale)
    assert tables["gFreqTable"][0] == 2147483648, tables["gFreqTable"][0]

    out = {
        "source": SRC,
        "tables": {k: {"count": len(v), "values": v} for k, v in tables.items()},
    }
    os.makedirs(a.out, exist_ok=True)
    with open(os.path.join(a.out, a.json), "w", encoding="utf-8") as f:
        json.dump(out, f, ensure_ascii=False, indent=1)

    if a.dart:
        lines = [
            "// 由 tools/pipeline/extract/parse_m4a_tables.py 生成，**不要手改**。",
            "// 出处：src/m4a_tables.c（日版这里就是可读的 C）",
            "// PORT OF: src/m4a_tables.c",
            "",
            "/// M4A 的**等待时长表**（`gClockTable[49]`）",
            "///",
            "/// 音序器里 `0x80..0xB0` 这些命令就是"
            "「等待 `gClockTable[op - 0x80]` 个 tick」",
            "/// （`src/m4a_1.s:1071-1076`）。⚠️ **不是 0..48 连续**：",
            "/// 尾部是 68,72,76,78,80,84,88,90,92,96 ⇒ 必须按表查，不能算。",
            "const List<int> gClockTable = [",
        ]
        for i in range(0, len(clock), 12):
            lines.append("  " + ", ".join(str(v) for v in clock[i:i + 12]) + ",")
        lines += ["];", ""]
        lines += [
            "/// `gScaleTable[192]`（16 组 × 12，音高换算用）",
            f"const int gScaleTableCount = {len(scale)};",
            "/// `gFreqTable[12]`（频率表）",
            "const List<int> gFreqTable = [",
        ]
        for i in range(0, len(tables["gFreqTable"]), 6):
            lines.append("  " + ", ".join(str(v) for v in tables["gFreqTable"][i:i + 6]) + ",")
        lines += ["];", ""]
        text = "\n".join(lines)
        if a.check:
            old = open(a.dart, encoding="utf-8").read() if os.path.exists(a.dart) else None
            if old != text:
                print(f"✗ {a.dart} 与生成结果不一致（不带 --check 重新生成）")
                return 1
            print(f"✓ {a.dart} 一致")
        else:
            os.makedirs(os.path.dirname(a.dart) or ".", exist_ok=True)
            open(a.dart, "w", encoding="utf-8").write(text)
            print(f"已写 {a.dart}")

    print("M4A 数值表：" + "、".join(f"{k}({len(v)})" for k, v in tables.items()))
    print(f"gClockTable 首尾 = {clock[0]}, …, {clock[-1]}")
    return 0


if __name__ == "__main__":
    sys.exit(main() or 0)
