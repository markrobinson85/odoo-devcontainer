#!/bin/bash

echo "Cloning extra repositories if specified..."
## ----------------------------------
## Use this script to add additional repos to the container.
## You can use P1, P2, P3, etc. to run multiple commands in parallel.
## The $PROJECT_VERSION will be set as an environment variable in devcontainer.json.
##
## ----------------------------------
EXCLUDE_DIRS+=() # i.e ('res' 'restores') # Add to array of directories that should not be indexed by PyCharm. (venv is excluded by default)
ADDITIONAL_ADDON_DIRS=() #i.e ('custom-addons' 'project-addons' '/shared/13.0/oca/web')

#git clone --quiet git@github.com:org/project-addons.git --branch $PROJECT_VERSION $PROJECT_WORKSPACE_FOLDER/project-addons &
#EP1=$!
#git clone --quiet git@github.com:org/other-addons.git --branch $PROJECT_VERSION $PROJECT_WORKSPACE_FOLDER/other-addons &
#EP2=$!

# Clone resources that can be shared between projects into the /shared mount, to reduce the number of volumes and duplicated source code.
#git clone --quiet git@github.com:oca/web.git --depth 1 --branch $PROJECT_VERSION /shared/$PROJECT_VERSION/oca/web &
#EP3=$!

# Define the array of additional addon directories that should be added to the odoo addons_path.
# The conf files will be updated with these directories.

#wait ${EP1:-} ${EP2:-} ${EP3:-}

#if [ -f "$PROJECT_WORKSPACE_FOLDER/project-addons/requirements.txt" ]; then
#  pip install -r $PROJECT_WORKSPACE_FOLDER/project-addons/requirements.txt
#fi
