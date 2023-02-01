FROM registry.cn-beijing.aliyuncs.com/aliyun_wiki/mkdocs_basic:v1
WORKDIR /mkdocs_wiki
COPY . /mkdocs_wiki
RUN mkdocs build && cp -r site /etc/nginx/ && rm -f /etc/nginx/nginx.conf
ADD nginx.conf /etc/nginx/nginx.conf

EXPOSE 80

STOPSIGNAL SIGQUIT
CMD ["nginx", "-g", "daemon off;"]
