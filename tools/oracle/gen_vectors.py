#!/usr/bin/env python3
"""
gen_vectors.py —— 生成 C Oracle 的测试向量。

设计要点:
  * **固定随机种子**，向量可完全复现。生成结果提交到仓库。
  * 每个场景显式声明字段与取值范围，覆盖边界值而不只是随机中值。
  * 输出 TSV（见 tools/oracle/lib/oracle_io.h 的格式说明）。

用法:
    python3 gen_vectors.py            # 生成全部场景
    python3 gen_vectors.py rng        # 只生成某一个
"""
import os
import random
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
OUT_DIR = os.path.join(HERE, "vectors")

# 全局固定种子 —— 改它会让所有向量失效，需要同步更新 .expected.tsv
SEED = 20261003


def gen_rng(rng):
    """乱数系统。重点覆盖边界种子与负数种子。"""
    cases = []
    seeds = [0, 1, 2, 6, 7, 22, 23, 100, 12345, 32767, 65535,
             -1, -7, -23, -12345]
    seeds += [rng.randrange(0, 65536) for _ in range(20)]

    for i, s in enumerate(seeds):
        cases.append((f"rng_next_{i:03d}", {"seed": s, "fn": "next", "count": 8}))
        cases.append((f"rng_100_{i:03d}", {"seed": s, "fn": "next100", "count": 8}))
        cases.append((f"rng_lcg_{i:03d}", {"seed": s, "fn": "lcg", "count": 8}))

    # Roll2RN / NextRN_N 的阈值覆盖：0、1、50、99、100
    for thr in [0, 1, 25, 50, 75, 99, 100]:
        for k in range(4):
            s = rng.randrange(0, 65536)
            cases.append((f"rng_roll2_t{thr}_{k}", {"seed": s, "fn": "roll2", "count": 10, "thr": thr}))
            cases.append((f"rng_nextn_t{thr}_{k}", {"seed": s, "fn": "nextn", "count": 10, "thr": thr}))
    return cases


def gen_battle_unit(rng):
    """战斗单位派生属性。重点覆盖 AvoidRate 的负数钳位边界。"""
    cases = []
    # 钳位边界：故意构造 speed*2 + terrainAvoid + lck <= 0 的组合
    edge = [
        (0, 0, 0), (0, -1, 0), (0, -5, 2), (0, 0, -1),
        (1, 0, 0), (0, 5, 0), (12, 20, 8), (30, 30, 30),
        (0, -30, 0), (0, 0, -30), (127, -127, 0),
    ]
    for i, (spd, tav, lck) in enumerate(edge):
        cases.append((f"bu_avoid_edge_{i:02d}",
                      {"fn": "avoid", "battleSpeed": spd, "terrainAvoid": tav, "lck": lck}))

    for i in range(60):
        cases.append((f"bu_avoid_rnd_{i:03d}", {
            "fn": "avoid",
            "battleSpeed": rng.randrange(0, 31),
            "terrainAvoid": rng.randrange(-30, 31),
            "lck": rng.randrange(0, 31),
        }))

    for i in range(40):
        cases.append((f"bu_defense_{i:03d}", {
            "fn": "defense",
            "terrainDefense": rng.randrange(-30, 31),
            "def": rng.randrange(-30, 31),
        }))

    for i in range(20):
        cases.append((f"bu_dodge_{i:03d}", {
            "fn": "dodge",
            "lck": rng.randrange(-30, 31),
        }))
    return cases


def gen_unit_defense(rng):
    """单位防御。覆盖空手 / 有加成 / 负防御 / 负加成。"""
    cases = []
    edges = [(0, 0, 0), (12, 0, 0), (12, 1, 3), (7, 1, 0), (-3, 1, 3),
             (0, 1, 127), (127, 1, -128), (-128, 1, -128), (20, 1, -10)]
    for i, (d, item, bonus) in enumerate(edges):
        cases.append((f"ud_edge_{i:02d}", {"def": d, "item": item, "defBonus": bonus}))

    for i in range(60):
        cases.append((f"ud_rnd_{i:03d}", {
            "def": rng.randrange(-128, 128),
            "item": rng.choice([0, 1]),
            "defBonus": rng.randrange(-128, 128),
        }))
    return cases


def gen_crit_rate(rng):
    """必杀率。重点覆盖三条归零分支与循环短路。"""
    cases = []
    MS = 0xB5  # ITEM_MONSTER_STONE

    # 手工边界：每条分支各来一遍
    edges = [
        # (critRate, dodgeRate, weapon, di0, di1, 说明)
        (30, 10, 1, 0, 0),          # 普通相减
        (5, 20, 1, 0, 0),           # 负数 -> 钳位 0
        (0, 0, 1, 0, 0),            # 零
        (30, 0, MS, 0, 0),          # 魔石 -> 0
        (30, 0, 1, 2, 0),           # 首件免疫必杀 -> 0
        (30, 0, 1, 1, 2),           # 第二件免疫 -> 0
        (30, 0, 1, 0, 2),           # ★ items[0]=0 短路，后面的 2 不该被看到 -> 30
        (30, 0, 1, 1, 0),           # 普通道具，无免疫 -> 30
        (32767, -32768, 1, 0, 0),   # 溢出边界
        (-100, -100, 1, 0, 0),      # 双负
    ]
    for i, (cr, dr, wp, d0, d1) in enumerate(edges):
        cases.append((f"cr_edge_{i:02d}",
                      {"critRate": cr, "dodgeRate": dr, "weapon": wp, "di0": d0, "di1": d1}))

    for i in range(80):
        cases.append((f"cr_rnd_{i:03d}", {
            "critRate": rng.randrange(-20, 101),
            "dodgeRate": rng.randrange(0, 41),
            "weapon": rng.choice([1, 2, 0x11, MS]),
            "di0": rng.choice([0, 1, 1, 1, 2]),
            "di1": rng.choice([0, 1, 2]),
        }))
    return cases


def gen_movement(rng):
    """移动范围（BFS 泛洪）。

    重点覆盖：
      * 纯平原（应得到规则菱形，可手算校验）
      * 不可通行地形切断区域
      * 高消耗地形（森林/山峰）导致绕路
      * 边界起点（角落、贴边）
      * 不同移动力（0 / 1 / 最大值）
    """
    cases = []

    # 地形 ID（见 include/constants/terrains.h）
    PLAINS, FOREST, MOUNTAIN, RIVER, SEA = 0x01, 0x0C, 0x11, 0x10, 0x15
    # 消耗表：常用地形给真实值，其余默认 1，河流/海不可通行
    def costs(**over):
        c = [1] * 65
        c[0x00] = -1          # TERRAIN_NONE
        c[FOREST] = 2
        c[MOUNTAIN] = 4
        c[RIVER] = -1
        c[SEA] = -1
        for k, v in over.items():
            c[int(k, 0)] = v
        return ",".join(map(str, c))

    BASE = costs()

    def mk(nid, w, h, move, x, y, terrain, c=BASE, unit=0):
        return (nid, {
            "w": w, "h": h, "move": move, "x": x, "y": y,
            "terrain": ",".join(map(str, terrain)), "costs": c, "unit": unit,
        })

    # --- 手工边界 ---
    cases.append(mk("mv_flat_8x8_m3", 8, 8, 3, 0, 0, [PLAINS] * 64))
    cases.append(mk("mv_flat_8x8_m0", 8, 8, 0, 0, 0, [PLAINS] * 64))
    cases.append(mk("mv_flat_8x8_m1", 8, 8, 1, 0, 0, [PLAINS] * 64))
    cases.append(mk("mv_flat_8x8_m15", 8, 8, 15, 0, 0, [PLAINS] * 64))
    cases.append(mk("mv_flat_center", 8, 8, 4, 4, 4, [PLAINS] * 64))
    cases.append(mk("mv_flat_corner_br", 8, 8, 4, 7, 7, [PLAINS] * 64))

    # 一列河（不可通行）把地图切成两半
    t = [PLAINS] * 64
    for y in range(8):
        t[y * 8 + 4] = RIVER
    cases.append(mk("mv_river_split", 8, 8, 5, 0, 0, t))

    # 一圈高消耗森林（绕路）
    t = [PLAINS] * 64
    for i in range(64):
        if (i // 8) in (2, 5) or (i % 8) in (2, 5):
            t[i] = FOREST
    cases.append(mk("mv_forest_bands", 8, 8, 6, 0, 0, t))

    # 山地：消耗 4，移动力 5 时只走得动一格
    t = [PLAINS] * 64
    for i in range(64):
        if i % 8 >= 3:
            t[i] = MOUNTAIN
    cases.append(mk("mv_mountain", 8, 8, 5, 0, 0, t))

    # 窄桥：整列只有一格可通行
    t = [RIVER] * 64
    for y in range(8):
        t[y * 8 + 4] = PLAINS
        t[y * 8 + 3] = PLAINS
    cases.append(mk("mv_bridge", 8, 8, 6, 0, 0, t))

    # 全不可通行（只有起点可达）
    cases.append(mk("mv_all_blocked", 8, 8, 5, 3, 3, [RIVER] * 64))

    # 长宽不等
    cases.append(mk("mv_rect_3x9", 3, 9, 4, 0, 0, [PLAINS] * 27))
    cases.append(mk("mv_rect_9x3", 9, 3, 4, 0, 0, [PLAINS] * 27))

    # 单位占位（terrain 里塞一个敌方单位挡住去路）
    t = [PLAINS] * 64
    cases.append((f"mv_unit_block", {
        "w": 8, "h": 8, "move": 4, "x": 0, "y": 0,
        "terrain": ",".join(map(str, t)), "costs": BASE, "unit": 0x81,
    }))

    # --- 随机 ---
    for i in range(40):
        w = rng.randint(3, 12)
        h = rng.randint(3, 12)
        t = []
        for _ in range(w * h):
            t.append(rng.choice([PLAINS, PLAINS, PLAINS, FOREST, MOUNTAIN,
                                 RIVER, SEA]))
        cases.append(mk(f"mv_rnd_{i:03d}", w, h, rng.randint(0, 12),
                        rng.randrange(w), rng.randrange(h), t))

    return cases


SCENARIOS = {
    "rng": gen_rng,
    "battle_unit": gen_battle_unit,
    "unit_defense": gen_unit_defense,
    "crit_rate": gen_crit_rate,
    "movement": gen_movement,
}


def fmt(cid, fields):
    parts = [cid]
    for k, v in fields.items():
        parts.append(f"{k}={v}")
    return "\t".join(parts)


def main():
    os.makedirs(OUT_DIR, exist_ok=True)
    only = sys.argv[1] if len(sys.argv) > 1 else None

    for name, gen in SCENARIOS.items():
        if only and name != only:
            continue
        # 每个场景用独立但确定的子种子
        rng = random.Random(f"{SEED}:{name}")
        cases = gen(rng)
        path = os.path.join(OUT_DIR, f"{name}.cases.tsv")
        with open(path, "w", encoding="utf-8") as f:
            f.write(f"# 自动生成，请勿手改。生成器: tools/oracle/gen_vectors.py\n")
            f.write(f"# 场景: {name}  种子: {SEED}:{name}  用例数: {len(cases)}\n")
            f.write("# 格式: <id>\\t key=value \\t key=value ...\n")
            for cid, fields in cases:
                f.write(fmt(cid, fields) + "\n")
        print(f"{name:16s} {len(cases):5d} 用例 -> vectors/{name}.cases.tsv")


if __name__ == "__main__":
    main()
