[Go：g0，特殊的 Goroutine](https://zhuanlan.zhihu.com/p/213745994)
### 创建P
- P 的初始化：首先会创建逻辑 CPU 核数个 P ，存储在 sched 的 空闲链表(pidle)。
![image](https://user-images.githubusercontent.com/39154923/127602696-7a68c508-2e07-43e8-b688-59346dc5b049.png)

### 创建os thread
- 准备运行的新 goroutine 将唤醒 P 以更好地分发工作。这个 P 将创建一个与之关联的 M 绑定到一个OS thread
- go func() 中 触发 Wakeup 唤醒机制，有空闲的 Processor 而没有在 spinning 状态的 Machine 时候, 需要去唤醒一个空闲(睡眠)的 M 或者新建一个。spinning就是自选状态，没有任务处理，自旋一段时间后进入睡眠状态等待下次被唤醒

### 创建M0 main
- 程序启动后，Go 已经将主线程和 M 绑定(rt0_go)
- 当 goroutine 创建完后，放在当前 P 的 local queue，如果本地队列满了，它会将本地队列的前半部分和 newg 迁移到全局队列中

### Work-stealing goroutine偷取
- M 绑定的 P 没有可执行的 goroutine 时，它会去按照优先级去抢占任务
- 有1/61的概率去选择全局goroutine队列获取任务，防止全局goroutine饥饿
- 如果没有的话，去自己本地的队列获取任务
- 如果没有的话，去偷取其他P的队列的任务
- 如果没有的话，检查其他阻塞的goroutine有没有就绪的
- 如果没有进入自旋状态
- 找到任何一个任务，切换调用栈执行任务。再循环不断的获取任务，直到进入休眠
> 为了保证公平性，从随机位置上的 P 开始，而且遍历的顺序也随机化了(选择一个小于 GOMAXPROCS，且和它互为质数的步长)，保证遍历的顺序也随机化了

### spinning thread 线程自旋
- 线程自旋是相对于线程阻塞而言的，表象就是循环执行一个指定逻辑(就是上面提到的调度逻辑，目的是不停地寻找 G)。
- 会产生问题，如果 G 迟迟不来，CPU 会白白浪费在这无意义的计算上。但好处也很明显，降低了 M 的上下文切换成本，提高了性能
-  带P的M不停的找G
- 不带P的M找P挂载
- G 创建又没 spining M 唤醒一个 M

