#!/usr/bin/env bash
# 截图（**不走 `flutter run`**）。
#
# ## 为什么不用 `flutter run`
#
# `flutter run` 是交互式前台进程：应用退出后它会打印
# `Application finished.` 然后**停在交互模式等 `q`**，自己不退出。
#
# 后果（实测）：`timeout 300 flutter run ...` 每条命令都要
# **跑满 5 分钟**才被杀掉 —— 而命令最终"成功"，所以从没被怀疑。
# 约 20 次截图 = 纯等待约 100 分钟。
#
# ## 这个脚本怎么做
#
#   1. `flutter build macos --release`（只在需要时重建）
#   2. 直接跑构建出来的二进制，带上环境变量
#   3. 应用自己 `exit(0)`（见 `lib/ui/debug_screenshot.dart`），脚本立刻返回
#
# 用法：
#   tools/verify/shot.sh <输出 png> [标题画面] [输入脚本]
set -uo pipefail

OUT="${1:?用法: shot.sh <out.png> [title_screen] [script]}"
TITLE="${2:-}"
SCRIPT="${3:-}"

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
FLUTTER="${HOME}/fvm/versions/3.47.6/bin/flutter"
BIN="$ROOT/build/macos/Build/Products/Release/fe8r.app/Contents/MacOS/fe8r"

# 只在源码比二进制新时重建
NEEDS_BUILD=0
[ -x "$BIN" ] || NEEDS_BUILD=1
if [ "$NEEDS_BUILD" = 0 ]; then
  # 找比二进制新的源文件（排除 build/ 与 third_party/）
  # ⚠️ **必须也看 assets/** —— 只盯 lib/ 的话，换了素材不会重新打包，
  # 于是改了没生效（我踩过一次，截出来字节完全相同）。
  NEWER=$(find "$ROOT/lib" "$ROOT/assets" "$ROOT/pubspec.yaml" -newer "$BIN" 2>/dev/null | head -1)
  [ -n "$NEWER" ] && NEEDS_BUILD=1
fi
if [ "$NEEDS_BUILD" = 1 ]; then
  echo "  [shot] 重建…"
  ( cd "$ROOT" && "$FLUTTER" build macos --release >/dev/null 2>&1 ) || {
    echo "  [shot] 构建失败" >&2; exit 1; }
fi

rm -f "$OUT"
FE8R_SCREENSHOT="$OUT" \
FE8R_TITLE="$TITLE" \
FE8R_SCRIPT="$SCRIPT" \
  "$BIN" 2>&1 | grep -E "screenshot|title\]" || true

if [ -f "$OUT" ]; then
  echo "  [shot] ✓ $OUT ($(stat -f%z "$OUT") 字节)"
else
  echo "  [shot] ✗ 没有产出 $OUT" >&2
  exit 1
fi
