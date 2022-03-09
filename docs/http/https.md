### HTTPS
- 超文本传输安全协议
- HyperText Transfer Protocol Secure
- HTTP over TLS， HTTP over SSL
- 默认占用端口443

### TLS、SSL
- TLS Transport Layer Security传输层安全协议
- SSL Secure Socket Layer 安全套接层
- 工作在传输层和应用层之间

### TLS 流程
![](/images/http/tls.png)

#### 客户端发送 `client hello`
- TLS 版本号
- 支持的加密组件列表
- 使用的加密算法以及秘钥长度
- 一个随机数字 client random

#### 服务发送 `server hello`
- TLS版本号
- 从客户端发送的加密组件列表中选择的加密方式
- 一个随机数 server random

#### 服务端发送 `Certificate`
- 服务器被CA签名过的公钥证书

#### 服务端发送 `Server Key Exchange`
- 实现`ECHDE`算法的其中一个参数（Server Params）
- Server Params 经过了服务端私钥签名

#### 服务端 `Server Hello Done`
- 告知客户端，服务端发送完毕，协商过程结束
- 明文共享
    - client random
    - server random
    - server params
    - 服务端公钥证书


#### 客户端发送 `Client Key Exchange`
- 实现`ECHDE`算法中的另一个参数（Client Params）
- 客户端和服务端此时都有了 Client Params 和 Server Params
- 用 ECHDE 算法和两个Params 生成随机秘钥串 pre-master
- 用client random，server random和pre-master生成主秘钥
- 主密钥衍生出，客户端和服务端发送用的会话秘钥

#### 客户端发送 `Change Ciper Spec`
- 告知服务端之后的通信会采用计算出来的秘钥进行加密通信

#### 客户端发送 `Finished`
- 连接至今全部报文的整体校验值（摘要），加密之后发送给服务端

#### 服务端发送 `Change Ciper Spec`和`Finished`
- 服务端解密检查报文没有问题，然后TLS完毕
- 后续所有数据采用加密传输

