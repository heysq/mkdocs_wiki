### 跨域配置
- server 配置块中添加请求头标志
- add_header 'Access-Control-Allow-Origin' *; 允许跨域请求的原始站点
- add_header 'Access-Control-Allow-Credentials' 'true'; 允许携带cookie进行跨域请求
- add_header 'Access-Control-Allow-Methods' *; 允许跨域请求的方法
- add_header 'Access-Control-Allow-Headers' *; 允许跨域请求的携带的header