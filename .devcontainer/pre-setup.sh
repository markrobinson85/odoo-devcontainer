#!/bin/bash

sudo chown -R vscode:vscode /workspace
sudo cp -r /root/.ssh /home/vscode/
sudo chown -R vscode:vscode /home/vscode/.ssh
sudo chmod -R u=rw,go= /home/vscode/.ssh
sudo chmod 700 ~/.ssh/

project_dir=/workspace/
version="13.0"

mkdir /workspace/.idea
mkdir /workspace/.idea/runConfigurations

cd /workspace
git submodule init
git submodule update

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

pip3 install --upgrade pip
pip3 install wheel matplotlib pydevd
if [ -f "/workspace/odoo/requirements.txt" ]; then
  pip3 install -r /workspace/odoo/requirements.txt
fi
if [ -f "/workspace/project-addons/requirements.txt" ]; then
  pip3 install -r /workspace/project-addons/requirements.txt
fi
