#!/bin/bash
#
# verify.sh —— C Oracle 的总入口。这一条命令必须永远绿灯。
#
# 用法:
#   ./verify.sh              常规校验（快，约 5 秒）
#   ./verify.sh --coverage   额外跑全量编译覆盖率（慢，约 80 秒）
#
# 校验内容:
#   1. 全部场景能构建（会真的编译反编译 C 代码）
#   2. Oracle 输出与提交的 golden 逐条一致
#   3. 与独立 Python 实现交叉一致（验证 harness 管道本身没问题）
#
set -uo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
COVERAGE=0
[ "${1:-}" = "--coverage" ] && COVERAGE=1

fail=0

echo "=============================================="
echo " C Oracle 验证"
echo "=============================================="

echo
echo "── [1/3] golden 对照 ──"
"$HERE/run_all.sh" --check || fail=1

echo
echo "── [2/3] 独立 Python 交叉校验 ──"
python3 "$HERE/crosscheck.py" || fail=1

if [ "$COVERAGE" = "1" ]; then
    echo
    echo "── [3/3] 全量编译覆盖率（慢）──"
    "$HERE/compile_coverage.sh" | tail -20
else
    echo
    echo "── [3/3] 全量编译覆盖率 ── 跳过（加 --coverage 启用）"
fi

echo
echo "=============================================="
if [ $fail -eq 0 ]; then
    echo " C ORACLE: ALL GREEN"
else
    echo " C ORACLE: FAILED"
fi
echo "=============================================="
exit $fail
