### 自定义新类型
- 用`type`定义新类型
    - 基于已有类型定义新类型 `type NewType int`
    - 字面值来定义新类型，多用于自定义一个新的复合类型
        - `type M map[int]string`
        - `type S []string`
    - 支持使用`type`块进行批量定义
    ```go 
    type (
        T1 int
        T2 T1
        T3 string
    )
    ```    

- 类型别名，通常用在项目的渐进式重构，还有对已有包的二次封装方面
    - `type MyInt = int`  
    - 新类型与原类型完全等价
    ```go

    type T = string 
    
    var s string = "hello" 
    var t T = s // ok
    fmt.Printf("%T\n", t) // string
    ```

### 结构体类型定义
- 结构体的类型字面值由若干个字段（field）聚合而成，每个字段有自己的名字与类型
- 每个结构体的field name 都是唯一的
- 如果结构体类型只在它定义的包内使用，可以将类型名的首字母小写
- 如果不想将结构体类型中的某个字段暴露给其他包，可以把这个字段名字的首字母小写
- 可以用空标识符“_”作为结构体类型定义中的字段名称，不能被外部包引用，也无法被结构体所在的包使用
```go
type T struct {
    Field1 T1
    Field2 T2
    ... ...
    FieldN Tn
}
```

### 空结构体
- `type Empty struct{}` 
- Empty是一个不包含任何字段的空结构体类型
- 空结构体类型变量的内存占用为 0
- 基于空结构体类型内存零开销这样的特性， Go 开发中会经常使用空结构体类型元素，作为一种“事件”信息进行 Goroutine 之间的通信
```go

var c = make(chan Empty) // 声明一个元素类型为Empty的channel
c<-Empty{}               // 向channel写入一个“事件”
```

### 结构体嵌套
- 其他结构体作为自定义结构体中字段的类型
- 可以只引入结构体类型，而不命名
- 不支持在结构体类型定义中，递归的放入自身类型字段的定义方式
- 不可在自身中出现自身的字段，但是可以拥有自身的指针类型、以自身类型为元素的切片类型和以自身类型作为value的map类型
- 一个类型，它所占用的大小是固定的，因此一个结构体定义好的时候，其大小是固定的。但是，如果结构体里面套结构体，那么在计算该结构体占用大小的时候，就会成死循环
- 但如果是指针、切片、map等类型，其本质都是一个int大小(指针，4字节或者8字节，与操作系统有关)，因此该结构体的大小是固定的，类型就能决定占用内存大小
```go

type Person struct {
    Name string
    Phone string
    Addr string
}

type Book struct {
    Title string
    Author Person
    ... ...
}

type BookV2 struct {
    Title string
    Person
    ... ...
}


type T struct {
    t  *T           // ok
    st []T          // ok
    m  map[string]T // ok
}     
```

### 初始化
- 零值初始化 

```go

type Book struct {
    ...
}

var book Book
var book = Book{} // 标准变量声明
book := Book{} // 短变量声明
```
- 复合字面值
    - 按顺序一次给每个结构体字段进行赋值，结构体字段较少，且没有非导出字段
    ```go
    
    type Book struct {
        Title string              // 书名
        Pages int                 // 书的页数
        Indexes map[string]int    // 书的索引
    }

    var book = Book{"The Go Programming Language", 700, make(map[string]int)}
    ```
    - field:value”形式的复合字面值

- 使用构造函数初始化结构体
```go

// $GOROOT/src/time/sleep.go
func NewTimer(d Duration) *Timer {
    c := make(chan Time, 1)
    t := &Timer{
        C: c,
        r: runtimeTimer{
            when: when(d),
            f:    sendTime,
            arg:  c,
        },
    }
    startTimer(&t.r)
    return t
}
```


### 结构体类型的内存布局
- 将结构体字段平铺的形式，存放在一个连续内存块中，理想情况
![](http://image.heysq.com/wiki/go/struct_ram.jpg)
- 现实实际存储，需要在字段之间添加padding，为了内存对齐
![](http://image.heysq.com/wiki/go/struct_padding.jpg)
- 使用`unsafe.Sizeof(t)` 获取结构体占用空间大小
- 使用`unsafe.Offsetof(t.Fn)` 获取字段Fn在内存中相对于t起始地址的偏移量

#### 内存对齐
- 出于对处理器存取数据效率的考虑
- 对于各种基本数据类型来说，它的变量的内存地址值必须是其类型本身大小的整数倍，比如，一个 int64 类型的变量的内存地址，应该能被 int64 类型自身的大小，也就是 8 整除；一个 uint16 类型的变量的内存地址，应该能被 uint16 类型自身的大小，也就是 2 整除
- 对于结构体而言，它的变量的内存地址，只要是它最长字段长度与系统对齐系数两者之间较小的那个的整数倍就可以。但对于结构体类型来说，还要让它每个字段的内存地址都严格满足内存对齐要求
- 可以主动填充结构体，内存对齐

#### 举例
- 64bit平台系统对齐系数是8
```go
type T struct {
    b byte // 1字节，对齐需要填充7字节

    i int64 // 8字节，对齐不需要填充
    u uint16 // 2字节，对齐需要填充6字节
}
```
![](http://image.heysq.com/wiki/go/neicunduiqi.jpg)

### 内存对齐
- CPU 访问内存时，并不是逐个字节访问，而是以字长（word size）为单位访问
- 32位的CPU，字长为4字节CPU访问内存的单位是4字节
- 64为的CPU，字长为8字节CPU访问内存的单位是8字节
- 为了减少 CPU 访问内存的次数，加大 CPU 访问内存的吞吐量。同样读取 8 个字节的数据，一次读取 4 个字节只需要读取 2 次
- CPU 始终以字长访问内存，如果不进行内存对齐，很可能增加 CPU 访问内存的次数
- 内存对齐对实现变量的原子性操作也有好处，每次内存访问是原子的，如果变量的大小不超过字长，那么内存对齐后，对该变量的访问就是原子的
![](http://image.heysq.com/wiki/go/neicunduiqijuli.png)

#### 内存对齐倍数
- unsafe.Alignof(变量)
- 表示内存占用的量必须是结果的倍数

#### Go内存对齐倍数
- 对于任意类型的变量 x ，`unsafe.Alignof(x)` 至少为 1。
- 对于 struct 结构体类型的变量 x，计算 x 每一个字段 f 的 `unsafe.Alignof(x.f)`，`unsafe.Alignof(x)` 等于其中的最大值。
- 对于 array 数组类型的变量 x，`unsafe.Alignof(x)` 等于构成数组的元素类型的对齐倍数

#### 空struct内存对齐
- 空 struct{} 大小为 0，作为其他 struct 的字段时，一般不需要内存对齐
- 有一种情况除外：即当 struct{} 作为结构体最后一个字段时，需要内存对齐。因为如果有指针指向该字段, 返回的地址将在结构体之外
- 如果此指针一直存活不释放对应的内存，就会有内存泄露的问题（该内存不因结构体释放而释放）
- 当 struct{} 作为其他 struct 最后一个字段时，需要填充额外的内存保证安全
```go
type demo3 struct {
	c int32
	a struct{}
}

type demo4 struct {
	a struct{}
	c int32
}

func main() {
	fmt.Println(unsafe.Sizeof(demo3{})) // 8
	fmt.Println(unsafe.Sizeof(demo4{})) // 4
}
```

