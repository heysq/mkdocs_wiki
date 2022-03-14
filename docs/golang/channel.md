### Channel
- 使用`make(chan eleType, cap)`创建
- 底层是`runtime.hchan`类型的指针

### 有缓冲channel和无缓冲channel
- 无缓冲
    - 发送数据的时候，如果没有对应的接收者ready，那么发送者就进入到等待发送队列中，等待有对应的接收者唤醒它
    - 接收数据的时候，如果没有对应的发送者ready，那么接收者就进入到等待接收队列中，等待有对应的发送者唤醒它
- 有缓冲
    - 对于发送者来说：只要缓冲区未满，发送者就可以继续发送数据存放在缓冲区。一旦缓冲区满了，发送者就只能进入到等待发送队列中，等待有对应的接收者唤醒它，然后它再把数据放入到刚刚被取走数据的位置

    - 对于接收者来说：只要缓冲区不为空，接收者就可以继续接收数据。一旦缓冲区空了，那么接收者就只能进入到等待接收队列中，等待有对应的发送者唤醒它

### 读取写入channel几种情况
#### 定义channel，但是不进行初始化
- `var ch chan string`定义的channel为 `nil channel` 导致 `fatal error`
```go
func main() {
	wg := sync.WaitGroup{}
	var ch chan string

	write := func() {
		fmt.Println("writing")
		s := "t"
		ch <- s
		fmt.Println("write:", s)
		wg.Done()
	}
	write()
}
// true
// writing
// fatal error: all goroutines are asleep - deadlock!
```

#### 定义channel，make初始化
- 正常读取，不会崩溃
- 读取如果处理不当会阻塞

```go
func main() {
	wg := sync.WaitGroup{}
	var ch chan string = make(chan string)

	read := func() {
		fmt.Println("reading")
		s := <-ch
		fmt.Println("read:", s)
		wg.Done()
	}

	write := func() {
		fmt.Println("writing")
		s := "t"
		ch <- s
		fmt.Println("write:", s)
		wg.Done()
	}

	wg.Add(2)
	go read()
	go write()

	fmt.Println("waiting")
	wg.Wait()

}
// waiting
// reading
// writing
// write: t
// read: t
```

#### 读取已经关闭的channel
- channel 关闭前正常读取
- channel 关闭后读取到chan元素类型的零值，并且第二个comma返回值返回false
```go
func main() {
	wg := sync.WaitGroup{}
	var ch = make(chan string, 5)

	read := func() {
		for {
			fmt.Println("reading")
			s, ok := <-ch
			fmt.Println("read:", len(s), s, ok)
			time.Sleep(time.Second)
		}
		wg.Done()
	}

	write := func() {
		for i := 0; i < 5; i++ {
			fmt.Println("writing")
			s := "t"
			ch <- s
			fmt.Println("write:", s)
		}
		wg.Done()
		close(ch)
		fmt.Println("closed")
	}

	wg.Add(2)
	write()
	go read()

	fmt.Println("waiting")
	wg.Wait()
	fmt.Println("finish")
}

//reading
//read: 1 t true
//reading
//read: 0  false
//reading
//read: 0  false
```

#### 写入已经关闭的channel
- panic: send on closed channel
```go
func main() {
	ch := make(chan string)
	close(ch)
	ch <- "1"
}
//panic: send on closed channel
```
### Channel 结构 hchan

```go
type hchan struct {
    // channel中当前元素个数
	qcount   uint           // total data in the queue
	// 队列容量
    dataqsiz uint           // size of the circular queue
	// 队列元素缓存区，数组指针
    buf      unsafe.Pointer // points to an array of dataqsiz elements
	// 每个元素大小
    elemsize uint16
	// channel是否关闭
    closed   uint32
	// 元素类型
    elemtype *_type // element type
	// 发送位置索引
    sendx    uint   // send index
	// 接收位置索引
    recvx    uint   // receive index
	// 等待接收阻塞的goroutine
    recvq    waitq  // list of recv waiters
	// 等待发送阻塞的goroutine
    sendq    waitq  // list of send waiters

	// lock protects all fields in hchan, as well as several
	// fields in sudogs blocked on this channel.
	//
	// Do not change another G's status while holding this lock
	// (in particular, do not ready a G), as this can deadlock
	// with stack shrinking.
	lock mutex
}
```

### runtime.makechan
- 必要的边界检查，内存溢出，容量为负数
- 如果创建一个无缓冲channel ，只需要为runtime.hchan本身分配一段内存空间
- 如果创建的缓冲channel存储的类型不是指针类型，会为当前channel和存储类型元素的缓冲区，分配一块连续的内存空间
- 默认情况下(缓冲channel存储类型包含指针)，会单独为runtime.hchan和缓冲区分配内存

```go
func makechan(t *chantype, size int) *hchan {
	elem := t.elem

    // compiler checks this but be safe.
	if elem.size >= 1<<16 {
		throw("makechan: invalid channel element type")
	}
	if hchanSize%maxAlign != 0 || elem.align > maxAlign {
		throw("makechan: bad alignment")
	}

	mem, overflow := math.MulUintptr(elem.size, uintptr(size))
	if overflow || mem > maxAlloc-hchanSize || size < 0 {
		panic(plainError("makechan: size out of range"))
	}


	// Hchan does not contain pointers interesting for GC when elements stored in buf do not contain pointers.
	// buf points into the same allocation, elemtype is persistent.
	// SudoG's are referenced from their owning thread so they can't be collected.
	// TODO(dvyukov,rlh): Rethink when collector can move allocated objects.
	var c *hchan
	switch {
	case mem == 0:
		// Queue or element size is zero.
        // 无缓冲队列或者元素占用大小为0
		c = (*hchan)(mallocgc(hchanSize, nil, true))
		// Race detector uses this location for synchronization.
		c.buf = c.raceaddr()
	case elem.ptrdata == 0:
		// Elements do not contain pointers.
		// Allocate hchan and buf in one call.
        // 存储的元素不包含指针，分配hchan和buf在一块内存区域
		c = (*hchan)(mallocgc(hchanSize+mem, nil, true))

        // maxAlign  = 8
	    // hchanSize = unsafe.Sizeof(hchan{}) + uintptr(-int(unsafe.Sizeof(hchan{}))&(maxAlign-1))
		c.buf = add(unsafe.Pointer(c), hchanSize)
	default:
		// Elements contain pointers.
        // 独立分配hchan和buff内存
		c = new(hchan)
		c.buf = mallocgc(mem, elem, true)
	}

	c.elemsize = uint16(elem.size)
	c.elemtype = elem
	c.dataqsiz = uint(size)
	lockInit(&c.lock, lockRankHchan)

	if debugChan {
		print("makechan: chan=", c, "; elemsize=", elem.size, "; dataqsiz=", size, "\n")
	}
	return c
}
```



### waitq && sudog
```go

type waitq struct {
	first *sudog
	last  *sudog
}

// sudog represents a g in a wait list, such as for sending/receiving
// on a channel.
//
// sudog is necessary because the g ↔ synchronization object relation
// is many-to-many. A g can be on many wait lists, so there may be
// many sudogs for one g; and many gs may be waiting on the same
// synchronization object, so there may be many sudogs for one object.
//
// sudogs are allocated from a special pool. Use acquireSudog and
// releaseSudog to allocate and free them.
type sudog struct {
	// The following fields are protected by the hchan.lock of the
	// channel this sudog is blocking on. shrinkstack depends on
	// this for sudogs involved in channel ops.

	g *g

	next *sudog
	prev *sudog
	elem unsafe.Pointer // data element (may point to stack)

	// The following fields are never accessed concurrently.
	// For channels, waitlink is only accessed by g.
	// For semaphores, all fields (including the ones above)
	// are only accessed when holding a semaRoot lock.

	acquiretime int64
	releasetime int64
	ticket      uint32

	// isSelect indicates g is participating in a select, so
	// g.selectDone must be CAS'd to win the wake-up race.
	isSelect bool

	// success indicates whether communication over channel c
	// succeeded. It is true if the goroutine was awoken because a
	// value was delivered over channel c, and false if awoken
	// because c was closed.
	success bool

	parent   *sudog // semaRoot binary tree
	waitlink *sudog // g.waiting list or semaRoot
	waittail *sudog // semaRoot
	c        *hchan // channel
}

```