<a href="https://elest.io">
  <img src="https://elest.io/images/elestio.svg" alt="elest.io" width="150" height="75">
</a>

[![Discord](https://img.shields.io/static/v1.svg?logo=discord&color=f78A38&labelColor=083468&logoColor=ffffff&style=for-the-badge&label=Discord&message=community)](https://discord.gg/4T4JGaMYrD "Get instant assistance and engage in live discussions with both the community and team through our chat feature.")
[![Elestio examples](https://img.shields.io/static/v1.svg?logo=github&color=f78A38&labelColor=083468&logoColor=ffffff&style=for-the-badge&label=github&message=open%20source)](https://github.com/elestio-examples "Access the source code for all our repositories by viewing them.")
[![Blog](https://img.shields.io/static/v1.svg?color=f78A38&labelColor=083468&logoColor=ffffff&style=for-the-badge&label=elest.io&message=Blog)](https://blog.elest.io "Latest news about elestio, open source software, and DevOps techniques.")

# Cryptpad, verified and packaged by Elestio

[Cryptpad](https://cryptpad.org) is a collaborative office suite that is end-to-end encrypted and open-source.

<img src="https://raw.githubusercontent.com/elestio-examples/cryptpad/main/cryptpad.jpg" alt="Cryptpad" width="800">

Deploy a <a target="_blank" href="https://elest.io/open-source/cryptpad">fully managed Cryptpad</a> on <a target="_blank" href="https://elest.io/">elest.io</a> if you want automated backups, reverse proxy with SSL termination, firewall, automated OS & Software updates, and a team of Linux experts and open source enthusiasts to ensure your services are always safe, and functional.

[![deploy](https://github.com/elestio-examples/cryptpad/raw/main/deploy-on-elestio.png)](https://dash.elest.io/deploy?source=cicd&social=dockerCompose&url=https://github.com/elestio-examples/cryptpad)

# Why use Elestio images?

- Elestio stays in sync with updates from the original source and quickly releases new versions of this image through our automated processes.
- Elestio images provide timely access to the most recent bug fixes and features.
- Our team performs quality control checks to ensure the products we release meet our high standards.

# Usage

## Git clone

Before deploying a new instance of Cryptpad, you'll have to get two domains:

- your-domain.com
- sandbox-your-domain.com

You can deploy it easily with the following command:

    git clone https://github.com/elestio-examples/cryptpad.git

Copy the .env file from tests folder to the project directory

    cp ./tests/.env ./.env

Edit the .env file with your own values.

Edit the pass for your cert.pem and key.pem

Create data folders with correct permissions

    mkdir -p ./data
    mkdir -p ./data/blob
    mkdir -p ./data/block
    mkdir -p ./data/data
    mkdir -p ./data/data/logs
    mkdir -p ./data/files
    mkdir -p ./customize

    chown -R 4001:4001 ./data
    chown -R 4001:4001 ./customize

Run the project with the following command

    ./scripts/preInstall.sh
    docker-compose up -d
    ./scripts/postInstall.sh

You can access the Web UI at: `https://your-domain:37443`

## Docker-compose

Here are some example snippets to help you get started creating a container.

    version: "3"
    services:
        cryptpad:
            image: elestio4test/cryptpad:${SOFTWARE_VERSION_TAG}
            hostname: cryptpad
            restart: always
            container_name: cryptpad
            environment:
                - CPAD_MAIN_DOMAIN=${DOMAIN}
                - CPAD_SANDBOX_DOMAIN=sandbox-${DOMAIN}
                - CPAD_REALIP_HEADER=X-Forwarded-For
                - CPAD_REALIP_RECURSIVE=on
                - CPAD_TRUSTED_PROXY=172.0.0.0/8
                - CPAD_HTTP2_DISABLE=true
                - CPAD_TLS_CERT=/etc/nginx/certs/cert.pem
                - CPAD_TLS_KEY=/etc/nginx/certs/key.pem
                - CPAD_TLS_DHPARAM=/etc/nginx/dhparam.pem

            volumes:
                - ./data/blob:/cryptpad/blob
                - ./data/block:/cryptpad/block
                - ./customize:/cryptpad/customize
                - ./data/data:/cryptpad/data
                - ./data/files:/cryptpad/datastore
                - ./data/config.js:/cryptpad/config/config.js
                - /path/to/your/cert.pem:/etc/nginx/certs/cert.pem
                - /path/to/your/key.pem:/etc/nginx/certs/key.pem
                - ./data/dh.pem:/etc/nginx/dhparam.pem
                - ./data/cryptpad.conf:/etc/nginx/conf.d/cryptpad.conf

            ports:
                - "172.17.0.1:37443:443"

            ulimits:
            nofile:
                soft: 1000000
                hard: 1000000

### Environment variables

|       Variable       | Value (example) |
| :------------------: | :-------------: |
| SOFTWARE_VERSION_TAG |     latest      |
|     ADMIN_EMAIL      | your@email.com  |
|        DOMAIN        | your-domain.com |

# Maintenance

## Logging

The Elestio Cryptpad Docker image sends the container logs to stdout. To view the logs, you can use the following command:

    docker-compose logs -f

To stop the stack you can use the following command:

    docker-compose down

## Backup and Restore with Docker Compose

To make backup and restore operations easier, we are using folder volume mounts. You can simply stop your stack with docker-compose down, then backup all the files and subfolders in the folder near the docker-compose.yml file.

Creating a ZIP Archive
For example, if you want to create a ZIP archive, navigate to the folder where you have your docker-compose.yml file and use this command:

    zip -r myarchive.zip .

Restoring from ZIP Archive
To restore from a ZIP archive, unzip the archive into the original folder using the following command:

    unzip myarchive.zip -d /path/to/original/folder

Starting Your Stack
Once your backup is complete, you can start your stack again with the following command:

    docker-compose up -d

That's it! With these simple steps, you can easily backup and restore your data volumes using Docker Compose.

# Links

- <a target="_blank" href="https://github.com/cryptpad/cryptpad">Cryptpad Github repository</a>

- <a target="_blank" href="https://docs.cryptpad.org/en/">Cryptpad documentation</a>

- <a target="_blank" href="https://github.com/elestio-examples/cryptpad">Elestio/Cryptpad Github repository</a>
