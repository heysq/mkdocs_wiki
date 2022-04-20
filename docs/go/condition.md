### 带label的continue语句
- 多用于嵌套循环
- 终止内层循环用，继续执行外层循环
- 如果使用`goto`语句不管是内层循环还是外层循环都会被终结，代码将会从 outerloop 这个 label 处，开始重新执行嵌套循环语句，这与带 label 的 continue 的跳转语义是完全不同的
```go
func main() {
    var sl = [][]int{
        {1, 34, 26, 35, 78},
        {3, 45, 13, 24, 99},
        {101, 13, 38, 7, 127},
        {54, 27, 40, 83, 81},
    }

outerloop:
    for i := 0; i < len(sl); i++ {
        for j := 0; j < len(sl[i]); j++ {
            if sl[i][j] == 13 {
                fmt.Printf("found 13 at [%d, %d]\n", i, j)
                continue outerloop
            }
        }
    }
}
```

### 带label的break语句
- 用于嵌套循环，结束外层循环
```go
var gold = 38

func main() {
    var sl = [][]int{
        {1, 34, 26, 35, 78},
        {3, 45, 13, 24, 99},
        {101, 13, 38, 7, 127},
        {54, 27, 40, 83, 81},
    }

outerloop:
    for i := 0; i < len(sl); i++ {
        for j := 0; j < len(sl[i]); j++ {
            if sl[i][j] == gold {
                fmt.Printf("found gold at [%d, %d]\n", i, j)
                break outerloop
            }
        }
    }
}
```


### for 循环的坑
- 循环变量重用，i和v变量只会定义一次，后续每次都是重用。为闭包函数增加参数，传参iv
```go
func main() {
    var m = []int{1, 2, 3, 4, 5}  
             
    for i, v := range m {
        go func() {
            time.Sleep(time.Second * 3)
            fmt.Println(i, v)
        }()
    }

    time.Sleep(time.Second * 10)
}
```

- 参与 for range 循环的是 range 表达式的副本，参与循环的a是a的副本，但是修改的是原始的a，数组类型循环可以用切片代替
```go
func main() {
    var a = [5]int{1, 2, 3, 4, 5}
    var r [5]int

    fmt.Println("original a =", a)

    for i, v := range a {
        if i == 0 {
            a[1] = 12
            a[2] = 13
        }
        r[i] = v
    }

    fmt.Println("after for range loop, r =", r)
    fmt.Println("after for range loop, a =", a)
}


// original a = [1 2 3 4 5]
// after for range loop, r = [1 2 3 4 5]
// after for range loop, a = [1 12 13 4 5]
```

- 遍历 map 中元素的随机性

### switch case type
- x 必须是一个interface{} 接口类型
- switch不用短变量接收，只会有x的动态类型
- 用短变量接受还可以获得x的value，v 存储的是变量 x 的动态类型对应的值信息
- Go 中所有类型都实现了 interface{}类型，所以 case 后面可以是任意类型信息
- 如果在 switch 后面使用了某个特定的接口类型 I，那么 case 后面就只能使用实现了接口类型 I 的类型了，否则 Go 编译器会报错
```go

func main() {
	var x interface{} = Book{Name: "11"}
	switch v := x.(type) {
	case nil:
		println("v is nil")
	case int:
		println("the type of v is int, v =", v)
	case string:
		println("the type of v is string, v =", v)
	case bool:
		println("the type of v is bool, v =", v)
	case Book:
		fmt.Println("the type of v is book, v =", v)
	default:
		println("don't support the type")
	}
}
```