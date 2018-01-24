FROM        prom/blackbox-exporter:v0.11.0

ADD         startapp.sh /etc/blackbox_exporter/startapp.sh
ADD         blackbox.yml /etc/blackbox_exporter/config.yml

EXPOSE      9115

ENTRYPOINT [ "/etc/blackbox_exporter/docker-entry.sh" ]
CMD         [ "--config.file=/etc/blackbox_exporter/config.yml" ]
