#!/bin/bash
#
# run_all.sh —— 构建全部场景，跑向量，产出/校验 golden 期望值。
#
# 用法:
#   ./run_all.sh            生成/更新 vectors/*.expected.tsv（golden）
#   ./run_all.sh --check    与已提交的 golden 比对（CI 用，不写入）
#
# 流程:
#   vectors/<name>.cases.tsv  ──[out/<name>]──▶  vectors/<name>.expected.tsv
#
set -uo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
VEC="$HERE/vectors"
CHECK=0
[ "${1:-}" = "--check" ] && CHECK=1

echo "== 1/3 构建场景 =="
"$HERE/build.sh" --all || exit 1

echo
echo "== 2/3 生成向量（若缺失）=="
if ! ls "$VEC"/*.cases.tsv >/dev/null 2>&1; then
    python3 "$HERE/gen_vectors.py" || exit 1
else
    echo "  已存在，跳过（要重生成请先删除 vectors/*.cases.tsv）"
fi

echo
echo "== 3/3 运行 Oracle =="
rc=0
total=0
for cases in "$VEC"/*.cases.tsv; do
    name="$(basename "$cases" .cases.tsv)"
    bin="$HERE/out/$name"
    expected="$VEC/$name.expected.tsv"
    actual="$(mktemp)"

    if [ ! -x "$bin" ]; then
        echo "  ✗ $name: 可执行文件缺失（out/$name）"
        rc=1
        rm -f "$actual"
        continue
    fi

    if ! "$bin" < "$cases" > "$actual"; then
        echo "  ✗ $name: Oracle 运行失败"
        rc=1
        rm -f "$actual"
        continue
    fi

    n=$(grep -cv '^#' "$actual" || true)
    total=$((total + n))

    if [ "$CHECK" = "1" ]; then
        if [ ! -f "$expected" ]; then
            echo "  ✗ $name: golden 缺失（$expected）"
            rc=1
        elif diff -q <(grep -v '^#' "$expected") "$actual" >/dev/null; then
            echo "  ✓ $name: $n 条与 golden 一致"
        else
            echo "  ✗ $name: 与 golden 不一致 —— 首个分歧:"
            diff <(grep -v '^#' "$expected") "$actual" | head -8 | sed 's/^/      /'
            rc=1
        fi
        rm -f "$actual"
    else
        {
            echo "# 自动生成，请勿手改。由 tools/oracle/run_all.sh 产出。"
            echo "# 来源: 对 vectors/$name.cases.tsv 运行真实反编译 C 代码（见 scenarios/$name.deps）"
            echo "# 格式: <id>\\t <result>"
            cat "$actual"
        } > "$expected"
        echo "  ✓ $name: $n 条 -> vectors/$name.expected.tsv"
        rm -f "$actual"
    fi
done

echo
if [ "$CHECK" = "1" ]; then
    [ $rc -eq 0 ] && echo "ALL GREEN — C Oracle $total 条向量与 golden 一致" \
                  || echo "FAILED — 见上面的分歧"
else
    echo "已更新 golden，共 $total 条向量。"
    echo "提交 vectors/ 下的 .cases.tsv 与 .expected.tsv。"
fi
exit $rc
