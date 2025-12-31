resource "aws_sns_topic" "btc_tweet_agent" {
  name = var.topic_name
}
