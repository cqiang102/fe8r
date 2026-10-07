#!/usr/bin/env bash
# 跑一个**真实场景**，转储它的状态，然后用判据检查。
#
# ## 为什么需要这一步
#
# 用户说过：「开场链路、序章剧情、序章战斗都还有 bug」，而当时这三件事的
# 证据都是**一张截图** —— 截图只证明那一刻那一帧，**证明不了这条链路**。
#
# 这里把"看画面"换成一条可重复执行的链：
#
#     构建（需要时） → 跑场景（喂输入） → 写状态转储 → check_dump 判据
#
# 判据本身是可证伪的：`check_dump.dart --selftest` 会用一组**故意坏掉的**
# 转储要求每一条都红（见那个文件）。
#
# ## 用法
#
#     tools/verify/scenario.sh prologue      # 开机 → 序章开场 → 可玩地图
#     tools/verify/scenario.sh title         # 直接跳到难度画面
#
# 环境变量：`FE8R_KEEP=1` 保留中间产物路径到 stdout。
set -uo pipefail

SCENARIO="${1:?用法: scenario.sh <prologue|title>}"

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
FLUTTER="${HOME}/fvm/versions/3.47.6/bin/flutter"
DART="${HOME}/fvm/versions/3.47.6/bin/cache/dart-sdk/bin/dart"
BIN="$ROOT/build/macos/Build/Products/Release/fe8r.app/Contents/MacOS/fe8r"

OUT_DIR="${FE8R_OUT:-/tmp/fe8r}"
mkdir -p "$OUT_DIR"
DUMP="$OUT_DIR/$SCENARIO.json"
PNG="$OUT_DIR/$SCENARIO.png"

case "$SCENARIO" in
  prologue)
    # 900 个 confirm、每个间隔 60ms（`runScript` 里的固定间隔）≈ 54 秒。
    #
    # ⚠️ **不要为了"推得快"把间隔压到 0**：那样输入会在场景开始之前被丢光，
    # 画面停在"过场还没开始"，而它看起来像"过场跑完了"。
    # （`FE8R_NODELAY` 就是这么制造过一个假象、并让我把错误结论写进提交信息的。）
    TITLE=""
    SCRIPT="$(python3 -c "print(','.join(['confirm']*900))")"
    ;;
  title)
    TITLE="difficulty"
    SCRIPT=""
    ;;
  *)
    echo "未知场景 $SCENARIO" >&2
    exit 2
    ;;
esac

# 只在源码比二进制新时重建（与 shot.sh 同一套判据）
NEEDS_BUILD=0
[ -x "$BIN" ] || NEEDS_BUILD=1
if [ "$NEEDS_BUILD" = 0 ]; then
  NEWER=$(find "$ROOT/lib" "$ROOT/assets" "$ROOT/pubspec.yaml" -newer "$BIN" 2>/dev/null | head -1)
  [ -n "$NEWER" ] && NEEDS_BUILD=1
fi
if [ "$NEEDS_BUILD" = 1 ]; then
  echo "  [scenario] 重建…"
  ( cd "$ROOT" && "$FLUTTER" build macos --release >/dev/null 2>&1 ) || {
    echo "  [scenario] 构建失败" >&2; exit 1; }
fi

rm -f "$DUMP" "$PNG"
FE8R_DEBUG=1 \
FE8R_SCREENSHOT="$PNG" \
FE8R_DUMP="$DUMP" \
FE8R_TITLE="$TITLE" \
FE8R_SCRIPT="$SCRIPT" \
  "$BIN" >"$OUT_DIR/$SCENARIO.log" 2>&1

# ⚠️ **转储缺失就是失败**。
# 真实踩过：`slots` 的键写成 int，`jsonEncode` 编不了 ——
# 而且只有槽非空时才炸，于是"标题画面转储正常、一到序章整个转储静默失败"。
if [ ! -f "$DUMP" ]; then
  echo "  [scenario] ✗ 没有产出转储 $DUMP" >&2
  grep -E "dump|Exception|错误" "$OUT_DIR/$SCENARIO.log" | tail -5 >&2
  exit 1
fi

echo "  [scenario] ✓ $SCENARIO 转储 $(stat -f%z "$DUMP") 字节（截图 $(stat -f%z "$PNG" 2>/dev/null || echo '?') 字节）"
cd "$ROOT" && "$DART" run tools/verify/check_dump.dart "$DUMP" --scenario "$SCENARIO"
