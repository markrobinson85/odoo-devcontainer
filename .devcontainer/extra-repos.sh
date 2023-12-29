#!/bin/bash

echo "Cloning extra repositories if specified..."
## ----------------------------------
## Use this script to add additional repos to the container.
## You can use P1, P2, P3, etc. to run multiple commands in parallel.
## The $version will be set in pre-setup.sh script.
## ----------------------------------
#git clone --quiet git@github.com:org/project-addons.git --depth 1 --branch $version /workspace/project-addons &
#P1=$!
#git clone --quiet git@github.com:org/other-addons.git --depth 1 --branch $version /workspace/other-addons &
#P2=$!
#
#wait $P1 $P2
