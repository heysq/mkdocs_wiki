### no matching host key type found. Their offer: ssh-dss,ssh-rsa
- OpenSSH7.0以后的版本不再支持ssh-dss(DSA)算法
- 命令行添加选项 `ssh -oHostKeyAlgorithms=+ssh-dss user@host -p port`
- 在ssh的配置文件中添加全局选项 HostKeyAlgorithms +ssh-dss
- 添加到配置 ~/.ssh/config
- 添加到 /etc/ssh/ssh_config