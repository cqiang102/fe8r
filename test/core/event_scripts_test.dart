// 场景剧情脚本的**真实 opcode 覆盖率**测试。
//
// "150 个指令里实现了 27 个"没有意义 —— 那 27 个是挑的。
// 这里跑的是 166 张真实场景、5843 条真实指令，
// 给出的百分比是"真实剧情里我能执行多少"。
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _p = 'tools/pipeline/out/tables/event_scripts.json';

void main() {
  group('场景剧情脚本', () {
    late Map<String, dynamic> d;

    setUpAll(() {
      final f = File(_p);
      if (!f.existsSync()) fail('缺少 $_p');
      d = jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
    });

    test('166 张表，100 张能完整解码', () {
      expect(d['tableCount'], 166);
      // ⚠️ 100，不是 159。这个下降是**修正**，不是退步。
      //
      // 之前指针槽打的是宿主地址，那些"能解码"的表里有 59 张是
      // **碰巧跨过垃圾继续走**到底的 —— 同一份源码，换个运行时
      // `decodedTables` 就在 159/160 之间飘
      // （`EventScr_Ch1Tut_EirikaVisitHouseInit` 一次能解一次不能）。
      //
      // 现在指针槽固定成哨兵，遍历可复现。100 才是**诚实的**数字：
      // 剩下 66 张里有指针被当成指令头，走不下去。
      //
      // 这个数字会随指针解析（把 CALL/LOAD 的目标还原成符号名）而上升。
      expect(d['decodedTables'], 100,
          reason: '数字钉死：解码器或数据变了这里会失败');
      expect(d['instructionCount'], 4263);
    });

    test('真实场景用到 57 种 opcode', () {
      final ops = d['opcodes'] as List<dynamic>;
      expect(ops.length, 57);
    });

    test('覆盖率曲线：前 20 个 opcode 就能覆盖近 9 成指令', () {
      final ops = d['opcodes'] as List<dynamic>;
      var acc = 0.0;
      final at = <int, double>{};
      for (var i = 0; i < ops.length; i++) {
        final o = ops[i] as Map<String, dynamic>;
        acc += (o['percent'] as num).toDouble();
        if ([10, 20, 30, 40].contains(i + 1)) at[i + 1] = acc;
      }
      // 这条曲线是"按频次实现"的依据
      expect(at[10]!, greaterThan(60));
      expect(at[20]!, greaterThan(85));
      expect(at[30]!, greaterThan(95));
    });

    test('**当前实现覆盖真实指令 88.5%**', () {
      final pct = (d['implementedCoveragePercent'] as num).toDouble();
      // 这是最有意义的指标。它上升说明真实可执行的剧情变多了；
      // 数字变化会在这里体现出来，从而提醒更新结论。
      expect(pct, closeTo(88.5, 0.1));
      expect((d['implementedOpcodes'] as List<dynamic>).length,
          greaterThan(25));
    });

    test('频次最高的 opcode 是 SVAL（18.1%）—— 变量赋值', () {
      final top = (d['opcodes'] as List<dynamic>).first
          as Map<String, dynamic>;
      expect(top['name'], 'EV_CMD_SVAL');
      expect((top['percent'] as num).toDouble(), closeTo(18.1, 0.1));
    });
  });
}
