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

## Grant docker control to non-root users

- Verify docker group and add user to docker group:

```Shell
sudo cat /etc/group
sudo gpasswd -a username docker
```

- Logout-login to reset usercache

Since we are working with Docker Swarm and Stack Deployments it is imperative to setup a Docker Registry to pull and push images from/to.

## Setting up Docker Registry

- Create a self-signed certificate pair, for domain registry.dream for Docker Registry:

```Shell
sudo openssl req -new -x509 -sha256 -days 365 -nodes -out /etc/ssl/certs/registry.dream.crt -keyout /etc/ssl/private/registry.dream.key
```

- On /etc/hosts add the following line (assume that we set registry at the same host ,hosting docker-ce):

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

- Deploy the service:

```Shell
docker stack deploy -c registry.yml registry
```

- The registry is listening on registry.dream:5001. To test that it is working correctly we run the following commands:

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

In this example (demo purposes):

- lb_admin_user: admin
- lb_admin_pass: pass!word
- wp_db_pass: wordpre5s, for user: wp, database: wp_dbase
- db_root_pass: r00t

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