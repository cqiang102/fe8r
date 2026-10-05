// 战场单位与场地的**语义模型**（纯 Dart，可序列化）。
//
// 这里刻意不复用 `lib/core/battle/battle_unit.dart` 里的 `BattleUnit`：
// 那是**一次战斗结算**期间的临时单位（含 battleAttack / wTriangleBonus 等
// 只在结算中有效的字段），而这里是**地图上长期存在的单位**。
// 两者的生命周期与字段完全不同，混成一个类会让"哪些字段该存档"变得含糊。
//
// 与技术方案 §4.2 的"完全可序列化"要求对应：这个对象能原样进存档。

import 'dart:convert';

import '../battle/phase.dart';

/// 地图上的一个单位。
class MapUnit {
  MapUnit({
    required this.id,
    required this.faction,
    required this.x,
    required this.y,
    this.classId = 0,
    this.level = 1,
    this.movement = 5,
    this.hp = 20,
    this.maxHp = 20,
    this.hasActed = false,
    this.name = '',
  });

  /// 单位编号（对应原版的 `gUnitLut` 下标）
  final int id;

  /// `FACTION_BLUE` / `FACTION_GREEN` / `FACTION_RED` + 编号
  final int faction;

  int x;
  int y;

  final int classId;
  final int level;

  /// 移动力
  final int movement;

  int hp;
  int maxHp;

  /// 本回合是否已行动
  bool hasActed;

  final String name;

  /// 阵营位
  int get factionBit => faction & 0x80;

  bool get isAlive => hp > 0;

  Map<String, dynamic> toJson() => {
        'id': id,
        'faction': faction,
        'x': x,
        'y': y,
        'classId': classId,
        'level': level,
        'movement': movement,
        'hp': hp,
        'maxHp': maxHp,
        'hasActed': hasActed,
        'name': name,
      };

  factory MapUnit.fromJson(Map<String, dynamic> j) => MapUnit(
        id: j['id'] as int,
        faction: j['faction'] as int,
        x: j['x'] as int,
        y: j['y'] as int,
        classId: j['classId'] as int? ?? 0,
        level: j['level'] as int? ?? 1,
        movement: j['movement'] as int? ?? 5,
        hp: j['hp'] as int? ?? 20,
        maxHp: j['maxHp'] as int? ?? 20,
        hasActed: j['hasActed'] as bool? ?? false,
        name: j['name'] as String? ?? '',
      );
}

/// 战场：一组单位 + 当前回合信息。
///
/// **完全可序列化**——这是"任意时刻存档"的基础。
class BattleField {
  BattleField({
    required this.width,
    required this.height,
    List<MapUnit>? units,
    this.turn = 1,
    this.activeFaction = Faction.blue,
  }) : units = units ?? [];

  final int width;
  final int height;
  final List<MapUnit> units;

  int turn;

  /// 当前行动阵营（`Faction.*`）
  int activeFaction;

  MapUnit? unitAt(int x, int y) {
    for (final u in units) {
      if (u.isAlive && u.x == x && u.y == y) return u;
    }
    return null;
  }

  MapUnit? unitById(int? id) {
    if (id == null) return null;
    for (final u in units) {
      if (u.id == id) return u;
    }
    return null;
  }

  /// 这个单位是否属于当前行动阵营、且可被玩家操控。
  ///
  /// 用 [PhaseRules.isSameAllegiance] 而不是 [PhaseRules.areUnitsAllied]：
  /// "同盟"包含友军 NPC，而友军 NPC 不由玩家操控。
  bool isControllable(MapUnit u) =>
      PhaseRules.isSameAllegiance(u.faction, activeFaction);

  /// 把单位移动到新位置
  void moveUnit(MapUnit u, int x, int y) {
    u.x = x;
    u.y = y;
  }

  /// 结束当前单位行动
  void finishUnit(MapUnit u) => u.hasActed = true;

  /// 把地图单位转成 `PhaseRules` 需要的最小视图。
  ///
  /// ⚠️ **`hasActed` 对应 `US_UNSELECTABLE`**，不是 `US_HAS_MOVED`。
  /// 原版里这两个是不同的位：
  ///   * `US_UNSELECTABLE` —— 灰掉、本回合不能再动（`GetPhaseAbleUnitCount` 的 notAble 掩码里有它）
  ///   * `US_HAS_MOVED`    —— 已经移动过（用于再移动 / Canto），**不在**掩码里，
  ///                          所以"移动过但还能再动"的单位仍然会被计入
  /// 把两者当成一个，会让再移动类单位在移动后立刻被判定为"已行动"。
  List<PhaseUnit?> toPhaseUnits() {
    final arr = List<PhaseUnit?>.filled(0x100, null);
    for (final u in units) {
      if (u.id < 0 || u.id >= 0x100) continue;
      arr[u.id] = PhaseUnit(
        faction: u.faction,
        state: u.isAlive ? (u.hasActed ? UnitState.unselectable : 0)
                         : UnitState.dead,
        statusIndex: UnitStatus.none,
        classAttributes: 0,
        hasCharacterData: true,
      );
    }
    return arr;
  }

  /// `GetPhaseAbleUnitCount(faction)`
  ///
  /// 直接用规则层的实现，不在表现层另写一套。
  int phaseAbleCount(int faction) =>
      PhaseRules.getPhaseAbleUnitCount(toPhaseUnits(), faction);

  /// 本回合还能行动的**我方**单位数
  int get actionableCount =>
      units.where((u) => u.isAlive && !u.hasActed && isControllable(u)).length;

  /// `ClearActiveFactionGrayedStates` 的核心：清掉当前阵营的灰化标记。
  ///
  /// 原版在阶段开始时调用它，把 `US_UNSELECTABLE | US_HAS_MOVED | US_HAS_MOVED_AI`
  /// 一起清掉——这正是"新回合所有单位又能动了"的机制。
  void clearActiveFactionGrayedStates() {
    for (final u in units) {
      if (PhaseRules.isSameAllegiance(u.faction, activeFaction)) {
        u.hasActed = false;
      }
    }
  }

  /// 是否所有我方单位都行动完了 —— 可以结束回合
  bool get allActed => actionableCount == 0;

  Map<String, dynamic> toJson() => {
        'width': width,
        'height': height,
        'turn': turn,
        'activeFaction': activeFaction,
        'units': units.map((u) => u.toJson()).toList(),
      };

  factory BattleField.fromJson(Map<String, dynamic> j) => BattleField(
        width: j['width'] as int,
        height: j['height'] as int,
        turn: j['turn'] as int? ?? 1,
        activeFaction: j['activeFaction'] as int? ?? Faction.blue,
        units: (j['units'] as List<dynamic>)
            .map((e) => MapUnit.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  String encode() => jsonEncode(toJson());

  static BattleField decode(String source) =>
      BattleField.fromJson(jsonDecode(source) as Map<String, dynamic>);
}
