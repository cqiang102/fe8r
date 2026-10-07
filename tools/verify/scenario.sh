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
  throne)
    # 序章第一幕（王座厅）**中途**停住：80 个 confirm。
    #
    # 用来验"取景"：`LOMA(0x10)` 之后脚本会 `CAMERA(0xE, 0)`，
    # 把镜头从地图中央压到王座上（相机 y: 80 → 0）。
    # `CAMERA` 曾经是占位符，所以镜头一直停在地图中央。
    TITLE=""
    SCRIPT="$(python3 -c "print(','.join(['confirm']*80))")"
    ;;
  battle)
    # ★ 序章 → 打死奥尼尔 → `MNC2(1)` → **第 1 章**（`Ch1Map`）
    #
    # 这是一段**固定输入脚本**，靠的是"AI 是确定性的"这条性质
    # （`EnemyAi.decide` 是战场状态的纯函数，见 lib/core/flow/enemy_ai.dart）。
    # 它同时依赖：
    #   * 序章我方在 (4,4)/(4,5)、奥尼尔在 (14,8)
    #   * 赛特移动力 8（`CLASS_PALADIN.baseMov`）、奥尼尔 5
    #   * 移动消耗表：**真实表**（`pMovCostTable`，按职业 × 天气）——
    #     所以山峰不可通行，路线只有"穿过艾莉卡"那一条
    # 这些只要变，这段脚本就会**红**（这正是不该静默的地方）。
    #
    # 分段：
    #   开机 4×wait（≈3.6s，覆盖 Nintendo/IS 两屏的 200 帧）
    #   → 5×confirm 走完 健康警告/标题/主菜单/难度/存档槽
    #   → start **跳过序章过场**（`EV_STATE_SKIPPING`，START 键触发）
    #   → 第 1 回合：光标 (14,8)→赛特 (4,4)，选中，移到 (9,4)，待机，结束回合
    #   → 第 2 回合：选中，绕开挡路的敌人到 (13,5)，打奥尼尔一下（-12）
    #   → 第 3 回合：原地再打一下（-8），奥尼尔阵亡
    TITLE=""
    SCRIPT="wait,wait,wait,wait,confirm,confirm,confirm,confirm,confirm,wait,start,wait,wait"
    SCRIPT="$SCRIPT,$(python3 -c "print(','.join(['left']*10+['up']*4))")"
    # 第 1 回合：光标 (14,8)→赛特 (4,4)，选中，沿 (4,5) 穿过艾莉卡往东走，
    #              落在 (8,5)（山峰不可通行，真实消耗表下能到的就这一条路），待机
    SCRIPT="$SCRIPT,confirm,down,down,right,right,right,right,confirm,down,confirm,endturn"
    # 第 2 回合：走 (9,5)→(9,6 林)→(9,7)→(10,7 林)，打奥尼尔一下（-14）
    SCRIPT="$SCRIPT,confirm,right,down,down,right,confirm,down,confirm,confirm,endturn"
    # 第 3 回合：原地再打一下（-14），奥尼尔阵亡
    SCRIPT="$SCRIPT,confirm,confirm,down,confirm,confirm,endturn"
    # 第 1 章的开场脚本会先淡到黑；再跳一次过场 + 等两拍，
    # 截图才看得到地图（判据看的是转储，不看这张图）。
    SCRIPT="$SCRIPT,start,wait,wait"
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

# ★ 画面判据（只对要看的场景）：**换章之后不能是一片黑**。
#
# 起因：`MNC2` 之前那次 `FADI` 留下的黑屏，原作是靠章节标题卡的
# `ChapterIntro_LoopFadeToMap` 淡回来的；我们没实现时，切到第 1 章
# 画面**全黑**（地图和单位都在，就是看不见）。转储看不出这件事，
# 只有像素能证明 —— 所以这里量一次像素比例。
if [ "$SCENARIO" = "battle" ]; then
  python3 - "$PNG" <<'PYEOF'
import sys
from PIL import Image
im = Image.open(sys.argv[1]).convert('RGB')
w, h = im.size
# 只看中间那块（HUD 在上下两条）
crop = im.crop((0, int(h*0.2), w, int(h*0.75)))
px = list(crop.getdata())
nonblack = sum(1 for r, g, b in px if r + g + b > 60)
ratio = nonblack / len(px)
print(f"  [scenario] 画面非黑像素比例 {ratio:.3f}（{len(px)} 个像素）")
if ratio < 0.05:
    print("  [scenario] ✗ 画面几乎全黑 —— 换章之后没有淡入", file=sys.stderr)
    sys.exit(1)
PYEOF
  [ $? -ne 0 ] && exit 1
fi

cd "$ROOT" && "$DART" run tools/verify/check_dump.dart "$DUMP" --scenario "$SCENARIO"
