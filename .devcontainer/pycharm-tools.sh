#!/bin/bash

# cmd: .devcontainer/pycharm-tools.sh -kill_test_server

# Sometimes when using PyCharm, you click stop, but the process continues to run, preventing you from re-running the process.
# This script provides a way to automatically terminate the process before starting the process again due to ports being used.

# Use with PyCharm "External Tools" as a run before launch configuration.
# To use, go to PyCharm > Settings > Tools > External Tools > Add
# Name: Kill Odoo Server
# Program: /workspace/.devcontainer/pycharm-tools.sh
# Arguments: -kill_odoo_server
# Working directory: $ProjectFileDir$

# Name: Kill Test Server
# Program: /workspace/.devcontainer/pycharm-tools.sh
# Arguments: -kill_test_server
# Working directory: $ProjectFileDir$

# To add to a run configuration, edit the run configuration and click Modify Options > Add Before Launch > External Tool.
# If your run configuration uses odoo-server.conf or odoo-server-workers.conf, select Kill Odoo Server.
# If your run configuration uses test-server.conf, select Kill Test Server.

if [[ "$1" == "-kill_odoo_server" ]]; then
    # Execute the process-killing script
    # Get the process IDs (PIDs) of processes containing "odoo-server", which will include debuggers and running the process without debugging.
    pids=$(ps aux | grep -ie 'odoo-server' | awk '{print $2}')

    # Terminate each process using SIGKILL
    for pid in $pids; do
        if kill -0 "$pid" 2>/dev/null; then
            kill -9 "$pid"
            echo "Terminated process with PID $pid"
        else
            echo "Process with PID $pid no longer exists"
        fi
    done
    exit 0
fi

if [[ "$1" == "-kill_test_server" ]]; then
    # Execute the process-killing script
    # Get the process IDs (PIDs) of processes containing "test-server" which launches when debugging.
    pids=$(ps aux | grep -ie 'test-server' | awk '{print $2}')

    # Terminate each process using SIGKILL
    for pid in $pids; do
        if kill -0 "$pid" 2>/dev/null; then
            kill -9 "$pid"
            echo "Terminated process with PID $pid"
        else
            echo "Process with PID $pid no longer exists"
        fi
    done
    exit 0
fi