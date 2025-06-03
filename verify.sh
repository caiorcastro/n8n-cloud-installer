#!/bin/bash

# Script de Verificação e Diagnóstico do N8N
echo "🔍 VERIFICAÇÃO DO STATUS DO N8N"
echo "=============================="

# Verificar se o usuário n8n existe
if id "n8n" &>/dev/null; then
    echo "✅ Usuário n8n existe"
else
    echo "❌ Usuário n8n não existe"
    exit 1
fi

# Verificar se N8N está instalado
if command -v n8n &> /dev/null; then
    echo "✅ N8N está instalado globalmente"
    echo "   Versão: $(n8n --version)"
else
    echo "❌ N8N não está instalado"
fi

# Verificar se PM2 está instalado
if command -v pm2 &> /dev/null; then
    echo "✅ PM2 está instalado"
    echo "   Versão: $(pm2 --version)"
else
    echo "❌ PM2 não está instalado"
fi

echo ""
echo "📊 STATUS DOS PROCESSOS:"
echo "========================"

# Status do PM2
echo "🔄 Status do PM2:"
sudo su - n8n -c "pm2 status" 2>/dev/null || echo "❌ PM2 não está rodando ou não configurado"

echo ""
echo "🔥 STATUS DO FIREWALL:"
echo "====================="
sudo ufw status

echo ""
echo "📁 ESTRUTURA DE ARQUIVOS:"
echo "========================"

# Verificar diretórios importantes
directories=(
    "/home/n8n"
    "/home/n8n/.n8n"
    "/opt/n8n-data"
    "/var/log/n8n"
)

for dir in "${directories[@]}"; do
    if [ -d "$dir" ]; then
        echo "✅ $dir existe"
        echo "   Propriedade: $(ls -ld $dir | awk '{print $3":"$4}')"
    else
        echo "❌ $dir não existe"
    fi
done

# Verificar arquivos importantes
files=(
    "/home/n8n/.n8n/config.env"
    "/home/n8n/ecosystem.config.js"
    "/opt/n8n-data/database.sqlite"
)

echo ""
echo "📄 ARQUIVOS IMPORTANTES:"
for file in "${files[@]}"; do
    if [ -f "$file" ]; then
        echo "✅ $file existe"
        echo "   Tamanho: $(ls -lh $file | awk '{print $5}')"
    else
        echo "❌ $file não existe"
    fi
done

echo ""
echo "🌐 CONECTIVIDADE:"
echo "================"

# Obter IP externo
EXTERNAL_IP=$(curl -s ifconfig.me 2>/dev/null)
if [ ! -z "$EXTERNAL_IP" ]; then
    echo "✅ IP externo: $EXTERNAL_IP"
    echo "🌐 URL do N8N: http://$EXTERNAL_IP:5678"
else
    echo "❌ Não foi possível obter IP externo"
fi

# Verificar se a porta 5678 está ouvindo
if ss -tuln | grep -q ":5678 "; then
    echo "✅ Porta 5678 está ouvindo"
else
    echo "❌ Porta 5678 não está ouvindo"
fi

echo ""
echo "📝 LOGS RECENTES:"
echo "================"

# Mostrar logs recentes
if [ -f "/var/log/n8n/combined.log" ]; then
    echo "🔍 Últimas 10 linhas do log:"
    tail -10 /var/log/n8n/combined.log
else
    echo "❌ Arquivo de log não encontrado"
fi

echo ""
echo "🔧 COMANDOS DE SOLUÇÃO:"
echo "======================"

# Verificar se PM2 está rodando N8N
N8N_STATUS=$(sudo su - n8n -c "pm2 describe n8n" 2>/dev/null | grep -c "online" || echo "0")

if [ "$N8N_STATUS" -eq 0 ]; then
    echo "❌ N8N não está rodando. Execute:"
    echo "   sudo su - n8n -c 'pm2 start ecosystem.config.js'"
    echo "   sudo su - n8n -c 'pm2 save'"
else
    echo "✅ N8N está rodando via PM2"
fi

echo ""
echo "🛠️ COMANDOS ÚTEIS:"
echo "   Reiniciar N8N: sudo su - n8n -c 'pm2 restart n8n'"
echo "   Ver logs em tempo real: sudo su - n8n -c 'pm2 logs n8n'"
echo "   Parar N8N: sudo su - n8n -c 'pm2 stop n8n'"
echo "   Status detalhado: sudo su - n8n -c 'pm2 describe n8n'"

echo ""
echo "🔄 TESTE DE CONECTIVIDADE LOCAL:"
echo "==============================="

# Teste local
LOCAL_TEST=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:5678 2>/dev/null || echo "000")
if [ "$LOCAL_TEST" = "200" ]; then
    echo "✅ N8N responde localmente"
elif [ "$LOCAL_TEST" = "000" ]; then
    echo "❌ N8N não responde localmente (não está rodando)"
else
    echo "⚠️ N8N responde com código: $LOCAL_TEST"
fi 