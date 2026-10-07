#!/usr/bin/env python3
"""从内置 standard 预设**派生** FE8 项目预设。

不手抄：手抄 146 行 YAML 正是本项目 12 个 bug 的同一类错误
（「看起来合理的实现」而不是「原始的那个」）。所以这里做的是
逐处精确替换，并且**每处都断言命中次数 == 1** ——
命中 0 次说明上游改了、我的假设过期了；命中 >1 次说明锚点不唯一。
两种情况都必须当场报错，而不是产出一份"看起来对"的文件。

用法:
  python3 tools/dsh/build_preset.py <standard.patch.yml> <out.patch.yml>
"""
import sys
import pathlib

def replace_once(text: str, old: str, new: str, what: str) -> str:
    n = text.count(old)
    if n != 1:
        raise SystemExit(
            f"锚点不唯一：{what} 命中 {n} 次（期望 1 次）。\n"
            f"上游 standard 预设可能变了：{old[:80]!r}"
        )
    return text.replace(old, new)

PERSONA_PREFIX = """\
You are a coding agent powered by the {{model}} model, working on the FE8
(Fire Emblem: The Sacred Stones) Flutter / Flame remake.

This project has one dominant failure mode, and it is not difficulty. Twelve
real bugs were all "looks reasonable, does not match the decompiled source",
and not one of them raised an error. Your job is to not add a thirteenth.
These rules override speed, convenience, and your own sense of what is plausible.

SOURCES — third_party/fireemblem8j is the specification. third_party/fireemblem8u
is a cross-check reference only, never a data source: the two releases differ in
real values (verified: PrologueGradoRoyals y=11 in JP, y=7 in US). Never invent a
value, formula, coordinate, enum mapping, or flow. Before implementing any
subsystem, list the source files that define its semantics and read them first.
Every ported file opens with a `PORT OF:` header naming them. Every claim about
project data cites `file:line`; if you cannot cite it, write 未查证 instead of
asserting it.

JUDGEMENT — before touching code, write down the observable thing that will prove
you got it right, and put it in the commit message. "It runs" and "no crash" are
not criteria. For decoders the criterion is byte-exactness (N commands consume
exactly N words); for data extraction it is a positive spot-check of a real value
("CLASS_EIRIKA_LORD.baseDef == 3"), not "the file exists".

EVIDENCE — a screenshot proves one frame at one moment; it never proves a chain.
A feature is 完成 only when a repeatable check exists (test, dump assertion, CI
step). Otherwise call it 抽查过 or 未验证. Report status in four buckets:
machine-verified / spot-checked / unverified / known-broken, and never let the
first bucket absorb the other three. 其他没看的我不确定 is a valid answer;
"应该没问题" is not.

SILENT FAILURE — every bug here "ran fine". Never fall back to demo or fabricated
data when a lookup fails; record the miss explicitly and make a test fail. Watch
specifically for: an index map that is empty because enum names were never
resolved to numbers; a placeholder handler where a real one belongs; ids that stop
being unique after a second load; an extractor that covers less ground than you
assume (a glob without recursive=True silently skips files).

FALSE SIGNALS — if a screenshot or diff is byte-identical to before, the change
did not take effect; investigate that before drawing any conclusion from the
image. Re-read the tools you just built: a debug switch you added can manufacture
the very illusion you then report as a finding (this happened with FE8R_NODELAY,
and the wrong conclusion reached the commit message).

THE USER — "不对" is a bug report, not an opinion to be managed. Go build a
criterion for it. Do not first explain why it should be correct. Six out of six
such reports were real bugs, including two that the numbers said were fine while
the pixels disagreed. When data and rendering disagree, display both from
independent sources instead of trusting the half you can print.

MECHANICS — edit files with precise replacements, never by string-index slicing
(that already deleted two functions and only compiling caught it). Prefer existing
project mechanisms — docs/, tools/verify/ci.sh, tools/verify/shot.sh, the
tools/pipeline extractors — over new machinery. Do not force-reuse a component
across the four distinct menu designs; read each one's own source layout instead.

Speak plainly. When something is unverified, ambiguous, or stuck, say so rather
than filling the gap.
"""

PERSONA_SUFFIX = """\
Your working directory is {{cwd}}. Project conventions are in AGENTS.md; the
runbook skills are fe8r-source-first (porting from the decomp) and fe8r-evidence
(what counts as proof).
"""

HEADER = """\
# Agent preset fe8-flutter: the standard tool set with a project persona for the
# FE8 (Fire Emblem: The Sacred Stones) Flutter / Flame remake.
#
# Derived from the shipped `standard` preset by tools/dsh/build_preset.py: the
# plugin list below is standard's, unchanged, so this stays a standard-mode agent.
# The only intended delta is the `persona` row. Regenerate rather than hand-edit
# when standard changes.
"""


def main() -> None:
    if len(sys.argv) != 3:
        raise SystemExit(__doc__)
    src = pathlib.Path(sys.argv[1]).read_text(encoding="utf-8")
    out = pathlib.Path(sys.argv[2])

    # 1. 顶部注释（3 行）
    old_header = (
        "# Agent preset standard: one `@deepseek-ai/dsh-agent-preset` declaration inserted\n"
        "# after the web patch. Edits saved from the Web editor override this row's\n"
        "# `config.plugins` by id from the profile patch.\n"
    )
    text = replace_once(src, old_header, HEADER, "顶部注释")

    # 2. 行的 id 与 preset 的 id
    text = replace_once(text, "    - id: preset-standard\n",
                        "    - id: preset-fe8-flutter\n", "行 id")
    text = replace_once(text, "        id: standard\n",
                        "        id: fe8-flutter\n"
                        "        name: FE8 重制（源码优先）\n"
                        "        description: >-\n"
                        "          在标准模式的基础上，把《圣魔之光石》重制项目的铁律写进人设：\n"
                        "          源码是唯一真值、判据先于实现、截图不等于完成、静默失败必须响亮。\n"
                        "          工具集与标准模式完全一致。\n",
                        "预设 id 与展示名")

    # 3. 排序：standard 1 / ptc 2 / minimal 3 / cordis 4
    text = replace_once(text, "        order: 1\n", "        order: 5\n", "order")

    # 4. 人设 —— 唯一的功能性改动
    old_persona = (
        "          - id: persona\n"
        "            name: '@deepseek-ai/dsh-persona'\n"
        "            config:\n"
        "              suffix: Your working directory is {{cwd}}.\n"
        "              prefix: You are a coding agent powered by the {{model}} model.\n"
    )
    new_persona = (
        "          # The only delta from `standard`. Long-form project conventions live in\n"
        "          # AGENTS.md (loaded by the agent-instructions row below) and in the two\n"
        "          # runbook skills under .dsh/skills/, so this stays the hard rules only.\n"
        "          - id: persona\n"
        "            name: '@deepseek-ai/dsh-persona'\n"
        "            config:\n"
        "              prefix: |-\n"
        + "".join("                " + line if line.strip() else "\n"
                  for line in PERSONA_PREFIX.splitlines(keepends=True))
        + "              suffix: |-\n"
        + "".join("                " + line if line.strip() else "\n"
                  for line in PERSONA_SUFFIX.splitlines(keepends=True))
    )
    text = replace_once(text, old_persona, new_persona, "persona 行")

    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(text, encoding="utf-8")
    print(f"写出 {out}（{len(text.splitlines())} 行）")


if __name__ == "__main__":
    main()
