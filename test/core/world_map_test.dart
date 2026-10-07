// 大地图**规则层**（`WMLoc_GetChapterId` / `WMLoc_GetNextLocId` / `GetPlayChapterId`）
//
// 出处：`src/worldmap_screen2.c:16-28`、`src/WMLoc_GetNextLocId.c:10-33`、
//       `src/worldmap_path_080C1DE8.c:36-52`
//
// 判据都是**正向抽查真值**（对着从 ROM 解出来的 `worldmap.json` 核），
// 不是"没抛异常"。
import 'dart:io';

import 'package:fe8r/core/core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late WorldMapData map;
  late WorldMapRules r;

  setUpAll(() {
    final f = File('tools/pipeline/out/tables/worldmap.json');
    if (!f.existsSync()) fail('缺少 ${f.path}（先跑 parse_worldmap.py）');
    map = WorldMapData.parse(f.readAsStringSync());
    r = WorldMapRules(map);
  });

  test('节点表 29 条；节点 0 = 序章(0x00)、节点 1 = C00(0x38)', () {
    expect(map.nodeCount, 29);
    expect(r.chapterIdOf(0), 0x00, reason: 'CHAPTER_L_PROLOGUE');
    expect(r.chapterIdOf(1), 0x38, reason: 'CHAPTER_CASTLE_FRELIA');
    // 塔/遗迹/海岸也是节点（placementFlag 3 = 迷宫、2 = 遭遇）
    expect(r.chapterIdOf(26), 0x24, reason: 'CHAPTER_T_01');
    expect(r.chapterIdOf(27), 0x2E, reason: 'CHAPTER_R_01');
    expect(r.chapterIdOf(28), 0x39, reason: 'CHAPTER_MALKAEN_COAST');
  });

  test('★ 路线分叉：节点 19 在两模式下是不同章节', () {
    expect(r.chapterIdOf(19, mode: ChapterMode.eirika), 0x0F);
    expect(r.chapterIdOf(19, mode: ChapterMode.ephraim), 0x1C);
  });

  test('★ `WMLoc_GetNextLocId`：条件旗决定用哪一对（`unk_08 + 2`）', () {
    // 节点 0：unk06 = 137，unk_08 = [0, 0, 1, 1]
    expect(r.nextLocIdOf(0), 0, reason: '旗子没置上 → 用前一对 → 0（自身）');
    expect(r.nextLocIdOf(0, checkFlag: (f) => f == 137), 1,
        reason: '旗子置上 → 用后一对 → 1（C00）');
    // 节点 1（C00）：unk06 = 136，unk_08 = [2, 2, 9, 14]
    expect(r.nextLocIdOf(1), 2, reason: '下一个是节点 2（第 2 章）');
    expect(r.nextLocIdOf(1, checkFlag: (f) => f == 136), 9);
    expect(r.nextLocIdOf(1, mode: ChapterMode.ephraim, checkFlag: (f) => f == 136),
        14, reason: '同一对里的第二个 = Ephraim 路线');
    // 没有下一个：-1
    expect(r.nextLocIdOf(25), -1);
  });

  test('★ 章间链（这是 M1 那条链的数据侧判据）', () {
    // 序章 →（旗 137 置上）→ C00 →（旗 136 置上）→ 第 9 章节点
    final flags = {137, 136};
    final n0 = r.nodeIndexOfChapter(0x00);
    expect(n0, 0);
    final n1 = r.nextLocIdOf(n0, checkFlag: flags.contains);
    expect(n1, 1);
    expect(r.chapterIdOf(n1), 0x38, reason: '第 1 章结束剧情 `MNCH(0x38)` 的目标');
    final n9 = r.nextLocIdOf(n1, checkFlag: flags.contains);
    expect(r.chapterIdOf(n9), 0x0A, reason: 'CHAPTER_E_9');
  });

  test('`GetPlayChapterId`：塔/遗迹折算到第一层', () {
    expect(r.nodeIndexOfChapter(0x38), 1);
    expect(r.nodeIndexOfChapter(0x14), 25, reason: 'CHAPTER_E_20');
    expect(r.nodeIndexOfChapter(0x25), 26, reason: 'T02 → T01 那个节点');
    expect(r.nodeIndexOfChapter(0x30), 27, reason: 'R03 → R01 那个节点');
    expect(r.nodeIndexOfChapter(0xFE), -1, reason: '不存在的章节 → -1');
  });

  test('★ 运行时状态：从序章节点走到 C00 节点，且能 JSON 往返', () {
    final st = WorldMapState(node: 0);
    final flags = {137, 136};
    expect(st.chapterId(r), 0x00);
    expect(st.chapterId(r, mode: ChapterMode.ephraim), 0x00);

    final arrived = st.travelToNext(r, flags.contains);
    expect(arrived, 1, reason: '旗 137 → 下一个是 C00 节点');
    expect(st.chapterId(r), 0x38);
    expect(st.cleared, contains(0), reason: '走过的节点记进 cleared');

    // 再走一步：C00 → 第 9 章节点（旗 136）
    expect(st.travelToNext(r, flags.contains), 9);
    expect(st.chapterId(r), 0x0A);

    // 原地不动（下一个是自身 / -1）→ 返回 null
    final stuck = WorldMapState(node: 0);
    expect(stuck.travelToNext(r, (_) => false), isNull,
        reason: '旗没置上时节点 0 的下一个是它自己 ⇒ 不该移动');

    // 可序列化（`lib/core` 的硬要求：任意时刻能存档）
    final back = WorldMapState.fromJson(st.toJson());
    expect(back.node, st.node);
    expect(back.cleared, st.cleared);
  });

  test('路径表也在同一份数据里（20 条、每帧有坐标）', () {
    expect(map.paths.length, 20);
    final p0 = map.paths['gWorldmapPath_0']!;
    expect((p0.first.t, p0.first.x, p0.first.y), (1351, 128, 88));
    expect(p0.length, 2);
  });
}
