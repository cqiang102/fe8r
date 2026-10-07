// 教学事件的**两段式**语义（入队 → 触发）
//
// 出处：`src/EnqueueTutEvent.c:24-38`、`src/eventinfo_0808618C.c:138-149`、
//       `include/eventinfo.h:30-36`
//
// 这条为什么值得单测：原作里**每次阶段切换的第一件事**就是
// `RunTutorialEvent(TUTORIAL_EVT_TYPE_PHASECHANGE)`
// （`src/RunPhaseSwitchEvents.c:36`），而教学脚本经常是对话 ——
// 用户说的「有时候阶段切换也会触发对话」就是它。
import 'package:fe8r/core/core.dart';
import 'package:flutter_test/flutter_test.dart';

/// 序章的 `EventListScr_Prologue_Tutorial`（`src/data/EventListScr_Prologue_Tutorial_ref/…c`）
const _prologueTutorials = <String>[
  'EventScr_Prologue_Tutorial0',
  'EventScr_Prologue_Tutorial1',
  'EventScr_Prologue_Tutorial2',
  'EventScr_Prologue_Tutorial3',
  'EventScr_Prologue_Tutorial4',
  'EventScr_Prologue_Tutorial5',
  'EventScr_Prologue_Tutorial6',
  'EventScr_Prologue_Tutorial7',
  'EventScr_Prologue_Tutorial8',
  'EventScr_Prologue_Tutorial9',
  'EventScr_Prologue_TutorialA',
  'EventScr_Prologue_TutorialB',
  'EventScr_Prologue_TutorialC',
  'EventScr_Prologue_TutorialD',
  'EventScr_Prologue_TutorialE',
];

void main() {
  test('`TUTORIAL_EVT_TYPE_*` 的数值 = include/eventinfo.h:30-36', () {
    expect(TutorialEvtType.phaseChange.id, 0);
    expect(TutorialEvtType.postAction.id, 1);
    expect(TutorialEvtType.onSelect.id, 2);
    expect(TutorialEvtType.destSelected.id, 3);
    expect(TutorialEvtType.afterMove.id, 4);
    expect(TutorialEvtType.forecast.id, 5);
    expect(TutorialEvtType.playerPhase.id, 6);
  });

  test('★ 入队 = 在**本章那张表**里查下标 + 1（查不到就不入队）', () {
    final q = TutorialQueue();
    // 序章那条链的第一环：`EventScr_Prologue_ExecTut` 入队 T0、type 2(ONSELECT)
    expect(q.enqueue('EventScr_Prologue_Tutorial0', TutorialEvtType.onSelect.id,
        _prologueTutorials), isTrue);
    expect(q.counter, 1, reason: '下标 0 → counter = 1');
    expect(q.execType, 2);
    // 表里没有的脚本：原版扫完一圈什么都不做
    expect(q.enqueue('EventScr_NotInTable', 1, _prologueTutorials), isFalse);
    expect(q.counter, 1, reason: '失败的入队不能改动状态');
  });

  test('★ 触发：类型不符**不动**，类型相符才取走并清空', () {
    final q = TutorialQueue()
      ..enqueue('EventScr_Prologue_Tutorial9', TutorialEvtType.playerPhase.id,
          _prologueTutorials);
    expect(q.counter, 10);

    // 类型不符（阶段切换 0 ≠ 玩家阶段 6）→ 什么都不发生
    expect(q.take(TutorialEvtType.phaseChange.id, _prologueTutorials), isNull);
    expect(q.counter, 10, reason: '不符的钩子不能把待触发事件吃掉');

    // 相符 → 取走 T9（下标 9 = counter-1），并清空
    expect(q.take(TutorialEvtType.playerPhase.id, _prologueTutorials),
        'EventScr_Prologue_Tutorial9');
    expect(q.counter, 0);
    expect(q.execType, 0);
    // 第二次同类型的钩子拿不到东西（只演一次）
    expect(q.take(TutorialEvtType.playerPhase.id, _prologueTutorials), isNull);
  });

  test('★ `phaseChange` 是 0，而"没有待触发"也是 0 —— 只能靠 counter 区分', () {
    final q = TutorialQueue();
    expect(q.execType, 0, reason: '没有待触发时 execType 也是 0');
    expect(q.hasPending, isFalse);
    expect(q.take(TutorialEvtType.phaseChange.id, _prologueTutorials), isNull,
        reason: 'counter == 0 ⇒ 阶段切换不该演出任何东西');
  });

  test('★ 每一次新入队都会**覆盖**上一条（原版就是直接赋值）', () {
    final q = TutorialQueue()
      ..enqueue('EventScr_Prologue_Tutorial0', 2, _prologueTutorials)
      ..enqueue('EventScr_Prologue_Tutorial5', 4, _prologueTutorials);
    expect(q.counter, 6);
    expect(q.execType, 4);
    expect(q.take(4, _prologueTutorials), 'EventScr_Prologue_Tutorial5');
  });

  test('串起来的链：T8 入队 T9(playerPhase) → 下一个玩家阶段演 T9', () {
    // 数据出处：`tools/pipeline/out/tables/event_scripts_asm.json`
    //   EventScr_Prologue_Tutorial8: EvtEnqueueConditionalTutCall(6, EventScr_Prologue_Tutorial9)
    final q = TutorialQueue()
      ..enqueue('EventScr_Prologue_Tutorial9', TutorialEvtType.playerPhase.id,
          _prologueTutorials);
    // 阶段切换（0）先来 —— 不是它
    expect(q.take(0, _prologueTutorials), isNull);
    // 玩家阶段（6）才演
    expect(q.take(6, _prologueTutorials), 'EventScr_Prologue_Tutorial9');
  });
}
