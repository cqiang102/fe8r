#!/bin/bash
#
# build.sh —— 构建一个场景的 C Oracle 可执行文件。
#
# 用法:
#   ./build.sh <场景名>          # 依赖见 scenarios/<场景名>.deps
#   ./build.sh --all             # 构建全部场景
#
# 产物: out/<场景名>
#
# 为什么用 -std=gnu89 -O2，两个都不能少：
#   -O2   上游 agbcc 就在 -O2 下编译。GNU89 的 `extern inline`（同一函数在多个
#         .c 里重复定义，如 GetItemStatBonuses）靠内联消除才不产生符号引用；
#         -O0 会因符号未定义而链接失败。
#   gnu89 C99 的 `extern inline` 语义相反（会产出外部定义），多个 TU 一起链接
#         时符号冲突。必须用 GNU89 语义。
#
set -uo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$HERE/../.." && pwd)"
DECOMP="$REPO_ROOT/third_party/fireemblem8j"
OUT="$HERE/out"
PRELUDE="$HERE/host/host_prelude.h"

if [ ! -d "$DECOMP/src" ]; then
    echo "错误: 找不到 $DECOMP/src" >&2
    echo "请先: git clone https://github.com/laqieer/fireemblem8j third_party/fireemblem8j" >&2
    exit 1
fi

mkdir -p "$OUT"

build_one() {
    local name="$1"
    local scen="$HERE/scenarios/$name.c"
    local deps_file="$HERE/scenarios/$name.deps"
    local -a deps=()

    if [ ! -f "$scen" ]; then
        echo "错误: 找不到场景 $scen" >&2
        return 1
    fi

    # 读取依赖的反编译源文件（每行一个；# 开头为注释）
    #   普通行     → 相对 DECOMP 根，如 src/rng.c
    #   @ 开头     → 相对 tools/oracle，如 @override/foo.c
    #                 （用于"只需要上游某个 TU 里的单个函数、直接编整个 TU
    #                   会拖进几十个无关符号"的情况）
    if [ -f "$deps_file" ]; then
        while IFS= read -r line; do
            line="${line%%#*}"                     # 去掉行内注释
            line="$(echo "$line" | xargs)"         # 去首尾空白
            [ -z "$line" ] && continue
            case "$line" in
                @*) deps+=("$HERE/${line#@}") ;;
                /*) deps+=("$line") ;;
                *)  deps+=("$DECOMP/$line") ;;
            esac
        done < "$deps_file"
    fi

    echo "构建 $name  (依赖 ${#deps[@]} 个反编译源文件)"
    clang -std=gnu89 -O2 -w \
        -include "$PRELUDE" \
        -I "$DECOMP/include" -I "$DECOMP" -I "$HERE/lib" \
        -o "$OUT/$name" \
        "$scen" "$HERE/lib/oracle_io.c" ${deps[@]+"${deps[@]}"}

    if [ $? -ne 0 ]; then
        echo "  ✗ $name 构建失败" >&2
        return 1
    fi
    echo "  ✓ out/$name"
    return 0
}

if [ "${1:---all}" = "--all" ]; then
    fail=0
    for f in "$HERE"/scenarios/*.c; do
        n="$(basename "$f" .c)"
        build_one "$n" || fail=1
    done
    exit $fail
else
    build_one "$1"
fi
