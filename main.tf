resource "aws_s3_bucket" "s3-sns-sqs-lambda-test-bucket" {
  bucket = "s3-sns-sqs-lambda-test-bucket"
  acl    = "private"

  tags = {
  	Project = "s3-sns-sqs-lambda"
    Name        = "s3-sns-sqs-lambda-test-bucket"
    Environment = "Dev"
  }
}

resource "aws_sns_topic" "s3-sns-sqs-lambda-sns-topic" {
  name = "s3-sns-sqs-lambda-sns-topic"
    delivery_policy = <<EOF
{
  "http": {
    "defaultHealthyRetryPolicy": {
      "minDelayTarget": 20,
      "maxDelayTarget": 20,
      "numRetries": 3,
      "numMaxDelayRetries": 0,
      "numNoDelayRetries": 0,
      "numMinDelayRetries": 0,
      "backoffFunction": "linear"
    },
    "disableSubscriptionOverrides": false,
    "defaultThrottlePolicy": {
      "maxReceivesPerSecond": 1
    }
  }
}
EOF
}
