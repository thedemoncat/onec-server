#!/bin/bash

if [ -f ".env" ]; then
    export $(grep -v '^#' .env | xargs)
fi

IMAGE_NAME=${1:-"ghcr.io/thedemoncat/onec-server"}

env=()
while IFS= read -r line || [[ "$line" ]]; do
  env+=("$line")
done < ONEC_VERSION

for item in ${env[*]}
do
    docker build -t $IMAGE_NAME:"$item" \
        --build-arg ONEC_USERNAME="$ONEC_USERNAME" \
        --build-arg ONEC_PASSWORD="$ONEC_PASSWORD"  \
        --build-arg ONEC_VERSION="$item" .
done
