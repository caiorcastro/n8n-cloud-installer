#!/bin/bash

echo "🔧 CORREÇÃO DEFINITIVA - NODE.JS 20 + N8N"
echo "=========================================="

# Parar qualquer processo do N8N que esteja rodando
echo "⏹️ Parando processos existentes..."
sudo pkill -f n8n 2>/dev/null || true
sudo su - n8n -c "pm2 kill" 2>/dev/null || true

# Remover instalações antigas
echo "🧹 Removendo versões antigas..."
sudo npm uninstall -g n8n pm2 2>/dev/null || true

# Instalar Node.js 20 via NodeSource
echo "📦 Instalando Node.js 20..."
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs

# Verificar versão
echo "✅ Nova versão instalada:"
node --version
npm --version

# Verificar se é Node.js 20+
NODE_VERSION=$(node --version | cut -d'.' -f1 | sed 's/v//')
if [ "$NODE_VERSION" -lt 20 ]; then
    echo "❌ ERRO: Node.js $NODE_VERSION é muito antigo. N8N precisa do Node.js 20+"
    exit 1
fi

echo "✅ Node.js 20+ detectado!"

# Instalar PM2 e N8N
echo "⚡ Instalando PM2 e N8N (pode demorar alguns minutos)..."
sudo npm install -g pm2@latest --unsafe-perm
echo "✅ PM2 instalado!"

echo "📦 Instalando N8N..."
sudo npm install -g n8n@latest --unsafe-perm || {
    echo "⚠️ Tentando instalação forçada..."
    sudo npm install -g n8n@latest --unsafe-perm --force
}

# Verificar instalação
if ! command -v pm2 &> /dev/null; then
    echo "❌ ERRO: PM2 não foi instalado"
    exit 1
fi

if ! command -v n8n &> /dev/null; then
    echo "❌ ERRO: N8N não foi instalado"
    exit 1
fi

echo "✅ Tudo instalado com sucesso!"

# Garantir que usuário n8n existe
sudo useradd -m -s /bin/bash n8n 2>/dev/null || echo "👤 Usuário n8n já existe"

# Criar diretórios se não existirem
sudo mkdir -p /home/n8n/.n8n /var/log/n8n /opt/n8n-data

# Recriar arquivo de configuração (caso tenha sido perdido)
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

# Recriar configuração do PM2
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

# Configurar permissões
sudo chown -R n8n:n8n /home/n8n /var/log/n8n /opt/n8n-data

# Iniciar N8N
echo "🚀 Iniciando N8N em BACKGROUND (roda mesmo com SSH desconectado)..."
sudo su - n8n -c "cd /home/n8n && pm2 start ecosystem.config.js"
sleep 3
sudo su - n8n -c "pm2 save"

# Configurar para iniciar automaticamente no boot
echo "🔄 Configurando início automático..."
sudo su - n8n -c "pm2 startup" 2>/dev/null || true
STARTUP_CMD=$(sudo su - n8n -c "pm2 startup 2>/dev/null" | grep "sudo env" | head -1)
if [ ! -z "$STARTUP_CMD" ]; then
    eval $STARTUP_CMD 2>/dev/null || true
fi

# Verificar status
echo "🔍 Status final:"
sudo su - n8n -c "pm2 status"

# Obter IP
EXTERNAL_IP=$(curl -s ifconfig.me)
echo ""
echo "🎉 INSTALAÇÃO DEFINITIVA CONCLUÍDA!"
echo "🌐 Acesse: http://$EXTERNAL_IP:5678"
echo ""
echo "✅ CARACTERÍSTICAS:"
echo "   🔥 Roda em BACKGROUND - pode desligar SSH"
echo "   🔄 Auto-restart se falhar"
echo "   🚀 Inicia automaticamente no boot da VM"
echo "   💾 Dados salvos permanentemente"
echo ""
echo "📋 Comandos úteis:"
echo "   Status: sudo su - n8n -c 'pm2 status'"
echo "   Logs: sudo su - n8n -c 'pm2 logs n8n'"
echo "   Reiniciar: sudo su - n8n -c 'pm2 restart n8n'"
echo ""
echo "🎯 Agora pode desconectar o SSH - N8N continuará rodando!" 