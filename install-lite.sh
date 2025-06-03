#!/bin/bash

echo "🚀 INSTALADOR OTIMIZADO PARA VM PEQUENA (1GB RAM)"
echo "================================================="

# Parar qualquer processo em execução
echo "⏹️ Limpando processos..."
sudo pkill -f npm 2>/dev/null || true
sudo pkill -f node 2>/dev/null || true
sudo pkill -f n8n 2>/dev/null || true
sudo su - n8n -c "pm2 kill" 2>/dev/null || true

# Limpar cache do npm para liberar espaço
echo "🧹 Limpando cache..."
sudo npm cache clean --force 2>/dev/null || true
sudo rm -rf /tmp/npm-* 2>/dev/null || true

# Aumentar swap temporariamente
echo "💾 Configurando swap temporário..."
sudo fallocate -l 1G /swapfile || sudo dd if=/dev/zero of=/swapfile bs=1024 count=1048576
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile

# Verificar se Node.js 20 está instalado
if ! command -v node &> /dev/null; then
    echo "📦 Instalando Node.js 20..."
    curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
    sudo apt-get install -y nodejs
fi

NODE_VERSION=$(node --version | cut -d'.' -f1 | sed 's/v//')
if [ "$NODE_VERSION" -lt 20 ]; then
    echo "🔄 Atualizando para Node.js 20..."
    curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
    sudo apt-get install -y nodejs
fi

echo "✅ Node.js $(node --version) | npm $(npm --version)"

# Criar usuário se não existir
sudo useradd -m -s /bin/bash n8n 2>/dev/null || echo "👤 Usuário n8n já existe"
sudo mkdir -p /home/n8n/.n8n /var/log/n8n /opt/n8n-data

# Instalar PM2 primeiro (mais leve)
echo "⚡ Instalando PM2..."
sudo npm install -g pm2@latest --unsafe-perm --no-optional --production

# Instalar N8N com configurações otimizadas
echo "📦 Instalando N8N (versão otimizada)..."
echo "⚠️  Isso pode demorar 5-10 minutos em VM pequena..."

# Configurar npm para usar menos memória
npm config set maxsockets 1
npm config set cache-max 0

# Instalar N8N com flags otimizadas
sudo npm install -g n8n@latest \
    --unsafe-perm \
    --no-optional \
    --production \
    --maxsockets=1 \
    --max_old_space_size=700

# Verificar instalação
if ! command -v pm2 &> /dev/null; then
    echo "❌ ERRO: PM2 não foi instalado"
    exit 1
fi

if ! command -v n8n &> /dev/null; then
    echo "❌ ERRO: N8N não foi instalado"
    exit 1
fi

echo "✅ Instalação concluída!"

# Configuração otimizada para VM pequena
sudo tee /home/n8n/.n8n/config.env > /dev/null << 'EOF'
N8N_HOST=0.0.0.0
N8N_PORT=5678
N8N_PROTOCOL=http
N8N_LOG_LEVEL=warn
N8N_USER_FOLDER=/home/n8n/.n8n
DB_TYPE=sqlite
DB_SQLITE_DATABASE=/opt/n8n-data/database.sqlite
EXECUTIONS_DATA_SAVE_ON_ERROR=all
EXECUTIONS_DATA_SAVE_ON_SUCCESS=all
EXECUTIONS_DATA_SAVE_MANUAL_EXECUTIONS=true
EXECUTIONS_DATA_PRUNE=false
# Otimizações para VM pequena
NODE_OPTIONS=--max_old_space_size=700
N8N_DIAGNOSTICS_ENABLED=false
N8N_VERSION_NOTIFICATIONS_ENABLED=false
EOF

# Configuração PM2 otimizada
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
    max_memory_restart: '850M',
    restart_delay: 10000,
    error_file: '/var/log/n8n/error.log',
    out_file: '/var/log/n8n/out.log',
    log_file: '/var/log/n8n/combined.log',
    time: true,
    node_args: ['--max_old_space_size=700']
  }]
};
EOF

# Configurar permissões
sudo chown -R n8n:n8n /home/n8n /var/log/n8n /opt/n8n-data

# Iniciar N8N
echo "🚀 Iniciando N8N..."
sudo su - n8n -c "cd /home/n8n && pm2 start ecosystem.config.js"
sleep 5
sudo su - n8n -c "pm2 save"

# Configurar startup
sudo su - n8n -c "pm2 startup" 2>/dev/null || true
STARTUP_CMD=$(sudo su - n8n -c "pm2 startup 2>/dev/null" | grep "sudo env" | head -1)
if [ ! -z "$STARTUP_CMD" ]; then
    eval $STARTUP_CMD 2>/dev/null || true
fi

# Limpar swap temporário
echo "🧹 Limpando swap temporário..."
sudo swapoff /swapfile
sudo rm -f /swapfile

# Status final
EXTERNAL_IP=$(curl -s ifconfig.me)
sudo su - n8n -c "pm2 status"

echo ""
echo "🎉 N8N OTIMIZADO INSTALADO!"
echo "🌐 Acesse: http://$EXTERNAL_IP:5678"
echo ""
echo "✅ OTIMIZAÇÕES APLICADAS:"
echo "   💾 Uso máximo de memória: 700MB"
echo "   🔄 Restart automático em 850MB"
echo "   📊 Logs reduzidos (warn apenas)"
echo "   🚀 Configuração para VM pequena"
echo ""
echo "📋 Comandos úteis:"
echo "   Status: sudo su - n8n -c 'pm2 status'"
echo "   Logs: sudo su - n8n -c 'pm2 logs n8n'"
echo "   Monitorar: sudo su - n8n -c 'pm2 monit'" 