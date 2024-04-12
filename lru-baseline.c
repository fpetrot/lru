#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

/*
 * Taken from QEMU cache plugin
 * And hacked a bit so as to allow for a fair comparison with the matrix
 * version of it.
 */

/*
 * LRU eviction policy: For each set, a generation counter is maintained
 * alongside a priority array.
 *
 * On each set access, the generation counter is incremented.
 *
 * On a cache hit: The hit-block is assigned the current generation counter,
 * indicating that it is the most recently used block.
 *
 * On a cache miss: The block with the least priority is searched and replaced
 * with the newly-cached block, of which the priority is set to the current
 * generation number.
 */

typedef struct {
    uint64_t lru_priorities[WAYS];
    uint64_t lru_gen_counter;
} CacheSet;

static inline void lru_update_blk(CacheSet *set, int idx)
{
    set->lru_priorities[idx] = set->lru_gen_counter;
    set->lru_gen_counter++;
}

static inline int lru_get_lru_block(CacheSet *set)
{
    int i, min_idx, min_priority;

    min_priority = set->lru_priorities[0];
    min_idx = 0;

    for (i = 1; i < WAYS; i++) {
        if (set->lru_priorities[i] < min_priority) {
            min_priority = set->lru_priorities[i];
            min_idx = i;
        }
    }
    return min_idx;
}

#define PASTE(x, n) x ## n

#define TESTD(N) \
static inline unsigned int PASTE(test, N)(void) \
{ \
    unsigned int w, r = 0; \
    CacheSet cs = { .lru_gen_counter = 0}; \
    /* Initialize stuff: Zero is MRU, WAYS -1 is LRU */ \
    for (int i = WAYS - 1; i >= 0; i--) { \
        lru_update_blk(&cs, i); \
    } \
    /* Proceed with execution */ \
    for (uint64_t i = 0; i < 0x1ffffffff; i++) { \
        w = i & (N - 1); \
        lru_update_blk(&cs, w); \
        /* Assumes a HR% hit rate */ \
        if ((i % (100 - HR)) == 0) { \
            w = lru_get_lru_block(&cs); \
            r += w; \
        } \
    } \
    return r; \
}

TESTD(WAYS)

#define TESTC(N) PASTE(test, N)()

int main(void)
{
    int t = TESTC(WAYS);
    return t;
}
