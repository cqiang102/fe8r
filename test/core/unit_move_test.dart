// `MOVE*` 的四种写法 —— 参数形状与目标格
// （`src/sub_800FF08.c` 的 `Event2F_MoveUnit`）。
//
// ## 为什么必须有这条
//
// 剧情里"某人走到某处"有**四种**宏，参数形状完全不同：
//
//     MOVE(speed, pid, x, y)             EvtMoveUnit
//     MOVEONTO(speed, pid, pid_target)   EvtMoveUnitToTarget
//     MOVE_1STEP(speed, pid, direction)  EvtMoveUnitOneStep
//     MOVE_DEFINED(pid)                  EvtMoveUnitByQueue
//
// 而游戏侧我原来**把它们都当成 `(speed, pid, x, y)` 读**：
//
//   * `MOVE_1STEP(0, 1, 0)`（艾莉卡往左走一格）→ 被读成"走到 (0,0)"
//   * `MOVEONTO(0, 2, 1)`（赛特走到艾莉卡那格）→ 被读成"走到 (1,0)"
//   * `MOVE_DEFINED(4)` → 参数不足 4 个 → **直接 return，人根本没动**
//
// 三种都不报错，只是位置全错 —— 正是这个项目最常见的形状。
import 'package:fe8r/core/core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('op 名 → 子命令', () {
    test('四种都认得出（含 _CLOSEST 变体）', () {
      expect(moveSubcmdOf('MOVE'), MoveSubcmd.move);
      expect(moveSubcmdOf('MOVE_CLOSEST'), MoveSubcmd.move);
      expect(moveSubcmdOf('MOVEONTO'), MoveSubcmd.moveOnto);
      expect(moveSubcmdOf('MOVEONTO_CLOSEST'), MoveSubcmd.moveOnto);
      expect(moveSubcmdOf('MOVE_1STEP'), MoveSubcmd.oneStep);
      expect(moveSubcmdOf('MOVE_DEFINED'), MoveSubcmd.defined);
      expect(moveSubcmdOf('CURSOR_CHAR'), isNull);
    });
  });

  group('参数形状（生成器给的列表）', () {
    test('MOVE：4 个参数 (speed, pid, x, y)', () {
      // 序章：`MOVE(0x18, CHARACTER_SETH, 4, 4)`
      final i = parseMoveIntent('MOVE', [24, 2, 4, 4])!;
      expect((i.pid, i.x, i.y), (2, 4, 4));
      expect(i.note, isEmpty);
    });

    test('MOVEONTO：3 个参数，第三个是**目标单位**', () {
      // 序章：`MOVEONTO(0, CHARACTER_SETH, CHARACTER_EIRIKA)`
      final i = parseMoveIntent('MOVEONTO', [0, 2, 1])!;
      expect(i.pid, 2);
      expect(i.x, 1, reason: '第三个参数是目标单位号，不是坐标');
    });

    test('MOVE_1STEP：3 个参数，第三个是**方向**', () {
      // 序章：`MOVE_1STEP(0, CHARACTER_EIRIKA, FACING_LEFT)`
      final i = parseMoveIntent('MOVE_1STEP', [0, 1, 0])!;
      expect(i.pid, 1);
      expect(i.facing, Facing.left);
    });

    test('MOVE_DEFINED：只有 1 个参数 (pid)', () {
      final i = parseMoveIntent('MOVE_DEFINED', [4])!;
      expect(i.pid, 4);
    });

    test('MOVE 参数不足要**说出来**，不静默当 (0,0)', () {
      final i = parseMoveIntent('MOVE', [24, 2])!;
      expect(i.note, isNotEmpty);
      expect(moveTarget(i, unitPos: (x: 1, y: 1)), isNull);
    });
  });

  group('目标格（`src/sub_800FF08.c:55-110`）', () {
    test('MOVE：就是写死的坐标', () {
      final i = parseMoveIntent('MOVE', [0, 15, 13, 11])!;
      final at = moveTarget(i, unitPos: (x: 9, y: 9))!;
      expect((at.x, at.y), (13, 11));
    });

    test('★ MOVEONTO：走到**目标单位**那一格（不是走到 (1,0)）', () {
      final i = parseMoveIntent('MOVEONTO', [0, 2, 1])!;
      final at = moveTarget(i,
          unitPos: (x: 13, y: 11), targetUnitPos: (x: 14, y: 4))!;
      expect((at.x, at.y), (14, 4));
    });

    test('★ MOVE_1STEP：方向 0/1/2/3 = 左/右/下/上（`include/types.h:274`）', () {
      ({int x, int y}) step(int dir) => moveTarget(
            parseMoveIntent('MOVE_1STEP', [0, 1, dir])!,
            unitPos: (x: 5, y: 5),
          )!;
      expect((step(Facing.left).x, step(Facing.left).y), (4, 5));
      expect((step(Facing.right).x, step(Facing.right).y), (6, 5));
      expect((step(Facing.down).x, step(Facing.down).y), (5, 6));
      expect((step(Facing.up).x, step(Facing.up).y), (5, 4));
    });

    test('方向越界 → 算不出来（不猜）', () {
      final i = parseMoveIntent('MOVE_1STEP', [0, 1, 9])!;
      expect(moveTarget(i, unitPos: (x: 5, y: 5)), isNull);
    });

    test('MOVE_DEFINED：队列没实现 → 返回 null（**不猜坐标**）', () {
      final i = parseMoveIntent('MOVE_DEFINED', [4])!;
      expect(moveTarget(i, unitPos: (x: 5, y: 5)), isNull);
    });
  });
}
