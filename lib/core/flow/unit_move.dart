// PORT OF: src/sub_800FF08.c（`Event2F_MoveUnit`，cmd 0x2F）
//          include/EAstdlib.h（`MOVE` / `MOVEONTO` / `MOVE_1STEP` / `MOVE_DEFINED`）
//          include/types.h（`FACING_*`）
//
// 剧情里"某个人走到某处"的**四种**写法，参数形状完全不同：
//
// ```c
// #define MOVE(speed, pid, x, y)                EvtMoveUnit(false, speed, pid, x, y)
// #define MOVEONTO(speed, pid, pid_target)      EvtMoveUnitToTarget(false, speed, pid, pid_target)
// #define MOVE_1STEP(speed, pid, direction)     EvtMoveUnitOneStep(false, speed, pid, direction)
// #define MOVE_DEFINED(pid)                     EvtMoveUnitByQueue(false, pid)
// ```
//
// 而引擎里是**同一个** `Event2F_MoveUnit` 按子命令分派
// （`src/sub_800FF08.c:55-110`）：
//
// ```c
// switch (subcmd) {
// case EVSUBCMD_MOVE:                 // ARGV[2] 低字节 = x，高字节 = y
//     xOut = ARGV[2]; yOut = ARGV[2] >> 8;                 queue = NULL; break;
// case EVSUBCMD_MOVEONTO:             // ARGV[2] = 目标单位
//     targetUnit = GetUnitStructFromEventParameter(targetPid);
//     xOut = targetUnit->xPos; yOut = targetUnit->yPos;    queue = NULL; break;
// case EVSUBCMD_MOVE_1STEP:           // ARGV[2] = 方向
//     switch (direction) { case 3: yOut--; case 2: yOut++; case 0: xOut--; case 1: xOut++; }
//     queue = NULL; break;
// case EVSUBCMD_MOVE_DEFINED:
//     queue = gEventSlotQueue; break;
// }
// ```
//
// ⚠️ **我原来把四种都当成 `(speed, pid, x, y)` 读** —— 于是：
//   * `MOVE_1STEP(0, 1, 0)`（艾莉卡往左走一格）被读成"走到 (0,0)"
//   * `MOVEONTO(0, 2, 1)`（赛特走到艾莉卡那格）被读成"走到 (1,0)"
//   * `MOVE_DEFINED(4)` 参数不足 4 个 → **直接 return，人根本没动**
// 三种全是"看着像实现了，其实位置全错"。

/// 方向常量（`include/types.h:274-279`）
class Facing {
  static const int left = 0;
  static const int right = 1;
  static const int down = 2;
  static const int up = 3;
}

/// `Event2F_MoveUnit` 的四种子命令（`include/eventscript.h` 的 `EVSUBCMD_MOVE*`）
enum MoveSubcmd { move, moveOnto, oneStep, defined }

/// 从生成器给出的 op 名认子命令（`MOVE` / `MOVEONTO` / `MOVE_1STEP` / `MOVE_DEFINED`）
MoveSubcmd? moveSubcmdOf(String op) {
  if (op.contains('MOVE_DEFINED')) return MoveSubcmd.defined;
  if (op.contains('MOVEONTO')) return MoveSubcmd.moveOnto;
  if (op.contains('MOVE_1STEP')) return MoveSubcmd.oneStep;
  if (op.startsWith('MOVE')) return MoveSubcmd.move;
  return null;
}

/// 一次移动的解析结果
class MoveIntent {
  const MoveIntent({
    required this.subcmd,
    required this.pid,
    this.x,
    this.y,
    this.facing,
    this.note = '',
  });

  final MoveSubcmd subcmd;

  /// 要移动的角色号（`ARGV[1]`）
  final int pid;

  /// 目标格（`moveOnto` 需要先查目标单位的位置，见 [moveTarget]）
  final int? x;
  final int? y;

  /// `MOVE_1STEP` 的方向
  final int? facing;

  /// 解析不出来时的说明（**响亮**，不静默）
  final String note;
}

/// 解析生成器传过来的参数 —— 四种 op 的参数形状在这里归一。
///
/// 返回 `null` 表示这个 op 不是移动（调用方不该调用）。
MoveIntent? parseMoveIntent(String op, List<Object> args) {
  final kind = moveSubcmdOf(op);
  if (kind == null) return null;

  int at(int i, [int d = 0]) => args.length > i && args[i] is int
      ? args[i] as int
      : d;

  switch (kind) {
    case MoveSubcmd.move:
      // `MOVE(speed, pid, x, y)`：四个参数
      return MoveIntent(
        subcmd: kind,
        pid: at(1),
        x: args.length > 2 ? at(2) : null,
        y: args.length > 3 ? at(3) : null,
        note: args.length < 4 ? 'MOVE 参数不足 4 个：$args' : '',
      );
    case MoveSubcmd.moveOnto:
      // `MOVEONTO(speed, pid, pid_target)`：第三个是**目标单位**
      return MoveIntent(subcmd: kind, pid: at(1), x: at(2));
    case MoveSubcmd.oneStep:
      // `MOVE_1STEP(speed, pid, direction)`
      return MoveIntent(subcmd: kind, pid: at(1), facing: at(2));
    case MoveSubcmd.defined:
      // `MOVE_DEFINED(pid)`：路径来自槽队列
      return MoveIntent(subcmd: kind, pid: at(0));
  }
}

/// 算出**目标格**。`moveOnto` 需要 [targetUnitPos]（被踩的那个单位在哪）。
///
/// 返回 `null` = 算不出来（例如 `MOVE_DEFINED` 的队列还没实现）——
/// **不猜一个坐标出来**。
({int x, int y})? moveTarget(
  MoveIntent intent, {
  required ({int x, int y}) unitPos,
  ({int x, int y})? targetUnitPos,
}) {
  switch (intent.subcmd) {
    case MoveSubcmd.move:
      if (intent.x == null || intent.y == null) return null;
      return (x: intent.x!, y: intent.y!);

    case MoveSubcmd.moveOnto:
      // `xOut = targetUnit->xPos`
      return targetUnitPos;

    case MoveSubcmd.oneStep:
      // `switch (direction) { 3: y--; 2: y++; 0: x--; 1: x++ }`
      var x = unitPos.x;
      var y = unitPos.y;
      switch (intent.facing) {
        case Facing.up:
          y--;
        case Facing.down:
          y++;
        case Facing.left:
          x--;
        case Facing.right:
          x++;
        default:
          return null;
      }
      return (x: x, y: y);

    case MoveSubcmd.defined:
      // 路径来自 `gEventSlotQueue`（`SAVETOQUEUE` 累计、`gEventSlots[0xD]`
      // 是字数）。**队列还没实现** —— 返回 null 让调用方响亮地记一笔。
      return null;
  }
}
