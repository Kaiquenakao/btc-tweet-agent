import json
import boto3
import openai
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)


def handler(event, context):
    logger.info("Iniciando processamento de mensagens SQS...")
    logger.info(event)

    for record in event["Records"]:
        message_body = record["body"]
        logger.info(f"Mensagem recebida: {message_body}")
        message_body = json.loads(message_body)

    ssm_client = boto3.client("ssm")
    parameter = ssm_client.get_parameter(
        Name="/btc_tweet_agent/openai_api_key", WithDecryption=True
    )
    openai_api_key = parameter["Parameter"]["Value"]
    logger.info(f"OpenAI API Key recuperada: {openai_api_key}")

    parameter = ssm_client.get_parameter(
        Name="/btc_tweet_agent/prompt", WithDecryption=True
    )

    prompt = parameter["Parameter"]["Value"]
    logger.info(f"Prompt recuperado: {prompt}")
    logger.info("Enviando mensagem para OpenAI...")

    openai.api_key = openai_api_key

    response = openai.ChatCompletion.create(
        model="gpt-4.1",
        messages=[
            {"role": "system", "content": prompt},
            {"role": "user", "content": message_body["message"]},
        ],
    )

    data = json.loads(response.choices[0].message["content"])
    data = {"noticia": message_body["message"], **data}

    logger.info(f"Resposta do OpenAI: {data}")

    return {"statusCode": 200, "body": json.dumps("Processado com sucesso!")}
