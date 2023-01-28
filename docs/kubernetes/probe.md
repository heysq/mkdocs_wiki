### 存活探针 livenessProbe
- HTTP GET，端口号和API，请求返回2XX或3XX，容器存活，无响应或状态码异常，重启容器
- TCP，和容器指定端口，建立TCP连接，建立成功，容器存活，否则重启容器
- EXEC，在容器内执行任意命令，检查明德退出状态码，如果为0，容器存活，否则重启容器

#### httpGet
```yaml
spec:
  livenessProbe:
    httpGet:
      path: /
      port: 808
```

### 就绪探针