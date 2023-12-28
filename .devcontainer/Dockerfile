FROM mcr.microsoft.com/devcontainers/base:ubuntu-20.04

# Setup Python 3.8
RUN apt update && apt install -y software-properties-common
RUN curl -fsSL https://apt.releases.hashicorp.com/gpg | apt-key add -
RUN apt-add-repository "deb [arch=$(dpkg --print-architecture)] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
RUN add-apt-repository -y ppa:deadsnakes/ppa
RUN apt install -y wget
RUN apt install -y build-essential python3.8 python3.8-dev python3-dev libxml2-dev libxslt1-dev libldap2-dev libsasl2-dev libtiff5-dev libjpeg8-dev libopenjp2-7-dev zlib1g-dev libfreetype6-dev liblcms2-dev libwebp-dev libharfbuzz-dev libfribidi-dev libxcb1-dev libpq-dev python3-pip python3.8-venv
RUN apt install -y awscli unzip terraform=1.6.5-1
RUN apt install -y npm

## Install wkhtmltopdf and pypdf2
RUN wget https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6-1/wkhtmltox_0.12.6-1.$(lsb_release -cs)_amd64.deb
RUN apt install -y ./wkhtmltox_0.12.6-1.$(lsb_release -cs)_amd64.deb
RUN apt install -y python3-pypdf2

# Clean up downloads
RUN rm wkhtmltox_0.12.6-1.focal_amd64.deb

RUN npm install -g less less-plugin-clean-css

# Enable persisting of bash command history
ARG USERNAME=vscode

RUN SNIPPET="export PROMPT_COMMAND='history -a' && export HISTFILE=/commandhistory/.bash_history" \
    && mkdir /commandhistory \
    && touch /commandhistory/.bash_history \
    && chown -R $USERNAME /commandhistory \
    && echo "$SNIPPET" >> "/home/$USERNAME/.bashrc"

## -- TEMPORARY --
## Install Postgres 15/Nginx into same container since docker-compose bug exists in JetBrains Gateway.
RUN wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -
RUN sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt/ focal-pgdg main" >> /etc/apt/sources.list.d/pgdg.list'
RUN apt-get update && apt-get install -y postgresql-15 postgresql-client-15

# Add VOLUMEs to allow backup of config, logs and databases
VOLUME  ["/etc/postgresql", "/var/log/postgresql", "/var/lib/postgresql"]

# Adjust PostgreSQL configuration to allow remote connections
RUN echo "host all  all    0.0.0.0/0  md5" >> /etc/postgresql/15/main/pg_hba.conf
RUN echo "listen_addresses='*'" >> /etc/postgresql/15/main/postgresql.conf

USER postgres
RUN /etc/init.d/postgresql start && \
    psql --command "CREATE USER odoo WITH SUPERUSER PASSWORD 'odoo';"

USER root
RUN apt-get install -y nginx
VOLUME ["/var/lib/nginx/cache/dev", "/var/log/nginx"]

## -- TEMPORARY --

USER vscode
# Setup volume for Odoo data.
RUN mkdir -p /home/vscode/.local/Odoo
VOLUME /home/vscode/.local/Odoo

CMD ["bash"]
