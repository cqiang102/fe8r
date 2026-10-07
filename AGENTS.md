# AGENTS.md —— FE8 重制版的 agent 工作约定

> 由 DSH 的 `agent-instructions` 行自动加载（项目根 → 当前工作目录，逐级）。
> 这里只写**行为约定**：怎么干、怎么算干对了。
> 一切**事实**以 `third_party/fireemblem8j` 源码和 `docs/` 为准，本文不复述数值。
>
> 配套：DSH 预设 `fe8-flutter`；skills `fe8r-source-first`、`fe8r-evidence`。

---

## 一、项目

《火焰之纹章：圣魔之光石》的 Flutter / Flame 重制版。
**规则**逐位 1:1 移植自反编译源码，**表现**用 Flutter / Flame 重新实现。仅供个人学习，不对外分发。

| 角色 | 路径 | 说明 |
|---|---|---|
| 规范（唯一真值）| `third_party/fireemblem8j` | 日版 BE8J 反编译源码 |
| 交叉验证参考 | `third_party/fireemblem8u` | **不是数据源**。两版真值不同，已实测：`PrologueGradoRoyals` 第 2 条日版 `y=11`、美版 `y=7` |

`third_party/` 在 `.gitignore` 里（151 MB，可复现的外部依赖）。

---

## 二、三层架构（机器强制，不是自觉）

```
lib/core  （纯 Dart 规则层）  ←  lib/game （Flame）  ←  lib/ui
```

`tools/verify/check_architecture.dart` 强制 7 条规则：

| 规则 | 内容 |
|---|---|
| R1 | `lib/core` 不得依赖 Flutter / Flame / `dart:ui` |
| R2 | `lib/core` 不得依赖 `dart:io` |
| R3 | `lib/core` 不得有非确定性来源（`DateTime.now` / `Random` / `Stopwatch`） |
| R4 | `lib/core` 不得使用 `async`/`await`（事件引擎必须是可中断、可存档的状态机） |
| R5 | `lib/core` 不得直接依赖 GBA 平台层（技术方案 §4.8 负面清单） |
| R6 | `lib/ui` 不得反向依赖 `lib/game` 的内部实现 |
| R7 | **`lib/core` 的每个文件必须带 `PORT OF: <C 源文件>` 头注释** |

> ⚠️ **R7 曾经是一条死规则。** 它用了剥注释的作用域，而它要匹配的正是注释，
> 于是"出现在任何合法 Dart 里都不可能命中"。审计实测：新建一个没有 `PORT OF:`
> 的纯 Dart 文件，门禁仍然报「7 条规则通过」、退出 0。
>
> **结论：门禁绿 ≠ 门禁有效。** 新增或修改任何一条规则/断言后，
> **必须验证它真的会失败**（故意造一个违规样本，看它红）。

`PORT OF:` 也是给"接上了源码"这件事留的可审计痕迹 —— 见第四节铁律 1。

---

## 三、验证入口

```bash
# 完整门禁（= flutter pub get + 下面那条）
./tools/verify/ci.sh

# 只要门禁本身（跳过 pub get；沙箱下常用）
"$HOME/fvm/versions/$(sed -n 's/.*"flutter"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' .fvmrc)/bin/cache/dart-sdk/bin/dart" \
    run tools/verify/run_all.dart

# 单元测试
"$HOME/fvm/versions/<版本>/bin/cache/dart-sdk/bin/dart" test

# 截图（不走 flutter run）
./tools/verify/shot.sh <out.png> [标题画面] [输入脚本]
```

* `tools/verify/run_all.dart` 是**门禁清单的唯一真源**；`ci.sh` 只是环境准备 + 调它。
* `shot.sh` 的环境变量：`FE8R_DEBUG=1` 显示调试 HUD；`FE8R_DUMP=<path>` 出状态转储；
  `FE8R_TITLE=` / `FE8R_SCRIPT=` 控制跳转与输入脚本。
* **数字以脚本输出为准**，不要引用本文或任何文档里的历史计数。

### ⚠️ 沙箱下的已知失败（不是项目坏了）

`ci.sh` 的第 4 步是 `"$FLUTTER_BIN" pub get`，而 fvm 的 `flutter` 是个会写
`~/fvm/versions/<版本>/bin/cache/engine.stamp` 的包装脚本。当工作区沙箱不允许写
工作区外的路径时，它会打印：

```
update_engine_version.sh: line 71: .../engine.stamp.tmp.<pid>: Operation not permitted
```

并以非 0 退出。**这条与项目代码无关。** 用上面第二条（直接 `dart run`）跑门禁即可。

---

## 四、铁律

这 12 条来自 `docs/复盘.md` 里 12 个**真实发生过**的 bug —— 它们**没有一个报错**，
全都是"跑起来了，但不对"。新加一条之前先读那份复盘。

### 1. 先读源码，再写代码

**动手实现任何子系统之前，先列出定义它语义的源文件，读完再写。**

入口是 `docs/源码索引.md`。它的存在理由值得抄一遍：

| 先做了什么 | 源码里其实有什么 | 代价 |
|---|---|---|
| 写重定位工具解指针 | `layout/baseline_syms.tsv` 里直接写着 | 2 轮 + 用户叫停 |
| 把对白截断当渲染 bug | `texts/jp_textdefs.txt` 里 `[A]`=等按键 | 1 轮 |
| 试 4 种图块排列 | `src/face.c` 的 `PutFace80x72_Standard` → `TmApplyTsa` | 2 轮 |
| 说"表在 ROM 里、未 carve" | 就在 `src/data/frontier_df4_banim_b.c`，可读的 C | 半轮 |
| 按"槽位"实现立绘 | `[OpenXXX]` 是**位置**不是槽位 | 1 轮 |
| 说"25 项全绿" | 从没验证过门禁真的会失败 | 门禁假了很久 |
| 键盘外面包一层 `Focus` | Flame 源码写着没混 `KeyboardEvents` 就吞掉 | 假了很久 |

> **七处里有五处的答案，就在一个能直接打开的文件里。**

具体地：

* **不许自己发明**数值、公式、坐标、枚举映射、流程。写出来的每一个都要能指到 `file:line`。
* **不许想当然枚举值**。反例：`FACTION_ID_BLUE=0, GREEN=1, RED=2, PURPLE=3` ——
  "蓝绿红"，不是"蓝红绿"。写反了敌人会变成绿色 NPC，而且不报错。
* **美版只能当参考。** 同名的表在两版里坐标可能不同（已实测）。拿它当交叉验证，
  不要当数据源。
* 指不到出处的陈述，写「**未查证**」，不要当成事实叙述。
  （反例：连续好几轮把赛特说成艾莉卡 —— 提取一直是对的，是叙述错了。）

### 2. 判据先于实现

**动代码之前，先写下「什么可观测的东西能证明我做对了」，并写进提交信息。**

* 好例子：提交 `c2caaf6` 标题里就写了「含严丝合缝判据」。
* 「能跑起来」「没崩」**不是**判据。
* 解码类：**字节数严丝合缝**（N 条命令恰好消费 N 个字）。这条抓到过事件脚本解码。
* 提取类：**正向抽查真值**（`CLASS_EIRIKA_LORD.baseDef == 3`），不是"文件存在"。
* 索引类：**长度下界**（`byNumber` 条数 > 200），而不是"没抛异常"。

### 3. 截图不是完成

**一张截图只证明「那一刻那一帧」，证明不了「这条链路」。**

| 宣称 | 一张图的实际证明力 |
|---|---|
| 开场链路 OK | 只证明难度页能显示 |
| 序章剧情 OK | 没证明过场能走完 |
| 序章战斗 OK | 没证明能重复打赢 |

**只有存在可重复执行的检查（测试 / 转储断言 / CI 步）才能说「完成」。**
否则说「抽查过」或「未验证」。

报告状态时**分四类**，不许让第一类吸收后三类：

```
机器验证 / 抽查过 / 未验证 / 已知有 bug
```

`FE8R_DUMP` 的状态转储就是为此存在的 —— 它第一次跑就抓到两个截图看不出来的问题
（渲染组件数 6 ≠ 存活单位 5；艾莉卡 items 里没有细剑）。
**一次跑回答多个问题，比"一个疑问一次截图"快一个数量级。**

### 4. 静默失败必须响亮

**查表失败不许退回演示数据。** 要显式记录，并让一条测试红。

本项目所有 bug 的共同形状，都是一次具体查询悄悄返回了空/兜底值：

| 形状 | 真例 |
|---|---|
| 索引整片为空 | `number` 是枚举名（`ITEM_SWORD_IRON`）而不是数字，按 `is int` 过滤后全空 |
| 占位代替实现 | `LoadUnits` / `MOVE` 只写了个 HUD 字符串 |
| **我自己造的工具把我骗了** | `FE8R_NODELAY` 是我为"推长过场"加的，它把输入在场景开始前丢光，我却据此得出「`loadMap(0)` 从未执行」并写进提交信息 |
| 覆盖范围小于假设 | 提取器只扫 3 个目录模式 → **少 2/3 的表**；`glob("**/*.c")` 少了 `recursive=True` → 直接放在目录下的文件全漏 |
| 靠猜目录名 | `UnitDef_Event_PrologueThroneRoomUnits` 定义在 `worldmap_gmapunit/` —— 目录名和单位毫无关系 |
| id 不再唯一 | 每次 `LOAD` 都从 `0x100` 重新编号 → 敌人的组件顶掉了我方的组件 |
| 只声明未定义 | 表/脚本只以裸 `.4byte` 存在于 `.s` 里，或只有 `extern` |

**动手前问一句：这次查询失败时会发生什么？** 如果答案是"用别的值继续"，就是 bug。

新增断言时优先加这几条（它们会**当场**抓到上表里的问题）：

```dart
assert(field.units.map((u) => u.id).toSet().length == field.units.length);        // id 唯一
assert(_unitById.length == field.units.where((u) => u.isAlive).length);           // 无幽灵精灵
```

### 5. 字节相同 ⇒ 改动没生效

**截图/产物与改动前字节完全相同，先当"改动没生效"，而不是"改动没影响"。**

抓到过两次：`..anchor = Anchor.topLeft` 其实是空操作（Flame 的默认值就是它）；
`FE8R_NODELAY` 导致的假象。**先查这个，再从图里下任何结论。**

### 6. 用户说"不对" = bug 报告

**先当"存在 bug"去构造判据，不要先解释"应该是对的"。**

实测：用户报过 6 次「不对」（单位不对 / 剧情不动 / 按源码做 / 光标不对 / 我方不对 /
相机不对），**6 次全中**，每一次都指向一个真 bug。

最典型的一次：HUD 里的坐标**一直是对的**，我盯着对的那一半看了好几轮 ——
**而错的是画面**（单位 id 冲突，精灵被顶掉）。
解法是**把两边的依据都显示出来**（HUD 数值 vs 光标实际位置），而不是信任能打印的那一半。

### 7. 别用字符串切片改代码

用 `s.index(...)` + 切片已经删掉过 `_loadSceneData()` 和 `backgroundColor()`；
那次是"编译不过"救的。**如果删掉的是不报错的东西，就会静默损坏。**
一律用 `edit` 的精确替换。

---

## 五、数据管线

```
third_party/fireemblem8j  ──► tools/pipeline/extract/*.py ──► tools/pipeline/out/tables/*.json ──► assets/
```

* `tools/pipeline/extract/` 有 30 个提取器，每个都对应一张表或一类素材。
* `tools/pipeline/out/tables/` 是**产物**，改提取器后要重跑（`ci.sh` 会重建并比对）。
* **提取器的覆盖面是风险点**：它靠什么 glob、扫哪些目录，决定了"少多少张表"。
  改提取器时**同时加一条正向计数抽查**，否则少覆盖是静默的。
* 汉化：`tools/i18n/i18n.py`（`extract` / `apply` / `verify`）。
  译文按**文本 run 的数组**存（`tools/i18n/zh/*.json`），控制码永不移动；
  `verify` 会拒绝 run 数不匹配或译文里含控制码。
  `tools/i18n/non_text.json` 登记 9 个非文本槽位，**翻译它们会让 verify 失败**。
  合并产物是 `assets/i18n/zh_CN.json`。

---

## 六、文档地图

| 想干什么 | 先读 |
|---|---|
| 实现任何子系统前 | `docs/源码索引.md`（**铁律，先读这个**）|
| 知道哪些错了、怎么防 | `docs/复盘.md` |
| 知道现在到哪了、还差什么 | `docs/还差什么.md` |
| 整体设计 | `docs/技术方案.md` |
| 开场链路 / 菜单 / 胜负条件 | `docs/开场流程.md`、`docs/菜单盘点.md`、`docs/胜负条件.md` |
| 复刻的边界（什么做不到）| `docs/复刻的边界.md`、`docs/缺失的脚本.md` |
| 美版文本能不能用 | `docs/美版文本可用性.md` |

**改完代码顺手更新对应文档** —— 这几份文档是给下一个 agent 的交接，不是装饰。

---

## 七、汇报的规矩

* 说"完成"必须有可重复的检查；否则用「抽查过」/「未验证」。
* 涉及项目数据的每句话都要能指到 `file:line`；指不到就标「未查证」。
* **明确列出"我没看过的地方"**，"其他应该没问题"不是可接受的回答。
* 卡住了就说卡在哪一条判据上，不要用"差不多了"收尾。
