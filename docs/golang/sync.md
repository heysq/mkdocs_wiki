### sync 包低级同步原语使用场景
- 高性能的临界区（critical section）同步机制场景
- 不想转移结构体对象所有权，但又要保证结构体内部状态数据的同步访问的场景

### sync包原语使用注意事项
- 不要将原语复制后使用
- 用闭包或者传递原语变量的地址（指针）

### mutex 互斥锁
- 零值可用，不用初始化
- Lock，Unlock
- lock状态下任何goroutine加锁都会阻塞

### RWMutex 读写锁
- 零值可用，不用初始化
- RLock，RUnlock 加读锁，解读锁
- Lock，Unlock 加写锁，解写锁
- 加读锁状态下，不会阻塞加读锁，会阻塞加写锁
- 加写锁状态下，会阻塞加读锁与写锁的goroutine

### sync.Cond 条件变量
- sync.Cond是传统的条件变量原语概念在 Go 语言中的实现
- 可以把一个条件变量理解为一个容器，这个容器中存放着一个或一组等待着某个条件成立的 Goroutine
- 当条件成立后，处于等待状态的 Goroutine 将得到通知，并被唤醒继续进行后续的工作
```go
type signal struct{}

var ready bool

func worker(i int) {
  fmt.Printf("worker %d: is working...\n", i)
  time.Sleep(1 * time.Second)
  fmt.Printf("worker %d: works done\n", i)
}

func spawnGroup(f func(i int), num int, groupSignal *sync.Cond) <-chan signal {
  c := make(chan signal)
  var wg sync.WaitGroup

  for i := 0; i < num; i++ {
    wg.Add(1)
    go func(i int) {
      groupSignal.L.Lock()
      for !ready {
        groupSignal.Wait()
      }
      groupSignal.L.Unlock()
      fmt.Printf("worker %d: start to work...\n", i)
      f(i)
      wg.Done()
    }(i + 1)
  }

  go func() {
    wg.Wait()
    c <- signal(struct{}{})
  }()
  return c
}

func main() {
  fmt.Println("start a group of workers...")
  groupSignal := sync.NewCond(&sync.Mutex{})
  c := spawnGroup(worker, 5, groupSignal)

  time.Sleep(5 * time.Second) // 模拟ready前的准备工作
  fmt.Println("the group of workers start to work...")

  groupSignal.L.Lock()
  ready = true
  groupSignal.Broadcast()
  groupSignal.L.Unlock()

  <-c
  fmt.Println("the group of workers work done!")
}
```