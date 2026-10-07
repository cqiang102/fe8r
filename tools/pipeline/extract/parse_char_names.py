#!/usr/bin/env python3
"""角色编号 -> 符号名（`include/constants/characters.h`）。

为什么需要：`gDefeatTalkList` 里用的是 **符号名**（`CHARACTER_ONEILL`），
而 `UnitDefinition.charIndex` 是 **数字**。胜负判定要认"首领是谁"，
就必须把两边对起来。
"""
import argparse, json, os, re, sys

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.abspath(os.path.join(HERE, "..", "..", ".."))
DECOMP = os.path.join(REPO, "third_party", "fireemblem8j")

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", default=os.path.join(HERE, "..", "out", "tables"))
    a = ap.parse_args()
    p = os.path.join(DECOMP, "include", "constants", "characters.h")
    if not os.path.exists(p):
        print("  ✗ 缺 characters.h", file=sys.stderr); return 1
    t = open(p, encoding="utf-8", errors="replace").read()
    out = {}
    for m in re.finditer(r"(CHARACTER_\w+)\s*=\s*(0x[0-9A-Fa-f]+|\d+)", t):
        v = int(m.group(2), 16) if m.group(2).startswith("0x") else int(m.group(2))
        out[v] = m.group(1)
    if not out:
        print("  ✗ 一个都没解出来", file=sys.stderr); return 1
    os.makedirs(a.out, exist_ok=True)
    dst = os.path.join(a.out, "char_names.json")
    json.dump(out, open(dst, "w", encoding="utf-8"), ensure_ascii=False, indent=1)
    print(f"  {len(out)} 个角色名 -> {dst}")
    return 0

if __name__ == "__main__":
    sys.exit(main())
