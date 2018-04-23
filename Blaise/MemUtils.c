//
//  MemUtils.c
//  Blaise
//
//  Created by Ryan Joseph on 4/16/18.
//  Copyright © 2018 The Alchemist Guild. All rights reserved.
//

#include "MemUtils.h"
#include <string.h>

void BlockMove (void* dest, int destOffset, const void* src, int srcOffset, size_t count) {
    memmove(dest + destOffset, src + srcOffset, count);
}
