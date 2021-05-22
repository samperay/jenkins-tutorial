#!/bin/bash 

echo "**********************"
echo "Testing mvn package"
echo "**********************"

docker run --rm -it -v $PWD/java-app:/app -v /root/.m2:/root/.m2 -w /app maven:3.6.1-jdk-8-alpine "$@"
