// PORT OF: src/Config_Loop_KeyHandler.c:30-120（`Config_Loop_KeyHandler`：
//            上下移动光标 / 左右改值（调 `func`）/ B 关屏；A 是动画预览的特例）
//          include/uiconfig.h:13-19（`struct GameOption`）、:22-31（`struct Selector`）
//          src/Config_Init.c:44（`maxOption = ARRAY_COUNT(gGameOptionsUiOrder)`）
//          src/uiconfig_080B6404.c:46（名字 = `GetStringFromIndex(gGameOptions[order[i]].msgId)`）
//          数据：`tools/pipeline/out/tables/game_options.json`（见 `parse_game_options.py`）
//
// # 「設定」屏的规则层
//
// 显示顺序**不是表序**，而是 `gGameOptionsUiOrder`（`src/data/data_08AAF6DC/` 前 13 字节）。
// 上下移动夹在两端（源码：`!= 0` / `< maxOption - 1` 才动，不倒扣也不循环）。
//
// ⚠️ **未逐行核对**：改值时 `func`（`GenericOptionChangeHandler` 等）**具体怎么改**
//    —— 是循环还是夹边界，我没读那几个 handler。这里用**夹边界**（保守：不发明循环），
//    并在转储里把"未核对"标出来。
// ⚠️ **未实现**：A 键的动画预览（`loadSoloAnimScreen`）、帮助框（`selectors[].helpTextId`）。

/// 一个选项在屏上的状态
class GameOptionState {
  GameOptionState({
    required this.msgId,
    required this.selectorCount,
    this.value,
    this.field,
  });

  /// `gPlaySt.config` 里的字段名（`src/uiconfig.c` 的 `GetGameOption` switch 解出来的）。
  /// null = 那个 switch 里没有它（例如 `GAME_OPTION_ANIMATION` 走的是另一套）。
  final String? field;

  /// 选项名的文本 id（`GetStringFromIndex(msgId)`）
  final int msgId;

  /// 有几个取值（`selectors` 个数）
  final int selectorCount;

  /// 当前取值下标。
  ///
  /// **null = 我们没建模这个选项的运行时值**（我们只有
  /// `PlayConfig.disableAutoEndTurns` 一个字段）——
  /// 这种情况屏上显示「—」，**不编一个值出来**。
  int? value;
}

/// `gPlaySt.config` 的那些字段（名字来自 `src/uiconfig.c:45+` 的 switch）。
///
/// ⚠️ **默认值未核对**：原作默认值在 `src/InitPlayConfig.c`，我没读 ⇒ 这里一律 0。
/// 所以屏上的**初值**可能与原作不同（改过之后就一致了）。
class GameConfigValues {
  GameConfigValues({Map<String, int>? initial}) : values = {...?initial};

  final Map<String, int> values;

  int get(String? field) => field == null ? 0 : (values[field] ?? 0);

  void set(String? field, int v) {
    if (field != null) values[field] = v;
  }
}

class GameOptionsState {
  GameOptionsState({required this.options, this.config}) {
    if (options.isNotEmpty) _clampValue(0);
  }

  /// **按显示顺序**排好的选项（来自 `uiOrder` 映射后的表）
  final List<GameOptionState> options;

  /// 配置值（`gPlaySt.config`）—— 选项改值**真的写到这儿**
  final GameConfigValues? config;

  int index = 0;
  bool closed = false;

  /// 改过值的次数（判据用：证明"真的改了"，而不是只移动光标）
  int changes = 0;

  int get count => options.length;

  GameOptionState? get current =>
      (index >= 0 && index < options.length) ? options[index] : null;

  void _clampValue(int i) {
    final o = options[i];
    if (o.value == null) {
      // 没建模的选项：值从配置里读（字段名有就取，没有就留 null）
      final f = o.field;
      if (f != null && config != null) o.value = config!.get(f).clamp(0, o.selectorCount - 1);
      return;
    }
    if (o.value! < 0) o.value = 0;
    if (o.value! > o.selectorCount - 1) o.value = o.selectorCount - 1;
  }
}

enum GameOptionsKey { up, down, left, right, a, b }

/// 应用一次输入。出处：`Config_Loop_KeyHandler.c:30-120`。
void gameOptionsKey(GameOptionsState s, GameOptionsKey k) {
  if (s.closed || s.options.isEmpty) return;
  switch (k) {
    case GameOptionsKey.b:
      s.closed = true;
      return;
    case GameOptionsKey.up:
      // 源码：`if (selectedOptionIdx != 0) selectedOptionIdx--;`
      if (s.index != 0) s.index--;
      return;
    case GameOptionsKey.down:
      // 源码：`if (selectedOptionIdx < maxOption - 1) selectedOptionIdx++;`
      if (s.index < s.options.length - 1) s.index++;
      return;
    case GameOptionsKey.left:
    case GameOptionsKey.right:
      // 源码：左右键调 `gGameOptions[order[i]].func(proc)` 改值。
      // ⚠️ handler 内部怎么改（循环/夹边界）**未逐行核对** ⇒ 这里夹边界。
      final o = s.current;
      if (o == null || o.value == null || o.selectorCount <= 1) return;
      final next = o.value! + (k == GameOptionsKey.right ? 1 : -1);
      final clamped = next.clamp(0, o.selectorCount - 1);
      if (clamped != o.value) {
        o.value = clamped;
        s.config?.set(o.field, clamped);   // ★ 真的写进配置
        s.changes++;
      }
      return;
    case GameOptionsKey.a:
      // 源码的 A 有两个前提（选中项是 `uiOrder[..] == 0` 且动画选项 != 3）才开预览；
      // **未实现**，什么都不做（不假装）。
      return;
  }
}
