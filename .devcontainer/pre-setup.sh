#!/bin/bash

sudo chown -R vscode:vscode /workspace
sudo cp -r /root/.ssh /home/vscode/
sudo chown -R vscode:vscode /home/vscode/.ssh
sudo chmod -R u=rw,go= /home/vscode/.ssh
sudo chmod 700 ~/.ssh/
sudo mkdir -p ~/.cache/pip
sudo chown -R vscode:vscode ~/.cache/pip

project_dir=/workspace/
version="13.0"

mkdir /workspace/.idea
mkdir /workspace/.idea/runConfigurations

# To speed up the process, we use a depth of 1 to pull a shallow clone of the repo.
# Then we update the remote fetch to include the branch we want to use.
cd /workspace

# Remove git folder.
sudo rm -r /workspace/.git
sudo rm -r /workspace/.gitignore

echo "Cloning Odoo $version, Enterprise $version and odoo-stubs..."
git clone --quiet git@github.com:odoo/odoo.git --depth 1 --branch $version /workspace/odoo &
P1=$!
git clone --quiet git@github.com:odoo/enterprise.git --depth 1 --branch $version /workspace/enterprise &
P2=$!
git clone --quiet https://github.com/odoo-ide/odoo-stubs.git --depth 1 --branch $version /workspace/odoo-stubs &
P3=$!

wait $P1 $P2 $P3

if [ ! -f "/workspace/.idea/runConfigurations/odoo_bin_single.xml" ]; then
echo "Creating debug configurations for Pycharm in ./.idea/runConfigurations/odoo_bin_single.xml"
cat >> /workspace/.idea/runConfigurations/odoo_bin_single.xml <<EOL
<component name="ProjectRunConfigurationManager">
  <configuration default="false" name="Odoo $version - Single Worker" type="PythonConfigurationType" factoryName="Python" nameIsGenerated="false">
    <module name="$project_dir" />
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
    <module name="$project_dir" />
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
    <module name="$project_dir" />
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

echo "Installing venv and requirements..."
python3.8 -m venv /workspace/venv
source /workspace/venv/bin/activate

pip install --upgrade pip
pip install wheel matplotlib pydevd
if [ -f "/workspace/odoo/requirements.txt" ]; then
  pip install -r /workspace/odoo/requirements.txt
fi
if [ -f "/workspace/project-addons/requirements.txt" ]; then
  pip install -r /workspace/project-addons/requirements.txt
fi
