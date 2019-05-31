terraform {
  backend "s3" {
    bucket = "s3-sns-sqs-lambda-test-bucket"
    key    = "terraform_state"
    region = "us-east-1"
  }
}
