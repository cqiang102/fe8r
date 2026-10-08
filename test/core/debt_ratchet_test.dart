// **欠账棘轮**（第 7 轮加）—— 替代"占位符棘轮"作为进度判据。
//
// 为什么换：占位符棘轮**奖励"把占位符换成只记录状态的接线"**，
// 而那正是用户明令禁止的"先做 demo"。实测证据（第 7 轮）：
// 它消掉的调用里 **267 次**属于音频族（`s.sound` / `s.volumeDown`）——
// **一个音都不出**。⇒ 它作为进度指标已被降级为"回归护栏"。
//
// 这份清单是"已知的半成品"，**只许变短**：
// 每一条都要写清 **现在什么样** + **怎样才算做完（判据）**。
// 做完一条就把它删掉，并把期望条数改小。

import 'package:flutter_test/flutter_test.dart';

/// 半成品：`(名称, 现状, 做完的判据)`
const List<(String, String, String)> knownHalfDone = [
  (
    '音频播放',
    ' `s.sound`/`s.volumeDown` 只记录状态（267 处），**一个音都没有**',
    '按 `docs/计划-音频.md` 做完「数据→规则→表现」，并有"事件时轴对齐 + WAV 非静音"判据',
  ),
  (
    'searchAvailableEvent（原始 blob 路线）',
    '无调用方（功能由 `chapter_objectives` 走具名表实现）',
    '要么删掉，要么接上一个真实调用点',
  ),
  (
    'popup / 场景光标 / 输入屏蔽 / 相机',
    '有真实效果，但只有转储判据',
    '各有至少一条端到端判据',
  ),
  (
    'TILECHANGE / TILEREVERT',
    '数据+规则+应用都已全链',
    '有端到端场景（踩图触发地形变化）',
  ),
  (
    '辞書',
    '数据表 `gGuideTable` 未 carve ⇒ 未开始',
    '表位可读后做屏 + 判据',
  ),
  (
    '中断存档 / 读档',
    'M9 未实现（端到端 `suspendBytes=0`）',
    '端到端"存→读→逐字段相同"全绿',
  ),
];

void main() {
  test('★ 欠账清单只许变短（做完一条就删掉并把期望改小）', () {
    const baseline = 6; // ← 第 7 轮实测；每做完一条就改小
    expect(knownHalfDone.length, lessThanOrEqualTo(baseline),
        reason: '新增半成品必须先删掉旧的，或者把这件事做完；'
            '列表不能变长。当前 ${knownHalfDone.length} 条、基线 $baseline 条');
  });

  test('★ 每一条都要写清"现状"与"做完的判据"（不许含糊）', () {
    for (final (name, now, done) in knownHalfDone) {
      expect(name.trim(), isNotEmpty);
      expect(now.trim().length, greaterThan(8),
          reason: '$name：现状要写具体（现在什么样）');
      expect(done.trim().length, greaterThan(8),
          reason: '$name：必须写清"怎样才算做完"（判据），否则不算记账');
    }
  });
}
