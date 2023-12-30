#!/bin/bash

echo "Cloning extra repositories if specified..."
## ----------------------------------
## Use this script to add additional repos to the container.
## You can use P1, P2, P3, etc. to run multiple commands in parallel.
## The $PROJECT_VERSION will be set as an environment variable in devcontainer.json.
##
## ----------------------------------

#git clone --quiet git@github.com:org/project-addons.git --branch $PROJECT_VERSION /workspace/project-addons &
#EP1=$!
#git clone --quiet git@github.com:org/other-addons.git --branch $PROJECT_VERSION /workspace/other-addons &
#EP2=$!

# Clone resources that can be shared between projects into the /shared mount, to reduce the number of volumes and duplicated source code.
#git clone --quiet git@github.com:oca/web.git --depth 1 --branch $PROJECT_VERSION /shared/$PROJECT_VERSION/oca/web &
#EP3=$!

EXCLUDE_DIRS+=() # i.e ('res' 'restores') # Add to array of directories that should not be indexed by PyCharm. (venv is excluded by default)

# Define the array of additional addon directories that should be added to the odoo addons_path.
# The conf files will be updated with these directories.
ADDITIONAL_ADDON_DIRS=() #i.e ('custom-addons' 'project-addons' 'oca/web')
#wait ${EP1:-} ${EP2:-} ${EP3:-}

#if [ -f "/workspace/project-addons/requirements.txt" ]; then
#  pip install -r /workspace/project-addons/requirements.txt
#fi

# Loop through each .conf file in the configs/ directory
for conf_file in /workspace/configs/*.conf; do
    # Read the current addons_path from the conf file
    current_addons_path=$(grep "addons_path" "$conf_file" | cut -d= -f2- | xargs)

    # Initialize new_addons_path with the current addons_path
    new_addons_path="$current_addons_path"

    # Loop through the additional directories
    for dir in "${ADDITIONAL_ADDON_DIRS[@]}"; do
        # Check if the directory is already in the addons_path
        if ! echo "$current_addons_path" | grep -q "$dir"; then
            # Append the directory if it's not already present
            new_addons_path="${new_addons_path},${dir}"
        fi
    done

    # Update the conf file with the new addons_path
    sed -i "s|addons_path.*|addons_path = ${new_addons_path}|" "$conf_file"
done