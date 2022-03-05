### Map 常用操作
#### 初始化
- var m1 map[string]int // m1 == nil 结果为true，此时写入会产生panic
- var m2 = map[string]int{}
- var m3 = make(map[string]int) 
- makmap_small 源码
```go
// makemap_small implements Go map creation for make(map[k]v) and
// make(map[k]v, hint) when hint is known to be at most bucketCnt
// at compile time and the map needs to be allocated on the heap.
// 创建map不指定容量，或者容量小于bucketCnt（这个容量为8）
func makemap_small() *hmap {
	h := new(hmap)
	h.hash0 = fastrand()
	return h
}

```
- makemap 源码
```go
// makemap implements Go map creation for make(map[k]v, hint).
// If the compiler has determined that the map or the first bucket
// can be created on the stack, h and/or bucket may be non-nil.
// If h != nil, the map can be created directly in h.
// If h.buckets != nil, bucket pointed to can be used as the first bucket.
func makemap(t *maptype, hint int, h *hmap) *hmap {
	mem, overflow := math.MulUintptr(uintptr(hint), t.bucket.size)
	// 数据范围溢出，设置为0
	if overflow || mem > maxAlloc {
		hint = 0
	}

	// initialize Hmap
	if h == nil {
		h = new(hmap)
	}
	// 随机种子
	h.hash0 = fastrand()

	// Find the size parameter B which will hold the requested # of elements.
	// For hint < 0 overLoadFactor returns false since hint < bucketCnt.
	B := uint8(0)
	for overLoadFactor(hint, B) {
		B++
	}
	h.B = B

	// allocate initial hash table
	// if B == 0, the buckets field is allocated lazily later (in mapassign)
	// If hint is large zeroing this memory could take a while.
	if h.B != 0 {
		var nextOverflow *bmap
		h.buckets, nextOverflow = makeBucketArray(t, h.B, nil)
		if nextOverflow != nil {
			h.extra = new(mapextra)
			h.extra.nextOverflow = nextOverflow
		}
	}

	return h
}


```

#### 写map
- key, value 写入
- mapassign源码
```go
// Like mapaccess, but allocates a slot for the key if it is not present in the map.
func mapassign(t *maptype, h *hmap, key unsafe.Pointer) unsafe.Pointer {
	if h == nil {
		panic(plainError("assignment to entry in nil map"))
	}
	if raceenabled {
		callerpc := getcallerpc()
		pc := funcPC(mapassign)
		racewritepc(unsafe.Pointer(h), callerpc, pc)
		raceReadObjectPC(t.key, key, callerpc, pc)
	}
	if msanenabled {
		msanread(key, t.key.size)
	}
	// hashWriting = 4 固定值 二进制 0000 0100
	if h.flags&hashWriting != 0 {
		throw("concurrent map writes")
	}
	hash := t.hasher(key, uintptr(h.hash0))


	// Set hashWriting after calling t.hasher, since t.hasher may panic,
	// in which case we have not actually done a write.
	// map真正写入前设置标记位，其他goroutine写入会马上 throw("concurrent map writes")
	// 异或操作，相同为0，不同为1，修改第三位为1，保留其他位为原值，再次进行与操作时，等于1，然后就会崩溃
	h.flags ^= hashWriting

	if h.buckets == nil {
		h.buckets = newobject(t.bucket) // newarray(t.bucket, 1)
	}

// 省略部分代码
```

#### 读map
- value := hash[key]
- value, ok := hash[key]
- 如果key不存在，返回value类型的零值
- mapaccess 源码
```go
// mapaccess1 returns a pointer to h[key].  Never returns nil, instead
// it will return a reference to the zero object for the elem type if
// the key is not in the map.
// NOTE: The returned pointer may keep the whole map live, so don't
// hold onto it for very long.

// key不存在返回类型的零值
// 不要持有返回的指针太长时间，容易造成GC无法回收map，导致内存泄漏
func mapaccess1(t *maptype, h *hmap, key unsafe.Pointer) unsafe.Pointer {
	if raceenabled && h != nil {
		callerpc := getcallerpc()
		pc := funcPC(mapaccess1)
		racereadpc(unsafe.Pointer(h), callerpc, pc)
		raceReadObjectPC(t.key, key, callerpc, pc)
	}
	if msanenabled && h != nil {
		msanread(key, t.key.size)
	}
	// map 为空
	if h == nil || h.count == 0 {
		if t.hashMightPanic() {
			t.hasher(key, 0) // see issue 23734
		}
		return unsafe.Pointer(&zeroVal[0])
	}
	// 有正在写的goroutine，崩溃fatal error
	if h.flags&hashWriting != 0 {
		throw("concurrent map read and map write")
	}
	hash := t.hasher(key, uintptr(h.hash0)) // 根据key计算的hash值
	m := bucketMask(h.B) // 桶的个数

	// 指针计算，找到key应该在的bmap
	b := (*bmap)(add(h.buckets, (hash&m)*uintptr(t.bucketsize)))

	// 桶正在扩容
	if c := h.oldbuckets; c != nil {
		if !h.sameSizeGrow() {
			// There used to be half as many buckets; mask down one more power of two.
			m >>= 1
		}
		oldb := (*bmap)(add(c, (hash&m)*uintptr(t.bucketsize)))
		if !evacuated(oldb) {
			b = oldb
		}
	}
	
	top := tophash(hash)
	// 遍历bucket
bucketloop:
	for ; b != nil; b = b.overflow(t) {
		for i := uintptr(0); i < bucketCnt; i++ {
			if b.tophash[i] != top {
				if b.tophash[i] == emptyRest {
					break bucketloop
				}
				continue
			}
			k := add(unsafe.Pointer(b), dataOffset+i*uintptr(t.keysize))
			if t.indirectkey() {
				k = *((*unsafe.Pointer)(k))
			}
			if t.key.equal(key, k) {
				e := add(unsafe.Pointer(b), dataOffset+bucketCnt*uintptr(t.keysize)+i*uintptr(t.elemsize))
				if t.indirectelem() {
					e = *((*unsafe.Pointer)(e))
				}
				return e
			}
		}
	}
	// 没有的话 返回零值
	return unsafe.Pointer(&zeroVal[0])
}

```

### 特性
- map是个指针，底层指向hmap，所以是个引用类型
- golang slice、map、channel都是引用类型，当引用类型作为函数参数时，可能会修改原内容数据
- golang 中没有引用传递，只有值和指针传递。map 作为函数实参传递时本质上也是值传递，因为 map 底层数据结构是通过指针指向实际的元素存储空间，在被调函数中修改 map，对调用者同样可见，所以 map 作为函数实参传递时表现出了引用传递的效果。
- map 底层数据结构是通过指针指向实际的元素存储空间，对其中一个map的更改，会影响到其他map
- 遍历无序

### Map 实现原理
- Go中的map是一个指针，占用8个字节，指向hmap结构体; 源码src/runtime/map.go中可以看到map的底层结构
- 每个map的底层结构是hmap，hmap包含若干个结构为bmap的bucket数组。每个bucket底层都采用链表结构
- map 结构
```golang
作者：Go程序员
链接：https://www.zhihu.com/question/414084056/answer/2321836599
来源：知乎
著作权归作者所有。商业转载请联系作者获得授权，非商业转载请注明出处。

// A header for a Go map.
type hmap struct {
    count     int 
    // 代表哈希表中的元素个数，调用len(map)时，返回的就是该字段值。
    flags     uint8 
    // 状态标志，下文常量中会解释四种状态位含义。
    B         uint8  
    // buckets（桶）的对数log_2
    // 如果B=5，则buckets数组的长度 = 2^5=32，意味着有32个桶
    noverflow uint16 
    // 溢出桶的大概数量
    hash0     uint32 
    // 哈希种子

    buckets    unsafe.Pointer 
    // 指向buckets数组的指针，数组大小为2^B，如果元素个数为0，它为nil。
    oldbuckets unsafe.Pointer 
    // 如果发生扩容，oldbuckets是指向老的buckets数组的指针，
    // 老的buckets数组大小是新的buckets的1/2;非扩容状态下，它为nil。
    nevacuate  uintptr        
    // 表示扩容进度，小于此地址的buckets代表已搬迁完成。

    extra *mapextra 
    // 这个字段是为了优化GC扫描而设计的。当key和value均不包含指针
    // 并且都可以inline时使用。extra是指向mapextra类型的指针。
 }
```
- bmap结构
```go
bucketCntBits = 3
bucketCnt     = 1 << bucketCntBits

// A bucket for a Go map.
type bmap struct {
	// tophash generally contains the top byte of the hash value
	// for each key in this bucket. If tophash[0] < minTopHash,
	// tophash[0] is a bucket evacuation state instead.
	tophash [bucketCnt]uint8
	// Followed by bucketCnt keys and then bucketCnt elems.
	// NOTE: packing all the keys together and then all the elems together makes the
	// code a bit more complicated than alternating key/elem/key/elem/... but it allows
	// us to eliminate padding which would be needed for, e.g., map[int64]int8.
	// Followed by an overflow pointer.
    
    // len为8的数组
    // 用来快速定位key是否在这个bmap中
    // 桶的槽位数组，一个桶最多8个槽位，如果key所在的槽位在tophash中，则代表该key在这个桶中
    // key 单独放在一起，value单独放在一起，相同的类型放在一起，减少空间浪费，
}


```
- mapextra结构
```go
// mapextra holds fields that are not present on all maps.
// 字面理解附加字段
type mapextra struct {
	// If both key and elem do not contain pointers and are inline, then we mark bucket
	// type as containing no pointers. This avoids scanning such maps.
	// However, bmap.overflow is a pointer. In order to keep overflow buckets
	// alive, we store pointers to all overflow buckets in hmap.extra.overflow and hmap.extra.oldoverflow.
	// overflow and oldoverflow are only used if key and elem do not contain pointers.
	// overflow contains overflow buckets for hmap.buckets.
	// oldoverflow contains overflow buckets for hmap.oldbuckets.
	// The indirection allows to store a pointer to the slice in hiter.

    // 如果 key 和 value 都不包含指针，并且可以被 inline(<=128 字节)
    // 就使用 hmap的extra字段 来存储 overflow buckets，这样可以避免 GC 扫描整个 map
    // 然而 bmap.overflow 也是个指针。这时候我们只能把这些 overflow 的指针
    // 都放在 hmap.extra.overflow 和 hmap.extra.oldoverflow 中了
    // overflow 包含的是 hmap.buckets 的 overflow 的 buckets
    // oldoverflow 包含扩容时的 hmap.oldbuckets 的 overflow 的 bucket

	overflow    *[]*bmap
	oldoverflow *[]*bmap

	// nextOverflow holds a pointer to a free overflow bucket.
	nextOverflow *bmap
}

```


### 为什么遍历map无序？
- range map，初始化时调用`fastrand()`随机一个数字，决定本次range的起始点
```go
// mapiterinit initializes the hiter struct used for ranging over maps.
// The hiter struct pointed to by 'it' is allocated on the stack
// by the compilers order pass or on the heap by reflect_mapiterinit.
// Both need to have zeroed hiter since the struct contains pointers.
func mapiterinit(t *maptype, h *hmap, it *hiter) {
	// 省略一部分

	// decide where to start
    // 开始迭代时会有一个随机数，决定起始位置
	r := uintptr(fastrand())
	if h.B > 31-bucketCntBits {
		r += uintptr(fastrand()) << 31
	}
	it.startBucket = r & bucketMask(h.B)
	it.offset = uint8(r >> h.B & (bucketCnt - 1))

	// iterator state
	it.bucket = it.startBucket

	// Remember we have an iterator.
	// Can run concurrently with another mapiterinit().
	if old := h.flags; old&(iterator|oldIterator) != iterator|oldIterator {
		atomic.Or8(&h.flags, iterator|oldIterator)
	}

	mapiternext(it)
}


```

### 怎么有序遍历map
- 先取出map的key
- 对key进行排序
- 循环排序后的key，实现有序遍历map

### 为什么map非线程安全
- 并发访问需要控制锁相关，防止出现资源竞争
- 大部分不需要从多个goroutine同时读写map，加锁反而造成性能降低

```go
func mapiternext(it *hiter) {
	h := it.h
	if raceenabled {
		callerpc := getcallerpc()
		racereadpc(unsafe.Pointer(h), callerpc, funcPC(mapiternext))
	}
	if h.flags&hashWriting != 0 {
        // 直接抛出异常，fatal error
		throw("concurrent map iteration and map write")
	}
	t := it.t
	bucket := it.bucket
	b := it.bptr
	i := it.i
	checkBucket := it.checkBucket
    // 省略部分代码
}
```

### 线程安全的map怎么实现
- 使用读写锁 `map` + `sync.RWMutex`
- [sync.Map](sync_map.md)
### map扩容策略

