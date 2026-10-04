#!/bin/bash
# 对 third_party/fireemblem8j 的每个 src/*.c 尝试 host 编译，统计覆盖率。
# 用法: ./compile_coverage.sh [输出目录]
set -u

HERE="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$HERE/../.." && pwd)"
SRC="$REPO_ROOT/third_party/fireemblem8j"
PRELUDE="$HERE/host/host_prelude.h"
OUT="${1:-/tmp/fe8r-oracle/results}"
OBJ="$(dirname "$OUT")/obj"

if [ ! -d "$SRC/src" ]; then
    echo "错误: 找不到 $SRC/src —— 请先克隆 fireemblem8j 到 third_party/" >&2
    exit 1
fi

rm -rf "$OUT" "$OBJ"
mkdir -p "$OUT" "$OBJ"

tryone() {
    local f="$1" b
    b=$(basename "$f" .c)
    if clang -c -std=gnu89 -O2 -w \
         -include "$PRELUDE" \
         -I "$SRC/include" -I "$SRC" \
         -o "$OBJ/$b.o" "$f" 2>"$OUT/$b.err"; then
        echo "OK" > "$OUT/$b.status"
    else
        local msg
        msg=$(grep -m1 "error:" "$OUT/$b.err" | sed 's/.*error: //' | cut -c1-90)
        echo "FAIL|$msg" > "$OUT/$b.status"
    fi
    rm -f "$OUT/$b.err"
}
export -f tryone
export SRC OUT OBJ PRELUDE

ls "$SRC"/src/*.c | xargs -P 8 -I{} bash -c 'tryone "$@"' _ {}

echo "=== 编译覆盖率 ==="
cat "$OUT"/*.status | awk -F'|' '
    { if ($1=="OK") ok++; else { f++; c[$2]++ } }
    END {
        printf "通过: %d   失败: %d   通过率: %.2f%%\n\n", ok, f, ok*100/(ok+f)
        print "剩余失败分类:"
        for (k in c) printf "%6d  %s\n", c[k], k
    }'
