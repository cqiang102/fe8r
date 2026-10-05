#!/bin/bash
#
# ci-linux.sh —— 在**本地 Linux 容器**里跑一遍 CI 的 C Oracle 部分。
#
# ## 为什么需要这个脚本
#
# `ci.sh` 的注释里写着"本地绿了 CI 却红基本不会发生"—— 这句话在
# M5 被打破了：`turn_switch` 场景里 `gPlaySt` 被定义两次，
# macOS 的 ld64 把两个 tentative definition 合并了，Linux 的 ld 直接报
# `multiple definition`。本机全绿，CI 两个 job 全红。
#
# 当时的排查很痛苦，因为：
#   * GitHub 的 job 日志需要登录才能看（API 未认证还会限流）
#   * 报错在**链接阶段**，和源码位置对不上
#   * macOS 上根本复现不出来
#
# 所以固化这个脚本：把"Linux 上的差异"变成一个本地就能跑的命令。
#
# ## 用法
#
#   ./tools/verify/ci-linux.sh            # 只跑 C Oracle（快，约 1 分钟）
#   ./tools/verify/ci-linux.sh --full     # 连 Python 数据管线一起跑
#
# 前置条件：Docker 可用，且 third_party/fireemblem8j 已就位。
#
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"

MODE="${1:-}"
# 与 GitHub Actions 的 ubuntu-latest 对齐（Ubuntu 24.04 + clang 18）
IMAGE="${FE8R_LINUX_IMAGE:-ubuntu:24.04}"

if [ ! -d "$ROOT/third_party/fireemblem8j/src" ]; then
    echo "错误：third_party/fireemblem8j 不在。先跑 ./tools/verify/ci.sh" >&2
    exit 1
fi

if ! command -v docker >/dev/null 2>&1; then
    echo "错误：找不到 docker。" >&2
    echo "  这个脚本的**全部价值**就是在 Linux 上跑，没有容器就没有意义。" >&2
    echo "  不提供'退化成 macOS 本地跑'的降级路径 —— 那正是要避免的自欺。" >&2
    exit 1
fi

echo "================================================================"
echo " 在 Linux 容器里复现 CI"
echo "   镜像: $IMAGE"
echo "   模式: ${MODE:---oracle-only}"
echo "================================================================"

# 反编译源码通过宿主目录挂进来（容器里不重新 clone，省 150MB 和几分钟）
exec docker run --rm \
    -v "$ROOT":/w \
    -w /w \
    "$IMAGE" bash -lc '
set -e
apt-get update -qq >/dev/null 2>&1
apt-get install -y -qq clang make python3 >/dev/null 2>&1
echo "clang: $(clang --version | head -1)"
echo "python: $(python3 --version)"
echo

if [ "'"$MODE"'" = "--full" ]; then
    echo "── Python 数据管线 ──"
    cd /w/tools/pipeline
    python3 extract/parse_c_tables.py --out out/tables >/dev/null
    python3 extract/parse_carved_tables.py --out out/tables >/dev/null
    python3 extract/parse_class_tables.py --out out/tables >/dev/null
    python3 extract/parse_eventscript.py --out out/tables >/dev/null
    python3 extract/verify_eventscript.py | tail -2
    python3 extract/verify_tables.py | tail -3
    echo
fi

echo "── C Oracle（构建全部场景 + 交叉校验）──"
cd /w/tools/oracle
./verify.sh
'
