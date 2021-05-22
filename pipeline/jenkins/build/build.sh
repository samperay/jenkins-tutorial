#!/bin/bash

# copy arftifacts into the app to build the container
cp -f java-app/target/*.jar jenkins/build/

echo "********************************************"
echo "**** Building Docker image ****"
echo "********************************************"

cd jenkins/build/ && docker-compose build --no-cache
