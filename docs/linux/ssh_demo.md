### ssh config 配置
- 多次连接同一服务器共享一个连接
- ssh host
- 指定密钥路径
```
host *
ControlMaster auto
ControlPath ~/.ssh/master-%r@%h:%p
ServerAliveInterval 80

Host tencent_ubuntu
	Hostname 49.232.155.155
	Port 22
	User ubuntu
	IdentityFile ~/.ssh/tencent_ubuntu_rsa
```