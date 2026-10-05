#!/bin/bash
#
# ci.sh —— CI 入口。
#
# **本地和 GitHub Actions 跑的是同一个脚本。** CI 的 YAML 只负责装环境
# （Flutter / Python / clang），具体检查什么全在 tools/verify/run_all.dart 里定义。
#
# ⚠️ 但"脚本相同"**不等于**"环境相同"。M5 就踩过一次：
# `turn_switch` 场景里 gPlaySt 被定义两次，macOS 的 ld64 把两个 tentative
# definition 合并了，Linux 的 ld 直接报 multiple definition —— 本机全绿，
# CI 两个 job 全红，而且报错在链接阶段、和源码位置对不上。
#
# 教训：**平台差异要在构建参数上消除，而不是靠"本地跑过"来推断。**
# 现在 build.sh 显式带 -fno-common，两边行为一致。
#
# 想在本地直接验 Linux，用 tools/verify/ci-linux.sh（Docker）。
#
# 用法:
#   ./tools/verify/ci.sh              常规
#   ./tools/verify/ci.sh --coverage   额外跑 C Oracle 全量编译覆盖率（慢，约 80s）
#
# 前置条件（CI 里由 workflow 准备好）:
#   * flutter / dart  —— 版本见 .fvmrc
#   * python3 + Pillow
#   * clang（C Oracle 用来编译反编译源码；GNU89 inline 语义需要 clang 或 gcc）
#
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"
cd "$ROOT"

COVERAGE=""
[ "${1:-}" = "--coverage" ] && COVERAGE="--coverage"

DECOMP="third_party/fireemblem8j"
DECOMP_URL="https://github.com/laqieer/fireemblem8j"

echo "================================================================"
echo " FE8 重制版 —— CI"
echo "================================================================"

# ---------------------------------------------------------------- 1. 反编译源码
#
# 数据管线与 C Oracle 都依赖它。不把它塞进仓库：151MB，且是可复现的外部依赖。
if [ ! -d "$DECOMP/graphics/map" ]; then
    echo
    echo "── [1/4] 拉取反编译源码 ──"
    echo "    $DECOMP 缺失，从 $DECOMP_URL clone（--depth 1，约 150MB）"
    mkdir -p third_party
    git clone --depth 1 "$DECOMP_URL" "$DECOMP"
else
    echo
    echo "── [1/4] 反编译源码已就位 ── $DECOMP"
fi

# ---------------------------------------------------------------- 2. Python 依赖
echo
echo "── [2/4] Python 依赖 ──"
if python3 -c "import PIL" 2>/dev/null; then
    echo "    Pillow 已安装：$(python3 -c 'import PIL; print(PIL.__version__)')"
else
    echo "    安装 Pillow…"
    python3 -m pip install --quiet --disable-pip-version-check Pillow
    echo "    完成：$(python3 -c 'import PIL; print(PIL.__version__)')"
fi

# ---------------------------------------------------------------- 3. 定位工具链
#
# 不假设 PATH 上的 dart 版本是对的。实测踩过：PATH 上是 3.9.2，
# 而项目要求 3.13，报出来的错是"语言版本要求过高"，很不容易一眼看懂。
echo
echo "── [3/4] 工具链 ──"
FLUTTER_VER="$(sed -n 's/.*"flutter"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' .fvmrc)"
DART_BIN="dart"
FLUTTER_BIN="flutter"
if [ -n "$FLUTTER_VER" ] && [ -x "$HOME/fvm/versions/$FLUTTER_VER/bin/cache/dart-sdk/bin/dart" ]; then
    DART_BIN="$HOME/fvm/versions/$FLUTTER_VER/bin/cache/dart-sdk/bin/dart"
    FLUTTER_BIN="$HOME/fvm/versions/$FLUTTER_VER/bin/flutter"
fi
echo "    .fvmrc 要求 Flutter ${FLUTTER_VER:-?}"
echo "    dart    -> $DART_BIN  ($("$DART_BIN" --version 2>&1 | head -1))"

# clang 只被 C Oracle 用来编译反编译 C，缺了会明确失败而不是静默跳过
if command -v clang >/dev/null 2>&1; then
    echo "    clang   -> $(clang --version | head -1)"
else
    echo "    ⚠️  找不到 clang，C Oracle 会失败" >&2
fi

# ---------------------------------------------------------------- 4. 依赖 + 验证
echo
echo "── [4/4] 拉依赖并跑验证 ──"
"$FLUTTER_BIN" pub get

echo
"$DART_BIN" run tools/verify/run_all.dart $COVERAGE
