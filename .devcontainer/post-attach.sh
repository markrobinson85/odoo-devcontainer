#!/bin/bash

# Startup Postgresql
sudo /etc/init.d/postgresql start

# Copy local host keys into tmpfs volumes on attachment.
sudo cp -r /root/.ssh /home/vscode/
sudo cp -r /root/.aws /home/vscode/
sudo chown -R vscode:vscode /home/vscode/.ssh
sudo chmod -R u=rw,go= /home/vscode/.ssh
sudo chown -R vscode:vscode /home/vscode/.aws
sudo chmod -R u=rw,go= /home/vscode/.aws
sudo chmod 700 ~/.ssh/
