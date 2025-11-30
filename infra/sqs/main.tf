resource "aws_sqs_queue" "btc_tweet_agent_queue" {
  name = "${var.queue_name}.fifo"

  fifo_queue                  = true
  content_based_deduplication = true

  tags = {
    Name = var.queue_name
  }
}

output "sqs_arn" {
  value = aws_sqs_queue.btc_tweet_agent_queue.arn
}
