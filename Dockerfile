### Stage 1
FROM python:3.8.10-slim

SHELL ["/bin/bash", "-xo", "pipefail", "-c"]

# Generate locale C.UTF-8 for postgres and general locale data
ENV LANG C.UTF-8

# Install some deps, lessc and less-plugin-clean-css, and wkhtmltopdf
RUN apt-get update --allow-releaseinfo-change -y && \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        dirmngr \
        fonts-noto-cjk \
        gnupg \
        libssl-dev \
        node-less \
        npm \
        python3-num2words \
        python3-pdfminer \
        python3-pip \
        python3-phonenumbers \
        python3-pyldap \
        python3-qrcode \
        python3-renderpm \
        python3-setuptools \
        python3-slugify \
        python3-vobject \
        python3-watchdog \
        python3-xlrd \
        python3-xlwt \
        xz-utils \
        sudo \
        dos2unix \
    && curl -o wkhtmltox.deb -sSL https://github.com/wkhtmltopdf/wkhtmltopdf/releases/download/0.12.5/wkhtmltox_0.12.5-1.buster_amd64.deb \
    && echo 'ea8277df4297afc507c61122f3c349af142f31e5 wkhtmltox.deb' | sha1sum -c - \
    && apt-get install -y --no-install-recommends ./wkhtmltox.deb \
    && rm -rf /var/lib/apt/lists/* wkhtmltox.deb


# Install rtlcss (on Debian buster)
RUN npm install -g rtlcss

# Install some deps, from the odoo docs
RUN apt-get update --allow-releaseinfo-change -y && \
    apt-get install -y --no-install-recommends \
    python3-dev libxml2-dev libxslt1-dev libldap2-dev libsasl2-dev \
    libtiff5-dev \
    libjpeg62-turbo \
    libopenjp2-7-dev zlib1g-dev libfreetype6-dev \
    liblcms2-dev libwebp-dev libharfbuzz-dev libfribidi-dev libxcb1-dev libpq-dev \
    build-essential

# Copy the requirements.txt
COPY ./requirements.txt /
RUN pip3 install setuptools wheel
RUN pip3 install -r requirements.txt

# Arguments
ARG PGHOST
ARG PGDATABASE
ARG DATABASE_URL
ARG PGUSER
ARG PGPORT
ARG PGPASSWORD

ARG PORT


### Stage 2
FROM moh3azzain/odoo-dev-env:test

# Generate locale C.UTF-8 for postgres and general locale data
ENV LANG C.UTF-8

ENV HOST=$PGHOST
ENV USER=$PGUSER
ENV PASSWORD=$PGPASSWORD
ENV DATABASE=$PGDATABASE
ENV DBPORT=$PGPORT

ENV HTTPPORT=$PORT

# Copy Odoo configuration file
COPY ./odoo-dev-env/odoo.conf /etc/odoo/

RUN useradd -rm -d /home/odoo -s /bin/bash -G sudo odoo

RUN chown odoo /etc/odoo/odoo.conf && mkdir -p /var/lib/odoo && chown odoo /var/lib/odoo

WORKDIR /home/odoo/app

COPY ./odoo-dev-env/wait-for-psql.py /usr/local/bin/wait-for-psql.py
RUN dos2unix /usr/local/bin/wait-for-psql.py

# Copy the entrypoint file
COPY ./odoo-dev-env/entrypoint.sh /home/odoo
RUN dos2unix /home/odoo/entrypoint.sh

# Set default user when running the container
USER odoo

# Expose Odoo services
EXPOSE ${HTTPPORT:-8069}

# Set the default config file
ENV ODOO_RC /etc/odoo/odoo.conf


ENTRYPOINT ["/home/odoo/entrypoint.sh"]
CMD ["odoo"]

