// 事件引擎（指令编码 + 虚拟机）的测试。
//
// 指令集常量与**位打包规则**由 C 编译器复核
// （tools/pipeline/extract/verify_eventscript.py：
//  150 条指令 / 161 个子命令 / `_EvtCmd` 宏展开值）。
//
// 这里验证的是引擎本身：
//   1. 指令解码/编码往返一致，长度按 **u16 字** 算
//   2. 控制流：goto / call-return / branch / stall
//   3. **完全可序列化**（剧情演到一半能存档）
//   4. 遇到未实现指令**立刻报错**，不静默跳过
import 'dart:convert';
import 'dart:io';

import 'package:fe8r/core/core.dart';
import 'package:flutter_test/flutter_test.dart';

/// 按 `_EvtCmd` 宏打包一个字
int w(int cmd, int len, int sub) =>
    ((cmd & 0xFF) << 8) | ((len & 0xF) << 4) | (sub & 0xF);

/// 一条 `len` 字指令：[w0, arg0, arg1, ...]
List<int> ins(int cmd, int len, int sub, [List<int> args = const []]) {
  final out = [w(cmd, len, sub)];
  for (var i = 1; i < len; i++) {
    out.add(i - 1 < args.length ? (args[i - 1] & 0xFFFF) : 0);
  }
  return out;
}

List<int> script(List<List<int>> parts) => [for (final p in parts) ...p];

void main() {
  group('指令编码（位打包）', () {
    test('编码位置：opcode<<8 | len<<4 | sub', () {
      expect(w(0x00, 2, 0), 0x0020, reason: 'EvtNop');
      expect(w(0x01, 2, 1), 0x0121, reason: 'EvtEndAll');
      expect(w(0x09, 2, 0), 0x0920, reason: 'EvtGoto');
      expect(w(0x0A, 4, 0), 0x0A40, reason: 'EvtCall 是 4 个字');
    });

    test('解码后能拿到 opcode / 长度 / 子命令 / 参数', () {
      final s = EventScript.decode(script([
        ins(0x09, 2, 0, [12]), // goto 12
        ins(0x00, 2, 0), // nop
      ]));
      expect(s.instructions.length, 2);
      final g = s.instructions[0];
      expect(g.opcode, 0x09);
      expect(g.length, 2);
      expect(g.subCommand, 0);
      expect(g.args, [12]);
      expect(g.offset, 0);
      expect(s.instructions[1].offset, 2, reason: '偏移按**字**累加，不是字节');
    });

    test('参数按 s16 解释（负数正确）', () {
      final s = EventScript.decode(ins(0x05, 3, 0, [1, -1]));
      expect(s.instructions[0].args, [1, -1]);
    });

    test('编码往返一致', () {
      final words = script([
        ins(0x05, 3, 0, [0, 42]),
        ins(0x0E, 2, 0, [5]),
        ins(0x01, 2, 1),
      ]);
      final s = EventScript.decode(words);
      final back = [for (final i in s.instructions) ...i.encode()];
      expect(back, words);
    });

    test('长度为 0 的指令会报错（否则执行器原地打转）', () {
      expect(
        () => EventScript.decode([w(0x00, 0, 0), 0]),
        throwsA(isA<FormatException>()),
      );
    });

    test('长度超出脚本末尾会报错', () {
      // 手工造一个**被截断**的流：声明 4 个字，实际只给 2 个。
      // 不能用 ins(0x0A, 4, 0, [0]) —— 那个 helper 会补齐到 4 个字，
      // 是一条合法指令（我第一版就是这么写错的）。
      expect(
        () => EventScript.decode([w(0x0A, 4, 0), 0]),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('控制流', () {
    EventVmState fresh(List<int> words) =>
        EventVmState(script: EventScript.decode(words));

    test('顺序执行直到 END', () {
      final vm = EventVm();
      final st = fresh(script([
        ins(0x00, 2, 0), // nop
        ins(0x00, 2, 0), // nop
        ins(0x01, 2, 1), // end all
      ]));
      final steps = vm.run(st);
      expect(steps.length, 3);
      expect(st.done, isTrue);
    });

    test('GOTO 跳到指定字偏移', () {
      final vm = EventVm();
      // 0: goto 6     (2 字)
      // 2: nop        (2 字)  ← 应当被跳过
      // 4: nop        (2 字)  ← 应当被跳过
      // 6: end all    (2 字)
      final st = fresh(script([
        ins(0x09, 2, 0, [6]),
        ins(0x00, 2, 0),
        ins(0x00, 2, 0),
        ins(0x01, 2, 1),
      ]));
      final steps = vm.run(st);
      expect(steps.length, 2, reason: 'goto 之后直接到 end，中间两条 nop 不该执行');
      expect(st.done, isTrue);
    });

    test('CALL / END(A) 成对：调用后能返回', () {
      final vm = EventVm();
      // 0: call 6     (2 字)
      // 2: nop        (2 字)  ← 返回点
      // 4: end all    (2 字)
      // 6: nop        (2 字)  ← 被调用
      // 8: end(A)     (2 字)  ← 返回
      final st = fresh(script([
        ins(0x0A, 2, 0, [6]),
        ins(0x00, 2, 0),
        ins(0x01, 2, 1),
        ins(0x00, 2, 0),
        ins(0x01, 2, 0), // EVSUBCMD_ENDA
      ]));
      vm.run(st);
      expect(st.done, isTrue);
      expect(st.callStack, isEmpty, reason: '返回后栈应当空了');
    });

    test('END(A) 在空栈时结束整个脚本', () {
      final vm = EventVm();
      final st = fresh(ins(0x01, 2, 0));
      vm.run(st);
      expect(st.done, isTrue);
    });

    test('STALL 会暂停推进', () {
      final vm = EventVm();
      final st = fresh(script([
        ins(0x0E, 2, 0, [3]), // stall 3
        ins(0x00, 2, 0),
        ins(0x01, 2, 1),
      ]));
      final first = vm.step(st)!;
      expect(first.note, contains('等待 3 帧'));
      expect(st.stallTimer, 3);

      // 接下来 3 次 step 都只是在减计数
      for (var i = 0; i < 3; i++) {
        final s = vm.step(st)!;
        expect(s.advanced, isFalse);
        expect(s.instruction, isNull);
      }
      expect(st.stallTimer, 0);
      // 计数归零后才继续执行
      final s = vm.step(st)!;
      expect(s.advanced, isTrue);
    });

    test('BRANCH 按条件跳转（六种比较）', () {
      // 布局（按**字**算偏移，注意 SVAL 占 3 字、BRANCH 占 4 字）：
      //   @0  SVAL slot1 = a          (3 字)
      //   @3  BRANCH sub [1, b, 11]   (4 字) → 跳转目标 @11
      //   @7  NOP                     (2 字) ← **只有不跳转时才会执行**
      //   @9  END all                 (2 字)
      //   @11 END all                 (2 字)
      // 判据用"@7 这条 NOP 有没有被执行"，比看最终 PC 可靠：
      // 两条路径都结束在 END，最终 PC 一样。
      List<int> build(int a, int b, int sub) => script([
            ins(0x05, 3, 0, [1, a]),
            ins(0x0C, 4, sub, [1, b, 11]),
            ins(0x00, 2, 0), // @7 只有不跳转才走到
            ins(0x01, 2, 1),
            ins(0x01, 2, 1),
          ]);

      for (final (sub, a, b, expectTaken) in [
        (BranchSubCommand.eq, 5, 5, true),
        (BranchSubCommand.eq, 5, 6, false),
        (BranchSubCommand.ne, 5, 6, true),
        (BranchSubCommand.ne, 5, 5, false),
        (BranchSubCommand.ge, 5, 5, true),
        (BranchSubCommand.ge, 4, 5, false),
        (BranchSubCommand.gt, 6, 5, true),
        (BranchSubCommand.gt, 5, 5, false),
        (BranchSubCommand.le, 5, 5, true),
        (BranchSubCommand.le, 6, 5, false),
        (BranchSubCommand.lt, 4, 5, true),
        (BranchSubCommand.lt, 5, 5, false),
      ]) {
        final vm = EventVm();
        final st = EventVmState(script: EventScript.decode(build(a, b, sub)));
        final steps = vm.run(st);
        expect(st.done, isTrue);

        final visited = steps
            .map((e) => e.instruction?.offset)
            .whereType<int>()
            .toSet();
        expect(visited.contains(7), !expectTaken,
            reason: 'sub=$sub a=$a b=$b 期望 take=$expectTaken，'
                '访问过的偏移=$visited');
      }
    });

    test('PC 落不到指令上时报错（不静默结束）', () {
      final vm = EventVm();
      final st = fresh(script([
        ins(0x09, 2, 0, [3]), // 跳到字 3 —— 落在一半的位置
        ins(0x01, 2, 1),
      ]));
      expect(() => vm.run(st), throwsA(isA<StateError>()));
    });

    test('未实现的指令立刻报错，不静默跳过', () {
      final vm = EventVm();
      final st = fresh(script([
        ins(0x12, 2, 0), // EV_CMD_BGMCHANGE_12 —— 未实现
        ins(0x01, 2, 1),
      ]));
      expect(() => vm.run(st), throwsA(isA<UnimplementedError>()));
    });
  });

  group('插槽与事件位', () {
    EventVmState fresh(List<int> words) =>
        EventVmState(script: EventScript.decode(words));

    test('SVAL 设置插槽，SLOT_OPS 做算术', () {
      final vm = EventVm();
      final st = fresh(script([
        ins(0x05, 3, 0, [1, 10]), // slot1 = 10
        ins(0x05, 3, 0, [2, 3]), // slot2 = 3
        ins(0x06, 4, SlotOpSubCommand.add, [1, 2]), // slot1 += slot2
        ins(0x06, 4, SlotOpSubCommand.mul, [1, 2]), // slot1 *= slot2
        ins(0x01, 2, 1),
      ]));
      vm.run(st);
      expect(st.slots[1], (10 + 3) * 3);
    });

    test('插槽运算除零会报错（而不是给个 0）', () {
      final vm = EventVm();
      final st = fresh(script([
        ins(0x05, 3, 0, [2, 0]), // slot2 = 0
        ins(0x06, 4, SlotOpSubCommand.div, [1, 2]),
        ins(0x01, 2, 1),
      ]));
      expect(() => vm.run(st), throwsA(isA<StateError>()));
    });

    test('EVSET 置位 / 清位，EVCHECK 把结果写进插槽 0', () {
      final vm = EventVm();
      final st = fresh(script([
        ins(0x02, 2, EvSetSubCommand.setEventBit, [7]), // 置位 7
        ins(0x03, 2, 0, [7]), // 检查 7
        ins(0x01, 2, 1),
      ]));
      vm.run(st);
      expect(st.eventBits[7], isTrue);
      expect(st.slots[0], 1);

      final st2 = fresh(script([
        ins(0x02, 2, EvSetSubCommand.clearEventBit, [7]),
        ins(0x03, 2, 0, [7]),
        ins(0x01, 2, 1),
      ]));
      EventVm().run(st2);
      expect(st2.slots[0], 0);
    });
  });

  group('表现类指令（对话 / 立绘 / 背景）', () {
    EventVmState fresh(List<int> words, {Map<int, String>? texts}) =>
        EventVmState(script: EventScript.decode(words));

    test('DISPLAYTEXT 显示文字并等玩家按键', () {
      final vm = EventVm(textTable: {7: '艾莉卡：我们上！'});
      final st = fresh(script([
        ins(0x1B, 2, TextShowSubCommand.show, [7]),
        ins(0x01, 2, 1),
      ]));
      final s0 = vm.step(st)!;
      expect(st.presentation.textBoxVisible, isTrue);
      expect(st.presentation.textId, 7);
      expect(st.lastText, '艾莉卡：我们上！');
      expect(st.waitingForPlayer, isTrue, reason: '显示文字后应当等玩家');
      expect(s0.text, '艾莉卡：我们上！');

      // 等玩家期间不推进
      final s1 = vm.step(st)!;
      expect(s1.advanced, isFalse);
      expect(s1.note, '等玩家按键');

      // 按键后继续
      expect(vm.advanceFromPlayerInput(st), isTrue);
      expect(st.waitingForPlayer, isFalse);
      final s2 = vm.step(st)!;
      expect(s2.instruction?.opcode, EventOpcodes.end);
    });

    test('文本编号 0 是哨兵：不显示也不等待', () {
      final vm = EventVm();
      final st = fresh(script([
        ins(0x1B, 2, TextShowSubCommand.show, [0]),
        ins(0x01, 2, 1),
      ]));
      vm.run(st);
      expect(st.waitingForPlayer, isFalse, reason: '编号 0 不该让流程卡住');
      expect(st.done, isTrue);
    });

    test('负数文本编号取插槽 2 的值', () {
      final vm = EventVm(textTable: {42: '来自插槽'});
      final st = fresh(script([
        ins(0x05, 3, 0, [2, 42]), // slot2 = 42
        ins(0x1B, 2, TextShowSubCommand.show, [-1]),
        ins(0x01, 2, 1),
      ]));
      vm.step(st); // SVAL
      vm.step(st); // DISPLAYTEXT
      expect(st.presentation.textId, 42);
      expect(st.lastText, '来自插槽');
    });

    test('REMA 关闭文字框且不等玩家', () {
      final vm = EventVm(textTable: {1: 'x'});
      final st = fresh(script([
        ins(0x1B, 2, TextShowSubCommand.show, [1]),
        ins(0x1B, 2, TextShowSubCommand.removeAll, [0]),
        ins(0x01, 2, 1),
      ]));
      vm.step(st); // 显示
      vm.advanceFromPlayerInput(st);
      vm.step(st); // REMA
      expect(st.presentation.textBoxVisible, isFalse);
      expect(st.waitingForPlayer, isFalse);
    });

    test('DISPLAYFACE 把子命令当槽位、参数当脸编号', () {
      final vm = EventVm();
      final st = fresh(script([
        ins(0x1E, 2, 0, [12]), // 槽 0 = 脸 12
        ins(0x1E, 2, 1, [34]), // 槽 1 = 脸 34
        ins(0x01, 2, 1),
      ]));
      vm.run(st);
      expect(st.presentation.faces[0], 12);
      expect(st.presentation.faces[1], 34);
    });

    test('SHOWBG 设背景；CLEARSCREEN 清掉背景与立绘', () {
      final vm = EventVm();
      final st = fresh(script([
        ins(0x21, 4, ShowBgSubCommand.display, [5, 0]),
        ins(0x1E, 2, 0, [9]),
        ins(0x22, 2, 0), // CLEARSCREEN
        ins(0x01, 2, 1),
      ]));
      vm.run(st);
      expect(st.presentation.backgroundId, isNull);
      expect(st.presentation.faces, isEmpty);
    });

    test('SETTEXTTYPE 切换样式；REMOVEPORTRAITS 会清立绘', () {
      final vm = EventVm();
      final st = fresh(script([
        ins(0x1E, 2, 0, [9]),
        ins(0x1A, 2, TextTypeSubCommand.removePortraits, [0]),
        ins(0x01, 2, 1),
      ]));
      vm.run(st);
      expect(st.presentation.textType, TextTypeSubCommand.removePortraits);
      expect(st.presentation.faces, isEmpty);
    });

    test('一段完整的对话场景能跑完', () {
      final vm = EventVm(textTable: {10: '第一句', 11: '第二句'});
      final st = fresh(script([
        ins(0x21, 4, ShowBgSubCommand.display, [3, 0]), // 背景
        ins(0x1E, 2, 0, [7]), // 立绘
        ins(0x1B, 2, TextShowSubCommand.show, [10]),
        ins(0x1B, 2, TextShowSubCommand.show, [11]),
        ins(0x1B, 2, TextShowSubCommand.removeAll, [0]),
        ins(0x22, 2, 0), // 清屏
        ins(0x01, 2, 1),
      ]));

      // 每帧推一次，遇到"等玩家"就按键
      var guard = 0;
      final seen = <String>[];
      while (!st.done && guard++ < 100) {
        final before = st.pc;
        vm.run(st);
        if (st.lastText.isNotEmpty && st.pc != before) seen.add(st.lastText);
        if (st.waitingForPlayer) vm.advanceFromPlayerInput(st);
      }
      expect(st.done, isTrue, reason: '循环 $guard 次仍未结束');
      expect(seen, contains('第一句'));
      expect(seen, contains('第二句'));
      expect(st.presentation.backgroundId, isNull, reason: '最后清屏了');
    });
  });

  group('单位移动与镜头', () {
    EventVmState fresh(List<int> words) =>
        EventVmState(script: EventScript.decode(words));

    test('子命令字段拆成低 3 位 + 第 3 位', () {
      // 原版把 MOVEUNIT 的子命令打包成 `EVSUBCMD_MOVE | (modify << 3)`。
      // modify=1 时 4 位的值是 8，但**真实子命令仍是 0（MOVE）**。
      final s = EventScript.decode(ins(0x2F, 4, 0 | (1 << 3), [1, 2, 0]));
      final i = s.instructions[0];
      expect(i.subCommand, 8);
      expect(i.subCommandLow, MoveUnitSubCommand.move,
          reason: '直接用 subCommand 会得到 8，把它当成子命令就错了');
      expect(i.subCommandHigh, 1);
    });

    test('MOVEUNIT/MOVE 解析打包的 (x, y)', () {
      final vm = EventVm();
      // 目标是 (7, 3)：packed = 7 | (3 << 8)
      final st = fresh(ins(0x2F, 4, MoveUnitSubCommand.move, [1, 5, 7 | (3 << 8)]));
      vm.step(st);
      expect(st.pendingMoves.length, 1);
      final m = st.pendingMoves.single;
      expect(m.unitId, 5);
      expect(m.toX, 7);
      expect(m.toY, 3);
      expect(m.targetMode, MoveTargetMode.absolute);
      expect(st.waitingForMove, isTrue);
    });

    test('负数速度表示瞬移', () {
      final vm = EventVm();
      final st = fresh(ins(0x2F, 4, MoveUnitSubCommand.move, [-1, 5, 2 | (2 << 8)]));
      vm.step(st);
      expect(st.pendingMoves.single.instant, isTrue);
    });

    test('MOVEONTO 把第二参数当作目标单位', () {
      final vm = EventVm();
      final st = fresh(ins(0x2F, 4, MoveUnitSubCommand.moveOnto, [1, 5, 9]));
      vm.step(st);
      final m = st.pendingMoves.single;
      expect(m.targetMode, MoveTargetMode.ontoUnit);
      expect(m.targetUnitId, 9);
    });

    test('MOVE_1STEP 记录方向', () {
      final vm = EventVm();
      final st = fresh(ins(0x2F, 4, MoveUnitSubCommand.moveOneStep,
          [1, 5, MoveDirection.right]));
      vm.step(st);
      final m = st.pendingMoves.single;
      expect(m.targetMode, MoveTargetMode.oneStep);
      expect(m.direction, MoveDirection.right);
    });

    test('等单位走完之前 VM 不推进', () {
      final vm = EventVm();
      final st = fresh(script([
        ins(0x2F, 4, MoveUnitSubCommand.move, [1, 5, 3 | (3 << 8)]),
        ins(0x1B, 2, TextShowSubCommand.show, [1]),
        ins(0x01, 2, 1),
      ]));
      vm.step(st); // MOVEUNIT
      expect(st.waitingForMove, isTrue);

      final blocked = vm.step(st)!;
      expect(blocked.advanced, isFalse);
      expect(blocked.note, contains('个单位走完'));
      expect(st.presentation.textBoxVisible, isFalse,
          reason: '移动没结束前不该弹对白');

      expect(vm.notifyMoveFinished(st), isTrue);
      expect(st.waitingForMove, isFalse);
      expect(st.pendingMoves, isEmpty);

      final next = vm.step(st)!;
      expect(next.instruction?.opcode, EventOpcodes.displayText);
    });

    test('CAMERACONTROL/AT 解析打包坐标', () {
      final vm = EventVm();
      final st = fresh(ins(0x26, 2, CameraSubCommand.at, [4 | (9 << 8)]));
      vm.step(st);
      expect(st.cameraX, 4);
      expect(st.cameraY, 9);
    });

    test('CAMERACONTROL 的子命令同样只用低 3 位', () {
      final vm = EventVm();
      final st = fresh(ins(0x26, 2, CameraSubCommand.at | (1 << 3), [1 | (2 << 8)]));
      vm.step(st);
      expect(st.cameraX, 1, reason: '第 3 位是附加参数，不是子命令的一部分');
      expect(st.cameraY, 2);
    });

    test('移动请求入档（含未解析的目标模式）', () {
      final words = ins(0x2F, 4, MoveUnitSubCommand.moveOnto, [1, 5, 9]);
      final sc = EventScript.decode(words);
      final st = EventVmState(script: sc);
      EventVm().step(st);

      final round = EventVmState.decode(st.encode(), sc);
      expect(round.waitingForMove, isTrue);
      expect(round.pendingMoves.length, 1);
      expect(round.pendingMoves.single.targetMode, MoveTargetMode.ontoUnit);
      expect(round.pendingMoves.single.targetUnitId, 9);
    });
  });

  group('可序列化（剧情中途存档）', () {
    test('状态编码再解码等价', () {
      final words = script([
        ins(0x05, 3, 0, [1, 42]),
        ins(0x02, 2, EvSetSubCommand.setEventBit, [3]),
        ins(0x0A, 2, 0, [8]), // call 8，栈里留一个返回地址
        ins(0x01, 2, 1),
        ins(0x01, 2, 0),
      ]);
      final sc = EventScript.decode(words);
      final vm = EventVm();
      final st = EventVmState(script: sc);
      vm.step(st); // SVAL
      vm.step(st); // EVSET
      vm.step(st); // CALL —— 此刻栈里有东西

      expect(st.callStack, isNotEmpty);
      final round = EventVmState.decode(st.encode(), sc);
      expect(round.pc, st.pc);
      expect(round.callStack, st.callStack);
      expect(round.slots, st.slots);
      expect(round.eventBits, st.eventBits);
      expect(round.stallTimer, st.stallTimer);
      expect(round.done, st.done);
    });

    test('表现状态与"等玩家"标志都入档', () {
      final words = script([
        ins(0x21, 4, ShowBgSubCommand.display, [5, 0]),
        ins(0x1E, 2, 1, [22]),
        ins(0x1B, 2, TextShowSubCommand.show, [3]),
        ins(0x01, 2, 1),
      ]);
      final sc = EventScript.decode(words);
      final vm = EventVm(textTable: {3: '台词'});
      final st = EventVmState(script: sc);
      vm.run(st);
      expect(st.waitingForPlayer, isTrue);

      final round = EventVmState.decode(st.encode(), sc);
      expect(round.waitingForPlayer, isTrue,
          reason: '存档时停在"等玩家按键"是完全正常的，这个标志必须入档');
      expect(round.presentation.backgroundId, 5);
      expect(round.presentation.faces[1], 22);
      expect(round.presentation.textId, 3);
      expect(round.lastText, '台词');
    });

    test('解档后能继续跑完（不是只能读的死状态）', () {
      final words = script([
        ins(0x05, 3, 0, [1, 5]),
        ins(0x0E, 2, 0, [2]), // stall 2
        ins(0x06, 4, SlotOpSubCommand.add, [1, 1]), // slot1 *= 2
        ins(0x01, 2, 1),
      ]);
      final sc = EventScript.decode(words);
      final st = EventVmState(script: sc);
      EventVm().step(st); // SVAL
      EventVm().step(st); // STALL（进入等待）

      // 存
      final saved = st.encode();
      // 读（新引擎、新状态）
      final st2 = EventVmState.decode(saved, sc);
      final vm2 = EventVm();

      // ⚠️ `run` 的语义是"推进到需要等待为止"，所以 STALL 期间
      // 每次调用只消耗 1 帧。调用方（游戏主循环）每帧调一次 ——
      // 测试里要自己循环。
      var guard = 0;
      while (!st2.done && guard++ < 50) {
        vm2.run(st2);
      }

      expect(st2.done, isTrue, reason: '循环 $guard 次仍未结束');
      expect(st2.slots[1], 10, reason: '5 + 5 = 10；存档不该丢掉插槽');
    });

    test('脚本本身不入档（偏移才有意义）', () {
      final sc = EventScript.decode(ins(0x01, 2, 1));
      final st = EventVmState(script: sc);
      final json = st.encode();
      expect(json.contains('instructions'), isFalse,
          reason: '脚本是静态数据，塞进存档会让它膨胀几百倍');
      expect(json.length, lessThan(450));
    });
  });

  group('操作码表与提取数据一致', () {
    test('eventscript.json 的指令数与 C 编译器复核的一致', () {
      final f = File('tools/pipeline/out/tables/eventscript.json');
      if (!f.existsSync()) {
        fail('缺少 eventscript.json，先跑 parse_eventscript.py');
      }
      final d = jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
      final cmds = d['commands'] as Map<String, dynamic>;
      final subs = d['subCommands'] as Map<String, dynamic>;
      expect(cmds.length, 150);
      expect(subs.length, 161);

      // 抽查几个在 Dart 侧也用到的值，防止两边漂移
      expect(cmds['EV_CMD_NOP'], EventOpcodes.nop);
      expect(cmds['EV_CMD_END'], EventOpcodes.end);
      expect(cmds['EV_CMD_GOTO'], EventOpcodes.goTo);
      expect(cmds['EV_CMD_CALL'], EventOpcodes.call);
      expect(cmds['EV_CMD_STALL'], EventOpcodes.stall);
      expect(cmds['EV_CMD_BRANCH'], EventOpcodes.branch);
      expect(cmds['EV_CMD_SLOT_OPS'], EventOpcodes.slotOps);

      expect(subs['EVSUBCMD_ENDA'], EndSubCommand.returnFromCall);
      expect(subs['EVSUBCMD_ENDB'], EndSubCommand.endAll);
      expect(subs['EVSUBCMD_SADD'], SlotOpSubCommand.add);
      expect(subs['EVSUBCMD_BEQ'], BranchSubCommand.eq);
      expect(subs['EVSUBCMD_EVBIT_T'], EvSetSubCommand.setEventBit);

      // 编码参数
      final enc = d['encoding'] as Map<String, dynamic>;
      expect(enc['opcodeShift'], 8);
      expect(enc['lengthShift'], 4);
      expect(enc['subCmdMask'], 0xF);
    });
  });
}
