// `debugFlagBits` —— 纯观测辅助（第 7 轮加）
//
// 为什么它值得一条判据：它现在是**所有场景**转储的一部分，
// 而"看不到这几个位"正是第 5/6 轮把"改动没生效"误读成"回归"的原因
// （`docs/路线图.md` 112/113）。观测本身也要有判据，否则它会静默漂移。

import 'package:fe8r/core/core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('★ 键名与 map-menu 的 inputs 保持一致（同一批判据读它）', () {
    final ng = NewGamePlayFlags(NewGameDifficulty.normal);
    final m = debugFlagBits(ng, 'normal', checkTutorialSlotC: 0);
    // 这 4 个键名是**契约**：check_dump.dart 与场景判据都按名字读
    // ⚠️ 第 7 轮实测：原来叫 `tutorial` 会与主转储里的**同名键**（教学队列状态 map）
    //   静默撞车 ⇒ 取到的是那个 map。改成不会撞的 `playFlagTutorial`。
    expect(m.keys.toSet(), {
      'difficulty',
      'playFlagTutorial',
      'tutorialMode',
      'guideLocked',
      'checkTutorialSlotC'
    });
    expect(m['difficulty'], 'normal');
    expect(m['checkTutorialSlotC'], 0);
  });

  test('★ 难度没选时给的是"（还没选）"，不是 null（免得看着像"没生效"）', () {
    final ng = NewGamePlayFlags(NewGameDifficulty.easy);
    expect(debugFlagBits(ng, null)['difficulty'], '（还没选）');
  });

  test('★ 三个位与 `NewGamePlayFlags` 一致（不在这里另算一遍）', () {
    for (final d in NewGameDifficulty.values) {
      final ng = NewGamePlayFlags(d);
      final m = debugFlagBits(ng, d.name);
      expect(m['playFlagTutorial'], ng.playFlagTutorial, reason: '$d');
      expect(m['tutorialMode'], ng.isTutorialMode, reason: '$d');
      expect(m['guideLocked'], ng.guideLocked, reason: '$d');
    }
  });
}
