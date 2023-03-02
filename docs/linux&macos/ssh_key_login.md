### SSH 设置密钥登录

#### 服务器操作
- cat id_rsa.pub >> authorized_keys
- chmod 600 authorized_keys
- chmod 700 ~/.ssh
- vim /etc/ssh/sshd_config
    - RSAAuthentication yes
    - RSAAuthentication yes
- systemctl restart ssh

#### 登录机器操作
- debian_rsa 是服务器生成的私钥，需要传送到登录机上

```
Host debian
   Hostname XXXX.com
   Port 22
   User debian
   IdentityFile ~/.ssh/debian_rsa
```

