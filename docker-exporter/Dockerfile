
FROM python:latest
LABEL maintainer="i.dritsas@jrtechnologies.com"

# set working directory
RUN mkdir -p /usr/src/docker-exporter
WORKDIR /usr/src/docker-exporter

# add requirements (to leverage Docker cache)
ADD ./setup.py /usr/src/docker-exporter/setup.py

# install requirements
# RUN sudo apt-get install python3.6-dev
RUN python setup.py install

# add app
ADD . /usr/src/docker-exporter

# run server
CMD ["python", "json_exporter.py"]

