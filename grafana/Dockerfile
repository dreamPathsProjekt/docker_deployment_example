FROM  grafana/grafana:4.6.3

LABEL maintainer="dream.paths.projekt@gmail.com"

COPY . /etc/grafana/
WORKDIR /etc/grafana/

ENTRYPOINT ["./docker-entry.sh"]