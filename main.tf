provider "aws" {
  region = var.aws_region
}

module "ec2" {
  source = "./infra/ec2"

  ami_id        = var.ami_id
  subnet_id     = "subnet-0a1c52410042a044e"
  vpc_id        = "vpc-0e9225ab2d16f8d9d"
  instance_type = var.instance_type
  region        = var.region
  sqs_arn       = module.sqs.sqs_arn
}

module "sqs" {
  source = "./infra/sqs"

  queue_name = "btc-tweet-agent"
}

module "ssm" {
  source     = "./infra/ssm"
  api_hash   = "/btc_tweet_agent/api_hash"
  api_id     = "/btc_tweet_agent/api_id"
  channel    = "/btc_tweet_agent/channel"
  queue_name = "/btc_tweet_agent/queue_name"
  api_key    = "/btc_tweet_agent/api_key"
  table_name = "/btc_tweet_agent/table_name"
  session_id = "/btc_tweet_agent/session_id"
  prompt     = "/btc_tweet_agent/prompt"
}


module "lambda" {
  source  = "./infra/lambda"
  sqs_arn = module.sqs.sqs_arn
}
