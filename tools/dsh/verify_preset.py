#!/usr/bin/env python3
"""FE8 项目预设的判据。

`tools/dsh/fe8-flutter-preset/cordis.patch.yml` 声明的工具集**必须与内置
`standard` 预设逐字节一致**，唯一允许的差异是人设（persona）与元数据。
这句话如果只是写在描述里，它就会烂掉 —— 所以它是这里的三条判据：

  A. 工具集未变   —— 两个文件从 `- id: agent-instructions` 到文件末尾**逐字节相同**。
                     这一段覆盖了整个工具/技能/委派列表；改任何一行都会红。
  B. 派生可复现   —— 用 `build_preset.py` 重新生成，必须与提交的文件**逐字节相同**。
                     手改生成物会红。
  C. 基线未过期   —— 快照 `standard.patch.yml` 必须与 DSH 实际出货的那份相同。
                     DSH 升级后会红（否则新工具会**静默**地不进本预设）。

为什么不用 PyYAML：CI 上没有保证。判据用逐字节比较反而更强 ——
它不关心"语义相同"，只认"就是那一份"。

用法:
  python3 tools/dsh/verify_preset.py                 判据（基线不在时降级并明确说明）
  python3 tools/dsh/verify_preset.py --refresh       从 DSH 重新抓取基线快照
"""
from __future__ import annotations

import json
import os
import pathlib
import struct
import subprocess
import sys
import tempfile
from typing import Callable

HERE = pathlib.Path(__file__).resolve().parent
ROOT = HERE.parent.parent
SNAPSHOT = HERE / "standard.patch.yml"
PRESET = HERE / "fe8-flutter-preset" / "cordis.patch.yml"
GENERATOR = HERE / "build_preset.py"

# 内置 standard 预设里"工具集从此开始"的那一行。
# 它之前的行（preset id、元数据、persona）是允许不同的部分。
TOOLSET_ANCHOR = "          - id: agent-instructions\n"

APP_ASAR = pathlib.Path(
    os.environ.get(
        "DSH_ASAR",
        "/Applications/DeepSeek Harness.app/Contents/Resources/app.asar",
    )
)
STANDARD_IN_ASAR = (
    "dsh/node_modules/@deepseek-ai/dsh-web-app/presets/standard.patch.yml"
)


# --------------------------------------------------------------- asar 读取
#
# app.asar 的头部：3 个 uint32 前缀 + JSON 头，文件数据紧随其后（按 4 字节对齐）。
# header JSON 里的 offset/size 是**字符串**（避免大文件精度丢失），必须转 int。
def read_from_asar(asar: pathlib.Path, member: str) -> str | None:
    with asar.open("rb") as fh:
        head = fh.read(16)
        if len(head) < 16:
            return None
        str_len = struct.unpack_from("<I", head, 12)[0]
        header = json.loads(fh.read(str_len).decode("utf-8"))
        base = 16 + str_len
        if base % 4:
            base += 4 - base % 4

        node = header
        for part in member.split("/"):
            node = (node.get("files") or {}).get(part)
            if node is None:
                return None
        fh.seek(base + int(node["offset"]))
        return fh.read(int(node["size"])).decode("utf-8")


def shipped_standard() -> tuple[str | None, str]:
    """返回 (内容, 说明)。内容为 None 表示拿不到。"""
    if not APP_ASAR.exists():
        return None, f"找不到 DSH 应用包：{APP_ASAR}"
    try:
        text = read_from_asar(APP_ASAR, STANDARD_IN_ASAR)
    except Exception as exc:  # noqa: BLE001 —— 读不到就当拿不到，并说明原因
        return None, f"读取 app.asar 失败：{exc}"
    if text is None:
        return None, f"app.asar 里没有 {STANDARD_IN_ASAR}"
    return text, f"{APP_ASAR}!{STANDARD_IN_ASAR}"


# --------------------------------------------------------------- 判据
def split_at_anchor(text: str, origin: str) -> tuple[str, str]:
    """切成 (工具集之前, 工具集及之后)。锚点必须恰好命中一次。"""
    n = text.count(TOOLSET_ANCHOR)
    if n != 1:
        raise SystemExit(
            f"✗ {origin} 里锚点 {TOOLSET_ANCHOR.strip()!r} 命中 {n} 次（期望 1 次）。\n"
            "  DSH 的 standard 预设结构变了，基线需要重新确认。"
        )
    i = text.index(TOOLSET_ANCHOR)
    return text[:i], text[i:]


def check_toolset(standard_text: str, preset_text: str) -> list[str]:
    """判据 A：工具集段逐字节相同。"""
    _, std_tools = split_at_anchor(standard_text, "standard")
    _, my_tools = split_at_anchor(preset_text, "fe8-flutter")
    if std_tools == my_tools:
        rows = sum(1 for ln in my_tools.splitlines() if ln.strip().startswith("- id:"))
        return [f"✓ 工具集与 standard 逐字节一致（{len(my_tools)} 字节，{rows} 个条目）"]
    std_lines = std_tools.splitlines()
    my_lines = my_tools.splitlines()
    diffs = [
        f"      standard: {a!r}\n      fe8-flutter: {b!r}"
        for a, b in zip(std_lines, my_lines)
        if a != b
    ][:8]
    raise SystemExit(
        "✗ 工具集与 standard 不再一致 —— 本预设的承诺（工具集完全一致）被破坏了。\n"
        + "\n".join(diffs)
        + (f"\n  （共 {len(std_lines)} vs {len(my_lines)} 行）" if len(std_lines) != len(my_lines) else "")
    )


def check_reproducible() -> list[str]:
    """判据 B：重新生成必须逐字节相同。"""
    if not SNAPSHOT.exists():
        raise SystemExit(f"✗ 缺基线快照 {SNAPSHOT}")
    with tempfile.TemporaryDirectory() as tmp:
        out = pathlib.Path(tmp) / "regenerated.patch.yml"
        proc = subprocess.run(
            [sys.executable, str(GENERATOR), str(SNAPSHOT), str(out)],
            capture_output=True,
            text=True,
        )
        if proc.returncode != 0:
            raise SystemExit(f"✗ 生成失败：\n{proc.stdout}{proc.stderr}")
        regenerated = out.read_text(encoding="utf-8")
    committed = PRESET.read_text(encoding="utf-8")
    if regenerated != committed:
        raise SystemExit(
            "✗ 提交的 cordis.patch.yml 与重新生成的结果不同 —— 说明它被手改过。\n"
            "  改人设/元数据请改 build_preset.py，然后重跑它，不要直接编辑生成物。"
        )
    return [f"✓ 派生可复现（{len(committed)} 字节，{len(committed.splitlines())} 行）"]


def check_baseline_fresh() -> list[str]:
    """判据 C：快照与 DSH 实际出货的 standard 相同。拿不到就明确降级。"""
    if not SNAPSHOT.exists():
        raise SystemExit(f"✗ 缺基线快照 {SNAPSHOT}（先跑 --refresh）")
    snapshot = SNAPSHOT.read_text(encoding="utf-8")
    shipped, origin = shipped_standard()
    if shipped is None:
        # 不是静默通过：说清楚"这一条没验"，并给出补救方式
        return [
            f"⚠ 未能核对基线新鲜度：{origin}",
            "    判据 A/B 仍成立，但 DSH 若升级、standard 新增工具，本预设会静默少工具。",
            "    补救：在有 DSH 应用的机器上跑 python3 tools/dsh/verify_preset.py --refresh",
        ]
    if shipped != snapshot:
        raise SystemExit(
            "✗ 基线快照过期：DSH 出货的 standard 预设与 tools/dsh/standard.patch.yml 不同。\n"
            f"  来源：{origin}\n"
            "  后果：standard 新增/改动的工具**不会**进入本预设，而且是静默的。\n"
            "  处理：审阅差异后跑 python3 tools/dsh/verify_preset.py --refresh，再重跑 "
            "build_preset.py。"
        )
    return [f"✓ 基线快照与 DSH 出货一致（{origin}）"]


def check_metadata(preset_text: str) -> list[str]:
    """判据 D：元数据与人设存在且非空（廉价的存在性判据）。"""
    need = [
        "    - id: preset-fe8-flutter\n",
        "        id: fe8-flutter\n",
        "        name: FE8 重制（源码优先）\n",
        "        order: 5\n",
    ]
    for s in need:
        if s not in preset_text:
            raise SystemExit(f"✗ 预设缺少必需行：{s.strip()!r}")
    # 人设必须真的写了东西 —— 空的人设行会让这个预设退化成"标准模式改名"
    for token in ("{{model}}", "{{cwd}}", "third_party/fireemblem8j", "PORT OF:"):
        if token not in preset_text:
            raise SystemExit(f"✗ 人设里缺少 {token!r} —— 它不该只是一个改名的 standard")
    return ["✓ 元数据与人设齐备（id / name / order / 人设变量与铁律关键词）"]


def refresh() -> None:
    shipped, origin = shipped_standard()
    if shipped is None:
        raise SystemExit(f"✗ 拿不到出货的 standard 预设：{origin}")
    SNAPSHOT.write_text(shipped, encoding="utf-8")
    print(f"已刷新基线：{SNAPSHOT}\n  来源：{origin}\n  {len(shipped)} 字节")


def main() -> None:
    if "--refresh" in sys.argv:
        refresh()
        return
    if not PRESET.exists():
        raise SystemExit(f"✗ 缺预设文件 {PRESET}（先跑 build_preset.py）")

    preset_text = PRESET.read_text(encoding="utf-8")

    # ⚠️ 必须**按顺序惰性求值**：写成列表字面量会先跑完 B/C 才轮到 A，
    # 于是 A 先不先失败都看不出来 —— 那是"看起来在验、其实没验"。
    # 实测：证伪"偷改一行工具配置"时，A 根本没被执行到。
    checks: list[tuple[str, Callable[[], list[str]]]] = [
        ("判据 A · 工具集未变", lambda: check_toolset(
            SNAPSHOT.read_text(encoding="utf-8"), preset_text)),
        ("判据 B · 派生可复现", check_reproducible),
        ("判据 C · 基线未过期", check_baseline_fresh),
        ("判据 D · 元数据与人设", lambda: check_metadata(preset_text)),
    ]

    print("预设判据 ——", PRESET.relative_to(ROOT))
    for label, run in checks:
        print(f"  [{label}]")
        for line in run():
            print("    " + line)
    print("\n预设判据：全部通过")


if __name__ == "__main__":
    main()
