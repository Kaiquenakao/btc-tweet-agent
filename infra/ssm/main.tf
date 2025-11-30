resource "aws_ssm_parameter" "api_hash" {
  name  = var.api_hash
  type  = "String"
  value = "value"
}

resource "aws_ssm_parameter" "api_id" {
  name  = var.api_id
  type  = "String"
  value = "value"
}

resource "aws_ssm_parameter" "channel" {
  name  = var.channel
  type  = "String"
  value = "value"
}
