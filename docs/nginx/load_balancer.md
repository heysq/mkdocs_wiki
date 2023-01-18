### 负责均衡策略
- 轮询 round-robin
- 最小连接 least-connected
- 源地址hash ip-hash
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