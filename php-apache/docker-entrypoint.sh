#!/bin/bash
# set -ex

if  [[ "$1" == apache2* ]];
then

    # Check for existing installation
    if [ -d admin/interface -a -f admin/interface/version.php -a -s config.php ];
    then

        # Get installed version
        INSTALLED_VERSION=$(php -r 'require "admin/interface/version.php"; echo WBCE_VERSION;')
        echo >&2 "Seeing installed WBCE Version ${INSTALLED_VERSION}"

        # For now we can asume, that minor and patchlevel stay
        # at one-digit values
        if [ $(echo ${INSTALLED_VERSION} | tr -d .) -gt $( echo ${WBCE_VERSION} | tr -d .) ];
        then
            echo >&2 "Fatal error: Installed WBCE version is newer than"
            echo >&2 "the one in this image: ${WBCE_VERSION}! Aborting."
            exit
        fi

        if [ ${INSTALLED_VERSION} != ${WBCE_VERSION} ];
        then
            echo >&2 "Installing WBCE version ${WBCE_VERSION} over ${INSTALLED_VERSION}"

            if [ ! -s wbce-update-exclude ];
            then
                echo <<EOF > wbce-update-exclude
wbce/favicon.ico
wbce/config.php.new
EOF
            fi

            # Get sources from WBCE project
            echo >&2 "Getting source for WBCE V${WBCE_VERSION} from official repository..."
            wget -q https://github.com/WBCE/WBCE_CMS/archive/refs/tags/${WBCE_VERSION}.tar.gz -O /tmp/wbce.tar.gz

            # Untar sources
            echo >&2 "Extracting source..."
            su www-data -s /bin/sh -c 'tar \
                --strip-components=2 \
                --exclude-from=wbce-update-exclude \
                -zxf /tmp/wbce.tar.gz'

            if [ -s wbce-update.patch ];
            then
                echo >&2 "Patching source using wbce-update.patch..."
                patch  -p0 < wbce-update.patch
            fi

            # Run update.sh!
            cat <<EOF > install/updatewrapper.php
<?php
\$_POST['backup_confirmed'] = 'confirmed';
\$_POST['send'] = 'Start+update+script';
require_once './update.php';
EOF

            # Get database host
            DB_HOST=$(php -r 'require "config.php"; echo DB_HOST;')

            /wait-for-it.sh -t 40 ${DB_HOST}:3306
            result=$(su www-data -s /bin/sh -c 'cd install; /usr/local/bin/php ./updatewrapper.php')

            if [ $(echo ${result} | grep -c Congratulations) -ne 1 ];
            then

                WB_URL=$(php -r 'require "config.php"; echo DB_HOST;')

                echo >&2 "Fatal: Something went wrong. Please run"
                echo >&2
                echo >&2 " ${WB_URL}/install/update.php"
                echo >&2
                echo >&2 "manually!"
            else

                # Tidy up
                echo >&2 "Deleting install directory"
                rm -Rf install

                echo >&2 "**********************************************"
                echo >&2 "Complete: WBCE has been successfully updated"
                echo >&2
                echo >&2 "Please check, if everything is working"
                echo >&2 "Also you maybe need to updates modules"
                echo >&2 "**********************************************"

            fi
        fi
    else

        # Get sources from WBCE project
        echo >&2 "Getting source for WBCE V${WBCE_VERSION} from official repository..."
        wget -q https://github.com/WBCE/WBCE_CMS/archive/refs/tags/${WBCE_VERSION}.tar.gz -O /tmp/wbce.tar.gz

        # Untar sources
        echo >&2 "Extracting source..."
        tar \
            --strip-components=2 \
            -zxf /tmp/wbce.tar.gz

        # Patch Installation process
        patch -p0 < /save.patch

        # The installation process needs an existing config.php
        if [ ! -f config.php ];
        then
            touch config.php
            chown www-data: ./config.php
        fi

        # All files should belong to www-data
        chown -R www-data: /var/www/html

        if [ -z "${DATABASE_USERNAME}" -o -z "${DATABASE_PASSWORD}" ];
        then

            echo >&2 "**************************************************"
            echo >&2 "Complete: WBCE files have been successfully copied"
            echo >&2
            echo >&2 "You need to install WBCE via calling"
            echo >&2 "   http[s]://<yourhost>/admin/login/"
            echo >&2
            echo >&2 "**************************************************"

        else

            # Prepare installation
            #
            # WBCE won't allow direct configuration, so we have to
            # simulate the installation process


            # Set defaults
            : "${WBCE_URL:=http://localhost}"
            : "${WBCE_LANGUAGE:=EN}"

            : "${WBCE_WEBSITE_TITLE:=WBCE Docker Site}"
            : "${WBCE_ADMIN_USERNAME:=admin}"
            : "${WBCE_ADMIN_EMAIL:=admin@please.change}"

            : "${DATABASE_HOST:=mysql}"
            : "${DATABASE_NAME:=wbce}"
            : "${DATABASE_TABLE_PREFIX:=wbce_}"

            # Read from secrets
            if [ -f /run/secrets/database_username ]; then
                DATABASE_USERNAME=$(cat /run/secrets/database_username)
            fi
            if [ -f /run/secrets/database_password ]; then
                DATABASE_PASSWORD=$(cat /run/secrets/database_password)
            fi
            if [ -f /run/secrets/wbce_admin_username ]; then
                WBCE_ADMIN_USERNAME=$(cat /run/secrets/wbce_admin_username)
            fi
            if [ -f /run/secrets/wbce_admin_password ]; then
                WBCE_ADMIN_PASSWORD=$(cat /run/secrets/wbce_admin_password)
            fi

            # Create fallback password for admin
            WBCE_ADMIN_RANDOM_PASSWORD=$(< /dev/urandom tr -dc A-Za-z0-9 | head -c14)

            # Create initialization wrapper script containing $_POST
            cat <<EOF > install/initialize.php
<?php
define("WB_DEBUG", false);
\$_POST['url'] = '';
\$_POST['username_fieldname'] = 'admin_username';
\$_POST['password_fieldname'] = 'admin_password';
\$_POST['remember'] = 'true';
\$_POST['install'] = 'Install+WBCE+CMS';
\$_POST['operating_system'] = 'linux';
\$_POST['website_title'] = '${WBCE_WEBSITE_TITLE}';
\$_POST['wb_url'] = '${WBCE_URL}';
\$_POST['default_timezone'] = '0';
\$_POST['default_language'] = '${WBCE_LANGUAGE}';
\$_POST['database_host'] = '${DATABASE_HOST}';
\$_POST['database_name'] = '${DATABASE_NAME}';
\$_POST['table_prefix'] = '${DATABASE_TABLE_PREFIX}';
\$_POST['database_username'] = '${DATABASE_USERNAME}';
\$_POST['database_password'] = '${DATABASE_PASSWORD}';
\$_POST['admin_username'] = '${WBCE_ADMIN_USERNAME}';
\$_POST['admin_email'] = '${WBCE_ADMIN_EMAIL}';
\$_POST['admin_password'] = '${WBCE_ADMIN_PASSWORD:-${WBCE_ADMIN_RANDOM_PASSWORD}}';
\$_POST['admin_repassword'] = \$_POST['admin_password'];
require_once './save.php';
EOF

            # Call installation routine as user www-data
            # This process will exit false of not successfull
            /wait-for-it.sh -t 40 mariadb:3306
            cd install; su www-data -s /bin/sh -c '/usr/local/bin/php ./initialize.php; exit $?'

            result=$?
            [ ${result} -ne 0 ] && exit ${result}

            # Tidy up
            echo >&2 "Deleting install directory"
            rm -Rf install

            echo >&2 "**********************************************"
            echo >&2 "Complete: WBCE has been successfully installed"
            echo >&2
            echo >&2 "You can log in to admin panel calling"
            echo >&2 "    ${WBCE_URL}/admin/login/"
            echo >&2
            if [ -z ${WBCE_ADMIN_PASSWORD} ];
            then
                echo >&2
                echo >&2 "using the credentials ${WBCE_ADMIN_USERNAME} / ${WBCE_ADMIN_RANDOM_PASSWORD}"
            fi
            echo >&2 "**********************************************"

        fi
    fi
fi

exec "$@"
