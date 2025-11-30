variable "ami_id" {
  type = string
}

variable "instance_type" {
  type    = string
  default = "t2.micro"
}

variable "subnet_id" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "sqs_arn" {
  type        = string
  description = "ARN da fila SQS"
}

variable "region" {
  type    = string
  default = "sa-east-1"
}
