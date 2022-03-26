### 高速缓存
- CPU Cache
- 弥补CPU与内存的速度差异
- 内存中的指令，数据会被加载到L1-L3Cache中，而不是直接由CPU访问内存去拿
- 由特定的SRAM（静态随机存储器）组成的物理芯片
- 现代 CPU 中大量的空间已经被 SRAM 占据，图中用红色框出的部分就是 CPU 的 L3 Cache 芯片
![](/images/jsjzc/cpucache.jpg)

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
![](/images/jsjzc/zhijieyingshe.png)

#### 优化
- 实际缓存块会分配2的N次方个
- 查询缓存块的位置就是内存块的低N为就可以
![](/images/jsjzc/neicunyouhua.png)

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
![](/images/jsjzc/fangcundizhi.png)

### CPU高速缓存层级结构

![](/images/jsjzc/cpucengjijiegou.jpeg)

### 高速缓存写入策略
- 写直达
- 写回

#### 写直达
- 写直达 Write-Through
- 每次数据写入都要写入到主内存里面
- 写数据时判断cache里有没有命中，有的话更新cache中的数据后继续写入到主内存
- 每次都要写主内存，这个写策略很慢
![](/images/jsjzc/xiezhida.jpeg)


#### 写回
- Write-Back
- 每次只写CacheBlock
- 当CacheBlock要被替换时才会写回到主内存
- 数据写入到CacheBlock时，同时会标记Block为脏状态
- 下次再写入时，会被刷到主内存
- 加载内存到Block时，也会加一个同步脏数据到主内存的过程
![](/images/jsjzc/xiehui.jpeg)

