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

[Grafana Example Snapshot](https://snapshot.raintank.io/dashboard/snapshot/WtLG0EcoRG47j2gAoaDMo4UwV62Cr80I)

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

## Benefits - Drawbacks of using Docker & Docker Swarm for Orchestration

Docker has arguably been a game changer, in the way we deploy applications at a massive scale , setup development environments and/or deliver a fast desired CI/CD pipeline environment.

### Advantages

- __Reusability of built images.__
  - You can setup different environments from development to production and leverage the use of containers to easily and quickly deploy scalable code that is first tested ,has passed the phase of acceptance testing (through a User Acceptance Testing environment) and delivered to production using the same builds/release version.
  - It is a very handy feature to be able to maintain different versions of an API or releases (stable/experimental) and thus keeping your existing userbase and backwards compatibility.
  - Avoids Vendor Lock-in.Migrating a stack to a different cloud provider requires almost single digit days' time ,rather than a painfully slow cycle of weeks and months.

- __Containerisation means separation of concerns.__
  - By using Docker images we can setup different underlying operating systems, language and/or library versions on the same system.
  - The fact that docker images are immutable, self contained and (at least in theory) sandboxed from one another ,means an endless stream of architectural choices ,for development and operations teams ,to setup and easily maintain testing, bugtracking, future release environments etc. without the pain points of having to setup conflicting tools or libraries.
  - It is also a technology that plays extremely nice with the whole notion of __microservices architecture__ because of the above.

- __Easy setup of unified and replicable development environments (Cattle vs Pets).__
  - It is a quite known joke, that the phrase "it works on my machine" is no longer an acceptable answer. The cost and operational complexity of provisioning and maintaining manually ,different development environments, is so big that Docker looks like a monopoly in this area.
  - Having replicable dev and testing environments means scalability for development teams also. It also means that if different environments use the same images, it reduces the pain points of migration from Dev to production and possible bugs introduced by the underlying application host.

- __Scalability - High Availability.__
  - Scalability to multiple containers and nodes is just a single command away using Docker Swarm `docker service scale my_service=...`.
  - Efficiently utilize machine resources and storage by using multiple containers on each VM ,instead of wasting money and resources by maintaining a VM per each component of your application/project
  - Although developers have to account for a distributed model (see also disadvantages) and plan ahead for services that span in multiple instances, the operational cost and complexity to scale a project is reduced.
  - Rolling updates are also faster and more secure, since you can easily rollback to stable versions in case of failure.
  - In case of a node failure, Swarm orchestration provides a way to balance the container load to remaining nodes in a swarm, at least temporarily until the problem is resolved.
  - Also by using clusters of odd number of nodes (3, 5 etc.), which has to be translated to an even number of managers as a best practice, you reduce the possibility of __single point of failure.__ Even if a Leader goes down, another manager is automatically elected Leader and cluster Quorom is maintained.

- __Much easier and user-friendly to setup, to alternative containerisation technologies__
  - CoreOS __rkt__, Canonical's __LXD__ and other containerisation alternatives are substantially more cumbersome to setup and maintain.
  - The use cases, pre-built base images and community support and documentation around Docker is at least twice as large (if not more).DockerHub has grown almost as popular as GitHub.
  - Kubernetes' __cri-o__ project is still in infancy and quite an uknown factor for the future.

- __Orchestration with Docker Swarm is as user-friendly as Docker itself and utilizes the same underlying principles__
  - By sharing the same technology principles between the build phase and orchestration, means that operations teams can utilize the same existing knowledge on multiple levels

- __CI / CD principles achieved.__
  - As mentioned above, using Docker images (with or without Swarm orchestration) can enhance your ability and simplicity of your automation pipelines, and shorten the cycle between each iteration.
  - Docker enhances the speed with which you can deliver bugfixes and new features.

- __Docker Swarm provides High-Level Abstractions__
  - By abstracting away the underlying networking details, using namespaces inside a single stack, rather than ip addresses, the use of persistence with mounting volumes, Docker registry & trusted Registry (EE version), attachable networks (services listening on two or more overlay networks) and Secrets are all usable, high level features that save time and reduce the low-level complexity needed otherwise, to provision all those configurations.
  - Minimizing human error with the help of the above high-level abstractions, leads to robustness.

## Disadvantages

- __Move development fast and break things.__
  - One of the biggest drawbacks of Docker, and fears of Operations & IT teams is the fact that the Docker development team moves too fast with new features and at times has neglected backwards compatibility and bug fixes of older versions. The forks of Docker-engine to CE and EE and the Moby project has been met with mixed feelings as to how Docker plans to move ahead.
  - Traditionally IT teams have longer update cycles compared to Dev teams ,in search of stability. Although Docker promises fixed stable and experimental release channel cycles for the commercial EE version, it is still uknown how, bugs introduced to newer releases will affect production systems and at what scale.

- __Compatibility issues with the CentOS/RHEL filesystems.__
  - In earlier versions of Docker there were various underlying filesystem problems, rendering Docker unusable to a wide array of Linux distributions (especially affecting Linux Kernels before 4.4). Although the Docker team and certain Linux distros(like CentOS) are moving towards fixing those compatibility issues (recent Docker updates have confirmed increased support), it is still the safest choice to use Ubuntu 16+ systems and strongly avoid kernels in the range of 3.* versions ,to host Docker.
  - Unfortunately IT teams have been hesitant and resistive to base production servers on Ubuntu and prefer el (enterprise Linux e.g. RHEL) based distros. This can be a point of friction between IT, Operations & Development teams across an organization and each side could have reasonable concerns that could result in a stalemate situation.

- __Docker Swarm provides High-Level Abstractions. This results to Cryptic Logging & Troubleshooting.__
  - Although containers and their abstraction logic of Swarm orchestration is a wonder when things go right, it is a major pain point when things go wrong.Potentially this could lead to an inability to find the root cause of many problems and bugs ,as the underlying configurations have been abstracted away.
  - Debugging and logging applications running on a Swarm cluster is riddled with hidden functionalities and decreased visibility. It is also a well known feature (not a bug) that you cannot view container specific logs of all containers (those running on workers) from a manager or leader. This leads to a back & forth process of checking logs between managers and workers and if you have reduced access to worker nodes (e.g. in the case of a jumphost server that is restricted to connect to a specific manager) your only solution is to view service-level logs that can be misleading ,in the use case that you want to view which specific container is reading/writing to what source etc.
  - High-level abstractions of networking with Docker Swarm does not play nice with specific technologies or tools and can lead to untraceable or difficult to trace connectivity problems. Furthermore until recently, there were versions of Docker Swarm that had problematic behaviour with regards to Docker specific network types (ingress, overlay).

- __Developers have to make a paradigm shift to a distributed model.__
  - Although Docker has solved numerous problems of Dev teams, it is still not overly clear or easily translatable to many developers, that they have to plan ahead (even in early protorype phases) and architect application structures that encompass their services running at scale with a specific immutable model. This leads to raising development and design to unwanted complexity levels ,early on and can potentially lead to quick and dirty duck tape solutions in a codebase. Collecting technical debt should be avoidable at all costs.
  - Immutable infrastructure means that you cannot always maintain state programmatically. Although the recent rise in functional programming goes along with the Docker philosophy of destroying containers and spawning new instances from scratch, not all dev teams follow the functional guidelines in regards to state management. Most enterprise dev teams usually are built around Object Oriented principles (Java, C# and C++ is still king at enterprise level) and older ways of thinking about mutable state and coupling data with functionality at the same class level.

- __Immutability vs databases. Persistence and safety of Data__
  - Managing data and databases in immutable containers is not always the optimal solution. Although persistence at Vm or bare-metal level can be achieved through the use of mounted volumes, if the node or Vm fails persistence fails along. In a Cloud environment (e.g. GC, AWS, Azure) running databases inside Vm ephemeral storage is best avoided. Although solutions to this problem have been provided by Cloud providers (such as Persistent Disks in Google cloud , S3 Buckets in AWS etc.), sometimes the best solution is to store your data and keep multiple backups of data and schema instances, to a separate physical or dedicated cluster for safety and security reasons.

- __The Container Security Landscape is still a relatively uknown territory.__
  - __DevSecOps__ has been a trending catchphrase for a reason. The maturity and ability to document, reproduce and patch security issues with containers and container orchestration in mind ,has not reached the levels of traditional server security. Although this can be controversial, but my opinion is that the Docker development community has still not taken security into serious account yet.

- __Docker Swarm specific issues and bugs__
  - Although certain bugs and issues that plagued earlier versions of Docker Swarm are slowly being patched, there is a focus amongst the community on new features being released, rather than patching issues and delivering a mature ,safe stable release channel. Maturity wise, Kubernetes looks like a safer orchestration (albeit more complex) alternative at this point in time. Also running Swarm in a cluster-as-a-service fashion (e.g. in AWS ECS clusters) through a Cloud Provider is another viable scalable solution to escape the pain of manually upgrading, maintaining, scaling and troubleshooting host Vms, by effectively delegating these tasks (or blame if things go wrong) to the Cloud provider service.