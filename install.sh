#!/bin/bash

# COMANDO ÚNICO - INSTALAÇÃO COMPLETA DO N8N COM PERSISTÊNCIA
echo "🚀 INSTALAÇÃO AUTOMÁTICA DO N8N - COMANDO ÚNICO"
echo "==============================================="

# Limpeza completa primeiro
echo "🧹 LIMPANDO INSTALAÇÕES ANTERIORES..."
sudo pkill -f n8n 2>/dev/null || true
sudo su - n8n -c "pm2 kill" 2>/dev/null || true
sudo userdel -r n8n 2>/dev/null || true
sudo npm uninstall -g n8n pm2 2>/dev/null || true
sudo rm -rf /var/log/n8n /opt/n8n-data 2>/dev/null || true
sudo crontab -r 2>/dev/null || true

echo "✅ Limpeza concluída!"

# Instalação completa
echo "🚀 INSTALANDO N8N..."
sudo apt update -y

# Instalar Node.js e npm
echo "📦 Instalando Node.js e npm..."
if ! command -v node &> /dev/null || ! command -v npm &> /dev/null; then
    # Primeiro tentar via apt
    sudo apt-get install -y nodejs npm curl
    
    # Se npm não estiver disponível, instalar via NodeSource
    if ! command -v npm &> /dev/null; then
        echo "🔄 Instalando Node.js via NodeSource..."
        curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
        sudo apt-get install -y nodejs
    fi
    
    # Verificar novamente
    if ! command -v npm &> /dev/null; then
        echo "❌ Erro: npm não foi instalado. Tentando instalação manual..."
        curl -L https://www.npmjs.com/install.sh | sudo sh
    fi
fi

# Verificar se npm está funcionando
if ! command -v npm &> /dev/null; then
    echo "❌ ERRO: npm não pôde ser instalado. Abortando..."
    exit 1
fi

echo "✅ Versões instaladas:"
node --version
npm --version

# Instalar PM2 e N8N
echo "⚡ Instalando PM2 e N8N..."
sudo npm install -g pm2@latest || {
    echo "❌ Erro ao instalar PM2. Tentando com --unsafe-perm..."
    sudo npm install -g pm2@latest --unsafe-perm
}

sudo npm install -g n8n@latest || {
    echo "❌ Erro ao instalar N8N. Tentando com --unsafe-perm..."
    sudo npm install -g n8n@latest --unsafe-perm
}

# Verificar se foram instalados
if ! command -v pm2 &> /dev/null; then
    echo "❌ ERRO: PM2 não foi instalado corretamente"
    exit 1
fi

if ! command -v n8n &> /dev/null; then
    echo "❌ ERRO: N8N não foi instalado corretamente"
    exit 1
fi

echo "✅ PM2 e N8N instalados com sucesso!"

# Criar usuário dedicado para N8N
echo "👤 Criando usuário n8n..."
sudo useradd -m -s /bin/bash n8n || true
sudo mkdir -p /home/n8n/.n8n /var/log/n8n /opt/n8n-data

# Configuração persistente
echo "⚙️ CONFIGURANDO PERSISTÊNCIA..."
sudo tee /home/n8n/.n8n/config.env > /dev/null << 'EOF'
N8N_HOST=0.0.0.0
N8N_PORT=5678
N8N_PROTOCOL=http
N8N_LOG_LEVEL=info
N8N_USER_FOLDER=/home/n8n/.n8n
DB_TYPE=sqlite
DB_SQLITE_DATABASE=/opt/n8n-data/database.sqlite
EXECUTIONS_DATA_SAVE_ON_ERROR=all
EXECUTIONS_DATA_SAVE_ON_SUCCESS=all
EXECUTIONS_DATA_SAVE_MANUAL_EXECUTIONS=true
EXECUTIONS_DATA_PRUNE=false
EOF

# Configuração PM2
sudo tee /home/n8n/ecosystem.config.js > /dev/null << 'EOF'
module.exports = {
  apps: [{
    name: 'n8n',
    script: 'n8n',
    args: 'start',
    cwd: '/home/n8n',
    user: 'n8n',
    env_file: '/home/n8n/.n8n/config.env',
    instances: 1,
    autorestart: true,
    watch: false,
    max_memory_restart: '900M',
    restart_delay: 5000,
    error_file: '/var/log/n8n/error.log',
    out_file: '/var/log/n8n/out.log',
    log_file: '/var/log/n8n/combined.log',
    time: true
  }]
};
EOF

# Permissões e inicialização
echo "🔐 CONFIGURANDO PERMISSÕES E INICIANDO..."
sudo chown -R n8n:n8n /home/n8n /var/log/n8n /opt/n8n-data
sudo ufw allow 5678 2>/dev/null || true

# Iniciar N8N com PM2
echo "🚀 Iniciando N8N..."
sudo su - n8n -c "cd /home/n8n && pm2 start ecosystem.config.js"
sleep 3
sudo su - n8n -c "pm2 save"

# Configurar startup automático
echo "🔄 Configurando startup automático..."
sudo su - n8n -c "pm2 startup" 2>/dev/null || true
STARTUP_CMD=$(sudo su - n8n -c "pm2 startup 2>/dev/null" | grep "sudo env" | head -1)
if [ ! -z "$STARTUP_CMD" ]; then
    eval $STARTUP_CMD 2>/dev/null || true
fi

# Verificar status
echo "🔍 Verificando status..."
sleep 5
EXTERNAL_IP=$(curl -s ifconfig.me)
sudo su - n8n -c "pm2 status"

echo ""
echo "🎉 INSTALAÇÃO CONCLUÍDA COM SUCESSO!"
echo "🌐 ACESSE: http://$EXTERNAL_IP:5678"
echo "🔐 Crie seu usuário e senha - serão salvos PERMANENTEMENTE!"
echo ""
echo "📋 Comandos úteis:"
echo "   Status: sudo su - n8n -c 'pm2 status'"
echo "   Logs: sudo su - n8n -c 'pm2 logs n8n'"
echo "   Reiniciar: sudo su - n8n -c 'pm2 restart n8n'"
echo ""
echo "🔍 Para verificar se tudo está funcionando:"
echo "   curl -fsSL https://raw.githubusercontent.com/caiorcastro/n8n-cloud-installer/main/verify.sh | bash" 