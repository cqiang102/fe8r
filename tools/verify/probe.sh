#!/usr/bin/env bash
# 开发用探针：跑一段输入脚本，打印**紧凑状态摘要**（不是截图）。
#
# ## 用途
#
# 拼"从开机一路打到某处"的输入脚本时，需要反复看"现在到了哪一步"：
# 回合 / 阶段 / 光标 / 单位坐标与 HP / 地图历史 / 最近几条指令。
# 截图看这些太慢（还要人眼读），转储又要自己 json 解析。
#
# ⚠️ 这是**开发工具**，不是门禁。判据在 `check_dump.dart` 里。
#
# 用法：
#   tools/verify/probe.sh "<脚本>" [输出名]
set -uo pipefail

SCRIPT="${1:?用法: probe.sh \"<脚本>\" [名字]}"
NAME="${2:-probe}"

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
FLUTTER="${HOME}/fvm/versions/3.47.6/bin/flutter"
BIN="$ROOT/build/macos/Build/Products/Release/fe8r.app/Contents/MacOS/fe8r"
OUT="$ROOT/tools/pipeline/out"
mkdir -p "$OUT"

NEEDS_BUILD=0
[ -x "$BIN" ] || NEEDS_BUILD=1
if [ "$NEEDS_BUILD" = 0 ]; then
  NEWER=$(find "$ROOT/lib" "$ROOT/assets" "$ROOT/pubspec.yaml" -newer "$BIN" 2>/dev/null | head -1)
  [ -n "$NEWER" ] && NEEDS_BUILD=1
fi
if [ "$NEEDS_BUILD" = 1 ]; then
  echo "  [probe] 重建…" >&2
  ( cd "$ROOT" && "$FLUTTER" build macos --release >/dev/null 2>&1 ) || {
    echo "  [probe] 构建失败" >&2; exit 1; }
fi

DUMP="$OUT/probe_$NAME.json"
rm -f "$DUMP" "$OUT/probe_$NAME.png"
FE8R_DEBUG=1 \
FE8R_SCREENSHOT="$OUT/probe_$NAME.png" \
FE8R_DUMP="$DUMP" \
FE8R_SCRIPT="$SCRIPT" \
  "$BIN" >"$OUT/probe_$NAME.log" 2>&1

python3 - "$DUMP" <<'PY'
import json, sys, os
p = sys.argv[1]
if not os.path.exists(p):
    print('✗ 没有转储 —— 看日志：', p.replace('.json', '.log'))
    sys.exit(1)
d = json.load(open(p))
print(f"地图 {d['map']['id'] if d['map'] else '?'}  历史 {d['mapHistory']!r}  章节 {d['chapter']}")
print(f"回合 {d['turn']}  {d['phase']}  光标 ({d['cursor']['x']},{d['cursor']['y']})  "
      f"选中 {d['selectedUnitId']}  乱数? 相机 ({d['camera']['x']:.0f},{d['camera']['y']:.0f})")
print(f"LOMA 失败 {d['mapLoadFailures']}  objectiveHit={d['objectiveHit']}")
print('单位：')
for u in d['units']:
    print(f"   id={u['id']:3d} {u['name']:12s} char={u['charIndex']:3d} cls={u['classId']:3d} "
          f"({u['x']:2d},{u['y']:2d}) HP {u['hp']}/{u['maxHp']} {'★死' if not u['alive'] else ''}")
print('轨迹：', ' | '.join(d['trace'][-4:]))
print('HUD ：', d['hud'].replace('\n', ' | ')[:200])
print('战报：', d['lastCombat'].replace('\n', ' | ')[:200])
PY
