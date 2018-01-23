FROM  wordpress:4-php7.1-fpm-alpine

LABEL maintainer="dream.paths.projekt@gmail.com"

RUN mkdir -p /home/custom_conf
COPY . /home/custom_conf
WORKDIR /home/custom_conf

ENTRYPOINT [ "./docker-entry.sh" ]
CMD ["php-fpm"]