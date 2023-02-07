### 原生字符串 string类型
- 数据不可变，提高了字符串的并发安全性和存储利用率
- 没有"\0"结尾，获取长度的时间复杂度是常数时间
- 原生字符串所见即所得，构造多行字符串更加简单，多行字符串用反引号包裹
- 采用unicode字符集，对非ASCII字符提供原生日支持，消除不同环境下乱码问题

### Go字符串组成
- 字节角度
    - Go 语言中的字符串值也是一个可空的字节序列，字节序列中的字节个数称为该字符串的长度
    - len方法返回字符串字节长度
- 字符视角
    - 字符串是由一个可空的字符序列构成
    - range 循环字符
    - utf8.RuneCountInString(s)统计字符个数

### rune类型与字面值
- Go 使用 rune 这个类型来表示一个 Unicode 码点。rune 本质上是 int32 类型的别名类型，它与 int32 类型是完全等价的
> Unicode 码点，就是指将 Unicode 字符集中的所有字符“排成一队”，字符在这个“队伍”中的位次，就是它在 Unicode 字符集中的码点。也就说，一个码点唯一对应一个字符

- 一个 rune 实例就是一个 Unicode 字符，一个 Go 字符串也可以被视为 rune 实例的集合
- 可以通过字符字面值来初始化一个 rune 变量

#### 字面值
-  通过单引号括起的字符字面值
```go
'a'  // ASCII字符
'中' // Unicode字符集中的中文字符
'\n' // 换行字符
'\'' // 单引号字符
```
- Unicode 专用的转义字符\u 或\U 作为前缀，来表示一个 Unicode 字符
    - \u 后面接两个十六进制数。如果是用两个十六进制数无法表示的 Unicode 字符，可以使用\U
    - \U 后面可以接四个十六进制数来表示一个 Unicode 字符
```go

'\u4e2d'     // 字符：中
'\U00004e2d' // 字符：中
'\u0027'     // 单引号字符
```
- 直接用整型值来给rune赋值
```go
'\x27'  // 使用十六进制表示的单引号字符
'\047'  // 使用八进制表示的单引号字符
```

### 字符串字面值
- 使用双引号给字符串赋值
- 如果需要表示原始的值可以使用转义字符`"\\xe4\\xb8\\xad\xe5\x9b\xbd\xe4\xba\xba"`
```go

"abc\n"
"中国人"
"\u4e2d\u56fd\u4eba" // 中国人
"\U00004e2d\U000056fd\U00004eba" // 中国人
"中\u56fd\u4eba" // 中国人，不同字符字面值形式混合在一起
"\xe4\xb8\xad\xe5\x9b\xbd\xe4\xba\xba" // 十六进制表示的字符串字面值：中国人
```

### Go字符串内部表示
- 本身并不真正存储字符串数据
- 由一个指向底层存储的指针和字符串的长度字段组成的
- 获取字符串长度，时间复杂度为O(1)
- 直接将 string 类型通过函数 / 方法参数传入也不会带来太多的开销
```go
// $GOROOT/src/reflect/value.go

// StringHeader是一个string的运行时表示
type StringHeader struct {
    Data uintptr
    Len  int
}
```

```go
package main

import (
	"fmt"
	"reflect"
	"unsafe"
)

func dumpBytesArray(arr []byte) {
	fmt.Printf("[")
	for _, b := range arr {
		fmt.Printf("%c ", b)
	}
	fmt.Printf("]\n")
}

func main() {
	var s = "hello"
	hdr := (*reflect.StringHeader)(unsafe.Pointer(&s)) // 将string类型变量地址显式转型为reflect.StringHeader
	fmt.Printf("0x%x\n", hdr.Data)                     // 0x495db9
	p := (*[5]byte)(unsafe.Pointer(hdr.Data))          // 获取Data字段所指向的数组的指针
	dumpBytesArray((*p)[:])                            // [h e l l o ]   // 输出底层数组的内容
}

```

### 字符串转换
- `string`、`[]byte`和`[]rune`互相转换
```go

var s string = "中国人"
                      
// string -> []rune
rs := []rune(s) 
fmt.Printf("%x\n", rs) // [4e2d 56fd 4eba]
                
// string -> []byte
bs := []byte(s) 
fmt.Printf("%x\n", bs) // e4b8ade59bbde4baba
                
// []rune -> string
s1 := string(rs)
fmt.Println(s1) // 中国人
                
// []byte -> string
s2 := string(bs)
fmt.Println(s2) // 中国人
```

### 字符串拼接
- `+` 操作符
- fmt.Sprintf
- strings.Join
- strings.Builder
- bytes.Buffer
 
```go

var sl []string = []string{
  "Rob Pike ",
  "Robert Griesemer ",
  "Ken Thompson ",
}

func concatStringByOperator(sl []string) string {
  var s string
  for _, v := range sl {
    s += v
  }
  return s
}

func concatStringBySprintf(sl []string) string {
  var s string
  for _, v := range sl {
    s = fmt.Sprintf("%s%s", s, v)
  }
  return s
}

func concatStringByJoin(sl []string) string {
  return strings.Join(sl, "")
}

func concatStringByStringsBuilder(sl []string) string {
  var b strings.Builder
  for _, v := range sl {
    b.WriteString(v)
  }
  return b.String()
}

func concatStringByStringsBuilderWithInitSize(sl []string) string {
  var b strings.Builder
  b.Grow(64)
  for _, v := range sl {
    b.WriteString(v)
  }
  return b.String()
}

func concatStringByBytesBuffer(sl []string) string {
  var b bytes.Buffer
  for _, v := range sl {
    b.WriteString(v)
  }
  return b.String()
}

func concatStringByBytesBufferWithInitSize(sl []string) string {
  buf := make([]byte, 0, 64)
  b := bytes.NewBuffer(buf)
  for _, v := range sl {
    b.WriteString(v)
  }
  return b.String()
}

func BenchmarkConcatStringByOperator(b *testing.B) {
  for n := 0; n < b.N; n++ {
    concatStringByOperator(sl)
  }
}

func BenchmarkConcatStringBySprintf(b *testing.B) {
  for n := 0; n < b.N; n++ {
    concatStringBySprintf(sl)
  }
}

func BenchmarkConcatStringByJoin(b *testing.B) {
  for n := 0; n < b.N; n++ {
    concatStringByJoin(sl)
  }
}

func BenchmarkConcatStringByStringsBuilder(b *testing.B) {
  for n := 0; n < b.N; n++ {
    concatStringByStringsBuilder(sl)
  }
}

func BenchmarkConcatStringByStringsBuilderWithInitSize(b *testing.B) {
  for n := 0; n < b.N; n++ {
    concatStringByStringsBuilderWithInitSize(sl)
  }
}

func BenchmarkConcatStringByBytesBuffer(b *testing.B) {
  for n := 0; n < b.N; n++ {
    concatStringByBytesBuffer(sl)
  }
}

func BenchmarkConcatStringByBytesBufferWithInitSize(b *testing.B) {
  for n := 0; n < b.N; n++ {
    concatStringByBytesBufferWithInitSize(sl)
  }
}
```

### []byte和string互相转换不拷贝方法
```go
func ByteArray2String(arr []byte) (str string) {
	sliceHeader := (*reflect.SliceHeader)(unsafe.Pointer(&arr))
	stringHeader := (*reflect.StringHeader)(unsafe.Pointer(&str))

	stringHeader.Data = sliceHeader.Data
	stringHeader.Len = sliceHeader.Len
	return
}

func String2ByteArray(str string) (arr []byte) {
	stringHeader := (*reflect.StringHeader)(unsafe.Pointer(&str))
	sliceHeader := (*reflect.SliceHeader)(unsafe.Pointer(&arr))

	sliceHeader.Data = stringHeader.Data
	sliceHeader.Len = stringHeader.Len
	sliceHeader.Cap = stringHeader.Len
	return
}
```