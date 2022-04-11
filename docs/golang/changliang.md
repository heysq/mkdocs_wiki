### Go 常量创新
- 支持无类型常量
- 支持隐式自动转型
- 可用于实现枚举

### 无类型常量
- 常量声明时没有被显示设置类型
- const n 根据字面值推断类型为int
```go
package main

import (
	"fmt"
)

type myInt int

const n = 13
const m int64 = n + 5 // OK

func main() {
	var a int = 5
	fmt.Println(a + n) // 输出：18
}

```

### 隐式转型
- 对于无类型常量参与的表达式求值，Go 编译器会根据上下文中的类型信息，把无类型常量自动转换为相应的类型后，再参与求值计算
- 转型的对象是一个常量，并不会引发类型安全问题，Go 编译器会保证这一转型的安全性
- 如果 Go 编译器在做隐式转型时，发现无法将常量转换为目标类型，Go 编译器也会报错
```go

const m = 1333333333

var k int8 = 1
j := k + m // 编译器报错：constant 1333333333 overflows int8
```

### 实现枚举
- Go 的 const 语法提供了“隐式重复前一个非空表达式”的机制
```go
package main

import (
	"fmt"
)

const (
	Apple  = 11
	Banana = 12
	Strawberry
	Pear
)

func main() {
	fmt.Println(Apple)
	fmt.Println(Pear)
}
```

- `iota` const 声明块（包括单行声明）中，每个常量所处位置在块中的偏移值（从零开始）
- 每一行中的 iota 自身也是一个无类型常量，可以像无类型常量那样，自动参与到不同类型的求值过程中来，不需要再对它进行显式转型操作
- 同一行的 iota 即便出现多次，多个 iota 的值也是一样的
- 其值一直自增１直到遇到下一个const关键字，其值才被重新置为０
```go

// $GOROOT/src/sync/mutex.go 
const ( 
    mutexLocked = 1 << iota // 刚开始iota为1，后续自增1, 1 << 0
    mutexWoken // 定义时没有显示赋值，重复上一行的值，1 << iota，相当于1 << 1
    mutexStarving // 同上
    mutexWaiterShift = iota // 重新设置为3
    starvationThresholdNs = 1e6
)

const (
    Apple, Banana = iota, iota + 10 // 0, 10 (iota = 0)
    Strawberry, Grape // 1, 11 (iota = 1)
    Pear, Watermelon  // 2, 12 (iota = 2)
)
```

- 略过iota中的0或者某个值
```go

// $GOROOT/src/syscall/net_js.go
const (
    _ = iota
    IPV6_V6ONLY  // 1
    SOMAXCONN    // 2
    SO_ERROR     // 3
)

const (
    _ = iota // 0
    Pin1
    Pin2
    Pin3
    _
    Pin5    // 5   
)
```

- 每个const块都有自己的iota
```go
const (
    a = iota + 1 // 1, iota = 0
    b            // 2, iota = 1
    c            // 3, iota = 2
)

const (
    i = iota << 1 // 0, iota = 0
    j             // 2, iota = 1
    k             // 4, iota = 2
)
```