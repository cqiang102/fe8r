// M4A 指令表（第 17 轮）—— 出处是**美版**的 carve（日版是 incbin，读不到函数名）
//
// ★ 判据：36 条、下标即指令号、且**运行时覆盖**那 8 条必须标出来
//   （尤其下标 8：模板写 `ply_fine`，但 `MPlayExtender` 覆盖成 `ply_memacc`
//    ⇒ MEMACC 的真处理函数是初始化时装上的）。

import 'package:fe8r/core/core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('★ 36 条，下标与列表位置一致（下标即指令号）', () {
    expect(MPlayCommands.count, 36);
    expect(MPlayCommands.table.length, 36);
    for (var i = 0; i < MPlayCommands.table.length; i++) {
      expect(MPlayCommands.table[i].index, i, reason: '第 $i 项');
    }
  });

  test('★ 模板逐条对上 `src/m4a_tables.c:6-42`', () {
    const expectHandlers = [
      'ply_fine', 'ply_goto', 'ply_patt', 'ply_pend', 'ply_rept',
      'ply_fine', 'ply_fine', 'ply_fine', 'ply_fine', 'ply_prio',
      'ply_tempo', 'ply_keysh', 'ply_voice', 'ply_vol', 'ply_pan',
      'ply_bend', 'ply_bendr', 'ply_lfos', 'ply_lfodl', 'ply_mod',
      'ply_modt', 'ply_fine', 'ply_fine', 'ply_tune', 'ply_fine',
      'ply_fine', 'ply_fine', 'ply_port', 'ply_fine', 'ply_endtie',
      'SampleFreqSet', 'TrackStop', 'FadeOutBody', 'TrkVolPitSet',
      'RealClearChain', 'SoundMainBTM',
    ];
    expect([for (final c in MPlayCommands.table) c.handler], expectHandlers);
  });

  test('★ 运行时覆盖 8 条（`MPlayExtender`，`src/m4a.c:265-272`）', () {
    final overrides = {
      for (final c in MPlayCommands.table)
        if (c.override != null) c.index: c.override
    };
    expect(overrides, {
      8: 'ply_memacc', 17: 'ply_lfos', 19: 'ply_mod', 28: 'ply_xcmd',
      29: 'ply_endtie', 30: 'SampleFreqSet', 31: 'TrackStop', 32: 'FadeOutBody',
    });
    // 下标 8 的**生效值**是覆盖后的（这条最容易踩）
    expect(MPlayCommands.table[8].handler, 'ply_fine', reason: '模板里是 fine');
    expect(MPlayCommands.table[8].effective, 'ply_memacc', reason: '生效的是 memacc');
  });

  test('★ M4A 命令名的位置（音序器按这些下标分派）', () {
    for (final (idx, name) in [
      (10, 'ply_tempo'), (12, 'ply_voice'), (13, 'ply_vol'), (14, 'ply_pan'),
      (1, 'ply_goto'), (4, 'ply_rept'), (2, 'ply_patt'), (3, 'ply_pend'),
    ]) {
      expect(MPlayCommands.table[idx].effective, name, reason: '下标 $idx');
    }
  });
}
