// 职业属性位（`attributes`）与它替换掉的"职业名近似"。
//
// 出处：`include/bmunit.h:305-345`（位定义）、`src/data/data_classes.c`（各职业的
//       `.attributes = CA_… | CA_…`，由 `parse_class_tables.py` 抽进 `classes.json`）。
import 'dart:convert';
import 'dart:io';

import 'package:fe8r/core/core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Map<String, dynamic> classes;
  setUpAll(() {
    final f = File('tools/pipeline/out/tables/classes.json');
    if (!f.existsSync()) fail('缺少 ${f.path}（先跑 parse_class_tables.py）');
    classes = (jsonDecode(f.readAsStringSync())
        as Map<String, dynamic>)['classes'] as Map<String, dynamic>;
  });

  Map<String, dynamic> entry(String key) =>
      (classes[key] as Map).cast<String, dynamic>();

  int attrsOf(String key) => (entry(key)['attributes'] as num).toInt();

  test('★ 真值抽查：CLASS_EIRIKA_LORD.attributes == 2^13 + 2^17 + 2^28', () {
    // 出处：`src/data/data_classes.c` 的 `.attributes = CA_LORD | CA_LOCK_2 | CA_LOCK_4`
    // 位值：CA_LORD=1<<13（`include/bmunit.h:324`）、CA_LOCK_2=1<<17（:328）、
    //       CA_LOCK_4=**1<<28**（:339）
    final e = entry('CLASS_EIRIKA_LORD');
    expect(e['attributes'], 268574720,
        reason: '(1<<13) + (1<<17) + (1<<28) —— "我以为 LOCK_4 是 1<<18"是错的，'
            '这个抽查就是为此存在的');
    expect((e['attributeNames'] as List).toSet(),
        {'CA_LORD', 'CA_LOCK_2', 'CA_LOCK_4'});
    // 用位断言（不写魔数）：领主但**不是**女性、**不**骑乘
    final a = attrsOf('CLASS_EIRIKA_LORD');
    expect(classHasAttribute(a, caLord), isTrue);
    expect(classHasAttribute(a, caFemale), isFalse, reason: '艾莉卡领主职业没有 CA_FEMALE');
    expect(classHasAttribute(a, caMountedAid), isFalse);
  });

  test('★ 位表与源码一致（含容易记错的 CA_LOCK_4）', () {
    expect(caLord, 8192, reason: '1<<13');
    expect(caLock2, 131072, reason: '1<<17');
    expect(caLock3, 262144, reason: '1<<18');
    expect(caBits['CA_LOCK_4'], isNull, reason: '本表只列到 LOCK_3（LOCK_4/LOCK_5 在头和尾）');
    expect(caFemale, 16384, reason: '1<<14');
    expect(caThief, 8, reason: '1<<3');
    expect(caSupply, 512, reason: '1<<9');
    expect(caMountedAid, 1, reason: '1<<0');
  });

  test('★ 职业侧有 CA_MOUNTEDAID / CA_THIEF / CA_SUPPLY（不是"抽了但全 0"）', () {
    int count(int bit) => classes.values
        .where((c) =>
            classHasAttribute(((c as Map)['attributes'] as num).toInt(), bit))
        .length;
    expect(count(caMountedAid), greaterThan(0), reason: 'CA_MOUNTEDAID（骑乘）');
    expect(count(caThief), greaterThan(0), reason: 'CA_THIEF');
    expect(count(caSupply), greaterThan(0), reason: 'CA_SUPPLY');
  });

  test('★ CA_FEMALE 在**角色**数据里，不在职业数据里（两边凑成 UNIT_CATTRIBUTES）', () {
    // 出处：`include/bmunit.h:479`
    //   `UNIT_CATTRIBUTES(aUnit) = pCharacterData->attributes | pClassData->attributes`
    // 实测：`CLASS_PEGASUS_KNIGHT.attributes = CA_MOUNTEDAID | CA_CANTO | CA_PEGASUS`
    //（**没有** CA_FEMALE）；`CHARACTER_EIRIKA.attributes = CA_FEMALE`（= 16384）。
    final clsFemale = classes.values
        .where((c) =>
            classHasAttribute(((c as Map)['attributes'] as num).toInt(), caFemale))
        .length;
    expect(clsFemale, 0,
        reason: '★ 职业侧一个都没有 —— 我第 54 轮拿"职业里有女性"当判据是**错的假设**，'
            '这条断言把这个事实钉住，免得下一个人再绕一圈');
    final chFile = File('tools/pipeline/out/tables/characters.json');
    final chars = ((jsonDecode(chFile.readAsStringSync())
                as Map<String, dynamic>)['entries'] as Map)
        .cast<String, dynamic>();
    final charsFemale = chars.values.where((c) {
      final a = (c as Map)['attributes'];
      return a is num && classHasAttribute(a.toInt(), caFemale);
    }).length;
    expect(charsFemale, greaterThan(0), reason: '角色侧有女性');
    expect((chars['CHARACTER_EIRIKA'] as Map)['attributes'], 16384,
        reason: '★ 抽查：CA_FEMALE = 16384（1<<14）');
  });
}
