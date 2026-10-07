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

# `FE8R_WM=<目标章>`：调试入口，走**和 `MNCH` 同一条路**（先记下、待地图就绪再进）。
# 默认空 ⇒ 正常流程（由章间脚本里的 `MNCH` 触发）。
WM=""

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
    # ★ 一轮 = "**取消到自由光标 → 确定性重定位 → 原地待机/攻击 → 结束回合**"
    #
    # 为什么这么写（而不是手算坐标）：
    #   * `cancel` ×4 —— 无论现在停在哪个阶段（已选中 / 行动菜单 / 选目标），
    #     都先退回自由光标，否则方向键会被"移动范围"限制住
    #   * 重定位：**先撞到地图角落**（`left`×20 到底、`up`×20 到底，光标会被
    #     夹在地图内），再 `right`×4 `down`×4 → 必定落在赛特 (4,4)。
    #     这样**不依赖光标原来在哪**（回合事件里的 `CURSOR_CHAR` 会挪动它）
    #   * 行动：确认(选中) → 确认(自己那格 = 原地待机) → 下+确认(有目标就打)
    #     → 确认(目标) → 结束回合
    #   * 回合事件会演对白，后面补 10 个确认把它们翻过去
    #
    # 这条脚本里的每一步都对应一条判据：
    #   * "友军格挡不住光标"、"自己那格能停" —— `flow_machine_test.dart`
    #   * "第 2 个敌方阶段敌人还会动" —— `turn_loop_test.dart`
    #   * "回合事件会演" —— `chapter_objectives_test.dart` + 转储 turnEventsNote
    SCRIPT="wait,wait,wait,wait,confirm,confirm,confirm,confirm,confirm,wait,start,wait,wait"
    CANCEL=$(python3 -c "print(','.join(['cancel']*4))")
    RESYNC=$(python3 -c "print(','.join(['left']*20+['up']*20+['right']*4+['down']*4))")
    ACT="confirm,confirm,down,confirm,confirm,endturn"
    EVENTS=$(python3 -c "print(','.join(['confirm']*10))")
    for _ in 1 2 3 4 5; do
      SCRIPT="$SCRIPT,$CANCEL,$RESYNC,$ACT,$EVENTS"
    done
    # 第 1 章的开场脚本会先淡到黑；再跳一次过场 + 等两拍，
    # 截图才看得到地图（判据看的是转储，不看这张图）。
    SCRIPT="$SCRIPT,start,wait,wait"
    ;;
  mapmenu)
    # ★ 序章可玩地图 → START 打开地图菜单（**只是打开**）。
    #
    # 这一段前缀与 `battle` 相同（4×wait 覆盖 Nintendo/IS 两屏 → 5×confirm
    # 走完 健康警告/标题/主菜单/难度/存档槽 → start 跳过序章过场 → 两拍等画面）。
    # 随后那个 `start` 才是"打开地图菜单"。
    #
    # 判据看的是**显示哪几条**（`src/StartMenuCore.c:61-72`）：
    # 故事章节 ⇒ 戦績/退却 是 MENU_NOTSHOWN、不占行；行距 2 个 UI 图块；
    # 默认难度 normal ⇒ 教学模式 ⇒ 辞书没锁。
    TITLE=""
    SCRIPT="wait,wait,wait,wait,confirm,confirm,confirm,confirm,confirm,wait,start,wait,wait,start,wait,wait"
    ;;
  menuend)
    # 同上，但一路按到 **「終了」** 再确认 —— 验"主动结束回合"这条路。
    #
    # 6 条（部隊/状況/辞書/設定/中断/終了）⇒ 「終了」在第 6 行 ⇒ down ×5。
    # 条目数一变这条脚本就得改 —— 这正是它该红的地方。
    TITLE=""
    SCRIPT="wait,wait,wait,wait,confirm,confirm,confirm,confirm,confirm,wait,start,wait,wait,start,down,down,down,down,down,confirm,wait,wait"
    ;;
  worldmap)
    # ★ **章间大地图**（`MNCH` 那条路）。
    #
    # 真实触发点是第 1 章结束剧情里的 `MNCH(56)`（`Ch1_EndingScene`），
    # 但要打到那里得先打完两章；所以这里用 `FE8R_WM=56` 走**同一条流程**
    # （`_pendingWorldMapTarget` → `update()` 里在"地图就绪 + 无剧情"时进），
    # 目标章节仍然是 56（C00 / フレリア城）。
    #
    # 前缀与 `mapmenu` 相同（4×wait 覆盖开机两屏 → 5×confirm 走完
    # 健康警告/标题/主菜单/难度/存档槽 → start 跳过序章过场 → 等两拍）。
    # 序章的**开场脚本里有 `LOMA`**（地图是它装的），所以"地图就绪"发生在
    # 那之后 —— 多给两拍等待。
    TITLE=""
    WM=56
    SCRIPT="wait,wait,wait,wait,confirm,confirm,confirm,confirm,confirm,wait,start,wait,wait,wait,wait"
    ;;
  turnend)
    # ★ **两条回合结束**在同一次运行里各走一遍：
    #   ① 第 1 回合：赛特待机 → START → 地图菜单 →「終了」（主动结束）
    #   ② 第 2 回合：赛特待机 → 光标下移到艾莉卡 → 她也待机（**不按任何键**）→
    #      `PlayerPhase_HandleAutoEnd`（`src/playerphase_0801D808.c:52`）自动结束
    #   之后应当：turn 3、我方阶段、`GetPhaseAbleUnitCount(blue) == 2`、
    #   所有人的 `hasActed` 都是 false（`ClearActiveFactionGrayedStates`
    #   在各自阶段结束时清，`src/bm_08015434.c:82-95`）。
    #
    # ⚠️ 输入脚本里**不能有多余的 confirm**：第 2 回合光标停在赛特那格，
    #    多按一次确认就会让他再行动一次 —— 那会污染转储（我踩过两次）。
    TITLE=""
    SCRIPT="wait,wait,wait,wait,confirm,confirm,confirm,confirm,confirm,wait,start,wait,wait"
    EVENTS=$(python3 -c "print(','.join(['confirm']*10))")
    CANCEL=$(python3 -c "print(','.join(['cancel']*4))")
    RESYNC=$(python3 -c "print(','.join(['left']*20+['up']*20+['right']*4+['down']*4))")
    ACT="confirm,confirm,down,confirm"          # 选中 → 自己那格 → 菜单选「待機」→ 确定
    MENU_END="start,down,down,down,down,down,confirm"
    WAITS=$(python3 -c "print(','.join(['wait']*4))")
    # ① 主动结束
    SCRIPT="$SCRIPT,$EVENTS,$CANCEL,$RESYNC,$ACT,$MENU_END,$WAITS"
    # ② 自动结束（两个单位都待机，中间不按任何结束回合的键）
    SCRIPT="$SCRIPT,$CANCEL,$RESYNC,$ACT,down,$ACT,$WAITS"
    SCRIPT="$SCRIPT,$(python3 -c "print(','.join(['wait']*4))")"
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
FE8R_WM="$WM" \
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
