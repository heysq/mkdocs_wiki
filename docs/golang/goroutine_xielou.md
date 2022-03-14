### 泄漏的大多数原因
- Goroutine 内正在进行 channel/mutex 等读写操作，但由于逻辑问题，某些情况下会被一直阻塞。
- Goroutine 内的业务逻辑进入死循环，资源一直无法释放。
- Goroutine 内的业务逻辑进入长时间等待，有不断新增的 Goroutine 进入等待

#### channel发送不接收
- 开启多个goroutine，写channel
- 只读了部分的channel，导致goroutine阻塞不会释放
```go
package main

func main() {
    for i := 0; i < 4; i++ {
        queryAll()
        fmt.Printf("goroutines: %d\n", runtime.NumGoroutine())
    }
}

func queryAll() int {
    ch := make(chan int)
    for i := 0; i < 3; i++ {
        go func() { ch <- query() }()
    }
    // 开启多个channel，只接收了一个
    return <-ch
}

func query() int {
    n := rand.Intn(100)
    time.Sleep(time.Duration(n) * time.Millisecond)
    return n
}
```

#### channel接收不发送
- 只开启了接收，但是没有goroutine去发送数据到channel
```go
func main() {
    defer func() {
        fmt.Println("goroutines: ", runtime.NumGoroutine())
    }()

    var ch chan struct{}
    go func() {
        ch <- struct{}{}
    }()
    
    time.Sleep(time.Second)
}
```

#### nil channel 读写都会阻塞goroutine
```go
ch := make(chan int)
go func() {
    <-ch
}()
ch <- 0
time.Sleep(time.Second)
```

#### 请求三方接口没有设置超时等待
```go
func main() {
    for {
        go func() {
            _, err := http.Get("https://www.xxx.com/")
            if err != nil {
                fmt.Printf("http.Get err: %v\n", err)
            }
            // do something...
    }()

    time.Sleep(time.Second * 1)
    fmt.Println("goroutines: ", runtime.NumGoroutine())
    }
}
```

#### 互斥锁忘记解锁
- 互斥锁上锁后，忘记解锁
- 造成其他goroutine锁等待，进而产生资源泄漏
- `defer lock.Unlock()`

#### 同步锁使用不当
- sync.WaitGroup
- `Add`的数量和`Done`的数量不一致
- `Wait`方法一直阻塞 