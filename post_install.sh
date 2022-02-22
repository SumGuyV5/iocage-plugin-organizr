#!/bin/sh -x
IP_ADDRESS=$(ifconfig | grep -E 'inet.[0-9]' | grep -v '127.0.0.1' | awk '{ print $2}')

#cp nginx.conf /usr/local/etc/nginx/nginx.conf
cat > /usr/local/etc/nginx/nginx.conf <<EOF
user  www;
worker_processes  1;

events {
    worker_connections  1024;
}

http {
    include       mime.types;
    default_type  application/octet-stream;

    sendfile        on;
    keepalive_timeout  65;

    server {
        listen       80;
        server_name  sage;
        #charset koi8-r;

        #access_log  logs/host.access.log  main;

        location / {
            root   /usr/local/www/Organizr;
            index  index.php index.html index.htm;	 
	}
	location /api/v2 {
	    try_files \$uri /api/v2/index.php\$is_args\$args;
        }

        #error_page  404              /404.html;

        # redirect server error pages to the static page /50x.html
        #
        error_page   500 502 503 504  /50x.html;
        location = /50x.html {
            root   /usr/local/www/nginx-dist;
        }

        # proxy the PHP scripts to Apache listening on 127.0.0.1:80
        #
        location ~ \.php$ {
            root /usr/local/www/Organizr;
	    fastcgi_split_path_info ^(.+\.php)(/.+)$;
	    fastcgi_pass unix:/var/run/php-fpm.sock;
	    fastcgi_index index.php;
	    fastcgi_param SCRIPT_FILENAME \$request_filename;
	    include fastcgi_params;
	}
    }
}
EOF

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
echo -e "\nGo to http://$IP_ADDRESS and complete the setup.\n" >> /root/PLUGIN_INFO