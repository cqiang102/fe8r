// PORT OF: src/bmsave.c:42-140（`WriteSuspendSave` / `ReadSuspendSave`）
//          src/bmsave.c:20（`ReadSuspendSavePlaySt`）
//          src/SaveGame.c（主存档：`gPlaySt` 的字段布局）
//          include/save.h（`struct SuspendSaveBlock`）
//          include/types.h:170-235（`struct PlaySt` 的字段与偏移）
//
// # 中断/存档的**快照层**
//
// ⚠️ **格式说明（诚实）**：这里存的是 **JSON**，不是 GBA 的 SRAM 二进制格式。
// 原作的格式（`struct SuspendSaveBlock` + 逐单位 pack）是为 8KB SRAM 设计的；
// 我们没有 SRAM、也不需要跨设备兼容 —— 所以只复刻**语义**（存什么、什么时候不许存），
// **不复刻字节布局**。将来若要跨实现交换存档，这一层必须重做。
//
// 出处里的关键规则：
//   * `WriteSuspendSave` 开头：`if (PLAY_FLAG_TUTORIAL & gPlaySt.chapterStateBits) return;`
//     ⇒ **教学模式章节不写中断存档**（序章就是教学模式：按中断不会产生任何存档）。
//   * 存 `gPlaySt`（章号 / 回合 / 旗 / 设置）、`gActionData`（含乱数状态
//     `StoreRNStateToActionStruct`）、**三个阵营的全部单位**
//     （`EncodeSuspendSavePackedUnit` 逐个 pack）、永久旗、章节旗。
//   * 不存：世界地图（那在主存档里）、表现层状态。
import 'dart:convert';

import '../flow/battle_field.dart';
import '../flow/flow_machine.dart';
import '../flow/tutorial_events.dart';
import '../flow/world_map.dart';

class SaveState {
  SaveState({
    required this.chapter,
    required this.field,
    required this.flow,
    required this.eventFlags,
    required this.rngConsumed,
    this.disableAutoEndTurns = false,
    this.isTutorial = false,
    this.isHard = false,
    this.worldMap,
    this.tutorial,
  });

  /// `gPlaySt.chapterIndex`
  int chapter;

  /// 三个阵营的全部单位（`gUnitArrayBlue/Red/Green`）
  BattleField field;

  /// 光标 / 阶段 / 已选单位（`gBmSt` 里我们真正用到的那部分）
  FlowState flow;

  /// 章节事件旗（`chapterFlags`）—— 丢了会导致"打过的事件又演一遍"
  Set<int> eventFlags;

  /// 乱数消耗计数（对应 `StoreRNStateToActionStruct` 存的那份乱数状态）
  int rngConsumed;

  /// `gPlaySt.config.disableAutoEndTurns`
  bool disableAutoEndTurns;

  /// `gPlaySt.chapterStateBits & PLAY_FLAG_TUTORIAL`
  ///
  /// 出处：`include/types.h:185-188`（`chapterStateBits` 的注释列出
  /// `PLAY_FLAG_TUTORIAL` / `PLAY_FLAG_HARD`）+ `src/GameControl_InitTutorialGame.c:33`
  /// （教学模式在这里置位）。**读回来必须恢复它** —— 地图菜单「中断」的可用性
  /// （`src/masked_0802257c.c:61-67`）就看这一位。
  bool isTutorial;

  /// `gPlaySt.chapterStateBits & PLAY_FLAG_HARD`
  bool isHard;

  /// 大地图状态（主存档里才有；中断存档里没有 —— 这里带上并在文档里说明）
  WorldMapState? worldMap;

  /// 教学队列（`gPlaySt.tutorial_counter` / `tutorial_exec_type`）
  TutorialQueue? tutorial;

  /// `PLAY_FLAG_TUTORIAL & gPlaySt.chapterStateBits` ⇒ 教学章节**不许**中断存档
  ///
  /// 出处：`src/bmsave.c:52-53`。这不是"暂时没实现"，是原作的规则：
  /// 教学模式章节按中断不会有任何存档产生。
  static bool canSuspend({required bool isTutorialChapter}) =>
      !isTutorialChapter;

  Map<String, dynamic> toJson() => {
        'chapter': chapter,
        'field': field.toJson(),
        'flow': flow.toJson(),
        'eventFlags': eventFlags.toList()..sort(),
        'rngConsumed': rngConsumed,
        'disableAutoEndTurns': disableAutoEndTurns,
        'isTutorial': isTutorial,
        'isHard': isHard,
        if (worldMap != null) 'worldMap': worldMap!.toJson(),
        if (tutorial != null) 'tutorial': tutorial!.toJson(),
      };

  factory SaveState.fromJson(Map<String, dynamic> j) => SaveState(
        chapter: j['chapter'] as int,
        field: BattleField.fromJson(j['field'] as Map<String, dynamic>),
        flow: FlowState.fromJson(j['flow'] as Map<String, dynamic>),
        eventFlags: ((j['eventFlags'] as List?) ?? const [])
            .map((e) => e as int)
            .toSet(),
        rngConsumed: j['rngConsumed'] as int? ?? 0,
        disableAutoEndTurns: j['disableAutoEndTurns'] as bool? ?? false,
        isTutorial: j['isTutorial'] as bool? ?? false,
        isHard: j['isHard'] as bool? ?? false,
        worldMap: j['worldMap'] == null
            ? null
            : WorldMapState.fromJson(j['worldMap'] as Map<String, dynamic>),
        tutorial: j['tutorial'] == null
            ? null
            : TutorialQueue.fromJson(j['tutorial'] as Map<String, dynamic>),
      );

  String encode() => jsonEncode(toJson());

  static SaveState decode(String s) =>
      SaveState.fromJson(jsonDecode(s) as Map<String, dynamic>);
}
