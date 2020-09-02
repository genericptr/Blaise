//
//  MemUtils.c
//  Blaise
//
//  Created by Ryan Joseph on 4/16/18.
//  Copyright © 2018 The Alchemist Guild. All rights reserved.
//

#include "MemUtils.h"
#include <string.h>
#include <stdlib.h>

void BlockMove (void* dest, int destOffset, const void* src, int srcOffset, size_t count) {
	memmove(dest + destOffset, src + srcOffset, count);
}

void BlockZero (void* dest, int value, size_t count) {
	memset(dest, value, count);
}


MemoryBuffer MemBufferNew(int size) {
	MemoryBuffer buffer;
	buffer.index = 0;
	buffer.size = size;
	buffer.bytes = malloc(size);
	return buffer;
}

void MemBufferPush(MemoryBuffer* buffer, void* bytes, int size) {
	BlockMove(buffer->bytes, buffer->index, bytes, 0, size);
	buffer->index += size;
}

void MemBufferInsert(MemoryBuffer* buffer, void* bytes, int offset, int size) {
	BlockMove(buffer->bytes, offset, bytes, 0, size);
}

void MemBufferGetBytes (MemoryBuffer* buffer, void *bytes, int offset, int size) {
	BlockMove(bytes, 0, buffer->bytes, offset, size);
}

void MemBufferFree (MemoryBuffer* buffer) {
	free(buffer->bytes);
	buffer->bytes = NULL;
	buffer = NULL;
}

