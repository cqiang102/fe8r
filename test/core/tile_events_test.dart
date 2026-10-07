// 「訪問」规则层的判据。
//
// 出处：`src/bmmenu_08022F50.c:89-118`（`VisitCommandUsability`）、
//       `src/StartAvailableTileEvent.c:24-60`（按 `locationBasedEvents` 匹配）、
//       `include/eventinfo.h:14`（`TILE_COMMAND_VISIT = 0x10`）。
import 'package:fe8r/core/core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const vill = LocationEvent(
      cmd: 'VILL', x: 1, y: 1, cmdId: kTileCommandVisit, doneFlag: 7);

  test('★ 坐标 + cmdId 匹配；`doneFlag` 置位后就不再命中', () {
    expect(availableTileEvent(const [vill], 1, 1, {}), isNotNull);
    expect(availableTileEvent(const [vill], 2, 1, {}), isNull, reason: '坐标不对');
    expect(availableTileEvent(const [vill], 1, 1, {7}), isNull,
        reason: '★ `doneFlag` 置位 ⇒ 同一条村不会再触发');
    expect(availableTileEvent(const [vill], 1, 1, {8}), isNotNull,
        reason: '别的旗不影响');
  });

  test('★ 地形：只有 4 种村/家/废墟能訪問', () {
    bool ok(int terrain) => visitAvailable(
        terrainId: terrain,
        isPhantom: false,
        hasActed: false,
        hasAvailableVill: true);
    expect(ok(3), isTrue, reason: 'TERRAIN_VILLAGE_REGULAR');
    expect(ok(5), isTrue, reason: 'TERRAIN_HOUSE');
    expect(ok(55), isTrue, reason: 'TERRAIN_RUINS_VILLAGE');
    expect(ok(56), isTrue, reason: 'TERRAIN_INN');
    expect(ok(1), isFalse, reason: '平原');
    expect(ok(4), isFalse, reason: 'TERRAIN_VILLAGE_CLOSED（已訪問過的村）');
  });

  test('★ 幻影职业 / 已行动 / 该格没有可用事件 ⇒ 都不出现', () {
    bool ok({bool phantom = false, bool acted = false, bool hasEv = true}) =>
        visitAvailable(
            terrainId: 3,
            isPhantom: phantom,
            hasActed: acted,
            hasAvailableVill: hasEv);
    expect(ok(), isTrue);
    expect(ok(phantom: true), isFalse, reason: '`CLASS_PHANTOM` ⇒ NOTSHOWN');
    expect(ok(acted: true), isFalse, reason: '对应 `US_HAS_MOVED`（见文件头）');
    expect(ok(hasEv: false), isFalse, reason: '该格没有可用 VILL 事件');
  });
  _seizeTests();
  _chestTests();
}

// 制圧（`CanUnitSeize`，`src/masked_08037bfc.c:50-70`）
void _seizeTests() {
  test('★ 领袖：模式 1/2 = 艾莉卡、3 = 艾弗雷姆；第 5 章一律艾弗雷姆', () {
    expect(seizeLeaderId(chapterModeIndex: 1, chapterIndex: 0), kCharacterEirika,
        reason: '教学模式（第 0–8 章）');
    expect(seizeLeaderId(chapterModeIndex: 2, chapterIndex: 9), kCharacterEirika,
        reason: 'Eirika 路线');
    expect(seizeLeaderId(chapterModeIndex: 3, chapterIndex: 9), kCharacterEphraim,
        reason: 'Ephraim 路线');
    expect(seizeLeaderId(chapterModeIndex: 3, chapterIndex: 5), kCharacterEphraim);
    expect(seizeLeaderId(chapterModeIndex: 2, chapterIndex: 5), kCharacterEphraim,
        reason: '★ 第 5 章的特例**压过**路线选择');
  });

  test('★ 模式未知 ⇒ 显式"不知道"，不照抄 C 的未初始化行为', () {
    expect(seizeLeaderId(chapterModeIndex: 0, chapterIndex: 0),
        kSeizeLeaderUnknown);
    expect(seizeLeaderId(chapterModeIndex: 7, chapterIndex: 0),
        kSeizeLeaderUnknown);
  });

  test('★ 可用性三条件：未行动 + 是领袖 + 该格有制圧地块', () {
    bool ok({bool acted = false, bool canSeize = true, bool tile = true}) =>
        seizeAvailable(hasActed: acted, canSeize: canSeize, hasSeizeTile: tile);
    expect(ok(), isTrue);
    expect(ok(acted: true), isFalse, reason: '对应 `US_HAS_MOVED`');
    expect(ok(canSeize: false), isFalse, reason: '不是领袖（`CanUnitSeize` 为假）');
    expect(ok(tile: false), isFalse, reason: '该格没有 `cmdId == 0x11` 的条目');
  });
}

// 宝箱（`src/bmmenu_08023D5C.c:85-97` + `src/bmunit_080187B0.c:39-58`）
void _chestTests() {
  test('★ 钥匙槽：钥匙/钥匙串；盗贼拿撬锁器也认（先查撬锁器）', () {
    int slot({required bool thief, required List<int> items}) =>
        unitKeyItemSlotForTerrain(
            isThief: thief, items: items, terrainId: kTerrainChestFull,
            lockpickItem: 107, chestKeyItem: 105, chestKeyBundleItem: 121);
    expect(slot(thief: false, items: [105, 0, 0]), 0, reason: '宝箱钥匙');
    expect(slot(thief: false, items: [121, 0, 0]), 0, reason: '钥匙串');
    expect(slot(thief: false, items: [105, 121, 0]), 0, reason: '两种都有时先钥匙');
    expect(slot(thief: false, items: [0, 0, 0]), -1, reason: '没有 ⇒ -1');
    expect(slot(thief: true, items: [107, 0, 0]), 0, reason: '盗贼的撬锁器');
    expect(slot(thief: true, items: [105, 107, 0]), 1,
        reason: '★ 盗贼分支**先**查撬锁器（源码顺序），所以返回 1 而不是 0');
    expect(slot(thief: true, items: [105, 0, 0]), 0,
        reason: '盗贼没撬锁器就退回钥匙那条');
  });

  test('★ 可用性：未行动 + 有钥匙/撬锁器 + 站在「满的宝箱」格上且那格有关着的宝箱', () {
    bool ok({bool acted = false, bool key = true, bool closed = true,
        int terrain = kTerrainChestFull}) =>
        chestAvailable(hasActed: acted, hasClosedChestTile: closed,
            hasKeyOrLockpick: key, terrainId: terrain);
    expect(ok(), isTrue);
    expect(ok(acted: true), isFalse, reason: '对应 `US_HAS_MOVED`');
    expect(ok(key: false), isFalse, reason: '没有钥匙/撬锁器');
    expect(ok(closed: false), isFalse, reason: '那格没有关着的宝箱（`IsThereClosedChestAt`）');
    expect(ok(terrain: 1), isFalse, reason: '不是 `TERRAIN_CHEST_FULL`');
  });

  test('`CanUnitUseChestKeyItem` 只看地形 + 关着的宝箱', () {
    expect(canUnitUseChestKeyItem(terrainId: kTerrainChestFull,
        hasClosedChestTile: true), isTrue);
    expect(canUnitUseChestKeyItem(terrainId: kTerrainChestFull,
        hasClosedChestTile: false), isFalse);
    expect(canUnitUseChestKeyItem(terrainId: 1, hasClosedChestTile: true), isFalse);
  });
}
