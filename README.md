# jenkins-tutorial

## Jenkins

### Directory Structure

jenkins-tutorial
├── centos7
│   ├── Dockerfile
│   ├── remote-key
│   └── remote-key.pub
├── jenkins_data
│   └── docker-compose.yml
└── README.md


### Infra Setup 

**jenkins-tutorial** is the parent directory and you would create **jenkins-data** which is mounted to the container and would be installed with Jenkins
you would first be required to download the image **docker pull jenkins/jenkins** 

Then you would be writing up the **docker-compose** for the jenkins container & would build the container with required ports **8080-8080** and volumes mapped. 
Once your installations are over, all your jenkins data is being mapped to **jenkins_data** folder. 

```
services:
  jenkins:
    container_name: jenkins
    image: jenkins/jenkins
    ports:
      - "8080:8080"
    volumes:
      - $PWD/jenkins_home:/var/jenkins_home
    networks:
      - net
```

### Jenkins for SSH connectivity for remote host

In order to do this, we would be required a set a new Virtual machine or a new docker container. 
Hence we would create a new docker container to SSH and execute from Jenkins. 

**centos7** would be the docker container and works as a remote host, hence create a new folder with **Dockerfile** which installs a new centos machine with SSH being enabled. 
create a pair of public/private keys, and update **docker-compose.yml** to build the new remote_host in the same network as jenkins **net**

```
  remote_host:
    container_name: remote-host
    image: remote-host
    build:
      context: centos7
    networks:
      - net
```

Now, you login to jenkins container and try to SSH to remote host, you would be able to connect to the **remote-host** container with password. 
```
jenkins@1a93d438c071:~$ ssh remote_user@remote-host
The authenticity of host 'remote-host (172.18.0.2)' can't be established.
ECDSA key fingerprint is SHA256:a8xE286YL6MoUg50rd3giV7De6vs74WcFKGiNeE5Khk.
Are you sure you want to continue connecting (yes/no)? yes
Warning: Permanently added 'remote-host' (ECDSA) to the list of known hosts.
remote_user@remote-host's password:
Last login: Wed May 19 05:33:06 2021 from jenkins.jenkins-data_net
[remote_user@ab606f56c931 ~]$
```

Copy the private key of the **remote-host** container to **jenkins** container and using the private key you would be able to connect without password. 

```
cd centos7
docker cp remote-key jenkins:/var/jenkins_home

jenkins@1a93d438c071:~$ ssh -i remote-key remote_user@remote-host
Last login: Wed May 19 05:37:50 2021 from jenkins.jenkins-data_net
[remote_user@ab606f56c931 ~]$
```

Now, create a new project and enable SSH plugin and you can create build steps to run to remote machine/container. 

### Jenkins for ansible plays && execute ansible playbooks

Now, you have an **jenkins** container, but you don't have an ansible installed.. Hence we would create a new directory **jenkins-ansible** which uses the **jenkins/jenkins** as an image and would install ansible using pip modules. 

```
FROM jenkins/jenkins

USER root

RUN apt-get update && apt-get install python3-pip -y && \
    pip3 install ansible --upgrade

USER jenkins
```

When you now login to your jenkins container, you would have ansible binary installed. You, would now like to run the playbook on the host **remote-host** so you need to configure the ansible inventory. since we already know that the jenkins host **jenkins_home** is mounted on the **/var/jenkins_home** of the container, I would configure the host and inventory detail of the remote_host.

```
mkdir jenkins_home/ansible
docker cp remote-key jenkins:/var/jenkins_home/ansible
docker cp remote-key.pub jenkins:/var/jenkins_home/ansible
docker cp hosts jenkins:/var/jenkins_home/ansible
```

Write your playbooks in the folder **/var/jenkins_home/ansible** and try to execute from the jenkins container by specifying the inventory file(hosts) and see if its connecting to the r
emote_host.

```
---
- hosts: test1
  tasks:
    - shell: echo "Hello world" > /tmp/ansible.txt
```

```
ansible-playbook -i hosts play.yml
```

Now, you would install plugins for **ansible** and **ansicolor** from the Jenkins and restart. Create a new project and provide the playbook path as **/var/jenkins_home/ansible/play.yml** and host file(inventory) as **/var/jenkins_home/ansible/hosts**. checkout the color output and you can parametrize(MSG) the playbooks if you need to. 

```
- hosts: test1
  tasks:
    - debug:
        msg: "{{ MSG }}" 
```

### Create Database and tables from Mysql 

Login to your **db** container and create database, tables and insert values to it. 

```
[jenkins@localhost ~]$ docker exec -it db bash
root@bc4ba9246f24:/# mysql -u root -p
Enter password:
Welcome to the MySQL monitor.  Commands end with ; or \g.
Your MySQL connection id is 2
Server version: 5.7.34 MySQL Community Server (GPL)

Copyright (c) 2000, 2021, Oracle and/or its affiliates.

Oracle is a registered trademark of Oracle Corporation and/or its
affiliates. Other names may be trademarks of their respective
owners.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

mysql> show databases;
+--------------------+
| Database           |
+--------------------+
| information_schema |
| mysql              |
| performance_schema |
| sys                |
+--------------------+
4 rows in set (0.14 sec)

mysql> create database people;
Query OK, 1 row affected (0.00 sec)

mysql> use people;
Database changed
mysql> create table register(id int(3), name varchar(50), lastname varchar(50), age int(3));
Query OK, 0 rows affected (0.05 sec)
mysql>

mysql> desc register;
+----------+-------------+------+-----+---------+-------+
| Field    | Type        | Null | Key | Default | Extra |
+----------+-------------+------+-----+---------+-------+
| id       | int(3)      | YES  |     | NULL    |       |
| name     | varchar(50) | YES  |     | NULL    |       |
| lastname | varchar(50) | YES  |     | NULL    |       |
| age      | int(3)      | YES  |     | NULL    |       |
+----------+-------------+------+-----+---------+-------+
4 rows in set (0.00 sec)
```

insert some dummy data using the bash scripts, which are in **jenkins-ansible**
copy those **people.txt** and **put.sh** into the db container /tmp directory and execute to populate to databases.

```
cd jenkins-ansible
docker cp people.txt db:/tmp
docker cp put.sh db:/tmp
```

Once you have executed, login to the db container and check for the data. 

```
mysql -u root -p1234
show databases;
use people;
select * from register;
```

### Using Jenkins to display people database using webserver/php

We would be required to create a new webserver which displays based on the age of the people. 

```
  web:
    container_name: web
    image: ansible-web
    build:
      context: jenkins_ansible/web
    ports:
      - "80:80"
    networks:
      - net
```

Build and create container for web

```
docker-compose build
docker-compose up -d 
```

playbooks are copied to **/var/jenkins_home/ansible** and we would be required to configure a new project in the jenkins job which is parameterized in the playbook

```
docker cp people.yml jenkins:/var/jenkins_home/ansible
docker cp table.j2 jenkins:/var/jenkins_home/ansible
```

```
$sql = "SELECT id, name, lastname, age FROM register {% if PEOPLE_AGE is defined %} where age = {{ PEOPLE_AGE }} {% endif %}";
```

The above one would be asked to select the age from the jenkins machine and based on which the template for the config would be run from ansible to be placed in the remote host in the **/var/www/html/index.php** page which you can display using the IP http://jenkins.local 

### Jenkins Security

You can create a role **dev** and assign the privileges to users who can read/write etc 
You should always provide them with the read overall along with other read access for other job. 

You could also provide them with project access so that they could only use that role. 

### Jenins with Maven 

Install the plugins for **Maven Integration** which would install **git** by default. 
try to configure your project using an sample application for Maven **https://github.com/jenkins-docs/simple-java-maven-app.git** and run. 
This also includes the **Jenkins** file which can be used to configure the pipeline. 

### Creation of your own gitlab server 

Create your own gitlab server
```
  git:
    container_name: git-server
    image: 'gitlab/gitlab-ce:latest'
    hostname: 'gitlab.example.com'
    ports:
      - '8090:80'
    volumes:
      - '/srv/gitlab/config:/etc/gitlab'
      - '/srv/gitlab/logs:/var/log/gitlab'
      - '/srv/gitlab/data:/var/opt/gitlab'
    networks:
      - net
```

Make an entry **gitlab.example.com** in your /etc/hosts and then once the gitlab server is up, try to run using **htt://gitlab.example.com:8090** and create project and add repository and then create user and add them to the project. 

On the Jenkins side, manage the add the credentials of the user to Jenkins and then change the settings of the URL in the Jenkins project which you have created. update it to **http://git:80** using the credentials. Now you can run the build which will connect to gitlab server and would be running the builds. 


### Create Docker in Jenkins Container
yes, we would be creating Docker in the jenkins container. 



### Jenkins Maven/Docker Builds


```
docker run --rm -it -v $PWD/java-app:/app -v /root/.m2:/root/.m2 -w /app maven:3.6.1-jdk-8-alpine sh
```



