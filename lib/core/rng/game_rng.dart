// PORT OF: src/rng.c
//
// 乱数系统。1:1 移植，**不改变任何数值行为**。
//
// 为什么这个模块必须最先做、且必须逐位对齐：乱数的**消耗顺序**是全局共享状态。
// 战斗中每多消耗或少消耗一个 RN，后面所有命中/暴击/成长全部错位。所以它是
// "看起来对了但实际全错"的最高危模块。
//
// 本文件是纯 Dart，不依赖 Flutter / Flame —— 见 tools/verify/check_architecture.dart。

/// GBA `u16`
const int _u16Mask = 0xFFFF;

/// GBA `u32`
const int _u32Mask = 0xFFFFFFFF;

/// C 语言的取余语义：**向零截断**。
///
/// ⚠️ 这是移植里最经典的陷阱。Dart 的 `%` 对负数返回非负值（欧几里得语义），
/// 而 C 的 `%` 向零截断。`-1 % 7` 在 C 里是 `-1`，在 Dart 里是 `6`。
/// 只有负种子才会触发，但一旦触发后面全部错位。
int _cMod(int a, int b) => a - (a ~/ b) * b;

/// `src/rng.c` 的 `InitRN` 初值表
const List<int> _initTable = [
  0xA36E, 0x924E, 0xB784, 0x4F67, 0x8092, 0x592D, 0x8E70, 0xA794,
];

/// FE8 的乱数发生器。
///
/// 两套独立的机制，游戏里都在用：
///   * **LFSR**（`NextRN` 等）—— 大部分游戏逻辑
///   * **LCG**（`AdvanceGetLCGRNValue`）—— 少数地方（如升级成长）
class GameRng {
  final List<int> _seeds = [0, 0, 0];
  int _lcg = 0;

  /// 当前 LFSR 状态（存档用）
  List<int> get seeds => List.unmodifiable(_seeds);

  /// 当前 LCG 状态（存档用）
  int get lcgValue => _lcg;

  /// `NextRN` —— 16 位伪随机数，范围 0..65535
  int nextRn() {
    var rn = ((_seeds[1] << 11) + (_seeds[0] >> 5)) & _u16Mask;

    // state[2] 左移一位，并把 state[1] 的最高位"进位"进来
    _seeds[2] = (_seeds[2] * 2) & _u16Mask;
    if ((_seeds[1] & 0x8000) != 0) {
      _seeds[2] = (_seeds[2] + 1) & _u16Mask;
    }

    rn ^= _seeds[2];

    // 整个状态右移 16 位
    _seeds[2] = _seeds[1];
    _seeds[1] = _seeds[0];
    _seeds[0] = rn;

    return rn;
  }

  /// `InitRN` —— 用种子初始化 LFSR
  void initRn(int seed) {
    var mod = _cMod(seed, 7);

    _seeds[0] = _initTable[mod++ & 7];
    _seeds[1] = _initTable[mod++ & 7];
    _seeds[2] = _initTable[mod & 7];

    final skip = _cMod(seed, 23);
    if (skip > 0) {
      for (var i = skip; i != 0; i--) {
        nextRn();
      }
    }
  }

  /// `LoadRNState`
  void loadRnState(int s0, int s1, int s2) {
    _seeds[0] = s0 & _u16Mask;
    _seeds[1] = s1 & _u16Mask;
    _seeds[2] = s2 & _u16Mask;
  }

  /// `StoreRNState`
  (int, int, int) storeRnState() => (_seeds[0], _seeds[1], _seeds[2]);

  /// `NextRN_100` —— 0..99
  ///
  /// 注意 FE6 用的是 `NextRN() / (0x10000 / 100)`，因为整数除法会舍入，
  /// 有极小概率掷出 100。FE8 修掉了这个 bug，这里必须跟 FE8 一致。
  int nextRn100() => nextRn() * 100 ~/ 0x10000;

  /// `NextRN_N` —— 0..(max-1)
  int nextRnN(int max) => nextRn() * max ~/ 0x10000;

  /// `Roll1RN` —— 单 RN 判定，命中返回 true
  bool roll1Rn(int threshold) => threshold > nextRn100();

  /// `Roll2RN` —— 双 RN 取平均判定
  bool roll2Rn(int threshold) {
    final average = (nextRn100() + nextRn100()) ~/ 2;
    return threshold > average;
  }

  /// `SetLCGRNValue`
  void setLcgRnValue(int seed) => _lcg = seed & _u32Mask;

  /// `AdvanceGetLCGRNValue` —— 推进并取出 LCG 值
  ///
  /// 中间乘法会**溢出 32 位**，必须显式截断；否则 Dart 的 64 位整数会算出不同结果。
  int advanceGetLcgRnValue() {
    var rn = (_lcg * 4 + 2) & _u32Mask;
    rn = (rn * ((_lcg * 4 + 3) & _u32Mask)) & _u32Mask;
    _lcg = rn >> 2;
    return _lcg;
  }
}
