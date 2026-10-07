// 中断/存档的**快照层**判据。
//
// 出处：`src/bmsave.c:42-140`（`WriteSuspendSave` / `ReadSuspendSave`）
//
// ## 为什么判据要这么写
//
// 存档的失败模式不是"崩了"，而是**存了、读回来少了/串了**：
//   * 单位**编号在第二次加载后不再唯一**（仓库铁律里点名的形状）；
//   * 事件旗丢了 ⇒ 打过的事件又演一遍；
//   * 回合/阵营/已行动标记串位。
// 所以这里三件事都要：**逐字段相等**、**编号唯一**（且连做两次加载）、
// 以及**改了东西必须不相等**（否则判据是死的）。
import 'package:fe8r/core/core.dart';
import 'package:flutter_test/flutter_test.dart';

BattleField _field() => BattleField(
      width: 15,
      height: 10,
      turn: 3,
      activeFaction: Faction.red,
      units: [
        MapUnit(
            id: 1, faction: Faction.blue, x: 4, y: 4, classId: 7,
            hp: 12, maxHp: 28, hasActed: true, name: 'SETH', items: [1, 5, 22]),
        MapUnit(
            id: 2, faction: Faction.blue, x: 5, y: 4, classId: 2,
            hp: 18, maxHp: 18, name: 'EIRIKA', items: [1]),
        MapUnit(
            id: 0x90, faction: Faction.red, x: 9, y: 6, classId: 0x2E,
            charIndex: 30, hp: 4, maxHp: 20, name: 'ONEILL'),
      ],
    );

SaveState _state() => SaveState(
      chapter: 1,
      field: _field(),
      flow: FlowState(phase: FlowPhase.freeCursor, cursorX: 9, cursorY: 6),
      eventFlags: {3, 7, 0x84},
      rngConsumed: 42,
      disableAutoEndTurns: false,
      worldMap: WorldMapState(node: 1, cleared: {0}),
      tutorial: TutorialQueue(counter: 2, execType: 1),
    );

/// 把两份快照按**每一件该保住的东西**比一遍，返回不等之处
List<String> diff(SaveState a, SaveState b) {
  final out = <String>[];
  if (a.chapter != b.chapter) out.add('chapter ${a.chapter} != ${b.chapter}');
  if (a.field.turn != b.field.turn) out.add('turn');
  if (a.field.activeFaction != b.field.activeFaction) out.add('activeFaction');
  if (a.field.units.length != b.field.units.length) out.add('unit count');
  if (a.rngConsumed != b.rngConsumed) out.add('rngConsumed');
  if (a.disableAutoEndTurns != b.disableAutoEndTurns) out.add('config');
  if (a.eventFlags.length != b.eventFlags.length ||
      !a.eventFlags.containsAll(b.eventFlags)) {
    out.add('eventFlags');
  }
  if (a.flow.cursorX != b.flow.cursorX || a.flow.cursorY != b.flow.cursorY) {
    out.add('cursor');
  }
  if (a.worldMap?.node != b.worldMap?.node) out.add('worldMap.node');
  if (a.tutorial?.counter != b.tutorial?.counter) out.add('tutorial.counter');
  for (var i = 0; i < a.field.units.length && i < b.field.units.length; i++) {
    final u = a.field.units[i], v = b.field.units[i];
    if (u.id != v.id) out.add('unit[$i].id ${u.id} != ${v.id}');
    if (u.faction != v.faction) out.add('unit[$i].faction');
    if (u.x != v.x || u.y != v.y) out.add('unit[$i].pos');
    if (u.hp != v.hp) out.add('unit[$i].hp ${u.hp} != ${v.hp}');
    if (u.maxHp != v.maxHp) out.add('unit[$i].maxHp');
    if (u.hasActed != v.hasActed) out.add('unit[$i].hasActed');
    if (u.classId != v.classId) out.add('unit[$i].classId');
    if (u.items.length != v.items.length) out.add('unit[$i].items');
  }
  return out;
}

void main() {
  test('★ 存 → 读：**逐字段**相同', () {
    final a = _state();
    final b = SaveState.decode(a.encode());
    expect(diff(a, b), isEmpty);
  });

  test('★ 单位编号在读回来之后**仍然唯一**（连做两次加载也不行）', () {
    final a = _state();
    // 第一次
    final b = SaveState.decode(a.encode());
    expect(b.field.units.map((u) => u.id).toSet().length, b.field.units.length,
        reason: '第一次加载后编号就重复了');
    // 第二次（"ids that stop being unique after a second load" 就是这个形状）
    final c = SaveState.decode(b.encode());
    expect(c.field.units.map((u) => u.id).toSet().length, c.field.units.length,
        reason: '第二次加载后编号重复了');
    expect(diff(a, c), isEmpty, reason: '两次往返之后状态还得一样');
  });

  test('★ 判据是活的：改一个值就必须不相等', () {
    final a = _state();
    // 篡改 HP：**显式覆盖**，别就地在共享结构上改
    //（就地改踩过一次：`remove(0)` 之后解码结果居然没变，
    //  于是证伪"没生效" —— 判据看起来是活的，其实是改错了地方）
    final j = a.toJson();
    final units = ((j['field'] as Map<String, dynamic>)['units'] as List)
        .cast<Map<String, dynamic>>();
    units[0] = Map<String, dynamic>.from(units[0])..['hp'] = 999;
    expect(diff(a, SaveState.fromJson(j)), isNotEmpty,
        reason: '改了 HP 还判等 ⇒ 这条判据根本没在看 HP');
    // 篡改事件旗（同样显式覆盖）
    final j2 = a.toJson();
    j2['eventFlags'] = <int>[3, 7];
    expect(diff(a, SaveState.fromJson(j2)), isNotEmpty,
        reason: '事件旗少了还判等 ⇒ 判据没在看旗');
    // 篡改单位编号（这条最要紧：编号重复是仓库铁律点名的形状）
    final j3 = a.toJson();
    final u3 = ((j3['field'] as Map<String, dynamic>)['units'] as List)
        .cast<Map<String, dynamic>>();
    u3[1] = Map<String, dynamic>.from(u3[1])..['id'] = 1;
    expect(diff(a, SaveState.fromJson(j3)), isNotEmpty,
        reason: '编号变了还判等 ⇒ 判据没在看 id');
  });

  test('教学模式章节**不许**中断存档（`src/bmsave.c:52-53`）', () {
    expect(SaveState.canSuspend(isTutorialChapter: true), isFalse);
    expect(SaveState.canSuspend(isTutorialChapter: false), isTrue);
  });
}
