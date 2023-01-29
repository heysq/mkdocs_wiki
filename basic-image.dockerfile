FROM python:3.10-alpine3.16
COPY requirements.txt /
RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.ustc.edu.cn/g' /etc/apk/repositories && apk add --no-cache nginx \
    && pip install -r requirements.txt -i https://mirrors.ustc.edu.cn/pypi/web/simple
