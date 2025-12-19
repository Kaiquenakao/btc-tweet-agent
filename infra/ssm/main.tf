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

resource "aws_ssm_parameter" "queue_name" {
  name  = var.queue_name
  type  = "String"
  value = "value"
}


resource "aws_ssm_parameter" "api_key" {
  name  = var.api_key
  type  = "String"
  value = "value"
}

resource "aws_ssm_parameter" "table_name" {
  name  = var.table_name
  type  = "String"
  value = "value"
}

resource "aws_ssm_parameter" "session_name" {
  name  = "/btc_tweet_agent/session_name"
  type  = "SecureString"
  value = "value"
}
