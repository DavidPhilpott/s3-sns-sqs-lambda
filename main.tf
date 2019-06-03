#############
# S3 Bucket #
#############

resource "aws_s3_bucket" "bucket" {
  bucket = "s3-sqs-lambda-test-s3-bucket"
  acl    = "private"
}


#############
# SNS Topic #
#############

resource "aws_sns_topic" "sns-topic" {
  name = "s3-sqs-lambda-test-sns-topic"

policy = <<POLICY
  {
      "Version":"2012-10-17",
      "Statement":[{
          "Effect": "Allow",
          "Principal": {"Service":"s3.amazonaws.com"},
          "Action": "SNS:Publish",
          "Resource":  "arn:aws:sns:eu-west-1:020968065558:s3-sqs-lambda-test-sns-topic",
          "Condition":{
              "ArnLike":{"aws:SourceArn":"${aws_s3_bucket.bucket.arn}"}
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


#################################
# S3 Bucket Notification to SNS #
#################################

resource "aws_s3_bucket_notification" "bucket-notification" {
  bucket = "${aws_s3_bucket.bucket.id}"

  topic {
    topic_arn = "${aws_sns_topic.sns-topic.arn}"

    events = [
      "s3:ObjectCreated:*",
    ]

  }
}


#############
# SQS Queue #
#############

resource "aws_sqs_queue" "sqs-queue" {
  name = "s3-sqs-lambda-test-sqs-queue"
}


###########################
# SNS to SQS Subscription #
###########################

resource "aws_sns_topic_subscription" "sns-to-sqs-subscription" {
  topic_arn = "arn:aws:sns:eu-west-1:020968065558:${aws_sns_topic.sns-topic.name}"
  protocol  = "sqs"
  endpoint  = "arn:aws:sqs:eu-west-1:020968065558:${aws_sqs_queue.sqs-queue.name}"
}
