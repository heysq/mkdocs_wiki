### 微信文章待整理
- Go 依赖注入 https://mp.weixin.qq.com/s/Do-kTTbyKT4rsAGD3ujKwQ
- 结构体多字段原子操作 https://mp.weixin.qq.com/s/Wa1l4M5P89rQ2pyB_KnMxg
- 函数调用相关 https://mp.weixin.qq.com/s/Ekx9JpclqLaa4baB6V5rLw https://mp.weixin.qq.com/s/QGp1H6-__pus1Kbb7U8CHw
- 泛型 https://mp.weixin.qq.com/s/s9SITQB2xQb4tqmoLaJUpw
### 各种nil判断
- 切片定义但不初始化，则为nil
```go
func main() {
	var s []int
	fmt.Println(s == nil)
}
```

- map定义但是不进行初始化，则为nil
```go
func main() {
	var m map[string]int
	fmt.Println(m == nil)
}
```

- 接口变量定义但是不赋初值
```go
type MyInterface interface {
	M1(string)
}

func main() {
	var m MyInterface
	fmt.Println(m == nil)
}
```

- channel定义但是不初始化
```go
func main() {
	var ch chan int
	fmt.Println(ch == nil)
}
```

- 指针类型变量没有被显式赋予初值
```go
type Book struct{}

func main() {
	var b *Book
	fmt.Println(b == nil)
}
```