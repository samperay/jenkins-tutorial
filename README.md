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


