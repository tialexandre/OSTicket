#!/bin/bash

# Defina a senha de root do MySQL
DB_NAME="osticket"
DB_USER="otuser"
DB_PASSWORD="123456"

# Executa os comandos no MySQL/MariaDB
mysql -u root <<EOF
CREATE DATABASE IF NOT EXISTS $DB_NAME;
GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASSWORD';
FLUSH PRIVILEGES;
EOF

echo "Banco de dados '$DB_NAME' criado com sucesso e permissões concedidas ao usuário '$DB_USER'."
