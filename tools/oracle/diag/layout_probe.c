#include "global.h"
#include "bmunit.h"
#include "bmitem.h"
#include <stdio.h>
#include <stddef.h>

int main(void) {
    printf("=== Host 上的结构体布局 (Apple clang, arm64) ===\n");
    printf("sizeof(void*)              = %zu\n", sizeof(void*));
    printf("sizeof(struct Unit)        = %zu   (GBA 应为 0x48 = 72)\n", sizeof(struct Unit));
    printf("offsetof(Unit, level)      = 0x%02zX (GBA 0x08)\n", offsetof(struct Unit, level));
    printf("offsetof(Unit, def)        = 0x%02zX (GBA 0x17)\n", offsetof(struct Unit, def));
    printf("offsetof(Unit, items)      = 0x%02zX (GBA 0x1E)\n", offsetof(struct Unit, items));
    printf("offsetof(Unit, pMapSpriteHandle) = 0x%02zX (GBA 0x3C)\n", offsetof(struct Unit, pMapSpriteHandle));
    printf("sizeof(struct ItemData)    = %zu\n", sizeof(struct ItemData));
    printf("sizeof(struct CharacterData)= %zu\n", sizeof(struct CharacterData));
    printf("sizeof(struct ClassData)   = %zu\n", sizeof(struct ClassData));
    return 0;
}
