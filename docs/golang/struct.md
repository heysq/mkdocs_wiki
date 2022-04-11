### 自定义新类型
- 用`type`定义新类型
    - 基于已有类型定义新类型 `type NewType int`
    - 字面值来定义新类型，多用于自定义一个新的复合类型
        - `type M map[int]string`
        - `type S []string`
    - 支持使用`type`块进行批量定义
    ```go 
    type (
        T1 int
        T2 T1
        T3 string
    )
    ```    

- 类型别名，通常用在项目的渐进式重构，还有对已有包的二次封装方面
    - `type MyInt = int`  
    - 新类型与原类型完全等价
    ```go

    type T = string 
    
    var s string = "hello" 
    var t T = s // ok
    fmt.Printf("%T\n", t) // string
    ```

### 结构体类型定义
- 结构体的类型字面值由若干个字段（field）聚合而成，每个字段有自己的名字与类型
- 每个结构体的field name 都是唯一的
- 如果结构体类型只在它定义的包内使用，可以将类型名的首字母小写
- 如果不想将结构体类型中的某个字段暴露给其他包，可以把这个字段名字的首字母小写
- 可以用空标识符“_”作为结构体类型定义中的字段名称，不能被外部包引用，也无法被结构体所在的包使用
```go
type T struct {
    Field1 T1
    Field2 T2
    ... ...
    FieldN Tn
}
```

### 空结构体
- `type Empty struct{}` 
- Empty是一个不包含任何字段的空结构体类型
- 空结构体类型变量的内存占用为 0
- 基于空结构体类型内存零开销这样的特性， Go 开发中会经常使用空结构体类型元素，作为一种“事件”信息进行 Goroutine 之间的通信