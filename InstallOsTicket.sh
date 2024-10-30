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


cat >  /etc/nginx/conf.d/osticket.conf <<EOF
server {
    listen 80;
    server_name manutencao.ccv.com.br;

    root /var/www/html/osticket;  # Diretório raiz do osTicket
    index index.php index.html index.htm;

    # Configuração de logs
    access_log /var/log/nginx/osticket_access.log;
    error_log /var/log/nginx/osticket_error.log;

    # Configurações de segurança e permissões
    location / {
        try_files $uri $uri/ /index.php;
    }

    # Configuração para arquivos PHP
    location ~ \.php$ {
        try_files $uri =404;
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass unix:/run/php-fpm/www.sock;  # Verifique o caminho do socket PHP-FPM
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include fastcgi_params;
    }

    # Diretório de upload
    location ~* \.(?:ico|css|js|gif|jpe?g|png)$ {
        expires 30d;
        access_log off;
        add_header Cache-Control "public";
    }

    # Segurança para bloquear acesso direto a arquivos sensíveis
    location ~ ^/ost-config\.php$ {
        deny all;
        access_log off;
        log_not_found off;
    }

    # Configurações de gzip para melhorar a performance
    gzip on;
    gzip_vary on;
    gzip_min_length 10240;
    gzip_proxied any;
    gzip_types text/plain text/css text/xml application/json application/javascript application/xml+rss application/atom+xml;
}
EOF

sudo chmod 0666 /var/www/html/osticket/include/ost-config.php
sudo systemctl restart nginx


#http://seusite.com/osticket/scp
