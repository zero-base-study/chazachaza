#!/bin/bash

# 1. env variable
echo "Project Name: $PROJECT_NAME"
echo "Project Version: $PROJECT_VERSION"
echo "1. Env variable setting complete"

# 2. cron delete
touch crontab_delete
crontab crontab_delete
rm crontab_delete
echo "2. Cron delete complete"

# 3. remove existing container if it exists
echo "Removing existing container if it exists..."
docker rm -f ${PROJECT_NAME}
echo "3. Existing container removal complete"

# 4. start Docker container
DOCKER_IMAGE_TAG="${HYOBIN_DOCKER_HUB_USER_NAME}/${PROJECT_NAME}:${PROJECT_VERSION}"
echo "Starting Docker container with image tag..."
docker run -d \
    --name $PROJECT_NAME \
    --network=docker-network \
    -p 8080:8080 \
    -e SPRING_DATASOURCE_URL=jdbc:mysql://mysql-container:3306/${PROJECT_NAME} \
    -e SPRING_DATASOURCE_USERNAME=$HYOBIN_HYOBIN_DB_USER_NAME \
    -e SPRING_DATASOURCE_PASSWORD=$HYOBIN_HYOBIN_DB_USER_PASSWORD \
    $DOCKER_IMAGE_TAG > ${HOME}/log.out 2> ${HOME}/err.out
echo "4. Starting server complete"

# 5. cron registration
echo "Registering cron job..."
touch crontab_new
echo "* * * * * ${HOME}/check-and-restart.sh" 1>>crontab_new
crontab crontab_new
rm crontab_new
echo "5. Cron registration complete"
