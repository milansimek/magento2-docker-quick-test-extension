#!/bin/bash

VOLUME_HOME="/var/lib/mysql"

sed -ri -e "s/^upload_max_filesize.*/upload_max_filesize = ${PHP_UPLOAD_MAX_FILESIZE}/" \
    -e "s/^post_max_size.*/post_max_size = ${PHP_POST_MAX_SIZE}/" /etc/php/${PHP_VERSION}/apache2/php.ini

sed -i "s/export APACHE_RUN_GROUP=www-data/export APACHE_RUN_GROUP=staff/" /etc/apache2/envvars

sed -i -e "s/cfg\['blowfish_secret'\] = ''/cfg['blowfish_secret'] = '`date | md5sum`'/" /var/www/phpmyadmin/config.inc.php

mkdir -p /var/run/mysqld

if [ -n "$VAGRANT_OSX_MODE" ];then
    usermod -u $DOCKER_USER_ID www-data
    groupmod -g $(($DOCKER_USER_GID + 10000)) $(getent group $DOCKER_USER_GID | cut -d: -f1)
    groupmod -g ${DOCKER_USER_GID} staff
    chmod -R 770 /var/lib/mysql
    chmod -R 770 /var/run/mysqld
    chown -R www-data:staff /var/lib/mysql
    chown -R www-data:staff /var/run/mysqld
else
    # Tweaks to give Apache/PHP write permissions to the app
    chown -R www-data:staff /var/www
    chown -R www-data:staff /app
    chown -R www-data:staff /var/lib/mysql
    chown -R www-data:staff /var/run/mysqld
    chmod -R 770 /var/lib/mysql
    chmod -R 770 /var/run/mysqld
fi

rm /var/run/mysqld/mysqld.sock

sed -i "s/bind-address.*/bind-address = 0.0.0.0/" /etc/mysql/my.cnf
sed -i "s/user.*/user = www-data/" /etc/mysql/my.cnf

if [[ ! -d $VOLUME_HOME/mysql ]]; then
    echo "=> An empty or uninitialized MySQL volume is detected in $VOLUME_HOME"
    echo "=> Installing MySQL ..."

    # Try the 'preferred' solution
    mysqld --initialize-insecure > /dev/null 2>&1

    # IF that didn't work
    if [ $? -ne 0 ]; then
        # Fall back to the 'depreciated' solution
        mysql_install_db > /dev/null 2>&1
    fi

    echo "=> Done!"  
    /create_mysql_users.sh
    echo "copying debian.cnf"
    cp -f /debian.cnf /etc/mysql/
else
    echo "=> Using an existing volume of MySQL"
fi

if [[ ! -f /var/www/html/index.php ]]; then
    tset xterm
    bold=$(tput bold)
    normal=$(tput sgr0)
    green=$(tput setaf 3)
    white=$(tput setaf 7)
    echo "${bold}${green}Installing Magento 2 ## ${normal}${white}"
    service mysql start
    /install-magento2.sh ${MAGENTO_VERSION}
    service mysql stop
else
    echo "=> Magento is already installed"
fi

service cron stop
