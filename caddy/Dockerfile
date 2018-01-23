FROM  stefanprodan/caddy:0.10.10

LABEL maintainer="dream.paths.projekt@gmail.com"

RUN rm -f /etc/caddy/Caddyfile
COPY . /etc/caddy/
WORKDIR /etc/caddy/

ENTRYPOINT [ "./docker-entry.sh" ]
CMD ["caddy", "-quic", "--conf", "/etc/caddy/Caddyfile"]