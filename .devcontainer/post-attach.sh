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
sudo chown -R vscode:vscode /home/vscode/.ssh
sudo chmod -R u=rw,go= /home/vscode/.ssh
sudo chmod 700 /home/vscode/.ssh/

# Define the directory to be added to PATH
utils_dir="$PROJECT_WORKSPACE_FOLDER/utils"

# Define the user's .bashrc file
bashrc="$HOME/.bashrc"

# Define the path to your Python virtual environment
venv_path="$PROJECT_WORKSPACE_FOLDER/venv"

# Check if the utils directory is already in PATH
if ! grep -q "$utils_dir" "$bashrc"; then
    # If not, append the export command to .bashrc
    echo "export PATH=\"\$PATH:$utils_dir\"" >> "$bashrc"
    echo "Added $utils_dir to PATH in $bashrc"
else
    echo "$utils_dir is already in PATH"
fi

# Make the scripts executable
chmod +x "$utils_dir"/*

# Add alias to activate the Python virtual environment
if ! grep -q "alias activatevenv" "$bashrc"; then
    echo "alias activatevenv='source $venv_path/bin/activate'" >> "$bashrc"
    echo "Added alias to activate Python venv in $bashrc"
else
    echo "Alias to activate Python venv already exists in $bashrc"
fi

# Reload .bashrc to apply changes immediately
source "$bashrc"

# Activate the Python virtual environment
source "$venv_path/bin/activate"
