#!/usr/bin/env python3
"""
立绘合成（**未完成** —— 见文件末尾的"卡在哪"）。

## 素材结构（已摸清）

    graphics/portrait/portrait_<名字>_tileset.png    256×32 索引色 PNG（4bpp 图块条）
    graphics/portrait/portrait_<名字>_palette.agbpal  GBA BGR555 调色板（16 色）
    graphics/portrait/portrait_<名字>_mouth.png       口型层
    graphics/portrait/portrait_<名字>_chibi.png       地图小头像

    483 个角色（每个 3~4 个文件）

## 排列从哪来

`src/face.c` 的 `PutFace80x72_Standard(tm, tileref, info)`：

    CallARM_FillTileRect(tm, gBattleForecast_0, (u16)tileref);
    tm[TILEMAP_INDEX(x, y) + 0x00 + 0] = tileref + 0x00 + 0x1C;

`gBattleForecast_0` 是一张 **10×9 图块的 TSA**
（`graphics/battle_forecast/gBattleForecast_0.tsa.bin`，文件头 2 字节是
`[width-1, height-1]`，随后每项 u16 = `tile(10b) | hflip | vflip | pal(4b)`）。

## 已经能跑通的部分

* `.agbpal` → RGB（BGR555，每通道 5 位左移 3 位再补低位）
* TSA 解码（宽度/高度/翻转/调色板bank）
* 索引色 PNG 取图块

合成出来**能认出是那个角色**（蓝发、脸型对），见
`docs/images/m6-portrait-attempt.png`。

## ⚠️ 卡在哪

**图块排列还不对** —— 拼出来的脸有明显错位。

可能的原因（按可能性排序）：

1. `CallARM_FillTileRect` 的语义是 **`tm[i] = pattern[i] + tileref`**，
   而不是直接取 `pattern[i]` 当图块号 —— 我把 TSA 项直接当索引用了
2. `gBattleForecast_0` 是**战斗预测界面**的 TSA，脸部用的可能是另一张，
   或需要配 `info->xMouth` / `yMouth` 的偏移（`PutFace80x72_Standard`
   开头就在算这两个）
3. 立绘实际是 **96×80**（120 图块）而不是 80×72（90 图块）——
   函数名叫 `80x72`，但素材有 128 个图块
4. 图块条可能按 32×32 分块存储，不是简单的行优先

**下一步**：把 `CallARM_FillTileRect` 的实现读出来（它是个 ARM 函数，
在 `src/` 或汇编里），确认第 1 条；再用 `info` 的 xMouth/yMouth 确认第 2 条。

**不要凭猜测调参数** —— 前几轮已经吃过"猜一个错的方向绕三轮"的亏。
"""
