resource "aws_s3_bucket" "input_sns_sqs_bucket" {
  bucket = "s3-sns-sqs-lambda-test-bucket"
  acl    = "private"

  tags = {
    Name        = "s3-sns-sqs-lambda-test-bucket"
    Environment = "Dev"
  }
}
