### for 循环中禁止使用defer
- 直接在 for 循环中使用 defer 很可能使得 defer 不能执行，导致内存泄露或者其他资源问题，所以应该将 defer 放到外层。
- 若确实需要使用 defer，可以将逻辑封装为一个独立函数或者使用闭包
- 错误
```go
func readFiles(files []string) {
	for i:=0;i<len(files);i++{
		f,err:=os.Open(files[i])
		if err!=nil{
			println(err.Error())
			continue
		}
        
        // bug here
        // 在循环中的 defer 只有在循环结束后才会执行
        // 若 files 很多，会导致大量文件句柄未及时释放
		defer f.Close()  
        
		bf,err:=io.ReadAll(f)
		if err!=nil{
			println(err.Error())
		}else{
			println(string(bf))
		}
	}
}
```
- 正确
```go
func readFiles(files []string) {
	for i:=0;i<len(files);i++{
		readFile(files[i])
	}
}

func readFile(name string){
	f,err:=os.Open(name)
	if err!=nil{
		println(err.Error())
		return
	}
	defer f.Close()
	bf,err:=io.ReadAll(f)
	if err!=nil{
		println(err.Error())
	}else{
		println(string(bf))
	}
}

```