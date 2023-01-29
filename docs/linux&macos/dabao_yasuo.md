### 打包
- 命令 `tar`
- tar cf 生成的文件名 打包的目录名
- tar cf /tmp/etc-backup.tar /etc

### 单独压缩
- `gzip`
- `bizp2`

### 组合打包压缩
- tar czf /tmp/etc-backup.tar.gz /etc 压缩速度快
- tar cjf /tmp/etc-backup.tar.bzip2 /etc 压缩比率高

### 解压缩
- tar xzf /tmp/etc-backup.tar.gz -C /root 解压缩的文件和解压到的路径
- tar xjf /tmp/etc-backup.tar.bzip2 -C root 