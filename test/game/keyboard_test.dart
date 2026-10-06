// 真实键盘路径的测试。
//
// ## 为什么必须有这条
//
// 键盘曾经**完全无效**：`main.dart` 用外层 `Focus(onKeyEvent:)` 接键，
// 而 `GameWidget` 内部有自己的 FocusNode（autofocus 默认 true）会抢走主焦点，
// 它的处理是"游戏没混 `KeyboardEvents` 就 `return handled`" —— 吞掉一切。
// 而 Flutter 的派发是"主焦点 → 祖先，遇到非 ignored 就停"，
// 所以外层回调**永远不会被调用**。
//
// 这个 bug 藏了很久，因为**视觉验证全走 `FE8R_SCRIPT` 直接注入输入**，
// 从没经过真实键盘路径。教训：验证脚本绕过的路径，等于没验证。
import 'package:fe8r/game/fe8_game.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('真实按键能到达游戏（不再被 GameWidget 的 FocusNode 吞掉）',
      (tester) async {
    final game = Fe8Game();
    final got = <String>[];
    game.onInputForTest = (i) => got.add(i.name);

    await tester.pumpWidget(MaterialApp(home: GameWidget(game: game)));
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(got, isNotEmpty,
        reason: '按键必须到达游戏 —— 空了说明又回到"被 FocusNode 吞掉"的状态');

    await tester.sendKeyEvent(LogicalKeyboardKey.keyZ);
    await tester.pump();
    expect(got, contains('confirm'));
  });
}
