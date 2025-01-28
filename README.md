# Running WBCE in a Docker Container

The simplest method is to run the *inofficial* image:

```sh
docker run -e DATABASE_HOST=maridb -e DATABSE_USER=wbce -e DATABASE_PASSWORD=secret-dbpassword -p 8000:80 -d bjalbor/wbce
```

where the values should be replaced with parameters which suit your needs.

## Tags

The `latest` tags always contain the **latest stable** version of WBCE with the latest version of the `php-apache` base images available. 

## Configuration/Environment Variables

If using a configured WBCE instance, e.g. when migrating from a standalone webserver, all configuration is in file `config.php` in document root.

The following env variables **must** be set for initializing a brand new WBCE Docker instance:

`DATABASE_USERNAME` - Username to connect to Database. Mandatory!

`DATABASE_PASSWORD` - Password to connect to Database. Mandatory!

These optional env variables **can** be set to configure your WBCE Docker instance:

`DATABASE_HOST` - Name of Database to connect to. Defaults to `mysql`.

`DATABASE_NAME` - Name of Database to connect to. Defaults to `wbce`.

`DATABASE_TABLE_PREFIX` - Table prefix for Database. Defaults to `wbce_`.

More optional parameters are:

`WBCE_URL` - Complete URL of the server to connect to. Defaults to `http://localhost`.

`WBCE_WEBSITE_TITLE` - Title of Website. Can be changed afterwards. Defaults to `WBCE Docker Site`.

`WBCE_ADMIN_USERNAME` - Username of first admin User. Defaults to `admin`.

`WBCE_ADMIN_PASSWORD` - Password of first admin User. Randomly value if not set.

`WBCE_LANGUAGE` - Language code. Defaults to `US`.

`WBCE_ADMIN_EMAIL` - email address of admin user.

## Database Connection

Before starting the container, please make sure that the supplied database exists and the given database user has privileges to acces (and create if building a new instance) tables.

Run it with a link to the MySQL/MariaDB host and the username/password variables:

```sh
docker run --link=mysql:mysql -d bjalbor/wbce
```

## Persistent data

The WBCE containers do not store any data persistently by default. There are, however,
some directories that should be mounted as volume or bind mount to keep persistent data:

* `/var/www/html`: WBCE installation directory
  This is the document root of WBCE. 

## Docker Secrets

When running the WBCE container in a Docker Swarm, you can use [Docker Secrets](https://docs.docker.com/engine/swarm/secrets/)
to share credentials across all instances. The following secrets are currently supported by WBCE:

* `database_username`: Database connection username (mappend to `DATABASE_USERNAME`)
* `database_password`: Database connection password (mappend to `DATABASE_PASSWORD`)
* `wbce_admin_username`: Admin username (mapped to `WBCE_ADMIN_USERNAME`)
* `wbce_admin_password`: Admin username (mapped to `WBCE_ADMIN_PASSWORD`)

## HTTPS

Currently all images are configured to speak HTTP. To provide HTTPS please run an additional reverse proxy in front of them, which handles certificates and terminates TLS. Alternatively you could derive from our images to make Apache or nginx provide HTTPS – but please refrain from opening issues asking for support with such a setup.


## Examples

A example setup using `docker-compose` can be found in the [Github repository](https://github.com/bjalbor/wbce-docker/tree/master/examples).

## Building a Docker image

Use the `Dockerfile` in this repository to build your own Docker image.
It pulls the latest build of WBCE from the Github download page and builds it on top of a `php:8.1-apache` Docker image.

Build it from the php-apache directories with

```sh
docker build -t wbce .
```

You can also create your own Docker image by extending from this image.

# Caveats

Upgrading of WBCE is currently not implemented and hopefully will come soon.

# License

This program is free software: you can redistribute it and/or modify it under the terms
of the GNU General Public License as published by the Free Software Foundation, either
version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
See the GNU General Public License for more details.
