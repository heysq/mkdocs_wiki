### 命令行小程序合计
- gzip 压缩
- gzip 解压

#### gzip 压缩
- go build -o gzip
- gzip < main.go > main.go.gz
```go
package main

import (
	"compress/gzip"
	"io"
	"os"
)
func main() {
	w := gzip.NewWriter(os.Stdout)
	io.Copy(w, os.Stdin)
}
```