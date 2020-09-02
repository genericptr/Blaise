//
//  MemUtils.h
//  Blaise
//
//  Created by Ryan Joseph on 4/16/18.
//  Copyright © 2018 The Alchemist Guild. All rights reserved.
//

#ifndef MemUtils_h
#define MemUtils_h

#include <stdio.h>

struct MemoryBuffer {
	int index;
	int size;
	void* bytes;
};
typedef struct MemoryBuffer MemoryBuffer;

#endif /* MemUtils_h */
