// 分层棘轮（第 106 轮定下的方向：先把逻辑搬进 `lib/core`，UI 后置）
//
// 背景（实测）：`lib/core`（纯规则）60 个文件 / 38109 行、80 个测试文件；
// 而 `lib/game/fe8_game.dart` **一个文件 7488 行**，占了 game 层 68%。
// 三次实测（第 87 / 101 / 106 轮）：我以为"未实现"的功能，
// 都在这个文件里找到了已经做好的实现 ⇒ **逻辑挤在这里**是真正的障碍。
//
// 所以这条棘轮**只许降**：每把一块逻辑搬进 `lib/core`（并给它配核心测试），
// 就把下面的数字改小。和占位符棘轮同一个套路。
//
// ⚠️ 为什么用"行数"这种粗指标：它是**可复核**的、不需要人来判断
//    "这算不算逻辑"。粗，但不会骗人 —— 而且它只用来**防止变大**。

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('★ `fe8_game.dart` 的规模只许降（搬走逻辑后把基线改小）', () {
    final f = File('lib/game/fe8_game.dart');
    expect(f.existsSync(), isTrue);
    final lines = f.readAsLinesSync().length;
    const baseline = 7488; // ← 第 106 轮实测；搬走一块就改小
    expect(lines, lessThanOrEqualTo(baseline),
        reason: '逻辑应当搬进 `lib/core`（带 PORT OF 与测试），而不是继续堆在这个文件里；'
            '当前 $lines 行、基线 $baseline 行。'
            '⚠️ 如果你**确实**在 core 里加了逻辑而这里只是引用了新接口，'
            '可以把基线改小（只许改小，不许改大）。');
  });
}
