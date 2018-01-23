FROM  wordpress:4-php7.1-fpm-alpine

LABEL maintainer="dream.paths.projekt@gmail.com"

COPY . /usr/local/bin/
WORKDIR /usr/local/bin/

ENTRYPOINT [ "./docker-entry.sh" ]
CMD ["php-fpm"]