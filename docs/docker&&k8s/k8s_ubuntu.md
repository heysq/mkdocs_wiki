### 安装准备
#### 安装 docker
- [docker](../install_ubuntu)

#### 修改 docker cgroupdriver
- /etc/docker/daemon.json
- 添加以下字段
```shell
"exec-opts": ["native.cgroupdriver=systemd"]
```