### 各种nil判断
- 切片定义但不初始化，则为nil
```go
package main

import "fmt"

func main() {
	var s []int
	fmt.Println(s == nil)
}
```