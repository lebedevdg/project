#!/bin/sh

PROJECTNAME=${1:-$PROJECTNAME}
PROJECTNAME=${PROJECTNAME:-user}

echo `git show --format="%h" HEAD | head -1` > build_info.txt
echo `git rev-parse --abbrev-ref HEAD` >> build_info.txt

docker build -f ./Dockerfile -t $PROJECTNAME/robot ./
