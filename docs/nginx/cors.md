### 跨域配置
- server 配置块中添加请求头标志
- add_header 'Access-Control-Allow-Origin' *;
- add_header 'Access-Control-Allow-Credentials' 'true';
- add_header 'Access-Control-Allow-Methods' *;
- add_header 'Access-Control-Allow-Headers' *;