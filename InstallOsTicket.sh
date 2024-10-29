sudo yum update -y 
sudo yum upgrade -y

sudo dnf -y install epel-release

sudo yum update -y 
sudo yum install  -y  install expect 
sudo yum install  -y  glibc-langpack-en 
sudo yum install  -y  glibc-langpack-pt
sudo yum install  -y  git
sudo yum install  -y  vim
sudo yum install  -y  wget
sudo yum install  -y  net-tools
sudo yum install  -y  htop
sudo yum install  -y  iftop
sudo yum install  -y  iotop
sudo yum install  -y  nload
sudo yum install  -y  nmon
sudo yum install  -y  nethogs
sudo yum install  -y  ntfs-3g
sudo yum install  -y  sshfs
sudo yum install  -y  parted
sudo yum install  -y  net-tools
sudo yum install  -y  ethtool 
sudo yum install  -y  unzip 

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

#instala pacotes
sudo yum -y install mariadb mariadb-server
systemctl enable mariadb
systemctl start mariadb

#Instalação do Apache
sudo yum -y  install httpd
systemctl start httpd
systemctl enable httpd

#Intalação do PHP5e alguns Módulos necessários.
sudo dnf install -y https://rpms.remirepo.net/enterprise/remi-release-9.rpm
sudo dnf module enable php:remi-8.4  # ou a versão desejada
sudo dnf install -y php php-mysqlnd php-zip php-intl php-imap php-gd php-mbstring php-xml php-curl php-cli php-pear php-devel
sudo pecl install apcu
echo "extension=apcu.so" | sudo tee /etc/php.d/40-apcu.ini

#Configura MariaDB
chmod +x *.sh
./secure_mysql_auto.sh
./CreateDB_OsTicket.sh

#Baixar osTicket
cd /tmp
git clone https://github.com/osTicket/osTicket
cd osTicket
php manage.php deploy --setup /var/www/html/osticket/
git pull
php manage.php deploy -v /var/www/html/osticket/

#configura apache
sudo chown -R apache:apache /var/www/html/osticket
sudo chmod -R 755 /var/www/html/osticket

#Renomeie o arquivo de configuração do osTicket:
cd /var/www/html/osticket/include
sudo cp ost-sampleconfig.php ost-config.php
sudo chmod 0666 ost-config.php


cat > /etc/httpd/conf.d/osticket.conf <<EOF
<VirtualHost *:80>
    ServerAdmin admin@seusite.com
    DocumentRoot /var/www/html/osticket
    ServerName seusite.com

    <Directory /var/www/html/osticket>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog /var/log/httpd/osticket_error.log
    CustomLog /var/log/httpd/osticket_access.log combined
</VirtualHost>
EOF

sudo chmod 0666 /var/www/html/osticket/include/ost-config.php
sudo systemctl restart httpd


#http://seusite.com/osticket/scp
