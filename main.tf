#S3 Bucket 

resource "aws_s3_bucket" "test-s3-bucket" {
  bucket = "s3-bucket"
  acl    = "private"
}

# S3 Bucket Notification
resource "aws_s3_bucket_notification" "test-bucket-notification" {
  bucket = "${aws_s3_bucket.s3-bucket-name.id}"

  topic {
    topic_arn = "${aws_sns_topic.test-sns-topic.arn}"

    events = [
      "s3:ObjectCreated:*",
    ]

  }
}

#SNS Topic
resource "aws_sns_topic" "test-sns-topic" {
  name = "sns-topic"

policy = <<POLICY
  {
      "Version":"2012-10-17",
      "Statement":[{
          "Effect": "Allow",
          "Principal": {"Service":"s3.amazonaws.com"},
          "Action": "SNS:Publish",
          "Resource":  "arn:aws:sns:eu-west-1:020968065558:test-sns-topic",
          "Condition":{
              "ArnLike":{"aws:SourceArn":"${aws_s3_bucket.test-s3-bucket.arn}"}
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

