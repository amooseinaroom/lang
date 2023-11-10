#pragma once

#include "basic.h"

u32 crc32_table[256];

void crc32_init()
{
#if 1
        u8 index = 0;
        do
        {
                crc32_table[index] = index;
                for (int z = 8; z; z--)
                {
                    if (crc32_table[index] & 1)
                        crc32_table[index] = (crc32_table[index] >> 1) ^ 0xEDB88320;
                    else
                        crc32_table[index] = crc32_table[index] >> 1;
                }
        }
        while (++index);
#else
    crc32_table[0] = 0;
    u32 crc = 1;
    u32 i = 128;
    
    do
    {
        if (crc & 1)
            crc = (crc >> 1) ^ 0x8408; // The CRC polynomial
        else 
            crc = crc >> 1;
            
        // crc is the value of crc32_table[i]; let j iterate over the already-initialized entries
        for (u32 j = 0; j < 256; j += i << 1)
            crc32_table[i + j] = crc ^ crc32_table[j];
        
        i >>= 1;
    } while (i > 0);
#endif
}

u32 crc32_begin()
{
    assert(crc32_table[1], "crc32_table not init, run crc32_init first");
    return ~0;
}

u32 crc32_advance(u32 crc32_value, u8_array data)
{
    for (u32 i = 0; i < data.count; i++)
    {
        u32 index = (crc32_value ^ data.base[i]) & 255;
        crc32_value = (crc32_value >> 8) ^ crc32_table[index];
    }
    
    return crc32_value;
}

u32 crc32_end(u32 crc32_value)
{
    return ~crc32_value;
}

u32 crc32_of(string text)
{
    u32 value = crc32_begin();
    value = crc32_advance(value, text);
    value = crc32_end(value);
    
    return value;
}
