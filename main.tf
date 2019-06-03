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
          "Resource":  "arn:aws:sns:${var.region}:${var.account}:s3-sqs-lambda-test-sns-topic",
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
        "Resource": "arn:aws:sqs:${var.region}:${var.account}:s3-sqs-lambda-test-sqs-queue",
        "Condition": {
          "ArnEquals": {
            "aws:SourceArn": "arn:aws:sns:${var.region}:${var.account}:${aws_sns_topic.sns-topic.name}"
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
  topic_arn = "arn:aws:sns:${var.region}:${var.account}:${aws_sns_topic.sns-topic.name}"
  protocol  = "sqs"
  endpoint  = "arn:aws:sqs:${var.region}:${var.account}:${aws_sqs_queue.sqs-queue.name}"
}


#####################
# Lambda IAM Policy #
#####################

resource "aws_iam_role" "lambda-endpoint-iam-role" {
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "lambda-endpoint-iam-policy-attachment" {
  policy_arn = "${aws_iam_policy.lambda-endpoint-iam-policy.arn}"
  role = "${aws_iam_role.lambda-endpoint-iam-role.name}"
}

resource "aws_iam_policy" "lambda-endpoint-iam-policy" {
  policy = "${data.aws_iam_policy_document.lambda-endpoint-iam-policy-document.json}"
}

data "aws_iam_policy_document" "lambda-endpoint-iam-policy-document" {
  statement {
    sid       = "AllowSQSPermissions"
    effect    = "Allow"
    resources = ["arn:aws:sqs:*"]

    actions = [
      "sqs:ChangeMessageVisibility",
      "sqs:DeleteMessage",
      "sqs:GetQueueAttributes",
      "sqs:ReceiveMessage",
    ]
  }

  statement {
    sid       = "AllowInvokingLambdas"
    effect    = "Allow"
    resources = ["arn:aws:lambda:${var.region}:*:function:*"]
    actions   = ["lambda:InvokeFunction"]
  }

  statement {
    sid       = "AllowCreatingLogGroups"
    effect    = "Allow"
    resources = ["arn:aws:logs:${var.region}:*:*"]
    actions   = ["logs:CreateLogGroup"]
  }
  statement {
    sid       = "AllowWritingLogs"
    effect    = "Allow"
    resources = ["arn:aws:logs:${var.region}:*:log-group:/aws/lambda/*:*"]

    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
  }
}


###################
# Lambda function #
###################

resource "aws_lambda_function" "lambda-endpoint" {
  function_name = "s3-sqs-lambda-test-lambda-endpoint"
  filename      = "lambda-script.zip"
  role          = "${aws_iam_role.lambda-endpoint-iam-role.arn}"
  handler       = "lambda-script.handler"

  runtime = "python3.7"
}


######################
# Lambda SQS Trigger #
######################

resource "aws_lambda_event_source_mapping" "lambda-sqs-event-source" {
  event_source_arn = "${aws_sqs_queue.sqs-queue.arn}"
  enabled          = true
  function_name    = "${aws_lambda_function.lambda-endpoint.function_name}"
  batch_size       = 1
}