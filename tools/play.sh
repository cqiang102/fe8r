#!/usr/bin/env bash
# 起一个**能试玩**的版本（macOS release 构建，已开调试 HUD）。
#
#     ./tools/play.sh              # 直接玩
#     FE8R_CTL=41999 ./tools/play.sh   # 同时开控制通道（AI/脚本可用 tools/verify/ctl.dart 接管）
#
# 键位（与 lib/game/fe8_game.dart 的 onKeyEvent 一一对应）：
#   方向键/WASD 移动光标 · Z/空格 确认 · X/ESC 取消 · 回车 START（地图菜单/跳过剧情）
#   E 直接结束回合（开发捷径） · C 剧情演示（开发用） · H 显示/收起按键说明
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FLUTTER="${HOME}/fvm/versions/3.47.6/bin/flutter"
BIN="$ROOT/build/macos/Build/Products/Release/fe8r.app/Contents/MacOS/fe8r"

NEEDS_BUILD=0
[ -x "$BIN" ] || NEEDS_BUILD=1
if [ "$NEEDS_BUILD" = 0 ]; then
  NEWER=$(find "$ROOT/lib" "$ROOT/assets" "$ROOT/pubspec.yaml" -newer "$BIN" 2>/dev/null | head -1)
  [ -n "$NEWER" ] && NEEDS_BUILD=1
fi
if [ "$NEEDS_BUILD" = 1 ]; then
  echo "  [play] 构建中（约 40 秒）…"
  ( cd "$ROOT" && "$FLUTTER" build macos --release >/dev/null 2>&1 ) || {
    echo "  [play] 构建失败，请直接跑 flutter run -d macos 看错误" >&2; exit 1; }
fi

echo "  [play] 键位："
echo "    方向键/WASD 移动光标    Z/空格 确认    X/ESC 取消"
echo "    回车 = START（打开地图菜单 / 跳过剧情）"
echo "    E 直接结束回合（开发捷径）   H 显示/收起按键说明"
[ -n "${FE8R_CTL:-}" ] && echo "  [play] 控制通道：FE8R_CTL=$FE8R_CTL（dart run tools/verify/ctl.dart '{\"cmd\":\"state\"}'）"
echo "  [play] 启动…（关掉窗口即退出）"
FE8R_DEBUG=1 "$BIN"
