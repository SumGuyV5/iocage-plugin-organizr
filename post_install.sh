#!/bin/sh -x
IP_ADDRESS=$(ifconfig | grep -E 'inet.[0-9]' | grep -v '127.0.0.1' | awk '{ print $2}')
MY_SERVER_NAME=$(hostname)

mkdir -p /usr/local/etc/ssl/private/
mkdir -p /usr/local/etc/ssl/certs/

openssl genrsa -out nginx-selfsigned.key 2048

openssl req -new -x509 -days 365 -key nginx-selfsigned.key -out nginx-selfsigned.crt -sha256 -subj "/C=CA/ST=ONTARIO/L=TORONTO/O=Global Security/OU=IT Department/CN=${MY_SERVER_NAME}"

mv nginx-selfsigned.key /usr/local/etc/ssl/private/
mv nginx-selfsigned.crt /usr/local/etc/ssl/certs/

echo 'listen = /var/run/php-fpm.sock' >> /usr/local/etc/php-fpm.conf
echo 'listen.owner = www' >> /usr/local/etc/php-fpm.conf
echo 'listen.group = www' >> /usr/local/etc/php-fpm.conf
echo 'listen.mode = 0660' >> /usr/local/etc/php-fpm.conf

cp /usr/local/etc/php.ini-production /usr/local/etc/php.ini
sed -i '' -e 's?;date.timezone =?date.timezone = "Universal"?g' /usr/local/etc/php.ini
sed -i '' -e 's?;cgi.fix_pathinfo=1?cgi.fix_pathinfo=0?g' /usr/local/etc/php.ini

git clone -b v2-develop https://github.com/causefx/Organizr /usr/local/www/Organizr

chown -R www:www /usr/local/www

sysrc nginx_enable=YES
sysrc php_fpm_enable=YES

service nginx start
service php-fpm start

echo -e "Organizr now installed.\n" > /root/PLUGIN_INFO
echo -e "\nGo to https://$IP_ADDRESS and complete the setup.\n" >> /root/PLUGIN_INFO