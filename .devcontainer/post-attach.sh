#!/bin/bash

# Startup Postgresql if enabled.
if [[ "$PROJECT_SKIP_POSTGRES" = "0" || "$PROJECT_SKIP_POSTGRES" = "false" ]]; then
  sudo /etc/init.d/postgresql start
fi

# Startup Nginx if enabled.
if [[ "$PROJECT_SKIP_NGINX" = "0" || "$PROJECT_SKIP_NGINX" = "false" ]]; then
  nginx -g 'daemon on;'
fi

# Copy local host keys into tmpfs volumes on attachment.
sudo cp -r /root/.ssh /home/vscode/
sudo cp -r /root/.aws /home/vscode/
sudo chown -R vscode:vscode /home/vscode/.ssh
sudo chmod -R u=rw,go= /home/vscode/.ssh
sudo chown -R vscode:vscode /home/vscode/.aws
sudo chmod -R u=rw,go= /home/vscode/.aws
sudo chmod 700 ~/.ssh/
