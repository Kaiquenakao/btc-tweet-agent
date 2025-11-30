data "aws_caller_identity" "current" {}

resource "aws_iam_role" "ec2_role" {
  name = "ec2-send-sqs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_policy" "sqs_send_policy" {
  name        = "btc-tweet-agent"
  description = "Allows EC2 to send messages to SQS"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sqs:SendMessage",
          "sqs:GetQueueUrl",
          "sqs:GetQueueAttributes"
        ]
        Resource = var.sqs_arn
      },
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath"
        ]
        Resource = "arn:aws:ssm:${var.region}:${data.aws_caller_identity.current.account_id}:parameter/btc_tweet_agent/*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ec2_sqs_attach" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.sqs_send_policy.arn
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2-iam-profile-sqs"
  role = aws_iam_role.ec2_role.name
}
