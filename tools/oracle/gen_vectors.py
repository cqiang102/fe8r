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


def gen_battle_speed(rng):
    """战斗速度：有效重量 = 武器重量 - 体格，两道钳位。

    并入 battle_unit 场景文件（靠 fn=speed 分派），所以这里产出的是
    追加到 battle_unit.cases.tsv 的用例。
    """
    cases = []
    # 手工边界：两道钳位各来一遍
    edges = [
        # (spd, weaponBefore, conBonus)
        (10, 0, 0),      # 空手，重量 0
        (10, 1, 0),      # 重量 1
        (10, 2, 0),      # 重量 5
        (5, 3, 0),       # 重量 12 > 速度 -> 钳位到 0
        (10, 4, 20),     # 体格 20 > 重量 20 -> 有效重量 0
        (10, 3, 5),      # 12 - 5 = 7
        (10, 3, 12),     # 12 - 12 = 0
        (10, 3, 30),     # 体格远超重量 -> 有效重量 0
        (0, 2, 0),       # 速度 0，重量 5 -> 钳位到 0
        (127, 0, 0),     # 速度上界
    ]
    for i, (spd, wb, con) in enumerate(edges):
        cases.append((f"bu_speed_edge_{i:02d}",
                      {"fn": "speed", "spd": spd, "weaponBefore": wb,
                       "conBonus": con}))
    for i in range(30):
        cases.append((f"bu_speed_rnd_{i:03d}", {
            "fn": "speed",
            "spd": rng.randrange(-10, 40),
            "weaponBefore": rng.choice([0, 1, 2, 3, 4]),
            "conBonus": rng.randrange(-5, 25),
        }))
    return cases


def gen_battle_unit_all(rng):
    """battle_unit 场景 = 原有三函数 + 新增 speed"""
    return gen_battle_unit(rng) + gen_battle_speed(rng)



def gen_battle_attack(rng):
    """攻击力与特效判定。

    重点覆盖：
      * 无特效（基准）
      * 各类特效列表命中 / 不命中
      * **神器 ×2 vs 普通特效 ×3** 这两条不同倍率
      * 飞行特效被 IA_NEGATE_FLYING 抵消
      * 魔物职业（0x2B/0x2C）对一切魔物 ×3
      * 魔石（ITEM_MONSTER_STONE）→ 攻击力归零

    ⚠️ **职业编号从真实有效性表里读，不手写。**
    早期版本我手写了 `armor=0x0F`、`horse=0x0C`，结果 0x0F 根本不在
    ItemEffectiveness_Armor 里，而 0x0C 是 CLASS_GENERAL_F **恰好在**里面——
    于是"armor 列表打 horse 职业"反而命中了。Oracle 本身没错，
    错的是我编的测试数据。现在改成从 itemuse.json 里取表成员。
    """
    import json as _json

    tables_path = os.path.join(
        HERE, "..", "pipeline", "out", "tables", "itemuse.json")
    if not os.path.exists(tables_path):
        raise SystemExit(
            f"错误：找不到 {tables_path}\n"
            "先跑 tools/pipeline/extract/parse_c_tables.py")
    idata = _json.load(open(tables_path, encoding="utf-8"))
    cls_enum = {k: v for k, v in idata["enum"].items()
                if k.startswith("CLASS_")}
    tbl = idata["tables"]

    def members(name):
        """取某张有效性表的成员（去掉末尾的 CLASS_NONE 终止符）"""
        vals = tbl[name]["values"]
        return [v for v in vals if v != 0]

    ARMOR = members("ItemEffectiveness_Armor")
    ARMOR_HORSE = members("ItemEffectiveness_ArmorAndHorse")
    HORSE = members("ItemEffectiveness_Horse")
    FLIER = members("ItemEffectiveness_Flier")
    FLIER_MON = members("ItemEffectiveness_FlierAndMonsters")
    DRAGON = members("ItemEffectiveness_Dragon")
    MONSTERS = members("ItemEffectiveness_Monsters")

    def outsider(members_list):
        """找一个**不在**该列表里的职业，用来测"不命中"分支"""
        for v in range(1, 0x80):
            if v not in members_list:
                return v
        return 1

    PLAIN = outsider(ARMOR + FLIER + DRAGON + MONSTERS)   # 什么特效都不吃

    # `IsUnitEffectiveAgainst` 里写死的 `case 0x2B: case 0x2C:` 对应的是
    # **主教**（CLASS_BISHOP / CLASS_BISHOP_F）——FE8 的"斩魔"特性。
    # 别按字面猜成石像鬼蛋：我第一版就猜错了，测试数据选了 CLASS_GORGONEGG，
    # 于是"主教打魔物 ×3"这条分支一次都没被覆盖到。
    BISHOP = cls_enum["CLASS_BISHOP"]
    BISHOP_F = cls_enum["CLASS_BISHOP_F"]

    cases = []
    LISTS = ["none", "armor", "armorAndHorse", "horse", "flier",
             "flierAndMonsters", "dragon", "monsters"]
    NEG = 1 << 14   # IA_NEGATE_FLYING

    # --- attack：完整链路 ---
    edges = [
        # (说明, weapon, might, triBonus, pow, actorCls, targetCls, effList, negFly)
        ("基准", 1, 10, 0, 5, 1, PLAIN, "none", 0),
        ("三角加成", 1, 10, 3, 5, 1, PLAIN, "none", 0),
        ("armor 列表命中", 1, 5, 0, 0, 1, ARMOR[0], "armor", 0),
        ("armorAndHorse 命中", 1, 5, 0, 0, 1, ARMOR_HORSE[0], "armorAndHorse", 0),
        ("armor 列表不命中", 1, 5, 0, 0, 1, outsider(ARMOR), "armor", 0),
        ("horse 列表命中", 1, 5, 0, 0, 1, HORSE[0], "horse", 0),
        ("flier 列表命中", 1, 5, 0, 0, 1, FLIER[0], "flier", 0),
        ("flier 被抵消", 1, 5, 0, 0, 1, FLIER[0], "flier", NEG),
        ("flierAndMonsters 命中飞行", 1, 5, 0, 0, 1, FLIER_MON[0], "flierAndMonsters", 0),
        ("flierAndMonsters 命中魔物", 1, 5, 0, 0, 1, MONSTERS[0], "flierAndMonsters", 0),
        ("flierAndMonsters 被抵消", 1, 5, 0, 0, 1, FLIER_MON[0], "flierAndMonsters", NEG),
        ("dragon 列表命中", 1, 5, 0, 0, 1, DRAGON[0], "dragon", 0),
        ("monsters 列表命中", 1, 5, 0, 0, 1, MONSTERS[0], "monsters", 0),
        ("monsters 列表不因抵消失效", 1, 5, 0, 0, 1, MONSTERS[0], "monsters", NEG),
        ("主教打魔物", 1, 5, 0, 0, BISHOP, MONSTERS[0], "none", 0),
        ("女主教打魔物", 1, 5, 0, 0, BISHOP_F, MONSTERS[0], "none", 0),
        ("主教打非魔物", 1, 5, 0, 0, BISHOP, PLAIN, "none", 0),
        ("魔石归零", 0xB5, 5, 0, 12, 1, PLAIN, "none", 0),
        ("空手", 0, 999, 0, 7, 1, PLAIN, "none", 0),
    ]
    for i, (why, w, might, tri, pw, ac, tc, el, ng) in enumerate(edges):
        cases.append((f"ba_attack_edge_{i:02d}", {
            "fn": "attack", "weapon": w, "might": might, "triBonus": tri,
            "pow": pw, "actorCls": ac, "targetCls": tc,
            "effList": el, "negFly": ng,
        }))
    globals()["_BA_NOTES"] = {f"ba_attack_edge_{i:02d}": e[0]
                              for i, e in enumerate(edges)}

    # --- item_eff / unit_eff：单独看判定 ---
    pairs = [
        (1, ARMOR[0], "armor", 0),
        (1, outsider(ARMOR), "armor", 0),
        (1, HORSE[0], "horse", 0),
        (1, FLIER[0], "flier", 0),
        (1, FLIER[0], "flier", NEG),
        (1, FLIER_MON[0], "flierAndMonsters", 0),
        (1, FLIER_MON[0], "flierAndMonsters", NEG),
        (1, MONSTERS[0], "flierAndMonsters", 0),
        (1, MONSTERS[0], "monsters", 0),
        (1, MONSTERS[0], "monsters", NEG),
        (1, DRAGON[0], "dragon", 0),
        (BISHOP, MONSTERS[0], "none", 0),
        (BISHOP_F, MONSTERS[0], "none", 0),
        (BISHOP, PLAIN, "none", 0),
    ]
    for i, (ac, tc, el, ng) in enumerate(pairs):
        common = {"weapon": 1, "might": 5, "actorCls": ac, "targetCls": tc,
                  "effList": el, "negFly": ng}
        cases.append((f"ba_item_eff_{i:02d}", dict(common, fn="item_eff")))
        cases.append((f"ba_unit_eff_{i:02d}", dict(common, fn="unit_eff")))

    # --- 随机 ---
    all_cls = [1, PLAIN, BISHOP, BISHOP_F] + ARMOR[:1] + HORSE[:1] + \
              FLIER[:1] + DRAGON[:1] + MONSTERS[:1]
    for i in range(60):
        cases.append((f"ba_rnd_{i:03d}", {
            "fn": rng.choice(["attack", "attack", "item_eff", "unit_eff"]),
            "weapon": rng.choice([0, 1, 1, 1, 0xB5]),
            "might": rng.randrange(0, 30),
            "triBonus": rng.randrange(-3, 4),
            "pow": rng.randrange(0, 40),
            "actorCls": rng.choice([1, 1, BISHOP, BISHOP_F]),
            "targetCls": rng.choice(all_cls),
            "effList": rng.choice(LISTS),
            "negFly": rng.choice([0, 0, NEG]),
        }))
    return cases



def gen_battle_rng(rng):
    """战斗流程的乱数消耗。

    判据不是"数了几次"，而是**调用结束后的 LFSR 状态**——
    少消耗一次 / 多消耗一次 / 顺序不同，状态都会完全不同。
    所以每条用例都输出 (damage, attributes, seed0, seed1, seed2)。

    重点覆盖：
      * 命中 / 未命中（未命中会提前 return，只消耗 2 个）
      * 必杀命中（多走一次 BattleCheckSilencer）
      * SURESHOT 标志（跳过命中判定 → 少消耗 2 个）
      * SIMULATE 配置（所有 BattleRoll*RN 直接短路 → 消耗 0 个）
      * 天马/翼骑士职业（BattleCheckPierce 额外消耗 1 个）
      * 魔王职业（BattleCheckSilencer 直接返回，少消耗 1 个）
    """
    edges = [
        # (说明, seed, hitRate, critRate, silencerRate, attack, defense, actorCls, targetCls, level, attrs, config)
        ("必中不必杀",       0, 100, 0,   0,   10, 2, 1, 1, 1, 0, 1),
        ("必中必杀",         0, 100, 100, 0,   10, 2, 1, 1, 1, 0, 1),
        ("必不中",           0, 0,   0,   0,   10, 2, 1, 1, 1, 0, 1),
        ("SURESHOT 跳过命中", 0, 0,   0,   0,   10, 2, 1, 1, 1, 1 << 14, 1),
        ("SIMULATE 全部短路", 0, 50,  50,  50,  10, 2, 1, 1, 1, 0, 2),
        ("翼骑士 extra roll", 0, 100, 0,   0,   10, 2, 0x23, 1, 50, 0, 1),
        ("魔王免疫瞬杀",     0, 100, 100, 100, 10, 2, 1, 0x66, 1, 0, 1),
        # ⚠️ 瞬杀判定嵌在**必杀判定内部**：
        #     if (BattleRoll1RN(critRate)) { if (BattleCheckSilencer(...)) ... }
        # 所以必须 critRate 也拉满才会走到瞬杀分支——
        # 之前只把 silencerRate 设成 100，critRate=0，结果一次都没覆盖到。
        ("瞬杀（必杀+瞬杀都满）", 0, 100, 100, 100, 10, 2, 1, 1, 1, 0, 1),
        ("有瞬杀率但必杀为 0",   0, 100, 0,   100, 10, 2, 1, 1, 1, 0, 1),
        ("伤害为负钳位",     0, 100, 0,   0,   3, 10, 1, 1, 1, 0, 1),
        ("不同种子",         7, 100, 0,   0,   10, 2, 1, 1, 1, 0, 1),
        ("不同种子+必杀",    42, 100, 100, 0,   10, 2, 1, 1, 1, 0, 1),
    ]
    cases = []
    for i, (why, sd, hr, cr, sr, atk, df, ac, tc, lv, attrs, cfg) in enumerate(edges):
        cases.append((f"br_edge_{i:02d}", {
            "seed": sd, "hitRate": hr, "critRate": cr, "silencerRate": sr,
            "attack": atk, "defense": df, "actorCls": ac, "targetCls": tc,
            "actorLevel": lv, "attrs": attrs, "config": cfg,
        }))

    for i in range(90):
        cases.append((f"br_rnd_{i:03d}", {
            "seed": rng.randrange(0, 1000),
            "hitRate": rng.choice([0, 10, 50, 90, 100, 100]),
            "critRate": rng.choice([0, 0, 20, 50, 100]),
            "silencerRate": rng.choice([0, 0, 0, 30]),
            "attack": rng.randrange(0, 40),
            "defense": rng.randrange(0, 40),
            "actorCls": rng.choice([1, 1, 0x23, 0x24]),
            "targetCls": rng.choice([1, 1, 1, 0x66]),
            "actorLevel": rng.randrange(1, 60),
            "attrs": rng.choice([0, 0, 0, 1 << 14]),
            "config": rng.choice([1, 1, 1, 2]),
        }))
    return cases



def gen_weapon_triangle(rng):
    """武器三角与命中率。

    重点覆盖：
      * 剑/枪/斧 六种组合（三种优势 + 三种劣势）
      * 魔法三角 理/光/暗
      * 同类型对同类型（表里没有规则 → 全 0）
      * 勇者武器（IA_REVERTTRIANGLE）反转
      * **双方都是勇者武器时互相抵消**（原版两个 if 是一起判的）
      * 命中率的整数除法边界（lck 奇偶）
    """
    SWORD, LANCE, AXE, BOW, ANIMA, LIGHT, DARK = 0, 1, 2, 3, 5, 6, 7
    REAVER = 1 << 8

    cases = []

    # --- triangle：物理与魔法三角全覆盖 ---
    phys = [SWORD, LANCE, AXE]
    magic = [ANIMA, LIGHT, DARK]
    for a in phys + magic:
        for d in phys + magic:
            cases.append((f"wt_pair_{a}_{d}", {
                "fn": "triangle", "atkType": a, "defType": d,
            }))

    # 弓箭/法杖：表里没有这两类，应当一律 0
    for a in (BOW, 4):
        for d in (SWORD, BOW):
            cases.append((f"wt_none_{a}_{d}", {
                "fn": "triangle", "atkType": a, "defType": d,
            }))

    # --- Reaver ---
    reaver = [
        ("atk_only_adv", SWORD, AXE, REAVER, 0),
        ("atk_only_dis", SWORD, LANCE, REAVER, 0),
        ("def_only_adv", SWORD, AXE, 0, REAVER),
        ("both_adv", SWORD, AXE, REAVER, REAVER),
        ("both_dis", SWORD, LANCE, REAVER, REAVER),
        ("no_rule_reaver", SWORD, SWORD, REAVER, 0),
        ("magic_reaver", ANIMA, LIGHT, REAVER, 0),
    ]
    for name, a, d, aa, da in reaver:
        cases.append((f"wt_reaver_{name}", {
            "fn": "triangle", "atkType": a, "defType": d,
            "atkAttr": aa, "defAttr": da,
        }))

    # --- hitrate ---
    hit_edges = [
        (0, 0, 0, 0),          # 全 0
        (10, 8, 85, 0),        # 常规
        (10, 8, 85, 15),       # 带三角优势
        (10, 8, 85, -15),      # 带三角劣势
        (0, 1, 0, 0),          # lck=1 -> 1/2 = 0
        (0, 3, 0, 0),          # lck=3 -> 3/2 = 1
        (-5, 0, 0, 0),         # 负技巧（异常输入）
        (127, 127, 127, 127),  # 上界
        (0, 0, 0, -127),       # 大负三角加成
    ]
    for i, (skl, lck, ih, wth) in enumerate(hit_edges):
        cases.append((f"wt_hit_edge_{i:02d}", {
            "fn": "hitrate", "skl": skl, "lck": lck, "itemHit": ih, "wth": wth,
        }))

    for i in range(60):
        cases.append((f"wt_rnd_{i:03d}", {
            "fn": rng.choice(["triangle", "triangle", "hitrate"]),
            "atkType": rng.choice([0, 1, 2, 3, 4, 5, 6, 7]),
            "defType": rng.choice([0, 1, 2, 3, 4, 5, 6, 7]),
            "atkAttr": rng.choice([0, 0, REAVER]),
            "defAttr": rng.choice([0, 0, REAVER]),
            "skl": rng.randrange(0, 40),
            "lck": rng.randrange(0, 40),
            "itemHit": rng.randrange(0, 100),
            "wth": rng.choice([0, 15, -15]),
        }))
    return cases



def gen_phase(rng):
    """阵营判定与"本回合可行动单位数"。

    重点覆盖：
      * 三个阵营两两组合（同盟 / 同一阵营是**两个不同**的判定）
      * notAble 掩码的**每一位单独触发**（漏一位就会让不该动的单位动起来）
      * 异常状态（睡眠 / 狂暴）
      * CA_UNSELECTABLE
      * pCharacterData 为空（UNIT_IS_VALID 为假）
      * CountUnitsInState 是"**不处于**该状态"的计数（容易写反）
    """
    BLUE, GREEN, RED = 0x00, 0x40, 0x80
    US_UNSEL, US_DEAD, US_NOTDEP, US_RESCUED, US_ROOF, US_B16 = (
        1 << 1, 1 << 2, 1 << 3, 1 << 5, 1 << 7, 1 << 16)
    CA_UNSEL = 1 << 20

    cases = []

    # --- 阵营判定 ---
    factions = [("blue", BLUE), ("green", GREEN), ("red", RED)]
    for ln, lv in factions:
        for rn, rv in factions:
            cases.append((f"ph_allied_{ln}_{rn}", {
                "fn": "allied", "left": lv, "right": rv}))
            cases.append((f"ph_alleg_{ln}_{rn}", {
                "fn": "allegiance", "left": lv, "right": rv}))
    for ln, lv in factions:
        cases.append((f"ph_current_{ln}", {"fn": "current", "faction": lv}))
        cases.append((f"ph_nonactive_{ln}", {"fn": "nonactive", "faction": lv}))

    # --- notAble 掩码逐位 ---
    unit = lambda st, status=0, ca=0, valid=1: f"{st}:{status}:{ca}:{valid}"
    bit_cases = [
        ("none", 0, 1), ("unsel", US_UNSEL, 0), ("dead", US_DEAD, 0),
        ("notdep", US_NOTDEP, 0), ("rescued", US_RESCUED, 0),
        ("roof", US_ROOF, 0), ("bit16", US_B16, 0),
        ("sleep", 0, 0), ("berserk", 0, 0), ("classes", 0, 0),
    ]
    for name, st, expect in bit_cases:
        status = 2 if name == "sleep" else (4 if name == "berserk" else 0)
        ca = CA_UNSEL if name == "classes" else 0
        # 一个"有问题"的单位 + 两个正常单位；期望值由 Oracle 决定，
        # 这里只负责把场景造出来
        units = f"1={unit(st, status, ca, 1)},2={unit(0)},3={unit(0)}"
        cases.append((f"ph_able_{name}", {
            "fn": "abled", "faction": BLUE, "units": units}))

    # 无效单位（valid=0）
    cases.append(("ph_able_invalid", {
        "fn": "abled", "faction": BLUE,
        "units": f"1={unit(0, 0, 0, 0)},2={unit(0)}"}))

    # 编号边界：阵营基址 +1 / +0x3F 应当算进去
    for fid, fname in ((BLUE, "blue"), (GREEN, "green"), (RED, "red")):
        units = f"{fid + 1}={unit(0)},{fid + 0x3F}={unit(0)}"
        cases.append((f"ph_able_bound_{fname}", {
            "fn": "abled", "faction": fid, "units": units}))

    # --- CountUnitsInState（注意语义是"不处于"）---
    for st in (US_DEAD, US_RESCUED, US_UNSEL, 0, 0xFFFFFFFF):
        units = f"1={unit(US_DEAD)},2={unit(0)},3={unit(0)},4={unit(US_RESCUED)}"
        cases.append((f"ph_instate_{st}", {
            "fn": "instate", "faction": BLUE, "state": st, "units": units}))

    # --- 随机 ---
    for i in range(60):
        fid = rng.choice([BLUE, GREEN, RED])
        parts = []
        for k in range(rng.randrange(1, 6)):
            uid = rng.randrange(fid, fid + 0x40)
            st = rng.choice([0, 0, 0, US_DEAD, US_RESCUED, US_UNSEL, US_B16])
            status = rng.choice([0, 0, 0, 2, 4])
            ca = rng.choice([0, 0, CA_UNSEL])
            valid = rng.choice([1, 1, 1, 0])
            parts.append(f"{uid}={unit(st, status, ca, valid)}")
        cases.append((f"ph_rnd_{i:03d}", {
            "fn": rng.choice(["abled", "abled", "instate"]),
            "faction": fid,
            "state": rng.choice([1, 2, 4, 1 << 5, 0]),
            "units": ",".join(parts),
        }))
    return cases



def gen_turn_switch(rng):
    """回合推进（SwitchPhases）。

    重点覆盖：
      * 三个起始阵营各自连切几次（顺序 蓝→红→绿→蓝）
      * **回合数只在 GREEN 绕回 BLUE 时递增**
      * **999 上限**：到顶后不再增长（998 跨一步、999 原地）
    """
    BLUE, GREEN, RED = 0x00, 0x40, 0x80
    cases = [
        # 各阵营起手连切一整轮多
        ("ts_from_blue", BLUE, 1, 7),
        ("ts_from_red", RED, 1, 7),
        ("ts_from_green", GREEN, 1, 7),
        # 回合数边界
        ("ts_turn_997", GREEN, 997, 6),
        ("ts_turn_998", GREEN, 998, 6),
        ("ts_turn_999", GREEN, 999, 6),
        ("ts_turn_1", BLUE, 1, 3),
    ]
    out = []
    for name, f, t, n in cases:
        out.append((name, {"faction": f, "turn": t, "steps": n}))

    for i in range(40):
        out.append((f"ts_rnd_{i:03d}", {
            "faction": rng.choice([BLUE, GREEN, RED]),
            "turn": rng.choice([1, 2, 5, 100, 500, 996, 997, 998, 999, 1000]),
            "steps": rng.randrange(1, 12),
        }))
    return out


SCENARIOS = {
    "rng": gen_rng,
    "battle_unit": gen_battle_unit_all,
    "unit_defense": gen_unit_defense,
    "crit_rate": gen_crit_rate,
    "movement": gen_movement,
    "battle_attack": gen_battle_attack,
    "battle_rng": gen_battle_rng,
    "weapon_triangle": gen_weapon_triangle,
    "phase": gen_phase,
    "turn_switch": gen_turn_switch,
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
