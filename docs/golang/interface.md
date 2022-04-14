### 接口定义注意事项
- Go语言要求接口类型声明中的方法必须是具名的，并且方法名字在这个接口类型的方法集合中是唯一的
- 即使嵌套接口出现交集，也要求交集的方法名，入参和返回值一样，否则编译器会报错
- 在 Go 接口类型的方法集合中放入首字母小写的非导出方法也是合法的

### 实现接口
- 如果一个类型 T 的方法集合是某接口类型 I 的方法集合的等价集合或超集，类型 T 实现了接口类型 I，那么类型 T 的变量就可以作为合法的右值赋值给接口类型 I 的变量
- 任何类型都实现了空接口

### 接口的静态特性与动态特性
- 静态特性：接口类型变量具有静态类型，比如var err error中变量 err 的静态类型为 error
- 静态类型：接口类型变量在运行时还存储了右值的真实类型信息，这个右值的真实类型被称为接口类型变量的动态类型
```go
var err error
err = errors.New("error1")
fmt.Printf("%T\n", err)  // *errors.errorString
```

### 动静特性优势
- 接口类型变量在程序运行时可以被赋值为不同的动态类型变量，每次赋值后，接口类型变量中存储的动态类型信息都会发生变化
- 鸭子类型 Duck Typing，某一类型表现出的行为不是有基因决定的，而是由类型所表现出的行为决定的
- Go 接口还可以保证“动态特性”使用时的安全性，编译阶段就可以发现接口类型赋值不正确的错误
```go
type QuackableAnimal interface {
    Quack()
}

type Duck struct{}

func (Duck) Quack() {
    println("duck quack!")
}

type Dog struct{}

func (Dog) Quack() {
    println("dog quack!")
}

type Bird struct{}

func (Bird) Quack() {
    println("bird quack!")
}                         
                          
func AnimalQuackInForest(a QuackableAnimal) {
    a.Quack()             
}                         
                          
func main() {             
    animals := []QuackableAnimal{new(Duck), new(Dog), new(Bird)}
    for _, animal := range animals {
        AnimalQuackInForest(animal)
    }  
}
```

### 接口变量的内部表示
```go
// $GOROOT/src/runtime/runtime2.go
type iface struct {
    tab  *itab
    data unsafe.Pointer
}

type eface struct {
    _type *_type
    data  unsafe.Pointer
}
```

- eface 用于表示没有方法的空接口（empty interface）类型变量，也就是 interface{}类型的变量
- iface 用于表示其余拥有方法的接口 interface 类型变量
- 第二个指针字段的功能相同，都是指向当前赋值给该接口类型变量的动态类型变量的值
- _type 指向赋值给这个接口的变量的动态类型信息
```go

// $GOROOT/src/runtime/type.go

type _type struct {
    size       uintptr
    ptrdata    uintptr // size of memory prefix holding all pointers
    hash       uint32
    tflag      tflag
    align      uint8
    fieldAlign uint8
    kind       uint8
    // function for comparing objects of this type
    // (ptr to object A, ptr to object B) -> ==?
    equal func(unsafe.Pointer, unsafe.Pointer) bool
    // gcdata stores the GC type data for the garbage collector.
    // If the KindGCProg bit is set in kind, gcdata is a GC program.
    // Otherwise it is a ptrmask bitmap. See mbitmap.go for details.
    gcdata    *byte
    str       nameOff
    ptrToThis typeOff
}
```
- iface 除了要存储动态类型信息之外，还要存储接口本身的信息（接口的类型信息、方法列表信息等）以及动态类型所实现的方法的信息，因此 iface 的第一个字段指向一个itab类型结构
```go
// $GOROOT/src/runtime/runtime2.go
type itab struct {
    inter *interfacetype // 接口类型自身的信息
    _type *_type
    hash  uint32 // copy of _type.hash. Used for type switches.
    _     [4]byte
    fun   [1]uintptr // variable sized. fun[0]==0 means _type does not implement inter. 字段fun则是动态类型已实现的接口方法的调用地址数组。
}


// $GOROOT/src/runtime/type.go
type interfacetype struct {
    typ     _type
    pkgpath name
    mhdr    []imethod
}
```

### 接口相等判断
- 接口存储的动态数据类型一样
    - 空接口使用_type
    - 非空接口使用tab._type
- 接口存储的data指向的数据一样
- 对于空接口类型变量，只有 _type 和 data 所指数据内容一致的情况下，两个空接口类型变量之间才能划等号
- Go 在创建 eface 时一般会为 data 重新分配新内存空间，将动态类型变量的值复制到这块内存空间，并将 data 指针指向这块内存空间，多数情况下看到的 data 指针值都是不同的