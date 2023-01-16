### 语义导入版本
- Semantic Import Versioning
- go.mod 的 require 段中依赖的版本号，都符合 vX.Y.Z 的格式
- 一个符合 Go Module 要求的版本号，由前缀 v 和一个满足语义版本规范的版本号组成
- 借助于语义版本规范，Go 命令可以确定同一 module 的两个版本发布的先后次序，而且可以确定它们是否兼容
- Go Module 规定：如果同一个包的新旧版本是兼容的，那么它们的包导入路径应该是相同的


#### 语义版本号组成
- 主版本
- 次版本
- 补丁版本
![](/images/go/yuyibanben.png)

### 最小版本选择
- Minimal Version Selection
- 项目之间出现依赖同一个包但是不同版本的情况
- go mod 选择依赖所有版本的最小的那个版本
- go mod 不会选择最新的1.7.0版本，而是选择1.3.0 版本
![](/images/go/zuixiaoyilai.png)

### GO111MODULE配置值
- on 开启
- off 关闭
- auto 编译器判断
![](/images/go/go111module.jpeg)