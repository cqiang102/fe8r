// PORT OF: src/masked_0802e4c4.c（`ApplyMapChangesById`）
//          src/sub_800BDE8.c（`TriggerMapChanges`：`if (IsMapChangeEnabled(id)) return;`
//                             → `ApplyMapChangesById(id)` → `EnableMapChange(id)`）
//          include/types.h:395-402（`struct MapChange { s8 id; u8 xOrigin; u8 yOrigin;
//                                    u8 xSize; u8 ySize; const void* data; }`）
//          src/GetMapChangeIdAt.c:15-40（按矩形命中，取 `id`）
//
// # 地形变化（tile change）
//
// ```c
// void ApplyMapChangesById(int id) {
//     const struct MapChange* mapChange = GetMapChange(id);
//     const u16* tileDataIt = mapChange->data;
//     for (iy = 0; iy < mapChange->ySize; ++iy)
//         for (ix = 0; ix < mapChange->xSize; ++ix) {
//             if (*tileDataIt != 0) gBmMapBaseTiles[y0+iy][x0+ix] = *tileDataIt++;
//             else ++tileDataIt;
//         }
// }
// ```
//
// ⚠️ **`0` 是"这格不动"**（稀疏更新），不是"写成 0" —— 这一点极易写反，
// 写反了会在地图上刷出一片空洞。判据里专门有一条钉它。
//
// ⚠️ 每次触发前要查 `IsMapChangeEnabled(id)`（已应用过就跳过）——
// 我们用调用方传的"已应用集合"表达（核心层不持有存档）。

/// 一条地形变化（`struct MapChange`）
class MapChangeRecord {
  const MapChangeRecord({
    required this.id,
    required this.xOrigin,
    required this.yOrigin,
    required this.xSize,
    required this.ySize,
    required this.tiles,
  });

  final int id;
  final int xOrigin;
  final int yOrigin;
  final int xSize;
  final int ySize;

  /// 瓦片数据（行优先，**`0` = 该格不动**）
  final List<int> tiles;

  Map<String, Object?> toJson() => {
        'id': id,
        'xOrigin': xOrigin,
        'yOrigin': yOrigin,
        'xSize': xSize,
        'ySize': ySize,
        'tiles': tiles,
      };

  factory MapChangeRecord.fromJson(Map<String, dynamic> j) => MapChangeRecord(
        id: (j['id'] as num).toInt(),
        xOrigin: (j['xOrigin'] as num).toInt(),
        yOrigin: (j['yOrigin'] as num).toInt(),
        xSize: (j['xSize'] as num).toInt(),
        ySize: (j['ySize'] as num).toInt(),
        tiles: (j['tiles'] as List).cast<int>(),
      );
}

/// `ApplyMapChangesById` 的**纯函数**版本：把变更**叠在**一份瓦片网格上。
///
/// 返回**新的**列表（调用方自己决定怎么用），越界的格子**跳过**（不崩）。
List<int> applyMapChangeToTiles({
  required List<int> metatiles,
  required int width,
  required int height,
  required MapChangeRecord r,
}) {
  final out = List<int>.from(metatiles);
  var i = 0;
  for (var iy = 0; iy < r.ySize; iy++) {
    for (var ix = 0; ix < r.xSize; ix++) {
      if (i >= r.tiles.length) return out; // 数据短了就停（不越界读）
      final v = r.tiles[i++];
      if (v == 0) continue; // ★ `0` = 这格不动
      final gx = r.xOrigin + ix;
      final gy = r.yOrigin + iy;
      if (gx < 0 || gy < 0 || gx >= width || gy >= height) continue;
      out[gy * width + gx] = v;
    }
  }
  return out;
}

/// `GetMapChangeIdAt`（`src/GetMapChangeIdAt.c:15-31`）的**纯函数**版本。
///
/// * 从表头开始走，走到 `id < 0`（哨兵）为止；
/// * 命中的矩形条件是 `x >= xOrigin && y >= yOrigin &&
///   xOrigin + xSize - 1 >= x && yOrigin + ySize - 1 >= y`；
/// * ★ **后面的记录覆盖前面的**（源码每命中一次就改写 `result`）
///   ⇒ 是"**最后命中者胜**"，不是第一个；
/// * 一个都没有 ⇒ **-1**（源码的初值）。
int getMapChangeIdAt(List<MapChangeRecord> records, int x, int y) {
  var result = -1;
  for (final r in records) {
    if (r.id < 0) break; // 哨兵
    if (x >= r.xOrigin &&
        y >= r.yOrigin &&
        r.xOrigin + r.xSize - 1 >= x &&
        r.yOrigin + r.ySize - 1 >= y) {
      result = r.id;
    }
  }
  return result;
}
