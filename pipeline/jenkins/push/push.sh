#!/bin/bash 

echo "**************************"
echo "*** pushing image ********"
echo "**************************"


IMAGE=simple-java-maven-app

echo "*** docker hub logging in ***"
docker login -u sunlnx -p $PASS
echo "*** tagging image ***"
docker tag $IMAGE:$BUILD_TAG sunlnx/$IMAGE:$BUILD_TAG
echo "*** pushing image to docker hub***"
docker push sunlnx/$IMAGE:$BUILD_TAG
