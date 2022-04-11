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