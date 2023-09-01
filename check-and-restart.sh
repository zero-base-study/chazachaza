#!/bin/bash

CONTAINER_RUNNING=$(docker ps -q -f name=${PROJECT_NAME})

if [ -z "$CONTAINER_RUNNING" ]; then
        # pull the latest image
        docker pull ${HYOBIN_DOCKER_HUB_USER_NAME}/${PROJECT_NAME}:${PROJECT_VERSION}

        # remove the existing container if any
        docker rm -f ${PROJECT_NAME}

        # start a new container
        docker run -d --name ${PROJECT_NAME} -p 8080:8080 ${HYOBIN_DOCKER_HUB_USER_NAME}/${PROJECT_NAME}:${PROJECT_VERSION}

        echo "Container restarted successfully."
else
        echo "Container is already running."
fi