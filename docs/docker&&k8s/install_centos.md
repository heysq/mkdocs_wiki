### CentOS 安装

#### 官方文档
- [Install on CentOS](https://docs.docker.com/engine/install/centos/)

#### 支持的系统版本
- CentOS7
- CentOS8（stream）
- CentOS9（stream）

#### 卸载旧安装
```shell
sudo yum remove docker \
                  docker-client \
                  docker-client-latest \
                  docker-common \
                  docker-latest \
                  docker-latest-logrotate \
                  docker-logrotate \
                  docker-engine
```

#### 通过仓库（repository）安装
##### 1. 安装依赖软件

```shell
sudo yum install -y yum-utils
```

##### 2. 添加软件源

```shell
sudo yum-config-manager \
    --add-repo \
    https://download.docker.com/linux/centos/docker-ce.repo
```

##### 3. 安装docker engine

``` shell
sudo yum install docker-ce docker-ce-cli containerd.io docker-compose-plugin
```

##### 4. 启动docker

``` shell
sudo systemctl start docker
```

##### 5. 验证安装

```shell
sudo docker run hello-world
```

#### 用非root用户操作docker
##### 1. 添加docker 用户组
```shell
sudo groupadd docker
```

##### 2. 将当前用户或者要添加的用户添加到docker组
```
sudo usermod -aG docker $USER
```

##### 3. 重载docker组
- 重启系统
- 不想重启输入以下命令

```shell
newgrp docker
```

##### 4. 测试非root用户操作docker
```shell
docker ps
或者
docker run hello-world
```
