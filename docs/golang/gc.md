### 内存管理的三个参与者
- mutator 指的是我们的应用，也就是 application，我们将堆上的对象看作一个图，跳出应用来看的话，应用的代码就是在不停地修改这张堆对象图里的指向关系
![](/images/golang/mutator.png)


- allocator 就很好理解了，指的是内存分配器，应用需要内存的时候都要向 allocator 申请。allocator 要维护好内存分配的数据结构，在多线程场景下工作的内存分配器还需要考虑高并发场景下锁的影响，并针对性地进行设计以降低锁冲突
- collector 是垃圾回收器。死掉的堆对象、不用的堆内存都要由 collector 回收，最终归还给操作系统。当 GC 扫描流程开始执行时，collector 需要扫描内存中存活的堆对象，扫描完成后，未被扫描到的对象就是无法访问的堆上垃圾，需要将其占用内存回收掉
![](/images/golang/neicunguanli.png)

### tcmalloc
![](/images/golang/tcmalloc.png)

### Go内存分配过程分类
- tiny ：size < 16 bytes && has no pointer(noscan)
- small ：has pointer(scan) || (size >= 16 bytes && size <= 32 KB)
- large ：size > 32 KB

### 内存分配数据结构
- arenas 是 Go 向操作系统申请内存时的最小单位，每个 arena 为 64MB 大小，在内存中可以部分连续，但整体是个稀疏结构
- 单个 arena 会被切分成以 8KB 为单位的 page，由 page allocator 管理
- 一个或多个 page 可以组成一个 mspan
- 每个 mspan 可以按照 sizeclass 再划分成多个 element
- 同样大小的 mspan 又分为 scan 和 noscan 两种，分别对应内部有指针的 object 和内部没有指针的 object
![](/images/golang/neicunshuju.png)

### mspan
- 每一个 mspan 都有一个 allocBits 结构
- 从 mspan 里分配 element 时，只要将 mspan 中对应该 element 位置的 bit 位置一就可以，其实就是将 mspan 对应 allocBits 中的对应 bit 位置一
- 每一个 mspan 都会对应一个 allocBits 结构
![](/images/golang/mspanbitmap.png)


### GC 流程
![](/images/golang/gc.png)

### 三色标记
- 黑表示已经扫描完毕，子节点扫描完毕（gcmarkbits = 1，且在队列外）
- 灰表示已经扫描完毕，子节点未扫描完毕（gcmarkbits = 1, 在队列内）
- 白表示未扫描，collector 不知道任何相关信息。

### 解决错标漏标，引入三色不变性
- 强三色不变性 strong tricolor invariant：黑色对象不能直接引用白色对象
![](/images/golang/qiangsanse.png)
- 弱三色不变性 weak tricolor invariant：黑色对象可以引用白色对象，但白色对象必须有能从灰色对象可达的路径
![](/images/golang/ruosanse.png)

### Go实现三色不变性，引入写屏障
- snippet of code insert before pointer modify
- 在应用进入 GC 标记阶段前的 stw 阶段，会将全局变量 runtime.writeBarrier.enabled 修改为 true
- 然后所有的堆上指针修改操作在修改之前便会额外调用 runtime.gcWriteBarrier
- 栈上的对象市不会开启写屏障的
- 混合写屏障，指针断开的老对象和新对象都标灰的实现
![](/images/golang/hunhexiepingzhang.png)
### 常见的写屏障
- Dijistra Insertion Barrier，指针修改时，指向的新对象要标灰
- Yuasa Deletion Barrier，指针修改时，修改前指向的对象要标灰

### 回收的两个goroutine
- 一个叫 sweep.g，主要负责清扫死对象，合并相关的空闲页
- 一个叫 scvg.g，主要负责向操作系统归还内存

### sweep.g
- GC 的标记流程结束之后，sweep goroutine 就会被唤醒，进行清扫工作
- 循环执行 sweepone -> sweep。针对每个 mspan，sweep.g 的工作是将标记期间生成的 bitmap 替换掉分配时使用的 bitmap
![](/images/golang/sweepg.png)
- 根据 mspan 中的槽位情况决定该 mspan 的去向
    - 如果 mspan 中存活对象数 = 0，也就是所有 element 都变成了内存垃圾，执行 freeSpan -> 归还组成该 mspan 所使用的页，并更新全局的页分配器摘要信息
    - 如果 mspan 中没有空槽，说明所有对象都是存活的，将其放入 fullSwept 队列中
    - 如果 mspan 中有空槽，说明这个 mspan 还可以拿来做内存分配，将其放入 partialSweep 队列中

    ### scvg.g 待补充
    - bgscavenge
    - pageAlloc.scavenge
    - pageAlloc.scavengeOne
    - pageAlloc.scavengeRangeLocked
    - sysUnused
    - madvise
    ![](/images/golang/madvise.png)