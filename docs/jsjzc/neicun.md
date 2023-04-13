### 内存
- 虚拟内存地址 Virtual Address
- 物理内存地址 Physical Address
- 内存被划分成固定大小的`页Page`，然后通过虚拟内存地址到物理内存地址的转换，才能到达实际存放数据的物理内存地址
- 程序看到的内存地址，都是虚拟内存地址

### 简单页表
- 虚拟内存地址映射到物理内存地址，最直观的方式就是建立一张映射表
- 能够实现虚拟内存里面的页，到物理内存里面的页的`映射`，在计算机里边叫做`页表Page Table`
- 把一个内存地址分成`页号 Directory`和`偏移量 Offset`

#### 页表举例
- 内存地址前面的高位，就是内存地址的页号
- 内存地址后面的地位，就是内存地址里面的偏移量
- 做地址转换的页表，只需要保留虚拟内存地址的页号和物理内存地址的页号之间的映射关系就可以
- 同一个页里的内存，在物理层面是连续的
- 32位的内存地址，然后每个页的大小是4KB，也就是4K字节，需要高20位，低12为
- 32为的内存地址，每个页表占用的内存空间都是4MB，每个进程都持有一个页表，导致严重的空间浪费
![](http://image.heysq.com/wiki/jsjzc/neicundizhi.jpeg)

#### 地址转换流程
- 把虚拟内存地址，切分成页号和偏移量的组合
- 从页表里面，查询出虚拟页号对应的物理页号
- 直接拿物理页号加上偏移量，就得到了物理内存地址
![](http://image.heysq.com/wiki/jsjzc/neicunzhuanhuan.jpeg)

### 多级页表
- 整个进程的内存地址空间通常都是 两头实。中间空
- 程序运行的时候，内存地址从顶部往下，不断分配占用的栈的空间，从底部往上，不断分配占用的堆的空间
![](http://image.heysq.com/wiki/jsjzc/duojiyebiao.jpeg)

#### 页表树
![](http://image.heysq.com/wiki/jsjzc/yebiaoshu.jpeg)

### 加速地址转换
- 局部性原理（空间局部性和时间局部性），连续执行的指令通常都在一个内存页中
![](http://image.heysq.com/wiki/jsjzc/huancunye.jpeg)
- CPU里放置一个缓存芯片，缓存访问过的页，减少反复去访问内存来进行地址转换的开销
- 缓存芯片叫`TLB 地址变换高速缓冲 Translation-Lookaside Buffer`
- 指令TLB `ITLB`
- 数据TLB `DTLB`
- TLB可以根据大小进行分级
- 需要用`脏页`这样的标记位，实现写回这样缓存管理策略
- 封装了内存管理单元 `MMU Memory Management Unit` 芯片和TLB进行交互
![](http://image.heysq.com/wiki/jsjzc/tlb.jpeg)

### 内存保护 Memory Protection
- 可执行空间保护
- 地址空间布局随机化

#### 可执行空间保护
- 对于一个进程使用的内存，只把其中的指令部分设置成“可执行”的，对于其他部分，比如数据部分，不给予“可执行”的权限

#### 地址空间布局随机化
- Address Space Layout Randomization
![](http://image.heysq.com/wiki/jsjzc/dizhisuiji.jpeg)