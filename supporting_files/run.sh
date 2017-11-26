#!/bin/bash
chown -R www-data:staff /var/www
chmod -Rf 777 /var/www/html
exec supervisord -n