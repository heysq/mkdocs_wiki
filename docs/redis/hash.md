### 哈希冲突
- 键的空间会大于Hash表的空间
- 导致用hash函数把键映射到Hash表空间时，会出现不同的键被映射到数组同一个位置上
- 如果同一个位置只能保存一个键值对，就会导致hash冲突

#### hash 冲突解决
- 链式哈希，且hash的链不能太长，太长也会影响性能
- rehash，增大hash表空间，重新计算hash表内的数据的hash
- 渐进式rehash 优化

### 链式哈希
- 每个hash的对象存储这下一个链表节点的指针
- redis 哈市结构
```c

typedef struct dictht {
    dictEntry **table; //二维数组
    unsigned long size; //Hash表大小
    unsigned long sizemask;
    unsigned long used;
} dictht;
```
- redis hash中的 dictEntry结构
```c

typedef struct dictEntry {
    void *key;
    union {
        void *val;
        uint64_t u64; // 本身存储的是8字节的内容时就不需要单独开辟空间存储指针了
        int64_t s64;
        double d;
    } v;
    struct dictEntry *next;
} dictEntry;
```

### rehash
- 两个哈希表，用于交替保存数据
- 正常请求阶段，数据全部写入到hash0
- 进行rehash，数据迁移到hash1
- 迁移完成后，hash0被释放，hash1的地址复制给hash0，hash1清空

### rehash 条件
- ht[0]承载的元素个数已经超过了 ht[0]的大小，同时 Hash 表`dict_can_resize`等于1，表示可以进行扩容
- ht[0]承载的元素个数，是 ht[0]的大小的 dict_force_resize_ratio 倍，其中，dict_force_resize_ratio 的默认值是 5

### rehash 触发点
- redis 当前没有进行RDB的子进程和AOF子进程
- dicAdd，向hash表中添加一个键值对
- dictReplace，向hash表中添加一个键值对，或者键值对存在时，修改键值对
- dictAddorFind：hash表添加或查找

### rehash 扩容
- `size` 是 初始化大小或者hash正在用的key的数量
- 用初始化大小`i`，不断 `i*=2`
- 直到 `i >= size`

### 渐进式rehash
- 目的，减少rehash迁移数据时，对主线程的阻塞，减轻rehash开销
- redis 并不会一次拷贝所有数据到新的位置，而是分批一部分迁移，每次只拷贝一个hash表中的一个bucket
- rahashidx 移动的bucket的编号，-1表示不需要rehash
- 如果hash正在进行rehash的话，添加和删除元素后会进行1个bucket的移动
- 如果hash正在进行rehash的话，查找也会导致1个bucket的移动
> key的hash算法是`siphash`
```c

/* Performs N steps of incremental rehashing. Returns 1 if there are still
 * keys to move from the old to the new hash table, otherwise 0 is returned.
 *
 * Note that a rehashing step consists in moving a bucket (that may have more
 * than one key as we use chaining) from the old to the new hash table, however
 * since part of the hash table may be composed of empty spaces, it is not
 * guaranteed that this function will rehash even a single bucket, since it
 * will visit at max N*10 empty buckets in total, otherwise the amount of
 * work it does would be unbound and the function may block for a long time. */

int dictRehash(dict *d, int n) {
    int empty_visits = n*10; // 最大rehash的bucket的数量
    if (!dictIsRehashing(d)) return 0;

    while(n-- && d->ht[0].used != 0) {
        dictEntry *de, *nextde;

        /* Note that rehashidx can't overflow as we are sure there are more
         * elements because ht[0].used != 0 */
        assert(d->ht[0].size > (unsigned long)d->rehashidx);
        while(d->ht[0].table[d->rehashidx] == NULL) { // 移动的bucket为空
            d->rehashidx++;
            if (--empty_visits == 0) return 1;
        }
        de = d->ht[0].table[d->rehashidx];
        /* Move all the keys in this bucket from the old to the new hash HT */
        while(de) {  // 每次移动一个bucket
            uint64_t h;

            nextde = de->next;
            /* Get the index in the new hash table */
            h = dictHashKey(d, de->key) & d->ht[1].sizemask;
            de->next = d->ht[1].table[h];
            d->ht[1].table[h] = de; // 移动过程
            d->ht[0].used--;
            d->ht[1].used++;
            de = nextde;
        }
        d->ht[0].table[d->rehashidx] = NULL;
        d->rehashidx++;
    }

    /* Check if we already rehashed the whole table... */
    // 都移动了，然后设置释放h0，h1赋值到h0，清空h1
    if (d->ht[0].used == 0) {
        zfree(d->ht[0].table);
        d->ht[0] = d->ht[1];
        _dictReset(&d->ht[1]);
        d->rehashidx = -1;
        return 0;
    }

    /* More to rehash... */
    return 1;
}
```