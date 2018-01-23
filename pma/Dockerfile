FROM  phpmyadmin/phpmyadmin:latest

LABEL maintainer="dream.paths.projekt@gmail.com"

RUN mkdir -p /usr/src/custom_conf
COPY . /usr/src/custom_conf
WORKDIR /usr/src/custom_conf

EXPOSE 80
ENTRYPOINT [ "./docker-entry.sh" ]
CMD ["phpmyadmin"]