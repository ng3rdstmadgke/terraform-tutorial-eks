#!/bin/bash

mkdir -p ~/.ssh ~/.aws
DOCKER_NETWORK=br-terraform-tutorial-eks-${USER}
NETWORK_EXISTS=$(docker network ls --filter name=$DOCKER_NETWORK --format '{{.Name}}')

if [ -z "$NETWORK_EXISTS" ]; then
  docker network create $DOCKER_NETWORK
fi