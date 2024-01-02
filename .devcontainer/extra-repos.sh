#!/bin/bash

echo "Cloning extra repositories if specified..."
## ----------------------------------
## Use this script to add additional repos to the container.
## You can use P1, P2, P3, etc. to run multiple commands in parallel.
## The $PROJECT_VERSION will be set as an environment variable in devcontainer.json.
##
## OCA repos are cloned into /shared/$PROJECT_VERSION/oca/$repo, and if specified, will
## automatically be configured in the addons_path in the .conf files. The /shared/version/oca directory
## will also be attached to the project in PyCharm.
## ----------------------------------

# Setting additional directories that should be excluded from indexing by PyCharm.
EXCLUDE_DIRS+=() # i.e ("res" "restores") # Add to array of directories that should not be indexed by PyCharm. (venv is excluded by default)
SHARED_DIRS+=() # Specify additional shared directories that should be attached to the project. i.e ("shared" "shared2")
OCA_REPOS=("web") # Specify additional OCA repos that should be cloned. i.e ("web" "server-tools")

# Setting additioanl addon paths to be used in conf files.
ADDITIONAL_ADDON_DIRS+=() # Specify addon paths that should be used in conf files. i.e ("custom-addons" "project-addons")

# Attach the OCA directory to the project if any OCA repos are specified.
if [ ${#OCA_REPOS[@]} -gt 0 ]; then
    SHARED_DIRS+=("oca")  # Add item to SHARED_DIRS
fi

#clone_or_pull_repo "git@github.com:org/project-addons.git" "$PROJECT_WORKSPACE_FOLDER/project-addons" --depth 1 --branch $PROJECT_VERSION
#clone_or_pull_repo "git@github.com:org/other-addons.git" "$PROJECT_WORKSPACE_FOLDER/other-addons" --depth 1 --branch $PROJECT_VERSION

for repo in "${OCA_REPOS[@]}"; do
    clone_or_pull_repo "git@github.com:oca/$repo.git" "/shared/$PROJECT_VERSION/oca/$repo" --depth 1 --branch $PROJECT_VERSION
    # Add the OCA repo to the ADDITIONAL_ADDON_DIRS array.
    ADDITIONAL_ADDON_DIRS+=("/shared/$PROJECT_VERSION/oca/$repo")
done

# Wait for all background processes to finish
for pid in "${pids[@]}"; do
    wait $pid
done

# Install requirements for the OCA repos.
for repo in "${OCA_REPOS[@]}"; do
    if [ -f "/shared/$PROJECT_VERSION/oca/$repo/requirements.txt" ]; then
      pip install --quiet -r /shared/$PROJECT_VERSION/oca/$repo/requirements.txt
    fi
done

#if [ -f "$PROJECT_WORKSPACE_FOLDER/project-addons/requirements.txt" ]; then
#  pip install --quiet -r $PROJECT_WORKSPACE_FOLDER/project-addons/requirements.txt
#fi
