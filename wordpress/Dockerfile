FROM  wordpress:4-php7.1-fpm-alpine

LABEL maintainer="dream.paths.projekt@gmail.com"

RUN mkdir -p /usr/src/custom_conf
COPY . /usr/src/custom_conf
WORKDIR /usr/src/custom_conf

ENTRYPOINT [ "./docker-entry.sh" ]
CMD ["php-fpm"]