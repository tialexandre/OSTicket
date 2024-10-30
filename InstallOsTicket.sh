sudo yum update -y 
sudo yum upgrade -y

sudo dnf -y install epel-release

sudo yum update -y 
#Instalar PHP83
Versao=83
VRemi="8.3"
sudo dnf install -y https://rpms.remirepo.net/enterprise/remi-release-9.rpm
sudo dnf module reset php -y
sudo dnf module enable php:remi-${VRemi} -y

# Instalar o PHP 8.3 e os módulos especificados
sudo dnf install -y php${VRemi} 
sudo dnf install -y php${Versao}-php-json
sudo dnf install -y php${Versao}-php-pdo
sudo dnf install -y php${Versao}-php-mysqlnd
sudo dnf install -y php${Versao}-php-cli
sudo dnf install -y php${Versao}-php-fpm
sudo dnf install -y php${Versao}-php-opcache
sudo dnf install -y php${Versao}-php-pecl-igbinary
sudo dnf install -y php${Versao}-php-pecl-msgpack
sudo dnf install -y php${Versao}-php-xml
sudo dnf install -y php${Versao}-php-mbstring
sudo dnf install -y php${Versao}-php-sodium
sudo dnf install -y php${Versao}-php-gd
sudo dnf install -y php${Versao}-php-pecl-redis6
sudo dnf install -y php${Versao}-php-pecl-mcrypt
sudo dnf install -y php${Versao}-php-intl
sudo dnf install -y php${Versao}-php-pecl-zip
sudo dnf install -y php${Versao}-php-pecl-mysql 
sudo dnf install -y php${Versao}*-imap*
sudo dnf install -y php${Versao}-php-gd 
sudo dnf install -y php${Versao}-php-zip 
sudo dnf install -y php${Versao}-php*imagick-im7*
sudo dnf install -y php${Versao}-php-gd 
sudo dnf install -y php${Versao}-php-zip  
sudo dnf install -y php${Versao}*-*xmlrpc*
sudo dnf install -y php${Versao}-php-pecl-apcu
sudo dnf install -y php${Versao}-php-pecl-simdjson
sudo systemctl enable --now php83-php-fpm


echo 'LANG="pt_BR.utf8"' > /etc/locale.conf 

#desativa SELINUX
sed -i 's/enforcing/disabled/g' /etc/selinux/config

#Desativa segurança
setenforce 0
systemctl stop firewalld ; systemctl disable firewalld

#dnf install qemu-guest-agent -y
#systemctl enable --now  qemu-guest-agent 
systemctl stop firewalld
systemctl disable firewalld

#Agent Proxmox
dnf install qemu-guest-agent -y
systemctl enable --now  qemu-guest-agent 

#Instala Nginx 
sudo dnf -y install nginx
sudo systemctl enable --now nginx


#instala pacotes
sudo yum -y install mariadb mariadb-server
systemctl enable mariadb
systemctl start mariadb

#Configura MariaDB
chmod +x *.sh
./secure_mysql_auto.sh
./CreateDB_OsTicket.sh



#Ajuste users
sudo useradd -m -d /var/www/html/osticket -g apache osticket
usermod -a -G apache nginx

#Baixar osTicket
cd /tmp
git clone https://github.com/osTicket/osTicket
cd osTicket
php manage.php deploy --setup /var/www/html/osticket/
git pull
php manage.php deploy -v /var/www/html/osticket/

chown ostickett:apache -R /var/www/html/osticket
sudo chmod -R 755 /var/www/html/osticket

#Renomeie o arquivo de configuração do osTicket:
cd /var/www/html/osticket/include
sudo cp ost-sampleconfig.php ost-config.php
sudo chmod 0666 ost-config.php


#Monta Sock no PHPfPM
cat > /etc/opt/remi/php83/php-fpm.d/osticket.conf <<'EOF'
[osticket]
;cpu_affinity = 0 1 3
prefix = /var/www/system/php
user = root
group = apache

listen = \$pool.sock
listen.owner = root
listen.group = apache
listen.mode = 0660

chdir = /

catch_workers_output = yes

php_value[memory_limit] = 2048M
php_value[disable_functions] = "opcache_get_status"
php_value[error_reporting] = 22519
php_value[max_execution_time] = 90
php_value[max_input_time] = 300
php_value[max_execution_time] = 300
php_value[open_basedir] = "/var/www/vhosts/\$pool/:/tmp/"
php_value[post_max_size] = 70M
php_value[upload_max_filesize] = 70M
php_value[opcache.enable] = 1
php_value[opcache.enable_cli] = 1
php_value[opcache.revalidate_freq] = 60
php_value[opcache.fast_shutdown] = 1
php_value[opcache.enable_file_override] = 1

pm = dynamic
pm.max_requests = 500
pm.max_children = 250
pm.max_spare_servers = 30
pm.min_spare_servers = 15
pm.process_idle_timeout = 15s
pm.start_servers = 15
EOF


#Cria certificado
openssl req -x509 -nodes -days 3650 -newkey rsa:2048 -keyout /etc/pki/tls/osticket.key -out /etc/pki/tls/osticket.crt -subj "/C=SE/ST=Some-State/O=Internet Widgits Pty Ltd/CN=osticket"
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/pki/tls/localhost.key -out /etc/pki/tls/localhost.pem

cat  > /etc/nginx/vhost.d/001-osticket.conf << 'EOF'
server {
	listen *:80;
	server_name manutencao.ccv.com.br;

	root /var/www/html/osticket;

	return 301 https://osticket$request_uri;
	location ~* ^.+\.(css|js|jpg|jpeg|gif|png|ico|gz|svg|svgz|ttf|otf|woff|woff2|eot|mp4|ogg|ogv|webm|webp|zip|swf|map)$ {
		aio threads;
		# Tenta servir arquivos estáticos e retorna 404 se não encontrado
		try_files $uri $uri/ /index.php?$args;
	}


	etag off;

	location / {
	        index  index.html index.htm index.php;
	        try_files $uri $uri/ /index.php?$args;
	}
	location ~ \.php$ {
	        expires        -1d;
	        fastcgi_pass   osticket;
	        fastcgi_index  index.php;
	        fastcgi_param  SCRIPT_FILENAME  $document_root$fastcgi_script_name;
	        include        fastcgi_params;
	        fastcgi_param  PHP_VALUE "default_charset=utf-8";
	}

	access_log /var/log/nginx/osticket-access.log;
	error_log /var/log/nginx/osticket-error.log;
}

server {
	listen *:443 ssl;
	server_name osticket www.osticket;

	ssl_certificate      /etc/pki/tls/osticket.crt;
	ssl_certificate_key  /etc/pki/tls/osticket.key;

	keepalive_timeout  65;
	root /var/www/html/osticket;
	etag off;

	# Custom 
	sendfile       on;
	tcp_nopush     on;
	tcp_nodelay    on;
	proxy_ignore_client_abort on;
	client_max_body_size 100m;
	include wordpress.d/*.conf;
	location ~* ^.+\.(css|js|jpg|jpeg|gif|png|ico|gz|svg|svgz|ttf|otf|woff|woff2|eot|mp4|ogg|ogv|webm|webp|zip|swf|map)$ {
		aio threads;
		# Tenta servir arquivos estáticos e retorna 404 se não encontrado
		try_files $uri $uri/ =404;
	}


	location / {
	        index  index.html index.htm index.php;
	        try_files $uri $uri/ /index.php?$args;
	}

	location ~ \.php$ {
	        expires        -1d;
	        fastcgi_pass   osticket;
	        fastcgi_index  index.php;
	        fastcgi_param  SCRIPT_FILENAME  $document_root$fastcgi_script_name;
	        include        fastcgi_params;
	        fastcgi_param  PHP_VALUE "default_charset=utf-8";
	}

	access_log /var/log/nginx/osticket-access.log;
	error_log /var/log/nginx/osticket-error.log;
}
EOF


sudo chmod 0666 /var/www/html/osticket/include/ost-config.php
sudo systemctl restart nginx


#http://seusite.com/osticket/scp
