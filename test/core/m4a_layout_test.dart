// `struct MusicPlayerInfo` 布局判据（第 14 轮）
//
// ★ 判据：逐字段的**偏移与大小**必须等于 C 头里的布局
//   （`include/gba/m4a_internal.h:294-319`，GBA/ARM32 自然对齐：指针 4、u32 4、u16 2、u8 1）。
//   为什么值得一条判据：M4A 的时序语义**全部**读写这些字段
//   （`tempoD/tempoU/tempoI/tempoC`、`fadeOI/fadeOC/fadeOV`），
//   字段位置错了之后每一步都错，而且**不报错**。

import 'package:fe8r/core/core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('★ 字段顺序与偏移逐条钉住', () {
    const expectOffsets = {
      'songHeader': 0, 'status': 4, 'trackCount': 8, 'priority': 9, 'cmd': 10,
      'unk_B': 11, 'clock': 12, 'gap': 16, 'memAccArea': 24, 'tempoD': 28,
      'tempoU': 30, 'tempoI': 32, 'tempoC': 34, 'fadeOI': 36, 'fadeOC': 38,
      'fadeOV': 40, 'tracks': 44, 'tone': 48, 'ident': 52, 'func': 56, 'intp': 60,
    };
    final got = {for (final f in MusicPlayerInfo.fields) f.name: f.offset};
    expect(got, expectOffsets);

    // 字段按偏移**单调递增**且互不重叠（含显式 gap[8]）
    final fs = MusicPlayerInfo.fields;
    for (var i = 1; i < fs.length; i++) {
      expect(fs[i].offset, greaterThanOrEqualTo(fs[i - 1].offset + fs[i - 1].size),
          reason: '${fs[i - 1].name} 与 ${fs[i].name} 重叠');
    }
  });

  test('★ 总大小 64，且对齐补白只有 [42..43] 两字节', () {
    final last = MusicPlayerInfo.fields.last;
    // ⚠️ 我第一版写 `end == 62` + "补白到 64" —— 算错了自己：
    //   `intp` 在 60、大小 4 ⇒ 结束在 **64**，**没有尾部补白**。
    final end = last.offset + last.size;
    expect(end, 64, reason: '最后一个字段（intp）结束在 64');
    expect(MusicPlayerInfo.size, 64, reason: '正好 64，无尾部补白');
    expect(MusicPlayerInfo.padding, {42: 2}, reason: '唯一的补白在 tracks 之前');
  });

  test('★ 四个 tempo 字段与三个 fade 字段位置（时序语义都住在这儿）', () {
    for (final n in ['tempoD', 'tempoU', 'tempoI', 'tempoC']) {
      expect(MusicPlayerInfo.field(n).size, 2, reason: n);
      expect(MusicPlayerInfo.field(n).cType, 'u16', reason: n);
    }
    for (final n in ['fadeOI', 'fadeOC', 'fadeOV']) {
      expect(MusicPlayerInfo.field(n).size, 2, reason: n);
    }
    // `gap[8]` 是源码里**就有**的空洞，不是我省略的字段
    expect(MusicPlayerInfo.field('gap').cType, 'u8[8]');
    expect(MusicPlayerInfo.field('gap').size, 8);
  });

  test('★ 头文件里的常量逐条对上（不凭印象）', () {
    // `include/gba/m4a_internal.h:283-295`
    expect(MPlayStatus.track, 0x0000FFFF);
    expect(MPlayStatus.pause, 0x80000000);
    expect(MPlayStatus.maxTracks, 16);
    expect(MPlayFade.temporaryFade, 0x0001);
    expect(MPlayFade.fadeIn, 0x0002);
    expect(MPlayFade.volMax, 64);
    expect(MPlayFade.volShift, 2);
  });

  test('★ 不存在的字段要抛错（不静默返回 null）', () {
    expect(() => MusicPlayerInfo.field('没有这个字段'), throwsArgumentError);
  });
}
