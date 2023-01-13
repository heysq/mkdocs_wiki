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

``` yaml
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

#### Drone 环境准备
- [Drone官方文档](https://docs.drone.io/server/provider/gitea/)
- Gitea中新建一个OAuth2应用
![](/images/cicd/gitea.png) 
- 创建一个共享密钥
``` shell
openssl rand -hex 16
bea26a2221fd8090ea38720fc445eca6
```

#### Drone docker 部署
- 替换多个变量 配置变量
- 更换映射端口
- 启动docker容器
``` shell
docker run \
  --volume=/var/lib/drone:/data \
  --env=DRONE_GITEA_SERVER=https://git.heysq.com:8443 \
  --env=DRONE_GITEA_CLIENT_ID=${oauth client id} \
  --env=DRONE_GITEA_CLIENT_SECRET=${oauth client secret} \
  --env=DRONE_RPC_SECRET=${共享密钥} \
  --env=DRONE_SERVER_HOST=drone.heysq.com:8443 \
  --env=DRONE_SERVER_PROTO=https \
  --publish=XXXX:80 \
  --publish=XXXX:443 \
  --restart=always \
  --detach=true \
  --name=drone \
  drone/drone:2
```

#### Drone Runner docker 部署
- Runner 用来执行仓库中的yaml文件
- 执行克隆打包编译等一些列预先定义好的操作
- 替换共享密钥和端口
- docker run 启动容器
- Runner容器日志有以下信息则启动成功
> INFO[0027] successfully pinged the remote server        
> INFO[0027] polling the remote server                     arch=amd64 capacity=2 endpoint="https://drone.heysq.com:8443" kind=pipeline os=linux type=docker

``` shell
docker run -itd --detach \
  --volume=/var/run/docker.sock:/var/run/docker.sock \
  --env=DRONE_RPC_PROTO=https \
  --env=DRONE_RPC_HOST=drone.heysq.com:8443 \
  --env=DRONE_RPC_SECRET=${共享密钥} \
  --env=DRONE_RUNNER_CAPACITY=2 \
  --env=DRONE_RUNNER_NAME=drone-runner \
  --publish=XXXX:3000 \
  --restart=always \
  --name=runner \
  drone/drone-runner-docker:1
```