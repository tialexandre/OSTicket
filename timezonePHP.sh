#!/bin/bash

# Define o timezone desejado
TIMEZONE="America/Sao_Paulo"

# Encontra todos os arquivos php.ini no sistema
find / -type f -name "php.ini" 2>/dev/null | while read -r php_ini; do
    echo "Processando $php_ini..."

    # Verifica se a linha date.timezone já existe e a configura
    if grep -q "^date.timezone" "$php_ini"; then
        # Atualiza a linha existente
        sed -i "s|^date.timezone.*|date.timezone = \"$TIMEZONE\"|" "$php_ini"
        echo "Timezone atualizado em $php_ini."
    else
        # Adiciona a configuração ao final do arquivo, caso não exista
        echo -e "\n; Definindo timezone\ndate.timezone = \"$TIMEZONE\"" >> "$php_ini"
        echo "Timezone adicionado ao final de $php_ini."
    fi
done

# Mensagem de conclusão
echo "Configuração de timezone concluída em todos os arquivos php.ini encontrados."
