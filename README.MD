# Docker Deployment Example Using Stack Deploy & Docker Swarm

We assume a single machine (for simplicity), Ubuntu 16.04 system with 4.13.0 Linux Kernel, with the latest version of Docker-CE (v).

```Shell
Client:
 Version:       17.12.0-ce
 API version:   1.35
 Go version:    go1.9.2
 Git commit:    c97c6d6
 Built: Wed Dec 27 20:11:19 2017
 OS/Arch:       linux/amd64

Server:
 Engine:
  Version:      17.12.0-ce
  API version:  1.35 (minimum version 1.12)
  Go version:   go1.9.2
  Git commit:   c97c6d6
  Built:        Wed Dec 27 20:09:53 2017
  OS/Arch:      linux/amd64
  Experimental: false

```

---

## Overview

Deploy a __Wordpress__ (PHP 7.1, Apache) installation stack that uses a __MariaDB__ database and __Adminer__ as an administrative interface for MariaDB (Protected with admin password).

Also in the production environment version ,there is included a simple monitoring stack with __Prometheus__ (collect metrics), __Grafana__ (visualization), __Blackbox Exporter__ (send probe Http requests ,as seen from the outside world) and __Docker Exporter__ which is a custom Python middleware exporter for Prometheus built into a Docker image that exports simple Docker Swarm metrics in the form of live and desired replicas.

Loadbalancing is handled by a __Caddy__ loadbalancer.

> Two Caddy Load balancers in production: services caddy (wpstack) and caddy_monitoring (monitoring stack)

- Caddy exposes desireable ports as proxies and provides Basic Authentication Security on selected services.

- Admin user and password are provided as build variables and initialized at runtime by using Docker Secrets.

### Monitoring - Prometheus

**Prometheus** service is at the center of collecting metrics from our installation.

You can view all Prometheus targets at [http://node:9090/targets](http://node:9090/targets)

- Demo Link: [http://35.189.200.49:9090](http://35.189.200.49:9090)

Prometheus listens and generates metrics from scrape_configs -> jobs

- Example of bootstrapping prometheus(self) & exporters to 'prometheus' job: [prometheus.yml](./production/environment/prometheus/prometheus.yml) configuration file mounted at `/home/username/docker_deployment_example/production/environment/prometheus/* (node-local) -> */etc/prometheus* (container)`

- Prometheus exposes all collected metrics at [http://35.189.200.49:9090/metrics](http://35.189.200.49:9090/metrics), see below for Live Demo credentials

### Grafana - Overview

Grafana is a visualization application that uses Prometheus metrics as a Data source ,and a frontend Dashboard to show simple metrics in human-friendly way.

The included Dashboard shows:

- If our live Docker services are up and scaled to desirable replicas
- Returned http codes
- If Prometheus targets are up

<iframe src=https://snapshot.raintank.io/dashboard/snapshot/WtLG0EcoRG47j2gAoaDMo4UwV62Cr80I width="650" height="300" frameborder="0"></iframe>

### Monitoring - Docker Exporter

Docker exporter (Author: [dreamPathsProjekt](https://github.com/dreamPathsProjekt)), uses Python 3 packages, [docker](https://docker-py.readthedocs.io/en/stable/index.html) and [prometheus_client](https://github.com/prometheus/client_python/tree/master/prometheus_client). It exposes an http server (internally only, on 8000 inside the monitoring stack). It also connects to the Docker daemon using Docker Api, and exposes metrics `live_replicas_<service name>` and `desired_replicas_<service name>` in a Prometheus compatible timeseries format.

A simple way to monitor if services have failed internally is to see if `live replicas < desired replicas`

Docker exporter is also compatible with __multi-node swarms__ (cluster) as long as it is deployed on a __manager node__ (preferably a Leader) and the container mounted to Docker host volume:

```YAML
services:
  # ...

  docker-exporter:
    # ...
    deploy:
      placement:
        constraints:
          - node.role == manager
      replicas: 1
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
```

### Monitoring - Blackbox Exporter

Blackbox exporter is used by Prometheus to probe targets from the outside and collect metrics. To setup a scrape job for Blackbox we setup targets in Prometheus and redirect them to Blackbox via a defined module (here __http_2xx__).

```YAML
  - job_name: 'wpstack_wordpress'
    metrics_path: /probe
    params:
      module: [http_2xx]
    scrape_interval: 10s

    static_configs:
      - targets:
        - '35.189.200.49:80'
    relabel_configs:
      - source_labels: [__address__]
        target_label: __param_target
      - source_labels: [__param_target]
        target_label: instance
      - target_label: __address__
        replacement: blackbox:9115
```

And the respective Blackbox exporter modules rules in [blackbox.yml](./blackbox-exporter/blackbox.yml):

```YAML
modules:
  http_2xx:
    prober: http
    timeout: 15s
    http:
      method: GET
      valid_http_versions: ["HTTP/1.1", "HTTP/2"]
      valid_status_codes: []
      preferred_ip_protocol: "ip4"
      # no_follow_redirects: true
      tls_config:
        insecure_skip_verify: xxx
        # insecure_skip_verify true/false is provided in blackbox.env file ,based on environment
```

In the working demo example, Blackbox returns correctly ,status codes: `200` for Wordpress and `401` (Unauthorized) for Adminer, since Adminer is protected with basic authorization via Caddy loadbalancer.

---

## Setup

### Procedure Overview

In order to build and deploy the stack, choose an environment (development or production) ,build images with the initial build scripts as shown below,make changes to options provided in .env files in each environment and deploy the stack (development) or stacks (production - wordpress & monitoring) accordingly.

### Environment Setup & Secrets

Before the images are built, you need to perform some initial steps to set up docker registry (CE edition) and provide secrets for your application. Secrets are essential since they are a more secure way to provide sensitive data to configuration files ,rather than using environment variables or plain text values inside configuration files.

## Grant docker control to non-root users

- Verify docker group and add user to docker group:

```Shell
sudo cat /etc/group
sudo gpasswd -a username docker
```

- Logout-login to reset usercache

Since we are working with Docker Swarm and Stack Deployments it is imperative to setup a Docker Registry to pull and push images from/to.

## Initialize the Swarm

```Shell
docker swarm init
```

## Setting up Docker Registry

- Create a self-signed certificate pair, for domain registry.dream for Docker Registry:

```Shell
sudo openssl req -new -x509 -sha256 -days 365 -nodes -out /etc/ssl/certs/registry.dream.crt -keyout /etc/ssl/private/registry.dream.key
```

- Provide answers to the certificate interactive process.After tha ,on /etc/hosts add the following line (assume that we set registry at the same host ,hosting docker-ce):

```Shell
127.0.0.1 registry.dream
```

- Clone this repository on a /home/username folder

```Shell
git clone https://github.com/dreamPathsProjekt/docker_deployment_example
```

We setup the registry as a normal Docker Service using the following yml [compose file](registry.yml), and mount folders on host: /etc/ssl/certs (certificate) & /etc/ssl/private (private key) to /certs & /private on the container respectively.

```YAML
version: "3.3"

services:
  registry:
    restart: always
    image: registry:2
    ports:
      - 5001:5000
    environment:
      REGISTRY_HTTP_TLS_CERTIFICATE: /certs/registry.dream.crt
      REGISTRY_HTTP_TLS_KEY: /private/registry.dream.key
    volumes:
      - /etc/ssl/certs:/certs
      - /etc/ssl/private:/private
```

- Deploy the registry service:

```Shell
docker stack deploy -c registry.yml registry
```

- The registry is listening on registry.dream:5001. To test that it is working correctly run the following commands:

```Shell
curl -v registry.dream:5001/v2/

# pull a test image from DockerHub, tag with registry domain, push and pull locally again.
docker pull hello-world
docker tag hello-world registry.dream:5001/hello-world
docker push registry.dream:5001/hello-world
docker pull registry.dream:5001/hello-world
```

## Create Docker Secrets

On Docker Host:

```bash
# caddy loadbalancer user & password
echo 'xxxxx' | docker secret create lb_admin_user -
echo 'xxxxx' | docker secret create lb_admin_pass -

# wordpress database password
echo 'xxxxx' | docker secret create wp_db_pass -

# mariadb root password
echo 'xxxxx' | docker secret create db_root_pass -
```

In this [live demo example](http://35.189.200.49/) (demo purposes):

- lb_admin_user: admin
- lb_admin_pass: pass!word
- wp_db_pass: wordpre5s, for user: wp, database: wp_dbase
- db_root_pass: r00t

## Make main Build scripts executable

In order to run either the __development environment__ stack or the __production environment__ stack you need to first run the following commands:

```Shell
# cd to the cloned repository directory
cd docker_deployment_example

chmod a+x build-all-dev.sh
chmod a+x build-all-prod.sh
```

## Build the required images

- Syntax:

```Shell
# Inside repository directory

# ./build-all-dev.sh <version>
# or
# ./build-all-prod.sh <version>
#  where <version> is the desired build version for all images
```

- Example for __development environment:__

```Shell
./build-all-dev.sh 0.1
```

- Example for __production environment:__

```Shell
./build-all-prod.sh 1.0
```

Wait for all images to build (production takes some significant time as it builds the monitoring stack also)

## Deploy the Stack

- Development:

```Shell
# Creates stack with name wpstack in swarm
docker stack deploy -c development/wp_mariadb_admin.yml wpstack
```

- Production:

```Shell
# Creates stack with name wpstack in swarm
docker stack deploy -c production/wp_mariadb_admin.yml wpstack

# Watch services to be up, and wait for caddy loadbalancer healthchecks
watch -n 1 -d docker service ls

# Output should look like this
xl5ktu1gmswq        wpstack_adminer               replicated          1/1                 hardware/adminer:latest
otwko13f7v8e        wpstack_caddy                 replicated          1/1                 registry.dream:5001/caddy:latest              *:80->80/tcp,*:8888->8
888/tcp
wcid84wpytla        wpstack_mariadb               replicated          1/1                 mariadb:10.3
wi0hbi0f31b9        wpstack_wordpress             replicated          1/1                 wordpress:latest


# Deploy monitoring stack with name monitoring
docker stack deploy -c production/monitoring-stack.yml monitoring

# Watch services to be up, and wait for caddy_monitoring loadbalancer healthchecks
watch -n 1 -d docker service ls

# Output should look like this
rrzsmnqt7x90        monitoring_blackbox           replicated          1/1                 registry.dream:5001/blackbox:latest
ip0imcbr6w41        monitoring_caddy_monitoring   replicated          1/1                 registry.dream:5001/caddy_monitoring:latest   *:3000->3000/tcp,*:9090->9090/tcp,*:9115->9115/tcp
t244e068sws9        monitoring_docker-exporter    replicated          1/1                 registry.dream:5001/docker-exporter:latest
c96eqzyiq7ks        monitoring_grafana            replicated          1/1                 registry.dream:5001/grafana:latest
jd6xq0v9g7i5        monitoring_prometheus         replicated          1/1                 prom/prometheus:v2.0.0

```

- If you are hosting a Linux Vm or cluster on a Cloud Provider (GCP, AWS) please make sure that the following firewall rules are applied for http:

- - Development: Allow ports tcp:80 (Wordpress), tcp:8888 (Adminer)
- - Production: Allow ports tcp:80 (Wordpress), tcp:8888 (Adminer), tcp:3000 (Grafana), tcp:9090 (Prometheus), tcp:9115 (Blackbox Exporter)

- For the sake of simplicity the values in environment files ( .env) ,in each folder are the same. However if you wish to change environment variables or secrets, you don't need to rebuild all images, just apply the changes and stack deploy (Updates services).

## Credentials for Live Demo

__Live Demo__ (production environment):

- [Wordpress](http://35.189.200.49/)
- [Adminer admin panel for MariaDB](http://35.189.200.49:8888) *needs credentials*
- [Grafana Monitoring](http://35.189.200.49:3000) *needs credentials*
- [Prometheus](http://35.189.200.49:9090) *needs credentials*

Adminer, Grafana, Prometheus loadbalancer credentials: see above secrets lb_admin_user, lb_admin_pass

- Admin Wordpress Account:
- - user:admin
- - password:admin
- - email:admin@domain.test

- Monitoring Stack, Grafana
- - admin user: admin
- - password: pass!word

- Grafana Read-Only User
- - user: support
- - password: support
