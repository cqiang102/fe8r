// 救出 / 降下的判据。
//
// 出处：`src/exact_08018030.c:40-45`（`CanUnitRescue`）、
//       `src/exact_080186cc.c:37-44`（`GetUnitAid`）、
//       `src/exact_08018060.c:37-46`（`UnitRescue`）、
//       `src/UnitDrop.c:31-45`（`UnitDrop`）、`src/DropUsability.c:50-66`。
import 'package:fe8r/core/core.dart';
import 'package:flutter_test/flutter_test.dart';

MapUnit u(int id, {int con = 7, int x = 1, int y = 1}) =>
    MapUnit(id: id, faction: 0, x: x, y: y, con: con);

void main() {
  test('★ Aid 三支：非骑乘 CON−1 / 骑乘女 20−CON / 骑乘男 25−CON', () {
    expect(unitAid(con: 7, mountedAid: false, female: false), 6);
    expect(unitAid(con: 7, mountedAid: true, female: true), 13);
    expect(unitAid(con: 7, mountedAid: true, female: false), 18);
  });

  test('★ 能不能救：Aid ≥ 目标的 Con', () {
    expect(canUnitRescue(actorAid: 6, targetCon: 6), isTrue, reason: '相等也算');
    expect(canUnitRescue(actorAid: 6, targetCon: 7), isFalse);
    expect(canUnitRescue(actorAid: 18, targetCon: 12), isTrue, reason: '骑乘男能救重甲');
  });

  test('★ `UnitRescue`：双方互记索引 + 目标**挪到发起者坐标**', () {
    final a = u(1, con: 10, x: 3, y: 4);
    final t = u(2, con: 6, x: 5, y: 4);
    unitRescue(a, t);
    expect(a.isRescuing, isTrue);
    expect(t.isRescued, isTrue);
    expect(t.isHidden, isTrue, reason: '`US_HIDDEN` ⇒ 渲染时不该画它');
    expect(a.rescueIndex, 2);
    expect(t.rescueIndex, 1, reason: '两个方向都记（`actor->rescue` / `target->rescue`）');
    expect(t.x, 3);
    expect(t.y, 4, reason: '★ 被救者挪到发起者那一格（两人叠在一起）');
  });

  test('★ `UnitDrop`：清状态、断链接、放到落点；**我方**降下后当回合不能再动', () {
    final a = u(1, con: 10, x: 3, y: 4);
    final t = u(2, con: 6, x: 5, y: 4);
    unitRescue(a, t);
    unitDrop(a, t, xTarget: 3, yTarget: 5, targetIsPlayerFaction: true);
    expect(a.isRescuing, isFalse);
    expect(t.isRescued, isFalse);
    expect(t.isHidden, isFalse, reason: '重新出现在地图上');
    expect(a.rescueIndex, 0);
    expect(t.rescueIndex, 0);
    expect(t.x, 3);
    expect(t.y, 5);
    expect(t.unselectable, isTrue, reason: '★ 我方被降下 ⇒ `US_UNSELECTABLE`（当回合不能再动）');
  });

  test('敌方被降下**不**置 `US_UNSELECTABLE`（源码只对己方 faction 置）', () {
    final a = u(1, con: 10);
    final t = MapUnit(id: 2, faction: 1, x: 5, y: 4, con: 6);
    unitRescue(a, t);
    unitDrop(a, t, xTarget: 1, yTarget: 2, targetIsPlayerFaction: false);
    expect(t.unselectable, isFalse);
  });

  test('★ 降下可用性：没行动 + 正扛着人 + 有落点', () {
    bool ok({bool acted = false, bool rescuing = true, bool target = true}) =>
        dropAvailable(hasActed: acted, isRescuing: rescuing, hasTarget: target);
    expect(ok(), isTrue);
    expect(ok(acted: true), isFalse, reason: '对应 `US_HAS_MOVED`');
    expect(ok(rescuing: false), isFalse, reason: '没扛着人 ⇒ `MENU_NOTSHOWN`');
    expect(ok(target: false), isFalse, reason: '没有空落点');
  });

  test('落点 = 相邻空格（四邻居）', () {
    final free = {(0, 1), (2, 1)};
    final got = dropTargets(x: 1, y: 1, isFree: (x, y) => free.contains((x, y)));
    expect(got.length, 2);
    expect(got.contains((0, 1)), isTrue);
    expect(got.contains((1, 0)), isFalse, reason: '那格不空');
  });
}
