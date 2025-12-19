#!/bin/bash
set -e

echo "🚀 Starting Telegram Watcher Agent"

APP_DIR="/opt/telegram-watcher"
REGION="${region}"

# -----------------------------
# Atualiza sistema e instala dependências
# -----------------------------
yum update -y
yum install -y python3 awscli
pip3 install --upgrade pip
pip3 install telethon boto3

# -----------------------------
# Cria diretório da aplicação
# -----------------------------
mkdir -p $APP_DIR

# -----------------------------
# Cria o agent.py
# -----------------------------
cat << 'EOF' > $APP_DIR/agent.py
from telethon import TelegramClient, events
import asyncio
import logging
import os

logging.basicConfig(
    format="[%(levelname) 5s/%(asctime)s] %(name)s: %(message)s",
    level=logging.WARNING
)

API_ID = int(os.environ["API_ID"])
API_HASH = os.environ["API_HASH"]
SESSION_NAME = "session"

channels_env = os.environ.get("CHANNELS", "")
if not channels_env:
    print("❌ Variável CHANNELS não definida")
    exit(1)

CHANNELS = channels_env.split(",")

client = TelegramClient(SESSION_NAME, API_ID, API_HASH)

@client.on(events.NewMessage(chats=CHANNELS))
async def handler_new_message(event):
    try:
        canal_origem = f"@{event.chat.username}"
    except Exception:
        canal_origem = "Canal desconhecido"

    print("="*50)
    print(f"📥 NOVA MENSAGEM DE: {canal_origem}")
    if event.raw_text:
        print(event.raw_text[:300])
    else:
        print("Mensagem contém mídia.")
    print("="*50)

async def main():
    await client.start()
    await client.run_until_disconnected()

if __name__ == "__main__":
    asyncio.run(main())
EOF

# -----------------------------
# Busca parâmetros no SSM
# -----------------------------
export API_ID=$(aws ssm get-parameter \
  --name "/btc_tweet_agent/api_id" \
  --region "$REGION" \
  --query "Parameter.Value" \
  --output text)

export API_HASH=$(aws ssm get-parameter \
  --name "/btc_tweet_agent/api_hash" \
  --with-decryption \
  --region "$REGION" \
  --query "Parameter.Value" \
  --output text)

export CHANNELS=$(aws ssm get-parameter \
  --name "/btc_tweet_agent/channel" \
  --region "$REGION" \
  --query "Parameter.Value" \
  --output text)

# -----------------------------
# Roda o bot em background
# -----------------------------
nohup python3 $APP_DIR/agent.py > $APP_DIR/agent.log 2>&1 &
