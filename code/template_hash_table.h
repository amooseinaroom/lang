
#if !defined TEMPLATE_HASH_TABLE_NAME
#error TEMPLATE_HASH_TABLE_NAME needs to be set to a valid name
#endif

#if !defined TEMPLATE_HASH_TABLE_KEY
#error TEMPLATE_HASH_TABLE_KEY needs to be set to a valid name
#endif

#if !defined TEMPLATE_HASH_TABLE_KEY_ZERO
#define TEMPLATE_HASH_TABLE_KEY_ZERO TEMPLATE_HASH_TABLE_KEY{}
#endif

#include "basic.h"
#include <math.h>

// hash_of function must be collision free for two unique keys
struct TEMPLATE_HASH_TABLE_NAME
{
    usize count;
    usize used_count;
    usize max_probe_step_count;
    
    TEMPLATE_HASH_TABLE_KEY *keys;
    
#if defined TEMPLATE_HASH_TABLE_VALUE
    TEMPLATE_HASH_TABLE_VALUE *values;
#endif

#if defined _DEBUG
    usize max_step_count;
#endif

#if defined TEMPLATE_HASH_TABLE_ADDITINAL_FIELDS
    TEMPLATE_HASH_TABLE_ADDITINAL_FIELDS
#endif
};

// these functions need to be defined
u64 hash_of(TEMPLATE_HASH_TABLE_NAME *table, TEMPLATE_HASH_TABLE_KEY key);
/* bool operator==(TEMPLATE_HASH_TABLE_KEY a, TEMPLATE_HASH_TABLE_KEY b);
bool operator!=(TEMPLATE_HASH_TABLE_KEY a, TEMPLATE_HASH_TABLE_KEY b)
{
    return !(a == b);
}
*/

void clear(TEMPLATE_HASH_TABLE_NAME *table)
{
    memset(table->keys, 0, table->count * sizeof(*table->keys));
    table->used_count = 0;
}

// we don't clear the whole table, since it may have additional fields
void init(TEMPLATE_HASH_TABLE_NAME *table, usize count)
{
    assert(((count - 1) & count) == 0, "count must be a power of 2");    
    table->used_count = 0;
    table->count = count;
    // max_step * (max_step + 1) / 2 = count
    // max_step² + max_step - 2 * count = 0
    // max_step = -1 + sqrt(1 + 2 * count);
    table->max_probe_step_count = (usize) ceil(sqrt(1.0f + 2.0f * (f32) table->count)) - 1;
    
    usize keys_byte_count = sizeof(*table->keys) * count;
    auto byte_count = keys_byte_count;

#if defined TEMPLATE_HASH_TABLE_VALUE
    usize values_byte_count = sizeof(*table->values) * count;
    byte_count += values_byte_count;
#endif
    
    // TODO check alignment?
    table->keys = (TEMPLATE_HASH_TABLE_KEY *) platform_allocate_bytes(byte_count).base;

#if defined TEMPLATE_HASH_TABLE_VALUE
    table->values = (TEMPLATE_HASH_TABLE_VALUE *) (table->keys + count);
#endif

#if defined _DEBUG
    table->max_step_count = 0;
#endif
    
    clear(table);
}

void free_table(TEMPLATE_HASH_TABLE_NAME *table)
{
    platform_free_bytes((u8 *) table->keys);
    *table = {};
}

usize get_index(TEMPLATE_HASH_TABLE_NAME *table, TEMPLATE_HASH_TABLE_KEY key)
{
    auto index_mask = table->count - 1;
    assert((index_mask & table->count) == 0, "table count must be a power of 2");
    
    assert(key != TEMPLATE_HASH_TABLE_KEY_ZERO, "key of zero is not allowed, it is reserved for empty indices");
    
    u64 key_hash = hash_of(table, key);    
    usize index = (usize) key_hash & index_mask;
    for (usize probe_step = 1; probe_step < table->max_probe_step_count; probe_step++)
    {
        auto index_key = table->keys[index];
        if ((index_key == TEMPLATE_HASH_TABLE_KEY_ZERO) || (key == index_key))
            return index;

        #if defined _DEBUG
            table->max_step_count = max(table->max_step_count, probe_step);
        #endif
        
        index = (index + probe_step) & index_mask;
    }
    
    return -1;
}

bool contains_key(TEMPLATE_HASH_TABLE_NAME *table, TEMPLATE_HASH_TABLE_KEY key)
{
    auto index = get_index(table, key);
    return ((index != -1) && (table->keys[index] != TEMPLATE_HASH_TABLE_KEY_ZERO));
}

#if defined TEMPLATE_HASH_TABLE_VALUE
TEMPLATE_HASH_TABLE_VALUE * get_value(TEMPLATE_HASH_TABLE_NAME *table, TEMPLATE_HASH_TABLE_KEY key)
{
    auto index = get_index(table, key);
    if ((index == -1) || (table->keys[index] == TEMPLATE_HASH_TABLE_KEY_ZERO))
        return null;
        
    return &table->values[index];
}
#endif

#if defined TEMPLATE_HASH_TABLE_VALUE
bool insert(TEMPLATE_HASH_TABLE_VALUE **value, TEMPLATE_HASH_TABLE_NAME *table, TEMPLATE_HASH_TABLE_KEY key)
#else
bool insert(TEMPLATE_HASH_TABLE_NAME *table, TEMPLATE_HASH_TABLE_KEY key)
#endif
{
    auto index = get_index(table, key);
    usize new_count = table->count;
    
    u32 debug_repeat_count = 0;
    while (index == -1)
    {
        assert(debug_repeat_count < 2);
        debug_repeat_count++;
        
        new_count <<= 1;
        TEMPLATE_HASH_TABLE_NAME new_table = *table;
        init(&new_table, new_count);
        
        bool ok = true;
        for (usize i = 0; i < table->count; i++)
        {
            auto current_key = table->keys[i];
            if (current_key != TEMPLATE_HASH_TABLE_KEY_ZERO)
            {
                index = get_index(&new_table, current_key);
                
                // can't insert all previous keys
                if (index == -1)
                {
                    free_table(&new_table);
                    ok = false;
                    break;
                }
                
                new_table.keys[index]   = current_key;
            
            #if defined TEMPLATE_HASH_TABLE_VALUE
                new_table.values[index] = table->values[i];
            #endif
            }
        }
        
        if (!ok)
            continue;
        
        index = get_index(&new_table, key);
        
        // still can't insert new key
        if (index == -1)
        {
            free_table(&new_table);
            continue;
        }
        
        new_table.used_count = table->used_count;
        
        free_table(table);
        *table = new_table;
        break;
    }
    
    bool is_new = (table->keys[index] == TEMPLATE_HASH_TABLE_KEY_ZERO);
    table->keys[index] = key;
    
#if defined TEMPLATE_HASH_TABLE_VALUE
    *value = &table->values[index];
#endif
    
    table->used_count += is_new;
    
    return is_new;
}

#undef TEMPLATE_HASH_TABLE_NAME
#undef TEMPLATE_HASH_TABLE_KEY
#undef TEMPLATE_HASH_TABLE_KEY_ZERO

#if defined TEMPLATE_HASH_TABLE_VALUE
#undef TEMPLATE_HASH_TABLE_VALUE
#endif

#if defined TEMPLATE_HASH_TABLE_ADDITINAL_FIELDS
#undef TEMPLATE_HASH_TABLE_ADDITINAL_FIELDS
#endif