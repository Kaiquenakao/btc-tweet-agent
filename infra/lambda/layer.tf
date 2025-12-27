resource "null_resource" "install_dependencies" {
  provisioner "local-exec" {
    interpreter = ["PowerShell", "-Command"]
    command     = <<EOT
      $basePath = "${path.module}/build/layers/openai/python"
      # O -Force garante que a árvore de diretórios seja criada sem erro
      if (!(Test-Path $basePath)) {
        New-Item -ItemType Directory -Force -Path $basePath
      }
      pip install -r "${path.module}/requirements.txt" -t $basePath
    EOT
  }

  triggers = {
    requirements_hash = filebase64sha256("${path.module}/requirements.txt")
  }
}

data "archive_file" "openai_layer_zip" {
  type        = "zip"
  source_dir  = fileexists("${path.module}/build/layers/openai/python/openai/__init__.py") ? "${path.module}/build/layers/openai" : "${path.module}/src"
  output_path = "${path.module}/build/openai_layer.zip"

  depends_on = [null_resource.install_dependencies]
}

resource "aws_lambda_layer_version" "openai_layer" {
  filename            = data.archive_file.openai_layer_zip.output_path
  layer_name          = "openai_library"
  compatible_runtimes = ["python3.11"]
  source_code_hash    = data.archive_file.openai_layer_zip.output_base64sha256
}
