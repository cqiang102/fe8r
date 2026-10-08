// PORT OF: src/m4a_tables.c:6-42（**美版**的 `gMPlayJumpTableTemplate`，36 条）
//          + src/m4a.c:236-275（`MPlayExtender` 里的**运行时覆盖**）
//          + src/m4a_1.s:934-1262（`MPlayMain` 用它按指令号分派）
//
// ⚠️ 为什么用美版：**日版的这张表是 incbin**（条目是 JP 偏移地址，
//   `src/m4a_tables.c:8-9` 自述 "stay region-different incbin"）⇒ 读不到函数名；
//   美版把它 carve 成了 C，**逐条写着处理函数名** ⇒ 正是"结合美版"该用的地方。
//
// ★ 一条容易踩的坑：模板里**下标 8 是 `ply_fine`**，但 `MPlayExtender`
//   在初始化时把它**覆盖**成 `ply_memacc` ⇒ **MEMACC 的真正处理函数是运行时装上的**。
//   `ply_xcmd`（下标 28）同理。

/// M4A 的一条指令（跳转表的一项）
class MPlayCommand {
  const MPlayCommand(this.index, this.handler, {this.override});

  /// 指令号 = 跳转表下标（音序器按它分派）
  final int index;

  /// 模板里的处理函数名（`src/m4a_tables.c`）
  final String handler;

  /// `MPlayExtender` 在初始化时的**覆盖**（没有就为 null）
  final String? override;

  /// 实际生效的处理函数
  String get effective => override ?? handler;
}

/// `gMPlayJumpTableTemplate` 的 36 项，**顺序照抄**（下标即指令号）
///
/// 名字含义（M4A 命令名）：`ply_fine` = FINE（结束）✓、`ply_goto` = GOTO ✓、
/// `ply_patt` = PATT ✓、`ply_pend` = PEND ✓、`ply_rept` = REPT ✓、
/// `ply_prio` = PRIO ✓、`ply_tempo` = TEMPO ✓、`ply_keysh` = KEYSH ✓、
/// `ply_voice` = VOICE ✓、`ply_vol` = VOL ✓、`ply_pan` = PAN ✓、
/// `ply_bend` = BEND ✓、`ply_bendr` = BENDR ✓、`ply_lfos` = LFOS ✓、
/// `ply_lfodl` = LFODL ✓、`ply_mod` = MOD ✓、`ply_modt` = MODT ✓、
/// `ply_tune` = TUNE ✓、`ply_port` = PORT ✓、`ply_endtie` = ENDTIE ✓。
abstract final class MPlayCommands {
  /// 0..7 里 5/6/7 是 `ply_fine`（模板如此，**不是**我省略的）
  static const List<MPlayCommand> table = [
    MPlayCommand(0, 'ply_fine'),
    MPlayCommand(1, 'ply_goto'),
    MPlayCommand(2, 'ply_patt'),
    MPlayCommand(3, 'ply_pend'),
    MPlayCommand(4, 'ply_rept'),
    MPlayCommand(5, 'ply_fine'),
    MPlayCommand(6, 'ply_fine'),
    MPlayCommand(7, 'ply_fine'),
    // ★ 模板是 ply_fine，但 MPlayExtender 覆盖成 ply_memacc（MEMACC 的真处理函数）
    MPlayCommand(8, 'ply_fine', override: 'ply_memacc'),
    MPlayCommand(9, 'ply_prio'),
    MPlayCommand(10, 'ply_tempo'),
    MPlayCommand(11, 'ply_keysh'),
    MPlayCommand(12, 'ply_voice'),
    MPlayCommand(13, 'ply_vol'),
    MPlayCommand(14, 'ply_pan'),
    MPlayCommand(15, 'ply_bend'),
    MPlayCommand(16, 'ply_bendr'),
    MPlayCommand(17, 'ply_lfos', override: 'ply_lfos'),
    MPlayCommand(18, 'ply_lfodl'),
    MPlayCommand(19, 'ply_mod', override: 'ply_mod'),
    MPlayCommand(20, 'ply_modt'),
    MPlayCommand(21, 'ply_fine'),
    MPlayCommand(22, 'ply_fine'),
    MPlayCommand(23, 'ply_tune'),
    MPlayCommand(24, 'ply_fine'),
    MPlayCommand(25, 'ply_fine'),
    MPlayCommand(26, 'ply_fine'),
    MPlayCommand(27, 'ply_port'),
    // ★ 模板是 ply_fine，MPlayExtender 覆盖成 ply_xcmd
    MPlayCommand(28, 'ply_fine', override: 'ply_xcmd'),
    MPlayCommand(29, 'ply_endtie', override: 'ply_endtie'),
    MPlayCommand(30, 'SampleFreqSet', override: 'SampleFreqSet'),
    MPlayCommand(31, 'TrackStop', override: 'TrackStop'),
    MPlayCommand(32, 'FadeOutBody', override: 'FadeOutBody'),
    MPlayCommand(33, 'TrkVolPitSet'),
    MPlayCommand(34, 'RealClearChain'),
    MPlayCommand(35, 'SoundMainBTM'),
  ];

  /// 指令数（`gMPlayJumpTable[36]`，`src/m4a.c:10`）
  static const int count = 36;
}
