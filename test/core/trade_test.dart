// 交换（`TradeMenu_ApplyItemSwap`）与交换对象条件的判据。
//
// 出处：`src/bmtrade_0802D520.c:124-135`、`src/bmtarget_0802506C.c:81-114`。
import 'package:fe8r/core/core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('★ 对调 + **双方各自压缩** ⇒ "和空格交换"就是**移动道具**', () {
    // 我：[A, B, 0]  对方：[0, C, 0]
    final r = applyItemSwap([11, 12, 0], 0, [0, 13, 0], 0);
    // 对调后：我 [0, 12, 0] → 压缩 [12, 0, 0]；对方 [11, 13, 0]（已无洞）
    expect(r.a, [12, 0, 0], reason: '发起方压缩后 A 被换走');
    expect(r.b, [11, 13, 0], reason: '对方把 A 收进来');
  });

  test('★ 两件都非空：对调后两边都压缩', () {
    final r = applyItemSwap([11, 0, 0], 0, [22, 0, 0], 0);
    expect(r.a, [22, 0, 0]);
    expect(r.b, [11, 0, 0]);
  });

  test('和自己交换（`hoverColumn == selectedColumn`）就是**原地重排**', () {
    // ⚠️ 必须是**同一个 list 对象**：原作那两个是**指向同一份背包的指针**
    //（我第一次传了两个相同的字面量 ⇒ `identical` 为假 ⇒ 测出来的行为不对）
    final inv = [11, 12, 13, 0, 0];
    final r = applyItemSwap(inv, 0, inv, 2);
    expect(r.a, [13, 12, 11, 0, 0]);
    expect(identical(r.a, r.b), isTrue, reason: '同一个背包 ⇒ 结果也是同一份');
  });

  test('越界槽位：不动（不崩）', () {
    final r = applyItemSwap([11, 0], 5, [22, 0], 0);
    expect(r.a, [11, 0]);
    expect(r.b, [22, 0]);
  });

  test('★ 交换对象条件：逐条照 `TryAddUnitToTradeTargetList`', () {
    bool ok({
      bool allied = true,
      bool subjPhantom = false,
      bool unitPhantom = false,
      int status = 0,
      int subj0 = 11,
      int unit0 = 0,
      bool supply = false,
    }) =>
        isTradeTarget(
          sameAllegiance: allied,
          subjectIsPhantom: subjPhantom,
          unitIsPhantom: unitPhantom,
          unitStatus: status,
          subjectItem0: subj0,
          unitItem0: unit0,
        ) &&
        !supply; // `CA_SUPPLY` 我们没建模（见文件头），这里显式表达"有输送队属性就不行"

    expect(ok(), isTrue, reason: '同阵营 + 发起方 0 号槽非空 ⇒ 可以');
    expect(ok(allied: false), isFalse, reason: '不同阵营');
    expect(ok(unitPhantom: true), isFalse, reason: '幻影职业不能交换');
    expect(ok(subjPhantom: true), isFalse);
    expect(ok(status: kUnitStatusBerserk), isFalse, reason: 'UNIT_STATUS_BERSERK = 4');
    expect(ok(subj0: 0, unit0: 0), isFalse,
        reason: '**双方 0 号槽都空** ⇒ 不能交换（哪怕别处有道具）');
    expect(ok(subj0: 0, unit0: 22), isTrue, reason: '只要有一边非空就行');
    // `isTradeTarget` 本身不判 CA_SUPPLY（我们没建模）；参数在签名里有，
    // 这里直接测它：
    expect(
        isTradeTarget(
            sameAllegiance: true,
            subjectIsPhantom: false,
            unitIsPhantom: false,
            unitStatus: 0,
            subjectItem0: 11,
            unitItem0: 0,
            unitHasSupply: true),
        isFalse,
        reason: '输送队属性 ⇒ 不能作为交换对象');
  });
}
