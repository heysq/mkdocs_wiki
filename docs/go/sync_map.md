### sync Map 总结
- sync.map 是线程安全的，读取，插入，删除也都保持着常数级的时间复杂度
- 通过读写分离，降低锁时间来提高效率，适用于读多写少的场景
- Range 操作需要提供一个函数，参数是 k,v，返回值是一个布尔值：f func(key, value interface{}) bool
- 调用 Load 或 LoadOrStore 函数时，如果在 read 中没有找到 key，则会将 misses 值原子地增加 1，当 misses 增加到和 dirty 的长度相等时，会将 dirty 提升为 read，来减少读miss
- 新写入的 key 会保存到 dirty 中，如果这时 dirty 为 nil，就会先新创建一个 dirty，并将 read 中未被删除的元素拷贝到 dirty。
- 当 dirty 为 nil 的时候，read 就代表 map 所有的数据；当 dirty 不为 nil 的时候，dirty 才代表 map 所有的数据

### sync.Map结构
```go
type Map struct {
	mu Mutex

	// read contains the portion of the map's contents that are safe for
	// concurrent access (with or without mu held).
    // read里边存的是并发访问安全的（持不持有锁都是可以的）
	//
	// The read field itself is always safe to load, but must only be stored with
	// mu held.
	// load read里边内容总是安全的，但是当你想store进去的时候就必须加mutex 锁

	// Entries stored in read may be updated concurrently without mu, but updating
	// a previously-expunged entry requires that the entry be copied to the dirty
	// map and unexpunged with mu held.
    // 大致意思是更新已经删除的key需要加锁，然后把key放到dirty里边
	read atomic.Value // readOnly

	// dirty contains the portion of the map's contents that require mu to be
	// held. To ensure that the dirty map can be promoted to the read map quickly,
	// it also includes all of the non-expunged entries in the read map.
    // 为了快速提升dirty为read，dirty中存储了read中未删除的key
	//
	// Expunged entries are not stored in the dirty map. An expunged entry in the
	// clean map must be unexpunged and added to the dirty map before a new value
	// can be stored to it.
	//
	// If the dirty map is nil, the next write to the map will initialize it by
	// making a shallow copy of the clean map, omitting stale entries.
	dirty map[interface{}]*entry

	// misses counts the number of loads since the read map was last updated that
	// needed to lock mu to determine whether the key was present.
	//
    // 从read中读取不到key，miss就会加一，加到一定阈值，dirty将被提升为read
	// Once enough misses have occurred to cover the cost of copying the dirty
	// map, the dirty map will be promoted to the read map (in the unamended
	// state) and the next store to the map will make a new dirty copy.
	misses int
}

// readOnly is an immutable struct stored atomically in the Map.read field.
// 不可改变，原子性的存在map的read字段里
type readOnly struct {
	m       map[interface{}]*entry
	amended bool // true if the dirty map contains some key not in m.
}

// expunged is an arbitrary pointer that marks entries which have been deleted
// from the dirty map.
// 专用来标记 entry已经从dirty中删除
var expunged = unsafe.Pointer(new(interface{}))

// An entry is a slot in the map corresponding to a particular key.
// entry存放的就是一个指针，指向value的地址
type entry struct {
	// p points to the interface{} value stored for the entry.
	//
	// If p == nil, the entry has been deleted, and either m.dirty == nil or
	// m.dirty[key] is e.
    // 地址为nil，表明key已经被删除，要么map的dirty为空，要么dirty[key]是这个entry
	//
	// If p == expunged, the entry has been deleted, m.dirty != nil, and the entry
	// is missing from m.dirty.
    // 地址是expunged，就表示这个entry已经被删了，并且dirty也已经 不存这个值了
	//
	// Otherwise, the entry is valid and recorded in m.read.m[key] and, if m.dirty
	// != nil, in m.dirty[key].
    // 其他情况下，就是没有被删除，read[key]为这个p，然后如果dirty不为nil，则ditry[key]也为p
	//
	// An entry can be deleted by atomic replacement with nil: when m.dirty is
	// next created, it will atomically replace nil with expunged and leave
	// m.dirty[key] unset.
    // 当删除 key 时，并不实际删除。一个 entry 可以通过原子地（CAS 操作）设置 p 为 nil 被删除。
    // 如果之后创建 m.dirty，nil 又会被原子地设置为 expunged，且不会拷贝到 dirty 中。
	//
	// An entry's associated value can be updated by atomic replacement, provided
	// p != expunged. If p == expunged, an entry's associated value can be updated
	// only after first setting m.dirty[key] = e so that lookups using the dirty
	// map find the entry.
    // 如果 p 不为 expunged，和 entry 相关联的这个 value 可以被原子地更新；
    //如果 p == expunged，那么仅当它初次被设置到 m.dirty 之后，才可以被更新
	p unsafe.Pointer // *interface{}
}
```
> 引用知乎回答的一张图 https://zhuanlan.zhihu.com/p/344834329

![sync_map结构](http://image.heysq.com/wiki/go/sync_map.jpg)


### Load
- 读不到返回nil，和false
- 读到返回值和ok
- read map中不存在key，但是ditry map中有这个key，加锁防止dirty升级为map
- 加锁从 dirty中读取key，然后load函数会判断读取到的值是不是expunged(也就是被删除的情况)
- 标记miss，以便后续dirty升级为read
- miss的数量大于等于dirty的map的数量时，dirty升级为map

```go
func (m *Map) Load(key interface{}) (value interface{}, ok bool) {
	read, _ := m.read.Load().(readOnly)
	e, ok := read.m[key]
    // read map中不存在key，但是ditry map中有这个key，加锁防止dirty升级为map
    // 加锁从 dirty中读取key，然后load函数会判断读取到的值是不是expunged(也就是被删除的情况)
    // 标记miss，以便后续dirty升级为read
    // miss的数量大于等于dirty的map的数量时，dirty升级为map
	if !ok && read.amended {
		m.mu.Lock()
		// Avoid reporting a spurious miss if m.dirty got promoted while we were
		// blocked on m.mu. (If further loads of the same key will not miss, it's
		// not worth copying the dirty map for this key.)
		read, _ = m.read.Load().(readOnly)
		e, ok = read.m[key]
		if !ok && read.amended {
			e, ok = m.dirty[key]
			// Regardless of whether the entry was present, record a miss: this key
			// will take the slow path until the dirty map is promoted to the read
			// map.
			m.missLocked()
		}
		m.mu.Unlock()
	}
	if !ok {
		return nil, false
	}
	return e.load()
}

func (e *entry) load() (value interface{}, ok bool) {
	p := atomic.LoadPointer(&e.p)
    // key 被删除
	if p == nil || p == expunged {
		return nil, false
	}
	return *(*interface{})(p), true
}

func (m *Map) missLocked() {
	m.misses++
	if m.misses < len(m.dirty) {
		return
	}
	m.read.Store(readOnly{m: m.dirty})
	m.dirty = nil
	m.misses = 0
}
```

### Store
- 存储一个key到sync Map
- key存在更新
- 没读到已经存在read中的key要加锁进行存储

#### store 流程
- 如果在 read 里能够找到待存储的 key，并且对应的 entry 的 p 值不为 expunged，也就是没被删除时，直接更新对应的 entry
- 第一步没有成功：要么 read 中没有这个 key，要么 key 被标记为删除。则先加锁，再进行后续的操作。
- 再次在 read 中查找是否存在这个 key，也就是 double check 一下
- 如果 read 中存在该 key，但 p == expunged，说明 m.dirty != nil 并且 m.dirty 中不存在该 key 值 此时: a. 将 p 的状态由 expunged 更改为 nil；b. dirty map 插入 key。然后，直接更新对应的 value。
- 如果 read 中没有此 key，那就查看 dirty 中是否有此 key，如果有，则直接更新对应的 value，这时 read 中还是没有此 key
- 最后一步，如果 read 和 dirty 中都不存在该 key，则：a. 如果 dirty 为空，则需要创建 dirty，并从 read 中拷贝未被删除的元素；b. 更新 amended 字段，标识 dirty map 中存在 read map 中没有的 key；c. 将 k-v 写入 dirty map 中，read.m 不变。最后，更新此 key 对应的 value

```go
// Store sets the value for a key.
func (m *Map) Store(key, value interface{}) {
    // read 中可以读到这个key
	read, _ := m.read.Load().(readOnly)
	if e, ok := read.m[key]; ok && e.tryStore(&value) {
		return
	}

	m.mu.Lock()
	read, _ = m.read.Load().(readOnly)
	if e, ok := read.m[key]; ok {
		if e.unexpungeLocked() {
            // 过去被删除了，就将这个key存到dirty
			// The entry was previously expunged, which implies that there is a
			// non-nil dirty map and this entry is not in it.
			m.dirty[key] = e
		}
        // 原子存指针的值
		e.storeLocked(&value)  //dirty和read都可以读到新存进去的值
	} else if e, ok := m.dirty[key]; ok {
		e.storeLocked(&value) // dirty 中存在，就直接存储值
	} else {
        // 两边都没读到这个key
		if !read.amended {
			// We're adding the first new key to the dirty map.
			// Make sure it is allocated and mark the read-only map as incomplete.
			m.dirtyLocked() // 如果dirty为nil，就新建一个dirty，然后把read中没删除的key存到dirty
			m.read.Store(readOnly{m: read.m, amended: true}) // 标记dirtymap中有read中不存在的key
		}
		m.dirty[key] = newEntry(value) // 值存储到dirty，下次load可以取到
	}
	m.mu.Unlock()
}

// tryStore stores a value if the entry has not been expunged.
//
// If the entry is expunged, tryStore returns false and leaves the entry
// unchanged.
// 如果这个key已经被删除了，就返回了
// key 没被删除原子交换entry中p的值
func (e *entry) tryStore(i *interface{}) bool {
	for {
		p := atomic.LoadPointer(&e.p)
		if p == expunged {
			return false
		}
		if atomic.CompareAndSwapPointer(&e.p, p, unsafe.Pointer(i)) {
			return true
		}
	}
}

// 如果没有dirtymap的话新建一个，然后把read中没有删除的存到dirty
func (m *Map) dirtyLocked() {
	if m.dirty != nil {
		return
	}

	read, _ := m.read.Load().(readOnly)
	m.dirty = make(map[interface{}]*entry, len(read.m))
	for k, e := range read.m {
		if !e.tryExpungeLocked() {
			m.dirty[k] = e
		}
	}
}

// 不是nil，也不是expunged的，也就是正常值才会被放到dirty中
func (e *entry) tryExpungeLocked() (isExpunged bool) {
	p := atomic.LoadPointer(&e.p)
	for p == nil {
		if atomic.CompareAndSwapPointer(&e.p, nil, expunged) {
			return true
		}
		p = atomic.LoadPointer(&e.p)
	}
	return p == expunged
}

```






### LoadAndStore
```go
// LoadOrStore returns the existing value for the key if present.
// Otherwise, it stores and returns the given value.
// The loaded result is true if the value was loaded, false if stored.
func (m *Map) LoadOrStore(key, value interface{}) (actual interface{}, loaded bool) {
	// Avoid locking if it's a clean hit.
    // 正产查询
	read, _ := m.read.Load().(readOnly)
	if e, ok := read.m[key]; ok {
		actual, loaded, ok := e.tryLoadOrStore(value)
		if ok {
			return actual, loaded
		}
	}

	m.mu.Lock()
	read, _ = m.read.Load().(readOnly)
	if e, ok := read.m[key]; ok {
		if e.unexpungeLocked() {
            // e 为 nil，tryLoadOrStore 可以继续store，而不是直接return
			m.dirty[key] = e
		}
		actual, loaded, _ = e.tryLoadOrStore(value)
	} else if e, ok := m.dirty[key]; ok {
		actual, loaded, _ = e.tryLoadOrStore(value)
		m.missLocked()
	} else {
		if !read.amended {
			// We're adding the first new key to the dirty map.
			// Make sure it is allocated and mark the read-only map as incomplete.
			m.dirtyLocked()
			m.read.Store(readOnly{m: read.m, amended: true})
		}
		m.dirty[key] = newEntry(value)
		actual, loaded = value, false
	}
	m.mu.Unlock()

	return actual, loaded
}

// tryLoadOrStore atomically loads or stores a value if the entry is not
// expunged.
//
// If the entry is expunged, tryLoadOrStore leaves the entry unchanged and
// returns with ok==false.
func (e *entry) tryLoadOrStore(i interface{}) (actual interface{}, loaded, ok bool) {
	p := atomic.LoadPointer(&e.p)
	if p == expunged {
		return nil, false, false
	}
	if p != nil {
		return *(*interface{})(p), true, true
	}

	// Copy the interface after the first load to make this method more amenable
	// to escape analysis: if we hit the "load" path or the entry is expunged, we
	// shouldn't bother heap-allocating.
	ic := i
	for {
		if atomic.CompareAndSwapPointer(&e.p, nil, unsafe.Pointer(&ic)) {
			return i, false, true
		}
		p = atomic.LoadPointer(&e.p)
		if p == expunged {
			return nil, false, false
		}
		if p != nil {
			return *(*interface{})(p), true, true
		}
	}
}
```
### Delete && LoadAndDelete
- 查询数据的逻辑同Load
- 主要调用LoadAndDelete 方法
- 返回val，和一个bool

```go
// LoadAndDelete deletes the value for a key, returning the previous value if any.
// The loaded result reports whether the key was present.
func (m *Map) LoadAndDelete(key interface{}) (value interface{}, loaded bool) {
	read, _ := m.read.Load().(readOnly)
	e, ok := read.m[key]
	if !ok && read.amended {
		m.mu.Lock()
		read, _ = m.read.Load().(readOnly)
		e, ok = read.m[key]
		if !ok && read.amended {
			e, ok = m.dirty[key]
			delete(m.dirty, key)
			// Regardless of whether the entry was present, record a miss: this key
			// will take the slow path until the dirty map is promoted to the read
			// map.
			m.missLocked()
		}
		m.mu.Unlock()
	}
	if ok {
		return e.delete()
	}
	return nil, false
}

// 直接标记成nil
func (e *entry) delete() (value interface{}, ok bool) {
	for {
		p := atomic.LoadPointer(&e.p)
		if p == nil || p == expunged {
			return nil, false
		}
		if atomic.CompareAndSwapPointer(&e.p, p, nil) {
			return *(*interface{})(p), true
		}
	}
}
```

### Range
- 函数传参一个`func(key, value interface{}) bool`
- 函数返回false，结束循环
- 如果dirty中存在read中没有的key，加锁将dirty升级为read
- 然后循环遍历read

```go
/ Range calls f sequentially for each key and value present in the map.
// If f returns false, range stops the iteration.
//
// Range does not necessarily correspond to any consistent snapshot of the Map's
// contents: no key will be visited more than once, but if the value for any key
// is stored or deleted concurrently, Range may reflect any mapping for that key
// from any point during the Range call.
//
// Range may be O(N) with the number of elements in the map even if f returns
// false after a constant number of calls.
func (m *Map) Range(f func(key, value interface{}) bool) {
	// We need to be able to iterate over all of the keys that were already
	// present at the start of the call to Range.
	// If read.amended is false, then read.m satisfies that property without
	// requiring us to hold m.mu for a long time.
	read, _ := m.read.Load().(readOnly)
	if read.amended {
		// m.dirty contains keys not in read.m. Fortunately, Range is already O(N)
		// (assuming the caller does not break out early), so a call to Range
		// amortizes an entire copy of the map: we can promote the dirty copy
		// immediately!
		m.mu.Lock()
		read, _ = m.read.Load().(readOnly)
		if read.amended {
			read = readOnly{m: m.dirty}
			m.read.Store(read)
			m.dirty = nil
			m.misses = 0
		}
		m.mu.Unlock()
	}

	for k, e := range read.m {
		v, ok := e.load()
		if !ok {
			continue
		}
		if !f(k, v) {
			break
		}
	}
}

```