FROM python:3.10-alpine3.16
WORKDIR /mkdocs_wiki
COPY . /mkdocs_wiki
RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.ustc.edu.cn/g' /etc/apk/repositories && apk add --no-cache nginx \
    && pip install -r requirements.txt -i https://mirrors.ustc.edu.cn/pypi/web/simple \
    && mkdocs build && cp -r site /etc/nginx/ \ 
    && rm -rf /mkdocs_wiki \
    && rm -f /etc/nginx/nginx.conf
ADD nginx.conf /etc/nginx/nginx.conf

EXPOSE 80

STOPSIGNAL SIGQUIT
CMD ["nginx", "-g", "daemon off;"]
