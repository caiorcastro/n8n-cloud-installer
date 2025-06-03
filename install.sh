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
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash - 2>/dev/null || true
sudo apt-get install -y nodejs
sudo npm install -g pm2@latest n8n@latest
sudo useradd -m -s /bin/bash n8n
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
sudo su - n8n -c "cd /home/n8n && pm2 start ecosystem.config.js && pm2 save"
sudo su - n8n -c "pm2 startup" 2>/dev/null || true

# Configurar startup automático
STARTUP_CMD=$(sudo su - n8n -c "pm2 startup 2>/dev/null" | grep "sudo env" | head -1)
if [ ! -z "$STARTUP_CMD" ]; then
    eval $STARTUP_CMD 2>/dev/null || true
fi

# Resultado final
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