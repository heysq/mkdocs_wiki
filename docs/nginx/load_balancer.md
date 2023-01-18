### 负责均衡策略
- 轮询 round-robin
- 最小连接 least-connected
- 源地址hash ip-hash
- uri hash
- 加权负载均衡 weight load balancer
- 运行状况检查 health checks

### 轮询
- 默认轮询算法
```
upstream backend {
    server srv1.example.com;
    server srv2.example.com;
    server srv3.example.com;
}
```

### 最小连接
```
upstream backend {
    least_conn;
    server srv1.example.com;
    server srv2.example.com;
    server srv3.example.com;
}
```

### 源地址hash
```
upstream backend {
    ip_hash;
    server srv1.example.com;
    server srv2.example.com;
    server srv3.example.com;
}
```

### uri hash
```
upstream backend {
    hash $request_uri;
    server srv1.example.com;
    server srv2.example.com;
    server srv3.example.com;
}
```

### 加权负载均衡
- 默认权重为1
```
upstream backend {
    server srv1.example.com weight=3;
    server srv2.example.com weitht=4;
    server srv3.example.com weight=1;
}
```

### 运行状况检查
- max_fails 缺省值是 1，fail_timeout 缺省值是 10s
- www.example.com 的健康检查会被关闭，一直都标记为可用
- www2.example.com 失败后会重试两次，再次失败后标记不可用一天
```
upstream backend {
    server www.example.com max_fails=0;
    server www2.example.com max_fails=2 fail_timeout=1d;
}
```

### proxy_next_upstream
- 负载均衡请求出现异常，使用下一个server
- error 建立连接 / 发送请求 / 接收响应时出错（缺省值之一）；
- timeout 建立连接 / 发送请求 / 接收响应时超时（缺省值之一）；
- invalid_header 上游返回空白或无效响应；
- http_500 上游返回 500 Internal Server Error；
- http_501 上游返回 501 Not Implemented；
- http_502 上游返回 502 Bad Gateway；
- http_503 上游返回 503 Service Unavailable；
- http_504 上游返回 504 Gateway Timeout；
- http_404 上游返回 404 Not Found；
- http_429 上游返回 429 Too Many Requests；
- non_idempotent 解除对非幂等请求 (POST, LOCK, PATCH) 的封印，小心造成重复提交；
- off 不得转给下一台服务器。

```
location / {
    ...
    proxy_pass http://backend;
    proxy_next_upstream error timeout http_500;
    ...
}
```