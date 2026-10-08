// 由 tools/pipeline/extract/parse_map_changes.py 生成，**不要手改**。
// 出处：src/data/map/data_map_change.c（typed C，65 张表）
// 应用语义：src/masked_0802e4c4.c:30-51 的 ApplyMapChangesById
//   —— **tile == 0 表示这一格不动**（判据在 test/core/map_change_test.dart）
// 记录类型复用 `lib/core/map/map_change.dart` 的 MapChangeRecord（不重复定义）
// PORT OF: src/data/map/data_map_change.c

import 'map_change.dart';

/// 地图变化表：表名 → 记录（哨兵条已去掉）
final Map<String, List<MapChangeRecord>> gMapChanges = {
  // Ch10EirikaMapChanges
  'Ch10EirikaMapChanges': [
    MapChangeRecord(id: 0, xOrigin: 10, yOrigin: 9, xSize: 2, ySize: 1, tiles: [0xb68, 0xb4c]),
    MapChangeRecord(id: 1, xOrigin: 10, yOrigin: 7, xSize: 1, ySize: 1, tiles: [0xd98]),
    MapChangeRecord(id: 2, xOrigin: 11, yOrigin: 6, xSize: 1, ySize: 1, tiles: [0xd98]),
    MapChangeRecord(id: 3, xOrigin: 12, yOrigin: 6, xSize: 1, ySize: 1, tiles: [0xd98]),
    MapChangeRecord(id: 4, xOrigin: 13, yOrigin: 8, xSize: 1, ySize: 1, tiles: [0xd98]),
  ],
  // Ch10EphraimMapChanges
  'Ch10EphraimMapChanges': [
    MapChangeRecord(id: 0, xOrigin: 8, yOrigin: 0, xSize: 3, ySize: 3, tiles: [0xe84, 0xe88, 0xe8c, 0xf04, 0xf08, 0xf0c, 0xf84, 0xf88, 0xf8c]),
    MapChangeRecord(id: 1, xOrigin: 3, yOrigin: 10, xSize: 3, ySize: 3, tiles: [0xe84, 0xe88, 0xe8c, 0xf04, 0xf08, 0xf0c, 0xf84, 0xf88, 0xf8c]),
    MapChangeRecord(id: 2, xOrigin: 5, yOrigin: 1, xSize: 1, ySize: 1, tiles: [0xf80]),
    MapChangeRecord(id: 3, xOrigin: 6, yOrigin: 0, xSize: 1, ySize: 1, tiles: [0xf80]),
    MapChangeRecord(id: 4, xOrigin: 9, yOrigin: 2, xSize: 1, ySize: 1, tiles: [0x80]),
    MapChangeRecord(id: 5, xOrigin: 4, yOrigin: 12, xSize: 1, ySize: 1, tiles: [0x80]),
    MapChangeRecord(id: 6, xOrigin: 8, yOrigin: 14, xSize: 1, ySize: 1, tiles: [0xf80]),
    MapChangeRecord(id: 7, xOrigin: 9, yOrigin: 14, xSize: 1, ySize: 1, tiles: [0xf80]),
  ],
  // Ch11EirikaMapChanges
  'Ch11EirikaMapChanges': [
    MapChangeRecord(id: 0, xOrigin: 3, yOrigin: 8, xSize: 1, ySize: 1, tiles: [0x104]),
    MapChangeRecord(id: 1, xOrigin: 12, yOrigin: 11, xSize: 1, ySize: 1, tiles: [0x104]),
    MapChangeRecord(id: 2, xOrigin: 17, yOrigin: 5, xSize: 1, ySize: 1, tiles: [0x104]),
    MapChangeRecord(id: 3, xOrigin: 4, yOrigin: 11, xSize: 1, ySize: 1, tiles: [0xbc0]),
    MapChangeRecord(id: 4, xOrigin: 17, yOrigin: 13, xSize: 2, ySize: 1, tiles: [0xbc0, 0xb44]),
  ],
  // Ch11EphraimMapChanges
  'Ch11EphraimMapChanges': [
    MapChangeRecord(id: 0, xOrigin: 14, yOrigin: 7, xSize: 7, ySize: 12, tiles: [0x0, 0x0, 0x86c, 0x868, 0x0, 0x0, 0x0, 0x0, 0x768, 0x64c, 0x668, 0x868, 0x0, 0x768, 0x7ec, 0x7e8, 0x378, 0x6e4, 0x7ec, 0x868, 0x768, 0x0, 0x3ec, 0x3f0, 0x3f4, 0x3f8, 0x7ec, 0x768, 0x468, 0x46c, 0x470, 0x474, 0x478, 0x47c, 0x768, 0x4e8, 0x584, 0x678, 0x598, 0x4f8, 0x4fc, 0x768, 0x3e4, 0x604, 0x598, 0x610, 0x608, 0x460, 0x768, 0x464, 0x6f4, 0x4f4, 0x4f4, 0x4f4, 0x4e0, 0x768, 0x464, 0x6f4, 0x4f4, 0x58c, 0x678, 0x4e0, 0x768, 0x464, 0x6f4, 0x4f4, 0x60c, 0x674, 0x4e0, 0x768, 0x464, 0x6f4, 0x4f4, 0x58c, 0x678, 0x4e0, 0x768, 0x464, 0x6f4, 0x4f4, 0x60c, 0x674, 0x4e0, 0x768]),
    MapChangeRecord(id: 1, xOrigin: 9, yOrigin: 0, xSize: 8, ySize: 19, tiles: [0x0, 0x0, 0x0, 0x86c, 0x868, 0x0, 0x0, 0x0, 0x0, 0x0, 0x86c, 0x64c, 0x668, 0x868, 0x0, 0x0, 0x76c, 0x8f0, 0x7e8, 0x378, 0x6e4, 0x7ec, 0x868, 0x0, 0x8f0, 0x86c, 0x3ec, 0x3f0, 0x3f4, 0x3f8, 0x7ec, 0x868, 0x868, 0x468, 0x46c, 0x470, 0x474, 0x478, 0x47c, 0x7ec, 0x86c, 0x4e8, 0x584, 0x678, 0x598, 0x4f8, 0x4fc, 0x7ec, 0x76c, 0x3e4, 0x604, 0x598, 0x610, 0x608, 0x460, 0x0, 0x0, 0x464, 0x6f4, 0x4f4, 0x4f4, 0x4f4, 0x4e0, 0x0, 0x0, 0x464, 0x6f4, 0x4f4, 0x58c, 0x678, 0x4e0, 0x7ec, 0x0, 0x464, 0x6f4, 0x4f4, 0x60c, 0x674, 0x4e0, 0x768, 0x0, 0x464, 0x6f4, 0x4f4, 0x58c, 0x678, 0x4e0, 0x768, 0x0, 0x464, 0x6f4, 0x4f4, 0x60c, 0x674, 0x4e0, 0x768, 0x0, 0x3e4, 0x6f4, 0x598, 0x598, 0x4f4, 0x4e0, 0x768, 0x86c, 0x3e4, 0x5a0, 0x670, 0x610, 0x5a0, 0x3e0, 0x0, 0x0, 0x4cc, 0x3d0, 0x3d4, 0x450, 0x454, 0x54c, 0x768, 0x868, 0x5d0, 0x5d4, 0x75c, 0x760, 0x5e0, 0x5e4, 0x7ec, 0x86c, 0x650, 0x654, 0x658, 0x65c, 0x660, 0x664, 0x86c, 0x0, 0x7ec, 0x6d4, 0x6d8, 0x6dc, 0x6e0, 0x7e8, 0x0, 0x0, 0x0, 0x7ec, 0x968, 0x968, 0x7e8, 0x0, 0x0]),
    MapChangeRecord(id: 2, xOrigin: 7, yOrigin: 7, xSize: 4, ySize: 5, tiles: [0x618, 0x59c, 0x59c, 0x61c, 0x618, 0x59c, 0x59c, 0x61c, 0x0, 0x76c, 0x0, 0x464, 0x3e0, 0x0, 0x0, 0x3e4, 0x618, 0x59c, 0x59c, 0x61c]),
    MapChangeRecord(id: 3, xOrigin: 15, yOrigin: 2, xSize: 6, ySize: 17, tiles: [0x868, 0x0, 0x0, 0x0, 0x86c, 0x868, 0x868, 0x868, 0x0, 0x86c, 0x64c, 0x668, 0x47c, 0x7ec, 0x7e8, 0x86c, 0x378, 0x6e4, 0x4fc, 0x7ec, 0x7e8, 0x3ec, 0x3f0, 0x3f4, 0x460, 0x7ec, 0x468, 0x46c, 0x470, 0x474, 0x4e0, 0x0, 0x4e8, 0x5a0, 0x578, 0x598, 0x4e0, 0x0, 0x568, 0x6f8, 0x4f4, 0x4f4, 0x4e0, 0x0, 0x5e8, 0x6f4, 0x4f4, 0x58c, 0x618, 0x59c, 0x61c, 0x6f4, 0x4f4, 0x60c, 0x4e0, 0x0, 0x464, 0x6f4, 0x4f4, 0x58c, 0x4e0, 0x0, 0x3e4, 0x6f4, 0x4f4, 0x60c, 0x3e0, 0x0, 0x464, 0x6f4, 0x4f4, 0x4f4, 0x54c, 0x0, 0x3e4, 0x5a0, 0x670, 0x4f4, 0x5e4, 0x7ec, 0x4cc, 0x3d0, 0x560, 0x55c, 0x664, 0x7ec, 0x5d0, 0x5d4, 0x5d8, 0x5dc, 0x7e8, 0x0, 0x650, 0x654, 0x658, 0x65c, 0x0, 0x0, 0x7ec, 0x6d4, 0x6d8, 0x6dc]),
  ],
  // Ch12EirikaMapChanges
  'Ch12EirikaMapChanges': [
    MapChangeRecord(id: 0, xOrigin: 6, yOrigin: 10, xSize: 1, ySize: 1, tiles: [0xe18]),
    MapChangeRecord(id: 1, xOrigin: 5, yOrigin: 12, xSize: 1, ySize: 1, tiles: [0xe18]),
    MapChangeRecord(id: 2, xOrigin: 6, yOrigin: 10, xSize: 1, ySize: 1, tiles: [0xc18]),
    MapChangeRecord(id: 3, xOrigin: 5, yOrigin: 12, xSize: 1, ySize: 1, tiles: [0xc18]),
  ],
  // Ch12EphraimMapChanges
  'Ch12EphraimMapChanges': [
    MapChangeRecord(id: 0, xOrigin: 4, yOrigin: 4, xSize: 3, ySize: 2, tiles: [0xb90, 0xb94, 0xb84, 0xc10, 0xc14, 0xc04]),
    MapChangeRecord(id: 1, xOrigin: 5, yOrigin: 5, xSize: 1, ySize: 1, tiles: [0x80]),
  ],
  // Ch13EphraimMapChanges
  'Ch13EphraimMapChanges': [
    MapChangeRecord(id: 0, xOrigin: 3, yOrigin: 16, xSize: 3, ySize: 3, tiles: [0xe1c, 0xe20, 0xe24, 0xe9c, 0xea0, 0xea4, 0xf1c, 0xf20, 0xf24]),
    MapChangeRecord(id: 1, xOrigin: 16, yOrigin: 11, xSize: 3, ySize: 3, tiles: [0xe1c, 0xe20, 0xe24, 0xe9c, 0xea0, 0xea4, 0xf1c, 0xf20, 0xf24]),
    MapChangeRecord(id: 2, xOrigin: 4, yOrigin: 18, xSize: 1, ySize: 1, tiles: [0x80]),
    MapChangeRecord(id: 3, xOrigin: 17, yOrigin: 13, xSize: 1, ySize: 1, tiles: [0x80]),
    MapChangeRecord(id: 4, xOrigin: 10, yOrigin: 17, xSize: 1, ySize: 3, tiles: [0x28, 0x10, 0x2c]),
  ],
  // Ch14EirikaMapChanges
  'Ch14EirikaMapChanges': [
    MapChangeRecord(id: 0, xOrigin: 19, yOrigin: 0, xSize: 6, ySize: 10, tiles: [0x6a8, 0x6a8, 0x6a8, 0x6a8, 0x6a8, 0x0, 0x0, 0xce4, 0xc48, 0xc48, 0xc48, 0x0, 0x0, 0x0, 0xc40, 0xc44, 0xc44, 0x0, 0x0, 0x0, 0xc40, 0x184, 0xc40, 0x0, 0x0, 0x0, 0xc40, 0xc48, 0xc44, 0x0, 0x0, 0x0, 0xc40, 0x184, 0xc40, 0x0, 0x0, 0x0, 0xc40, 0xc48, 0xc44, 0x0, 0x0, 0x0, 0xc40, 0xc44, 0xc44, 0x0, 0x0, 0x0, 0x0, 0xc40, 0x0, 0x0, 0x0, 0x0, 0x0, 0xcd8, 0x0, 0x0]),
    MapChangeRecord(id: 1, xOrigin: 21, yOrigin: 11, xSize: 3, ySize: 7, tiles: [0x804, 0xc40, 0x604, 0xc4c, 0xc44, 0xc48, 0xc40, 0xc44, 0xc44, 0xc40, 0xc44, 0xc44, 0xc40, 0xc44, 0xc44, 0xc40, 0xc44, 0xc44, 0x0, 0xc40, 0x0]),
    MapChangeRecord(id: 2, xOrigin: 17, yOrigin: 2, xSize: 2, ySize: 1, tiles: [0xcd0, 0xcd8]),
    MapChangeRecord(id: 3, xOrigin: 16, yOrigin: 14, xSize: 4, ySize: 6, tiles: [0x6a8, 0x6a8, 0x6a8, 0x6a8, 0xcc8, 0xc48, 0xc48, 0xc48, 0xc44, 0xc44, 0x184, 0xc40, 0xc40, 0xc44, 0xc48, 0xc44, 0xc40, 0xc44, 0xc44, 0xc44, 0x0, 0xc40, 0x0, 0x0]),
    MapChangeRecord(id: 4, xOrigin: 10, yOrigin: 14, xSize: 1, ySize: 1, tiles: [0xcd0]),
    MapChangeRecord(id: 5, xOrigin: 6, yOrigin: 19, xSize: 7, ySize: 6, tiles: [0x6a8, 0x6a8, 0x6a8, 0x6a8, 0x6a8, 0x6a8, 0x730, 0xc4c, 0xc48, 0x184, 0xc4c, 0x184, 0xc4c, 0xc48, 0xc40, 0xc44, 0xc48, 0xc44, 0xc48, 0xc44, 0xc44, 0xd48, 0xc44, 0xc44, 0xc44, 0xc44, 0xc44, 0xc44, 0xc44, 0xc44, 0xc44, 0xc44, 0xc44, 0xc44, 0xc44, 0x0, 0x0, 0x0, 0xc40, 0x0, 0x0, 0x0]),
    MapChangeRecord(id: 6, xOrigin: 1, yOrigin: 14, xSize: 4, ySize: 6, tiles: [0x6a8, 0x6a8, 0x6a8, 0x6a8, 0xc4c, 0xc48, 0xc48, 0xc48, 0xc40, 0x184, 0xc40, 0xc44, 0xc40, 0xc48, 0xc44, 0xc44, 0xc40, 0xc44, 0xc44, 0xc44, 0x0, 0xc40, 0x0, 0x0]),
    MapChangeRecord(id: 7, xOrigin: 22, yOrigin: 3, xSize: 1, ySize: 1, tiles: [0x104]),
    MapChangeRecord(id: 8, xOrigin: 22, yOrigin: 5, xSize: 1, ySize: 1, tiles: [0x104]),
    MapChangeRecord(id: 9, xOrigin: 20, yOrigin: 11, xSize: 4, ySize: 6, tiles: [0x0, 0x804, 0xcd0, 0x604, 0x8a4, 0xc4c, 0xc44, 0xc48, 0xce4, 0xc44, 0xc44, 0xc44, 0x0, 0xc40, 0xc44, 0xc44, 0x0, 0xc40, 0xc44, 0xc44, 0x0, 0xc40, 0xc44, 0xc44]),
    MapChangeRecord(id: 10, xOrigin: 18, yOrigin: 16, xSize: 1, ySize: 1, tiles: [0x104]),
    MapChangeRecord(id: 11, xOrigin: 8, yOrigin: 20, xSize: 1, ySize: 1, tiles: [0x104]),
    MapChangeRecord(id: 12, xOrigin: 2, yOrigin: 16, xSize: 1, ySize: 1, tiles: [0x104]),
    MapChangeRecord(id: 13, xOrigin: 10, yOrigin: 20, xSize: 1, ySize: 1, tiles: [0x104]),
  ],
  // Ch14EphraimMapChanges
  'Ch14EphraimMapChanges': [
    MapChangeRecord(id: 0, xOrigin: 13, yOrigin: 7, xSize: 3, ySize: 2, tiles: [0x680, 0x684, 0x684, 0x680, 0x684, 0x684]),
    MapChangeRecord(id: 1, xOrigin: 6, yOrigin: 12, xSize: 3, ySize: 3, tiles: [0x980, 0x80c, 0x890, 0x984, 0xa94, 0x80c, 0x984, 0x88c, 0x88c]),
    MapChangeRecord(id: 2, xOrigin: 20, yOrigin: 12, xSize: 3, ySize: 3, tiles: [0x904, 0x88c, 0x88c, 0x980, 0x80c, 0x80c, 0x984, 0x888, 0x810]),
    MapChangeRecord(id: 3, xOrigin: 13, yOrigin: 20, xSize: 3, ySize: 2, tiles: [0x680, 0x684, 0x684, 0x680, 0x684, 0x684]),
    MapChangeRecord(id: 4, xOrigin: 13, yOrigin: 18, xSize: 1, ySize: 1, tiles: [0x4]),
    MapChangeRecord(id: 5, xOrigin: 15, yOrigin: 18, xSize: 1, ySize: 1, tiles: [0x4]),
    MapChangeRecord(id: 6, xOrigin: 3, yOrigin: 1, xSize: 1, ySize: 1, tiles: [0x4]),
    MapChangeRecord(id: 7, xOrigin: 27, yOrigin: 1, xSize: 1, ySize: 1, tiles: [0x4]),
    MapChangeRecord(id: 8, xOrigin: 14, yOrigin: 18, xSize: 1, ySize: 1, tiles: [0x4]),
  ],
  // Ch15MapChanges
  'Ch15MapChanges': [
    MapChangeRecord(id: 0, xOrigin: 0, yOrigin: 12, xSize: 3, ySize: 3, tiles: [0xec8, 0xecc, 0xed0, 0xf48, 0xf4c, 0xf50, 0xfc8, 0xfcc, 0xfd0]),
    MapChangeRecord(id: 1, xOrigin: 1, yOrigin: 14, xSize: 1, ySize: 1, tiles: [0xe50]),
  ],
  // Ch16MapChanges
  'Ch16MapChanges': [
    MapChangeRecord(id: 0, xOrigin: 3, yOrigin: 3, xSize: 2, ySize: 2, tiles: [0x740, 0xc40, 0x0, 0xc44]),
    MapChangeRecord(id: 1, xOrigin: 2, yOrigin: 10, xSize: 3, ySize: 2, tiles: [0x8a4, 0xc40, 0x7b0, 0x0, 0xc44, 0x0]),
    MapChangeRecord(id: 2, xOrigin: 3, yOrigin: 12, xSize: 1, ySize: 1, tiles: [0x4]),
    MapChangeRecord(id: 3, xOrigin: 20, yOrigin: 1, xSize: 1, ySize: 1, tiles: [0x4]),
    MapChangeRecord(id: 4, xOrigin: 20, yOrigin: 3, xSize: 1, ySize: 1, tiles: [0x4]),
    MapChangeRecord(id: 5, xOrigin: 1, yOrigin: 4, xSize: 1, ySize: 1, tiles: [0xc40]),
    MapChangeRecord(id: 6, xOrigin: 20, yOrigin: 5, xSize: 1, ySize: 1, tiles: [0x4]),
    MapChangeRecord(id: 7, xOrigin: 13, yOrigin: 2, xSize: 1, ySize: 2, tiles: [0xf68, 0x68c]),
    MapChangeRecord(id: 8, xOrigin: 14, yOrigin: 2, xSize: 2, ySize: 2, tiles: [0xfdc, 0x0, 0x9c0, 0xc2c]),
  ],
  // Ch17MapChanges
  'Ch17MapChanges': [
    MapChangeRecord(id: 0, xOrigin: 4, yOrigin: 14, xSize: 1, ySize: 3, tiles: [0x1c, 0x9c, 0x2c]),
    MapChangeRecord(id: 1, xOrigin: 15, yOrigin: 13, xSize: 3, ySize: 1, tiles: [0x110, 0x94, 0x114]),
    MapChangeRecord(id: 2, xOrigin: 12, yOrigin: 2, xSize: 1, ySize: 1, tiles: [0xe0c]),
    MapChangeRecord(id: 3, xOrigin: 1, yOrigin: 20, xSize: 1, ySize: 1, tiles: [0xe0c]),
  ],
  // Ch19MapChanges
  'Ch19MapChanges': [
    MapChangeRecord(id: 0, xOrigin: 2, yOrigin: 11, xSize: 1, ySize: 1, tiles: [0x4]),
    MapChangeRecord(id: 1, xOrigin: 3, yOrigin: 12, xSize: 1, ySize: 1, tiles: [0x4]),
    MapChangeRecord(id: 2, xOrigin: 4, yOrigin: 11, xSize: 1, ySize: 1, tiles: [0x4]),
    MapChangeRecord(id: 3, xOrigin: 27, yOrigin: 10, xSize: 1, ySize: 1, tiles: [0x4]),
    MapChangeRecord(id: 4, xOrigin: 27, yOrigin: 12, xSize: 1, ySize: 1, tiles: [0x4]),
    MapChangeRecord(id: 5, xOrigin: 27, yOrigin: 14, xSize: 1, ySize: 1, tiles: [0x4]),
    MapChangeRecord(id: 6, xOrigin: 3, yOrigin: 15, xSize: 1, ySize: 2, tiles: [0xb40, 0xb44]),
  ],
  // Ch2TileChanges
  'Ch2TileChanges': [
    MapChangeRecord(id: 0, xOrigin: 3, yOrigin: 0, xSize: 3, ySize: 3, tiles: [0xe1c, 0xe20, 0xe24, 0xe9c, 0xea0, 0xea4, 0xf1c, 0xf20, 0xf24]),
    MapChangeRecord(id: 1, xOrigin: 6, yOrigin: 0, xSize: 3, ySize: 3, tiles: [0xe1c, 0xe20, 0xe24, 0xe9c, 0xea0, 0xea4, 0xf1c, 0xf20, 0xf24]),
    MapChangeRecord(id: 2, xOrigin: 11, yOrigin: 1, xSize: 3, ySize: 3, tiles: [0xe1c, 0xe20, 0xe24, 0xe9c, 0xea0, 0xea4, 0xf1c, 0xf20, 0xf24]),
    MapChangeRecord(id: 3, xOrigin: 0, yOrigin: 10, xSize: 3, ySize: 3, tiles: [0xe1c, 0xe20, 0xe24, 0xe9c, 0xea0, 0xea4, 0xf1c, 0xf20, 0xf24]),
    MapChangeRecord(id: 4, xOrigin: 4, yOrigin: 2, xSize: 1, ySize: 1, tiles: [0x80]),
    MapChangeRecord(id: 5, xOrigin: 7, yOrigin: 2, xSize: 1, ySize: 1, tiles: [0x80]),
    MapChangeRecord(id: 6, xOrigin: 12, yOrigin: 3, xSize: 1, ySize: 1, tiles: [0x80]),
    MapChangeRecord(id: 7, xOrigin: 1, yOrigin: 12, xSize: 1, ySize: 1, tiles: [0x80]),
  ],
  // Ch3MapChanges
  'Ch3MapChanges': [
    MapChangeRecord(id: 0, xOrigin: 4, yOrigin: 8, xSize: 2, ySize: 2, tiles: [0xa38, 0x0, 0x690, 0x710]),
    MapChangeRecord(id: 1, xOrigin: 4, yOrigin: 11, xSize: 2, ySize: 2, tiles: [0xa38, 0x0, 0x690, 0x710]),
    MapChangeRecord(id: 2, xOrigin: 8, yOrigin: 7, xSize: 2, ySize: 2, tiles: [0xa38, 0x0, 0x690, 0x838]),
    MapChangeRecord(id: 3, xOrigin: 2, yOrigin: 3, xSize: 1, ySize: 2, tiles: [0x8bc, 0x934]),
    MapChangeRecord(id: 4, xOrigin: 6, yOrigin: 10, xSize: 1, ySize: 1, tiles: [0x718]),
    MapChangeRecord(id: 5, xOrigin: 10, yOrigin: 5, xSize: 1, ySize: 1, tiles: [0x8bc]),
    MapChangeRecord(id: 6, xOrigin: 6, yOrigin: 3, xSize: 1, ySize: 1, tiles: [0x100]),
    MapChangeRecord(id: 7, xOrigin: 8, yOrigin: 3, xSize: 1, ySize: 1, tiles: [0x100]),
    MapChangeRecord(id: 8, xOrigin: 10, yOrigin: 3, xSize: 1, ySize: 1, tiles: [0x100]),
    MapChangeRecord(id: 9, xOrigin: 6, yOrigin: 12, xSize: 1, ySize: 1, tiles: [0x100]),
  ],
  // Ch4MapChanges
  'Ch4MapChanges': [
    MapChangeRecord(id: 0, xOrigin: 7, yOrigin: 0, xSize: 3, ySize: 3, tiles: [0xe1c, 0xe20, 0xe24, 0xe9c, 0xea0, 0xea4, 0xf1c, 0xf20, 0xf24]),
    MapChangeRecord(id: 1, xOrigin: 4, yOrigin: 8, xSize: 1, ySize: 3, tiles: [0x1c, 0x10, 0x2c]),
    MapChangeRecord(id: 2, xOrigin: 0, yOrigin: 9, xSize: 3, ySize: 3, tiles: [0xe1c, 0xe20, 0xe24, 0xe9c, 0xea0, 0xea4, 0xf1c, 0xf20, 0xf24]),
    MapChangeRecord(id: 3, xOrigin: 8, yOrigin: 2, xSize: 1, ySize: 1, tiles: [0x80]),
    MapChangeRecord(id: 4, xOrigin: 4, yOrigin: 8, xSize: 1, ySize: 3, tiles: [0x1c, 0x10, 0x2c]),
    MapChangeRecord(id: 5, xOrigin: 1, yOrigin: 11, xSize: 1, ySize: 1, tiles: [0x80]),
  ],
  // Ch5MapChanges
  'Ch5MapChanges': [
    MapChangeRecord(id: 0, xOrigin: 4, yOrigin: 0, xSize: 3, ySize: 2, tiles: [0xb90, 0xb94, 0xc88, 0xc10, 0xc14, 0xd08]),
    MapChangeRecord(id: 1, xOrigin: 4, yOrigin: 5, xSize: 3, ySize: 2, tiles: [0xb90, 0xb94, 0xc88, 0xc10, 0xc14, 0xd08]),
    MapChangeRecord(id: 2, xOrigin: 11, yOrigin: 9, xSize: 3, ySize: 2, tiles: [0xb90, 0xb94, 0xc88, 0xc10, 0xc14, 0xd08]),
    MapChangeRecord(id: 3, xOrigin: 11, yOrigin: 18, xSize: 3, ySize: 2, tiles: [0xc88, 0xb94, 0xb98, 0xd08, 0xc14, 0xc18]),
    MapChangeRecord(id: 4, xOrigin: 5, yOrigin: 1, xSize: 1, ySize: 1, tiles: [0x80]),
    MapChangeRecord(id: 5, xOrigin: 5, yOrigin: 6, xSize: 1, ySize: 1, tiles: [0x80]),
    MapChangeRecord(id: 6, xOrigin: 12, yOrigin: 10, xSize: 1, ySize: 1, tiles: [0x80]),
    MapChangeRecord(id: 7, xOrigin: 12, yOrigin: 19, xSize: 1, ySize: 1, tiles: [0x80]),
  ],
  // Ch5XMapChanges
  'Ch5XMapChanges': [
    MapChangeRecord(id: 0, xOrigin: 4, yOrigin: 8, xSize: 1, ySize: 1, tiles: [0x4]),
    MapChangeRecord(id: 1, xOrigin: 5, yOrigin: 8, xSize: 1, ySize: 1, tiles: [0x4]),
    MapChangeRecord(id: 2, xOrigin: 4, yOrigin: 10, xSize: 1, ySize: 1, tiles: [0xcd0]),
  ],
  // Ch6MapChanges
  'Ch6MapChanges': [
    MapChangeRecord(id: 0, xOrigin: 10, yOrigin: 16, xSize: 3, ySize: 3, tiles: [0xe1c, 0xe20, 0xe24, 0xe9c, 0xea0, 0xea4, 0xf1c, 0xf20, 0xf24]),
    MapChangeRecord(id: 1, xOrigin: 11, yOrigin: 18, xSize: 1, ySize: 1, tiles: [0x80]),
  ],
  // Ch8MapChanges
  'Ch8MapChanges': [
    MapChangeRecord(id: 0, xOrigin: 20, yOrigin: 7, xSize: 1, ySize: 1, tiles: [0xcd0]),
    MapChangeRecord(id: 1, xOrigin: 4, yOrigin: 6, xSize: 2, ySize: 3, tiles: [0x748, 0x0, 0x7c8, 0x0, 0xce4, 0xcd4]),
    MapChangeRecord(id: 2, xOrigin: 1, yOrigin: 5, xSize: 1, ySize: 1, tiles: [0xcd0]),
    MapChangeRecord(id: 3, xOrigin: 1, yOrigin: 3, xSize: 1, ySize: 1, tiles: [0x4]),
    MapChangeRecord(id: 4, xOrigin: 2, yOrigin: 3, xSize: 1, ySize: 1, tiles: [0x4]),
    MapChangeRecord(id: 5, xOrigin: 18, yOrigin: 21, xSize: 4, ySize: 3, tiles: [0x36c, 0x370, 0x374, 0x378, 0x3ec, 0x3f0, 0x3f0, 0x3f8, 0x46c, 0x470, 0x474, 0x478]),
    MapChangeRecord(id: 6, xOrigin: 19, yOrigin: 4, xSize: 1, ySize: 1, tiles: [0x4]),
  ],
  // Ch9EirikaMapChanges
  'Ch9EirikaMapChanges': [
    MapChangeRecord(id: 0, xOrigin: 0, yOrigin: 10, xSize: 3, ySize: 2, tiles: [0xb90, 0xb94, 0xb98, 0xc10, 0xc14, 0xc18]),
    MapChangeRecord(id: 1, xOrigin: 10, yOrigin: 14, xSize: 3, ySize: 2, tiles: [0xb90, 0xb94, 0xb98, 0xc10, 0xc14, 0xc18]),
    MapChangeRecord(id: 2, xOrigin: 1, yOrigin: 11, xSize: 1, ySize: 1, tiles: [0xe04]),
    MapChangeRecord(id: 3, xOrigin: 11, yOrigin: 15, xSize: 1, ySize: 1, tiles: [0xe04]),
  ],
  // Ch9EphMapChanges
  'Ch9EphMapChanges': [
    MapChangeRecord(id: 0, xOrigin: 12, yOrigin: 17, xSize: 2, ySize: 2, tiles: [0xcd0, 0xcd4, 0xcd0, 0xcd4]),
    MapChangeRecord(id: 1, xOrigin: 13, yOrigin: 1, xSize: 2, ySize: 2, tiles: [0x7a8, 0x0, 0xce4, 0xcd4]),
    MapChangeRecord(id: 2, xOrigin: 12, yOrigin: 3, xSize: 1, ySize: 2, tiles: [0xcd0, 0xcd8]),
    MapChangeRecord(id: 3, xOrigin: 7, yOrigin: 1, xSize: 1, ySize: 1, tiles: [0x104]),
    MapChangeRecord(id: 4, xOrigin: 18, yOrigin: 1, xSize: 1, ySize: 1, tiles: [0x104]),
    MapChangeRecord(id: 5, xOrigin: 23, yOrigin: 1, xSize: 1, ySize: 1, tiles: [0x104]),
  ],
  // FinalChapterMap1Changes
  'FinalChapterMap1Changes': [
    MapChangeRecord(id: 0, xOrigin: 4, yOrigin: 19, xSize: 1, ySize: 2, tiles: [0xcd4, 0xc50]),
    MapChangeRecord(id: 1, xOrigin: 18, yOrigin: 19, xSize: 1, ySize: 2, tiles: [0xd50, 0xdd0]),
    MapChangeRecord(id: 2, xOrigin: 21, yOrigin: 18, xSize: 1, ySize: 1, tiles: [0x4]),
    MapChangeRecord(id: 3, xOrigin: 2, yOrigin: 18, xSize: 1, ySize: 1, tiles: [0x4]),
  ],
  // GradoPrisonMapChanges
  'GradoPrisonMapChanges': [
    MapChangeRecord(id: 0, xOrigin: 18, yOrigin: 6, xSize: 2, ySize: 2, tiles: [0x780, 0x788, 0x780, 0x788]),
  ],
  // GradoShrineMapChangesPast
  'GradoShrineMapChangesPast': [
    MapChangeRecord(id: 0, xOrigin: 5, yOrigin: 2, xSize: 1, ySize: 2, tiles: [0xde8, 0xe68]),
    MapChangeRecord(id: 1, xOrigin: 9, yOrigin: 2, xSize: 1, ySize: 2, tiles: [0xde4, 0xe64]),
  ],
  // LagdouRuins10MapChanges
  'LagdouRuins10MapChanges': [
    MapChangeRecord(id: 0, xOrigin: 9, yOrigin: 2, xSize: 1, ySize: 1, tiles: [0x4]),
  ],
  // LagdouRuins1MapChanges
  'LagdouRuins1MapChanges': [
    MapChangeRecord(id: 0, xOrigin: 4, yOrigin: 3, xSize: 2, ySize: 1, tiles: [0xdd0, 0x0]),
  ],
  // LagdouRuins2MapChanges
  'LagdouRuins2MapChanges': [
    MapChangeRecord(id: 0, xOrigin: 9, yOrigin: 13, xSize: 2, ySize: 3, tiles: [0xd18, 0x0, 0x654, 0x0, 0xe3c, 0xfbc]),
  ],
  // LagdouRuins3MapChanges
  'LagdouRuins3MapChanges': [
    MapChangeRecord(id: 0, xOrigin: 1, yOrigin: 2, xSize: 1, ySize: 1, tiles: [0x4]),
    MapChangeRecord(id: 1, xOrigin: 3, yOrigin: 1, xSize: 2, ySize: 2, tiles: [0xd18, 0x0, 0xe3c, 0xfb8]),
    MapChangeRecord(id: 2, xOrigin: 1, yOrigin: 7, xSize: 1, ySize: 1, tiles: [0xeb8]),
    MapChangeRecord(id: 3, xOrigin: 8, yOrigin: 6, xSize: 2, ySize: 1, tiles: [0xeb8, 0xfbc]),
    MapChangeRecord(id: 4, xOrigin: 14, yOrigin: 0, xSize: 3, ySize: 2, tiles: [0xc18, 0xc18, 0xc18, 0x0, 0xe3c, 0xe3c]),
    MapChangeRecord(id: 5, xOrigin: 15, yOrigin: 3, xSize: 2, ySize: 2, tiles: [0xd18, 0x0, 0xe3c, 0xfb8]),
    MapChangeRecord(id: 6, xOrigin: 17, yOrigin: 3, xSize: 1, ySize: 1, tiles: [0x4]),
    MapChangeRecord(id: 7, xOrigin: 17, yOrigin: 8, xSize: 1, ySize: 1, tiles: [0xeb8]),
    MapChangeRecord(id: 8, xOrigin: 8, yOrigin: 10, xSize: 1, ySize: 2, tiles: [0xeb8, 0xfbc]),
    MapChangeRecord(id: 9, xOrigin: 1, yOrigin: 15, xSize: 1, ySize: 2, tiles: [0xeb8, 0xfbc]),
    MapChangeRecord(id: 10, xOrigin: 1, yOrigin: 22, xSize: 1, ySize: 1, tiles: [0xebc]),
    MapChangeRecord(id: 11, xOrigin: 15, yOrigin: 15, xSize: 1, ySize: 1, tiles: [0x4]),
    MapChangeRecord(id: 12, xOrigin: 17, yOrigin: 13, xSize: 2, ySize: 2, tiles: [0xd18, 0xeb8, 0xe3c, 0xfb8]),
  ],
  // LagdouRuins4MapChanges
  'LagdouRuins4MapChanges': [
    MapChangeRecord(id: 0, xOrigin: 4, yOrigin: 3, xSize: 2, ySize: 3, tiles: [0xd18, 0x0, 0x650, 0x0, 0xe3c, 0xfbc]),
    MapChangeRecord(id: 1, xOrigin: 12, yOrigin: 2, xSize: 3, ySize: 3, tiles: [0xdac, 0xebc, 0xc20, 0x5d4, 0xebc, 0xd98, 0x0, 0xfbc, 0x0]),
    MapChangeRecord(id: 2, xOrigin: 18, yOrigin: 2, xSize: 1, ySize: 1, tiles: [0x4]),
    MapChangeRecord(id: 3, xOrigin: 1, yOrigin: 26, xSize: 1, ySize: 1, tiles: [0x4]),
    MapChangeRecord(id: 4, xOrigin: 1, yOrigin: 9, xSize: 2, ySize: 3, tiles: [0xc24, 0xebc, 0x5d4, 0xebc, 0x0, 0xfbc]),
    MapChangeRecord(id: 5, xOrigin: 7, yOrigin: 9, xSize: 3, ySize: 3, tiles: [0xc24, 0xebc, 0xc90, 0x5d4, 0xebc, 0x0, 0x0, 0xfbc, 0x0]),
    MapChangeRecord(id: 6, xOrigin: 12, yOrigin: 9, xSize: 2, ySize: 3, tiles: [0xc94, 0xeb8, 0x0, 0xeb8, 0x0, 0xeb8]),
    MapChangeRecord(id: 7, xOrigin: 1, yOrigin: 13, xSize: 2, ySize: 3, tiles: [0xc24, 0xebc, 0x5d4, 0xebc, 0x0, 0xfbc]),
    MapChangeRecord(id: 8, xOrigin: 4, yOrigin: 9, xSize: 2, ySize: 3, tiles: [0xc18, 0xc18, 0xd9c, 0xd9c, 0xe3c, 0xe3c]),
    MapChangeRecord(id: 9, xOrigin: 6, yOrigin: 13, xSize: 2, ySize: 3, tiles: [0xd18, 0x0, 0x654, 0x0, 0xe3c, 0xfbc]),
    MapChangeRecord(id: 10, xOrigin: 11, yOrigin: 13, xSize: 2, ySize: 3, tiles: [0xd18, 0x0, 0x654, 0x0, 0xe3c, 0xfbc]),
    MapChangeRecord(id: 11, xOrigin: 4, yOrigin: 17, xSize: 2, ySize: 3, tiles: [0xd18, 0x0, 0x654, 0x0, 0xe3c, 0xfbc]),
    MapChangeRecord(id: 12, xOrigin: 7, yOrigin: 16, xSize: 3, ySize: 3, tiles: [0xc24, 0xebc, 0xc90, 0x5d4, 0xebc, 0x0, 0x0, 0xfbc, 0x0]),
    MapChangeRecord(id: 13, xOrigin: 14, yOrigin: 16, xSize: 2, ySize: 3, tiles: [0xeb8, 0xd18, 0xebc, 0x654, 0xec4, 0x0]),
    MapChangeRecord(id: 14, xOrigin: 16, yOrigin: 15, xSize: 3, ySize: 3, tiles: [0xdac, 0xebc, 0xc90, 0x5d4, 0xebc, 0x0, 0x0, 0xfbc, 0x0]),
    MapChangeRecord(id: 15, xOrigin: 6, yOrigin: 20, xSize: 2, ySize: 3, tiles: [0xc24, 0xebc, 0x5d4, 0xebc, 0x0, 0xfbc]),
    MapChangeRecord(id: 16, xOrigin: 11, yOrigin: 20, xSize: 2, ySize: 3, tiles: [0xc94, 0xebc, 0x0, 0xebc, 0x0, 0xeb8]),
    MapChangeRecord(id: 17, xOrigin: 9, yOrigin: 24, xSize: 2, ySize: 3, tiles: [0xc24, 0xebc, 0x5d4, 0xebc, 0x0, 0xfbc]),
  ],
  // LagdouRuins5MapChanges
  'LagdouRuins5MapChanges': [
    MapChangeRecord(id: 0, xOrigin: 4, yOrigin: 4, xSize: 1, ySize: 1, tiles: [0x4]),
    MapChangeRecord(id: 1, xOrigin: 13, yOrigin: 10, xSize: 1, ySize: 1, tiles: [0x4]),
    MapChangeRecord(id: 2, xOrigin: 17, yOrigin: 21, xSize: 1, ySize: 1, tiles: [0x4]),
    MapChangeRecord(id: 3, xOrigin: 0, yOrigin: 6, xSize: 2, ySize: 3, tiles: [0xe14, 0xebc, 0x0, 0xebc, 0x0, 0xeb8]),
    MapChangeRecord(id: 4, xOrigin: 8, yOrigin: 5, xSize: 2, ySize: 3, tiles: [0xeb8, 0xd18, 0xeb8, 0x654, 0xfbc, 0x0]),
  ],
  // LagdouRuins6MapChanges
  'LagdouRuins6MapChanges': [
    MapChangeRecord(id: 0, xOrigin: 7, yOrigin: 1, xSize: 2, ySize: 2, tiles: [0xd18, 0x0, 0xe3c, 0xfbc]),
    MapChangeRecord(id: 1, xOrigin: 17, yOrigin: 4, xSize: 1, ySize: 2, tiles: [0xebc, 0xfbc]),
    MapChangeRecord(id: 2, xOrigin: 16, yOrigin: 7, xSize: 1, ySize: 1, tiles: [0xebc]),
  ],
  // LagdouRuins7MapChanges
  'LagdouRuins7MapChanges': [
    MapChangeRecord(id: 0, xOrigin: 5, yOrigin: 11, xSize: 1, ySize: 1, tiles: [0x4]),
    MapChangeRecord(id: 1, xOrigin: 14, yOrigin: 17, xSize: 2, ySize: 2, tiles: [0xc18, 0xc18, 0xe3c, 0xe3c]),
    MapChangeRecord(id: 2, xOrigin: 16, yOrigin: 4, xSize: 3, ySize: 2, tiles: [0xc94, 0xebc, 0xc90, 0x0, 0xebc, 0x0]),
  ],
  // LagdouRuins8MapChanges
  'LagdouRuins8MapChanges': [
    MapChangeRecord(id: 0, xOrigin: 0, yOrigin: 15, xSize: 2, ySize: 3, tiles: [0x6cc, 0x25c, 0x6cc, 0x2dc, 0x6cc, 0x2dc]),
    MapChangeRecord(id: 1, xOrigin: 0, yOrigin: 10, xSize: 3, ySize: 2, tiles: [0x6cc, 0x6cc, 0x358, 0x6cc, 0x6cc, 0x2dc]),
    MapChangeRecord(id: 2, xOrigin: 0, yOrigin: 3, xSize: 7, ySize: 2, tiles: [0x6cc, 0x6cc, 0x6cc, 0x6cc, 0x6cc, 0x6cc, 0x2dc, 0x2d8, 0x2d8, 0x6cc, 0x6cc, 0x358, 0x2d8, 0x0]),
    MapChangeRecord(id: 3, xOrigin: 5, yOrigin: 19, xSize: 1, ySize: 2, tiles: [0x6cc, 0x358]),
    MapChangeRecord(id: 4, xOrigin: 9, yOrigin: 15, xSize: 3, ySize: 4, tiles: [0x6cc, 0x6cc, 0x358, 0x6cc, 0x6cc, 0x2dc, 0x6cc, 0x6cc, 0x2dc, 0x6cc, 0x6cc, 0x2dc]),
    MapChangeRecord(id: 5, xOrigin: 9, yOrigin: 9, xSize: 3, ySize: 2, tiles: [0x6cc, 0x6cc, 0x2dc, 0x6cc, 0x6cc, 0x2dc]),
    MapChangeRecord(id: 6, xOrigin: 9, yOrigin: 6, xSize: 3, ySize: 1, tiles: [0x6cc, 0x6cc, 0x0]),
    MapChangeRecord(id: 7, xOrigin: 12, yOrigin: 11, xSize: 3, ySize: 2, tiles: [0x6cc, 0x6cc, 0x6cc, 0x358, 0x2d8, 0x2d8]),
    MapChangeRecord(id: 8, xOrigin: 11, yOrigin: 20, xSize: 2, ySize: 1, tiles: [0x6cc, 0x6cc]),
    MapChangeRecord(id: 9, xOrigin: 15, yOrigin: 13, xSize: 5, ySize: 2, tiles: [0x0, 0x0, 0x0, 0x0, 0x6cc, 0x6cc, 0x6cc, 0x6cc, 0x6cc, 0x6cc]),
    MapChangeRecord(id: 10, xOrigin: 16, yOrigin: 7, xSize: 3, ySize: 1, tiles: [0x6cc, 0x6cc, 0x0]),
    MapChangeRecord(id: 11, xOrigin: 4, yOrigin: 16, xSize: 2, ySize: 2, tiles: [0x6cc, 0x0, 0x6cc, 0x2dc]),
    MapChangeRecord(id: 12, xOrigin: 4, yOrigin: 12, xSize: 1, ySize: 1, tiles: [0x4]),
    MapChangeRecord(id: 13, xOrigin: 16, yOrigin: 5, xSize: 2, ySize: 1, tiles: [0xdb0, 0xd28]),
  ],
  // LagdouRuins9MapChanges
  'LagdouRuins9MapChanges': [
    MapChangeRecord(id: 0, xOrigin: 1, yOrigin: 5, xSize: 3, ySize: 1, tiles: [0x734, 0xb70, 0x730]),
    MapChangeRecord(id: 1, xOrigin: 15, yOrigin: 11, xSize: 3, ySize: 1, tiles: [0x734, 0xb70, 0x730]),
  ],
  // RenaisShrineMapChanges
  'RenaisShrineMapChanges': [
    MapChangeRecord(id: 0, xOrigin: 6, yOrigin: 7, xSize: 3, ySize: 1, tiles: [0xb40, 0xb44, 0xb44]),
  ],
  // RenaisThroneMapChanges
  'RenaisThroneMapChanges': [
    MapChangeRecord(id: 0, xOrigin: 7, yOrigin: 7, xSize: 2, ySize: 1, tiles: [0xc40, 0xc44]),
  ],
  // TowerOfValni3MapChanges
  'TowerOfValni3MapChanges': [
    MapChangeRecord(id: 0, xOrigin: 10, yOrigin: 3, xSize: 1, ySize: 1, tiles: [0x110]),
  ],
  // TowerOfValni5MapChanges
  'TowerOfValni5MapChanges': [
    MapChangeRecord(id: 0, xOrigin: 6, yOrigin: 9, xSize: 1, ySize: 1, tiles: [0x110]),
    MapChangeRecord(id: 1, xOrigin: 14, yOrigin: 14, xSize: 1, ySize: 1, tiles: [0x110]),
  ],
  // TowerOfValni6MapChanges
  'TowerOfValni6MapChanges': [
    MapChangeRecord(id: 0, xOrigin: 5, yOrigin: 3, xSize: 2, ySize: 3, tiles: [0x8d4, 0x0, 0x8cc, 0x0, 0x18, 0x14]),
    MapChangeRecord(id: 1, xOrigin: 8, yOrigin: 0, xSize: 2, ySize: 3, tiles: [0x8d4, 0x0, 0x8cc, 0x0, 0x18, 0x14]),
    MapChangeRecord(id: 2, xOrigin: 10, yOrigin: 1, xSize: 1, ySize: 1, tiles: [0x110]),
    MapChangeRecord(id: 3, xOrigin: 12, yOrigin: 1, xSize: 1, ySize: 1, tiles: [0x110]),
    MapChangeRecord(id: 4, xOrigin: 4, yOrigin: 8, xSize: 2, ySize: 3, tiles: [0x8d4, 0x0, 0x8cc, 0x0, 0x18, 0x14]),
    MapChangeRecord(id: 5, xOrigin: 9, yOrigin: 6, xSize: 3, ySize: 3, tiles: [0x8c8, 0x1c, 0x6c8, 0x8c4, 0x1c, 0x8c0, 0x0, 0x14, 0x0]),
    MapChangeRecord(id: 6, xOrigin: 14, yOrigin: 6, xSize: 3, ySize: 3, tiles: [0x8c8, 0x1c, 0x6c8, 0x8c4, 0x1c, 0x8c0, 0x0, 0x14, 0x0]),
    MapChangeRecord(id: 7, xOrigin: 7, yOrigin: 11, xSize: 2, ySize: 3, tiles: [0x8c8, 0x0, 0x8c4, 0x0, 0x18, 0x14]),
    MapChangeRecord(id: 8, xOrigin: 13, yOrigin: 9, xSize: 2, ySize: 3, tiles: [0x8c8, 0x1c, 0x8c4, 0x1c, 0x0, 0x14]),
    MapChangeRecord(id: 9, xOrigin: 17, yOrigin: 9, xSize: 2, ySize: 3, tiles: [0x8c8, 0x1c, 0x8c4, 0x1c, 0x0, 0x14]),
    MapChangeRecord(id: 10, xOrigin: 2, yOrigin: 18, xSize: 1, ySize: 1, tiles: [0x110]),
    MapChangeRecord(id: 11, xOrigin: 4, yOrigin: 16, xSize: 2, ySize: 3, tiles: [0x8d4, 0x0, 0x8cc, 0x0, 0x18, 0x14]),
    MapChangeRecord(id: 12, xOrigin: 7, yOrigin: 16, xSize: 2, ySize: 3, tiles: [0x8d4, 0x0, 0x8cc, 0x0, 0x18, 0x14]),
    MapChangeRecord(id: 13, xOrigin: 10, yOrigin: 16, xSize: 2, ySize: 3, tiles: [0x8d4, 0x0, 0x8cc, 0x0, 0x18, 0x14]),
    MapChangeRecord(id: 14, xOrigin: 16, yOrigin: 16, xSize: 2, ySize: 3, tiles: [0x6c8, 0x6cc, 0x8c0, 0x844, 0x18, 0x18]),
    MapChangeRecord(id: 15, xOrigin: 18, yOrigin: 16, xSize: 2, ySize: 3, tiles: [0x8c8, 0x1c, 0x8c4, 0x1c, 0x0, 0x14]),
    MapChangeRecord(id: 16, xOrigin: 19, yOrigin: 1, xSize: 1, ySize: 1, tiles: [0x110]),
  ],
  // TowerOfValni7MapChanges
  'TowerOfValni7MapChanges': [
    MapChangeRecord(id: 0, xOrigin: 9, yOrigin: 13, xSize: 1, ySize: 7, tiles: [0x94, 0x94, 0x94, 0x94, 0x94, 0x94, 0x94]),
    MapChangeRecord(id: 1, xOrigin: 17, yOrigin: 12, xSize: 1, ySize: 8, tiles: [0x94, 0x94, 0x94, 0x94, 0x94, 0x94, 0x94, 0x94]),
    MapChangeRecord(id: 2, xOrigin: 22, yOrigin: 4, xSize: 2, ySize: 11, tiles: [0x94, 0x94, 0x94, 0x94, 0x0, 0x94, 0x0, 0x94, 0x0, 0x94, 0x0, 0x94, 0x0, 0x94, 0x0, 0x94, 0x0, 0x94, 0x0, 0x94, 0x0, 0x94]),
    MapChangeRecord(id: 3, xOrigin: 12, yOrigin: 2, xSize: 1, ySize: 4, tiles: [0x94, 0x94, 0x94, 0x94]),
    MapChangeRecord(id: 4, xOrigin: 4, yOrigin: 2, xSize: 3, ySize: 2, tiles: [0x94, 0x94, 0x94, 0x94, 0x94, 0x94]),
  ],
  // TowerOfValni8MapChanges
  'TowerOfValni8MapChanges': [
    MapChangeRecord(id: 0, xOrigin: 11, yOrigin: 8, xSize: 1, ySize: 1, tiles: [0x110]),
  ],
  // UnusedMapChanges11
  'UnusedMapChanges11': [
    MapChangeRecord(id: 0, xOrigin: 14, yOrigin: 10, xSize: 1, ySize: 1, tiles: [0x810]),
    MapChangeRecord(id: 1, xOrigin: 13, yOrigin: 10, xSize: 1, ySize: 1, tiles: [0x810]),
    MapChangeRecord(id: 2, xOrigin: 12, yOrigin: 10, xSize: 1, ySize: 1, tiles: [0x810]),
    MapChangeRecord(id: 3, xOrigin: 11, yOrigin: 10, xSize: 1, ySize: 1, tiles: [0x810]),
    MapChangeRecord(id: 4, xOrigin: 14, yOrigin: 11, xSize: 1, ySize: 1, tiles: [0x100]),
    MapChangeRecord(id: 5, xOrigin: 13, yOrigin: 11, xSize: 1, ySize: 1, tiles: [0x100]),
    MapChangeRecord(id: 6, xOrigin: 12, yOrigin: 11, xSize: 1, ySize: 1, tiles: [0x100]),
    MapChangeRecord(id: 7, xOrigin: 11, yOrigin: 11, xSize: 1, ySize: 1, tiles: [0x100]),
    MapChangeRecord(id: 8, xOrigin: 14, yOrigin: 12, xSize: 1, ySize: 1, tiles: [0x810]),
    MapChangeRecord(id: 9, xOrigin: 13, yOrigin: 12, xSize: 1, ySize: 1, tiles: [0x810]),
    MapChangeRecord(id: 10, xOrigin: 12, yOrigin: 12, xSize: 1, ySize: 1, tiles: [0x810]),
    MapChangeRecord(id: 11, xOrigin: 11, yOrigin: 12, xSize: 1, ySize: 1, tiles: [0x810]),
    MapChangeRecord(id: 12, xOrigin: 14, yOrigin: 13, xSize: 1, ySize: 1, tiles: [0x100]),
    MapChangeRecord(id: 13, xOrigin: 13, yOrigin: 13, xSize: 1, ySize: 1, tiles: [0x100]),
    MapChangeRecord(id: 14, xOrigin: 12, yOrigin: 13, xSize: 1, ySize: 1, tiles: [0x100]),
    MapChangeRecord(id: 15, xOrigin: 11, yOrigin: 13, xSize: 1, ySize: 1, tiles: [0x100]),
    MapChangeRecord(id: 16, xOrigin: 14, yOrigin: 14, xSize: 1, ySize: 1, tiles: [0x810]),
    MapChangeRecord(id: 17, xOrigin: 13, yOrigin: 14, xSize: 1, ySize: 1, tiles: [0x810]),
    MapChangeRecord(id: 18, xOrigin: 12, yOrigin: 14, xSize: 1, ySize: 1, tiles: [0x810]),
    MapChangeRecord(id: 19, xOrigin: 11, yOrigin: 14, xSize: 1, ySize: 1, tiles: [0x810]),
  ],
  // UnusedMapChanges2
  'UnusedMapChanges2': [
    MapChangeRecord(id: 0, xOrigin: 3, yOrigin: 3, xSize: 2, ySize: 2, tiles: [0x740, 0xc40, 0x0, 0xc44]),
    MapChangeRecord(id: 1, xOrigin: 2, yOrigin: 10, xSize: 3, ySize: 2, tiles: [0x8a4, 0xc40, 0x7b0, 0x0, 0xc44, 0x0]),
    MapChangeRecord(id: 2, xOrigin: 3, yOrigin: 12, xSize: 1, ySize: 1, tiles: [0x4]),
    MapChangeRecord(id: 3, xOrigin: 20, yOrigin: 2, xSize: 1, ySize: 1, tiles: [0x4]),
    MapChangeRecord(id: 4, xOrigin: 20, yOrigin: 4, xSize: 1, ySize: 1, tiles: [0x4]),
  ],
  // UnusedMapChanges3
  'UnusedMapChanges3': [
    MapChangeRecord(id: 0, xOrigin: 4, yOrigin: 14, xSize: 1, ySize: 3, tiles: [0x1c, 0x9c, 0x2c]),
    MapChangeRecord(id: 1, xOrigin: 15, yOrigin: 13, xSize: 3, ySize: 1, tiles: [0x110, 0x94, 0x114]),
  ],
  // UnusedMapChanges5
  'UnusedMapChanges5': [
    MapChangeRecord(id: 0, xOrigin: 2, yOrigin: 12, xSize: 1, ySize: 1, tiles: [0x4]),
    MapChangeRecord(id: 1, xOrigin: 4, yOrigin: 12, xSize: 1, ySize: 1, tiles: [0x4]),
    MapChangeRecord(id: 2, xOrigin: 3, yOrigin: 15, xSize: 1, ySize: 2, tiles: [0xb40, 0xb44]),
    MapChangeRecord(id: 3, xOrigin: 27, yOrigin: 12, xSize: 1, ySize: 1, tiles: [0x4]),
    MapChangeRecord(id: 4, xOrigin: 27, yOrigin: 10, xSize: 1, ySize: 1, tiles: [0x4]),
  ],
};
