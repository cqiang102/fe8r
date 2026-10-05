// 章节配置表（编译器提取）的测试。
import 'dart:io';

import 'package:fe8r/core/core.dart';
import 'package:flutter_test/flutter_test.dart';

const _p = 'tools/pipeline/out/tables/chapters.json';

void main() {
  group('章节配置表', () {
    late Chapters chapters;

    setUpAll(() {
      final f = File(_p);
      if (!f.existsSync()) {
        fail('缺少 $_p，先跑 tools/pipeline/extract/parse_chapters.py');
      }
      chapters = Chapters.parse(f.readAsStringSync());
    });

    test('79 章，序号连续', () {
      expect(chapters.list.length, 79);
      for (var i = 0; i < chapters.list.length; i++) {
        expect(chapters.list[i].index, i, reason: '序号必须连续且与下标一致');
      }
    });

    test('章节名：60 个有名、19 个空槽位（`-`）', () {
      // 79 个槽位里只有 60 个真的有名 —— 其余是占位。
      // 名字格式有 3 字符（`L00`）和 4 字符（`E20B` / `E10x`）两种。
      final names = chapters.list.map((c) => c.internalName).toList();
      final real = names.where((n) => n != '-').toList();

      expect(names.length, 79);
      expect(real.length, 60);
      expect(real.toSet().length, real.length, reason: '有名的不应重复');
      for (final n in real) {
        expect(RegExp(r'^[A-Za-z]\d\d[A-Za-z]?$').hasMatch(n), isTrue,
            reason: '"$n" 不是预期的 <字母><两位数字>[可选字母] 形式');
      }
    });

    test('第一章是 L00，且与已知值一致', () {
      final c = chapters.byName('L00');
      expect(c, isNotNull);
      expect(c!.index, 0);
      // 这些值直接来自 chapter_settings.h 的第一项
      expect(c.mapEventDataId, 7);
      expect(c.initialPosX, 1);
      expect(c.initialPosY, 0);
      expect(c.hasPrepScreen, isFalse);
    });

    test('mapEventDataId 是 u8 字段，全部在 0..255', () {
      for (final c in chapters.list) {
        expect(c.mapEventDataId, inInclusiveRange(0, 255),
            reason: '${c.internalName} 的 mapEventDataId 越界');
      }
    });

    test('用到的 mapEventDataId 共 61 个（钉死：将来链路打通时会变）', () {
      // 数字钉死是有意的：下一步把 ChapterEventGroup 解出来之后，
      // 这里会失败并提醒更新结论。
      expect(chapters.eventGroupIds.length, 61);
    });

    test('地图资源 id 都非负（下一跳要拿去查资产表）', () {
      for (final c in chapters.list) {
        for (final v in [c.obj1Id, c.obj2Id, c.paletteId, c.tileConfigId,
                         c.mainLayerId, c.changeLayerId]) {
          expect(v, greaterThanOrEqualTo(0));
        }
      }
    });
  });
}
