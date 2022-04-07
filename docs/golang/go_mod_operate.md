### 为当前项目添加一个依赖
- 在代码中import包地址
- go get `新的依赖的包地址`
- go mod tidy 自动处理包的依赖导入

### 升级/降级依赖的版本
- 项目modules目录，执行go get 指定的版本
- go mod edit 更新依赖版本，然后执行go mod tidy
- 可以修改go mod 依赖版本号为要使用的分支，然后执行go mod tidy

### 添加一个主版本号大于 1 的依赖
- 在导包的路径上加上版本号
- github.com/go-redis/redis/v7
- 然后执行go get 或者 go mod tidy

### 升级依赖版本到一个不兼容版本
- 通过空应用更新版本
- `import _ "github.com/go-redis/redis/v8"`
- 然后执行go get 或者 go mod tidy

### 移除一个不用的依赖
- 删除代码中的引用
- 执行 go mod tidy，更新go.mod和go.sum

### 特殊情况，可以使用vendor
- vendor做为go mod的补充
- 不方便访问外网进行包下载
- 比较关注构建过程中的性能
- 通过 `go mod vendor`自动常见vendor目录
- 基于vender文件夹进行构建 `go build -mod=vendor`
- Go 1.14 及以后版本中，如果 Go 项目的顶层目录下存在 vendor 目录，那么 go build 默认也会优先基于 vendor 构建，除非go build 传入 -mod=mod 的参数