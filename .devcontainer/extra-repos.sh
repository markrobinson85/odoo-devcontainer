#!/bin/bash

echo "Cloning extra repositories if specified..."
## ----------------------------------
## Use this script to add additional repos to the container.
## You can use P1, P2, P3, etc. to run multiple commands in parallel.
## The $version will be set in pre-setup.sh script.
##
## ----------------------------------

#git clone --quiet git@github.com:org/project-addons.git --depth 1 --branch $version /workspace/project-addons &
#P1=$!
#git clone --quiet git@github.com:org/other-addons.git --depth 1 --branch $version /workspace/other-addons &
#P2=$!
#git clone --quiet git@github.com:oca/web.git --depth 1 --branch $version /workspace/oca/web &
#P2=$!

#wait $P1 $P2

#if [ -f "/workspace/project-addons/requirements.txt" ]; then
#  pip install -r /workspace/project-addons/requirements.txt
#fi

# Define the array of additional addon directories that should be added to the odoo addons_path.
# The conf files will be updated with these directories.
additional_addon_dirs=('custom-addons' 'project-addons' 'oca/web')

# Loop through each .conf file in the configs/ directory
for conf_file in configs/*.conf; do
    # Read the current addons_path from the conf file
    current_addons_path=$(grep "addons_path" "$conf_file" | cut -d= -f2- | xargs)

    # Initialize new_addons_path with the current addons_path
    new_addons_path="$current_addons_path"

    # Loop through the additional directories
    for dir in "${additional_addon_dirs[@]}"; do
        # Check if the directory is already in the addons_path
        if ! echo "$current_addons_path" | grep -q "$dir"; then
            # Append the directory if it's not already present
            new_addons_path="${new_addons_path},${dir}"
        fi
    done

    # Update the conf file with the new addons_path
    sed -i "s|addons_path.*|addons_path = ${new_addons_path}|" "$conf_file"
done