### 原码安装ZSH新版
> ubuntu 18.04 安装的zsh版本较低（5.4）oh-my-zsh需要使用5.8以上

1. 源码网址 https://zsh.sourceforge.io/Arc/source.html
2. `wget https://jaist.dl.sourceforge.net/project/zsh/zsh/5.8/zsh-5.8.tar.xz`
3. `tar xvf zsh-5.8.tar.xz`
4. centos 需要
    ```shell
    yum install gcc perl-ExtUtils-MakeMaker
    yum install ncurses-devel
    ```
5. `cd zsh-5.8`
6. `./configure`
7. `make && make install`
8. `vim /etc/shells` 添加 `/usr/local/bin/zsh`