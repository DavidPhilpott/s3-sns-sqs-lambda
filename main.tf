resource "aws_s3_bucket" "${var.s3-bucket-name}" {
  bucket = "${var.s3-bucket-name}"
  acl    = "private"

  tags = {
  	Project     = "${var.project_name}"
    Name        = "${var.s3-bucket-name}"
    Environment = "Dev"
  }
}

resource "aws_sns_topic" "${var.sns-topic-name}" {
  name = "${var.sns-topic-name}"

  tags = {
    Project     = "${var.project_name}"
    Name        = "${var.sns-topic-name}"
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
              "ArnLike":{"aws:SourceArn":"${var.s3-bucket-name}.arn}"}
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
  bucket = "${var.s3-bucket-name}.id}"

  topic {
    topic_arn = "${var.sns-topic-name}.arn}"

    events = [
      "s3:ObjectCreated:*",
    ]

  }
}