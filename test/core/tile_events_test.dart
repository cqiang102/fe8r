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
}
