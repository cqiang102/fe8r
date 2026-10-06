#!/bin/bash
#
# ci.sh —— CI 入口。
#
# **本地和 GitHub Actions 跑的是同一个脚本。** CI 的 YAML 只负责装环境
# （Flutter / Python / clang），具体检查什么全在 tools/verify/run_all.dart 里定义。
#
# ⚠️ **这个脚本就是真正的闸门** —— CI 只是兜底。
#
# CI 已经**不在 push 上跑**了（只在 PR / 手动 / 每周定时）。
# 理由：本脚本与 CI 跑的是同一条路径、同一个平台，
# 而每次推送前本地都会跑一遍（约 40 秒）——
# push 时再跑一遍 CI 是纯重复，只换来 2~4 分钟的等待，信息量为零。
#
# 所以流程是：**改完 → 跑本脚本 → 绿了就推**，不用等 CI。
#
# ⚠️ **CI 全部跑在 macos-latest**（曾经跑 ubuntu 以省时间，现已改回）。
#
# 复盘：Linux 与 macOS 的差异在这个项目里**只制造假问题、没抓到过真问题**。
#   * `gPlaySt` 重复定义 —— 只在 C Oracle 测试脚手架里，不影响产品
#   * 数据提取产物平台不一致 —— 只在构建期数据管线里
# 四次排查全部花在"验证工具自己"身上，而 macOS 构建 job 一直全绿。
#
# 所以本地跑 `./tools/verify/ci.sh` 与 CI 跑的是**同一个平台**，
# "本地绿、CI 红"从根上不可能发生了。
#
# 另外 build.sh 仍然带 -fno-common：那是个好的防御（重复定义本来就该报错），
# 只是不再需要它去弥合平台差异。
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
