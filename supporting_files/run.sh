#!/bin/bash

echo "starting MySQL"
service mysql start

echo "enabling all modules"
cd /var/www/html
bin/magento module:enable --all

echo "clearing caches"
bin/magento cache:clean

echo "removing generated code"
rm -Rf ./var/generation/*
rm -Rf ./generated/code/*

echo "running setup:upgrade"
bin/magento setup:upgrade

echo "running setup:di:compile"
bin/magento setup:di:compile

echo "updating permissions for webserver"
chmod -Rf 777 .
chown -R www-data:staff .

echo "running deploy:mode:set production"
bin/magento deploy:mode:set production

echo "updating permissions for webserver"
chmod -Rf 777 .
chown -R www-data:staff .

echo "starting maildev"
maildev &

exec supervisord -n