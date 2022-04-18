### Socket模型
- 提供阻塞 I/O 模型，只需在 Goroutine 中以最简单、最易用的“阻塞 I/O 模型”的方式，进行 Socket 操作
- 每个 Goroutine 处理一个 TCP 连接成为可能，并且在高并发下依旧表现出色
- 在运行时中实现了网络轮询器（netpoller)，netpoller 的作用，就是只阻塞执行网络 I/O 操作的 Goroutine，但不阻塞执行 Goroutine 的线程（也就是 M）
- Go 程序的用户层（相对于 Go 运行时层）来说，它眼中看到的 goroutine 采用了“阻塞 I/O 模型”进行网络 I/O 操作，Socket 都是“阻塞”的

### netpoller 网络轮询器
- I/O 多路复用机制
- 真实的底层操作系统 Socket，是非阻塞的
- 运行时拦截了针对底层 Socket 的系统调用返回的错误码，并通过 netpoller 和 Goroutine 调度，让 Goroutine“阻塞”在用户层所看到的 Socket 描述符上


### netpoller流程
- 用户层针对某个 Socket 描述符发起read操作时，如果这个 Socket 对应的连接上还没有数据，运行时将这个 Socket 描述符加入到 netpoller 中监听，同时发起此次读操作的 Goroutine 会被挂起
- Go 运行时收到 Socket 数据可读的通知，Go 运行时重新唤醒等待在这个 Socket 上准备读数据的 Goroutine
- 从 Goroutine 的视角来看，就像是 read 操作一直阻塞在 Socket 描述符上

### 不同系统io多路复用模型
- Linux epoll
- Windows iocp
- FreeBSD/MacOS kqueue
- Solaris event port

### socket 服务端监听（listen）与接收（Accept）
- 服务端程序通常采用一个 Goroutine 处理一个连接
```go
 func handleConn(c net.Conn) {
     defer c.Close()
     for {
         // read from the connection
         // ... ...
         // write to the connection
         //... ...
     }
 }
 
 func main() {
     l, err := net.Listen("tcp", ":8888")
     if err != nil {
         fmt.Println("listen error:", err)
         return
     }
 
     for {
         c, err := l.Accept()
         if err != nil {
             fmt.Println("accept error:", err)
             break
         }
         // start a new goroutine to handle
         // the new connection.
         go handleConn(c)
     }
 }
```

### socket客户端
```go
conn, err := net.Dial("tcp", "localhost:8888")
conn, err := net.DialTimeout("tcp", "localhost:8888", 2 * time.Second)
```

### socket 全双工通信
- 通信双方通过各自获得的 Socket，可以在向对方发送数据包的同时，接收来自对方的数据包
- 任何一方的操作系统，都会为已建立的连接分配一个发送缓冲区和一个接收缓冲区
- 客户端会通过成功连接服务端后得到的 conn（封装了底层的 socket）向服务端发送数据包
- 数据包会先进入到己方（客户端）的发送缓冲区中，之后，这些数据会被操作系统内核通过网络设备和链路，发到服务端的接收缓冲区中，服务端程序再通过代表客户端连接的 conn 读取服务端接收缓冲区中的数据

### socket 读操作
- Socket 中无数据，读操作阻塞
- Socket 中有部分数据，成功读出这部分数据，并返回，而不是等待期望长度数据全部读取后，再返回
- Socket 中有足够数据，读出read操作的数据，剩余数据分多次读取
- Socket 设置读超时，SetReadDeadline 方法接受一个绝对时间作为超时的 deadline，一旦通过这个方法设置了某个 socket 的 Read deadline，无论后续的 Read 操作是否超时，只要不重新设置 Deadline，后面与这个 socket 有关的所有读操作，都会返回超时失败错误
- 取消超时设置，可以使用 SetReadDeadline（time.Time{}）

### socket 写操作
- Write 调用的返回值 n 的值，与预期要写入的数据长度相等，且 err = nil 时，代表写入成功
- 写阻塞，发送方将对方的接收缓冲区，以及自身的发送缓冲区都写满后，再调用 Write 方法就会出现阻塞
- 写入部分数据
- 写入超时，SetWriteDeadline，如果出现超时，无论后续 Write 方法是否成功，如果不重新设置写超时或取消写超时，后续对 Socket 的写操作都将超时失败

### socket 并发读写
- 可以用，但是没必要
- 并发写，写入顺序会乱
- 并发读，读取的数据是一部分，业务处理逻辑复杂

### socket 关闭
#### 有数据关闭
- 有数据关闭”是指在客户端关闭连接（Socket）时，Socket 中还有服务端尚未读取的数据
- 服务端的 Read 会成功将剩余数据读取出来
- 最后一次 Read 操作将得到io.EOF错误码

#### 无数据关闭
- 服务端直接读到io.EOF
> 客户端关闭 Socket 后，如果服务端 Socket 尚未关闭，这个时候服务端向 Socket 的写入操作依然可能会成功，因为数据会成功写入己方的内核 socket 缓冲区中，即便最终发不到对方 socket 缓冲区
