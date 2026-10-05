#!/usr/bin/env python3
"""
crosscheck.py —— 用 Python 独立重实现各场景，交叉校验 C Oracle 的输出。

为什么需要这个：
    C Oracle 用的是**真实的反编译 C 代码**，所以它算出来的数值本身是权威的。
    但 harness 的"管道"可能写错 —— struct 字段填错位、TSV 解析错、
    类型截断没模拟对。这些错误会让 Oracle 安静地给出错误的期望值。

    本脚本从 C 源码**独立地**重写一遍逻辑（严格模拟 C 的整数语义），
    与 C Oracle 的输出逐条比对。两者一致才说明管道是通的。

    这同时也是 Dart 侧实现的预演 —— Dart 的移植会遇到完全相同的截断问题。

用法:
    python3 crosscheck.py            # 校验全部场景
    python3 crosscheck.py rng        # 只校验某一个
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
VEC = os.path.join(HERE, "vectors")


# ---------------------------------------------------------------- 工具

def s8(v):
    """模拟 C 的 s8（signed char）"""
    v &= 0xFF
    return v - 256 if v >= 128 else v


def s16(v):
    """模拟 C 的 s16（short）"""
    v &= 0xFFFF
    return v - 65536 if v >= 32768 else v


def u16(v):
    return v & 0xFFFF


def c_trunc_div(a, b):
    """C 的整数除法向零截断（Python 的 // 是向下取整，不同）"""
    q = abs(a) // abs(b)
    return -q if (a < 0) != (b < 0) else q


def c_mod(a, b):
    """C 的 % 向零截断（Python 的 % 结果非负，不同）"""
    return a - c_trunc_div(a, b) * b


# ---------------------------------------------------------------- 场景: rng
# 逐行对照 third_party/fireemblem8j/src/rng.c

class Rng:
    INIT_TABLE = [0xA36E, 0x924E, 0xB784, 0x4F67, 0x8092, 0x592D, 0x8E70, 0xA794]

    def __init__(self, seed):
        self.s = [0, 0, 0]
        self.lcg = 0
        self.init(seed)

    def init(self, seed):
        mod = c_mod(seed, 7)
        self.s[0] = self.INIT_TABLE[mod & 7]; mod += 1
        self.s[1] = self.INIT_TABLE[mod & 7]; mod += 1
        self.s[2] = self.INIT_TABLE[mod & 7]
        r = c_mod(seed, 23)
        for _ in range(r if r > 0 else 0):
            self.next_rn()

    def next_rn(self):
        s = self.s
        # u16 rn = (gRNSeeds[1] << 11) + (gRNSeeds[0] >> 5);
        rn = u16((s[1] << 11) + (s[0] >> 5))
        # gRNSeeds[2] *= 2;  (u16 截断)
        s[2] = u16(s[2] * 2)
        if s[1] & 0x8000:
            s[2] = u16(s[2] + 1)
        rn = u16(rn ^ s[2])
        s[2], s[1], s[0] = s[1], s[0], rn
        return rn

    def next_rn_100(self):
        return c_trunc_div(self.next_rn() * 100, 0x10000)

    def next_rn_n(self, mx):
        return c_trunc_div(self.next_rn() * mx, 0x10000)

    def roll2_rn(self, thr):
        avg = c_trunc_div(self.next_rn_100() + self.next_rn_100(), 2)
        return 1 if thr > avg else 0

    def set_lcg(self, v):
        self.lcg = v

    def advance_lcg(self):
        # u32 rn = (gLCGRNValue * 4 + 2); rn *= (gLCGRNValue * 4 + 3);
        # gLCGRNValue = rn >> 2; return gLCGRNValue;
        v = self.lcg
        rn = u16_32((v * 4 + 2) & 0xFFFFFFFF)
        rn = (rn * ((v * 4 + 3) & 0xFFFFFFFF)) & 0xFFFFFFFF
        self.lcg = s32(rn >> 2)
        return self.lcg & 0xFFFFFFFF


def u16_32(v):
    return v & 0xFFFFFFFF


def s32(v):
    v &= 0xFFFFFFFF
    return v - (1 << 32) if v >= (1 << 31) else v


def model_rng(f):
    r = Rng(f["seed"])
    n = f.get("count", 8)
    fn = f.get("fn", "next")
    thr = f.get("thr", 50)
    if fn == "lcg":
        r.set_lcg(f["seed"])
        return [r.advance_lcg() for _ in range(n)]
    if fn == "next100":
        return [r.next_rn_100() for _ in range(n)]
    if fn == "nextn":
        return [r.next_rn_n(thr) for _ in range(n)]
    if fn == "roll2":
        return [r.roll2_rn(thr) for _ in range(n)]
    return [r.next_rn() for _ in range(n)]


# ------------------------------------------------ 场景: battle_unit

# 与 scenarios/battle_unit.c 里的 gItemData 重量表保持一致
BU_ITEM_WEIGHTS = {0: 0, 1: 1, 2: 5, 3: 12, 4: 20}


def model_battle_unit(f):
    fn = f.get("fn", "avoid")
    if fn == "speed":
        # ComputeBattleUnitSpeed:
        #   effWt = GetItemWeight(weaponBefore) - conBonus; 负数钳位到 0
        #   battleSpeed = spd - effWt;                     负数钳位到 0
        eff = BU_ITEM_WEIGHTS.get(f.get("weaponBefore", 0) & 0xFF, 0) - s8(f.get("conBonus", 0))
        if eff < 0:
            eff = 0
        spd = s8(f.get("spd", 0)) - eff
        if spd < 0:
            spd = 0
        return s16(spd)
    if fn == "defense":
        # bu->battleDefense = bu->terrainDefense + bu->unit.def;
        return s16(s8(f.get("terrainDefense", 0)) + s8(f.get("def", 0)))
    if fn == "dodge":
        # bu->battleDodgeRate = bu->unit.lck;
        return s16(s8(f.get("lck", 0)))
    # bu->battleAvoidRate = (battleSpeed*2) + terrainAvoid + unit.lck; 负数钳位
    v = s16(s16(f.get("battleSpeed", 0)) * 2 + s8(f.get("terrainAvoid", 0)) + s8(f.get("lck", 0)))
    return 0 if v < 0 else v


# ------------------------------------------------ 场景: unit_defense

def model_unit_defense(f):
    # GetUnitDefense = unit->def + GetItemDefBonus(item)
    # GetItemDefBonus(item): item==0 -> 0; 否则 statBonuses ? defBonus : 0
    item = f.get("item", 0)
    bonus = 0
    if item != 0:
        idx = item & 0xFF              # ITEM_INDEX
        if idx == 1:                   # harness 里只有索引 1 挂了 pStatBonuses
            bonus = s8(f.get("defBonus", 0))
    return s16(s8(f.get("def", 0)) + bonus)


# ------------------------------------------------ 场景: crit_rate

ITEM_MONSTER_STONE = 0xB5
IA_NEGATE_FLYING = (1 << 14)
IA_NEGATE_CRIT = 1 << 15


def model_crit_rate(f):
    # battleEffectiveCritRate = critRate - dodgeRate
    v = s16(s16(f.get("critRate", 0)) - s16(f.get("dodgeRate", 0)))
    if (f.get("weapon", 0) & 0xFF) == ITEM_MONSTER_STONE:
        v = 0
    if v < 0:
        v = 0
    # 循环: i < UNIT_ITEM_COUNT(5) && items[i] != 0
    for key in ("di0", "di1", "di2", "di3", "di4"):
        item = f.get(key, 0)
        if item == 0:
            break                       # ★ 空道具处短路
        idx = item & 0xFF
        attrs = IA_NEGATE_CRIT if idx == 2 else 0
        if attrs & IA_NEGATE_CRIT:
            v = 0
            break
    return v



# ------------------------------------------------ 场景: battle_attack

# 与 src/data/data_itemuse.c 的真实有效性表保持一致，从提取出的 JSON 读，
# 避免"Python 侧手抄一份"导致两边数据不一致
def _load_effectiveness():
    import json as _json
    path = os.path.join(HERE, "..", "pipeline", "out", "tables", "itemuse.json")
    if not os.path.exists(path):
        return None
    d = _json.load(open(path, encoding="utf-8"))
    tbl = d["tables"]
    out = {}
    for name, key in (
        ("armor", "ItemEffectiveness_Armor"),
        ("armorAndHorse", "ItemEffectiveness_ArmorAndHorse"),
        ("horse", "ItemEffectiveness_Horse"),
        ("flier", "ItemEffectiveness_Flier"),
        ("flierAndMonsters", "ItemEffectiveness_FlierAndMonsters"),
        ("dragon", "ItemEffectiveness_Dragon"),
        ("monsters", "ItemEffectiveness_Monsters"),
    ):
        out[name] = [v for v in tbl[key]["values"] if v != 0]
    return out


_EFF = _load_effectiveness()
_BISHOP = (0x2B, 0x2C)
_SACRED = {0x3E, 0x85, 0x87, 0x8E, 0x91, 0x92, 0x93, 0x94}


def _eff_list(name):
    if name in (None, "none"):
        return None
    return _EFF[name] if _EFF else None


def _is_flier_list(name):
    return name in ("flier", "flierAndMonsters")


def _weapon_slot(f):
    """场景里道具 1 承载被测武器；其它编号的道具没有威力也没有特效。

    ⚠️ 这一条必须照 C 的查表方式写：`GetItemMight(weapon)` 等价于
    `gItemData[weapon & 0xFF].might`。空手（weapon=0）时查的是**道具 0**，
    它的 might 与 pEffectiveness 都是 0 —— 用例里的 might/effList
    只对 `weapon & 0xFF == 1` 生效。
    漏了这条，所有 weapon=0 的用例都会算出 C 不可能产生的结果。
    """
    return (f.get("weapon", 0) & 0xFF) == 1


def _might(f):
    return f.get("might", 0) if _weapon_slot(f) else 0


def _item_effective(f):
    """IsItemEffectiveAgainst 的独立实现"""
    if _EFF is None:
        return None
    if not _weapon_slot(f):
        return 0            # 道具 0 没有 pEffectiveness
    eff = _eff_list(f.get("effList", "none"))
    if eff is None:
        return 0
    target = f.get("targetCls", 1)
    if target not in eff:
        return 0
    if not _is_flier_list(f.get("effList", "none")):
        return 1
    attrs = IA_NEGATE_FLYING if f.get("negFly", 0) else 0
    return 0 if (attrs & IA_NEGATE_FLYING) else 1


def _unit_effective(f):
    """IsUnitEffectiveAgainst 的独立实现：只有主教对魔物"""
    if _EFF is None:
        return None
    if f.get("actorCls", 1) not in _BISHOP:
        return 0
    return 1 if f.get("targetCls", 1) in _EFF["monsters"] else 0


def model_battle_attack(f):
    if _EFF is None:
        return None
    fn = f.get("fn", "attack")
    if fn == "item_eff":
        return _item_effective(f)
    if fn == "unit_eff":
        return _unit_effective(f)

    weapon = f.get("weapon", 0)
    base = _might(f) + s16(f.get("triBonus", 0))
    attack = base
    if _unit_effective(f):
        attack = base * 3
    if _item_effective(f):
        attack = base * (2 if (weapon & 0xFF) in _SACRED else 3)
    attack = s16(attack + s8(f.get("pow", 0)))
    if (weapon & 0xFF) == ITEM_MONSTER_STONE:
        attack = 0
    return s16(attack)



# ------------------------------------------------ 场景: battle_rng

# 战斗判定的乱数消耗顺序，逐条对照：
#   src/BattleGenerateHitAttributes.c / src/bmbattle_0802B164.c / src/BattleCheckSilencer.c
# 输出与 C 场景一致：damage,attributes,seed0,seed1,seed2

_ATTR_CRIT = 1 << 0
_ATTR_MISS = 1 << 1
_ATTR_SILENCER = 1 << 11
_ATTR_SURESHOT = 1 << 14
_ATTR_GREATSHLD = 1 << 15
_ATTR_PIERCE = 1 << 16

_CFG_SIMULATE = 1 << 1
_MAX_DAMAGE = 127

_CLS_SNIPER = 0x1B
_CLS_SNIPER_F = 0x1C
_CLS_GENERAL = 0x0B
_CLS_GENERAL_F = 0x0C
_CLS_WYVERN_KNIGHT = 0x23
_CLS_WYVERN_KNIGHT_F = 0x24
_CLS_DEMON_KING = 0x66


class _BattleRng:
    def __init__(self, seed):
        self.r = Rng(seed)

    def roll1(self, thr):
        return thr > self.r.next_rn_100()

    def roll2(self, thr):
        avg = c_trunc_div(self.r.next_rn_100() + self.r.next_rn_100(), 2)
        return thr > avg

    def state(self):
        return tuple(self.r.s)

    def battle_roll1(self, config, thr, sim):
        if config & _CFG_SIMULATE:
            return sim
        return self.roll1(thr)

    def battle_roll2(self, config, thr, sim):
        if config & _CFG_SIMULATE:
            return sim
        return self.roll2(thr)


def model_battle_rng(f):
    seed = f.get("seed", 0)
    config = f.get("config", 1)
    attrs = f.get("attrs", 0)
    attacker_cls = f.get("actorCls", 1)
    defender_cls = f.get("targetCls", 1)
    level = f.get("actorLevel", 1)

    t = _BattleRng(seed)
    damage = 0

    # ---- 1. BattleCheckSureShot ----
    if not (attrs & _ATTR_SURESHOT or attrs & _ATTR_PIERCE or attrs & _ATTR_GREATSHLD):
        if attacker_cls in (_CLS_SNIPER, _CLS_SNIPER_F):
            # 弩车（0x35/0x36/0x37）直接必中且不消耗乱数；否则 roll 一次
            if f.get("weaponIndex", 1) not in (0x35, 0x36, 0x37):
                if t.battle_roll1(config, level, False):
                    attrs |= _ATTR_SURESHOT

    # ---- 2. 命中判定（Roll2RN，2 个乱数）----
    if not (attrs & _ATTR_SURESHOT):
        if not t.battle_roll2(config, f.get("hitRate", 100), True):
            attrs |= _ATTR_MISS
            st = t.state()
            return "0,%d,%d,%d,%d" % (attrs, st[0], st[1], st[2])

    attack = f.get("attack", 0)
    defense = f.get("defense", 0)

    # ---- 3. BattleCheckGreatShield（只有 GENERAL / GENERAL_F）----
    if not (attrs & (_ATTR_MISS | _ATTR_SURESHOT | _ATTR_PIERCE | _ATTR_GREATSHLD)):
        if defender_cls in (_CLS_GENERAL, _CLS_GENERAL_F):
            if t.battle_roll1(config, level, False):
                attrs |= _ATTR_GREATSHLD

    # ---- 4. BattleCheckPierce（翼骑士）----
    if not (attrs & (_ATTR_SURESHOT | _ATTR_PIERCE | _ATTR_GREATSHLD)):
        if attacker_cls in (_CLS_WYVERN_KNIGHT, _CLS_WYVERN_KNIGHT_F):
            if t.battle_roll1(config, level, False):
                attrs |= _ATTR_PIERCE

    if attrs & _ATTR_PIERCE:
        defense = 0

    damage = s16(attack - defense)
    if attrs & _ATTR_GREATSHLD:
        damage = 0

    # ---- 5. 必杀判定 + 6. 瞬杀判定（嵌在必杀内部）----
    if t.battle_roll1(config, f.get("critRate", 0), False):
        if defender_cls == _CLS_DEMON_KING:
            sil = False
        else:
            sil = t.battle_roll1(config, f.get("silencerRate", 0), False)
        if sil:
            attrs |= _ATTR_SILENCER
            damage = _MAX_DAMAGE
            attrs &= ~_ATTR_GREATSHLD
        else:
            attrs |= _ATTR_CRIT
            damage = damage * 3

    if damage > _MAX_DAMAGE:
        damage = _MAX_DAMAGE
    if damage < 0:
        damage = 0

    st = t.state()
    return "%d,%d,%d,%d,%d" % (damage, attrs, st[0], st[1], st[2])



# ------------------------------------------------ 场景: weapon_triangle

# 规则表从 carve 提取的 JSON 读，避免 Python 侧手抄一份
_REAVER = 1 << 8


def _load_triangle():
    import json as _json
    path = os.path.join(HERE, "..", "pipeline", "out", "tables",
                        "weapon_triangle.json")
    if not os.path.exists(path):
        return None
    d = _json.load(open(path, encoding="utf-8"))
    return [(r["attackerWeaponType"], r["defenderWeaponType"],
             r["hitBonus"], r["atkBonus"]) for r in d["rules"]]


_TRI = _load_triangle()


def model_weapon_triangle(f):
    if _TRI is None:
        return None
    fn = f.get("fn", "triangle")

    if fn == "hitrate":
        # ComputeBattleUnitHitRate:
        #   skl*2 + GetItemHit(weapon) + lck/2 + wTriangleHitBonus
        # 注意 lck/2 是 C 的向零截断除法
        return s16(s8(f.get("skl", 0)) * 2
                   + s8(f.get("itemHit", 0))
                   + c_trunc_div(s8(f.get("lck", 0)), 2)
                   + s8(f.get("wth", 0)))

    at_t = s8(f.get("atkType", 0))
    df_t = s8(f.get("defType", 0))
    at_hit = at_dmg = df_hit = df_dmg = 0

    for (a, d, h, k) in _TRI:
        if at_t == a and df_t == d:
            at_hit, at_dmg = h, k
            df_hit, df_dmg = -h, -k
            break

    at_attr = f.get("atkAttr", 0)
    df_attr = f.get("defAttr", 0)
    both = (at_attr & _REAVER) and (df_attr & _REAVER)
    if not both:
        if at_attr & _REAVER:
            at_hit, at_dmg = -at_hit * 2, -at_dmg * 2
            df_hit, df_dmg = -df_hit * 2, -df_dmg * 2
        if df_attr & _REAVER:
            at_hit, at_dmg = -at_hit * 2, -at_dmg * 2
            df_hit, df_dmg = -df_hit * 2, -df_dmg * 2

    return "%d,%d,%d,%d" % (s8(at_hit), s8(at_dmg), s8(df_hit), s8(df_dmg))



# ------------------------------------------------ 场景: phase

# 逐条对照 src/bmphase.c
_US_UNSEL, _US_DEAD, _US_NOTDEP, _US_RESCUED, _US_ROOF, _US_B16 = (
    1 << 1, 1 << 2, 1 << 3, 1 << 5, 1 << 7, 1 << 16)
_CA_UNSEL = 1 << 20
_NOT_ABLE = _US_UNSEL | _US_DEAD | _US_NOTDEP | _US_RESCUED | _US_ROOF | _US_B16


def _parse_phase_units(spec):
    """解析 `<id>=<state>:<status>:<classAttr>:<valid>` 列表 → {id: tuple}"""
    units = {}
    if not spec:
        return units
    for p in spec.split(","):
        if "=" not in p:
            continue
        k, v = p.split("=", 1)
        f = v.split(":")
        if len(f) < 4:
            continue
        units[int(k)] = (int(f[0]), int(f[1]), int(f[2]), f[3] != "0")
    return units


def model_phase(f):
    fn = f.get("fn", "abled")

    if fn == "allied":
        return 1 if (f.get("left", 0) & 0x80) == (f.get("right", 0) & 0x80) else 0
    if fn == "allegiance":
        return 1 if (f.get("left", 0) & 0xC0) == (f.get("right", 0) & 0xC0) else 0
    if fn == "current":
        return f.get("faction", 0) & 0x80
    if fn == "nonactive":
        return (f.get("faction", 0) & 0x80) ^ 0x80

    units = _parse_phase_units(f.get("units", ""))
    faction = f.get("faction", 0)
    count = 0
    for uid in range(faction + 1, faction + 0x40):
        u = units.get(uid)
        if u is None:
            continue
        state, status, ca, valid = u
        if not valid:                       # UNIT_IS_VALID 要求 pCharacterData
            continue

        if fn == "instate":
            # ⚠️ 语义是"**不处于**该状态"的单位数
            if state & f.get("state", 0) == 0:
                count += 1
            continue

        if state & _NOT_ABLE:
            continue
        if status in (2, 4):                # SLEEP / BERSERK
            continue
        if ca & _CA_UNSEL:
            continue
        count += 1
    return count



# ------------------------------------------------ 场景: turn_switch

# 逐条对照 src/bm_080153B0.c 的 SwitchPhases
def model_turn_switch(f):
    faction = f.get("faction", 0)
    turn = f.get("turn", 1)
    steps = f.get("steps", 1)
    out = []
    for _ in range(steps):
        if faction == 0x00:
            faction = 0x80
        elif faction == 0x80:
            faction = 0x40
        elif faction == 0x40:
            faction = 0x00
            # ⚠️ 回合数只在 GREEN 绕回 BLUE 时递增，且有 999 上限
            if turn < 999:
                turn += 1
        out.append("%d,%d" % (faction, turn))
    return ";".join(out)



# ------------------------------------------------ 场景: effective_hit

# 逐条对照 src/bmbattle_0802ABD0.c / src/bmbattle.c / src/GetBattleUnitHitCount.c
_CA_BOSS = 1 << 15
_CA_NEGATE_LETHALITY = 1 << 24
_CA_ASSASSIN = 1 << 25
_IA_BRAVE = 1 << 5
_FOLLOWUP_THRESHOLD = 4
_WPN_EFFECT_HPHALVE = 3
_ITEM_MONSTER_STONE = 0xB5


def model_effective_hit(f):
    fn = f.get("fn", "effhit")

    if fn == "effhit":
        # ⚠️ 上限 100 —— 漏掉它，120 的命中率会一路传进 Roll2RN
        v = s16(f.get("hitRate", 0)) - s16(f.get("avoidRate", 0))
        if v > 100:
            v = 100
        if v < 0:
            v = 0
        return s16(v)

    if fn == "silencer":
        if not (f.get("atkCA", 0) & _CA_ASSASSIN):
            return 0
        rate = 50
        if f.get("defCA", 0) & _CA_BOSS:
            rate = 25
        if f.get("defCA", 0) & _CA_NEGATE_LETHALITY:
            rate = 0
        return rate

    if fn == "hitcount":
        return 1 << (1 if (f.get("wepAttr", 0) & _IA_BRAVE) else 0)

    # followup
    a_spd = s16(f.get("atkSpd", 0))
    d_spd = s16(f.get("defSpd", 0))

    if d_spd > 250:
        return 0
    if abs(a_spd - d_spd) < _FOLLOWUP_THRESHOLD:
        return 0

    side = 1 if a_spd > d_spd else 2
    if f.get("wepEffect", 0) == _WPN_EFFECT_HPHALVE:
        return 0
    if (f.get("weapon", 1) & 0xFF) == _ITEM_MONSTER_STONE:
        return 0
    return side


MODELS = {
    "rng": (model_rng, True),          # True = 结果是列表
    "battle_unit": (model_battle_unit, False),
    "unit_defense": (model_unit_defense, False),
    "crit_rate": (model_crit_rate, False),
    "battle_attack": (model_battle_attack, False),
    "battle_rng": (model_battle_rng, False),
    "weapon_triangle": (model_weapon_triangle, False),
    "phase": (model_phase, False),
    "turn_switch": (model_turn_switch, False),
    "effective_hit": (model_effective_hit, False),
}


# ---------------------------------------------------------------- 驱动

def read_cases(path):
    out = []
    with open(path, encoding="utf-8") as fh:
        for line in fh:
            line = line.rstrip("\n")
            if not line or line.startswith("#"):
                continue
            parts = line.split("\t")
            cid = parts[0]
            fields = {}
            for p in parts[1:]:
                if "=" in p:
                    k, v = p.split("=", 1)
                    fields[k] = int(v) if _is_int(v) else v
            out.append((cid, fields))
    return out


def _is_int(v):
    try:
        int(v, 0)
        return True
    except ValueError:
        return False


def read_expected(path):
    out = {}
    with open(path, encoding="utf-8") as fh:
        for line in fh:
            line = line.rstrip("\n")
            if not line or line.startswith("#"):
                continue
            cid, _, val = line.partition("\t")
            out[cid] = val
    return out


def main():
    only = sys.argv[1] if len(sys.argv) > 1 else None
    rc = 0
    grand = 0

    for name, (model, is_list) in MODELS.items():
        if only and name != only:
            continue
        cases = read_cases(os.path.join(VEC, f"{name}.cases.tsv"))
        expected = read_expected(os.path.join(VEC, f"{name}.expected.tsv"))

        bad = 0
        for cid, fields in cases:
            got = model(fields)
            got_s = ",".join(str(x) for x in got) if is_list else str(got)
            exp_s = expected.get(cid)
            if exp_s is None:
                print(f"  ✗ {name}:{cid} 缺少期望值")
                bad += 1
            elif got_s != exp_s:
                if bad < 5:
                    print(f"  ✗ {name}:{cid}\n      Python: {got_s}\n      C     : {exp_s}")
                bad += 1

        grand += len(cases)
        if bad == 0:
            print(f"  ✓ {name:16s} {len(cases):4d} 条全部一致")
        else:
            print(f"  ✗ {name:16s} {bad}/{len(cases)} 条不一致")
            rc = 1

    print()
    if rc == 0:
        print(f"交叉校验通过 —— C Oracle 与独立 Python 实现在 {grand} 条向量上完全一致")
    else:
        print("交叉校验失败 —— harness 管道可能有问题")
    return rc


if __name__ == "__main__":
    sys.exit(main())
