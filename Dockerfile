FROM 43797189/mkdocs_wiki_nginx:v1
WORKDIR /mkdocs_wiki
COPY . /mkdocs_wiki
RUN mkdocs build && cp -r site /etc/nginx/ && rm -f /etc/nginx/nginx.conf
ADD nginx.conf /etc/nginx/nginx.conf

EXPOSE 80

STOPSIGNAL SIGQUIT
CMD ["nginx", "-g", "daemon off;"]
