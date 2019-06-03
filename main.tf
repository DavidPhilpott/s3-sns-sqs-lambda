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

  policy = <<POLICY
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": {
          "AWS": "*"
        },
        "Action": "SQS:SendMessage",
        "Resource": "arn:aws:sqs:eu-west-1:020968065558:s3-sqs-lambda-test-sqs-queue",
        "Condition": {
          "ArnEquals": {
            "aws:SourceArn": "arn:aws:sns:eu-west-1:020968065558:${aws_sns_topic.sns-topic.name}"
          }
        }
      }
    ]
  }
  POLICY
}


###########################
# SNS to SQS Subscription #
###########################

resource "aws_sns_topic_subscription" "sns-to-sqs-subscription" {
  topic_arn = "arn:aws:sns:eu-west-1:020968065558:${aws_sns_topic.sns-topic.name}"
  protocol  = "sqs"
  endpoint  = "arn:aws:sqs:eu-west-1:020968065558:${aws_sqs_queue.sqs-queue.name}"
}


#####################
# Lambda IAM Policy #
#####################

resource "aws_iam_role" "lambda-endpoint-iam-role" {
  name = "s3-sqs-lambda-test-lambda-iam-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}


###################
# Lambda function #
###################

resource "aws_lambda_function" "lambda-endpoint" {
  function_name = "s3-sqs-lambda-test-lambda-endpoint"
  filename      = "lambda-script.zip"
  role          = "${aws_iam_role.lambda-endpoint-iam-role.arn}"
  handler       = "lambda-script.lambda-handler"

  runtime = "python3.7"

  environment {
    variables = {
      foo = "bar"
    }
  }
}