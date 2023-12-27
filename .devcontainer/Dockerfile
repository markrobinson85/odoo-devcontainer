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

USER vscode

CMD ["bash"]
