#!/bin/bash

## ----------------------------------
## VARIABLES
## ----------------------------------
project_dir=/workspace/

## ----------------------------------
## Pass keys to container vscode user.
## ----------------------------------
sudo chown -R vscode:vscode /workspace
sudo chown -R vscode:vscode /shared
sudo cp -r /root/.ssh /home/vscode/
sudo chown -R vscode:vscode /home/vscode/.ssh
sudo chmod -R u=rw,go= /home/vscode/.ssh
sudo chmod 700 ~/.ssh/
sudo mkdir -p ~/.cache/pip
sudo chown -R vscode:vscode ~/.cache/pip
sudo ln -s /workspace/configs/nginx.conf /etc/nginx/sites-enabled/odoo-devcontainer.conf

mkdir -p /workspace/.idea
mkdir -p /workspace/.idea/runConfigurations

# To speed up the process, we use a depth of 1 to pull a shallow clone of the repo.
# Then we update the remote fetch to include the branch we want to use.
cd /workspace

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

          # Check if the local branch is behind its remote counterpart
          if git log --oneline $branch..$remote | grep -q '.'; then
              echo "Local branch $branch is behind its remote counterpart $remote."
              repo_ready_for_removal=0
              # Handle the situation for behind remote
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
      sudo rm -r /workspace/.git
      sudo rm -r /workspace/.gitignore
  else
      echo "Skipping the removal of .git directory."
  fi

fi
echo "Cloning Odoo $PROJECT_VERSION, Enterprise $PROJECT_VERSION and odoo-stubs..."
git clone --quiet git@github.com:odoo/odoo.git --depth 1 --branch $PROJECT_VERSION /shared/$PROJECT_VERSION/odoo &
P1=$!

# Clone enterprise repo only if PROJECT_SKIP_ENTERPRISE is not set to 1 or true
if [[ "$PROJECT_SKIP_ENTERPRISE" != "1" && "$PROJECT_SKIP_ENTERPRISE" != "true" ]]; then
    git clone --quiet git@github.com:odoo/enterprise.git --depth 1 --branch $PROJECT_VERSION /shared/$PROJECT_VERSION/enterprise &
    P2=$!
fi

git clone --quiet https://github.com/odoo-ide/odoo-stubs.git --depth 1 --branch $PROJECT_VERSION /shared/$PROJECT_VERSION/odoo-stubs &
P3=$!

# Loop through each .conf file in the configs/ directory
for conf_file in configs/*.conf; do
    # Replace the $PROJECT_VERSION placeholder with the actual version
    sed -i "s/\$PROJECT_VERSION/$PROJECT_VERSION/g" "$conf_file"

    # Check if PROJECT_SKIP_ENTERPRISE is set to true
    if [[ "$PROJECT_SKIP_ENTERPRISE" == "true" ]]; then
      # Use sed to remove the 'enterprise,' portion from the addons_path
#      sed -i 's/addons_path = enterprise,/addons_path = /' "$conf_file"
      sed -i "s,/shared/[0-9]*\.[0-9]*/enterprise,,g" "$conf_file"
      sed -i "s,addons_path = ,addons_path = /shared/[0-9]*\.[0-9]*/odoo/addons,g" "$conf_file"
    fi
done

# Download the requirements file separately from the repo to speed up the process.
version_url="https://raw.githubusercontent.com/odoo/odoo/"
            version_url+=$PROJECT_VERSION
            version_url+="/requirements.txt"

curl $version_url -o requirements.txt

echo "Installing venv and requirements..."

if [ "$PROJECT_VERSION" = "17.0" ] || [ "$PROJECT_VERSION" = "16.0" ] || [ "$PROJECT_VERSION" = "15.0" ] || [ "$PROJECT_VERSION" = "14.0" ]; then
  python3.10 -m venv /workspace/venv
elif [ "$PROJECT_VERSION" = "13.0" ] || [ "$PROJECT_VERSION" = "12.0" ] || [ "$PROJECT_VERSION" = "11.0" ]; then
  python3.8 -m venv /workspace/venv
elif [ "$PROJECT_VERSION" = "9.0" ] || [ "$PROJECT_VERSION" = "10.0" ]; then
  virtualenv --python=/usr/bin/python2.7 /workspace/venv
fi
source /workspace/venv/bin/activate

pip install --quiet --upgrade pip
pip install --quiet wheel matplotlib pydevd

if [ -f "/workspace/requirements.txt" ]; then
  echo "Installing requirements.txt..."
  pip install --quiet -r /workspace/requirements.txt
fi

if [ "$PROJECT_VERSION" = "10.0" ] || [ "$PROJECT_VERSION" = "9.0" ]; then
  echo "Installing psycopg-binary..."
  pip uninstall --quiet -y psycopg2
  pip install -quiet psycopg2-binary
fi

wait $P1 ${P2:-} ${P3:-}

EXCLUDE_DIRS=('venv')
sudo chmod +x /workspace/.devcontainer/extra-repos.sh
/workspace/.devcontainer/extra-repos.sh

# To make the runConfiguration work, we need to ensure we use the correct module name,
# which is the .iml file that PyCharm creates. We can pass this to the module's name attribute.
if [ ! -f "/workspace/.idea/workspace.iml" ]; then
## Create iml file if it does not exist.
cat >> /workspace/.idea/workspace.iml <<EOL
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

if [ ! -f "/workspace/.idea/modules.xml" ]; then
## Create modules.xml file if it does not exist.
cat >> /workspace/.idea/modules.xml <<EOL
<?xml version="1.0" encoding="UTF-8"?>
<project version="4">
  <component name="ProjectModuleManager">
    <modules>
      <module fileurl="file://\$PROJECT_DIR\$/.idea/workspace.iml" filepath="\$PROJECT_DIR\$/.idea/workspace.iml" />
    </modules>
  </component>
</project>
EOL
fi

iml_file=$(find .idea -name "*.iml")
module_name=$(basename "$iml_file" .iml)
echo "Project name: $module_name"

# Function to add excludeFolder tag
add_exclude_folder() {
    local folder=$1
    # Open the self-closed content tag if it is not already opened
    if grep -q "<content url=\"file://\$MODULE_DIR\$\" />" "$iml_file"; then
        sed -i 's|<content url="file://\$MODULE_DIR\$" />|<content url="file://\$MODULE_DIR\$">|' "$iml_file"
        sed -i '/<content url="file:\/\/\$MODULE_DIR\$">/a \    </content>' "$iml_file"
    fi

    if ! grep -q "<excludeFolder url=\"file://\$MODULE_DIR$/$folder\" />" "$iml_file"; then
        sed -i "/<content url=\"file:\/\/\$MODULE_DIR\$\">/a \      <excludeFolder url=\"file://\$MODULE_DIR$/$folder\" />" "$iml_file"
    fi
}

# Iterate over each folder in the array and add it if not already present
for folder in "${EXCLUDE_DIRS[@]}"; do
    add_exclude_folder "$folder"
done

echo "IML file has been updated with excluded directories."

if [ ! -f "/workspace/.idea/runConfigurations/odoo_bin_single.xml" ]; then
echo "Creating debug configurations for Pycharm in ./.idea/runConfigurations/odoo_bin_single.xml"
cat >> /workspace/.idea/runConfigurations/odoo_bin_single.xml <<EOL
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
    <option name="SCRIPT_NAME" value="\$PROJECT_DIR\$/odoo/odoo-bin" />
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

if [ ! -f "/workspace/.idea/runConfigurations/odoo_bin.xml" ]; then
echo "Creating debug configurations for Pycharm in ./.idea/runConfigurations/odoo_bin.xml"
cat >> /workspace/.idea/runConfigurations/odoo_bin.xml <<EOL
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
    <option name="SCRIPT_NAME" value="\$PROJECT_DIR\$/odoo/odoo-bin" />
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

if [ ! -f "/workspace/.idea/runConfigurations/odoo_bin_test.xml" ]; then
echo "Creating debug configurations for Pycharm in ./.idea/runConfigurations/odoo_bin_test.xml"
cat >> /workspace/.idea/runConfigurations/odoo_bin_test.xml <<EOL
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
    <option name="SCRIPT_NAME" value="\$PROJECT_DIR\$/odoo/odoo-bin" />
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

