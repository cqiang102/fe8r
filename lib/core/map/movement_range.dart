// PORT OF: src/MapFloodCoreStepThumb.c + src/arm.s (MapFloodCore)
//
// 移动范围计算。**这是规则层代码，必须 1:1 移植。**
//
// ## 原版算法
//
// `GenerateMovementMap(x, y, movement, unitId)` 初始化两块队列缓冲，
// 然后 `MapFloodCore()` 反复调用 `MapFloodCoreStep()` 做双缓冲泛洪。
// 结果写进 `gWorkingBmMap`：每格是走到那里的**最小消耗**，255 表示到不了。
//
// ## 保真要点（每一条都对应一个真实的坑）
//
// 1. **`>=` 而不是 `>`**。`MapFloodCoreStepThumb.c` 与 `arm.s` 里的 `bhs`
//    都是"无符号大于等于"。`arm.s` 上方那段重构注释写的是 `>`，是错的。
//
// 2. **未访问记 255（即 s8 的 -1）**。`BmMapFill(gWorkingBmMap, -1)` 填的是
//    0xFF；读取时按 `s8` 解释。所以"到不了"和"消耗 -1"是同一个字节。
//
// 3. **`connexion` 是"从父节点过来的方向"，本节点不往回走**。
//    编码：0=从右来，1=从左来，2=从上（向下走）来，3=从下来（向上走）来，
//    5=起点（四向全扩），4=终止标记。
//    这是个剪枝优化，不是严格的 Dijkstra——顺序会影响哪些节点被展开，
//    所以必须逐字复刻，不能"顺手改成标准 BFS"。
//
// 4. **队列不环绕**。`arm.s` 里是指针裸加，真机上池子溢出就是内存踩踏。
//    这里用 Dart 的 List 并显式扩容，语义等价于"池子足够大"。
//
// ## 与 C 的差异（唯一一处）
//
// 原版直接读写 GBA 的 `gWorkingBmMap` 二维指针数组；这里改成显式的网格对象，
// 因为 `lib/core` 必须是纯 Dart 且可序列化（见 tools/verify/check_architecture.dart）。

import 'dart:typed_data';

import '../terrain/terrain_type.dart';
import 'map_grid.dart';

/// `connexion` 的取值。数字本身是对齐原版的，不要改。
class _Conn {
  static const int fromRight = 0;
  static const int fromLeft = 1;
  static const int fromAbove = 2; // 向下走
  static const int fromBelow = 3; // 向上走
  static const int terminator = 4;
  static const int start = 5;
}

/// 未访问 / 不可达的标记值。与 C 里 `BmMapFill(map, -1)` 一致。
const int unreachable = 255;

/// 一次泛洪的队列节点
class _Node {
  _Node();
  int x = 0;
  int y = 0;
  int connexion = 0;
  int leastMoveCost = 0;

  void set(int px, int py, int pc, int pcost) {
    x = px;
    y = py;
    connexion = pc;
    leastMoveCost = pcost;
  }
}

/// 地形移动消耗表（按地形 ID 索引）。
///
/// ⚠️ **按无符号字节读取。** C 里 `gWorkingTerrainMoveCosts` 是 `u8[]`，
/// 数据表里写的 `-1`（不可通行）取出来是 **255**。早期版本按 s8 读成 -1，
/// 于是 `cost = -1 + 0 = -1`，通过了 `cost >= gWorkingBmMap[...]` 与
/// `cost > movement` 两道检查，把边界格也写了进去，泛洪直接跑出地图。
///
/// 这个差异只有"不可通行"的地形才会暴露——所以测试里必须真的有障碍物。
class MovementCostTable {
  MovementCostTable(List<int> costs)
      : _costs = Uint8List.fromList(
          List<int>.generate(256, (i) => (i < costs.length ? costs[i] : 1) & 0xFF),
        );

  final Uint8List _costs;

  /// 与 C 的 `gWorkingTerrainMoveCosts[terrain]` 一致（**u8** 语义）
  int costOf(TerrainType terrain) => _costs[terrain.id];

  /// 按原始地形 ID 取（未知值也能取到，便于发现数据异常）
  int costOfId(int terrainId) => _costs[terrainId & 0xFF];

  /// 是否可通行。C 里用 `-1`（即 u8 的 255）表示不可通行。
  bool isPassable(TerrainType terrain) => _costs[terrain.id] != 255;
}

/// 地图外圈（边界）的等效消耗。对应真机上 `BmMapFillEdges` 填的不可通行地形。
const int _borderCost = 255;

/// 泛洪的结果：每格的移动消耗，[unreachable] 表示到不了。
class MovementRange {
  MovementRange(this.width, this.height)
      : costs = Uint8List(width * height)..fillRange(0, width * height, unreachable);

  final int width;
  final int height;
  final Uint8List costs;

  int costAt(int x, int y) {
    if (x < 0 || y < 0 || x >= width || y >= height) return unreachable;
    return costs[y * width + x];
  }

  bool canReach(int x, int y) => costAt(x, y) != unreachable;

  /// 可达格子的数量（含起点）
  int get reachableCount => costs.where((c) => c != unreachable).length;
}

/// 移动范围计算器。
///
/// 用法：
/// ```dart
/// final r = MovementRange.compute(
///   map: grid, costTable: table, x: 3, y: 4, movement: 6,
/// );
/// ```
class MovementRangeComputer {
  MovementRangeComputer({
    required this.map,
    required this.costTable,
    int queueCapacity = 4096,
  }) : _pool1 = List<_Node>.generate(queueCapacity, (_) => _Node()),
       _pool2 = List<_Node>.generate(queueCapacity, (_) => _Node()) {
    // 四周各留一格边界：步长 = width + 2，总行数 = height + 2。
    // 于是 (x,y) 落在 (y+1)*stride + (x+1)，
    // 而 x=-1 / x=width / y=-1 / y=height 都仍落在缓冲区内。
    _workW = map.width + 2;
    _work = Uint8List(_workW * (map.height + 2));
  }

  final MapGrid map;
  final MovementCostTable costTable;

  final List<_Node> _pool1;
  final List<_Node> _pool2;

  late final Uint8List _work;
  late final int _workW;

  int _poolSize = 0;
  int _dst = 0;
  int _src = 0;
  bool _usePool1AsSrc = true;
  int _movement = 0;
  bool _hasUnit = false;
  int _unitId = 0;

  /// 带边界的写入。地图外圈一律不可通行，与原版 `BmMapFillEdges` 一致。
  int _get(int x, int y) {
    final bx = x + 1;
    final by = y + 1;
    // 只可能越界到"再外面一圈"（正常不会发生，因为边界格写不进去）
    if (bx < 0 || by < 0 || bx >= _workW || by * _workW + bx >= _work.length) {
      return unreachable;
    }
    return _work[by * _workW + bx];
  }

  void _set(int x, int y, int v) {
    _work[(y + 1) * _workW + (x + 1)] = v;
  }

  /// 对应 `MapFloodCoreStep`
  void _step(int connexion, int dx, int dy) {
    final src = _srcNode;
    final x = src.x + dx;
    final y = src.y + dy;

    // 边界的消耗由 _get 的越界保护 + 边界值共同决定
    final border = x < 0 || y < 0 || x >= map.width || y >= map.height;
    // 边界用 255（不可通行地形的 u8 值），与 C 完全一致
    final terrainCost =
        border ? _borderCost : costTable.costOf(map.terrainAt(x, y));
    // C 把当前格消耗按 **s8** 读回来（`(s8)gWorkingBmMap[...]`）
    final srcCost = _signed8(_get(src.x, src.y));
    final cost = terrainCost + srcCost;

    if (cost >= _get(x, y)) return;

    if (_hasUnit) {
      final u = _unitAt(x, y);
      if (u != 0 && (u ^ _unitId) & 0x80 != 0) return;
    }

    if (cost > _movement) return;

    _dstNode.set(x, y, connexion, cost);
    _dst++;
    if (_dst >= _poolSize) _grow();

    _set(x, y, cost & 0xFF);
  }

  int _unitAt(int x, int y) {
    if (x < 0 || y < 0 || x >= map.width || y >= map.height) return 0;
    return _unitGrid[y * map.width + x];
  }

  late Uint8List _unitGrid;

  List<_Node> get _activePool => _usePool1AsSrc ? _pool1 : _pool2;
  List<_Node> get _inactivePool => _usePool1AsSrc ? _pool2 : _pool1;
  _Node get _srcNode => _activePool[_src];
  _Node get _dstNode => _inactivePool[_dst];

  void _grow() {
    throw StateError('移动范围队列溢出（$_poolSize 项）——原版在这个规模下也是内存踩踏，'
        '说明测试用例的规模超出了预期');
  }

  static int _signed8(int v) => v >= 128 ? v - 256 : v;

  /// 对应 `MapFloodCore`
  void _floodCore() {
    var i = 0;
    for (;;) {
      i = i ^ 1;
      _usePool1AsSrc = i != 0;

      if (_activePool[_src].connexion == _Conn.terminator) return;

      for (;;) {
        switch (_activePool[_src].connexion) {
          case _Conn.fromBelow: // 3
            _step(_Conn.fromBelow, 0, -1);
            _step(_Conn.fromRight, -1, 0);
            _step(_Conn.fromLeft, 1, 0);
            break;
          case _Conn.fromAbove: // 2
            _step(_Conn.fromAbove, 0, 1);
            _step(_Conn.fromRight, -1, 0);
            _step(_Conn.fromLeft, 1, 0);
            break;
          case _Conn.fromRight: // 0
            _step(_Conn.fromBelow, 0, -1);
            _step(_Conn.fromAbove, 0, 1);
            _step(_Conn.fromRight, -1, 0);
            break;
          case _Conn.fromLeft: // 1
            _step(_Conn.fromBelow, 0, -1);
            _step(_Conn.fromAbove, 0, 1);
            _step(_Conn.fromLeft, 1, 0);
            break;
          case _Conn.terminator: // 4
            break;
          case _Conn.start: // 5
            _step(_Conn.fromBelow, 0, -1);
            _step(_Conn.fromAbove, 0, 1);
            _step(_Conn.fromRight, -1, 0);
            _step(_Conn.fromLeft, 1, 0);
            break;
          default:
            break;
        }

        if (_activePool[_src].connexion == _Conn.terminator) break;

        _dstNode.connexion = _Conn.terminator;
        _src++;
      }
    }
  }

  /// 计算移动范围。对应 `GenerateMovementMap(x, y, movement, unitId)`。
  static MovementRange compute({
    required MapGrid map,
    required MovementCostTable costTable,
    required int x,
    required int y,
    required int movement,
    int unitId = 0,
    List<int>? unitGrid,
    int queueCapacity = 4096,
  }) {
    final c = MovementRangeComputer(
      map: map,
      costTable: costTable,
      queueCapacity: queueCapacity,
    );
    return c._run(x, y, movement, unitId, unitGrid);
  }

  MovementRange _run(int x, int y, int movement, int unitId, List<int>? unitGrid) {
    _poolSize = _pool1.length;
    _unitGrid = Uint8List(map.width * map.height);
    if (unitGrid != null) {
      for (var i = 0; i < unitGrid.length && i < _unitGrid.length; i++) {
        _unitGrid[i] = unitGrid[i] & 0xFF;
      }
    }

    _movement = movement;
    _hasUnit = unitId != 0;
    _unitId = unitId & 0xFF;

    // BmMapFill(gWorkingBmMap, -1)
    _work.fillRange(0, _work.length, unreachable);

    _usePool1AsSrc = true; // 起点写在 pool1
    _pool1[0].set(x, y, _Conn.start, 0);
    _set(x, y, 0);

    _dst = 1;
    _pool1[1].connexion = _Conn.terminator;
    _src = 0;

    _floodCore();

    final out = MovementRange(map.width, map.height);
    for (var yy = 0; yy < map.height; yy++) {
      for (var xx = 0; xx < map.width; xx++) {
        out.costs[yy * map.width + xx] = _get(xx, yy);
      }
    }
    return out;
  }
}
