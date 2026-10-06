// PORT OF: src/bmmind.c 的敌方 AI
//          ⚠️ 不是 1:1 移植（原版 AI 是大型打分器，此处只做最小可用版本）
//
// 敌方 AI。
//
// ## 这不是原版 AI 的移植
//
// 原版 AI 在 `src/cp_*.c` / `src/ai_*.c` 里，是一套带"AI 标记位"、
// 目标评分、行动优先级表的完整系统（M1 分类里归入 rewrite 的部分）。
// 那是 M7 的工作量。
//
// 这里实现的是 **M5 需要的最小可用 AI**：朝最近的我方单位移动，
// 够得着就打。目的是把回合循环跑通，让"打完一场遭遇战"这句话成立。
//
// ## 唯一不能妥协的是确定性
//
// AI 的每一步选择都必须是 (战场状态) 的纯函数：
//   * 单位按 **id 升序**处理（不是按列表顺序，也不是按距离）
//   * 距离相同时的落点按 **(y, x) 字典序**取最小
//   * 目标选择先比距离、再比 id
//
// 只要有一处用了 HashMap 的迭代顺序或浮点比较，同一个局面就会产生
// 不同的结果——那时"AI 有问题"会变成无法复现的偶发 bug。
// 原版的乱数消耗约束（M4 已验证）也要求 AI 的行动序列是确定的。

import '../battle/phase.dart';
import '../map/map_grid.dart';
import '../map/movement_range.dart';
import 'battle_field.dart';

/// AI 的一次决策结果
class AiAction {
  AiAction({
    required this.unitId,
    required this.toX,
    required this.toY,
    this.targetId,
    this.attacked = false,
  });

  final int unitId;
  final int toX;
  final int toY;

  /// 移动后够得着的目标（null = 没得打）
  final int? targetId;
  final bool attacked;

  @override
  String toString() => 'AiAction(unit $unitId -> ($toX,$toY)'
      '${targetId == null ? '' : ' 攻击 $targetId'})';
}

class EnemyAi {
  EnemyAi({required this.map, required this.costTable});

  final MapGrid map;
  final MovementCostTable costTable;

  /// 给 [unit] 选一个行动。
  ///
  /// 找不到目标时返回"原地待机"（不返回 null——AI 永远要给出结论，
  /// 让调用方去处理 null 只会把分支扩散到别处）。
  AiAction decide(BattleField field, MapUnit unit) {
    final enemies = field.units
        .where((u) => u.isAlive && !PhaseRules.areUnitsAllied(u.faction, unit.faction))
        .toList()
      ..sort((a, b) => a.id.compareTo(b.id));

    if (enemies.isEmpty) {
      return AiAction(unitId: unit.id, toX: unit.x, toY: unit.y);
    }

    // 目标：距离最近，距离相同取 id 小的
    MapUnit? target;
    var bestDist = 1 << 30;
    for (final e in enemies) {
      final d = _dist(unit.x, unit.y, e.x, e.y);
      if (d < bestDist) {
        bestDist = d;
        target = e;
      }
    }
    final t = target!;

    // 能站的位置
    final range = MovementRangeComputer.compute(
      map: map,
      costTable: costTable,
      x: unit.x,
      y: unit.y,
      movement: unit.movement,
    );

    // 选一个使"到目标的距离"最小的落点；平手时按 (y,x) 字典序取最小。
    //
    // 注意：**不要求严格更近**。原地不动也是候选之一
    // （当己方位置已经是最优时，"移动"应当是原地），
    // 否则单位会在等距的几个格子之间无意义地来回走。
    var bestX = unit.x;
    var bestY = unit.y;
    var bestScore = _dist(unit.x, unit.y, t.x, t.y);

    for (var y = 0; y < field.height; y++) {
      for (var x = 0; x < field.width; x++) {
        if (x == unit.x && y == unit.y) continue;
        if (!range.canReach(x, y)) continue;
        final occupant = field.unitAt(x, y);
        if (occupant != null && occupant.id != unit.id) continue;

        final d = _dist(x, y, t.x, t.y);
        if (d < bestScore || (d == bestScore && _lexLess(x, y, bestX, bestY))) {
          bestScore = d;
          bestX = x;
          bestY = y;
        }
      }
    }

    // 移动后够得着就打（M5 用相邻作为射程；真实武器射程属于 M4 收尾）
    final attacked = _dist(bestX, bestY, t.x, t.y) == 1;

    return AiAction(
      unitId: unit.id,
      toX: bestX,
      toY: bestY,
      targetId: attacked ? t.id : null,
      attacked: attacked,
    );
  }

  /// 曼哈顿距离（FE 的移动/射程都用它，不用欧氏距离）
  static int _dist(int ax, int ay, int bx, int by) =>
      (ax - bx).abs() + (ay - by).abs();

  static bool _lexLess(int ax, int ay, int bx, int by) =>
      ay != by ? ay < by : ax < bx;
}
