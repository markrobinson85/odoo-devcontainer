#!/bin/bash

# Startup Postgresql if enabled.
if [[ "$PROJECT_SKIP_POSTGRES" = "0" || "$PROJECT_SKIP_POSTGRES" = "false" ]]; then
  sudo /etc/init.d/postgresql start
fi

# Startup Nginx if enabled.
if [[ "$PROJECT_SKIP_NGINX" = "0" || "$PROJECT_SKIP_NGINX" = "false" ]]; then
  sudo nginx -g 'daemon on;'
fi

# Copy local host keys into tmpfs volumes on attachment.
sudo cp -r /root/.ssh /home/vscode/
#sudo cp -r /root/.aws /home/vscode/
sudo chown -R vscode:vscode /home/vscode/.ssh
sudo chmod -R u=rw,go= /home/vscode/.ssh
#sudo chown -R vscode:vscode /home/vscode/.aws
#sudo chmod -R u=rw,go= /home/vscode/.aws
sudo chmod 700 ~/.ssh/

iml_file=$(find .idea -name "*.iml")
module_name=$(basename "$iml_file" .iml)
echo "Project name: $module_name"

# Function to add a content tag before the first content tag
add_content_tag() {
    local url=$1
    if ! grep -q "<content url=\"$url\" />" "$iml_file"; then
        # Add the new content tag before MODULE_DIR content tag
        sed -i "/<content url=\"file:\/\/\$MODULE_DIR\$\">/i \    <content url=\"$url\" />" "$iml_file"
    fi
}

# Check and add content tags
if [ "$PROJECT_SKIP_ENTERPRISE" != "true" ]; then
    add_content_tag "file:///shared/$PROJECT_VERSION/enterprise"
fi
add_content_tag "file:///shared/$PROJECT_VERSION/odoo"
add_content_tag "file:///shared/$PROJECT_VERSION/odoo-stubs"

echo "IML file has been attached to shared directories."
