#!/usr/bin/env python3
"""可编程波（`sound/programmable_wave_data.s`）+ 键分离表使用情况 → JSON / Dart

## 出处

* `sound/programmable_wave_data.s`：11 条，形如

      wave000_sinewave: @ 8214004
          .incbin "sound/programmable_wave_samples/wave000_sinewave.pcm"

  ⇒ 地址注解在**标签行**，`.incbin` 在**下一行**（第一版把它们配错了，一条都没算出来）。
* `sound/programmable_wave_samples/*.pcm`：11 个文件，**每个 16 字节**
  （GBA 波 RAM 一页 = 16 B = 32 个 4 位样本）。
* `sound/keysplit_tables.s`：**死数据**。源码文件自己的注释就写着
  "These keysplit tables appear to be unused in Fire Emblem 8."

## ★ 判据

1. **字节严丝合缝**：波 `k` 的地址到波 `k+1` 的地址之间的**间隙**，
   必须等于波 `k` 那个 `.pcm` 文件的**实际大小**（11 条里 10 条有后继，全部相符）。
2. **"键分离表未使用"是可验证的事实**（三个数字互证）：
   * 引用 `keysplit_table_*` 的 voicegroup 文件数 == **0**；
   * `voice_keysplit`（type `0x40`）出现次数 == **0**；
   * `voice_keysplit_all`（type `0x80`）出现次数 == **67**（它指向**音色组**，不需要表）。
   ⇒ 这一条**故意做成断言**：将来若有人 carve 出真正的键分离引用，这里会红。
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
WAVE_S = "sound/programmable_wave_data.s"
VOICEGROUP_DIR = "sound/voicegroups"


def parse_waves(decomp):
    lines = open(os.path.join(decomp, WAVE_S), encoding="utf-8",
                 errors="replace").read().split("\n")
    out = []
    for i, l in enumerate(lines):
        m = re.match(r"(\w+):\s*@\s*([0-9A-Fa-f]+)\s*$", l.strip())
        if not m:
            continue
        sym, addr = m.group(1), int(m.group(2), 16)
        path = None
        for j in range(i + 1, min(i + 4, len(lines))):
            fm = re.search(r'incbin "([^"]+)"', lines[j])
            if fm:
                path = fm.group(1)
                break
        if path is None:
            raise SystemExit(f"✗ {WAVE_S}:{i + 1} `{sym}` 后面没有 .incbin")
        full = os.path.join(decomp, path)
        out.append({"symbol": sym, "addr": addr, "file": path,
                    "bytes": os.path.getsize(full)})
    return out


def keysplit_usage(decomp):
    d = os.path.join(decomp, VOICEGROUP_DIR)
    refs = 0
    keysplit = 0
    keysplit_all = 0
    for f in sorted(os.listdir(d)):
        if not f.endswith(".s"):
            continue
        t = open(os.path.join(d, f), encoding="utf-8", errors="replace").read()
        if "keysplit_table" in t:
            refs += 1
        keysplit += len(re.findall(r"^\s*voice_keysplit\s", t, re.M))
        keysplit_all += len(re.findall(r"^\s*voice_keysplit_all\s", t, re.M))
    return refs, keysplit, keysplit_all


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", default="out/tables")
    ap.add_argument("--json", default="programmable_waves.json")
    ap.add_argument("--dart")
    ap.add_argument("--check", action="store_true")
    a = ap.parse_args()

    waves = parse_waves(DECOMP)
    assert len(waves) == 11, len(waves)
    assert all(w["bytes"] == 16 for w in waves), waves
    # ★ 判据 1：地址间隙 == 文件实际大小
    for k in range(len(waves) - 1):
        gap = waves[k + 1]["addr"] - waves[k]["addr"]
        assert gap == waves[k]["bytes"], \
            f"{waves[k]['symbol']}: 间隙 {gap} != 文件大小 {waves[k]['bytes']}"
    assert waves[0]["symbol"] == "wave000_sinewave", waves[0]
    assert waves[0]["addr"] == 0x08214004, hex(waves[0]["addr"])

    # ★ 判据 2：键分离表确实是死数据（三个数字互证）
    refs, ks, ksa = keysplit_usage(DECOMP)
    assert refs == 0, f"有 {refs} 个 voicegroup 引用了 keysplit_table_*"
    assert ks == 0, f"voice_keysplit 出现了 {ks} 次"
    assert ksa == 67, f"voice_keysplit_all 出现了 {ksa} 次（基线 67）"

    out = {
        "source": f"{WAVE_S} + sound/programmable_wave_samples/*.pcm",
        "count": len(waves),
        "waves": waves,
        "keysplit": {
            "tableRefs": refs,
            "voiceKeysplit": ks,
            "voiceKeysplitAll": ksa,
            "status": (
                "**未使用**（源码 `sound/keysplit_tables.s` 自述 "
                "\"These keysplit tables appear to be unused in Fire Emblem 8.\"，"
                "本提取器用三个计数互证：表引用 0、`voice_keysplit` 0、"
                "`voice_keysplit_all` 67（它指向音色组，不需要表））"
            ),
        },
    }
    os.makedirs(a.out, exist_ok=True)
    with open(os.path.join(a.out, a.json), "w", encoding="utf-8") as f:
        json.dump(out, f, ensure_ascii=False, indent=1)

    if a.dart:
        lines = [
            "// 由 tools/pipeline/extract/parse_programmable_waves.py 生成，**不要手改**。",
            "// 出处：sound/programmable_wave_data.s + sound/programmable_wave_samples/*.pcm",
            "// PORT OF: sound/programmable_wave_data.s",
            "",
            "/// 一个可编程波（GBA 波 RAM 一页 = 16 字节 = 32 个 4 位样本）",
            "class ProgrammableWave {",
            "  const ProgrammableWave(this.symbol, this.bytes);",
            "  final String symbol;",
            "  final int bytes;",
            "}",
            "",
            f"/// {len(waves)} 个波；地址由 `programmable_wave_data.s` 的注解核对过",
            "const List<ProgrammableWave> gProgrammableWaves = [",
        ]
        for w in waves:
            lines.append(f"  ProgrammableWave('{w['symbol']}', {w['bytes']}),")
        lines += [
            "];",
            "",
            "/// 键分离表在 FE8 里**未使用**（三个计数互证，见提取器判据）",
            f"const int gKeysplitTableRefs = {refs};",
            f"const int gVoiceKeysplitCount = {ks};",
            f"const int gVoiceKeysplitAllCount = {ksa};",
            "",
        ]
        text = "\n".join(lines)
        if a.check:
            old = open(a.dart, encoding="utf-8").read() if os.path.exists(a.dart) else None
            if old != text:
                print(f"✗ {a.dart} 与生成结果不一致（不带 --check 重新生成）")
                return 1
            print(f"✓ {a.dart} 一致（{len(waves)} 个波）")
        else:
            os.makedirs(os.path.dirname(a.dart) or ".", exist_ok=True)
            open(a.dart, "w", encoding="utf-8").write(text)
            print(f"已写 {a.dart}（{len(waves)} 个波）")

    print(f"可编程波：{len(waves)} 个 × 16 B（间隙与文件大小逐条相符）；"
          f"键分离：表引用 {refs}、voice_keysplit {ks}、keysplit_all {ksa} ⇒ **未使用**")
    return 0


if __name__ == "__main__":
    sys.exit(main() or 0)
