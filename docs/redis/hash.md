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