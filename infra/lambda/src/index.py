import json
import boto3


def handler(event, context):
    print("Iniciando processamento de mensagens SQS...")
    print(event)

    for record in event["Records"]:
        message_body = record["body"]
        print(f"Mensagem recebida: {message_body}")

    return {"statusCode": 200, "body": json.dumps("Processado com sucesso!")}
