### 简介
- 看书阅读记笔记的地方
- web [网站 wiki.heysq.com](https://wiki.heysq.com)
- 基于`mkdocs`，主题`mkdocs-material`

### 环境安装
- 本地环境直接运行
```shell
pip install -r requirements.txt
```

- 基于docker运行
```dockerfile
docker build -f Dockerfile -t imagename:tagname .
docker run -itd --rm -p 8080:80 imagename:tagname
```

### 基础镜像
- https://hub.docker.com/r/43797189/mkdocs_wiki_nginx