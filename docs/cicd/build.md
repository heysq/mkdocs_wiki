### 基于Gitea的CICD流程
#### 部署Gitea
- 本身搭建环境，先不考虑数据安全性
- docker-compose 启动容器
- 数据库暂时使用sqlite
- 可以自定义端口
- 访问3000端口设置gitea
> mkdir -p gitea/{data,config} && cd gitea
> touch docker-compose.yaml
> docker-compose up -d

```
version: "2"

services:
  server:
    image: gitea/gitea:1.18.0-rootless
    restart: always
    volumes:
      - ./data:/var/lib/gitea
      - ./config:/etc/gitea
      - /etc/timezone:/etc/timezone:ro
      - /etc/localtime:/etc/localtime:ro
    ports:
      - "3000:3000"
      - "2222:2222"
```

#### docker部署Drone
- [Drone官方文档](https://docs.drone.io/server/provider/gitea/)
- 新建一个OAuth2应用
![](/images/cicd/gitea.png) 