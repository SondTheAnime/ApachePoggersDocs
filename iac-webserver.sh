#!/bin/bash

# Script de provisionamento para servidor web Apache
# Autor: João Victor
# Data: 05/11/2024

# Cores para output
VERDE='\033[0;32m'
VERMELHO='\033[0;31m'
NC='\033[0m' # Sem cor

# Função para exibir mensagens de log
log() {
    echo -e "${VERDE}[INFO]${NC} $1"
}

# Função para exibir erros
erro() {
    echo -e "${VERMELHO}[ERRO]${NC} $1"
    exit 1
}

# Verificar se está rodando como root
if [ "$EUID" -ne 0 ]; then 
    erro "Este script precisa ser executado como root (sudo)"
fi

# Verificar se é um sistema Ubuntu
if [ ! -f /etc/os-release ] || ! grep -q "Ubuntu" /etc/os-release; then
    erro "Este script foi projetado para sistemas Ubuntu"
fi

# Atualizar o sistema
log "Atualizando o sistema..."
apt-get update && apt-get upgrade -y || erro "Falha ao atualizar o sistema"

# Instalar Apache2
log "Instalando Apache2..."
apt-get install apache2 -y || erro "Falha ao instalar Apache2"

# Instalar unzip
log "Instalando unzip..."
apt-get install unzip -y || erro "Falha ao instalar unzip"

# Verificar e instalar git
if ! command -v git &> /dev/null; then
    log "Instalando git..."
    apt-get install git -y || erro "Falha ao instalar git"
else
    log "Git já está instalado"
fi

# Instalar Python e dependências
log "Instalando Python e dependências..."
apt-get install python3 python3-pip python3-venv libpq-dev python3-dev -y || erro "Falha ao instalar Python"

# Baixar a aplicação do GitHub
log "Baixando aplicação do GitHub..."
cd /tmp || erro "Falha ao acessar diretório /tmp"
git clone https://github.com/SondTheAnime/poggersdocs.git docestagio || erro "Falha ao clonar repositório"

# Criar diretório da aplicação
log "Configurando diretório da aplicação..."
mkdir -p /opt/docestagio
cp -r /tmp/docestagio/* /opt/docestagio/ || erro "Falha ao copiar arquivos"

# Configurar ambiente virtual Python
log "Configurando ambiente virtual Python..."
python3 -m venv /opt/docestagio/venv
source /opt/docestagio/venv/bin/activate

# Instalar dependências do projeto
log "Instalando dependências do projeto..."
cd /opt/docestagio
pip install --upgrade pip
pip install -r requirements.txt || erro "Falha ao instalar dependências do projeto"

# Configurar Django
log "Configurando Django..."
python manage.py collectstatic --noinput || erro "Falha ao coletar arquivos estáticos"
python manage.py migrate || erro "Falha ao executar migrações"

# Configurar serviço do Django
log "Configurando serviço do Django..."
cat > /etc/systemd/system/docestagio.service << EOF
[Unit]
Description=DocEstágio Django Application
After=network.target

[Service]
User=www-data
Group=www-data
WorkingDirectory=/opt/docestagio
Environment="PATH=/opt/docestagio/venv/bin"
ExecStart=/opt/docestagio/venv/bin/gunicorn --workers 3 --bind unix:/opt/docestagio/docestagio.sock docestagio.wsgi:application

[Install]
WantedBy=multi-user.target
EOF

# Configurar Apache como proxy reverso
log "Configurando Apache como proxy reverso..."
cat > /etc/apache2/sites-available/docestagio.conf << EOF
<VirtualHost *:80>
    ServerName localhost
    
    ProxyPass / unix:/opt/docestagio/docestagio.sock|http://localhost/
    ProxyPassReverse / unix:/opt/docestagio/docestagio.sock|http://localhost/

    ProxyPreserveHost On
    RequestHeader set X-Forwarded-Proto "http"
    RequestHeader set X-Forwarded-Port "80"

    Alias /static/ /opt/docestagio/static/
    <Directory /opt/docestagio/static>
        Require all granted
    </Directory>
</VirtualHost>
EOF

# Ativar módulos do Apache necessários
a2enmod proxy
a2enmod proxy_http
a2enmod headers
a2dissite 000-default
a2ensite docestagio

# Configurar permissões
log "Configurando permissões..."
chown -R www-data:www-data /opt/docestagio
chmod -R 755 /opt/docestagio

# Iniciar serviços
log "Iniciando serviços..."
systemctl daemon-reload
systemctl enable docestagio
systemctl start docestagio
systemctl restart apache2

# Configurar firewall
log "Configurando firewall..."
ufw allow 80/tcp    # HTTP
ufw allow 443/tcp   # HTTPS
ufw --force enable

# Limpar arquivos temporários
log "Limpando arquivos temporários..."
rm -rf /tmp/docestagio.zip /tmp/docestagio

# Exibir informações finais
IP_ADDR=$(hostname -I | cut -d' ' -f1)
log "Instalação concluída com sucesso!"
log "Você pode acessar o site em: http://$IP_ADDR"

exit 0