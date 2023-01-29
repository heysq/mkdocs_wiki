### 简介
- 看书阅读记笔记的地方
- web [网站 wiki.heysq.com](https://wiki.heysq.com)
- 基于`mkdocs`，主题`mkdocs-material`

### 环境安装
- 本地环境直接运行
```shell
pip install -r requirements.txt
```

- docker运行
```dockerfile
docker build -f Dockerfile -t imagename:tagname .
docker run -itd --rm -p 8080:80 imagename:tagname
```

- k8s运行
1. 在docker打包镜像后，修改kubernetes.yaml中镜像的为本地
2. kubectl apply -f kubernetes.yaml

### 基础镜像
- https://hub.docker.com/r/43797189/mkdocs_wiki_nginx

### 基于Drone进行cicd操作
- 可以修改`.drone.yml`文件
- 调整执行流程与打包操作