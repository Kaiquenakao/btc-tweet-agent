data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/src"
  output_path = "${path.module}/build/lambda_function.zip"
}

resource "aws_lambda_function" "sqs_processor" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "btc-tweet-agent"
  role             = aws_iam_role.lambda_role.arn
  handler          = "index.handler"
  runtime          = "python3.11"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  layers = [aws_lambda_layer_version.openai_layer.arn]

  timeout     = 120
  memory_size = 2000
}

# Trigger do SQS
resource "aws_lambda_event_source_mapping" "sqs_trigger" {
  event_source_arn = var.sqs_arn
  function_name    = aws_lambda_function.sqs_processor.arn
  batch_size       = 5
}
