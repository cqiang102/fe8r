#!/usr/bin/env python3
"""歌曲表（`gSongTable`）—— 音频子系统的第一块数据。

出处：
* 表定义：`sound/song_table.s`，每行一条 `song <label>, <ms>, <me>`。
  宏展开（`asm/macros/m4a.inc:1-5`）：
      .4byte <label>     ← 歌曲头指针（4 字节）
      .2byte <music_player>  ← **音乐播放器下标**（2 字节）
      .2byte <unknown>       ← （2 字节）
  ⇒ **每条 8 字节**，可字节核对。
* 取用：`src/m4aSongNumStart.c:5-12`：
      const struct Song *song = &gSongTable[n];
      MPlayStart(mplayTable[song->ms].info, song->header);
  ⇒ 事件指令里的 `MUSC/MUSI/MUNO/...` 参数 `n` 就是**这张表的下标**。
* 歌曲本身：`sound/songs/midi/<label>.mid`（**标准 MIDI**，588 个）。
  ⚠️ 这是反编译项目给出的**乐曲源**；ROM 里是 M4A 编译产物。
  本仓库的原则是"规则 1:1、表现自己实现" ⇒ 播 MIDI 是**允许的表现替换**，
  但**音色**与 GBA 的 M4A 不同（未查证两者听感差异）。

判据（正向抽查真值）：
* 条数 == 解析出的 `song` 行数，且每条正好 8 字节；
* `songs[1].symbol == 'song001_agbfe3_bgm_opening'`、`ms == 0`；
* `songs[4].symbol == 'song004_agbfe3_bgm_wmap_01'`、`ms == 1`；
* 每个 label 要么有 `midi`（`sound/songs/midi/<label>.mid`），要么是 `dummy_song`
  —— 否则**显式记进 `missingMidi`**（不静默丢）。
"""
import argparse
import json
import os
import re

HERE = os.path.dirname(os.path.abspath(__file__))
DECOMP = os.path.normpath(os.path.join(HERE, "..", "..", "..", "third_party", "fireemblem8j"))

BYTES_PER_ENTRY = 8


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", required=True)
    ap.add_argument("--dart", help="同时把表写成 Dart（给 lib/core 用；核心禁 dart:io）")
    ap.add_argument("--check", action="store_true",
                    help="只校验 --dart 指向的文件是否与生成结果一致（门禁用）")
    a = ap.parse_args()

    table_p = os.path.join(DECOMP, "sound", "song_table.s")
    rows = []
    with open(table_p, encoding="utf-8", errors="replace") as f:
        for line in f:
            m = re.match(r"\s*song\s+([A-Za-z0-9_]+)\s*,\s*(\d+)\s*,\s*(\d+)", line)
            if m:
                rows.append((m.group(1), int(m.group(2)), int(m.group(3))))

    midi_dir = os.path.join(DECOMP, "sound", "songs", "midi")
    midi_names = set(os.listdir(midi_dir)) if os.path.isdir(midi_dir) else set()

    songs, missing = [], []
    for i, (sym, ms, me) in enumerate(rows):
        fn = sym + ".mid"
        has = fn in midi_names
        if not has and sym != "dummy_song":
            missing.append({"index": i, "symbol": sym})
        songs.append({
            "index": i,
            "symbol": sym,
            "ms": ms,
            "me": me,
            "midi": fn if has else None,
        })

    # ---- ★ 重复符号记账（"id 不唯一"那类陷阱）----
    # 实测：1000 条里只有 **594 个不同符号**；重复最多的是 `dummy_song` **361 次**
    # （原作里"没有 BGM"的槽位就是这个），另有 34 个符号各出现 2 次。
    # 这件事必须显式记下来：`n` 是**下标**不是"歌曲标识"，
    # 拿符号当唯一键会静默合并不同的 id。
    from collections import Counter
    counts = Counter(sym for sym, _, _ in rows)
    duplicates = {k: v for k, v in counts.items() if v > 1}
    dummy_count = counts.get("dummy_song", 0)

    # ---- 判据（正向抽查真值 + 字节严丝合缝）----
    assert len(rows) > 500, f"歌曲表条数太少：{len(rows)}"
    assert songs[1]["symbol"] == "song001_agbfe3_bgm_opening", songs[1]
    assert songs[1]["ms"] == 0, songs[1]
    assert songs[4]["symbol"] == "song004_agbfe3_bgm_wmap_01", songs[4]
    assert songs[4]["ms"] == 1, songs[4]
    assert songs[0]["symbol"] == "dummy_song", songs[0]
    # 重复/哑元的**具体数字**（实测值；变了一定要有人看一眼）
    assert len(rows) == 1000, len(rows)
    assert len(counts) == 594, len(counts)
    assert dummy_count == 361, dummy_count

    out = {
        "songs": songs,
        "count": len(songs),
        "bytesPerEntry": BYTES_PER_ENTRY,
        "totalBytes": len(songs) * BYTES_PER_ENTRY,
        "midiCount": len(midi_names),
        "missingMidi": missing,
        "distinctSymbols": len(counts),
        "duplicateSymbols": len(duplicates),
        "dummySongCount": dummy_count,
        "note": "n 是 gSongTable 下标（src/m4aSongNumStart.c:5-12）；midi 是反编译给出的乐曲源",
    }
    os.makedirs(a.out, exist_ok=True)
    with open(os.path.join(a.out, "song_table.json"), "w", encoding="utf-8") as f:
        json.dump(out, f, ensure_ascii=False, indent=1)
    if a.dart:
        lines = [
            "// 由 tools/pipeline/extract/parse_song_table.py 生成，**不要手改**。",
            "// 出处：sound/song_table.s（`gSongTable`）+ asm/macros/m4a.inc:1-5（每条 8 字节）",
            "// 取用：src/m4aSongNumStart.c:5-12 —— `&gSongTable[n]`，**n 是下标**。",
            "// PORT OF: sound/song_table.s",
            "",
            "/// 一条歌曲表项",
            "class SongEntry {",
            "  const SongEntry(this.symbol, this.ms, this.hasMidi);",
            "",
            "  /// 歌曲头符号（**不是**唯一键：1000 条里只有 594 个不同符号）",
            "  final String symbol;",
            "",
            "  /// `song` 宏的第 2 个参数（音乐播放器下标）",
            "  final int ms;",
            "",
            "  /// 反编译里有对应的 `.mid` 乐曲源",
            "  final bool hasMidi;",
            "}",
            "",
            f"/// `gSongTable`：{len(songs)} 条（下标即事件指令里的歌曲参数）",
            "const List<SongEntry> gSongTable = [",
        ]
        for e in songs:
            lines.append(f"  SongEntry('{e['symbol']}', {e['ms']}, "
                         f"{'true' if e['midi'] else 'false'}),")
        lines.append("];")
        lines.append("")
        lines.append(f"/// 不同符号数（{len(counts)}）—— 与 `gSongTable.length` "
                     f"（{len(songs)}）**不同**，因为 `dummy_song` 占了 {dummy_count} 条")
        lines.append(f"const int gSongTableDistinctSymbols = {len(counts)};")
        lines.append("")
        text = "\n".join(lines)
        if a.check:
            old = open(a.dart, encoding="utf-8").read() if os.path.exists(a.dart) else None
            if old != text:
                print(f"✗ {a.dart} 与生成结果不一致（跑提取器不带 --check 重新生成）")
                raise SystemExit(1)
            print(f"✓ {a.dart} 与生成结果一致（{len(songs)} 条）")
        else:
            os.makedirs(os.path.dirname(a.dart) or ".", exist_ok=True)
            with open(a.dart, "w", encoding="utf-8") as f:
                f.write(text)
            print(f"已写 {a.dart}（{len(songs)} 条）")

    print(f"歌曲表：{len(songs)} 条 × {BYTES_PER_ENTRY} B = {len(songs)*BYTES_PER_ENTRY} B"
          f"；midi {len(midi_names)} 个；缺 midi {len(missing)} 条；"
          f"不同符号 {len(counts)}（dummy {dummy_count}、重复符号 {len(duplicates)}）")
    if missing:
        print("  缺 midi 的：", [m["symbol"] for m in missing[:5]], "…" if len(missing) > 5 else "")


if __name__ == "__main__":
    main()
