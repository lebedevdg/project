#!/bin/bash
set -evx

GITLAB_CI_URL=${1:-$GITLAB_CI_URL}
GITLAB_CI_URL=${GITLAB_CI_URL:-http://127.0.0.1}

GITLAB_CI_TOKEN=${2:-$GITLAB_CI_TOKEN}
GITLAB_CI_TOKEN=${GITLAB_CI_TOKEN:-A1b2C3d4E5f6G7h8I9j0}

GITLAB_CI_RUNNER_NAME=${3:-$GITLAB_CI_RUNNER_NAME}
GITLAB_CI_RUNNER_NAME=${GITLAB_CI_RUNNER_NAME:-gitlab-runner}

# запускаем runner:
docker run -d --name $GITLAB_CI_RUNNER_NAME --restart always \
  -v /srv/${GITLAB_CI_RUNNER_NAME}/config:/etc/gitlab-runner \
  -v /var/run/docker.sock:/var/run/docker.sock \
  gitlab/gitlab-runner:latest

# регистрируем запущенный runner:
docker exec -it $GITLAB_CI_RUNNER_NAME gitlab-runner register \
  --run-untagged \
  --locked=false \
  --non-interactive \
  --url $GITLAB_CI_URL \
  --registration-token $GITLAB_CI_TOKEN \
  --description "docker-runner" \
  --tag-list "linux,xenial,ubuntu,docker" \
  --executor docker \
  --docker-image "alpine:latest" \
  --docker-privileged \
  --docker-volumes "docker-certs-client:/certs/client" \
  --env "DOCKER_DRIVER=overlay2" \
  --env "DOCKER_TLS_CERTDIR=/certs"
