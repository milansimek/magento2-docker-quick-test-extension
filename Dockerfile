FROM phusion/baseimage

MAINTAINER Milan Simek <milan@plugin.company>

#PHP & MAGENTO VERSIONS
ARG PHP_VERSION=5.6
ARG MAGENTO_VERSION=2.0.16
ARG BASE_URL=local.dev:8080

# based on dgraziotin/lamp
# MAINTAINER Daniel Graziotin <daniel@ineed.coffee>

ENV DOCKER_USER_ID 501 
ENV DOCKER_USER_GID 20

ENV BOOT2DOCKER_ID 1000
ENV BOOT2DOCKER_GID 50

# Tweaks to give Apache/PHP write permissions to the app
RUN usermod -u ${BOOT2DOCKER_ID} www-data && \
    usermod -G staff www-data && \
    useradd -r mysql && \
    usermod -G staff mysql

RUN groupmod -g $(($BOOT2DOCKER_GID + 10000)) $(getent group $BOOT2DOCKER_GID | cut -d: -f1)
RUN groupmod -g ${BOOT2DOCKER_GID} staff

# Install packages
ENV DEBIAN_FRONTEND noninteractive
RUN add-apt-repository -y ppa:ondrej/php && \
  apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 4F4EA0AAE5267A6C && \
  apt-get update && \
  apt-get -y upgrade && \
  apt-get -y install supervisor ssmtp wget git apache2 libapache2-mod-php${PHP_VERSION} mysql-server php${PHP_VERSION} php${PHP_VERSION}-mysql php${PHP_VERSION}-curl php${PHP_VERSION}-mcrypt php${PHP_VERSION}-intl php${PHP_VERSION}-mcrypt pwgen php${PHP_VERSION}-apc php${PHP_VERSION}-mcrypt php${PHP_VERSION}-gd php${PHP_VERSION}-xml php${PHP_VERSION}-mbstring php${PHP_VERSION}-gettext zip unzip php${PHP_VERSION}-zip  php${PHP_VERSION}-soap && \
  apt-get -y autoremove && \
  echo "ServerName localhost" >> /etc/apache2/apache2.conf && \
  curl -sL https://deb.nodesource.com/setup_8.x | bash && \
  apt-get -y install nodejs && \
  npm install -g maildev

RUN sed -i -e 's/\=mail/\=0\.0\.0\.0\:1025/g' /etc/ssmtp/ssmtp.conf

# Update CLI PHP to use ${PHP_VERSION}
RUN ln -sfn /usr/bin/php${PHP_VERSION} /etc/alternatives/php

# needed for phpMyAdmin
RUN phpenmod mcrypt && phpenmod curl && phpenmod intl

# Add image configuration and scripts
ADD supporting_files/start-apache2.sh /start-apache2.sh
ADD supporting_files/start-mysqld.sh /start-mysqld.sh
ADD supporting_files/run.sh /run.sh
ADD supporting_files/runInstall.sh /runInstall.sh
ADD supporting_files/install-magento2.sh /install-magento2.sh
ADD supporting_files/debian.cnf /debian.cnf
ADD supporting_files/auth.json /auth.json
RUN chmod 755 /*.sh
ADD supporting_files/supervisord-apache2.conf /etc/supervisor/conf.d/supervisord-apache2.conf
ADD supporting_files/supervisord-mysqld.conf /etc/supervisor/conf.d/supervisord-mysqld.conf
ADD supporting_files/supervisord-cron.conf /etc/supervisor/conf.d/supervisord-cron.conf

# Set PHP timezones to Europe/London
RUN sed -i "s/;date.timezone =/date.timezone = Europe\/London/g" /etc/php/${PHP_VERSION}/apache2/php.ini
RUN sed -i "s/;date.timezone =/date.timezone = Europe\/London/g" /etc/php/${PHP_VERSION}/cli/php.ini

# Remove pre-installed database
RUN rm -rf /var/lib/mysql

# Add MySQL utils
ADD supporting_files/create_mysql_users.sh /create_mysql_users.sh
RUN chmod 755 /*.sh

# Add phpmyadmin
ENV PHPMYADMIN_VERSION=4.6.4
RUN wget -O /tmp/phpmyadmin.tar.gz https://files.phpmyadmin.net/phpMyAdmin/${PHPMYADMIN_VERSION}/phpMyAdmin-${PHPMYADMIN_VERSION}-all-languages.tar.gz
RUN tar xfvz /tmp/phpmyadmin.tar.gz -C /var/www
RUN ln -s /var/www/phpMyAdmin-${PHPMYADMIN_VERSION}-all-languages /var/www/phpmyadmin
RUN mv /var/www/phpmyadmin/config.sample.inc.php /var/www/phpmyadmin/config.inc.php

# Add composer
ENV COMPOSER_ALLOW_SUPERUSER=1
RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" && \
    php composer-setup.php && \
    php -r "unlink('composer-setup.php');" && \
    mv composer.phar /usr/local/bin/composer


ENV MYSQL_PASS:-$(pwgen -s 12 1)
# config to enable .htaccess
ADD supporting_files/apache_default /etc/apache2/sites-available/000-default.conf
RUN a2enmod rewrite

#Environment variables to configure php
ENV PHP_UPLOAD_MAX_FILESIZE 10M
ENV PHP_POST_MAX_SIZE 10M

RUN /runInstall.sh

# Add volumes for the local code directory
VOLUME  ["/var/www/html/app/code"]

EXPOSE 80

CMD ["/run.sh"]
