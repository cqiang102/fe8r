#!/usr/bin/env python3
"""
事件脚本的操作码表 —— **命令字的位域定义**。

出处：`include/eventscript.h:570-576`

```c
#define _EvtCmd(cmd, len, sub) \\
    (((cmd) & 0xFF) << 8) + (((len) & 0x0F) << 4) + (((sub) & 0x0F))
#define _EvtParams2(x, y) ((((y) & 0xFFFF) << 16) + ((x) & 0xFFFF))
#define _EvtArg0(cmd, len, sub, arg0) _EvtParams2(_EvtCmd(cmd, len, sub), arg0)
```

**所以一个命令字是**：

    bit  0..3   sub（子命令，随 cmd 而变）
    bit  4..7   len（这条命令占几个字，含命令字本身）
    bit  8..15  cmd（操作码）
    bit 16..31  arg0（第一个参数）

`len` 非常关键 —— **靠它才知道下一条命令从哪开始**，
这也是"字节数严丝合缝"的判据。
"""

# fmt: off
OPCODES = {
    0x00: "NOP", 0x01: "END", 0x02: "EVSET", 0x03: "EVCHECK",
    0x04: "RANDOMNUMBER", 0x05: "SVAL", 0x06: "SLOT_OPS", 0x07: "QUEUE_OPS",
    0x08: "LABEL", 0x09: "GOTO", 0x0A: "CALL", 0x0B: "ENQUEUE_CALL",
    0x0C: "BRANCH", 0x0D: "ASMC", 0x0E: "STALL", 0x0F: "COUNTER",
    0x10: "EVBITMODIFY", 0x11: "IGNOREKEYS", 0x12: "BGMCHANGE_12",
    0x13: "BGMCHANGE_13", 0x14: "BGMOVERWRITE", 0x15: "BGMVOLUMECHANGE",
    0x16: "PLAYSE", 0x17: "FADE", 0x18: "COLORFADE", 0x19: "CHECKVARIOUS",
    0x1A: "SETTEXTTYPE", 0x1B: "DISPLAYTEXT", 0x1C: "CONTINUETEXT",
    0x1D: "ENDTEXT", 0x1E: "DISPLAYFACE", 0x1F: "MOVEFACE",
    0x20: "CLEARTEXTBOX", 0x21: "SHOWBG", 0x22: "CLEARSCREEN",
    0x23: "CMD23", 0x24: "CMD24", 0x25: "LOMA", 0x26: "CAMERACONTROL",
    0x27: "TILE_CHANGE", 0x28: "CHANGEWEATHER", 0x29: "CHANGEFOGVISION",
    0x2A: "CHANGECHAPTER", 0x2B: "LOAD_PRECONF", 0x2C: "LOADUNIT",
    0x2D: "CHANGE_PAL", 0x2E: "GET_PID", 0x2F: "MOVEUNIT", 0x30: "ENUN",
    0x31: "TOGGLERANGE", 0x32: "LOADSINGLEUNIT", 0x33: "CHECKSTATE",
    0x34: "CHANGESTATE", 0x35: "CHANGECLASS", 0x36: "CHECKINAREA",
    0x37: "GIVEITEM", 0x38: "CHANGEACTIVEUNIT", 0x39: "CHANGEAI",
    0x3A: "DISPLAYPOPUP", 0x3B: "DISPLAYCURSOR", 0x3C: "MOVE_CURSOR",
    0x3D: "MENUOVERRIDE", 0x3E: "PREPSCREEN", 0x3F: "SCRIPT_BATTLE",
    0x40: "PROM", 0x41: "WARP", 0x42: "EARTHQUAKE", 0x43: "SUMMONUNIT",
    0x44: "BREAKSTONE", 0x45: "GLOWING_CROSS",
    0x80: "WM_80", 0x81: "WM_81", 0x82: "WM_82", 0x83: "WM_SETCAM",
    0x84: "WM_84", 0x85: "WM_CENTERCAMONLORD", 0x86: "WM_MOVECAM",
    0x87: "WM_MOVECAMTO", 0x88: "WM_88", 0x89: "WM_WAITFORCAM",
}
# fmt: on


def decode_word(w):
    """把一个命令字拆成 `(cmd, name, len, sub, arg0)`"""
    sub = w & 0xF
    ln = (w >> 4) & 0xF
    cmd = (w >> 8) & 0xFF
    arg = (w >> 16) & 0xFFFF
    return cmd, OPCODES.get(cmd, f"UNKNOWN_{cmd:02X}"), ln, sub, arg
