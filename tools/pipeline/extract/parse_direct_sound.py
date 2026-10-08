#!/usr/bin/env python3
"""直采采样（`sound/direct_sound_samples/*.aif`）→ JSON / Dart

## 出处与**已证实的边界**（第 10 轮）

* 采样文件：`third_party/fireemblem8j/sound/direct_sound_samples/*.aif`
  —— **439 个**，标准 **AIFF**（`file` 实测：`IFF data, AIFF audio`）。
* 需求侧：`sound/voicegroups/*.s` 里 `voice_directsound … DirectSoundData_<名字> …`
  引用这些采样（第 9 轮已提取 9787 条 voice）。

## ⚠️ 缺口（**未查证**，不许编）

**符号 → 采样文件** 的映射**不在日版仓库里**：

* 全树 grep `DirectSoundData_k_tubular_c4_13k_s` ⇒ 只出现在 `sound/voicegroups/*.s`
  （**只在引用处**，没有定义/清单）；
* 美版有 `fireemblem8u/sound/direct_sound_data.s`，但它映射的是
  `sound/direct_sound_samples/<名字>.bin` ——**日版是编号的 `<n>.aif`**，
  **两边文件名不同** ⇒ 不能拿美版的名字硬套日版的编号。
* ⇒ 要建立映射，需要**日版构建时生成的** `direct_sound_data.s`（本仓库没有 carve）
  或从 ROM 里读指针表。**在那之前，本项目不提供"符号 → 采样"的对应**。

本提取器因此只做**能证实的两件事**：

1. 读每个 `.aif` 的 **AIFF 头**（声道数 / 帧数 / 位深 / 采样率）；
2. 把**需求侧**（voicegroup 引用到的不同 `DirectSoundData_*` 名字个数）报出来，
   与"手上有 439 个采样"对照 —— 数量对不上就是信号，**不许自动配一个**。

## 判据

* 采样数 == 439（实测）；
* 每个文件都能解析出 COMM 块（否则报错，**不许跳过**）；
* 至少抽查一个文件的**采样率**与 `file(1)` 的输出一致
  （`0.aif` 实测 `1 ch, 8-bit`，rate 见脚本内断言）。
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
SAMPLES = "sound/direct_sound_samples"
VOICEGROUP_DIR = "sound/voicegroups"


def read_aiff_comm(path):
    """返回 (channels, frames, bits, rate, data_bytes)。

    AIFF：`FORM` .. `AIFF` 之后是一串块；`COMM` 块的布局是
    channels(2) frames(4) bits(2) rate(10 字节 80 位扩展浮点)；
    `SSND` 块里前 8 字节是 offset/blocksize，其余是采样数据。
    """
    b = open(path, "rb").read()
    if b[:4] != b"FORM" or b[8:12] != b"AIFF":
        raise SystemExit(f"✗ {path}: 不是 AIFF")
    i = 12
    channels = frames = bits = None
    rate = None
    data_bytes = None
    while i + 8 <= len(b):
        cid = b[i:i + 4]
        size = int.from_bytes(b[i + 4:i + 8], "big")
        body = b[i + 8:i + 8 + size]
        if cid == b"COMM":
            channels = int.from_bytes(body[0:2], "big")
            frames = int.from_bytes(body[2:6], "big")
            bits = int.from_bytes(body[6:8], "big")
            rate = _ext80(body[8:18])
        elif cid == b"SSND":
            data_bytes = max(0, len(body) - 8)
        i += 8 + size + (size & 1)
    if channels is None or frames is None or bits is None or rate is None:
        raise SystemExit(f"✗ {path}: 没找到 COMM 块")
    return channels, frames, bits, rate, data_bytes


def _ext80(raw):
    """80 位扩展浮点（AIFF 采样率就是它）。"""
    if len(raw) < 10:
        return None
    expon = int.from_bytes(raw[0:2], "big")
    mant = int.from_bytes(raw[2:10], "big")
    if expon == 0 and mant == 0:
        return 0
    sign = -1 if expon & 0x8000 else 1
    expon &= 0x7FFF
    return sign * mant * (2.0 ** (expon - 16383 - 63))


def needed_symbols(decomp):
    """需求侧：voicegroup 里引用到的不同 `DirectSoundData_*` 名字。"""
    d = os.path.join(decomp, VOICEGROUP_DIR)
    names = set()
    for f in sorted(os.listdir(d)):
        if not f.endswith(".s"):
            continue
        for line in open(os.path.join(d, f), encoding="utf-8", errors="replace"):
            for m in re.finditer(r"DirectSoundData_(\w+)", line):
                names.add(m.group(1))
    return names


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", default="out/tables")
    ap.add_argument("--json", default="direct_sound_samples.json")
    ap.add_argument("--dart")
    ap.add_argument("--check", action="store_true")
    a = ap.parse_args()

    d = os.path.join(DECOMP, SAMPLES)
    files = sorted(f for f in os.listdir(d) if f.endswith(".aif"))
    samples = {}
    for f in files:
        ch, frames, bits, rate, data = read_aiff_comm(os.path.join(d, f))
        samples[f[:-4]] = {
            "channels": ch, "frames": frames, "bits": bits,
            "rate": round(rate, 3), "dataBytes": data,
        }
    assert len(files) == 439, len(files)
    # ★ 抽查：`0.aif` 的头（值是从文件里读出来、**打印核对过**才写进判据的）
    s0 = samples["0"]
    assert s0["channels"] == 1, s0
    assert s0["bits"] == 8, s0
    assert s0["frames"] == 1199, s0
    assert s0["rate"] == 13379.0, s0          # AIFF 的 80 位扩展浮点解出来就是它
    assert s0["dataBytes"] == 1199, s0
    # ★★ 全量不变量：帧数 × 声道 × 位深/8 == SSND 里的数据长度
    #   （这条比"抽一个文件看看"强：439 个文件全都必须成立）
    #   ⚠️ 第一版这里写的是我**凭印象编的容差** `abs(rate - 13379) < 16000` ——
    #      那正是"自己发明数值"，已删掉。
    for name, v in samples.items():
        expect = v["frames"] * v["channels"] * v["bits"] // 8
        assert expect == v["dataBytes"], \
            f"{name}.aif: 帧×声道×位深/8 = {expect}，但 SSND 数据长度 = {v['dataBytes']}"

    need = needed_symbols(DECOMP)
    out = {
        "source": f"{SAMPLES}/*.aif（AIFF）",
        "count": len(samples),
        "samples": samples,
        "neededSymbolCount": len(need),
        "neededSymbols": sorted(need)[:40],
        "mappingStatus": (
            "**未查证/缺失**：符号 → 采样文件 的映射不在日版仓库里"
            "（`DirectSoundData_*` 只出现在 voicegroup 的引用处）；"
            "美版 `direct_sound_data.s` 用的是**不同文件名**（`<名字>.bin` vs 日版 `<n>.aif`）"
            "⇒ 不能直接套用。需要日版构建产物或 ROM 指针表。"
        ),
    }
    os.makedirs(a.out, exist_ok=True)
    with open(os.path.join(a.out, a.json), "w", encoding="utf-8") as f:
        json.dump(out, f, ensure_ascii=False, indent=1)

    if a.dart:
        lines = [
            "// 由 tools/pipeline/extract/parse_direct_sound.py 生成，**不要手改**。",
            "// 出处：sound/direct_sound_samples/*.aif（AIFF 头）",
            "// PORT OF: sound/direct_sound_samples/*.aif",
            "",
            "/// 一个直采采样（只含**头信息**，不含音频数据）",
            "class DirectSoundSample {",
            "  const DirectSoundSample(this.channels, this.frames, this.bits,",
            "      this.rate, this.dataBytes);",
            "  final int channels;",
            "  final int frames;",
            "  final int bits;",
            "  final double rate;",
            "  final int dataBytes;",
            "}",
            "",
            f"/// {len(samples)} 个采样，键是**文件名**（`<n>.aif` 的 `<n>`）",
            "///",
            "/// ⚠️ **没有**「符号名 → 采样」的映射 —— 见",
            "/// `docs/计划-音频.md`：日版仓库里不存在该映射（未 carve）。",
            "const Map<String, DirectSoundSample> gDirectSoundSamples = {",
        ]
        for k, v in samples.items():
            lines.append(f"  '{k}': DirectSoundSample({v['channels']}, {v['frames']}, "
                         f"{v['bits']}, {v['rate']}, {v['dataBytes']}),")
        lines += ["};", ""]
        text = "\n".join(lines)
        if a.check:
            old = open(a.dart, encoding="utf-8").read() if os.path.exists(a.dart) else None
            if old != text:
                print(f"✗ {a.dart} 与生成结果不一致（不带 --check 重新生成）")
                return 1
            print(f"✓ {a.dart} 一致（{len(samples)} 个）")
        else:
            os.makedirs(os.path.dirname(a.dart) or ".", exist_ok=True)
            open(a.dart, "w", encoding="utf-8").write(text)
            print(f"已写 {a.dart}（{len(samples)} 个）")

    print(f"采样：{len(samples)} 个 AIFF；"
          f"需求侧 voicegroup 引用了 {len(need)} 个不同 DirectSoundData_* 名字")
    print(f"⚠️ 符号→文件映射：{out['mappingStatus'][:40]}…")
    return 0


if __name__ == "__main__":
    sys.exit(main() or 0)
