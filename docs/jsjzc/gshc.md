### 高速缓存
- CPU Cache
- 弥补CPU与内存的速度差异
- 内存中的指令，数据会被加载到L1-L3Cache中，而不是直接由CPU访问内存去拿
- 由特定的SRAM（静态随机存储器）组成的物理芯片
- 现代 CPU 中大量的空间已经被 SRAM 占据，图中用红色框出的部分就是 CPU 的 L3 Cache 芯片
![](http://image.heysq.com/wiki/jsjzc/cpucache.jpg)

### Cache Line
- 缓存块
- CPU冲内存中读取数据是一块一块读的，然后存进CPU cache中

### Cache的数据结构和读取过程
- 无论数据是否在cache中，CPU都会先访问cache
- 只有cache中找不到数据时，才会访问内存

### Cache中缓存放置策略
- 直接映射Cache Direct Mapped Cache
- 全相连Cache Fully Associative Cache
- 组相连Cache  Set Associative Cache


#### 直接映射Cache
- Direct Mapped Cache
- 确保任何一个内存块的地址，始终映射到一个固定的CPU Cache地址
- 这个映射关系，通常用mod，求余操作计算
- 一个内存的访问地址，最终包括高位代表的组标记、低位代表的索引，以及在对应的 Data Block 中定位对应字的位置偏移量

#### 举例
- 主内存被分为32块，然后cache中有8个缓存块
- 访问第21号内存块，就回去查询`21mod8`也就是第5块缓存块的位置
![](http://image.heysq.com/wiki/jsjzc/zhijieyingshe.png)

#### 优化
- 实际缓存块会分配2的N次方个
- 查询缓存块的位置就是内存块的低N为就可以
![](http://image.heysq.com/wiki/jsjzc/neicunyouhua.png)

#### 确定缓存块的地址来自确定的内存块
- 21， 13， 5 mod8余数都是5
- 在对应的缓存块中存储一个组标记Tag
- 缓存块本身存储的是内存块的低N位
- 组tag存的就是内存块剩余的高位

#### 缓存块中的数据是不是有效
- 缓存块存组标记还有内存块中的数据
- 还存了一个有效位 valid bit
- 用来标记对应的缓存块中的数据是否有效
- 有效位是0，CPU会忽略Cache Line中的数据，直接访问内存，重新加载缓存数据

#### 访存偏移量
- CPU 在读取数据的时候，并不是要读取一整个 Block，而是读取一个他需要的数据片段。这样的数据，我们叫作 CPU 里的一个字（Word）
- 具体是哪个字，就用这个字在整个 Block 里面的位置来决定，这个位置就是偏移量
![](http://image.heysq.com/wiki/jsjzc/fangcundizhi.png)

### CPU高速缓存层级结构

![](http://image.heysq.com/wiki/jsjzc/cpucengjijiegou.jpeg)

### 高速缓存写入策略
- 写直达
- 写回

#### 写直达
- 写直达 Write-Through
- 每次数据写入都要写入到主内存里面
- 写数据时判断cache里有没有命中，有的话更新cache中的数据后继续写入到主内存
- 每次都要写主内存，这个写策略很慢
![](http://image.heysq.com/wiki/jsjzc/xiezhida.jpeg)


#### 写回
- Write-Back
- 每次只写CacheBlock
- 当CacheBlock要被替换时才会写回到主内存
- 数据写入到CacheBlock时，同时会标记Block为脏状态
- 下次再写入时，会被刷到主内存
- 加载内存到Block时，也会加一个同步脏数据到主内存的过程
![](http://image.heysq.com/wiki/jsjzc/xiehui.jpeg)


### 缓存一致性问题
- CPU核心进行数据更改后，其他核心与更改的核心的cache中数据是不一致的
![](http://image.heysq.com/wiki/jsjzc/hcbyz.jpeg)

#### 缓存不一致解决
- 写传播 Write Propagation：一个CPU核心里的cache更新，必须能够传播到其他的对应节点的cache line里
- 事务的串行化 Transaction Serialization：一个CPU核心里面的读取和写入，在其他节点看起来是顺序是一样的，如果两个CPU核心的cache中有相同的数据时，更新数据情况下，需要加锁机制，只有拿到了对应的cache block的核心才能更新数据
> 两个CPU核心对数据的更新，传播到其他CPU核心的顺序应该是一样的，先后顺序要一致


![](http://image.heysq.com/wiki/jsjzc/swcxh.jpeg)

### 总线嗅探机制
- 总线嗅探机制解决多个CPU核心之间的数据传播机制
- 本质上就是把所有读写请求都通过总线广播给所有CPU核心，然后各个核心接收信息，根据本地缓存的情况进行数据处理


### MESI协议
- 写失效协议（Write Invalidate），只有一个核心负责写入数据，其他核心同步读取到这个写入
- CPU核心写入Cache之后，会广播一个失效请求告诉其他CPU核心，其他CPU核心，根据内容标记自己本地的Cache中的缓存数据为失效状态
- 写广播（Write Broadcast）的协议。一个写入请求广播到所有的 CPU 核心，同时更新各个核心里的 Cache
- 写广播在实现上很简单，但是写广播需要占用更多的总线带宽。写失效只需要告诉其他的 CPU 核心，哪一个内存地址的缓存失效了，但是写广播还需要把对应的数据传输给其他 CPU 核心
![](http://image.heysq.com/wiki/jsjzc/xieshixiao.jpeg)

### MESI 内容
- M：代表已修改 Modified，cache line中的脏的block，里边的数据更新了，但是没有写回到主内存
- E：代表独占 Exclusive，cache line只加载了当前CPU核所拥有的Cache里，其他的CPU核并没有加载对应的数据到自己的Cache里，这个时候，更新cache block写入数据，不需要更新到其他CPU核心
- S：代表共享 Shared，独占状态下，核心接收到主线的其他CPU也读取数据到自己的Cache中的请求，就会变成共享状态。当要更新cache中的数据时，需要获取当前对应的cache block数据的所有权，一般发送一个广播操作`RFO（Request For Ownership）`，通知其他CPU核心将对应的Cache标记为失效状态
- I：代表已失效 Invalidated，cache line中的block，数据已经失效了，数据不可信
![](http://image.heysq.com/wiki/jsjzc/mesi.jpeg)