---
name: fe8r-source-first
description: 把 fireemblem8j 反编译源码里的语义移植到 Dart 的作业流程 —— 先定位定义文件、再解数据、最后补 PORT OF 与正向判据。用于本仓库任何"实现一个原作子系统"的任务。
whenToUse: 当任务涉及实现/修复 FE8 玩法逻辑（事件、战斗、菜单、地图、单位、AI、乱数、汉化管线），或在动手前需要确认"原作到底怎么做的"时。
---

# 源码优先移植流程

这个仓库最大的失败模式不是"算法难"，而是**写了一个看起来合理的实现，而不是源码里的实现**。
12 个真实 bug 没有一个报错。所以流程本身就固定了。

## 0. 先确认你没在发明

动代码之前问自己一句话：

> **我要写的这个数值 / 映射 / 顺序，出处是哪个文件的哪一行？**

答不上来就**不要写**。去 `docs/源码索引.md` 找。

## 1. 定位定义文件

按这个顺序找，**前面找到就停**：

1. `docs/源码索引.md` —— 项目自己整理的「功能 → 源文件」索引，先查这里
2. `third_party/fireemblem8j/docs/strategy.md`、`porting.md`、`decisions.md`、`asset_forms.md`
   （反编译仓库**自己写给人读**的文档；`decisions.md` 能避免重开已定的问题）
3. 反编译源码本体：

```bash
DECOMP=third_party/fireemblem8j
grep -rn "宏名或函数名" $DECOMP/include/          # 先看头文件里的宏与结构体
grep -rn "表名" $DECOMP/src/data/                 # 再找数据表定义
```

**不要靠猜目录名。** 反例：`UnitDef_Event_PrologueThroneRoomUnits` 定义在
`src/data/worldmap_gmapunit/` —— 目录名和单位毫无关系。靠猜的提取器漏了 **2/3 的表**。

## 2. 读结构体，不要读例子

几乎每个 bug 都源于"我按一个例子推出了结构"。

* 读 `include/` 里的 `struct` 定义，注意 **位域**
  （`u16 xPosition:6, yPosition:6, ...` 解码错一位就是"看似合理但错误"的坐标）
* 读**所有**相关字段，不是只读你要的那一个。
  反例：提取器 `WANTED_SCALAR = ("number",)` 只抽了一个字段 →
  `classes.json` 里一行基础属性都没有 → 战斗悄悄退回演示数据。
* **枚举值必须查**，不许想当然。
  `FACTION_ID_BLUE=0, GREEN=1, RED=2, PURPLE=3` 是"蓝绿红"，不是"蓝红绿"。
  写反了敌人会变成绿色 NPC —— 不报错。
* 注意 `.byte` 与 `.4byte` 的区别；注意"只声明未定义"（`extern` 或裸 `.4byte`）。

## 3. 表可能在汇编里 —— 别急着说"不存在"

C 里只有 `extern`、或者你只看到裸 `.4byte` 时，**先假设是你没找到**。

* 全树扫描：`glob("**/*.c", recursive=True)` ——
  **少了 `recursive=True` 时 `**` 不递归**，直接放在目录下的文件会全漏。
* 汇编里的表是可解的（本项目已解出：单位表 37 张、事件脚本 115 个）。
* **美版（`third_party/fireemblem8u`）常常有可读的 C 版本** —— 用它做
  **交叉验证**，不要当数据源：同名表在两版里坐标可能不同
  （已实测 `PrologueGradoRoyals` 日版 `y=11` / 美版 `y=7`）。

## 4. 写实现

* `lib/core` 的文件**必须**以 `PORT OF:` 头注释开头（架构门禁 R7），列出你读过的源文件。
* 遵守三层：`lib/core`（纯 Dart、无 `dart:io`、无 `async`、无 `DateTime.now`/`Random`）
  ← `lib/game`（Flame）← `lib/ui`。
* **别用字符串切片改代码**（`s.index(...)` + 切片删掉过两个函数）。
  用精确替换。
* **不要跨类型复用组件**：本作有四种不同的菜单，各有自己的源布局值。
  先读那一种的源码，再写。

## 5. 补判据（这一步不做完就不算做完）

按类型选判据：

| 你做的事 | 判据 | 反例（不算判据）|
|---|---|---|
| 解码二进制 | **字节数严丝合缝**：N 条命令恰好消费 N 个字 | "解出来看着对" |
| 解表 / 提取 | **正向抽查真值**：`CLASS_EIRIKA_LORD.baseDef == 3` | "文件存在" |
| 建索引 | **长度下界**：`byNumber` 条数 > 200 | "没抛异常" |
| 移植流程 | 对照源码逐条列出「源码要求 → 核对结果」 | "跑起来没崩" |

**改了提取器就同时加一条计数抽查** —— 少覆盖是静默的，没有抽查就会一路带到产品里。

判据写好后，把「含……判据」写进提交信息（本项目实战有效的做法，见提交 `c2caaf6`）。

## 6. 收尾

* 跑门禁：`./tools/verify/ci.sh`（沙箱下 `flutter pub get` 可能因写 `~/fvm` 缓存失败，
  改用 `dart run tools/verify/run_all.dart`，见 `AGENTS.md`）。
* 更新对应文档（`docs/还差什么.md` 等）—— 那是给下一个 agent 的交接。
