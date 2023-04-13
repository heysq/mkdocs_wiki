### 数组定义
- 一个长度固定的、由同构类型（相同类型）元素组成的连续序列
- `var arr [N]T`
- 数组变量 arr，类型为`[N]T`，长度为N，元素类型为T
- 如果两个数组类型的元素类型 T 与数组长度 N 都是一样的，那么这两个数组类型是等价的
- 如果有一个属性不同，它们就是两个不同的数组类型
- 通过`len`方法获得数组长度
- 通过`unsafe.Pointer()`可以获得数组总的占用空间
- 数组做为函数参数，值拷贝，性能代价高

#### 数组定义&&初始化
- 定义但不初始化
- 定义且初始化并指定长度
- 定义且初始化当不指定长度
- 下标赋值的方式对它进行初始化
```go

var arr1 [6]int // 没有显示初始化，数据默认为零值，[0 0 0 0 0 0]

var arr2 = [6]int {
    11, 12, 13, 14, 15, 16,
} // [11 12 13 14 15 16]

var arr3 = [...]int { 
    21, 22, 23,
} // 编译器自动推断数组的长度，[21 22 23]
fmt.Printf("%T\n", arr3) // [3]int

// 下标赋值的方式对它进行初始化
var arr4 = [...]int{
    99: 39, // 将第100个元素(下标值为99)的值赋值为39，其余元素值均为0
}
fmt.Printf("%T\n", arr4) // [100]int
```

### 切片
- 定义切片变量时，不像数组一样定义长度
- 长度容量不固定
- len 返回切片长度
- append 向切片中追加元素
- 切片传参数，相当于传递底层数组的描述符

#### 切片结构
- 底层运行时结构
- array 底层数组的指针
- len 切片长度
- cap 切片容量
```go

type slice struct {
    array unsafe.Pointer
    len   int
    cap   int
}
```

#### 切片定义与初始化
- 通过make创建切片，可以指定长度与容量
    - `var arr = make([]int, 3, 6)` 类型，长度，容量
    - 不指定容量，cap=len
- 采用 array[low : high : max]语法基于一个已存在的数组创建切片。这种方式被称为数组的切片化
    - 从原数组起始位置low开始
    - 新数组长度 high - low
    - 数组容量是 max - low
    - 对新切片中元素的修改将直接影响原数组
    - 新数组的容量和长度不能大于原数组
```go
arr := [10]int{1, 2, 3, 4, 5, 6, 7, 8, 9, 10}
sl := arr[3:7:9]
``` 
![](http://image.heysq.com/wiki/go/arr_low_high_max.jpg)   

- 基于切片创建切片

#### 切片动态扩容
- 翻倍扩容
- 基于一个已有数组建立的切片，一旦追加的数据操作触碰到切片的容量上限（实质上也是数组容量的上界)，切片就会和原数组解除“绑定”，后续对切片的任何修改都不会反映到原数组中

### 数组与切片互相转换（go1.17后官方支持）
- 数组转切片
```go
func main() {
	arr := [3]int{1, 2, 3}
	sli := arr[:]
	fmt.Println(sli)
}
```

- 切片转数组 `unsafe` 方法
```go
func main() {
	b := []int{1, 2, 3}
	p := (*[3]int)(unsafe.Pointer(&b[0]))
	(*p)[1]+= 10
	fmt.Println(*p)
}
```

- 切片转数组官方方法，转换后的数组长度不能大于原切片的长度，nil 切片或 cap 为 0 的 empty 切片都可以被转换为一个长度为 0 的数组指针
```go
func main() {
	b := []int{1, 2, 3}
	p := (*[3]int)(b)
	(*p)[1] += 10
	fmt.Println(*p)
}
```

### 函数传参性能
- 传参都是值拷贝
- slice拷贝的是引用结构
- array拷贝的是数组的值（包含元素）
```go
a1 := [16]int{}
	d1 := func(arr [16]int) int {
		return len(arr)
	}

	f1 := func() int {
		return d1(a1)
	}

	a2 := [65535]int{}
	d2 := func(arr [65535]int) int {
		return len(arr)
	}
	f2 := func() int {
		return d2(a2)
	}

	for _, f := range []func() int{f1, f2} {
		start := time.Now()
		for i := 0; i < 10000; i++ {
			f()
		}
		fmt.Printf("time.Since(start).Milliseconds(): %v\n", time.Since(start).Microseconds())
	}
    // 88
    // 398362
```