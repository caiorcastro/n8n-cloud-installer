#!/bin/bash

echo "🔧 CORREÇÃO RÁPIDA - INSTALANDO NPM E COMPLETANDO INSTALAÇÃO"
echo "==========================================================="

# Instalar npm corretamente
echo "📦 Instalando npm..."
sudo apt-get update
sudo apt-get install -y npm curl

# Verificar se npm foi instalado
if ! command -v npm &> /dev/null; then
    echo "🔄 Tentando instalação via NodeSource..."
    curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
    sudo apt-get install -y nodejs
fi

# Verificar novamente
if ! command -v npm &> /dev/null; then
    echo "❌ ERRO: Não foi possível instalar npm"
    exit 1
fi

echo "✅ npm instalado com sucesso!"
echo "Versões:"
node --version
npm --version

# Instalar PM2 e N8N
echo "⚡ Instalando PM2 e N8N..."
sudo npm install -g pm2@latest --unsafe-perm
sudo npm install -g n8n@latest --unsafe-perm

# Verificar instalação
if ! command -v pm2 &> /dev/null; then
    echo "❌ ERRO: PM2 não foi instalado"
    exit 1
fi

if ! command -v n8n &> /dev/null; then
    echo "❌ ERRO: N8N não foi instalado"
    exit 1
fi

echo "✅ PM2 e N8N instalados!"

# Garantir que usuário n8n existe
sudo useradd -m -s /bin/bash n8n 2>/dev/null || echo "👤 Usuário n8n já existe"

# Criar diretórios se não existirem
sudo mkdir -p /home/n8n/.n8n /var/log/n8n /opt/n8n-data

# Configurar permissões
sudo chown -R n8n:n8n /home/n8n /var/log/n8n /opt/n8n-data

# Iniciar N8N
echo "🚀 Iniciando N8N..."
sudo su - n8n -c "cd /home/n8n && pm2 start ecosystem.config.js"
sudo su - n8n -c "pm2 save"

# Verificar status
echo "🔍 Status do N8N:"
sudo su - n8n -c "pm2 status"

# Obter IP
EXTERNAL_IP=$(curl -s ifconfig.me)
echo ""
echo "🎉 CORREÇÃO CONCLUÍDA!"
echo "🌐 Acesse: http://$EXTERNAL_IP:5678"
echo ""
echo "📋 Se precisar reiniciar:"
echo "   sudo su - n8n -c 'pm2 restart n8n'" 