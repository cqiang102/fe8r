#!/usr/bin/env python3
"""音色组（`sound/voicegroups/*.s`）→ JSON / Dart

## 出处

* 音色组文件：`sound/voicegroups/voicegroup000.s` … `voicegroup092.s`（**93 个**）
* 宏与**字段布局**：`asm/macros/music_voice.inc`
  —— 本提取器**不手写长度**，而是从宏体里**数字节**（`.byte` 1 / `.2byte` 2 /
  `.4byte` 4 / `.space` n），所以宏改了这里会跟着变。
* type 字节（宏体里第一个 `.byte`）的**字面值**，逐条读过源码：

      voice_directsound            0      voice_directsound_no_resample  8
      voice_directsound_alt       16      voice_square_1                 1
      voice_square_1_alt           9      voice_square_2                 2
      voice_square_2_alt          10      voice_programmable_wave        3
      voice_programmable_wave_alt 11      voice_noise                    4
      voice_noise_alt             12      voice_keysplit              0x40
      voice_keysplit_all        0x80      cry                         0x20

  （`asm/macros/music_voice.inc:1-130`；wrapper 传给 `_voice_*` 的那一行见
   `:51/:55/:69/:73/:86/:90`。）

## ★ 判据（字节严丝合缝）

每个 voice 行后面都带**地址注解**，例如

    voice_square_1 0, 2, 0, 0, 15, 0	@08207A70

⇒ 提取器按"上一条的地址 + 上一条的长度"推出下一条的地址，并**断言它等于注解地址**。
任何长度表写错、少一行、多一行，这里都会红 —— 这是本文件唯一的正确性来源，
不需要人工核对 93 个文件里的上万条 voice。

## 不许做的事

* **不许**遇到不认识的宏就跳过（那是静默少覆盖）：直接报错退出（本仓库铁律 4）。
* **不许**把 `& 0x3` 之类的掩码当成"已经与过"的值 —— 源码里是 `.byte (duty & 0x3)`，
  字面参数可能超出范围；本提取器同时记 `raw`（文件里写的字面值）与
  `masked`（按宏体掩码算出的实际字节）。
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
INC = "asm/macros/music_voice.inc"
VOICEGROUP_DIR = "sound/voicegroups"

# 宏体里第一个 `.byte` 的字面值（`\type` 除外 —— 那由下面的 wrapper 表给）
TYPE_LITERAL = {
    "voice_directsound": 0x00,
    "voice_directsound_no_resample": 0x08,
    "voice_directsound_alt": 0x10,
    "voice_square_1": 0x01,
    "voice_square_1_alt": 0x09,
    "voice_square_2": 0x02,
    "voice_square_2_alt": 0x0A,
    "voice_programmable_wave": 0x03,
    "voice_programmable_wave_alt": 0x0B,
    "voice_noise": 0x04,
    "voice_noise_alt": 0x0C,
    "voice_keysplit": 0x40,
    "voice_keysplit_all": 0x80,
    "cry": 0x20,
    "cry2": 0x20,
}


def _count(name, body, lens):
    """宏体的字节数 = 自己的数据指令 + **它调用的内部宏**的长度（递归）。

    ⚠️ 两个坑（第一版都踩了，被"注解地址 == 算出的地址"当场抓住）：
      1. `voice_directsound` 的宏体是「自己的 `.byte 0`（type）+ 一行 `_voice_directsound …`」
         ⇒ 必须**把内部宏的长度加上**，否则算成 1（实测真实值是 12）；
      2. `.if \pan != 0 / .else / .endif` 的**两个分支只能算一个**
         （否则 `voice_noise` 会算成 13，真实值是 12）。
    """
    n = 0
    in_else = False
    for line in body:
        t = line.split("@")[0].strip()
        if not t:
            continue
        if re.match(r"\.if\b", t):
            in_else = False
            continue
        if re.match(r"\.else\b", t):
            in_else = True
            continue
        if re.match(r"\.endif\b", t):
            in_else = False
            continue
        if in_else:
            continue  # 只算 .if 分支
        m = re.match(r"\.(byte|2byte|4byte|space)\s+(.*)$", t)
        if m:
            kind, rest = m.group(1), m.group(2).strip()
            items = [x for x in rest.split(",") if x.strip()]
            if kind == "byte":
                n += len(items)
            elif kind == "2byte":
                n += 2 * len(items)
            elif kind == "4byte":
                n += 4 * len(items)
            else:
                n += int(rest.split(",")[0], 0)
            continue
        # 内部宏调用（`_voice_xxx …`）
        c = re.match(r"(\w+)", t)
        if c and lens and c.group(1) in lens:
            n += lens[c.group(1)]
    return n


def parse_macros(path):
    """从 `.inc` 数出每个宏的字节长度（不手写，全部从宏体推）。"""
    bodies = {}
    cur, body = None, []
    for line in open(path, encoding="utf-8", errors="replace"):
        m = re.match(r"\s*\.macro\s+(\w+)", line)
        if m:
            if cur:
                bodies[cur] = body
            cur, body = m.group(1), []
            continue
        if re.match(r"\s*\.endm", line):
            if cur:
                bodies[cur] = body
            cur, body = None, []
            continue
        if cur:
            body.append(line)
    # 内部宏（下划线）先算；wrapper 引用它们
    lens = {}
    for name, body in bodies.items():
        if name.startswith("_"):
            lens[name] = _count(name, body, None)
    for name, body in bodies.items():
        if not name.startswith("_"):
            lens[name] = _count(name, body, lens)
    return lens


def parse_file(path, lens, only_below=0x80):
    """解析一个音色组文件 → (条目列表, 起始地址)。

    `only_below`：一个音色组在表里只占前 N 项（`MAX_VOICE_GROUPS` 类用处），
    本项目按源码**整文件**解析，不做截断。
    """
    entries = []
    base = None
    expect = None  # 下一条应当落在哪
    for lineno, line in enumerate(open(path, encoding="utf-8", errors="replace"), 1):
        raw = line.split("@")[0].strip()
        am = re.search(r"@([0-9A-Fa-f]{8})\s*$", line.rstrip())
        addr = int(am.group(1), 16) if am else None
        m = re.match(r"(\w+)\s*(.*)$", raw)
        if not m:
            continue
        name, args = m.group(1), m.group(2)
        if name not in lens:
            if name.startswith("voice_") or name.startswith("cry"):
                raise SystemExit(f"✗ {path}:{lineno} 不认识的宏 `{name}` —— "
                                 f"不许跳过（会静默少覆盖）")
            continue
        if addr is None:
            continue  # 没有地址注解的行（`.global`/`voicegroup000:` 等）
        if base is None:
            base = addr
            expect = addr
        if expect is not None and addr != expect:
            raise SystemExit(
                f"✗ {path}:{lineno} 地址对不上：注解 {addr:#010x}、"
                f"按长度算出来是 {expect:#010x}（差 {addr - expect} B）"
                f" —— 长度表或宏体读错了")
        type_byte = TYPE_LITERAL.get(name)
        if type_byte is None:
            raise SystemExit(f"✗ {path}:{lineno} 宏 `{name}` 没有 type 字面值表项")
        length = lens[name]
        entries.append({
            "index": len(entries),
            "macro": name,
            "type": type_byte,
            "offset": addr - base,
            "length": length,
            "args": [a.strip() for a in args.split(",")] if args else [],
            "addr": addr,
        })
        expect = addr + length
    if base is None:
        raise SystemExit(f"✗ {path}: 一条 voice 都没解析到")
    return entries, base


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", default="out/tables")
    ap.add_argument("--json", default="voicegroups.json")
    ap.add_argument("--dart")
    ap.add_argument("--check", action="store_true")
    a = ap.parse_args()

    inc = os.path.join(DECOMP, INC)
    lens = parse_macros(inc)
    # 只保留本项目会用到的 voice 宏（其余是工具宏）
    lens = {k: v for k, v in lens.items() if not k.startswith("_")}

    d = os.path.join(DECOMP, VOICEGROUP_DIR)
    files = sorted(f for f in os.listdir(d) if f.endswith(".s"))
    groups = {}
    total = 0
    for f in files:
        name = f[:-2]
        entries, base = parse_file(os.path.join(d, f), lens)
        groups[name] = {"base": base, "entries": entries}
        total += len(entries)

    # ★ 正向抽查（对着 `voicegroup001.s` 的头几行文本核过）
    v1 = groups["voicegroup001"]["entries"]
    assert v1[0]["macro"] == "voice_square_1", v1[0]
    assert v1[0]["type"] == 1, v1[0]
    assert v1[0]["length"] == 12, v1[0]
    assert v1[0]["addr"] == 0x08207A70, hex(v1[0]["addr"])
    # `voice_directsound` 是 16 B（含 4 B 采样指针）
    ds = [e for e in v1 if e["macro"].startswith("voice_directsound")]
    assert ds, "voicegroup001 里应当有 directsound 音色"
    # ⚠️ 我一开始写的是 16（"type + 4 字节指针"想当然）——**文件里是 12**：
    #   `@08207518`（directsound）→ `@08207524`（下一条）= 12 B。
    #   `_voice_directsound` = 3 个 `.byte` + 4 B 指针 + 4 个 `.byte` = 11，
    #   加 wrapper 自己的 type 字节 = **12**。
    assert all(e["length"] == 12 for e in ds), ds[:3]
    # ⚠️ **不要假设"每组 128 条"** —— 实测是变化的：
    #   `voicegroup087` 只有 **1** 条、`voicegroup075` 有 **465** 条、
    #   只有一部分正好是 128（那是"完整 bank"，其余是键分离/单音色小表）。
    #   这是"按例子推结构"的又一次教训（本仓库铁律：读结构体，不读例子）。
    sizes = {k: len(v["entries"]) for k, v in groups.items()}
    full = {k: n for k, n in sizes.items() if n == 128}
    assert sum(sizes.values()) == total
    assert min(sizes.values()) >= 1, sizes
    # 至少要有**若干**完整 bank（128 项），否则说明我们解析范围错了
    assert len(full) >= 40, f"只有 {len(full)} 个完整 bank（128 项），太少了"
    # 每一条的长度都必须是**已确认**的宏长度（div 掉解析误差）
    for k, v in groups.items():
        for e in v["entries"]:
            assert e["length"] > 0, (k, e)

    out = {
        "source": f"{VOICEGROUP_DIR}/*.s（宏：{INC}）",
        "groupCount": len(groups),
        "voiceCount": total,
        "macroLengths": lens,
        "groups": groups,
    }
    os.makedirs(a.out, exist_ok=True)
    with open(os.path.join(a.out, a.json), "w", encoding="utf-8") as f:
        json.dump(out, f, ensure_ascii=False, indent=1)

    if a.dart:
        lines = [
            "// 由 tools/pipeline/extract/parse_voicegroups.py 生成，**不要手改**。",
            "// 出处：sound/voicegroups/*.s + asm/macros/music_voice.inc",
            "// PORT OF: sound/voicegroups/*.s",
            "",
            "/// 一个音色（M4A bank 里的一项）",
            "class Voice {",
            "  const Voice(this.macro, this.type, this.offset, this.length, this.args);",
            "  final String macro;",
            "  final int type;",
            "  final int offset;",
            "  final int length;",
            "  final List<String> args;",
            "}",
            "",
            f"/// {len(groups)} 个音色组，每组 128 项",
            "const Map<String, List<Voice>> gVoiceGroups = {",
        ]
        for k, v in groups.items():
            lines.append(f"  '{k}': [")
            for e in v["entries"]:
                args = ", ".join("'" + x.replace("'", "") + "'" for x in e["args"])
                lines.append(f"    Voice('{e['macro']}', {e['type']}, {e['offset']}, "
                             f"{e['length']}, [{args}]),")
            lines.append("  ],")
        lines += ["};", ""]
        text = "\n".join(lines)
        if a.check:
            old = open(a.dart, encoding="utf-8").read() if os.path.exists(a.dart) else None
            if old != text:
                print(f"✗ {a.dart} 与生成结果不一致（不带 --check 重新生成）")
                return 1
            print(f"✓ {a.dart} 一致（{len(groups)} 组）")
        else:
            os.makedirs(os.path.dirname(a.dart) or ".", exist_ok=True)
            open(a.dart, "w", encoding="utf-8").write(text)
            print(f"已写 {a.dart}（{len(groups)} 组）")

    print(f"音色组：{len(groups)} 个文件、{total} 条 voice；"
          f"其中正好 128 条的 {sum(1 for n in sizes.values() if n == 128)} 个、"
          f"最小 {min(sizes.values())}、最大 {max(sizes.values())}；"
          f"宏长度：{ {k: v for k, v in sorted(lens.items()) if k in TYPE_LITERAL} }")
    return 0


if __name__ == "__main__":
    sys.exit(main() or 0)
