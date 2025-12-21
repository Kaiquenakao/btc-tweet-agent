#!/bin/bash
set -e

# Log de tudo para debug
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

echo "🚀 Starting Telegram Watcher Agent Setup"

APP_DIR="/opt/telegram-watcher"
REGION="${region}"

yum update -y
yum install -y python3 python3-pip awscli


python3 -m pip install telethon boto3

mkdir -p $APP_DIR
cd $APP_DIR

echo "Reading parameters from SSM..."
API_ID=$(aws ssm get-parameter --name "/btc_tweet_agent/api_id" --region "sa-east-1" --query "Parameter.Value" --output text)
API_HASH=$(aws ssm get-parameter --name "/btc_tweet_agent/api_hash" --with-decryption --region "sa-east-1" --query "Parameter.Value" --output text)
CHANNELS=$(aws ssm get-parameter --name "/btc_tweet_agent/channel" --region "sa-east-1" --query "Parameter.Value" --output text)
SESSION_ID=$(aws ssm get-parameter --name "/btc_tweet_agent/session_id" --with-decryption --region "sa-east-1" --query "Parameter.Value" --output text)

echo "Parameters retrieved successfully."
echo "API_ID: $API_ID"
echo "CHANNELS: $CHANNELS"

cat << 'EOF' > $APP_DIR/agent.py
import os
import asyncio
import logging
from telethon import TelegramClient, events
from telethon.sessions import StringSession

# Configura logging para systemd
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s"
)

# Lê variáveis de ambiente
try:
    API_ID = int(os.environ["API_ID"])
    API_HASH = os.environ["API_HASH"]
    CHANNELS = os.environ["CHANNELS"].split(",")
    SESSION_ID = os.environ.get("SESSION_ID")
except KeyError as e:
    logging.exception(f"Variável de ambiente faltando: {e}")
    raise SystemExit(1)
except ValueError as e:
    logging.exception(f"Erro ao converter API_ID para inteiro: {e}")
    raise SystemExit(1)

logging.info(f"Watching channels: {CHANNELS}")
logging.info(f"Using session: {SESSION_ID}")
logging.info(f"API_ID: {API_ID}")
logging.info(f"API_HASH: {API_HASH}")

# Cria cliente Telegram
client = TelegramClient(StringSession(SESSION_ID), API_ID, API_HASH)
logging.info(f"Cliente Telegram criado com sucesso. {client}")

resolved_channels = {}

@client.on(events.NewMessage(chats=CHANNELS))
async def handler_new_message(event):
    """Chamado sempre que QUALQUER canal da lista enviar mensagem"""

    # Identifica de onde veio a mensagem
    try:
        canal_origem = f"@{event.chat.username}"
    except:
        canal_origem = "Canal desconhecido"

    mensagem_text = event.raw_text

    logging.info("====================================")
    logging.info(f"NOVA MENSAGEM DE: {canal_origem}")

    if mensagem_text:
        logging.info(f"Texto (início):\n{mensagem_text}...")
    else:
        logging.info("Mensagem contém mídia (foto, vídeo, etc).")

    logging.info("====================================\n")

    # Encaminha para "Mensagens Salvas" (chat pessoal)
    try:
        await event.forward_to("me")
    except Exception as e:
        logging.info(f"Aviso: não foi possível encaminhar. Erro: {e}")


# ----------------------------------------------------------
# PROGRAMA PRINCIPAL
async def main():
    logging.info("-------------------------------------------------------------------")
    logging.info("Iniciando monitoramento dos seguintes canais:")
    for c in CHANNELS:
        logging.info(f" - {c}")

    await client.start()

    if not await client.is_user_authorized():
        logging.info("\nERRO: O cliente não está autenticado.")
        return

    logging.info("\nResolvendo entidades dos canais...")

    for canal in CHANNELS:
        try:
            entidade = await client.get_entity(canal)
            resolved_channels[canal] = entidade
            logging.info(f"Canal {canal} resolvido! ID: {entidade.id}")
        except Exception as e:
            logging.info(f"\nNão foi possível resolver {canal}. Erro: {e}")

    logging.info("\n✨ Monitoramento ATIVO. Pressione Ctrl + C para encerrar.")
    await client.run_until_disconnected()

# ----------------------------------------------------------
if __name__ == "__main__":
    try:
        loop = asyncio.get_event_loop()
        loop.run_until_complete(main())
    except KeyboardInterrupt:
        logging.info("\nMonitoramento interrompido pelo usuário.")
    except Exception as e:
        logging.info(f"Ocorreu um erro geral: {e}")
    finally:
        if client.is_connected():
            logging.info("Desconectando o cliente Telegram.")
            if asyncio.get_event_loop().is_running():
                asyncio.ensure_future(client.disconnect())
            else:
                client.disconnect()
EOF

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
Environment="SESSION_ID=$SESSION_ID"
ExecStart=/usr/bin/python3 $APP_DIR/agent.py
Restart=always

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable telegram-agent
systemctl start telegram-agent

echo "Setup Finalizado com Sucesso!"