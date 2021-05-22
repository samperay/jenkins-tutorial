#!/bin/bash

echo simple-java-maven-app > /tmp/.auth
echo $BUILD_TAG >>/tmp/.auth
echo $PASS >>/tmp/.auth


scp /tmp/.auth produser@prodserver:/tmp/.auth
scp ./jenkins/deploy/publish.sh produser@prodserver:/tmp/publish.sh
ssh produser@prodserver "/tmp/publish.sh"
