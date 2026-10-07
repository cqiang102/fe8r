// PORT OF: src/player_interface_0808F2C0.c:49-52（`disableTerrainDisplay == 0`
//            ⇒ `Proc_Start(gProcScr_TerrainDisplay)`）
//          src/player_interface_0808E8CC.c:182-205（`DrawTerrainMapUi`：
//            `terrainId = gBmMapTerrain[cursor.y][cursor.x]`；名字 `GetTerrainName`；
//            **def/avoid 只在 `TerrainTable_MovCost_BerserkerNormal[terrainId] > 0` 时显示**）
//          include/types.h:143（`disableTerrainDisplay:1`）
//          src/GetTerrainName.c:5-7（`gTerrainNames[terrainId]`）
//
// ⚠️ **数据缺口**：`gTerrainNames[]`（日文地形名）**没有 carve**
//（`src/` 里只有 `GetTerrainName.c` 的 extern，`.c`/`.s` 都没有定义）
// ⇒ 窗口里显示的是**枚举名**（`TERRAIN_FOREST` 这种），不是原作那句日文。
// 这一条与 `gGuideTable` 同类：**缺数据，不编**。

/// 地形窗口开不开（`disableTerrainDisplay == 0`）
bool terrainWindowVisible({required int disableTerrainDisplay}) =>
    disableTerrainDisplay == 0;

/// def/avoid 那一行显不显示
///
/// 出处：`DrawTerrainMapUi` 用 `TerrainTable_MovCost_BerserkerNormal[terrainId] > 0`
/// 判断（**不可通行**的地形不显示数值）——`-1` 表示不可通行。
bool terrainShowsDefAvo({required int berserkerNormalCost}) =>
    berserkerNormalCost > 0;
