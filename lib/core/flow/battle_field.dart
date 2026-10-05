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

  /// 本回合还能行动的我方单位数（对应 `GetPhaseAbleUnitCount` 的简化版）
  int get actionableCount =>
      units.where((u) => u.isAlive && !u.hasActed && isControllable(u)).length;

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
