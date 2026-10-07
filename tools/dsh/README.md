# tools/dsh —— FE8 项目的 DSH Agent 预设

这个目录产出**一个 Agent 预设**：`fe8-flutter`。它是内置 `standard`（标准模式）
预设的**派生**：工具集逐字节不变，只把人设换成这个项目的铁律。

```
tools/dsh/
  build_preset.py                 从 standard 派生预设（逐处精确替换，锚点必须命中 1 次）
  verify_preset.py                判据 A/B/C/D + --refresh 刷新基线
  standard.patch.yml              ★ 基线快照：DSH 出货的 standard 预设原文
  fe8-flutter-preset/             ★ DSH bundle（要装进 profile）
    package.json                  dsh.bundle.patch -> cordis.patch.yml
    cordis.patch.yml              生成物，**不要手改**（判据 B 会红）
```

预设本身只带**硬规则**。长篇的项目约定在仓库另外两处，各由官方机制自动加载：

| 文件 | 由谁加载 | 内容 |
|---|---|---|
| [`AGENTS.md`](../../AGENTS.md) | 预设里的 `agent-instructions` 行（项目根 → 工作目录逐级）| 项目事实、架构门禁、验证入口、铁律、文档地图 |
| [`.dsh/skills/fe8r-source-first/`](../../.dsh/skills/fe8r-source-first/SKILL.md) | 预设里的 `skill-filesystem` 行（rank 100 默认根 `<项目根>/.dsh/skills`）| 从反编译源码移植的作业流程 |
| [`.dsh/skills/fe8r-evidence/`](../../.dsh/skills/fe8r-evidence/SKILL.md) | 同上 | 什么算证据、"完成"的口径 |

**所以预设行里不需要任何 `customSkillDirs` 或 `!!js` 路径魔法** ——
用的都是现成的默认根（"不要重复造轮子"）。

---

## 安装到 profile

```bash
# 在 DSH 里（创造模式启用 plugin_manager 工具时）：
plugin_manager(action="install_bundle",
               target="/Users/caoqiang/person/flutter-game/tools/dsh/fe8-flutter-preset")
```

或命令行：

```bash
dsh plugin --profile desktop install /Users/caoqiang/person/flutter-game/tools/dsh/fe8-flutter-preset
```

装完后在 **设置 → 通用 → Agent 预设** 里能看到「FE8 重制（源码优先）」，
点卡片可只读查看它声明的插件列表。

装了什么、为什么需要：profile 的 `package.json` 会多一条
`"dsh-preset-fe8-flutter": "link:<绝对路径>"`，`dsh.profile.bundles` 多一项。
**这依赖仓库停在这个路径上** —— 挪仓库要重装。

---

## 判据

```bash
python3 tools/dsh/verify_preset.py            # 判据 A/B/C/D
python3 tools/dsh/verify_preset.py --refresh  # 从 DSH 应用重抓基线快照
```

| 判据 | 内容 | 什么时候会红 |
|---|---|---|
| **A** 工具集未变 | 两文件从 `- id: agent-instructions` 到文件末尾**逐字节相同** | 有人改了某一行工具/技能/委派配置 |
| **B** 派生可复现 | 重新生成必须与提交的 `cordis.patch.yml` 逐字节相同 | 有人手改了生成物（改人设请改 `build_preset.py`） |
| **C** 基线未过期 | 快照必须等于 DSH 实际出货的 standard | **DSH 升级后** —— 否则新工具会静默不进本预设 |
| **D** 元数据与人设 | id / name / order 存在，人设含 `{{model}}`/`{{cwd}}`/铁律关键词 | 预设退化成"标准模式改个名" |

这四条**都做过证伪**（不是"跑通了所以对"）：

```
改一行工具配置   -> A 红 ✗ 工具集与 standard 不再一致
手改生成物       -> B 红 ✗ 被手改过
伪造基线快照     -> C 红 ✗ 基线快照过期
```

判据 A/B/C 在 `tools/verify/run_all.dart` 里是**门禁的一步**（`[L3] Agent 预设`）。

> ⚠️ 踩过一次：判据列表原先写成列表字面量，**先跑完 B/C 才轮到 A**，
> 于是"偷改一行工具配置"只看到 B 报错，**A 根本没被执行**。
> 已改成按顺序惰性求值 —— "看起来在验、其实没验"是这里最危险的形态。

---

## 改人设 / 跟随 DSH 升级

```bash
# 1. 改人设：编辑 build_preset.py 里的 PERSONA_PREFIX / PERSONA_SUFFIX
# 2. 重新生成
python3 tools/dsh/build_preset.py tools/dsh/standard.patch.yml \
        tools/dsh/fe8-flutter-preset/cordis.patch.yml
# 3. 跑判据
python3 tools/dsh/verify_preset.py
```

DSH 升级后（判据 C 报"基线快照过期"）：

```bash
python3 tools/dsh/verify_preset.py --refresh   # 重抓 standard
git diff tools/dsh/standard.patch.yml          # ★ 先审阅差异：standard 新增了什么工具
python3 tools/dsh/build_preset.py tools/dsh/standard.patch.yml \
        tools/dsh/fe8-flutter-preset/cordis.patch.yml
python3 tools/dsh/verify_preset.py
```

**别跳过"审阅差异"这一步** —— 新增工具的值不值得进本预设是个判断，不是机械动作。

---

## 基线快照是怎么抓的

`verify_preset.py` 内置一个极小的 asar 读取器，直接从
`/Applications/DeepSeek Harness.app/Contents/Resources/app.asar` 里读
`dsh/node_modules/@deepseek-ai/dsh-web-app/presets/standard.patch.yml`。

路径可用 `DSH_ASAR` 覆盖。**两条独立实现（Node 手写解析 / 这个 Python 版）
读出的字节已验证完全相同。**

拿不到应用时（例如 CI），判据 C 会**明确打印一条警告**说自己没被验证，
而不是静默通过。

**出处与许可**：`standard.patch.yml` 是 DeepSeek Harness（`@deepseek-ai/dsh-web-app`，
MIT）出货文件的逐字节副本，仅用作比对基线；它**必须保持逐字节原样**，
否则判据 A/C 会红。`cordis.patch.yml` 是它的派生物。
