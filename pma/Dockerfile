FROM  phpmyadmin/phpmyadmin:latest

LABEL maintainer="dream.paths.projekt@gmail.com"

RUN mkdir -p /home/custom_conf
COPY . /home/custom_conf
WORKDIR /home/custom_conf

EXPOSE 80
ENTRYPOINT [ "./docker-entry.sh" ]
CMD ["phpmyadmin"]