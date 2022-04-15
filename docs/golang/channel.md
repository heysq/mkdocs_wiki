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
- 阻塞模式读取或写入到chan，才会崩溃
- `select`中向`nil channel`写入或读取不会崩溃，因为select是非阻塞模式
    ```go
    // select 发送
    func selectnbsend(c *hchan, elem unsafe.Pointer) (selected bool) {
        return chansend(c, elem, false, getcallerpc())
    }

    // select 接收  
    func selectnbrecv(elem unsafe.Pointer, c *hchan) (selected, received bool) {
        return chanrecv(c, elem, false)
    }

    func chansend(c *hchan, ep unsafe.Pointer, block bool, callerpc uintptr) bool {
        // nilchannel 非阻塞写入不会崩溃
        if c == nil {
            if !block {
                return false
            }
            gopark(nil, nil, waitReasonChanSendNilChan, traceEvGoStop, 2)
            throw("unreachable")
        }

        if debugChan {
            print("chansend: chan=", c, "\n")
        }
        // ...省略代码
    }

    func chanrecv(c *hchan, ep unsafe.Pointer, block bool) (selected, received bool) {
        // raceenabled: don't need to check ep, as it is always on the stack
        // or is new memory allocated by reflect.

        if debugChan {
            print("chanrecv: chan=", c, "\n")
        }

        if c == nil {
            if !block {
                return
            }
            gopark(nil, nil, waitReasonChanReceiveNilChan, traceEvGoStop, 2)
            throw("unreachable")
        }
        // ...省略代码
    }
    ```
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
### 向channel发送数据 runtime.chansend
- c channel对象的指针
- ep 具体要发送的元素
- block true阻塞模式，false 非阻塞模式
- callerpc 调用者的调用者的程序计数器 (PC)

```go
func full(c *hchan) bool {
	// c.dataqsiz is immutable (never written after the channel is created)
	// so it is safe to read at any time during channel operation.
    // 创建之后就不会边，0是一个无缓冲channel
    // 没有接收的，返回true
	if c.dataqsiz == 0 {
		// Assumes that a pointer read is relaxed-atomic.
		return c.recvq.first == nil
	}
	// Assumes that a uint read is relaxed-atomic.
    // 有缓冲channel
	return c.qcount == c.dataqsiz
}

func chansend(c *hchan, ep unsafe.Pointer, block bool, callerpc uintptr) bool {
    // nil channel 判断
    // 阻塞模式,阻塞goroutine，然后崩溃
    // 非阻塞模式 比如select case情况下，返回false
    if c == nil {
		if !block {
			return false
		}
		gopark(nil, nil, waitReasonChanSendNilChan, traceEvGoStop, 2)
		throw("unreachable")
	}

    // 调试日志
	if debugChan {
		print("chansend: chan=", c, "\n")
	}

    // go build -race 才会用到
	if raceenabled {
		racereadpc(c.raceaddr(), callerpc, funcPC(chansend))
	}

    // 非阻塞模式，然后channel没有关闭，并且channel满的情况下返回false
	if !block && c.closed == 0 && full(c) {
		return false
	}

	var t0 int64
	if blockprofilerate > 0 {
		t0 = cputicks()
	}

    // 上锁
	lock(&c.lock)

    // 关闭的channel 报错
	if c.closed != 0 {
		unlock(&c.lock)
		panic(plainError("send on closed channel"))
	}

    // 取出第一个接收者，
	if sg := c.recvq.dequeue(); sg != nil {
		// Found a waiting receiver. We pass the value we want to send
		// directly to the receiver, bypassing the channel buffer (if any).
		send(c, sg, ep, func() { unlock(&c.lock) }, 3)
		return true
	}

    // 有缓冲通道
	if c.qcount < c.dataqsiz {
		// Space is available in the channel buffer. Enqueue the element to send.
		qp := chanbuf(c, c.sendx)
		if raceenabled {
			racenotify(c, c.sendx, nil)
		}
		typedmemmove(c.elemtype, qp, ep)
		c.sendx++
        // 循环写入
		if c.sendx == c.dataqsiz {
			c.sendx = 0
		}
		c.qcount++
		unlock(&c.lock)
		return true
	}

    // 无缓冲channel select 也不会阻塞
	if !block {
		unlock(&c.lock)
		return false
	}
    // 当前发送的g，封装成sudog
	// Block on the channel. Some receiver will complete our operation for us.
	gp := getg()
	mysg := acquireSudog()
	mysg.releasetime = 0
	if t0 != 0 {
		mysg.releasetime = -1
	}
	// No stack splits between assigning elem and enqueuing mysg
	// on gp.waiting where copystack can find it.
	mysg.elem = ep
	mysg.waitlink = nil
	mysg.g = gp
	mysg.isSelect = false
	mysg.c = c
	gp.waiting = mysg
	gp.param = nil
    
    //  sudog入队
	c.sendq.enqueue(mysg)
	// Signal to anyone trying to shrink our stack that we're about
	// to park on a channel. The window between when this G's status
	// changes and when we set gp.activeStackChans is not safe for
	// stack shrinking.

    // 原子标记goroutine 因为chansend 或者chanrecv阻塞
	atomic.Store8(&gp.parkingOnChan, 1)

    // 挂起当前G
	gopark(chanparkcommit, unsafe.Pointer(&c.lock), waitReasonChanSend, traceEvGoBlockSend, 2)
	// Ensure the value being sent is kept alive until the
	// receiver copies it out. The sudog has a pointer to the
	// stack object, but sudogs aren't considered as roots of the
	// stack tracer.

    // 保持当前ep 不会被GC回收，也就是发送的元素不会被回收
	KeepAlive(ep)

	// someone woke us up.
    // 被唤醒后才会使用
	if mysg != gp.waiting {
		throw("G waiting list is corrupted")
	}
	gp.waiting = nil
	gp.activeStackChans = false
	closed := !mysg.success
	gp.param = nil
	if mysg.releasetime > 0 {
		blockevent(mysg.releasetime-t0, 2)
	}
	mysg.c = nil
	releaseSudog(mysg)
	if closed {
		if c.closed == 0 {
			throw("chansend: spurious wakeup")
		}
        // 关闭的channel 写入 panic
		panic(plainError("send on closed channel"))
	}
	return true
}
```




### 从channel接收数据 runtime.chanrecv
- c 读取的channel
- ep 要读取出的内容存的地址
- block 阻塞模式
- nil channel 非阻塞模式不会报错，会读不到return，阻塞模式读nil channel 崩溃
- 非阻塞模式读取关闭的channel
```go

// empty reports whether a read from c would block (that is, the channel is
// empty).  It uses a single atomic read of mutable state.
func empty(c *hchan) bool {
	// c.dataqsiz is immutable.
	if c.dataqsiz == 0 {
		return atomic.Loadp(unsafe.Pointer(&c.sendq.first)) == nil
	}
	return atomic.Loaduint(&c.qcount) == 0
}

// chanrecv receives on channel c and writes the received data to ep.
// ep may be nil, in which case received data is ignored.
// If block == false and no elements are available, returns (false, false).
// Otherwise, if c is closed, zeros *ep and returns (true, false).
// Otherwise, fills in *ep with an element and returns (true, true).
// A non-nil ep must point to the heap or the caller's stack.
func chanrecv(c *hchan, ep unsafe.Pointer, block bool) (selected, received bool) {
	// raceenabled: don't need to check ep, as it is always on the stack
	// or is new memory allocated by reflect.

	if debugChan {
		print("chanrecv: chan=", c, "\n")
	}
    // nil channel 判断
	if c == nil {
		if !block {
			return
		}
		gopark(nil, nil, waitReasonChanReceiveNilChan, traceEvGoStop, 2)
		throw("unreachable")
	}

	// Fast path: check for failed non-blocking operation without acquiring the lock.
	if !block && empty(c) {
		// After observing that the channel is not ready for receiving, we observe whether the
		// channel is closed.
		//
		// Reordering of these checks could lead to incorrect behavior when racing with a close.
		// For example, if the channel was open and not empty, was closed, and then drained,
		// reordered reads could incorrectly indicate "open and empty". To prevent reordering,
		// we use atomic loads for both checks, and rely on emptying and closing to happen in
		// separate critical sections under the same lock.  This assumption fails when closing
		// an unbuffered channel with a blocked send, but that is an error condition anyway.
		if atomic.Load(&c.closed) == 0 {
			// Because a channel cannot be reopened, the later observation of the channel
			// being not closed implies that it was also not closed at the moment of the
			// first observation. We behave as if we observed the channel at that moment
			// and report that the receive cannot proceed.
			return
		}
		// The channel is irreversibly closed. Re-check whether the channel has any pending data
		// to receive, which could have arrived between the empty and closed checks above.
		// Sequential consistency is also required here, when racing with such a send.
		if empty(c) {
			// The channel is irreversibly closed and empty.
			if raceenabled {
				raceacquire(c.raceaddr())
			}
            // value := <- ch 读取方式
			if ep != nil {
				typedmemclr(c.elemtype, ep)
			}
			return true, false
		}
	}

	var t0 int64
	if blockprofilerate > 0 {
		t0 = cputicks()
	}

	lock(&c.lock)

    // value := <- ch 读取方式
    // channel 已经关闭，没有未读出的元素
	if c.closed != 0 && c.qcount == 0 {
		if raceenabled {
			raceacquire(c.raceaddr())
		}
		unlock(&c.lock)
		if ep != nil {
			typedmemclr(c.elemtype, ep)
		}
		return true, false
	}

    // 有阻塞的send goroutine
	if sg := c.sendq.dequeue(); sg != nil {
		// Found a waiting sender. If buffer is size 0, receive value
		// directly from sender. Otherwise, receive from head of queue
		// and add sender's value to the tail of the queue (both map to
		// the same buffer slot because the queue is full).
		recv(c, sg, ep, func() { unlock(&c.lock) }, 3)
		return true, true
	}

    // 有缓冲
	if c.qcount > 0 {
		// Receive directly from queue
		qp := chanbuf(c, c.recvx)
		if raceenabled {
			racenotify(c, c.recvx, nil)
		}
		if ep != nil {
			typedmemmove(c.elemtype, ep, qp)
		}
		typedmemclr(c.elemtype, qp)
		c.recvx++
		if c.recvx == c.dataqsiz {
			c.recvx = 0
		}
		c.qcount--
		unlock(&c.lock)
		return true, true
	}

	if !block {
		unlock(&c.lock)
		return false, false
	}

    // 阻塞情况下封装G，存到recvq
	// no sender available: block on this channel.
	gp := getg()
	mysg := acquireSudog()
	mysg.releasetime = 0
	if t0 != 0 {
		mysg.releasetime = -1
	}
	// No stack splits between assigning elem and enqueuing mysg
	// on gp.waiting where copystack can find it.
	mysg.elem = ep
	mysg.waitlink = nil
	gp.waiting = mysg
	mysg.g = gp
	mysg.isSelect = false
	mysg.c = c
	gp.param = nil
	c.recvq.enqueue(mysg)
	// Signal to anyone trying to shrink our stack that we're about
	// to park on a channel. The window between when this G's status
	// changes and when we set gp.activeStackChans is not safe for
	// stack shrinking.
	atomic.Store8(&gp.parkingOnChan, 1)
    
    //挂起goroutine
	gopark(chanparkcommit, unsafe.Pointer(&c.lock), waitReasonChanReceive, traceEvGoBlockRecv, 2)

	// someone woke us up
	if mysg != gp.waiting {
		throw("G waiting list is corrupted")
	}
	gp.waiting = nil
	gp.activeStackChans = false
	if mysg.releasetime > 0 {
		blockevent(mysg.releasetime-t0, 2)
	}
	success := mysg.success
	gp.param = nil
	mysg.c = nil
	releaseSudog(mysg)
	return true, success
}
```

### 有缓存channel用做计数器，用作计数信号量（counting semaphore），可以用来控制活动goroutine数量
```go

var active = make(chan struct{}, 3)
var jobs = make(chan int, 10)

func main() {
    go func() {
        for i := 0; i < 8; i++ {
            jobs <- (i + 1)
        }
        close(jobs)
    }()

    var wg sync.WaitGroup

    for j := range jobs {
        wg.Add(1)
        go func(j int) {
            active <- struct{}{}
            log.Printf("handle job: %d\n", j)
            time.Sleep(2 * time.Second)
            <-active
            wg.Done()
        }(j)
    }
    wg.Wait()
}
```

### nil channel配合 select使用 才不会崩溃
- channel 关闭后读取会读取到零值
- 用select可以将关闭后的channel变成nil channel，而不是每次都读到零值
```go
func main() {
    ch1, ch2 := make(chan int), make(chan int)
    go func() {
        time.Sleep(time.Second * 5)
        ch1 <- 5
        close(ch1)
    }()

    go func() {
        time.Sleep(time.Second * 7)
        ch2 <- 7
        close(ch2)
    }()

    for {
        select {
        case x, ok := <-ch1:
            if !ok {
                ch1 = nil
            } else {
                fmt.Println(x)
            }
        case x, ok := <-ch2:
            if !ok {
                ch2 = nil
            } else {
                fmt.Println(x)
            }
        }
        if ch1 == nil && ch2 == nil {
            break
        }
    }
    fmt.Println("program end")
}
```