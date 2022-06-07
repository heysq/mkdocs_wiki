### 原理
- 结构体实现ServeHTTP(http.ResponseWriter, *http.Request)方法

### 代码
```go
package main

import (
	"fmt"
	"io/ioutil"
	"net/http"
)

type Handler struct{}

func (h *Handler) ServeHTTP(w http.ResponseWriter, req *http.Request) {
	requestBody, err := ioutil.ReadAll(req.Body)
	if err != nil {
		w.Write([]byte(err.Error()))
		return
	}
	fmt.Println(req.RequestURI)
	fmt.Println(string(requestBody))
}

func main() {
	server := http.Server{Addr: ":8081", Handler: &Handler{}}
	err := server.ListenAndServe()
	if err != nil {
		fmt.Println(err.Error())
	}
}

```