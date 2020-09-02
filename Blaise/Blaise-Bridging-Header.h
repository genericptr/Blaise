//
//  Use this file to import your target's public headers that you would like to expose to Swift.
//

#include "MemUtils.h"

void BlockMove (void* dest, int destOffset, void* src, int srcOffset, int count);
void BlockZero (void* dest, int value, int count);

MemoryBuffer MemBufferNew(int size);
void MemBufferPush(MemoryBuffer* buffer, void* bytes, int size);
void MemBufferInsert(MemoryBuffer* buffer, void* bytes, int offset, int size);
void MemBufferGetBytes (MemoryBuffer* buffer, void *bytes, int offset, int size);
void MemBufferFree (MemoryBuffer* buffer);
