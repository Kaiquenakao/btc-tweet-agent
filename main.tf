provider "aws" {
  region = var.aws_region
}

module "ec2" {
  source = "./infra/ec2"

  ami_id        = var.ami_id
  subnet_id     = "subnet-0a1c52410042a044e"
  vpc_id        = "vpc-0e9225ab2d16f8d9d"
  instance_type = var.instance_type

  sqs_arn = module.sqs.sqs_arn
}

module "sqs" {
  source = "./infra/sqs"

  queue_name = "btc-tweet-agent"
}
