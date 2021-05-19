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
