### Ubuntu 安装

#### 官方文档
- [Install on Ubuntu](https://docs.docker.com/engine/install/ubuntu/)
#### 支持的系统版本

- Ubuntu Jammy 22.04 (LTS)
- Ubuntu Impish 21.10
- Ubuntu Focal 20.04 (LTS)
- Ubuntu Bionic 18.04 (LTS)

#### 卸载旧安装

```shell
sudo apt-get remove docker docker-engine docker.io containerd runc
```

#### 通过仓库（repository）安装
##### 1. 更新并添加仓库源

```shell
sudo apt-get update
sudo apt-get install ca-certificates curl gnupg lsb-release
```
##### 2. 添加docker官方GPG key

```shell
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
```

##### 3. 添加仓库源地址到docker.list

```shell
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
```

##### 4. 安装docker engine

```shell
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-compose-plugin
```

##### 5. 测试安装

```shell
sudo docker run hello-world:lastest
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
