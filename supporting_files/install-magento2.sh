#!/bin/bash
mkdir -p ~/.composer
cp /auth.json ~/.composer/auth.json

rm -Rf /var/www/html/*
rm -Rf /var/www/html/.[^.]*
cd /var/www/html

echo "creating database magento"
mysql -uadmin -ppassword123 -e "create database magento" 2>&1 | grep -v "Warning: Using a password"
if [ $@ ]; then
  composer create-project --repository-url=https://repo.magento.com/ magento/project-community-edition:$1 . ;
else
  composer create-project --repository-url=https://repo.magento.com/ magento/project-community-edition . ;
fi

php -f ./bin/magento setup:install --base-url=http://${BASE_URL}/ \
    --db-host=localhost \
    --db-name=magento \
    --db-user=admin \
    --db-password=password123 \
    --admin-firstname=Magento \
    --admin-lastname=Commerce \
    --admin-email=user@example.com \
    --admin-user=admin \
    --admin-password=password123 \
    --language=en_US \
    --currency=USD \
    --timezone=America/Chicago \
    --use-rewrites=1 \
    --backend-frontname=admin \
    --use-sample-data

php -f ./bin/magento indexer:set-mode schedule \
&& cp /auth.json var/composer_home/auth.json \
&& php -f ./bin/magento sampledata:deploy \
&& php -f ./bin/magento setup:upgrade \
&& php -f ./bin/magento indexer:reindex \
&& php -f ./bin/magento cache:flush \
&& php -f ./bin/magento deploy:mode:set developer

echo "updating permissions for webserver"
chmod -Rf 777 .
chown -R www-data:staff .

echo "enabling error reporting"
sed -i -e 's/#ini_set/ini_set/g' app/bootstrap.php
