### 并发&&并行
- 并发不是并行
- 并发是应用结构设计相关的概念，而并行只是程序执行期的概念
- 并行的必要条件是具有多个处理器或多核处理器，否则无论是否是并发的设计，程序执行时都有且仅有一个任务可以被调度到处理器上执行

### Go并发方案
- Go 的并发方案：goroutine
- Go 并没有使用操作系统线程作为承载分解后的代码片段（模块）的基本执行单元
- 实现了goroutine这一由 Go 运行时（runtime）负责调度的、轻量的用户级线程，为并发程序设计提供原生支持
- 无论是 Go 自身运行时代码还是用户层 Go 代码，都无一例外地运行在 goroutine 中

### goroutine优势
- 资源占用小，每个 goroutine 的初始栈大小仅为 2k
- 由 Go 运行时而不是操作系统调度，goroutine 上下文切换在用户层完成，开销更小
- 在语言层面而不是通过标准库提供。goroutine 由go关键字创建，一退出就会被回收或销毁，开发体验更佳
- 语言内置 channel 作为 goroutine 间通信原语，为并发设计提供了强大支撑

### goroutine使用
#### 创建goroutine
- Go 语言通过go关键字+函数/方法的方式创建一个 goroutine
- Go 也可以基于匿名函数 / 闭包创建 goroutine
- 创建 goroutine 后，go 关键字不会返回 goroutine id 之类的唯一标识 goroutine 的 id
- 一个应用内部启动的所有 goroutine 共享进程空间的资源，如果多个 goroutine 访问同一块内存数据，将会存在竞争，需要进行 goroutine 间的同步
- 创建后，新 goroutine 将拥有独立的代码执行流，并与创建它的 goroutine 一起被 Go 运行时调度

#### 退出goroutine
- goroutine 的执行函数的返回，就意味着 goroutine 退出，goroutine 执行的函数或方法即便有返回值，Go 也会忽略这些返回值，如果需要返回值，通过 goroutine 间的通信来实现
- main goroutine 退出，那么也意味着整个应用程序的退出，其他的goroutine也就都退出

#### goroutine间的通信
> 操作系统线程间的通信方式：共享内存、信号（signal）、管道（pipe）、消息队列、套接字（socket），基于对内存的共享的

- channel 符合`CSP（Communicationing Sequential Processes，通信顺序进程）`模型的通信方式，通过使用 channel 将goroutine组合在一起
- Go 也支持传统的、基于共享内存的并发模型，并提供了基本的低级别同步原语（主要是 sync 包中的互斥锁、条件变量、读写锁、原子操作等）