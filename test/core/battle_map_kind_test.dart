// `GetBattleMapKind()` / 教学模式 —— **明确标注未查证程度的**移植
//
// 出处见 `lib/core/flow/battle_map_kind.dart` 与 `lib/core/flow/play_config.dart`
// 的头注释。这两个文件存在的理由就是：地图菜单的可见性依赖它们，
// 而它们的真值来源不是"我以为"，是能指出行号的推理。
import 'package:fe8r/core/core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('battleMapKindOf', () {
    test('能进入的三个章节都是 story', () {
      for (final id in [0x00, 0x01, 0x38]) {
        expect(battleMapKindOf(id), BattleMapKind.story,
            reason: '0x${id.toRadixString(16)}');
      }
    });

    test('★ 查不到就返回 null（**不兜底**）—— 这是"响亮失败"的关键', () {
      expect(battleMapKindOf(0x02), isNull, reason: '第 2 章还没查证');
      expect(battleMapKindOf(0x24), isNull, reason: '塔 1');
      expect(battleMapKindOf(0xFF), isNull);
    });

    test('枚举数值 = include/types.h:368-370', () {
      expect(BattleMapKind.story.index, 0);
      expect(BattleMapKind.dungeon.index, 1);
      expect(BattleMapKind.skirmish.index, 2);
    });

    test('已查证集合非空且带章节名（不是裸数字）', () {
      expect(battleMapKindVerifiedChapters.length, 3);
      expect(battleMapKindVerifiedChapters[0x38], 'CHAPTER_CASTLE_FRELIA');
    });
  });

  group('NewGamePlayFlags', () {
    test('难度 → isTutorial/isDifficult（src/SaveMenuWriteNewGame.c:35-48）', () {
      const easy = NewGamePlayFlags(NewGameDifficulty.easy);
      const normal = NewGamePlayFlags(NewGameDifficulty.normal);
      const hard = NewGamePlayFlags(NewGameDifficulty.hard);

      expect(easy.configController, isFalse);
      expect(normal.configController, isTrue);
      expect(hard.configController, isTrue);

      expect(easy.playFlagHard, isFalse);
      expect(normal.playFlagHard, isFalse);
      expect(hard.playFlagHard, isTrue);
    });

    test('★ 教学模式 = config.controller || PLAY_FLAG_HARD（CHECK_TUTORIAL）', () {
      expect(const NewGamePlayFlags(NewGameDifficulty.easy).isTutorialMode,
          isFalse);
      expect(const NewGamePlayFlags(NewGameDifficulty.normal).isTutorialMode,
          isTrue);
      expect(const NewGamePlayFlags(NewGameDifficulty.hard).isTutorialMode,
          isTrue);
    });

    test('★ 辞书锁定 ⟺ 非教学模式（序章那句 ASMC 的 BNE 条件）', () {
      expect(const NewGamePlayFlags(NewGameDifficulty.easy).guideLocked, isTrue);
      expect(
          const NewGamePlayFlags(NewGameDifficulty.normal).guideLocked, isFalse);
      expect(const NewGamePlayFlags(NewGameDifficulty.hard).guideLocked, isFalse);
    });

    test('★ PLAY_FLAG_TUTORIAL 在这条链上是 0（见 play_config.dart 的推理）', () {
      for (final d in NewGameDifficulty.values) {
        expect(NewGamePlayFlags(d).playFlagTutorial, isFalse,
            reason: '$d：只有 GameControl_InitTutorialGame 会置它，而那条链没人调它');
      }
    });

    test('★ 新手难度下地图菜单只有 5 条、普通/困难 6 条', () {
      for (final d in NewGameDifficulty.values) {
        final ng = NewGamePlayFlags(d);
        final entries = buildMapMenu(MapMenuContext(
          chapterIndex: 0x00,
          battleMapKind: BattleMapKind.story,
          guideLocked: ng.guideLocked,
          tutorial: ng.playFlagTutorial,
        ));
        expect(entries.length, d == NewGameDifficulty.easy ? 5 : 6,
            reason: '$d → ${entries.map((e) => e.item.label).toList()}');
      }
    });
  });
}
