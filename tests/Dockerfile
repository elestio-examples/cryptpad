# Multistage build to reduce image size and increase security

FROM node:16-bullseye-slim AS build

# Install requirements to clone repository and install deps
RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -yq git \
    && npm install -g bower

# Get cryptpad from repository submodule
COPY . /cryptpad

WORKDIR /cryptpad

RUN sed -i "s@//httpAddress: '::'@httpAddress: '0.0.0.0'@" /cryptpad/config/config.example.js
RUN sed -i "s@installMethod: 'unspecified'@installMethod: 'docker'@" /cryptpad/config/config.example.js

# Install dependencies
RUN npm install --production \
    && npm run install:components


# Create actual cryptpad image
FROM node:16-bullseye-slim

RUN set -x \
    # Create users and groups for cryptpad
    && groupadd -r -g 4001 cryptpad \
    && useradd -rMs /bin/false -d /dev/null -u 4001 -g 4001 cryptpad \
    \
    # Install packages
    && apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -yq --no-install-recommends nginx supervisor openssl zlib1g \
    && rm -rf /var/lib/apt/lists/* /etc/nginx

# Copy nginx conf from official image
COPY --from=nginx:latest /etc/nginx /etc/nginx

# Change nginx user and disable server tokens
RUN sed -i -e 's@\(^user\).*[^;]@\1 www-data@' \
    -e "/default_type/a \\    server_tokens off;" /etc/nginx/nginx.conf

# Copy cryptpad with installed modules
COPY --from=build --chown=cryptpad /cryptpad /cryptpad

# Copy supervisord conf file
COPY supervisord.conf /etc/supervisord.conf

# Copy docker-entrypoint.sh script
COPY docker-entrypoint.sh /docker-entrypoint.sh

# Set workdir to cryptpad
WORKDIR /cryptpad

# Create directories
RUN mkdir blob block customize data datastore \
    && chown cryptpad:cryptpad blob block customize data datastore

# Volumes for data persistence
VOLUME /cryptpad/blob \
    /cryptpad/block \
    /cryptpad/customize \
    /cryptpad/data \
    /cryptpad/datastore

# Ports
EXPOSE 80 443

ENTRYPOINT ["/bin/sh", "/docker-entrypoint.sh"]

CMD ["/usr/bin/supervisord", "-n", "-c", "/etc/supervisord.conf"]