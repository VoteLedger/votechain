#!/usr/bin/env bash

DEVCONTAINER_NAME=votechain-dev

# Check if the devcontainer is running
if [ "$(docker ps -q -f name=$DEVCONTAINER_NAME)" ]; then
  # Stop the devcontainer
  docker stop $DEVCONTAINER_NAME 1>/dev/null
  # Remove the devcontainer
  docker rm $DEVCONTAINER_NAME 1>/dev/null
fi
