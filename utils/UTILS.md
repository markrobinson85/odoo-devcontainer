
# Utilities

## Overview

These utilities are meant to offer developers a way to quickly perform common tasks within a devcontainer. 

For ease of use, the utils directory is added to the PATH variable in the devcontainer. This means you can run any of 
the scripts from anywhere within the devcontainer.

## Usage

```bash
unshallow
```
To improve build times and to reduce disk storage, the shared repositories for Odoo and Enterprise are cloned with a  
depth of 1.

If for some reason you need to have the histories of these repos, `unshallow` command will fetch the full histories of 
these repos. This will take a long time to complete.

```bash
kill_odoo
```
This command will kill any running Odoo processes. This is useful if the Odoo process continues to run even after 
terminating it from PyCharm.

```bash
kill_tests
```
This command will kill any running Odoo tests. This is useful if the tests continue to run even after terminating them 
from PyCharm.

```bash
get_db_config

# Example in a script.
source get_db_config
```
This command will export the postgres database connection specified in odoo-server.conf to the environment variables. 
You can use this command to automate restoring a database from a backup into your dev environment, or other scripts that 
need the database connection information.
