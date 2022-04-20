### 方法
- Go 语言中的方法的本质就是，一个以方法的 receiver 参数作为第一个参数的普通函数
![](/images/go/methods.jpg)
- 方法支持赋值给变量，相当于第一个参数是结构体自身或者自身的指针类型
```go
package main

import "fmt"

type T struct{}

func (t *T) M(n int) {
	fmt.Println(n)
}

func (t T)N(n int) {
	fmt.Println(n)
}

func main() {
	m1 := (*T).M
	m1(&T{}, 2)

	m2 := T.N
	m2(T{}, 3)
}
```

### 方法接收receiver
```go
func (t *T或T) MethodName(参数列表) (返回值列表) {
    // 方法体
}
```
- T为基类型
- receiver 参数的基类型本身不能为指针类型或接口类型
- 每个方法只能有一个 receiver 参数
- Go 不支持在方法的 receiver 部分放置包含多个 receiver 参数的参数列表，或者变长 receiver 参数
- 方法接收器（receiver）参数、函数 / 方法参数，以及返回值变量对应的作用域范围，都是函数 / 方法体对应的显式代码块
- receiver 部分的参数名不能与方法参数列表中的形参名，以及具名返回值中的变量名存在冲突，必须在这个方法的作用域中具有唯一性
- 如果在方法体中，我们没有用到 receiver 参数，我们也可以省略 receiver 的参数名

### 方法声明约束
- 方法声明要与 receiver 参数的基类型声明放在同一个包内
- 不能为原生类型（诸如 int、float64、map 等）添加方法
- 不能跨越 Go 包为其他包的类型声明新方法

### 选择receiver 原则
- 如果需要修改receiver内部属性，使用指针类型
- 不需要修改内部属性，使用结构体类型，传参值拷贝，但是结构体过大时，选用指针类型
- 如果 T 类型需要实现某个接口，那就要使用 T 作为 receiver 参数的类型，来满足接口类型方法集合中的所有方法

### 方法集合
```go
- 用来判断一个类型是否实现了某接口类型的唯一手段
- T类型实现了M1方法
- *T类型实现了M1和M2方法
type Interface interface {
    M1()
    M2()
}

type T struct{}

func (t T) M1()  {}
func (t *T) M2() {}

func main() {
    var t T
    var pt *T
    var i Interface

    i = pt
    i = t // cannot use t (type T) as type Interface in assignment: T does not implement Interface (M2 method has pointer receiver)
}
```

### type定义的新类型和命名的类型的方法集合
- 自定义非接口类型的 defined 类型的方法集合为空
- 自定义接口类型的 defined 类型的方法集合为接口的方法
```go
package main

type T struct{}

func (T) M1()  {}
func (*T) M2() {}

type T1 T

func main() {
  var t T
  var pt *T
  var t1 T1
  var pt1 *T1

  dumpMethodSet(t)
  dumpMethodSet(t1)

  dumpMethodSet(pt)
  dumpMethodSet(pt1)
}


main.T's method set:
- M1

main.T1's method set is empty!

*main.T's method set:
- M1
- M2

*main.T1's method set is empty!
```
- 无论原类型是接口类型还是非接口类型，类型别名都与原类型拥有完全相同的方法集合
```go

type T struct{}

func (T) M1()  {}
func (*T) M2() {}

type T1 = T

func main() {
    var t T
    var pt *T
    var t1 T1
    var pt1 *T1

    dumpMethodSet(t)
    dumpMethodSet(t1)

    dumpMethodSet(pt)
    dumpMethodSet(pt1)
}


main.T's method set:
- M1

main.T's method set:
- M1

*main.T's method set:
- M1
- M2

*main.T's method set:
- M1
- M2
```