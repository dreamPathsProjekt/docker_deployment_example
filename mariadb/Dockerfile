FROM  mariadb:10.3

LABEL maintainer="dream.paths.projekt@gmail.com"

RUN mkdir -p /usr/src/custom_conf
COPY . /usr/src/custom_conf
WORKDIR /usr/src/custom_conf

ENTRYPOINT [ "./docker-entry.sh" ]
EXPOSE 3306
CMD ["mysqld"]