// **START 跳过剧情**（`EV_STATE_SKIPPING`）。
//
// ## 出处
//
// `include/event.h:57`
//
// ```c
// EV_STATE_SKIPPING = (1 << 0x2), // currently skipping events (trigger with start)
// #define EVENT_IS_SKIPPING(aEventProc) (((aEventProc)->evStateBits >> 2) & 1)
// ```
//
// 触发（`src/event_0800D110.c:25-28`）：
//
// ```c
// if (EventEngine_CanStartSkip(proc) && (gKeyStatusPtr->newKeys & START_BUTTON)) {
//     EventEngine_StartSkip(proc);
//     return;
// }
// ```
//
// ⚠️ 是 `START_BUTTON` 的 **newKeys**（按下那一刻），不是"按住"。
//
// 各指令里的检查：`Event17_Fade.c:49`（淡入淡出立即到位）、
// `Event21_TextBg.c:42`（不等按键）、`Event2F_MoveUnit`（瞬移）、
// `Event34`（`KILL` 跳过死亡淡出）。
//
// 用户的原话：「**跳过动画才是正式进入游戏**」—— 就是这条。
import 'dart:io';

import 'package:fe8r/core/core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late GameTexts texts;

  setUpAll(() {
    final tf = File('tools/pipeline/out/tables/texts.json');
    if (!tf.existsSync()) fail('缺少 ${tf.path}');
    texts = GameTexts.parse(tf.readAsStringSync());
  });

  Scene makeScene(List<SceneEvent> log) => Scene(
        texts: texts,
        scripts: allSceneFns,
        defined: definedSceneScripts,
        onEvent: (e) async => log.add(e),
      );

  test('默认不快进', () {
    final s = makeScene([]);
    expect(s.skipping, isFalse);
  });

  test('startSkip / stopSkip', () {
    final s = makeScene([]);
    s.startSkip();
    expect(s.skipping, isTrue);
    s.stopSkip();
    expect(s.skipping, isFalse);
  });

  // ⚠️ 这里**不能**测"不快进时会阻塞"：`Scene` 只负责产出事件，
  // "等按键"是 `Fe8Game._onSceneEvent` 的 `await _sceneWait`。
  // 在 core 测试里 `onEvent` 立即返回，脚本当然会跑完
  // —— 我第一版就是在这儿写错了一条判据（红了，但**判据本身错**）。
  // 那条链由端到端场景 `scenario.sh battle` 真机验证。

  test('★ 快进之后，脚本不再等人：整段王座过场能**跑到底**', () async {
    final log = <SceneEvent>[];
    final s = makeScene(log);
    s.startSkip(); // 一开始就快进（等价于玩家按住/连按 START）
    await allSceneFns['EventScr_Prologue_RenaisThroneCutscene']!(s);
    // 没有任何 `advanceDialogue` 调用，却跑完了 —— 这就是"跳过"
    expect(log.whereType<ShowText>(), isNotEmpty);
    // 而且该发生的**状态变化**照旧发生（跳过的是演出，不是逻辑）
    expect(log.whereType<RemoveUnit>().map((e) => e.pid).toList(),
        contains(15), reason: '快进不该吞掉 DISA');
    expect(log.whereType<CameraControl>(), isNotEmpty,
        reason: '快进不该吞掉相机指令');
  });
}
