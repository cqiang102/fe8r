// HUD 的文字组装。
//
// ## 为什么单独一个类
//
// 原来这些字符串拼接散在 `Fe8Game` 的 `_updateHud()` 与 `sceneHudLine` 里，
// 一个方法 60 多行、混着三种模式（场景 / 剧情 / 战斗）。
//
// 搬出来之后它是**纯函数**：给同样的状态，产出同样的字符串。
// 这带来一个额外好处 —— **可以单测**，而原来嵌在 game 里没法测。
//
// ⚠️ 表现方式仍是"拼一个字符串交给 Flutter 的 `Text`"。
// 更 Flame 的做法是把这些做成 HUD 组件或用 `GameWidget.overlayBuilderMap`，
// 但**调试信息本来就不该进游戏画面**（它只服务于开发），
// 所以留在 Flutter 层是合理的。

import 'package:fe8r/core/core.dart';

/// 一段 HUD 文字
class HudText {
  const HudText(this.lines);

  final List<String> lines;

  String get value => lines.join('\n');
}

class HudView {
  const HudView();

  /// 场景演出模式
  HudText scene({
    required int shown,
    required ShowText? current,
    required Set<String> missing,
    required Map<String, int> placeholder,
    required String extra,
    List<String> trace = const [],
  }) {
    final script = current?.scriptName ?? '-';
    final miss = missing.isEmpty ? '' : '  缺${missing.length}';
    final skip = placeholder.isEmpty
        ? ''
        : '  未执行${placeholder.keys.take(3).join('/')}';
    // 轨迹：最后几条执行的指令 —— "停在哪"一眼可见
    final tail = trace.length <= 3
        ? trace
        : trace.sublist(trace.length - 3);
    return HudText([
      if (tail.isNotEmpty) '→ ${tail.join("  →  ")}',
      '剧情 第$shown句  文本=0x${current?.message.id.toRadixString(16) ?? '-'}'
          '$miss$skip${extra.isEmpty ? '' : '  $extra'}',
      '【$script】',
    ]);
  }

  /// 战斗模式
  HudText battle({
    required BattleField field,
    required FlowState state,
    required int rnConsumed,
    required List<ActionOption> menu,
    required String lastCombat,
    /// 屏幕底部的一行提示（地图菜单选到"还没做的界面"时也走这里 ——
    /// 不显示的话玩家会以为按键没反应，把"没有的"当成 bug 反馈）
    String note = '',
  }) {
    final who = field.activeFaction == Faction.red ? '敌方' : '我方';
    // 带上坐标 —— 排查"单位站的位置不对"时这是唯一可靠的依据
    final hp = field.units
        .where((u) => u.isAlive)
        .map((u) => '${u.name.isEmpty ? u.id : u.name}'
            '(${u.x},${u.y}):${u.hp}')
        .join(' ');
    final m = state.phase == FlowPhase.actionMenu
        ? '  [${menu.map((o) => o.label).join(' / ')}]'
        : (state.phase == FlowPhase.selectTarget ? '  选择目标' : '');
    return HudText([
      '回合 ${field.turn}  $who  可行动 ${field.actionableCount}  '
          '光标 (${state.cursorX},${state.cursorY})  ${state.phase.name}$m  '
          '乱数 $rnConsumed',
      'HP  $hp${lastCombat.isEmpty ? '' : '\n$lastCombat'}',
      if (note.isNotEmpty) note,
    ]);
  }

  /// 旧事件引擎的剧情模式
  HudText event({
    required EventVmState st,
    required BattleField field,
    required int pendingMoves,
  }) {
    final pos = field.units
        .where((u) => u.isAlive)
        .map((u) => '${u.name.isEmpty ? u.id : u.name}(${u.x},${u.y})')
        .join(' ');
    return HudText([
      '剧情  ${st.done ? '结束' : (st.waitingForPlayer ? '等按键（Z / 回车）' : '演出中')}'
          '  背景 ${st.presentation.backgroundId ?? '-'}'
          '  立绘 ${st.presentation.faces.values.join(',')}'
          '  镜头 ${st.cameraX ?? '-'},${st.cameraY ?? '-'}'
          '  待移动 $pendingMoves',
      st.lastText,
      pos,
    ]);
  }
}
