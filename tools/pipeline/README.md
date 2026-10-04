# 数据管线

把 `third_party/fireemblem8j` 的 GBA 格式资产转换成**语义形式**（技术方案 §4.3）。

## 现状

| 阶段 | 状态 |
|---|---|
| `.mar` → 瓦片网格 + **往返自检** | ✅ **66/66 张地图字节级无损**（26541 个瓦片值） |
| `TileConfiguration.S` → metatile/TSA | ✅ 实测 1024 × 4 = 4096 条 |
| 图集 + 调色板 → **地图合成** | ✅ **已与官方图逐像素验证**（4 张地图） |
| 地形类型网格 | ✅ 从 `.S` 末尾的 1024 条 `.byte TERRAIN_*` 查表 |
| **Tiled `.tmx` 导出 + 往返验证** | ✅ **52 / 66 张地图通过**（其余 14 张有明确原因，见下） |
| **纯数据 `.json` 导出（给 `lib/core`）** | ✅ 与 `.tmx` 同源同步导出 |
| C 数据表导出 | ⬜ 待做（归 M1） |

## 用法

```bash
# 渲染成 PNG
python3 extract/map_render.py --list                 # 列出地图与章节资产映射
python3 extract/map_render.py --roundtrip            # 全部地图的 .mar 往返自检
python3 extract/map_render.py PrologueMap --scale 2  # 输出到 tools/pipeline/out/
python3 extract/map_render.py Ch3Map --scale 3 --out /tmp/ch3.png

# 导出成 Tiled .tmx（含图集 PNG）
python3 extract/map_tmx.py PrologueMap --out /tmp/tmx
python3 extract/map_tmx.py --verify /tmp/tmx/PrologueMap.tmx   # 往返验证
python3 extract/map_tmx.py --verify-all --out /tmp/tmx         # 全部导出 + 验证
```

导出的 `.tmx` 直接用 Tiled 打开：`tiled /tmp/tmx/PrologueMap.tmx`

### 输出两份，给两个不同的消费者

| 产物 | 消费者 | 用途 |
|---|---|---|
| `<地图>.tmx` + `<地图>.metatiles.png` | `lib/game`（Flame） | **怎么画** |
| `<地图>.json` | `lib/core`（纯 Dart） | **是什么规则** |

**刻意不合并。** `.tmx` 是视觉格式，把瓦片、图集、图层编码绑在一起；
而 `lib/core` 只关心"哪一格是什么地形"。让规则层去解析 Tiled 的 XML 是架构错误——
将来换掉渲染方案（比如改用预合成纹理 + 着色器，见 §4.9.4）时，规则层不该跟着动。

两者由同一管线从同一份 GBA 数据导出，因此不可能不一致。

JSON 里地形名做了字典去重，避免每格重复存字符串：

```json
{
  "id": "PrologueMap", "chapter": "L00",
  "width": 15, "height": 10, "tileSize": 16,
  "grid": [99, 99, 782, ...],
  "terrainIndex": [0, 0, 1, ...],
  "terrainLegend": ["TERRAIN_PLAINS", "TERRAIN_FOREST", "TERRAIN_RIVER",
                    "TERRAIN_PEAK", "TERRAIN_BRIDGE_REGULAR"]
}
```

序章的地形是 **平原 / 森林 / 河流 / 山峰 / 桥**——与地图画面完全吻合。

## ⚠️ 本项目最大的坑：调色板 bank 内部顺序是反的

**不修正的后果不是"颜色有点偏"，而是明暗完全反相。地图看上去仍然像一张地图**（所以肉眼极易漏过，我们自己就漏过了两轮），**但每个像素的地形类型都是错的。**

### 实测推导过程

1. 图集 PNG 是 **4bit 灰度**（`bitdepth=4, colortype=0`）。手动解码 PNG 的 IDAT 字节证实：
   像素 nibble `v` 就是调色板索引，PIL 的 `>>4` / `&15` 读取**正确**。

   ```
   raw 第一行前 16 像素: [8, 6, 8, 14, 11, 8, 14, 14, 14, 6, 14, 8, 11, 4, 14, 4]
   PIL>>4            : [8, 6, 8, 14, 11, 8, 14, 14, 14, 6, 14, 8, 11, 4, 14, 4]  ✅
   ```

2. 构建链（`Makefile`）是 `png --gbagfx--> .4bpp --lz--> ROM`，且字节精确。
   所以 **ROM 里的 nibble 就是 PNG 的 nibble `v`**。

3. 用 **火焰纹章 Wiki 的官方章节地图**做逐像素比对，发现官方图上某像素的颜色，
   恰好是 `.pal` 文件里 **`15 - v`** 位置的颜色。

4. 反查证实：**ROM 调色板条目 `i` == `.pal` 文件条目 `15 - i`，但 bank 号不变**。
   即 `.pal` 文件每个 16 色 bank 内部顺序是反的。

### 验证结果（与官方图逐像素平均色差，0–765）

| 地图 | 章节 | 修正前 | **修正后** |
|---|---|---:|---:|
| PrologueMap | 序章 The Fall of Renais | 270.58 | **17.43** |
| Ch1Map | 1 Escape! | 186.44 | **25.15** |
| Ch2Map | 2 The Protected | 238.92 | **23.34** |
| Ch3Map | 3 The Bandits of Borgo | 173.73 | **24.26** |

残差 ~17–25 基本只来自官方图上绘制着的角色与光标。

### 修正方式

在 `load_palette()` 里，把每个 16 色 bank 反转（`bank_reversed=True`，默认开启）。
用 `--no-palette-reverse` 可关闭以复现错误结果（仅调试用）。

> 等价写法是把瓦片像素索引取反（`15 - v`）。两种写法输出完全相同，
> 这里选调色板侧修正，因为它把问题定位在一处、且更贴近因果链。

## 已验证的 GBA 地图四层格式

| 层 | 来源 | 关键点 |
|---|---|---|
| 地图网格 | `graphics/map/layout/*.mar` | **`metatileIndex = u16_le >> 5`**（低 5 位是标志，实测全 0） |
| metatile 定义 | `graphics/map/TileConfiguration*.S` | 1024 metatile × 4 条 TSA（TL/TR/BL/BR） |
| TSA 条目 | 同上 | bit 0-9 瓦片索引；bit 10 水平翻转；bit 11 垂直翻转；**bit 12-15 调色板 bank** |
| 图集 | `graphics/map/ObjectType*.png`、`graphics/frontier_map_objtype/*.png` | `bitdepth=4, gray`；瓦片 N 在 `((N%W)*8, (N//W)*8)` |
| 调色板 | `graphics/map/MapPalette*.pal` | JASC，160 色 = 10 banks × 16，**每 bank 需反转** |

### 调色板 bank 的选取（第二容易错的地方）

`src/bmmap_DisplayBmTile.c`：

```c
u16 base = gBmMapFog[y][x] ? (6 << 12) : (11 << 12);
out[k] = base + tsaEntry;          // 直接相加
```

而 `RefreshEntityBmMaps` 在**没有迷雾**的章节把 `gBmMapFog` **全填 1**。

所以：**无迷雾章节走 `6 << 12` 分支 → 调色板文件 bank = `tsaEntry >> 12`**（不是 `5 +`）。
`ApplyPalettes(pal, 6, 10)` = `CopyToPaletteBuffer(src, 0x20*6, 0x20*10)`，确实装到硬件 palette 6。

### ⚠️ 资产映射：**不要信源文件里的注释**

`src/data/data_chapter_asset_table.c` 每条都带 `/* US ... */` 注释。**它们是错的**
（从下标 47 开始漂移）：

```
idx 47  注释 MapPalette4   实际 MapPalette5
idx 52  注释 MapPalette5   实际 Ch12EirikaMap
idx 110 注释 TileConfiguration9  实际 Ch10EphraimMap
```

原因：JP 表比美版**少了 `MapPalette4` 和 `MapPalette16`**（JP 的 `graphics/map/`
里确实没有这两个文件），而注释是从美版整段抄的，于是从第一个缺失处开始错位，
后期能差好几个位置。

**正确做法：按地址反查真实符号名。**

```
gChapterDataAssetTable[M] → gChDAsset_M → JP 地址 → 真实符号名
```

地址来自 `layout/baseline_syms.d/dataMore_chapter_asset_table.tsv`；符号名从三处汇总
（`sym_jp.txt` + `layout/baseline_syms.tsv` + `reference/maps/febuilder_rom_us_jp.tsv`），
再加**段首符号兜底**（`carved_rom.tsv` 的段起点 + 该段 `.c` 里第一个 INCBIN）。

`map_render.py` 的三个 `resolve_*` 全部基于这套机制：

| 符号名 | 文件 |
|---|---|
| `ObjectType4..10` | `graphics/map/ObjectTypeN.png` |
| `ObjectType1/2/3` | `graphics/frontier_map_objtype/*_<地址>.png`（按文件名里的地址匹配） |
| `TowerOfValniObjectType` | `graphics/map/TowerOfValniObjectType.png` |
| `MapPaletteN` / `TowerOfValniMapPalette` | `graphics/map/<符号名>.pal` |
| `TileConfigurationN` / `TowerOfValniTileConfiguration` | `graphics/map/<符号名>.S` |
| `<地图名>` | `graphics/map/layout/<符号名>.mar` |

**交叉验证**：`frontier_map_objtype_002_188888.png` 与美版反编译的 `ObjectType1.png`
**SHA-256 完全相同**；`PrologueMap.mar` 也完全相同。

> ⚠️ **不要按章节顺序猜资产**。例如 `Ch2Map` 属于章节 `L02`，用的是
> `ObjectType1 / MapPalette1 / TileConfiguration1`——和 Ch1 一样，**不是 2**。
> 一律走 `--list` 输出的映射表。

### frontier 图集的真瓦片宽度未 pin

反编译项目自己在 `docs/bin_verification_wave8.md` 标注这些是
*"raw-4bpp, JP-only fresh extraction; **pin true tile width**"*。

实测 **32 宽（行优先）连贯度最优**（相邻像素差异率 0.654，16 色随机期望 0.9375），
且与美版同名素材字节相同，故采用 32 宽。

## Tiled `.tmx` 导出

### 设计：metatile 图集，而不是原始瓦片集

原版瓦片是 4bpp 灰度索引图，**必须配调色板才能看**；而且同一个瓦片索引在不同
metatile 里会用**不同的调色板 bank**，一张原始图集根本无法表达。

所以改成：**给地图用到的每个 metatile 索引发一个 16×16 槽位**，把颜色（含每个角的
翻转）直接烘焙进去。于是：

* 图集是一张普通 RGB PNG，任何编辑器都能打开
* 图层里一格 = 一个 GID，与游戏的格子网格一一对应
* 不需要 Tiled 的翻转标志位

### 自包含 + 无损往返

每个图集槽位在 tileset 的 tile properties 里记录原始 `metatile` 索引与 `terrain`：

```xml
<tile id="0">
 <properties>
  <property name="metatile" type="int" value="34" />
  <property name="terrain" value="TERRAIN_BRIDGE_REGULAR" />
  <property name="terrain_id" type="int" value="19" />
 </properties>
</tile>
```

所以 `.tmx` 是自包含的：读回来即可还原 `(metatile 网格, 地形网格)` 并与
`.mar` + 地形查表逐格比对。**篡改一格会被检出**：

```
$ python3 extract/map_tmx.py --verify /tmp/tamper/PrologueMap.tmx
  ✗ PrologueMap: 1 格 metatile 不一致
```

> ⚠️ **`terrain` 图层是规则层数据，不是装饰。** 地形类型决定移动消耗 / 回避 /
> 防御加成。见下面的红线表——编辑器可以改**外观**，不能改它。

### 覆盖率：52 / 66

未覆盖的 14 张都有明确原因：

| 原因 | 地图 |
|---|---|
| 引用的资产下标无法反查符号名（缺段内符号偏移） | `LagdouRuins1..10`、`Ch10EphraimMap`、`Ch18Map` |
| 没有被任何章节条目引用 | `AnotherShrineMap`、`Ch5TownMapPast` |

## 渲染样本（已与官方图逐像素验证）

| 文件 | 内容 |
|---|---|
| `out/before_vs_after.png` | **左 = 未修正（bank 顺序反）／右 = 修正后** —— 一眼看出问题所在 |
| `out/verified_maps.png` | 自上而下：序章 / Ch1「Escape!」/ Ch2「The Protected」/ Ch3「The Bandits of Borgo」 |
| `out/PrologueMap.png`、`out/Ch1Map.png` | 2× 放大的单张样本 |
| `out/tmx_preview.png` | **完全由 `out/tmx/PrologueMap.tmx` + 图集重建**（独立代码路径），与直接渲染结果 SHA-256 相同 |
| `out/tmx/` | 序章的 `.tmx` 与图集，可直接用 Tiled 打开 |

> 左边那张**看起来也像一张地图**——这正是这个坑危险的地方：不是明显的崩坏，
> 而是明暗反相导致的"地形类型全错"，肉眼很容易放过去。

## 红线（技术方案 §4.9.5）

管线可以换**视觉与格式**，但以下**绝不能改**（它们是游戏规则）：

地形类型网格 · 地图尺寸与格子坐标 · 天气对移动力的影响（`pMovCostTable[0..2]`）·
雾战可见性判定 · 地图变更的触发条件与效果
