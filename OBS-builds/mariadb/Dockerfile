FROM  mariadb:10.3

LABEL maintainer="dream.paths.projekt@gmail.com"

COPY . /usr/local/bin/
WORKDIR /usr/local/bin/

ENTRYPOINT [ "./docker-entry.sh" ]
EXPOSE 3306
CMD ["mysqld"]