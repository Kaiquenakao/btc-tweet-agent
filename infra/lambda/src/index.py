import json
import boto3


def handler(event, context):
    print("Iniciando processamento de mensagens SQS...")
    print(event)

    ssm_client = boto3.client("ssm")
    parameter = ssm_client.get_parameter(
        Name="/btc_tweet_agent/openai_api_key", WithDecryption=True
    )
    openai_api_key = parameter["Parameter"]["Value"]
    print(f"OpenAI API Key recuperada: {openai_api_key}")

    for record in event["Records"]:
        message_body = record["body"]
        print(f"Mensagem recebida: {message_body}")

    return {"statusCode": 200, "body": json.dumps("Processado com sucesso!")}
