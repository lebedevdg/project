#!/bin/bash
set -e

RUNNER_COMMAND=${1:-up}

if [ "$RUNNER_COMMAND" = "up" ]
then
  GITLAB_CI_URL=${2:-$GITLAB_CI_URL}
  GITLAB_CI_URL=${GITLAB_CI_URL:-http://127.0.0.1}
  echo "GITLAB_CI_URL=$GITLAB_CI_URL"

  GITLAB_CI_TOKEN=${3:-$GITLAB_CI_TOKEN}
  GITLAB_CI_TOKEN=${GITLAB_CI_TOKEN:-A1b2C3d4E5f6G7h8I9j0}
  echo "GITLAB_CI_TOKEN=$GITLAB_CI_TOKEN"

  GITLAB_CI_RUNNER_NAME=${4:-$GITLAB_CI_RUNNER_NAME}
  GITLAB_CI_RUNNER_NAME=${GITLAB_CI_RUNNER_NAME:-gitlab-runner}

  echo "Starting runner $GITLAB_CI_RUNNER_NAME ..."
  # запускаем runner:
  docker run -d --name $GITLAB_CI_RUNNER_NAME --restart always \
    -v /srv/${GITLAB_CI_RUNNER_NAME}/config:/etc/gitlab-runner \
    -v /var/run/docker.sock:/var/run/docker.sock \
    gitlab/gitlab-runner:latest

  echo "Registering runner $GITLAB_CI_RUNNER_NAME ..."
  # регистрируем запущенный runner:
  docker exec -it $GITLAB_CI_RUNNER_NAME gitlab-runner register \
    --name $GITLAB_CI_RUNNER_NAME \
    --run-untagged \
    --locked=false \
    --non-interactive \
    --url $GITLAB_CI_URL \
    --registration-token $GITLAB_CI_TOKEN \
    --tag-list "linux,xenial,ubuntu,docker" \
    --executor docker \
    --docker-image "alpine:latest" \
    --docker-privileged \
    --docker-volumes "docker-certs-client:/certs/client" \
    --env "DOCKER_DRIVER=overlay2" \
    --env "DOCKER_TLS_CERTDIR=/certs"

  exit 0
fi

if [ "$RUNNER_COMMAND" = "down" ]
then
  GITLAB_CI_RUNNER_NAME=${2:-$GITLAB_CI_RUNNER_NAME}
  GITLAB_CI_RUNNER_NAME=${GITLAB_CI_RUNNER_NAME:-gitlab-runner}

  echo "Unregistering runner $GITLAB_CI_RUNNER_NAME ..."
  # разрегистрируем runner:
  docker exec -it $GITLAB_CI_RUNNER_NAME gitlab-runner unregister \
    --name $GITLAB_CI_RUNNER_NAME

  echo "Stopping runner $GITLAB_CI_RUNNER_NAME ..."
  docker container rm --force $GITLAB_CI_RUNNER_NAME

  exit 0
fi

echo "Unknown runner command: $RUNNER_COMMAND, nothing to do"
