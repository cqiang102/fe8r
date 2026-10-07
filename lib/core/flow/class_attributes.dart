// PORT OF: include/bmunit.h:305-345（`enum { CA_NONE = 0, CA_MOUNTEDAID = (1 << 0), … }`）
//          以及 `src/data/data_classes.c` 里各职业的 `.attributes = CA_… | CA_…`
//          （由 `tools/pipeline/extract/parse_class_tables.py` 抽进 `classes.json`）
//
// # 职业属性位
//
// 这些位**影响真实规则**（不再用"职业名里有没有 CAVALIER"这种近似）：
//   * `CA_MOUNTEDAID` ⇒ `GetUnitAid` 走骑乘分支（`src/exact_080186cc.c:37-44`）；
//   * `CA_FEMALE`     ⇒ 骑乘 Aid 是 `20 - Con` 还是 `25 - Con`；
//   * `CA_THIEF`      ⇒ 撬锁器能开锁（`src/bmunit_080187B0.c:39-58`）；
//   * `CA_SUPPLY`     ⇒ 输送队，不能作为交换对象（`src/bmtarget_0802506C.c:95`）。
//
// ⚠️ 位值以 `include/bmunit.h` 为准，**不要手抄**：`CA_LOCK_4` 是 `1 << 28`
//（不是 1<<18 —— 我第 54 轮就是凭印象写了个错期望值，抽查当场把它抓出来了）。

/// `CA_*` 位（`include/bmunit.h:305-345`）
const int caNone = 0;
const int caMountedAid = 1 << 0;
const int caCanto = 1 << 1;
const int caSteal = 1 << 2;
const int caThief = 1 << 3;
const int caDance = 1 << 4;
const int caPlay = 1 << 5;
const int caBallistae = 1 << 7;
const int caPromoted = 1 << 8;
const int caSupply = 1 << 9;
const int caMounted = 1 << 10;
const int caWyvern = 1 << 11;
const int caPegasus = 1 << 12;
const int caLord = 1 << 13;
const int caFemale = 1 << 14;
const int caLock1 = 1 << 16;
const int caLock2 = 1 << 17;
const int caLock3 = 1 << 18;
const int caMaxLevel10 = 1 << 19;

/// 位名 → 位值（判据里按名字断言，别写魔数）
const Map<String, int> caBits = {
  'CA_NONE': caNone,
  'CA_MOUNTEDAID': caMountedAid,
  'CA_CANTO': caCanto,
  'CA_STEAL': caSteal,
  'CA_THIEF': caThief,
  'CA_DANCE': caDance,
  'CA_PLAY': caPlay,
  // `CA_CRITBONUS` 已在 `combat.dart` 里定义（同名常量），这里不重复声明 ——
  // 两处都导出的同名常量会让 barrel 变成 ambiguous_export（第 54 轮编译当场抓到）。
  'CA_CRITBONUS': 1 << 6,
  'CA_BALLISTAE': caBallistae,
  'CA_PROMOTED': caPromoted,
  'CA_SUPPLY': caSupply,
  'CA_MOUNTED': caMounted,
  'CA_WYVERN': caWyvern,
  'CA_PEGASUS': caPegasus,
  'CA_LORD': caLord,
  'CA_FEMALE': caFemale,
  // `CA_BOSS` 已在 `battle_unit.dart` 里定义（同名常量），这里不重复声明。
  'CA_BOSS': 1 << 15,
  'CA_LOCK_1': caLock1,
  'CA_LOCK_2': caLock2,
  'CA_LOCK_3': caLock3,
  'CA_MAXLEVEL10': caMaxLevel10,
};

/// 这个职业有没有某一位（`attributes` 来自 `classes.json`）
bool classHasAttribute(int attributes, int bit) => (attributes & bit) != 0;
