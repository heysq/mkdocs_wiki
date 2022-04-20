https://mp.weixin.qq.com/s/ZmfwNlq5_A2RgpUSkJQXrQ

### defer
- Go 语言提供的一种延迟调用机制，defer 的运作离不开函数
- 只有在函数（和方法）内部才能使用 defer
- defer 关键字后面只能接函数（或方法），这些函数被称为 deferred 函数
- defer 将它们注册到其所在 Goroutine 中，用于存放 deferred 函数的栈数据结构中，这些 deferred 函数将在执行 defer 的函数退出前，按后进先出（LIFO）的顺序被程序调度执行
- 无论是执行到函数体尾部返回，还是在某个错误处理分支显式 return，又或是出现 panic，已经存储到 deferred 函数栈中的函数，都会被调度执行
![](/images/go/defer.jpg)

### defer 注意事项
- 明确哪些函数可以作为 deferred 函数，有返回值的deferred函数的返回值会被自动丢弃
    - 内置函数 append、cap、len、make、new和imag不能被注册为deferred函数，可以包装一层func，进行调用
    - close、copy、delete、print、recover 可以被注册为deferred函数
```go

Functions: 内置函数列表
  append cap close complex copy delete imag len 
  make new panic print println real recover
```
- 注意 defer 关键字后面表达式的求值时机，defer 关键字后面的表达式，是在将 deferred 函数注册到 deferred 函数栈的时候进行求值的
```go
package main

import (
	"fmt"
)

func foo1() {
	for i := 0; i <= 3; i++ {
		defer fmt.Println(i)
	}
}

func foo2() {
	for i := 0; i <= 3; i++ {
		defer func(n int) {
			fmt.Println(n)
		}(i)
	}
}

func foo3() {
	for i := 0; i <= 3; i++ {
		defer func() {
			fmt.Println(i)
		}()
	}
}

func main() {
	fmt.Println("foo1 result:")
	foo1()
	fmt.Println("\nfoo2 result:")
	foo2()
	fmt.Println("\nfoo3 result:")
	foo3()
}

```

- 知晓 defer 带来的性能损耗