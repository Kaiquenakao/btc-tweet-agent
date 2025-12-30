resource "null_resource" "install_dependencies" {
  provisioner "local-exec" {
    command     = <<EOT
if (Test-Path build) { Remove-Item build -Recurse -Force }
New-Item -ItemType Directory -Path build\python
pip install -r requirements.txt -t build\python
EOT
    working_dir = path.module
    interpreter = ["PowerShell", "-Command"]
  }

  triggers = {
    requirements_hash = sha256(file("${path.module}/requirements.txt"))
  }
}

data "archive_file" "lambda_layer_zip" {
  type        = "zip"
  source_dir  = "${path.module}/build"
  output_path = "${path.module}/lambda_layer.zip"

  depends_on = [null_resource.install_dependencies]
}

resource "aws_lambda_layer_version" "lambda_layer" {
  filename            = data.archive_file.lambda_layer_zip.output_path
  layer_name          = "btc_tweet_agent_layer"
  compatible_runtimes = ["python3.11"]
  source_code_hash    = data.archive_file.lambda_layer_zip.output_base64sha256
}

output "lambda_layer_arn" {
  description = "ARN da Lambda Layer criada"
  value       = aws_lambda_layer_version.lambda_layer.arn
}

output "lambda_layer_version" {
  description = "Versão da Lambda Layer"
  value       = aws_lambda_layer_version.lambda_layer.version
}

output "lambda_layer_name" {
  description = "Nome da Lambda Layer"
  value       = aws_lambda_layer_version.lambda_layer.layer_name
}
