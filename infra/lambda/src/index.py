import json
import boto3
from openai import OpenAI


def handler(event, context):
    print("Iniciando processamento de mensagens SQS...")
    print(event)

    for record in event["Records"]:
        message_body = record["body"]
        print(f"Mensagem recebida: {message_body}")

    ssm_client = boto3.client("ssm")
    parameter = ssm_client.get_parameter(
        Name="/btc_tweet_agent/openai_api_key", WithDecryption=True
    )
    openai_api_key = parameter["Parameter"]["Value"]
    print(f"OpenAI API Key recuperada: {openai_api_key}")

    parameter = ssm_client.get_parameter(
        Name="/btc_tweet_agent/prompt", WithDecryption=True
    )

    prompt = parameter["Parameter"]["Value"]
    print(f"Prompt recuperado: {prompt}")

    client = OpenAI(api_key=openai_api_key)

    response = client.chat.completions.create(
        model="gpt-4",
        messages=[
            {
                "role": "system",
                "content": prompt,
            },
            {
                "role": "user",
                "content": message_body["message"],
            },
        ],
    )
    print("Resposta do OpenAI:")
    print(response.choices[0].message.content)
    return {"statusCode": 200, "body": json.dumps("Processado com sucesso!")}
