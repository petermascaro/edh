EDH Stack
=========

Static Nginx webpage with logging to Elasticsearch fronted by a secured Kibana service.

Requirements
------------

- AWS m3.large instance with a 50GB filesystem
- Deploy and configure Nginx, Kibana, and Elasticsearch Docker containers
- Nginx serves static webpage from external Docker volume
- Nginx logs are forwarded to Elasticsearch
- Kibana is secured with username/password
- Elasticsearch kept private

Design
------

- application stack encapsulated in a dedicated VPC
- secure Kibana using Nginx
- use Terraform to build VPC infrastructure

  - VPC, subnet, internet gateway, default route, key pair, security group and EC2 instance

    - apply security updates at boot with userdata configuration
    - install Ansible

  - push an Ansible playbook to the provisioned EC2 and execute locally

- use Ansible to build and configure service containers

  - install and start Docker
  - prime /data directory with static web content and custom service configuration
  - provision Elasticsearch container
  - build Fluentd custom Docker image to use as the Nginx container log driver

    - Fluentd will forward logs to Elasticsearch using the "fluentd-plugin-elasticsearch" plugin

  - provision Fluentd container from custom image linking Elasticsearch

    - mount external directory as configuration and log destination

  - provision Kibana container linking Elasticsearch
  - provision Nginx container linking Kibana

    - mount /data directory as a volume for static web content
    - proxy Kibana and configure authentication

- Nginx endpoint on DOCKER_HOST:80, Kibana endpoint on DOCKER_HOST:5601

Usage
-----

Default Terraform variables values assume the of existence of "~/.ssh/id_rsa" and "~/.ssh/id_rsa.pub".

These can be overridden using the following environment variables:

```
TF_VAR_ssh_private_key_path
TF_VAR_ssh_public_key_path
```

Clone the following repository and run Terrraform from the top level directory:

```
$ git clone https://github.com/petermascaro/edh.git
$ cd ./edh
$ terraform apply
```

Improvements
------------

- Packer the Docker host to speed deployment
- front Nginx (port 80) and Kibana (5601) with dedicated ELBs or attach and EIP to Docker instance in order to preserve endpoints during updates
- build out the "edh-stack" Ansible role into several separate roles for each service
- make use of Jinga templates throughout Ansible roles
