### 运行系统命令，获取结果，错误信息

```go
func RunCommand(path, name string, arg ...string) (string, string, error) {
	var err error
	var msg string
	cmd := exec.Command(name, arg...)
	var out bytes.Buffer
	var stderr bytes.Buffer
	cmd.Stdout = &out
	cmd.Stderr = &stderr
	cmd.Dir = path
	err = cmd.Run()
	log.Println(cmd.Args)
	if err != nil {
		msg = fmt.Sprint(err) + ": " + stderr.String()
		err = errors.New(msg)
		log.Println("err", err.Error(), "cmd", cmd.Args)
	}
	log.Println(out.String())
	return msg, out.String(), nil
}
```