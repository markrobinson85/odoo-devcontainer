
# Odoo Dev Container

![](.images/devcontainer-setup.png)

## Overview
Odoo Dev Container is designed to streamline the setup process for developing Odoo modules using PyCharm Professional. 
This container manages the complexities of setting up Odoo and its dependencies, including Postgres and Nginx, allowing 
you to focus on development.

This devcontainer will take care of the pain of setting up a local Odoo development environment, including:
- Cloning the Odoo repo
- Cloning the Odoo enterprise repo (if you have access)
- Installing Python dependencies
- Installing Odoo dependencies
- Installing Postgres and Nginx
- Setting up run configurations in PyCharm for Odoo
- Setting up database connections in PyCharm for Postgres

You can use JetBrains Gateway or PyCharm Professional to build and run PyCharm in a container.

For use on a project, I recommend forking or cloning this repo and making changes to suit your team's needs. 

## Prerequisites
- [Docker](https://www.docker.com/)
- [PyCharm Professional](https://www.jetbrains.com/pycharm/) >= 2023.3.2 or [JetBrains Gateway](https://www.jetbrains.com/remote-development/gateway/) >= 2023.3.2 (Requires PyCharm Professional License)
- SSH keys set up in your user's .ssh directory for cloning private repositories.
- For Windows users: Ensure the OpenSSH Authentication Agent service is running and your SSH key is added to the agent.

## Setup
### Building the Dev Container
2. Open PyCharm Professional or JetBrains Gateway.
2. Navigate to Remote Development (If you are alreay inside a project, click File > Remote Development)
3. Click the New Dev Container button.
4. Select the Docker server you want to use, should default to your local Docker server.
5. Copy and paste the git repo URL into the Git Repository field. (This repo's URL or your forked repo's URL)
6. Select the branch (version of Odoo) you want to use.
7. Click Build Container and Continue.
8. Wait for the container to build.
9. Once the container is ready, you should make sure to select PyCharm as your IDE (especially if using JetBrains Gateway).

### Configuring the Project Interpreter
The container should have prepared a venv for you automatically, but you will need to select it as the project interpreter within PyCharm.
1. If in the lower right corner you see <No interpreter>, click on it.

![](.images/add_local_interpreter.png)
2. Click Add new interpreter > Add Local Interpreter.

![](.images/select_existing_venv.png)
3. On the Add Python Interpreter screen, select Existing > Click Ok.

#### Configuring the Run Configurations

![](.images/run_configurations.png)
1. Next you'll need to set the interpreter on the built-in Run Configurations.
2. From the PyCharm main screen, to the left of the Run button, click the dropdown menu and click Edit Configurations.
3. Select one of the Run Configurations for Odoo.

![](.images/run_config_interpreter.png)
3. Where you see <No interpreter>, click on it and select the interpreter you just configured.

### Configuring the Database Connection
The container should have set up a database connection for you automatically, but there is a couple of manual steps 
required to get the database driver installed and password authenticated.
1. From the PyCharm main screen, click the Database icon on the upper right side of the screen.
2. From the database pull out, you should see a connection to the Postgres database.

![](.images/install-db-drivers.png)
3. Right click on the connection and click Download Driver Files.
4. The database drivers download and install very quickly.
5. Right click again, and click Properties. 
6. In the password field, enter the default password, odoo. Click Ok.

## Customizing the Dev Container

1. **Clone and Modify**: Clone this repository and make your desired changes to the files within the .devcontainer 
directory.
2. **Add Custom Repositories**: Include your custom repositories in the _./devcontainer/extra-repos.sh_ file.

![](.images/e9006d3a.png)
3. **Testing Customizations**: In PyCharm, when you edit the devcontainer.json file, a block icon appears near the 
opening curly bracket. Click this to access customization options. Select **_Create Container and Mount Sources_** for PyCharm 
to rebuild the container with your changes, using a bind mount to include the current project directory.
4. **Considerations for Windows and macOS Users**: Be aware that using **_Create Container and Mount Sources_** on Windows and 
macOS may lead to I/O performance issues due to the containers running within a VM. This can make bind mounts less 
efficient. While this method is suitable for testing container customizations, for day-to-day development, particularly 
on Windows and macOS, use _**Create Container and Clone Sources**_ instead, which will put your source code in a volume. 
This approach avoids the noted I/O issues. More details can be found in [Visual Studio Code's performance improvement guide](https://code.visualstudio.com/remote/advancedcontainers/improve-performance#_use-a-targeted-named-volume).

#### Environment Variables
- **PROJECT_SHORT_NAME**: Shortcode for the project, used in config files and domain names.
- **PROJECT_VERSION**: Odoo version to install. Make sure to set on both build args and containerEnv.
- **PROJECT_SKIP_ENTERPRISE**: Set to true to skip cloning the Odoo enterprise repo.
- **PROJECT_SKIP_POSTGRES**: Set to true to skip starting Postgres on attach.
- **PROJECT_SKIP_NGINX**: Set to true to skip starting Nginx on attach.
- **PROJECT_KEEP_DOTGIT**: Set to true to keep the .git directory when bind mounting locally.

#### Extra Repos
The extra-repos.sh file is used to clone additional repositories into the container.

## Usage
For use on a project, you'll want to update the extra-repos.sh file to include additional repos you need for your project. 

## License
This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details.
