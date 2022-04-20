### 多个嵌入方式
- 接口嵌入
- 结构体嵌入

### 嵌入总结
- 结构体类型的方法集合包含嵌入的接口类型的方法集合
- 当结构体类型 T 包含嵌入字段 E 时，*T 的方法集合不仅包含类型 E 的方法集合，还要包含类型 *E 的方法集合
- 基于非接口类型的 defined 类型创建的新 defined 类型不会继承原类型的方法集合
- 通过类型别名定义的新类型则和原类型拥有相同的方法集合

### 接口嵌入
- 接口就是一个方法集合
- 新接口类型（如接口类型 I）将嵌入的接口类型（如接口类型 E）的方法集合，并入到自己的方法集合中
- 在 Go 1.14 版本之前是有约束的：如果新接口类型嵌入了多个接口类型，这些嵌入的接口类型的方法集合不能有交集，同时嵌入的接口类型的方法集合中的方法名字，也不能与新接口中的其他方法同名
```go
type I interface {
    M1()
    M2()
    M3()
}


type I interface {
    E
    M3()
}
```
- 以某个类型名、类型的指针类型名或接口类型名，直接作为结构体字段的方式就叫做结构体的类型嵌入，这些字段也被叫做嵌入字段（Embedded Field）
- 结构体可以嵌入结构体和接口类型
- 嵌入字段类型的底层类型不能为指针类型
- 嵌入字段的名字在结构体定义也必须是唯一的，如果两个类型的名字相同，它们无法同时作为嵌入字段放到同一个结构体定义中
### 结构体嵌入
```go
type T1 int
type t2 struct{
    n int
    m int
}

type I interface {
    M1()
}

type S1 struct {
    T1
    *t2
    I            
    a int
    b string
}
```

### 嵌入后方法集合
- 结构体类型的方法集合，包含嵌入的接口类型的方法集合
```go

type I interface {
    M1()
    M2()
}

type T struct {
    I
}

func (T) M3() {}

func main() {
    var t T
    var p *T
    dumpMethodSet(t)
    dumpMethodSet(p)
}

main.T's method set:
- M1
- M2
- M3

*main.T's method set:
- M1
- M2
- M3
```

- 嵌入了其他类型的结构体类型本身是一个代理
- 调用其实例所代理的方法时，Go 会首先查看结构体自身是否实现了该方法
- 如果实现方法了，Go 就会优先使用结构体自己实现的方法
- 如果没有实现，那么 Go 就会查找结构体中的嵌入字段的方法集合中，是否包含了这个方法
- 如果多个嵌入字段的方法集合中都包含这个方法，那么方法集合存在交集。Go 编译器就会因无法确定究竟使用哪个方法而报错
- 去掉因嵌入造成的交集的方法或者结构体自身实现交集的方法
```go
  type E1 interface {
      M1()
      M2()
      M3()
  }
  
  type E2 interface {
     M1()
     M2()
     M4()
 }
 
 type T struct {
     E1
     E2
 }
 
 func main() {
     t := T{}
     t.M1()
     t.M2()
 }
 ```

 ### 打印一个interface的方法集合
 ```go
 func dumpMethodSet(i interface{}) {
	dynTyp := reflect.TypeOf(i)

	if dynTyp == nil {
		fmt.Printf("there is no dynamic type\n")
		return
	}

	n := dynTyp.NumMethod()
	if n == 0 {
		fmt.Printf("%s's method set is empty!\n", dynTyp)
		return
	}

	fmt.Printf("%s's method set:\n", dynTyp)
	for j := 0; j < n; j++ {
		fmt.Println("-", dynTyp.Method(j).Name)
	}
	fmt.Printf("\n")
}

```
