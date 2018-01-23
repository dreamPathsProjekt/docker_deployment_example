FROM  mariadb:10.3

LABEL maintainer="dream.paths.projekt@gmail.com"

RUN mkdir -p /home/custom_conf
COPY . /home/custom_conf
WORKDIR /home/custom_conf

ENTRYPOINT [ "./docker-entry.sh" ]
EXPOSE 3306
CMD ["mysqld"]