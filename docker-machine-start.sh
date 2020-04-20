#!/bin/bash

echo "Enter machine name"

#read name

name=${1:-docker-host}
#echo $name

gproject=docker3-273507

docker-machine create --driver google --google-machine-image https://www.googleapis.com/compute/v1/projects/ubuntu-os-cloud/global/images/family/ubuntu-1604-lts \
--google-machine-type n1-standard-2 --google-project $gproject --google-zone europe-north1-b \
--google-open-port 9292/tcp --google-open-port 9090/tcp --google-open-port 8080/tcp --google-open-port 3000/tcp --google-open-port 8000/tcp --google-open-port 8001/tcp --google-open-port 15672/tcp $name

eval $(docker-machine env $name)

##eval "$(docker-machine env -u)"
