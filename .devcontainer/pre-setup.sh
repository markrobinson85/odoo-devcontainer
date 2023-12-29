#!/bin/bash

## ----------------------------------
## VARIABLES
## ----------------------------------
project_dir=/workspace/
version="13.0"

## ----------------------------------
## Pass keys to container vscode user.
## ----------------------------------
sudo chown -R vscode:vscode /workspace
sudo cp -r /root/.ssh /home/vscode/
sudo cp -r /root/.aws /home/vscode/
sudo chown -R vscode:vscode /home/vscode/.ssh
sudo chmod -R u=rw,go= /home/vscode/.ssh
sudo chown -R vscode:vscode /home/vscode/.aws
sudo chmod -R u=rw,go= /home/vscode/.aws
sudo chmod 700 ~/.ssh/
sudo mkdir -p ~/.cache/pip
sudo chown -R vscode:vscode ~/.cache/pip
sudo ln -f /workspace/configs/nginx.conf /etc/nginx/sites-enabled/odoo-devcontainer.conf

mkdir /workspace/.idea
mkdir /workspace/.idea/runConfigurations

# To speed up the process, we use a depth of 1 to pull a shallow clone of the repo.
# Then we update the remote fetch to include the branch we want to use.
cd /workspace

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

echo "Cloning Odoo $version, Enterprise $version and odoo-stubs..."
git clone --quiet git@github.com:odoo/odoo.git --depth 1 --branch $version /workspace/odoo &
P1=$!
git clone --quiet git@github.com:odoo/enterprise.git --depth 1 --branch $version /workspace/enterprise &
P2=$!
git clone --quiet https://github.com/odoo-ide/odoo-stubs.git --depth 1 --branch $version /workspace/odoo-stubs &
P3=$!

# Download the requirements file separately from the repo to speed up the process.
version_url="https://raw.githubusercontent.com/odoo/odoo/"
            version_url+=$version
            version_url+="/requirements.txt"

curl $version_url -o requirements.txt

echo "Installing venv and requirements..."

python3.8 -m venv /workspace/venv
source /workspace/venv/bin/activate

pip install --upgrade pip
pip install wheel matplotlib pydevd
if [ -f "/workspace/requirements.txt" ]; then
  pip install -r /workspace/requirements.txt
fi

wait $P1 $P2 $P3

/workspace/.devcontainer/extra-repos.sh

if [ ! -f "/workspace/.idea/runConfigurations/odoo_bin_single.xml" ]; then
echo "Creating debug configurations for Pycharm in ./.idea/runConfigurations/odoo_bin_single.xml"
cat >> /workspace/.idea/runConfigurations/odoo_bin_single.xml <<EOL
<component name="ProjectRunConfigurationManager">
  <configuration default="false" name="Odoo $version - Single Worker" type="PythonConfigurationType" factoryName="Python" nameIsGenerated="false">
    <module name="workspace" />
    <option name="INTERPRETER_OPTIONS" value="" />
    <option name="PARENT_ENVS" value="true" />
    <envs>
      <env name="PYTHONUNBUFFERED" value="1" />
    </envs>
    <option name="SDK_HOME" value="./venv/bin/python" />
    <option name="SDK_NAME" value="Python 3.8 (workspace)" />
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
  <configuration default="false" name="Odoo $version" type="PythonConfigurationType" factoryName="Python" nameIsGenerated="false">
    <module name="workspace" />
    <option name="INTERPRETER_OPTIONS" value="" />
    <option name="PARENT_ENVS" value="true" />
    <envs>
      <env name="PYTHONUNBUFFERED" value="1" />
    </envs>
    <option name="SDK_HOME" value="./venv/bin/python" />
    <option name="SDK_NAME" value="Python 3.8 (workspace)" />
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
  <configuration default="false" name="Odoo $version - Init Test" type="PythonConfigurationType" factoryName="Python" nameIsGenerated="false">
    <module name="workspace" />
    <option name="INTERPRETER_OPTIONS" value="" />
    <option name="PARENT_ENVS" value="true" />
    <envs>
      <env name="PYTHONUNBUFFERED" value="1" />
    </envs>
    <option name="SDK_HOME" value="./venv/bin/python" />
    <option name="SDK_NAME" value="Python 3.8 (workspace)" />
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

if [ -f "/workspace/project-addons/requirements.txt" ]; then
  pip install -r /workspace/project-addons/requirements.txt
fi
