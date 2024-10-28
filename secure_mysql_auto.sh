#!/usr/bin/expect -f

# Inicie o mysql_secure_installation com `expect`
spawn mysql_secure_installation

# Caso a senha do root ainda não esteja configurada, envie uma resposta vazia
expect "Enter password for user root:"
send "\r"

expect "Switch to unix_socket authentication \[Y/n\]"
send "Y\r"

expect "Set root password? \[Y/n\]"
send "n\r"

expect "Remove anonymous users? \[Y/n\]"
send "Y\r"

expect "Disallow root login remotely? \[Y/n\]"
send "Y\r"

expect "Remove test database and access to it? \[Y/n\]"
send "Y\r"

expect "Reload privilege tables now? \[Y/n\]"
send "Y\r"

# Espere o processo finalizar
expect eof
