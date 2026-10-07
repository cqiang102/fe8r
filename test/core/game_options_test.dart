// 「設定」屏：规则层 + 数据层的判据。
//
// 出处：`src/Config_Loop_KeyHandler.c:30-120`（上下夹边界 / 左右调 `func` 改值 / B 关）、
//       `src/uiconfig.c:45+`（`GetGameOption` switch：选项 → `gPlaySt.config.<字段>`）、
//       `include/uiconfig.h:53`（`GAME_OPTION_ANIMATION = 0` ⇒ 枚举值 = 表下标）
import 'dart:convert';
import 'dart:io';

import 'package:fe8r/core/core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('上下夹在两端（源码：!= 0 / < maxOption-1 才动）', () {
    final s = GameOptionsState(options: [
      GameOptionState(msgId: 1, selectorCount: 2, value: 0),
      GameOptionState(msgId: 2, selectorCount: 2, value: 0),
    ]);
    gameOptionsKey(s, GameOptionsKey.up);
    expect(s.index, 0, reason: '已在顶端');
    gameOptionsKey(s, GameOptionsKey.down);
    expect(s.index, 1);
    gameOptionsKey(s, GameOptionsKey.down);
    expect(s.index, 1, reason: '源码 `< maxOption - 1` 才加 ⇒ 不倒扣、不循环');
  });

  test('★ 左右改值会**写进配置**（这就是"改了真生效"的规则层）', () {
    final cfg = GameConfigValues(initial: {'disableAutoEndTurns': 0});
    final s = GameOptionsState(
      options: [
        GameOptionState(
            msgId: 1, selectorCount: 2, value: 0, field: 'disableAutoEndTurns'),
      ],
      config: cfg,
    );
    gameOptionsKey(s, GameOptionsKey.right);
    expect(s.current!.value, 1);
    expect(cfg.get('disableAutoEndTurns'), 1, reason: '值必须落到配置字段上');
    expect(s.changes, 1);
    // 到顶再按右：**不发明循环**（handler 未逐行核对 ⇒ 夹边界）
    gameOptionsKey(s, GameOptionsKey.right);
    expect(s.current!.value, 1);
    expect(s.changes, 1, reason: '夹边界 ⇒ 没有变化就不该计数');
  });

  test('没有字段的选项：值保持 null（不编），左右也改不动', () {
    final s = GameOptionsState(options: [
      GameOptionState(msgId: 1, selectorCount: 4), // 例如 GAME_OPTION_ANIMATION
    ]);
    expect(s.current!.value, isNull);
    gameOptionsKey(s, GameOptionsKey.right);
    expect(s.current!.value, isNull);
    expect(s.changes, 0);
  });

  test('B 关屏；关掉后按键无效', () {
    final s = GameOptionsState(options: [
      GameOptionState(msgId: 1, selectorCount: 2, value: 0),
    ]);
    gameOptionsKey(s, GameOptionsKey.b);
    expect(s.closed, isTrue);
    gameOptionsKey(s, GameOptionsKey.down);
    expect(s.index, 0);
  });

  test('★ 数据层抽查：13 项显示顺序 + 自动结束回合的映射', () {
    final f = File('tools/pipeline/out/tables/game_options.json');
    if (!f.existsSync()) fail('缺少 ${f.path}（先跑 parse_game_options.py）');
    final d = jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
    expect((d['uiOrder'] as List).length, 13);
    expect(d['uiOrder'], [0, 5, 4, 1, 2, 10, 14, 11, 3, 12, 6, 7, 8]);
    final m = (d['optionToConfigField'] as Map).cast<String, dynamic>();
    Map<String, dynamic> asMap(dynamic v) => (v as Map).cast<String, dynamic>();
    final autoend = m.values.map(asMap).firstWhere(
        (v) => v['field'] == 'disableAutoEndTurns');
    expect(autoend['enum'], 'GAME_OPTION_AUTOEND_TURNS');
    // 下标 12：`include/uiconfig.h` 的枚举值（= 表下标）
    expect(asMap(m['12'])['field'], 'disableAutoEndTurns');
    expect((d['options'] as List).length, 17);
  });
}
