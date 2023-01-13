### 基于Gitea的CICD流程
#### 部署gitea
- 本身搭建环境，先不考虑数据安全性
- docker-compose 启动容器
- 数据库暂时使用sqlite

```
version: "3"

networks:
  gitea:
    external: false

services:
  server:
    image: gitea/gitea:1.18.0
    container_name: gitea
    environment:
      - USER_UID=1000
      - USER_GID=1000
    restart: always
    networks:
      - gitea
    volumes:
      - ./gitea:/data
      - /etc/timezone:/etc/timezone:ro
      - /etc/localtime:/etc/localtime:ro
    ports:
      - "3000:3000"
      - "222:22"
```
