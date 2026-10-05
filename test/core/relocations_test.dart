// 重定位读取的测试。
//
// 判据：**在不依赖平台的前提下**能拿到"某个偏移引用哪个符号"。
// 这是把指针类数据从"宿主绝对地址"归一化成"符号引用"的前提 ——
// 章节事件与单位配置都卡在这上面。
//
// 测试自己编译一个小目标文件，然后读它的重定位。
// macOS 走 `otool -rv`，Linux 走 `readelf -r`，两条路径都要覆盖。
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// 调 Python 侧的重定位读取。
/// 它已经是解析逻辑的唯一实现（提取器与测试共用），不必在 Dart 里重写一遍。
({int count, Map<int, String> relocs}) readRelocs(String objPath) {
  final r = Process.runSync('python3', [
    '-c',
    '''
import json, sys
sys.path.insert(0, "tools/pipeline/extract")
import relocations as R
rel = R.read_relocations("$objPath")
print(json.dumps({str(k): v for k, v in rel.items()}))
''',
  ]);
  if (r.exitCode != 0) {
    fail('读取重定位失败: ${r.stderr}');
  }
  final m = jsonDecodeRel(r.stdout as String);
  return (count: m.length, relocs: m);
}

Map<int, String> jsonDecodeRel(String s) {
  final trimmed = s.trim();
  final body = trimmed.substring(1, trimmed.length - 1);
  final out = <int, String>{};
  if (body.isEmpty) return out;
  for (final part in body.split(',')) {
    final i = part.indexOf(':');
    if (i < 0) continue;
    final k = int.parse(part.substring(0, i).trim().replaceAll('"', ''));
    var v = part.substring(i + 1).trim();
    if (v.startsWith('"')) v = v.substring(1, v.length - 1);
    out[k] = v;
  }
  return out;
}

void main() {
  test('能从目标文件读出重定位（符号引用）', () {
    final dir = Directory.systemTemp.createTempSync('reloc_test');
    try {
      final c = File('${dir.path}/t.c')
        ..writeAsStringSync('''
struct S { const char* p; int v; };
extern int gTarget;
struct S tab[] = { { "abc", 1 }, { 0, 2 } };
int* pt = &gTarget;
''');
      final obj = '${dir.path}/t.o';
      final r = Process.runSync('clang',
          ['-O0', '-w', '-c', '-o', obj, c.path]);
      if (r.exitCode != 0) {
        fail('编译测试用例失败: ${r.stderr}');
      }

      final res = readRelocs(obj);
      expect(res.count, greaterThan(0),
          reason: '这个文件里有两个指针，应当有重定位');

      // 命名符号必须能解析出来（并保留加数）
      expect(res.relocs.values.any((v) => v.contains('gTarget')), isTrue,
          reason: '指向 gTarget 的重定位应当被解析成符号名');

      // 指进只读字符串段的那种，应当被明确标成"非命名符号"，
      // 而不是被当成一个符号名 —— 后者会让调用方以为拿到了可用引用。
      final values = res.relocs.values.toList();
      for (final v in values) {
        expect(v, isNotEmpty);
        if (v.startsWith('?')) {
          expect(v.startsWith('?section:') || v.startsWith('?unparsed:'),
              isTrue,
              reason: '解析不了的条目应当以 ?section: / ?unparsed: 标出');
        }
      }
    } finally {
      dir.deleteSync(recursive: true);
    }
  });
}
