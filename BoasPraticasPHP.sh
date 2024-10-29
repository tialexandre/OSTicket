#!/bin/bash

# Define as configurações desejadas para o php.ini
TIMEZONE="America/Sao_Paulo"
MEMORY_LIMIT="512M"
MAX_EXECUTION_TIME="300"
UPLOAD_MAX_FILESIZE="20M"
POST_MAX_SIZE="25M"
ERROR_REPORTING="E_ALL & ~E_NOTICE & ~E_STRICT & ~E_DEPRECATED"
DISPLAY_ERRORS="Off"
LOG_ERRORS="On"
ERROR_LOG="/var/log/php_errors.log"
SESSION_GC_MAXLIFETIME="1440"
SESSION_SAVE_PATH="/var/lib/php/sessions"
DISABLE_FUNCTIONS="exec,passthru,shell_exec,system,proc_open,popen,show_source"
EXPOSE_PHP="Off"
MAX_INPUT_VARS="3000"
MAX_INPUT_TIME="600"
OPCACHE_ENABLE="1"
OPCACHE_MEMORY="128"
OPCACHE_MAX_FILES="4000"
OPCACHE_VALIDATE_TIMESTAMPS="1"
OPCACHE_REVALIDATE_FREQ="60"
SHORT_OPEN_TAG="Off"


# Encontra todos os arquivos php.ini no sistema
find / -type f -name "php.ini" 2>/dev/null | while read -r php_ini; do
    echo "Configurando $php_ini..."

    # Define ou atualiza cada configuração
    sed -i "s|^memory_limit.*|memory_limit = $MEMORY_LIMIT|" "$php_ini"
    sed -i "s|^max_execution_time.*|max_execution_time = $MAX_EXECUTION_TIME|" "$php_ini"
    sed -i "s|^upload_max_filesize.*|upload_max_filesize = $UPLOAD_MAX_FILESIZE|" "$php_ini"
    sed -i "s|^post_max_size.*|post_max_size = $POST_MAX_SIZE|" "$php_ini"
    sed -i "s|^date.timezone.*|date.timezone = \"$TIMEZONE\"|" "$php_ini"
    sed -i "s|^error_reporting.*|error_reporting = $ERROR_REPORTING|" "$php_ini"
    sed -i "s|^display_errors.*|display_errors = $DISPLAY_ERRORS|" "$php_ini"
    sed -i "s|^log_errors.*|log_errors = $LOG_ERRORS|" "$php_ini"
    sed -i "s|^error_log.*|error_log = $ERROR_LOG|" "$php_ini"
    sed -i "s|^session.gc_maxlifetime.*|session.gc_maxlifetime = $SESSION_GC_MAXLIFETIME|" "$php_ini"
    sed -i "s|^session.save_path.*|session.save_path = \"$SESSION_SAVE_PATH\"|" "$php_ini"
    sed -i "s|^disable_functions.*|disable_functions = $DISABLE_FUNCTIONS|" "$php_ini"
    sed -i "s|^expose_php.*|expose_php = $EXPOSE_PHP|" "$php_ini"
    sed -i "s|^max_input_vars.*|max_input_vars = $MAX_INPUT_VARS|" "$php_ini"
    sed -i "s|^max_input_time.*|max_input_time = $MAX_INPUT_TIME|" "$php_ini"
    sed -i "s|^max_input_time.*|max_input_time = $MAX_INPUT_TIME|" "$php_ini"

    # Configurações de OpCache
    sed -i "s|^opcache.enable.*|opcache.enable = $OPCACHE_ENABLE|" "$php_ini"
    sed -i "s|^opcache.memory_consumption.*|opcache.memory_consumption = $OPCACHE_MEMORY|" "$php_ini"
    sed -i "s|^opcache.max_accelerated_files.*|opcache.max_accelerated_files = $OPCACHE_MAX_FILES|" "$php_ini"
    sed -i "s|^opcache.validate_timestamps.*|opcache.validate_timestamps = $OPCACHE_VALIDATE_TIMESTAMPS|" "$php_ini"
    sed -i "s|^short_open_tag.*|short_open_tag = $SHORT_OPEN_TAG|" "$php_ini"

    # Se o timezone não existir, adiciona a configuração ao final do arquivo
    if ! grep -q "^date.timezone" "$php_ini"; then
        echo -e "\n; Definindo timezone\ndate.timezone = \"$TIMEZONE\"" >> "$php_ini"
    fi

    echo "Configurações aplicadas em $php_ini."
done

# Reiniciar o servidor web para aplicar as alterações
echo "Reiniciando o servidor web..."
systemctl restart httpd

# Mensagem de conclusão
echo "Configuração de php.ini para osTicket concluída com sucesso."

