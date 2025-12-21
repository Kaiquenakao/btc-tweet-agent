#!/bin/bash
set -e

# Log de tudo para debug
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

echo "🚀 Starting Telegram Watcher Agent Setup"

APP_DIR="/opt/telegram-watcher"
REGION="${region}"

# 1. Instalação usando o gerenciador de pacotes do Amazon Linux 2023
yum update -y
yum install -y python3 python3-pip awscli

# 2. Instala as dependências usando o módulo do python para evitar erro de "command not found"
python3 -m pip install telethon boto3

mkdir -p $APP_DIR
cd $APP_DIR

# 3. Busca Parâmetros no SSM
echo "Reading parameters from SSM..."
API_ID=$(aws ssm get-parameter --name "/btc_tweet_agent/api_id" --region "sa-east-1" --query "Parameter.Value" --output text)
API_HASH=$(aws ssm get-parameter --name "/btc_tweet_agent/api_hash" --with-decryption --region "sa-east-1" --query "Parameter.Value" --output text)
CHANNELS=$(aws ssm get-parameter --name "/btc_tweet_agent/channel" --region "sa-east-1" --query "Parameter.Value" --output text)
SESSION_NAME=$(aws ssm get-parameter --name "/btc_tweet_agent/session_name" --with-decryption --region "sa-east-1" --query "Parameter.Value" --output text)

echo "Parameters retrieved successfully."
echo "API_ID: $API_ID"
echo "CHANNELS: $CHANNELS"

# 4. Cria o arquivo Python
cat << 'EOF' > $APP_DIR/agent.py
from telethon import TelegramClient, events
from telethon.sessions import StringSession
import asyncio
import os
import logging

logging.basicConfig(level=logging.INFO)

API_ID = int(os.environ["API_ID"])
API_HASH = os.environ["API_HASH"]
CHANNELS = os.environ["CHANNELS"].split(",")
SESSION_NAME = os.environ.get("SESSION_NAME")

logging.info(f"Watching channels: {CHANNELS}")
logging.info(f"Using session: {SESSION_NAME}")
logging.info(f"API_ID: {API_ID}")
logging.info(f"API_HASH: {API_HASH}")

client = TelegramClient(SESSION_NAME, API_ID, API_HASH)

@client.on(events.NewMessage(chats=CHANNELS))
async def handler(event):
    try:
        chat = await event.get_chat()
        sender = getattr(chat, 'username', 'Canal Privado')
        print(f"📥 MENSAGEM: @{sender}: {event.raw_text}")
    except Exception as e:
        print(f"Erro: {e}")

async def main():
    await client.start()
    print("✅ Bot Conectado!")
    await client.run_until_disconnected()

if __name__ == "__main__":
    asyncio.run(main())
EOF

# 5. Configuração do Serviço
cat <<EOF > /etc/systemd/system/telegram-agent.service
[Unit]
Description=Telegram Watcher Agent
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=$APP_DIR
Environment="API_ID=$API_ID"
Environment="API_HASH=$API_HASH"
Environment="CHANNELS=$CHANNELS"
Environment="SESSION_NAME=$SESSION_NAME"
ExecStart=/usr/bin/python3 $APP_DIR/agent.py
Restart=always

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable telegram-agent
systemctl start telegram-agent

echo "✅ Setup Finalizado com Sucesso!"