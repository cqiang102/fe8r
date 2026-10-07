// PORT OF: src/masked_08018a60.c（`GetUnitMovementCost`）
//
// **单位 → 移动消耗表**。
//
// ## 出处
//
// ```c
// const s8* GetUnitMovementCost(struct Unit* unit) {
//     if (unit->state & US_IN_BALLISTA)
//         return Unk_TerrainTable_0;
//
//     switch (gPlaySt.chapterWeatherId) {
//     case WEATHER_RAIN:
//         return unit->pClassData->pMovCostTable[1];
//     case WEATHER_SNOW:
//     case WEATHER_SNOWSTORM:
//         return unit->pClassData->pMovCostTable[2];
//     default:
//         return unit->pClassData->pMovCostTable[0];
//     }
// }
// ```
//
// 所以消耗表是**按单位（其实是按职业）× 天气**选的 ——
// 不是"全场一张"。`ClassData.pMovCostTable` 有三张（晴/雨/雪），
// 提取器已经把三张都抽出来了（`classes.json` 的 `pMovCostTable`）。
//
// ## ⚠️ 我原来写的是"全场一张演示表"
//
// ```dart
// flow = FlowMachine(map: grid, costTable: _demoCostTable());  // 除 0 号地形外全 1
// ```
//
// 后果：**山峰（`TERRAIN_PEAK = 0x12`）也能走** —— 真实表里绝大多数职业
// 在山峰上是 `-1`（不可通行，u8 语义 255）。走位与原作不一致，
// 而且不报错：只是"路好像能走"。
import '../map/movement_range.dart';
import 'battle_field.dart';

/// 取某个单位当前的移动消耗表
typedef MoveCostsOf = MovementCostTable Function(MapUnit unit);

/// 所有单位共用一张表 —— **测试与兜底**用。
///
/// 生产路径必须走 `ClassTable.movementCosts()`（按职业查三张表）。
MoveCostsOf uniformCosts(MovementCostTable t) => (_) => t;

/// 按**职业**建一个 `MoveCostsOf`。
///
/// [costsOfClass] 给 `null` 表示这个职业没有消耗表（石像鬼蛋、弩车），
/// 调用方要自己决定是响亮报错还是兜底。
MoveCostsOf costsByClass({
  required List<int>? Function(int classId) costsOfClass,
  required MovementCostTable fallback,
  void Function(int classId)? onMissing,
}) =>
    (MapUnit unit) {
      final costs = costsOfClass(unit.classId);
      if (costs == null) {
        onMissing?.call(unit.classId);
        return fallback;
      }
      return MovementCostTable(costs);
    };
