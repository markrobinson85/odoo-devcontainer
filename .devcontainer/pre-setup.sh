#!/bin/bash

## ----------------------------------
## VARIABLES
## ----------------------------------
project_dir=$PROJECT_WORKSPACE_FOLDER
pids=() # Store background process IDs

## ----------------------------------
#  FUNCTIONS - TODO: Refactor into Python script?
## ----------------------------------
#Function to add a content tag before the first content tag
add_content_tag() {
    local url=$1
    echo "Attaching $url to project in $iml_file..."
    if ! grep -q "<content url=\"$url\" />" "$iml_file"; then
        # Add the new content tag before MODULE_DIR content tag
        sed -i "/<content url=\"file:\/\/\$MODULE_DIR\$\">/i \    <content url=\"$url\" />" "$iml_file"
    fi
}

# Function to add excludeFolder tag
add_exclude_folder() {
    local folder=$1
    echo "Excluding $folder from PyCharm indexing in $iml_file..."
    # Open the self-closed content tag if it is not already opened
    if grep -q "<content url=\"file://\$MODULE_DIR\$\" />" "$iml_file"; then
        sed -i 's|<content url="file://\$MODULE_DIR\$" />|<content url="file://\$MODULE_DIR\$">|' "$iml_file"
        sed -i '/<content url="file:\/\/\$MODULE_DIR\$">/a \    </content>' "$iml_file"
    fi

    if ! grep -q "<excludeFolder url=\"file://\$MODULE_DIR$/$folder\" />" "$iml_file"; then
        sed -i "/<content url=\"file:\/\/\$MODULE_DIR\$\">/a \      <excludeFolder url=\"file://\$MODULE_DIR$/$folder\" />" "$iml_file"
    fi
}

# Function to loop through each .conf file in the configs/ directory and update the addons_path
update_config_files() {
for conf_file in configs/*.conf; do
    echo "Updating $conf_file with $ADDITIONAL_ADDON_DIRS..."
    # Replace the $PROJECT_VERSION placeholder with the actual version
    sed -i "s/\$PROJECT_VERSION/$PROJECT_VERSION/g" "$conf_file"

    # Check if PROJECT_SKIP_ENTERPRISE is set to true
    if [[ "$PROJECT_SKIP_ENTERPRISE" == "true" ]]; then
      # Use sed to remove the 'enterprise,' portion from the addons_path
      sed -i "s,/shared/$PROJECT_VERSION/enterprise,,g" "$conf_file"
      sed -i 's/^addons_path = ,/addons_path = /' "$conf_file"
    fi

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
}

clone_or_pull_repo() {
    local repo_url=$1
    local target_dir=$2
    local clone_args=${@:3}

    if [ -d "$target_dir/.git" ]; then
        echo "Repository exists. Pulling latest changes in $target_dir"
        git -C "$target_dir" pull &
    else
        echo "Cloning repository into $target_dir"
        git clone $clone_args "$repo_url" "$target_dir" &
    fi
    pids+=($!)
}

## ----------------------------------
## Pass keys to container vscode user.
## ----------------------------------
sudo chmod +x $project_dir/.devcontainer/extra-repos.sh
sudo chown -R vscode:vscode $project_dir
sudo chown -R vscode:vscode /shared
sudo cp -r /root/.ssh /home/vscode/
sudo chown -R vscode:vscode /home/vscode/.ssh
sudo chmod -R u=rw,go= /home/vscode/.ssh
sudo chmod 700 ~/.ssh/
sudo mkdir -p ~/.cache/pip
sudo chown -R vscode:vscode ~/.cache/pip
sudo ln -s $project_dir/configs/nginx.conf /etc/nginx/sites-enabled/odoo-devcontainer.conf

mkdir -p $project_dir/.idea
mkdir -p $project_dir/.idea/runConfigurations

# To speed up the process, we use a depth of 1 to pull a shallow clone of the repo.
# Then we update the remote fetch to include the branch we want to use.
cd $project_dir

# If PROJECT_KEEP_DOGIT is not true, we will check if it is safe to remove the .git directory before removing it.
# This would typically be removed when cloning directly into a new container as we won't need the .git, but when
# mounting the local files into the container when customizing the devcontainer setup, we'll want to keep the .git.
if [ $PROJECT_KEEP_DOTGIT != "true" ]; then
  ## We check if the git repo is up to date or has changes staged/unstaged. We do this do
  # prevent removal of the .git directory, as we won't need it once we've pulled in our files.
  # Fetch updates from remote
  git fetch --all

  # Initialize a flag to track the overall status
  repo_ready_for_removal=1

  # Loop through each local branch and check its status against the remote
  for branch in $(git branch | sed 's/* //'); do
      # Get the name of the remote tracking branch, if it exists
      remote=$(git for-each-ref --format='%(upstream:short)' refs/heads/$branch)

      if [ -n "$remote" ]; then
          # Check if the local branch is behind its remote counterpart
          if git log --oneline $remote..$branch | grep -q '.'; then
              echo "Local branch $branch is ahead of its remote counterpart $remote."
              repo_ready_for_removal=0
              # Handle the situation for unpushed commits
          fi

      fi
  done

  # Check for a clean state
  if [ -n "$(git status --porcelain -uno)" ]; then
      echo "Repository is not clean."
      repo_ready_for_removal=0
  else
      echo "Repository is clean."
  fi

  # Remove .git directory if both conditions are met
  if [ $repo_ready_for_removal -eq 1 ]; then
      echo "Repository is clean and up-to-date. Proceeding to remove .git directory."
      sudo rm -r $project_dir/.git
      sudo rm -r $project_dir/.gitignore
  else
      echo "Skipping the removal of .git directory."
  fi

fi

# Clone or pull the repo
clone_or_pull_repo "git@github.com:odoo/odoo.git" "/shared/$PROJECT_VERSION/odoo" --depth 1 --branch $PROJECT_VERSION

# Clone enterprise repo only if PROJECT_SKIP_ENTERPRISE is not set to 1 or true
if [[ "$PROJECT_SKIP_ENTERPRISE" != "1" && "$PROJECT_SKIP_ENTERPRISE" != "true" ]]; then
    clone_or_pull_repo "git@github.com:odoo/enterprise.git" "/shared/$PROJECT_VERSION/enterprise" --depth 1 --branch $PROJECT_VERSION
fi
clone_or_pull_repo "git@github.com:odoo-ide/odoo-stubs.git" "/shared/$PROJECT_VERSION/odoo-stubs" --depth 1 --branch $PROJECT_VERSION

# Download the requirements file separately from the repo to speed up the process.
version_url="https://raw.githubusercontent.com/odoo/odoo/"
            version_url+=$PROJECT_VERSION
            version_url+="/requirements.txt"

curl $version_url -o requirements.txt

echo "Installing venv and requirements..."

if [ "$PROJECT_VERSION" = "17.0" ] || [ "$PROJECT_VERSION" = "16.0" ] || [ "$PROJECT_VERSION" = "15.0" ] || [ "$PROJECT_VERSION" = "14.0" ]; then
  python3.10 -m venv $project_dir/venv
elif [ "$PROJECT_VERSION" = "13.0" ] || [ "$PROJECT_VERSION" = "12.0" ] || [ "$PROJECT_VERSION" = "11.0" ]; then
  python3.8 -m venv $project_dir/venv
elif [ "$PROJECT_VERSION" = "9.0" ] || [ "$PROJECT_VERSION" = "10.0" ]; then
  virtualenv --python=/usr/bin/python2.7 $project_dir/venv
fi
source $project_dir/venv/bin/activate

pip install --quiet --upgrade pip
pip install --quiet wheel matplotlib pydevd

if [ -f "$project_dir/requirements.txt" ]; then
  echo "Installing requirements.txt..."
  pip install --quiet -r $project_dir/requirements.txt
fi

if [ "$PROJECT_VERSION" = "10.0" ] || [ "$PROJECT_VERSION" = "9.0" ]; then
  echo "Installing psycopg-binary..."
  pip uninstall --quiet -y psycopg2
  pip install --quiet psycopg2-binary
fi

# Check for existing .iml file
iml_file=$(find .idea -name "*.iml")

if [ ! -f "$project_dir/.idea$project_dir.iml" ] && [ ! -f "$project_dir/$iml_file" ]; then
## Create iml file if it does not exist.
cat >> $project_dir/.idea$project_dir.iml <<EOL
<?xml version="1.0" encoding="UTF-8"?>
<module type="PYTHON_MODULE" version="4">
  <component name="NewModuleRootManager">
    <content url="file://\$MODULE_DIR\$">
    </content>
    <orderEntry type="inheritedJdk" />
    <orderEntry type="sourceFolder" forTests="false" />
  </component>
</module>
EOL
fi

iml_file=$(find .idea -name "*.iml")
module_name=$(basename "$iml_file" .iml)
echo "Project name: $module_name"

if [ ! -f "$project_dir/.idea/modules.xml" ]; then
## Create modules.xml file if it does not exist.
cat >> $project_dir/.idea/modules.xml <<EOL
<?xml version="1.0" encoding="UTF-8"?>
<project version="4">
  <component name="ProjectModuleManager">
    <modules>
      <module fileurl="file://\$PROJECT_DIR\$/.idea$project_dir.iml" filepath="\$PROJECT_DIR\$$iml_file" />
    </modules>
  </component>
</project>
EOL
fi

EXCLUDE_DIRS=('venv' 'sql' 'utils' 'restores' 'docs') # Directories that should not be indexed by PyCharm.
SHARED_DIRS=('enterprise' 'odoo' 'odoo-stubs') # Directories that should be shared between projects.
ADDITIONAL_ADDON_DIRS=() # Additional addon directories.
source $project_dir/.devcontainer/extra-repos.sh

# Wait for all background processes to finish
for pid in "${pids[@]}"; do
    wait $pid
done

# Update config files with addons_path from ADDITIONAL_ADDON_DIRS, and set versions for addons.
update_config_files

# To make the runConfiguration work, we need to ensure we use the correct module name,
# which is the .iml file that PyCharm creates. We can pass this to the module's name attribute.

# Iterate over each folder in the array and add it if not already present
for folder in "${EXCLUDE_DIRS[@]}"; do
    add_exclude_folder "$folder"
done

echo "IML file has been updated with excluded directories."


# Iterate over each folder in the SHARED_DIRS array and add it if not already present
for folder in "${SHARED_DIRS[@]}"; do
    add_content_tag "file:///shared/$PROJECT_VERSION/$folder"
done

echo "IML file has been attached to shared directories."

if [ ! -f "$project_dir/.idea/runConfigurations/odoo_bin_single.xml" ]; then
echo "Creating debug configurations for Pycharm in ./.idea/runConfigurations/odoo_bin_single.xml"
cat >> $project_dir/.idea/runConfigurations/odoo_bin_single.xml <<EOL
<component name="ProjectRunConfigurationManager">
  <configuration default="false" name="Odoo $PROJECT_VERSION - Single Worker" type="PythonConfigurationType" factoryName="Python" nameIsGenerated="false">
    <module name="$module_name" />
    <option name="INTERPRETER_OPTIONS" value="" />
    <option name="PARENT_ENVS" value="true" />
    <envs>
      <env name="PYTHONUNBUFFERED" value="1" />
    </envs>
    <option name="SDK_HOME" value="./venv/bin/python" />
    <option name="WORKING_DIRECTORY" value="\$PROJECT_DIR\$" />
    <option name="IS_MODULE_SDK" value="true" />
    <option name="ADD_CONTENT_ROOTS" value="true" />
    <option name="ADD_SOURCE_ROOTS" value="true" />
    <EXTENSION ID="PythonCoverageRunConfigurationExtension" runner="coverage.py" />
    <option name="SCRIPT_NAME" value="/shared/$PROJECT_VERSION/odoo/odoo-bin" />
    <option name="PARAMETERS" value="--config=./configs/odoo-server.conf" />
    <option name="SHOW_COMMAND_LINE" value="false" />
    <option name="EMULATE_TERMINAL" value="false" />
    <option name="MODULE_MODE" value="false" />
    <option name="REDIRECT_INPUT" value="false" />
    <option name="INPUT_FILE" value="" />
    <method v="2" />
  </configuration>
</component>
EOL
fi

if [ ! -f "$project_dir/.idea/runConfigurations/odoo_bin.xml" ]; then
echo "Creating debug configurations for Pycharm in ./.idea/runConfigurations/odoo_bin.xml"
cat >> $project_dir/.idea/runConfigurations/odoo_bin.xml <<EOL
<component name="ProjectRunConfigurationManager">
  <configuration default="false" name="Odoo $PROJECT_VERSION" type="PythonConfigurationType" factoryName="Python" nameIsGenerated="false">
    <module name="$module_name" />
    <option name="INTERPRETER_OPTIONS" value="" />
    <option name="PARENT_ENVS" value="true" />
    <envs>
      <env name="PYTHONUNBUFFERED" value="1" />
    </envs>
    <option name="SDK_HOME" value="./venv/bin/python" />
    <option name="WORKING_DIRECTORY" value="\$PROJECT_DIR\$" />
    <option name="IS_MODULE_SDK" value="true" />
    <option name="ADD_CONTENT_ROOTS" value="true" />
    <option name="ADD_SOURCE_ROOTS" value="true" />
    <EXTENSION ID="PythonCoverageRunConfigurationExtension" runner="coverage.py" />
    <option name="SCRIPT_NAME" value="/shared/$PROJECT_VERSION/odoo/odoo-bin" />
    <option name="PARAMETERS" value="--config=./configs/odoo-server-workers.conf" />
    <option name="SHOW_COMMAND_LINE" value="false" />
    <option name="EMULATE_TERMINAL" value="false" />
    <option name="MODULE_MODE" value="false" />
    <option name="REDIRECT_INPUT" value="false" />
    <option name="INPUT_FILE" value="" />
    <method v="2" />
  </configuration>
</component>
EOL
fi

if [ ! -f "$project_dir/.idea/runConfigurations/odoo_bin_test.xml" ]; then
echo "Creating debug configurations for Pycharm in ./.idea/runConfigurations/odoo_bin_test.xml"
cat >> $project_dir/.idea/runConfigurations/odoo_bin_test.xml <<EOL
<component name="ProjectRunConfigurationManager">
  <configuration default="false" name="Odoo $PROJECT_VERSION - Init Test" type="PythonConfigurationType" factoryName="Python" nameIsGenerated="false">
    <module name="$module_name" />
    <option name="INTERPRETER_OPTIONS" value="" />
    <option name="PARENT_ENVS" value="true" />
    <envs>
      <env name="PYTHONUNBUFFERED" value="1" />
    </envs>
    <option name="SDK_HOME" value="./venv/bin/python" />
    <option name="WORKING_DIRECTORY" value="\$PROJECT_DIR\$" />
    <option name="IS_MODULE_SDK" value="true" />
    <option name="ADD_CONTENT_ROOTS" value="true" />
    <option name="ADD_SOURCE_ROOTS" value="true" />
    <EXTENSION ID="PythonCoverageRunConfigurationExtension" runner="coverage.py" />
    <option name="SCRIPT_NAME" value="/shared/$PROJECT_VERSION/odoo/odoo-bin" />
    <option name="PARAMETERS" value="--config=./configs/test-server.conf -i account --test-tags account -d test_db --no-http --stop-after-init" />
    <option name="SHOW_COMMAND_LINE" value="false" />
    <option name="EMULATE_TERMINAL" value="false" />
    <option name="MODULE_MODE" value="false" />
    <option name="REDIRECT_INPUT" value="false" />
    <option name="INPUT_FILE" value="" />
    <method v="2" />
  </configuration>
</component>
EOL
fi

