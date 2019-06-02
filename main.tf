resource "aws_s3_bucket" "${var.project_name}-test-bucket" {
  bucket = "${var.project_name}-test-bucket"
  acl    = "private"

  tags = {
  	Project     = "${var.project_name}"
    Name        = "${var.project_name}-test-bucket"
    Environment = "Dev"
  }
}

resource "aws_sns_topic" "${var.project_name}-sns-topic" {
  name = "${var.project_name}-sns-topic"

  tags = {
    Project     = "${var.project_name}-lambda"
    Name        = "${var.project_name}-sns-topic"
    Environment = "Dev"
  }
policy = <<POLICY
  {
      "Version":"2012-10-17",
      "Statement":[{
          "Effect": "Allow",
          "Principal": {"Service":"s3.amazonaws.com"},
          "Action": "SNS:Publish",
          "Resource":  "arn:aws:sns:eu-west-1:020968065558:s3-sns-sqs-lambda-sns-topic",
          "Condition":{
              "ArnLike":{"aws:SourceArn":"${aws_s3_bucket.${var.project_name}-test-bucket.arn}"}
          }
      }]
  }
  POLICY

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

resource "aws_s3_bucket_notification" "${var.project_name}-test-bucket-notification" {
  bucket = "${aws_s3_bucket.${var.project_name}-test-bucket.id}"

  topic {
    topic_arn = "${aws_sns_topic.${var.project_name}-sns-topic.arn}"

    events = [
      "s3:ObjectCreated:*",
    ]

  }
}