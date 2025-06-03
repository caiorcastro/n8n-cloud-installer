# 🚀 N8N Cloud Installer

**Instalação automática e completa do N8N em máquinas virtuais no Google Cloud com persistência total.**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Shell Script](https://img.shields.io/badge/Shell-Script-blue.svg)](https://www.gnu.org/software/bash/)
[![N8N](https://img.shields.io/badge/N8N-Latest-purple.svg)](https://n8n.io/)

## 🎯 O que este instalador faz?

✅ **Instalação completamente automatizada** do N8N em VMs do Google Cloud  
✅ **Persistência total** - usuários, senhas e workflows salvos permanentemente  
✅ **Auto-restart** em caso de falhas ou reinicialização da VM  
✅ **Zero configuração manual** necessária  
✅ **Limpeza automática** de instalações anteriores  
✅ **Firewall configurado** automaticamente  

## ⚡ Instalação Ultra-Rápida

### 1️⃣ Conecte na sua VM
```bash
# Google Cloud Console → Compute Engine → VM instances → SSH
```

### 2️⃣ Execute este comando único:
```bash
curl -fsSL https://raw.githubusercontent.com/caiorcastro/n8n-cloud-installer/main/install.sh | bash
```

### 3️⃣ Acesse o N8N
- O script mostrará a URL de acesso: `http://SEU_IP:5678`
- Crie sua conta de administrador (será salva permanentemente!)
- Comece a criar seus workflows!

## 🔧 Scripts Disponíveis

### 📦 `install.sh` - Instalador Principal
Script principal que faz tudo automaticamente:
- Limpa instalações anteriores
- Instala Node.js, PM2 e N8N
- Configura persistência total
- Inicia o serviço automaticamente

### 🔍 `verify.sh` - Verificação e Diagnóstico
Script para verificar se tudo está funcionando:
```bash
curl -fsSL https://raw.githubusercontent.com/caiorcastro/n8n-cloud-installer/main/verify.sh | bash
```

## 📋 Requisitos

- **VM no Google Cloud** (recomendado: e2-micro ou superior)
- **Ubuntu/Debian** (testado no Ubuntu 20.04+)
- **Porta 5678** liberada no firewall
- **Acesso sudo** na VM

## 🛠️ Pós-Instalação

### Comandos Úteis:
```bash
# Ver status do N8N
sudo su - n8n -c 'pm2 status'

# Ver logs em tempo real
sudo su - n8n -c 'pm2 logs n8n'

# Reiniciar N8N
sudo su - n8n -c 'pm2 restart n8n'

# Parar N8N
sudo su - n8n -c 'pm2 stop n8n'
```

### Localização dos Dados:
- **Banco de dados:** `/opt/n8n-data/database.sqlite`
- **Configurações:** `/home/n8n/.n8n/`
- **Logs:** `/var/log/n8n/`

## 🔥 Características Técnicas

- **Banco SQLite** para máxima simplicidade e portabilidade
- **PM2** para gerenciamento de processo e auto-restart
- **Usuário dedicado** (`n8n`) para segurança
- **Logs organizados** e timestampados
- **Configuração de ambiente** otimizada para VMs pequenas
- **Startup automático** no boot da VM

## 🚨 Solução de Problemas

### N8N não está acessível?
```bash
# Execute o script de diagnóstico
curl -fsSL https://raw.githubusercontent.com/caiorcastro/n8n-cloud-installer/main/verify.sh | bash
```

### Precisa reinstalar?
```bash
# Execute novamente o instalador
curl -fsSL https://raw.githubusercontent.com/caiorcastro/n8n-cloud-installer/main/install.sh | bash
```

## ⏱️ Tempo de Instalação

- **VM e2-micro:** 3-5 minutos
- **VM e2-small:** 2-3 minutos
- **VM e2-medium:** 1-2 minutos

## 💡 Dicas

1. **Free Tier:** Funciona perfeitamente na VM e2-micro do Google Cloud (Free Tier)
2. **Região:** Use `us-west1-c` para melhor latência no Brasil
3. **Backup:** O banco SQLite pode ser facilmente copiado para backup
4. **Escalabilidade:** Para uso intensivo, considere VMs maiores

## 📝 Licença

MIT License - veja o arquivo [LICENSE](LICENSE) para detalhes.

## 🤝 Contribuindo

Contribuições são bem-vindas! Sinta-se à vontade para:
- Reportar bugs
- Sugerir melhorias
- Enviar pull requests

---

**🎉 Desenvolvido para facilitar o uso do N8N no Google Cloud!** 