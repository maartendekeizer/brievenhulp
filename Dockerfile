FROM nginx
MAINTAINER datapunt.ois@amsterdam.nl

EXPOSE 80

# add basic packages
RUN apt-get update \
 && apt-get clean \
 && apt-get install -y curl git vim wget cron

# add dotdeb
COPY Docker/dotdeb.list /etc/apt/sources.list.d/dotdeb.list
RUN wget https://www.dotdeb.org/dotdeb.gpg \
 && apt-key add dotdeb.gpg

# install php packages
RUN apt-get update \
 && apt-get clean \
 && apt-get install -y php7.0-fpm php7.0-intl php7.0-pgsql php7.0-curl php7.0-cli php7.0-gd php7.0-intl php7.0-mbstring php7.0-mcrypt php7.0-opcache php7.0-sqlite3 php7.0-xml php7.0-xsl php7.0-zip

# create basic directory
RUN mkdir -p /srv/web/brievenhulp

# project setup
COPY . /srv/web/brievenhulp
WORKDIR /srv/web
COPY /Docker/parameters.yml /srv/web/brievenhulp/app/config/parameters.yml
COPY /Docker/fix-null-values.php /srv/web/brievenhulp/app/config/fix-null-values.php
RUN wget https://getcomposer.org/composer.phar

# nginx and php setup
COPY Docker/brievenhulp.vhost /etc/nginx/conf.d/brievenhulp.vhost.conf
RUN rm /etc/nginx/conf.d/default.conf \
 && sed -i '/\;listen\.mode\ \=\ 0660/c\listen\.mode=0666' /etc/php/7.0/fpm/pool.d/www.conf \
 && sed -i '/pm.max_children = 5/c\pm.max_children = 20' /etc/php/7.0/fpm/pool.d/www.conf \
 && sed -i '/\;pm\.max_requests\ \=\ 500/c\pm\.max_requests\ \=\ 100' /etc/php/7.0/fpm/pool.d/www.conf \
 && echo "server_tokens off;" > /etc/nginx/conf.d/extra.conf \
 && echo "client_max_body_size 20m;" >> /etc/nginx/conf.d/extra.conf \
 && sed -i '/upload_max_filesize \= 2M/c\upload_max_filesize \= 20M' /etc/php/7.0/fpm/php.ini \
 && sed -i '/post_max_size \= 8M/c\post_max_size \= 21M' /etc/php/7.0/fpm/php.ini \
 && sed -i '/\;date\.timezone \=/c\date.timezone = Europe\/Amsterdam' /etc/php/7.0/fpm/php.ini \
 && sed -i '/\;security\.limit_extensions \= \.php \.php3 \.php4 \.php5 \.php7/c\security\.limit_extensions \= \.php' /etc/php/7.0/fpm/pool.d/www.conf \
 && sed -e 's/;clear_env = no/clear_env = no/' -i /etc/php/7.0/fpm/pool.d/www.conf

RUN php composer.phar install -d brievenhulp/ --prefer-dist --no-scripts

# cronjob set
#COPY Docker/brievenhulp.cron /etc/cron.d/brievenhulp

# redirect logging to stderr
#RUN touch /var/log/cron.log \
# && chmod ugo+rwx /var/log/cron.log
# RUN mkdir -p brievenhulp/var/logs \ 
# && ln -s /dev/stderr brievenhulp/var/logs/dev.log \
# && ln -s /dev/stderr brievenhulp/var/logs/prod.log \
# && ln -s /dev/stderr /var/log/php7.0-fpm.log \
# && ln -s /dev/stdout /var/log/cron.log

# run
COPY docker-entrypoint.sh /docker-entrypoint.sh
CMD /docker-entrypoint.sh
