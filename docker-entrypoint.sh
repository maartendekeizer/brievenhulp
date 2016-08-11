#!/usr/bin/env bash

echo Starting server

set -u
#set -e

php composer.phar install -d brievenhulp/
php brievenhulp/bin/console cache:clear --env=prod
php brievenhulp/bin/console assetic:dump --env=prod
php brievenhulp/bin/console doctrine:query:sql "CREATE EXTENSION IF NOT EXISTS \"uuid-ossp\";" --env=prod
php brievenhulp/bin/console doctrine:migrations:migrate -n --env=prod
chown -R www-data:www-data brievenhulp/var/
chmod -R 0770 brievenhulp/var/

service php7.0-fpm start
service cron start
nginx -g "daemon off;"
